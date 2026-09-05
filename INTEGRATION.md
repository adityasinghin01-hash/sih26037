# INTEGRATION — the integrator's page

**Aditya only. One page. Last verified 4 September 2026, 22:0x IST, by running things.**

`README.md` orients. `TEAM.md` says who owns what. `HANDOFF.md` says what each person does next.
**This file says what is actually true right now, and what is blocking what.**

---

## The three chats

| Chat | Owns | Writes to |
|---|---|---|
| **CITY** | The full rendered world — the main attraction. Five scenarios. The component chain (light → land → roads → buildings → infrastructure → vegetation → life → blending) | `world/build/city/` |
| **BACKUP** | A fast, correct world from existing code, in case the city is not finished. **It also runs THE DEMO — it calls this repo's planner unmodified** | `~/Desktop/SIH26037-Reference/build/backup/` |
| **INTEGRATOR (this repo)** | MATLAB planner, Simulink, ML, the baseline, the evidence, the demo | everything else |

**The city is committed.** It will not be finished by the 7th and that is expected. The backup is a
fallback **for the demo**, not a change of direction. See [[sih26037-parallel-chats]].

---

## THE DEMO RUNS ON ADITYA'S MAC

Decided 4 Sep by running every piece on it, not by assuming. MATLAB `26.1.0.3346908 (R2026a)
Update 5`, `MACA64`, 11 products.

