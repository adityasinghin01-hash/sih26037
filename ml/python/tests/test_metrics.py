"""Known-answer tests for the evaluation metrics.

    python3 ml/python/tests/test_metrics.py

evaluate.py decides whether a model is allowed near MATLAB. If its metrics are wrong, every
verdict it gives is wrong in a way nobody would notice - a broken average_precision does not
crash, it just returns a plausible number. So the metrics are checked against cases whose answer
can be worked out by hand.

No pytest needed. Exits non-zero on failure.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.evaluate import (average_precision, bootstrap_ci, confusion,      # noqa: E402
                            expected_calibration_error, pick_threshold,
                            single_feature_baselines)

FAILED: list[str] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"  {'PASS' if ok else 'FAIL'}  {name}{'  ' + detail if detail else ''}")
    if not ok:
        FAILED.append(name)


def close(a: float, b: float, tol: float = 1e-9) -> bool:
    return bool(np.isfinite(a) and abs(a - b) <= tol)


def main() -> int:
    print("average_precision - hand-computable cases")

    # A perfect ranking puts every positive first: precision is 1 at every hit.
    check("perfect ranking scores 1.0",
          close(average_precision(np.array([0.9, 0.8, 0.2, 0.1]), np.array([1, 1, 0, 0])), 1.0))

    # The worst ranking puts both positives last. Hits land at ranks 3 and 4, so precision is
    # 1/3 and 2/4, and AP = (1/3 + 1/2) / 2 = 0.41666...
    check("worst ranking matches the hand calculation",
          close(average_precision(np.array([0.9, 0.8, 0.2, 0.1]), np.array([0, 0, 1, 1])),
                (1/3 + 1/2) / 2, 1e-12))

    # One positive at rank 2 of 4: precision there is 1/2, and there is one positive.
    check("single positive at rank 2 gives 0.5",
          close(average_precision(np.array([0.9, 0.8, 0.7, 0.6]), np.array([0, 1, 0, 0])), 0.5))

    # A useless score on rare data should land near the base rate. This is the property the whole
    # "does it beat something trivial" check rests on, so it is worth pinning.
    rng = np.random.default_rng(0)
    truth = (rng.random(20000) < 0.01).astype(int)
    ap_rand = average_precision(rng.random(20000), truth)
    check("random scoring lands near the base rate", abs(ap_rand - 0.01) < 0.005,
          f"AP={ap_rand:.4f} base={truth.mean():.4f}")

    check("no positives returns nan",
          bool(np.isnan(average_precision(np.array([0.5, 0.4]), np.array([0, 0])))))

    # Ranking is what matters, not the scale of the scores.
    s = np.array([0.9, 0.8, 0.2, 0.1]); y = np.array([1, 0, 1, 0])
    check("invariant to a monotonic rescale",
          close(average_precision(s, y), average_precision(s * 100 - 7, y), 1e-12))

    print("\nconfusion - the two mistakes must not be swapped")
    # 2 positives. At 0.5: predicts yes on items 0 and 1. Item 0 is a real positive (tp),
    # item 1 is not (fp = DANGEROUS). Item 2 is a missed positive (fn = harmless).
    c = confusion(np.array([0.9, 0.6, 0.4, 0.1]), np.array([1, 0, 1, 0]), 0.5)
    check("true positives counted", c["correct_go"] == 1, str(c["correct_go"]))
    check("DANGEROUS error is a false positive", c["dangerous_errors"] == 1)
    check("harmless error is a false negative", c["harmless_errors"] == 1)
    check("dangerous_rate is fp/(tp+fp), not fp/all", close(c["dangerous_rate"], 0.5))
    check("recall is tp/(tp+fn)", close(c["recall"], 0.5))
    check("threshold is inclusive at the boundary",
          confusion(np.array([0.5]), np.array([1]), 0.5)["correct_go"] == 1)

    print("\npick_threshold - must respect the safety target")
    # Scores where only a high cut is safe: the top item is a true positive, the next is not.
    p = np.concatenate([[0.95], np.full(99, 0.60), [0.10]])
    t = np.concatenate([[1], np.zeros(99, dtype=int), [0]])
    thr, c = pick_threshold(p, t, target=0.01)
    check("picks a threshold at or above the contaminated band", thr >= 0.60 - 1e-9,
          f"thr={thr:.4f}")
    check("meets the target at that threshold", c["dangerous_rate"] <= 0.01,
          f"{c['dangerous_rate']:.3f}")
    # When nothing can meet the target it must still return the safest point, not crash.
    thr2, c2 = pick_threshold(np.full(50, 0.5), np.zeros(50, dtype=int), target=0.01)
    check("degrades to the safest point rather than raising", np.isfinite(thr2))

    print("\nexpected_calibration_error")
    # A model that says 0.0 for 100 negatives and 1.0 for 100 positives is perfectly calibrated.
    p = np.concatenate([np.zeros(100), np.ones(100)])
    t = np.concatenate([np.zeros(100, dtype=int), np.ones(100, dtype=int)])
    check("perfect calibration scores 0", close(expected_calibration_error(p, t), 0.0, 1e-12))
    # Says 1.0 every time and is always wrong: the gap is 1.0 across the whole population.
    check("always wrong and certain scores 1",
          close(expected_calibration_error(np.ones(100), np.zeros(100, dtype=int)), 1.0, 1e-12))
    # Population weighting: 999 well-calibrated samples plus one wild bin must stay small.
    p = np.concatenate([np.zeros(999), [0.95]])
    t = np.concatenate([np.zeros(999, dtype=int), [0]])
    ece = expected_calibration_error(p, t)
    check("one wild bin cannot dominate a large population", ece < 0.01, f"ECE={ece:.5f}")

    print("\nbootstrap_ci")
    rng = np.random.default_rng(1)
    truth = (rng.random(4000) < 0.05).astype(int)
    # Informative but genuinely OVERLAPPING. An earlier version of this test used
    # truth*0.6 + noise*0.4, which is perfectly separable, so AP was exactly 1.0 and every
    # interval was [1, 1]. A metric test built on a separable case proves nothing.
    score = rng.random(4000) + truth * 0.35
    point = average_precision(score, truth)
    lo, hi = bootstrap_ci(average_precision, score, truth, n=200)
    check("interval brackets the point estimate", lo <= point <= hi,
          f"[{lo:.4f}, {point:.4f}, {hi:.4f}]")
    check("interval is ordered", lo <= hi)
    # A tiny sample must produce a WIDE interval - that is the whole reason this exists.
    # Positives are interleaved with negatives, so which ones a resample happens to draw
    # changes the answer a lot. That spread is the point of reporting an interval at all.
    small_t = np.array([0, 1, 0, 0, 1, 0, 0, 0])
    small_s = np.array([0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2])
    slo, shi = bootstrap_ci(average_precision, small_s, small_t, n=400)
    check("a tiny sample yields a wide interval", (shi - slo) > 0.2, f"[{slo:.3f}, {shi:.3f}]")

    print("\nsingle_feature_baselines - the check that catches a useless model")
    rng = np.random.default_rng(2)
    n = 2000
    y = (rng.random(n) < 0.05).astype(int)
    x = rng.normal(size=(n, 31)).astype(np.float32)
    x[:, 6] += y * 3.0                                    # feature 7 carries the signal
    name, ap, col, sign = single_feature_baselines(x, y)
    check("finds the one informative feature", col == 6, f"found {name}")
    check("reports the correct sign", sign == 1, f"sign {sign:+d}")
    check("scores well above the base rate", ap > 5 * y.mean(), f"AP={ap:.4f} base={y.mean():.4f}")
    # A constant column must be skipped, not divided by zero.
    xc = np.zeros((100, 31), dtype=np.float32)
    yc = (np.arange(100) < 5).astype(int)
    nm, apc, cc, _ = single_feature_baselines(xc, yc)
    check("constant features are skipped", cc == -1, f"got {nm}")

    print()
    if FAILED:
        print(f"{len(FAILED)} metric test(s) failed: {FAILED}")
        return 1
    print("all metric tests passed - the numbers evaluate.py reports can be trusted")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
