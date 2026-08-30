# SIH26037 — the interface contract

**FROZEN.** Changing anything here requires a written reason in `docs/CHANGELOG.md` and a message
to every owner. The point of this document is that six people can build in parallel without
asking each other a single question.

Read `docs/ARCHITECTURE.md` first for the picture. This is the wiring.

---

## The pipeline, and who owns each edge

```
 [A] Scenario ──ActorPoses──► [B] Perception ──TrackList──► [C] Features ──FeatureFrame──► [C] Predictor
                                                                                                │
                                                                                          YieldProb
                                                                                                ▼
 [A] Scenario ◄──EgoCommand── [D] Bicycle model ◄──EgoCommand── [D] Planner ◄──Roles── [D] RoleAssigner
                                                                     ▲
                                                                TrackList
```

Every arrow is a struct defined below. **If it is not in this file, it does not cross a module
boundary.**

---

## S1 · TrackList — Perception (B) → everyone downstream

One struct array, one element per tracked agent, produced every sample step.

**Sensor-agnostic by design.** Lidar and radar detections are fused *before* this struct, so
nothing downstream knows or cares which sensor produced a track. Adding a sensor never changes
this interface — it only changes what feeds the tracker.

| Source | Generator | Role |
|---|---|---|
| **Lidar** | `lidarPointCloudGenerator` | Primary. Real point clouds, extent estimation |
| **Radar** | `drivingRadarDataGenerator` | Fused. Direct range-rate, and it degrades differently from lidar in dust and rain |
| Camera | `visionDetectionGenerator` | **Offline only.** Object lists, not pixels — see `docs/PS-COMPLIANCE.md` |

The `SensorMask` field records which sensors contributed, so the perception-degradation sweep (M3)
can knock out one modality at a time.

| Field | Type | Units | Meaning |
|---|---|---|---|
| `TrackID` | `uint32` | — | Stable across frames. Never reused within a run |
| `ClassID` | `uint8` | — | See §S5. `0` = unknown |
| `Position` | `1x3 double` | m | Ego-vehicle frame: x forward, y left, z up |
| `Velocity` | `1x3 double` | m/s | Same frame |
| `Extent` | `1x3 double` | m | Length, width, height of the fitted box |
| `Yaw` | `double` | rad | Heading in the ego frame, `atan2` convention |
| `Existence` | `double` | 0–1 | Tracker confidence |
| `Age` | `uint32` | frames | How long this track has been alive |
| `SensorMask` | `uint8` | bitfield | bit0 lidar, bit1 radar, bit2 camera. Which sensors saw it |

**Guarantees B must uphold**
1. Sorted by ascending `TrackID`.
2. Never contains the ego vehicle.
3. May be empty (`0x1 struct`). Every consumer must handle that without erroring.
4. `Position` is finite. No `NaN`, no `Inf`. Drop the track instead.

---

## S2 · FeatureFrame — Features (C) → Predictor (C)

The 31-dimension vector from research section 11. **Depth-free by construction**, so the same
builder works on METEOR video and on simulated lidar.

| Idx | Name | Source |
|---|---|---|
| 1–2 | `u_c`, `v_c` | box centre / image size |
| 3 | `v_bottom` | box foot / image height |
| 4–5 | `w`, `h` | box size / image size |
| 6 | `log_aspect` | `log(w/h)` |
| 7–9 | `du`, `dv`, `dh` | per-second rates |
| 10 | `tau` | `h / (dh/dt)`, clamped to ±100 |
| 11 | `lat_closure` | `d(u − u_ego)/dt` |
| 12–27 | `class_onehot` | 16-way, §S5 |
| 28 | `ego_speed` | m/s |
| 29 | `ego_yawrate` | rad/s |
| 30 | `ego_accel` | m/s² |
| 31 | `cand_action` | the ego manoeuvre being scored, §S6 |

```
FeatureFrame
  .Data       [N x 31 single]   N agents, row order matches TrackList
  .Adjacency  [N x N single]    symmetric, 1 if pair within 15 m, 0 otherwise, diagonal 0
  .TrackIDs   [N x 1 uint32]    to map rows back to tracks
  .Timestamp  double            seconds
```

