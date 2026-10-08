# PRD — SIH26037

**Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles on Unstructured Indian Roads**
MathWorks · Smart Vehicles · Smart India Hackathon 2026

---

## 0 · What this document is

A **PRD** is a Product Requirements Document. It answers five questions in one place, so nobody
has to guess:

1. **What problem are we solving, and for whom?**
2. **What exactly was asked of us?**
3. **What are we building, and what are we deliberately *not* building?**
4. **How will we know it worked?** (the measurements, agreed before we start)
5. **Who does what, and how do the pieces fit together?**

This is the only project-level document. Everything else is five workstream files in
`teammates/`. If something is not in here or in your own file, it does not exist.

---

## 1 · The problem, in plain language

Every self-driving car has one rule: **when it isn't sure, it stops.**

That works where lanes are painted and signals say whose turn it is. At an Indian junction with no
signal, nobody has priority — so the car is never sure. It stops, and it never goes. Traffic piles
up behind it, and people drive around it.

**Stopping is not safety here. It is failure.**

We did not have to argue this. India's own driving-decision dataset, IDD-X, contains **3,634
recorded decisions, and every single one is the car giving way.** There is not one recorded
example of going first. Even the data only knows how to be defensive.

---

## 2 · What MathWorks asked for

Quoted, not paraphrased.

| They asked for | Our status |
|---|---|
| "a working simulation pipeline that integrates **perception, prediction, path planning, decision logic, and vehicle motion** in MATLAB and Simulink" | The whole loop, in their toolchain |
| "a multi-sensor setup such as **camera, LiDAR, and radar**" | Lidar + radar in the loop; camera offline and reported separately |
| "**auto-rickshaws, pushcarts, pedestrians, and animals**" | All four in the class table, §6 |
| "**at least five** realistic Indian road scenarios" | All five ship. Two are perfected first |
| "at least two detailed **RoadRunner scenes**" | **Our one declared deviation** — no licence. See §3 |
| "**replanning latency, path smoothness, and scenario completion rate**" | M6, M7, M2. Plus seven more |
| "a short **technical report**" and "a **demonstration video**" | Both ship |
| "**closed-loop validation**" | Agents react to us; they do not follow scripts |

### The five scenarios, with honest expectations

| # | Scenario | Priority | What we expect |
|---|---|---|---|
| 1 | **Urban intersection, no signals** | perfect first | **We win.** No controller exists to defer to |
| 2 | **Sudden cattle crossing** | perfect first | **We win.** Nobody models animals as agents |
| 3 | Dense market, mixed traffic | coverage | We expect to win — highest density |
| 4 | Unmarked village road | coverage | Baseline copes at low density. **Our contribution is small and we say so** |
| 5 | Highway merge, slow vehicles | coverage | **Lane-based methods beat us. We do not claim this win** |

"Two perfect first" is an **ordering, not a reduction.** All five ship.

### The one deviation, declared

RoadRunner is not on licence 41087767. Instead: scenes are built **programmatically** with the
`drivingScenario` API (scriptable, so we generate many junction variants where a GUI makes one),
from **real Meerut geometry via OpenStreetMap**, and **exported as OpenDRIVE**. They import into
RoadRunner the day a licence arrives.

---

## 3 · Our solution, in plain language

**Teach the car to negotiate instead of wait.**

We take the rulebook from ships. The sea has no lanes either, and it solved this a century ago:
when two vessels meet, one **gives way** and the other **holds course and speed**. Which is which
comes from the angle between them — no radio, no permission, no central authority. Just geometry.

| # | What we build | Why it is not obvious |
|---|---|---|
| 1 | **Delete the traffic controller** | The MathWorks code we build on resolves junctions with a central referee. A signal is a referee. We remove it — literally one method call |
| 2 | **COLREGs roles from geometry** | Give-way acts early and substantially. Stand-on **holds course and speed**. Predictability is the safety mechanism, not aggression |
| 3 | **A learned yield predictor** | Answers *"will that scooter let me in?"* — a decision, not a trajectory — and takes our own intended action as input |
| 4 | **A cow with an internal state** | Grazes, crosses, responds to a horn only if it is not used to traffic. A parameter, so we get a curve rather than an anecdote |
| 5 | **Evidence, not a demo** | The car we beat is MathWorks' shipped planner, unmodified. Three curves, not one video |

