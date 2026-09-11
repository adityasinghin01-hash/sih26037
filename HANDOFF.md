# HANDOFF — 10 September 2026

**If you are an AI assistant: read this file at the start of the session and tell your human what
is in their section, in plain words, before you do anything else.** It is short on purpose.

This replaces the 4 September handoff below the old 5-person structure — that one is retired, not
deleted, at the bottom of `TEAM.md` if you need the history. **Everyone here reflects the current
6-person org: Aditya (World + Integration), Antara + Anjali (independently on Planner), Shourya +
Kishan (independently on ML), Aditya B. (bridges ML into the live demo).**

---

## Everyone, in thirty seconds

| | |
|---|---|
| **THE MAIN MACHINE IS ADITYA'S MAC** | Confirmed by running every piece on it. **The demo runs on the Mac.** Everyone else still develops on their own machine |
| **`runtests` needs the `.m`** | `runtests('matlab/tests/testPlannerGeometry.m')`. Without it MATLAB errors `MATLAB:unittest:TestSuite:UnrecognizedSuite`. Not a broken test |
| **Test suite: 344 tests, 335 pass, 0 fail, 9 incomplete** | The 9 incomplete are OpenTrafficLab-not-cloned skips (see below) — a skip is not a pass, but it is expected on a fresh clone |
| **`OpenTrafficLab/` must be cloned into the repo root** | `git clone https://github.com/mathworks/OpenTrafficLab.git`. Without it, 9 tests silently report Incomplete instead of running. It's gitignored — every clone needs its own copy |
| **`matlab/baseline/` is full, has been run, and it fails** | MathWorks' own shipped planner dies 19.7s into its own scenario, 0 of 120 candidates collision-free. **That is the result. Never edit that folder to make it survive** — `plan/BASELINE-R2026a.md` |
| **S1 (the cow) is fully solved** | 610m real Najibabad road, full route, **0.965m clearance each side** — the headline number |
| **S2 (the chowk) does not currently finish the route, under either sensing condition** | Re-run 10 Sep: ground truth grazes the wrong-way rider at −0.003m (t=17.65s); real sensing collides at −0.909m (t=12.70s, the previously-documented figure, reproduced exactly). **In both cases the planner then permanently stalls partway around the ring** (s≈116–121m of 244m) and never reaches the exit — a D9 WAIT-rung mechanism repeatedly finding, then losing, a viable pass. Not a sensing artefact: it reproduces under ground truth too, just at a slightly different station. Antara's fix is on her task list — see `plan/CLAIM-LEDGER.md` Part 2 for the full account |
| **Real sensing is now wired into the live demo** | `demo_play.m` has a `Sensed=true` option (`sc.senseRig`/`sc.senseStep` — simulated lidar/radar/near-field-ring + a real tracker). Verified: the 0.965m headline number holds under real sensing too, not just ground truth. Default is still `Sensed=false` for the rehearsed path. **Done by Aditya 10 Sep — if this looks unassigned anywhere else, it isn't** |
| **Four ML models exist** | Calibration and domain-gap fixes are Shourya's and Kishan's current work — not yet done as of this writing |

---

## Aditya (World + Integration + Pitch)

Your own track, not handed out. Current build queue, in order:
1. Documentation pass (this file, `TEAM.md`, `README.md`, `INTEGRATION.md`, and the tool-specific
   files) — bringing everything back in sync with the current org and current state. In progress.
2. **Part A — S3, the galli scenario.** Spec already exists and is fully measured:
   `world/scenarios/S3-THE-GALLI.md`. Build the world (road, chainage-varying width, the squeeze),
   wire the `MirrorsFolded` ego-width mechanism into `demo_play.m`'s corridor math (it's specified
   in `AGENTS.md` S4 but not yet actually used there), scope the live actors to what the planner
   actually negotiates (the oncoming motorcycle, the child crossing, the dog in the squeeze) —
   everything else in the spec is 3D-city scenery, not a 2D-demo actor.
