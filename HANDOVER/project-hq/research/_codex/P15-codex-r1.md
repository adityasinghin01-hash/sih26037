# P15 — build plan to the December 2026 finale

**Verdict — JUDGMENT:** Two builders can produce a credible **simulation-only, integrated** system in roughly ten weeks if the current stalls and timing failure are fixed first. A flawless car for all Indian roads is impossible; here, “no gaps” means **40/40 P14 rows and 25/25 top difficulties have an owner, executable test, recorded result and declared fallback**. The two RoadRunner rows remain disclosed deviations. The finale date is unverified, so the core demonstration must be ready by **late November**, with December as buffer. [P14 scorecard](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md), [P2 audit](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md)

**Scope cut:** **MUST** is one Simulink ego stack, front camera + lidar + front radar, vehicle-state sensors and actuator feedback, all five PS scenarios, four required object classes, irregular-motion fallback, independent movement check, 10 Hz measurement and stale-plan response, PS metrics, report and video. **SHOULD** adds the remaining car sensors, detailed degradation curves, 14DOF pothole runs, automated shadow mining and broad F1–F10 sweeps. **STRETCH** adds a learned joint traffic model, a horn-response study and strong statistical claims. Every listed car signal has an interface even if its higher-fidelity model is cut.

## 1. Interface contract: one running stack

