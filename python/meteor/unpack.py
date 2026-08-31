"""Unpack METEOR clip archives.

Each clip arrives as one zip containing <clip>/Annotations/frame_NNNNNN.xml.
Unpacking is optional - check_balance.py and build_dataset.py read the zips directly - but it
is useful for looking at the data by hand.

    python3 python/meteor/unpack.py --data ~/meteor-data [--limit 5]
"""
from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path

FRAME_DIR = "Frame XML Annotations"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data", type=Path, required=True, help="folder holding METEOR_Dataset/")
    ap.add_argument("--out", type=Path, default=None, help="default: <data>/unpacked")
    ap.add_argument("--limit", type=int, default=0, help="unpack only the first N clips")
    args = ap.parse_args()

    src = args.data / "METEOR_Dataset" / FRAME_DIR
    if not src.is_dir():
        print(f"ERROR: {src} not found. Run fetch_annotations.py first.", file=sys.stderr)
        return 1
    out = args.out or (args.data / "unpacked")
    out.mkdir(parents=True, exist_ok=True)

    zips = sorted(src.glob("*.zip"))
    if args.limit:
        zips = zips[: args.limit]
    print(f"{len(zips)} clip archives -> {out}")

    done = failed = 0
    for i, z in enumerate(zips, 1):
        try:
            with zipfile.ZipFile(z) as zf:
                zf.extractall(out)
            done += 1
        except Exception as exc:                      # noqa: BLE001
            print(f"  FAILED {z.name}: {type(exc).__name__}: {exc}", file=sys.stderr)
            failed += 1
        if i % 50 == 0 or i == len(zips):
            print(f"  [{i}/{len(zips)}] unpacked={done} failed={failed}", flush=True)

    print(f"\nunpacked={done} failed={failed} -> {out}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