**The one line:**
> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

### Two technical results worth stating on their own

**Project down, never lift up.** The instinct is to lift the METEOR dataset into 3-D so it matches
the simulator. That needs monocular depth, and **1° of camera pitch error is ~31% depth error at
30 m**. So we go the other way: the simulator's exact 3-D is projected *into* the image plane,
where METEOR already lives. Downward projection is arithmetic; upward lifting is ill-posed.

**The negotiation geometry is the safety proof.** The velocity obstacle's safety condition is
`h = λ − β ≥ 0` — and that is already a control barrier function. We do not bolt a safety filter
onto the planner. The planner is written in the filter's own variable.

---

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

---

## 5 · What the judge sees, start to end

| When | On screen | What happens |
|---|---|---|
| **0:00** | Real Meerut street footage, looping. No slides | *"Every self-driving car has one rule: when it's not sure, it stops. On this road, it's never sure"* |
| **1:00** | One number: **3,634 decisions, all giving way** | The problem is documented, not claimed |
| **2:00** | **Screen splits.** Left: MathWorks' planner. Right: ours. Same junction, same traffic, same seed. One slider: **traffic density** | We hand them the mouse |
| **3:00** | Light traffic — both get through. We say out loud: *"here we're no better"* | They keep dragging |
| **3:30** | **The left car stops. And never starts again.** Cars pile up behind it. The right car keeps threading through | **They caused it.** Not a video |
| **4:00** | Overlay on: **GIVE WAY / STAND ON** labels, the collision cone drawn from our car, a safety number `h` staying green, **"0.81"** above the scooter | They see the car *thinking* |
| **5:00** | Cattle scene. A **HORN** button and a **how used to traffic** slider | Low + horn → **the cow bolts.** High + horn → **it doesn't lift its head** |
| **6:00** | Three charts: time-to-enter · success vs density · **performance as sensors degrade** | *"Nobody publishes that third one"* |
| **7:00** | The honest slide: where lane-based methods beat us, no real vehicle, not peer-reviewed | Trust |
| **8:00** | *"One command. Twelve minutes. Re-run every number yourself"* | Close |

**What they remember:** they made a car freeze with their own hand, they honked at a cow and it
ignored them, and we told them where we lose before they had to ask.

---

## 6 · The architecture

```
  drivingScenario API
    unmarked roads · real Meerut geometry via OpenStreetMap · custom zebu mesh
         │
         ▼
  [B] lidar + radar ──► tracker ──► TrackList ─────────────┬────────────┐
         │                                                  │            │
         ▼                                                  ▼            ▼
  [C] FeatureFrame (31 dims, no depth) ◄── project down   [D] assignRoles (COLREGs)
         │                                                              │
         ▼                                                              ▼
  [C] YieldNet (ONNX LSTM) ──► YieldPrediction ──────────► [D] velocityObstacle
                                                             β = asin(dMin/d)
                                                             λ = acos((vᵣ·r)/(|vᵣ|d))
                                                             h = λ − β   ← the barrier
                                                                    │
                                                                    ▼
                                                          bicycle model
                                                                    │
                                    Non-ego Actor Poses input port ◄─┘  (closes the loop)
```

Feeding poses back into that input port **overwrites the programmed waypoints**. That is the
documented fix for open-loop NPCs — no RoadRunner, no external simulator.

### The gap, in one sentence
`mathworks/OpenTrafficLab` resolves a junction with a **TrafficController** — a central authority.
**An Indian junction has no authority.** We delete the controller. It is one method:
`getNextNodeState()`.

