# PHASE 4 — MERGED RESULT: THE ARCHITECTURE IS NOW DECIDED
**30 Aug 2026. Gemini (MathWorks) + ChatGPT (ONNX) + Consensus (models) + Perplexity (geometry).**

---

# PART 1 — MATLAB WITHOUT ROADRUNNER: BETTER THAN EXPECTED

## Unmarked Indian roads are directly buildable in code — CONFIRMED
`road(scenario, roadCenters, 'Lanes', laneSpec)` where roadCenters is an N-by-3 matrix of
(x,y,z), spline-interpolated. **Elevation supported.** Width numeric via `laneSpec`, range
(0, 50] m, scalar or per-lane.

**Unmarked roads: `laneMarking('Unmarked')`.** Omit the marking entirely and the road renders
as "a continuous, unbounded drivable surface" — exactly an Indian gali.

Working example from the docs:
```matlab
scenario = drivingScenario;
roadCenters = [0 0 0; 20 20 2; 40 10 4; 60 -10 2; 80 -20 0];
unmarkedLane = laneSpec(1,'Width',15,'Marking',laneMarking('Unmarked'));
road(scenario, roadCenters, 'Lanes', unmarkedLane);
```
Junctions via `roadGroup` / `roadNetwork`, or by deliberately overlapping road calls.

## The cuboid sensor limitation — and the way through it
| Sensor | Output |
|---|---|
| `visionDetectionGenerator` | **object lists only, NO pixels** |
| `drivingRadarDataGenerator` | object lists |
| **`lidarPointCloudGenerator`** | **a real 3D point cloud (x,y,z)** |
| `ultrasonicDetectionGenerator` | object lists |
| `insSensor` | synthesised GPS + IMU |

Gemini states it plainly: "a YOLOv8 network trained on the Indian Driving Dataset **cannot
consume the output of visionDetectionGenerator, as there are no pixels to process**."

**BUT LIDAR IS DIFFERENT.** `lidarPointCloudGenerator` computes real ray intersections against
actor meshes and emits a genuine point cloud. **So closed-loop perception IS possible without
RoadRunner and without Unreal — via lidar, not camera.**

Object lists feed `multiObjectTracker` (GNN/JPDA), **PHD extended-object trackers**, Kalman
filters, and RSS-style safety logic.

## The 11 prebuilt Unreal scenes need NEITHER RoadRunner NOR Unreal Editor
They ship as precompiled binaries and DO produce photoreal RGB (e.g. 1080x1920x3) via the
`Simulation 3D Camera` block, plus programmable weather, rain, snow, sun azimuth/altitude.
Scenes: Empty Scene, Blank Scene, Empty Grass, Straight Road, Curved Road, US City Block,
Large Parking Lot, Parking Lot, Double Lane Change, US Highway, **Open Surface**.

**"Open Surface — a flat, black pavement surface without specific road delineation markings,
useful for testing unstructured space."** The one prebuilt scene that suits us.

## THE COW — answered precisely
**Cuboid: YES, a real custom mesh.**
```matlab
actor(scenario,'ClassID',5,'Length',2.5,'Width',1.0, ...
      'MeshVertices',cowVertices,'MeshFaces',cowFaces);
```
Lidar and radar then compute returns against the actual animal geometry, not a box.

**Unreal: NO.** Default blocks support only hardcoded vehicle profiles (Hatchback, Sedan,
Muscle Car, Box Truck). A visual cow requires the Unreal Editor, the support package, and
Blueprint reparenting. **Out of scope for us.**

## OpenDRIVE
Import v1.4/1.5/1.6 via `roadNetwork(scenario,'OpenDRIVE',file)`.
Export via `export(scenario,'OpenDRIVE','file.xodr')`.
**Documented limitations that hit us:** `compositeLaneSpec` (tapering/varying width) not fully
supported; self-intersecting geometry restricted; **`roadGroup` junctions unsupported for HD
map export**; only standard white/yellow markings preserved.
**So our unstructured junctions may not survive export. Test early, and say so if it degrades.**

## THE RECIPE FOR REACTIVE AGENTS — the single most valuable finding
Documented Simulink closed loop, no RoadRunner, no external simulator:

1. `Scenario Reader` block emits an **Actor Poses** bus
2. `Bus Selector` extracts ego and the chosen non-ego agent
3. **Stateflow chart** = the agent's brain: relative distance, closing velocity,
   RSS-style safe-distance thresholds, Cruise -> Brake -> Avoid transitions
4. Kinematic **bicycle model** turns the decision into a new pose
5. **Feed that pose back into Scenario Reader's `Non-ego Actor Poses` INPUT PORT** —
   this **overwrites the programmed waypoints**

That closes the loop. Agents react to us instead of following fixed paths. It is documented,
it is in our licence, and it is the exact fix for the open-loop NPC problem.

---

# PART 2 — THE ONNX BRIDGE: HARD CONSTRAINTS THAT DECIDE THE MODEL

`importNetworkFromONNX` (R2023b+) replaces the deprecated `importONNXNetwork`. Needs the Deep
Learning Toolbox Converter for ONNX. R2024b: IR v9, opsets 6-18. R2025a+: opsets 6-20.

| Imports cleanly | Fails / becomes a placeholder |
|---|---|
| Conv, pooling, batchnorm | **NonMaxSuppression** |
| ReLU/LeakyReLU/Sigmoid/Tanh/Softmax | TopK, RoiAlign |
| **LSTM, GRU, BiLSTM** | **Gather, Scatter, GatherND** |
| Resize/Upsample, PReLU, LRN, Gelu | reduce ops, Squeeze, Transpose, Where |
| elementwise Add/Mul/Sub | control flow (Loop, If) |

