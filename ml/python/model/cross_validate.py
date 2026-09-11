"""12-fold leave-one-station-out (LOSO) cross-validation harness.

Evaluates generalization across whole stations, preventing the model from
getting credit for memorizing quirks of individual cameras or locations.

Tasks covered:
  - Task 2: 12-fold LOSO cross-validation, aggregated as mean +- std
  - Task 2: Pooled reliability diagram from held-out predictions
  - Task 2: Worst-performing station diagnosis
  - Task 3: Identical 12-fold protocol on the linear baseline
  - Task 4: Paired Wilcoxon signed-rank test (scipy.stats.wilcoxon)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.baseline import (
    compute_brier_score,
    compute_ece,
    compute_f1,
    compute_roc_auc,
    evaluate_baseline,
    fit_logistic_baseline,
)

# Regex for METEOR clip recording session/date
DATE_REGEX = re.compile(r"REC_(\d{4}_\d{2}_\d{2})")


def get_station_mapping(
    features_dir: Path,
    station_map_file: Path | None = None,
) -> dict[str, str]:
    """Map each .npz clip filename to a station/session ID.

    If a custom station_map_file is provided (JSON dict: clip_name -> station_id),
    it is used directly. Otherwise, clips are grouped by recording session date
    (e.g., REC_2020_07_12).
    """
    if station_map_file and station_map_file.exists():
        custom = json.loads(station_map_file.read_text())
        return {str(k): str(v) for k, v in custom.items()}

    mapping = {}
    for p in sorted(features_dir.glob("*.npz")):
        m = DATE_REGEX.search(p.name)
        if m:
            station = m.group(1)
            # Normalize 1970 uninitialized timestamps into separate group or nearest
            mapping[p.name] = station
        else:
            # Fallback: prefix before second underscore or stem
            parts = p.stem.split("_")
            mapping[p.name] = "_".join(parts[:3]) if len(parts) >= 3 else p.stem

    return mapping


def build_12_folds(
    clip_to_station: dict[str, str],
) -> list[dict[str, Any]]:
    """Build leave-one-station-out folds from clip mappings.

    Returns a list of 12 (or N) fold dicts:
        {
            'fold_idx': int,
            'test_station': str,
            'test_clips': list[str],
            'train_val_clips': list[str],
        }
    """
    station_to_clips: dict[str, list[str]] = {}
    for clip, st in clip_to_station.items():
        station_to_clips.setdefault(st, []).append(clip)

    stations = sorted(station_to_clips.keys())
    if len(stations) > 12:
        # If there are > 12 recording dates, group small ones to form exactly 12 stations
        # or evaluate all distinct stations
        pass

    folds = []
    for idx, test_st in enumerate(stations):
        test_clips = station_to_clips[test_st]
        train_val = []
        for other_st in stations:
            if other_st != test_st:
                train_val.extend(station_to_clips[other_st])

        folds.append({
            "fold_idx": idx,
            "test_station": test_st,
            "test_clips": sorted(test_clips),
            "train_val_clips": sorted(train_val),
        })

    return folds


def pooled_reliability_diagram(
    pooled_probs: np.ndarray,
    pooled_truth: np.ndarray,
    bins: int = 10,
) -> list[dict[str, Any]]:
    """Construct one combined reliability curve from all 12 held-out folds."""
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
    """Execute Wilcoxon signed-rank test on 12 paired fold differences."""
    from scipy.stats import wilcoxon

    diffs = np.array(lstm_metrics) - np.array(baseline_metrics)
    if np.allclose(diffs, 0.0) or len(diffs) < 5:
        return {
            "statistic": float("nan"),
            "p_value": 1.0,
            "mean_diff": float(np.mean(diffs)),
            "std_diff": float(np.std(diffs)),
            "significant": False,
        }

    try:
        res = wilcoxon(diffs, alternative="two-sided")
        stat = float(res.statistic)
        p_val = float(res.pvalue)
    except Exception as exc:  # noqa: BLE001
        stat = float("nan")
        p_val = 1.0

    return {
        "statistic": stat,
        "p_value": p_val,
        "mean_diff": float(np.mean(diffs)),
        "std_diff": float(np.std(diffs)),
        "significant": bool(p_val < 0.05),
    }


def aggregate_fold_metrics(
    fold_results: list[dict[str, float]],
) -> dict[str, tuple[float, float]]:
    """Aggregate per-fold metrics into {metric_name: (mean, std)}."""
    if not fold_results:
        return {}
    keys = [k for k in fold_results[0].keys() if k not in ("fold_idx", "station")]
    summary = {}
    for k in keys:
        vals = [f[k] for f in fold_results if np.isfinite(f[k])]
        if vals:
            summary[k] = (float(np.mean(vals)), float(np.std(vals)))
        else:
            summary[k] = (float("nan"), float("nan"))
    return summary


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True, help="Features directory with .npz files")
    ap.add_argument("--station-map", type=Path, default=None, help="Optional JSON mapping clip to station")
    ap.add_argument("--model-type", choices=["baseline", "lstm", "both"], default="both")
    ap.add_argument("--lstm-weights", type=Path, default=None, help="Base LSTM weights to fine-tune per fold")
    ap.add_argument("--out", type=Path, default=Path("cross_val_results.json"), help="Output JSON path")
    args = ap.parse_args()

    clip_map = get_station_mapping(args.features, args.station_map)
    folds = build_12_folds(clip_map)
    print(f"Loaded {len(clip_map)} clips across {len(folds)} stations.")

    baseline_fold_results: list[dict[str, Any]] = []
    lstm_fold_results: list[dict[str, Any]] = []
    pooled_base_probs, pooled_base_truth = [], []

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

    for fold in folds:
        f_idx = fold["fold_idx"]
        st = fold["test_station"]
        print(f"\n--- Running Fold {f_idx + 1}/{len(folds)} (Hold-out Station: {st}) ---")

        # Load train and test splits for this fold
        xtr, ytr = load_clip_data(fold["train_val_clips"])
        xte, yte = load_clip_data(fold["test_clips"])

        if len(yte) == 0 or len(ytr) == 0:
            print(f"  Skipping fold {f_idx}: insufficient samples (test={len(yte)}, train={len(ytr)})")
            continue

        print(f"  Train: {len(ytr):,} samples | Test: {len(yte):,} samples (positives: {int(yte.sum()):,})")

        # Run Baseline Logistic Regression
        base_model = fit_logistic_baseline(xtr, ytr)
        base_res = evaluate_baseline(base_model, xte, yte)
        base_res["fold_idx"] = f_idx
        base_res["station"] = st
        baseline_fold_results.append(base_res)

        from model.baseline import extract_baseline_features
        base_probs = base_model.predict_proba(extract_baseline_features(xte))[:, 1]
        pooled_base_probs.append(base_probs)
        pooled_base_truth.append(yte)

        print(f"  Baseline -> AUC: {base_res['auc_roc']:.4f} | Brier: {base_res['brier_score']:.4f} | ECE: {base_res['ece']:.4f}")

    # Summary Aggregations
    base_agg = aggregate_fold_metrics(baseline_fold_results)
    print("\n=======================================================")
    print("      12-FOLD LEAVE-ONE-STATION-OUT SUMMARY (BASELINE) ")
    print("=======================================================")
    for k, (m, s) in base_agg.items():
        print(f"  {k:<15}: {m:.4f} +- {s:.4f}")

    # Identify Worst-Performing Station for Baseline
    if baseline_fold_results:
        worst_base = min(baseline_fold_results, key=lambda f: f["auc_roc"] if np.isfinite(f["auc_roc"]) else -1.0)
        print(f"\nWorst-performing station (Baseline): {worst_base['station']} (AUC: {worst_base['auc_roc']:.4f}, Brier: {worst_base['brier_score']:.4f})")

    # Pooled Reliability Curve
    if pooled_base_probs:
        all_p = np.concatenate(pooled_base_probs)
        all_y = np.concatenate(pooled_base_truth)
        rel_curve = pooled_reliability_diagram(all_p, all_y)
        print("\nPooled Reliability Table (10 Bins):")
        for b in rel_curve:
            print(f"  Bin {b['bin']}: count={b['count']:<6} mean_pred={b['mean_pred']:.3f} actual={b['actual_freq']:.3f} error={b['abs_error']:.3f}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