### RISK — read this
OpenTrafficLab's `DrivingStrategy` header says, in their own words: *"inherits from a MATLAB class
meant for internal use. It has been tested in MATLAB 2020b, and may not work in future or earlier
releases."* Our licence is R2024b+. **This is the single largest unverified risk in the build.**
Fallback: Scenario Reader → Stateflow → bicycle model with poses fed back through the input port.
Budget two days if it fires.

---

## 7 · THE FROZEN CONTRACT

**This section is frozen.** Five people build against it in parallel. Changing anything here
requires a written reason and a message to everyone. **If your AI agent proposes editing this
section, the answer is no.**

Every arrow in §6 is one of these structs. **If it is not here, it does not cross a module boundary.**

### S1 · TrackList — Perception (B) → everyone downstream

Sensor-agnostic by design. Lidar and radar are fused *before* this struct, so nothing downstream
knows which sensor saw what. Adding a sensor never changes this interface.

| Field | Type | Units | Meaning |
|---|---|---|---|
| `TrackID` | `uint32` | — | Stable across frames. Never reused within a run |
| `ClassID` | `uint8` | — | See S5. `0` = unknown |
| `Position` | `1x3 double` | m | Ego frame: x forward, y left, z up |
| `Velocity` | `1x3 double` | m/s | Same frame |
| `Extent` | `1x3 double` | m | Length, width, height of the fitted box |
| `Yaw` | `double` | rad | Heading in the ego frame |
| `Existence` | `double` | 0–1 | Tracker confidence |
| `Age` | `uint32` | frames | How long this track has lived |
| `SensorMask` | `uint8` | bitfield | bit0 lidar, bit1 radar, bit2 camera |

**Four guarantees B must uphold:**
1. Sorted by ascending `TrackID`
2. Never contains the ego vehicle
3. **May be empty** (`0x1 struct`) — every consumer must handle that without erroring
4. `Position` is finite. No `NaN`, no `Inf`. Drop the track instead

### S2 · FeatureFrame — Features (C) → Predictor (C)

31 dimensions, **depth-free by construction**, so the same builder works on METEOR video and on
simulated tracks projected through a virtual camera.

| Idx | Name | Meaning |
|---|---|---|
| 1–2 | `u_c`, `v_c` | box centre ÷ image size |
| 3 | `v_bottom` | box foot ÷ image height — range proxy on flat road |
| 4–5 | `w`, `h` | box size ÷ image size |
| 6 | `log_aspect` | `log(w/h)` — separates a bus from a scooter without distance |
| 7–9 | `du`, `dv`, `dh` | per-second rates |
| 10 | **`tau`** | **`h / (dh/dt)`** — time-to-contact from pure 2-D expansion. **The feature that makes image-plane learning legitimate.** Clamp to ±100 |
| 11 | `lat_closure` | `d(u − u_ego)/dt` |
| 12–27 | `class_onehot` | 16-way, S5 |
| 28–30 | `ego_speed`, `ego_yawrate`, `ego_accel` | our own state |
| 31 | `cand_action` | the manoeuvre being scored, S6 |

```
FeatureFrame
  .Data       [N x 31 single]   row order matches TrackList
  .Adjacency  [N x N single]    symmetric, 1 if pair within 15 m, diagonal 0
  .TrackIDs   [N x 1 uint32]
  .Timestamp  double            seconds
```

**`Adjacency` is emitted from day one even though the LSTM ignores it.** It makes the
graph-network upgrade a ~60-line change instead of a rewrite. Do not remove it.

**Sequence form:** `[T x 31]` per agent, `T = 20` frames at 10 Hz = 2.0 s. Front-pad with the
earliest frame when a track is younger than T.

### S3 · YieldPrediction — Predictor (C) → Planner (D)

```
.TrackIDs  [N x 1 uint32]
.PYield    [N x 1 double]   probability in [0,1] that this agent yields to us
.Valid     [N x 1 logical]  false when the track is younger than T frames
```

**When `Valid(i)` is false, the planner falls back to the geometric role alone.** It must never
treat an invalid prediction as 0.5.

### S4 · Role and EgoCommand — Planner (D)

