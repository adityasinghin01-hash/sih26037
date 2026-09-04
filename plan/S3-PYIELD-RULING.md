# S3 `PYield` — what the number actually means. Ruling, 4 September 2026.

**Read this if you produce S3 (Stream C) or consume it (Stream D). It is the difference between
the planner weighting its branches correctly and weighting them backwards.**

`AGENTS.md` section 3 is **not** changed by this file. S3 still reads
`.PYield [N x 1 double] in [0,1]` and `.Valid [N x 1 logical]`. What this file fixes is that
section 3 never said *probability of what*, and the model we trained answers a different question
from the one the field name implies.

---

## The problem, in three lines

- The model was trained on **`assert`** — "did this road user take the gap?" — because `yield` occurs
  1 in 301 in METEOR and cannot be learned. That decision was correct and is documented in
  `ml/ReadThis.md`.
- The contract field is called **`PYield`**, the export is `yield_lstm_opset<N>.onnx`, and its
  output tensor is `yield_logits`.
- **`ml/ReadThis.md` says explicitly: "Not asserting is not the same as yielding."** So it is not
  even a clean `1 - p` flip. A driver who simply carries on doing nothing is in the negative class
  for both.

Plug P(assert) into a field named `PYield` and **D6 weights its two futures backwards**, silently,
with nothing erroring. That is the exact failure mode this project keeps losing to.

---

## The ruling

> **`PYield` carries `1 - P(assert)`: the probability that the other road user does NOT take the gap.**

Stream C computes it. Stream D consumes it. Nobody renames anything, and section 3 stays frozen.

### Why this and not the alternatives

**Not `PYield = P(assert)`.** The field name would then mean the opposite of what it says. Someone
reads `PYield` in six weeks, assumes it means yield, and the planner drives into the gap.

**Not "`Valid = false` always, ignore the model."** Safe, but it throws away the entire ML stream
and there is no reason to — see the safety argument below.

### The honest caveat, which must go in the report

`1 - P(assert)` lumps **"actively yielded"** together with **"did nothing"**. Those are not the same
thing, and treating "did nothing" as yielding is **optimistic**. State it plainly:

> We predict whether the other road user will take the gap. Not taking it is what our safety check
> actually needs to know. We do not claim to predict active yielding.

That is Aditya's wording from `ml/ReadThis.md`, and it is already the agreed language.

---

## Why an optimistic `PYield` is not a safety hole

This only holds because of the D6 ruling, so it must not be separated from it.

**`PYield` does not decide what is safe. It decides what is preferred.**

Per `plan/D6-TRUNK-RULING.md`, the trunk is the prefix that is safe **under both futures** — yield
*and* assert — and a braking-to-stop must be clear from the end of it under both. The weights never
enter that test. They only rank candidates that have already passed it.

**So a mis-weighted `PYield` costs efficiency, not safety.** The car dithers or waits longer than it
needed to. It does not drive into anything. The barrier `h = lambda - beta` and the both-futures
check are what carry safety, and neither reads `PYield`.

**Stream D: if you ever find yourself using `PYield` to decide whether something is safe rather than
which safe thing to prefer, stop. That is outside this ruling and the argument above no longer
holds.**

---

## The second ruling: the model is not allowed to say GO yet

Measured on the full validation set, 249 clips, 783,928 samples:

| | Model 1 (LSTM) | Model 2 (Attention) | Target |
|---|---|---|---|
| Average Precision | 0.3500 | **0.3691** | beats 0.0982 random ✓ |
| Calibration error | 0.2079 | **0.1502** | — |
| **Dangerous error rate** | 20.18% | — | **≤ 1.0%** ✗ |

**The model fails its own operating-point gate by a factor of twenty.** At threshold 0.99 it says GO
1,630 times out of 783,928 — already maximally conservative — and is still wrong 1 in 5 times it
commits.

> **Ruling: set `Valid = false` wherever the model cannot meet the ≤1% dangerous-error bar, and let
> the planner fall back to the geometric role.** S3 already mandates exactly that behaviour:
> *"When `Valid` is false the planner uses the geometric role alone - never 0.5."*

This is not a workaround. It is the contract being used as designed, and it is a **better result to
present than a hidden 20%**:

> We measured our own predictor against a safety threshold we fixed before training. It does not
> clear it, so the planner does not let it drive — it falls back to geometry. Here is the number.

**Do not ship a model that failed Check 4/5 without this gate.** Three of our previous entries died
from shipping things that were not finished.

---

## Consequences, by stream

**Stream C**
- Emit `PYield = 1 - P(assert)`. Do it at the S3 boundary, once, in one place.
- Emit `Valid = false` in the band where the dangerous-error rate exceeds 1%. Record the threshold
  and the measured rate in `results/<run>/config.json`.
- The `.onnx` output tensor stays `yield_logits` — the file format in section 3 is frozen. The
  conversion happens on the MATLAB side of the boundary, not by renaming the tensor.
- Keep reporting the `yield` label as a measured data limitation, as `ml/ReadThis.md` says.

**Stream D**
- `PYield` is the weight on the *"they do not take the gap"* branch. `1 - PYield` weights the
  *"they take the gap"* branch, which is the dangerous one.
- **Never treat `PYield` as a safety criterion.** It ranks; it does not permit.
- When `Valid` is false, geometric role alone. **Never 0.5.**

---

## Status

**This is a ruling by Claude at Aditya's instruction on 4 September 2026, not a decision Aditya made
personally. It touches what the project claims, so he can overturn it** — but until he does, build
against it, because two streams guessing differently is worse than either answer.

Nothing in `AGENTS.md` section 3 was changed to make this work.
