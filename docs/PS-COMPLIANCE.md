# Compliance matrix — SIH26037

Every requirement MathWorks stated, quoted, mapped to where we satisfy it. **One deliberate
deviation, declared.** This document is also useful in the room: it is the checklist a judge
would otherwise build in their head.

## Part 1 — the pipeline

> "build a working simulation pipeline that integrates **perception, prediction, path planning,
> decision logic, and vehicle motion** in MATLAB and Simulink"

| Required | Where | Status |
|---|---|---|
| Perception | `matlab/+sih/+perception/` — lidar + radar + tracking | planned |
| Prediction | `matlab/+sih/+prediction/` + ONNX LSTM in a Simulink Predict block | planned |
| Path planning | `matlab/+sih/+planner/` — velocity obstacle | **code written** |
| Decision logic | Stateflow, COLREGs roles | **code written** |
| Vehicle motion | Simulink bicycle model | planned |
| In MATLAB and Simulink | entire stack. No external simulator | by construction |

## Sensing — all three named modalities

> "perceive the environment using a **multi-sensor setup such as camera, LiDAR, and radar**"

| Modality | Our use | Generator |
|---|---|---|
| **LiDAR** | **In the loop.** The cuboid environment emits real point clouds | `lidarPointCloudGenerator` |
| **Radar** | **In the loop**, fused with lidar. Robust where lidar degrades — dust, rain | `drivingRadarDataGenerator` |
| **Camera** | Offline. Detector trained on IDD, benchmarked on real Indian video | `visionDetectionGenerator` + YOLOX |

**Why camera is offline and we say so plainly:** the cuboid environment gives object lists, not
pixels, so a detector cannot consume it in the loop. Measured support for the decision — a cow at
9.2 m is only **77 x 63 pixels** in a 140-degree dashcam frame. We report camera performance
separately rather than pretending it is in the loop.

## Road users we must identify

> "auto-rickshaws, pushcarts, pedestrians, and animals"

All four are in the ClassID table (`docs/INTERFACES.md` S5): auto-rickshaw **4**, pedestrian **8**,
cow/cattle **10**, pushcart **12**, animal-drawn cart **13**.

## The five scenarios — all five required, all five built

> "validate their solution using **at least five** realistic Indian road scenarios"

**Build order is two-perfect-first, then coverage. That is an ordering, not a reduction.**

| # | Scenario | Priority | Honest expectation |
|---|---|---|---|
| 1 | **Urban intersection without signals** | **Perfect first** | Where we win. No controller exists to defer to |
| 2 | **Sudden cattle crossing** | **Perfect first** | Where we win. Nobody models animals as agents |
| 3 | Dense market, mixed traffic | Coverage | Where we expect to win — highest agent density |
| 4 | Unmarked village road | Coverage | **Baseline copes at low density. Our contribution is small here and we say so** |
| 5 | Highway merge, slow vehicles | Coverage | **Lane-based methods genuinely beat us. We do not claim this win.** Planner detects structure and switches to STRUCTURED mode (S8) |

Scenarios 4 and 5 are reported honestly. A planner that knows when it is not needed is evidence of
judgement, not weakness.

## Part 2 — scenes

> "including **at least two detailed RoadRunner scenes** such as a village road and an urban
> intersection"

**THE ONE DEVIATION, DECLARED.**

RoadRunner is not on licence 41087767 and is not included in student licences. Our answer:

1. Scenes are built programmatically with the `drivingScenario` API — which is **scriptable**,
   so we generate many junction variants where a GUI tool produces one.
2. Real geometry comes from **OpenStreetMap** — `roadNetwork(scenario,'OpenStreetMap',f)` — the
   same source Team TwinX used.
3. Every scene is **exported as OpenDRIVE** via `export(scenario,'OpenDRIVE',...)`. **They import
   into RoadRunner the day a licence arrives.**

Status: licence request sent to the institutional administrator. If granted, this deviation closes.

## Part 3 — results

> "collision-free performance, smooth path generation, and timely replanning"

| Their metric | Ours | Notes |
|---|---|---|
| collision-free performance | **M4** weighted infractions, **M5** minimum TTC | Uses CARLA's own coefficients so the numbers are comparable |
| smooth path generation | **M7** path smoothness | Integral of squared lateral jerk + peak lateral acceleration |
| timely replanning | **M6** replanning latency | mean, p95, max |
| scenario completion rate | **M2** completion vs density | Reported as a curve, not a single figure |

**Plus six metrics they did not ask for**, including the perception-degradation curve (M3) and the
yield ledger (M8). See `docs/metrics.md`.

## Final submission

| Required | Ours | Status |
|---|---|---|
| The simulation model | `matlab/` + Simulink models | planned |
| The designed scenarios | all five, plus config files | planned |
| Performance results with metrics | `results/<run>/metrics.json`, one command regenerates all | planned |
| **A short technical report** | `report/TECHNICAL-REPORT.md` -> PDF | **planned — Phase 5.4** |
| A demonstration video | Blender renders + Meerut composite + screen capture | planned |
| Closed-loop validation | poses fed back through the Non-ego Actor Poses input port | core of the design |

## Where we go beyond what was asked

| Beyond | Why it matters |
|---|---|
| **An unmodified third-party baseline** | They did not ask for a control arm. Without one, "it works" is unfalsifiable |
| **Metrics pre-registered before any run** | Nobody can say we picked metrics that flattered the result |
| **The perception-degradation curve** | No incumbent publishes it. B-GAP admits it needs "very good sensing" |
| **Everything released publicly** | A benchmark is citable. A private demo is not |
| **An interactive demo** | The judge causes the baseline to fail themselves |
