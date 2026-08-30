# DOSSIER 1 — SIH26037
## Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles on Unstructured Indian Roads
**MathWorks · Software · Theme: Smart Vehicles · Deadline 20 Sept 2026**

Research date 27 Aug 2026. Written for the KIET team of 6.
Companion: `DOSSIER-26047.md`. Official PS text: `SIH26037-official-text.md`.

---

# 1. THE PS, DECODED

**What the title hides:** this is not a "build a self-driving car" problem. It is a
**simulation engineering** problem, and MathWorks — who wrote it and will judge it — says so
explicitly. Read the Expected Solution literally:

> "teams should build a working simulation pipeline that integrates perception, prediction, path
> planning, decision logic, and vehicle motion **in MATLAB and Simulink**... including at least two
> detailed **RoadRunner scenes**... The final submission should include the simulation model, the
> designed scenarios, performance results with metrics such as **replanning latency, path
> smoothness, and scenario completion rate**, a short technical report, and a **demonstration video**."

**No vehicle is required. No road test is required.** That single fact is why this PS was wrongly
killed in our first sweep, and it is also this PS's biggest structural advantage — see §8.

### The five scenarios you must demonstrate (non-negotiable, named in the PS)
1. Unmarked village road
2. Busy urban intersection **without signals**
3. Highway merge involving slow-moving vehicles
4. Dense market area with mixed traffic
5. **Sudden cattle-crossing event**

### The two RoadRunner scenes you must author (minimum)
A village road, and an urban intersection.

### Tools MathWorks "encourages" (read: expects)
| Tool | Used for |
|---|---|
| RoadRunner | 3D scenario/scene design |
| Automated Driving Toolbox | sensor modelling and fusion |
| Navigation Toolbox | path planning (`trajectoryOptimalFrenet`) |
| Stateflow | decision logic / behaviour state machine |
| Vehicle Dynamics Blockset *or* a Simulink bicycle model | vehicle motion |
| Deep Learning Toolbox | detection and trajectory prediction |

### Datasets the PS itself points you to
- **Indian Driving Dataset (IDD)** — https://idd.insaan.iiit.ac.in/
- A Mendeley traffic dataset (URL truncated on the SIH page)
- MathWorks' own built-in sensor/scenario datasets and RoadRunner sample scenes

### How this gets judged — and it is different from a normal SIH PS
MathWorks is a **corporate sponsor**, not a ministry. There is no policy angle, no beneficiary
story, no government stakeholder to please. You are being marked on **engineering quality**:
does the closed loop actually close, are the metrics real, is the scenario fidelity honest.
Pitch-craft matters far less here than it does on a ministry PS. That cuts both ways — it rewards
depth, and it removes the "social impact" cushion that a weaker build can hide behind.

---

# 2. PAST SIH PS IN THIS SPACE, AND WHO WON THEM

## Team TwinX — SIH 2025 winner, MathWorks PS (the closest possible precedent)
**K.K. Wagh Institute of Engineering Education and Research, Nashik.**
Members: Aakanksha Sutrave, Anurag Mohod, Abhishek Ahirrao, Vaishnavi Pawar, Sagar Sahu,
Chanchal Mahalpure. Mentor: Prof. Dr. Vilas Patil.

**Their PS:** accelerating road-network modelling for Indian traffic simulations — the gap between
real Indian roads (potholes, barricades, roadside parking) and simulation tools built for orderly
lanes. **Nearly the same territory as ours, one year earlier.**

**What they actually built:** a pipeline converting real-world road data into simulation-ready
scenarios —
- imports **OpenStreetMap** data
- auto-places vehicles with **Indian-specific driving behaviours**
- integrates **Indian road assets** (potholes, barricades, construction elements)
- adds weather by geographic location
- exports directly to **Driving Scenario Designer, RoadRunner, and Simulink**

**Tools:** MATLAB (map processing + scenario generation), Driving Scenario Designer, RoadRunner
(3D visualisation), Simulink (high-fidelity simulation).

**Their own stated reason it worked:**
> "MATLAB was the backbone because it allowed us to build an **end-to-end workflow on a single
> platform**."

**Their judging tactic, quoted:**
> "get feedback from judges in the mentoring round and modify the solution till upcoming
> evaluation round" — over 36 hours, through exhaustion.

