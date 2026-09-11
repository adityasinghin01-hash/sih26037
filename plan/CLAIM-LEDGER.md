# The claim ledger — what we may say, and what we may not

> ## REWRITTEN IN FULL — 10 September 2026. This supersedes the 4 September original below,
> ## and its own 10 September "superseded in part" note, both kept underneath for history.
>
> Every row in Part 1 and Part 2 below was produced by re-running something today, 10 September
> 2026, on MATLAB `26.1.0.3346908 (R2026a) Update 5`, on this machine — not carried forward from
> memory of an earlier run. Where a number could not be re-run today (mainly the ML track's own
> figures, which need the Python pipeline and training data this pass did not touch), that is
> stated next to the number, not silently presented as current.

---

## Part 1 — What we CAN say, with the evidence

| Claim | Evidence |
|---|---|
| **"Our planner drives a real 610 m stretch of an actual Indian road and negotiates around a cow, computing every acceleration and steering command itself, with 0.965 m clearance on both sides for the full route."** | `demo_play('demo1')`, full route, 0 plan failures. Re-verified 10 Sep under BOTH exact ground truth and simulated lidar+radar+near-field-ring sensing — the number is unchanged between the two |
| **"Real sensing can replace ground truth in the live demo with no change to the headline S1 number."** | `demo_play('demo1', Sensed=true)`, byte-identical planner behaviour confirmed as a regression check when sensing is disabled |
| **"We built a third scenario — a 1.95 m squeeze in a residential galli, with an oncoming motorcycle, a child crossing, and a dog in the road — and the planner clears all three."** | `demo_play('demo3')`, full 382.2 m route, 0 plan failures, 0 NaN/Inf, separations +0.175 m / +0.999 m / +0.550 m, `MirrorsFolded` engages correctly through the squeeze. Four real planner-interaction bugs were found and fixed getting here — see `demo3Route.m` and `demo_play.m`'s own headers for the full account, not summarised away |
| **"We ran MathWorks' shipped urban planner, unmodified. It does not complete."** Dies at its own `error()` call at t = 19.7 s, 0 of 120 candidates collision-free | `plan/BASELINE-R2026a.md`. Reproduced 3×, two platforms (macOS Apple Silicon, Windows x86), identical to the digit |
| **"When every candidate trajectory is invalid, their planner has no defined behaviour — it raises an error."** | Their own source, `MotionPlanningUsingDynamicMapExample.m` line 193, under their own comment |
| **"Our planner checks that a path leaves us somewhere we can still stop; theirs checks only that the path itself is clear."** | `plan/D6-TRUNK-RULING.md`; `checkTerminalStop` wired at `planContingency.m`; the baseline's own `HelperDynamicMapValidator.m` does per-point checking with no terminal condition — read, never edited |
| **"344 automated tests exist against the planner, scenario, sensing, and evidence code; 335 pass, 0 fail."** The 9 Incomplete are a gitignored third-party dependency not cloned, not a regression | Re-run today, same session as this document |
| **"Every demo run ships its own evidence: a trajectory log, ten standard metrics, and the exact configuration that produced it."** | `results/<run>/{trajectories.csv, metrics.json, config.json}`, built 10 Sep. Explicitly disclosed as reusing an already-proven metric formula set, not independently re-derived against the PRD — see the file's own header |
| **"Head-on give-way is LEFT, derived from Indian law, not imported from COLREGs."** RRR 1989 reg. 2. COLREGs Rule 14 says the opposite and would steer into oncoming traffic | `chooseVelocity.m` header; caught and corrected during the D6 design pass, before any demo used it |
| **"Two barriers, no mode switch — geometry decides which binds."** `h_agent` and `h_road`, both implemented and logged every step | `velocityObstacle.m`, `roadBarrier.m`, `speedLimit.m` |

---

## Part 2 — What we must NOT say, and the honest sentence that replaces it

