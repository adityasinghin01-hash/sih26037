P14 accepted (saved as research/P14-PS-COMPLIANCE.md; Reader/Writer now VERIFIED by Claude). Scorecard
today: 1 MEETS / 22 PARTIAL / 15 NOT YET / 2 DEVIATION.

NEXT: PHASE P15 — THE BUILD PLAN to the Dec 2026 finale. Synthesis, xhigh. PLAN ONLY — nothing gets built
until Aditya confirms it.

Aditya's requirements (his words, paraphrased):
- Every part must CONNECT seamlessly: one running system, not separate demos.
- The final build must solve the real problem as a WHOLE system, with no gaps — every P14 row and every
  P1 top-25 difficulty must be traceable to a build step and a test.
- It must USE EVERYTHING A REAL CAR HAS, and show it in MATLAB/Simulink. Think: cameras (front, rear,
  surround), lidar, radar (front + corner), ultrasonic parking sensors, GNSS + IMU, wheel speed/odometry,
  steering-angle sensor, the vehicle bus (CAN-style signals), actuators (steer, throttle, brake, gear incl.
  reverse), and the car's outputs to other road users: horn, indicators, headlights/high beam, hazard
  lights, and a driver display (HMI) with takeover request. Decide which are real value vs decoration and
  say so; do not pad.
- Add other sensible specs yourself (e.g. timing budget per layer, fault/degraded modes, ODD statement,
  logging/replay, minimal-risk manoeuvre, driver takeover, map/localisation).

CONSTRAINTS (facts): 2 builders (Aditya + Shourya), ~10 weeks from 1 Oct 2026 to an early-Dec finale
(exact date UNVERIFIED). Mac M1 (MATLAB R2026a, no CARLA), Windows lab PC (8 GB GPU → CARLA 0.9.x),
DGX A100 (training only, no RT cores). No RoadRunner. Repo ~/dev/sih2026 branch integration/dense-planner
(8 commits, not pushed; 348 tests). Known bugs: S2 collides+stalls, dense S3 stalls at 81.4 m, 736 ms/step,
camera not in loop, YOLOX zero boxes on renders, PYield unused by planner, futures fixed-heading.

Brutal honesty: "no flaws, no gaps" is impossible for any AV. Say so in one line, then define what
"no gaps" MEANS measurably for us (e.g. every requirement traced to a test; every failure has a
declared fallback). If 10 weeks cannot fit everything, give a MUST / SHOULD / STRETCH cut and say what
falls out.

DELIVERABLE (markdown, tight):
1. One-line honest verdict on feasibility.
2. The INTERFACE CONTRACT: the fixed messages between layers (name, fields, rate, units, frame) so parts
   plug together. This is what makes it "seamless".
3. The CAR SPEC: every sensor, actuator and signalling output: model/parameters, MATLAB block/object that
   simulates it, what the stack uses it for, MUST/SHOULD/STRETCH.
4. The BUILD PHASES: week-by-week, each phase = goal | tasks | owner (A/S) | exit test (a measurable
   gate) | which P14 rows and P1 IDs it closes. Fix-the-bugs and the 10 Hz gate come first. Integration
   is continuous, not a final week.
5. The TRACEABILITY check: list any P14 row or P1 top-25 ID with no phase/test. Should be empty or
   explained.
6. Degraded modes and fallbacks table: failure → detection → response.
7. The finale demo script (what the judges see, in order, ~8 min).
8. Top risks + the cut-line if a phase slips.
Cite file paths. FACT vs JUDGMENT where it matters.
