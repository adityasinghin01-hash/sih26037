Excellent P4/P5 - verified and accepted. Next: PHASES P6 (SIMULATION WORLD), P7 (TRAFFIC BEHAVIOUR / SIM AGENTS),
P8 (SENSORS). The core question: "If you were designing the simulation in which a car brain proves it can
drive Indian roads, how must it be built?" It must run the PS toolchain (MATLAB/Simulink, RoadRunner if we get
the licence) but may co-simulate with others.
My raw notes (verify, extend, correct):
# P6 simulation world — Claude's raw findings

## PS toolchain (must host the running system)
- MATLAB `drivingScenario` (cuboid) + RoadRunner + RoadRunner Scenario + Unreal (`sim3d`). As of
  R2026a, RoadRunner Scenario imports ASAM OpenSCENARIO. Scenario Builder (a free add-on) rebuilds
  scenarios from recorded camera, lidar, GPS and IMU.
- **RoadRunner licence: still missing.** TwinX (SIH 2025 winner) exported to RoadRunner, so SIH
  teams appear to get access. The MathWorks Student Competition Software Request Form route
  exists. **ACTION: chase the mentor's August request / hackathon@mathworks.com.**
- MATLAB ↔ CARLA: officially supported through the ROS Toolbox (CARLA ROS bridge) and
  "RoadRunner Scenario: cosimulate with CARLA".
  https://www.mathworks.com/help/ros/ug/set-up-and-connect-to-carla-simulator.html

## The neural-fields / world-model route (the "beyond PS" tech)
- **NVIDIA AlpaSim** (open source, NVlabs/alpasim): closed-loop AV simulator built as microservices
  (Driver, Renderer, TrafficSim, Controller, Physics), running on Docker Compose on one machine or
  on SLURM. https://github.com/NVlabs/alpasim
- **NuRec**: 3D Gaussian Splatting reconstruction from real sensor logs, rendered with gsplat. It
  plugs into AlpaSim **and CARLA** over gRPC. https://developer.nvidia.com/omniverse/nurec
- **Instant NuRec** (arXiv 2607.14203, Jul 2026; github NVIDIA/instant-nurec): turns a SHORT
  MULTI-VIEW driving log into a simulatable 3DGS world in one forward pass.
  **OPEN QUESTION: does it work from a single dashcam plus GPS (what we can record in Najibabad or
  Meerut)?**
- **OmniDreams** (arXiv 2606.03159): a real-time generative world model as the renderer.
- `alpasim-carla` (SimForge): a CARLA renderer for AlpaSim.
- **So the "real Indian road reconstructed from our own video → closed-loop test" pipeline now
  exists in open source.** This is what makes a "neural fields" claim real.
  Cost: it needs an NVIDIA GPU. The DGX A100 fits, but the A100 has **no RT cores**, which matters
  for Unreal/CARLA rendering, not for gsplat.

## Assets
- Auto-rickshaw and cow 3D models exist as commercial or free game assets (TurboSquid, CGTrader,
  itch.io). **No dedicated Indian asset pack for CARLA/Unreal was found.**
# P7 traffic behaviour — Claude's raw findings

- **SUMO, calibrated for India:**
  - Sublane model at a 0.2 m resolution reproduces two-wheeler seepage. Mean observed gap 0.906 m,
    vs SUMO's default minGap exceeding it by 176%.
    (ScienceDirect S1389128626005220; dataset on Zenodo 18955993.)
  - Chennai lane-less calibration using a GA on travel time (Springer 978-981-15-3742-4_13).
  - W99 calibration thresholds differ between two-wheelers and cars.
  - MATLAB ↔ SUMO co-simulation exists (TraCI4Matlab; MathWorks Simulink–SUMO–CARLA examples).
- **Learned sim agents (reactive, realistic):**
  - Waymo Open Sim Agents Challenge 2025 winner **SMART-R1** (realism meta 0.7858; SFT-RFT-SFT
    training), runner-up TrajTok.
  - RIFT (RL fine-tuning for controllable traffic, 2505.03344).
  - Promptable closed-loop traffic sim (2409.05863).
  - All are trained on Western data (WOMD). **None is trained on Indian data** (METEOR/IDD-X are
    candidates).
- **Our gap:** actors are scripted, and `reactStep` is a hand-rule. A realistic Indian agent layer
  = SUMO-sublane (cheap, calibrated) and/or a learned sim-agent fine-tuned on Indian trajectories.

P6 SIM WORLD:
1. Compare simulators for our purpose: MATLAB cuboid drivingScenario, RoadRunner+RoadRunner Scenario, Unreal sim3d,
   CARLA (+MATLAB via ROS/RoadRunner co-sim), NVIDIA AlpaSim (+NuRec/Instant NuRec 3DGS), SUMO, esmini/OpenSCENARIO,
   Waymax, nuPlan/NAVSIM, MetaDrive/ScenarioNet. Axes: sensor realism, traffic realism, closed-loop, Indian assets,
   MATLAB integration, GPU/OS needs (we have a M1 Mac 8GB, Windows RTX A1000 8GB lab PC, DGX A100 no RT cores).
2. Neural reconstruction: can Instant NuRec / NuRec / 3DGS reconstruct a drivable scene from a SINGLE forward dashcam
   + phone GPS (what a student can record in UP)? What inputs are required (multi-cam, lidar, poses)? Any Indian-road
   reconstructions published? Licences.
3. Scenario generation at scale: OpenSCENARIO 1.x/2.0, ScenarioRunner, adversarial/safety-critical scenario generation
   (e.g. KING, AdvSim, CAT, ChatScene/LLM-to-scenario), coverage-guided testing, and how to cover the 10 families x params.
4. Map: OSM->OpenDRIVE (netconvert, RoadRunner OSM import), unmarked roads, road-surface defects (potholes) in OpenDRIVE/OpenCRG.
P7 TRAFFIC BEHAVIOUR:
1. Rule-based heterogeneous models (SUMO sublane calibrated for India, social force for pedestrians, cattle movement
   models from ecology), learned sim agents (SMART, TrajTok, SMART-R1, RIFT), and hybrid. Which can be trained on
   Indian data (SPT Chennai drone data - check access/licence/size; METEOR; IDD-X)?
2. Reactivity + controllability: agents that react to the ego but can be scripted into adversarial behaviour; how to
   avoid "home-field advantage" (agents that dodge to save the ego).
3. Validation of behaviour realism (WOSAC realism metrics, distribution matching) for Indian traffic.
P8 SENSORS:
1. Sensor-model fidelity in MATLAB vs CARLA vs neural sim: camera, lidar (incl. rain/fog/dust noise models),
   radar (clutter, multipath), near-field ultrasonic; realistic failure models (dropout, ghost targets, glare).
2. What sensor suite Indian AV startups and Waymo/Tesla use; cost-realistic suite for Indian ADAS (camera+radar).
3. How to test perception degradation (our M3 curve) in simulation - published methods.
End each phase with good/better/best options for us, effort, risk. Tables, every fact sourced.
