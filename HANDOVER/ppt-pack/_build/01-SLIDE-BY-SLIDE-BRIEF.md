
# Six-slide brief

Use the **official six-slide template and its headings**. The PDF is the idea-round upload. Bold text below is slide copy. Label proposed capabilities **PLANNED**; label the existing prototype **PARTIAL**. Use no survey, invented prototype URL, unsourced cost percentage, or projected lives saved. Reference IDs point to DOC 3. [P0](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md)

## Slide 1 — Title

**Layout:** Follow the reference title fields. Put the idea title in the largest type and the child line below it.

| Field | Exact text |
|---|---|
| Problem statement ID | **SIH26037** |
| Idea title | **Safety-Checked Adaptive Path Planning for Unstructured Indian Roads** |
| Theme | **Smart Vehicles** |
| Category | **Software** |
| Team ID | **[TEAM ID]** |
| Team name | **[TEAM NAME]** |
| One-line idea | **The car watches and listens, guesses what might move, and drives only when it has room to stop.** |

**Limit:** Title ≤10 words (uses the PS's own keywords); one-line idea as written. Source: R01.

## Slide 2 — Proposed Solution

**Layout:** Left solution bullets; central hub **D1**; right “It addresses the problem by”; narrow platform strip and tagline below. Mark D1 **PLANNED SYSTEM**.

**Left column — copy verbatim; max 45 words**

- **One car, one loop:** sense → understand → decide → act → prove.
- **Mixed traffic:** detect autos, pushcarts, pedestrians, animals and uncertain road edges.
- **Several futures:** predict short-term, non-lane-based movement.
- **Only checked moves:** brake and report **BLOCKED** when no safe move passes.

**D1 central hub — max 38 label words:** One idea contains these five layers and **13 named parts**. Group them into roughly ten visual bubbles without dropping a part:

| Layer | Parts |
|---|---|
| **SENSE** | Sensors |
| **UNDERSTAND** | Perception ML; Hearing; Gesture reader; Tracker; Prediction ML |
| **DECIDE** | Planner; Safety checker; Safety monitor |
| **ACT** | Control; Signals & driver screen |
| **PROVE** | World; Test & learn loop |

**Right column — copy verbatim; max 43 words**

- **No lane markings:** check road, shoulder and unknown space.
- **Informal merging:** consider yielding and non-yielding responses.
- **Sudden movement:** reserve space for crossing people and cattle.
- **Unexpected obstacles:** preserve a visible stopping path.
- **Closed loop:** the car’s action changes the next traffic scene.

**Platform strip — max 19 words:** **MATLAB/Simulink ego stack · SUMO reactive traffic · CARLA 0.9.15 Indian scenes · real Indian video replay**

**Tagline — max 13 words:** **Learning ranks moves. An independent physical check alone permits movement.**

Source: R01; [P13](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md).

## Slide 3 — Technical Approach

**Layout:** Top expert line; left tech-stack logo wall grouped by the five layers; **D2** centre; **D3** right; prototype strip at bottom. Use a clear **PLANNED** label over the joined pipeline.

**Top line — exact:** **One Simulink ego stack combines Indian-road sensing and prediction with a learned manoeuvre scorer, an independent movement verifier, and measured closed-loop tests.**

**Tech-stack wall — max 52 words total**

- **SENSE:** CARLA camera/LiDAR/radar; Automated Driving Toolbox.
- **UNDERSTAND:** Python/PyTorch → ONNX → Deep Learning Toolbox; `trackerGNN`.
- **DECIDE:** Navigation Toolbox; Stateflow; MATLAB Coder.
- **ACT:** Simulink control; Vehicle Dynamics Blockset.
- **PROVE:** `drivingScenario`; official R2026a SUMO blocks; CARLA scene replay.

**D2:** One decision: **observe → track/predict → rank 8–16 moves → check swept space and stopping distance → drive or brake**. Show the safety monitor’s veto arrow. Max 24 words inside the diagram.

**D3:** Label **“Five-model target core; nine later models”**, never “14 models running.” Exact model labels:

- **Core target:** YOLOX object detector; DeepLab v3+ road/pothole mask; pose-based hand-signal reader; ego-conditioned top-K motion predictor with conformal coverage; move scorer.
- **Later tier:** lidar 3D detector; BEV free-space/occupancy; sign and Indian-text reader; siren/horn recogniser; visibility estimator; driver watcher; crossing-intent model; RL policy **comparison only**; learned traffic agents.

YOLOX and DeepLab exist **offline**; the other core models and the joined loop are **planned**. No AI model can move the car without the verifier. [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md), [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)

**Prototype strip — max 22 words:** **PARTIAL today:** internal `sihDemo` runs S1 and sparse S3. **Public prototype link:** [INSERT VERIFIED URL AFTER UPLOAD].

Source: R01, R20–R28; [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md).

## Slide 4 — Feasibility and Viability

**Layout:** Four boxes as in the reference: Financials, Feasibility, Viability, Challenges → Mitigation. Put **D5** as a compact bottom timeline. Use the **cost component of D7** in Financials.

**Financials — max 29 words:** **Software ₹0** (KIET MATLAB licence; open-source CARLA, SUMO). **Training ₹0** on KIET DGX A100. Backup cloud A100 **~$0.43–1.09/GPU-hour** (GetDeploying, Thunder Compute, Sep 2026).

**D7 graphic:** use D7's cash-cost table (sourced) and its effort-split pie, labelled **“planned effort split”** — never as a cost pie.

**Feasibility — max 32 words:** **Two builders, ten-week plan.** W2 gates: 100 ms fast-tier planning and one custom prop plus vehicle spawning. W8 gate: five scenes and full camera-in-loop timing.

**Viability — max 30 words:** **Real starting point (PARTIAL):** MATLAB planner completes S1 (610 m); **348/348** automated tests; real-map pipeline; offline Indian road mask **96.0% drivable IoU**. Open failures are disclosed in Q&A (DOC 4), not on the slide.

**Challenges → Mitigation — max 11 words per row**

| Challenge | Mitigation |
|---|---|
| **Slow checking** | Profile, reduce candidates, compile and retest full-loop timing. |
| **CARLA assets** | Start source build W1; prove prop and vehicle W2. |
| **Render-to-real gap** | Measure per-class recall on held-out renders and Indian footage. |

**D5:** Ten weekly gates; distinguish A’s brain/safety/evaluation track from S’s world/assets/perception track. Add a red caption: **“Two detailed CARLA scenes replace specified RoadRunner scenes; no RoadRunner licence.”**

Source: [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md), [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md), R27–R28.

## Slide 5 — Impact and Benefits

**Layout:** Stakeholders left; large sourced problem numbers centre; **D4** five-scenario strip right; **D6** coverage/beyond panel at bottom. Numbers describe the **problem**, not an impact achieved by this proposal.

**Stakeholders — max 24 words**

- **Road users:** safer decisions are the research goal.
- **ADAS and AV teams:** reproducible Indian-road stress tests.
- **Researchers and judges:** contact, progress, comfort and timing evidence.

**Large numbers — exact labels**

- **4,80,583 crashes · 1,72,890 deaths — India, 2023.** R03
- **2,161 pothole-related deaths — India, 2023.** R03
- **3,383 stray-cattle crashes — Haryana, preceding five years.** R04
- Small footnote: **50 lakh stray cattle — 2019 livestock census; not a road-encounter rate.** R05

**D4:** Exact PS scenes: **unmarked village road; unsignalled urban intersection; highway merge with slow vehicles; dense market; sudden cattle crossing**. Label **PLANNED CLOSED-LOOP TESTS**.

**D6 — max 31 words:** **90 difficulties catalogued → ten composable families → 25 priority probes.** Planned proof: **replanning latency, path smoothness, scenario completion rate**, plus contacts and false stalls. **RoadRunner substitution remains a deviation.**

Optional small behaviour note, if legible: **“Patna sample: 26% rolling crossings; site-specific, not a national rate.”** R06. Do not claim an estimated crash reduction.

Source: R01, R03–R06; [P1](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md).

## Slide 6 — Research and References

**Layout:** Left: short reference list; right: **D7 competitor component**; bottom: dataset ribbon, prototype placeholder and RoadRunner disclosure. Keep the official “Research and References” heading.

**Visible references — max 65 words:** **MoRTH 2023; Haryana Assembly cattle answer; IDD; IDD-PeD; METEOR; Kruse et al. 2022; Mosaic 2026; MathWorks SUMO/CARLA documentation.** Use small `[Rxx]` tags linked to DOC 3.

**D7 competitor table:** Use **✓ documented**, **P proposed**, **? unverified**. Do not use × to assert an undocumented absence.

| Organisation | Indian traffic/scenario work | Independent movement checker | Paired Indian closed-loop metrics |
|---|:---:|:---:|:---:|
| **Our system** | ✓ catalogue; P executable suite | P | P |
| **The Syndicate*** | ? | ? | ? |
| **ARAI** | ✓ | ? | ? |
| **WMG Safety Pool India** | ✓ | ? | ? |
| **Swaayatt Robots** | ✓ company-described work | ? | ? |
| **Minus Zero** | ✓ company-described work | ? | ? |

\*Teammate-supplied description says stock CARLA, YOLOv11 + LiDAR, a three-tier planner and three scenes; **independent evidence was not found in the research pack**. Do not convert that description into ticks or crosses. ARAI and WMG already have Indian scenario work; do not claim “first Indian test suite.” [P1](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md), [P3](/Users/aditya/dev/sih2026-hq/research/P3-PLANNER.md)

**Dataset ribbon — max 22 words:** **IDD family · DriveIndia · FGVD · TIAND · METEOR · Chennai SPT · RoadText · simulator data**. Access and licences are checked before training.

**Bottom disclosure — exact:** **RoadRunner is unavailable: two planned detailed CARLA scenes substitute for, but do not literally meet, that PS clause.**

**Prototype link:** [INSERT VERIFIED PUBLIC URL]; otherwise print **“Internal prototype available on request”**. Source: R01, R09–R19, R29–R32.

## Keyword glossary — team use only

| Term | Plain meaning |
|---|---|
| **Adaptive path planning** | Reconsidering the car’s path as the scene changes. |
| **Unstructured Indian road conditions** | Roads and traffic where lanes, edges and behaviour may be irregular. |
| **Multi-sensor** | Combining camera, LiDAR, radar and vehicle-state measurements. |
| **LiDAR** | Laser distance measurements that give obstacle shape and location. |
| **Radar** | Radio sensing that helps measure distance and closing speed. |
| **Perception ML** | Models that find road users, road surface and hazards. |
| **Hearing** | In this plan, simulated horn/siren direction and class events. |
| **Gesture reader** | Camera pose cues for raised hands and traffic direction. |
| **Tracker** | A continuing position and uncertainty record for each observed actor. |
| **Short-term motion prediction** | Possible actor positions over the next few seconds. |
| **Ego-conditioned** | Forecasting an actor given a proposed action by our car. |
| **Non-lane-based movement** | Sideways or crossing motion that does not follow a lane centre. |
| **Conformal coverage** | A calibrated method for sizing predicted occupied regions. |
| **Learned manoeuvre scorer** | A model that ranks a fixed set of candidate moves. |
| **Independent movement verifier** | A separate geometric and braking check that alone permits motion. |
| **Safety monitor** | A watchdog that cancels permission when data or control is faulty. |
| **BLOCKED** | An explicit state when no checked move exists. |
| **Real-time replanning** | Meeting a measured decision deadline while driving. |
| **Closed-loop validation** | The car acts, traffic responds, sensors update, and the next decision uses that update. |
| **Replanning latency** | Time from a scene snapshot to a checked replacement path. |
| **Path smoothness** | How sharply the driven path bends or acceleration changes. |
| **Scenario completion rate** | Share of runs that reach the goal under the declared rules. |
| **ODD** | The roads, speeds, weather and traffic conditions within which the system is tested. |

