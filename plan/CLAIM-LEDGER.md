# The claim ledger — what we may say on the 7th, and what we may not

**Written 4 September 2026, 20:18 IST. Every row traces to something that was RUN.**

> ### CORRECTED 4 September 2026, 22:0x IST — read `plan/BACKUP-PROBE-FINDING.md` first
> The backup demo was run for the first time this evening and it changed three things in this
> ledger. **The planner DOES drive** — the backup calls the real `sih.planner.*` unmodified and
> completes a 610 m route, so Part 2 row 1 and Part 3's second sentence were understating us.
> But **the probe never fires in either scenario**, S1 contains a genuine collision at 0.735 m,
> and the defensive stand-in currently BEATS us on both scenarios. Part 2 has four new rows.
> **Nothing about the probe-and-commit mechanism may be claimed until that gate is fixed.**

`TEAM.md`, `HANDOFF.md`, `plan/D-planner.md`, `plan/E-evidence.md`, `ml/C-prediction.md` and three
world files all refer to "the claim ledger". **It had never been written.** This is it, for the code
side. The World's visual claims are Aditya's and live elsewhere.

**Rule: if a sentence is not in the left column below, do not say it on stage.**

> ### SCOPE, added 5 September — read this before Part 2
> **Two different programs are called "the backup" and the rows below do not apply to both.**
> - `build/backup/matlab/+backup/` calls the real `sih.planner.*`. **Every probe, clearance and
>   stand-in number in Part 2 was measured there.**
> - `matlab/+sc/` is **the 7 September demo**. Its driver `sc.s1drive` senses nothing and makes
>   no planning claim, so nothing it measures is evidence *about the planner* — but its geometry
>   is asserted and real (free width **3.830 m**, margin **0.965 m each side**, cow motionless to
>   1 µm over 45.2 s).
>
> So "we pass the cow with 0.95 m clearance" is **forbidden as a planner claim** and **true as a
> statement about the scenario geometry**. Say which one you mean, every time.

---

## Part 1 — What we CAN say, with the evidence

| Claim | Evidence |
|---|---|
| **"We ran MathWorks' shipped planner, unmodified. It does not complete."** Dies 19.7 s into its own scenario, 120 candidates generated, **0 collision-free** | `plan/BASELINE-R2026a.md`. Run 3x, 2 platforms, checksums OK before and after |
| **"When every candidate is invalid, their planner has no defined behaviour — it raises an error."** | Their own source, `MotionPlanningUsingDynamicMapExample.m` line 193, under their own comment |
| **"It is deterministic, not luck."** The example seeds itself `rng(2020)`; identical to the digit on macOS/ARM and Windows/x86 | Three runs, two machines |
| **"Their planner checks the path is clear. Ours checks the path leaves us somewhere we can still stop."** | `plan/D6-TRUNK-RULING.md`; `checkTerminalStop` wired at `planContingency.m:225`; trunk mode **"B" is the default** |
| **"The planner's geometry is tested."** **304 tests, 303 passing** on `stream-d-a` | Re-run on the Mac, 5 Sep, 18 files, 0 incomplete. The 1 failure is Stream C's `testFeatureParity` |
| **"Two barriers, no mode switch — geometry decides which binds."** `h_agent` and `h_road` both implemented with tests | `velocityObstacle.m`, `roadBarrier.m`, `speedLimit.m` |
| **"Every run is reproducible and ships its own configuration."** | `sih.runExperiment` writes `results/<run>/{trajectories.csv, metrics.json, config.json}` |
| **"OpenTrafficLab does not run unmodified on R2026a; we found the two fixes."** | `plan/OPENTRAFFICLAB-R2026a.md`, both fixes outside their folder |
| **"Head-on gives way LEFT, derived from Indian law, not imported from COLREGs."** RRR 1989 reg. 2. COLREGs Rule 14 says the opposite and would steer into oncoming traffic | `chooseVelocity.m` header |
| **"We measured our own predictor against a threshold fixed before training. It fails, so the planner does not let it drive."** | `plan/S3-PYIELD-RULING.md`, 20.18% vs a 1% bar |

---

## Part 2 — What we must NOT say, and the honest sentence that replaces it