## Team Solar Masters — SIH 2024 winner, MathWorks PS
**Sir Padampat Singhania University, Udaipur.** PS: single-axis solar tracking in MATLAB/Simulink/
Simscape. In the 36-hour finale they presented **software simulation results + a working hardware
prototype doing real-time sun tracking + MATLAB and Android monitoring apps**.

## The pattern across both MathWorks winners
1. **One platform, end to end.** Both winners emphasised a single integrated MATLAB workflow rather
   than a patchwork of tools. This is what MathWorks rewards.
2. **Simulation plus something you can point at.** Solar Masters had hardware; TwinX had real OSM
   data flowing in. Pure simulation with nothing grounding it is the weaker submission.
3. **Iterate against the mentoring rounds.** Both describe modifying between evaluation rounds
   rather than defending a fixed design.

**What this means for us:** TwinX built the *scenario generator*. Our PS asks for the *planner that
drives inside the scenario*. Adjacent, not identical — and the precedent proves a MathWorks
Indian-roads PS is winnable by a team like ours. It also means judges have seen the
"Indian scenarios in RoadRunner" move already, so scenario-building alone will not win it twice.

---

# 3. THE SAME PROBLEM AT OTHER HACKATHONS

## IIT Madras CoERS Road Safety Hackathon (2023) — the most relevant non-SIH precedent
National-level, **47 teams**, backed by **MoRTH** and HL Mando Anand India Ltd. Brief: build
**India-specific ADAS**. Framing number used: **4,12,432 crashes and 1,53,972 fatalities in 2021,
with driver error responsible for ~84%.**

| Place | Team | What they built |
|---|---|---|
| 1st | Safety Guardians (Chalapathi Institute + IIIT Nuzvid + IIT Bombay) | Bike safety system — IMU sensors detect rash riding and falls, trigger phone alerts |
| 2nd | Safety Sentinels (IIT Roorkee) | Real-time lane departure warning using **LiDAR**, works with **faded or absent lane markings** |
| 3rd | Tons of Tech (Prince Shri Venkateshwara Engg.) | Connected radio for traffic-signal coordination for emergency vehicles |

**The single most useful finding in this whole dossier:**
**Every winner built a DETECTION or WARNING system. Not one built a planner.**
Indian road-safety hackathons are saturated with "detect the hazard and alert the human."
**The vehicle that decides and acts is an empty lane.**

IIT Madras is running an **AI Road Safety Hackathon 2026** now — worth watching for overlap.

## International student AV competitions (context for what "good" looks like)
- **CARLA Autonomous Driving Challenge / Leaderboard 2.0** — the global benchmark for urban driving
  agents in simulation. The top Leaderboard 2.0 submission used a **modular architecture**
  (arXiv 2405.01394), not end-to-end learning. Relevant: our PS also wants a modular pipeline.
- **Bosch Future Mobility Challenge** — international student competition, 1:10 scale autonomous
  cars on a physical track.

---

# 4 & 5. EXISTING SOLUTIONS AND COMPETITOR CHECK

## Indian companies doing this for real
| Who | What | Status |
|---|---|---|
| **Swaayatt Robots** (Bhopal) | L5 autonomy for **adversarial, unstructured** traffic. From IIT Roorkee research 2009; road-testing in MP since 2015. 2024 video: vehicle handling pedestrians, dogs, cows, tractors, wrong-way scooters on narrow unmarked streets. | **$4M raised 2024 at $151M valuation** |
| **Minus Zero** (Bengaluru) | Camera-first autopilot on foundation models trained on large unstructured datasets; **no HD maps, no human-labelled data** | Funded, unveiled AI autopilot for Indian roads |
| **Hi-Tech Robotic Systemz** | Indian ADAS/autonomous systems | Established |

**Read this correctly.** These are *product* companies solving it on real vehicles. Our PS asks for
a *simulation study*. They are not our competitors in the hackathon — but a judge who knows the
space will ask "how is this different from Swaayatt?" and the answer must be ready: *we are not
building a vehicle, we are building the reproducible test-and-planning framework that anyone
validating an Indian AV needs, and Swaayatt's stack is proprietary and unpublished.*

## The competitor that actually threatens us: MathWorks' own examples
Automated Driving Toolbox **ships** most of the requested pipeline as reference examples:
- `Highway Lane Following` (Unreal-based, monocular perception + controller)
- `Highway Lane Change`
- `trajectoryOptimalFrenet` (Navigation Toolbox) — Frenet-frame trajectory generation
- an urban dynamic-replanning example using a grid-based tracker
- reference test benches for AEB, ACC, lane keep assist, traffic light negotiation, intersection
  movement assist

