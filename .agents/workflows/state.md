---
description: Where SIH26037 is right now - what is built, what is unverified, what is blocked, and who is waiting on whom.
---

# /state — where the project actually is

Answer the person by **reading the repository, not by remembering.** Anything in this file is a
starting point that may be out of date; the repository is the truth.

## Do this

1. **What has moved.**
   ```bash
   git log --oneline -15
   git status --short
   git branch -a
   ```
   Report what changed recently and whether anyone has pushed a stream branch yet.

2. **What is built, per stream.** Check whether these directories hold anything:
   ```bash
   for d in matlab/+sih/*/ ; do echo "$d $(ls -1 $d 2>/dev/null | wc -l) files"; done
   ls matlab/baseline/ 2>/dev/null | wc -l
   ```
   **whether `matlab/baseline/` has been RUN is the finding that matters most** (it is filled as of
   4 Sep but never executed) — it is the competitor we
   compare against, and until MathWorks' shipped planner is in there unmodified, no number this
   project produces is comparable to anything. Say so every time it is still empty.

3. **What passes.**
   ```bash
   python3 ml/python/tests/test_contract.py
   python3 ml/python/tests/test_parity.py
   python3 ml/python/tests/test_metrics.py
   ```
   In MATLAB, if it is available: `runtests('matlab/tests')`.

4. **What has never run.** `matlab/+sih/+prediction/`, `matlab/+sih/+models/`,
   `derisk/check04_onnx_lstm.m`, `matlab/tests/testFeatureParity.m`. If `/first-run` has not been
   done on this machine, **say that before reporting anything as working.**

## Then report, in this shape

```
BUILT AND RUN     : ...
WRITTEN, NEVER RUN: ...
NOT STARTED       : ...
BLOCKED ON A HUMAN: ...
NEXT MOST USEFUL  : one thing
```

## The blockers as of 1 Sep 2026 — verify each, do not just repeat them

- **RoadRunner licence 41087767** — the only problem-statement requirement we cannot meet
- **The baseline does not COMPLETE** — run 4 Sep on both platforms, it dies 19.7 s into its own
  scenario with 0 of 120 candidates collision-free (`plan/BASELINE-R2026a.md`). E2 is blocked,
  not unstarted, and there is still no head-to-head number
- **The opset number** — Stream D cannot wire the predictor until Stream C runs `check04`
- **The ONNX converter add-on** — missing on the Mac, and it is what blocks `check04`.
  Home -> Add-Ons -> Get Add-Ons. MATLAB itself is confirmed on the Mac and both Windows
  machines; only the ML person's machine is unconfirmed

**Closed since then — do not report these as open:**
- **Does OpenTrafficLab run on our release?** Answered 4 Sep: **not unmodified.** Two fixes,
  both applied, both outside their folder — `plan/OPENTRAFFICLAB-R2026a.md`
- **D2 `chooseVelocity`** — merged 3 Sep (PR #3), 19 tests
- **The planner suites** — do NOT quote 42. On `main` it is **51 tests, 50 passing, 1 failing**
  (Stream C's `testFeatureParity`). On `stream-d-a` with D6 and D8 it is **213 tests, 212
  passing**. Re-run before quoting either
- **Which machine gives the demo?** Answered 4 Sep: **Aditya's Mac**, verified by running the
  planner, the Simulink model, OpenTrafficLab and the baseline on it — `TEAM.md`
- **E9 (formal proof / fault injection / traceability / PIL)** — **CANCELLED.** All eight
  toolboxes it needs are absent from the licence. Do not report it as pending work

## Deadline
**Idea submission 20 September 2026.** Say how many days are left.
