P15 ROUND 2. Your round 1 is strong on contract, gates and honesty. Aditya's bar is HIGHER: "finale-level
is not enough — it must surpass that, a real problem-solution plan", "use everything a car has, shown in
MATLAB", "every part connects seamlessly", and "the whole idea must be explainable to a child in ONE
sentence, while the execution is very tough". Revise with the fixes below. Keep everything that is not
challenged.

CLAUDE'S FINDINGS (verified by opening sources — act on them):
1. **CARLA custom actors are a hidden schedule killer.** CARLA 0.9.15 docs: "Add a new vehicle" — "This
   tutorial only applies to users that work with a build from source, and have access to the Unreal Engine
   Editor" (carla.readthedocs.io/en/0.9.15/tuto_A_add_vehicle/). New PROPS can be ingested into a packaged
   CARLA only via a Docker UE image that "takes 4h and 400GB to be built", or via a source build
   (…/tuto_A_add_props/). So driveable autos/e-rickshaws/tractors = UE4 source build on the Windows PC;
   static cows/potholes/stalls = props. Your W6 puts all assets in one week — wrong. Make an asset
   pipeline track starting W1 (Shourya, parallel), with an early gate: "one custom prop and one custom
   vehicle spawn in CARLA by end of W2", and a fallback (e.g. cattle as props moved kinematically each tick
   by our scenario/SUMO driver via set_transform; autos as a resized existing blueprint with a 3-wheel
   mesh swap only if source build works). Check disk/VS requirements for a Windows source build and state them.
2. **Hand signals are MISSING.** The idea explicitly promises hand-signal handling (P1 IDs 28 pedestrian
   raises hand, 58 police directs traffic, 64 rider hand signal). Add a gesture/pose path (e.g. pose
   keypoints on the front camera → gesture class → belief update / right-of-way input), a CARLA way to
   produce it (walker animation or scripted pose), an exit test, and the honest limit (a gesture may only
   make the car MORE cautious, never grant movement alone).
3. **Hearing is MISSING.** Indian driving uses horns and sirens (P1 IDs 18, 62, 66). "Everything a car has"
   → add a microphone-array channel (simulated as direction+class events: siren, horn) → emergency-vehicle
   yield behaviour. Priority SHOULD; siren-yield probe in W7.
4. **Real-world evidence, not only sim.** To surpass the finale: add open-loop runs of the perception
   (and prediction if feasible) on REAL Indian footage — IDD/IDD-X/METEOR/DriveIndia held-out clips, and
   one self-recorded Meerut/Najibabad dashcam clip — reporting per-class recall on real frames alongside
   rendered frames (sim-to-real gap number). Also a "log replay" mode: feed a recorded real clip through the
   same Simulink perception→tracking path.
5. **Deployability.** Add a codegen gate: planner+verifier compiled (MEX / embedded C via MATLAB Coder) with
   numerical equivalence tests, and timing measured on the compiled path; Jetson is a post-finale STRETCH.
6. **Driver-monitoring camera** for the takeover request (driver eyes-on/hands-on, simulated) — SHOULD.
   Rain/light sensor → auto wipers/headlamps — decide value vs decoration honestly. State V2X as
   deliberately OUT (no Indian infrastructure) in one line.
7. **Shortlist risk.** The idea shortlist date is UNVERIFIED. Say which weeks are useful even if not
   shortlisted (W1–W3 fix real bugs) and when to re-plan.
8. **Post-finale track** (one short table): what turns this into a real product path — ODD document
   (ISO 34503 style, not compliance), UL 4600-style safety case, Jetson HIL, a real vehicle data-collection
   run, the regression library as a reusable Indian benchmark. Keep it short.

FORMAT for round 2 (Aditya reads headings only; he wants concise and structured):
0. **ONE LINE a child understands** (≤20 words, no jargon), then ONE LINE for an expert judge.
1. Verdict (2 lines).
2. System parts list — every part in plain words, one line each (sense / see / hear / understand / predict /
   decide / check / drive / signal / fall back / learn / prove).
3. Car spec table (updated).
4. Interface contract (keep; add GestureV1, AudioEventV1, DriverStateV1).
5. Weekly plan — now TWO parallel tracks (A: brain/safety/eval; S: world/assets/perception), each week with
   one exit gate. Integration every week.
6. Traceability (P14 40/40, P1 top-25 + IDs 18, 28, 58, 62, 64, 66).
7. Fallbacks table.
8. 8-minute finale demo.
9. Risks + cut line.
10. Beyond the finale (short).
Tight. No filler. Cite paths/URLs. FACT vs JUDGMENT where it matters.
