# SIH26037 - agent rules

Read by Antigravity, Cursor and Claude Code.
**Section 3 below is the frozen contract. It is the reason five people can work at once.**

## The project
Smart India Hackathon 2026, problem statement **SIH26037** (MathWorks): adaptive path planning on
unstructured Indian roads.

> An Indian junction has no controller. We built the planner that negotiates instead of waiting -
> in MATLAB, against a cow that behaves like a cow.

PRD: a PDF, ask Aditya. Your tasks: your stream folder, `world/` `ml/` or `plan/`.
Who does what: `TEAM.md`.

**Machine-learning task? Read `ml/ML.md` first.** Planner task? Read `plan/ReadThis.md` first.
Neither loads automatically, and both carry facts you must not re-derive.

## 1 - Hard rules

**Never change section 3.** Six people build against it; a silent change breaks five.
If it needs changing, stop and ask a human.

**Never edit `matlab/baseline/`.** That is MathWorks' shipped planner, unmodified, and it is our
control arm. A tuned baseline is a strawman and kills the result.

**Verify, do not assume.** Never write a number you did not produce by running something.
`TODO(unverified)` is acceptable; a plausible number is not.

**Report errors in full.** A trimmed stack trace costs a day.

## 2 - Settled - do not reopen
- **No RoadRunner.** `drivingScenario` + `roadNetwork(...,'OpenStreetMap',f)` + OpenDRIVE export
- **Lidar and radar in the loop; camera offline.** The cuboid environment emits object lists, not
  pixels. Measured: a cow at 9.2 m is 77×63 px in a 140° dashcam frame
- **Two models, one loader: the LSTM and a dense-adjacency GNN.** Sparse message passing cannot
  import (no `Gather`/`Scatter`) - written as an adjacency **matmul + softmax** it imports fine.
  `Adjacency` exists for exactly this. **The LSTM ships first and is never blocked by the GNN.**
- **Do not import YOLO.** Use MATLAB's built-in YOLOX
- **Foundation is `mathworks/OpenTrafficLab`.** Subclass `DrivingStrategy`; delete `TrafficController`
- **Dataset is METEOR**, not IDD-X
- **Project the simulation down to the image plane. Never lift METEOR up to 3-D**

### Re-locked 31 Aug 2026 - design
- **Probe and commit is the mechanism.** Creep (S6=0.5), read the answer, commit or abort.
  Deleting `TrafficController` is a consequence, not the headline
- **COLREGs is a tie-break, not negotiation** - it buys legibility. Hill roads: *Rules of the
  Road, 1989* - **downhill gives way to uphill**
- **Contingency planning:** N paths 3-5 s ahead, each rolled under **two futures (yield/assert)**
  weighted by `PYield`, checked with `dynamicCapsuleList`, **commit only the trunk safe under
  both.** The trunk IS the probe. Rates: route 2-5 Hz - contingency 10 Hz - **barriers 50-100 Hz**
- **Two barriers:** `h_agent` for movers, `h_road` (S9) for the ground. **A khai returns no lidar
  points and can never be an S1 track. No mode switch - geometry decides which binds**
- **`v_max = min( sqrt(aLat*R), sqrt(2*aBrake*(VisibleRange - v*tReact)), vRoute )`.
  No weather mode** - bad weather shrinks `VisibleRange` and speed falls out
- **Reversibility:** escape breadcrumbs (S10) - point of no return sets `Committed` - blockage
  ladder ends in a **re-route** - galli deadlock: **nearer a passing place reverses**
- **Turn type is DERIVED from `S10.GoalHeading`, never classified.** No sign detection
- **Handover is terminal.** A driver is always in the seat - no remote operator. **Raise
  `Signal=6` BEFORE `Committed`** - a late handover is a failure (M11)
- **Three baselines:** Frenet **given the reference path it needs** - **ORCA** (assumes everyone
  runs it; a cow does not) - **always-yield**
- **Models (1 Sep 2026):** predictor -> Python->ONNX, LSTM + attention, **never Gather/Scatter** -
  spotter -> **YOLOX** (*not RTMDet* - inference-only in MATLAB) - road -> DeepLab v3+ -
  lidar -> **PointPillars, native MATLAB**
- **Split by clip, never by frame** - adjacent frames leak and inflate every score
- **IDD-3D is DATA, not a model:** replay real tracks; compare real vs simulated point clouds

