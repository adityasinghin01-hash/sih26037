# Stream E · Evidence

**You own the reason anyone believes us.** A working planner with no numbers loses to a worse
planner with a curve.

## The baseline is sacred
`matlab/baseline/` holds **"Motion Planning in Urban Environments Using Dynamic Occupancy Grid
Map"** — MathWorks' shipped example, **completely unmodified**.

Requires Automated Driving + Sensor Fusion and Tracking + Navigation Toolbox. All three are on
licence 41087767.

**Never edit anything in that folder.** If we tune the baseline to fail, a judge calls it a
strawman and the entire result dies. Record its exact example name and MATLAB version in
`docs/baseline.md` — that file is your first deliverable.

### Why it is a fair fight, and worth being able to say out loud
We picked their **strongest** relevant planner, not their weakest. It uses lidar like us, handles
pedestrians and bicycles like us, and targets an urban intersection like us. It fails at an
unmarked junction for a **structural** reason: it requires `referencePathFrenet` — Cartesian
waypoints defining a path to follow — and an unsignalled Indian junction supplies none. Its cost
function has no term for progress through a contested junction. Research section 14.

## Your job, in order

### E1 — `docs/baseline.md`. Exact example name, MATLAB release, date run, unmodified checksum.
### E2 — The experiment runner
`matlab/+sih/runExperiment.m`. One command, a config file in, `results/<run>/` out containing
`metrics.json` and a copy of `config.json`. **A number without its config is not a result.**
### E3 — The ten metrics
`docs/metrics.md`, pre-registered, M1 to M10. Implement them exactly as written.
**Do not add metrics. Do not change definitions.** They were fixed before any run precisely so
nobody can say we chose metrics that flattered us.
### E4 — The three curves
- **M1** time-to-enter, ours vs baseline
- **M2** completion vs traffic density — the headline
- **M3** completion vs perception degradation — the one nobody publishes

### E5 — Guard against winning the wrong way
**M4 and M5 must not regress against the baseline.** A faster car that is less safe is a failed
project, and we report it as one if that is what the numbers say.

### E6 — Reproducibility
One command regenerates every number from scratch. A judge can re-run ours in twelve minutes;
they cannot re-run B-GAP. That is a real advantage — make it true.


## Done when

| Task | Done means |
|---|---|
| E1 | `docs/baseline.md` names the exact example and MATLAB release, and records that it is unmodified |
| E2 | One command produces `results/<run>/` with `metrics.json` **and** a copy of the config |
| E3 | All ten metrics computed, matching `docs/metrics.md` definitions exactly |
| E4 | Three curves plotted from real runs, not placeholders |
| E5 | M4 and M5 compared against the baseline and **reported even if we lose** |
| E6 | A clean clone reproduces every number with one command |

**Four conditions apply to every task** (`docs/WORKFLOW.md`): it runs from a clean clone, a test
covers it, it matches `docs/INTERFACES.md` exactly, and someone else could run it without asking
you a question.

## Your handoff

**H6 → F:** write `results/<run>/trajectories.csv` in the exact schema in S8. Blender only reads it — MATLAB does all the computing.

**Read `docs/WORKFLOW.md` before your first commit** — branch naming, commit format, how to report
a blocker, and what to do when the contract is not enough.

---

## What you use

| | |
|---|---|
| **Stack** | MATLAB + Simulink (Automated Driving, Sensor Fusion & Tracking, Navigation) |
| **Machine** | Windows |
| **IDE / agent** | Antigravity |
| **Key functions & tools** | `trackerGridRFS` · `trajectoryGeneratorFrenet` · `referencePathFrenet` (the baseline) · `runtests` |

**Setup:** `docs/SETUP.md` — 20 minutes.
**Before you write any code:** read `docs/INTERFACES.md`. It is frozen; five other people build
against it. If your agent proposes editing it, the answer is no.

**Reference docs you will need:**
`docs/PRD.md` (the whole idea) · `docs/ROADMAP.md` (phases and gates) ·
`docs/metrics.md` (M1–M10) · `docs/CLAIM-LEDGER.md` (never state a number that is not in it)
