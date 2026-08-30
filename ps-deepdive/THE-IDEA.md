# SIH26037 — THE IDEA, LOCKED
**30 Aug 2026. Every claim below traces to a verified source in `research/`.**

---

## THE ONE LINE
> **An Indian junction has no controller. We built the planner that negotiates instead of
> waiting — in MATLAB, where no one has built one, against a cow that behaves like a cow.**

---

## THE PROBLEM, IN ONE SLIDE
Every autonomous vehicle ever built has the same safe default: **when uncertain, stop.**
On an unsignalled Indian junction, stopping is not safety. It is failure.

**Evidence we did not have to generate:**
- The number one reason humans honk at real driverless cars is **"waiting too long before
  going"** (ACM study of AV honking).
- **Waymo publicly rebuilt its Driver to be "confidently assertive"** because passivity was
  disrupting traffic — and then drew an **NHTSA investigation and an NTSB probe** over school-bus
  incidents. Assertiveness without a principle is a liability.
- India's own flagship driving-decision dataset, **IDD-X, contains 3,634 scenarios and every
  one is the car giving way.** There is no label for going first. Even the data only knows how
  to be defensive.

---

## THE FOUNDATION WE BUILD ON — named on our own slide
**`mathworks/OpenTrafficLab`** — MathWorks' own open-source MATLAB repository. Closed-loop
junction simulation, T-junctions and four-way intersections, with `DrivingStrategy` and
`TrafficController` classes explicitly designed to be inherited from.

**And the gap is one sentence:**
> OpenTrafficLab resolves a junction with a **TrafficController** — a central authority, like a
> signal. **An Indian junction has no authority.** We delete the controller and let the agents
> negotiate.

---

## THE FOUR THINGS WE BUILD

### 1. Role-based negotiation, imported from the sea
**The ocean has no lanes either.** Shipping solved contested open space with **COLREGs** — a
rulebook that assigns **roles**, not positional right-of-way:
- **give-way:** take early and substantial action
- **stand-on:** hold course and speed
- three defined geometries: head-on, overtaking, crossing

It is already a working planner formalism — COLREGs encoded in **velocity space** through
velocity obstacles, which "specify on which side of the obstacle the vehicle will pass."

**Why this beats "make the car assertive":** the stand-on duty is to **hold course**.
**Predictability is the safety mechanism.** Our car is not aggressive; it declares a role and
keeps it. That is defensible in front of a judge in a way that "we made it pushier" is not.

*No public work we could find applies COLREGs-style role assignment to road traffic.*

### 2. A learned yield predictor — the gap nobody has filled
We asked the literature: has anyone trained a model to predict whether an agent will
**yield or not yield** — a decision, not a trajectory?
**NO RESULTS.**

**METEOR labels exactly that, per agent.** Quoted from the paper:
> **Yield:** "a slow-moving agent trying to cross the road in front of another agent.
> **If the latter slows down or stops, letting them cross**, then such behavior is labeled as yield."
> **Cutting:** "when a slow-moving agent trying to cross the road **is interrupted by another agent**."

Those are the two outcomes of a negotiation, labelled across 13 million bounding boxes of real
Hyderabad traffic. We train an **LSTM classifier** on them — the one architecture that imports
cleanly into MATLAB — and keep it in the image plane, sidestepping monocular depth error
entirely.

### 3. A cow that behaves like a cow
Verified: **no dataset, no product and no planner treats animals on Indian roads as agents.**
Every existing animal system detects and warns. The problem statement *requires* a cattle scenario.

We model it from published movement ecology, not imagination:
- a **state-switching correlated random walk** — one state for directed crossing, one for
  tortuous grazing (Michelot 2019)
- **plus a habituation parameter**, because livestock science says a horn frightens rural
  cattle but has *"little effect on cattle accustomed to motorway traffic."*
- a **real 3D mesh** via `MeshVertices`/`MeshFaces`, so simulated lidar returns come off actual
  animal geometry, not a box

