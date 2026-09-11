"""Fit Platt scaling and establish the safety gate on calibration clips only.

Step 94 implementation:
1. Correct weighted cross-entropy probability using recorded pos_weight.
2. Fit Platt scaling (A, B) using Platt's smoothed targets.
3. Generate and save before/after reliability diagrams using quantile bins.
4. Compare raw, pos_weight-corrected, Platt, and isotonic calibration.
5. Select operating threshold satisfying 95% upper confidence bound <= 1.0% risk.
6. Freeze calibration gate configuration in calibration_gate.json.

Usage:
    python ml/python/model/calibrate.py --features C:/Users/admin/meteor-data/features --model C:/Users/admin/meteor-data/features/yield_lstm.pt
"""
from __future__ import annotations

import argparse
from datetime import datetime
import json
from pathlib import Path
import sys

import matplotlib
matplotlib.use("Agg")  # Headless backend for server/CLI
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import minimize
from sklearn.isotonic import IsotonicRegression
import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.yield_lstm import YieldNet
from model.yield_attention import YieldAttentionNet
from model.train import load
from model.evaluate import read_label_mode, expected_calibration_error


def smooth_targets(y: np.ndarray) -> tuple[np.ndarray, float, float]:
    """Compute Platt's smoothed binary targets:
    t+ = (N+ + 1) / (N+ + 2)
    t- = 1 / (N- + 2)
    """
    n_pos = int((y == 1).sum())
    n_neg = int((y == 0).sum())
    t_pos = (n_pos + 1.0) / (n_pos + 2.0)
    t_neg = 1.0 / (n_neg + 2.0)
    y_smooth = np.where(y == 1, t_pos, t_neg).astype(np.float64)
    return y_smooth, t_pos, t_neg


def fit_platt(raw_logits: np.ndarray, y_smooth: np.ndarray) -> tuple[float, float]:
    """Fit Platt scaling parameters (A, B) minimizing binary cross-entropy:
    P(y=1 | f) = 1 / (1 + exp(A * f + B))
    where f = logit_1 - logit_0.
    """
    f = raw_logits.astype(np.float64)

    def objective(params):
        A, B = params
        u = A * f + B
        loss = np.sum(np.logaddexp(0, u) - (1.0 - y_smooth) * u)
        p_act = 1.0 / (1.0 + np.exp(-np.clip(u, -50, 50)))
        grad_u = p_act - (1.0 - y_smooth)
        grad_A = np.sum(grad_u * f)
        grad_B = np.sum(grad_u)
        return loss, np.array([grad_A, grad_B])

    res = minimize(objective, x0=[-1.0, 0.0], jac=True, method="L-BFGS-B")
    return float(res.x[0]), float(res.x[1])


def apply_platt(raw_logits: np.ndarray, A: float, B: float) -> np.ndarray:
    """Compute Platt calibrated probability:
    P = 1 / (1 + exp(A * f + B))
    """
    u = A * raw_logits + B
    return 1.0 / (1.0 + np.exp(np.clip(u, -50, 50)))


def correct_pos_weight(raw_logits: np.ndarray, pos_weight: float) -> tuple[np.ndarray, np.ndarray]:
    """Remove the artificial Bayes shift introduced by training with pos_weight:
    f_unweighted = logit_diff - ln(pos_weight)
    p_unweighted = sigmoid(f_unweighted)
    """
    shift = np.log(max(pos_weight, 1e-6))
    f_corr = raw_logits - shift
    p_corr = 1.0 / (1.0 + np.exp(-np.clip(f_corr, -50, 50)))
    return f_corr, p_corr


