---
trigger: model_decision
description: Load when the task involves the machine-learning pipeline - METEOR data, downloading or preprocessing the dataset, the 31-feature vector, training the yield predictor, evaluation metrics, ONNX export, or the detector/segmentation/lidar models. Do not load for MATLAB planner, Simulink or scenario work.
---

# ML work: read ML.md first

**Read `ML.md` at the repository root before writing any code for this task.** It is not loaded
automatically. It carries facts about this dataset that were measured by running code, and
re-deriving them wastes a day each.

## The procedures are workflows

| Command | What it does |
|---|---|
| **`/ml-run`** | The whole pipeline: features -> split -> train -> evaluate -> export |
| **`/ml-parity`** | Proves the Python and MATLAB feature builders still agree |
| **`/ml-models`** | Models 3-5: YOLOX spotter, DeepLab v3+ road, PointPillars lidar - all MATLAB-native |

They live in `.agents/workflows/`. Open the file and follow it if a slash command does not resolve.

## Five facts that cause the most damage when guessed

- **There is no per-agent 3-D in METEOR.** The `x-axis/y-axis/z-axis` fields are the ego vehicle's
  own position repeated on every object. Never build 3-D positions from them.
- **The feature vector is 31 values in a fixed order.** Positions 1-31 never move. Append only at
  32+, and only with a changelog row. Stream D reads them by position.
- **`Gather` is not only a message-passing problem.** `out[:, -1, :]` and reading `x.shape` at
  runtime both emit it. Use `torch.flatten(out[:, -1:, :], 1)` and compile-time constants.
- **torch lies about the opset.** Requesting 9, 11 or 13 writes a file stamped 18. Always read the
  opset back out of the file before reporting it — that number unblocks the planner stream.
- **The label is far too rare to train on as it stands**: 109 positives in 68,011 samples, 6 of
  them in validation, measured over 39 of METEOR's 2,502 clips. Reporting a precision or recall
  from a set that size without saying so is misleading, not merely incomplete.

## Never download without being asked

A download spends someone else's disk and bandwidth. METEOR's annotations are 1.81 GB down and
10.28 GB on disk. State the cost, then wait for a yes.
