=====DOC 1: 01-SLIDE-BY-SLIDE-BRIEF.md=====

# Six-slide brief

Use the **official six-slide template and its headings**. The PDF is the idea-round upload. Bold text below is slide copy. Label proposed capabilities **PLANNED**; label the existing prototype **PARTIAL**. Use no survey, invented prototype URL, unsourced cost percentage, or projected lives saved. Reference IDs point to DOC 3. [P0](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md)

## Slide 1 — Title

**Layout:** Follow the reference title fields. Put the idea title in the largest type and the child line below it.

| Field | Exact text |
|---|---|
| Problem statement ID | **SIH26037** |
| Idea title | **Safety-Checked Adaptive Driving on Indian Roads** |
| Theme | **Smart Vehicles** |
| Category | **Software** |
| Team ID | **[TEAM ID]** |
| Team name | **[TEAM NAME]** |
| One-line idea | **The car watches and listens, guesses what might move, and drives only when it has room to stop.** |

**Limit:** Title ≤9 words; one-line idea as written. Source: R01.

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

**Financials — max 29 words:** **Existing route:** KIET DGX A100 for training; Mac M1 for fast tests; Windows 8 GB GPU PC for CARLA. **Cloud A100, assets and storage: cost to confirm.**

**D7 cost graphic:** Show cost *categories* with **“quotes pending”**. Do **not** draw proportional slices or print a total until prices and machine access are confirmed.

**Feasibility — max 32 words:** **Two builders, ten-week plan.** W2 gates: 100 ms fast-tier planning and one custom prop plus vehicle spawning. W8 gate: five scenes and full camera-in-loop timing.

**Viability — max 30 words:** **Real starting point:** 348/348 existing tests; S1 completes 610 m. **Open failures:** S2/dense S3 stall; planner takes 735.8 ms/step; camera gives zero render boxes.

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

=====DOC 2: 02-NUMBERS-AND-CLAIMS.md=====

# Numbers and claims ledger

**Rule:** Carry the qualifier with the number. National crash counts, one-city behaviour samples, today’s prototype measurements, and future design targets are different kinds of evidence. No cloud price, hardware bill, cost-pie percentage, or crash-reduction estimate is established. [P14](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md)