def quantile_reliability(scores: np.ndarray, labels: np.ndarray, n_bins: int = 10) -> list[dict]:
    """Compute quantile-binned reliability points (equal sample counts per bin)."""
    quantiles = np.linspace(0.0, 1.0, n_bins + 1)
    bin_edges = np.quantile(scores, quantiles)
    # Ensure strictly monotonic bin boundaries to prevent empty zero-width bins
    bin_edges[0] = 0.0
    bin_edges[-1] = 1.0

    rows = []
    n_total = len(scores)
    for i in range(n_bins):
        lo, hi = bin_edges[i], bin_edges[i + 1]
        m = (scores >= lo) & (scores < hi if i < n_bins - 1 else scores <= hi)
        n_bin = int(m.sum())
        if n_bin == 0:
            continue
        p_mean = float(scores[m].mean())
        y_mean = float(labels[m].mean())
        rows.append({
            "bin": i + 1,
            "range": f"[{lo:.4f}, {hi:.4f}]",
            "n": n_bin,
            "pct": n_bin / n_total * 100,
            "predicted": p_mean,
            "actual": y_mean,
            "gap": abs(p_mean - y_mean),
        })
    return rows


def plot_reliability_diagram(
    bins: list[dict],
    title: str,
    out_path: Path,
    ece: float,
    worst_gap: float,
) -> None:
    """Generate and save a publication-quality reliability diagram."""
    out_path.parent.mkdir(parents=True, exist_ok=True)

    pred = [b["predicted"] for b in bins]
    actual = [b["actual"] for b in bins]
    sample_pct = [b["pct"] for b in bins]

    fig, (ax1, ax2) = plt.subplots(
        2, 1, figsize=(7, 8), gridspec_kw={"height_ratios": [3, 1]}, sharex=True
    )

    # Main calibration curve
    ax1.plot([0, 1], [0, 1], "k--", label="Perfect Calibration (Identity)")
    ax1.plot(pred, actual, "s-", color="#1f77b4", linewidth=2, markersize=7, label="Model (Quantile Bins)")
    ax1.fill_between(pred, actual, pred, color="#1f77b4", alpha=0.15, label="Calibration Gap")
    ax1.set_ylabel("Empirical True Fraction P(assert)", fontsize=11)
    ax1.set_title(f"{title}\nECE: {ece:.4f} | Worst Gap: {worst_gap*100:.1f} pts", fontsize=12, fontweight="bold")
    ax1.grid(True, linestyle=":", alpha=0.6)
    ax1.legend(loc="upper left", frameon=True)
    ax1.set_ylim(-0.02, 1.02)
    ax1.set_xlim(-0.02, 1.02)

    # Bin sample distribution bar chart
    bin_centers = pred
    ax2.bar(bin_centers, sample_pct, width=0.04, color="#aec7e8", edgecolor="#1f77b4", alpha=0.8)
    ax2.set_xlabel("Mean Stated Probability P(assert)", fontsize=11)
    ax2.set_ylabel("Samples (%)", fontsize=10)
    ax2.set_ylim(0, max(sample_pct) * 1.3 if sample_pct else 10)
    ax2.grid(True, linestyle=":", alpha=0.4)

    plt.tight_layout()
    plt.savefig(out_path, dpi=200)
    plt.close()


def evaluate_threshold_risk(
    scores: np.ndarray, labels: np.ndarray, thr: float, label_mode: str = "assert"
) -> dict:
    """Evaluate GO decision confusion matrix at threshold."""
    if label_mode == "assert":
        said_go = scores <= thr
        safe_truth = labels == 0
    else:
        said_go = scores >= thr
        safe_truth = labels == 1

    correct_go = int((said_go & safe_truth).sum())
    dangerous = int((said_go & ~safe_truth).sum())
    harmless = int((~said_go & safe_truth).sum())
    correct_wait = int((~said_go & ~safe_truth).sum())
    n_go = correct_go + dangerous

    return {
        "threshold": float(thr),
        "n_go": n_go,
        "dangerous": dangerous,
        "harmless": harmless,
        "coverage": n_go / max(len(labels), 1),
        "dangerous_rate": dangerous / max(n_go, 1) if n_go else 0.0,
        "recall": correct_go / max(correct_go + harmless, 1),
    }


