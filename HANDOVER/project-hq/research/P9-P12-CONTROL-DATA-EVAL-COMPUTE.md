# P9–P12 — Control, data engine, evaluation, real-time

Status: FINAL, 26 Sep 2026. Codex (session B) + Claude verification.

## Claude-verified corrections (these override Claude's earlier raw notes)
- **ISO 34502:2022 applies to LIMITED-ACCESS HIGHWAYS** (scope confirmed via the ISO catalogue and
  the SIS/ANSI previews). For Indian village and market roads we may only **adapt its process,
  labelled as an adaptation**. Never claim conformance.
- The **"NXP + EyeQ6 Lite BOM < $95" claim is UNVERIFIED**; drop it. The "30–250 TOPS Indian ADAS
  budget" is unsupported; drop it.
- Tesla shadow mode is verified only narrowly (the 2019 stop-sign/traffic-light feature, per a
  Tesla filing).
- The Waymo "10 AI Lessons from Driving 200+ Million Fully Autonomous Miles" (Aug 2026) blog
  exists; it is used as the source for the critic + validation-layer description.

## Headline decisions
- **P9:** Stanley + PI baseline → compare with constrained MPC. Use 3DOF for sweeps and 14DOF for
  the pothole/speed-breaker ride set. Reverse and 3-point turns are explicit states
  (`plannerHybridAStar` gives geometry only).
- **P10:** a **simulation shadow-mode data engine**:
  - log both proposals
  - mine disagreements, near-misses and uncertainty
  - replay with the same seed → turn into a regression scenario → frozen holdout set
  - Demo = "one failure discovered → replayed → fixed → retested", with the frozen set reported
- **P11:**
  - Write our own exact formulas for the PS's three metrics (replanning latency p50/p95/p99 +
    deadline misses; smoothness as jerk + curvature, reported separately; completion = reached +
    no disqualifying contact + stayed drivable).
  - Stratify by family, weather and sensing.
  - **299 independent zero-failure runs are needed for a 95% upper bound below 1%** per test
    distribution.
  - Baselines: MathWorks example, always-yield, PDM-like rule planner, ORCA (geometric only).
- **P12:**
  - Profile → MEX/codegen hot paths → prove numerical equivalence → a 10 Hz gate with deadline-miss
    counts and a stale-plan fallback.
  - Jetson deployment = the "best" tier (MathWorks example: PyTorch → Simulink → Jetson AGX Orin,
    Jul 2026).

---
# P9–P12: what the driving system must prove