| ✗ Do not say | ✓ Say instead | Why |
|---|---|---|
| *"S2 works, with one disclosed clearance bug"* | **"S2 does not currently finish the route under either condition we tested today. Under exact ground truth it grazes the wrong-way rider at −0.003 m (t=17.65 s); under real sensing it collides at −0.909 m (t=12.70 s, reproducing the previously-documented figure exactly). In BOTH cases the planner then permanently stalls partway around the ring — s≈116–121 m of a 244 m route — and never reaches the ring exit."** | Re-run today, `s2_planner_run.m`, both `Sensed=true` and `Sensed=false`. The previous wording ("works, one disclosed bug") is not what a fresh run shows — it implies the route otherwise completes, and it does not, under either sensing condition |
| *"The stall is a sensing artefact"* | **"It is not — it reproduces under exact ground truth too, at a different station (s≈121 m vs s≈116 m) and holding on a different track (one stable ID under ground truth vs three different IDs in sequence under sensing). Both conditions show the same D9 WAIT-rung mechanism repeatedly finding, then losing, a viable pass and never fully clearing."** | Directly observed in both re-runs' own state timelines, not inferred |
| *"We beat MathWorks' planner"* | **"We ran theirs unmodified and it does not complete. We do not yet have both planners on one shared scenario."** | No head-to-head exists — theirs is a six-lidar urban intersection, ours is a different scenario set entirely |
| *"MathWorks' planner is broken"* | **"It fails identically on macOS Apple Silicon and Windows x86 under R2026a Update 5. An earlier MATLAB release has not been tested."** | Two platforms, one MATLAB version. Say the bound, not more |
| *"Our ML model decides who yields"* | **"As of the last figure we have (4 Sep, not independently re-run this pass), it did not clear its own pre-registered safety bar — 20.18% dangerous-error rate against a ≤1% target — so it emits `Valid=false` and the planner falls back to the geometric right-of-way role. Calibration is Shourya's current, in-progress work."** | Flagged as not re-verified this session rather than re-quoted as current fact |
| *"Validated on real road data"* | **"S1 and S3 are built on real OpenStreetMap road geometry with measured, disclosed real-vs-chosen decisions in each scenario file. S2's world geometry is real map data with an authored gyratory island (no island exists in the OSM data — stated plainly in `s2world.m`'s own header)."** | Precise about which parts of which scenario are measured vs. authored |
| *"We detect pushcarts and animal-drawn carts"* | **"S5 defines them. METEOR contains no examples of either, so no detection performance can be claimed for them."** | Features `[23,24,25,27]` are permanently dead in the frozen 31-dim vector — a data property, not a bug |
| *"344 tests pass"* — any bare number, unquoted date | **Re-run it first, every time.** Today: 344 total, 335 pass, 0 fail, 9 incomplete (needs `OpenTrafficLab/` cloned into the repo root) | This count has been wrong in project docs multiple times before, always from someone quoting it without re-running it |
| *"We pass the cow with 0.965 m clearance"* without saying which run | **"0.965 m is the real planner's own number, verified under both ground truth and real sensing, full route, 0 plan failures."** | Distinguish a planner claim from a scenario-geometry claim, every time — the discipline the 5 Sep scope note below still requires |

---

## Part 3 — Sentences to say before a judge says them for us

> **"S2, the chowk, does not currently finish the route under either ground truth or real sensing — it collides with the wrong-way rider and then stalls partway around the ring. This is the open item on the Planner track, not a hidden gap."**

> **"We do not yet have both planners — ours and MathWorks' shipped one — on a common scenario. That is real, remaining comparative work."**

> **"Our ML yield predictor has not cleared its own pre-registered safety bar, so the planner does not let it drive anything yet — it falls back to geometric right-of-way, which is the designed fallback, not a missing feature."**

Saying these costs nothing. Having them extracted from us on stage costs the project.

---

## Part 4 — If S2 or the ML gate close before the cutoff

Nothing above transfers automatically.

- If Antara's S2 fix lands: re-run `s2_planner_run.m` under BOTH `Sensed=true` and `Sensed=false` (this pass found they fail differently — a ground-truth-only re-run would miss half the picture) and quote the new numbers, replacing the Part 2 row above with whatever is actually measured, including a fresh check for the permanent-stall behaviour specifically, since a fix for the −0.909 m clearance does not automatically fix the separate stall.
- If Shourya's calibration and Kishan's evaluation clear the ≤1% dangerous-error bar: re-run the actual evaluation and quote the new figure with its confidence interval — never the old 20.18% figure past that point, in either direction.
- **If `h` still goes negative with the real planner driving, that is a finding and it gets reported.** Never clip it to make a run look clean.

---

## Status

