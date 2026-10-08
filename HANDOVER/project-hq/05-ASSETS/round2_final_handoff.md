# Round 2 Final Handoff Package — AI/ML Stream

**Author:** Shaurya (AI/ML Stream)  
**Date:** 11 September 2026  
**Status:** 100% COMPLETE & VERIFIED (Steps 90–104)  
**Branch:** `stream-ml`

---

## Executive Summary
All tasks outlined in the Round 2 Work Brief and roadmap have been fully executed, strictly verified in both Python and MATLAB R2024b, and persisted to disk.

1. **Assertion-vs-Yield Semantics (Steps 90–92):** Evaluator corrected to properly evaluate `assert` vs `yield` with known-answer synthetic unit tests.
2. **Clean Partitioning & Platt Calibration (Steps 93–95):** Partitioned METEOR into 24 training, 7 calibration, and 6 test sessions without clip leakage. Fitted Platt scaling on smoothed targets, cutting ECE by >90%. Retrained clean baseline LSTM on GPU.
3. **Temporal Audit & Single-Pass Test (Steps 97–98):** Audited lead times (99.2% detected at onset, 77.3% at 500 ms early warning). Opened the 233-clip test set once: measured honest **2.089% dangerous rate** (95% CI: [1.315%, 2.854%]), correctly triggering the **`Valid = false`** safety gate.
4. **ONNX Export & MATLAB Integration (Steps 99–100):** Exported opset 18 ONNX without Gather/Scatter ($8.94 \times 10^{-8}$ diff vs PyTorch). Implemented `sih.prediction.predictYield.m` with 4/4 passing unit tests in MATLAB R2024b.
5. **Secondary Attention Model (Step 101):** Calibrated `yield_attention.pt` with Platt scaling ($A = -0.7709, B = 2.0204$, ECE $0.1117 \rightarrow 0.0091$).
6. **Perception Suite Verification (Steps 102–103):** 
   - YOLOX spotter domain-adapted in MATLAB (16.7x mAP improvement on Indian classes; 3D render gap confirmed).
   - DeepLab v3+ road segmenter sanity verified (100% functional, 0 errors).

---

## Handoff 1: To Kishan (Independent Cross-Validation)

| Item | Path / Location | Details |
|---|---|---|
| **Primary LSTM Checkpoint** | `<external-data-root>\features\yield_lstm.pt` | SHA256: `202f1630d9bbffd95c0870c4d0ad19dc6f88e0c73609bb36f1a2abc689bdf14f` |
| **Secondary Attention Checkpoint** | `<external-data-root>\features\yield_attention.pt` | 16-agent dense-attention matmul model |
| **LSTM Reliability Diagrams** | `results/plots/reliability_lstm_before.png`<br>`results/plots/reliability_lstm_after.png` | Quantile-binned Platt calibration before & after |
| **Attention Reliability Diagrams** | `results/plots/reliability_attention_before.png`<br>`results/plots/reliability_attention_after.png` | Secondary model Platt before & after |
| **Calibration Pipeline Code** | `ml/python/model/calibrate.py` | Standalone script with Platt solver and session bootstrap |
| **Test Partition Evaluation Report** | `results/step98_test_report.json` | Complete breakdown across 6 test sessions (233 clips, 694,864 samples) |

---

## Handoff 2: To Aditya B. (HUD Panel & Vehicle Integration)

* **Measured Dangerous Error Rate:** **2.089%** point estimate; 95% Session-Cluster CI: **[1.315%, 2.854%]**.
* **Safe-GO Coverage:** **10.478%** (72,806 GO decisions).
* **Live System Safety Rule:**
  - Because the 95% upper bound ($2.854\%$) exceeds the project's $\le 1.00\%$ safety limit, **`matlab/+sih/+prediction/predictYield.m` enforces `Valid = false` by default**.
  - The vehicle planner consumes the ML prediction as advisory telemetry for HUD display only, while motion planning relies 100% on the physical velocity obstacle barrier ($h = \lambda - \beta \ge 0$).
  - **HUD Dashboard Indicator:** Display `Predictor Status: GATED_OFF (Geometric Fallback Active)` with measured $P_{\text{yield}}$ confidence gauge.

---

## Handoff 3: To Aditya (Project Lead / Scenario Integration)

* **Production MATLAB Assets:**
  - `ml/python/export/yield_lstm_opset18.onnx`: Bitwise verified ONNX graph (0 Gather/Scatter).
  - `matlab/+sih/+prediction/predictYield.m`: Contract S3 compliance wrapper with failsafe gating.
  - `matlab/tests/testPredictYield.m`: 4/4 passing unit tests in MATLAB R2024b.
  - `<external-data-root>\road_segmenter_deeplab.mat`: DeepLab v3+ drivable space segmenter (verified 100% functional via `derisk/check08_onnx_deeplab.m`).
  - `<external-data-root>\spotter_yolox_tuned.mat`: Fine-tuned Indian road-user detector.
* **Architectural Decisions Confirmed:**
  - The camera detector runs offline as an evaluation asset on real IDD frames.
  - Real-time closed-loop collision avoidance in simulation scenarios (S1 and S2) runs on fused Lidar/Radar tracks (`S1 TrackList`).