| Number | Meaning and required qualifier | Source link | Slide |
|---|---|---|---|
| **SIH26037; 30 Sep 2026** | PS ID and idea-submission deadline | [Official PS](https://www.sih.gov.in/sih2026PS), [P0](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md) | 1 |
| **Six slides** | Official maximum, including title | [P0 template audit](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md) | Pack rule |
| **4,80,583; 1,72,890** | India road crashes and deaths in **2023**; problem scale, not our impact | [MoRTH, *Road Accidents in India 2023*](https://morth.nic.in/sites/default/files/Road-Accident-in-India-2023-Publications.pdf) | 5 |
| **5,840; 2,161** | Pothole-related crashes and deaths in **2023** | [MoRTH](https://morth.nic.in/sites/default/files/Road-Accident-in-India-2023-Publications.pdf), [P1](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md) | 5; 5,840 optional |
| **25,242; 9,432; 5.46%** | Crashes, deaths and death share in **combined wrong-side/lane-indiscipline** category; never call it a wrong-way-only rate | [MoRTH Table 3.1](https://morth.nic.in/sites/default/files/Road-Accident-in-India-2023-Publications.pdf), [P16](/Users/aditya/dev/sih2026-hq/research/P16-INDIAN-TRAFFIC-NUMBERS.md) | Optional |
| **3,383; 919** | Stray-cattle crashes and deaths in **Haryana over the preceding five years**, not all India | [Haryana Assembly answer](https://haryanaassembly.gov.in/wp-content/uploads/2023/01/14_13_US_1262_V4_signed.pdf) | 5; deaths optional |
| **50 lakh; 2019** | India stray-cattle count in the livestock census; not road encounters | [PIB livestock-census answer](https://www.pib.gov.in/PressReleasePage.aspx?PRID=1813802) | 5 |
| **722; 26%; 54.8%** | Interactions, rolling crossings and group crossings at **three Patna sites**; site sample only | [Suman et al., *Scientific Reports*, 2026](https://www.nature.com/articles/s41598-026-55112-9) | 5 optional |
| **0.906 m** | Observed **mean squeeze-through gap** in a filtered two-wheeler sample; not a safe-clearance rule | [P16 source and qualifier](/Users/aditya/dev/sih2026-hq/research/P16-INDIAN-TRAFFIC-NUMBERS.md), [study](https://www.sciencedirect.com/science/article/pii/S1389128626005220) | Optional |
| **Five scenarios; two RoadRunner scenes** | Literal PS counts. The RoadRunner count is **not met** by the proposed substitute | [Official PS](https://www.sih.gov.in/sih2026PS) | 4–6 |
| **Two CARLA scenes** | **Planned substitutes**, village and junction; never label RoadRunner | [P13](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md), [P14](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md) | 4, 6 |
| **Five layers; 13 parts** | Proposed architecture count, not built-function count | [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md), user design brief | 2 |
| **14 models = five core + nine later** | **Design inventory**; two core models exist offline, joined AI stack is not running | User design brief; [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | 3 |
| **8–16 moves; 2–3 s futures** | Planned bounded candidate count and prediction horizon | [P13](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md), [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md) | 3 |
| **90 difficulties; ten families; top 25** | **Catalogue built**; executable suite and passes are planned | [P1](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md) | 5 |
| **Two builders; ten weeks** | Planning assumption from 1 Oct to early December; exact finale date unverified | [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md), [P0](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md) | 4 |
| **10 Hz; 100 ms** | **Target** replanning cadence/deadline, not achieved today | [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md) | 4 |
| **735.8 ms/step; 88%** | Current measured planner step; share spent in capsule-list checking | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | 4 |
| **348/348** | Existing tests passing; they do **not** establish PS completion | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | 4 |
| **610 m; 382 m** | Current S1 and sparse S3 completion distances in 2D demo | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | 4; 382 optional |
| **Two of five** | Current working demos, S1 and sparse S3; **not** five PS-scenario validations | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md), [P14](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md) | 4 optional |
| **Zero render boxes** | YOLOX output at its default threshold on audited renders; not zero objects present | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | 4 |
| **38.2%; 16.3%** | Offline YOLOX AP for auto and cow respectively; neither is in-loop recall | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | Q&A |
| **2.089% vs ≤1%** | Current yield model dangerous-error and its internal gate; output is disabled | [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md) | Q&A |
| **165 GB; 4 h+; 8 GB; 400 GB** | CARLA Windows source-build disk/time, lab GPU, and packaged-prop Docker-image cost in storage; **not** a cash estimate | [CARLA Windows build](https://carla.readthedocs.io/en/0.9.15/build_windows/), [CARLA props](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_props/) | 4; some optional |
| **R2026a; CARLA 0.9.15** | Pinned proposed MathWorks/SUMO and CARLA tool versions | [P13 correction](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md), [MathWorks SUMO Client](https://www.mathworks.com/help/driving/ref/client.html) | 2–4 |
| **299; 95%; <1%** | Only **299 independent zero-failure runs from one specified distribution** justify that one-sided confidence bound; not an Indian-road safety rate | [P14](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md), [P9–P12](/Users/aditya/dev/sih2026-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md) | Q&A only |
| **Cloud A100 price: to confirm** | No sourced rental quote in research; print no rupee/hour figure or cost pie shares | [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md) | 4 |

## Claims ledger

| SAY — evidenced today | SAY ONLY AS **PLANNED** | NEVER SAY |
|---|---|---|
| “Our MATLAB 2D demo completes S1 and sparse S3.” | “One Simulink ego stack will join sensing through vehicle motion.” | “The complete system already drives Indian roads.” |
| “Simulated lidar/radar tracking and offline YOLOX/DeepLab models exist.” | “A learned scorer will rank moves; an independent checker alone will permit motion.” | “ML drives the car” or “the verifier guarantees public-road safety.” |
| “The S1 route reached 610 m; 348/348 existing tests pass.” | “We will test all five PS scenarios, 25 priority probes and three PS metrics.” | “All five PS scenarios pass today.” |
| “The present loop takes 735.8 ms/step and S2/dense S3 stall.” | “10 Hz is a measured **target**, with a stale-plan brake.” | “Real-time today.” |
| “RoadRunner is unavailable under our licence.” | “Two detailed CARLA scenes will substitute for RoadRunner.” | “Two RoadRunner scenes” or “MathWorks approved the substitution.” |
| “ARAI and WMG already document Indian scenario work.” | “A reproducible Indian closed-loop benchmark may be a measured contribution after paired tests.” | “First Indian test suite” or “competitors have no safety checker” without evidence. |
| “Real Indian footage can test perception open loop.” | “Real-versus-render recall and a held-out gap will be reported.” | “Real-footage replay proves autonomous driving safety.” |
| “AI stack has a five-model target core and nine later candidates.” | “Additional models depend on data, time and measured value.” | “Fourteen AI models are built or run together today.” |

Source: [P14 claims audit](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md). **No projected reduction in crashes or deaths is supportable.**

=====DOC 3: 03-REFERENCES.md=====

# References

Use **R01, R03–R06, R09, R13, R17, R20 and R22** as the short visible slide-6 list; this document is the linked backup. The titles below link to sources already used in the research files. “n.d.” means the linked page does not establish a publication year.

## Problem statement and Indian road safety data

- **R01.** Smart India Hackathon / MathWorks, “SIH26037 problem statement,” official PS page, 2026. [Link](https://www.sih.gov.in/sih2026PS).
- **R02.** Ministry of Education Innovation Cell, “SIH 2026 Guidelines,” competition guide, 2026. [College-hosted copy](https://sih-uit.vercel.app/assets/sih-2026-guidelines.pdf). Its printed September date is stale; use the live PS deadline in R01. [P0 check](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md).
- **R03.** Ministry of Road Transport & Highways, *Road Accidents in India 2023*, Government of India report, 2023 data. [Link](https://morth.nic.in/sites/default/files/Road-Accident-in-India-2023-Publications.pdf).
- **R04.** Haryana Legislative Assembly, “To solve the problem of Stray Cattle,” Assembly answer, n.d. [Link](https://haryanaassembly.gov.in/wp-content/uploads/2023/01/14_13_US_1262_V4_signed.pdf). The answer reports the preceding five years; its exact answer date was not established in P1.
- **R05.** Ministry of Fisheries, Animal Husbandry & Dairying / PIB, “Livestock Census,” Lok Sabha reply, 2022, reporting the 2019 census. [Link](https://www.pib.gov.in/PressReleasePage.aspx?PRID=1813802).

## Indian traffic behaviour

- **R06.** Suman, Mondal and Lokesh, “Assessment of pedestrian safety margins at unsignalized mid block crossings in Patna,” *Scientific Reports*, 2026. [Link](https://www.nature.com/articles/s41598-026-55112-9).
- **R07.** Sahu, Parganiha and Pati, “A population estimation study reveals a staggeringly high number of cattle on the streets of urban Raipur in India,” *PLOS ONE*, 2021. [Link](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0234594).
- **R08.** Mohan and Chandra, “Investigating the influence of conflicting flow’s composition on critical gap under heterogeneous traffic conditions,” *International Journal of Transportation Science and Technology*, 2021. [Link](https://doi.org/10.1016/j.ijtst.2021.01.004).
- **R09.** Chennai Traffic Data / Rajput et al., “SPT Chennai traffic trajectories,” dataset project and *Transportation Research Part C* study, 2026. [Project](https://www.chennaitrafficdata.com/), [paper link cited in P4–P5](https://www.sciencedirect.com/science/article/pii/S0968090X25004358). File access and licence remain unverified. [P4–P5](/Users/aditya/dev/sih2026-hq/research/P4-P5-ML-PREDICTION-PERCEPTION.md)

## Indian datasets

- **R10.** IIIT Hyderabad, “India Driving Dataset (IDD),” dataset portal, n.d. [Link](https://insaan.iiit.ac.in/datasets/). Licence terms appear at download and were not verified in P4–P5.
- **R11.** IDD-3D authors, “IDD-3D: Indian Driving Dataset for 3D Unstructured Road Scenes,” arXiv preprint, 2022. [Link](https://arxiv.org/abs/2210.12878).
- **R12.** Shaik et al., “IDD-AW: A Benchmark for Safe and Robust Segmentation of Drive Scenes in Unstructured Traffic and Adverse Weather,” *WACV*, 2024. [Link](https://arxiv.org/abs/2311.14459).
- **R13.** Parikh, Saluja, Jawahar and Sarvadevabhatla, “IDD-X: A Multi-View Dataset for Ego-relative Important Object Localization and Explanation in Dense and Unstructured Traffic,” research paper, 2024. [Link](https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2024/IDDX_2024.pdf). Its labels are **not metric future trajectories**.
- **R14.** Bokkasam et al., “Pedestrian Intention and Trajectory Prediction in Unstructured Traffic Using IDD-PeD,” arXiv preprint, 2025. [Link](https://arxiv.org/abs/2506.22111). Dataset licence unverified.
- **R15.** Kumar, Reddy and Rajalakshmi, “DriveIndia: An Object Detection Dataset for Diverse Indian Traffic Scenes,” *ITSC*, 2025. [Link](https://arxiv.org/abs/2507.19912). TiHAN access requires an agreement; exact reuse terms need checking.
- **R16.** Khoba et al., “A Fine-Grained Vehicle Detection Dataset for Unconstrained Roads,” research paper, 2022. [Link](https://arxiv.org/abs/2212.14569).
- **R17.** TiHAN IIT Hyderabad, “TIAND: multimodal Indian driving scenes,” dataset portal and IEEE paper, 2024. [Portal](https://tihan.iith.ac.in/TiAND.html), [paper](https://ieeexplore.ieee.org/document/10588583/). Request and usage agreement required.
- **R18.** Chandra et al., “METEOR: A Dense, Heterogeneous, and Unstructured Traffic Dataset With Rare Behaviors,” arXiv preprint, 2021/2022. [Link](https://arxiv.org/abs/2109.07648). Dataset reuse terms need checking.
- **R19.** RoadText authors, “RoadText-1K: Text Detection & Recognition Dataset for Driving Videos,” arXiv preprint, 2020. [Link](https://arxiv.org/abs/2005.09496). Dataset licence unverified.

**Unfilled data needs:** Indian police hand gestures, siren/horn audio with direction labels, and driver-monitoring footage. The design must collect or simulate these and mark synthetic results as such. [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)

## Planning and safety prior art; competitor evidence

- **R20.** Kruse, Yel, Senanayake and Kochenderfer, “Uncertainty-Aware Online Merge Planning with Learned Driver Behavior,” arXiv preprint, 2022. [Link](https://arxiv.org/abs/2207.05228).
- **R21.** Cai and Hsu, “Closing the Planning-Learning Loop with Application to Autonomous Driving” (*LeTS-Drive*), *IEEE Transactions on Robotics*, 2022. [Link](https://arxiv.org/abs/2101.03834).
- **R22.** Le Large et al., “Mosaic: An Extensible Framework for Composing Rule-Based and Learned Motion Planners,” *IROS*, 2026. [Link](https://arxiv.org/abs/2604.13853). Separate proposal and verification are prior art.
- **R23.** Trautman and Krause, “Unfreezing the Robot: Navigation in Dense, Interacting Crowds,” research paper, 2010. [Link](https://las.inf.ethz.ch/files/trautman10unfreezing.pdf).
- **R24.** “Multi-Agent Reachability Calibration with Conformal Prediction,” arXiv preprint, 2023. [Link](https://arxiv.org/abs/2304.00432). Calibration is conditional on its assumptions; it does not rescue missed detections.
- **R25.** ARAI, “Intelligent Vehicle Technology: Indian driving scenario repository for ADAS functions,” institutional page, n.d. [Link](https://www.araiindia.com/departments-laboratories/technology-group/intelligent-vehicle-technology).
- **R26.** Warwick WMG, “Crowdsourcing Indian Traffic Scenarios for ADAS Development and Testing,” research paper, 2026. [Link](https://wrap.warwick.ac.uk/196298/1/WRAP-Crowdsourcing-Indian-traffic-scenarios-ADAS-development-testing-26.pdf).
- **R27.** Swaayatt Robots, “Technology and autonomous-driving work,” company site, n.d. [Link](https://www.swaayattrobots.com/). Treat detailed performance as company claims.
- **R28.** Minus Zero, “How did a foundational model learn to navigate the busy streets of Bengaluru?”, company technical account, 2025. [Link](https://minuszero.ai/blog/how-did-foundational-model-learn-to-navigate-the-busy-streets-of-bengaluru). Its detailed runtime safety mechanism is unverified.

## MathWorks and simulation tools

- **R29.** MathWorks, “Client, Reader and Writer blocks for Eclipse SUMO co-simulation,” R2026a documentation. [Client](https://www.mathworks.com/help/driving/ref/client.html), [Reader](https://www.mathworks.com/help/driving/ref/reader.html), [Writer](https://www.mathworks.com/help/driving/ref/writer.html).
- **R30.** MathWorks, “Set Up and Connect to CARLA Simulator,” product documentation, n.d. [Link](https://www.mathworks.com/help/ros/ug/set-up-and-connect-to-carla-simulator.html).
- **R31.** CARLA project, “Windows build; add a new vehicle; add new props,” CARLA 0.9.15 documentation, n.d. [Build](https://carla.readthedocs.io/en/0.9.15/build_windows/), [vehicle](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_vehicle/), [props](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_props/).
- **R32.** MathWorks, “Verify MEX Functions in the MATLAB Coder App,” product documentation, n.d. [Link](https://www.mathworks.com/help/coder/ug/how-to-test-mex-functions.html).
- **R33.** MathWorks, “Passenger Vehicle Dynamics Models,” Vehicle Dynamics Blockset documentation, n.d. [Link](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html).

=====DOC 4: 04-JUDGE-QA.md=====

# Fifteen hard questions and honest answers

1. **The PS explicitly says RoadRunner. Where are those scenes?**  
   We lack that licence. We propose two detailed **CARLA 0.9.15** village and junction scenes connected to the Simulink ego stack. This is a disclosed **literal deviation**, not a waiver. [P14](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md)

2. **Is the complete Simulink system working today?**  
   No. The MATLAB 2D planner and some sensor tracking run; the Simulink bicycle model is a side model, and camera inference is outside the driving loop. [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md)

3. **Why claim real-time replanning when you measured 735.8 ms?**  
   We do **not** claim it today. The build gate replaces the collision-check hotspot, compiles planner and verifier kernels, and reports full-loop p50/p95/p99 plus 100 ms deadline misses. [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)

4. **Can your camera currently identify an auto or a cow in CARLA?**  
   Not reliably: YOLOX produced zero render boxes at the audited default threshold. Offline auto and cow AP are 38.2% and 16.3%; labelled in-loop recall is a required gate. [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md)

5. **Does your yield model give the car permission to cross?**  
   No. Its dangerous-error rate is 2.089% against its ≤1% gate, so its output is disabled. The planned model predicts occupied regions; only the separate geometric/braking checker may permit movement. [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md), [P13](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md)

6. **What prevents the independent checker from freezing the car forever?**  
   Nothing can guarantee progress in a truly blocked road. We fix today’s S2/S3 stall bugs, record **false** stalls when a feasible gap existed, and permit only a freshly checked, stoppable creep. [P3](/Users/aditya/dev/sih2026-hq/research/P3-PLANNER.md)

7. **What is new if learned proposals and separate verification already exist?**  
   Those mechanisms are prior art, including Mosaic. The proposed contribution is an **India-calibrated, measured** closed loop with responsive traffic, false-stall accounting and held-out baselines; its benefit is not proved yet. R20–R23.

8. **Fourteen AI models with two builders in ten weeks?**  
   Fourteen is the **design inventory**. Five form the target core; only YOLOX and DeepLab exist offline today. Nine are later extensions, and the RL policy is a comparison, not the driving authority. [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)

9. **How will you obtain authentic autos and cattle in CARLA?**  
   A custom driveable vehicle needs a Windows UE4 source build; W2 must spawn one vehicle and one prop. If it fails, we disclose blueprint/prop surrogates and withdraw claims of realistic auto pixels or physics. R31.

10. **Will SUMO and CARLA both control the same actor?**  
    No. SUMO owns reactive traffic state; the bridge mirrors it into CARLA, while Simulink controls ego. Timestamp, actor-ID and pose assertions must pass before a run counts. [P13](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md)

11. **How do hand gestures and horns affect right of way?**  
    They raise caution or change an intent hypothesis. A police “proceed” gesture, horn, or siren cannot itself open the verifier; a siren triggers only a checked yield or stop. [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)

12. **Does a real dashcam replay prove the car can drive on a real road?**  
    No. It is open-loop evidence for perception and tracking transfer. We report per-class recall on held-out real versus rendered frames; road-driving safety still needs much more evidence. [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)

13. **How do you predict a cow’s sudden motion without a cattle-trajectory dataset?**  
    We do not claim a learned cattle-intent model. Cattle remain detected obstacles with conservative reachable regions, tested against sudden-onset scenarios. [P4–P5](/Users/aditya/dev/sih2026-hq/research/P4-P5-ML-PREDICTION-PERCEPTION.md)

14. **What do the large crash numbers prove about your expected impact?**  
    They establish the **problem’s scale**, not lives saved by our system. MoRTH totals are national 2023 counts; the cattle-crash count is Haryana-only over five years. We give no projected reduction. R03–R05.

15. **What will you hand over if the finale gates fail or data access is denied?**  
    The same model, scenario manifests, raw logs, failure reasons, measured PS metrics and a plainly marked partial result. Dataset access is checked before use; missing classes and the RoadRunner deviation remain visible. [P14](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md), [P15](/Users/aditya/dev/sih2026-hq/research/P15-BUILD-PLAN.md)