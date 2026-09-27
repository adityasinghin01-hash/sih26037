PHASE P3 - THE PLANNER (the brain). Deep research. Read my notes and audit first (below), then research.
Goal: know exactly how the best in the world build the decision/planning brain, and what options we
have for a planner that handles the P1 top-25 on Indian roads, buildable by a student team in MATLAB/Simulink
(Python allowed for training; the PS toolchain must host the running system).

=== MY RAW NOTES ===
# P3 planner — Claude's raw findings (to be merged into P3 doc)

## How the leaders build the brain (sources opened)
- **Waymo (Dec 2025 blog, primary):** ONE foundation model powering three things: the **Driver**, the
  **Simulator** and the **Critic**.
  - "Think fast" part: a sensor-fusion encoder (camera + lidar + radar → objects and embeddings).
  - "Think slow" part: a Driving VLM (Gemini) for rare semantic cases.
  - Both feed a **World Decoder**, which predicts behaviour, the map and trajectories.
  - **The generative planner's trajectories are checked by "a separate and rigorous onboard
    validation layer"**, learned plus rule-based.
  - An outer loop flags bad behaviour → improves it → tests in the sim with the Critic → deploys.
  https://waymo.com/blog/2025/12/demonstrably-safe-ai-for-autonomous-driving/
- **Tesla FSD v12→v14:** one end-to-end network from camera pixels to control; an RL stage in
  training; a video world model generates futures. (Secondary sources only: thinkautonomous,
  eeworld. Tesla publishes no architecture papers.)
- **NVIDIA Alpamayo (CES, Jan 2026, primary):**
  - Alpamayo 1: a 10B-parameter VLA with **open weights on Hugging Face**, chain-of-thought
    reasoning plus trajectories; meant as a **teacher to fine-tune and distil**, not to deploy.
  - **AlpaSim:** an open-source closed-loop sim on GitHub.
  - **Physical AI open dataset:** 1,700+ hours.
  - The licence is non-commercial for now ("options for commercial usage" in future models).
  https://nvidianews.nvidia.com/news/alpamayo-autonomous-vehicle-development
- **Swaayatt Robots (Bhopal, 2015):** deep-RL-based motion planning and decision-making for
  unstructured traffic, map-free, bidirectional negotiation; says 70% of its R&D goes to
  decision-making and planning. No public papers found. (inc42, autofutures)
- **Minus Zero (Bengaluru):** camera-only "Nature-Inspired AI" end-to-end, no HD maps; zPod
  concept limited to campuses. (autocarindia, businesstoday)
- Others: **Ati Motors** (autonomous cargo in factories), **Flux Auto** (truck retrofit ADAS),
  **RoshAI** (Kochi; industrial autonomous vehicles and truck retrofits), **TiHAN IIT Hyderabad**
  (₹130 cr national autonomous-navigation testbed; DriveIndia dataset).

## Academic state of the art
- NAVSIM leaderboard (2026): diffusion / flow-based planners on top (DRIFT 89.6 PDMS; FlowDrive
  86.3 EPDMS). PDM-Closed is the rule-based hybrid baseline.
- **NOVELTY HIT 1:** "Active Interaction-Aware MPPI via Ego-Conditioned Generative Predictions"
  (Mustafa, …, Alonso-Mora), arXiv 2608.21400, 6 Aug 2026. The car **actively probes** to reduce
  ambiguity about whether others will cooperate, in unprotected turns. **This is our
  probe-and-commit idea, already published.**
- **NOVELTY HIT 2:** "CoPlanner" (Zhong et al.), arXiv 2509.17080, Sep 2025. Diffusion planner with
  a **validated shared short-term segment plus contingency branches**. **This is our "trunk",
  published, on nuPlan.**
- Also: MARC (risk-aware contingency, 2308.12021), Contingency Games (2304.05483), GameOpt+
  (heterogeneous intersections, V2I assumption).
- **So novelty cannot rest on the planner mechanism.** It has to come from: India-specific
  behaviour models (mass-priority, per-agent negotiability, animals), the Indian scenario and
  evaluation suite, integrating everything in the PS toolchain (MATLAB), and the safety-validated
  learned + rule hybrid tested on Indian data.

