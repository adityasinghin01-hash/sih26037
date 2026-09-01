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

- **One task per instruction.** Complete it, report, stop. Never continue because a task "seems next".
- **Do not create, rename, delete or refactor files** the operator did not name.
- **Do not "improve" working code.** If you see a problem, say so in one sentence and wait.
- **Never download data, install packages, or start training unless that IS the named task.**
  A download spends someone else's disk and bandwidth. Ask, state the cost, wait for a yes.
- **Do not change `AGENTS.md` section 3.** Five people build against it. If your task appears to
  require a change, stop and say which field and why. Wait.
- **Do not invent numbers.** Never write an accuracy, latency, size or ratio you did not produce by
  running something. Write `TODO(unverified)` instead.
- **Do not guess a function or flag exists.** Verify against the installed package or the docs.

**When in doubt, stop and ask. A blocked task is cheap. A silent wrong assumption costs days.**

---

## 1 · Scope

| In scope | Out of scope |
|---|---|
| `python/meteor/`, `python/model/`, `python/export/`, `python/tests/` | the planner, scenarios, sensors |
| `matlab/+sih/+prediction/`, `matlab/+sih/+models/` — the twin and the trainers | the planner, `matlab/+sih/+scenario/` |
| The 31-feature vector (S2) and the prediction output (S3) | the Simulink model |

**Never write to `matlab/baseline/`.** That is a third-party planner used as a control. Editing it
invalidates the entire result.

---

## 2 · Ground truth — verified by running code. Do not re-derive.

**Dataset.** `huggingface.co/datasets/XijunWang/METEOR`, public, ungated. One zip in 5 chunks,
93.4 GB. **We take annotations only: 2,502 clips, 1.81 GB down, 10.28 GB on disk.** The 91.6 GB of
video is not used. Annotations sit contiguously at both ends of the archive and
`fetch_annotations.py` pulls them with HTTP range requests — **do not modify or rewrite it**; a
replacement will not match the byte layout. Sizes must come from the central directory because
local headers use data descriptors. The CLI is `hf`, not `huggingface-cli`.

**Structure.** `METEOR_Dataset/Frame XML Annotations/*.zip`, one zip per clip, holding
`<clip>/Annotations/frame_NNNNNN.xml`. 30 Hz; the contract needs 10 Hz, so take every 3rd frame.
`track_id` is stable across frames — **do not implement tracking**. Every non-ego object carries
`Yield`, `Cutting`, `OverTaking`, `LaneChanging`, `ZigzagMovement`, `OverSpeeding`, `RuleBreak`,
`Behaviour`, `keyframe`. `Behaviour` is dirty: `false`, `False`, `fasle` — compare
case-insensitively. `RuleBreak` holds `false` or a reason string, not a boolean.
`Pedestrain` is misspelt in the source — match both spellings.

**`<bndbox>` `x-axis/y-axis/z-axis` is the EGO's ECEF position repeated on every object**, not a
per-object position. |r| ≈ 6380.7 km. **There is no per-agent 3-D. Never build 3-D positions and
never use monocular depth.**

### Measured 1 Sep 2026 — the numbers that decide what to do next

**THE ONE DECISION THAT IS ADITYA'S.** `check_balance.py` reports two candidate labels on the
same objects. Measured over 79 clips: `yield` is **1 in 581**, `assert`
(`OverTaking OR LaneChanging OR Cutting`) is **1 in 14** - about 42x more signal, and to a
planner "they will not assert" means nearly the same thing. `build_dataset.py --label` switches
between them. **Report both and wait. Never choose it yourself.**

**The label is too rare to train on as it stands.** Over 39 clips: **109 positives in 68,011
samples (0.160%)**, and the by-clip split leaves **6 positives in validation**. Every figure
`evaluate.py` prints on a set that small is noise. `check_balance.py` verdict: **SEVERE**.
**We hold only ~79 of 2,502 clips — about 3% of the dataset.** Do not conclude anything about the
label from that sample, and do not re-tune the model against it.

**27 of 31 features are alive.** Dead across all clips: **23, 24, 25, 27** — one-hot slots for S5
ClassID 11 dog, 12 pushcart, 13 animal-drawn cart, 15 static obstacle. METEOR contains none of
them. Nothing to fix. **The cow stays simulated.**

**Features 28-31 were poisoned, not empty.** The GPS-jump guard tested distance, not speed, and
admitted 3,000 m/s: measured ego speed reached **557.7 m/s** and acceleration **±5,576 m/s²**,
four orders of magnitude above the box-geometry features sharing their input layer. Now gated by
`MAX_SPEED_MPS`/`MAX_ACCEL_MPS2` in `parse_xml.py`. **If you ever see an ego range far outside a
real vehicle's, the gate has been removed — stop and report it.**