```
Role                          EgoCommand
  .TrackID  uint32              .Accel      double  m/s²,  [-6, +3]
  .Role     uint8  (S7)         .SteerAngle double  rad,   [-0.6, +0.6]
  .Beta     double  rad         .Mode       uint8   (S8)
  .Lambda   double  rad         .Reason     string  one short line, for the log
  .TCPA     double  s
```

`Beta` and `Lambda` are the velocity-obstacle quantities: `β = asin(dMin/d)`,
`λ = acos((vᵣ·r)/(‖vᵣ‖d))`. **Collision iff `λ < β`.** Log both every step — `h = λ − β` is our
barrier function and our safety evidence.

### S5 · ClassID — the one table everybody uses

**Never renumber.**

| ID | Class | | ID | Class |
|---|---|---|---|---|
| 0 | unknown | | 8 | pedestrian |
| 1 | car | | 9 | bicycle |
| 2 | truck | | 10 | **cow / cattle** |
| 3 | bus | | 11 | dog |
| 4 | **auto-rickshaw** | | 12 | **pushcart** |
| 5 | motorbike | | 13 | **animal-drawn cart** |
| 6 | scooter | | 14 | tractor |
| 7 | van | | 15 | static obstacle |

MATLAB's `drivingScenario` reserves its own ClassIDs 1–6. Use `sih.util.toSimClassID()`.
**Never hardcode either numbering** — a literal class number anywhere in the code is a bug.

### S6 · Candidate actions (feature 31)

| Value | Meaning |
|---|---|
| 0.0 | hold speed |
| 1.0 | accelerate / commit to cross |
| −1.0 | decelerate / give way |
| 0.5 | creep forward (the probe manoeuvre) |

### S7 · Role codes

| Value | Role | Duty |
|---|---|---|
| 0 | `SAFE` | no action; `tCPA < 0`, opening |
| 1 | `GIVE_WAY` | early, substantial action. Pass astern |
| 2 | `STAND_ON` | **hold course and speed** |
| 3 | `HEAD_ON` | both alter to the same side |
| 4 | `OVERTAKING` | keep clear of the overtaken agent |

Sector boundaries are **22.5°, 90°, 112.5°**. The sign of `tCPA` disambiguates closing from opening.

### S8 · Planner mode

| Value | Mode | When |
|---|---|---|
| 0 | `STRUCTURED` | lane markings detected — defer to baseline-style planning |
| 1 | `UNSTRUCTURED` | no usable lane structure — our negotiation planner |
| 2 | `EMERGENCY` | barrier violated, `h < 0` |

Mode 0 exists because **we do not claim a win on the highway merge.**
*"Our planner knows when it isn't needed."*

### File formats — frozen

| What | Path | Format |
|---|---|---|
| Trajectories for Blender | `results/<run>/trajectories.csv` | `t,actor_id,class_id,x,y,z,yaw` — SI units, header row |
| Metrics per run | `results/<run>/metrics.json` | keys are metric IDs `M1`–`M10` |
| Run config | `results/<run>/config.json` | **a copy of the inputs. A number without its config is not a result** |
| Model | `python/export/yield_lstm_opset<N>.onnx` | input `sequence` `[1,20,31]`, output `yield_logits` `[1,2]` |

### Contract change log

| Date | Change | Reason |
|---|---|---|
| 2026-08-30 | Initial freeze, S1–S8 | Architecture locked |
| 2026-08-30 | S1: added `SensorMask`; radar declared a fused in-loop source | The PS names "camera, LiDAR, and radar". Radar was missing — an unforced gap |

**Two reconciliations left open on purpose.** OpenTrafficLab defaults `AccBounds` to `[-5, 3]`;
ours is `[-6, +3]` — Stream D decides at integration and records it. And ClassID conversion must
always go through the helper, never a literal.

---

## 8 · How we measure

Ten metrics, **fixed before any run** so nobody can say we picked them to flatter the result.

### The standard, and why it is not enough