## 3 - THE FROZEN CONTRACT

### S1 TrackList - Perception -> everyone
Sensor-agnostic: lidar and radar are fused *before* this struct.

| Field | Type | Units |
|---|---|---|
| `TrackID` | uint32 | stable across frames, never reused |
| `ClassID` | uint8 | see S5 |
| `Position` | 1x3 double | m, ego frame: x fwd, y left, z up |
| `Velocity` | 1x3 double | m/s |
| `Extent` | 1x3 double | m - length, width, height |
| `Yaw` | double | rad |
| `Existence` | double | 0-1 |
| `Age` | uint32 | frames |
| `SensorMask` | uint8 | bit0 lidar, bit1 radar, bit2 camera, **bit3 near-field ring** |

Four guarantees: sorted by `TrackID` - never contains the ego - **may be empty, and consumers must
not error** - no `NaN`/`Inf` in `Position` - drop the track instead.

### S2 FeatureFrame - 31 dims, depth-free
`1-2` u_c, v_c (box centre ÷ image size) - `3` v_bottom - `4-5` w, h - `6` log(w/h) -
`7-9` du, dv, dh - **`10` tau = h/(dh/dt)** clamp ±100 - `11` lateral closure -
`12-27` 16-way class one-hot - `28-30` ego speed, yaw rate, accel - `31` candidate action.

```
.Data [N x 31 single]  .Adjacency [N x N single]  .TrackIDs [N x 1 uint32]  .Timestamp double
```
Sequence: `[T x 31]`, T = 20 at 10 Hz. Front-pad when younger than T.
**`Adjacency` is always emitted even though the LSTM ignores it.** Do not remove it.
**Positions 1-31 are frozen and never move.** New features may only be *appended* at 32+, and
only with a changelog row. Stream D reads by position.

### S3 YieldPrediction
`.TrackIDs [N x 1 uint32]` - `.PYield [N x 1 double]` in [0,1] - `.Valid [N x 1 logical]`.
**When `Valid` is false the planner uses the geometric role alone - never 0.5.**

### S4 Role and EgoCommand
```
Role: .TrackID uint32  .Role uint8(S7)  .Beta double rad  .Lambda double rad  .TCPA double s
EgoCommand: .Accel double [-6,+3] m/s^2  .SteerAngle double [-0.6,+0.6] rad  .Mode uint8(S8)  .Reason string
            .MirrorsFolded logical   folding narrows the ego footprint ~20 cm - a real action
            .Signal uint8            0 none - 1 horn - 2 headlight flash - 3 declare blocked
                                     4 indicate left - 5 indicate right  (legibility is the point)
                                     6 REQUEST DRIVER HANDOVER - must be raised BEFORE .Committed
                                     goes true. India requires a driver in the seat, so this is the
                                     terminal state. Raising it after the point of no return is a
                                     failure, not a handover - log it as one (M11)
            .Gear int8               +1 forward - 0 hold - -1 REVERSE. Without reverse a 3-point
                                     U-turn and backing out of a galli are both impossible
            .Committed logical       true past the point of no return - planner must NOT re-decide
```
`beta = asin(dMin/d)`, `lambda = acos((v_r . r)/(|v_r| d))`. **Collision iff lambda < beta.**
Log `h = lambda - beta` every step - it is our safety evidence.

### S5 ClassID - never renumber
`0` unknown - `1` car - `2` truck - `3` bus - **`4` auto-rickshaw** - `5` motorbike - `6` scooter -
`7` van - `8` pedestrian - `9` bicycle - **`10` cow** - `11` dog - **`12` pushcart** -
**`13` animal-drawn cart** - `14` tractor - `15` static obstacle.
`drivingScenario` reserves its own 1-6 - use `sih.util.toSimClassID()`. **Never hardcode either.**

### S6 Candidate action (feature 31)
`0.0` hold - `1.0` accelerate/commit - `-1.0` decelerate/give way - `0.5` creep (probe)

### S7 Role codes
`0` SAFE - `1` GIVE_WAY (early, substantial; pass astern) - `2` STAND_ON (**hold course and speed**) -
`3` HEAD_ON - `4` OVERTAKING. Sector boundaries **22.5°, 90°, 112.5°**; sign of tCPA disambiguates.

