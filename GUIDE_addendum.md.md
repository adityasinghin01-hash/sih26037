# Shourya — Round 2 Work Brief

**Read this whole thing before you start. It's written so Codex can execute it directly — every
step says what to do, why, and what "done" looks like. You have real intelligence in Codex; this
brief just tells you exactly where to point it.**

**Timeline: 2 days, ~15-20 hours total. Demo is Saturday 12:30pm. Nothing here waits on anyone
else — you can start immediately.**

---

## The one rule that matters more than any task below

**Never write a number you didn't actually measure by running something.** If a number isn't
real yet, write `TODO(unverified)` — that's a complete, acceptable answer. A number that sounds
good but wasn't produced by running code is exactly the kind of thing that gets a project torn
apart on stage. This project has a whole culture built around this — keep it.

---

## Where things live (so Codex doesn't guess)

- `ml/python/meteor/` — the dataset pipeline (you shouldn't need to touch this)
- `ml/python/model/` — `yield_lstm.py`, `yield_attention.py`, `train.py`, `evaluate.py` — this is
  where your work happens
- `ml/python/export/to_onnx.py` — exports a trained model to ONNX for MATLAB
- `matlab/+sih/+models/` — the three MATLAB-native models. **YOLOX is trained in MATLAB, not
  Python** — `yoloxObjectDetector` + `trainYOLOXObjectDetector`, needs Computer Vision Toolbox +
  Deep Learning Toolbox + the free "Automated Visual Inspection Library for Computer Vision
  Toolbox" add-on (Home → Add-Ons → Get Add-Ons — training fails without it, and the error looks
  like a typo, not a missing install). Confirm the exact script entry point with Codex by
  searching the repo before writing anything new.
- Data lives **outside the repo** (typically `~/meteor-data`) — never commit datasets, `.pt`,
  `.onnx`, or `.mat` files

---

## Task 1 — Calibrate the Yield-LSTM (do this first)

**The problem, precisely:** the model's raw confidence number is not honest. When it says "80%
sure," it is not actually right 80% of the time. Separately, its measured **dangerous-error-rate
is 20.18%** against a required **≤1%** safety bar — it is roughly 20x over the line.

**What calibration fixes and what it doesn't, said plainly:** calibration makes the model's
*stated confidence* match *reality*. It does **not** make the underlying model smarter or fix the
20% error rate on its own. Do not expect calibration alone to get this under 1% — it almost
certainly won't, and that's fine. The honest deliverable is: an honestly-calibrated model, a
precisely measured post-calibration number, and clear evidence for why it stays safety-gated.

### Step 1.1 — Get the raw, uncalibrated predictions
Use the same validation split `evaluate.py` already uses (built by `split.py`, `--val-frac 0.2`
is the real default — verified live in the repo, don't assume 0.25 or any other number without
checking — split **by clip, not by frame**, which is the file's only option, so that part's safe). Don't assume `evaluate.py` already exposes raw scores in a reusable file — write
`calibrate.py` so it loads the trained checkpoint **itself** and runs its own forward pass on
that validation split, saving raw scores + true labels to disk. That way this doesn't depend on
guessing what `evaluate.py` does internally, and you have your "before" evidence saved before
touching anything.

### Step 1.2 — Fit the calibration (Platt scaling)
This is new code — there is no existing `calibrate.py` in the repo, so write one
(`ml/python/model/calibrate.py`).

