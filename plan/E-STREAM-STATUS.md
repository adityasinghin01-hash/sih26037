# Stream E — status, 6 September 2026

**Everything below was produced by running something, on this Mac, today. Where a piece is
blocked or was deliberately not attempted, it says so plainly rather than being left silent.**

---

## Update — 6 September, afternoon (re-verified on `stream-e-evidence`)

- **Full suite: 323 tests, 323 pass, 0 fail, 0 incomplete** — re-run on this branch with
  `OpenTrafficLab/` present, so no silent skips.
- **`matlab/baseline/`: 7 of 7 SHA-256 checksums OK, folder clean** (`git status` prints nothing).
- **`sih.runExperiment` re-run ×3: bit-identical** — steps 398, barrier samples 1815,
  min h −0.782088, h < 0 count 241, 3000 trajectory rows. Deterministic.
- **M6 re-measured clean (idle machine): median 9.1 ms, p95 26.3 ms, max 96.1 ms** — consistent
  with the 10.6 ms recorded below; it is wall-clock on this Mac and varies with machine load.
- **M7 still exactly 0.0 / 0.0** — the stub control law, no encounter. The real "before".
- **Scenario-format bug found and fixed.** `build_junction_crossing.m` saved a raw
  `drivingScenario` to a `.mat`; the Scenario Reader block **rejects that format**
  (`"not a supported driving scenario file"` — it wants a Driving Scenario Designer session).
  The script now builds `scenario` in the workspace and saves nothing; the model reads it via
  `ScenarioSource = "From workspace"` and its `PreLoadFcn` runs the script. **No `.mat` — a
  fresh clone needs no file.** Verified headless: the block loads the object and its Actors
  output carries the crossing vehicle; two `update`s in a row produce no `BusActors`
  regeneration.
- **M1 / M7 wiring prepared and tested headless**, pending Person B applying it to the `.slx`:
  a `pickOther` MATLAB Function block reads the Scenario Reader Actors bus (`NumActors`,
  `Actors(1).Position/.Velocity`, already ego-frame) and feeds `computeSafety`, which now
  calls the real `sih.planner.velocityObstacle` instead of a hardcoded phantom agent.
  Expected `h` on `junction_crossing`: ≈ −0.03 early → −π/2 at t ≈ 3.8–4.0 s (the two cars
  pass at 1.56 m) → ≈ +2.8 after. It is a genuine conflict, so h < 0 there is correct.
- **Chart note for Person B:** `NeedsReverse` is declared in the chart but never read — a
  Simulink warning fires on every run. Wire it or delete it.
- `sih.planner.defaults()` → `config.json` (the planner design numbers) stays **deferred to
  integration**, per `defaults.m`'s own header.

---

## E1 — the comparison car — DONE

`matlab/baseline/` holds MathWorks' shipped planner, unmodified, checksummed. It fails at
19.7 s, 0 of 120 candidates collision-free. Full finding: `plan/BASELINE-R2026a.md`.

## E2 — the experiment runner — DONE

`sih.runExperiment.m` exists, runs, and writes `results/<run>/{trajectories.csv, metrics.json,
config.json}` every time. Re-run today, deterministic:

```
steps 398   barrier samples 1815   min h -0.782088   h < 0: 241 (13.3%)
```

`config.plannerInLoop` is `false` in this harness — **`NegotiatingStrategy.m` line 105 was
deliberately reverted today** (`plan/PLANNER-IN-LOOP-FINDING.md`), so this number describes
traffic our planner watches, not traffic it drives. Say which one you mean, every time.

## E3 — the ten measurements — PARTIAL

