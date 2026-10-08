# P2 — Audit of our own system (what exists on 26 Sep 2026)

Source: the repo `~/dev/sih2026`, branch `integration/dense-planner` (8 commits, **NOT pushed**),
plus `~/dev/sih2026-hq`. Every number comes from a run recorded 16–17 Sep 2026, except where marked.
Grades: **Strong** / **Partial** / **Weak** / **Missing**.

| # | Layer | What we have (real, runs) | Measured | Grade | Main weakness |
|---|---|---|---|---|---|
| 1 | **Planner — the brain** | `+sih/+planner` (18 functions): velocity-obstacle barrier `h=λ−β`; COLREGs-style roles adapted to Indian law (keep left, RRR 1989 reg.2/9); **contingency planner**: a fan of 35 paths × 2 futures per agent (yield/assert), commit only the trunk that is safe under both, plus a brake-to-stop terminal check (trunk mode B); pure-pursuit follower; turn classification; escape memory; point of no return. Plus the `+sc/planSeat` layer: D9 ladder (creep → WAIT → go-around), track hysteresis, sanity reject | S1 completes 610 m, 0 plan failures, min clearance **0.618 m** sparse / **0.135 m** dense; 8 randomised runs: mean 0.143, 95% CI [0.093, 0.193], **worst −0.001 m (contact)**. S3 sparse completes, 0.293 m | **Partial** | **Permanent stall** in circulating/dense traffic (S2 at s≈116–121 m, dense S3 at 81.4 m). Root cause found by Codex (the clearance gate drops the longitudinal station; WAIT commits on one frame; the timeout re-arms). Not fixed. Tie-break prefers standing still or small offsets. Hand-tuned, not learned |
| 2 | **Prediction ML** | LSTM (25k params) + attention model (58k params) over 31 depth-free image-plane features, trained on METEOR (1,251 clips); Platt calibration; ONNX opset 18 with no Gather/Scatter; `predictYield.m` plus the `gateYield` gate | Test set (233 clips): **dangerous-error 2.089%**, CI [1.315, 2.854] vs bar ≤1%; covers 10.5% of GO decisions; ECE 0.0159 | **Weak** | **Fails its own bar, so it drives nothing** (Valid=false). Label is "assert" (took the gap), not true yield; the ego features 28–31 are nearly empty in METEOR; it predicts intent only, not trajectories; no multi-agent joint prediction |
| 3 | **Perception ML** | YOLOX spotter (IDD, A100); DeepLab v3+ road segmenter; PointPillars (script only) | DeepLab: **drivable IoU 96.0%, mIoU 86.3%**. YOLOX: mAP 29.1% (cow AP 16.3%, auto 38.2%). On rendered frames: **0 detections at the default threshold** | **Weak** | **Offline only**, nothing in the driving loop. Camera not in the loop. PointPillars never trained. Two of the model files are only on Shourya's Windows PC |
| 4 | **Sensing and tracking** | Simulated lidar, radar and near-field ring → `trackerGNN` (constant-velocity EKF) → S1 TrackList | S1 under sensing: 0.625 m vs 0.618 m ground truth (7 mm change) | **Partial** | Sensor numbers are not from a datasheet; no real ray-cast occlusion; no false alarms; no weather model |
| 5 | **Safety layer** | Two barriers (`h_agent`, `h_road`), a speed law limited by sight, a terminal-stop guarantee | 0 "imminent" barrier violations on S1/S3 runs | **Partial** | No formal proof; the raw barrier fires falsely (387 raw vs 0 imminent); no independent watchdog; RSS not implemented |
| 6 | **Sim world** | Real Najibabad OSM roads imported into MATLAB (1.05 m median agreement); 2D worlds for S1/S2/S3 + density layers for S1/S3/S4/S5; Blender 3D city (~7,800 buildings) | S1 610 m, S3 382 m, S2 244 m | **Partial** | S4/S5 have no planner route. **No RoadRunner** (a hard PS requirement). The 3D city is not in the loop |
| 7 | **Traffic behaviour** | Scripted actors; `reactStep` (per-class yield authority, speed-only) | 35 reactions per S1 run | **Weak** | Replays a script, not learned Indian behaviour; the density layer is scenery (50 of 51 actors are off the road) |
| 8 | **Control and vehicle** | Frenet target speed/lateral + an accel-limited integrator (`lateralStep`); a Simulink bicycle model in `sih_planner.slx` | — | **Weak** | No real vehicle dynamics (Vehicle Dynamics Blockset unused); the steering command is not executed in the main demo |
| 9 | **Data loop** | none | — | **Missing** | No shadow mode, no scenario mining, no retraining loop |
| 10 | **Evaluation** | `writeDemoResults` M1–M10; `benchRuns` CIs; `whoDidWeHit`; **MathWorks baseline run unmodified: fails at 19.7 s, 0/120** | 348/348 tests | **Partial** | No head-to-head on a shared scenario; ORCA and always-yield baselines are not built; PS metrics only partly covered (replanning latency is not reported as the PS asks) |
| 11 | **Real-time** | profiler | **735.8 ms/step** (10 Hz budget = 100 ms → **7.4× too slow**); 88% of the time is spent in MathWorks' `dynamicCapsuleList` | **Weak** | Plays back a precomputed run; the only lever left is the candidate grid (35 → fewer), which costs plan quality |
| 12 | **Demo** | `sihDemo` one command; HUD with a live ML-gate row; live obstacle injection; fallback films | S1 + S3 play | **Partial** | S2 refused on purpose |

## Problem-statement compliance today (P0 checklist)
| PS requirement | Status |
|---|---|
| Full pipeline perception→prediction→planning→decision→motion in MATLAB/Simulink | Partial — MATLAB yes; Simulink only as a side model; perception is simulated tracks |
| Camera + LiDAR + radar | Lidar + radar yes; **camera offline** |
| Identify autos, pushcarts, pedestrians, animals | Offline YOLOX only; **pushcart has no training data** |
| Predict irregular motion | Intent model gated off; constant-velocity futures used in practice |
| Real-time replanning | **Not real-time** (7.4× over) |
| 5 scenarios | **2 working** (S1, S3); S2 broken; S4/S5 not driven |
| 2 RoadRunner scenes | **None** (no licence) |
| Metrics: latency, smoothness, completion | Partly (M10 wobble ≈ smoothness; latency is profiled, not reported per the PS) |
| Report + video + closed-loop validation | Films exist; closed loop is partial (scripted agents) |

## Assets worth keeping whatever we redesign
- the frozen interface contract (S1–S10), which lets any planner plug in
- the honest evidence machinery (results folder, CIs, the claim ledger)
- the real-map pipeline
- 348 tests
- the finding that MathWorks' baseline fails
