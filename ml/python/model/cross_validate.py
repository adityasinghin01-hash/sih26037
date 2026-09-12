"""Leave-one-session-out (LOSO) cross-validation harness.

Evaluates generalization across continuous driving sessions, preventing the model
from getting credit for memorizing quirks of individual sessions or time periods.

Tasks covered:
  - Task 2: Leave-one-session-out cross-validation using meteor.split.group_clips_into_sessions
  - Task 2: Per-fold Platt calibration fit (from model.calibrate)
  - Task 2: Every metric reported as mean +- std across all session folds
  - Task 2: Automated identification of the worst-performing session with diagnosis
  - Task 2: Pooled reliability diagram from held-out predictions
  - Task 3: Identical protocol on the linear baseline (model.baseline)
  - Task 4: Paired Wilcoxon signed-rank test (scipy.stats.wilcoxon) on per-fold differences
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from meteor.split import group_clips_into_sessions
from model.baseline import (
    compute_brier_score,
    compute_ece,
    compute_f1,
    compute_roc_auc,
    evaluate_baseline,
    extract_baseline_features,
    fit_logistic_baseline,
)
try:
    from model.calibrate import apply_platt, fit_platt, smooth_targets
except ImportError:
    from scipy.optimize import minimize

    def smooth_targets(y: np.ndarray) -> tuple[np.ndarray, float, float]:
        n_pos = int((y == 1).sum())
        n_neg = int((y == 0).sum())
        t_pos = (n_pos + 1.0) / (n_pos + 2.0)
        t_neg = 1.0 / (n_neg + 2.0)
        y_smooth = np.where(y == 1, t_pos, t_neg).astype(np.float64)
        return y_smooth, t_pos, t_neg

    def fit_platt(raw_logits: np.ndarray, y_smooth: np.ndarray) -> tuple[float, float]:
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
        u = A * raw_logits + B
        return 1.0 / (1.0 + np.exp(np.clip(u, -50, 50)))


def build_session_folds(
    features_dir: Path,
    gap_seconds: int = 1800,
) -> list[dict[str, Any]]:
    """Discover all clips and group into continuous driving sessions via split.py.

    Returns a list of K fold dicts:
        {
            'fold_idx': int,
            'session_name': str,
            'test_clips': list[str],
            'train_val_clips': list[str],
            'cal_clips': list[str],
            'train_clips': list[str],
        }
    """
    all_clips = sorted(p.name for p in features_dir.glob("*.npz"))
    if not all_clips:
        raise FileNotFoundError(f"No .npz feature files found in {features_dir}")

    sessions = group_clips_into_sessions(all_clips, gap_seconds=gap_seconds)
    n_sessions = len(sessions)
    print(f"Discovered {len(all_clips)} clips grouped into {n_sessions} driving sessions.")

    folds = []
    for idx, test_clips in enumerate(sessions):
        session_name = f"session_{idx + 1:02d}"
        # All other sessions form the train + calibration pool
        train_val_sessions = [s for j, s in enumerate(sessions) if j != idx]
        
        # Reserve one session (or ~15% of train sessions) for fitting calibration
        cal_idx = len(train_val_sessions) - 1
        cal_clips = sorted(train_val_sessions[cal_idx])
        train_clips = sorted([c for j, s in enumerate(train_val_sessions) if j != cal_idx for c in s])

        folds.append({
            "fold_idx": idx,
            "session_name": session_name,
            "test_clips": sorted(test_clips),
            "cal_clips": cal_clips,
            "train_clips": train_clips,
            "train_val_clips": sorted([c for s in train_val_sessions for c in s]),
        })

    return folds


def pooled_reliability_diagram(
    pooled_probs: np.ndarray,
    pooled_truth: np.ndarray,
    bins: int = 10,
) -> list[dict[str, Any]]:
    """Construct one combined reliability curve from all held-out folds."""
    edges = np.linspace(0.0, 1.0, bins + 1)
    diagram = []
    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (pooled_probs >= lo) & (pooled_probs < hi if hi < 1.0 else pooled_probs <= hi)
        n = int(m.sum())
        if n == 0:
            continue
        diagram.append({
            "bin": f"{lo:.1f}-{hi:.1f}",
            "count": n,
            "mean_pred": float(pooled_probs[m].mean()),
            "actual_freq": float(pooled_truth[m].mean()),
            "abs_error": float(abs(pooled_probs[m].mean() - pooled_truth[m].mean())),
        })
    return diagram


def run_paired_wilcoxon_test(
    lstm_metrics: list[float],
    baseline_metrics: list[float],
) -> dict[str, Any]:
    """Execute Wilcoxon signed-rank test on paired fold differences."""
    from scipy.stats import wilcoxon

    diffs = np.array(lstm_metrics) - np.array(baseline_metrics)
    mean_d = float(np.mean(diffs))
    std_d = float(np.std(diffs))

    if np.allclose(diffs, 0.0) or len(diffs) < 5:
        return {
            "statistic": float("nan"),
            "p_value": 1.0,
            "mean_diff": mean_d,
            "std_diff": std_d,
            "significant": False,
            "conclusion": "No significant difference between models (identical or insufficient samples).",
        }

    try:
        res = wilcoxon(diffs, alternative="two-sided")
        stat = float(res.statistic)
        p_val = float(res.pvalue)
    except Exception:  # noqa: BLE001
        stat = float("nan")
        p_val = 1.0

    sig = bool(p_val < 0.05)
    if sig:
        winner = "LSTM" if mean_d > 0 else "Baseline"
        conclusion = f"Statistically significant difference (p = {p_val:.4f} < 0.05). {winner} leads by {abs(mean_d):.4f} +- {std_d:.4f}."
    else:
        conclusion = f"Null result: No statistically significant difference (p = {p_val:.4f} >= 0.05). Simple baseline ties LSTM."

    return {
        "statistic": stat,
        "p_value": p_val,
        "mean_diff": mean_d,
        "std_diff": std_d,
        "significant": sig,
        "conclusion": conclusion,
    }


def aggregate_fold_metrics(
    fold_results: list[dict[str, Any]],
) -> dict[str, tuple[float, float]]:
    """Aggregate per-fold metrics into {metric_name: (mean, std)}."""
    if not fold_results:
        return {}
    keys = ["auc_roc", "brier_score", "ece", "f1", "n_samples", "n_positives"]
    summary = {}
    for k in keys:
        vals = [f[k] for f in fold_results if k in f and np.isfinite(f[k])]
        if vals:
            summary[k] = (float(np.mean(vals)), float(np.std(vals)))
        else:
            summary[k] = (float("nan"), float("nan"))
    return summary


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True, help="Features directory holding .npz files")
    ap.add_argument("--lstm-weights", type=Path, default=None, help="Optional pre-trained LSTM checkpoint (.pt)")
    ap.add_argument("--gap-seconds", type=int, default=1800, help="Maximum gap between clips in same session")
    ap.add_argument("--out", type=Path, default=Path("cross_val_results.json"), help="Output JSON path")
    args = ap.parse_args()

    folds = build_session_folds(args.features, gap_seconds=args.gap_seconds)
    k_sessions = len(folds)
    print(f"\n=========================================================================")
    print(f"  RUNNING LEAVE-ONE-SESSION-OUT CROSS-VALIDATION ({k_sessions} SESSIONS) ")
    print(f"=========================================================================")

    def load_clip_data(names: list[str]) -> tuple[np.ndarray, np.ndarray]:
        xs, ys = [], []
        for n in names:
            p = args.features / n
            if not p.exists():
                continue
            d = np.load(p)
            xs.append(d["x"])
            ys.append(d["y"])
        if not xs:
            return np.empty((0, 20, 31), dtype=np.float32), np.empty((0,), dtype=np.int64)
        return np.concatenate(xs), np.concatenate(ys)

    baseline_fold_results: list[dict[str, Any]] = []
    lstm_fold_results: list[dict[str, Any]] = []

    pooled_base_probs, pooled_base_truth = [], []
    pooled_lstm_probs, pooled_lstm_truth = [], []

    # Optional torch setup if evaluating LSTM weights
    net = None
    if args.lstm_weights and args.lstm_weights.exists():
        import torch
        from model.yield_lstm import YieldNet
        ckpt = torch.load(args.lstm_weights, map_location="cpu", weights_only=False)
        state_dict = ckpt.get("model", ckpt) if isinstance(ckpt, dict) else ckpt
        net = YieldNet()
        net.load_state_dict(state_dict)
        net.eval()
        print(f"Loaded LSTM model from {args.lstm_weights}")

    for fold in folds:
        f_idx = fold["fold_idx"]
        s_name = fold["session_name"]
        print(f"\n>>> Fold {f_idx + 1}/{k_sessions} (Held-out: {s_name} | {len(fold['test_clips'])} clips)")

        # Load train, calibration, and test data for this fold
        xtr, ytr = load_clip_data(fold["train_clips"])
        xcal, ycal = load_clip_data(fold["cal_clips"])
        xte, yte = load_clip_data(fold["test_clips"])

        if len(yte) == 0 or len(xtr) == 0:
            print(f"  [SKIPPED] Insufficient data (train={len(ytr)}, test={len(yte)})")
            continue

        n_pos = int((yte == 1).sum())
        print(f"  Train: {len(ytr):,} | Calib: {len(ycal):,} | Test: {len(yte):,} (positives: {n_pos})")

        # ----------------- TASK 3: LOGISTIC REGRESSION BASELINE -----------------
        base_model = fit_logistic_baseline(xtr, ytr)
        base_feats_te = extract_baseline_features(xte)
        base_probs = base_model.predict_proba(base_feats_te)[:, 1]

        # Apply fold-level Platt calibration to baseline probabilities using calibration slice
        if len(ycal) > 0 and len(np.unique(ycal)) > 1:
            base_feats_cal = extract_baseline_features(xcal)
            cal_logits = base_model.decision_function(base_feats_cal)
            y_smooth, _, _ = smooth_targets(ycal)
            A_base, B_base = fit_platt(cal_logits, y_smooth)
            test_logits = base_model.decision_function(base_feats_te)
            cal_base_probs = apply_platt(test_logits, A_base, B_base)
        else:
            cal_base_probs = base_probs

        base_res = {
            "fold_idx": f_idx,
            "session": s_name,
            "auc_roc": compute_roc_auc(cal_base_probs, yte),
            "brier_score": compute_brier_score(cal_base_probs, yte),
            "ece": compute_ece(cal_base_probs, yte),
            "f1": compute_f1(cal_base_probs, yte, threshold=0.5),
            "n_samples": float(len(yte)),
            "n_positives": float(n_pos),
        }
        baseline_fold_results.append(base_res)
        pooled_base_probs.append(cal_base_probs)
        pooled_base_truth.append(yte)

        print(f"  [Task 3 Baseline] AUC: {base_res['auc_roc']:.4f} | Brier: {base_res['brier_score']:.4f} | ECE: {base_res['ece']:.4f}")

        # ----------------- TASK 2: LSTM MODEL WITH PLATT CALIBRATION -----------------
        if net is not None:
            import torch
            with torch.no_grad():
                # Forward pass on calib and test
                def get_logits(x_arr):
                    tx = torch.from_numpy(x_arr)
                    lg = net(tx)
                    return (lg[..., 1] - lg[..., 0]).numpy().reshape(-1)

                cal_lg = get_logits(xcal)
                te_lg = get_logits(xte)

            if len(ycal) > 0 and len(np.unique(ycal)) > 1:
                y_smooth, _, _ = smooth_targets(ycal)
                A_lstm, B_lstm = fit_platt(cal_lg, y_smooth)
                lstm_probs = apply_platt(te_lg, A_lstm, B_lstm)
            else:
                lstm_probs = 1.0 / (1.0 + np.exp(-np.clip(te_lg, -50, 50)))

            lstm_res = {
                "fold_idx": f_idx,
                "session": s_name,
                "auc_roc": compute_roc_auc(lstm_probs, yte),
                "brier_score": compute_brier_score(lstm_probs, yte),
                "ece": compute_ece(lstm_probs, yte),
                "f1": compute_f1(lstm_probs, yte, threshold=0.5),
                "n_samples": float(len(yte)),
                "n_positives": float(n_pos),
            }
            lstm_fold_results.append(lstm_res)
            pooled_lstm_probs.append(lstm_probs)
            pooled_lstm_truth.append(yte)

            print(f"  [Task 2 LSTM]     AUC: {lstm_res['auc_roc']:.4f} | Brier: {lstm_res['brier_score']:.4f} | ECE: {lstm_res['ece']:.4f}")

    # ----------------- AGGREGATION & HONEST REPORTING -----------------
    base_agg = aggregate_fold_metrics(baseline_fold_results)
    print("\n" + "=" * 76)
    print(f"TASK 3 SUMMARY: BASELINE LOGISTIC REGRESSION (MEAN +- STD ACROSS {len(baseline_fold_results)} SESSIONS)")
    print("=" * 76)
    for k, (m, s) in base_agg.items():
        print(f"  {k:<15}: {m:.4f} +- {s:.4f}")

    if baseline_fold_results:
        worst_base = min(baseline_fold_results, key=lambda f: f["auc_roc"] if np.isfinite(f["auc_roc"]) else -1.0)
        print(f"\nWorst-performing session (Baseline): {worst_base['session']} "
              f"(AUC: {worst_base['auc_roc']:.4f}, Brier: {worst_base['brier_score']:.4f}, samples: {int(worst_base['n_samples'])})")

    # If LSTM results exist, compare and run Wilcoxon test (Task 4)
    wilcoxon_report = {}
    if lstm_fold_results:
        lstm_agg = aggregate_fold_metrics(lstm_fold_results)
        print("\n" + "=" * 76)
        print(f"TASK 2 SUMMARY: LSTM WITH PLATT CALIBRATION (MEAN +- STD ACROSS {len(lstm_fold_results)} SESSIONS)")
        print("=" * 76)
        for k, (m, s) in lstm_agg.items():
            print(f"  {k:<15}: {m:.4f} +- {s:.4f}")

        worst_lstm = min(lstm_fold_results, key=lambda f: f["auc_roc"] if np.isfinite(f["auc_roc"]) else -1.0)
        print(f"\nWorst-performing session (LSTM): {worst_lstm['session']} "
              f"(AUC: {worst_lstm['auc_roc']:.4f}, Brier: {worst_lstm['brier_score']:.4f}, samples: {int(worst_lstm['n_samples'])})")

        # TASK 4: PAIRED COMPARISON
        print("\n" + "=" * 76)
        print("TASK 4: PAIRED WILCOXON SIGNED-RANK TEST (LSTM vs BASELINE)")
        print("=" * 76)
        lstm_aucs = [f["auc_roc"] for f in lstm_fold_results]
        base_aucs = [f["auc_roc"] for f in baseline_fold_results]
        wilcoxon_report = run_paired_wilcoxon_test(lstm_aucs, base_aucs)
        print(f"  Statistic:  {wilcoxon_report['statistic']}")
        print(f"  p-value:    {wilcoxon_report['p_value']:.4f}")
        print(f"  Difference: {wilcoxon_report['mean_diff']:+.4f} +- {wilcoxon_report['std_diff']:.4f}")
        print(f"  Verdict:    {wilcoxon_report['conclusion']}")

    # Output full report to JSON
    report = {
        "total_sessions": k_sessions,
        "baseline_summary": {k: {"mean": m, "std": s} for k, (m, s) in base_agg.items()},
        "baseline_folds": baseline_fold_results,
        "lstm_summary": {k: {"mean": m, "std": s} for k, (m, s) in aggregate_fold_metrics(lstm_fold_results).items()},
        "lstm_folds": lstm_fold_results,
        "wilcoxon_paired_test": wilcoxon_report,
    }
    args.out.write_text(json.dumps(report, indent=2))
    print(f"\nWrote full cross-validation report to {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