The method, precisely (this is Platt's actual original procedure, not a simplified version):

1. Don't fit against raw 0/1 labels — use **smoothed targets**, which matters more for us because
   our calibration set is small:
   ```
   t+ = (N+ + 1) / (N+ + 2)      for a true-positive example
   t- =        1 / (N- + 2)      for a true-negative example
   ```
   where `N+`/`N-` are the counts of positive/negative examples in your calibration set.
2. Fit two numbers, `A` and `B`, by minimizing cross-entropy between the smoothed targets and:
   ```
   P_calibrated = 1 / (1 + exp(A * raw_score + B))
   ```
3. Use a numerically stable solver for this (Newton's method the way Platt's original 1999 paper
   did it has known stability problems — a standard logistic-regression fit on `(raw_score, t)`
   pairs is the practical way to get `A, B` without hitting that issue).

### Step 1.3 — Decide where the calibration actually lives, before you export anything
This is a real coordination point, not a detail to skip. Two options for where `A`/`B` get
applied:

- **Bake it into the exported ONNX graph** — add the Platt sigmoid
  (`1/(1+exp(A*raw_score+B))`) as a final op after the model's existing output, so the `.onnx`
  file itself already emits calibrated probabilities. **Recommended for this 2-day window** —
  nobody on the MATLAB side has to change anything to use it, which removes a handoff risk under
  time pressure.
- **Apply it separately at the S3 boundary in MATLAB** (alongside the existing
  `PYield = 1 - P(assert)` conversion) — only fall back to this if baking it into ONNX turns out
  to be awkward, and if you do, hand `A` and `B` to whoever owns that MATLAB conversion
  explicitly and in writing, not as a verbal note that can get lost.
- Either way, **the `.onnx` output tensor name stays `yield_logits`** — that file format is
  frozen. Only what's mathematically computed before that tensor is emitted changes.

### Step 1.4 — Produce BOTH reliability diagrams, don't overwrite the first one
A reliability diagram: bin predictions by confidence (10 bins is standard), and for each bin plot
the *actual* fraction that came true against the *average predicted* confidence in that bin. A
perfectly honest model has every point sitting on the diagonal. No special library needed — this
is a plain numpy/matplotlib job: bin, average per bin, plot against the diagonal.

- Save the **before** diagram (raw, uncalibrated scores) as its own file.
- Apply calibration, then save the **after** diagram as a separate file.
- With a small dataset, use **quantile bins** (each bin has the same number of examples, not the
  same probability width) — fixed-width bins will leave some bins with almost no data, which
  makes the chart noise, not evidence.
- This before/after pair is the single most demo-worthy artifact from this whole task — it's real
  proof, not a claim.

### Step 1.5 — Measure the REAL dangerous-error-rate after calibration
Recompute the dangerous-error-rate metric (same definition already used in the project — the
rate at which the model says "safe to go" and is wrong) on the calibrated output. Write down the
exact number.

### Step 1.6 — Apply the honest rule
- If the number is still above 1% (very likely): the model stays `Valid=false` in the contract,
  the planner keeps falling back to geometry, and you report the real number plainly. This is not
  a failure to hide — it's the correct, designed behavior, and it's a stronger thing to present
  than a faked pass.
- Do not tune, retrain, or cherry-pick a threshold just to cross the 1% line artificially — a
  threshold chosen to hit a target rather than reflect real performance is exactly the kind of
  invented number this project doesn't do.

---

## Task 2 — Same calibration pass on the Yield-GNN/Attention model

Same steps as Task 1 (1.1 through 1.6), same honesty rule. This is the secondary model — it never
blocks the LSTM, so if you're short on time, this is the first thing to compress or cut, not Task
1, 3, or 4.

---

## Task 3 — Fix YOLOX's real domain-gap problem

**Tool note, don't skip this:** unlike Tasks 1 and 2, this one is **MATLAB work, not Python** —
`trainYOLOXObjectDetector`. The actual training script is confirmed at
**`matlab/+sih/+models/trainSpotter.m`** (verified live in the repo, this exact path) — start
there, don't build a Python fine-tuning loop for this by mistake.

**The problem, precisely:** YOLOX is only 5-19% confident right now. This is not a training bug —
it was trained on real photographs and is being run against our synthetic/rendered scenes, which
look visually different (lighting, texture, noise characteristics). This is the one model-status
number judges will actually see live and notice looking broken.

**The realistic 2-day fix, in order of how fast it is to try:**

1. **Fastest, try this first:** pull a small batch of frames directly from our own rendered
   demo scenes (the actual images the live demo will show), label them (even a rough manual pass
   on 100-300 frames is enough for a short fine-tune), and fine-tune YOLOX briefly on this small,
   domain-matched set. This directly closes the exact gap the demo will expose, rather than
   fixing the general problem.
2. **If there's time left:** apply augmentation during that fine-tune that mimics the difference
   between real photos and our renders (adjust contrast/noise/color characteristics toward what
   the renders actually look like) — this is a lighter-weight version of domain randomization and
   doesn't need new labeled data beyond what you already used in step 1.
3. **Don't attempt:** a full domain-adaptation training pipeline (adversarial domain-invariant
   features, etc.) — that's real Round-2-proper research work, not a 2-day fix. If you don't have
   time for even step 1, report the honest confidence numbers as they are; do not claim a fix that
   didn't happen.

