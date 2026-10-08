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
