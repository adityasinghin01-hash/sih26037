# PRD — SIH26037

**Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles on Unstructured Indian Roads**
MathWorks · Smart Vehicles · Smart India Hackathon 2026

Read this first. Everything else in `docs/` is detail hanging off it.

---

## 1 · The problem, in plain language

Every self-driving car has one rule: **when it isn't sure, it stops.**

That works where lanes are painted and signals say whose turn it is. At an Indian junction with no
signal, nobody has priority — so the car is never sure. It stops, and it never goes. Traffic piles
up behind it and people drive around it.

**Stopping is not safety here. It is failure.**

We did not have to argue this. India's own driving-decision dataset, IDD-X, contains **3,634
recorded decisions, and every single one is the car giving way.** There is no recorded example of
going first. Even the data only knows how to be defensive.

## 2 · What MathWorks asked for

Quoted, not paraphrased. Full mapping in `docs/PS-COMPLIANCE.md`.

| They asked for | Short version |
|---|---|
| "a working simulation pipeline that integrates perception, prediction, path planning, decision logic, and vehicle motion in MATLAB and Simulink" | The whole loop, in their toolchain |
| "a multi-sensor setup such as camera, LiDAR, and radar" | All three modalities |
| "auto-rickshaws, pushcarts, pedestrians, and animals" | Indian road users, not Western ones |
| "at least five realistic Indian road scenarios" | Village road · unsignalled junction · highway merge · dense market · **cattle crossing** |
| "at least two detailed RoadRunner scenes" | **Our one declared deviation** — no licence |
| "replanning latency, path smoothness, and scenario completion rate" | Measured, not asserted |
| "a short technical report" and "a demonstration video" | Both shipped |
| "closed-loop validation" | Agents must react to us, not follow scripts |

## 3 · Our solution, in plain language

**Teach the car to negotiate instead of wait.**

We take the rulebook from ships. The sea has no lanes either, and it solved this a century ago:
when two vessels meet, one **gives way** and the other **holds course and speed**. Which is which
comes from the angle between them — no radio, no permission, no central authority. Just geometry.

Five parts:

| # | What | Why it is not obvious |
|---|---|---|
| 1 | **Delete the traffic controller** | The MathWorks code we build on resolves junctions with a central referee. A signal is a referee. We remove the object — it is literally one method call |
| 2 | **COLREGs roles from geometry** | Give-way acts early and substantially. Stand-on **holds course and speed**. Predictability is the safety mechanism, not aggression |
| 3 | **A learned yield predictor** | Answers *"will that scooter let me in?"* — a decision, not a trajectory — and takes our own intended action as input |
| 4 | **A cow with an internal state** | Grazes, crosses, and responds to a horn only if it is not used to traffic. A parameter, so we get a curve instead of an anecdote |
| 5 | **Evidence, not a demo** | The car we beat is MathWorks' shipped planner, unmodified. Three curves, not one video |

### The one line
> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

## 4 · What we are NOT building

**Not a self-driving car.** India legally requires a driver in effective control.

| Tesla | Us |
|---|---|
| The whole car brain, door to door | **One decision**: who goes first |
| A product you buy | **A test suite** anyone can run |
| Closed and proprietary | Published — scenarios, metrics, results |

> **We are not building the car. We are building the driving test that a Western car would fail in
> India — and one car that passes it.**

Since **1 April 2026**, MoRTH notification GSR 184(E) makes a full ADAS suite mandatory on new
buses and trucks in India. One of the five required standards, **AIS-188, is lane departure
warning** — a lane-based standard, on roads that often have no lanes.

Our users are **ARAI and ICAT**, who homologate every vehicle sold in India, and the validation
teams at Bosch India, Continental, Tata Elxsi and KPIT.

## 5 · The user journey — what a judge sees, start to end

| When | What is on screen | What they do |
|---|---|---|
| **0:00** | Real Meerut street footage, looping. No slides | Watch. *"Every self-driving car has one rule: when it's not sure, it stops. On this road, it's never sure"* |
| **1:00** | One number: **3,634 decisions, all giving way** | Understand the problem is documented, not claimed |
| **2:00** | **Screen splits.** Left: MathWorks' planner. Right: ours. Same junction, same traffic, same seed. One slider between them: **traffic density** | We hand them the mouse |
| **3:00** | Light traffic — both get through. We say out loud: *"here we're no better"* | They keep dragging |
| **3:30** | **The left car stops. And never starts again.** Cars pile up behind it. The right car keeps threading through | **They caused it.** Not a video |
| **4:00** | Overlay switches on: **GIVE WAY / STAND ON** labels over each agent, the collision cone drawn from our car, a safety number `h` staying green, **"0.81"** above the scooter | They see the car *thinking* |
| **5:00** | Cattle scene. A **HORN** button and a **how used to traffic** slider | Slider low + horn → **the cow bolts**. Slider high + horn → **it doesn't lift its head** |
| **6:00** | Three charts: time-to-enter · success vs density · **performance as sensors degrade** | *"Nobody publishes that third one"* |
| **7:00** | The honest slide: where lane-based methods beat us, no real vehicle, not peer-reviewed | Trust |
| **8:00** | *"One command. Twelve minutes. Re-run every number yourself"* | Close |

**What they remember:** they made a car freeze with their own hand, they honked at a cow and it
ignored them, and we told them where we lose before they had to ask.

## 6 · Scope

**In:** all five scenarios, with the unsignalled junction and cattle crossing perfected first.
**Out:** real-vehicle deployment, peer review, RoadRunner scenes, any claim on the highway merge.

**Honest expectations per scenario are in `docs/PS-COMPLIANCE.md`.** On the highway merge,
lane-based methods genuinely beat us — our planner detects road structure and switches off.
*"Our planner knows when it isn't needed."*

## 7 · How success is measured

Ten metrics, **pre-registered before any run** so nobody can say we picked them to flatter the
result. Full definitions in `docs/metrics.md`. The three that matter:

- **M1 time-to-enter** — how long the car sits there
- **M2 completion vs traffic density** — the curve the judge felt with their own hand
- **M3 perception-degradation curve** — the one no incumbent publishes

**Rule:** M4 (collisions) and M5 (minimum time-to-collision) **must not regress against the
baseline.** A faster car that is less safe is a failed project, and we report it as one.

## 8 · The team

Six streams, deliberately independent because `docs/INTERFACES.md` is frozen.

| Stream | Owns | Brief |
|---|---|---|
| **A** | Scenarios, roads, junctions | `teammates/A-world.md` |
| **B** | Lidar, radar, tracking | `teammates/B-perception.md` |
| **C** | METEOR, LSTM, training | `teammates/C-prediction.md` |
| **D** | COLREGs planner, Stateflow | `teammates/D-planner.md` |
| **E** | Baseline, metrics, experiments | `teammates/E-evidence.md` |
| **F** | Blender, renders, demo (Aditya) | `teammates/F-visual.md` |

## 9 · Rules that apply to everyone

1. **Never edit `matlab/baseline/`.** A tuned baseline is a strawman and kills the result.
2. **Never invent a number.** If it is not in `docs/CLAIM-LEDGER.md`, it does not go on a slide.
3. **Never change `docs/INTERFACES.md`** without a row in `docs/CHANGELOG.md`.
4. **Nothing ships with a bug already reproduced in the demo flow.** We lost a hackathon that way.
5. **Errors are reported in full.** Never a summary.
