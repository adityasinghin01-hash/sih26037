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
