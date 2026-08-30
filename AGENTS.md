# SIH26037 — agent rules

Read by Antigravity, Cursor and Claude Code. Project-wide, always applies.

## What this is
Smart India Hackathon 2026, problem statement **SIH26037** (MathWorks, Smart Vehicles):
adaptive path planning and collision avoidance on unstructured Indian roads.

**One line:** an Indian junction has no controller; we built the planner that negotiates instead
of waiting — in MATLAB, against a cow that behaves like a cow.

## Read before writing any code
1. **`docs/PRD.md` — the only project document.** Section 7 is the **frozen contract**: every
   struct that crosses a module boundary. Section 8 is what we measure. Section 9 is what we are
   allowed to claim.
2. `teammates/<your-stream>.md` — your own tasks and handoffs.
3. `~/Desktop/SIH26037-Research.html` — full research, 18 sections, every claim sourced.

## Hard rules

**Never change section 7 of `docs/PRD.md` (the frozen contract) without telling everyone.**
Five people build in parallel against it. A silent change breaks four of them.

**Verify, do not assume.** Before writing any number into a doc, slide or comment, run the thing
that produces it. This project's whole pitch is that its claims are checkable. If you cannot run
it, write `TODO(unverified)` and say so.

**The baseline is sacred.** `matlab/baseline/` holds MathWorks' shipped planner
("Motion Planning in Urban Environments Using Dynamic Occupancy Grid Map"), **completely
unmodified**. Never edit, tune or "fix" anything in that folder. A tuned baseline is a strawman
and kills the result.

**Novelty phrasing is always "no public work we could find"** — never "this has never been done."

**Nothing ships with a bug already reproduced in the demo flow.** A previous hackathon was lost
exactly that way.

**Errors are reported in full.** Never summarise a stack trace.

## Stack
| Layer | Tool |
|---|---|
| Scenarios, planner, simulation | MATLAB R2024b+ / Simulink / Stateflow |
| Toolboxes | Automated Driving, Computer Vision, Image Processing, Deep Learning, Sensor Fusion & Tracking, Navigation, Lidar, Stateflow |
| Data pipeline, model training | Python 3.11, PyTorch, ONNX |
| Model in the loop | ONNX → `importNetworkFromONNX` → Simulink **Predict** block |
| Rendering | Blender 4.x, Cycles |
| **No RoadRunner** | not on our licence. Scenes are built with the `drivingScenario` API and exported as OpenDRIVE |

## Settled — do not reopen
- **No RoadRunner.** Everything via `drivingScenario`. Real geometry via
  `roadNetwork(scenario,'OpenStreetMap',f)`.
- **In-loop perception is lidar, not camera.** The cuboid environment emits point clouds, not
  pixels. Measured: a cow at 9.2 m is only 77×63 px in a 140° dashcam frame.
- **The prediction model is an LSTM.** GNNs need Gather/Scatter, unsupported by ONNX import.
  LSTM/GRU import cleanly. The GNN is a parallel upgrade track only.
- **Do not import YOLO.** Use MATLAB's built-in YOLOX.
- **Foundation is `mathworks/OpenTrafficLab`.** Subclass `DrivingStrategy`; delete
  `TrafficController` and replace it with COLREGs role negotiation.
- **Dataset is METEOR.** IDD-X labels why the *ego* acted — wrong direction of causality.
- **Two scenarios perfect** — the unsignalled junction and the cattle crossing. Not five rough.
- **Project the simulation down to the image plane. Never lift METEOR up to 3D.** Lifting needs
  monocular depth; 1° of camera pitch error is ~31% depth error at 30 m.

## MATLAB conventions
- All project code lives in the package `matlab/+sih/`. Call it as `sih.planner.assignRoles(...)`.
- **`lanespec` is lowercase.** `laneSpec` does not exist. This has already cost us once.
- One function per file, named the same as the file.
- Every public function starts with a comment block: purpose, inputs with units, outputs, and
  which struct from `docs/PRD.md` it produces or consumes.
- Units are **SI, always**: metres, seconds, radians, m/s. Put the unit in the variable name when
  it could be ambiguous — `dist_m`, `angle_rad`, `t_s`.
- No `clear all`, no `close all`, no `clc` inside functions.
- Prefer `arguments` blocks for validation over manual `if nargin`.

## Python conventions
- `python/meteor/` — dataset parsing and the feature builder.
- `python/model/` — the LSTM. `python/export/` — ONNX export only.
- Type hints on every public function. `pathlib.Path`, never string paths.
- The feature builder must produce **byte-identical** vectors to the MATLAB one for the same
  input. `python/tests/test_parity.py` is the check that proves it. Keep it passing.

## Never
- Never commit dataset files, `.onnx` weights, or anything in `results/` — see `.gitignore`.
- Never hardcode a path under `/Users/` or `C:\`. Use `configs/paths.json`.
- Never invent a number. Never write "approximately" where a measured value belongs.
- Never edit `matlab/baseline/`.
