# INTEGRATION — the integrator's page

**Aditya only. One page. Last verified 4 September 2026, 20:xx IST, by running things.**

`README.md` orients. `TEAM.md` says who owns what. `HANDOFF.md` says what each person does next.
**This file says what is actually true right now, and what is blocking what.**

---

## The three chats

| Chat | Owns | Writes to |
|---|---|---|
| **CITY** | The full rendered world — the main attraction. Five scenarios. The component chain (light → land → roads → buildings → infrastructure → vegetation → life → blending) | `world/build/city/` |
| **BACKUP** | A fast, correct world from existing code, in case the city is not finished | `world/build/backup/` |
| **INTEGRATOR (this repo)** | MATLAB planner, Simulink, ML, the baseline, the evidence, the demo | everything else |

**The city is committed.** It will not be finished by the 7th and that is expected. The backup is a
fallback **for the demo**, not a change of direction. See [[sih26037-parallel-chats]].

---

## THE DEMO RUNS ON ADITYA'S MAC

Decided 4 Sep by running every piece on it, not by assuming. MATLAB `26.1.0.3346908 (R2026a)
Update 5`, `MACA64`, 11 products.

| Piece | On the Mac | Number |
|---|---|---|
| Planner, `stream-d-a` | ✅ | **214 tests, 213 pass** (the 1 failure is Stream C's) |
| Simulink + Stateflow, `stream-d-b` | ✅ | loads, 0 unresolved refs, **sims in 47 s**, logs `h` |
| OpenTrafficLab subclass | ✅ | 9/9 |
| `matlab/baseline/` | ✅ runs, **fails at 19.7 s** | same as Windows, to the digit |
| Required toolboxes | ✅ | 9/9 |
| **ONNX converter add-on** | ❌ **MISSING** | the only real gap. Home → Add-Ons |
| **Coder family** | ❌ absent | MATLAB/Simulink/Embedded Coder, Simulink Test/Check/Coverage, Design Verifier, Fault Analyzer, Requirements Toolbox — **all 8. E9 is cancelled** |

Windows machines stay as the **second platform** — that is what settled the baseline question.

---

## THE ONE THING THAT DECIDES WHETHER THERE IS A DEMO

**The planner does not drive.** `NegotiatingStrategy.m` line 105 is still:

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

| | What | State |
|---|---|---|
| **PR #9** | Mac is main machine · baseline confirmed on Windows · E9 cancelled · arbitration ruling · runExperiment · claim ledger | **OPEN — Aditya to merge** |
| `stream-d-a` | D6 with terminal check, trunk mode **B by default**, D8. Merged main already | Antara to open a PR |
| `stream-d-b` | D3, D4, D5, D11. **10 commits behind, no merge commit.** Still has the ego-in-its-own-TrackList defect | Anjali to merge main first |

---

## Blocking chain, in order

1. **ONNX add-on** (Aditya, 5 min) → `check04` → **the opset number** → the planner can wire the predictor.
2. **Arbitration** (Antara) → **wiring `chooseVelocity` at line 105** → the loop closes → `h` means something.
3. **Anjali merges main** → her `h` stops being computed from a poisoned track list.

**Cutoff: 12:00 noon, 5 September.** Anything not running by then is written up honestly, not shipped.

---

## Before quoting ANY number

1. `plan/CLAIM-LEDGER.md` — what we may and may not say, with the honest replacement for each.
2. Test counts have been wrong in the docs **three times**. `main` = 51/50. `stream-d-a` = 214/213. **Re-run.**
3. `matlab/baseline/` — verify, never edit: `git status --short matlab/baseline/` must print nothing.
4. A number without its `config.json` is not a result (`AGENTS.md` §3).

---

## The rulings, and who owns them

Four files in `plan/`, all written by Claude at Aditya's instruction, all overrulable by him,
all currently load-bearing:

- `D6-TRUNK-RULING.md` — trunk is **(b)**; terminal braking check; `Committed` false while on (a)
- `S3-PYIELD-RULING.md` — `PYield = 1 - P(assert)`; gate the model behind `Valid = false`
- `ARBITRATION-RULING.md` — `arbitrate(roles)` only; winner is smallest `h`
- `CLAIM-LEDGER.md` — what we may say on the 7th

**S3's safety argument depends on D6. Do not separate them.**

`AGENTS.md` section 3 has not moved all day, through a machine change, a cancelled task and three
rulings. That is the freeze doing its job.
