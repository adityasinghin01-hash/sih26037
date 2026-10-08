# P15 — Build plan to the December 2026 finale (FINAL DRAFT, awaiting Aditya's confirmation)

Status: 27 Sep 2026. Codex (gpt-6-sol, xhigh) rounds 1+2; Claude critiqued and verified. PLAN ONLY — nothing built.
Round 1: `_codex/P15-codex-r1.md`. Round-2 brief with Claude's critique: `_codex/P15-brief-r2.md`.

## Claude's verification
- CARLA 0.9.15 Windows source build: **165 GB disk, UE 4.26 fork, VS 2019, "4 hours or more"**: VERIFIED (carla.readthedocs.io/en/0.9.15/build_windows/).
- Custom driveable vehicles need the source build + UE Editor; props in a packaged CARLA need a 400 GB Docker image: VERIFIED (tuto_A_add_vehicle, tuto_A_add_props).
- Walker bone poses for raised-hand gestures (`WalkerBoneControlIn`, `set_bones`, `blend_pose`) exist in the 0.9.15 Python API: VERIFIED.
- SUMO Client/Reader/Writer blocks (R2026a): VERIFIED 27 Sep.
- Finale: "December 2026, offline, 36 h". Exact date UNVERIFIED. The 2024 software finale ran 11–12 Dec.

## Claude's added cautions
- **Load:** this is ~10 weeks of work that P3/P6–P12 individually rated at 3–7 weeks each. Two builders can only do it if W2 (10 Hz) and the W2 asset gate pass. Otherwise use the cut order in §9.
- **One 8 GB GPU** has to run CARLA + extra cameras + the Simulink/SUMO loop. Measure it in W1. Surround cameras are the first thing to drop.
- All CARLA/asset work sits on the Windows lab PC (the M1 cannot run CARLA). Shourya's track depends on that one machine.

---
## 0. The idea

**For a child:** The car watches and listens, guesses what might move, and drives only when it has room to stop.

**For an expert judge:** One Simulink ego stack combines Indian-road sensing and prediction with a learned manoeuvre scorer, an independent movement verifier, and measured closed-loop tests.

## 1. Verdict

**JUDGMENT:** Two builders can build a strong **simulation system** in ten weeks if the existing stalls, camera failure, and 736 ms planner step are fixed first. “No flaws” is impossible; **“no gaps” means every P14 row and every P1 top-25 item has an owner, executable test, recorded outcome, and declared fallback**.  
**FACT:** Two RoadRunner clauses remain literal deviations. A CARLA substitute must be presented openly, even if every other planned test passes. Today’s P14 scorecard is **1 MEETS / 22 PARTIAL / 15 NOT YET / 2 DEVIATION**. [P14](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P14-PS-COMPLIANCE.md), [P2](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md)

## 2. System parts

- **Sense:** Time-stamp cameras, lidar, radar, near-field sensors, position, motion, and vehicle feedback.
- **See:** Find road edges, free space, potholes, and road users from pixels and range measurements.
- **Hear:** Receive simulated horn and siren direction/class events; test safe emergency-vehicle yielding.
- **Understand:** Track objects, recognise hand gestures, locate the car, and represent uncertainty.
- **Predict:** Make several possible short paths for each actor, including lateral moves and non-response.
- **Decide:** Rank 8–16 short manoeuvres using a small learned scorer and route progress.
- **Check:** Independently reject any manoeuvre without space and stopping margin.
- **Drive:** Send only a checked trajectory to steering, throttle, brake, and gear control.
- **Signal:** Show indicators, lights, hazards, horn request, and the driver’s current mode and fault.
- **Fall back:** Slow or stop when data, time, control, or a safe path is missing.
- **Learn:** Replay failures, add regression cases, and keep a frozen holdout untouched.
- **Prove:** Run the same stack across five PS scenes, real-video replay, faults, and shared-seed baselines.

**JUDGMENT — simulated ODD:** Test up to 30 km/h in markets and junctions, 40 km/h on village roads, and 60 km/h at the highway merge. Severe rain, fog, darkness, blocked roads, and lost localisation require sight-limited slowing or a declared stop. These are test limits, not public-road operating claims. [P13](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P13-SYSTEM-DESIGN.md)

## 3. Car specification

