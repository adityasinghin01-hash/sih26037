"""Split the dataset BY CLIP or BY RECORDING SESSION, never by frame.

Frames next to each other are near-duplicates. A frame-level split puts almost the same sample
in both training and test, so the model has effectively seen the answers. Scores look excellent
and mean nothing. This is the single easiest way to ruin the result silently.

Clips recorded minutes apart on the same drive also leak road geometry, lighting, and driving
style. Session-level splitting groups continuous drives so no recording session spans across
partitions.

    python3 ml/python/meteor/split.py --features ~/meteor-data/features --by session --seed 42
"""
from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
import random
import re
from typing import Sequence

import numpy as np

TIMESTAMP_PATTERN = re.compile(
    r"REC_(\d{4})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_(\d{2})_", re.IGNORECASE
)


def parse_clip_timestamp(clip_name: str) -> datetime | None:
    """Extract recording timestamp from clip filename, or None if unparseable."""
    m = TIMESTAMP_PATTERN.search(clip_name)
    if not m:
        return None
    return datetime(
        int(m.group(1)), int(m.group(2)), int(m.group(3)),
        int(m.group(4)), int(m.group(5)), int(m.group(6))
    )


def group_clips_into_sessions(
    clip_names: Sequence[str], gap_seconds: int = 1800
) -> list[list[str]]:
    """Group clips into continuous driving sessions based on timestamp proximity."""
    parsed = []
    unparsed = []
    for name in clip_names:
        dt = parse_clip_timestamp(name)
        if dt is not None:
            parsed.append((name, dt))
        else:
            unparsed.append(name)

    parsed.sort(key=lambda x: x[1])

    sessions: list[list[str]] = []
    curr: list[str] = []
    last_dt: datetime | None = None

    for name, dt in parsed:
        if last_dt is None:
            curr.append(name)
            last_dt = dt
        else:
            gap = (dt - last_dt).total_seconds()
            if 0 <= gap <= gap_seconds:
                curr.append(name)
                last_dt = dt
            else:
                sessions.append(curr)
                curr = [name]
                last_dt = dt
    if curr:
        sessions.append(curr)

    # Any clips without valid timestamps are treated as independent singleton sessions
    for u in unparsed:
        sessions.append([u])

    return sessions


