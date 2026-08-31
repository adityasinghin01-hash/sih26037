"""THE GATE. Count how often a vehicle actually yields, before any model is trained.

Why this exists: if yielding is rare, a model can answer "no" every time, score 99%, and be
useless. That changes the whole approach, so it is measured first.

    python3 python/meteor/check_balance.py --data ~/meteor-data [--clips 50] [--every 10]

Reads the clip zips directly. Nothing needs unpacking.
"""
from __future__ import annotations

import argparse
import collections
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from meteor.parse_xml import parse_frame, frame_index      # noqa: E402

FRAME_DIR = "Frame XML Annotations"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data", type=Path, required=True)
    ap.add_argument("--clips", type=int, default=50, help="how many clips to sample")
    ap.add_argument("--every", type=int, default=10, help="sample every Nth frame")
    args = ap.parse_args()

    src = args.data / "METEOR_Dataset" / FRAME_DIR
    if not src.is_dir():
        print(f"ERROR: {src} not found. Run fetch_annotations.py first.", file=sys.stderr)
        return 1

    zips = sorted(src.glob("*.zip"))[: args.clips]
    if not zips:
        print(f"ERROR: no clip archives in {src}", file=sys.stderr)
        return 1

    objects = yes = frames = clips = 0
    by_class: collections.Counter[int] = collections.Counter()
    yes_by_class: collections.Counter[int] = collections.Counter()

    for z in zips:
        try:
            zf = zipfile.ZipFile(z)
        except Exception as exc:                       # noqa: BLE001
            print(f"  skipped {z.name}: {exc}", file=sys.stderr)
            continue
        clips += 1
        names = sorted((n for n in zf.namelist() if n.lower().endswith(".xml")),
                       key=lambda n: frame_index(n))
        for n in names[:: args.every]:
            try:
                fr = parse_frame(zf.read(n).decode("utf-8", "replace"), frame_index(n))
            except Exception:                          # noqa: BLE001
                continue
            frames += 1
            for b in fr.boxes:
                objects += 1
                by_class[b.class_id] += 1
                if fr.labels.get(b.track_id, 0) == 1:
                    yes += 1
                    yes_by_class[b.class_id] += 1

    if objects == 0:
        print("ERROR: parsed 0 objects. Send this whole output.", file=sys.stderr)
        return 1

    ratio = objects / yes if yes else float("inf")
    pct = 100.0 * yes / objects
    print(f"clips read        : {clips}")
    print(f"frames sampled    : {frames:,}  (every {args.every}th)")
    print(f"vehicles seen     : {objects:,}")
    print(f"of which yielded  : {yes:,}  ({pct:.3f}%)")
    print(f"RATIO             : 1 yield per {ratio:,.0f} vehicles" if yes else
          "RATIO             : NO POSITIVE EXAMPLES FOUND")

    print("\nper class (ClassID: seen / yielded):")
    for cid, n in by_class.most_common():
        print(f"  {cid:>3}: {n:>8,} / {yes_by_class[cid]:,}")

    print("\nVERDICT:")
    if yes == 0:
        print("  NO POSITIVES. Stop. Do not train. Report this to Aditya immediately.")
    elif ratio <= 20:
        print("  Healthy. Train normally.")
    elif ratio <= 200:
        print(f"  Imbalanced. Train with --pos-weight {ratio:.0f} and report recall, not accuracy.")
    else:
        print("  SEVERE. Stop and report. The question itself may need to change.")
    print("\nDo not proceed to training. Report this output and wait.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
