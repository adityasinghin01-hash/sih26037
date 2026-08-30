# PHASE 4 — THE TRAINING PLAN (and building without RoadRunner)
**Constraint set 30 Aug: assume we do NOT have RoadRunner.**

## What that changes
**In our favour:** RoadRunner is a GUI 3D authoring tool that cannot be scripted by an AI.
It was the one part of this project the team structurally could not do. Removing it removes
that risk. Everything else in MATLAB is scriptable.

**Replacement:** Driving Scenario Designer and the `drivingScenario` MATLAB API build roads,
actors and trajectories **programmatically**. Critically, **mathworks/OpenTrafficLab is built
on Driving Scenario Designer** — so our chosen foundation never needed RoadRunner.

**The real cost:** no photoreal 3D rendering of custom Indian scenes, so we cannot feed
rendered camera images from an Indian street into a trained detector inside the loop.

**The resolution — split the two validations:**
- **Perception** — train on IDD, evaluate on REAL Indian video, report real numbers.
- **Planning** — closed loop in Driving Scenario Designer using object lists.
- **Then join them:** inject our detector's MEASURED error into the planner's inputs and
  sweep it. Every incumbent assumes perfect perception — B-GAP admits it needs "very good
  sensing", GameOpt uses SUMO with no sensors at all. **Nobody reports how their planner
  degrades under real perception error. That is a curve nobody else will have.**

**The PS clause we cannot fully meet:** "at least two detailed RoadRunner scenes."
Say it ourselves on our own slide, and mitigate: author the scenes from real Meerut road
geometry and **export OpenDRIVE**, so they import into RoadRunner the moment a licence lands.

## The question for this phase
What do we train, so that eight A100s are load-bearing rather than decorative?
A judge will ask "why did you need a supercomputer?" and "we fine-tuned YOLO" is a weak answer.

================================================================
## PROMPT A — CONSENSUS  (what to train, and how it is measured)
================================================================
Academic search on trajectory and behaviour prediction for DENSE, HETEROGENEOUS, UNSTRUCTURED
traffic — mixed cars, motorcycles, auto-rickshaws, pedestrians, animals, no lane discipline.

1. What model architectures are used for trajectory prediction in dense heterogeneous
   traffic? List the main families (LSTM-CNN hybrids, graph neural networks, transformers,
   diffusion) with representative papers, years and links.
2. For each: how much training data and compute did they report? Training time, GPU type,
   number of GPUs, model size. I need to know what is realistic to train from scratch.
3. Which methods work from MONOCULAR VIDEO ONLY — image-plane bounding boxes, no LiDAR, no
   HD map? This matters because our dataset (METEOR) provides image-plane boxes and states it
   does "not provide trajectory information from a fixed reference frame."
4. What are the standard EVALUATION METRICS for this task (ADE, FDE, others)? What numbers do
   the leading methods report, on which datasets, so our results are comparable?
5. Has anyone trained a model to predict whether an agent will YIELD or NOT YIELD — a
   discrete interaction outcome rather than a continuous trajectory? Name it or say NO RESULTS.

RULES: link every paper. Quote reported training times and hardware where stated. If compute
is not reported, say so — that is itself useful.

================================================================
## PROMPT B — PERPLEXITY  (image-plane boxes to world coordinates)
================================================================
Practical engineering question. I have dashcam video with 2D bounding boxes and camera
intrinsics, plus ego GPS. I need world-frame trajectories of surrounding vehicles.

1. What are the standard methods to recover metric positions of vehicles from a single
   monocular camera? Cover: ground-plane homography / flat-earth assumption, monocular depth
   estimation, monocular 3D object detection, and bounding-box-height priors.
2. What are the current best monocular depth models (e.g. Depth Anything and successors)?
   Give model sizes, inference speed, licences, and whether metric depth or relative only.
3. What accuracy can be expected for vehicle distance estimation from a dashcam at 5 m, 20 m
   and 50 m? Give published error figures.
4. What are the failure modes — sloped roads, camera pitch changes, occlusion, unusual
   vehicle shapes like auto-rickshaws and carts?