## Architectural pattern everyone converges on
**learned proposer (generative / end-to-end) + independent safety validator (rule and physics)
+ simulator + critic + data flywheel.** Our current system is the validator-heavy half; it is
missing the learned proposer and the flywheel.

## NOVELTY HIT 3 (found in P1): the "Indian test suite" angle is occupied
- WMG (University of Warwick) **Safety Pool Studio**: crowdsourced **Indian** traffic scenarios for ADAS
  testing (SAE paper 2026-26-0046). They feed the Safety Pool Scenario Database, which has **250,000+
  scenarios and 500+ member organisations**.
  https://saemobilus.sae.org/papers/crowdsourcing-indian-traffic-scenarios-adas-development-testing-2026-26-0046
  https://www.safetypool.ai/
- ARAI already sells India-specific data digitisation plus scenario creation plus SIL/MIL/HIL V&V.
- **So "the first Indian ADAS test suite" is NOT a safe claim.** A narrower angle is still possible:
  a closed-loop **planner** benchmark for unstructured traffic, in the PS toolchain, with reactive
  Indian agents. This must be re-checked against Safety Pool's own libraries.

=== OUR CURRENT PLANNER (audit row) ===
| 1 | **Planner — the brain** | `+sih/+planner` (18 functions): velocity-obstacle barrier `h=λ−β`; COLREGs-style roles adapted to Indian law (keep left, RRR 1989 reg.2/9); **contingency planner**: a fan of 35 paths × 2 futures per agent (yield/assert), commit only the trunk that is safe under both, plus a brake-to-stop terminal check (trunk mode B); pure-pursuit follower; turn classification; escape memory; point of no return. Plus the `+sc/planSeat` layer: D9 ladder (creep → WAIT → go-around), track hysteresis, sanity reject | S1 completes 610 m, 0 plan failures, min clearance **0.618 m** sparse / **0.135 m** dense; 8 randomised runs: mean 0.143, 95% CI [0.093, 0.193], **worst −0.001 m (contact)**. S3 sparse completes, 0.293 m | **Partial** | **Permanent stall** in circulating/dense traffic (S2 at s≈116–121 m, dense S3 at 81.4 m). Root cause found by Codex (the clearance gate drops the longitudinal station; WAIT commits on one frame; the timeout re-arms). Not fixed. Tie-break prefers standing still or small offsets. Hand-tuned, not learned |

=== TASKS ===
1. For EACH of: Tesla, Waymo, Mobileye (RSS + its planning stack), Wayve, NVIDIA (Alpamayo + Hydra/DRIVE
   planner), Baidu Apollo (open source), Autoware (open source), comma.ai openpilot, Swaayatt, Minus Zero:
   how is the planner built (end-to-end vs modular vs hybrid), what the planner outputs, how safety is
   enforced on top of it, how it handles interaction/negotiation, and what is public (papers/code/patents).
   One compact table + key sources. Mark marketing claims vs technical evidence.
2. Academic state of the art for INTERACTIVE planning in dense, heterogeneous traffic (2023-2026):
   contingency/branch MPC, game-theoretic (incl. GameOpt+, B-GAP, Chandra's work), MPPI with generative
   prediction (2608.21400), diffusion/flow planners (CoPlanner, DiffusionDrive, DRIFT), RL planners,
   hybrid learned-proposer + rule-validator (PDM-Hybrid, Hydra-MDP, Waymo's validation layer).
   For each: core idea, handles non-lane traffic? , compute cost, code available?, benchmark numbers.
3. Deadlock/"frozen robot" in dense crowds specifically (our known failure): best published fixes.
4. Patents: key planning/safety patents (Mobileye RSS, Waymo/Tesla planning, animal avoidance
   US9481367B1/US9481366B1) - what each claims in plain words and how to design around.
5. RECOMMENDATION: 2-3 candidate planner architectures for us (with the learned part + safety validator +
   fallback), each rated on: handles top-25, real-time feasibility (our step now 736 ms vs 100 ms budget;
   88% spent in MathWorks dynamicCapsuleList), MATLAB/Simulink deployability, data needs, novelty on top
   of the 3 NOVELTY HITS in my notes. Be honest; attack my notes where wrong.
Tables, concise, every fact sourced, UNVERIFIED where needed.
