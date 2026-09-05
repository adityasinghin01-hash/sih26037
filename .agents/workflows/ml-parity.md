---
description: Prove the Python feature builder and its MATLAB twin still produce identical vectors. Run after any change to features.py.
---

**The person you are helping has `ml/ReadThis.md`** — the plain-language roadmap for this
stream. Point them at it rather than re-explaining. `ml/TROUBLESHOOTING.md` has every error we
have already hit, with its real cause.

## Stay inside the ML stream

| Yours | NOT yours — say so in one sentence and stop |
|---|---|
| `ml/` and everything in it | `matlab/+sih/+planner/` and the Simulink model — Stream D |
| `matlab/+sih/+prediction/` — the feature twin | `plan/` and `plan/CONTRACT-AB.md` — Stream D's roadmap |
| `matlab/+sih/+models/` | `matlab/+sih/+scenario/`, `+perception/` — Streams A and B |
| `ml/python/tests/` | `matlab/baseline/` — the competitor. **Never** |

**You produce `S3 PYield`. You never consume it.** The planner reads it through the contract and
never opens your model; you never open theirs. If the planner looks like it is misusing your
output, that is a message to a human — **not** a reason to go and read `matlab/+sih/+planner/`.

Reading across that line is how two people end up with two versions of the same thing, and nobody
knows which one the demo used.

# /ml-parity — keep the two feature builders identical

## Why this exists

The yield model is **trained** by `ml/python/meteor/features.py` and **run** by
`matlab/+sih/+prediction/buildFeatureFrame.m`.

If those two ever disagree, the network is fed different numbers at inference than it saw in
training. **Nothing throws. Nothing warns.** Accuracy quietly collapses and it presents as a
planner fault, days later, in someone else's code. `AGENTS.md` section 5 makes the two agreeing a
hard requirement, and this is the only thing that enforces it.

MATLAB cannot be called from Python, so the check runs in two halves.

---

## Step 1 — regenerate the fixture (Python side)

```bash
python3 ml/python/tests/test_parity.py
```

This builds cases that exercise every branch — no history, zero `dt`, dead-centre boxes, a
ClassID out of range, all 16 classes at once, an extreme aspect ratio, near and far adjacency
pairs — records what Python produces, and writes `ml/python/tests/parity_fixture.json`.

**Validation:** every case prints PASS and the script reports the fixture path.

---

## Step 2 — check MATLAB against it

In MATLAB, from the repository root:

```matlab
runtests('matlab/tests/testFeatureParity.m')
```

**Validation:** all tests pass. Agreement is required to `1e-6`.

**If a test fails it names the feature number and both values.** Feature numbers are `AGENTS.md`
S2 positions: 10 is tau, 11 the lateral time-to-cross, 12-27 the class one-hot, 28-31 ego state.

**Do not "fix" one side to match the other.** Work out which is correct first, then say which and
why. The two most likely causes:
- the `1e-9` threshold inside `_safe_div` / `iSafeDiv` changed on one side only;
- a class one-hot landed at the wrong position. Python writes `row[11 + cid]` zero-indexed, MATLAB
  writes `data(i, 12 + cid)` one-indexed. **These are the same position.** A cow is S5 ClassID 10,
  so its bit belongs at feature 22.

---

## Step 3 — commit them together

**A fixture older than `features.py` proves nothing.** If `features.py` changed, the regenerated
`parity_fixture.json` goes in the same commit. Never one without the other.

---

## When to run this

- After **any** edit to `ml/python/meteor/features.py` or `buildFeatureFrame.m`.
- Before exporting a model that will be handed to the planner stream.
- After a merge that touched either file.

Finish with the section 7 report from `ml/ML.md`.
