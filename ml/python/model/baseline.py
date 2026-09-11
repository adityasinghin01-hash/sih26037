"""Simple linear baseline for yield prediction.

Used for Task 3 comparison against the LSTM/Attention models under the identical
12-fold leave-one-station-out cross-validation protocol.

A complex model that cannot beat a simple baseline is a classic trap.
If our recurrent neural network cannot outperform a hand-picked logistic
regression baseline on the exact same folds, that is an honest empirical finding.

Features extracted from S2 (7 dimensions total):
    1. tau (feature 10, index 9) - time to contact from looming
    2. lateral closure rate (feature 11, index 10) - time to cross image centre
    3. ego speed (feature 28, index 27) - m/s
    4. candidate action (feature 31, index 30) - [-1.0 decelerate, 0.0 hold, 0.5 probe, 1.0 commit]
    5-7. coarse 3-way actor category collapsed from 16-way S5 one-hot (indices 11..26):
        - is_vehicle: car (1), truck (2), bus (3), auto-rickshaw (4), van (7), tractor (14)
        - is_vru: motorbike (5), scooter (6), pedestrian (8), bicycle (9), pushcart (12)
        - is_animal: cow (10), dog (11), animal-drawn cart (13)
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

import numpy as np

# S5 Class indices within the 16-way one-hot slice (features 12..27 -> slice 11..27)
VEHICLE_CLASSES = (1, 2, 3, 4, 7, 14)
VRU_CLASSES = (5, 6, 8, 9, 12)
ANIMAL_CLASSES = (10, 11, 13)


def extract_baseline_features(x: np.ndarray) -> np.ndarray:
    """Extract the compact 7-dim feature vector from full S2 frames or sequences.

    Parameters:
        x: [N, 31] or [N, T, 31] numpy array of raw S2 features.
           If 3D, uses the most recent timestep (index -1).

    Returns:
        [N, 7] float32 array:
            [:, 0] = tau (feat 10)
            [:, 1] = lateral closure rate (feat 11)
            [:, 2] = ego speed (feat 28)
            [:, 3] = candidate action (feat 31)
            [:, 4] = is_vehicle (collapsed from 16-way one-hot)
            [:, 5] = is_vru (collapsed from 16-way one-hot)
            [:, 6] = is_animal (collapsed from 16-way one-hot)
    """
    if x.ndim == 3:
        # Use latest timestep
        x_frame = x[:, -1, :]
    elif x.ndim == 2:
        x_frame = x
    else:
        raise ValueError(f"Expected 2D or 3D array, got shape {x.shape}")

    n = len(x_frame)
    feats = np.zeros((n, 7), dtype=np.float32)

    # 1. tau (feature 10, index 9)
    feats[:, 0] = x_frame[:, 9]

    # 2. lateral closure rate (feature 11, index 10)
    feats[:, 1] = x_frame[:, 10]

    # 3. ego speed (feature 28, index 27)
    feats[:, 2] = x_frame[:, 27]

    # 4. candidate action (feature 31, index 30)
    feats[:, 3] = x_frame[:, 30]

    # 5-7. Coarse 3-way class indicator from 16-way one-hot (indices 11..27)
    one_hot = x_frame[:, 11:27]
    feats[:, 4] = np.any(one_hot[:, VEHICLE_CLASSES] > 0.5, axis=1).astype(np.float32)
    feats[:, 5] = np.any(one_hot[:, VRU_CLASSES] > 0.5, axis=1).astype(np.float32)
    feats[:, 6] = np.any(one_hot[:, ANIMAL_CLASSES] > 0.5, axis=1).astype(np.float32)

    return feats


def compute_roc_auc(scores: np.ndarray, truth: np.ndarray) -> float:
    """Compute ROC-AUC using trapezoidal integration (pure numpy)."""
    n_pos = int((truth == 1).sum())
    n_neg = int((truth == 0).sum())
    if n_pos == 0 or n_neg == 0:
        return float("nan")

    order = np.argsort(-scores, kind="stable")
    sorted_truth = truth[order]

    # Cumulative TPR and FPR
    tp = np.cumsum(sorted_truth == 1, dtype=np.float64)
    fp = np.cumsum(sorted_truth == 0, dtype=np.float64)

    tpr = np.concatenate([[0.0], tp / n_pos])
    fpr = np.concatenate([[0.0], fp / n_neg])

    trapz_fn = getattr(np, "trapezoid", getattr(np, "trapz", None))
    return float(trapz_fn(tpr, fpr))


def compute_brier_score(prob: np.ndarray, truth: np.ndarray) -> float:
    """Mean squared probability error: 1/N * sum((p - y)^2)."""
    if len(truth) == 0:
        return float("nan")
    return float(np.mean((prob - truth) ** 2))


def compute_ece(prob: np.ndarray, truth: np.ndarray, bins: int = 10) -> float:
    """Expected Calibration Error, matching evaluate.py."""
    edges = np.linspace(0.0, 1.0, bins + 1)
    err = 0.0
    n = len(prob)
    if n == 0:
        return float("nan")

    for lo, hi in zip(edges[:-1], edges[1:]):
        m = (prob >= lo) & (prob < hi if hi < 1.0 else prob <= hi)
        if not m.any():
            continue
        err += (m.sum() / n) * abs(prob[m].mean() - truth[m].mean())
    return float(err)


def compute_f1(prob: np.ndarray, truth: np.ndarray, threshold: float = 0.5) -> float:
    """F1 score at operating threshold."""
    pred = (prob >= threshold).astype(np.int64)
    tp = int(((pred == 1) & (truth == 1)).sum())
    fp = int(((pred == 1) & (truth == 0)).sum())
    fn = int(((pred == 0) & (truth == 1)).sum())

    prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    rec = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    return 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0


def fit_logistic_baseline(
    x_train: np.ndarray,
    y_train: np.ndarray,
    class_weight: str | dict | None = "balanced",
    max_iter: int = 1000,
) -> Any:
    """Fit a LogisticRegression baseline model on extracted features."""
    try:
        from sklearn.linear_model import LogisticRegression
        from sklearn.preprocessing import StandardScaler
        from sklearn.pipeline import Pipeline
    except ImportError:
        raise RuntimeError(
            "scikit-learn is required for baseline.py. Install via 'pip install scikit-learn'."
        )

    feats_train = extract_baseline_features(x_train)

    pipeline = Pipeline([
        ("scaler", StandardScaler()),
        ("clf", LogisticRegression(class_weight=class_weight, max_iter=max_iter, random_state=42)),
    ])
    pipeline.fit(feats_train, y_train)
    return pipeline


def evaluate_baseline(
    model: Any,
    x_test: np.ndarray,
    y_test: np.ndarray,
    threshold: float = 0.5,
) -> dict[str, float]:
    """Evaluate baseline model on test data, returning standard metrics."""
    feats_test = extract_baseline_features(x_test)
    prob = model.predict_proba(feats_test)[:, 1]

    return {
        "auc_roc": compute_roc_auc(prob, y_test),
        "brier_score": compute_brier_score(prob, y_test),
        "ece": compute_ece(prob, y_test),
        "f1": compute_f1(prob, y_test, threshold=threshold),
        "n_samples": float(len(y_test)),
        "n_positives": float(np.sum(y_test == 1)),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--features", type=Path, required=True, help="Path to features dir holding .npz files")
    ap.add_argument("--split", type=Path, default=None, help="Optional split.json to run train/val split")
    args = ap.parse_args()

    split_file = args.split or (args.features / "split.json")
    if not split_file.exists():
        print(f"ERROR: split file {split_file} not found.", file=sys.stderr)
        return 1

    sp = json.loads(split_file.read_text())
    print(f"Loading train ({len(sp['train'])} clips) and val ({len(sp['val'])} clips)...")

    def load_clips(names: list[str]) -> tuple[np.ndarray, np.ndarray]:
        xs, ys = [], []
        for n in names:
            p = args.features / n
            if not p.exists():
                continue
            d = np.load(p)
            xs.append(d["x"])
            ys.append(d["y"])
        return np.concatenate(xs), np.concatenate(ys)

    x_train, y_train = load_clips(sp["train"])
    x_val, y_val = load_clips(sp["val"])

    print(f"Train samples: {len(y_train):,} (pos: {int(y_train.sum()):,})")
    print(f"Val samples:   {len(y_val):,} (pos: {int(y_val.sum()):,})")

    model = fit_logistic_baseline(x_train, y_train)
    results = evaluate_baseline(model, x_val, y_val)

    print("\n--- BASELINE LOGISTIC REGRESSION RESULTS ---")
    print(f"  AUC-ROC:     {results['auc_roc']:.4f}")
    print(f"  Brier Score: {results['brier_score']:.4f}")
    print(f"  ECE:         {results['ece']:.4f}")
    print(f"  F1:          {results['f1']:.4f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
