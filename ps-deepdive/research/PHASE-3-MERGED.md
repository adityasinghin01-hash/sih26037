# PHASE 3 — MERGED RESULT
**30 Aug 2026. Consensus + Gemini + ChatGPT + Grok + Perplexity.**
**Verdict: Phase 1 was too pessimistic. The incumbents admit, in their own words, that they
do not do what we thought they did.**

---

# PART 1 — B-GAP IS NOT UNSTRUCTURED TRAFFIC AT ALL

We wrote B-GAP off as owning our per-agent behaviour idea. Its own limitations section
says otherwise. All quoted:

> "we plan to develop efficient navigation techniques to handle **heterogeneous
> traffic-agents such as pedestrians or bicycles**" — FUTURE WORK

> "we plan to extend our approach to different environments like **roundabouts,
> intersections**, and parking lots"

> "the performance of our approach **drops as the perception radius decreases**... it would
> require **very good sensing** for it to be applicable to real-world scenarios"

> "In some cases, the ego-vehicle avoids aggressive vehicles by decelerating and performing
> fewer lane changes, **thereby acting conservatively**"

**What B-GAP actually is:** a highway agent in **highway-env** (a lane-based OpenAI Gym
simulator) that does **lane changes**, handles **vehicles only**, needs near-perfect sensing,
and **admits it turns conservative** — the very failure we are trying to fix.

No pedestrians. No bicycles. No animals. No intersections. No unstructured roads. Lanes
throughout.

---

# PART 2 — GAMEOPT+ NEEDS INFRASTRUCTURE COMMUNICATION

My Phase 1 hypothesis was right. Quoted:

> **GameOpt+ "assumes connected autonomous vehicles equipped with V2I communication"**

> GamePlan: "our method currently **does not plan beyond computing turn-based orderings**,
> i.e. local navigation" — it decides *who goes first*, not how to drive

> "we have currently demonstrated real world application with **2-3 vehicles**"

> GameOpt+ states prior GAMEOPT "**did not account for heterogeneous vehicles**"

Simulator: **SUMO** — a microscopic traffic simulator, no sensors, no perception.
Agents: vehicles only. No pedestrians, no animals.

**A cow cannot bid in an auction. Neither can an auto-rickshaw driver.** An auction-based
intersection method is structurally unavailable on an Indian road.

---

# PART 3 — "UNFREEZING AVs" IS A REVIEW, NOT A SYSTEM

Camara & Fox 2022 is a **review article**. No implementation, no simulator, no limitations
section, and its scope is **AV-pedestrian interaction only**. It is a citation for the
problem, not a competitor for the solution. We cite it and move on.

---

# PART 4 — WHAT NO PRODUCTION SYSTEM DOES (Grok)

- **No AV company publicly classifies individual road users by behaviour and adapts.**
  Checked: Waymo, Zoox, Tesla, Mobileye, Wayve, Nuro. Tesla has Chill/Average/Assertive as
  **global driver profiles**, not per-agent judgement. Nothing found for the others.
- **Waymo's assertiveness push has a cost we should name.** Assertive changes were linked
  by reporting to **Austin school-bus incidents** — passing stopped buses with stop arms
  out — triggering an **NHTSA investigation, an NTSB probe and voluntary software recalls**.
  Police also stopped a Waymo for an illegal U-turn.
  **This is the argument for our safety layer:** the industry leader made its car assertive
  and immediately hit a regulatory wall. Assertiveness without a formal bound is a liability.

## India's regulatory reality — changes how we pitch
- Motor Vehicles Act 1988 still requires a vehicle be under a driver's **"effective control."**
- Minister Gadkari: *"I will not allow driverless cars in India at any cost."*
- Draft AIS-189/190 cybersecurity and software-update rules reference Level 3+, phased from
  ~Oct 2026. Automotive radar spectrum 77-81 GHz delicensed.
- This is why Minus Zero and others pivoted to **ADAS for OEMs**, not robotaxis.

**Consequence: never pitch this as a driverless car for India.** Pitch it as a simulation
and validation framework — which is exactly what the PS asks for anyway.

---

# PART 5 — MATHWORKS (Gemini; treat with caution, some claims need re-checking)

## Their shipped examples are lane-based and break without lanes
- **Highway Lane Following / Lane Change** rely on painted boundaries and parabolic curve
  fitting. In lane-free traffic the coordinate system they use *does not physically exist*.
- **ACC** assumes a single target ahead in-lane; useless when a bike, an auto and a car share
  the same lateral space.
- **Intersection Movement Assist** exists but leans on **V2V/V2X**, not perception.

## Two MathWorks assets we should actually use
- **Extended Object Tracking with a PHD tracker** — tracks objects *and estimates their
  spatial extent*. Built for exactly the case where a bus and a scooter occupy the same
  space and multiple returns belong to one large body. Highly applicable.
- **RoadRunner can build lane-free scenes programmatically** — no painted markings required.

## The open-loop NPC problem is named explicitly
Simulator NPCs "follow predetermined trajectories regardless of the ego vehicle's actions."
Closing that loop requires **Simulink-controlled agents inside RoadRunner Scenario**.
**So the closed loop is possible but is not shipped. We would be building it.**

