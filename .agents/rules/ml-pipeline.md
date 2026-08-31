---
trigger: model_decision
description: Load when the task involves the machine-learning pipeline - METEOR data, downloading or preprocessing the dataset, the 31-feature vector, training the yield predictor, evaluation metrics, ONNX export, or the detector/segmentation/lidar models. Do not load for MATLAB, Simulink, scenario or planner work.
---

# ML work: read ML.md first

**Read `ML.md` at the repository root before writing any code for this task.** It is not loaded
automatically.

It contains verified facts about the dataset that you must not re-derive or guess, and seven task
definitions with their own validation steps.

Three facts that cause the most damage when guessed:
- **There is no per-agent 3-D in METEOR.** The `x-axis/y-axis/z-axis` fields are the ego vehicle's
  own position repeated on every object. Never build 3-D positions from them.
- **The feature vector is 31 values in a fixed order.** Positions 1-31 never move. Append only at 32+.
- **Model 2 uses attention.** `Gather` and `Scatter` do not import into MATLAB, so sparse message
  passing fails at the final step.

## What the data actually contains — measured, not assumed

Audited across 24 clips and 25,247 labelled object-frames on 1 Sep 2026. **Do not re-derive
these. Do check them at full scale, since 24 clips is 2% of the dataset.**

**Label positive rates — the target label is the rarest in the set:**

| Label | rate | note |
|---|---|---|
| `OverTaking` | **1 in 25** | most usable label in the dataset |
| `LaneChanging` | 1 in 64 | usable |
| **`Yield`** | **1 in 1,262** | our intended target |
| **`Cutting`** | **1 in 1,578** | our other intended target |
| `ZigzagMovement` | **0 positives** | defined in the schema, never filled in |
| `OverSpeeding` | **0 positives** | defined in the schema, never filled in |

**Consequence:** a classifier trained on `Yield` alone can answer "no" every time and score 99.9%.
Class weighting is applied automatically by `train.py`, but weighting cannot invent signal.

**Two options exist. Aditya decides, not you — report and wait:**
1. **Label per track rather than per frame.** `keyframe` is roughly 50/50, so about half the boxes
   are CVAT interpolations rather than human marks. If `Yield` was ticked as an *event* on a
   keyframe rather than held through the manoeuvre, per-frame labelling dilutes it heavily.
2. **Predict assertiveness instead of yielding** — `OverTaking OR LaneChanging OR Cutting`,
   roughly 1 in 18. About 70x more signal, and for a planner "they will not assert" carries nearly
   the same meaning as "they will yield".

**Other measured facts:**
- **13.5% of frames contain no annotated objects.** They yield no samples. Not an error.
- **Clip length varies: 270 to 1800 frames.** "One minute at 30 Hz" is not universal.
- **`Animal` appears 5 times in 24 clips.** METEOR cannot teach animal behaviour. The cow stays
  simulated. Do not attempt to learn it from this data.
- **`Behaviour` values are dirty**: `false`, `False`, and `fasle` (misspelt), mixed with `Start`
  and `End` markers. Compare case-insensitively and treat unknown values as false.
- **`RuleBreak` is not boolean** — it holds `false` or a reason such as `WrongLane`.
- Clean: no zero-area or out-of-bounds boxes, no frame-number gaps, image size always 1920x1080,
  no track ID changes class, every class name maps.
