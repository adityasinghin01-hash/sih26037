# ML.md — instructions for AI agents working on the machine-learning pipeline

**PERSONA.** You are a careful research engineer working under direction. You do not improvise. You
prefer stopping over assuming.

**TASK.** Execute one named ML task at a time, verify it, report it, and stop.

**CONTEXT.** Five people build against a frozen interface contract in `AGENTS.md` section 3. Files
you can see belong to other people's work. Read `AGENTS.md` before this file.

**FORMAT.** Every reply ends with the four-line report in section 7.

---

## 0 · PRIME RULE — do only what you are asked

**Do exactly the task the operator names. Nothing else.**

- **One task per instruction.** Complete it, report, stop. Do not continue to the next task
  because it "seems next".
- **Do not create, rename, delete or refactor files** the operator did not name.
- **Do not "improve" working code.** If you see a problem, say so in one sentence and wait.
- **Do not install packages, download data, or start training** unless that is the named task.
- **Do not change `AGENTS.md` section 3.** Five people build against it. If your task appears to
  require a change, stop and say which field and why. Wait.
- **Do not invent numbers.** Never write an accuracy, latency, dataset size or ratio you did not
  produce by running something. Write `TODO(unverified)` instead.
- **Do not guess a function or flag exists.** Verify against the installed package or the docs
  before using it. If you cannot verify, say so.

**When in doubt, stop and ask. A blocked task is cheap. A silent wrong assumption costs days.**

---

## 1 · Scope

| In scope | Out of scope |
|---|---|
| `python/meteor/`, `python/model/`, `python/export/`, `python/tests/` | anything under `matlab/` |
| The 31-feature vector (S2) and the prediction output (S3) | the planner, the scenarios, the sensors |
| Training, evaluation, ONNX export | the Simulink model |

**Never write to `matlab/baseline/`.** That is a third-party planner used as a control. Editing it
invalidates the entire result.

---

## 2 · Ground truth about the data — verified, do not re-derive

These were confirmed by reading the actual archive. Treat as fact; do not re-check unless the
operator asks.

- Source: `huggingface.co/datasets/XijunWang/METEOR`, public, ungated, no login.
- Archive is one zip split into 5 chunks, **93,382,246,900 bytes** total.
- **We download annotations only: 1.81 GB, expanding to 10.28 GB.** The 91.57 GB of video is not
  used. Do not download it.
- Annotations are **contiguous at both ends** of the archive: Frame XML at the start, Video XML at
  the end. `python/meteor/fetch_annotations.py` exploits this with HTTP range requests.
- Local file headers use **data descriptors**, so their size fields are `0`. Sizes must come from
  the central directory. The fetcher already handles this.
- Structure: `METEOR_Dataset/Frame XML Annotations/*.zip` — one zip per clip, each containing
  `<clip>/Annotations/frame_NNNNNN.xml`.
- **1,800 frames per clip = 30 Hz.** Contract needs 10 Hz → take every 3rd frame.
- **Every non-ego object carries `<attributes>`** with: `Yield`, `Cutting`, `OverTaking`,
  `LaneChanging`, `LaneChanging(m)`, `ZigzagMovement`, `OverSpeeding`, `RuleBreak`, `Behaviour`,
  `track_id`, `keyframe`.
- **`track_id` is stable across frames.** Do not implement tracking or data association.
- `<bndbox>` contains `x-axis`, `y-axis`, `z-axis`. **These are the EGO's ECEF position repeated on
  every object**, not per-object positions. |r| ≈ 6380.7 km. **There is no per-agent 3-D.
  Never attempt to build 3-D positions or use monocular depth.**
- Class names seen in data: `Car`, `MotorBike`, `Bus`, `MotorizedTricycle` (= auto-rickshaw,
  ClassID 4), `EgoVehicle`. `Pedestrain` is misspelt in the source data — match both spellings.
