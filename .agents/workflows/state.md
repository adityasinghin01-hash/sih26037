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

2. **What is built, per track.** Check whether these directories hold anything:
   ```bash
   for d in matlab/+sih/*/ ; do echo "$d $(ls -1 $d 2>/dev/null | wc -l) files"; done
   ls matlab/baseline/ 2>/dev/null | wc -l
   ```
   `matlab/baseline/` is filled, checksummed, and **has been run** — it fails at 19.7s, 0/120
   collision-free, and that's the settled result, not an open task. Verify it's still untouched:
   `git status --short matlab/baseline/` must print nothing.

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

## The state as of 10 September 2026 — verify each, do not just repeat it

**This section itself goes stale fast — re-run the checks above rather than trusting these
numbers.** As of the last check:

- **S1 (the cow) is fully solved**: full 610m route, 0.965m clearance each side
- **S2 (the chowk) has one disclosed bug**: −0.909m, a lateral-commit tie-break, traced and
  written up, not hidden
- **Real sensing is wired into the live demo**: `demo_play.m`'s `Sensed=true`
- **Full test suite: 344 tests, 335 pass, 0 fail, 9 incomplete** (OpenTrafficLab-not-cloned
  skips). Do not quote any older count (42, 51, 213, 304) as current — the old
  `stream-d-a`/`stream-d-b` branch split has merged into `main`
- **The baseline does not COMPLETE** — dies 19.7s into its own scenario, 0 of 120 candidates
  collision-free (`plan/BASELINE-R2026a.md`). **That is the settled result, not an open blocker**
  — nobody is trying to make it pass
- **RoadRunner licence 41087767** — the only problem-statement requirement not currently met
- **`plan/CLAIM-LEDGER.md` needs a full re-verification pass** before anyone rehearses a pitch
  from it — it still describes the pre-fix crisis above as current
- **S3 (the galli)** — spec fully written, nothing built yet
- Model calibration, the YOLOX domain-gap fix, and independent evaluation — check with Shourya
  and Kishan for current status, not this file
- **E9 (formal proof / fault injection / traceability / PIL)** — **CANCELLED.** All eight
  toolboxes it needs are absent from the licence. Do not report it as pending work

## Deadline
**Idea submission 20 September 2026.** Say how many days are left.