**`Adjacency` is emitted from day one even though the LSTM ignores it.** It is what makes the
graph-network swap a ~60-line change. Do not remove it. Do not make it optional.

**Sequence form for the model:** `[T x 31]` per agent, `T = 20` frames at 10 Hz = 2.0 s.
Pad at the front with the earliest frame when a track is younger than T.

---

## S3 · YieldPrediction — Predictor (C) → Planner (D)

```
YieldPrediction
  .TrackIDs  [N x 1 uint32]
  .PYield    [N x 1 double]   probability in [0,1] that this agent yields to the ego
  .Valid     [N x 1 logical]  false when the track is younger than T frames
```

When `Valid(i)` is false the planner **must** fall back to the geometric role alone. It must not
treat an invalid prediction as 0.5.

---

## S4 · Roles and EgoCommand — Planner (D)

```
Role                                EgoCommand
  .TrackID   uint32                   .Accel      double   m/s^2, [-6, +3]
  .Role      uint8  (§S7)             .SteerAngle double   rad,   [-0.6, +0.6]
  .Beta      double  rad               .Mode       uint8   (§S8)
  .Lambda    double  rad               .Reason     string  one short line, for the log
  .TCPA      double  s
```

`Beta` and `Lambda` are the velocity-obstacle quantities from research section 15:
`beta = asin(d_min/d)`, `lambda = acos((v_r·r)/(|v_r| d))`. **Collision iff `lambda < beta`.**
Log both every step — `h = lambda − beta` is our barrier function and the safety evidence.

---

## S5 · ClassID — the one table everybody uses

METEOR's 16 categories, mapped onto our simulated classes. **Never renumber.**

| ID | Class | | ID | Class |
|---|---|---|---|---|
| 0 | unknown | | 8 | pedestrian |
| 1 | car | | 9 | bicycle |
| 2 | truck | | 10 | **cow / cattle** |
| 3 | bus | | 11 | dog |
| 4 | **auto-rickshaw** | | 12 | **pushcart** |
| 5 | motorbike | | 13 | **animal-drawn cart** |
| 6 | scooter | | 14 | tractor |
| 7 | van | | 15 | static obstacle |

MATLAB `drivingScenario` reserves its own ClassIDs 1–6. Use `sih.util.toSimClassID()` to convert.
**Never hardcode either numbering.**

---

## S6 · Candidate actions (feature 31)

| Value | Meaning |
|---|---|
| 0.0 | hold speed |
| 1.0 | accelerate / commit to cross |
| −1.0 | decelerate / give way |
| 0.5 | creep forward (the probe manoeuvre) |

---

## S7 · Role codes

| Value | Role | Duty |
|---|---|---|
| 0 | `SAFE` | no action; `tCPA < 0`, opening |
| 1 | `GIVE_WAY` | early, substantial action. Pass astern |
| 2 | `STAND_ON` | **hold course and speed** |
| 3 | `HEAD_ON` | both alter to the same side |
| 4 | `OVERTAKING` | keep clear of the overtaken agent |

Boundaries are **22.5°, 90°, 112.5°** (research section 12). `tCPA` sign disambiguates.

---

## S8 · Planner mode

| Value | Mode | When |
|---|---|---|
| 0 | `STRUCTURED` | lane markings detected — defer to the baseline-style planner |
| 1 | `UNSTRUCTURED` | no usable lane structure — our negotiation planner |
| 2 | `EMERGENCY` | barrier violated, `h < 0` |

Mode 0 exists because **we do not claim a win on the highway merge.** The planner detects that
the road has structure and switches. "Our planner knows when it isn't needed."

---

## File formats — frozen

| What | Path | Format |
|---|---|---|
| Trajectory export for Blender | `results/<run>/trajectories.csv` | `t,actor_id,class_id,x,y,z,yaw` — SI units, header row |
| Metrics per run | `results/<run>/metrics.json` | keys are the metric IDs `M1`–`M10` from `docs/metrics.md` |
| Run config | `configs/<name>.json` | seed, density, scenario, noise levels |
| Model | `python/export/yield_lstm_opset<N>.onnx` | input `sequence` `[1,20,31]`, output `yield_logits` `[1,2]` |

**Every run writes a `results/<run>/config.json` copy of its inputs.** A number without its
config is not a result.
