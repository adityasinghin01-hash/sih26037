PHASE P13 — FULL SYSTEM DESIGN (SIH26037). Synthesis task.

You are in /Users/aditya/dev/sih2026-hq (read-only). READ these files yourself first, fully:
research/PS-SIH26037-verbatim.md, P0-RULES.md, P1-DIFFICULTY-CATALOGUE.md, P2-AUDIT-OUR-SYSTEM.md,
P3-PLANNER.md, P4-P5-ML-PREDICTION-PERCEPTION.md, P6-P7-P8-SIM-TRAFFIC-SENSORS.md,
P9-P12-CONTROL-DATA-EVAL-COMPUTE.md, P16-INDIAN-TRAFFIC-NUMBERS.md.
The code is at /Users/aditya/dev/sih2026 (branch integration/dense-planner) if you need to check a fact.

GOAL: one architecture for "a system that drives a car by itself on Indian roads" that meets every
PS requirement and goes beyond it. It goes on a 6-slide national idea PPT (slide 3 "Technical approach")
judged in ~2 minutes by experts, then gets built by the Dec 2026 finale by a 2-builder student team.

LOCKED DECISIONS (do not reopen; flag a conflict only if it breaks a PS requirement):
- RoadRunner is OUT (no licence). Do not put it in the design.
- 3D world = CARLA's ready-made town + INDIAN COMPONENTS added (cattle, auto-rickshaws, e-rickshaws,
  tractor-trolleys, overloaded 2W, jaywalkers, hand-signalling pedestrians, potholes, stalls).
- Najibabad Blender city is parked.
- Simulink/MATLAB hosts the running ego stack and test harness (PS toolchain). SUMO (official R2026a
  Simulink block) for dense reactive traffic. drivingScenario fast tier.
- Planner direction = P3 option A: small learned scorer over 8–16 precomputed manoeuvres + independent
  swept-footprint/uncertainty/stop-distance verifier + certified brake fallback + explicit "blocked" state;
  per-actor "response propensity" belief (intent modes incl. group/cover × response coefficient),
  permission to move only from the independent certificate.
- Prediction = top-K metric trajectories/occupied regions conditioned on ego candidate, conformal
  coverage, conservative reachable-set fallback; yield gate stays closed; animals = obstacle + reachable region.
- Perception = camera in the loop first (YOLOX + DeepLab road mask), lidar+radar, trackerGNN; open-vocab
  models only for label mining.
- Control = Stanley+PI baseline vs constrained MPC; 3DOF sweeps, 14DOF for potholes.
- Data engine = simulation shadow mode → mined failures → regression scenarios → frozen holdout.
- Eval = PS metrics with our exact formulas (latency p50/p95/p99 + deadline misses; smoothness jerk +
  curvature; completion), stratified; baselines; 10 Hz gate with stale-plan fallback.
- Indian numbers from P16 parametrise actors; pedestrian yield rate is SWEPT, not assumed.

HONESTY CONSTRAINTS: every planner mechanism alone is prior art (Mosaic, CoPlanner, 2608.21400, Kruse,
LeTS-Drive). Today: S2 collides+stalls, dense S3 stalls, ML dangerous-error 2.089% vs ≤1%, 736 ms/step
vs 100 ms. Never present planned parts as built. Mark every block BUILT / PARTIAL / PLANNED.

DELIVERABLE (markdown, tight, plain words, no padding):
1. ONE ASCII diagram of the whole system: sim world → sensors → perception → tracking → prediction →
   belief → planner (proposer + verifier + fallback) → control → vehicle, plus the safety monitor,
   the data-engine loop and the evaluation harness. Show rates (Hz) where decided. Fits one slide.
2. Table, one row per layer: job in one line | inputs → outputs | method | MATLAB/other tool |
   Indian-specific part | P1 difficulties it covers (IDs) | status BUILT/PARTIAL/PLANNED.
3. Safety architecture: what may veto what; what happens on stale/late/missing data.
4. Simulation architecture: which tool runs what, how they connect (CARLA↔MATLAB route, SUMO block),
   what runs on Mac vs Windows lab PC vs DGX A100 (no RT cores; lab PC GPU 8 GB).
5. The 5 PS scenarios + the 10 families (F1–F10) mapped onto this system.
6. "Beyond the PS": each item one line, with its honest novelty status (prior art / India-specific /
   measured contribution).
7. Top 5 technical risks of this design with the mitigation.
8. A 5-bullet plain-language version for the slide.
Label FACT vs JUDGMENT where it matters. Cite file paths or URLs for facts.
