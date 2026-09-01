# ReadThis — the ML stream, start to finish


**Install your fence before you start.** `cp .claude/fences/ml.settings.local.json .claude/settings.local.json`
It refuses reads outside your stream instead of relying on you to remember. See `.claude/fences/README.md`.
**You are Stream C. This folder is yours.** Everything the machine-learning side of SIH26037
needs is here or linked from here.

Read this once, top to bottom, before you run anything. It is long because it tries to leave
nothing out — but you only have to read it once, and after that you work from the checklists.

## What is in this folder

| File | What it is | When you open it |
|---|---|---|
| **`ReadThis.md`** | this file — the whole stream, start to finish | first, once |
| **`C-prediction.md`** | your task list, and who is waiting on you | after this file |
| **`ML.md`** | the measured facts about the data, written for your AI assistant | tell your agent to read it before it writes ML code |
| **`DGX.md`** | the college supercomputer — what it is, and the rules for using it | **before you run anything on the DGX** |
| **`CHEATSHEET.md`** | every command, in order, nothing explained | once you know what you are doing |
| **`TROUBLESHOOTING.md`** | errors we already hit, and what they really mean | when something breaks |
| **`python/`** | the actual code: dataset pipeline, both yield models, ONNX export | as the checklists tell you |

**Your commands:** `/ml-run` the whole pipeline · `/ml-parity` check Python and MATLAB still agree
· `/ml-models` the three MATLAB-native models · `/state` where the project is · `/first-run` the
MATLAB that has never been executed.

Nothing outside this folder and `matlab/+sih/+prediction/` and `matlab/+sih/+models/` is yours.
**Install your fence** (top of this file) and it stops depending on you remembering.

---

# 0 · What you are actually building, in plain words

Our car is going to drive through an Indian junction with no traffic light. To get through, it
has to guess what the other road users will do. **That guess is your job.**

You build **five models**. Only the first one is on the critical path.

| # | Model | What it does | Where it runs |
|---|---|---|---|
| **1** | **Yield predictor (LSTM)** | Watches a vehicle for 2 seconds and says "this one will take the gap" or "this one won't" | Python → exported to MATLAB |
| **2** | Yield predictor (attention) | Same job, but looks at all nearby vehicles together instead of one at a time. We report both to show which is better | Python → exported to MATLAB |
| 3 | Spotter (YOLOX) | Finds vehicles, cows, auto-rickshaws in a photo | MATLAB, offline |
| 4 | Road segmenter (DeepLab v3+) | Marks which pixels are drivable road | MATLAB, offline |
| 5 | Lidar detector (PointPillars) | Finds objects in a 3-D laser scan | MATLAB, offline |

**Models 3, 4 and 5 never run while the car is driving.** The simulator does not produce a
camera image at all, so a model that reads pixels would have nothing to look at. They exist to
produce **real numbers on real Indian images** for the report — specifically for cow,
auto-rickshaw and pushcart, which no Western dataset contains.

**Model 1 is the one that matters.** If you only finish one thing, finish that.

## What is yours, and what is not

| Yours | Not yours |
|---|---|
| `ml/` — this whole folder | **`plan/`** — Stream D's folder |
| `matlab/+sih/+prediction/` — the feature twin | `matlab/+sih/+planner/` and the Simulink model |
| `matlab/+sih/+models/` — the three MATLAB models | `matlab/+sih/+scenario/`, `+perception/` |
| | **`matlab/baseline/`** — the competitor. Never |

**You produce `S3 PYield`. You do not consume it.** The planner reads it through the contract and
never opens your model; you never open theirs. If the planner looks like it is misusing your
prediction, tell Aditya — do not go and read `plan/` or edit anything there.

That line exists because crossing it is how two people end up with two versions of the same
thing and nobody knows which one the demo used.

---

# 1 · How to work with your AI assistant

You will not write most of this code by hand. That is fine and expected. But **the AI is not in
charge, and neither is it a search engine.** Use it like this.

### It writes, you judge

| The AI does | You do |
|---|---|
| Writes and edits code | Runs it and reads what actually happened |
| Explains an error | Decides whether the fix is real or a patch over a symptom |
| Suggests an approach | Decides whether it matches what this file says |
| Reports a number | Asks: *did something actually compute that?* |

### Give it the right starting point

**Open the repository root folder in Antigravity, not this subfolder.** `AGENTS.md`,
`GEMINI.md` and everything in `.agents/` only load from the root. Open `ml/` alone and your
agent works blind — it will invent function names and break other people's code.