## RSS — and the lateral term is the interesting one
MathWorks supports integrating Responsibility-Sensitive Safety. The **lateral** safe-distance
formula matters most in lane-free traffic where vehicles pass with centimetres of clearance.
NEEDS DIRECT VERIFICATION on mathworks.com before we claim it.

## Metrics
Built in: Euro NCAP AEB scenarios, time-to-collision, collision velocity, bird's-eye-view
plotting. **No built-in progress or blocking metric.** Academic work reaching for these uses
**Episodic Average Speed, Average Travel Time, and Acceleration Cost** via external
simulators — usually a **SUMO-MATLAB interface** (e.g. the UAMP uncertainty-aware planning
framework, mixed aggressive/normal/cautious drivers).

## A cross-domain precedent worth stealing
MATLAB path planning has been used for **agricultural robots generating clothoid trajectories
in pasture land amid unpredictable grazing livestock.** That is the same kinematic problem as
a car weaving past stray cattle. A genuine import move.

**CAUTION:** this Gemini report contains at least one verified error — it claims METEOR is
Apache 2.0, which contradicts the CC BY-NC-SA on the project page. Verify every MathWorks
claim on mathworks.com directly before it reaches a slide.

---

# PART 6 — AUDIO: WEAKER THAN HOPED, AND I MUST CORRECT MYSELF

**Correction: audio-visual driving datasets DO exist.** A3CarScene has **8 microphones**,
inside and outside a research vehicle, ~31 hours, ~1,500 km. My earlier "no driving dataset
has audio" was wrong. It is true of the *Indian* datasets only.

**Sound is already shipping in production AVs:**
- **Waymo External Audio Receivers** — detect sirens and railroad crossings; the car pulls
  over or yields. Placement designed around wind noise.
- **Zoox** — microphones detect and localise sirens before they are visible; yields/pulls over.
- **Tesla** — sound detection, yields to approaching emergency vehicles.

**The horn is already patented, in detail:**
- **Motional US11567510B2** — "Using classified sounds and localized sound sources to operate
  an autonomous vehicle." Covers sirens, **horns**, vehicle sounds, pedestrian sounds,
  construction; localisation; **route and trajectory planning from acoustic information.**
  This is the closest prior art to our horn idea, and it is a granted patent.
- **Waymo US11958505B2** — locating a horn honk using multiple vehicles.

**Research beyond sirens is real:**
- **TU Delft "Hearing What You Cannot See"** — 56-mic array detects vehicles **around blind
  corners**; 0.92 accuracy stationary, 0.84 moving. OVAD dataset.
- **MM-DistillNet** (Freiburg) — 113,000 frames; audio-only object detection while moving.

**Known engineering difficulty:** wind noise, ego noise, Doppler from a moving array,
reverberation in streets, array calibration, and ice — there is a patent for *heated*
external microphones.

**What is still not demonstrated:** an open, end-to-end system where a **non-siren**
environmental sound changes an autonomous vehicle's planned trajectory.

**HONEST VERDICT: down-rate the horn idea.** It is patented, partially shipped, and hard to
engineer. The only surviving slice is narrow: the horn as a *continuous negotiation signal*
in dense unstructured traffic, where honking is the norm rather than the exception, and where
over-use degrades it. Interesting, but no longer a headline.

---

# PART 7 — ANIMALS: THIS IS THE FLOOR

Everything points the same way, and we now have numbers.

## Nobody models animals as agents on Indian roads
- **NO RESULTS** for an Indian AV dataset recording vehicle approach + horn + animal response.
- **NO RESULTS** for a commercial Indian automotive product doing closed-loop cow behaviour
  prediction and negotiation.
- Deer work exists (a 26,127-image FIR dataset with risk labels) but is **not public** and is
  North American wildlife, not Indian urban cattle.
- Commercial products (CrossTek, DeterCamAI, Tentosoft, Swedish roadside pilots) all
  **detect and warn**. None plan.

## Livestock science gives us the behaviour model — and a beautiful nuance
- "truck horns can **elevate cattle heart rates**"
- "a vehicle horn can frighten cattle grazing in rural areas but has **little effect on
  cattle accustomed to motorway traffic**" — **HABITUATION**
- Dairy-cow experiment: a car-horn signal made cows avoid the walkway
- Handling guidance: "Don't honk a horn or otherwise harass the cattle"
- Deer research: vehicle approach may not register as a threat until ~470 m

**The habituation finding is the gold.** A rural cow flees the horn; an urban cow ignores it.
**That is per-agent negotiability, grounded in published animal science rather than invented
by us** — and it makes Aditya's own observation precise rather than contradicting it.

## The citable Indian numbers
- **Haryana Assembly: 3,383 stray-cattle road accidents in five years — 919 deaths,
  3,017 injuries.** The strongest official figure found.
- Madhya Pradesh Assembly: 237 cattle-related accidents, 94 deaths, 133 injuries over 2 years.
- **India's stray cattle population: 5,021,587** (20th Livestock Census).
- **No national figure exists.** A Parliamentary answer confirms India does not maintain data
  on deaths caused specifically by stray cattle. Do NOT use the NCRB "6,331 killed by animals
  2017-2021" figure — it is all animal-caused deaths, not road accidents.
