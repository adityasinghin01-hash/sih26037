# The claim ledger — what we may say on the 7th, and what we may not

**Written 4 September 2026, 20:18 IST. Every row traces to something that was RUN.**

`TEAM.md`, `HANDOFF.md`, `plan/D-planner.md`, `plan/E-evidence.md`, `ml/C-prediction.md` and three
world files all refer to "the claim ledger". **It had never been written.** This is it, for the code
side. The World's visual claims are Aditya's and live elsewhere.

**Rule: if a sentence is not in the left column below, do not say it on stage.**

---

## Part 1 — What we CAN say, with the evidence

| Claim | Evidence |
|---|---|
| **"We ran MathWorks' shipped planner, unmodified. It does not complete."** Dies 19.7 s into its own scenario, 120 candidates generated, **0 collision-free** | `plan/BASELINE-R2026a.md`. Run 3x, 2 platforms, checksums OK before and after |
| **"When every candidate is invalid, their planner has no defined behaviour — it raises an error."** | Their own source, `MotionPlanningUsingDynamicMapExample.m` line 193, under their own comment |
| **"It is deterministic, not luck."** The example seeds itself `rng(2020)`; identical to the digit on macOS/ARM and Windows/x86 | Three runs, two machines |
| **"Their planner checks the path is clear. Ours checks the path leaves us somewhere we can still stop."** | `plan/D6-TRUNK-RULING.md`; `checkTerminalStop` wired at `planContingency.m:225`; trunk mode **"B" is the default** |
| **"The planner's geometry is tested."** **214 tests, 213 passing** on `stream-d-a` | Run on the Mac, 4 Sep. The 1 failure is Stream C's `testFeatureParity` |
| **"Two barriers, no mode switch — geometry decides which binds."** `h_agent` and `h_road` both implemented with tests | `velocityObstacle.m`, `roadBarrier.m`, `speedLimit.m` |
| **"Every run is reproducible and ships its own configuration."** | `sih.runExperiment` writes `results/<run>/{trajectories.csv, metrics.json, config.json}` |
| **"OpenTrafficLab does not run unmodified on R2026a; we found the two fixes."** | `plan/OPENTRAFFICLAB-R2026a.md`, both fixes outside their folder |
| **"Head-on gives way LEFT, derived from Indian law, not imported from COLREGs."** RRR 1989 reg. 2. COLREGs Rule 14 says the opposite and would steer into oncoming traffic | `chooseVelocity.m` header |
| **"We measured our own predictor against a threshold fixed before training. It fails, so the planner does not let it drive."** | `plan/S3-PYIELD-RULING.md`, 20.18% vs a 1% bar |

---

## Part 2 — What we must NOT say, and the honest sentence that replaces it

| ✗ Do not say | ✓ Say instead | Why |
|---|---|---|
| *"`h` never goes below zero"* | **"The planner is not yet in the loop. `h` is measured passively while OpenTrafficLab's car-following model drives, and it goes negative 13.3% of the time. Closing that loop is the next step."** | Measured: `min h = -0.782088`, **241 of 1815 samples negative**, deterministic. `NegotiatingStrategy.m:105` is still a TODO |
| *"We beat MathWorks' planner"* | **"We ran theirs unmodified and it does not complete. We do not yet have both planners on one scenario."** | No head-to-head exists. Theirs is a six-lidar urban intersection; ours is the OpenTrafficLab T-junction |
| *"MathWorks' planner is broken"* | **"It fails identically on macOS/Apple Silicon and Windows x86 under R2026a Update 5."** | Two platforms, **one MATLAB version**. Older releases untested |
| *"We formally verified our safety property"* | **"We log the barrier every step of every run, and the runs are reproducible."** | E9 cancelled — all 8 toolboxes absent from the licence |
| *"Latency on hardware"* / *"PIL timing"* | **"Simulation timings."** | No MATLAB/Simulink/Embedded Coder on this licence |
| *"Our ML model decides who yields"* | **"It does not clear its own safety bar, so it emits `Valid = false` and the planner falls back to geometry. Here is the number."** | 20.18% dangerous-error rate against a ≤1% target |
| *"Validated on real road data"* | **"Tested against hand-constructed S9/S10. Not yet validated against World data."** | `matlab/+sih/+scenario/` and `+perception/` are empty |
| *"We detect pushcarts and animal-drawn carts"* | **"S5 defines them. METEOR contains no examples, so we cannot claim detection performance for them. Cows and tractors are present."** | Features `[23,24,25,27]` are dead — dog, pushcart, animal-drawn cart, static obstacle |
| *"51 / 42 / 213 tests pass"* — any bare number | **Re-run it first.** `main` = 51 tests / 50 pass. `stream-d-a` = 214 / 213 | The count has been wrong in the docs three separate times |

---

## Part 3 — The two sentences to say before a judge says them for us

> **"We do not yet have both planners on a common scenario. That is the next piece of work."**

> **"Our planner computes the commands; in this run it is observing rather than driving. Closing that
> loop is the last integration step."**

Saying these costs nothing. Having them extracted from us costs the project.

---

## Part 4 — If the loop closes before the cutoff

If `chooseVelocity` is wired into `NegotiatingStrategy` and the run comes back clean, then and only
then:

- `config.json` shows `plannerInLoop: true`
- **Re-run `sih.runExperiment` and quote the NEW numbers.** Nothing above transfers automatically.
- Row 1 of Part 2 is retired and replaced with the measured result — **whatever it is.**

**If `h` still goes negative with the planner driving, that is a finding and it gets reported.**
`plan/ReadThis.md` rule 5: *never clip `h < 0` to make a run look clean. A hidden violation is the
one thing that would genuinely invalidate this project.*

---

## Status

Written by Claude at Aditya's instruction, 4 September 2026. Every claim in Part 1 was produced by
running something on MATLAB `26.1.0.3346908 (R2026a) Update 5`. Part 2 exists because each of those
sentences was, at some point today, something this project believed and could not support.
