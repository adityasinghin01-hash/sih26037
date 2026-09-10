"""Test a trained predictor BEFORE it goes anywhere near MATLAB.

    python3 ml/python/model/evaluate.py --features ~/meteor-data/features --model <checkpoint.pt>

The point is not to prove the model is perfect - it cannot be, because it is predicting what a
human will do next and humans are not consistent. The point is to know exactly how it fails, to
make sure it fails in the safe direction, and to refuse to let a number that means nothing reach
a slide.

THE TWO MISTAKES ARE NOT EQUAL. The direction depends on what class 1 means:

    yield label : high P(yield), but they do not yield  -> DANGEROUS
    assert label: low P(assert), but they assert         -> DANGEROUS

So the operating point is chosen to make the dangerous mistake rare and the harmless one is
accepted. A cautious honest model beats an accurate average one.

FOUR THINGS THIS REFUSES TO REPORT WITHOUT CONTEXT
1. A metric without a confidence interval. Recall 0.33 on 6 positives is 2 out of 6. Printed
   bare it reads like a measurement; it is a coin flip. Every headline number carries a
   bootstrap interval and the interval is what you quote.
2. A model that has not been compared to something trivial. If a single threshold on one feature
   scores the same, the network learned nothing and the honest move is to ship the threshold.
   Section 3 runs three baselines and the model must beat the best of them.
3. A threshold chosen and reported on the same data. That is optimistic by construction, so
   section 5 picks the operating point on one half of the validation clips and reports it on the
   other half. The gap between the two is printed - a large gap means the threshold is fitted to
   noise.
4. Degradation measured in absolute units. Features 10 and 11 are clamped at +/-100 while the box
   geometry lives in [0,1], so one absolute noise level is 11% of one feature's spread and 0.02%
   of another's. Section 8 scales noise per feature. This is M3, so it has to be real.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

TARGET_DANGEROUS_RATE = 0.01     # at most 1% of planner GO calls may be wrong
MIN_POSITIVES = 50               # below this, no metric on the set is trustworthy
N_BOOTSTRAP = 400
LABEL_MODES = {"yield", "assert"}

# S2 feature groups, 1-indexed as in AGENTS.md, for permutation importance
GROUPS = {
    "box geometry (1-6)":   range(0, 6),
    "motion rates (7-9)":   range(6, 9),
    "looming (10-11)":      range(9, 11),
    "class one-hot (12-27)": range(11, 27),
    "ego state (28-31)":    range(27, 31),
}


# ---------------------------------------------------------------- pure numpy, testable

def confusion(score: np.ndarray, truth: np.ndarray, thr: float,
              label_mode: str = "yield") -> dict:
    """At threshold ``thr``, count planner GO decisions and their two kinds of error.

    ``score`` is always the probability of class 1. For a yield-trained dataset, class 1
    means yield and a high score permits GO. For an assert-trained dataset, class 1 means
    assert and a low score permits GO. This distinction changes which tail is safety-critical.
    """
    if label_mode not in LABEL_MODES:
        raise ValueError(f"unknown label_mode {label_mode!r}; expected one of {sorted(LABEL_MODES)}")

    if label_mode == "yield":
        said_go = score >= thr
        safe_truth = truth == 1
    else:
        said_go = score <= thr
        safe_truth = truth == 0

    correct_go = int((said_go & safe_truth).sum())
    dangerous = int((said_go & ~safe_truth).sum())
    harmless = int((~said_go & safe_truth).sum())
    correct_wait = int((~said_go & ~safe_truth).sum())
    n_go = correct_go + dangerous
    return {
        "threshold": float(thr),
        "label_mode": label_mode,
        "dangerous_errors": dangerous, "harmless_errors": harmless,
        "correct_go": correct_go, "correct_wait": correct_wait,
        # of every time we said "go", how often were we wrong? This is the number that matters.
        "dangerous_rate": dangerous / n_go if n_go else 0.0,
        "precision": correct_go / n_go if n_go else 0.0,
        "recall": correct_go / (correct_go + harmless) if (correct_go + harmless) else 0.0,
        "n_go": n_go,
    }


def average_precision(score: np.ndarray, truth: np.ndarray) -> float:
    """Area under the precision-recall curve.

    The right threshold-free summary when the positive class is rare. ROC-AUC is not: it stays
    high on data this imbalanced because the huge true-negative count dominates it.
    A useless model scores the base rate, so ALWAYS read this against the base rate, never alone.
    """
    n_pos = int((truth == 1).sum())
    if n_pos == 0 or len(truth) == 0:
        return float("nan")
    order = np.argsort(-score, kind="stable")
    hits = (truth[order] == 1).astype(np.float64)
    tp = np.cumsum(hits)
    precision = tp / np.arange(1, len(hits) + 1)
    return float((precision * hits).sum() / n_pos)


def expected_calibration_error(p: np.ndarray, truth: np.ndarray, bins: int = 10) -> float:
    """One number for "when it says 80%, does it happen 80% of the time".

    Weighted by bin population, so a wild bin holding three samples cannot dominate - which is
    exactly the failure a bare worst-gap number has.
    """
    edges = np.linspace(0.0, 1.0, bins + 1)
    err = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (p >= lo) & (p < hi if hi < 1.0 else p <= hi)
        if not m.any():
            continue
        err += (m.sum() / len(p)) * abs(p[m].mean() - truth[m].mean())
    return float(err)


def bootstrap_ci(fn, score: np.ndarray, truth: np.ndarray,
                 n: int = N_BOOTSTRAP, seed: int = 0) -> tuple[float, float]:
    """95% interval for any metric, by resampling. Reported because our positive counts are
    small enough that a point estimate on its own is not a measurement."""
    rng = np.random.default_rng(seed)
    n_obs = len(truth)
    vals = []
    for _ in range(n):
        idx = rng.integers(0, n_obs, n_obs)
        v = fn(score[idx], truth[idx])
        if np.isfinite(v):
            vals.append(v)
    if not vals:
        return (float("nan"), float("nan"))
    return (float(np.percentile(vals, 2.5)), float(np.percentile(vals, 97.5)))


def pick_threshold(score: np.ndarray, truth: np.ndarray,
                   target: float = TARGET_DANGEROUS_RATE,
                   label_mode: str = "yield") -> tuple[float, dict]:
    """Return the largest empirical GO set within ``target``, including all score ties.

    Yield ranks high scores first; assert ranks low scores first. If no non-empty GO set meets
    the target, return the observed threshold with the lowest dangerous rate, breaking ties in
    favour of greater coverage.
    """
    if label_mode not in LABEL_MODES:
        raise ValueError(f"unknown label_mode {label_mode!r}; expected one of {sorted(LABEL_MODES)}")
    if len(score) == 0:
        fallback = 1.0 if label_mode == "yield" else 0.0
        return fallback, confusion(score, truth, fallback, label_mode)

    order = np.argsort(-score if label_mode == "yield" else score, kind="stable")
    ranked_score = score[order]
    safe_truth = (truth == 1) if label_mode == "yield" else (truth == 0)
    ranked_safe = safe_truth[order]
    cumulative_safe = np.cumsum(ranked_safe, dtype=np.int64)
    # Only evaluate a threshold after the last member of a tie, so identical probabilities
    # can never be split between GO and WAIT.
    ends = np.r_[np.flatnonzero(np.diff(ranked_score)) + 1, len(ranked_score)]
    correct_go = cumulative_safe[ends - 1]
    dangerous = ends - correct_go
    rates = dangerous / ends
    safe_idx = np.flatnonzero(rates <= target)
    if len(safe_idx):
        chosen = int(safe_idx[-1])       # ends is ascending: greatest safe coverage
    else:
        minimum = rates.min()
        chosen = int(np.flatnonzero(np.isclose(rates, minimum))[-1])
    thr = float(ranked_score[ends[chosen] - 1])
    return thr, confusion(score, truth, thr, label_mode)


def risk_coverage(score: np.ndarray, truth: np.ndarray, label_mode: str,
                  coverage_points: tuple[float, ...] =
                  (0.001, 0.005, 0.01, 0.02, 0.05, 0.10, 0.20, 0.50)) -> list[dict]:
    """Planner risk at fixed approximate coverage points, with score ties kept together."""
    if len(score) == 0:
        return []
    order = np.argsort(-score if label_mode == "yield" else score, kind="stable")
    rows = []
    for coverage in coverage_points:
        rank = min(max(int(np.ceil(coverage * len(score))), 1), len(score))
        thr = float(score[order[rank - 1]])
        c = confusion(score, truth, thr, label_mode)
        c["coverage"] = c["n_go"] / len(score)
        rows.append(c)
    return rows


def calibration(score: np.ndarray, truth: np.ndarray, bins: int = 10) -> list[dict]:
    """When it says 80%, does it happen 80% of the time? An overconfident model is worse than a
    weak one, because the planner trusts the number."""
    out = []
    edges = np.linspace(0.0, 1.0, bins + 1)
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (score >= lo) & (score < hi)
        n = int(m.sum())
        if n == 0:
            continue
        out.append({"bin": f"{lo:.1f}-{hi:.1f}", "n": n,
                    "said": float(score[m].mean()), "actual": float(truth[m].mean())})
    return out


def read_label_mode(features: Path) -> tuple[str, int]:
    """Verify that every feature archive declares the same class-1 label meaning."""
    files = sorted(features.glob("*.npz"))
    if not files:
        raise ValueError(f"no .npz feature files found in {features}")
    counts: dict[str, int] = {}
    missing: list[str] = []
    for path in files:
        with np.load(path) as data:
            if "label_mode" not in data.files:
                missing.append(path.name)
                continue
            mode = str(data["label_mode"].item())
        counts[mode] = counts.get(mode, 0) + 1
    if missing:
        preview = ", ".join(missing[:3])
        suffix = " ..." if len(missing) > 3 else ""
        raise ValueError(f"{len(missing)} feature file(s) have no label_mode: {preview}{suffix}")
    unknown = sorted(set(counts) - LABEL_MODES)
    if unknown:
        raise ValueError(f"unknown label mode(s) in feature files: {unknown}")
    if len(counts) != 1:
        raise ValueError(f"mixed label modes in feature files: {counts}")
    return next(iter(counts)), len(files)


def single_feature_baselines(x_last: np.ndarray, truth: np.ndarray) -> tuple[str, float, int, int]:
    """Best average precision reachable by thresholding ONE raw feature.

    This is the baseline that actually threatens us. If one number scores what the network
    scores, the network is decoration and we should ship the number: it is faster, it needs no
    ONNX, and it cannot fail to import into MATLAB.
    """
    best = ("none", -1.0, -1, 1)
    for j in range(x_last.shape[1]):
        col = x_last[:, j]
        if col.std() < 1e-9:
            continue
        for sign in (1, -1):
            ap = average_precision(sign * col, truth)
            if np.isfinite(ap) and ap > best[1]:
                best = (f"feature {j+1}", float(ap), j, sign)
    return best


# ---------------------------------------------------------------- needs torch

def _predict(net, x, adj, grouped, batch=256):
    import torch
    with torch.no_grad():
        parts = []
        for i in range(0, len(x), batch):
            xb = x[i:i + batch]
            lg = net(xb, adj[i:i + batch]) if grouped else net(xb)
            parts.append(torch.softmax(lg, -1)[..., 1].reshape(-1).numpy())
    return np.concatenate(parts)


def main() -> int:
    import torch
    from model.yield_lstm import YieldNet
    from model.yield_attention import YieldAttentionNet
    from model.train import load

    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True)
    ap.add_argument("--model", type=Path, required=True)
    ap.add_argument("--target", type=float, default=TARGET_DANGEROUS_RATE)
    ap.add_argument("--onnx", type=Path, default=None, help="also check the exported file agrees")
    args = ap.parse_args()

    try:
        label_mode, label_file_count = read_label_mode(args.features)
    except ValueError as exc:
        print(f"ERROR: cannot establish class-1 label meaning: {exc}", file=sys.stderr)
        return 1

    ck = torch.load(args.model, map_location="cpu", weights_only=False)
    kind = ck.get("model", "lstm")
    grouped = kind == "attention"
    net = (YieldAttentionNet(hidden=ck.get("hidden", 64)) if grouped
           else YieldNet(hidden=ck.get("hidden", 64)))
    net.load_state_dict(ck["state_dict"]); net.eval()

    split = json.loads((args.features / "split.json").read_text())
    val_clips = split["val"]
    x, y, adj = load(args.features, val_clips, grouped)

    score_all = _predict(net, x, adj, grouped)
    truth_all = y.numpy().reshape(-1)
    keep = truth_all >= 0
    score, truth = score_all[keep], truth_all[keep]
    n_pos = int(truth.sum())
    base_rate = truth.mean() if len(truth) else 0.0

    fails: list[str] = []
    warns: list[str] = []

    def check(name, ok, detail=""):
        print(f"  {'PASS' if ok else 'FAIL'}  {name}{'  ' + detail if detail else ''}")
        if not ok:
            fails.append(name)

    def warn(msg):
        print(f"  WARN  {msg}")
        warns.append(msg)

    print(f"model={kind}  validation clips={len(val_clips)}  samples={len(truth):,}  "
          f"positives={n_pos:,}  base rate={base_rate*100:.3f}%\n")
    print(f"label_mode={label_mode} verified across {label_file_count:,} feature files")
    if label_mode == "assert":
        print("  class 1 score q = P(assert)")
        print("  GO = q <= threshold")
        print("  DANGEROUS = GO while truth == assert")
        print("  dangerous rate = count(GO and assert) / count(GO)")
        print("  S3 boundary: PYield = 1 - q\n")
    else:
        print("  class 1 score q = P(yield)")
        print("  GO = q >= threshold")
        print("  DANGEROUS = GO while truth == no-yield")
        print("  dangerous rate = count(GO and no-yield) / count(GO)\n")

    print("1 - outputs are usable numbers")
    check("all finite", bool(np.isfinite(score).all()))
    check("all within 0 and 1", bool((score >= 0).all() and (score <= 1).all()))
    check("not a constant", float(score.std()) > 1e-4, f"std={score.std():.5f}")
    check("uses more than one value", len(np.unique(np.round(score, 3))) > 5,
          f"{len(np.unique(np.round(score,3)))} distinct")

    print("\n2 - is there enough to measure")
    check("validation set contains positives", n_pos > 0)
    if n_pos == 0:
        print("\n  Cannot evaluate: no positive examples. Re-split with another seed.")
        return 1
    if n_pos < MIN_POSITIVES:
        warn(f"only {n_pos} positives. Below {MIN_POSITIVES} no number here is trustworthy - "
             f"every interval below will be wide, and that is the honest signal, not a defect.")

    print("\n3 - does it beat something trivial")
    ap_model = average_precision(score, truth)
    lo, hi = bootstrap_ci(average_precision, score, truth)
    print(f"  model average precision      {ap_model:.4f}   95% CI [{lo:.4f}, {hi:.4f}]")
    print(f"  always-say-no / base rate    {base_rate:.4f}   <- a useless model scores this")
    rng = np.random.default_rng(0)
    ap_rand = average_precision(rng.random(len(truth)), truth)
    print(f"  random scores                {ap_rand:.4f}")
    x_last = x.reshape(-1, x.shape[-2], x.shape[-1])[:, -1, :].numpy()[keep]
    fname, ap_feat, _, sign = single_feature_baselines(x_last, truth)
    print(f"  best SINGLE feature          {ap_feat:.4f}   ({fname}, sign {sign:+d})")
    check("beats the base rate", ap_model > base_rate,
          f"{ap_model:.4f} vs {base_rate:.4f}")
    check("beats the best single feature", ap_model > ap_feat,
          f"{ap_model:.4f} vs {ap_feat:.4f}")
    if lo <= base_rate:
        warn("the confidence interval includes the base rate - on this much data we cannot say "
             "the model beats guessing, whatever the point estimate looks like.")

    print("\n4 - the operating point (chosen and reported on the SAME data - optimistic)")
    thr, c = pick_threshold(score, truth, args.target, label_mode)
    comparator = ">=" if label_mode == "yield" else "<="
    print(f"  chosen GO rule: class-1 score {comparator} {thr:.8f}")
    print(f"  says GO {c['n_go']:,} times; of those {c['dangerous_errors']:,} are wrong")
    print(f"  coverage             : {100*c['n_go']/max(len(truth), 1):.3f}%")
    print(f"  DANGEROUS error rate : {c['dangerous_rate']*100:.2f}%   (target <= {args.target*100:.1f}%)")
    print(f"  harmless errors      : {c['harmless_errors']:,}  (waited when we could have gone)")
    rec_lo, rec_hi = bootstrap_ci(
        lambda s, u: confusion(s, u, thr, label_mode)["recall"], score, truth)
    dan_lo, dan_hi = bootstrap_ci(
        lambda s, u: confusion(s, u, thr, label_mode)["dangerous_rate"], score, truth)
    print(f"  recall         {c['recall']*100:>6.2f}%  95% CI [{rec_lo*100:.2f}%, {rec_hi*100:.2f}%]")
    print(f"  dangerous rate {c['dangerous_rate']*100:>6.2f}%  95% CI [{dan_lo*100:.2f}%, {dan_hi*100:.2f}%]")
    check("dangerous error rate within target", c["dangerous_rate"] <= args.target,
          f"{c['dangerous_rate']*100:.2f}%")
    check("still useful - says GO sometimes", c["n_go"] > 0)

    print("\n  risk versus coverage (same validation data - descriptive only)")
    print("  coverage     n_go    dangerous    risk")
    for row in risk_coverage(score, truth, label_mode):
        print(f"  {row['coverage']*100:>7.3f}%  {row['n_go']:>8,}  "
              f"{row['dangerous_errors']:>9,}  {row['dangerous_rate']*100:>6.3f}%")

    print("\n5 - the honest operating point (threshold from one half, reported on the other)")
    half = max(1, len(val_clips) // 2)
    a_clips, b_clips = val_clips[:half], val_clips[half:]
    if not b_clips:
        warn("too few validation clips to split - section 4's number is the only one available "
             "and it is optimistic.")
    else:
        xa, ya, aa = load(args.features, a_clips, grouped)
        xb, yb, ab = load(args.features, b_clips, grouped)
        pa, ta = _predict(net, xa, aa, grouped), ya.numpy().reshape(-1)
        pb, tb = _predict(net, xb, ab, grouped), yb.numpy().reshape(-1)
        ka, kb = ta >= 0, tb >= 0
        pa, ta, pb, tb = pa[ka], ta[ka], pb[kb], tb[kb]
        if ta.sum() == 0 or tb.sum() == 0:
            warn(f"one half has no positives ({int(ta.sum())} / {int(tb.sum())}) - cannot "
                 f"separate threshold choice from reporting. Section 4 stands, optimistically.")
        else:
            thr_a, _ = pick_threshold(pa, ta, args.target, label_mode)
            cb = confusion(pb, tb, thr_a, label_mode)
            print(f"  GO score {comparator} {thr_a:.8f} chosen on {len(a_clips)} clips, "
                  f"reported on {len(b_clips)}")
            print(f"  n_go {cb['n_go']:,} of {len(tb):,}  coverage {100*cb['n_go']/len(tb):.3f}%")
            print(f"  dangerous rate {cb['dangerous_rate']*100:>6.2f}%   recall {cb['recall']*100:>5.1f}%")
            drift = abs(cb["dangerous_rate"] - c["dangerous_rate"])
            print(f"  gap vs section 4: {drift*100:.2f} points")
            if drift > 0.10:
                warn("the operating point moves a lot between halves - it is fitted to noise, "
                     "not to a property of the data.")

    print("\n6 - is it honest about its own confidence")
    rows = calibration(score, truth)
    worst = 0.0
    for r in rows:
        worst = max(worst, abs(r["said"] - r["actual"]))
        print(f"  {r['bin']}  n={r['n']:>7,}  said {r['said']*100:>5.1f}%  actually {r['actual']*100:>5.1f}%")
    ece = expected_calibration_error(score, truth)
    print(f"  expected calibration error (population weighted): {ece:.4f}")
    check("never overconfident by more than 20 points", worst <= 0.20, f"worst gap {worst*100:.1f}")
    check("expected calibration error under 0.10", ece <= 0.10, f"{ece:.4f}")

    print("\n7 - which features does it actually use (permutation importance)")
    print("  shuffle a group across samples; a large drop means the model depends on it")
    rng = np.random.default_rng(1)
    for gname, cols in GROUPS.items():
        xs = x.clone()
        idx = rng.permutation(len(xs))
        cols = list(cols)
        xs[..., cols] = xs[idx][..., cols]
        ap_s = average_precision(_predict(net, xs, adj, grouped)[keep], truth)
        drop = ap_model - ap_s
        flag = "" if abs(drop) > 0.01 * max(ap_model, 1e-9) else "   <- ignored"
        print(f"  {gname:<24} AP {ap_s:.4f}   drop {drop:+.4f}{flag}")

    print("\n8 - how fast does it fall apart as sensing degrades (M3)")
    print("  noise is a FRACTION OF EACH FEATURE'S OWN SPREAD, not an absolute value -")
    print("  features 10 and 11 are clamped at +/-100 while geometry lives in [0,1].")
    sd = torch.as_tensor(x.reshape(-1, x.shape[-1]).std(0).clamp_min(1e-6))
    for frac in (0.05, 0.10, 0.25, 0.50):
        xs = x + torch.randn_like(x) * sd * frac
        pn = _predict(net, xs, adj, grouped)[keep]
        cn = confusion(pn, truth, thr, label_mode)
        print(f"  noise {frac*100:>3.0f}% of std: dangerous {cn['dangerous_rate']*100:>6.2f}%  "
              f"recall {cn['recall']*100:>5.1f}%  AP {average_precision(pn, truth):.4f}")

    print("\n9 - per class, where does it fail worst")
    cls = x_last[:, 11:27].argmax(-1)
    for cid in sorted(set(cls.tolist())):
        m = cls == cid
        if m.sum() < 50:
            continue
        cc = confusion(score[m], truth[m], thr, label_mode)
        print(f"  ClassID {cid:>2}: n={int(m.sum()):>7,}  pos={int(truth[m].sum()):>4}  "
              f"dangerous {cc['dangerous_rate']*100:>6.2f}%  recall {cc['recall']*100:>5.1f}%")

    print("\n10 - is the score driven by a single clip")
    per_clip = []
    for cname in val_clips:
        xc, yc, ac = load(args.features, [cname], grouped)
        tc = yc.numpy().reshape(-1); kc = tc >= 0
        tc = tc[kc]
        if tc.sum() == 0:
            continue
        per_clip.append((cname, int(tc.sum()),
                         average_precision(_predict(net, xc, ac, grouped)[kc], tc)))
    if not per_clip:
        warn("no validation clip contains a positive - nothing can be said per clip.")
    else:
        for cname, npc, apc in sorted(per_clip, key=lambda r: -r[2]):
            print(f"  {cname[:34]:<34} pos={npc:>4}  AP {apc:.4f}")
        share = max(r[1] for r in per_clip) / max(sum(r[1] for r in per_clip), 1)
        print(f"  clips carrying a positive: {len(per_clip)} of {len(val_clips)}; "
              f"largest single clip holds {share*100:.0f}% of them")
        if share > 0.5:
            warn("more than half the positives come from ONE clip. The score describes that "
                 "clip, not Indian traffic.")

    print("\n11 - does the exported file behave the same as the model")
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
            pt = _predict(net, x[:64], adj[:64] if grouped else None, grouped)
            gap = float(np.abs(po - pt).max())
            check("exported file agrees with the model", gap < 1e-3, f"largest difference {gap:.2e}")
        except ImportError:
            print("  SKIPPED - onnxruntime not installed (pip install onnxruntime)")
    else:
        print("  SKIPPED - pass --onnx <file> to check the exported model too")

    print("\n" + "=" * 68)
    if warns:
        print(f"{len(warns)} warning(s) - these do not block, but they change what the numbers mean:")
        for w in warns:
            print(f"  - {w}")
        print()
    if fails:
        print(f"NOT READY FOR MATLAB. {len(fails)} check(s) failed: {', '.join(fails)}")
        print("Fix these before exporting. Report the whole output.")
        return 1
    print("READY FOR MATLAB.")
    print(f"Use the tested GO rule: class-1 score {comparator} {thr:.8f}.")
    if label_mode == "assert":
        print("At the S3 boundary compute PYield = 1 - P(assert) exactly once.")
    print("Outside the validated gate, emit Valid=false and fall back to geometry alone.")
    print("Quote the CONFIDENCE INTERVALS on the slide, not the point estimates, and quote the")
    print("dangerous error rate. Those are the honest numbers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