5. Is there open-source code that turns dashcam video plus 2D boxes into bird's-eye-view
   trajectories? Give repository links, stars and last commit.

RULES: link everything. Prefer published error numbers over claims. Say plainly where no
reliable figure exists.

================================================================
## PROMPT C — CHATGPT  (the ONNX to MATLAB bridge — this decides our architecture)
================================================================
I need to train models in PyTorch on a Linux GPU cluster, export to ONNX, and import into
MATLAB/Simulink to run inside a Simulink simulation. Tell me precisely what works and what
breaks.

1. How does MATLAB's `importNetworkFromONNX` work in recent releases? What replaced the older
   `importONNXNetwork`? Which MATLAB releases support what?
2. Which layer types and operators import CLEANLY, and which are known to fail or produce
   placeholder layers? Give the common failure list.
3. Can a YOLO object detector be exported from PyTorch/Ultralytics to ONNX and imported into
   MATLAB successfully? What are the known problems — NMS, dynamic shapes, custom layers?
4. Can an LSTM, a GRU, a graph neural network, or a transformer be imported? Which of these
   commonly fail?
5. How do you run an imported network inside a **Simulink** model — which block, what are the
   constraints, and does it work in a closed-loop simulation with the Automated Driving
   Toolbox?
6. What are the alternatives if ONNX import fails — MATLAB Engine calling Python, a TCP/file
   bridge, or re-implementing the model natively in MATLAB? Trade-offs of each.

RULES: cite mathworks.com documentation directly wherever possible. Distinguish "documented
as supported" from "reported working by users". Name specific MATLAB release versions.

================================================================
## PROMPT D — GEMINI DEEP RESEARCH  (building it all WITHOUT RoadRunner)
================================================================
Research question: how much of an autonomous-driving simulation pipeline can be built in
MATLAB and Simulink **without RoadRunner**, using only Automated Driving Toolbox, Navigation
Toolbox, Stateflow and the Driving Scenario Designer?

Deliver, citing mathworks.com documentation directly:
1. The `drivingScenario` programmatic API — what road geometry can be built in code? Can
   roads be created **without lane markings**? Can road width, curvature and junctions be
   specified numerically? Give function names and example code.
2. Driving Scenario Designer — what can it do, what does it export, and can scenarios be
   generated fully from a script with no GUI work?
3. **Sensor simulation without a 3D renderer:** what sensor models are available — vision
   detection generator, probabilistic radar, lidar point cloud generation? Do these produce
   object lists only, or images? What exactly can a perception algorithm consume?
4. The 11 prebuilt Unreal Engine 3D scenes shipped with Automated Driving Toolbox — do they
   require RoadRunner or Unreal Editor? Do they produce photoreal camera images? List them.
5. **OpenDRIVE:** can MATLAB export a `drivingScenario` to OpenDRIVE, and can it import
   OpenDRIVE? Which functions, which releases, what are the documented limitations?
6. Can custom actor meshes or non-standard actors — an auto-rickshaw, a cow, a pushcart — be
   added to a driving scenario? How?
7. What is the documented workflow for co-simulating a Simulink-controlled agent inside a
   driving scenario so that agents REACT to the ego vehicle rather than following fixed
   waypoints?

RULES: mathworks.com documentation is the primary source. Give function names and doc links.
Where a capability does not exist, say so explicitly — that is the most useful answer here.

================================================================
## PROMPT E — GROK  (what is current in 2026)
================================================================
Search X/Twitter and the recent web for what is current right now:

1. What are the current best small, practical models for multi-agent trajectory prediction?
   Anything released in 2025-2026 that is compact enough to train on a single node of
   8x A100 40GB in a few days?
2. What is the current state of monocular depth estimation — which models do practitioners
   actually use in 2026, and what has replaced earlier favourites?
3. Is anyone running PyTorch models inside MATLAB/Simulink in practice? What do people
   report about the ONNX bridge — does it work, what breaks?
4. Any recent work, demos or discussion on predicting animal behaviour near vehicles?

RULES: link every claim. Prefer practitioner reports over marketing. Say clearly if you find
nothing.