Rewritten by Claude at Aditya's instruction, 10 September 2026, on MATLAB `26.1.0.3346908
(R2026a) Update 5`, `MACA64`. Every row in Part 1 and Part 2 traces to something re-run today
in this same session, except the ML dangerous-error-rate figure, which is explicitly marked as
last measured 4 Sep and not independently re-verified this pass.

---

<br>

# Below: the original 4 September ledger and its 10 September superseded-in-part note, kept for
# history. Do not quote numbers from this section — everything current is above.

> ## SUPERSEDED — 10 September 2026 (original note, itself now superseded by the full rewrite above)
>
> This entire ledger was written around a crisis (the probe never fires, S1 collides, the
> defensive stand-in beats us) that **has since been fixed.** What I can personally confirm as
> current, verified this session:
> - **S1 is fully solved**: 610m real route, full route completed, 0.965m clearance each side.
>   Several of Part 2's "must not say" rows below (S1 safety, "the mechanism doesn't fire",
>   "defensive beats us on S1") are now **false as written** — the honest claim has gotten
>   *stronger*, not weaker, and this ledger has not caught up.
> - **S2 still has one disclosed bug** (−0.909m, a lateral-commit tie-break) — closer to what
>   Part 2 originally described, but re-verify the exact current number before quoting it; a lot
>   has changed since 4-5 September.
> - **Real sensing is now wired into the live demo** (`demo_play.m`, `Sensed=true`) — not
>   mentioned anywhere below because it didn't exist yet.
> - I have **not** personally re-verified the ML dangerous-error-rate (20.18% below), the exact
>   current baseline framing, or most of Part 1/2's other specific numbers this session — do not
>   treat their absence from my list above as confirmation they're still accurate either way.
>
> **Before any pitch rehearsal: re-run the actual measurements this ledger depends on and rewrite
> it properly.** I'm flagging this rather than silently rewriting a new ledger myself — composing
> new stage claims from partial knowledge is exactly the mistake this file exists to prevent.

**Original version written 4 September 2026, 20:18 IST. Every row traces to something that was RUN — at that time.**

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

### (Original) Part 1 — What we CAN say, with the evidence

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

### (Original) Part 2 — What we must NOT say, and the honest sentence that replaces it

| ✗ Do not say | ✓ Say instead | Why |
|---|---|---|
| *"`h` never goes below zero"* | **"It does, and we report it. In the OpenTrafficLab harness the planner is only watching — 241 of 1815 samples negative. In the backup demo, where the planner actually drives, S1 is 47 of 1060 negative and S2 is 573 of 960."** | Three separate measured runs. `NegotiatingStrategy.m:105` is still a TODO **in the OpenTrafficLab harness only** — the backup calls the real planner and it drives |
| *"We beat MathWorks' planner"* | **"We ran theirs unmodified and it does not complete. We do not yet have both planners on one scenario."** | No head-to-head exists. Theirs is a six-lidar urban intersection; ours is the OpenTrafficLab T-junction |
| *"MathWorks' planner is broken"* | **"It fails identically on macOS/Apple Silicon and Windows x86 under R2026a Update 5."** | Two platforms, **one MATLAB version**. Older releases untested |
| *"We formally verified our safety property"* | **"We log the barrier every step of every run, and the runs are reproducible."** | E9 cancelled — the 8 toolboxes are **absent from the INSTALL, not from the licence**. Corrected 5 Sep: `license('checkout', ...)` succeeded live for MATLAB/Simulink/Embedded Coder, Simulink Test, Design Verifier, Coverage and Requirements Toolbox; `Fusion_Toolbox` correctly failed as a control. Installing them is Add-Ons, GUI only. **Do not say "not on our licence" — it is false and checkable** |
| *"Latency on hardware"* / *"PIL timing"* | **"Simulation timings."** | No MATLAB/Simulink/Embedded Coder on this licence |
| *"Our ML model decides who yields"* | **"It does not clear its own safety bar, so it emits `Valid = false` and the planner falls back to geometry. Here is the number."** | 20.18% dangerous-error rate against a ≤1% target |
| *"Validated on real road data"* | **"Tested against hand-constructed S9/S10. Not yet validated against World data."** | `matlab/+sih/+scenario/` and `+perception/` are empty |
| *"We detect pushcarts and animal-drawn carts"* | **"S5 defines them. METEOR contains no examples, so we cannot claim detection performance for them. Cows and tractors are present."** | Features `[23,24,25,27]` are dead - dog, pushcart, animal-drawn cart, static obstacle |
| *"51 / 42 / 213 / 214 tests pass"* — any bare number | **Re-run it first.** `main` = 51 tests / 50 pass. `stream-d-a` = **304 total, 303 pass, 1 fail, 0 incomplete** (5 Sep) — and only with `OpenTrafficLab/` cloned into the repo root; without it 7 tests silently SKIP | The count has been wrong in the docs **five** separate times |
| *"The car probes, reads the response, then commits"* | **"The mechanism is implemented and the gate that triggers it does not currently open. Here is the measurement."** | `any(contains(o.Reason,"probe"))` = **0** in both S1 and S2. `plan/BACKUP-PROBE-FINDING.md` |
| *"We pass the cow with 0.95 m clearance"* | **"The written manoeuvre does not run. Measured closest approach to the cow is 3.656 m."** | Per-actor minimum distance, S1, 1060 samples |
| *"A defensive planner freezes where ours gets through"* | **"Not yet. On both scenarios the defensive stand-in currently does better than we do, and that is what we are fixing."** | S1: defensive 50.6 s vs ours 53.0 s. S2: defensive 208.5 m vs ours 90.9 m of 382.6 m |
| *"S1 is collision-free"* | **Say nothing about S1 safety until it is fixed.** | `MC_WRONGSIDE` closes to **0.735 m** centre-to-centre against 1.30 m of body. The bodies overlap |

---

### (Original) Part 3 — The two sentences to say before a judge says them for us

> **"We do not yet have both planners on a common scenario. That is the next piece of work."**

> **"Our planner drives the demo — it computes every acceleration in it. In the separate
> multi-agent OpenTrafficLab harness it is still only observing, and we will say which one you
> are watching."**

> **"The negotiation mechanism is built and its trigger is not firing yet, so what you are seeing
> is the barrier and the geometry, not the probe."** — say this only while
> `plan/BACKUP-PROBE-FINDING.md` step 1 is outstanding. Once the gate is fixed, delete this line
> and re-measure.

---

### (Original) Status

Written by Claude at Aditya's instruction, 4 September 2026. Every claim in Part 1 was produced by
running something on MATLAB `26.1.0.3346908 (R2026a) Update 5`. Part 2 exists because each of those
sentences was, at some point today, something this project believed and could not support.