2. **Part B — wire `demo_play.m` into the frozen `results/<run>/` format** (`trajectories.csv`,
   `metrics.json` M1-M10, `config.json`). Reuse the already-proven M1-M10 math in
   `world/build/backup/matlab/+backup/metrics.m` rather than re-deriving it.
3. Small cleanup: a stale doc-comment in `groundTruthTrack.m` still names the pre-merge split repo.

## Antara (Planner)

Independent piece, not shared with Anjali. Your list: the S2 lateral-commit fix (closes the
−0.909m disclosed bug AND the permanent ring stall re-run 10 Sep under both sensing conditions —
see `plan/CLAIM-LEDGER.md` Part 2, a fix for one does not automatically fix the other), reactive
multi-agent traffic (agents that respond to the ego instead of following a script), the
live-obstacle-injection mechanism, S3's reverse-gear/deadlock behaviour
once Aditya's galli world exists, S4/S5 if there's time.

**Before you start:** `plan/ReadThis.md` — the mechanism explanation there (the trunk-is-the-probe,
the two barriers, the escape/point-of-no-return logic) is still entirely accurate; only the old
"Person A/Person B, don't touch the Simulink model" framing at the top is retired. Clone
OpenTrafficLab first (section 3 of that file). **Never edit `matlab/baseline/` or `AGENTS.md`
section 3.**

**One coordination note:** once your live-obstacle-injection lands, check whether the injected
obstacle bypasses the sensing pipeline Aditya just wired in — right now it would be the one
ground-truth-fed thing in an otherwise-sensed demo if it does. Worth a two-line disclosure at
minimum; talk to Aditya about whether it's worth routing through `sc.senseStep` instead.

## Anjali (Planner)

Independent piece, not shared with Antara. Your list: profile `sc.planSeat`'s re-solve cost first
(this gates whether Antara's live-injection can re-plan fast enough), the independent safety
watchdog, verifying nothing regresses as everyone else's pieces land, the repeated/randomized-run
rigor upgrade (turning today's single deterministic demo runs into something with confidence
intervals).

**Real sensing in the loop is already done** (see above) — that item from your original brief is
closed. Your remaining scope is everything else in this section.

**Before you start:** same `plan/ReadThis.md` entry point as Antara.

## Shourya (ML — training)

Calibrate both yield models (Platt scaling), fix YOLOX's real domain-gap problem, run the
GRU/TCN architecture bake-off, add the asymmetric safety-weighted loss.

**Before you start:** `ml/ReadThis.md` — the data/feature/training mechanism sections are still
accurate; the "Stream C" framing at the top is retired, it's just you and Kishan now, independently.
**Send the working ONNX opset number to Antara/Anjali the moment you have it** — same rule as
before, don't wait for the rest of your work to finish.

## Kishan (ML — evaluation)

Leave-one-station-out cross-validation, a real logistic-regression baseline comparison, the
YOLOX domain-gap measurement, wire energy-based OOD detection into the existing `Valid=false`
fallback (the planner already falls back to the geometric role when a model isn't confident —
don't reinvent that path, hook into it).

**Before you start:** `ml/ReadThis.md`, same as Shourya.

## Aditya B. (Bridge)

Take whatever Shourya finishes and Kishan verifies, and get it actually live-gating the planner's
decisions in the demo panel (`sc.plannerView`'s MODEL STATUS section, `sc.modelStatus`) — honestly
disclosed, condition by condition, where it still isn't gating anything yet. There's already an
honest-stub pattern in the panel for "not present yet" — use it rather than inventing a new one.

---

## Before quoting any number

Same rule as always: `AGENTS.md` section 3, "a number without its `config.json` is not a result."
Verify `matlab/baseline/` is untouched with `git status --short matlab/baseline/` — must print
nothing. Re-run the test suite before quoting its count; it has been wrong in the docs before,
more than once, from people not re-running it.