**Recommendation:** keep the running vehicle, controllers, safety gate, and evaluation harness in Simulink. Use the DGX for training and batch scenario search. First prove that the ego follows feasible paths, then that it handles interactive traffic without collisions or indefinite stopping, and finally that the measured loop meets its deadline. This is a proposed project sequence, not a claim of road safety. [MathWorks’ integrated path-following example](https://www.mathworks.com/help/mpc/ref/pathfollowingcontrolsystem.html), [Waymo’s account of closed-loop evaluation](https://waymo.com/blog/2026/08/10ailessons/)

**Evidence key:** *Verified* means the linked primary source supports the statement. *UNVERIFIED* means I could not substantiate the raw-note claim. Effort below is my planning estimate, assuming an existing Simulink driving loop.

## P9 — Control and vehicle dynamics

| Finding | Consequence for SIH26037 |
|---|---|
| Autoware exposes both **MPC and pure pursuit** lateral-following modes; its MPC models steering response and delay. Openpilot’s control process runs at **100 Hz** and selects vehicle-specific angle, curvature, PID, or torque control. There is no single controller shared by the open stacks. [Autoware follower](https://autowarefoundation.github.io/autoware_universe/main/control/autoware_trajectory_follower_node/), [Autoware MPC](https://autowarefoundation.github.io/autoware_universe/latest/control/autoware_mpc_lateral_controller/), [openpilot source](https://github.com/commaai/openpilot/blob/master/openpilot/selfdrive/controls/controlsd.py) | Compare controllers **on the same reference trajectory and plant**, including steering delay and saturation. |
| MathWorks provides a lateral Stanley block with kinematic/dynamic bicycle choices and reverse support; its longitudinal “Stanley” block is a **discrete PI speed controller**. MPC Toolbox supplies constrained path-following and nonlinear MPC blocks. [Lateral Stanley](https://www.mathworks.com/help/driving/ref/lateralcontrollerstanley.html), [longitudinal block](https://www.mathworks.com/help/driving/ref/longitudinalcontrollerstanley.html), [MPC blocks](https://www.mathworks.com/help/mpc/automated-driving-applications.html) | A Stanley + PI baseline is quick to integrate; MPC earns its cost only if it improves tracking or constraint handling in measured tests. |
| Vehicle Dynamics Blockset’s **3DOF** model covers planar motion; its **14DOF** model adds vertical motion, pitch, roll, and wheel motion. A planar bicycle model cannot measure pothole or speed-breaker ride response. [MathWorks vehicle-model comparison](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html) | Use 3DOF for broad traffic sweeps and 14DOF for a smaller rough-road validation set. Feed those tests an actual road-height profile. |
| MATLAB’s `plannerHybridAStar` permits forward/reverse Reeds–Shepp paths. It supplies geometry, not the gear-change, stop, clearance-check, and creep logic needed for a three-point turn. [MathWorks documentation](https://www.mathworks.com/help/nav/ref/plannerhybridastar.html) | Implement reverse and narrow-galli maneuvers as explicit states, with low-speed tracking and an obstacle check before each direction change. |

**Control test I would build:** command trajectory → steering/acceleration controller → actuator delay and limits → vehicle plant → pose feedback. Sweep speed, wheelbase, steering lag, braking effectiveness, grade, and road friction; record lateral error, heading error, stopping distance, overshoot, command saturation, and collision. For potholes, additionally record vertical acceleration and pitch on the 14DOF plant. Autoware explicitly identifies mistaken steering delay as a source of late curve response; MathWorks documents the model split. [Autoware tuning guidance](https://autowarefoundation.github.io/autoware_universe/main/control/autoware_mpc_lateral_controller/), [MathWorks vehicle models](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html)

| Option | Build | Effort estimate | Main risk |
|---|---|---:|---|
| **Good** | Stanley lateral + PI longitudinal; 3DOF plant; add actuator limits and delay. [Blocks](https://www.mathworks.com/help/driving/planning-and-control.html) | 1–2 weeks | Poor tracking at very low speed or sharp curvature. |
| **Better — recommended** | Compare Stanley with constrained MPC; forward/reverse state machine; test rough-road cases on 14DOF. [MPC](https://www.mathworks.com/help/mpc/automated-driving-applications.html), [14DOF](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html) | 3–5 weeks | MPC tuning and solver time. |
| **Best** | Speed-dependent controller, identified actuator dynamics, friction-aware limits, and measured ride/control trade-off. [Autoware delay treatment](https://autowarefoundation.github.io/autoware_universe/latest/control/autoware_mpc_lateral_controller/), [MathWorks nonlinear MPC example](https://www.mathworks.com/help/mpc/ug/lane-following-using-nonlinear-model-predictive-control.html) | 6–10 weeks | Parameter identification without a physical test vehicle. |

## P10 — Data engine and learning loop

| Raw-note claim checked | Verdict and useful lesson |
|---|---|
| **Tesla shadow mode** | **Verified narrowly:** Tesla’s 2019 filing says its *stop-sign/traffic-light feature* ran in fleet shadow mode and compared algorithm decisions with driver behavior. The proposed list of tunnel, flicker, and cut-in triggers as Tesla’s documented process is **UNVERIFIED**. [Tesla’s Q2 2019 filing](https://ir.tesla.com/_flysystem/s3/sec/000156459019025855/tsla-8k_20190724-gen_0.pdf) |
| **Waymo and Wayve close the loop** | Waymo describes an AI critic, issue extraction, auto-labeling, retraining, simulation, and a separate trajectory validation layer. Wayve describes fleet collection, training, simulated worlds, and evaluation. These are company descriptions, not evidence that our student loop will attain equivalent safety. [Waymo](https://waymo.com/blog/2026/08/10ailessons/), [Wayve](https://wayve.ai/technology/fleet-learning-technology/) |
| **Open tools** | AIDE proposes iterative issue identification, curation, auto-labeling, and scenario-based verification. OpenAnnotate3D describes open-vocabulary 2D/3D labels; AutoMine mines scenarios from AV2 logs. DeepScenario contains **33,530 executable scenarios**, but its published toolset targets SVL Simulator/Apollo, so it is not a ready Simulink scenario library. [AIDE](https://openaccess.thecvf.com/content/CVPR2024/html/Liang_AIDE_An_Automatic_Data_Engine_for_Object_Detection_in_Autonomous_CVPR_2024_paper.html), [OpenAnnotate3D](https://arxiv.org/abs/2310.13398), [AutoMine](https://arxiv.org/abs/2606.11874), [DeepScenario](https://github.com/Simula-COMPLEX/DeepScenario) |
| **Scenario Builder from dashcam** | MathWorks supports recorded GPS, IMU, camera, lidar, and actor tracks, with preprocessing and scene/actor extraction steps. “Upload one dashcam video and obtain a reliable executable Indian scene” is **UNVERIFIED**. [Scenario Builder workflow](https://www.mathworks.com/help/driving/ug/overview-of-scenario-generation-from-recorded-sensor-data.html) |

**Proposed student loop:** during every simulation, run the candidate predictor/planner in shadow alongside the active controller. Log both proposals, the gate decision, simulator truth, sensor inputs, scenario parameters, seed, software/model versions, and outcome. Rank clips by safety-rule violation, near miss, uncertainty, and disagreement; cluster duplicates; review selected clips; then create regression scenarios or training labels. **Disagreement is a mining trigger, not a ground-truth error label.** Keep a frozen test set and rerun it after each update; Waymo likewise describes a critic separate from the driver. [Waymo](https://waymo.com/blog/2026/08/10ailessons/), [AIDE](https://openaccess.thecvf.com/content/CVPR2024/html/Liang_AIDE_An_Automatic_Data_Engine_for_Object_Detection_in_Autonomous_CVPR_2024_paper.html)

A convincing demo would show one failure being discovered, replayed with its original seed, turned into a regression case, and retested after a change. **A reduction on that same mined case alone is insufficient:** report the frozen set and other scenario families as well. [nuPlan’s scenario-level evaluation approach](https://arxiv.org/abs/2403.04133), [Waymo’s critic and validation description](https://waymo.com/blog/2026/08/10ailessons/)

| Option | Build | Effort estimate | Main risk |
|---|---|---:|---|
| **Good** | Deterministic run logs, replay, and a manually reviewed failure queue. | 1–2 weeks | Reviewing too many similar events. |
| **Better — recommended** | Shadow proposals, automatic event triggers, deduplication, parameterized regression scenarios, frozen holdout. [AIDE](https://openaccess.thecvf.com/content/CVPR2024/html/Liang_AIDE_An_Automatic_Data_Engine_for_Object_Detection_in_Autonomous_CVPR_2024_paper.html) | 3–5 weeks | Label leakage and mistaking baseline disagreement for error. |
| **Best** | Add dashcam/track mining and human-checked open-vocabulary labels; train on DGX, evaluate in the Simulink loop. [Scenario Builder](https://www.mathworks.com/help/driving/ug/overview-of-scenario-generation-from-recorded-sensor-data.html), [OpenAnnotate3D](https://arxiv.org/abs/2310.13398) | 6–10 weeks | Noisy tracks and costly data review. |

## P11 — Evaluation, benchmarks, and safety case

### Correct the standards and benchmark framing

| Reference | What it supports—and its limit here |
|---|---|
| [ISO 26262](https://www.iso.org/publication/PUB200262.html) and [ISO 21448:2022](https://www.iso.org/standard/77490.html) | Functional safety of E/E faults and safety of the intended functionality, respectively. Use their hazard vocabulary and traceability ideas; **do not claim compliance**. |
| [ISO 34502:2022](https://www.iso.org/standard/78951.html) | **Important correction:** its scenario-based evaluation framework explicitly applies to **limited-access highways**. Indian village and market roads are outside that stated scope. Borrow its process as an adaptation, identified as such. |
| [ISO 34503:2023](https://www.iso.org/standard/78952.html) and [IEEE 2846-2022](https://standards.ieee.org/ieee/2846/10831/) | Specify the ODD and document reasonable assumptions about other road users. For this project, assumptions must explicitly include foreseeable wrong-way movement, seepage, crossings, and animals; that list is our proposed Indian-road application of the standards. |
| [UL 4600](https://www.ul.com/news/ul-4600-edition-3-updates-incorporate-autonomous-trucking) | Structure claims, evidence, and residual gaps. UL describes it as technology-agnostic and says no fixed road-mile count suffices by itself. A student simulation dossier can use this *style* without claiming certification. |
| [CARLA Leaderboard 2.1](https://leaderboard.carla.org/evaluation_v2_1/) | Current driving score combines per-route completion and infraction penalty; version **2.1 changed the penalty formula** from 2.0, so scores across versions are not directly comparable. Its blocked-agent and minimum-speed penalties help expose “always yield.” |
| [nuPlan](https://arxiv.org/abs/2403.04133), [interPlan](https://github.com/mh0797/interPlan), [NAVSIM metrics](https://github.com/autonomousvision/navsim/blob/main/docs/metrics.md), [WOSAC](https://waymo.com/open/challenges/2025/sim-agents/) | nuPlan is closed-loop planning; interPlan adds difficult interactive cases; NAVSIM’s PDMS/EPDMS uses short pseudo-simulation (v2 approximates later effects with staged scenes); WOSAC judges **simulated agents’ realism**, not ego driving success. Their scores are different quantities and their source roads do not establish Indian-road performance. |

The accessible [SIH26037 problem-statement mirror](https://sihone.pages.dev/ps/26037) names **replanning latency, path smoothness, and scenario completion rate**, plus five scenarios and two detailed RoadRunner scenes. It gives **no exact metric formulas or pass thresholds**; I could not verify an official PS page, so treat those counts as **provisionally sourced from a mirror**. Define and publish your formulas before comparing runs. [Mirror](https://sihone.pages.dev/ps/26037)

| Proposed metric for your harness | Operational definition |
|---|---|
| **Replanning latency** | Wall-clock time from a time-stamped world-state snapshot to a validated replacement trajectory; report median, p95, p99, maximum, and deadline misses. Include transfer/serialization when used. This is our definition; MathWorks distinguishes function timing from profiler overhead and notes `coder.timeit` excludes MATLAB-to-generated-code transfer. [MathWorks timing](https://www.mathworks.com/help/matlab/matlab_prog/measure-performance-of-your-program.html), [`coder.timeit`](https://www.mathworks.com/help/coder/ref/coder.timeit.html) |
| **Path smoothness** | Report curvature discontinuity and commanded/realized acceleration and jerk separately. A single “smoothness” number can conceal a sharp brake or oscillatory steering; NAVSIM likewise separates comfort from progress and collision terms. [NAVSIM metrics](https://github.com/autonomousvision/navsim/blob/main/docs/metrics.md) |
| **Scenario completion** | Destination reached within a declared simulation-time limit **and** without disqualifying contact or leaving the declared drivable region; also report raw progress and reason for failure. This is our proposed definition, informed by CARLA’s separate completion, infraction, and blocked-agent accounting. [CARLA 2.1](https://leaderboard.carla.org/evaluation_v2_1/) |

For **safety**, retain each contact by object class and impact speed; report minimum geometric clearance with uncertainty margins, TTC and PET where applicable, and violations of your explicit braking/right-of-way assumptions. TTC and PET are conflict surrogates, not substitutes for observed collisions. For **mobility**, report route progress, time to complete, and deadlock/timeout rate. For **comfort**, report longitudinal/lateral acceleration and jerk. Stratify every result by scenario family, weather, and sensing mode, including runs in which the perception model misses an object. [FHWA definitions of TTC/PET](https://www.fhwa.dot.gov/publications/research/safety/08051/02.cfm), [CARLA 2.1 scoring](https://leaderboard.carla.org/evaluation_v2_1/), [NAVSIM metrics](https://github.com/autonomousvision/navsim/blob/main/docs/metrics.md)

**Statistics:** if independent runs yield zero failures, the exact one-sided 95% binomial upper bound is \(1-0.05^{1/n}\). It takes **299 zero-failure runs to put that bound below 1% for one specified test distribution**; about 2,995 for 0.1%. Reusing correlated seeds weakens that interpretation. Report intervals *per family* and treat adversarially sampled failure frequency as a stress-test result, not a road-event rate; rare-event probability estimation needs a defined base distribution and appropriate sampling weights. [NIST’s rule-of-three discussion](https://pages.nist.gov/frvt/reports/demographics/nistir_8429.pdf), [rare-event AV testing paper](https://arxiv.org/abs/1811.00145)

**Baselines:** test the same scenario seeds with your current planner, a documented MathWorks controller/planner example, an always-yield policy to expose deadlock, and a simple rule-based gap/stop planner inspired by PDM-Closed. Label the last one “PDM-like” unless you actually port its implementation and inputs; interPlan publishes the real PDM-Closed baseline. ORCA is useful as a **geometric reciprocal-avoidance comparison**, but its standard velocity-space formulation alone does not solve car steering, braking, and right-of-way. [MathWorks path control](https://www.mathworks.com/help/mpc/ref/pathfollowingcontrolsystem.html), [interPlan baselines](https://github.com/mh0797/interPlan), [ORCA authors’ project](https://gamma.cs.unc.edu/ORCA/)

| Option | Build | Effort estimate | Main risk |
|---|---|---:|---|
| **Good** | Five named showcase scenarios, fixed seeds, all three PS metrics plus contacts and timeouts. [PS mirror](https://sihone.pages.dev/ps/26037) | 1–2 weeks | Showcase success says little about robustness. |
| **Better — recommended** | Parameter sweeps and held-out seeds by family; baselines; confidence intervals; a claims/evidence/gaps sheet. [nuPlan](https://arxiv.org/abs/2403.04133), [UL 4600](https://www.ul.com/news/ul-4600-edition-3-updates-incorporate-autonomous-trucking) | 3–5 weeks | Simulator or actor behavior can dominate the result. |
| **Best** | Add independent simulator/sensor variants, rare-event search with explicit sampling assumptions, and reviewed regression evidence. [Rare-event testing](https://arxiv.org/abs/1811.00145), [Waymo on closed-loop simulation](https://waymo.com/blog/2026/08/10ailessons/) | 8–12 weeks | Large run count still cannot establish real-road safety. |

## P12 — Real-time compute and deployment

| Raw-note claim checked | Verdict |
|---|---|
| **MATLAB → Jetson/DRIVE** | **Verified, with prerequisites:** MATLAB Coder’s NVIDIA support package lists Jetson AGX Thor, AGX Orin, Orin Nano and DRIVE kits; **GPU Coder is additionally needed for CUDA**, and Simulink code generation needs the relevant coder products/support packages. Hardware and release compatibility must be checked for the installed release. [MathWorks NVIDIA support](https://www.mathworks.com/help/coder/nvidia.html), [GPU Coder prerequisites](https://www.mathworks.com/help/gpucoder/gs/install-prerequisites.html) |
| **PyTorch → Simulink → Jetson example** | Verified: MathWorks’ July 2026 YOLOv26 segmentation example uses a PyTorch ExportedProgram block and deploys to **Jetson AGX Orin**. It is an example pipeline, not proof that your complete stack is code-generation compatible. [MathWorks blog](https://blogs.mathworks.com/deep-learning/2026/07/06/from-pytorch-to-jetson-via-simulink-deploying-yolov26-instance-segmentation-with-code-generation/) |
| **GPU Coder on KIET licence / installed state** | **UNVERIFIED externally.** The licence number and “not installed” status come from the project notes; confirm in the institution’s MathWorks licence portal and local `ver` output. [MathWorks prerequisite/product check](https://www.mathworks.com/help/gpucoder/gs/install-prerequisites.html) |
| **Chip figures** | EyeQ6 **High** is 34 INT8 TOPS; do not assign 34 TOPS to EyeQ6 Lite. DRIVE AGX Orin is **up to 254 TOPS**; Jetson AGX Orin is **up to 275 INT8 TOPS with sparsity**; DRIVE AGX Thor is **over 1,000 INT8 TOPS / 2,000 FP4 TFLOPS**. These are differing products and arithmetic formats, so a blanket “30–250 TOPS Indian ADAS budget” is **unsupported**. [Mobileye](https://www.mobileye.com/technology/eyeq-chip/), [NVIDIA DRIVE](https://www.nvidia.com/en-us/solutions/autonomous-vehicles/in-vehicle-computing/), [NVIDIA Jetson guide](https://developer.nvidia.com/sites/default/files/akamai/Jetson_AGX_Orin_Developer_Kit_RG_0.pdf) |
| **NXP + EyeQ6 Lite BOM below $95** | **UNVERIFIED.** I found no primary NXP/Mobileye source establishing that BOM; exclude it from the pitch. Qualcomm does position Ride Flex as a consolidated cockpit/ADAS platform for mass-market tiers, but that supplies no universal Indian hardware budget. [Qualcomm white paper](https://www.qualcomm.com/content/dam/qcomm-martech/dm-assets/documents/Snapdragon-Ride-GLOBAL-whitepaper.pdf) |
| **Separate safety ECU** | Too prescriptive. Waymo describes an independent onboard validation layer; Qualcomm describes mixed-criticality functions and a safety island on an SoC. For this simulation, prove **logical independence, bounded response, and stale-output handling**; a separate physical ECU is a later hardware decision. [Waymo](https://waymo.com/blog/2026/08/10ailessons/), [Qualcomm](https://www.qualcomm.com/automotive/solutions/snapdragon-ride) |

The reported **736 ms/step on M1** is a *project measurement supplied in your notes*, not independently verified here. “Codegen plus a smaller grid reaches 10 Hz” remains **UNVERIFIED**. Profile the actual call graph first; generate MEX for codegen-compatible hot paths, compare outputs with interpreted MATLAB, and measure whole-loop wall time under dense traffic. MATLAB provides `timeit`, Profiler, generated-MEX profiling, and `coder.timeit`; note that the last excludes MATLAB↔generated-code transfer. [MathWorks timing guide](https://www.mathworks.com/help/matlab/matlab_prog/measure-performance-of-your-program.html), [MEX profiling](https://www.mathworks.com/help/coder/ug/profile-generated-mex-functions-using-matlab-profiler.html), [`coder.timeit`](https://www.mathworks.com/help/coder/ref/coder.timeit.html)

**Proposed 10 Hz gate:** set a 100 ms planner-cycle deadline, then measure sensor-to-actuation age separately. Report p50/p95/p99/max for perception, tracking, prediction, planning, validation, control, and transfers; count missed deadlines. If the new plan is late or stale, the safety controller must use a previously validated bounded action or a tested stop response. **These are project design targets, not published industry latency limits.** The distinction matters because an open stack may run low-level control faster than planning; openpilot’s control loop, for example, is 100 Hz. [openpilot source](https://github.com/commaai/openpilot/blob/master/openpilot/selfdrive/controls/controlsd.py), [MathWorks timing guide](https://www.mathworks.com/help/matlab/matlab_prog/measure-performance-of-your-program.html)

| Option | Build | Effort estimate | Main risk |
|---|---|---:|---|
| **Good** | Profile interpreted MATLAB and Simulink; reduce candidate count only after identifying the bottleneck; publish latency distributions and deadline misses. [MATLAB Profiler](https://www.mathworks.com/help/matlab/matlab_prog/profiling-for-improving-performance.html), [Simulink Profiler](https://www.mathworks.com/help/simulink/slref/simulinkprofiler.html) | 1–2 weeks | Optimizing the wrong stage. |
| **Better — recommended** | MEX/codegen the planner and gate, use fixed-size interfaces, test numerical equivalence, and demonstrate the full loop at the declared rate on the available Windows lab PC. [MathWorks MEX profiling](https://www.mathworks.com/help/coder/ug/profile-generated-mex-functions-using-matlab-profiler.html) | 3–5 weeks | Unsupported MATLAB functions or changed numerical behavior. |
| **Best** | Deploy supported perception and planning components to a borrowed Jetson/DRIVE target; measure on-device timing, power, memory, and missed deadlines with the safety gate active. [MathWorks support package](https://www.mathworks.com/help/coder/nvidia.html) | 6–10 weeks **after hardware/licence access** | Target availability, codegen support, and data-transfer cost. |

**Overall choice:** P9 **Better**, P10 **Better**, P11 **Better**, and P12 **Good → Better** form one defensible student system: a controller whose limits are measured, a reproducible learning loop, stratified closed-loop results, and a demonstrated timing budget. The strongest honest claim at that point is **“validated in our declared simulated ODD and scenario distribution”**; the cited standards and Waymo’s own discussion of simulation do not turn that into demonstrated public-road safety. [ISO 34503](https://www.iso.org/standard/78952.html), [UL 4600](https://www.ul.com/news/ul-4600-edition-3-updates-incorporate-autonomous-trucking), [Waymo](https://waymo.com/blog/2026/08/10ailessons/)