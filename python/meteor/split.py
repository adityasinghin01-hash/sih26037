"""Split the dataset BY CLIP, never by frame.

Frames next to each other are near-duplicates. A frame-level split puts almost the same sample
in both training and test, so the model has effectively seen the answers. Scores look excellent
and mean nothing. This is the single easiest way to ruin the result silently.

    python3 python/meteor/split.py --features ~/meteor-data/features --by clip
"""
from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

import numpy as np


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True)
    ap.add_argument("--by", choices=["clip"], default="clip",
                    help="only 'clip' is allowed; frame-level splitting leaks")
    ap.add_argument("--val-frac", type=float, default=0.2)
    ap.add_argument("--seed", type=int, default=0)
    args = ap.parse_args()

    clips = sorted(p.name for p in args.features.glob("*.npz"))
    if not clips:
        print(f"ERROR: no .npz in {args.features}. Run build_dataset.py first.")
        return 1

    random.Random(args.seed).shuffle(clips)
    n_val = max(1, int(len(clips) * args.val_frac))
    val, train = clips[:n_val], clips[n_val:]

    def count(names):
        n = p = 0
        for nm in names:
            y = np.load(args.features / nm)["y"]
            n += len(y); p += int(y.sum())
        return n, p

    tn, tp = count(train)
    vn, vp = count(val)

    out = args.features / "split.json"
    out.write_text(json.dumps({"train": train, "val": val, "seed": args.seed}, indent=1))

    print(f"SPLIT BY CLIP (seed {args.seed})")
    print(f"  train : {len(train):>4} clips   {tn:>9,} samples   {tp:>7,} positives")
    print(f"  val   : {len(val):>4} clips   {vn:>9,} samples   {vp:>7,} positives")
    print(f"\nwrote {out}")
    if vp == 0:
        print("\nWARNING: the validation set has ZERO positives. Recall is undefined.")
        print("Re-run with a different --seed, or report this.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