| Metric | Status | Source |
|---|---|---|
| **M6** replanning latency | **MEASURED**, on the Simulink model. Clean median 10.6 ms/step, p95 35.3 ms, max 90.9 ms (two artifacts — first-step compile cost, final-step sim teardown — identified and excluded, not hidden). Wall-clock on this Mac, not a hardware timing claim | `simulink/extract_metrics.m` |
| **M7** path smoothness | **MEASURED, and it is exactly zero** — correct, not a bug. The Chart's role is currently a hardcoded constant (`GIVE_WAY`), which never commands steering, so there is no lateral motion to be smooth about yet. Becomes a real number once the wiring in the 6 Sep afternoon update lands | `simulink/extract_metrics.m` |
| **M1** time-to-enter | **BLOCKED**, wiring prepared. Needs the Chart to read a real second vehicle instead of hardcoded constants — Person B's `.slx` change, prepared and tested headless (see the 6 Sep afternoon update). The scenario is `build_junction_crossing.m` (workspace object, no `.mat`); crossing car, closest approach 1.56 m at t = 3.90 s | — |
| M2, M3, M8, M9, M10, M11 | **NOT REACHED.** M2 needs many agents *and* real planner authority at once — no harness currently has both (see below). M3 needs sensor-noise injection, not built. M8 needs the ONNX model wired in — it isn't (both models fail their own safety gate, `plan/S3-PYIELD-RULING.md`). M9/M11 (handover) live in the Stateflow chart's state machine, not this harness | — |

## E4 — the three graphs — NOT ATTEMPTED, decided out of scope

The headline graph (completion rate as traffic gets heavier, our planner driving) needs a
scenario with **many vehicles** *and* **our planner in full control**. No such harness exists:
where there are many vehicles (OpenTrafficLab), the planner only watches, and today's finding
shows wiring it in there makes the logged safety number *worse*, not better — a single-axis
(braking-only) harness cannot use "brake harder" as a universal fix. Where the planner fully
drives (the Simulink model), there is one vehicle. Building the missing piece — many agents,
planner driving, safely — is a real engineering problem, not a config change, and was
explicitly decided against attempting before the 7th. Reported here so it is said by us, not
discovered on stage.

## E5 — the safety check — DONE, with an honest result

Two things are true at once, both measured today:

1. **In the multi-agent OpenTrafficLab harness, wiring the planner to drive made the safety
   number worse, not better** — new violations on vehicles that never had them, traced to a
   single-axis (braking-only) harness where "more conservative" and "safer" come apart. **We
   did not ship it.** `NegotiatingStrategy.m` is reverted to observing. Full numbers and
   mechanism: `plan/PLANNER-IN-LOOP-FINDING.md`.
2. **In the single-vehicle Simulink harness, no genuine safety number exists yet** — the barrier
   is currently computed from the ego's own state alone, no second body in the loop. Pending
   Person B's wiring.

**So: Stream D correctly declined to ship an unsafe result. That is itself the safety-check
outcome for today**, not a placeholder. A real "does our planner keep two real vehicles safe"
number is the next thing this stream produces once E3's M1 is unblocked.

## E6 — reproducibility — DONE for what exists

`sih.runExperiment()` and `simulink/extract_metrics.m` are each one command.
`simulink/scenarios/build_junction_crossing.m` builds the crossing scenario as a workspace
object (`scenario`) and saves nothing — the model's `PreLoadFcn` runs it, so a fresh clone
needs no file. (A raw `drivingScenario` written to a `.mat` is not a format the Scenario
Reader accepts; that was a bug, fixed 6 Sep.)

## E7 — the technical report — NOT ATTEMPTED, decided out of scope

Not reachable before the 7th alongside everything else. This file is the honest substitute for
the internal round.

## E8 — the other two baselines (ORCA, always-yield) — NOT ATTEMPTED, decided out of scope

Same reason as E4/E7 — a time decision, not a technical blocker. Recorded so it is asked about
rather than assumed done.

---

## Reproduce every number in this file

```matlab
addpath(genpath('OpenTrafficLab')); addpath('matlab');
sih.runExperiment('runName','any-name')          % E2/E5 numbers
addpath('simulink'); extract_metrics()           % E3 M6/M7 numbers (current stub .slx)
runtests('matlab/tests')                          % 323/323 - needs OpenTrafficLab cloned
cd matlab/baseline && shasum -a 256 -c CHECKSUMS.txt   % 7/7 OK
run('simulink/scenarios/build_junction_crossing.m')    % builds `scenario` in the workspace
```

## Status

Written by Claude at Aditya's instruction, 6 September 2026 (first pass in the morning, the
afternoon-update block added after re-verification). Every number above traces to a command in
this file. `matlab/baseline/` and `AGENTS.md` section 3 untouched.
