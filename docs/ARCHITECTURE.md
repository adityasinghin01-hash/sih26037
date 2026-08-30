# Architecture

## The gap, in one sentence
`mathworks/OpenTrafficLab` resolves a junction with a **TrafficController** — a central authority,
like a signal. **An Indian junction has no authority.** We delete the controller and let each
agent negotiate from geometry alone.

## The pipeline

```
  drivingScenario API
    unmarked roads  ·  real Meerut geometry via OpenStreetMap  ·  custom zebu mesh
    lanespec(1,'Width',12,'Marking',laneMarking('Unmarked'))   ·  export OpenDRIVE
         │
         ▼
  [B] lidarPointCloudGenerator ──► trackerGridRFS ──► TrackList (S1)
         │                                                │
         │                                                ├──────────────┐
         ▼                                                ▼              ▼
  [C] FeatureFrame (S2)  ◄── monoCamera/vehicleToImage    [D] assignRoles  (COLREGs)
         │   31 dims, depth-free, + adjacency                    │  22.5 / 90 / 112.5 deg
         ▼                                                        │  tCPA sign disambiguates
  [C] YieldNet (ONNX LSTM, Simulink Predict block)                ▼
         │                                              [D] velocityObstacle
         └──────── YieldPrediction (S3) ──────────────►  beta = asin(dMin/d)
                                                         lambda = acos((vr·r)/(|vr| d))
                                                         h = lambda - beta   ← the barrier
                                                                │
                                                                ▼
                                                        [D] EgoCommand (S4)
                                                                │
                                                                ▼
                                            bicycle model ──► Non-ego Actor Poses input port
                                                                │
                                                                └──► closes the loop
```

Feeding poses back into that input port **overwrites the programmed waypoints**. That is the
documented fix for open-loop NPCs — no RoadRunner, no external simulator.

## Module owners

| Module | Stream | Package |
|---|---|---|
| Scenario, roads, junctions | **A** | `matlab/+sih/+scenario/` |
| Lidar, tracking, noise injection | **B** | `matlab/+sih/+perception/` |
| Features, ONNX predictor | **C** | `matlab/+sih/+prediction/`, `python/` |
| Roles, velocity obstacle, Stateflow | **D** | `matlab/+sih/+planner/` |
| Baseline, metrics, experiment runner | **E** | `matlab/baseline/`, `matlab/+sih/+metrics/` |
| Blender, renders, demo | **F** | `blender/` |

## The four load-bearing decisions

**Lidar in the loop, not camera.** The cuboid environment emits point clouds, not pixels. Measured
support: a cow at 9.2 m is 77x63 px in a 140-degree dashcam frame.

**Project down, never lift up.** The simulation is projected into the image plane to match METEOR,
rather than lifting METEOR into 3-D. Lifting needs monocular depth; 1 degree of pitch error is
~31% depth error at 30 m.

**LSTM, not GNN.** ONNX import does not support Gather/Scatter. The adjacency matrix is emitted
from day one anyway, which makes the GNN swap ~60 lines.

**h = lambda - beta is already a control barrier function.** The negotiation geometry and the
safety proof are the same quantity. We do not bolt a filter on — the planner is written in the
filter's own variable.
