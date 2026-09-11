---
trigger: model_decision
description: Load when the task involves the PLANNER - COLREGs roles, the velocity obstacle, the safety barrier h, contingency or candidate paths, the Stateflow chart, the closed-loop Simulink model, reversibility, handover, or anything under matlab/+sih/+planner. Do NOT load for the machine-learning pipeline, the dataset, the feature vector, ONNX export, or scenario building.
---

# Planner work: read plan/ReadThis.md first

**Read `plan/ReadThis.md`** before writing anything. It explains the mechanism — why the trunk
IS the probe, why there are two barriers, why turn types are derived rather than classified.

**As of the 10 September restructure, the Planner track is Antara and Anjali, independently —
not a two-person split of one job.** `plan/CONTRACT-AB.md` describes that older, no-longer-
current arrangement (one person on pure functions, one on the Simulink model) — check
`HANDOFF.md` for what each of them is actually building right now before assuming which workflow
applies.

**Workflows available:**

| | |
|---|---|
| **`/plan-work`** | The planner build order — pure MATLAB functions in `matlab/+sih/+planner/` |
| **`/plan-harness`** | The Simulink model and Stateflow chart, **if that piece of work is still live for anyone** — it was last recorded as merged and dormant, so check before assuming it's someone's active task |
| `/plan-test` | the geometry tests, and what a failure means |

## Stay inside the planner

| Yours | NOT yours — say so and stop |
|---|---|
| `matlab/+sih/+planner/`, `matlab/+sc/`, the Simulink model and chart if still live | `ml/` and everything in it |
| `matlab/+sih/+metrics/` reads your logs | `matlab/+sih/+prediction/`, `+models/` — the ML track |
| | `matlab/+sih/+scenario/`, `+perception/` — Aditya's World track |

**The predictor is not yours.** You consume `S3 PYield` through the contract and never open the
model that produced it. If `PYield` looks wrong, report it to the ML track (Shourya or Kishan) —
do not go and retrain anything.

## Four things that are settled

- **`h = lambda - beta` must never go below zero, and it is logged every step.** That log is our
  safety evidence. **Never clip a violation to make a run look clean** — a hidden `h < 0` is the
  one thing that would genuinely invalidate this project.
- **When `S3.Valid` is false, use the geometric role alone. Never 0.5.** A made-up probability is
  worse than none, because the planner trusts the number it is given.
- **`Accel` is clamped to `[-6, +3]` m/s², `SteerAngle` to `[-0.6, +0.6]` rad.** S4 fixes those.
- **`Signal = 6` (handover) must be raised BEFORE `.Committed` goes true.** A handover requested
  after the point of no return is abdication, not safety, and M11 counts it as a failure.

## Before it will even load

`NegotiatingStrategy.m` extends `DrivingStrategy`, which lives in **OpenTrafficLab — not in this
repository**, deliberately, because it is third-party code.

```bash
git clone https://github.com/mathworks/OpenTrafficLab.git
```

Without it MATLAB says `Undefined base class 'DrivingStrategy'`, which reads like our code is
broken. It is not.

## Never edit a test to make it pass
The 14 geometry tests encode `AGENTS.md` S4 and S7. A test edited to go green hides a planner
that will drive into something.

```matlab
runtests('matlab/tests/testPlannerGeometry.m')   % the .m is REQUIRED - without it MATLAB
                                                % errors: UnrecognizedSuite
```

## OpenTrafficLab does not run unmodified on R2026a
Answered by running it on 4 September 2026. Stock `DrivingStrategy` dies on the first
`advance()` with `MATLAB:noSuchMethodOrField ... 'ReferencePoint'`. Two fixes, both **outside**
`OpenTrafficLab/`, both applied. **Read `plan/OPENTRAFFICLAB-R2026a.md` before debugging any
harness failure** — you will otherwise spend a day on a known incompatibility.
