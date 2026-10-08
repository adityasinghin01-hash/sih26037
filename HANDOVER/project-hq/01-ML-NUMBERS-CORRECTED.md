# The ML numbers, corrected — 16 Sep 2026

**Source:** `05-ASSETS/round2_final_handoff.md`, written by the ML stream 11 Sep 2026
(Steps 90–104, branch `stream-ml`, merged to `main` as PR #21 on 12 Sep).
**Nothing below is estimated. Every figure is quoted from that handoff.**

## The headline correction

| | Stale figure still in the docs | Real figure |
|---|---|---|
| Dangerous-error rate | **20.18%** (measured 4 Sep) | **2.089%**, 95% CI **[1.315%, 2.854%]** (measured 11 Sep) |

**That is a ten-fold improvement and it is currently written down nowhere the team reads.**
`plan/CLAIM-LEDGER.md` and `SIH26037-Idea-PPT-Source.md` both still carry 20.18%.

## What it still does NOT mean — say this before a judge does

The pre-registered safety bar is **≤ 1.00%**. The 95% upper bound is **2.854%**, which is
above it. **The model still fails its own bar.** So `matlab/+sih/+prediction/predictYield.m`
enforces `Valid = false` by default, and the planner falls back to geometric right-of-way.
The prediction is displayed as advisory telemetry on the HUD and drives nothing.

**The honest sentence:** *"We cut our predictor's dangerous-error rate from 20% to 2%. It
still does not clear the 1% bar we set ourselves before we started, so we do not let it
steer the car — it falls back to geometry. That fallback is the designed behaviour, not a
missing feature."*

Do not upgrade this into "our model works now." It does not, by our own standard.

## The rest of the measured results

| What | Result |
|---|---|
| Test partition | 24 train / 7 calibration / 6 test sessions, **no clip leakage** |
| Test set, opened **once** | 233 clips, 694,864 samples |
| Safe-GO coverage | 10.478% (72,806 GO decisions) |
| Detection at onset | 99.2% |
| Early warning at 500 ms | 77.3% |
| Platt calibration (attention model) | ECE **0.1117 → 0.0091**; A = −0.7709, B = 2.0204 |
| Platt calibration (LSTM) | ECE cut by **>90%** |
| ONNX export | opset 18, **0 Gather/Scatter**, max diff **8.94 × 10⁻⁸** vs PyTorch |
| `predictYield.m` unit tests | **4/4 pass** (MATLAB R2024b) |
| YOLOX after domain adaptation | **16.7× mAP improvement** on Indian classes; 3D-render gap confirmed and disclosed |
| DeepLab v3+ road segmenter | verified functional, 0 errors |

## Where the model files actually are

| File | Location | On this Mac? |
|---|---|---|
| `yield_lstm.pt` | `~/meteor-data/features/` | **yes** |
| `yield_attention.pt` | `~/meteor-data/features/` | **yes** |
| `yield_lstm_opset18.onnx` | `ml/python/export/` in the repo | **yes** |
| `spotter_yolox_tuned.mat` | Shourya's Windows box | **no — still needs sending** |
| `road_segmenter_deeplab.mat` | Shourya's Windows box | **no — still needs sending** |

## Two errors to fix before anything is presented

1. **`Frame 1.png`** (the 3-stage architecture flowchart, in `05-ASSETS/`) says the planner
   follows **COLREGs** right-of-way. It does not. `plan/CLAIM-LEDGER.md` records that
   give-way-to-the-left is derived from **Indian RRR 1989 reg. 2**, and that COLREGs Rule 14
   says the opposite and would steer into oncoming traffic. This was caught during design
   and corrected in the code. **The diagram was never updated.** Do not show it as-is.
2. Anywhere still quoting **20.18%** — replace with the row at the top of this file.
