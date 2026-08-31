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

## Using the 93 GB of video — one rule decides everything

**Use the video to produce numbers the simulator can ALSO produce. Never numbers only the video
has.** Storage is not a constraint; this is not about disk or time.

**Permitted, and both are valuable:**

1. **Check whether the labels are trustworthy.** `Yield` is ticked 1 in 1,262. That is either
   genuinely rare, or annotators under-applied it - and those need opposite responses. Fetch ~20
   clips and look. This settles a decision that is currently blocking the whole stream, so **do it
   before anything else involving video.**
   ```bash
   python3 python/meteor/fetch_annotations.py --out <path> --videos 20
   ```
2. **Recover the ego's own motion.** METEOR records the car's position once per clip, not as it
   moves, so S2 features 28-31 are empty. The video shows ego motion through how the static
   background flows past the camera. The simulator knows its own speed exactly, so **both sources
   can produce this number** - it is safe to use.

**Forbidden, and the second one is dangerous:**

3. **Do not train a model that reads pixels.** The cuboid simulator emits an object list, not an
   image. A pixel model would have nothing to read at the moment the car drives. It could never be
   connected to the thing we are building.
4. **Do not add a feature the simulator cannot reproduce** - brake lights, indicator lamps, hand
   signals. A model that learns "brake lights on means they will yield" works on real footage, then
   meets a simulation with no brake lights, where that input is permanently blank. **The model then
   behaves differently from the one that was tested, with no error and no crash.** It looks like a
   planner fault and costs days to find. Object *orientation* is acceptable, because simulated
   actors have a yaw angle.

**Redundant:** do not train the detector on METEOR video. IDD Detection is 40,000 images already
prepared for exactly that.

## task: test-model
**Trigger:** "evaluate the model" / "is it ready for MATLAB"
**PRECONDITION:** a trained checkpoint exists. **Run this before `export-onnx`, never after.**
```bash
python3 python/model/evaluate.py --features <path> --model <checkpoint.pt> [--onnx <file>]
```
**What it decides:** not whether the model is accurate, but **whether it fails in the safe
direction**. The two mistakes are not equal - predicting yield when they do not is a car pulling
out in front of someone; predicting no-yield when they would have is a few seconds of waiting. The
script picks the threshold that keeps the dangerous error under 1%.
**Validation:** it prints READY FOR MATLAB or NOT READY.
**If NOT READY:** stop. Do not export. Report the whole output and wait.
**On success report three things:** the threshold, the dangerous-error rate, and the degradation
table. Below that threshold the planner treats the prediction as unusable and falls back to
geometry alone - S3 says never 0.5.