def make_3way_split(
    features_dir: Path,
    clips: list[str],
    by: str = "session",
    val_frac: float = 0.15,
    test_frac: float = 0.15,
    seed: int = 42,
    gap_seconds: int = 1800,
) -> dict:
    """Create a deterministic 3-way partition: train, calibration, and untouched test."""
    if by == "session":
        sessions = group_clips_into_sessions(clips, gap_seconds=gap_seconds)
    elif by == "clip":
        sessions = [[c] for c in clips]
    else:
        raise ValueError(f"Unknown split mode: {by!r}. Expected 'session' or 'clip'.")

    # Measure sample and positive counts for each session to balance partitions
    session_data = []
    for s_idx, s_clips in enumerate(sessions):
        tot_samples = 0
        tot_pos = 0
        for c in s_clips:
            feat_file = features_dir / c
            if feat_file.exists():
                y = np.load(feat_file)["y"]
                tot_samples += len(y)
                tot_pos += int((y == 1).sum())
            else:
                tot_samples += 1
        session_data.append({
            "session_id": s_idx + 1,
            "clips": s_clips,
            "samples": tot_samples,
            "positives": tot_pos,
        })

    total_samples = sum(s["samples"] for s in session_data)
    target_test = test_frac * total_samples
    target_cal = val_frac * total_samples

    rng = random.Random(seed)
    shuffled = list(session_data)
    rng.shuffle(shuffled)

    train_sessions: list[dict] = []
    cal_sessions: list[dict] = []
    test_sessions: list[dict] = []

    train_samples = 0
    cal_samples = 0
    test_samples = 0

    # Max session quota per validation partition to ensure multi-session diversity
    max_eval_sessions = max(1, len(shuffled) // 4)

    for s in shuffled:
        if test_samples < target_test and len(test_sessions) < max_eval_sessions:
            test_sessions.append(s)
            test_samples += s["samples"]
        elif cal_samples < target_cal and len(cal_sessions) < max_eval_sessions:
            cal_sessions.append(s)
            cal_samples += s["samples"]
        else:
            train_sessions.append(s)
            train_samples += s["samples"]

    train_clips = [c for s in train_sessions for c in s["clips"]]
    cal_clips = [c for s in cal_sessions for c in s["clips"]]
    test_clips = [c for s in test_sessions for c in s["clips"]]

    train_pos = sum(s["positives"] for s in train_sessions)
    cal_pos = sum(s["positives"] for s in cal_sessions)
    test_pos = sum(s["positives"] for s in test_sessions)

    return {
        "seed": seed,
        "method": f"{by}_grouped",
        "train": sorted(train_clips),
        "calibration": sorted(cal_clips),
        "test": sorted(test_clips),
        # Alias 'val' to 'calibration' for backwards compatibility
        "val": sorted(cal_clips),
        "counts": {
            "train": {
                "sessions": len(train_sessions),
                "clips": len(train_clips),
                "samples": train_samples,
                "positives": train_pos,
                "base_rate": train_pos / max(train_samples, 1),
            },
            "calibration": {
                "sessions": len(cal_sessions),
                "clips": len(cal_clips),
                "samples": cal_samples,
                "positives": cal_pos,
                "base_rate": cal_pos / max(cal_samples, 1),
            },
            "test": {
                "sessions": len(test_sessions),
                "clips": len(test_clips),
                "samples": test_samples,
                "positives": test_pos,
                "base_rate": test_pos / max(test_samples, 1),
            },
            "total": {
                "sessions": len(sessions),
                "clips": len(clips),
                "samples": total_samples,
                "positives": train_pos + cal_pos + test_pos,
                "base_rate": (train_pos + cal_pos + test_pos) / max(total_samples, 1),
            },
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True)
    ap.add_argument(
        "--by", choices=["session", "clip"], default="session",
        help="split by continuous recording session (default) or individual clip"
    )
    ap.add_argument("--val-frac", type=float, default=0.15,
                    help="fraction of data allocated to calibration partition")
    ap.add_argument("--test-frac", type=float, default=0.15,
                    help="fraction of data allocated to untouched test partition")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--gap-seconds", type=int, default=1800,
                    help="maximum time gap in seconds between clips in same session")
    ap.add_argument("--out", type=Path, default=None,
                    help="output path for split JSON (defaults to features/split.json)")
    args = ap.parse_args()

    clips = sorted(p.name for p in args.features.glob("*.npz"))
    if not clips:
        print(f"ERROR: no .npz in {args.features}. Run build_dataset.py first.")
        return 1

    manifest = make_3way_split(
        features_dir=args.features,
        clips=clips,
        by=args.by,
        val_frac=args.val_frac,
        test_frac=args.test_frac,
        seed=args.seed,
        gap_seconds=args.gap_seconds,
    )

    out = args.out or (args.features / "split.json")
    out.write_text(json.dumps(manifest, indent=2))

    c = manifest["counts"]
    tot = c["total"]
    print("=" * 76)
    print(f"3-WAY DATASET PARTITION (Method: {manifest['method']}, Seed: {manifest['seed']})")
    print("=" * 76)
    print(f"{'Partition':<14} | {'Sessions':>8} | {'Clips':>6} ({'%':>5}) | {'Samples':>11} ({'%':>5}) | {'Positives':>9} ({'Base%':>5})")
    print("-" * 76)
    for p_name in ["train", "calibration", "test"]:
        pc = c[p_name]
        clip_pct = pc["clips"] / tot["clips"] * 100
        samp_pct = pc["samples"] / tot["samples"] * 100
        print(f"{p_name.capitalize():<14} | {pc['sessions']:>8} | {pc['clips']:>6} ({clip_pct:4.1f}%) | {pc['samples']:>11,d} ({samp_pct:4.1f}%) | {pc['positives']:>9,d} ({pc['base_rate']*100:4.1f}%)")
    print("-" * 76)
    print(f"{'Total':<14} | {tot['sessions']:>8} | {tot['clips']:>6} (100.0%) | {tot['samples']:>11,d} (100.0%) | {tot['positives']:>9,d} ({tot['base_rate']*100:4.1f}%)")
    print("=" * 76)
    print(f"\nSaved split manifest to: {out}")

    # Check for 0 positives warning
    for p_name in ["train", "calibration", "test"]:
        if c[p_name]["positives"] == 0:
            print(f"\nWARNING: Partition '{p_name}' has ZERO positives! Re-run with another seed.")
            return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