CARLA's leaderboard is the reference: `Driving Score = Route Completion × Infraction Penalty`,
where `Penalty = 1 / (1 + Σ cⱼ × nⱼ)`. Coefficients: pedestrian collision **1.00**, vehicle
**0.70**, static **0.60**, red light **0.40**, timeout **0.40**, min-speed failure **up to 0.40**.

We must correct ourselves in public on one point. We once said no standard metric punishes a
frozen car. **It does.** But:

> "Agent blocked — if an agent doesn't take any actions for **180 simulation seconds**."

**Three minutes.** A car stuck twenty seconds at an Indian junction has already failed, and CARLA
registers nothing. The honest claim is that **the standard metric's resolution is about an order of
magnitude too coarse** — not that no metric exists. Always use that phrasing.

### Ours

| ID | Metric | Exact definition |
|---|---|---|
| **M1** | **Time-to-enter** | Seconds from the ego first coming within 5 m of the junction entry line to its front axle crossing it. **The headline number** |
| **M2** | **Completion vs density** | Fraction of runs reaching the goal in time, swept across agents per 100 m² |
| **M3** | **Perception-degradation curve** | M2 re-measured under injected position error, dropout, and false positives — each swept independently |
| M4 | Weighted infractions | **CARLA's own coefficients**, with animals at the pedestrian weight of 1.00 |
| M5 | Minimum TTC | Smallest time-to-collision, per agent class |
| M6 | Replanning latency | ms per planning cycle: mean, p95, max. *PS requires this* |
| M7 | Path smoothness | Integral of squared lateral jerk + peak lateral acceleration. *PS requires this* |
| **M8** | **Yield ledger** | Every negotiation logged: predicted vs actual yield. Precision and recall **in closed loop**, not on a held-out set |
| M9 | Deadlock rate | Both parties below 0.5 m/s for more than 3 s |
| M10 | Role churn | Give-way ↔ stand-on flips per encounter. **Rule 8 forbids "a series of small alterations"** |

**Three rules.** M1–M3 are the result; the rest guard against winning the wrong way. **M4 and M5
must not regress against the baseline** — a faster but less safe car is a failed project and we
report it as one. One command regenerates every number; an unreproducible number never reaches a
slide.

### The baseline is sacred

**"Motion Planning in Urban Environments Using Dynamic Occupancy Grid Map"** — MathWorks' shipped
example, **completely unmodified**, in `matlab/baseline/`. **Never edit anything in that folder.**

We picked their *strongest* relevant planner: six lidars, urban intersection, pedestrians and
bicyclists, `trackerGridRFS`. It fails at an unmarked junction for a **structural** reason — it
requires `referencePathFrenet`, Cartesian waypoints defining a path, and an unsignalled junction
supplies none. Its cost function has no term for progress through a contested junction.

That distinction — structural failure, not tuned failure — is the difference between a result and
a strawman.

---

## 9 · Every claim, and what backs it

**If a claim is not in this table, it does not go on a slide, in the report, or in the repo.**

Three states: **VERIFIED** (primary source or measured by us — safe to say) · **NOT YET RUN**
(our own number; the run is named; never state it until run) · **CORRECTED** (we believed
something false; recorded so we never say it again).

### VERIFIED — the problem and the competition

| Claim | Source |
|---|---|
| IDD-X has **3,634 scenarios and every one is the car giving way** | IDD-X paper, arXiv 2404.08561 |
| METEOR's authors measured that models good on **Waymo fail on METEOR** | arXiv 2109.07648 |
| **3,383** stray-cattle accidents in 5 yrs, **919** dead, **3,017** injured | Haryana Assembly reply |
| **5,021,587** stray cattle in India | Livestock census |
| A cow at 9.2 m is **77 × 63 px** in a 140° dashcam frame — 3.98% of frame width | **Measured by us** |
| **B-GAP**: pedestrians, bicycles, intersections all "future work"; needs "very good sensing"; admits it acts "conservatively" | Their paper |
| **GameOpt+**: "assumes connected autonomous vehicles equipped with **V2I communication**" | Their paper |
| **GamePlan**: demonstrated with **2–3 vehicles** | Their paper |
| **TwinX used RoadRunner only as an export target** — no RoadRunner workflow described | MathWorks Student Lounge, 6 Apr 2026 |
| IIT-Madras hackathon: **47 teams, all three winners built detect-and-warn.** Not one built a planner | Event results |

