"""Test a trained predictor BEFORE it goes anywhere near MATLAB.

    python3 python/model/evaluate.py --features ~/meteor-data/features --model <checkpoint.pt>

Eight checks. The point is not to prove the model is perfect - it cannot be, because it is
predicting what a human will do next and humans are not consistent. The point is to know exactly
how it fails, and to make sure it fails in the safe direction.

THE TWO MISTAKES ARE NOT EQUAL:

    says "they will let me in", they do not   ->  we pull out in front of someone.  DANGEROUS
    says "they will not", they would have     ->  we wait a few seconds longer.     harmless

So the operating point is chosen to make the dangerous mistake rare, and the harmless one is
accepted. A cautious honest model beats an accurate average one.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

TARGET_DANGEROUS_RATE = 0.01     # at most 1% of "will yield" calls may be wrong


# ---------------------------------------------------------------- pure numpy, testable

def confusion(p_yield: np.ndarray, truth: np.ndarray, thr: float) -> dict:
    """At threshold thr, how often is each mistake made?"""
    said_yield = p_yield >= thr
    tp = int((said_yield & (truth == 1)).sum())
    fp = int((said_yield & (truth == 0)).sum())     # DANGEROUS: we go, they do not yield
    fn = int((~said_yield & (truth == 1)).sum())    # harmless: we wait unnecessarily
    tn = int((~said_yield & (truth == 0)).sum())
    return {
        "threshold": float(thr),
        "dangerous_errors": fp,
        "harmless_errors": fn,
        "correct_go": tp,
        "correct_wait": tn,
        # of every time we said "go", how often were we wrong? This is the number that matters.
        "dangerous_rate": fp / (tp + fp) if (tp + fp) else 0.0,
        "precision": tp / (tp + fp) if (tp + fp) else 0.0,
        "recall": tp / (tp + fn) if (tp + fn) else 0.0,
        "n_go": tp + fp,
    }


def pick_threshold(p_yield: np.ndarray, truth: np.ndarray,
                   target: float = TARGET_DANGEROUS_RATE) -> tuple[float, dict]:
    """Lowest threshold whose dangerous-error rate is within target, so we stay as useful as
    possible while staying safe. Falls back to the safest available point."""
    best = None
    for thr in np.linspace(0.05, 0.99, 95):
        c = confusion(p_yield, truth, thr)
        if c["n_go"] == 0:
            continue
        if c["dangerous_rate"] <= target:
            return float(thr), c
        if best is None or c["dangerous_rate"] < best[1]["dangerous_rate"]:
            best = (float(thr), c)
    return best if best else (0.99, confusion(p_yield, truth, 0.99))


def calibration(p_yield: np.ndarray, truth: np.ndarray, bins: int = 10) -> list[dict]:
    """When it says 80%, does it happen 80% of the time? An overconfident model is worse than a
    weak one, because the planner trusts the number."""
    out = []
    edges = np.linspace(0.0, 1.0, bins + 1)
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (p_yield >= lo) & (p_yield < hi)
        n = int(m.sum())
        if n == 0:
            continue
        out.append({"bin": f"{lo:.1f}-{hi:.1f}", "n": n,
                    "said": float(p_yield[m].mean()),
                    "actual": float(truth[m].mean())})
    return out


# ---------------------------------------------------------------- needs torch

def main() -> int:
    import torch
    from model.yield_lstm import YieldNet
    from model.yield_attention import YieldAttentionNet, MAX_AGENTS
    from model.train import load

    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True)
    ap.add_argument("--model", type=Path, required=True)
    ap.add_argument("--target", type=float, default=TARGET_DANGEROUS_RATE)
    ap.add_argument("--onnx", type=Path, default=None, help="also check the exported file agrees")
    args = ap.parse_args()

    ck = torch.load(args.model, map_location="cpu")
    kind = ck.get("model", "lstm")
    grouped = kind == "attention"
    net = (YieldAttentionNet(hidden=ck.get("hidden", 64)) if grouped
           else YieldNet(hidden=ck.get("hidden", 64)))
    net.load_state_dict(ck["state_dict"]); net.eval()

    split = json.loads((args.features / "split.json").read_text())
    x, y, adj = load(args.features, split["val"], grouped)

    with torch.no_grad():
        parts = []
        for i in range(0, len(x), 256):
            xb = x[i:i + 256]
            lg = net(xb, adj[i:i + 256]) if grouped else net(xb)
            parts.append(torch.softmax(lg, -1)[..., 1].reshape(-1).numpy())
    p = np.concatenate(parts)
    t = y.numpy().reshape(-1)
    keep = t >= 0
    p, t = p[keep], t[keep]

    fails: list[str] = []

    def check(name, ok, detail=""):
        print(f"  {'PASS' if ok else 'FAIL'}  {name}{'  ' + detail if detail else ''}")
        if not ok:
            fails.append(name)

    print(f"model={kind}  validation samples={len(t):,}  positives={int(t.sum()):,}\n")

    print("1 - outputs are usable numbers")
    check("all finite", bool(np.isfinite(p).all()))
    check("all within 0 and 1", bool((p >= 0).all() and (p <= 1).all()))
    check("not a constant", float(p.std()) > 1e-4, f"std={p.std():.5f}")
    check("uses more than one value", len(np.unique(np.round(p, 3))) > 5,
          f"{len(np.unique(np.round(p,3)))} distinct")

    print("\n2 - is there anything to measure")
    check("validation set contains positives", int(t.sum()) > 0)
    if int(t.sum()) == 0:
        print("\n  Cannot evaluate: no positive examples. Re-split with another seed.")
        return 1

    print("\n3 - the operating point")
    thr, c = pick_threshold(p, t, args.target)
    print(f"  chosen threshold: {thr:.2f}")
    print(f"  says GO {c['n_go']:,} times; of those {c['dangerous_errors']:,} are wrong")
    print(f"  DANGEROUS error rate : {c['dangerous_rate']*100:.2f}%   (target <= {args.target*100:.1f}%)")
    print(f"  harmless errors      : {c['harmless_errors']:,}  (waited when we could have gone)")
    check("dangerous error rate within target", c["dangerous_rate"] <= args.target,
          f"{c['dangerous_rate']*100:.2f}%")
    check("still useful - says GO sometimes", c["n_go"] > 0)

    print("\n4 - is it honest about its own confidence")
    rows = calibration(p, t)
    worst = 0.0
    for r in rows:
        gap = abs(r["said"] - r["actual"])
        worst = max(worst, gap)
        print(f"  {r['bin']}  n={r['n']:>7,}  said {r['said']*100:>5.1f}%  actually {r['actual']*100:>5.1f}%")
    check("never overconfident by more than 20 points", worst <= 0.20, f"worst gap {worst*100:.1f}")

    print("\n5 - does it actually read its inputs")
    with torch.no_grad():
        xb = x[:256]
        base = net(xb, adj[:256]) if grouped else net(xb)
        shuffled = xb.clone()
        shuffled[..., :11] = shuffled[..., :11].flip(0)     # scramble the geometry columns
        alt = net(shuffled, adj[:256]) if grouped else net(shuffled)
        moved = float((base - alt).abs().mean())
    check("output changes when the inputs change", moved > 1e-3, f"mean shift {moved:.5f}")

    print("\n6 - how fast does it fall apart as sensing degrades")
    for noise in (0.01, 0.05, 0.10):
        with torch.no_grad():
            xb = x[:2048] + torch.randn_like(x[:2048]) * noise
            lg = net(xb, adj[:2048]) if grouped else net(xb)
            pn = torch.softmax(lg, -1)[..., 1].reshape(-1).numpy()
        tn = y[:2048].numpy().reshape(-1)
        k = tn >= 0
        cn = confusion(pn[k], tn[k], thr)
        print(f"  noise {noise:.2f}: dangerous rate {cn['dangerous_rate']*100:>6.2f}%  "
              f"recall {cn['recall']*100:>5.1f}%")

    print("\n7 - per class, where does it fail worst")
    cls = x[:, -1, 11:27].argmax(-1).numpy().reshape(-1)[keep]
    for cid in sorted(set(cls.tolist())):
        m = cls == cid
        if m.sum() < 50:
            continue
        cc = confusion(p[m], t[m], thr)
        print(f"  ClassID {cid:>2}: n={int(m.sum()):>7,}  dangerous {cc['dangerous_rate']*100:>6.2f}%  "
              f"recall {cc['recall']*100:>5.1f}%")

    print("\n8 - does the exported file behave the same as the model")
    if args.onnx and args.onnx.exists():
        try:
            import onnxruntime as ort
            sess = ort.InferenceSession(str(args.onnx), providers=["CPUExecutionProvider"])
            feed = {"sequence": x[:64].numpy()}
            if grouped:
                feed["adjacency"] = adj[:64].numpy()
            out = sess.run(None, feed)[0]
            e = np.exp(out - out.max(-1, keepdims=True))
            po = (e / e.sum(-1, keepdims=True))[..., 1].reshape(-1)
            with torch.no_grad():
                lg = net(x[:64], adj[:64]) if grouped else net(x[:64])
                pt = torch.softmax(lg, -1)[..., 1].reshape(-1).numpy()
            gap = float(np.abs(po - pt).max())
            check("exported file agrees with the model", gap < 1e-3, f"largest difference {gap:.2e}")
        except ImportError:
            print("  SKIPPED - onnxruntime not installed (pip install onnxruntime)")
    else:
        print("  SKIPPED - pass --onnx <file> to check the exported model too")

    print("\n" + "=" * 64)
    if fails:
        print(f"NOT READY FOR MATLAB. {len(fails)} check(s) failed: {', '.join(fails)}")
        print("Fix these before exporting. Report the whole output.")
        return 1
    print("READY FOR MATLAB.")
    print(f"Use threshold {thr:.2f}. Below it the planner should treat the prediction as")
    print("unusable and fall back to geometry alone - S3 says never 0.5.")
    print("Report the dangerous error rate on the slide. It is the honest number.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
