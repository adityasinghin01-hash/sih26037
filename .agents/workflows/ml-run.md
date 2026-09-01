---
description: Run the whole yield-predictor pipeline end to end - features, split, train, evaluate, export - stopping at every decision that belongs to a human.
---

# /ml-run — the machine-learning pipeline, start to finish

**Read `ML.md` at the repository root before step 1.** It carries the measured facts about this
dataset, and every one of them was expensive to learn. Section 0 of that file applies to every
step here: **you do the step you were asked for and stop at the first thing a human must decide.**

**Environment, once:**
```bash
pip3 install torch numpy onnx onnxruntime onnxscript
```
`onnxscript` is not optional — torch >= 2.9 uses the dynamo ONNX exporter and dies without it.

Data lives **outside the repo**. Below, `DATA` means that path (default `~/meteor-data`).
On the DGX use `/raid/<user>/` and read `DGX.md` first.

---

## Step 0 — say how much data you actually have

```bash
ls "$DATA"/METEOR_Dataset/*/*.zip | wc -l
```

METEOR has **1,251 clips**. Report the fraction you hold.

**If it is under about 500 clips, STOP and say so.** Training on a small slice produces numbers
that mean nothing: on 39 clips the whole dataset yielded **109 positives and only 6 in
validation**. Tell the operator that `/ml-run` needs `fetch-data` first, and give them the cost:
**1.81 GB to download, 10.28 GB on disk**, then wait.

**Never start the download yourself.** It spends someone else's disk and bandwidth.

---

## Step 0b — measure BOTH candidate labels, then stop

```bash
python3 python/meteor/check_balance.py --data "$DATA" --clips <all of them> --every 10
```

It reports `yield` and `assert` side by side on the same objects. Measured on 79 clips,
1 Sep 2026:

| label | rate | 1 in N |
|---|---|---|
| `yield` | 0.172% | **1 in 581** |
| `assert` = OverTaking OR LaneChanging OR Cutting | 7.166% | **1 in 14** |

`assert` has roughly **42x more signal**, and for a planner "they will not assert" carries
nearly the same meaning as "they will yield".

**This is Aditya's decision, not yours and not the agent's.** Report both numbers on the full
dataset and STOP. When he answers, pass it through as `--label yield` or `--label assert` in
step 1. **Changing the label requires `--force`** - otherwise the old `.npz` files survive and
you train on the previous label without any warning.

---

## Step 1 — build the feature vectors

```bash
python3 python/meteor/build_dataset.py --data "$DATA" --out "$DATA"/features \
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
python3 python/meteor/split.py --features "$DATA"/features --val-frac 0.25
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
python3 python/model/train.py --features "$DATA"/features --model lstm      --epochs 20
python3 python/model/train.py --features "$DATA"/features --model attention --epochs 20
```

Do not change the architecture, the defaults or the hyperparameters unless told to.
**Never enlarge the model to fix a data problem.** These are 25,090 and 58,434 parameters on
purpose; with a few hundred positives a bigger network only memorises faster.

**Report precision and recall for BOTH classes, for both models, side by side. Never accuracy
alone** — when yielding is rare, answering "no" every time scores 99.9% and is useless.

---

## Step 4 — decide whether it may cross into MATLAB

```bash
python3 python/model/evaluate.py --features "$DATA"/features --model "$DATA"/features/yield_lstm.pt
```

This does not ask whether the model is accurate. It asks **whether it fails in the safe
direction**: predicting yield when they do not is a car pulling out in front of someone;
predicting no-yield when they would have is a few seconds of waiting.

**If it prints NOT READY: STOP. Do not export. Report the entire output and wait.**
Report the threshold, the dangerous-error rate and the degradation table.

---

## Step 5 — export to ONNX

```bash
python3 python/export/to_onnx.py --model "$DATA"/features/yield_lstm.pt
```

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

Finish with the section 7 report from `ML.md`:

```
COMMAND:   <the exact commands you ran>
VALIDATION: PASS | FAIL | NOT RUN
NUMBERS:   <clips, samples, positives, precision/recall per class, opset, max abs diff>
NOT CHANGED: <anything you noticed but left alone, or "nothing">
```