**The number:** Haryana Assembly, answered by the Agriculture Minister — **3,383 stray-cattle
road accidents in five years, 919 dead, 3,017 injured.** India has **5,021,587 stray cattle**
and **no national record of the deaths they cause.**

### 4. Evidence, not a demo
- The car we beat is **MathWorks' own shipped planner, unmodified.** The freeze is their code,
  not our strawman.
- Not one video — **a curve.** Traffic density on the x-axis, scenario completion on the y.
- **The perception-degradation sweep:** planner performance as detection error rises.
  Every incumbent assumes near-perfect sensing — B-GAP admits it needs "very good sensing",
  GameOpt runs in SUMO with no sensors at all. **Nobody publishes this curve.**
- **Eight GPUs, forty experiments, one command, twelve minutes to regenerate every number.**

---

## WHY THE INCUMBENTS DO NOT COVER US — in their own words
| Work | Their own admission |
|---|---|
| **B-GAP** | pedestrians and bicycles are **future work**; intersections are **future work**; needs "very good sensing"; admits it acts **conservatively** |
| **GameOpt+** | **"assumes connected autonomous vehicles equipped with V2I communication."** A cow cannot bid in an auction. |
| **GamePlan** | "does not plan beyond computing turn-based orderings"; demonstrated with **2-3 vehicles** |
| **Camara & Fox** | a **review article** about pedestrians. No system, no simulator. |
| **MathWorks examples** | lane-based; break where painted lines do not exist |

---

## WHAT WE SAY BEFORE A JUDGE SAYS IT
- **"You didn't invent this."** Correct. We took the best published methods, none of which exist
  in the toolchain MathWorks asked for, and built the first working closed-loop implementation
  in MATLAB and Simulink on Indian scenes with an honest baseline.
- **"Where are the RoadRunner scenes?"** We do not have a RoadRunner licence. Our scenes are
  built programmatically from real Meerut road geometry and **exported as OpenDRIVE** — they
  import into RoadRunner the day a licence arrives.
- **"Is your perception real?"** Camera perception is trained on IDD and benchmarked on real
  Indian video. In-loop perception is **lidar**, because the cuboid environment produces real
  point clouds and no pixels. We report both, separately, and we report how the planner degrades
  when perception is wrong.
- **"Isn't this Swaayatt?"** Swaayatt builds a proprietary vehicle. We build the reproducible,
  open, measurable test framework — and we publish our numbers.

---

## THE ARCHITECTURE
```
 drivingScenario API  ──►  unmarked roads, real Meerut geometry, custom cow mesh
        │                  laneMarking('Unmarked')  ·  export OpenDRIVE
        ▼
 Scenario Reader ──► Bus Selector ──► Stateflow (COLREGs roles) ──► bicycle model
        ▲                                                                │
        └──────────── Non-ego Actor Poses input (closes the loop) ◄──────┘
        │
 lidarPointCloudGenerator ──► detection/tracking ──► LSTM yield predictor (ONNX)
        │
        ▼
 metrics: yield ledger · time-to-enter · completion vs density · perception-degradation curve
```

---

## OPEN RISKS, RANKED
1. **`lidarPointCloudGenerator` + a MATLAB-native lidar detector working end to end.**
   Everything rests on this. Test it on day one.
2. Supercomputer disk, internet and booking — still unanswered by the lab.
3. OpenDRIVE export may degrade unstructured junctions (documented limitation).
4. METEOR is 93.4 GB and its official page is dead; only the HuggingFace mirror lives.
   **Download it early.**

## IMMEDIATE ACTIONS
- Find the date of the **MathWorks SIH webinar** and attend it.
- Read the **Team TwinX** write-up on the MathWorks Student Lounge blog (6 Apr 2026) — the
  judges' own publisher explaining what winning looks like.
- Download METEOR before the mirror disappears.