### Use the slash commands, do not improvise

| Type this | It does |
|---|---|
| **`/first-run`** | Runs the MATLAB that has never been executed. **Do this before trusting anything.** |
| **`/ml-run`** | The whole pipeline for models 1 and 2 |
| **`/ml-parity`** | Checks the Python and MATLAB feature builders still agree |
| **`/ml-models`** | Models 3, 4 and 5 |

If a slash command does not work in your version, open the file in `.agents/workflows/` and tell
your agent to follow it. It is ordinary text.

### Three sentences that will save you days

1. **"Show me the actual output, do not summarise it."** A trimmed error costs a day.
2. **"Did you run that, or are you telling me what you expect?"** They are different things.
   The correct answers are *I ran it*, *I checked the documentation but never ran it*, and
   *I believe*. Make it say which.
3. **"Which file did you change?"** If it names a file nobody asked it to touch, stop.

### Two things to refuse, always

- **Editing section 3 of `AGENTS.md`.** Four other people build against it. If something really
  needs changing there, that goes to Aditya, not into a commit.
- **Editing anything in `matlab/baseline/`.** That is the competitor we compare against. If we
  change it, a judge calls the whole comparison rigged and every number we have dies.

---

# 2 · The decisions that are YOURS

Most of what you do is execution. These are the points where you actually decide something.
They are written as rules so you are not guessing.

## Decision 1 — how much data to pull

METEOR has **1,251 clips**. Annotations only: **1.81 GB to download, 10.28 GB on disk.** We do
not download the 91.6 GB of video; nothing needs it.

**Rule:** if you hold fewer than about 500 clips, fetch the rest before training. Check `df -h`
first and say the numbers out loud so someone can stop you if the machine is tight.
**You do not need permission for this.** It is your disk and you cannot do the job without it.

**Ask first** only for: a shared or borrowed machine, anything over ~50 GB, or the video.

## Decision 2 — which behaviour to predict  ← the important one

We can teach the model to spot one of two things.

| Label | What it means | Measured on 79 of 1,251 clips |
|---|---|---|
| `yield` | someone let our car through | **1 in 581** |
| `assert` | someone took the gap: overtook, changed lane, or cut in | **1 in 14** |

Something that happens 1 in 581 times cannot be learned. The model answers "no" every time,
scores 99.8%, and is useless.

**Rule — measure on ALL your clips first, then apply this:**

| What you measure | What you do |
|---|---|
| `assert` better than 1 in 50, `yield` worse than 1 in 200 | Train on **`assert`**. Also run `yield` and report it as a measured failure |
| both better than 1 in 50 | Train **both** and report them side by side |
| `assert` also worse than 1 in 200 | **Stop. Tell Aditya.** Neither works and the question changes |

**Why `assert` is the expected answer**, so you can defend it:

- **METEOR's own paper groups these behaviours** and predicts them together — its benchmark task
  is *action-behavior prediction*. Using `Yield` alone was never how this dataset was meant to
  be used.
- **The rarity is a published problem on this exact dataset.** Transfer-LMR (arXiv 2405.05354,
  2024) exists to handle heavy-tailed behaviour classes in METEOR. **Cite it.** It is a known
  hard problem, not our mistake.
- The imbalance literature calls 50:1 *severe*. `yield` at 581:1 is past where the field even
  has a name for it. `assert` at 14:1 is ordinary.
- **It is the more useful question anyway.** The car never needs "will they let me through". It
  needs "is it safe to go", and "will they take the gap" answers that directly.

**The one thing you must say honestly.** Not asserting is **not** the same as yielding — a
driver who just carries on doing nothing is in the negative class for both. So never write
*"our model predicts yielding"*. Use Aditya's wording, exactly:

> We predict whether the other road user will take the gap. Not taking it is what our safety
> check actually needs to know.

## Decision 3 — when to stop and say it is not working

`evaluate.py` prints **NOT READY FOR MATLAB** when the model is unsafe to ship. When it does:

**Stop. Do not export. Send the whole output.**

Do not tune until it passes. A model tuned until the test goes green is worse than no model,
because now nobody knows it is broken. **A failing check is information, not an obstacle.**

---

# 3 · The data — what it is and what is wrong with it

Every fact here was produced by running code. **Do not re-derive them, and do not let your AI
guess at them.**

### Where it comes from

`huggingface.co/datasets/XijunWang/METEOR` — public, no login. One zip in five pieces, 93.4 GB
total. The annotations sit in a contiguous block at each end of that archive, and
`fetch_annotations.py` pulls just those blocks with HTTP range requests.