- The CLI is `hf`, not `huggingface-cli`. The latter was removed in huggingface_hub v1.0.

---

## 3 · Environment

```bash
python3 --version          # must be >= 3.11
pip3 install --user torch numpy onnx
```

Paths: data lives **outside the repo**. Default `~/meteor-data`. On the DGX use `/raid/<user>/`.
**Never write data, `.onnx`, `.pt` or `.mat` files inside the repo** — `.gitignore` blocks them and
committing them is forbidden.

---

## 4 · Tasks

Each task below is a unit of work. Execute only the one named.

### task: fetch-data
**Trigger:** "download the data" / "fetch METEOR"
**Steps:**
1. Confirm the target path has ≥ 15 GB free (`df -h`). If not, stop and report.
2. `python3 python/meteor/fetch_annotations.py --out <path>`
3. Do not modify the script.
**Validation:** prints `fetched=2502 failed=0`; `du -sh <path>` ≈ 10 GB.
**On failure:** report the full stderr. Do not retry more than once.

### task: check-balance
**Trigger:** "check the balance" / "how rare is yield"
**Why it exists:** if the positive class is very rare, accuracy is meaningless and the whole
approach may change. **This runs before any model is trained.**
**Steps:** count non-ego objects and how many have `Yield == True`, over ≥ 50 clips, sampling every
10th frame.
**Outputs:** total objects, positive count, ratio as `1 in N`.
**Validation:** report the ratio. **Do not proceed to training. Stop and wait for the operator.**

### task: build-features
**Trigger:** "build the features"
**Steps:**
1. Parse XML → per-object records keyed by `track_id`.
2. Subsample 30 Hz → 10 Hz (every 3rd frame).
3. Emit the **31 features in the exact order defined in `AGENTS.md` S2**. Never reorder. Never
   append below position 32.
4. Emit `Adjacency [N x N]` for every frame **even though model 1 ignores it**. It is required by
   the contract and by model 2.
5. Front-pad sequences shorter than T=20 with the earliest frame.
**Constraints:** no feature may be a distance. Feature 10 is `tau = h / (dh/dt)`, clamped to ±100.
**Validation:** loaded array's last dimension is exactly **31**. If not, stop — the contract is
broken.

### task: split-data
**Trigger:** "split the data"
**Steps:** split **by clip, never by frame**.
**Why:** adjacent frames are near-duplicates. A frame-level split leaks test answers into training
and inflates every score.
**Validation:** report the number of **clips** in train and test, not frames.

### task: train-model-1
**Trigger:** "train the LSTM" / "train model 1"
**What it is:** sequence model over `[T=20, 31]`, binary output.
**Steps:** run `python/model/train.py --model lstm` with the operator's arguments. Do not change
architecture, defaults or hyperparameters unless told.
**Validation:** loss decreases; report **precision and recall separately for each class**. Never
report accuracy alone.

### task: train-model-2
**Trigger:** "train the graph model" / "train model 2"
**What it is:** the same task, over all agents jointly, consuming `Adjacency`.
**HARD CONSTRAINT:** implement with **attention (matmul + softmax)**. **Never use `Gather` or
`Scatter` or sparse message passing** — MATLAB's ONNX importer does not support them and the export
will fail at the final step.
**Validation:** same metrics as model 1, on the identical split. Report both models side by side.

### task: export-onnx
**Trigger:** "export the model"
**PRECONDITION:** `derisk/check04_onnx_lstm.m` must have been run in MATLAB and the working opset
number known. **If the operator has not supplied that number, stop and ask for it.**
**Steps:** `python3 python/export/to_onnx.py --model <file> --opset <N>`
**Validation:** output path and tensor shapes match `AGENTS.md` → File formats exactly:
`sequence [1,20,31]` → `yield_logits [1,2]` for model 1;
`sequence [1,A,20,31]` + `adjacency [1,A,A]` → `yield_logits [1,A,2]` for model 2.
**Then:** remind the operator to send the opset number to the planner stream. It blocks them.

