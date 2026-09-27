# P14 — PS compliance and beyond

**FACT:** This is an audit of the design, not a claim that the finale system exists. “Today” means the [26 September system audit](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md). `MEETS`, `PARTIAL`, `NOT YET` and `DEVIATION` describe **today’s evidence**; the finale column is a target. The clauses come from the [verbatim PS](/Users/aditya/dev/sih2026-hq/research/PS-SIH26037-verbatim.md) and [P0 checklist](/Users/aditya/dev/sih2026-hq/research/P0-RULES.md). The proposed layers are in [P13](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md).

## 1. Compliance table

| PS clause, short quote | How P13 addresses it | Status today | Planned for finale | Evidence to show | Gap or risk |
|---|---|---|---|---|---|
| “adaptive path planning” on unstructured roads | Belief → manoeuvre scorer → verifier → control | **PARTIAL:** S1 completes 610 m; S2 and dense S3 stall | Five closed-loop Indian scenarios | Paired route films and run logs | Progress and safety both unproven |
| “mixed traffic” with diverse users | CARLA Indian actors; reactive SUMO traffic | **PARTIAL:** scripted actors; 50/51 density actors off road | Ego-responsive mixed traffic | Actor-response plots; films | Simulator realism |
| “perception, prediction, path planning, decision logic, and vehicle motion in MATLAB and Simulink” | Simulink hosts all ego blocks and harness | **PARTIAL:** MATLAB loop; Simulink bicycle side model; camera offline | One running Simulink model | `.slx`, signal traces, closed-loop film | Major integration task |
| “multi-sensor … camera, LiDAR, and radar” | Timestamped camera, lidar and radar → fusion | **PARTIAL:** lidar/radar → `trackerGNN`; camera outside loop | All three in selected CARLA runs | Sensor topics, detections, fault runs | Calibration and timing |
| “auto-rickshaws” | YOLOX class + tracked occupied region | **PARTIAL:** offline auto AP **38.2%**; zero boxes on renders at default threshold | In-loop auto recall measured | Labelled render set; recall table | Render transfer |
| “pushcarts” | Mine labels, train detector; obstacle envelope | **NOT YET:** no pushcart training data | In-loop pushcart detection | Annotated images; recall; film | Rare-class data |
| “pedestrians” | Detector, tracker, crossing modes | **PARTIAL:** simulated tracks; camera model offline | In-loop crossing and occlusion tests | Recall, track loss, crossing film | Hidden people |
| “animals” | Cattle detector + conservative reachable region | **PARTIAL:** offline cow AP **16.3%**; zero render boxes at default threshold | Cattle stop/cross runs | Recall; occupied-region and braking plots | No validated animal-motion dataset |
| “predict short-term motion” | Top-K metric paths or occupied regions | **PARTIAL:** two fixed-heading speed futures | Candidate-conditioned 2–3 s futures | Coverage and miss-rate plots | Indian metric tracks |
| “non-lane-based and irregular movement” | Lateral/turn modes plus reachable fallback | **NOT YET:** fixed-heading futures cannot bracket lateral moves | Cut-in, seepage and turn coverage | Held-out trajectory coverage | Model shift |
| “safe, collision-free path” and “collision-free performance” | Independent swept-footprint and stop check | **PARTIAL:** worst randomized clearance **−0.001 m: contact** | No contacts on declared test set; report failures | Contact log, margin, impact speed | No universal guarantee |
| “replanned in real time” / “timely replanning” | 10 Hz gate and stale-plan brake | **NOT YET:** **735.8 ms/step**, 7.4× the 100 ms budget | Measured 100 ms cycle gate | p50/p95/p99, deadline misses, full-loop trace | 88% capsule-list hotspot |
| “missing lane markings” | Road/shoulder/unknown grid; verifier uses free space | **NOT YET:** road model is outside a rendered camera loop | Unmarked village route | Road-edge error and route film | Surface colour is not safe geometry |
| “informal merging” | Response belief; candidate-conditioned forecasts | **PARTIAL:** scripted response; S2 stalls | Reactive merge with non-yield variants | Gap use, contacts, stall rate | Courtesy bias |
| “sudden pedestrian movement” | Crossing tubes, occlusion region, stop check | **NOT YET:** no audited in-loop camera case | Delayed-start crossing tests | Onset-to-brake trace; film | Detection may arrive too late |
| “unexpected obstacles” | Unknown occupancy, safety veto, stop | **PARTIAL:** live obstacle injection and fallback films | Debris, stopped vehicle and roadblock tests | Detection-to-stop trace | Visible stopping distance |
| Background: wrong-way travel and unmarked crossings | F5 and F3/F4 stress cases | **NOT YET:** no audited named pass | Seeded counterflow and midblock crossings | Contact/progress by family | Rare-event rate unknown |
| Background: unclear edges and potholes | Traversability fusion; 14DOF rough-road subset | **NOT YET:** no in-loop surface sensing or 14DOF run | Edge refusal; pothole slow/avoid tests | Clearance and vertical-acceleration traces | Depth and friction uncertainty |
| “unmarked village road” | F1 + F7 + F9; detailed CARLA scene | **NOT YET:** no verified named end-to-end run | Driven route | Scene file, seed, film, result | Needs genuine unmarked geometry |
| “busy urban intersection without signals” | F4 + F2/F3; detailed CARLA scene | **NOT YET:** S2 stalls, but audit does not establish it as this PS scene | Driven reactive junction | Scene file, gap and stall plots | Deadlock and collision |
| “highway merge involving slow-moving vehicles” | F5 + F4/F9 | **NOT YET:** no verified named end-to-end run | Slow-vehicle merge route | Film, gap and TTC logs | Speed mismatch |
| “dense market area with mixed traffic” | F2 + F3/F9 | **NOT YET:** dense S3 stalls; PS-scene mapping unaudited | Driven market route | Film, contact and blocked-state log | Occlusion and over-conservatism |
| “sudden cattle-crossing event” | F6 + F1/F7 | **NOT YET:** no verified named end-to-end run | Delayed cattle onset and safe stop | Film; onset, detection, stop trace | Low cattle recall |
| “at least two detailed RoadRunner scenes” | Two detailed **CARLA 0.9.x** scenes: village and urban junction | **DEVIATION:** zero RoadRunner scenes; no licence | **DEVIATION remains:** deliver CARLA substitutes | CARLA assets, scenario files and films | Literal PS requirement unmet |
| “use them to test … all five” | Shared scenario IDs across fast and rendered tiers | **NOT YET:** two working 2D demos; S4/S5 lack planner routes | Five named routes; selected rendered repeats | Five-row result matrix | Scene portability |
| “simulation model” | One Simulink ego stack and harness | **PARTIAL:** `sih_planner.slx` is a side model | Reproducible running `.slx` | Model and one-command run | Main-demo steering not executed today |
| “designed scenarios” | Five named cases plus F1–F10 parameters | **PARTIAL:** S1–S3 2D; S4/S5 density layers lack routes | Versioned scenario package | Scenario manifest, seeds and assets | CARLA/SUMO synchronization |
| “performance results” | Paired baselines and frozen holdout | **PARTIAL:** M1–M10, **348/348** tests; no shared-seed head-to-head | Stratified results and intervals | Results tables and raw logs | Current tests do not prove PS outcomes |
| “replanning latency” | Snapshot → validated replacement time | **PARTIAL:** profiler gives 735.8 ms/step; PS metric not reported | p50/p95/p99 and misses over 100 ms | Timing CSV and profiler trace | Transfer time must be included |
| “path smoothness” / “smooth path generation” | Realized jerk and curvature change, separately | **PARTIAL:** M10 wobble is only a proxy | Declared jerk and curvature formulas | Per-run traces and summary | Brake events can hide in one score |
| “scenario completion rate” | Reached on time, no disqualifying contact, stayed drivable | **PARTIAL:** S1/S3 finish; only **2/5** working demos | Rate by scenario and family | Outcome table with failure reasons | Stall versus true blockage |
| “short technical report” | Architecture, assumptions, formulas, limits | **NOT YET:** no final report in audit | Versioned report | PDF and claim-to-evidence table | Must disclose RoadRunner deviation |
| “demonstration video” | Five closed-loop runs, including failure handling | **PARTIAL:** S1/S3 films; S2 withheld | Narrated five-scene video | Video and matching run IDs | Film alone does not prove robustness |
| “closed-loop validation … mixed traffic” | Ego command affects reactive actors and next sensor frame | **PARTIAL:** `reactStep` made **35** speed-only reactions per S1 run; density largely scenery | At least two independently specified actor policies | Ego-action/actor-response traces | Fixed scripts can flatter planner |
| Encouraged: “RoadRunner for scenario design” | CARLA 0.9.x substitutes | **DEVIATION:** no licence or scenes | **DEVIATION:** two CARLA scenes | Asset and scene package | Do not imply a MathWorks waiver |
| Encouraged: “Automated Driving Toolbox” | Sensor/scenario workflow | **PARTIAL:** simulated sensing exists; exact toolbox use not audited | Use documented sensor/scenario blocks | `.slx` block inventory | Installed products and integration |
| Encouraged: “Navigation Toolbox” | Candidate geometry and collision checks | **MEETS tool use:** `dynamicCapsuleList` is in current checker | Replace slow repeated calls where needed | Model/code and profile | Present use costs 88% of step |
| Encouraged: “Stateflow” | Persistent blocked and fallback states | **NOT YET:** no audited Stateflow decision logic | Stateflow decision chart | Chart and state-transition logs | Timeout must not grant passage |
| Encouraged: “Vehicle Dynamics Blockset or a Simulink bicycle model” | Bicycle baseline; 3DOF/14DOF tests | **PARTIAL:** bicycle side model; main demo uses an integrator | Executed plant; 14DOF pothole subset | Model, tracking and ride plots | Steering path not closed today |
| Encouraged: “Deep Learning Toolbox” | Detector, road mask and compact prediction/scorer | **PARTIAL:** YOLOX/DeepLab offline; ML gate disabled | In-loop inference with measured age | Model files, inference logs | Import, recall and deadline |