**Do not rewrite the fetcher.** A replacement will not match the archive's byte layout and will
either fetch the wrong bytes or the whole 93 GB.

### What one clip contains

One zip per clip, holding one XML file per frame. Recorded at **30 frames per second**; we use
every 3rd frame to get to 10 per second, which is what the contract asks for.

Every object in a frame carries a `track_id` that stays the same across frames — **so you never
have to work out which car in this frame is which car in the last one.** That is normally the
hardest part of this job and it is done for you.

### The four things that will bite you

**1 · There is no 3-D position for other vehicles.** The XML has `x-axis`, `y-axis`, `z-axis`
inside every object's box, which looks like a 3-D position. It is not. It is **the ego
vehicle's own GPS position, copied onto every object.** Every value is about 6,380 km from the
origin, because that is the radius of the Earth.

**Never build 3-D positions from it, and never use monocular depth to invent them.** Everything
we compute lives in the flat image, which is why the feature vector has no distances in it.

**2 · The behaviour labels are dirty.** `Behaviour` contains `false`, `False`, and `fasle`
(misspelt in the source data), mixed with `Start` and `End` markers. `RuleBreak` is not a
true/false at all — it holds `false` or a reason like `WrongLane`. `Pedestrain` is misspelt
throughout. All of this is already handled in `parse_xml.py`. **Compare case-insensitively and
treat anything unrecognised as false.**

**3 · Four of the 31 features are permanently empty**, and that is correct, not a bug. They are
the one-hot slots for dog, pushcart, animal-drawn cart and static obstacle — **METEOR contains
none of them.** This is also why the cow in our simulation is hand-built rather than learned:
`Animal` appears 5 times in 24 clips. You cannot learn animal behaviour from that.

**4 · The ego's own speed and acceleration are nearly empty**, because METEOR records the car's
position once per clip rather than continuously. They are gated to physically possible values in
`parse_xml.py`. **If you ever see an ego speed above about 40 m/s in the build output, that
gate has been removed — stop and say so.** Before the gate existed, this feature reached
557 m/s (2,008 km/h) and drowned every other feature in the model.

---

# 4 · The feature vector — the 31 numbers

This is the interface between you and Stream D. **It is frozen.** Positions 1–31 never move.
New features can only be added at position 32 or later, and only with a changelog entry,
because the planner reads them **by position** — if you reorder them it silently reads the
wrong thing and nobody gets an error.

| # | What it is | Why it is here |
|---|---|---|
| 1–2 | Where the box centre is in the image | where they are |
| 3 | Bottom edge of the box | lower in frame ≈ closer |
| 4–5 | Box width and height | apparent size |
| 6 | log(width / height) | shape — tells a bus from a scooter |
| 7–9 | How fast 1, 2 and 5 are changing | how they are moving |
| **10** | **`tau` = height ÷ (rate height grows)** | **seconds until contact, from the box growing alone. No distance needed** |
| **11** | Seconds until they reach our path line | the sideways version of 10 |
| 12–27 | Which of 16 classes it is | a cow is not a bus |
| 28–30 | Our own speed, turn rate, acceleration | nearly empty in METEOR, see above |
| 31 | The action our car is considering | during training this is what the driver actually did |

**The rule behind all of it: every number here can be computed BOTH from a dashcam video AND
from our MATLAB simulation.** That is why nothing is a distance — METEOR has no distances. We
project the simulation down into a flat image rather than trying to lift the video into 3-D.

### The known weakness, which we say out loud before a judge finds it

Feature 31 is the action **our** car is considering. But METEOR only ever shows what the driver
actually did — we never see what would have happened if they had done something else. So at
driving time the model is asked about actions no one in the data ever took.

**We do not hide this.** The honest test is M8, the closed-loop yield ledger: run the model
inside the simulation and compare what it predicted against what happened. Say this first.

### Features 1–31 exist in TWO places and they must agree exactly

- `ml/python/meteor/features.py` — trains the model
- `matlab/+sih/+prediction/buildFeatureFrame.m` — runs it in MATLAB

**If those two ever disagree, the model is fed different numbers at driving time than it saw in
training. Nothing crashes. Accuracy silently collapses and it looks like the planner is broken,
days later, in someone else's code.**

`/ml-parity` is the only thing standing between us and that. Run it after **any** change to
either file, and commit the regenerated fixture together with the change.

---

# 5 · The flow — every step, in order