**Every serious team will assemble this same stack.** If our submission is "MathWorks examples
plus our scenes," we are indistinguishable. **Differentiation must come from the planner and the
data, not the pipeline.** That is what §7 is for.

---

# 6. THE DATA — and this is where we have a real edge

The **IDD family from IIIT Hyderabad** is the largest unstructured-road dataset collection in the
world, and it is free behind a registration login at `idd.insaan.iiit.ac.in`.

| Dataset | Size | Contents | Enables |
|---|---|---|---|
| **IDD-3D** | 236 GiB | **15.5k annotated frames**, 93k images, **6 cameras + LiDAR**, 10 primary + 7 extra classes, **223k 3D boxes** with 9DoF + instance IDs | 3D detection **and tracking** — the exact perception layer our PS needs |
| **IDD-X** | 160 GB | **3,634 driving scenarios** in 1,140 dual-view videos, **697K object boxes / 9K tracks**, 10 object categories, **19 explanation categories** | **Why the ego vehicle acted** — see §7 |
| IDD-117K / IDD-Detection | 72 GB / 22.8 GB | 31,569 train + 10,225 val + 4,794 test; 40,000 images w/ boxes | 2D detection |
| IDD Segmentation | 24 GB | 20,000 images, fine semantic annotation | drivable-area / road-edge extraction where markings are absent |
| IDD Multimodal | 16.1 GB | stereo + **GPS at 15 Hz** + 16-channel LiDAR + **OBD data** | ego-motion and real trajectory ground truth |
| IDD-AW | 19 GB | rain, fog, lowlight, snow + near-infrared | robustness story |
| IDD Temporal | 99.3 GB | consecutive frames | motion/tracking |
| I2WDD / FGVD / MTSVD | 19.4 / 2.6 / 138 GB | two-wheeler behaviour; 210 fine-grained vehicle labels; 1,590 traffic-sign videos | supporting |

### Why IDD-3D specifically matters (from the paper, arXiv 2210.12878)
Against every major 3D driving dataset — KITTI, nuScenes, Waymo Open, ApolloScape, ONCE, A*3D —
IDD-3D is rated **"High" traffic diversity while all others are Low or Mid**, and it has the
**highest average number of bounding boxes per frame**. Two findings from the paper are directly
exploitable:
- **Objects are much closer to the ego vehicle** than in other datasets → *"motivation... for
  modeling of shorter reaction times."* This is a quantitative, citable justification for why a
  planner tuned on KITTI/nuScenes fails here.
- Classes include **auto-rickshaws, hand carts, concrete mixer machines, and animals on roads.**
- Baselines already run by the authors: **SECOND, CenterPoint, PointPillars** for detection, plus
  Kalman-filter-based MOT. So there are published numbers to beat.

**Our supercomputer + IDD-3D = we can train the perception/prediction stack from scratch.**
Almost no SIH team can do that. This is the single biggest asset we have and the idea must be
built around it, not decorated with it.

---

# 7. NOVELTY SCAN — where the actual gap is

## The finding
India has built **world-class perception data** for unstructured roads: 12+ datasets, thousands of
citations, IDD/IDD-3D/IDD-X/IDD-AW. A targeted search for Indian-specific **heterogeneous,
non-lane-based behaviour planners** returned **no India-focused planning research** — the planning
literature that exists is intersection-focused, structured-road, and Western-dataset-based.

> **Perception for Indian roads is saturated. Planning for Indian roads is nearly empty.**
> Everyone built the eyes. Almost nobody built the decision.

That is the seam, and it aligns exactly with the IIT Madras hackathon finding in §3 — every winner
built detection and warning, nobody built a planner.

## Import move 1 — Indian traffic is a crowd, not a lane system
Import the **Social Force Model** and **Reciprocal Velocity Obstacles** from **pedestrian crowd
dynamics** and use them as the **ego vehicle's planner**.

Prior art, checked honestly: social force has been applied to non-lane-based motorcycle flow
(Nguyen & Hanaoka 2011), e-bike/car mixed flow, and mixed traffic at signalised intersections; the
SUMMIT simulator uses crowd algorithms to *generate* traffic behaviour. **But those all use it to
simulate the other agents. Using it as the ego planner on Indian roads is the unoccupied move.**