**JUDGMENT — fixed conventions:** Every message carries `run_id`, monotonically increasing `seq`, `t_sim_s`, `source`, `valid` and `age_s`. Position uses metres, speed m/s, angles radians. Canonical world coordinates are **ENU** (east, north, up); ego coordinates are **FLU** (forward, left, up). The CARLA adapter reverses its right-positive lateral axis; the Vehicle Dynamics Blockset adapter also converts its right/down-positive vehicle axes. Simulator ground truth goes to evaluation only. A timestamp, frame or transform mismatch is a fault, never silently corrected. [CARLA sensor frames](https://carla.readthedocs.io/en/0.9.15/ref_sensors/), [Vehicle Body 3DOF axes](https://www.mathworks.com/help/vdynblks/ref/vehiclebody3dof.html)

| Message and producer → consumer | Fixed fields beyond the common header | Target rate; frame |
|---|---|---|
| `ScenarioTickV1`: world adapter → harness | `scenario_id`, seed, backend, actor-policy version, fixed step, route ID | 10 Hz; world ENU |
| `SensorPacketV1`: CARLA/fast-tier adapter → perception | modality, sensor ID, calibration ID, extrinsic pose, payload, measurement covariance, dropout flag | RGB/lidar 10 Hz; radar 20 Hz; ultrasonic 10 Hz; GNSS 10 Hz; IMU 100 Hz; native sensor frame |
| `VehicleStateV1`: localization → all ego blocks | ENU pose and covariance, FLU velocity/acceleration, yaw rate, wheel speeds, measured steer, gear, friction estimate, quality flag | 50 Hz; stated per field |
| **Frozen `S1 TrackList`**: tracker → downstream | Existing `TrackID`, `ClassID`, ego-frame position/velocity/extent/yaw, existence, age, `SensorMask` | 10 Hz; ego FLU |
| `FreeSpaceV1`: perception → proposer/verifier | local-grid origin, resolution, traversable/occupied/**unknown** cells, edge confidence, visible range, localization margin | 10 Hz; ego FLU |
| `MotionSetV1`: prediction → proposer/verifier | track IDs; top-K metric paths and time-indexed occupied regions for each ego candidate; coverage, unmodelled flag | 10 Hz; ego FLU; 2–3 s horizon |
| `BeliefV1`: belief update → prediction/proposer | track IDs; probabilities for continue, cross, brake/turn, group/cover; five response values; unmodelled mass | 10 Hz; ego FLU |
| `CandidateSetV1`: proposer → verifier | 8–16 IDs, sampled pose/speed/curvature, executed prefix, planned stop, route progress | 10 Hz; ego FLU; SI units |
| `CertificateV1`: verifier → control/monitor | accepted candidate ID **and trajectory hash**, pass/veto reason, last valid time, worst clearance, stopping margin, assumed sensor ages | 10 Hz; ego FLU |
| `ActuatorBusV1`: control/monitor → plant/CARLA | steering angle rad, throttle/brake 0–1, gear P/N/D/R, command counter, applied-feedback counter | 50 Hz; vehicle frame |
| `SignalHMIV1`: decision/monitor → vehicle/driver display | left/right indicator, hazards, low/high beam, brake/reverse light, horn request, mode, fault reason, takeover request/ack/deadline | On change; heartbeat 10 Hz |
| `RunRecordV1`: harness → replay/evaluation | all message hashes, scenario/config/seed/model versions, separate simulator truth, contacts, timing and outcome | Every tick; files under `results/<run>/` |

**Compatibility rule:** The [frozen S1–S8 contract](/Users/aditya/dev/sih2026-hq/05-ASSETS/PRD.md:192) stays unchanged. In particular, S3 `PYield` remains invalid and cannot authorize movement; S4 `EgoCommand` is adapted into `ActuatorBusV1`. Do not renumber S5 classes. An e-rickshaw uses the existing three-wheeler class plus subtype metadata keyed by `TrackID`; an overloaded two-wheeler carries its measured **extent**, not a new class ID.

**JUDGMENT — timing allocation:** The target from a synchronized sensor snapshot to a validated command is **100 ms**: transport/sync 10, perception 30, localization/tracking 10, belief/prediction 15, candidates/scorer 10, verifier 15, control/monitor 5, slack 5 ms. Measure each stage and the separate sensor-to-actuation age on the Windows PC. These are budgets to test, **not current performance**; today’s planner alone takes **735.8 ms/step**. [P9–P12](/Users/aditya/dev/sih2026-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md), [P2](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md)

**Declared simulated ODD:** Five named road layouts; speed caps chosen for testing of 30 km/h in market/junction, 40 km/h on village roads and 60 km/h on the highway merge. Heavy rain, dense fog, darkness beyond reliable headlamp range, lost localization and blocked roads are **degraded-mode tests**: safe slowing or a minimal-risk stop counts as correct handling, not route completion. The controller never depends on a driver accepting takeover. These limits are design choices to validate, not public-road operating claims.

## 2. Car specification

Parameters below are **proposed simulation settings**, not measured specifications of a production car. The same Simulink ports receive fast-tier sensor models or CARLA 0.9.x messages. `visionDetectionGenerator` supplies detections for fast sweeps; it does **not** test YOLOX on pixels. CARLA’s ROS bridge exposes RGB, lidar, radar, GNSS and IMU. [MathWorks sensor models](/Users/aditya/dev/sih2026-hq/research/P6-P7-P8-SIM-TRAFFIC-SENSORS.md), [CARLA ROS bridge](https://carla.readthedocs.io/en/0.9.15/ros_documentation/)

| Car part | Model/parameters; MATLAB/Simulink or CARLA source | Actual use | Priority |
|---|---|---|---|
| Front RGB camera | CARLA `sensor.camera.rgb`, ~800×450, 90° field, 10 Hz; fast tier `visionDetectionGenerator` | Road mask and auto/pushcart/person/cattle detection | **MUST** |
| Rear RGB camera | CARLA RGB, ~640×360, wide field, 5–10 Hz | Reverse clearance and rear approach | **SHOULD** |
| Left/right surround cameras | Two CARLA RGB views, ~640×360, 5–10 Hz | Merge-side and near-corner occlusion; measured value must justify GPU cost | **SHOULD** |
| Lidar | CARLA ray-cast or MATLAB `lidarSensor`; ~32 beams, 100 m, 10 Hz, dropout sweep | Metric obstacles, edge height, unknown space | **MUST** |
| Front radar | CARLA radar or `radarDetectionGenerator`; ~150 m, 20 Hz | Closing speed and fog redundancy | **MUST** |
| Corner radars | Two CARLA radar cones or radar-generator instances; ~80 m, 20 Hz | Cross traffic and side approach at junctions | **SHOULD** |
| Ultrasonic ring | 8 short-range channels, ~0.2–5 m, 10 Hz; `ultrasonicDetectionGenerator` plus miss/ghost injection | Low-speed clearance and reverse; not a long-range safety sensor | **SHOULD** |
| GNSS | CARLA GNSS or MATLAB `gnssSensor`, 10 Hz; drift/dropout injection | Coarse route position; never the sole road-edge source | **MUST** |
| IMU | CARLA IMU or MATLAB `imuSensor`, 100 Hz | Yaw, acceleration and GNSS-loss propagation | **MUST** |
| Wheel speed/odometry | Plant wheel rotation or speed/radius with slip and quantization; MATLAB Function block, 50 Hz | Speed, distance and GNSS-loss support | **MUST** |
| Steering-angle sensor | Measured steering-system output with delay/noise, 50 Hz | Detect tracking or actuator mismatch | **MUST** |
| CAN-style vehicle bus | `Simulink.Bus` + rate transitions; counter, delay, stale and dropped-frame injection, 50 Hz | One timed path for sensors, commands and feedback; **simulation**, not a physical CAN claim | **MUST** |
| Steer, throttle, brake | Simulink bicycle/3DOF plant and CARLA `VehicleControl`; steer bounded by existing ±0.6 rad contract, throttle/brake 0–1; feedback at 50 Hz | Execute and verify accepted motion | **MUST** |
| Gear including reverse | P/N/D/R command and applied gear; CARLA vehicle control; zero-speed interlock | Forward drive and tested reverse command; a full three-point turn is additional work | **MUST** interface; manoeuvre **SHOULD** |
| Indicators, brake/reverse lights, hazards | `SignalHMIV1`; CARLA `VehicleLightState` where supported; event log | Show intended turn and minimal-risk stop | **MUST** |
| Low beam and high beam | CARLA light state plus recorded illumination setting | Low beam supports night tests; high beam is evaluated for glare and has **no assumed effect on other drivers** | Low beam **MUST**; high beam **SHOULD** |
| Horn | Boolean request, event/audio overlay; no assumed actor response | Judge-visible communication only until a response model is validated | **STRETCH** |
| Driver display and takeover input | Simulink Dashboard/Stateflow mode, reason, request timer and simulated acknowledgment | Explain degraded state; no acknowledgment leads to minimal-risk stop | **MUST** |

The 3DOF plant is the broad test model; the 14DOF model is reserved for pothole and speed-breaker ride checks because it includes vertical, pitch, roll and wheel motion. [MathWorks vehicle-model comparison](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html) CARLA 0.9.x is pinned for the 8 GB lab GPU; 0.9.15 documents a 6 GB minimum and 8 GB recommendation. The exact 0.9.x release and ROS bridge pair is frozen only after a lab smoke test. [P13 correction](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md), [CARLA requirements](https://carla.readthedocs.io/en/0.9.15/start_quickstart/)

## 3. Ten weekly build gates

**Global exit rule:** Every week ends with the **same Simulink ego model** running an end-to-end seed, all applicable existing **348 tests**, schema/units checks and a saved `config.json` plus timing/contact log. Fast-tier ground-truth input is an explicit test mode, never silently mixed with sensor-in-loop results. A phase is unfinished if its gate fails. **A = Aditya; S = Shourya.** Dates assume a 1 October start; move the freeze forward when the official finale date is known. [Existing tests and artifacts](/Users/aditya/dev/sih2026-hq/research/P2-AUDIT-OUR-SYSTEM.md)

| Week | Goal and tasks | Owner | Measurable exit gate | P14 rows; P1 top-25 IDs |
|---|---|---|---|---|
| **W1, 1–7 Oct** | Reproduce S2 contact/stall and dense S3 stall; fix lost longitudinal station, one-frame WAIT, rearming timeout and tie-break; preserve traces. Inventory and safeguard the eight unpushed commits and model files. | A; S reproduces | On ≥3 fixed seeds each, S2 and dense S3 have **0 contact** and no >10 s stall when an oracle-labelled gap exists; before/after logs retained. | C01, C11, C14; **16, 53, 61** |
| **W2, 8–14 Oct** | Replace per-candidate capsule construction with broad-phase then exact swept check; use 8–16 candidates; add independent stop check, persistent blocked state and stale-plan brake. | A; S profiles | Fast-tier state-input run: **p99 validated-plan time ≤100 ms** across ≥1,000 ticks; 100 deliberately unsafe candidates all vetoed; late output triggers brake, never GO. | C11–12, C29, C37–38; **5, 6, 38** |
| **W3, 15–21 Oct** | Establish versioned buses, frame adapters, map/localization and 50 Hz plant/control/actuator feedback inside one `.slx`; Stanley+PI baseline; gear and HMI fault path. | A; S connects sensor adapter | One 5-minute S1 run in the unified model with steering executed, no unit/frame assertion, measured feedback, and a stop on injected command loss. | C03, C26, C30, C39; **46, 52** |
| **W4, 22–28 Oct** | Put CARLA front RGB → YOLOX/DeepLab → lidar/radar fusion → frozen S1 tracks in the loop. Diagnose zero render boxes before retraining; label auto, pushcart, person and cattle renders. | S; A integrates verifier input | Held-out labelled render set reports per-class recall at the **visible stopping distance**; all four PS classes produce checked in-loop detections, and missed/unknown cells reduce permission. Recheck 100 ms budget. | C04–08, C13, C18, C36, C40; **31, 38, 75, 76** |
| **W5, 29 Oct–4 Nov** | Add top-K metric occupancy and conservative tubes; belief over intent × response, including group/cover; small learned scorer. Keep S3 `PYield` disabled. | S prediction; A belief/scorer/verifier | Held-out trajectory coverage and fallback rate reported by class; lateral cut-in and rolling-crossing tests included; a unit test proves changing ML scores alone cannot bypass the verifier. | C01, C09–10, C14–15; **1, 2, 16, 20, 21, 32, 61** |
| **W6, 5–11 Nov** | Pin CARLA 0.9.x; build detailed unmarked village and unsignalled junction scenes; connect the verified R2026a SUMO blocks to reactive traffic and CARLA actor mirroring. | S worlds/assets; A synchronization | ≥1,000 synchronized ticks with actor ID/pose and timestamp assertions, no 8 GB GPU exhaustion; a changed ego action produces a changed actor response. Both scenes run the **same** Simulink model. | C02, C19–20, C24, C27, C34–35; **11, 53, 61** |
| **W7, 12–18 Nov** | Finish the five PS routes and a seeded probe for each top-25 difficulty; include F1–F10 templates, wrong-way users, bus pull-out, auto stop, diversion and service-road entry. | A routes/tests; S actors | **5 × 10 predeclared seeds**: report completion, contact and false-blocked rates per scene; target ≥9/10 completion and zero disqualifying contacts per scene. All 25 probes have a result and fallback trace. | C01–02, C14–25, C27, C31, C34; **all 25** |
| **W8, 19–25 Nov** | Inject sensor delay/dropout, rain/fog/night and friction loss; test minimal-risk stop and takeover timeout. Compare 3DOF with 14DOF on a small pothole set if plant access permits. Add shadow disagreement/replay queue. | A safety/control; S faults/data | Every declared fault produces either continued certified motion or a logged stop; no fault silently yields a GO. Rain/fog/night curves and replay of one mined failure exist. **Core demo freezes by 25 Nov.** | C04, C16–18, C30, C38–39; **39, 45, 67, 68, 70, 75** |
| **W9, 26 Nov–2 Dec** | Run frozen holdout and shared-seed baselines; profile the **full camera-in-loop** model on Windows; calculate exact PS metrics, confidence intervals and claim ledger. Prepare report and film from matched run IDs. | A evaluation/timing; S perception/results | Five-scene results, baseline table, p50/p95/p99 and deadline misses published. Run **299 independent predeclared fast-tier seeds** if ready; claim a <1% bound only if all 299 have zero failures for that specified distribution. | C11–12, C25, C28–34; all top-25 outcome summaries |
| **W10, 3–9 Dec, contingent buffer** | Fix only release-blocking regressions; rehearse the eight-minute demo; package model, scenarios, logs, report and video. Move this work earlier if the finale is earlier. | A + S | Fresh-machine one-command replay matches recorded run IDs and metrics; every P14 row has evidence, failure or explicit deviation; RoadRunner substitution is visible. | C24, C32–35; final 40-row audit |

The week estimates compress work that [P3](/Users/aditya/dev/sih2026-hq/research/P3-PLANNER.md), [P6–P8](/Users/aditya/dev/sih2026-hq/research/P6-P7-P8-SIM-TRAFFIC-SENSORS.md) and [P9–P12](/Users/aditya/dev/sih2026-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md) individually rate at several weeks. **W2, W4 and W6 are schedule gates:** failure there forces the cut line below, not an unlabelled claim of completion.

## 4. Traceability check

`C01–C40` are the rows of the [accepted P14 table](/Users/aditya/dev/sih2026-hq/research/P14-PS-COMPLIANCE.md), in order. Coverage: **C01–C03** W1/3/7; **C04–C08** W4/7; **C09–C10** W5; **C11–C12** W2/7/9; **C13–C18** W4/5/7/8; **C19–C23** W6/7; **C24 and C35** W6/10 as **permanent RoadRunner deviations**; **C25–C27** W3/6/7; **C28–C31** W9; **C32–C34** W6/9/10; **C36–C40** W2–5/8. Thus no P14 row lacks a phase; **C24 and C35 cannot be closed as MEETS** under the locked licence decision.

Each top-25 ID gets one named regression probe, with the phase that supplies its mechanism and the W7 suite that records its result. A “pass” means the ego either completes within its declared ODD **or reaches a justified minimal-risk stop**; a false stall where a feasible gap existed fails.

| P1 ID | Required probe | Phase |
|---:|---|---|
| **38** | Unmarked edge versus unsafe shoulder | W4/7 |
| **2** | Two-wheeler seeps through a narrow lateral gap | W5/7 |
| **20** | Pedestrian starts a midblock crossing | W5/7 |
| **75** | Person emerges from behind a bus | W4/7/8 |
| **16** | Informal merge with yielding **and** non-yielding actor | W1/5/7 |
| **53** | Uncontrolled T-junction crossing gap | W1/6/7 |
| **5** | Wrong-way oncoming vehicle | W2/7 |
| **6** | Abrupt lead-vehicle brake and stop margin | W2/7 |
| **1** | Close lateral cut-in | W5/7 |
| **31** | Standing and low-lying cattle envelope | W4/7 |
| **32** | Cattle starts crossing after ego approaches | W5/7 |
| **11** | Slow tractor-trolley; passing sight distance | W6/7 |
| **21** | Pedestrian pauses, then resumes | W5/7 |
| **76** | Overlapping tracks and ID swaps | W4/7 |
| **39** | Pothole slow/avoid choice; ride subset | W4/7/8 |
| **45** | Temporary construction corridor | W7/8 |
| **10** | Bus stops, hides a person, then pulls out | W5/7 |
| **9** | Auto-rickshaw stops for pickup | W4/7 |
| **67** | Rain reduces visibility **and** grip | W8 |
| **68** | Fog reduces reliable stopping sight | W8 |
| **70** | Unlit night road beyond headlamp range | W8 |
| **46** | Blind curve with speed limited by visible road | W3/7 |
| **61** | Mutual yield, then an observable safe gap | W1/5/7 |
| **25** | Pedestrian walks along road, then turns across | W5/7 |
| **52** | Service-road re-entry into faster flow | W3/7 |

**Uncovered P14 rows: none in the plan. Uncovered top-25 IDs: none in the plan.** That is traceability, not evidence that tests will pass. The nine beyond-PS items from P14 land in W2 (verifier, timing), W5 (belief), W6–7 (reactive traffic and families), W8 (degradation, 14DOF, shadow replay) and W9 (stratified statistics and baselines).

## 5. Degraded modes and fallbacks

**JUDGMENT — age limits to test:** ego state >50 ms, front RGB >150 ms, lidar/radar >200 ms or validated plan >100 ms counts as stale. These values must be checked against actual sensor timing; the monitor logs every transition.

| Failure | Detection | Required response |
|---|---|---|
| Late planner or stale sensor | Timestamp/sequence/heartbeat limit | Recheck the remaining certified prefix; otherwise brake within the last known free corridor, hazards, `BLOCKED` |
| Missed, unknown or conflicting object | Cross-sensor disagreement, low existence, unknown grid cell | Widen occupied region, reduce speed to visible stopping distance; stop if no certified corridor |
| Prediction out of distribution or coverage failure | Unmodelled mass, wide tube or held-out coverage monitor | Replace learned paths with conservative reachable region; no ML-derived GO |
| GNSS loss or map mismatch | Pose covariance, innovation and route-edge checks | IMU/wheel dead reckoning at reduced speed; stop when position margin exceeds free corridor |
| Heavy rain, fog or dark road | Measured reliable range and friction estimate, not weather slider alone | Sight-limited speed; low beam; minimal-risk stop when stopping sight is inadequate |
| Actuator/CAN fault | Counter/timeout or commanded-versus-measured steer/brake mismatch | Reject new trajectories; brake if available, hazards and takeover request; log when braking cannot be guaranteed |
| No safe candidate or traffic deadlock | All candidates vetoed; persistent reason and observed gap record | `BLOCKED`; re-evaluate, permit only a newly verified creep; timeout never authorizes crossing |
| No driver response to takeover | Request timer expires without acknowledgment | Continue autonomous minimal-risk stop; never assume a driver took control |
| CARLA–SUMO desynchronization | Actor ID, frame, pose or timestamp assertion fails | Pause/fail the run and command stop; mark results invalid for performance claims |

A minimal-risk manoeuvre here is a **verified deceleration to a stop in visible free space**, optionally toward a verified pull-over region. It is not a promise that a safe stopping place always exists. [P13 safety design](/Users/aditya/dev/sih2026-hq/research/P13-SYSTEM-DESIGN.md)

## 6. Eight-minute finale demonstration

| Time | What judges see |
|---|---|
| **0:00–0:40** | One Simulink model, live sensor/track/belief/certificate/actuator/HMI signals; declared simulated ODD and RoadRunner substitution on screen. |
| **0:40–1:35** | Unmarked village: camera road mask, lidar edge, tractor/pushcart and a stoppable pass. |
| **1:35–2:30** | Unsignalled junction: group/cover actor response, rejected unsafe candidate, then verified progress or an explained blocked state. |
| **2:30–3:20** | Highway slow-vehicle merge: metric futures, front/corner sensing where available, measured gap and control response. |
| **3:20–4:15** | Dense market: bike seepage, auto stop and pedestrian occlusion; show track IDs and no false permanent stall. |
| **4:15–5:05** | Sudden cattle crossing: detection, reachable region, brake and stop margin. |
| **5:05–6:00** | Inject one sensor dropout or fog/actuator delay; monitor requests takeover, hazards activate, car reaches the tested stop. |
| **6:00–7:10** | Replay one mined failure by seed, show changed result and frozen-holdout result; display paired baseline comparison. |
| **7:10–8:00** | PS scorecard: contact, completion, jerk/curvature, p50/p95/p99 and deadline misses; state remaining failures and the RoadRunner deviation. |

All segments use **recorded run IDs from the same model**. If a live simulator hiccups, play the matching trace and film rather than implying a separate successful run.

## 7. Top risks and cut line

| Risk | Decision if its gate slips |
|---|---|
| **W2 fails 100 ms even before pixels** | Stop feature expansion; simplify candidate generation and rewrite the hotspot. Do not claim real-time. |
| **W4 camera still gives unreliable rendered detections** | Retain lidar/radar and unknown-space fallback for safety; label the camera result as failed. Do not claim all four classes are identified in-loop. |
| **W6 three-way world sync or 8 GB GPU fails** | Keep **one Simulink ego stack** with SUMO reactive fast-tier traffic and CARLA selected pixel scenes as separate world backends. Disclose that simultaneous CARLA–SUMO runs were not achieved. |
| **Reactive actors overfit the planner** | Add a second fixed actor policy and non-yield sweeps before tuning the learned scorer. |
| **Two-builder capacity or earlier finale** | Freeze the core by W8. Cut automated shadow mining, full 299-run claim, 14DOF ride study, broad F7–F10 sweeps, rear/surround pixel inference, corner-radar refinement and horn-response work—in that order. Keep their interface ports and mark them unvalidated. |

**Non-negotiable line:** If the five PS scenes, in-loop front camera/lidar/radar, independent movement check, working actuator loop, declared fallback, measured latency and three PS metrics are unfinished, the final claim is **“partial integrated prototype”**, not a complete autonomous-driving solution. RoadRunner remains a disclosed literal deviation in either case.