Set `DATA` to a folder **outside the repository**. `~/meteor-data` is fine.
Never write data or model files inside the repo; `.gitignore` blocks them and committing them
is forbidden.

```bash
pip install torch numpy onnx onnxruntime onnxscript
```
**`onnxscript` is not optional.** Without it the export dies with `ModuleNotFoundError`.

### Step 1 — get the data
```bash
python3 ml/python/meteor/fetch_annotations.py --out $DATA
```
Resumable and CRC-checked; safe to stop and restart. **Expect `fetched=2502`** — that is 2,502
*files*, one Frame XML and one Video XML set for each of the 1,251 clips.

### Step 2 — measure both labels, apply Decision 2
```bash
python3 ml/python/meteor/check_balance.py --data $DATA --clips 1251 --every 10
```
Prints `yield` and `assert` side by side, plus a per-class breakdown and a verdict.
**This decides what the whole stream trains on. Do it before anything else.**

### Step 3 — turn XML into training data
```bash
python3 ml/python/meteor/build_dataset.py --data $DATA --out $DATA/features \
        --label <yield|assert> --force
```

**`--force` is required after ANY change to `features.py`, `parse_xml.py`, or the label.**
Without it the script skips clips that already have a `.npz` file and you silently train on the
old code. That failure looks exactly like a training problem and it is not one — it cost a whole
run to find once already.

**Read three things in the output:**
1. `samples=` and `positives=` — how much you actually have
2. the **dead feature list** — expect `[23, 24, 25, 27]`. A different list is worth reporting
3. the **ego feature ranges** — expect roughly 0–40 m/s and ±10 m/s². Anything wilder means the
   physical gate is gone

### Step 4 — split into train and test
```bash
python3 ml/python/meteor/split.py --features $DATA/features --val-frac 0.25
```

**It splits by clip, never by frame, and this matters more than it sounds.** Frames next to each
other are almost identical pictures. Split by frame and nearly every test frame has a twin in
training, so the model looks brilliant and has learned nothing. Splitting by whole clips is the
only honest way.

**Look at the positives in the test half.** Under about 50, no score computed on it can be
trusted, and you must say so beside every number you report from then on.

### Step 5 — train
```bash
python3 ml/python/model/train.py --features $DATA/features --model lstm      --epochs 20
python3 ml/python/model/train.py --features $DATA/features --model attention --epochs 20
```

**Report precision and recall for BOTH classes. Never accuracy on its own** — when the thing you
are looking for is rare, saying "no" every time scores 99.8%.

*Precision* = when it said yes, how often was it right. *Recall* = of all the real cases, how
many did it catch. You need both: a model that says yes once and is right has perfect precision
and is useless.

**Do not make the model bigger to fix a data problem.** These are 25,090 and 58,434 parameters
on purpose. With a few hundred positive examples, a bigger network only memorises faster.

### Step 6 — decide whether it may go to MATLAB
```bash
python3 ml/python/model/evaluate.py --features $DATA/features \
        --model $DATA/features/yield_lstm.pt
```

This does not ask "is it accurate". It asks **"does it fail in the safe direction"**, because
the two mistakes are not equal:

| Mistake | Cost |
|---|---|
| Says they will let us in, they do not | **we pull out in front of someone** |
| Says they will not, they would have | we wait a few seconds |

It runs eleven checks. Four worth understanding:

- **Does it beat something trivial?** It compares the model against always-saying-no, random
  guessing, and *the best single feature on its own*. **If one number beats the network, the
  network learned nothing and the honest thing is to ship the single number.**
- **Confidence intervals.** "Recall 83%" on 6 examples is 5 out of 6. It prints a range. **Quote
  the range, not the single number.**
- **Which features does it actually use?** It shuffles each group and sees what breaks. If the
  model ignores a group, that is worth knowing and worth saying.
- **Is one clip carrying the whole score?** If all the positives are in one clip, your number
  describes that clip, not Indian traffic.

### Step 7 — export to MATLAB
```bash
python3 ml/python/export/to_onnx.py --model $DATA/features/yield_lstm.pt
python3 ml/python/export/to_onnx.py --model $DATA/features/yield_attention.pt
```

**Run it once per model.** A checkpoint holds one model, so the script exports only that one.
It used to export both, which meant the untrained one was written with **random weights** under
an "OK" line.

**There is no `--opset` flag, on purpose.** PyTorch silently upgrades any ONNX version below its
minimum — ask for 9, 11 or 13 and you get a file that is really 18. The script writes 17, 18 and
20 and reads the version back out of each file, so the number it prints is true.

