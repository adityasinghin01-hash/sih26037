# P3 — The planner (the brain)

Status: FINAL (round 1 + round 2), 26 Sep 2026. Codex (session A, gpt-6-sol, xhigh) + Claude verification.

## What Claude verified by opening the source
- Waymo Driver/Simulator/Critic + separate onboard validator (Waymo blog, Dec 2025).
- **Alpamayo-R1-10B licence is OpenMDW-1.1: permissive, no non-commercial restriction** (read the
  LICENSE file). Claude's earlier "non-commercial" note was wrong.
- **Mosaic** (KIT-MRT, arXiv 2604.13853, Apr 2026): rule-based + learned planners combined through
  arbitration graphs, with **centralised verification as a "safety floor"**. SOTA on nuPlan. Code
  on github.com/KIT-MRT/mosaic.
  **So "learned proposer + rule validator" is published prior art.**
- **Minus Zero**: an end-to-end camera → foundation model → trajectory demo on **Bengaluru public
  roads**, 20 May 2025, safety driver, ≤25 km/h. "Campus-limited" was outdated.
- **Patents (Google Patents pages):**
  - US9481367B1 / US9481366B1: animal–AV interaction. **Assignee IBM** (NOT Google, as an older
    memory note said). **Expired (fee related).**
  - US11840258B2 "navigating with safe distances": **Mobileye**, active to 2040.
  - US12280797B2 "validation of trajectory planning": **Waymo**, active to 2043. Claim 1 = an
    untrusted planner's trajectory is checked by a trusted *planner* generating an alternative.
    A **non-planning geometric verifier is a different architecture**, but this is not legal advice.

## Novelty status after P3 (be blunt)
Every one of these planner mechanisms is **prior art**:
- probing (2608.21400)
- shared trunk + contingency (CoPlanner)
- rule + learned hybrid with a verifier (Mosaic)
- Indian scenario library (Safety Pool / ARAI)

What is left is a **measured, India-calibrated implementation + closed-loop evaluation in the PS
toolchain**, plus whatever the yield/assert upgrade (round 2) adds.

## Hard arithmetic on real-time (from our audit)
- 736 ms per step, 88% hotspot ≈ 648 ms.
- Hitting 100 ms needs the hotspot at ~12 ms, i.e. **≈55× faster**.
- Even 10× gives ~153 ms.
- **The candidate count and the collision checker must be redesigned, not tuned.**

## Codex recommendation (accepted as a working direction, not final)
- **A (recommended first):** a small learned scorer over 8–16 precomputed feasible manoeuvres,
  plus an independent swept-footprint / uncertainty / stop-distance verifier, plus a certified
  brake fallback and a "blocked" state.
- **B:** a conditional predictor for 1–3 decisive actors + limited contingency search. The best
  interaction model, but the heaviest compute.
- **C:** an RL manoeuvre chooser over the same safe library. A stretch/ablation option.
- **First, in all cases:** fix the S2/S3 stall and the timing.

---
# P3 — planner research and audit

**Recommendation:** build a small learned candidate scorer around your existing geometric planner, with a separate short-horizon safety check and a persistent deadlock recovery state. The first work is to fix the reported stall and timing failure. Adding learning to the current 736 ms loop would make neither result better.

## 1. Audit of your notes

