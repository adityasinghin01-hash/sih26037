# PHASE 1 RESULT — Claude's own sweep
**Run 30 Aug 2026. Web search, verified links. Cross-check against agent results before use.**

## HEADLINE: the dossier's central novelty claim is FALSE

DOSSIER-26037 §7 says: *"A targeted search for Indian-specific heterogeneous,
non-lane-based behaviour planners returned no India-focused planning research."*

**That is wrong.** There is an entire research line — a PhD thesis, a dataset, and
multiple planners — aimed at exactly this problem. It was missed because the earlier
search used our words ("Indian planner") instead of the field's words
("dense, heterogeneous, unstructured traffic").

---

## THE TOP 5 CLOSEST WORKS

### 1. Rohan Chandra, PhD thesis (Univ. of Maryland, 2022)
**"Towards Autonomous Driving in Dense, Heterogeneous, and Unstructured Traffic"**
https://drum.lib.umd.edu/items/f0148588-8046-451e-a196-23f51c770169
Advisor: Dinesh Manocha (GAMMA lab). Chandra is now Assistant Professor at UVA.
*This is our problem statement as a doctoral thesis title.*

### 2. B-GAP — behaviour-aware ego navigation (RA-L / IROS 2022)
https://arxiv.org/abs/2011.03748 · code: https://github.com/angmavrogiannis/B-GAP-Behavior-Guided-Action-Prediction-and-Navigation-for-Autonomous-Driving
Classifies surrounding drivers as **aggressive or conservative** (CMetric), then uses
that classification for ego decision-making in dense traffic via a deep RL policy.
**This is our build change #2 (per-agent negotiability), already built and published.**

### 3. METEOR — Indian unstructured traffic dataset (ICRA 2023)
https://gamma.umd.edu/researchdirections/autonomousdriving/meteor/
1,000+ one-minute clips, **2M+ annotated frames, 13M+ bounding boxes**, ego trajectories.
Annotated behaviours include: **yielding, cut-ins, overtaking, overspeeding, zigzagging,
wrong-lane driving, running signals, and explicitly "lack of right-of-way rules at
intersections."** Covers rain, night, and rural unmarked roads.
**This is a better source for "negotiability" than IDD-X — it annotates yielding directly.**

### 4. GameOpt / GamePlan — unsignalised intersection negotiation (2022)
https://arxiv.org/abs/2202.11572
Auction mechanism assigns a priority entry sequence, then an optimisation-based planner
computes velocities. Runs in **<10 ms at >10,000 vehicles/hr**, and GamePlan
**proves it prevents deadlocks**.
**This is our "negotiate the unsignalled intersection" idea, already built, with proofs.**

### 5. TraPHic — trajectory prediction in dense heterogeneous traffic (CVPR 2019)
https://arxiv.org/abs/1812.04767 · code: https://github.com/rohanchandra30/TrackNPred
LSTM-CNN hybrid, models heterogeneous interactions between buses/cars/scooters/
pedestrians. Introduced the TRAF dataset from urban Asian video. Beat prior methods
by 30% on dense traffic.

## ALSO FOUND — directly on our framing

- **"Unfreezing autonomous vehicles with game theory, proxemics, and trust"**
  Camara & Fox, Frontiers in Computer Science, Oct 2022.
  https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2022.969194/full
  *Our exact pitch framing, already published as a review.* States the problem we state:
  AVs treat pedestrians as obstacles, always yield, and get taken advantage of until they halt.

- **"Deep reinforcement learning for autonomous driving in uncontrolled intersections
  of Indian roads"** — Multimedia Tools and Applications, Aug 2024.
  https://link.springer.com/article/10.1007/s11042-024-19812-6
  DDPG actor-critic, uncontrolled Indian intersection with bidirectional traffic.
  **India + intersection + planner, published, two years old.**

- **Frozone: Freezing-Free, Pedestrian-Friendly Navigation in Human Crowds**
  https://arxiv.org/pdf/2003.05395

- **Human-like Decision-making at Unsignalized Intersection using Social Value Orientation**
  https://arxiv.org/pdf/2306.17456 — confirms SVO is occupied territory.

---

## OUR OWN CLAIMS, CORRECTED