Then in MATLAB:
```matlab
check04_onnx_lstm
```

**Read the output for PLACEHOLDER layers, not for the word "succeeded".** An operation MATLAB
cannot convert does not throw an error — it becomes an empty custom layer that a human has to
fill in. A network full of placeholders "imported successfully" and is useless.

### Step 8 — tell Stream D, immediately

**The opset number is the one thing blocking the planner stream.** Send it the moment you have
it. Do not wait until the rest of your work is finished.

### Step 9 — models 3, 4 and 5

Follow **`/ml-models`**. Needs IDD, which requires **a human signup** at
`idd.insaan.iiit.ac.in/accounts/signup/`. **A script cannot download it — do not write one.**

Two free add-ons the MATLAB installer does **not** give you, both from
**Home → Add-Ons → Get Add-Ons**:
- **Deep Learning Toolbox Converter for ONNX Model Format** — step 7 fails without it
- **Automated Visual Inspection Library for Computer Vision Toolbox** — YOLOX *training* fails
  without it, and only training, so the error arrives late and looks like a typo

---

# 6 · Before you trust any MATLAB here — run `/first-run`

**Most of the MATLAB in this repository has never been executed.** It was written on a machine
with no MATLAB installed. Every function name was checked against the MathWorks documentation —
but checked is not run, and **four real defects were already found that way.**

`/first-run` executes it in the right order and tells you what to look for.

**Expect something to break. That is the workflow working, not the repo being broken.**
Send the whole error.

---

# 7 · What "done" looks like

| Task | Done when |
|---|---|
| Data | `fetched=2502 failed=0`, and `du -sh` shows about 10 GB |
| Label decision | Both ratios measured on all your clips, rule applied, choice stated |
| Features | Last dimension is exactly 31; dead list and ego ranges reported |
| Split | Clips **and positives** reported for each half |
| Training | Precision and recall for both classes, both models, side by side |
| Evaluation | `evaluate.py` run and its verdict reported **even when it fails** |
| Export | `check04` imports a real file with **no placeholder layers** |
| **Handoff** | **Stream D has the opset number** |
| Models 3–5 | Per-class scores, with cow, auto-rickshaw and pushcart named |

**And four things are true of every one of them:**

1. It runs from a fresh clone, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 3 of `AGENTS.md` exactly
4. **Someone else could run it without asking you a question**

*"It works on my machine"* is not done.

---

# 8 · Never do these

1. **Never invent a number.** If you did not run something to get it, write `TODO(unverified)`.
2. **Never report accuracy on its own.** Precision and recall, both classes, always.
3. **Never split by frame.** Whole clips only.
4. **Never reorder features 1–31**, or remove `Adjacency` because model 1 ignores it.
5. **Never rebuild features without `--force`** after changing the code or the label.
6. **Never add a feature the simulator cannot produce** — brake lights, indicators, hand
   signals. The model would learn it, then meet a simulation where that input is blank forever,
   with no error and no crash.
7. **Never train anything that reads pixels for the driving loop.** The simulator produces an
   object list, not an image.
8. **Never commit data, `.onnx`, `.onnx.data`, `.pt` or `.mat` files.**
9. **Never edit `matlab/baseline/` or section 3 of `AGENTS.md`.**
10. **Never summarise an error.** All of it, first line to last.
11. **Never tune until a safety check passes.** Report the failure.

---

# 9 · Where everything is

| You want | Look here |
|---|---|
| This roadmap | `ml/ReadThis.md` |
| The Python pipeline | `ml/python/` |
| The MATLAB feature twin | `matlab/+sih/+prediction/buildFeatureFrame.m` |
| The three MATLAB models | `matlab/+sih/+models/` |
| **The frozen contract** | **`AGENTS.md` section 3** |
| Facts about the data, for your AI | `ml/ML.md` |
| The step-by-step workflows | `.agents/workflows/` |
| Your task list and who waits on you | `ml/C-prediction.md` |
| The de-risk checks | `derisk/HOW-TO-RUN.md` |

---

# 10 · If you only remember five things

1. **Model 1 is the one that matters.** Finish it before anything else.
2. **Send Stream D the opset number the moment you have it.** They are blocked until you do.
3. **`--force` after any change to the feature code or the label.** Otherwise you measure old code.
4. **Precision and recall, both classes, with the confidence interval.** Never accuracy alone.
5. **A failing check is information.** Report it. Do not tune until it goes green.
