---
description: Run the whole yield-predictor pipeline end to end - features, split, train, evaluate, export - stopping at every decision that belongs to a human.
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

# /ml-run — the machine-learning pipeline, start to finish

**Read `ml/ML.md` before step 1.** It carries the measured facts about this
dataset, and every one of them was expensive to learn. Section 0 of that file applies to every
step here: **you do the step you were asked for and stop at the first thing a human must decide.**

**Environment, once:**
```bash
pip3 install torch numpy onnx onnxruntime onnxscript
```
`onnxscript` is not optional — torch >= 2.9 uses the dynamo ONNX exporter and dies without it.

Data lives **outside the repo**. Below, `DATA` means that path (default `~/meteor-data`).
On the DGX use `/raid/<user>/` and read `ml/DGX.md` first.

---

## Step 0 — say how much data you actually have

```bash
ls "$DATA"/METEOR_Dataset/*/*.zip | wc -l
```

METEOR has **1,251 clips**. Report the fraction you hold.

**If it is under about 500 clips, fetch the rest before going on.** Training on a small slice
produces numbers that mean nothing: on 39 clips the whole dataset yielded **109 positives and
only 6 in validation**.

```bash
python3 ml/python/meteor/fetch_annotations.py --out "$DATA"
```

**1.81 GB to download, 10.28 GB on disk.** Check `df -h` first and say the numbers out loud
before you start, so the person can stop you if the machine is tight. **You do not need Aditya's
permission for this** - it is their own disk and they cannot do the job without the data.

**What DOES need asking:** writing to a shared or borrowed machine, anything over ~50 GB, or
downloading the 91.6 GB of video, which we never use.

---

## Step 0b — measure both labels, then apply the rule below

```bash
python3 ml/python/meteor/check_balance.py --data "$DATA" --clips <all of them> --every 10
```

It reports two candidate labels on the same objects.

| label | what it means | measured on 79 of 1,251 clips |
|---|---|---|
| `yield` | someone let the ego through | 1 in 581 |
| `assert` = OverTaking OR LaneChanging OR Cutting | someone took the gap | 1 in 14 |

**Those numbers came from 6% of the dataset. Re-measure on everything you have before deciding
anything - that is what this step is for.**

### The decision rule — apply it yourself, do not wait

Aditya set this rule; you apply it to whatever numbers you get.

| What the full measurement shows | What to do |
|---|---|
| `assert` better than **1 in 50**, `yield` worse than **1 in 200** | **Train on `assert`.** Also run `yield` and report it as a measured failure |
| both better than 1 in 50 | Train **both**, report side by side as an ablation |
| `assert` also worse than 1 in 200 | **STOP and tell Aditya.** Neither label works and the question itself changes |

**Report which label produced every number you quote, every time.** A precision figure with no
label attached is unreadable by anyone else.

### Why `assert` is the expected answer, so you can explain it

- **METEOR's own paper groups these behaviours** and predicts them together — its benchmark task
  is *action-behavior prediction*, not single-label yielding. Using `Yield` alone was never how
  this dataset was meant to be used.
- **The rarity is a published problem on this exact dataset** — Transfer-LMR (arXiv 2405.05354,
  2024) exists to handle heavy-tailed behaviour classes in METEOR. It is a known hard problem,
  not a mistake on our side. **Cite it.**
- Imbalance literature calls 50:1 to 100:1 *severe*. `yield` at **581:1** is past where the
  field characterises it at all. `assert` at 14:1 is ordinary.
- **It is the more useful question.** The planner never needs "will they let me through". It
  needs "is it safe to go", and "will they take the gap" answers that directly.

### The one thing that must be said honestly

**Not asserting is NOT the same as yielding.** A driver who simply carries on doing nothing is in
the negative class for both. So never write *"our model predicts yielding"*. Write:

> We predict whether the other road user will take the gap. Not taking it is what our safety
> check actually needs to know.

That sentence is Aditya's wording. **Use it as-is on any slide or report** - do not invent a
different claim, and do not quietly upgrade it to "predicts yielding".

---

## Step 1 — build the feature vectors

```bash
python3 ml/python/meteor/build_dataset.py --data "$DATA" --out "$DATA"/features \
      --label <yield|assert> [--force]
```

**`--force` is REQUIRED if `features.py`, `parse_xml.py` or the ego helpers changed since the last
build.** Without it the script skips clips that already have an `.npz` and the whole run silently
measures stale vectors — a failure that looks like a training problem for days.