**Input scaling is baked into the model as buffers**, fitted on training clips only, so the
exported ONNX takes **raw contract-S2 features** and MATLAB needs no matching preprocessing.
Do not add normalisation to `features.py` — that would desynchronise it from the MATLAB twin.

**Model sizes: `yield_lstm` 25,090 parameters, `yield_attention` 58,434.** Small on purpose.
**The bottleneck is labels, not capacity. Never answer a data problem with a bigger model.**

---

## 3 · Environment

```bash
python3 --version          # >= 3.11
pip3 install torch numpy onnx onnxruntime onnxscript
```
**`onnxscript` is required**, not optional: torch ≥ 2.9 defaults to the dynamo ONNX exporter and
dies with `ModuleNotFoundError: onnxscript` without it.

Data lives **outside the repo**. Default `~/meteor-data`. On the DGX use `/raid/<user>/` and
**read `DGX.md` first**. **Never write data, `.onnx`, `.pt` or `.mat` inside the repo.**

---

## 4 · The procedures live in workflows, not here

A rule file holds **facts**. A repeatable procedure with steps is a **workflow**, and Antigravity
runs those from a slash command. The ML procedures are:

| Command | What it does |
|---|---|
| **`/ml-run`** | The whole pipeline: build features -> split -> train -> evaluate -> export. Stops at every decision that belongs to a human |
| **`/ml-parity`** | Proves `features.py` and its MATLAB twin still produce identical vectors |
| **`/ml-models`** | Models 3-5 - spotter, road segmenter, lidar detector. All MATLAB-native, no ONNX |

They live in `.agents/workflows/`. If the slash command does not resolve, open the file and follow
it — the steps are plain markdown.

**Every workflow inherits section 0.** A workflow tells you what to do; it never overrides the rule
that you do only the step you were asked for and stop at the first thing a human must decide.

---

## 5 · Never

- Never commit datasets, `.onnx`, `.onnx.data`, `.pt`, `.pth`, `.mat`, or anything under `results/`.
- Never hardcode a path under `/Users/` or `C:\`. Never work on `main` — branch first.
- Never change the order or meaning of features 1-31. Never remove `Adjacency`.
- Never rebuild features after editing `features.py` without `--force`.
- Never add a feature the simulator cannot reproduce — brake lights, indicators, hand signals. The
  model would learn it, then meet a simulation where that input is permanently blank, with no error
  and no crash. Object *orientation* is fine; simulated actors have a yaw angle.
- Never train a model that reads pixels. The cuboid simulator emits an object list, not an image.
- Never lift METEOR into 3-D or use monocular depth.
- Never import a YOLO model into MATLAB — NMS and dynamic shapes are unsupported.
- Never summarise an error. Report it in full, first line to last.
- Never report a number produced by anything other than running the code.

---

## 6 · Worked examples — where agents actually go wrong

<example id="1" name="you notice a second problem">
<operator>Build the features.</operator>
<correct>
Features built. Last dimension is 31, validation passed.
Noticed but did not change: `split.py` splits by frame, not by clip. That leaks test data into
training. Want me to fix it?
</correct>
<incorrect>Features built. I also fixed split.py while I was there.</incorrect>
<why>Fixing an unnamed file is the failure this file exists to prevent. Report and wait.</why>
</example>

<example id="2" name="a number you cannot produce">
<operator>How long does training take on the DGX?</operator>
<correct>TODO(unverified) — I have not run training on that machine. To measure it: run task
train-model-1 there and report wall-clock time.</correct>
<incorrect>Roughly 2-3 hours on 8 A100s.</incorrect>
<why>Plausible, unverifiable, and it could end up on a slide.</why>
</example>

<example id="3" name="the contract appears to be wrong">
<operator>Add camera brightness as a feature.</operator>
<correct>
Stopped. This changes S2 in `AGENTS.md` section 3, which four other people build against.
Positions 1-31 are frozen; this would have to be position 32. Confirm and I will append it.
</correct>
<incorrect>Added brightness as feature 12 and shifted the class one-hot to 13-28.</incorrect>
<why>Reordering silently breaks the planner, which reads features by position.</why>
</example>

<example id="4" name="a task needs data you do not have">
<operator>Train the LSTM.</operator>
<correct>
Blocked. `~/meteor-data/features` holds 39 clips of 2,502. Training on 3% of the data will produce
a number that means nothing. Task fetch-data would take 1.81 GB down and 10.28 GB on disk — say
the word and I will run it.
</correct>
<incorrect>Data looked thin so I downloaded the rest, then trained.</incorrect>
<why>A download spends someone else's disk and bandwidth. Name the cost and wait.</why>
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

## 8 · FINAL REMINDER

**Do exactly the task the operator named. Nothing else.**
Change only files that were named. Describe a second problem in one sentence and wait. Write
`TODO(unverified)` when you cannot verify. Never reorder features 1-31, never edit
`matlab/baseline/`, never commit data or model files, never download without being asked.

**A blocked task is cheap. A silent wrong assumption costs days.**