### S8 Planner mode
`0` STRUCTURED (lanes exist - defer) - `1` UNSTRUCTURED (ours) - `2` EMERGENCY (`h < 0`).

### S9 DrivableSpace - Perception -> planner
A khai is not an object. Lidar returns **nothing** from a drop-off, so it can never appear in S1.
This carries the ground itself.

```
.Costmap      vehicleCostmap   wraps MathWorks' shipped object - do NOT invent a new one
.EdgeDistance double  m   signed distance to the drivable boundary, + inside
.EdgeSide     uint8       0 unknown - 1 wall/rising - 2 drop/falling
.VisibleRange double  m   furthest confidently-observed ground along the path
.Valid        logical     false => planner falls back to a fixed conservative corridor
```

Two rules the planner must honour:
- **`d_min = f(EdgeSide, speed)` - asymmetric AND speed-dependent.** Larger on `EdgeSide == 2`
  than on `1`: a wall dents a panel, a drop is fatal - weighted by **consequence**, not collision
  probability. And larger with speed: at 2 km/h centimetres will do, at 40 km/h you need ~1.5 m.
  **Footprint is the real body including mirrors, and shrinks when `MirrorsFolded` is true.**
  Check the **swept path of the whole body**, not the centreline.
- **Speed is capped by sight:** `v_max = sqrt(2*aBrake*(VisibleRange - v*tReact))`.

`h_road = EdgeDistance - dMin(EdgeSide) >= 0` is a barrier of the same form as `h = lambda - beta`.
**Both must hold. No mode switch** - geometry decides which binds.

### S10 Route - coarse goal, and it must be re-plannable
Not a navigator. It supplies a goal and accepts failure feedback.
```
.GoalHeading  double rad   direction of the next goal - TURN TYPE IS DERIVED FROM THIS, never classified
.GoalPoint    1x2 double m ego frame
.BlockedEdges uint32 []    edges the planner has declared impassable - route AROUND them
.EscapePoints Nx3 double   breadcrumbs [x y width_m] of places wide enough to turn around in
```
**Turn type is derived:** heading change ~180° + tight radius = U-turn - ~90° across a stream = cut.
**No sign detection, no classifier.**
`v_max = min( sqrt(aLat*R), sqrt(2*aBrake*(VisibleRange - v*tReact)), vRoute )`.

### File formats
`results/<run>/trajectories.csv` -> `t,actor_id,class_id,x,y,z,yaw`, SI units, header row -
`results/<run>/metrics.json` -> keys `M1`-`M10` - `results/<run>/config.json` -> **a copy of the
inputs; a number without its config is not a result** -
`ml/python/export/yield_lstm_opset<N>.onnx` -> in `sequence [1,20,31]`, out `yield_logits [1,2]` -
`ml/python/export/yield_gnn_opset<N>.onnx` -> in `sequence [1,A,20,31]` + `adjacency [1,A,A]`,
out `yield_logits [1,A,2]`. **`A` = max agents, fixed at export and recorded in `config.json`.**
The two are interchangeable at the S3 boundary: both produce `PYield` per `TrackID`.

## 4 - Stack
MATLAB R2024b+ / Simulink / Stateflow - Automated Driving, Computer Vision, Image Processing,
Deep Learning, Sensor Fusion & Tracking, Navigation, Lidar toolboxes - Python 3.11 + PyTorch +
ONNX - Blender 4.x Cycles - ONNX -> `importNetworkFromONNX` -> Simulink **Predict** block
(not ONNX Model Predict - that is simulation-only). Opsets: R2024b 6-18, R2025a+ 6-20.

## 5 - Conventions
- All project code in `matlab/+sih/`. Call as `sih.planner.assignRoles(...)`
- **`lanespec` is lowercase.** `laneSpec` does not exist. This has already cost us once
- One function per file. Every public function documents its inputs with units and names the
  contract struct it produces or consumes
- **SI units always.** Put the unit in the name where ambiguous: `dist_m`, `angle_rad`, `t_s`
- Prefer `arguments` blocks over manual `nargin` checks
- Python: type hints on public functions, `pathlib.Path` not strings
- `ml/python/meteor/features.py` and its MATLAB twin must produce identical vectors

## 6 - Never
- Never commit datasets, `.onnx` weights, or `results/`
- Never hardcode a path under `/Users/` or `C:\`
- Never invent a number
- Never edit `matlab/baseline/`