## Consequences, in order of importance
1. **A GNN cannot be imported.** Graph models depend on Gather/Scatter. Effectively impossible.
2. **A transformer imports only partially**, with manual placeholder surgery.
3. **An LSTM or GRU imports cleanly.** This is the one sequence architecture that just works.
4. **YOLO import is fragile.** Requires `nms=False` on export, a fixed input size, avoiding the
   opset-11+ Resize `antialias` attribute — and even then Reshape can fail at runtime.
   MathWorks' own expert answer to this ends with "contact support."
5. **MATLAB ships YOLO v4 and YOLOX natively** in Computer Vision Toolbox. Use those instead of
   importing.
6. In Simulink use the **Predict block** (R2020b+) pointed at a saved network — supports code
   generation. The **ONNX Model Predict** block is simulation-only, no codegen.

---

# PART 3 — WHAT TO TRAIN

## The literature
- Families: LSTM-CNN hybrid (**TraPHic**), GNN (HEAT, SFEM-GCN), transformer (HDGT, VNAGT,
  TP-EGT), diffusion (mostly pedestrian-only).
- **Compute is almost never reported.** None of 20 surveyed papers stated training time, GPU
  type, GPU count and model size together. These models are small; nobody brags about compute.
- Monocular-only capable: **FIERY** (camera-only, map-free, end-to-end future motion),
  QD-3DT, Joint Monocular 3D Vehicle Detection and Tracking.
- **Standard metrics: ADE and FDE, in metres.** HEAT reports FDE@3s = 0.66 m in urban driving.

## THE GAP WE CAN OCCUPY
> **"Has anyone trained a model to predict whether an agent will YIELD or NOT YIELD — a
> discrete interaction outcome rather than a continuous trajectory?"**
> **NO RESULTS.** Closest work is interaction-event recognition and lane-change intention.

**And METEOR labels exactly that, per agent: Yield (Y) and Cutting (C).**

So: **a yield / no-yield classifier trained on METEOR.** It is unoccupied, it is a
classification task (far easier than trajectory regression), an **LSTM does it**, and an LSTM
is the one architecture that imports cleanly into MATLAB. Every constraint points the same way.

## Monocular geometry — a real cost, do not underestimate it
- Best baseline is **bottom-centre ray + ground-plane homography + temporal tracking**, not a
  depth network.
- **A 1-degree camera pitch error produces roughly 31% depth error at 30 m.** Pitch is the
  dominant error source, and a dashcam pitches under every brake and pothole.
- Published vehicle-distance errors: RMSE 6.10-7.31 m (KITTI/nuScenes/Lyft), AbsRel ~8.3%,
  QD-3DT RMSE 2.847 m. **No Indian-road figures exist at all.**
- Depth Anything V2: Small (24.8M) is **Apache-2.0**; Base/Large/Giant are **CC BY-NC-4.0**.
- Failure modes: slopes, pitch, occlusion, and irregular shapes — auto-rickshaws and carts
  specifically.
- Useful repos: UCBDrive 3D Vehicle Tracking (669*), SysCV QD-3DT (526*).

**Mitigation: keep the yield classifier in the IMAGE PLANE where possible** — relative box
positions, sizes and their rates — instead of forcing METEOR into world coordinates. That
sidesteps the entire depth problem for the model that matters most.

---

# PART 4 — THE ARCHITECTURE, DECIDED

| Layer | Decision | Why |
|---|---|---|
| **Scenes** | `drivingScenario` API, `laneMarking('Unmarked')`, geometry traced from Meerut footage. Export OpenDRIVE. | Fully scriptable. No RoadRunner. RoadRunner-ready if a licence lands. |
| **The cow** | Custom mesh via `MeshVertices`/`MeshFaces` in the cuboid environment | Real lidar returns off real animal geometry |
| **Perception in the loop** | **Lidar**, not camera — `lidarPointCloudGenerator` | The only real sensor data available without Unreal |
| **Perception benchmark (offline)** | YOLO trained on IDD, evaluated on real Indian video | Real numbers, uses the DGX, honest |
| **Prediction** | **LSTM yield / no-yield classifier trained on METEOR** | Unoccupied (NO RESULTS), LSTM imports cleanly, classification not regression |
| **Planner** | Subclass OpenTrafficLab's `DrivingStrategy`; **delete `TrafficController`, replace with negotiation** | Their junction has a central authority. Ours has none. |
| **Reactive agents** | Scenario Reader -> Bus Selector -> Stateflow -> bicycle model -> back into Non-ego Actor Poses | Documented, in-licence, closes the loop |
| **Metrics** | ADE/FDE for prediction; completion and progress for planning; **plus the perception-degradation sweep** | Nobody else reports how their planner degrades under real perception error |

## Is the DGX load-bearing? Honest answer
An LSTM classifier is small. **One GPU trains it.** The eight GPUs buy us the **sweep** —
training many variants at once to produce curves rather than a single point:
- yield-classifier ablations (which input features matter)
- the perception-degradation sweep (planner performance vs detection error)
- assertiveness sweep (safety vs progress Pareto frontier)

**Say that honestly on the slide.** "We used eight GPUs to run forty experiments, not to train
one big model" is a stronger and more truthful claim than pretending we needed the compute for
a single network.

## OPEN
- Verify `lidarPointCloudGenerator` + a MATLAB-native lidar detector (PointPillars in Lidar
  Toolbox?) actually works end to end. **This is now the highest-risk unverified assumption.**
- Confirm MATLAB release available at KIET (decides ONNX opset support).
- Test OpenDRIVE export on an unstructured junction early — it may degrade.