Claim to make on the slide: *"no public product or paper does this"* — never "this has never been
done."

## Import move 2 — conformal prediction for a calibrated safety envelope
Wrap the trajectory predictor in **conformal prediction** so the planner does not merely avoid
collisions but **bounds the probability** of one at a chosen error rate. Active in 2025–26 robotics
(arXiv 2212.00278 motion planning among dynamic agents; arXiv 2508.05634 crowd navigation), and
**not aimed at Indian traffic by anyone**. It also hands the demo a hard number, which is exactly
what a MathWorks judge rewards.

## Import move 3 — the one I would actually lead with: IDD-X makes the planner *explainable*
IDD-X labels **19 explanation categories** for why the ego vehicle acted — congestion, obstruction,
**on-road living being**, stopped vehicle, cut-in, overtake, confrontation, crossing, merging,
deviate, slow down, turns, red light — across 3,634 real Indian driving scenarios.

Train the decision layer on those labels and the planner **narrates its own reasoning**:

> *"Slowing — on-road living being at 8.2 m, right-front. Deviating left. Collision probability
> bounded at 0.7%."*

Why this is the strongest option:
- It **turns an invisible algorithm into a visible one** — the exact fix for the Quiesce loss.
- It maps directly onto the **Stateflow decision logic** the PS explicitly asks for.
- It is grounded in **real Indian driver behaviour**, not invented rules.
- It is trainable on our supercomputer, and nobody without one can copy it in 7 days.
- Explainability is a live research topic, so it reads as a contribution, not a feature.

---

# 8. TARGET USER BASE — precise, not vague

**Wrong answer:** "Indian drivers" or "road accident victims." Too broad; fails criterion #2.

**Primary user: the ADAS/AV validation engineer who has to sign off a system for Indian roads.**
Nameable employers: Bosch India, Continental India, Tata Elxsi, KPIT, Hi-Tech Robotic Systemz,
Swaayatt Robots, Minus Zero, ARAI.

**Their actual pain, stated as they would state it:** *"I cannot prove my planner is safe on Indian
roads, because there is no standard Indian scenario suite to prove it against, and my planner was
tuned on datasets where every object is far away and in a lane."*

That pain is real and citable — IDD-3D's own paper documents that objects sit much closer to the
ego vehicle in India, demanding shorter reaction times than KITTI/nuScenes-tuned systems assume.

**Secondary user: MoRTH / ARAI homologation.** India has no unstructured-road AV test protocol.
A reproducible scenario suite plus metrics is the seed of one.

**Who benefits downstream (say this once, do not lead with it):** the framing number from the IIT
Madras hackathon — 4,12,432 crashes and 1,53,972 fatalities in 2021, ~84% driver error.

---

# 9. FEASIBILITY — the honest section

## The hard problem: nobody on our team has ever opened MATLAB
This is now the biggest risk on this PS, bigger than licensing. Specifics:

- **MATLAB/Simulink is the worst possible stack for a team that vibecodes.** LLMs are markedly
  weaker at Simulink block diagrams than at Python or JavaScript, and **RoadRunner is a GUI 3D
  authoring tool that cannot be prompted into existence at all.** Someone has to sit and learn it.
- We have **7 days to build** (31 Aug PS lock → 7 Sept internal hackathon).

## What the ramp actually looks like (verified)
| Resource | Length |
|---|---|
| MATLAB Onramp | **2 hours**, free, self-paced |
| Simulink Onramp | free, self-paced |
| Control Design Onramp with Simulink | free |
| "Getting Started with RoadRunner" | **14-video series** |
| "Understanding Sensor Fusion and Tracking" | 6 videos |
| "Autonomous Navigation" (path planning) | 6 videos |
| "Introduction to Automated Driving Toolbox" | 37 minutes |

Realistic plan: **2 days ramp, 5 days build**, with one person owning RoadRunner exclusively from
day one.

## The licence route — found, and better than expected
**MathWorks Student Competition Individual Team Request**
(`mathworks.com/academia/academic-support/student-competition-individual-team.html`)

- Must be submitted by **a faculty advisor or someone authorised to act for the university** —
  **we have a faculty mentor assigned**, so this route is open to us.