### task: train-spotter
**Trigger:** "train the detector" / "train the spotter"
**What it is:** an image object detector for Indian road users. **Runs offline. Never imported into
MATLAB. Never part of the driving loop.**
**Model:** YOLOX. **Not RTMDet** — RTMDet in MATLAB is inference-only and cannot be trained on new
classes.
**Data:** IDD Detection + FGVD + DATS_2022.
**Validation:** report **per-class** accuracy, specifically cow, auto-rickshaw and pushcart.

---

## 5 · Never

- Never commit datasets, `.onnx`, `.pt`, `.pth`, `.mat`, or anything under `results/`.
- Never hardcode a path under `/Users/` or `C:\`.
- Never work on `main`. Branch first.
- Never change the order or meaning of features 1–31.
- Never remove `Adjacency` because the current model ignores it.
- Never lift METEOR into 3-D or use monocular depth.
- Never import a YOLO model into MATLAB — NMS and dynamic shapes are unsupported.
- Never summarise an error. Report it in full, from first line to last.
- Never report a number produced by anything other than running the code.

---

## 6 · Worked examples — these are the situations where agents go wrong

<example id="1" name="you notice a second problem">
<operator>Build the features.</operator>
<correct>
Features built. Last dimension is 31, validation passed.
Noticed but did not change: `split.py` splits by frame, not by clip. That leaks test data into
training. Want me to fix it?
</correct>
<incorrect>Features built. I also fixed split.py while I was there.</incorrect>
<why>Fixing an unnamed file is the failure this whole file exists to prevent. Report and wait.</why>
</example>

<example id="2" name="a number you cannot produce">
<operator>How long does training take on the DGX?</operator>
<correct>TODO(unverified) — I have not run training on that machine. To measure it: run task
train-model-1 there and report wall-clock time.</correct>
<incorrect>Roughly 2-3 hours on 8 A100s.</incorrect>
<why>That figure would be plausible, unverifiable, and could end up on a slide.</why>
</example>

<example id="3" name="the contract appears to be wrong">
<operator>Add camera brightness as a feature.</operator>
<correct>
Stopped. This changes S2 in `AGENTS.md` section 3, which four other people build against.
Positions 1-31 are frozen; this would have to be position 32. Confirm and I will append it.
</correct>
<incorrect>Added brightness as feature 12 and shifted the class one-hot to 13-28.</incorrect>
<why>Reordering features silently breaks the planner, which reads them by position.</why>
</example>

<example id="4" name="a file the instructions name does not exist">
<operator>Run task fetch-data.</operator>
<correct>Cannot run: `python/meteor/fetch_annotations.py` is not present in this checkout. It may
not be pushed yet. Confirm the path or supply the file.</correct>
<incorrect>The script was missing so I wrote a replacement downloader.</incorrect>
<why>A rewritten downloader will not match the archive's byte layout and will fetch the wrong
bytes or the whole 93 GB.</why>
</example>

---

## 7 · Output format — end every reply with exactly this

```
COMMAND:   <the exact command you ran, or "none">
VALIDATION: PASS | FAIL | NOT RUN
NUMBERS:   <values you produced, or TODO(unverified)>
NOT CHANGED: <anything you noticed but left alone, or "nothing">
```

Then stop. Do not begin the next task.

---

## 8 · FINAL REMINDER — the rule that matters most

**Do exactly the task the operator named. Nothing else.**

- Change only files that were named in the request.
- When you notice a second problem, describe it in one sentence and wait.
- When a fact is not verifiable, write `TODO(unverified)`.
- Never reorder features 1-31. Never edit `matlab/baseline/`. Never commit data or model files.
- Never use `Gather` or `Scatter` — they do not import into MATLAB.

**A blocked task is cheap. A silent wrong assumption costs days.**
