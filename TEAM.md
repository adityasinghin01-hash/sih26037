# Who is doing what

**One page. If you are not sure whose job something is, it is answered here.**
Current as of 10 September 2026 (the team restructure that replaced the old 5-person, 5-stream
model below). Idea submission deadline **20 September 2026**.

---

## The shape of the team

Not shared collaborative streams anymore. **Three independent tracks**, two of them run by two
people each doing separately-owned work — not two people splitting one job.

| Track | Who | Owns |
|---|---|---|
| **World + Integration + Pitch** | **Aditya (you)** | The scenarios, roads, junction, galli, ghat, the cow, pedestrians · lidar, radar, tracking, the near-field ring · produces `S1 TrackList` and `S9 DrivableSpace`. Plus: merging everyone's work, the live demo, the business/pitch framing. Coordinated by call, not through this repo |
| **Planner** | **Antara** | S2's lateral-commit fix · reactive multi-agent traffic (agents respond to the ego, not a script) · the live-obstacle-injection mechanism · S3 (the galli) reverse-gear/deadlock behaviour · S4/S5 if time |
| **Planner** | **Anjali** | Profiles the planner's re-solve cost first (gates the live-injection build) · the independent safety watchdog · verifies nothing regresses · owns the repeated/randomized-run rigor upgrade |
| **ML — training** | **Shourya** | Calibrates both yield models (Platt scaling) · fixes YOLOX's real domain-gap problem · runs the GRU/TCN architecture bake-off · adds the asymmetric safety-weighted loss |
| **ML — evaluation** | **Kishan** | Leave-one-station-out cross-validation · a real baseline (logistic regression) comparison · the YOLOX domain-gap measurement · wires energy-based OOD detection into the existing `Valid=false` fallback |
| **Bridge** | **Aditya B.** | Takes whatever Shourya finishes and Kishan verifies and gets it actually live-gating the planner's decisions, per condition, honestly disclosed where it still isn't |

**One thing worth flagging if you're picking this file up fresh:** "real sensing in the loop"
was on Anjali's original brief. It is **DONE** — Aditya wired `sc.senseRig`/`sc.senseStep` into
the live demo (`demo_play.m`) on 10 Sep, verified against the full test suite and a full-route
run (the 0.965m headline clearance holds under real sensing, not just ground truth). If this
still shows as open somewhere, check with Aditya before re-building it.

**There is exactly ONE interface between the World and the Planner: `S1 TrackList`**, frozen in
`AGENTS.md` section 3. That is why the tracks cannot break each other.

---

## Everyone, by name

| Who | Owns | Reads first |
|---|---|---|
| **Aditya (you)** | World, Integration, the demo, the pitch | — |
| **Antara** | Planner — S2 fix, reactive agents, live-obstacle-injection, S3 reverse/deadlock | `plan/ReadThis.md` |
| **Anjali** | Planner — profiling, safety watchdog, regression verification, randomized-run rigor | `plan/ReadThis.md` |
| **Shourya** | ML — calibration, YOLOX domain-gap fix, architecture bake-off | `ml/ReadThis.md` |
| **Kishan** | ML — evaluation, cross-validation, OOD detection | `ml/ReadThis.md` |
| **Aditya B.** | Bridge — wires Shourya/Kishan's work into the live demo panel | `ml/ReadThis.md` and `plan/ReadThis.md`, plus `sc.plannerView`/`sc.modelStatus` |

**Antara and Anjali are independent, not a split single job.** The old arrangement (below) had
one person write pure planner functions and the other own the Simulink model, specifically
because a `.slx` is a binary file two people cannot merge. That specific problem does not
describe Antara and Anjali's current work — neither's task list mentions the Simulink model.
**`plan/CONTRACT-AB.md` describes that old, no-longer-current split and should not be treated as
governing this pair.** If their files genuinely overlap, that's a conversation with Aditya, not
a pre-written rule.

---

## The main machine

**Aditya's Mac.** Confirmed by running every piece on it, not by assuming — the planner tests,
OpenTrafficLab, and the baseline have all been run there. **The demo runs on the Mac.** Everyone
else keeps developing on their own machine; this is only about where the demo runs and where
integration happens.

---

## What nobody may touch

| | Why |
|---|---|
| **`AGENTS.md` section 3** | Everyone builds against it. A silent change breaks everyone else's work. If it genuinely needs changing, that is a conversation with Aditya, not a commit |
| **`matlab/baseline/`** | MathWorks' shipped planner, unmodified. It is the competitor. Tune it to survive and a judge calls it a strawman and the result dies |
| **Someone else's independent piece** | If something in another person's area looks wrong, say so in one sentence. Do not fix it yourself |

---

## Five rules everyone follows

1. **Never invent a number.** If you did not run something to get it, write `TODO(unverified)`
2. **Never summarise an error.** All of it, first line to last. A trimmed error costs a day
3. **Disclose bugs, do not hide them.** This project's whole culture — and a real competitive
   edge — is built on saying what's still broken, out loud, before a judge finds it
4. **Never work on `main`.** Branch, then a pull request Aditya reviews
5. **Say when you are stuck, the same day.** Being quietly stuck for two days is the most
   expensive thing that can happen on a team this size

---

## An honest note about the code

Large parts of this codebase are well-tested — **344 tests passing** as of 10 Sep — but that does
not mean everything has been run on every machine. `/first-run` exists to catch exactly that gap.
**Expect something to break the first time you run it somewhere new — that is the process
working, not the repository being broken.** Send the whole error, not a summary.

---

## Retired — the old 5-person, 5-stream structure (kept for history, not current)

Before 10 September, the team was organised as Stream A (World)/B (Perception)/C (ML)/D
(Planner, split "Person A" pure functions vs "Person B" Simulink)/E (Evidence). Files like
`plan/CONTRACT-AB.md`, `ml/C-prediction.md`, `plan/D-planner.md` and `plan/E-evidence.md`
describe that structure and the work done under it (which is real, tested, and still part of
the codebase) — just not the current org chart. If you find a reference to "Stream C" or
"Person A/B" elsewhere and it's confusing, this is why.