- Grants complimentary software, self-paced online training, **access to MathWorks engineering
  mentors**, and technical support.
- The form accepts any competition (asks for name + website); it is not restricted to a fixed list.
- **Caveat found on inspection: the form currently displays "Form submission is currently
  unavailable."** So use the parallel route too — MathWorks has partnered with SIH since 2019 and
  runs per-PS webinars; contact **hackathon@mathworks.com**.
- Fallback: KIET's MATLAB Campus-Wide Licence, if it includes RoadRunner + Automated Driving
  Toolbox. Student licences do **not** include either. (Sensor Fusion and Navigation Toolbox **are**
  in student licences.)

## Platform
**RoadRunner is Windows/Linux only — no macOS build.** Confirmed on the MathWorks
platform-availability page. We have at least one Windows/Linux machine, so this is handled — but
Aditya cannot do the RoadRunner work on his Mac. MATLAB itself does run on macOS.

## Where our team is actually strong
Put the ML in **Python/PyTorch on the supercomputer** — training a 3D detector/predictor on IDD-3D
and a decision-explainer on IDD-X — and keep MATLAB to the **integration and simulation layer**.
That plays to the team's real skills and confines the unfamiliar tool to a smaller surface.

## The field-data asset nobody else has
Aditya can shoot **real Indian road video** — main roads, galis, society lanes, under-construction
stretches, construction activity. Feeding real local footage into the RoadRunner scenes makes them
**provably real rather than imagined**, which is precisely the grounding move that both MathWorks
winners in §2 made. Do this in the research window, before the build starts.

---

# 9b. LICENCE RESOLVED — 27 Aug 2026 (checked directly in Aditya's MathWorks account)

**KIET holds a MATLAB "Total Headcount | Academic" (TAH) campus-wide licence, No. 41087767,
valid to 30 April 2027.** Aditya verified the full product list himself from home.

## Present — every single thing this PS needs, bar one
MATLAB - Simulink - **Automated Driving Toolbox** - **Navigation Toolbox** - **Stateflow** -
**Deep Learning Toolbox** - Computer Vision Toolbox - **Sensor Fusion and Tracking Toolbox** -
**Lidar Toolbox** - **Radar Toolbox** - **Vehicle Dynamics Blockset** - Parallel Computing Toolbox -
GPU Coder - Model Predictive Control Toolbox - Reinforcement Learning Toolbox -
Robotics System Toolbox - ROS Toolbox - UAV Toolbox - **Mapping Toolbox** - Image Processing -
Statistics and Machine Learning - Optimization + Global Optimization - Simulink 3D Animation -
Simulink Test / Coverage / Design Verifier / Requirements Toolbox - Simscape family -
Powertrain Blockset - System Composer - Embedded/MATLAB/Simulink Coder.

This is a near-complete TAH. Camera, LiDAR **and** radar sensor stacks are all covered, which is
exactly the multi-sensor setup the PS asks for. Parallel Computing Toolbox + GPU Coder means
training can even happen inside MATLAB, not only in PyTorch.

## Absent — RoadRunner
No RoadRunner, no RoadRunner Asset Library, no RoadRunner Scenario in the product list.
(Still to check: whether a *separate* licence entry exists on the Licenses page - RoadRunner is
often issued as its own licence rather than as a product under MATLAB.)

## Can the PS be built without RoadRunner? Partly - and this is the important nuance.

**Yes for the simulation.** Automated Driving Toolbox ships an Unreal Engine 3D environment with
**5 default scenes** (Straight Road, Curved Road, US City Block, Large Parking Lot, Empty Grass)
and **6 on-demand scenes** (Parking Lot, Double Lane Change, Open Surface, US Highway,
Virtual Mcity, ZalaZONE Smart City). Using them requires **neither RoadRunner nor Unreal Editor**.
Simulatable sensors: camera (incl. fisheye), scanning lidar, probabilistic radar, and a vision
detection generator. Driving Scenario Designer covers road networks, actors and trajectories and
exports to Simulink.

**No for the Indian-ness.** Every prebuilt scene is American or European - "US City Block",
"US Highway", "Virtual Mcity". **None resembles an unmarked village road or a dense Indian market**,
and the PS explicitly demands "at least two detailed RoadRunner scenes such as a village road and
an urban intersection." Custom scenes need either RoadRunner, or the free
**"Automated Driving Toolbox Interface for Unreal Engine Projects"** support package - which does
allow modifying and creating scenes, but requires Unreal Editor and is a much steeper climb.

