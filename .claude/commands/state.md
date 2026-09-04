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
- **`matlab/baseline/` has never been RUN** — filled and checksummed 4 Sep, but `checkcode`
  is not a run, so no result is comparable yet
- **The opset number** — Stream D cannot wire the predictor until Stream C runs `check04`
- **MATLAB is not installed everywhere** — Aditya's Mac has R2026a (9/9 required products,
  see `derisk/check01_output.txt`); the ONNX converter add-on is still MISSING there

**Closed since then — do not report these as open:**
- **Does OpenTrafficLab run on our release?** Answered 4 Sep: **not unmodified.** Two fixes,
  both applied, both outside their folder — `plan/OPENTRAFFICLAB-R2026a.md`
- **D2 `chooseVelocity`** — merged 3 Sep (PR #3), 19 tests
- **The planner suites** — 14 + 19 + 9 = 42 tests passing on R2026a, 4 Sep

## Deadline
**Idea submission 20 September 2026.** Say how many days are left.