### VERIFIED — toolchain

| Claim | Source |
|---|---|
| `roadNetwork(scenario,'OpenStreetMap',f)` imports real geometry free | mathworks.com |
| Automated Driving Toolbox runs on **Apple Silicon macOS** | mathworks.com |
| Unreal co-sim is **Windows/Linux only**, needs **8 GB VRAM + 32 GB RAM** | mathworks.com |
| RoadRunner is **not in the student licence**; Windows/Linux only | MATLAB Answers |
| `importNetworkFromONNX` lacks Gather/Scatter → **GNNs cannot import** | mathworks.com |
| **OpenTrafficLab's `DrivingStrategy` "tested in MATLAB 2020b, may not work in future releases"** | **Their own header** |
| `lanespec` is lowercase; `laneSpec` does not exist | MATLAB docs |
| CARLA's agent-blocked threshold is **180 simulation seconds** | leaderboard.carla.org |

### CORRECTED — do not repeat these

| We said | Truth |
|---|---|
| ~~"AIS-189/190 mandate ADAS in India"~~ | **Wrong.** AIS-189 is a *Cyber Security Management System*; AIS-190 is a *Software Update Management System*. **The ADAS mandate is MoRTH GSR 184(E)**, in force **1 Apr 2026** for buses and trucks — AIS-162/184/186/187/188. This matters: our users are ARAI and ICAT, who wrote them |
| ~~"No standard metric punishes a frozen car"~~ | **Wrong.** CARLA does — but at **180 s**, which is ~an order of magnitude too coarse for us. Say that instead |

### NOT YET RUN — never state these until the named run produces them

| Claim | Produced by |
|---|---|
| Lidar returns come off a custom cow mesh | `derisk/check02_lidar_cow.m` |
| **OpenTrafficLab runs on our MATLAB release** | `derisk/check05_opentrafficlab.m` — **highest risk** |
| Which ONNX opset MATLAB accepts | `python/export/to_onnx.py` + `check04` |
| **METEOR labels attach per-agent or ego-only** | Open one dynamic XML — Stream C task C2 |
| M1–M10, every one | `runExperiment` |
| Yield predictor precision / recall | Stream C training |

### Phrasing rules

- **"No public work we could find"** — never "this has never been done"
- Never "approximately" where a measured value belongs. Write `TODO(unverified)` instead
- Name the closest competitor and the closest patent **on our own slide**, before a judge does

---

## 10 · The phases

| Phase | Status |
|---|---|
| 0 · Unblock | **OPEN** |
| 1 · Research | ✅ complete |
| 2 · Architecture + contract | ✅ complete |
| 3 · Idea locked | ✅ complete |
| 4 · Build | blocked on 0 |
| 5 · Evidence + report | blocked on 4 |

**Phase 0 — blocks everything.** MATLAB + 7 products on a Windows machine · run `derisk/` checks
0–5 · DGX disk, internet and booking · email the licence admin about RoadRunner.
**Gate:** check 2 passes — lidar returns off the cow mesh.

**Phase 4 — build.** Scenarios 1 and 2 perfected, then perception, prediction, planner, baseline,
experiment runner, then scenarios 3–5.
**Gate:** scenarios 1 and 2 run clean end to end, five times consecutively.

**Phase 5 — evidence.** The three curves, then M4–M10, then the **interactive demo** (density
slider, reasoning overlay, honk button), the **technical report**, the video, and the public release.
**Gate on the demo:** built only after the curves exist. A GUI over a planner that does not
negotiate is the "beautiful scenes, weak planner" tier — and TwinX already won with that move, so
it will not win twice.

---

## 11 · The team

Five streams, plus Aditya on visuals. Deliberately independent, because §7 is frozen.