| Note | Audit |
|---|---|
| **Waymo: foundation model → Driver, Simulator, Critic** | **Verified, with a nuance.** Waymo adapts a shared foundation model into task-specific teachers, then distils smaller runtime students. Its World Decoder produces trajectories and validation signals; a **separate onboard layer verifies generated trajectories**. The public post does not disclose that validator’s exact algorithm. [Waymo technical post](https://waymo.com/blog/2025/12/demonstrably-safe-ai-for-autonomous-driving/) |
| **Tesla: one pixels-to-control network; RL; video world model** | Tesla calls V14.2 an end-to-end driving model and confirms an RL training stage. Its public material also describes world representations and trajectory planning. The exact deployed network output, independent onboard validator, and role of the video-generation model in the driving policy are **UNVERIFIED**. FSD *Supervised* remains an L2 system relying on an attentive driver. [Tesla CVPR page](https://www.tesla.com/event/tesla-x-cvpr-2026), [Tesla Q1 2026 update](https://ir.tesla.com/_flysystem/s3/sec/000162828026026551/tsla-20260422-gen.pdf), [Tesla AI page](https://www.tesla.com/en_gb/AI), [Tesla L2 description](https://www.tesla.com/fsd-evidence-dashboard) |
| **Alpamayo 1 licence is non-commercial** | **Needs correction as of this check.** NVIDIA’s January announcement anticipated future commercial-use options, but the model’s *current posted* OpenMDW-1.1 licence grants use without a non-commercial restriction, subject to its terms. Recheck the exact model licence before reuse. Alpamayo 1 is a **10B teacher**, intended for distillation rather than direct vehicle deployment. [Announcement](https://nvidianews.nvidia.com/news/alpamayo-autonomous-vehicle-development), [current model licence](https://huggingface.co/nvidia/Alpamayo-R1-10B/blob/main/LICENSE) |
| **Swaayatt map-free; Minus Zero campus-limited** | Swaayatt itself advertises **sparse maps**, so “map-free” is too strong. Minus Zero describes a supervised public-road Bengaluru demonstration in 2025, with a safety driver and speeds up to 25 km/h; “campus-limited” is outdated. Both firms’ detailed runtime safety logic is **UNVERIFIED**. [Swaayatt](https://www.swaayattrobots.com/), [Minus Zero technical account](https://minuszero.ai/blog/how-did-foundational-model-learn-to-navigate-the-busy-streets-of-bengaluru) |
| **Novelty: probe-and-commit, shared trunk, hybrid validator, Indian test suite** | The first two have direct prior art in [ego-conditioned MPPI](https://arxiv.org/abs/2608.21400) and [CoPlanner](https://arxiv.org/abs/2509.17080). A **rule/learned planner with separate verification and arbitration** is also published as [Mosaic](https://arxiv.org/abs/2604.13853). Indian scenario collection exists in [Safety Pool’s 2026 paper](https://saemobilus.sae.org/papers/crowdsourcing-indian-traffic-scenarios-adas-development-testing-2026-26-0046). Your defensible contribution is a *measured implementation and evaluation* for reactive, heterogeneous Indian traffic in the required toolchain, if your results establish it. |
| **Current planner audit row** | I found research notes in the accessible workspace, but no planner `.m` or `.slx` files to inspect. Therefore the stated root cause, 736 ms profile, and scenario outcomes are **team-reported, not independently verified here**. The reported worst clearance of **−0.001 m is contact**; the confidence interval for *mean* clearance does not establish collision safety. |

## 2. What the named systems actually disclose

“Interaction” below means evidence of how the planner accounts for another road user’s response, not a claim that it solves Indian-road negotiation.

| System | Planner type and output | Safety, interaction, and public evidence |
|---|---|---|
| **Waymo** | Hybrid learned world model; World Decoder generates ego trajectories and predicts other users. | Separate onboard trajectory validation; simulation and Critic feed improvement. Exact interaction policy and validator internals are proprietary. **Company technical disclosure, not code.** [Waymo](https://waymo.com/blog/2025/12/demonstrably-safe-ai-for-autonomous-driving/) |
| **Tesla** | End-to-end driving model is publicly claimed; vehicle supplies lateral and longitudinal control. Exact neural-network output interface is **UNVERIFIED**. | For FSD *Supervised*, active driver oversight, monitoring, warnings and controlled slowdown form the disclosed safety arrangement. Separate trajectory shield and negotiation algorithm: **UNVERIFIED**. No production planner code. [CVPR page](https://www.tesla.com/event/tesla-x-cvpr-2026), [L2 evidence filing](https://www.tesla.com/fsd-evidence-dashboard) |
| **Mobileye** | “Compound AI”: learned components plus purpose-built planning for motion, behavior and collision avoidance; full output schema is **UNVERIFIED**. | RSS supplies explicit safe-distance and proper-response rules as part of the driving policy; it is **not itself the whole planner**. Public model and descriptions, production code proprietary. [Compound AI](https://www.mobileye.com/blog/compound-ai-the-framework-powering-scalable-autonomy/), [stack](https://www.mobileye.com/blog/autonomous-vehicle-day-the-self-driving-stack/), [RSS](https://www.mobileye.com/technology/responsibility-sensitive-safety/) |
| **Wayve** | End-to-end network from six camera streams plus supporting sensor/navigation data to a **motion plan** actuated by a controller. | Learns behavior from driving data; precise onboard safety check and negotiation logic are **UNVERIFIED**. Public research and demonstrations, not production planner code. [Wayve technical explanation](https://wayve.ai/thinking/emerging-behaviour-of-our-driving-intelligence-with-end-to-end-deep-learning/) |
| **NVIDIA** | **Alpamayo 1:** video → reasoning traces and trajectories, as a teacher. **Hydra-MDP:** research model distilling human and rule-based teachers into trajectory heads. Neither establishes the proprietary DRIVE production planner architecture. | AlpaSim provides open closed-loop testing. A rule-based *training teacher* in Hydra-MDP is not evidence of an independent **runtime** shield. Public [Alpamayo announcement](https://nvidianews.nvidia.com/news/alpamayo-autonomous-vehicle-development), [AlpaSim code](https://github.com/NVlabs/alpasim), [Hydra-MDP paper](https://arxiv.org/abs/2406.06978); production safety/negotiation **UNVERIFIED**. |
| **Baidu Apollo** | Modular prediction → scenario/decider/path/speed planning → timed trajectory (position, speed, acceleration) for control. | Predicted obstacle trajectories and explicit decisions/Estop are public; interaction is handled through prediction and scenario rules, with no demonstrated general negotiation guarantee. **Code available.** [Planner overview](https://github.com/ApolloAuto/apollo/blob/master/collection/planning/README.md), [output and inputs](https://github.com/ApolloAuto/apollo/blob/master/docs/07_Prediction/Class_Architecture_Planning.md) |
| **Autoware** | Modular behavior path and velocity planners; outputs a path with velocity/stop decisions. | Collision checks and behavior modules are public, but a general non-lane negotiation planner is **UNVERIFIED**. **Code and documentation available.** [Behavior path](https://autowarefoundation.github.io/autoware_universe/main/planning/behavior_path_planner/autoware_behavior_path_planner/), [velocity planner](https://autowarefoundation.github.io/autoware_core/pr-292/planning/motion_velocity_planner/autoware_motion_velocity_planner/) |
| **comma.ai openpilot** | Learned driving model combined with conventional longitudinal MPC and lateral control; produces driver-assistance steering/speed commands. | Driver-supervised L2 and actuator safety limits; no public evidence of autonomous unsignalled-junction negotiation. **Code available.** [Longitudinal planner](https://github.com/commaai/openpilot/blob/master/openpilot/selfdrive/controls/lib/longitudinal_planner.py), [safety document](https://github.com/commaai/openpilot/blob/master/docs/SAFETY.md) |
| **Swaayatt** | Company describes RL/agentic decision making, sparse-map navigation and learned control. Planner’s precise output is **UNVERIFIED**. | Bidirectional negotiation and safety method lack inspectable production evidence in the material found. Treat performance claims as **company claims**. [Swaayatt site](https://www.swaayattrobots.com/) |
| **Minus Zero** | Company describes camera → foundation model → planned trajectory → controller; no HD-map dependency claimed. | It reports simulation, public-road tests with a safety driver, and onboard “safety mechanisms”; the mechanism is **UNVERIFIED**. **Company technical account, no production code found.** [Training and road-test account](https://minuszero.ai/blog/how-did-foundational-model-learn-to-navigate-the-busy-streets-of-bengaluru), [technology page](https://minuszero.ai/technology) |

**Synthesis:** there is no verified single architecture “everyone converges on.” Waymo and Mobileye disclose layered safety around learning; Apollo and Autoware are modular; Tesla and Wayve disclose end-to-end policies with fewer public runtime details. These are materially different evidence levels. [Waymo](https://waymo.com/blog/2025/12/demonstrably-safe-ai-for-autonomous-driving/), [Mobileye](https://www.mobileye.com/blog/compound-ai-the-framework-powering-scalable-autonomy/), [Apollo](https://github.com/ApolloAuto/apollo/blob/master/collection/planning/README.md), [Wayve](https://wayve.ai/thinking/emerging-behaviour-of-our-driving-intelligence-with-end-to-end-deep-learning/)

## 3. Interactive-planning research

**Reading the scores:** NAVSIM’s original PDMS uses a **four-second non-reactive** rollout; nuPlan’s reactive score uses simulated reacting agents. Neither is a test of unstructured Indian roads. PDMS, EPDMS and nuPlan CLS must not be ranked against each other as one leaderboard. “Non-lane” means *demonstrated* planning without dependable lanes, not possible adaptation. [NAVSIM paper](https://proceedings.neurips.cc/paper_files/paper/2024/hash/32768f7faf1995026ef9821c696f3404-Abstract-Datasets_and_Benchmarks_Track.html), [nuPlan paper](https://arxiv.org/abs/2403.04133)

| Work | Core idea; non-lane evidence | Compute, code, reported result |
|---|---|---|
| [MARC, 2023](https://arxiv.org/abs/2308.12021) | Ego policy-conditioned futures, risk-aware contingency tree. **Non-lane: no.** | Bi-level optimization; runtime, code and directly comparable score **UNVERIFIED**. |
| [Contingency Games, 2023](https://arxiv.org/abs/2304.05483) | Strategic branches until other agents’ intent becomes clearer. **Non-lane: no.** | Multi-agent game optimization; runtime/standard benchmark number **UNVERIFIED**. [Author’s code/project page](https://lasse-peters.net/pub/contingency-games/). |
| [GameOpt+, 2024](https://arxiv.org/abs/2405.16430) | Auction orders vehicles; optimizer sets speeds at an unsignalled intersection. **Heterogeneous but lane-defined and centrally coordinated.** | Authors report **<10 ms** and ≥25% throughput gain in SUMO. Their model assumes **ideal, zero-delay V2I with connected controllable vehicles**, so it cannot be transplanted to unconnected Indian traffic. Code **UNVERIFIED**. [Model assumptions](https://arxiv.org/pdf/2405.16430) |
| [B-GAP, 2020–22](https://arxiv.org/abs/2011.03748) | Historical precursor: behavior-rich traffic simulation trains an RL policy for high-level controls. **Heterogeneous driver styles, not demonstrated lane-free.** | [Code available](https://github.com/angmavrogiannis/B-GAP-Behavior-Guided-Action-Prediction-and-Navigation-for-Autonomous-Driving); directly comparable 2023–26 benchmark score **not applicable**. This is Chandra coauthored work **outside** your requested date window. |
| [Ego-conditioned MPPI, Aug 2026](https://arxiv.org/abs/2608.21400) | Samples ego actions and conditional reactions; can probe before commitment. **Non-lane: no demonstrated Indian-road test.** | Nested sampling is compute intensive; runtime/code **UNVERIFIED**. Paper reports **75% adjacent-merge rate** and **0% on-ramp collisions** in its small simulation experiments. Its table says “20 runs” yet lists rates such as 37.5% and 56.25%; that denominator inconsistency needs author clarification. [Results table](https://arxiv.org/pdf/2608.21400) |
| [CoPlanner, 2025](https://arxiv.org/abs/2509.17080) | Diffusion generates a common near-term segment plus contingency branches, then scores them. **Non-lane: no.** | nuPlan **Val14 reactive 93.13** with refinement; **Test14-hard reactive 78.59**, below Diffusion Planner with refinement at **82.00**. Runtime **UNVERIFIED**; paper promises code upon acceptance, release **UNVERIFIED**. [Result table](https://arxiv.org/pdf/2509.17080) |
| [PDM-Closed / PDM-Hybrid, 2023](https://arxiv.org/abs/2306.07962) | Closed: rule-based candidate selection; Hybrid: learned long-term forecast alongside rule-based short-term planning. **Lane/reference-line dependent.** | nuPlan Val14 reactive **92.12 / 92.11** in CoPlanner’s comparison; compute figure **UNVERIFIED**. [PDM explanation](https://openreview.net/pdf?id=o82EXEK5hu6), [comparison table](https://arxiv.org/pdf/2509.17080) |
| [Hydra-MDP, 2024](https://arxiv.org/abs/2406.06978) | Distil human and rule teachers into multimodal trajectory heads. **Non-lane: no.** | NAVSIM challenge result reported, but a runtime safety validator and reproducible end-to-end runtime **UNVERIFIED**. [Public repository](https://github.com/NVlabs/Hydra-MDP); completeness requires inspection. |
| [DiffusionDrive, 2024–25](https://arxiv.org/abs/2411.15139) | Anchored, two-step truncated diffusion proposes trajectories. **Non-lane: no.** | **88.1 PDMS**, **45 FPS on RTX 4090** as reported by authors; [code/model](https://github.com/hustvl/DiffusionDrive). GPU figure does not imply MATLAB CPU timing. |
| [FlowDrive: Energy Flow Field, 2025](https://arxiv.org/abs/2509.14303) | Risk and lane-attraction fields guide an intent-gated **diffusion** planner. **Lane prior; non-lane unshown.** | **86.3 EPDMS**; runtime and code **UNVERIFIED**. This is **not** the distinct [FlowDrive flow-matching paper](https://arxiv.org/abs/2509.21961). |
| [DRIFT, 2026](https://arxiv.org/abs/2607.14507) | One-step latent drift creates 48 proposals, then aggregates them. **Non-lane: no.** | **89.6 PDMS / 90.4 EPDMS**; full inference **66.43 ms on RTX 4090**; code **UNVERIFIED**. |
| [CarPlanner, 2025](https://arxiv.org/abs/2502.19908) | RL trains an autoregressive, multimodal trajectory proposer. **Non-lane: no.** | **nuPlan Test14-Random CLS-NR 94.07, CLS-R 91.10**; paper trained with two RTX 3090s. Inference runtime and code **UNVERIFIED**. [Methods/results](https://arxiv.org/pdf/2502.19908) |
| [Mosaic, 2026](https://arxiv.org/abs/2604.13853) | Rule and learned planners propose; separate verification, scoring and arbitration select a trajectory. **Non-lane: no.** | **nuPlan Val14 reactive 93.98; interPlan reactive 54.30**; [code available](https://github.com/KIT-MRT/mosaic). Runtime on your hardware **UNVERIFIED**. |

## 4. The frozen-robot failure

The important published insight is that better *independent* predictions of each pedestrian can still leave every path apparently blocked. Trautman and Krause showed that **joint adaptation** matters. More recent work addresses contingent interaction and density generalization, but a safe system must still stop when there truly is no usable space. [Unfreezing the Robot](https://las.inf.ethz.ch/files/trautman10unfreezing.pdf), [2026 dense-crowd study](https://arxiv.org/abs/2603.06729)

| Fix to test, in order | Why it addresses your stall |
|---|---|
| **Repair the reported implementation faults first:** retain longitudinal station in the clearance gate; require a sustained WAIT decision; prevent timeout re-arming; break equal-cost ties toward verified progress. | These are team-reported causes, **UNVERIFIED without code**. A learned model would mask rather than establish whether they are fixed. |
| **Persist one blocked-state record:** reason, candidate corridor, elapsed time, observed actor response and recovery attempt. | Stops one-frame mode changes from resetting the decision. Treat timeout as a trigger to *re-evaluate*, never as permission to cross. This is an engineering recommendation; related published “stuck condition” detection exists. [Waymo patent](https://patents.google.com/patent/US8996224B1/en) |
| **Predict conditional responses for only the decisive actors.** Compare “holds course” and “yields” under a small ego creep, then update beliefs from observed motion. | Captures the joint adaptation behind frozen-robot research without evaluating a full behavior tree for every road user. An optimistic yield prediction must never be the only safe branch. [Trautman–Krause](https://las.inf.ethz.ch/files/trautman10unfreezing.pdf), [ego-conditioned MPPI](https://arxiv.org/abs/2608.21400) |
| **Execute only a common, stoppable near-term segment.** Keep longer alternatives contingent on what actors actually do. | This is the part of contingency planning worth retaining; it is established prior art, not the novelty claim. [CoPlanner](https://arxiv.org/abs/2509.17080), [MARC](https://arxiv.org/abs/2308.12021) |
| **Declare “blocked” when no certified move exists.** | A system cannot guarantee progress and no contact in an arbitrarily adversarial dense crowd. Record whether a feasible gap later appeared; count only failure to take such a gap as a planner deadlock. [Frozen-robot analysis](https://las.inf.ethz.ch/files/trautman10unfreezing.pdf) |

## 5. Patent map: claims and engineering choices

These are **US claim-reading observations, not an infringement or freedom-to-operate opinion**. A different implementation choice does not itself establish clearance; Indian families and current official register status are **UNVERIFIED**.

| Document | What an independent claim covers, in plain words | Relevant design choice |
|---|---|---|
| [Mobileye US11840258B2](https://patents.google.com/patent/US11840258B2/en) | Continue a planned action when predicted separation exceeds a specified longitudinal safe distance calculated from ego response/acceleration/braking and the target’s stopping distance. | Use a directly specified **reachable-occupancy and swept-geometry** safety check, documented from your own assumptions, instead of copying that particular distance/decision formula. |
| [Waymo US12280797B2](https://patents.google.com/patent/US12280797B2/en) | Feed part of a first planner’s trajectory into a **second planning system**; use its generated second trajectory to decide whether to validate the first. | A non-planning verifier that checks physical and occupancy constraints directly is a distinct architecture to examine. |
| [Tesla US20260098740A1](https://patents.google.com/patent/US20260098740A1/en) | **Pending application:** camera image → voxel occupancy/3D model → localization via image feature without a location-tracking sensor → path. | Your tracked-object/drivable-area planner with ordinary localization does not need that specific combined pipeline. Status and final claim scope can change. |
| [IBM US9481367B1](https://patents.google.com/patent/US9481367B1/en) | Species identification plus environment-conditioned animal motion prediction, encounter threshold, and—when blockage is forecast long enough—stop and turn off the engine. | Treat an animal as an uncertain occupied region and plan a stoppable path; avoid claiming invention of generic animal avoidance. Google lists this US patent as **fee-expired**, which needs official confirmation. |
| [IBM US9481366B1](https://patents.google.com/patent/US9481366B1/en) | Uses signals from **animal-worn transceivers**, including a second nearby animal, to estimate encounter risk and respond. | A camera/lidar-only cattle detector uses a materially different sensing premise. Google likewise lists this US patent as fee-expired, subject to confirmation. |

## 6. Student-team architecture decision

Using **your reported** 736 ms timing and 88% hotspot share: the hotspot is about **648 ms**, all other work about **88 ms**. At a 100 ms total budget, the hotspot allowance is **12 ms**, requiring roughly **55×** reduction if the rest stays constant. Even a 10× hotspot improvement gives about **153 ms** total. [MathWorks documents C/C++ generation for `dynamicCapsuleList`](https://www.mathworks.com/help/nav/ref/dynamiccapsulelist.html), but gives **no speed guarantee**.

| Candidate | Learned part → runtime output; verifier and fallback | Top-25 fit; feasibility; data; novelty judgment |
|---|---|---|
| **A. Small learned scorer over a bounded maneuver library — recommended** | A small model scores 8–16 precomputed, drivable-area-valid short trajectories using local actor history, occupancy, route and surface state. A **separate** swept-footprint/uncertainty/stop-distance check accepts one; fallback brakes within a certified corridor, then reports blocked. | **Best first build.** Handles the planning share of cut-ins, two-wheelers, wrong-way users, pedestrians, animals, narrow passages and unsignalled merges *if upstream detection and tracking work*. Smallest training need: labelled or counterfactual outcomes from your reactive Indian simulation. MATLAB deployment plausible through [ONNX import](https://www.mathworks.com/help/deeplearning/ref/importnetworkfromonnx.html) and a [Simulink Predict block](https://www.mathworks.com/help/deeplearning/ref/predict.html). **100 ms: UNVERIFIED until hotspot replacement is profiled.** The hybrid mechanism is prior art; India-specific calibration and measured results are the contribution. [Mosaic](https://arxiv.org/abs/2604.13853) |
| **B. Small conditional predictor + limited contingency search** | Predict 2–3 response modes for each of 1–3 decisive actors, conditioned on a few ego actions. Search a shared stoppable trunk and longer branches; verify the trunk against non-yielding/uncertain occupancy; brake on failure. | **Strongest interaction model**, especially S2/S3 deadlock, but the branching and repeated collision checks threaten 100 ms. Requires richer reactive training data and calibration of yielding by actor type. Prototype *after A*; a full MPPI/generative version is unlikely to meet your budget without substantial optimisation. Planner mechanism already published. [MPPI](https://arxiv.org/abs/2608.21400), [CoPlanner](https://arxiv.org/abs/2509.17080) |
| **C. RL chooses a maneuver from the same safe library** | A policy picks yield/creep/follow/go-around/gap. The **same independent verifier** checks the resulting trajectory; failed choices fall back to a stop and enter recovery state. | Could learn progress in dense traffic, but has the largest simulation coverage and distribution-shift risk. A bounded discrete policy is deployable through the [Simulink Policy block](https://www.mathworks.com/help/reinforcement-learning/ref/policy.html); its choice still needs validation. Useful as an ablation/stretch result, not the first national-PPT promise. [B-GAP](https://arxiv.org/abs/2011.03748), [CarPlanner](https://arxiv.org/abs/2502.19908) |

**Concrete build gate:** profile the actual planner; fix the reported S2/S3 stall; replace repeated expensive checks with a conservative broad phase, then exact-check only survivors; cap candidates and interaction actors; measure full Simulink step time. Compare A against your corrected rule-only baseline on the **same** reactive Indian scenario seeds. Report collision/contact, minimum clearance after uncertainty margins, feasible-gap progress, false deadlock, comfort and **p95/p99 latency**, including S2 and dense S3. MATLAB’s ONNX importer may create custom layers, so the *specific trained network* must be imported and code-generation tested rather than assuming generic compatibility. [MathWorks ONNX documentation](https://www.mathworks.com/help/deeplearning/ref/importnetworkfromonnx.html)

**PPT-safe claim:** “A safety-checked learned maneuver scorer and reactive Indian-road evaluation, implemented in MATLAB/Simulink.” Claim improvements only after the paired runs. Planner performance cannot cover the top 25 when perception misses an occluded child, animal, pothole or road edge.

### UNVERIFIED / still needed

- Actual `+sih/+planner` and `+sc/planSeat` source, profiler trace, S1–S3 logs, and the reported root-cause fix.
- Tesla’s deployed network output interface and any independent onboard trajectory validator; Wayve’s, Swaayatt’s and Minus Zero’s detailed onboard validators.
- A public, complete production NVIDIA DRIVE/Hydra planner implementation; code releases and comparable runtimes for MARC, CoPlanner, ego-conditioned MPPI and DRIFT where marked above.
- Indian-road, lane-free closed-loop results for the cited academic planners.
- Official US register confirmation of the two IBM patents’ fee status and any corresponding Indian patent families.
- Whether the proposed architecture can meet **100 ms** on your actual hardware and MATLAB/Simulink model.

---

# ROUND 2 — Replacing yield/assert

## Claude-verified
- **Kruse, Yel, Senanayake, Kochenderfer**, "Uncertainty-Aware Online Merge Planning with Learned Driver
  Behavior", arXiv 2207.05228 (2022).
  - A **particle-filter belief over a continuous cooperation level** inside an online POMDP.
  - **Simulation only.**
  - This is the closest prior art to our "cooperativeness belief" idea.
- **Cai & Hsu, LeTS-Drive**, "Closing the Planning-Learning Loop…", arXiv 2101.03834 (IEEE T-RO 2022).
  - Real-time belief-tree planning plus learning, in **crowded urban traffic with cars, motorcycles
    and buses** (unregulated, heterogeneous).
- **Correction:** arXiv 1704.04322 is by **Bouton, Cosgun, Kochenderfer**, not Hubmann (Claude's error).
- The Mohan & Chandra per-class critical gaps (below) are Codex-reported; the ResearchGate PDF was
  blocked to Claude. **Treat them as UNVERIFIED until the paper is opened.**

## FINDINGS IN OUR OWN CODE (Codex read the repo)
- `planContingency` carries `PYield` for logging but **does not use it to rank or permit
  candidates**. The yield model never influenced planning, even if gated on.
- `predictAgentFutures` makes 2 futures (yield/assert) that only change **speed along a fixed
  heading**. They **cannot bracket turns or sideways moves** (cut-ins, seepage, U-turns).
- `checkTrajectorySafety` **builds a new `dynamicCapsuleList` per candidate × future call**. This
  is the 88% hotspot, and its structure explains the ~55× gap to 100 ms.

## Decision: the representation that replaces yield/assert (working design)
- **Name:** "response propensity". An honest name, because behaviour alone doesn't prove
  psychology.
- **Per decision-relevant actor (max ~3):**
  - a belief over **intent modes** {continue, enter/cross, brake/turn, **group/cover** merge}
  - × a **5-point grid of response coefficient c ∈ [0,1]**
  - + an explicit "unmodelled" mass
  - Animals get their own motion model.
- **Update:** Bayes on the observed motion **given OUR executed action**. Broaden on occlusion or
  track loss.
- **Use:**
  - ego-conditioned multi-mode prediction per shortlisted ego path
  - ranking = progress + comfort + future options
  - **probe credit = the expected improvement in a later safe decision** (Geary et al.), not raw
    entropy
- **Permission** to move comes ONLY from an independent certificate: a no-cooperation response +
  lateral/turn envelopes + tracking uncertainty + a reachable stop.
- **Indian priors:**
  - class × class gap acceptance (Patil & Sangole: ~22% of two-wheelers accept a 3 s gap vs a
    two-wheeler, ~10% vs a car)
  - Chennai merge modes (group 37%, forced 26%, normal 21%, cover 16%)
  - pedestrian rolling crossings (Kanpur ~38%, Patna 26%)
  - Pedestrian-yield rates by class: **UNVERIFIED, must be measured.**
- **Novelty verdict (honest):** the mechanism is occupied (Sadigh, Geary, Kruse, LeTS-Drive, the
  2026 SVO planners, 2608.21400). What remains is the **India-calibrated implementation + group/cover/
  rolling modes + an ablation showing fewer contacts AND fewer permanent stalls, in MATLAB/Simulink
  at a measured 10 Hz.**

---
# P3 Round 2 — replacing yield/assert

**Recommendation:** represent each relevant road user with a belief over **what they may do** and **how strongly they respond to our motion**. Use that belief to rank reversible plans and decide when a cautious probe is useful. Keep permission to move with a separate geometric and braking check. I would call the continuous variable *response propensity*, not an SVO angle: observed motion alone does not establish a driver’s psychological preference.

## 1. Audit of the candidate

| Finding | Consequence |
|---|---|
| Schwarting et al. report **18% lower position error with “static best” SVO** and **25% with dynamically estimated SVO**, across 92 recorded US merges. “Static best” is fitted to the interaction; neither result is a real-car deployment result. [PNAS paper](https://sites.bu.edu/pierson/files/2021/05/schwarting2019pnas.pdf) | Strong evidence that social preference helps prediction; weak evidence for transferring a fixed class prior to Indian roads. |
| arXiv **1704.04322 is by Bouton, Cosgun and Kochenderfer**, not Hubmann, and reports simulation. [Paper](https://arxiv.org/abs/1704.04322) | Correct the attribution. A separate, earlier MOMDP was tested on an autonomous golf cart with pedestrians. [Bandyopadhyay et al.](https://dspace.mit.edu/entities/publication/ed3df604-a9da-4c15-b70f-a3a115241e09) |
| Your [planner](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/+sih/+planner/planContingency.m:39) currently carries `PYield` for logging but **does not use it to rank or permit candidates**; default generation is 5 offsets × 4 speeds. The [predictor](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/+sih/+planner/predictAgentFutures.m:46) changes speed along a fixed heading. | This upgrade needs a real planner integration, not just a better probability field. The comment that the two futures “bracket” actual behavior is false for turns and lateral movement. |
| The repo defines `PYield = 1 − P(assert)`, where “did nothing” can be counted with “did not take the gap.” Its recorded validation shows a **20.18% dangerous-error rate** against a **≤1% gate** and instructs `Valid=false` where that gate fails. [Ruling](https://github.com/adityasinghin01-hash/sih26037/blob/main/plan/S3-PYIELD-RULING.md:13) | Do not interpret current `PYield` as a calibrated probability of active yielding. Whether the deployed runtime currently emits `Valid=false` everywhere required is **UNVERIFIED**. |
| A raw entropy-reduction reward can encourage probes whose information will never change the driving decision. Geary et al. demonstrate this failure and propose **expected reward gain** instead. [Paper](https://arxiv.org/abs/2110.04580) | Probe only when resolving the uncertainty can improve a *safe* subsequent choice. |

## 2. Serious representations

“Compute” is a **relative implementation assessment**, not a measured latency on your machine. “Vehicle” distinguishes an autonomous vehicle experiment from evaluation on recorded human driving.

| Approach | Output and data required | Vehicle evidence; compute; code |
|---|---|---|
| **Discrete maneuver/type belief**: keep, brake, turn, cross; optionally passive/aggressive style. Needs tracked motion and maneuver labels. [Latent-driver paper](https://arxiv.org/pdf/1704.05566.pdf) | Its published evaluation used synthetic drivers. Low runtime cost after training; [research code](https://github.com/sisl/latent_driver). A fixed type misses changes within an encounter. |
| **SVO / reward weighting**: an inferred angle or reward weights trading own and others’ outcomes; needs interaction trajectories and a specified reward/game model. [Schwarting et al.](https://sites.bu.edu/pierson/files/2021/05/schwarting2019pnas.pdf) | Recorded NGSIM data plus simulation, no verified vehicle test. Online game solving costs more than a small classifier; [third-party reproduction](https://github.com/superboySB/SVO4AD), authors’ runnable code **UNVERIFIED**. Later SVO–Stackelberg and SVO-conditioned-prediction studies already cover much of this mechanism. [2023 study](https://saemobilus.sae.org/articles/game-theory-based-lane-change-decision-making-considering-vehicles-social-value-orientation-2023-01-7109), [2026 MATLAB/Python study](https://www.mdpi.com/2079-9292/15/9/1914) |
| **Continuous cooperation belief + POMDP**: a distribution over another driver’s cooperation level, updated by a particle filter; outputs a merge policy. Needs responsive trajectories and an actor model. [Kruse et al., 2022](https://arxiv.org/abs/2207.05228) | High-fidelity **simulation**, not verified on a vehicle. Particle update is modest; online belief-tree planning is the costly part. Public code **UNVERIFIED**. This is particularly close to your proposal. |
| **Intent belief / MOMDP**: discrete hidden destination or crossing intent alongside observed kinematics. Needs intent-conditioned motion models. [Bandyopadhyay et al.](https://dspace.mit.edu/entities/publication/ed3df604-a9da-4c15-b70f-a3a115241e09) | A golf-cart pedestrian experiment establishes real-platform feasibility, but is from **2013** and does not establish dense-road capability. A 2024 unsignalized-intersection POMDP study used aerial-data-seeded **simulation**. [Study](https://arxiv.org/abs/2412.06405) |
| **Ego-conditioned joint prediction**: distributions of others’ paths *given a candidate ego path*. Needs multi-agent tracks and, ideally, varied ego actions. [Waymo conditional behavior prediction](https://waymo-prod.appspot.com/research/identifying-driver-interactions-via-conditional-behavior-prediction/), [MotionLM](https://waymo-prod.appspot.com/research/motionlm/) | The cited research pages describe prediction models; their deployment in a particular Waymo runtime planner is **UNVERIFIED**. Inference cost grows with ego candidates and sampled futures. Public implementation of these models **UNVERIFIED**. |
| **Level-k, Stackelberg, Nash / learned games**: response or equilibrium trajectories under assumed reasoning levels and payoffs; needs a payoff model and online fitting. [Open level-k simulator](https://sites.google.com/umich.edu/testing-of-automotive-cps/game-theoretic-traffic-simulator), [GPG-drive paper/code](https://brechtevens.github.io/GPG-drive/) | The cited implementations show simulation and offer code, including an intersection MATLAB model on the level-k site. A distinct 2024 game/IRL study reports real-vehicle tests, but its **72.73% decision similarity and zero reported safety violations** do not validate this approach for Indian crowds. [Study](https://arxiv.org/abs/2402.11467) Exact online equilibrium solving is expensive. |
| **Inverse RL / reward distributions**: inferred costs or driving-style mixture from demonstrations; predicts behavior by optimizing those costs. [Probabilistic IRL](https://arxiv.org/abs/2008.08812) | Evaluated on recorded human driving, not a vehicle for that paper. Offline learning can be expensive; online lookup plus prediction is cheaper. A separate IRL *ego planner* has been tested on a vehicle in Las Vegas; that is evidence for IRL planning, not for online inference of every neighboring driver. [DriveIRL](https://arxiv.org/abs/2206.03004) |
| **Active information gathering**: choose a reversible action because observing the response can improve the next decision. Needs an ego-conditioned response model. [Sadigh et al.](https://people.eecs.berkeley.edu/~sastry/pubs/Pdfs%20of%202018/SadighPlanning2018.pdf), [Geary et al.](https://arxiv.org/abs/2110.04580) | Human-user studies and simulation in the cited work; an on-road autonomous test is **UNVERIFIED**. Evaluating information value for every candidate is costly. The August 2026 ego-conditioned MPPI paper also explicitly probes in closed-loop simulation. [Mustafa et al.](https://arxiv.org/abs/2608.21400) |
| **Traffic-engineering gap model**: probability of accepting a gap given its duration, speeds, geometry and vehicle classes. Needs observed **accepted and rejected opportunities**, not just successful turns. [Indian study](https://link.springer.com/article/10.1007/s40534-014-0057-8) | Cheap logistic/lookup inference; no autonomous-vehicle result implied. It estimates what the *gap-seeking vehicle* does, **not** whether a conflicting vehicle will yield to us. |

## 3. Indian evidence that can actually set priors

| Observation | Appropriate use |
|---|---|
| Across **six Indian unsignalized intersections**, a study’s model lists base critical gaps for right turns from **major/minor** roads, respectively: two-wheeler **2.5/3.5 s**; three-wheeler **2.7/3.7 s**; small car **2.7/3.8 s**; bus **3.6/5.5 s**; truck **3.8/5.7 s**. These are *model base values*, not universal safe gaps or yield probabilities. [Mohan & Chandra, Table 10](https://www.researchgate.net/profile/Mithun-Mohan-2/publication/350907993_Investigating_the_Influence_of_Conflicting_Flow%27s_Composition_on_Critical_Gap_under_Heterogeneous_Traffic_Conditions/links/61ae043529948f41dbcddfab/Investigating-the-Influence-of-Conflicting-Flows-Composition-on-Critical-Gap-under-Heterogeneous-Traffic-Conditions.pdf) | Initialize **maneuver/gap-taking** models by class and geometry. The bus/truck figures also undermine the proposed “bus/truck = selfish” prior: physical clearing time matters. |
| At four Maharashtra T-junctions, for a displayed **3 s** gap, about **22%** of right-turning two-wheelers accepted it when the conflicting vehicle was a two-wheeler, versus about **10%** when it was a car. [Patil & Sangole study](https://link.springer.com/article/10.1007/s40534-014-0057-8) | Condition gap acceptance on **both** parties’ class. These cumulative observations are site-specific, not a general response-to-ego probability. |
| One congested Chennai T-junction study classified merges as **group 37%, forced 26%, normal 21%, vehicle-cover 16%**. [Kanagaraj et al.](https://www.sciencedirect.com/science/article/abs/pii/S1369847815000224) | Add **group** and **cover** as interaction modes. A single scalar cooperativeness cannot represent them. |
| A Kanpur unsignalized-intersection study reports **3.76 s mean pedestrian critical headway** and about **38% rolling-gap crossings**. [Study](https://www.sciencedirect.com/science/article/abs/pii/S1369847820304927) A separate Patna study observed **722 interactions**, with **26% rolling crossings** and **54.8% group crossings**. [Study](https://www.nature.com/articles/s41598-026-55112-9) | Set context-dependent pedestrian **crossing modes**, with wide uncertainty. These numbers are not vehicle-to-pedestrian yielding rates. |
| Indian midblock research finds driver yielding varies with speed and road geometry; the accessible evidence does **not** establish a transferable, vehicle-class-specific yielding percentage. [Study](https://doi.org/10.1016/j.iatssr.2020.06.001) | **UNVERIFIED:** numerical Indian priors for `P(car/bus/two-wheeler yields to pedestrian or ego)`. Measure them from annotated interaction opportunities before using them. |

## 4. Buildable representation and planner

I recommend an **intent × response belief**, implemented first with fixed-size MATLAB arrays:

1. **Per tracked actor:** retain measured S1 kinematics; a belief over `z = {continue, enter/cross, brake/turn, group/cover when relevant}`; five grid values for a continuous **response coefficient** `c∈[0,1]`; and an explicit *unmodelled/uncertain* probability. Treat animals with a separate motion model, not SVO. Five grid points and a limit of three decision-relevant actors are **proposed engineering choices**, not published performance claims. This follows the distinction between intent, latent cooperation and multimodal motion in [Kruse et al.](https://arxiv.org/abs/2207.05228) and [Chakravarty et al.](https://arxiv.org/abs/2602.14540).

2. **Update using the action we actually executed:**  
   `bₜ(z,c) ∝ P(observed acceleration, lateral motion | z,c, ego actionₜ₋₁, scene) × predicted bₜ₋₁(z,c)`.  
   Broaden the belief after occlusion, track loss or model mismatch. Do **not** claim to learn responsiveness during a period when ego’s motion offered the other actor no observable choice. A small grid Bayes update is easier to bound and deploy than a full particle-filter POMDP; the latter is demonstrated for merging by [Kruse et al.](https://arxiv.org/abs/2207.05228).

3. **Predict conditionally, plan reversibly:** for each shortlisted ego path, produce a few actor motion modes conditional on that path and the current belief. Rank candidates by progress, comfort and future options. Give a cautious probe credit only for its **expected improvement in a later safe decision**, minus delay and disturbance; do not give a blanket entropy bonus. [Conditional prediction](https://waymo-prod.appspot.com/research/identifying-driver-interactions-via-conditional-behavior-prediction/), [information-sufficiency result](https://arxiv.org/abs/2110.04580).

4. **Independently certify the executed prefix and stop:** check a no-cooperation response, plausible lateral/turning envelopes, tracking uncertainty and a reachable braking stop. The current [two fixed-heading futures](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/+sih/+planner/predictAgentFutures.m:87) cannot provide that certificate. Only probe within a prefix that remains stoppable without another actor yielding. Treat a resulting stall as an explicit state with persistence and a safe escape route; the reported S2/S3 stall still needs its own fix.

**Training and calibration**

| Data | Use and limit |
|---|---|
| [SPT Chennai](https://www.chennaitrafficdata.com/about-our-data) | Its listed fields include metric longitudinal/lateral positions, velocities, accelerations and vehicle class: useful for following, seepage and response distributions. The [paper](https://www.sciencedirect.com/science/article/pii/S0968090X25004358) says it is public, but the site’s [access page](https://www.chennaitrafficdata.com/how-to-access) did not expose a verifiable download in this check: **file access UNVERIFIED**. One arterial segment does not supply all junction modes. |
| [METEOR](https://arxiv.org/abs/2109.07648) | Use tracked image-plane behaviors for recognition and weak class/context pretraining. The repo records absent per-frame metric ego motion and only the **executed**, not alternative, ego action; it cannot identify a causal response-to-probe model or metric safe gaps. [Dataset notes](https://github.com/adityasinghin01-hash/sih26037/blob/main/ml/ReadThis.md:203) |
| [IDD-PeD annotations/code](https://github.com/Ruthvik9/IDD-PeD) | Train crossing intent and image-plane pedestrian motion, including attention, gestures and interaction labels. Those labels do not by themselves identify how the pedestrian would react to a different ego action. |
| [EoT Ahmedabad](https://github.com/NaveenKumar-1311/EoT-EyeonTraffic) and [Indian junction studies](https://www.researchgate.net/profile/Mithun-Mohan-2/publication/350907993_Investigating_the_Influence_of_Conflicting_Flow%27s_Composition_on_Critical_Gap_under_Heterogeneous_Traffic_Conditions/links/61ae043529948f41dbcddfab/Investigating-the-Influence-of-Conflicting-Flows-Composition-on-Critical-Gap-under-Heterogeneous-Traffic-Conditions.pdf) | Seed junction scenes and accepted/rejected gap distributions. EoT lists one unsignalized and two signalized Ahmedabad sites; access to its referenced SkyEye track repository returned 404 here, so usable individual tracks are **UNVERIFIED**. |
| **Randomized interactive simulation** | Generate the missing counterfactual ego actions and actor responses; fit the response model there, then calibrate its *observable* trajectory and mode statistics against Indian recordings. Sim-to-road transfer of its causal response coefficient remains **UNVERIFIED**. |

Test against binary yield/assert, fixed class priors and no-probe ablations. Across the P1 top-25 scenarios, record collision/contact, minimum clearance, successful safe gap use, false commitments, permanent stalls, probability calibration and cycle-time **p95/p99**. Include group/cover merges, lateral cut-ins, occlusion and nonresponse so the learned model cannot win merely by assuming courtesy. These are proposed evaluation requirements, motivated by the [Chennai merge modes](https://www.sciencedirect.com/science/article/abs/pii/S1369847815000224) and the [current fixed-heading model](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/+sih/+planner/predictAgentFutures.m:46).

## 5. Novelty and the 100 ms gate

| Closest prior art | What it already occupies |
|---|---|
| [Sadigh et al., 2018](https://people.eecs.berkeley.edu/~sastry/pubs/Pdfs%20of%202018/SadighPlanning2018.pdf); [Geary et al., 2021](https://arxiv.org/abs/2110.04580) | Online preference inference and purposeful probing, including when probing has decision value. |
| [Kruse et al., 2022](https://arxiv.org/abs/2207.05228); [LeTS-Drive](https://arxiv.org/abs/2101.03834) and its [code](https://github.com/cindycia/lets-drive) | Continuous cooperation belief with online POMDP merging; real-time belief-guided planning in simulated dense, unregulated heterogeneous traffic. |
| [2026 SVO-conditioned MATLAB/Python planner](https://www.mdpi.com/2079-9292/15/9/1914); [Chakravarty et al., 2026](https://arxiv.org/abs/2602.14540); [Mustafa et al., 2026](https://arxiv.org/abs/2608.21400) | SVO inference plus prediction/fallback; multimodal belief plus active probing and risk monitoring; ego-conditioned generative probing. |

**Novelty verdict:** the combined *mechanism* is occupied. I found **no verified publication with the exact combination evaluated on Indian lane-free traffic in a real-time MATLAB/Simulink closed loop**, but absence from this search is not proof of firstness. The defensible contribution is a **measured India-calibrated implementation**, with group/cover/rolling-gap modes, uncertainty-aware safety, and an ablation showing fewer contacts *and* fewer permanent stalls.

The timing gate comes first. Using your **736 ms** measurement and **88%** capsule-list share: capsule work is **647.68 ms** and everything else **88.32 ms**. A 100 ms cycle leaves **11.68 ms** for capsule work *and every new computation*, requiring about a **55.5× reduction in that hotspot alone** if other costs stay fixed. The current checker [constructs a new `dynamicCapsuleList` for each candidate–future call](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/+sih/+planner/checkTrajectorySafety.m:74); adding belief branches directly to that loop worsens it. First use vectorized broad-phase rejection, retain only a small candidate shortlist, then run exact near-term swept-occupancy and stop checks. Measure the whole loop again before claiming 10 Hz. The belief grid may be cheap; **its integration is not yet proven to meet 100 ms**.

**Still UNVERIFIED:** usable SPT download; public code and runtime for several cited recent planners; transferable Indian vehicle-to-pedestrian yielding rates by class; causal response-to-ego parameters from the observational datasets; the new design’s safety coverage and 100 ms runtime; whether the current deployed S3 output obeys its documented `Valid=false` gate.