| Claim we were going to make | Verdict |
|---|---|
| "No India-focused planning research exists" | **FALSE.** A thesis, a dataset, and several planners exist. |
| "Per-agent negotiability is novel" | **OCCUPIED.** B-GAP does aggressive/conservative classification for ego navigation. |
| "Negotiating an unsignalled intersection is novel" | **OCCUPIED.** GameOpt/GamePlan, with deadlock proofs. |
| "The frozen-robot framing is our angle" | **OCCUPIED.** Camara & Fox 2022 is literally titled "Unfreezing autonomous vehicles." |
| "Standard metrics reward a car that never moves" | **PARTLY FALSE — important.** CARLA's Driving Score = route completion x infraction penalty, and "agent blocked" (no action for 180 s) is already a tracked infraction. Freezing IS penalised. Our Novelty 2 must be re-scoped: the gap is that 180 s is meaningless for an Indian junction and nothing measures *degree* of hesitation — not that no metric exists. |
| "ASSERT / horn is a new action" | **PATENTS EXIST.** US 9919560 "Adaptive horn honking which can learn the effectiveness of a honking action"; US 10373499 "Cognitively filtered and recipient-actualized vehicle horn activation"; US 11958505 / 12280803 on locating horn honks. Name these on our own slide. |

---

## WHAT IS STILL OPEN — candidate floors

**1. None of it is in MATLAB/Simulink.** Every work above is Python — CARLA, SUMO, custom
simulators. MathWorks' own shipped examples are highway and lane-based
(`Highway Lane Following`, `Highway Lane Change`, `Lane-Level Path Planning`).
Our PS *requires* MATLAB/Simulink + RoadRunner. So: **the first open, reproducible
MATLAB/Simulink implementation of unstructured-traffic negotiation** is a real,
checkable, honest contribution — and it is exactly what MathWorks asked for.

**2. Animals.** A targeted search for cattle/livestock behaviour models in AV planning
returned essentially nothing — only generic obstacle avoidance. The PS *explicitly
requires* a cattle-crossing scenario. This looks genuinely open, and it is uniquely Indian.
NEEDS ONE MORE VERIFICATION PASS.

**3. The horn as a costed, context-dependent negotiation action.** Patents cover adaptive
honking. Academic eHMI work covers light-strips and displays aimed at *pedestrians*, in the
West. What was NOT found: the horn modelled inside a planner's action space in dense
unstructured traffic, with the signal-inflation property (honking constantly makes honking
stop working). NEEDS MORE CHECKING — do not claim yet.
  Supporting find: **"Honkable Gestalts: Why Autonomous Vehicles Get Honked At"**
  (ACM, https://dl.acm.org/doi/fullHtml/10.1145/3640792.3675732) — reports that the #1
  reason people honk at real AVs is **"waiting too long before going."** Excellent citation
  for our problem framing: even in San Francisco the frozen AV is the top complaint.

**4. Closed loop with real perception.** Most of the works above assume ground-truth agent
states from a dataset or simulator. The PS demands camera/LiDAR/radar -> detection ->
prediction -> planning -> control, closed. NEEDS VERIFICATION per paper.

---

## THE ANSWER TO "WHAT DO WE BUILD ON"

**The apartment: the Chandra / Manocha stack.** B-GAP for per-agent behaviour, GameOpt for
intersection negotiation, METEOR for real Indian behaviour data, TraPHic for dense-traffic
prediction. All published, most with public code. We cite it, we build on it, we say so.

**Our floors, in order of how defensible they currently look:**
1. It runs in MATLAB/Simulink with RoadRunner Indian scenes — nobody has this, and it is the deliverable MathWorks asked for
2. Animals as negotiating agents, not obstacles
3. The horn / explicit signalling layer with signal inflation
4. Closed loop from real trained perception, not ground truth

## OPEN QUESTIONS FOR THE NEXT PASS
- Does B-GAP handle animals or non-vehicle agents? (probably not — verify)
- Is METEOR downloadable, and what licence?
- Does GameOpt require vehicle-to-vehicle communication? (an auction implies it — if so,
  it does NOT work with human drivers who cannot bid, and that is a real gap for us)
- Has anyone published unstructured-traffic planning in MATLAB/Simulink at all?