| Piece | On the Mac | Number |
|---|---|---|
| Planner, `stream-d-a` | ✅ | **304 tests, 303 pass** (the 1 failure is Stream C's) |
| Simulink + Stateflow, `stream-d-b` | ✅ | loads, 0 unresolved refs, **sims in 47 s**, logs `h` |
| OpenTrafficLab subclass | ✅ | 9/9 |
| `matlab/baseline/` | ✅ runs, **fails at 19.7 s** | same as Windows, to the digit |
| Required toolboxes | ✅ | 9/9 |
| **Backup demo, planner DRIVING** | ✅ | S1 completes **610 m in 53.0 s**. But see the probe finding below |
| **ONNX converter add-on** | ❌ **MISSING** (re-verified 21:xx: all 4 functions absent, 10 add-ons installed) | Home → Add-Ons. **NOT demo-blocking** — the 6 `.onnx` files are already on disk and the planner reads no `PYield` |
| **Coder family** | ❌ absent | MATLAB/Simulink/Embedded Coder, Simulink Test/Check/Coverage, Design Verifier, Fault Analyzer, Requirements Toolbox — **all 8. E9 is cancelled** |

Windows machines stay as the **second platform** — that is what settled the baseline question.

---

## THE PLANNER DRIVES — corrected 4 Sep 22:0x, and this reverses the old headline

**The backup demo runs the real planner and completes a 610 m route.**
`~/Desktop/SIH26037-Reference/build/backup/matlab/+backup/runScenario.m` calls
`assignRoles` -> `velocityObstacle` -> `chooseVelocity` out of THIS repository, unmodified
(`+backup/addSihPath.m` adds the path and asserts it resolves). Nothing is forked.

```
[S1] 16 road pieces built (0 rejected), route 610 m over 612 stations
  t= 22.8  COMMIT - offset 0.95 m, clearance 2.20 m
  t= 53.0  ROUTE COMPLETE at 610 m
```

**So "closing line 105 is the one thing that decides whether there is a demo" was wrong.** It
matters — it is what puts the planner in the *multi-agent* harness — but it is not the blocker.

### THE REAL BLOCKER: the probe never fires, in either scenario

`any(contains(o.Reason,"probe"))` = **0** for S1 and **0** for S2. The gate at `runScenario.m:213`
requires the binding agent to be **stationary**, and the binding agent is the one with the
smallest `h` — which is almost always something moving. So the creep-read-commit mechanism, the
whole novelty of this project, does not execute. Three consequences, all measured:

| | |
|---|---|
| **S1 is a collision** | `MC_WRONGSIDE` closes to **0.735 m** centre-to-centre against **1.30 m** of body. Ego brakes maximally (mode 2, `h = -pi/2`) and is still hit — `chooseVelocity` does no lateral avoidance |
| **S2 is a deadlock** | Stops dead at **90.9 m of 382.6 m** at t=12.8 s and never restarts. `h < 0` on **573 of 960** samples. Never commits -> reactive agent never yields -> never commits |
| **The contrast is INVERTED** | S1: defensive **50.6 s** vs ours 53.0 s. S2: defensive **208.5 m** vs ours 90.9 m. **The naive baseline currently beats us on both** |

**Full finding, with the reproduce commands: `plan/BACKUP-PROBE-FINDING.md`.**

> **SCOPE CORRECTION, 5 Sep.** Everything above measures
> `~/Desktop/SIH26037-Reference/build/backup/`, which calls the real `sih.planner.*`.
> **That is NOT the demo any more.** The 7 Sep demo is
> `~/Desktop/SIH26037-Reference/matlab/+sc/`, a different program whose driver
> (`sc.s1drive`) senses nothing and makes no planning claim. Two things are called
> "the backup" and only one of them runs the planner. The probe finding still stands
> as a finding about the planner; it is no longer the thing that decides the demo.

---

## The OpenTrafficLab harness is separate, and there the planner still only watches

`NegotiatingStrategy.m` line 105 is still:

```matlab
% TODO(stream-D): call sih.planner.chooseVelocity here
```

The cars are driven by OpenTrafficLab's Gipps car-following model. Our planner watches and logs `h`.

Measured by `sih.runExperiment`, deterministic across three runs:

```
steps 398   barrier samples 1815   min h = -0.782088   h < 0: 241  (13.3%)
```

The repo previously claimed `h min 1.3936, h < 0 count 0`. **That does not reproduce.**
`config.json` now carries `plannerInLoop: false` so no number from this runner can be quoted
without it. **Closing that loop is Person A's job after arbitration.**

---

## Merge queue

**Re-checked 5 Sep after `git fetch`. Counts below were measured, not remembered.**

| | What | State |
|---|---|---|
| **PR #10** | These two findings · the A/B contract freeze · the `world/` resync that makes the build scripts portable via `SIH_REF` | **OPEN, MERGEABLE.** 43 files, no source code, `matlab/baseline/` and `AGENTS.md` untouched |
| `stream-d-a` | D6, D8, **D9, D10 and arbitration**. **16 ahead, 0 behind** — main is merged in | **304 tests, 303 pass.** Still no PR. The ledger's claims rest on unmerged code |
| `stream-d-b` | D3, D4, D5, D7, D11, `sih_planner.slx`. **20 ahead, 0 behind** — main *and* `stream-d-a` are merged in | **The old "20 behind, head of the queue" is gone.** She is not behind and nothing waits on her |
| `stream-ml` | 4 ahead, 18 behind | docs only; no code fix pushed |
| `stream-e-baseline` | 1 ahead, 17 behind | dormant since 4 Sep |

---

## Blocking chain, in order

**Re-ordered 4 Sep 22:0x. The demo chain and the merge chain are SEPARATE — the demo needs no ML.**

**The demo chain (this decides whether there is a live demo):**
1. **Open the probe gate** (Aditya, BACKUP chat) → the mechanism actually runs → S2 stops deadlocking.
2. **Resolve the S1 wrong-side motorcycle** → S1 stops containing a collision.
3. **Re-run all four combinations** → confirm ours beats the defensive stand-in again.

**The merge chain:**
4. ~~**Anjali merges main**~~ — **DONE 5 Sep.** Both planner branches are 0 behind.
5. **Antara opens the `stream-d-a` PR.** `arbitrate` is already written and frozen in
   `plan/CONTRACT-AB.md`. **Line 105 is NOT wired and must not be.** Integration is OFF until
   the demo, the planner work and the AI work are all built — Aditya's call, 4 Sep. One clean
   integration at the end.

**The ML chain — NOT blocking the demo:**
6. **ONNX add-on** (Aditya, 5 min) → `check04` → the opset number.
   **The six `.onnx` files are ALREADY on disk** at opsets 17/18/20, and `check04` asks a
   graph question (placeholder layers), which is weight-independent. **Aditya can run this
   tonight without the ML pair.** And `chooseVelocity`/`assignRoles` contain zero `PYield`
   references — grepped — so the demo does not wait on it.

**Cutoff: expired at noon on 5 September and was not enforced.** The rule it carried still holds and is the one that matters: anything not running is written up honestly, not shipped.

---

## Before quoting ANY number

1. `plan/CLAIM-LEDGER.md` — what we may and may not say, with the honest replacement for each.
2. Test counts have been wrong in the docs **five times**. `main` = 51/50. `stream-d-a` = **304/303**. **Re-run.**
3. `matlab/baseline/` — verify, never edit: `git status --short matlab/baseline/` must print nothing.
4. A number without its `config.json` is not a result (`AGENTS.md` §3).

---

## The rulings, and who owns them

Four files in `plan/`, all written by Claude at Aditya's instruction, all overrulable by him,
all currently load-bearing:

- `D6-TRUNK-RULING.md` — trunk is **(b)**; terminal braking check; `Committed` false while on (a)
- `S3-PYIELD-RULING.md` — `PYield = 1 - P(assert)`; gate the model behind `Valid = false`
- `ARBITRATION-RULING.md` — `arbitrate(roles)` only; winner is smallest `h`
- `CLAIM-LEDGER.md` — what we may say on the 7th. **Corrected 22:0x: four new forbidden rows**
- `BACKUP-PROBE-FINDING.md` — **the probe never fires; S1 collides; the contrast is inverted**
- `HARNESS-STEERING-FINDING.md` — OpenTrafficLab discards `SteerAngle`, so `followTrunk` cannot
  drive there. Person B's `.slx` is the only harness that executes steering

**S3's safety argument depends on D6. Do not separate them.**

`AGENTS.md` section 3 has not moved all day, through a machine change, a cancelled task and three
rulings. That is the freeze doing its job.
