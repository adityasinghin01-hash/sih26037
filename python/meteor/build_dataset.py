"""Turn METEOR clip archives into training sequences.

    python3 python/meteor/build_dataset.py --data ~/meteor-data --out ~/meteor-data/features

Per clip it writes ONE .npz holding:
    x    [N, 20, 31] float32   the S2 sequences, one per (agent, timestep) sample
    y    [N]         int64     1 if that agent yielded at that timestep, else 0
    adj  [N, A, A]   float32   adjacency, emitted even though the LSTM ignores it (S2 rule)
    tid  [N]         int64     track_id, for the yield ledger later
    fidx [N]         int64     frame index - lets model 2 group all agents of one frame

30 Hz is subsampled to 10 Hz by taking every 3rd frame, per the contract.
Sequences shorter than 20 steps are front-padded with their earliest frame.
"""
from __future__ import annotations

import argparse
import sys
import zipfile
from collections import defaultdict, deque
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from meteor.features import FEATURE_DIM, SEQ_LEN, EgoState, frame_features, to_sequence  # noqa: E402
from meteor.parse_xml import (action_from_accel, ecef_to_speed, ecef_to_yaw_rate,        # noqa: E402
                              frame_index, parse_frame)

FRAME_DIR = "Frame XML Annotations"
STRIDE = 3               # 30 Hz -> 10 Hz
MAX_AGENTS = 16          # A, the cap the graph model needs. Fixed at export.


def build_clip(zf: zipfile.ZipFile, cand_action: float = 0.0):
    names = sorted((n for n in zf.namelist() if n.lower().endswith(".xml")),
                   key=lambda n: frame_index(n))[::STRIDE]
    hist: dict[int, deque] = defaultdict(lambda: deque(maxlen=SEQ_LEN))
    prev_boxes: dict = {}
    prev_ecef = None
    prev_prev_ecef = None
    prev_speed = 0.0
    xs, ys, adjs, tids, fidxs = [], [], [], [], []

    for n in names:
        try:
            fr = parse_frame(zf.read(n).decode("utf-8", "replace"), frame_index(n))
        except Exception:                                    # noqa: BLE001
            continue
        if not fr.boxes:
            prev_ecef = fr.ego_ecef or prev_ecef
            continue

        dt = STRIDE / 30.0
        speed = ecef_to_speed(prev_ecef, fr.ego_ecef, dt)
        yaw_rate = ecef_to_yaw_rate(prev_prev_ecef, prev_ecef, fr.ego_ecef, dt)
        accel = (speed - prev_speed) / dt
        # feature 31 carries the action the ego ACTUALLY took, since METEOR never shows the
        # counterfactual. Overridden by the caller when a hypothetical action is being scored.
        action = cand_action if cand_action else action_from_accel(accel)
        ego = EgoState(speed=speed, yaw_rate=yaw_rate, accel=accel, cand_action=action)
        data, adj, ids = frame_features(fr.boxes, prev_boxes, ego, fr.width, fr.height)

        for i, tid in enumerate(ids):
            hist[tid].append(data[i])
            seq = to_sequence(list(hist[tid]))
            a = np.zeros((MAX_AGENTS, MAX_AGENTS), dtype=np.float32)
            k = min(len(ids), MAX_AGENTS)
            a[:k, :k] = adj[:k, :k]
            xs.append(seq)
            ys.append(fr.labels.get(tid, 0))
            adjs.append(a)
            tids.append(tid)
            fidxs.append(fr.index)

        prev_boxes = {b.track_id: b for b in fr.boxes}
        prev_prev_ecef = prev_ecef
        prev_ecef = fr.ego_ecef or prev_ecef
        prev_speed = speed

    if not xs:
        return None
    return (np.stack(xs).astype(np.float32), np.asarray(ys, dtype=np.int64),
            np.stack(adjs).astype(np.float32), np.asarray(tids, dtype=np.int64),
            np.asarray(fidxs, dtype=np.int64))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--limit", type=int, default=0, help="only the first N clips")
    args = ap.parse_args()

    src = args.data / "METEOR_Dataset" / FRAME_DIR
    if not src.is_dir():
        print(f"ERROR: {src} not found. Run fetch_annotations.py first.", file=sys.stderr)
        return 1
    args.out.mkdir(parents=True, exist_ok=True)

    zips = sorted(src.glob("*.zip"))
    if args.limit:
        zips = zips[: args.limit]
    total = pos = 0
    written = skipped = 0

    for i, z in enumerate(zips, 1):
        dest = args.out / f"{z.stem}.npz"
        if dest.exists():
            skipped += 1
            continue
        try:
            with zipfile.ZipFile(z) as zf:
                built = build_clip(zf)
        except Exception as exc:                             # noqa: BLE001
            print(f"  FAILED {z.name}: {type(exc).__name__}: {exc}", file=sys.stderr)
            continue
        if built is None:
            continue
        x, y, adj, tid, fidx = built
        assert x.shape[1:] == (SEQ_LEN, FEATURE_DIM), f"BAD SHAPE {x.shape} - contract broken"
        np.savez_compressed(dest, x=x, y=y, adj=adj, tid=tid, fidx=fidx)
        total += len(y); pos += int(y.sum()); written += 1
        if i % 25 == 0 or i == len(zips):
            print(f"  [{i}/{len(zips)}] clips={written} samples={total:,} positives={pos:,}",
                  flush=True)

    # A constant feature carries no information. METEOR's ECEF is a single clip-level location
    # tag, not a trajectory, so features 28-31 cannot be filled from these annotations.
    # Say so loudly rather than let someone train on dead columns without knowing.
    if written:
        import glob as _g
        sample = np.load(sorted(_g.glob(str(args.out / "*.npz")))[0])["x"].reshape(-1, FEATURE_DIM)
        dead = [i + 1 for i in range(FEATURE_DIM) if sample[:, i].min() == sample[:, i].max()]
        if dead:
            print(f"\nWARNING: features {dead} are CONSTANT and carry no information.")
            print("  28-31 (ego speed, yaw rate, acceleration, candidate action) are expected to")
            print("  be dead: METEOR's ECEF field is one clip-level location tag, not a per-frame")
            print("  trajectory, and the annotations contain no ego motion at all. The model is")
            print("  effectively training on 27 features. Report this; do not silently ignore it.")

    print(f"\nwritten={written} skipped={skipped}")
    print(f"samples={total:,}  positives={pos:,}  "
          f"({100.0*pos/max(total,1):.3f}%)")
    print(f"shape check: [N, {SEQ_LEN}, {FEATURE_DIM}] - last dimension must be {FEATURE_DIM}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
