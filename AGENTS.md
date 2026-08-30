# SIH26037 — agent rules

Read by Antigravity, Cursor and Claude Code. Always applies.
**Section 3 below is the frozen contract. It is the reason five people can work at once.**

## The project
Smart India Hackathon 2026, problem statement **SIH26037** (MathWorks): adaptive path planning on
unstructured Indian roads.

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, against a cow that behaves like a cow.

The full PRD is distributed as a PDF, not kept in this repo. Your own tasks are in
`teammates/<stream>.md`.

## 1 · Hard rules

**Never change section 3.** Five people build against it. A silent change breaks four of them.
If you think it needs changing, stop and ask a human.

**Never edit `matlab/baseline/`.** That is MathWorks' shipped planner, unmodified, and it is our
control arm. A tuned baseline is a strawman and kills the result.

**Verify, do not assume.** Never write a number you have not produced by running something.
`TODO(unverified)` is acceptable; a plausible-sounding number is not.

**Errors are reported in full.** Never summarise a stack trace. A trimmed error costs a day.

**Nothing ships with a bug already reproduced in the demo flow.**

## 2 · Settled — do not reopen
- **No RoadRunner.** `drivingScenario` + `roadNetwork(...,'OpenStreetMap',f)` + OpenDRIVE export
- **Lidar and radar in the loop; camera offline.** The cuboid environment emits object lists, not
  pixels. Measured: a cow at 9.2 m is 77×63 px in a 140° dashcam frame
- **LSTM, not GNN.** ONNX import lacks Gather/Scatter. The adjacency matrix is emitted anyway
- **Do not import YOLO.** Use MATLAB's built-in YOLOX
- **Foundation is `mathworks/OpenTrafficLab`.** Subclass `DrivingStrategy`; delete `TrafficController`
- **Dataset is METEOR**, not IDD-X
- **Project the simulation down to the image plane. Never lift METEOR up to 3-D**

## 3 · THE FROZEN CONTRACT

### S1 TrackList — Perception → everyone
Sensor-agnostic: lidar and radar are fused *before* this struct.

| Field | Type | Units |
|---|---|---|
| `TrackID` | uint32 | stable across frames, never reused |
| `ClassID` | uint8 | see S5 |
| `Position` | 1x3 double | m, ego frame: x fwd, y left, z up |
| `Velocity` | 1x3 double | m/s |
| `Extent` | 1x3 double | m — length, width, height |
| `Yaw` | double | rad |
| `Existence` | double | 0–1 |
| `Age` | uint32 | frames |
| `SensorMask` | uint8 | bit0 lidar, bit1 radar, bit2 camera |

Four guarantees: sorted by `TrackID` · never contains the ego · **may be empty, and consumers must
not error** · no `NaN`/`Inf` in `Position` — drop the track instead.

### S2 FeatureFrame — 31 dims, depth-free
`1-2` u_c, v_c (box centre ÷ image size) · `3` v_bottom · `4-5` w, h · `6` log(w/h) ·
`7-9` du, dv, dh · **`10` tau = h/(dh/dt)** clamp ±100 · `11` lateral closure ·
`12-27` 16-way class one-hot · `28-30` ego speed, yaw rate, accel · `31` candidate action.

```
.Data [N x 31 single]  .Adjacency [N x N single]  .TrackIDs [N x 1 uint32]  .Timestamp double
```
Sequence: `[T x 31]`, T = 20 at 10 Hz. Front-pad when younger than T.
**`Adjacency` is always emitted even though the LSTM ignores it.** Do not remove it.

### S3 YieldPrediction
`.TrackIDs [N x 1 uint32]` · `.PYield [N x 1 double]` in [0,1] · `.Valid [N x 1 logical]`.
**When `Valid` is false the planner uses the geometric role alone — never 0.5.**

### S4 Role and EgoCommand
```
Role: .TrackID uint32  .Role uint8(S7)  .Beta double rad  .Lambda double rad  .TCPA double s
EgoCommand: .Accel double [-6,+3] m/s^2  .SteerAngle double [-0.6,+0.6] rad  .Mode uint8(S8)  .Reason string
```
`beta = asin(dMin/d)`, `lambda = acos((v_r . r)/(|v_r| d))`. **Collision iff lambda < beta.**
Log `h = lambda - beta` every step — it is our safety evidence.

### S5 ClassID — never renumber
`0` unknown · `1` car · `2` truck · `3` bus · **`4` auto-rickshaw** · `5` motorbike · `6` scooter ·
`7` van · `8` pedestrian · `9` bicycle · **`10` cow** · `11` dog · **`12` pushcart** ·
**`13` animal-drawn cart** · `14` tractor · `15` static obstacle.
`drivingScenario` reserves its own 1–6 — use `sih.util.toSimClassID()`. **Never hardcode either.**

### S6 Candidate action (feature 31)
`0.0` hold · `1.0` accelerate/commit · `-1.0` decelerate/give way · `0.5` creep (probe)

### S7 Role codes
`0` SAFE · `1` GIVE_WAY (early, substantial; pass astern) · `2` STAND_ON (**hold course and speed**) ·
`3` HEAD_ON · `4` OVERTAKING. Sector boundaries **22.5°, 90°, 112.5°**; sign of tCPA disambiguates.

### S8 Planner mode
`0` STRUCTURED (lanes exist — defer) · `1` UNSTRUCTURED (ours) · `2` EMERGENCY (`h < 0`).

### File formats
`results/<run>/trajectories.csv` → `t,actor_id,class_id,x,y,z,yaw`, SI units, header row ·
`results/<run>/metrics.json` → keys `M1`–`M10` · `results/<run>/config.json` → **a copy of the
inputs; a number without its config is not a result** ·
`python/export/yield_lstm_opset<N>.onnx` → in `sequence [1,20,31]`, out `yield_logits [1,2]`.

## 4 · Stack
MATLAB R2024b+ / Simulink / Stateflow · Automated Driving, Computer Vision, Image Processing,
Deep Learning, Sensor Fusion & Tracking, Navigation, Lidar toolboxes · Python 3.11 + PyTorch +
ONNX · Blender 4.x Cycles · ONNX → `importNetworkFromONNX` → Simulink **Predict** block
(not ONNX Model Predict — that is simulation-only). Opsets: R2024b 6–18, R2025a+ 6–20.

## 5 · Conventions
- All project code in `matlab/+sih/`. Call as `sih.planner.assignRoles(...)`
- **`lanespec` is lowercase.** `laneSpec` does not exist. This has already cost us once
- One function per file. Every public function documents its inputs with units and names the
  contract struct it produces or consumes
- **SI units always.** Put the unit in the name where ambiguous: `dist_m`, `angle_rad`, `t_s`
- Prefer `arguments` blocks over manual `nargin` checks
- Python: type hints on public functions, `pathlib.Path` not strings
- `python/meteor/features.py` and its MATLAB twin must produce identical vectors

## 6 · Never
- Never commit datasets, `.onnx` weights, or `results/`
- Never hardcode a path under `/Users/` or `C:\`
- Never invent a number
- Never edit `matlab/baseline/`