## Consequence
- The mentor ask on 29 Aug is now **surgical**: *we have the entire TAH stack, we need RoadRunner
  added.* That is a far easier request than "please get us software."
- **A fallback path exists**, so the PS is no longer all-or-nothing on the licence. Worst case we
  build a working closed-loop demo in prebuilt scenes with weaker scene fidelity, and say so
  honestly on our own slide.
- **Feasibility moves up.** The toolchain risk is now purely the *learning curve*, not access.

---

# 10. PROPOSED IDEA SHAPE

Aditya has no fixed idea yet, so here is the one I would put forward, assembled from the findings
above rather than invented.

## "The planner that reads the road like a crowd — and says why."

**Spine (Import move 3):** a decision layer trained on **IDD-X's 19 explanation categories** that
emits a human-readable reason for every manoeuvre, wired into the **Stateflow** logic the PS asks
for.

**Mechanism (Import move 1):** the planner itself treats surrounding agents as a **crowd** — Social
Force / RVO — rather than as lane-following vehicles, because Indian traffic empirically is one.

**Guarantee (Import move 2):** **conformal prediction** over the trajectory predictor gives a
calibrated bound on collision probability, displayed live.

**Perception:** trained from scratch on **IDD-3D** on the college supercomputer, benchmarked against
the paper's own SECOND / CenterPoint / PointPillars baselines.

**Scenarios:** the five required scenarios in RoadRunner, with the village road and market scenes
**traced from Aditya's own footage** of real local roads.

**The demo:** the vehicle drives the cattle-crossing scenario while a side panel narrates —
*"on-road living being detected, 8.2 m, collision probability bounded at 0.7%, deviating left"* —
and the metrics the PS names (replanning latency, path smoothness, scenario completion rate) tick
live.

**Why this survives a hostile judge:**
- "Isn't this just the MathWorks examples?" — No: the perception model is trained from scratch on
  IDD-3D, and the planner is crowd-dynamics-based, not `trajectoryOptimalFrenet` out of the box.
- "Isn't Swaayatt already doing this?" — Swaayatt builds a proprietary vehicle. We build the
  reproducible, explainable planning-and-test framework, and we publish our numbers.
- "What's actually new?" — No public product or paper uses crowd-dynamics as the *ego planner* on
  Indian roads, and none produces per-manoeuvre explanations grounded in a real Indian
  decision-labelled dataset.

---

# 11. OPEN ITEMS

| # | Item | Owner | Urgency |
|:-:|---|---|---|
| 1 | Faculty mentor submits the MathWorks Student Competition request; parallel email to hackathon@mathworks.com | Mentor + Aditya | **Before 31 Aug** |
| 2 | Confirm whether KIET's Campus-Wide Licence includes RoadRunner + Automated Driving Toolbox | Aditya → licence admin | **Before 31 Aug** |
| 3 | Register at `idd.insaan.iiit.ac.in`, confirm IDD-3D and IDD-X actually download (236 GiB + 160 GB — check disk and campus bandwidth) | Hosteller with lab access | Immediately |
| 4 | Confirm supercomputer specs, booking process, and how many days we can hold it in September | Hostellers | Immediately |
| 5 | One person starts MATLAB Onramp + Simulink Onramp (4 h total) now, before the PS is even locked | Whoever owns RoadRunner | Now |
| 6 | Aditya shoots real road footage — main road, gali, society lane, under-construction stretch, market | Aditya | During research window |

---

# 12. VERDICT

**Strengths:** the best demo and judge-legibility of anything we have screened; no government
dependency at all; no unprovable physical claim; a world-class free dataset family that suits our
supercomputer perfectly; a genuine and verified novelty seam (planning, not perception); and a
direct winning precedent in TwinX.

**Weaknesses:** an unfamiliar toolchain with a real learning curve inside a 7-day build; a licence
route that is open but unconfirmed; and a judge pool that saw the "Indian scenarios in RoadRunner"
move win last year.

**Score will be finalised after Dossier 2**, with the supercomputer priced into feasibility and
novelty. Provisional read: this moves **up** from the 7.4 in the earlier comparison on the strength
of the IDD-X explainability angle and the empty planning seam — held back only by the MATLAB ramp.
