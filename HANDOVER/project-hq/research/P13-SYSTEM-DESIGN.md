# P13 — Full system design

Status: ROUND 1, 26 Sep 2026. Codex (gpt-6-sol, xhigh) synthesis; Claude checked.

## Claude's corrections (override the text below)
- **CARLA GPU:** the "needs 16 GB" warning is for the UE5 build. **CARLA 0.9.x (UE4) needs 6 GB and recommends 8 GB** (carla.readthedocs.io/en/0.9.15/start_quickstart). So the 8 GB lab PC is fine if we **pin CARLA 0.9.x**. The MathWorks bridge example uses 0.9.13.
- **CARLA↔SUMO sync is real:** CARLA ships its own SUMO co-simulation (carla.readthedocs.io/en/latest/adv_sumo). One SUMO instance feeding both CARLA and Simulink still needs testing (it's the #3 risk).
- **MathWorks SUMO Reader/Writer: VERIFIED 27 Sep** (mathworks.com/help/driving/ref/reader.html, /writer.html). Both come in the R2026a add-on "Automated Driving Toolbox Interface for Eclipse SUMO Traffic Simulator". Writer sends vehicle data (ID, velocity, angular velocity) into SUMO. Reader returns each vehicle's position, speed and angle every step. Together with Client, that covers the ego↔SUMO loop.
- **RoadRunner conflict:** accepted as stated. The PPT must openly say "2 detailed CARLA scenes replace RoadRunner (no licence)". This goes into P14.
- Status labels match P2-AUDIT. Nothing planned is shown as built.

---
# P13 — system design for SIH26037

**FACT — requirement conflict:** The problem statement asks for **two detailed RoadRunner scenes**. With RoadRunner ruled out, this design cannot meet that literal requirement. Two detailed CARLA scenes can serve the same simulation purpose, but the submission must name the substitution as a deviation. The remaining PS requirements have a path through the architecture below. [PS text](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/PS-SIH26037-verbatim.md)

**FACT — starting point:** The running stack is partial. The current snapshot reports S2 contact and stalls, dense S3 stalls, a **2.089%** ML dangerous-error rate against a **≤1%** gate, and **736 ms per step** against a **100 ms** target. The yield gate stays closed. [System audit](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md)

## 1. Whole system

`P = PARTIAL; L = PLANNED. Rates are targets, not measured performance.`

```text
[drivingScenario P | CARLA town + Indian assets L | SUMO traffic L]
             | timestamped sensor data and simulator truth             ^
             v                                                        |
[camera/lidar/radar P] -> [YOLOX + road mask P] -> [trackerGNN P]       |
                                                   |                   |
                                            [top-K prediction L]       |
                                                   <->                 |
                                            [response belief L]        |
                                                   |                   |
                                [8-16 manoeuvre proposer L, 10 Hz]    |
                                      | candidates -> prediction       |
                                      v                                |
                           [swept + stop verifier L]                  |
                              | pass       | fail                      |
                              v            v                           |
                         [control P] <- [brake + blocked L] -> [vehicle P]
                              ^                                        |
                  [safety monitor L] -------- veto -------------------+
 simulator truth + all decisions -> [evaluation harness P]
 all logs -> [shadow mining L] -> [regression + frozen holdout L] -> scenarios
```

The belief updates from observed motion **and the ego action actually taken**. Prediction then queries that belief for each shortlisted ego manoeuvre. [Planner design](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md)

## 2. Layers

P1 IDs below are **difficulties targeted by design or tests, not demonstrated passes**. Status is as of 26 September 2026. [Difficulty catalogue](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P1-DIFFICULTY-CATALOGUE.md), [audit](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md)

| Layer | Job; inputs → outputs | Method and tool | Indian-specific part; P1 IDs | Status |
|---|---|---|---|---|
| World and traffic | Supply reactive roads and actors; ego action → next scene | `drivingScenario` fast tier; CARLA town and assets; R2026a Simulink–SUMO blocks | Ten families cover 1–90; actors respond to ego | **PARTIAL** 2D scripted worlds; CARLA/SUMO **PLANNED** |
| Sensors | Produce timestamped observations; scene → RGB, lidar, radar | CARLA sensors; MATLAB fault injection | Glare, rain, dust, dense overlap; 67–78, 82 | **PARTIAL** lidar/radar; rendered camera loop **PLANNED** |
| Perception | Find actors and traversable space; observations → detections, road/unknown grid | YOLOX, DeepLab, lidar geometry in MATLAB/Simulink | Autos, e-rickshaws, pushcarts, cattle, potholes, unmarked edges; 13, 20, 31–32, 38–41, 75–81 | **PARTIAL** offline models; in-loop fusion **PLANNED** |
| Tracking | Maintain positions and uncertainty; detections → tracks | `trackerGNN`, ego pose, occlusion handling | Seeping bikes, crossing groups, hidden people; 2–4, 20–22, 75–76, 82 | **PARTIAL** |
| Prediction | Forecast occupied regions; tracks + ego candidate → top-K metric futures | Compact fixed-shape model, conformal calibration, reachable-set fallback | Lateral cut-ins, rolling crossings, group/cover merges; 1–4, 16, 20–23, 53–61 | **PLANNED**; old binary yield model is disabled |
| Belief | Track likely intent and response; history + executed ego motion → actor belief | Intent modes × five response values + unmodelled mass; animals use separate reachable regions | Group/cover, informal negotiation, cattle; 16, 21–22, 31–37, 61 | **PLANNED** |
| Manoeuvre proposer | Rank feasible short moves; route + scene belief → 8–16 candidates | Precomputed manoeuvre library and small learned scorer in Simulink | Missing lanes, seepage, merges and blocked streets; 1–5, 16, 38, 49, 52–61 | **PLANNED**; current rule planner is **PARTIAL** baseline |
| Verifier and fallback | Permit a stoppable prefix or refuse it; candidates + conservative occupancy → pass/brake/blocked | Swept vehicle footprint, uncertainty, sight and stopping distance; Stateflow blocked state | Occluded crossings, wrong-way traffic, animals, road edges; 5–7, 20, 31–32, 38, 75, 88 | **PLANNED** independent check; current barriers **PARTIAL** |
| Safety monitor | Veto stale or unsafe commands; ages, faults, bounds → control override | Separate Simulink logic with logged reasons | Weather, sensor loss, unknown obstacles; 67–82, 83–90 | **PLANNED** |
| Control and vehicle | Follow accepted path; trajectory → steering/brake → pose | Stanley + PI baseline versus constrained MPC; 3DOF sweeps, 14DOF rough-road tests | Sharp turns, grades and potholes; 39–48, 49 | **PARTIAL** bicycle model; controller comparison **PLANNED** |
| Data engine | Turn failures into repeatable tests; logs → mined cases → regression set | Simulation shadow mode, seed replay, human review, frozen holdout | Indian interaction failures across 1–90 | **PLANNED** |
| Evaluation | Measure safety, progress and timing; truth + logs → stratified results | Simulink harness and paired baselines | Five PS scenes and F1–F10 | **PARTIAL** current metrics; exact PS metrics **PLANNED** |

The perception, prediction and control choices follow the reviewed designs in [P4–P5](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P4-P5-ML-PREDICTION-PERCEPTION.md) and [P9–P12](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md).

## 3. Safety architecture

**JUDGMENT — authority:** The learned predictor, response belief and scorer may **rank** moves; none may grant permission. The independent verifier may reject any proposal. The safety monitor may veto both an accepted plan and its control command. Control also rejects a trajectory it cannot track within steering, braking and friction limits.

The verifier checks the **executed short prefix and a reachable stop**, including a non-cooperating actor response, lateral and turning envelopes, track uncertainty, vehicle footprint and visible free space. A probe or creep receives permission only if it passes that same check. “Certified” here means checked against declared simulation bounds; it is **not a formal guarantee against missed objects or public-road collisions**. [Planner design](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md)

**Missing, late or stale input:** Close new movement permission; widen uncertain occupancy. Reuse an earlier plan only while its remaining prefix and stop still pass the current check. Otherwise command the tested brake response and enter a persistent **blocked** state with reason, elapsed time and observed actor response. A timeout triggers reassessment, never automatic entry into a gap. Log when the available distance is already too short to guarantee a stop.

## 4. Simulation and compute

**JUDGMENT — one state owner per actor:** Simulink runs the ego stack and harness. `drivingScenario` runs fast sweeps. SUMO owns dense vehicle motion, receives the ego’s executed position through the official R2026a **Client/Writer** path, and returns actor states through **Reader**. CARLA renders selected closed-loop scenes; a synchronized bridge mirrors SUMO actors into CARLA so the two simulators do not independently steer the same actor. Simulink receives CARLA camera/lidar/radar messages and sends steering, throttle and brake through the documented **CARLA ROS bridge**. The three-way synchronization, coordinate conversion and latency remain **PLANNED integration work**. [MathWorks SUMO blocks](https://www.mathworks.com/help/driving/ug/perform-cosimulation-between-simulink-and-sumo.html), [Writer](https://www.mathworks.com/help/driving/ref/writer.html), [MathWorks CARLA bridge](https://www.mathworks.com/help/ros/ug/set-up-and-connect-to-carla-simulator.html), [CARLA–SUMO synchronization](https://carla.readthedocs.io/en/latest/adv_sumo/)

- **Mac:** edit models, run `drivingScenario`, unit and fast regression sweeps, inspect results.
- **Windows lab PC, 8 GB GPU:** run Simulink–SUMO and selected reduced-resolution CARLA scenes. Pin and test a CARLA/ROS bridge version first. CARLA’s UE5 guide recommends **at least 16 GB VRAM**, so UE5 performance on this PC cannot be assumed; the documented MathWorks bridge example uses CARLA 0.9.13. [CARLA requirements](https://github.com/carla-simulator/carla/blob/ue5-dev/Docs/start_quickstart.md), [MathWorks example](https://www.mathworks.com/help/ros/ug/set-up-and-connect-to-carla-simulator.html)
- **DGX A100:** train YOLOX, road segmentation and compact prediction/scoring models; batch-search failures. Its lack of RT cores makes it an unsuitable promised host for the rendered CARLA demonstration.
- **Two detailed CARLA variants:** an **unmarked village segment** and an **unsignalled urban junction** in a ready-made town, with corrected road edges and surface geometry. Add cattle, auto- and e-rickshaws, tractor-trolleys, overloaded two-wheelers, pushcarts, jaywalkers, hand-signalling pedestrians, potholes and stalls. A town with actors alone does not establish an unmarked village road.

Use local Indian observations as **scenario parameter ranges**, not national rates: class-specific turning gaps, two-wheeler lateral gaps, speed spreads, pedestrian crossing speeds and group/cover modes. **Sweep pedestrian yielding** because the available studies disagree sharply and no transferable class-specific rate is established. [Indian traffic numbers](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P16-INDIAN-TRAFFIC-NUMBERS.md)

## 5. Required scenarios and ten test families

| PS scenario | Main families | System decision being tested |
|---|---|---|
| Unmarked village road | F1, F7, F9 | Find traversable edges; follow or pass tractors and carts; slow for surface defects |
| Unsignalled urban intersection | F4, F2, F3 | Handle negotiated priority, hand signals, crossings and occlusion |
| Highway merge with slow vehicles | F5, F4, F9 | Choose a verified gap despite speed mismatch and uncertain response |
| Dense market | F2, F3, F9 | Track bikes, autos and pedestrians; make safe progress or declare blocked |
| Sudden cattle crossing | F6, F1, F7 | Detect the animal, reserve its reachable region and retain a stop |

**F1** village mix (IDs 11–15, 31, 33–34, 38, 43, 49); **F2** market seepage (1–4, 9, 26, 28–29, 76–77); **F3** pedestrians and buses (10, 17, 20–25, 27, 30, 75); **F4** junction negotiation (7–8, 16, 53–61, 63–65); **F5** highway approach (5–6, 18–19, 52, 66); **F6** animal movement (32, 35–37); **F7** surface and terrain (39–42, 46–48, 51); **F8** disrupted layout (44–45, 50, 79–81); **F9** visibility and sensing (67–74, 78, 82); **F10** acute incident (62, 83–90). F8 and F10 are added to applicable base scenes; F9 is a reusable weather/sensor overlay. These are test templates, not 90 solved behaviours. [P1 family definitions](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P1-DIFFICULTY-CATALOGUE.md)

## 6. Beyond the PS

- **Response-propensity belief and safe probing — prior art; India-specific modes PLANNED.** Kruse, LeTS-Drive and ego-conditioned planning already cover the mechanisms. [P3 prior-art review](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md)
- **Learned scorer with an independent verifier — prior art; PLANNED implementation.** Mosaic already combines learned/rule proposals and verification. [Mosaic](https://arxiv.org/abs/2604.13853)
- **Reactive Indian traffic calibrated by actor class — India-specific, PLANNED.** Publish the source range and sensitivity to pedestrian yield assumptions. [P16](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P16-INDIAN-TRAFFIC-NUMBERS.md)
- **Composable closed-loop benchmark and failure-to-regression loop — prior-art methods applied to Indian scenes, PLANNED.** ARAI and Safety Pool already collect Indian scenarios; claim no “first.” [P1 competitor check](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P1-DIFFICULTY-CATALOGUE.md)
- **Measured contribution — not established yet.** It becomes defensible only if paired held-out runs show fewer contacts **and** stalls at a measured 10 Hz, with the same seeds and baselines. [P3 gates](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md)

## 7. Five technical risks

| Risk | Mitigation and evidence gate |
|---|---|
| **736 ms loop misses 10 Hz** | Replace per-candidate capsule-list construction with a cheap broad phase and exact checks on survivors; cap candidates; MEX compatible hot paths; measure full sensor-to-validated-plan latency. |
| **Detector returns zero boxes on renders** | First audit preprocessing, scores and class mapping on labelled CARLA frames; then fine-tune on randomized renders plus Indian images. Report per-class recall, especially cattle and pushcarts. |
| **8 GB CARLA plus SUMO bridge overload or desynchronizes** | Pin versions; test one actor and one tick at a time; assert timestamps and coordinate transforms; use reduced-resolution selected scenes while fast sweeps remain in `drivingScenario`. |
| **Prediction or simulator assumes yielding that does not happen** | Sweep yield rates; test at least two independently specified reactive actor policies; keep non-cooperation inside the verifier; measure coverage and fallback rate on held-out scenes. |
| **Safety creates permanent stalls** | Repair the known WAIT/clearance logic first; keep a persistent blocked record; count feasible gaps missed separately from genuinely blocked scenes; allow only verified, stoppable creep. |

These mitigations address the audit failures and the simulation limits in [P2](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md), [P3](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md) and [P6–P8](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P6-P7-P8-SIM-TRAFFIC-SENSORS.md).

## 8. Five bullets for slide 3

- **Build the test roads:** CARLA town scenes with Indian vehicles, people, cattle and damaged surfaces; SUMO supplies reactive dense traffic.
- **See the road:** camera, lidar and radar feed detection, road-edge estimation and tracking in Simulink.
- **Consider short moves:** predict how nearby users might move, then rank 8–16 manoeuvres.
- **Move only after a separate check:** verify space and stopping distance; brake and report **blocked** when no move passes.
- **Prove it in five scenarios:** report contacts, completion, jerk and curvature, and **10 Hz** replanning latency against baselines. **Today these are build targets; the current stack is partial.**

**JUDGMENT — exact evaluation rules to publish before testing:** latency is snapshot timestamp to validated replacement trajectory, with p50/p95/p99 and the share over **100 ms**; smoothness reports mean absolute realized jerk and mean absolute change of path curvature per metre **separately**; completion is the share reaching the destination before the declared time limit with no disqualifying contact or exit from the declared drivable area. Stratify by family, weather and sensing mode, and retain raw progress and failure reason. [Evaluation design](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md)