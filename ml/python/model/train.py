"""Train and evaluate a yield predictor.

    python3 ml/python/model/train.py --features ~/meteor-data/features --model lstm  --epochs 20
    python3 ml/python/model/train.py --features ~/meteor-data/features --model attention --epochs 20

Reads split.json, so it trains on whole clips and validates on clips it has never seen.
Run split.py first.

Reports PRECISION AND RECALL PER CLASS. It deliberately does not print accuracy on its own:
when yielding is rare, a model that always answers "no" scores ~99.9% and is useless.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.yield_lstm import YieldNet                              # noqa: E402
from model.yield_attention import YieldAttentionNet, MAX_AGENTS    # noqa: E402


def load(features: Path, names: list[str], group_by_frame: bool):
    xs, ys, adjs, fis = [], [], [], []
    for n in names:
        d = np.load(features / n)
        xs.append(d["x"]); ys.append(d["y"]); adjs.append(d["adj"])
        fi = d["fidx"] if "fidx" in d else np.arange(len(d["y"]))
        # make frame ids unique across clips
        fis.append(fi + len(fis) * 10_000_000)
    x = np.concatenate(xs); y = np.concatenate(ys)
    adj = np.concatenate(adjs); fi = np.concatenate(fis)
    if not group_by_frame:
        return torch.from_numpy(x), torch.from_numpy(y), None

    # group agents of the same frame into [B, A, T, 31]
    order = np.argsort(fi, kind="stable")
    x, y, adj, fi = x[order], y[order], adj[order], fi[order]
    bounds = np.flatnonzero(np.diff(fi)) + 1
    gx, gy, ga = [], [], []
    for chunk in np.split(np.arange(len(fi)), bounds):
        k = min(len(chunk), MAX_AGENTS)
        idx = chunk[:k]
        px = np.zeros((MAX_AGENTS, x.shape[1], x.shape[2]), dtype=np.float32)
        py = np.full((MAX_AGENTS,), -100, dtype=np.int64)     # -100 = ignored by the loss
        px[:k] = x[idx]; py[:k] = y[idx]
        gx.append(px); gy.append(py); ga.append(adj[idx[0]])
    return (torch.from_numpy(np.stack(gx)), torch.from_numpy(np.stack(gy)),
            torch.from_numpy(np.stack(ga)))


def metrics(pred: np.ndarray, true: np.ndarray) -> dict:
    keep = true >= 0
    pred, true = pred[keep], true[keep]
    out = {}
    for cls, name in ((1, "yield"), (0, "no-yield")):
        tp = int(((pred == cls) & (true == cls)).sum())
        fp = int(((pred == cls) & (true != cls)).sum())
        fn = int(((pred != cls) & (true == cls)).sum())
        out[name] = {
            "precision": tp / (tp + fp) if tp + fp else 0.0,
            "recall": tp / (tp + fn) if tp + fn else 0.0,
            "support": int((true == cls).sum()),
        }
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True)
    ap.add_argument("--model", choices=["lstm", "attention"], default="lstm")
    ap.add_argument("--epochs", type=int, default=20)
    ap.add_argument("--batch", type=int, default=256)
    ap.add_argument("--lr", type=float, default=1e-3)
    ap.add_argument("--hidden", type=int, default=64)
    ap.add_argument("--pos-weight", type=float, default=0.0,
                    help="0 = compute it from the data. Essential when yielding is rare.")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    sp = args.features / "split.json"
    if not sp.exists():
        print("ERROR: split.json missing. Run split.py first.", file=sys.stderr)
        return 1
    split = json.loads(sp.read_text())
    grouped = args.model == "attention"

    xtr, ytr, atr = load(args.features, split["train"], grouped)
    xva, yva, ava = load(args.features, split["val"], grouped)
    if args.limit:
        xtr, ytr = xtr[: args.limit], ytr[: args.limit]
        if atr is not None:
            atr = atr[: args.limit]

    valid = ytr[ytr >= 0]
    npos = int((valid == 1).sum()); nneg = int((valid == 0).sum())
    pw = args.pos_weight or (nneg / max(npos, 1))
    # The two models count differently and printing one number for both is how the
    # "14,216 samples, 50,527 labels" confusion happened. Say which unit each figure is in.
    unit = "frames (each holding up to MAX_AGENTS agents)" if grouped else "agent-sequences"
    print(f"train batches over {len(ytr):,} {unit}")
    print(f"labelled agent-sequences={npos + nneg:,}  positives={npos:,}  negatives={nneg:,}")

    # 3. per-feature normalisation, measured on the TRAINING clips only and baked into the
    # model as buffers so the exported ONNX takes raw contract-S2 features. Without it the
    # two looming features (10, 11, clamped at +/-100 s) carry ~400x the numeric range of the
    # box geometry features and the LSTM sees little else.
    # Fit on REAL agent rows only. The attention model pads every frame out to MAX_AGENTS
    # with zeros, and those padded slots are 77.8% of the tensor - measured on this data.
    # Including them drags every mean toward zero and distorts every scale, so model 2 would
    # train on badly scaled inputs while model 1 trained on correct ones, and the ablation
    # between them would be measuring the bug rather than the architecture.
    n_feat = xtr.shape[-1]
    if grouped:
        real = (ytr.reshape(-1) >= 0)                       # [B*A] - padded slots are -100
        flat = xtr.reshape(-1, xtr.shape[-2], n_feat)[real].reshape(-1, n_feat).numpy()
    else:
        flat = xtr.reshape(-1, n_feat).numpy()
    fmean = flat.mean(0)
    fstd = flat.std(0)
    print(f"normaliser rows: {len(flat):,} "
          f"({'real agents only, padding excluded' if grouped else 'all sequences'})")
    nconst = int((fstd < 1e-6).sum())
    print(f"normaliser fitted on train clips only; {nconst} constant feature(s) left at scale 1")
    print(f"pos_weight={pw:,.1f}  (rare-class weighting; without it the model answers 'no' always)")
    if npos == 0:
        print("\nERROR: no positive examples in training. Stop and report.", file=sys.stderr)
        return 1

    dev = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"device={dev}  gpus={torch.cuda.device_count()}")
    net = (YieldAttentionNet(hidden=args.hidden) if grouped
           else YieldNet(hidden=args.hidden))
    net.set_normaliser(fmean, fstd)
    net = net.to(dev)
    opt = torch.optim.AdamW(net.parameters(), lr=args.lr)
    lossf = nn.CrossEntropyLoss(weight=torch.tensor([1.0, pw], device=dev), ignore_index=-100)

    n = len(xtr)
    for ep in range(1, args.epochs + 1):
        net.train()
        perm = torch.randperm(n)
        tot = 0.0
        for i in range(0, n, args.batch):
            j = perm[i: i + args.batch]
            xb, yb = xtr[j].to(dev), ytr[j].to(dev)
            logits = net(xb, atr[j].to(dev)) if grouped else net(xb)
            loss = lossf(logits.reshape(-1, 2), yb.reshape(-1))
            opt.zero_grad(); loss.backward(); opt.step()
            tot += float(loss.detach()) * len(j)

        net.eval()
        with torch.no_grad():
            preds = []
            for i in range(0, len(xva), args.batch):
                xb = xva[i: i + args.batch].to(dev)
                lg = net(xb, ava[i: i + args.batch].to(dev)) if grouped else net(xb)
                preds.append(lg.argmax(-1).cpu().numpy().reshape(-1))
            m = metrics(np.concatenate(preds), yva.numpy().reshape(-1))
        print(f"epoch {ep:>3}  loss={tot/n:.4f}  "
              f"yield P={m['yield']['precision']:.3f} R={m['yield']['recall']:.3f} "
              f"(n={m['yield']['support']})  "
              f"no-yield P={m['no-yield']['precision']:.3f} R={m['no-yield']['recall']:.3f}")

    out = args.out or (args.features / f"yield_{args.model}.pt")
    torch.save({"state_dict": net.state_dict(), "model": args.model,
                "hidden": args.hidden, "pos_weight": pw,
                "feat_mean": fmean.tolist(), "feat_std": fstd.tolist(),
                "train_clips": split["train"], "val_clips": split["val"]}, out)
    print(f"\nsaved {out}")
    print("Report precision and recall for BOTH classes. Never report accuracy alone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