| Stream | Owns | File |
|---|---|---|
| **A** | Scenarios, roads, junctions | `teammates/A-world.md` |
| **B** | Lidar, radar, tracking | `teammates/B-perception.md` |
| **C** | METEOR, LSTM, training | `teammates/C-prediction.md` |
| **D** | COLREGs planner, Stateflow | `teammates/D-planner.md` |
| **E** | Baseline, metrics, experiments | `teammates/E-evidence.md` |
| **F** | Blender, renders, demo | Aditya |

### Who needs what from whom

```
A ──scenario──► B ──TrackList──► C ──opset number──► D
│                │                                    │
│                └──TrackList────────────────────────►│
└─────────────────────────────────────────────────────┤
                                                      ▼
                                    E ──trajectories.csv──► F
```

| ID | From → To | What crosses |
|---|---|---|
| **H1** | A → B | A working scenario with actors |
| **H2** | B → C, D | `TrackList` (S1) |
| **H3** | **C → D** | **Which ONNX opset MATLAB accepts.** One number. Gates all in-loop integration |
| H4 | C → D | The trained `.onnx` file |
| H5 | A,B,C,D → E | A pipeline that runs end to end |
| H6 | E → F | `results/<run>/trajectories.csv` |

---

## 12 · Tech stack

| Layer | Tool |
|---|---|
| Scenarios, planner, simulation | MATLAB R2024b+ / Simulink / Stateflow |
| Toolboxes | Automated Driving · Computer Vision · Image Processing · Deep Learning · Sensor Fusion & Tracking · Navigation · Lidar · Stateflow |
| Data pipeline, training | Python 3.11 · PyTorch · ONNX · the DGX A100 (8 × 40 GB) |
| Model in the loop | ONNX → `importNetworkFromONNX` → Simulink **Predict** block |
| Rendering | Blender 4.x, Cycles |
| **No RoadRunner** | `drivingScenario` + OpenStreetMap + OpenDRIVE export |

### The model pipeline, end to end

```
METEOR video + XML  →  parse  →  per-agent box tracks
                    →  features (31 dims, no depth)  [python/meteor/features.py]
                    →  train LSTM  [DGX, 8× A100]    [python/model/yield_lstm.py]
                    →  export ONNX                    [python/export/to_onnx.py]
                    →  importNetworkFromONNX          [MATLAB]
                    →  Simulink Predict block         → P(yield) per agent, every step
```

MATLAB opset support: **R2024b = 6–18; R2025a+ = 6–20.** Use the **Predict** block (supports code
generation), not ONNX Model Predict (simulation-only).

**Do not import YOLO** — NMS unsupported, dynamic shapes fail. Use MATLAB's built-in YOLOX.

### The supercomputer

Used for exactly two things: **downloading METEOR** and **training**.

METEOR is **93.4 GB** in five chunks and needs **~190 GB free at peak** (chunks + reassembled zip
before extraction). **`gamma.umd.edu/meteor` is dead — the HuggingFace mirror is the only live
route.** If it disappears, the yield-predictor plan dies with it.

```bash
huggingface-cli download XijunWang/METEOR --repo-type dataset --local-dir ./meteor
cd meteor && cat chunk_* > METEOR_Dataset.zip && unzip METEOR_Dataset.zip && rm chunk_*
```

Run inside `tmux`. Six questions to answer first: free disk (`df -h`), per-user quota
(`quota -s`), **does the compute node have internet** (`curl -I https://huggingface.co` from a
compute node), how to book GPU time, who approves accounts, and can we `pip install --user`.

---

## 13 · The five rules

1. **Never edit `matlab/baseline/`.** A tuned baseline is a strawman and kills the result.
2. **Never invent a number.** If it is not in §9, it does not go on a slide.
3. **Never change §7** without a changelog row and telling everyone.
4. **Nothing ships with a bug already reproduced in the demo flow.** We lost a hackathon that way.
5. **Errors are reported in full.** Never a summary. A trimmed stack trace costs a day.
