P6-P8 accepted (verified: SUMO Client block R2026a, Instant NuRec input/scope, student-form unavailable).
NEXT: PHASES P9 (CONTROL + VEHICLE DYNAMICS), P10 (DATA ENGINE / LEARNING LOOP), P11 (EVALUATION, METRICS,
BENCHMARKS, SAFETY CASE), P12 (REAL-TIME + COMPUTE + DEPLOYMENT). My raw notes (verify/extend/attack):
# P9–P12 — Claude's raw findings

## Safety standards a real system is judged against (P11)
- **ISO 26262**: functional safety (malfunctions).
- **ISO 21448 SOTIF**: insufficiencies of the intended function, i.e. unknown hazardous scenarios.
- **ISO 34502:2022**: a scenario-based safety evaluation framework (scenario generation →
  evaluation). https://www.iso.org/standard/78951.html
- **ISO 34503:2023**: the ODD taxonomy (from P1).
- **UL 4600**: an overarching safety case. It prescribes no specific technology and no pass/fail
  threshold, only the topics the argument must cover.
- Common integration: 26262 for faults · 21448 for insufficiencies · 34502 for scenario evaluation
  · UL 4600 for the safety case.
  (ScienceDirect S259019822500510X; prostep fact sheet.)
- **For us:** structuring the evaluation around ISO 34502 + ISO 34503, with a UL 4600-style safety
  case, is a real industry-grade move beyond the PS. Just use the vocabulary honestly, and **never
  claim "compliance"**.

## Data engine (P10)
- **Tesla shadow mode:**
  - FSD runs silently while a human drives and compares its decision with the human's.
  - Triggers fire on disagreements and anomalies (detection flicker, tunnel lighting, cut-in /
    cut-out mismatches).
  - Matched samples are retrieved from the fleet, auto-labelled, and used to retrain.
  (Secondary sources; notateslaapp; arXiv 2401.12888 survey.)
- **Open equivalents:**
  - AIDE (automatic data engine, LLM auto-labelling)
  - OpenAnnotate3D (open-vocabulary 2D/3D auto-labels)
  - AV2 2026 Scenario Mining Challenge (AutoMine, 2606.11874)
  - DeepScenario (30K executable scenarios)
- **For us:** a "simulation shadow mode". Run the learned model in shadow beside the
  rule/validator in every sim run, log disagreements, mine them into new scenarios and training
  data. A cheap, real flywheel; no fleet needed.

## Real-time and compute (P12)
- **MATLAB → NVIDIA:**
  - GPU Coder + the "MATLAB Coder Support Package for NVIDIA Jetson and NVIDIA DRIVE" generate
    CUDA from MATLAB/Simulink and deploy to **Jetson AGX Thor, AGX Orin, Orin Nano, and DRIVE**.
    https://www.mathworks.com/help/coder/nvidia.html
  - A July 2026 MathWorks blog shows PyTorch → Simulink → Jetson code generation (YOLO26
    segmentation).
  - **Licence:** GPU Coder is on KIET licence 41087767 (per the licence memory) but **not
    installed**.
- **Indian-market chips:**
  - Qualcomm Snapdragon Ride Flex is pitched at cost-sensitive Indian L2 (autocarpro).
  - Mobileye EyeQ6 is 34 TOPS; the NXP+EyeQ6 Lite reference design has a BOM **< $95** for
    emerging-market L2+.
  - NVIDIA Orin is 254 TOPS; Thor is 2,000 TOPS.
  - **So an Indian ADAS target realistically = a ~30–250 TOPS budget, not a robotaxi GPU.**
- **Our planner** runs at 736 ms/step on a Mac M1 in interpreted MATLAB. Codegen to C/CUDA plus a
  smaller candidate grid is the realistic route to 10 Hz. **UNVERIFIED until measured.**

P9: controllers used by leaders/open stacks (MPC, pure pursuit, Stanley, LQR; Apollo/Autoware/openpilot);
    vehicle models (kinematic vs dynamic bicycle, MATLAB Vehicle Dynamics Blockset 3DOF/14DOF, tyre models,
    actuator delay); low-speed manoeuvres (3-point turn, reverse in galli, creeping at 1-2 km/h); pothole/
    speed-breaker ride and control; what MATLAB offers (MPC Toolbox, Lateral/Longitudinal controller blocks).
P10: data engine design for a student team without a fleet: simulation shadow mode, disagreement mining,
    scenario mining from dashcam video (Scenario Builder support package; AV2 scenario-mining challenge),
    auto-labelling (open-vocab + tracking), active learning; how Waymo/Tesla/Wayve close the loop; what can be
    shown in a demo.
P11: what "passing" means: CARLA leaderboard driving score, nuPlan CLS, NAVSIM PDMS/EPDMS, WOSAC, interPlan;
    safety metrics (TTC, PET, post-encroachment, RSS violations, minimum clearance with uncertainty, collision
    severity), progress/deadlock metrics, comfort (jerk); statistical validity (how many runs; rare-event
    estimation, importance sampling); ISO 34502 / 34503 / 21448 / UL 4600 / IEEE 2846 - what a student project
    can honestly adopt; the PS's 3 metrics (replanning latency, path smoothness, completion rate) exact
    definitions to use; baselines to compare (MathWorks example, PDM-Closed-like rule baseline, always-yield,
    ORCA).
P12: real-time: profiling/optimising MATLAB (codegen MEX, GPU Coder, parfor), reaching 10 Hz; deployment
    targets (Jetson Orin/Thor via MATLAB Coder support package), Indian ADAS compute budgets (Qualcomm
    Snapdragon Ride Flex, Mobileye EyeQ6 L, NXP+EyeQ6L <$95 BOM claim - verify), latency budgets per layer
    used in industry; functional-safety split (safety controller on separate ECU).
Each: leaders' practice (sourced), options good/better/best, effort, risk. Tables.
