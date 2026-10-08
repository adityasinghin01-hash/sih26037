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

## Safety layer and freezing (Claude, 26 Sep)
- **RSS (Mobileye):** a formal safe-distance model (longitudinal, lateral, intersection priority,
  and a "proper response" given as acceleration limits). It is being standardised as **IEEE P2846**.
  An **open-source C++ implementation exists: Intel ad-rss-lib** (https://github.com/intel/ad-rss-lib).
  - **Patents:** Mobileye "Navigation with a safe lateral distance" (US 11,897,508) and "…safe
    longitudinal distance" (US 12,037,019); also "VRU safety technologies based on RSS"
    (US 12,509,071). **Using RSS in a commercial product needs a licence check.** Research or
    hackathon use of the open library is fine; cite it.
- **Frozen robot, published fixes:**
  - Trautman & Krause 2010: even perfect individual prediction cannot fix freezing without a
    model of joint cooperation.
  - HiCrowd (arXiv 2602.05608, 2026): align with the crowd's flow; deployed at a museum and at
    Expo 2025 Osaka.
  - Frozone (arXiv 2003.05395).
  - A-DRIVE: deadlock detection and recovery, but it assumes V2V.
  - **Our S2/S3 stall is exactly this class of failure.** The fix direction is to treat other
    agents as cooperative, react to the flow, and have deadlock detection that escalates. Not
    more waiting.

## UPGRADE THE YIELD/ASSERT IDEA (asked by Aditya, 26 Sep): candidate replacements found
1. **Continuous cooperativeness instead of binary yield/assert:** Social Value Orientation (SVO).
   - Schwarting, Pierson, Alonso-Mora, Karaman, Rus. "Social behavior for autonomous vehicles",
     PNAS 116(50), 2019.
   - Each driver has an SVO angle (selfish ↔ altruistic), **estimated online** from behaviour.
   - Interactions are a best-response game (Nash equilibrium).
   - Trajectory prediction improved **18% with static SVO and 25% with estimated dynamic SVO**.
   - https://www.pnas.org/doi/abs/10.1073/pnas.1820676116
2. **Belief-space planning (POMDP):** keep a probability belief over each agent's hidden intent and
   cooperativeness, and update it every step with a particle filter.
   - Bouton, Cosgun, Kochenderfer (NOT Hubmann — corrected), "Belief State Planning for Autonomously Navigating Urban Intersections"
     (1704.04322).
   - POMDP unsignalised-intersection parameter study (2412.06405).
   - MOMDP vehicle–pedestrian work, **tested on real vehicles**.
3. **Ego-conditioned multi-future prediction:** "what will they do IF we take path A"
   (Waymo conditional behaviour prediction; MotionLM). This is already in P4.
4. **Probing to reduce uncertainty (active information gathering):** arXiv 2608.21400 (MPPI +
   ego-conditioned generative prediction). This is our probe, but done properly: choose the action
   that most reduces the belief uncertainty.
5. **Indian traffic-engineering grounding:** class-specific critical-gap / gap-acceptance models at
   uncontrolled Indian junctions. **TODO: source these.**

**Combined idea (candidate):** per-agent **belief over a continuous cooperativeness (SVO-like)
parameter, with a class-specific prior** (bus/truck selfish; pedestrian/two-wheeler varied; cow =
non-reactive).
- The belief is updated online from how the agent reacts to our probe.
- It conditions a multi-future trajectory predictor.
- The planner does contingency / belief-space planning with an **active-probing** term.
- An RSS/barrier validator sits underneath.
**This replaces binary yield/assert with something published, real-vehicle-tested, and
India-calibratable.**

## CORRECTIONS (26 Sep, after verification)
- The Alpamayo licence is permissive (OpenMDW-1.1), not non-commercial.
- The animal patents are IBM's (expired), not Google's.
- Minus Zero drove on Bengaluru public roads in May 2025; "campus only" was wrong.
- Swaayatt claims **sparse** maps, not map-free.
- "Everyone converges on proposer + validator" is **too strong**. Waymo and Mobileye disclose
  layering; Tesla and Wayve don't publish their runtime validators.

## Indian gap-acceptance priors (Claude search, 26 Sep; secondary snippets, VERIFY the exact papers)
- Critical gap at uncontrolled Indian T-junctions ≈ **2.5 s for two-wheelers vs 3.0 s for cars**,
  lower than in developed countries. (ResearchGate 320297740, "Gap Acceptance Behaviour of Drivers
  at Uncontrolled T-Intersections under Mixed Traffic Conditions".)
- Ranges: 2.378–3.06 s on the major road, 2.77–3.71 s on the minor road
  (Springer 978-981-32-9042-6_43).
- Review: "Assessment of critical gap at uncontrolled intersections under mixed traffic" (Springer
  s41062-022-00933-6). Most standard methods fail in mixed traffic; the "clearing behaviour"
  approach works.
- Two-wheelers at limited-priority T-intersections: ScienceDirect S0386111215000291.
- **Use:** class-specific priors for the cooperativeness belief (two-wheelers accept tighter gaps,
  i.e. more assertive).