**Judge-facing RoadRunner wording:** “The PS specifies two detailed RoadRunner scenes. RoadRunner is unavailable under our licence, so we will provide two detailed CARLA 0.9.x scenes—an unmarked village road and an unsignalled urban junction—with the ego stack and evaluation in MATLAB/Simulink. This is a substitution, not literal compliance.” P13’s correction pins **CARLA 0.9.x (UE4)** for the 8 GB lab GPU; its documented minimum is 6 GB and recommendation is 8 GB. [P13 correction](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md), [CARLA 0.9.15 requirements](https://carla.readthedocs.io/en/0.9.15/start_quickstart/)

## 2. Beyond-the-PS table

**JUDGMENT:** Effort is incremental, rough builder time; items overlap with the required stack and cannot simply be added into a schedule. “Measured contribution” remains **unproven** until paired held-out results exist.

| Beyond-PS item | Why a judge cares | Novelty status and closest prior art | Effort | Status |
|---|---|---|---|---|
| Response-propensity belief with group/cover modes | Tests negotiation without assuming every driver yields | **Prior-art mechanism; India-specific modes proposed.** Continuous cooperation belief: [Kruse et al.](https://arxiv.org/abs/2207.05228); dense belief planning: [LeTS-Drive](https://arxiv.org/abs/2101.03834). Chennai mode shares are site-specific. | 2–4 weeks | **PLANNED** |
| Independent verifier and persistent blocked state | Makes the source of permission and the reason for stopping inspectable | **Prior art**, including learned/rule verification in [Mosaic](https://arxiv.org/abs/2604.13853) and the [frozen-robot problem](https://las.inf.ethz.ch/files/trautman10unfreezing.pdf). India-specific measured benefit unproven. | 2–4 weeks | Current barriers **PARTIAL**; independent check **PLANNED** |
| India-calibrated reactive traffic | Prevents a showcase where other users conveniently clear the path | **India-specific application**, with prior sublane simulation. Parameterize the **0.906 m** measured squeeze gap, class gap/speed ranges and group/cover modes; **sweep** pedestrian yielding, whose site studies disagree. [P16](/Users/aditya/dev/sih2026-hq/research/P16-INDIAN-TRAFFIC-NUMBERS.md), [SUMO sublanes](https://sumo.dlr.de/docs/Simulation/SublaneModel.html) | 3–5 weeks | **PLANNED**; speed-only scripts today |
| F1–F10 over 90 difficulties | Makes coverage and missing cases visible | **Prior-art scenario collection; India-specific closed-loop use proposed.** ARAI already lists an [Indian ADAS repository](https://www.araiindia.com/departments-laboratories/technology-group/intelligent-vehicle-technology); [P1](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md) maps 90 IDs to ten families. | 2–3 weeks fast tier; rendered subset extra | Catalogue **BUILT**; executable family suite **PLANNED** |
| Simulation shadow-mode data engine | Turns one found failure into a replayable regression | **Prior art** in [AIDE](https://openaccess.thecvf.com/content/CVPR2024/html/Liang_AIDE_An_Automatic_Data_Engine_for_Object_Detection_in_Autonomous_CVPR_2024_paper.html) and [Waymo’s described loop](https://waymo.com/blog/2026/08/10ailessons/); measured benefit unproven. | 3–5 weeks | **NOT YET** |
| Stratified evaluation, baselines and 299-run statistic | Exposes hidden stalls and limits safety claims | **Prior-art evaluation practice; measured Indian contribution possible.** **299 independent zero-failure runs** put a one-sided 95% bound below 1% for **one specified distribution**, not “Indian roads.” Compare current planner, MathWorks example, always-yield and PDM-like rule baseline on shared seeds. [P9–P12](/Users/aditya/dev/sih2026-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md), [nuPlan](https://arxiv.org/abs/2403.04133) | 3–5 weeks | Current metrics **PARTIAL**; paired holdout **PLANNED** |
| Sensor-degradation curves | Shows when the system stops safely as sensing worsens | **Prior art** in [RoboBEV](https://github.com/worldbench/robobev) and [Robo3D](https://github.com/worldbench/Robo3D); India-scene curves proposed. Report measured dropout/visibility, not a weather-slider setting. | 3–6 weeks | **NOT YET**; current sensors lack weather/miss models |
| 14DOF pothole tests | A planar car cannot measure ride response to a hole | **Established vehicle modeling**, applied to Indian defects. MathWorks’ [14DOF model](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html) includes vertical, pitch, roll and wheel motion. | 1–2 weeks after plant setup | **NOT YET** |
| 10 Hz timing gate and stale-plan response | Makes “real time” a falsifiable result | **Standard engineering practice; measured contribution only if demonstrated.** Current **735.8 ms/step** requires redesign, not a smaller label on the slide. [P3 timing analysis](/Users/aditya/dev/sih2026-hq/research/P3-PLANNER.md), [P9–P12](/Users/aditya/dev/sih2026-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md) | 3–5 weeks | **NOT YET** |

The official **R2026a SUMO Client** block is documented. P13’s header records that Claude could not verify Reader/Writer pages; their installed-version behaviour and the single-SUMO, CARLA, Simulink loop still need an integration test. [Client documentation](https://www.mathworks.com/help/driving/ref/client.html), [P13 correction](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md)

## 3. PPT claims ledger

| One-line slide claim | Tag | Reason |
|---|---|---|
| “A MATLAB 2D planner currently completes S1 and sparse S3.” | **SAFE NOW** | Audited runs: S1 **610 m**; S3 **382 m**. |
| “We have simulated lidar/radar tracking and offline Indian-road perception models.” | **SAFE NOW** | `trackerGNN`, YOLOX and DeepLab exist; camera inference is outside the driving loop. |
| “Our proposed Simulink stack joins sensing, prediction, planning, safety and vehicle motion.” | **SAFE ONLY AS ‘PLANNED’** | Today’s Simulink model is a side model. |
| “We plan two detailed CARLA 0.9.x Indian scenes in place of the specified RoadRunner scenes.” | **SAFE ONLY AS ‘PLANNED’** | Honest substitution; literal PS gap remains. |
| “A small learned scorer will rank manoeuvres; a separate check will grant motion.” | **SAFE ONLY AS ‘PLANNED’** | Current planner is hand-tuned; independent verifier is not built. |
| “We will test five PS scenarios and F1–F10 with paired baselines and a 10 Hz gate.” | **SAFE ONLY AS ‘PLANNED’** | Only two demos work; 736 ms/step today. |
| “This is the first Indian autonomous-driving test suite.” | **DO NOT CLAIM** | ARAI, Warwick/Safety Pool and others already work on Indian scenarios. [P1](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md) |
| “The planner is real-time today.” | **DO NOT CLAIM** | **735.8 ms/step** versus a 100 ms target. |
| “ML drives the car today.” | **DO NOT CLAIM** | Yield model has **2.089%** dangerous error and is gated off; perception is offline. |
| “We have two RoadRunner scenes.” | **DO NOT CLAIM** | There are **zero**; the proposed scenes use CARLA. |

Current numbers and limitations in this ledger are from [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md). Neither the proposed verifier nor zero-contact simulated runs justify a claim of certified safety on public Indian roads.

## 4. Five hostile questions and honest answers

1. **“The PS says RoadRunner. Where are your two scenes?”** — “We cannot meet that literal tool requirement; without the licence we will deliver two detailed CARLA scenes and disclose the substitution on the slide and in the report.”

2. **“How is this real-time when your loop takes 736 ms?”** — “It is not real-time today; we must replace the 88% collision-check hotspot and publish full-loop p50/p95/p99 and deadline misses before claiming 10 Hz.”

3. **“Does your camera system even see a cow or auto in the simulator?”** — “Not reliably yet: the detector produced zero boxes at its default render threshold; in-loop labelled-render recall is a required gate, and the ML yield output stays disabled.”

4. **“Won’t your safety layer just freeze at an intersection?”** — “It does stall today in S2 and dense S3. We will fix the WAIT logic, record when a feasible gap appeared, and allow a creep only when the independent stop check passes.”

5. **“What is novel here if Mosaic, Kruse and Indian scenario libraries already exist?”** — “The mechanisms and scenario collection are prior art. Our proposed contribution is a **measured**, India-calibrated Simulink closed loop that reduces contacts and false stalls on held-out reactive scenes; we cannot claim that result yet.” [P3 prior-art audit](/Users/aditya/dev/sih2026-hq/research/P3-PLANNER.md), [P1 competitor audit](/Users/aditya/dev/sih2026-hq/research/P1-DIFFICULTY-CATALOGUE.md)