All listed inputs and outputs get visible ports, health flags, and traces in **one Simulink vehicle model**. Parameters are proposed simulation settings. **MUST** means a tested driving or safety function; **SHOULD** means integrated and probed if the core gates hold; **STRETCH** means no finale claim without evidence. Fast sweeps use MATLAB sensor models; selected pixel runs use CARLA 0.9.15. [P6–P8](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P6-P7-P8-SIM-TRAFFIC-SENSORS.md), [CARLA sensors](https://carla.readthedocs.io/en/0.9.15/ref_sensors/)

| Car part | Simulation source and proposed rate | What the stack actually uses it for | Priority |
|---|---|---|---|
| Front camera | CARLA RGB, ~800×450, 90°, 10 Hz; `visionDetectionGenerator` only for fast sweeps | YOLOX objects, DeepLab road mask, pose keypoints | **MUST** |
| Rear and left/right surround cameras | CARLA RGB, ~640×360, 5–10 Hz | Reverse, merge-side and near-corner visibility; measure added recall against compute cost | **SHOULD** |
| Lidar | CARLA ray-cast / MATLAB `lidarSensor`, ~32 beams, 100 m, 10 Hz | Metric obstacles, road-edge height, unknown space | **MUST** |
| Front radar; two corner radars | CARLA radar / `radarDetectionGenerator`; ~150 m and ~80 m, 20 Hz | Closing speed; corner approach in merges and junctions | Front **MUST**; corners **SHOULD** |
| Eight ultrasonic channels | `ultrasonicDetectionGenerator`, ~0.2–5 m, 10 Hz | Low-speed and reverse clearance only | **SHOULD** |
| GNSS; IMU | CARLA sensors / `gnssSensor` at 10 Hz, `imuSensor` at 100 Hz | Route position and motion propagation under GNSS loss | **MUST** |
| Wheel speed/odometry; measured steering angle | Vehicle plant outputs with slip, delay and quantisation, 50 Hz | Speed, dead reckoning, command-versus-feedback fault checks | **MUST** |
| Microphone array | **Simulated** direction + `siren`/`horn` events on a Simulink bus; no claimed waveform recogniser | Siren approach → safe yield; ambiguous horn → caution, never automatic right of way | **SHOULD** |
| Driver-monitoring camera | Recorded or synthetic cabin frames → simulated eyes-on/hands-on estimate, 10 Hz | Decide whether a takeover was actually acknowledged | **SHOULD** |
| Rain and light sensors | CARLA weather/illumination → noisy scalar Simulink signals | Adjust visibility confidence; command low beams and wipers | **SHOULD** |
| CAN-style bus | `Simulink.Bus`, counters, delay/drop injection, 50 Hz | Timed command and feedback path; **no physical CAN claim** | **MUST** |
| Steer, throttle, brake; P/N/D/R gear | 3DOF/bicycle plant and CARLA `VehicleControl`, 50 Hz; zero-speed reverse interlock | Execute checked paths, stop, and test reverse clearance | **MUST** |
| Indicators, brake/reverse lights, hazards | Simulink signal bus; CARLA `VehicleLightState` where the blueprint supports it | Announce turns and a minimal-risk stop | **MUST** |
| Low/high beam; wipers | Light-state commands; wiper command logged unless a wet-camera effect is modelled | Low beam supports night tests; high beam and wipers earn a safety claim only with a measured sensing effect | Low **MUST**; high/wipers **SHOULD** |
| Horn | Event and optional sound overlay; actor response swept, never assumed | Communication trace; no claim that others obey it | **SHOULD** |
| Driver display and takeover input | Simulink Dashboard + Stateflow mode, reason, timer and acknowledgment | Explain faults; without an acknowledged handoff the car attempts its own stop | **MUST** |

A 3DOF vehicle runs broad sweeps; 14DOF is a **SHOULD** ride and wheel-load check for potholes, not a substitute for the main loop. **V2X is deliberately out:** this ODD cannot depend on roadside messages being present. [P9–P12](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md)

**FACT — asset cost:** CARLA 0.9.15 custom driveable vehicles require a source build and Unreal Editor. Its Windows guide specifies **165 GB disk**, the CARLA **UE4.26 fork**, and **Visual Studio 2019** with Windows 8.1 SDK, x64 C++ toolset and .NET 4.6.2; VS 2022 is documented with a Windows 10/11 SDK and explicit generator. The build is described as **4 hours or more**. Packaged custom-prop ingestion instead describes a first-time **400 GB Docker image**. The W1 lab audit checks free disk, toolchain, Unreal GitHub access, GPU memory and actual build time before promising Indian actors. [Windows build](https://carla.readthedocs.io/en/0.9.15/build_windows/), [custom vehicle](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_vehicle/), [custom props](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_props/)

## 4. Interface contract

**JUDGMENT — fixed rule:** Every message has `run_id`, increasing `seq`, capture/simulation timestamp in seconds, `source`, `valid`, `age_s`, and a frame identifier. World positions use **ENU metres**; ego positions use **forward-left-up (FLU)** metres; speed is m/s and angles are radians. The CARLA and vehicle-plant adapters convert axes, with assertion tests. Ground truth enters evaluation only. Preserve the frozen S1–S8 class IDs and `TrackList`; `PYield` cannot grant movement. [Frozen contract](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/05-ASSETS/PRD.md:192)

| Message: producer → consumer | Fixed payload beyond header | Rate; frame |
|---|---|---|
| `ScenarioTickV1`: world → harness | Scenario, seed, backend, actor-policy version, route, fixed step | 10 Hz planning tick; world ENU |
| `SensorPacketV1`: adapters/replay → perception | Modality, sensor/calibration IDs, extrinsics, data, covariance, dropout | Camera/lidar 10; radar 20; GNSS 10; IMU 100 Hz; native frame |
| `VehicleStateV1`: localisation → all ego blocks | Pose/covariance, velocity, acceleration, yaw rate, wheels, measured steer, gear, friction/quality | 50 Hz; ENU pose, FLU motion |
| `RouteMapV1`: map/route → planner | Route centre hint, surface/edge confidence, static exclusions, version | On change, heartbeat 1 Hz; ENU |
| **Frozen S1 `TrackList`:** tracker → downstream | Existing ID, class, position/velocity/extent/yaw, existence, age, sensor mask | 10 Hz; FLU |
| `FreeSpaceV1`: perception → proposer/verifier | Grid origin/resolution, free/occupied/**unknown**, edge confidence, visible range | 10 Hz; FLU |
| `GestureV1`: front-image pose path → belief | Actor/track ID, keypoints, `ped_stop`/`police_stop`/`police_proceed`/`rider_turn`/`unknown`, confidence, visibility | 10 Hz; image keypoints + FLU actor bearing |
| `AudioEventV1`: simulated microphone array → belief/monitor | `siren`/`horn`/`unknown`, bearing rad, confidence, onset, optional source track | Event + 10 Hz health; FLU bearing |
| `DriverStateV1`: cabin camera → HMI/monitor | Eyes-on, hands-on, confidence, acknowledgment, age | 10 Hz; cabin |
| `BeliefV1`: belief → prediction/proposer | Track IDs, intent including group/cover, five response coefficients, unmodelled mass | 10 Hz; FLU |
| `MotionSetV1`: prediction → proposer/verifier | Top-K candidate-conditioned metric paths and occupied regions, coverage/fallback flag, 2–3 s horizon | 10 Hz; FLU |
| `CandidateSetV1`: proposer → verifier | 8–16 sampled pose/speed/curvature paths, executed prefix, planned stop, progress | 10 Hz; FLU |
| `CertificateV1`: verifier → monitor/control | Accepted ID **and path hash**, veto reason, clearance, stopping margin, assumed data ages, expiry | 10 Hz; FLU |
| `ActuatorBusV1`: control → plant/CARLA | Steer rad, throttle/brake 0–1, P/N/D/R, command and applied-feedback counters | 50 Hz; vehicle |
| `SignalHMIV1`: decision/monitor → car/display | Indicators, hazards, beams, brake/reverse lights, horn, wipers, mode, fault, takeover request/ack/deadline | On change; 10 Hz heartbeat |
| `RunRecordV1`: harness → replay/evaluation | Message hashes, versions, seed, separate truth, contacts, timing, outcome | Every tick; `results/<run>/` |

**Permission order:** gesture, siren, prediction and learned score may make the car **more cautious**. Only the independent verifier issues a movement certificate; the monitor may revoke it for stale data or faults. Control cannot change the certified path into a different manoeuvre. A police “proceed” gesture changes the priority hypothesis **but never opens the movement gate by itself**. CARLA 0.9.15 supports scripted walker bone poses, so W6 can render a raised hand; rider signals need a scripted animation or visual asset and remain separately tested. [CARLA walker API](https://carla.readthedocs.io/en/0.9.15/python_api/), [P3](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md)

**Timing target, not today’s result:** synchronized snapshot → validated command ≤100 ms: transport 10, perception 30, localisation/tracking 10, belief/prediction 15, proposals 10, verifier 15, control/monitor 5, slack 5 ms. Measure full sensor-to-actuation age separately. The planner alone currently takes **735.8 ms/step**. [P2](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md)

## 5. Ten weeks, two parallel tracks

**A = Aditya, brain/safety/evaluation; S = Shourya, world/assets/perception.** Both merge into the **same Simulink model every week** and run schema, timing, contact and replay checks. Mac M1 handles MATLAB fast sweeps and editing; the Windows 8 GB GPU PC runs CARLA 0.9.15 + the selected Simulink/SUMO integration; DGX A100 trains models, not the rendered demo. SUMO owns reactive traffic, the bridge mirrors its actor states into CARLA, and Simulink owns ego control. The verified R2026a SUMO Client/Reader/Writer path is used; no simulator independently steers the same actor. [P13](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P13-SYSTEM-DESIGN.md), [P14 correction](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P14-PS-COMPLIANCE.md)

| Week | A: brain, safety, evaluation | S: world, assets, perception | **One weekly exit gate** |
|---|---|---|---|
| **W1, 1–7 Oct** | Reproduce and fix S2 contact/stall and dense S3 stall; preserve before/after traces. | Audit 165 GB/toolchain/UE access; start source build and asset licence/mesh inventory; prepare real-data splits. | On ≥3 fixed seeds each, S2 and dense S3 have **zero contact** and no >10 s false stall when an oracle gap exists; source-build feasibility recorded. |
| **W2, 8–14 Oct** | Remove the capsule-list hotspot; 8–16 candidates, exact swept check, stop certificate, persistent `BLOCKED`, late-plan brake. | **Spawn one custom prop and one custom driveable vehicle in CARLA** as the source-build proof. | Fast-tier p99 validated-plan time **≤100 ms over ≥1,000 ticks**, 100 unsafe candidates vetoed, **and** both custom asset types spawned. A failed asset gate immediately invokes the disclosed surrogate plan below. |
| **W3, 15–21 Oct** | Version the buses; compile planner **and verifier** entry points with MATLAB Coder to MEX; compare outputs and veto decisions across ≥10,000 normal/boundary cases. | Continue auto/e-rickshaw/tractor and cattle/roadside prop pipeline; establish CARLA sensor calibration and bridge smoke test. | One five-minute S1 run in the unified model, no frame assertion, command-loss stop, and MATLAB/MEX decision equivalence. Measure compiled p99; standalone C is a **SHOULD** extension. [MATLAB Coder verification](https://www.mathworks.com/help/coder/ug/how-to-test-mex-functions.html) |
| **W4, 22–28 Oct** | Close 50 Hz localisation, map hint, Stanley+PI baseline, actuator feedback, gear/HMI/Stateflow fault path. | Diagnose YOLOX’s **zero render boxes**; connect front RGB, lidar and radar to detection, road mask and frozen S1 tracks; start real-clip `SensorPacketV1` replay. | Five minutes of sensor → track → certificate → executed steering/brake in one model; injected sensor/command loss gives a logged stop. |
| **W5, 29 Oct–4 Nov** | Add top-K metric occupancy, conservative reachable fallback, response belief and small scorer; `PYield` remains closed. | Label held-out rendered frames for all four PS classes; run held-out **real Indian frames** and one self-recorded Meerut/Najibabad dashcam clip through the **same** Simulink perception→tracking path. | No zero-box render result; publish per-class sample count and recall at fixed IoU/distance for render **and real**, plus `real recall − render recall`. Publish trajectory coverage/fallback rate; ML-score changes alone never bypass a veto. |
| **W6, 5–11 Nov** | Add gesture-to-belief/right-of-way path; test police stop/proceed and pedestrian request with verifier still closed. | Finish detailed CARLA village and unsignalled junction variants; script walker raised-hand poses and rider-signal visuals; build remaining assets. | Two scenes drive the same model; **all scripted stop gestures slow/stop**, and **zero proceed gestures alone cause an uncertified GO**. |
| **W7, 12–18 Nov** | Connect SUMO Client/Reader/Writer, reactive response belief, siren-yield behaviour and P16 yield-rate sweep. | Mirror SUMO actors into CARLA, finish five route manifests, and inject microphone-array events, auto stops and cattle onset. | ≥1,000 synchronized ticks with matching IDs/time/pose; changed ego action changes an actor response; safe siren-yield probe passes; one seeded run exists for each PS scenario. |
| **W8, 19–25 Nov** | Run top-25 plus six communication probes, fault/degraded modes, 10 Hz **full camera-in-loop** timing and five-scene gate; freeze core demo. | Add F1–F10 compositions, rain/fog/night variations and optional 14DOF pothole subset; replay a mined failure. | **5 scenarios × 10 declared seeds**: target ≥9/10 completions and zero disqualifying contacts per scene; every failed/blocked run has a reason. Report full-loop p50/p95/p99 and deadline misses; a missed 10 Hz gate is a failed claim. |
| **W9, 26 Nov–2 Dec** | Frozen holdout, shared-seed current/always-yield/rule baselines, exact PS metrics, intervals and claim ledger. | Recheck real-versus-render gaps and packaged asset performance; film matched run IDs. | Report contact, false-blocked, completion, jerk, curvature and timing by scene/family. **299 independent fast-tier seeds** support a <1% one-sided 95% bound **only if all 299 have zero failures for that specified distribution**; smaller CARLA results remain separate. [P9–P12](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P9-P12-CONTROL-DATA-EVAL-COMPUTE.md) |
| **W10, 3–9 Dec, buffer** | Fix release blockers; finish report, scenario/result package and eight-minute script. | Fresh-machine replay and final video; preserve failures and substitutions. | One-command replay reproduces run IDs and metrics; all **40 P14 rows** point to evidence, failure, or the two explicit RoadRunner deviations. Move this gate earlier if the official finale is earlier. |

**Asset fallback, declared at W2:** If the source-build proof fails, use packaged CARLA props or available blueprints; move a cattle prop kinematically each tick with `set_transform`, and use an existing driveable vehicle blueprint resized as an **auto behaviour surrogate**. A true three-wheel mesh swap occurs **only if** the source build works. A surrogate does **not** prove realistic auto pixels or three-wheel physics; real auto frames test the detector separately, and the scene film states the limitation. CARLA documents `set_transform`; it teleports an actor, so the step size and collision behaviour must be checked. [CARLA Python API](https://carla.readthedocs.io/en/0.9.15/python_api/)

**Shortlist risk — FACT:** The shortlist and exact finale dates are unverified. **JUDGMENT:** W1–W3 are worthwhile regardless because they repair current failures, establish 10 Hz feasibility, and expose the asset constraint. Re-plan within 48 hours of an official shortlist/date announcement; do not spend W4–W10 effort against an assumed date. [P0](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P0-RULES.md)

## 6. Traceability

The row numbers below follow the **40 P14 compliance rows in order**. **40/40 have a planned gate; this does not mean 40/40 will pass.** `C24` and `C35` remain **DEVIATION**, since two CARLA scenes replace RoadRunner scenes without a waiver. [P14](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P14-PS-COMPLIANCE.md)

| P14 rows | Gate and evidence |
|---|---|
| `C01–C03` adaptive, mixed traffic, joined pipeline | W1, W4, W7–8: executed model and reactive-run logs |
| `C04–C08` sensors and four named classes | W4–5: in-loop detections, render/real recall, track traces |
| `C09–C10` short and irregular prediction | W5–8: metric coverage and reachable-fallback tests |
| `C11–C12` collision check and timing | W2–3, W8–9: veto/contact tests and compiled/full-loop latency |
| `C13–C18` markings, merge, sudden users, obstacles, wrong-way, potholes | W4–8: named scenario probes and fault traces |
| `C19–C23` five PS scenarios | W6–8: five manifests, films and 10-seed result rows |
| `C24`, `C35` RoadRunner scenes/tool | W2, W6, W10: **permanent disclosed deviation**; two CARLA substitutes |
| `C25–C27` scene use, model, scenarios | W4, W7–8: same `.slx`, versioned scenarios and run IDs |
| `C28–C31` results and three separate metrics | W8–9: raw logs, latency, jerk/curvature, completion |
| `C32–C34` report, video, closed loop | W7–10: report, matched-run film, actor-response evidence |
| `C36–C40` encouraged MathWorks tools | W2–5, W8: Automated Driving Toolbox sensor/scenario blocks; Navigation Toolbox geometry; Stateflow modes; bicycle/3DOF and optional 14DOF; Deep Learning Toolbox inference |

Each listed P1 item has a **named probe**, supplied in the indicated week and recorded in the W8 suite. A justified stop passes handling; a false stall despite an observable feasible gap fails. [P1](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P1-DIFFICULTY-CATALOGUE.md)

| Build gate | P1 IDs and probes |
|---|---|
| **W1–2** | **16** informal merge with yield/non-yield; **53** uncontrolled T-junction gap; **61** mutual yield then feasible gap; **5** wrong-way approach; **6** lead brake and stop margin |
| **W4–5** | **38** unmarked edge/unsafe shoulder; **31** low-lying cattle; **76** overlapping tracks and ID swaps; **75** person behind bus; **39** pothole depth/slow-or-avoid; **9** auto pickup stop |
| **W5–7** | **2** two-wheeler seepage; **20** midblock crossing; **1** close cut-in; **32** delayed cattle dash; **11** tractor passing sight; **21** rolling crossing; **10** bus pull-out/hidden person; **25** roadside walker turns across |
| **W7–8** | **45** construction corridor; **67** rain plus grip loss; **68** fog stopping sight; **70** unlit road; **46** blind curve sight speed; **52** service-road re-entry |
| **W6–8 additions** | **28** pedestrian raised hand; **58** police stop/proceed; **64** rider hand turn; **18** emergency vehicle behind; **62** ambiguous horn; **66** siren/flasher passage |

**Real-data limit:** IDD and DriveIndia provide annotated frames; IDD-X and METEOR provide video-related labels, but **IDD-X does not supply metric future trajectories**. Dataset access and class coverage determine which can support a prediction check. Real-video replay is **open loop**: without recorded lidar/radar and controlled counterfactual traffic, it tests perception/tracking transfer, not driving safety. Report class support and unavailable classes rather than filling gaps with invented labels. [P4–P5](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P4-P5-ML-PREDICTION-PERCEPTION.md)

## 7. Degraded modes

**JUDGMENT — initial thresholds to validate:** ego state older than 50 ms, front RGB older than 150 ms, lidar/radar older than 200 ms, or a validated plan older than 100 ms is stale. The monitor records every transition. [P13](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P13-SYSTEM-DESIGN.md)

| Failure or uncertainty | Detection → response |
|---|---|
| Late plan, missing frame or timestamp/frame mismatch | Veto new movement; recheck the remaining certified prefix; otherwise brake in known free space, hazards, `BLOCKED` |
| Missed/unknown object, occlusion or conflicting sensors | Expand occupied/unknown region; cap speed by visible stopping distance; stop if no certified corridor |
| Low prediction coverage or unfamiliar behaviour | Replace learned paths with conservative reachable regions; no ML-derived permission |
| Ambiguous hand signal or horn | Add caution/right-of-way uncertainty; never grant movement from the signal |
| Siren from behind | Locate if possible; seek a **verified** yield/pull-over path, otherwise slow/stop and signal; never swerve into an unverified shoulder |
| GNSS or map failure | IMU/wheel propagation with larger pose margin and lower speed; stop when the margin exceeds known free space |
| Rain, fog, darkness or low grip | Reduce sensor confidence and speed; low beams; stop if reliable sight is shorter than stopping distance |
| CAN, steering or brake feedback fault | Veto new paths; request takeover, hazards, attempt tested braking; log if braking cannot be guaranteed |
| No safe candidate or traffic deadlock | Persistent `BLOCKED` with reason and gap history; only a newly verified creep can move |
| Driver inattentive or takeover unacknowledged | Continue autonomous minimal-risk stop; never infer control was transferred |
| CARLA–SUMO desynchronisation | Stop and invalidate that run’s performance result |

A minimal-risk manoeuvre is a **verified deceleration within currently visible free space**, possibly toward a verified pull-over region. Late detection can make even that impossible; the log must say so.

## 8. Eight-minute finale demonstration

| Time | Judge-visible action |
|---|---|
| **0:00–0:40** | One Simulink model and car signal panel; state ODD, current mode, and the RoadRunner→CARLA deviation. |
| **0:40–1:30** | Village: unmarked edge, tractor/pushcart, front view plus lidar, checked pass or explained stop. |
| **1:30–2:20** | Unsignalled junction: raised-hand/police gesture affects belief, unsafe proposal vetoed, checked progress. |
| **2:20–3:10** | Highway merge: slow vehicle, corner approach, response belief and measured gap. |
| **3:10–4:00** | Dense market: bikes, auto stop, bus occlusion; show tracks and false-stall monitor. |
| **4:00–4:50** | Cattle onset: occupied region, stopping margin, brake and vehicle feedback. |
| **4:50–5:40** | Siren behind plus sensor dropout: safe yield or stop, hazards, takeover request and driver-state trace. |
| **5:40–6:35** | Feed a real Indian dashcam clip through the **same** perception/tracking blocks; show render-versus-real per-class recall and its gap. |
| **6:35–7:25** | Replay one mined failure and fixed regression; show compiled planner/verifier equivalence and timing trace. |
| **7:25–8:00** | Five-scenario scorecard: contacts, false stalls, completion, jerk/curvature, p50/p95/p99, deadline misses and remaining failures. |

Every scene and chart displays its run ID. If live rendering fails, the matching recorded trace and film are shown as recorded evidence, not passed off as live.

## 9. Risks and cut line

| Top risk | Gate and response |
|---|---|
| **CARLA custom assets consume the schedule** | W1 check 165 GB/UE/VS; W2 prop + vehicle spawn. If failed, use labelled surrogates and explicitly withdraw realistic-auto-render claims. |
| **736 ms planner or full camera loop misses 10 Hz** | W2 broad phase, W3 MEX equivalence/profile, W8 full-loop timing. Freeze features until the measured bottleneck is fixed; never call a late loop real-time. |
| **YOLOX gives zero render boxes or poor real recall** | W4 preprocessing/class audit, W5 held-out render and real recall by class; unknown space and lidar/radar stop path remain active. |
| **Reactive simulation rewards a false yielding assumption** | Use P16 actor-specific ranges, **sweep** pedestrian yielding, test a second actor policy and non-yield cases. P16’s published yield observations disagree sharply, so no single rate is treated as truth. [P16](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P16-INDIAN-TRAFFIC-NUMBERS.md) |
| **Safety causes permanent stalls or world sync fails** | Count false-blocked states; W7 asserts every actor ID/pose/time and ego-response link; failed sync invalidates the run. |

**Cut order if behind:** reduce custom-asset variety → rear/surround inference and driver-monitoring detail → audio waveform work (retain the W7 event probe) → 14DOF breadth → automated shadow mining → broad 90-difficulty combinations and 299-run claim. **Never cut** the same Simulink ego stack, four PS classes, five routes, front camera/lidar/radar loop, independent veto, tested brake, full-loop timing disclosure, or three separate PS metrics. If those fail, call the result a **partial integrated prototype**. The RoadRunner deviation remains in either case.

## 10. Beyond the finale

| Product-path step | Concrete next evidence |
|---|---|
| **ODD document** | Specify roads, users, weather, speeds and exit conditions using an [ISO 34503-style taxonomy](https://www.iso.org/standard/78952.html); **no compliance claim**. |
| **Safety case** | Link hazards, controls, faults and test results in a [UL 4600-style argument](https://www.ul.com/news/ul-4600-edition-3-updates-incorporate-autonomous-trucking); **no certification claim**. |
| **Jetson hardware-in-the-loop** | Port generated planner/verifier code, replay sensor logs, compare decisions and end-to-end deadlines; post-finale **STRETCH**. |
| **Real vehicle data collection** | Instrument a human-driven car to record synchronized sensors and CAN-style signals; no autonomous public-road actuation. |
| **Reusable Indian benchmark** | Publish permitted scenario manifests, actor ranges, baselines, frozen splits, failure logs and metric code, with the RoadRunner substitution stated. |

This is a **plan only**; no build or repository changes were made.