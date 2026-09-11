"""Unit tests for Step 94: Platt calibration and probability scaling."""
from __future__ import annotations

from pathlib import Path
import sys
import unittest

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.calibrate import (
    smooth_targets,
    fit_platt,
    apply_platt,
    correct_pos_weight,
    quantile_reliability,
    evaluate_threshold_risk,
)


class TestCalibrate(unittest.TestCase):
    def test_smooth_targets(self):
        y = np.array([1, 1, 0, 0, 0, 0, 0, 0])  # 2 pos, 6 neg
        y_smooth, t_pos, t_neg = smooth_targets(y)
        self.assertAlmostEqual(t_pos, 3.0 / 4.0)  # (2 + 1) / (2 + 2) = 0.75
        self.assertAlmostEqual(t_neg, 1.0 / 8.0)  # 1 / (6 + 2) = 0.125
        self.assertEqual(len(y_smooth), 8)
        self.assertAlmostEqual(y_smooth[0], 0.75)
        self.assertAlmostEqual(y_smooth[2], 0.125)

    def test_fit_and_apply_platt(self):
        raw_logits = np.array([-4.0, -2.0, 0.0, 2.0, 4.0])
        y = np.array([0, 0, 0, 1, 1])
        y_smooth, _, _ = smooth_targets(y)

        A, B = fit_platt(raw_logits, y_smooth)
        self.assertLess(A, 0.0, "A must be negative so positive logits map to high probability")

        probs = apply_platt(raw_logits, A, B)
        self.assertTrue((probs > 0.0).all() and (probs < 1.0).all())
        # Monotonically increasing with raw logits
        self.assertTrue((np.diff(probs) > 0).all())

    def test_correct_pos_weight(self):
        raw_logits = np.array([2.0, 0.0, -2.0])
        pw = 9.0
        f_corr, p_corr = correct_pos_weight(raw_logits, pw)
        expected_shift = np.log(9.0)
        np.testing.assert_allclose(f_corr, raw_logits - expected_shift)
        self.assertTrue((p_corr >= 0.0).all() and (p_corr <= 1.0).all())

    def test_quantile_reliability(self):
        rng = np.random.default_rng(0)
        scores = rng.random(1000)
        labels = (rng.random(1000) < scores).astype(np.int64)

        bins = quantile_reliability(scores, labels, n_bins=10)
        self.assertEqual(len(bins), 10)
        total_n = sum(b["n"] for b in bins)
        self.assertEqual(total_n, 1000)
        for b in bins:
            self.assertGreater(b["n"], 80)
            self.assertLess(b["n"], 120)

    def test_evaluate_threshold_risk_assert_mode(self):
        # Assert mode: low score permits GO
        scores = np.array([0.01, 0.05, 0.20, 0.80, 0.95])
        labels = np.array([0, 1, 0, 1, 1])  # 0 = no assert (safe), 1 = assert (dangerous)
        thr = 0.10

        res = evaluate_threshold_risk(scores, labels, thr, label_mode="assert")
        # said_go is scores <= 0.10 -> [True, True, False, False, False] (indices 0 and 1)
        # index 0: safe (labels=0) -> correct_go
        # index 1: assert (labels=1) -> dangerous_error
        self.assertEqual(res["n_go"], 2)
        self.assertEqual(res["dangerous"], 1)
        self.assertEqual(res["dangerous_rate"], 0.5)


if __name__ == "__main__":
    unittest.main()