- India Roadkill Monitoring Project — public, georeferenced, 2018-2025, ten states.

---

# PART 8 — WHERE THIS LEAVES THE DESIGN

| Idea | Phase 1 verdict | Phase 3 verdict |
|---|---|---|
| Per-agent negotiability | Dead (B-GAP) | **ALIVE.** B-GAP is highway, lane-based, vehicles-only, and admits it goes conservative. |
| Intersection negotiation | Dead (GameOpt) | **ALIVE.** GameOpt+ needs V2I. Nothing on an Indian road can communicate. |
| The frozen-robot framing | Dead (Camara & Fox) | **ALIVE as ours to build.** Theirs is a review of AV-pedestrian interaction, not a system. |
| Assertiveness | Dead (Waymo) | **ALIVE with a twist.** Waymo shipped it and got investigated. Assertiveness needs a formal safety bound — that is our contribution. |
| The horn | Promising | **DOWN-RATED.** Patented by Motional, shipped for sirens, hard to engineer. Keep as a secondary idea. |
| **Animals as agents** | Unverified | **THE FLOOR.** No dataset, no product, no planner. Livestock science supplies the behaviour model. Haryana gives us 919 deaths. The PS requires the scenario. |
| MATLAB/Simulink | The gap | **CONFIRMED.** Shipped examples are lane-based and break without lanes; the closed loop is not shipped. |

## Next actions
1. Verify on mathworks.com directly: does Automated Driving Toolbox ship RSS? Which product?
2. Get the Indian DRL intersection paper (Multimedia Tools & Apps, Aug 2024) — it is the
   closest published competitor and we still have not read its limitations.
3. Confirm the Haryana figure from the primary Assembly document before it goes on a slide.

---

# PART 9 — VERIFICATION OF THE THREE WARNINGS (Claude, 30 Aug)

## 1. RSS in MathWorks — **GEMINI WAS WRONG. NOT SHIPPED.**
Two searches of mathworks.com and its documentation found **no RSS function, no RSS example,
no RSS reference application** in Automated Driving Toolbox. RSS is Mobileye's model; MathWorks
does not ship an implementation.
**Consequence:** if we want RSS we implement it ourselves. That is more work but a bigger
contribution — and the **lateral** RSS term is the one that matters on a lane-free road.
Do not claim MathWorks ships RSS.

## 2. Haryana stray-cattle figure — **CONFIRMED, with a proper citation**
**3,383 road accidents caused by stray cattle over five years; 919 killed; 3,017 injured.**
Source: written answer by Haryana Agriculture and Animal Husbandry Minister **J P Dalal** in
the Haryana Assembly, to a question by Independent MLA **Balraj Kundu**. PTI, Aug 2022.
Carried by Deccan Herald and Business Standard. **Safe to put on a slide, cited as a Haryana
Assembly answer, not a national figure.**

## 3. Indian DRL intersection paper — **STILL UNVERIFIED.** Springer is gated. Its
limitations remain unread. Keep it on the open list.

---

# PART 10 — THE FIND THAT MATTERS MOST: MathWorks' own GitHub

## mathworks/OpenTrafficLab — 42 stars, official MathWorks repo
- MATLAB environment for traffic scenarios, **T-junctions and four-way intersections**
- **Extends Driving Scenario Designer into CLOSED-LOOP simulation, where vehicle behaviour
  emerges from control logic instead of predefined waypoints** — this is precisely the
  open-loop NPC problem, already solved, by MathWorks, in MATLAB
- Parent classes **DrivingStrategy** and **TrafficController** designed to be inherited from
  "to implement user defined driving logic"
- Ships two human-driver car-following models: **Gipps** and **Intelligent Driver Model (IDM)**
- Requires MATLAB R2020b + Automated Driving Toolbox — both in KIET's licence

**This is the apartment.** MathWorks' own code, in the required toolchain, for intersections,
with reactive agents and human driver models, explicitly built to be extended.

**And the gap is now precise and sayable in one line:**
> OpenTrafficLab resolves a junction with a **TrafficController** — a central authority, like
> a signal. Indian junctions have no controller. **We replace the controller with negotiation
> between the agents themselves.**

Its models are also longitudinal and lane-based (Gipps, IDM are car-following), so
lane-free lateral behaviour is ours to build.

## mathworks/adScenarioSimRefEx — 13 stars, official MathWorks repo
- "Agent based simulation framework for **validating planners**"
- The **"smart actor"** pattern: mark one actor as autonomous, give others car-following models
- Requires MATLAB, ADT, **Model Predictive Control Toolbox, Simulink, Simulink Coder,
  Stateflow** — all present in KIET's TAH licence
- **Confirms the limitation:** other agents "operate independently" and do not react to the
  ego vehicle's decisions. Only overtake-on-a-straight-road.

**Use OpenTrafficLab as the environment; borrow the smart-actor pattern from adScenarioSimRefEx.**