**Measure it, don't just eyeball it:** run the same test frames through YOLOX before and after
your fix and report the actual confidence numbers, both. If it's still low after your attempt,
say so — "improved from X% to Y%, still short of ideal" is a legitimate, honest result.

---

## Task 4 — Verify DeepLab (quick, don't over-invest here)

DeepLab is already working well — it was already verified against three genuinely different
plausible outputs. Your only job: re-run its existing sanity check once, confirm the output
hasn't silently changed because of anything else moving in the repo, and move on. If it's still
solid (it should be), spend zero further hours here. Don't "improve" something that isn't broken.

---

## What NOT to do (do not skip this section)

- **Never touch `matlab/baseline/`.** It's the unmodified competitor planner — not your file,
  not your job, ever.
- **Never reorder, remove, or add to features 1-31** in the feature vector without flagging it
  loudly first — the planner reads them by position, and a silent reorder breaks it with no
  error message at all.
- **Never rebuild features without `--force`** after changing any feature code — otherwise you
  silently train on stale data and won't know it.
- **Never report accuracy alone.** Precision and recall, both classes, always — a model that
  always says "no" can look 99% accurate and be useless.
- **Never invent a number.** Say this to Codex directly, in every session: if you didn't run
  something to produce this number, don't write it down as if you did.

---

## Handoffs — tell people immediately, don't wait until you're "done"

- **To Kishan:** the calibrated checkpoints for both yield models, plus both reliability
  diagrams (before and after), the moment they exist — he needs them for his evaluation, don't
  make him wait on your whole task list.
- **To Aditya B.:** the final calibrated model plus the honest post-calibration dangerous-error
  number — he needs to know exactly what can and cannot safely be live-gated into the planner.

---

## Definition of done — check every line before you say you're finished

- [ ] LSTM: before AND after reliability diagrams exist as separate saved files
- [ ] LSTM: real post-calibration dangerous-error-rate is written down, whatever it is
- [ ] LSTM: if still above 1%, `Valid=false` stays in place — not quietly removed to make a demo look better
- [ ] LSTM: calibration is either baked into the `.onnx` export or its `A`/`B` are handed off in writing, not left verbal
- [ ] GNN/Attention: same four boxes above, or explicitly cut and said so out loud
- [ ] YOLOX: confidence measured before AND after the fix, on the same test frames
- [ ] YOLOX: fix was done in MATLAB (`trainYOLOXObjectDetector`), not a Python script that doesn't touch the real model
- [ ] DeepLab: sanity check re-run once, confirmed unchanged
- [ ] Kishan has the calibrated checkpoints + both diagrams
- [ ] Aditya B. has the final model + the real dangerous-error-rate number
- [ ] Nothing in this list contains an invented or rounded-up number

---

## Suggested pacing across the 2 days

**Day 1:** Task 1 (LSTM calibration + both reliability diagrams + the real number) — this is the
highest-value, must-finish item. Start Task 2 (GNN calibration) if Task 1 finishes with time to
spare.

**Day 2:** Task 3 (YOLOX domain-gap fix, the fastest-fix version first). Task 4 (DeepLab
re-verify) takes minutes, do it whenever there's a gap. Leave real buffer time at the end of day
2 for handoffs — don't be still calibrating models an hour before the demo.