def session_cluster_bootstrap(
    session_slices: list[tuple[str, slice]],
    scores: np.ndarray,
    labels: np.ndarray,
    thr: float,
    n_bootstrap: int = 400,
    seed: int = 42,
) -> tuple[float, float, float]:
    """Compute 95% confidence bounds by resampling entire recording sessions."""
    rng = np.random.default_rng(seed)
    n_sess = len(session_slices)
    session_scores = [scores[sl] for _, sl in session_slices]
    session_labels = [labels[sl] for _, sl in session_slices]

    rates = []
    for _ in range(n_bootstrap):
        sampled_idx = rng.integers(0, n_sess, n_sess)
        b_scores = np.concatenate([session_scores[i] for i in sampled_idx])
        b_labels = np.concatenate([session_labels[i] for i in sampled_idx])
        r = evaluate_threshold_risk(b_scores, b_labels, thr)
        if r["n_go"] > 0:
            rates.append(r["dangerous_rate"])

    if not rates:
        return 0.0, 0.0, 1.0
    return float(np.mean(rates)), float(np.percentile(rates, 2.5)), float(np.percentile(rates, 97.5))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True)
    ap.add_argument("--model", type=Path, required=True)
    ap.add_argument("--split", type=Path, default=None)
    ap.add_argument("--target-risk", type=float, default=0.01)
    ap.add_argument("--plots-dir", type=Path, default=Path("results/plots"))
    ap.add_argument("--out-config", type=Path, default=None)
    args = ap.parse_args()

    split_file = args.split or (args.features / "split.json")
    if not split_file.exists():
        print(f"ERROR: split manifest missing: {split_file}", file=sys.stderr)
        return 1

    split = json.loads(split_file.read_text())
    cal_clips = split.get("calibration", split.get("val", []))
    if not cal_clips:
        print("ERROR: split manifest has no calibration partition", file=sys.stderr)
        return 1

    try:
        label_mode, label_file_count = read_label_mode(args.features)
    except ValueError as exc:
        print(f"ERROR: label mode verification failed: {exc}", file=sys.stderr)
        return 1

    ck = torch.load(args.model, map_location="cpu", weights_only=False)
    kind = ck.get("model", "lstm")
    pos_weight = float(ck.get("pos_weight", 1.0))
    grouped = kind == "attention"

    net = (YieldAttentionNet(hidden=ck.get("hidden", 64)) if grouped
           else YieldNet(hidden=ck.get("hidden", 64)))
    if "feat_mean" in ck and "feat_std" in ck:
        net.set_normaliser(np.array(ck["feat_mean"]), np.array(ck["feat_std"]))
    net.load_state_dict(ck["state_dict"])
    net.eval()

    device = "cuda" if torch.cuda.is_available() else "cpu"
    net = net.to(device)

    print(f"Loaded {kind.upper()} model ({device}) | Training pos_weight={pos_weight:.4f}")
    print(f"Calibration clips: {len(cal_clips):,} | Verified label_mode: {label_mode}\n")

    # Load calibration data and record session slices
    print("Loading calibration feature vectors...")
    x, y, adj = load(args.features, cal_clips, grouped)
    truth_all = y.numpy().reshape(-1)
    keep = truth_all >= 0
    labels = truth_all[keep]

    # Map session slices for cluster bootstrap
    clip_slices = []
    idx = 0
    for cname in cal_clips:
        d = np.load(args.features / cname)
        k_len = int((d["y"] >= 0).sum())
        clip_slices.append((cname, slice(idx, idx + k_len)))
        idx += k_len

    # Group clip slices by recording session (based on timestamp gap <= 30 min)
    session_slices = []
    curr_slice_clips = []
    curr_start = 0
    from meteor.split import parse_clip_timestamp
    parsed_clips = [(c, parse_clip_timestamp(c)) for c in cal_clips]
    
    last_dt = None
    curr_len = 0
    for i, (cname, dt) in enumerate(parsed_clips):
        sl_len = clip_slices[i][1].stop - clip_slices[i][1].start
        if last_dt is None or (dt and last_dt and 0 <= (dt - last_dt).total_seconds() <= 1800):
            curr_len += sl_len
            last_dt = dt or last_dt
        else:
            session_slices.append((f"session_{len(session_slices)+1}", slice(curr_start, curr_start + curr_len)))
            curr_start += curr_len
            curr_len = sl_len
            last_dt = dt
    if curr_len > 0:
        session_slices.append((f"session_{len(session_slices)+1}", slice(curr_start, curr_start + curr_len)))

    print(f"Calibration set: {len(labels):,} samples | {int((labels==1).sum()):,} assert positives | {len(session_slices)} sessions")

    # Forward pass
    print("Executing forward pass for raw logits...")
    batch = 512
    raw_diffs = []
    with torch.no_grad():
        for i in range(0, len(x), batch):
            xb = x[i:i + batch].to(device)
            lg = net(xb, adj[i:i + batch].to(device)) if grouped else net(xb)
            # Logit difference: logit(1) - logit(0) across classes dimension
            diff = (lg[..., 1] - lg[..., 0]).cpu().numpy().reshape(-1)
            raw_diffs.append(diff)

    raw_diffs = np.concatenate(raw_diffs)[keep]
    raw_scores = 1.0 / (1.0 + np.exp(-raw_diffs))

    # 1. Correct pos_weight
    f_unweighted, p_unweighted = correct_pos_weight(raw_diffs, pos_weight)

    # 2. Fit Platt scaling on smoothed targets
    y_smooth, t_pos, t_neg = smooth_targets(labels)
    A_platt, B_platt = fit_platt(raw_diffs, y_smooth)
    p_platt = apply_platt(raw_diffs, A_platt, B_platt)

    # 3. Fit Isotonic regression
    iso = IsotonicRegression(out_of_bounds="clip")
    iso.fit(raw_scores, labels)
    p_iso = iso.predict(raw_scores)

    # 4. Measure calibration metrics for all 4 variants
    def measure_calibration(name: str, probs: np.ndarray) -> dict:
        q_bins = quantile_reliability(probs, labels, n_bins=10)
        ece = expected_calibration_error(probs, labels, bins=10)
        worst_gap = max(b["gap"] for b in q_bins) if q_bins else 0.0
        return {"name": name, "ece": ece, "worst_gap": worst_gap, "bins": q_bins}

    m_raw = measure_calibration("Raw Uncalibrated", raw_scores)
    m_unw = measure_calibration("Pos-Weight Corrected", p_unweighted)
    m_platt = measure_calibration("Platt Scaled", p_platt)
    m_iso = measure_calibration("Isotonic", p_iso)

    print("\n" + "=" * 76)
    print("STEP 94: CALIBRATION COMPARISON ON CALIBRATION CLIPS ONLY")
    print("=" * 76)
    print(f"{'Method':<24} | {'ECE (Pop-Weighted)':>18} | {'Worst Bin Gap':>15} | {'Stated StDev':>12}")
    print("-" * 76)
    for m, p in [(m_raw, raw_scores), (m_unw, p_unweighted), (m_platt, p_platt), (m_iso, p_iso)]:
        print(f"{m['name']:<24} | {m['ece']:>18.4f} | {m['worst_gap']*100:>13.1f}% | {p.std():>12.4f}")
    print("=" * 76)

    # 5. Generate and save before & after reliability diagrams
    args.plots_dir.mkdir(parents=True, exist_ok=True)
    before_plot = args.plots_dir / f"reliability_{kind}_before.png"
    after_plot = args.plots_dir / f"reliability_{kind}_after.png"

    plot_reliability_diagram(m_raw["bins"], f"Raw Uncalibrated Model ({kind.upper()})", before_plot, m_raw["ece"], m_raw["worst_gap"])
    plot_reliability_diagram(m_platt["bins"], f"Platt-Calibrated Model ({kind.upper()})", after_plot, m_platt["ece"], m_platt["worst_gap"])
    print(f"\nSaved before diagram: {before_plot}")
    print(f"Saved after diagram : {after_plot}")

    # 6. Build risk vs coverage curve on Platt-calibrated probabilities
    print("\nEvaluating risk-versus-coverage curve & cluster-bootstrap bounds...")
    coverage_points = [0.001, 0.005, 0.01, 0.02, 0.05, 0.10, 0.15, 0.20, 0.30, 0.50]
    sorted_order = np.argsort(p_platt)
    ranked_p = p_platt[sorted_order]

    print("-" * 84)
    print(f"{'Target Cov':>10} | {'Thr P(assert)':>14} | {'Coverage':>10} | {'n_go':>8} | {'Dang Rate':>10} | {'95% Cluster CI':>18}")
    print("-" * 84)

    safe_thresholds = []
    for cp in coverage_points:
        rank = min(max(int(np.ceil(cp * len(ranked_p))), 1), len(ranked_p))
        thr = float(ranked_p[rank - 1])
        res = evaluate_threshold_risk(p_platt, labels, thr)
        mean_r, lo_r, hi_r = session_cluster_bootstrap(session_slices, p_platt, labels, thr)
        flag = " [SAFE]" if hi_r <= args.target_risk else ""
        print(f"{cp*100:>9.1f}% | {thr:>14.8f} | {res['coverage']*100:>9.3f}% | {res['n_go']:>8,d} | {res['dangerous_rate']*100:>9.3f}% | [{lo_r*100:5.2f}%, {hi_r*100:5.2f}%]{flag}")
        if hi_r <= args.target_risk:
            safe_thresholds.append((thr, res, hi_r))

    # 7. Select operating threshold
    if safe_thresholds:
        chosen_thr, chosen_res, upper_bound = safe_thresholds[-1]
        gate_status = "PASS"
        valid_gate = True
        print(f"\nSelected Safe Operating Threshold: P(assert) <= {chosen_thr:.8f}")
        print(f"  Coverage: {chosen_res['coverage']*100:.3f}% ({chosen_res['n_go']:,} samples)")
        print(f"  Dangerous Rate Point Estimate: {chosen_res['dangerous_rate']*100:.3f}% (Upper 95% Bound: {upper_bound*100:.3f}%)")
    else:
        # Fallback to strictest non-zero point
        chosen_thr = float(ranked_p[0])
        chosen_res = evaluate_threshold_risk(p_platt, labels, chosen_thr)
        _, _, upper_bound = session_cluster_bootstrap(session_slices, p_platt, labels, chosen_thr)
        gate_status = "FAIL (Target <= 1.0% not met by upper confidence bound)"
        valid_gate = False
        print(f"\nWARNING: No threshold satisfies upper confidence bound <= {args.target_risk*100:.1f}%.")
        print(f"Enforcing safety rule: Gate status = {gate_status}. Model must emit Valid=false.")

    # 8. Save frozen calibration config
    default_cfg = args.features / ("calibration_gate.json" if kind == "lstm" else f"calibration_gate_{kind}.json")
    out_cfg = args.out_config or default_cfg
    calibration_config = {
        "timestamp": datetime.now().isoformat(),
        "model_file": str(args.model),
        "model_kind": kind,
        "calibration_clips": len(cal_clips),
        "calibration_samples": len(labels),
        "training_pos_weight": pos_weight,
        "method": "platt_scaling",
        "platt_A": A_platt,
        "platt_B": B_platt,
        "platt_formula": "P(assert) = 1.0 / (1.0 + exp(A * raw_logit_diff + B))",
        "ece_before": m_raw["ece"],
        "ece_after": m_platt["ece"],
        "worst_gap_before": m_raw["worst_gap"],
        "worst_gap_after": m_platt["worst_gap"],
        "chosen_threshold": chosen_thr,
        "gate_upper_bound_95": upper_bound,
        "calibration_coverage": chosen_res["coverage"],
        "calibration_n_go": chosen_res["n_go"],
        "gate_passed": valid_gate,
        "abstention_rules": {
            "require_history_steps": 20,
            "max_tau_magnitude": 100.0,
            "max_lateral_closure_magnitude": 100.0,
            "unsupported_classes_emit_valid_false": [0, 9, 11, 12, 13, 15],
            "confidence_upper_bound_exceeded": not valid_gate,
        },
        "diagrams": {
            "before_png": str(before_plot),
            "after_png": str(after_plot),
        },
    }

    out_cfg.write_text(json.dumps(calibration_config, indent=2))
    print(f"\nFrozen calibration gate config written to: {out_cfg}")

    return 0 if valid_gate else 1


if __name__ == "__main__":
    raise SystemExit(main())