| ✗ Do not say | ✓ Say instead | Why |
|---|---|---|
| *"`h` never goes below zero"* | **"It does, and we report it. In the OpenTrafficLab harness the planner is only watching — 241 of 1815 samples negative. In the backup demo, where the planner actually drives, S1 is 47 of 1060 negative and S2 is 573 of 960."** | Three separate measured runs. `NegotiatingStrategy.m:105` is still a TODO **in the OpenTrafficLab harness only** — the backup calls the real planner and it drives |
| *"We beat MathWorks' planner"* | **"We ran theirs unmodified and it does not complete. We do not yet have both planners on one scenario."** | No head-to-head exists. Theirs is a six-lidar urban intersection; ours is the OpenTrafficLab T-junction |
| *"MathWorks' planner is broken"* | **"It fails identically on macOS/Apple Silicon and Windows x86 under R2026a Update 5."** | Two platforms, **one MATLAB version**. Older releases untested |
| *"We formally verified our safety property"* | **"We log the barrier every step of every run, and the runs are reproducible."** | E9 cancelled — the 8 toolboxes are **absent from the INSTALL, not from the licence**. Corrected 5 Sep: `license('checkout', ...)` succeeded live for MATLAB/Simulink/Embedded Coder, Simulink Test, Design Verifier, Coverage and Requirements Toolbox; `Fusion_Toolbox` correctly failed as a control. Installing them is Add-Ons, GUI only. **Do not say "not on our licence" — it is false and checkable** |
| *"Latency on hardware"* / *"PIL timing"* | **"Simulation timings."** | No MATLAB/Simulink/Embedded Coder on this licence |
| *"Our ML model decides who yields"* | **"It does not clear its own safety bar, so it emits `Valid = false` and the planner falls back to geometry. Here is the number."** | 20.18% dangerous-error rate against a ≤1% target |
| *"Validated on real road data"* | **"Tested against hand-constructed S9/S10. Not yet validated against World data."** | `matlab/+sih/+scenario/` and `+perception/` are empty |
| *"We detect pushcarts and animal-drawn carts"* | **"S5 defines them. METEOR contains no examples, so we cannot claim detection performance for them. Cows and tractors are present."** | Features `[23,24,25,27]` are dead — dog, pushcart, animal-drawn cart, static obstacle |
| *"51 / 42 / 213 / 214 tests pass"* — any bare number | **Re-run it first.** `main` = 51 tests / 50 pass. `stream-d-a` = **304 total, 303 pass, 1 fail, 0 incomplete** (5 Sep) — and only with `OpenTrafficLab/` cloned into the repo root; without it 7 tests silently SKIP | The count has been wrong in the docs **five** separate times |
| *"The car probes, reads the response, then commits"* | **"The mechanism is implemented and the gate that triggers it does not currently open. Here is the measurement."** | `any(contains(o.Reason,"probe"))` = **0** in both S1 and S2. `plan/BACKUP-PROBE-FINDING.md` |
| *"We pass the cow with 0.95 m clearance"* | **"The written manoeuvre does not run. Measured closest approach to the cow is 3.656 m."** | Per-actor minimum distance, S1, 1060 samples |
| *"A defensive planner freezes where ours gets through"* | **"Not yet. On both scenarios the defensive stand-in currently does better than we do, and that is what we are fixing."** | S1: defensive 50.6 s vs ours 53.0 s. S2: defensive 208.5 m vs ours 90.9 m of 382.6 m |
| *"S1 is collision-free"* | **Say nothing about S1 safety until it is fixed.** | `MC_WRONGSIDE` closes to **0.735 m** centre-to-centre against 1.30 m of body. The bodies overlap |

---

## Part 3 — The two sentences to say before a judge says them for us

> **"We do not yet have both planners on a common scenario. That is the next piece of work."**

> **"Our planner drives the demo — it computes every acceleration in it. In the separate
> multi-agent OpenTrafficLab harness it is still only observing, and we will say which one you
> are watching."**

> **"The negotiation mechanism is built and its trigger is not firing yet, so what you are seeing
> is the barrier and the geometry, not the probe."** — say this only while
> `plan/BACKUP-PROBE-FINDING.md` step 1 is outstanding. Once the gate is fixed, delete this line
> and re-measure.

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