**Report from its output, all four:**
0. The **label mode** it printed. Every number below means something different depending on it.
1. `samples=` and `positives=` with the percentage.
2. The **dead-feature list**. Expected: `[23, 24, 25, 27]` — the one-hot slots for S5 ClassID 11
   dog, 12 pushcart, 13 animal-drawn cart, 15 static obstacle. METEOR contains none of them, so
   this is correct, not a bug. **A different list is worth reporting.**
3. The **ego feature ranges** (28-31). Expected roughly `0..40 m/s` and `+/-10 m/s^2`.
   **A range far outside a real vehicle's means the physical gate in `parse_xml.py` has been
   removed — STOP and report it.** Those columns previously reached 557 m/s and 568 g and
   silently drowned every other feature.

**Validation:** last dimension is exactly **31**. If not, the contract is broken — stop.

---

## Step 2 — split by clip

```bash
python3 ml/python/meteor/split.py --features "$DATA"/features --val-frac 0.25
```

Split **by clip, never by frame**. Adjacent frames are near-duplicates; a frame split leaks the
answers into training and inflates every score.

**Report clips AND positives on each side.**
**If validation holds fewer than about 50 positives, say plainly that no metric computed on it can
be trusted**, and carry that sentence into every later step. Do not quietly report precision and
recall as though they mean something.

---

## Step 3 — train both models

```bash
python3 ml/python/model/train.py --features "$DATA"/features --model lstm      --epochs 20
python3 ml/python/model/train.py --features "$DATA"/features --model attention --epochs 20
```

Do not change the architecture, the defaults or the hyperparameters unless told to.
**Never enlarge the model to fix a data problem.** These are 25,090 and 58,434 parameters on
purpose; with a few hundred positives a bigger network only memorises faster.

**Report precision and recall for BOTH classes, for both models, side by side. Never accuracy
alone** — when yielding is rare, answering "no" every time scores 99.9% and is useless.

---

## Step 4 — decide whether it may cross into MATLAB

```bash
python3 ml/python/model/evaluate.py --features "$DATA"/features --model "$DATA"/features/yield_lstm.pt
```

This does not ask whether the model is accurate. It asks **whether it fails in the safe
direction**: predicting yield when they do not is a car pulling out in front of someone;
predicting no-yield when they would have is a few seconds of waiting.

**If it prints NOT READY: STOP. Do not export. Report the entire output and wait.**
Report the threshold, the dangerous-error rate and the degradation table.

---

## Step 5 — export to ONNX

```bash
python3 ml/python/export/to_onnx.py --model "$DATA"/features/yield_lstm.pt
python3 ml/python/export/to_onnx.py --model "$DATA"/features/yield_attention.pt
```

**Run it once per checkpoint.** A checkpoint holds one model, so the script now exports only
that one and prints `SKIPPED` for the other. It used to export both, which meant the untrained
one was written with random weights under an `[OK]` line - a randomly-initialised network could
have reached the planner stream looking finished. Nothing would have errored; it would simply
have predicted noise.

**There is no `--opset` flag.** The script writes opsets 17, 18 and 20, then reads the opset back
out of each file, because **torch silently upconverts anything below its implementation floor** —
ask for 9, 11 or 13 and you get a file stamped 18. Reporting the number you requested would send
the planner stream an opset that is not true of the file.

**Check three things in its output:**
- **numerics vs PyTorch below `1e-4`.** An export that succeeds and returns different numbers is
  the worst outcome available, because nothing errors.
- **no `Gather` or `Scatter`.** If one appears, it is almost certainly plain indexing, not message
  passing: `out[:, -1, :]` and reading `x.shape` at runtime both emit `Gather`. Use
  `torch.flatten(out[:, -1:, :], 1)` and compile-time constants.
- the **operators outside MATLAB's built-in list**. `Expand, Shape, Slice, Transpose, Unsqueeze`
  are expected and are **not** blockers — MATLAB makes custom layers for them. Only
  `derisk/check04_onnx_lstm.m` settles whether any needs a hand-written placeholder.

**Opset 20 is best for model 2:** GELU exports as a native `Gelu` node, which MATLAB supports; at
17 and 18 it decomposes to `Erf`, which it does not.

---

## Step 6 — hand off

Run `/ml-parity` if `features.py` changed during this run.

**Send the working opset number to the planner stream immediately. It blocks them.**

Finish with the section 7 report from `ml/ML.md`:

```
COMMAND:   <the exact commands you ran>
VALIDATION: PASS | FAIL | NOT RUN
NUMBERS:   <clips, samples, positives, precision/recall per class, opset, max abs diff>
NOT CHANGED: <anything you noticed but left alone, or "nothing">
```
