# Stream C — Prediction

> ## Read [`ml/ReadThis.md`](../ml/ReadThis.md) first.
>
> `ml/` is your folder. It holds the whole roadmap in plain language: what you are building,
> which decisions are yours and how to make them, how the data works and what is wrong with it,
> every step in order, and what "done" means.
>
> - **[`ml/ReadThis.md`](../ml/ReadThis.md)** — the roadmap. Read once, top to bottom
> - **[`ml/CHEATSHEET.md`](../ml/CHEATSHEET.md)** — every command, keep it open
> - **[`ml/TROUBLESHOOTING.md`](../ml/TROUBLESHOOTING.md)** — errors we already hit
>
> **This file is your task list and who is waiting on you.** The roadmap is how to do the work.

**You build the model that answers one question: will that vehicle let us in?**

This is the stream with the most computer time and the least MATLAB. If you like training models
and wrangling large datasets, this is yours.

**Your machine:** Any machine, plus the supercomputer
**Your branch:** `stream-c-prediction`

---

# Part 1 — Getting started

Do these in order. Do not skip ahead. If a step fails, **stop and report it** — do not carry on
and hope.

### Step 1 — Get the code

Install **Git** if you do not have it (git-scm.com), then open a terminal and type:

```bash
git clone https://github.com/adityasinghin01-hash/sih26037.git
cd sih26037
```

If it says *"repository not found"*, you have not been invited yet. Ask Aditya for an invite to
the GitHub repo.

### Step 2 — Open it in Antigravity

**Open the folder `sih26037` itself.** Not a subfolder. Not `matlab/`. The top folder.

This matters more than it sounds. Three files sit in that top folder that your AI assistant reads
automatically:

| File | What it does for you |
|---|---|
| **`AGENTS.md`** | The project rules. Your agent reads this by itself — the stack, our conventions, and the decisions that are already settled so it does not re-argue them |
| **`GEMINI.md`** | Antigravity-specific rules. Overrides `AGENTS.md` where they disagree |
| **`README.md`** | The front door. One page, tells you where everything is |

**If you open a subfolder instead, none of these load and your agent works blind.** It will invent
things, use wrong function names, and propose changes that break other people's work.

You do not have to read `AGENTS.md` or `GEMINI.md` yourself. The agent reads them. You just have
to open the right folder.

### Step 4 — Install Python things

Open a terminal (Command Prompt on Windows) and type these one line at a time:

```bash
cd <where-you-cloned>/sih26037
python -m venv .venv
.venv\Scripts\activate          # on Mac use:  source .venv/bin/activate
pip install torch onnx numpy tqdm xmltodict onnxruntime onnxscript
```

Prove it worked:
```bash
python ml/python/model/yield_lstm.py
```
It should print the model size and some numbers. If it errors, send the whole error.

**`onnxscript` is not optional.** Without it the ONNX export dies with
`ModuleNotFoundError: No module named 'onnxscript'`. Newer PyTorch needs it to write the file at
all. If you already made your `.venv` before 1 Sep, run the `pip install` line again.

### Step 5 — Get onto the supercomputer

You need an account on the **DGX A100** before you can do anything real. Ask whoever runs it and
get answers to these six questions. **Paste the raw output — do not summarise it.**

| # | Question | Command to run |
|---|---|---|
| 1 | How much free disk? | `df -h` |
| 2 | Is there a per-user limit? | `quota -s` |
| 3 | **Does the compute node have internet?** | `curl -I https://huggingface.co` — run it **on a compute node**, not the login node |
| 4 | How do we book GPU time? | ask |
| 5 | Who approves accounts, how long? | ask |
| 6 | Can we install our own packages? | `pip install --user --dry-run numpy` |

**Question 1 is the one that can kill your work.** We need **~190 GB free**.

---

### Before you trust any MATLAB in this repo — run `/first-run`

Most of the MATLAB here was written on a machine with **no MATLAB installed**. Every function
name and signature was checked against the MathWorks documentation, but **checked is not run**.
Four real defects were already found that way and there are probably more.

The first time you have MATLAB working, tell your AI assistant: **`/first-run`**. It runs
everything that has never been executed, in the right order, and says what to look for.

**Expect something to break.** That is the workflow doing its job, not the repo being broken.
Send the whole error, every line.


# Part 2 — How to work

### Your branch

**Never save your work directly to `main`.** Five people are working at once and you would
overwrite each other. You get your own branch:

```bash
git checkout -b stream-c-prediction
```

Do that once. From then on you are on your own branch and cannot break anyone.

### Saving your work

Do this **several times a day**, not once a week:

```bash
git add -A
git commit -m "C2: OSM import working, 14 roads found"
git push -u origin stream-c-prediction
```

The message format is **`<task number>: <what you did>`**. That is it. It tells everyone which
item in this file moved.

**Before every push, run the tests:**

```matlab
runtests('matlab/tests')
```

If a test fails, either fix it or say so when you push. **Do not push broken code quietly.**

### Getting your work into the project

On GitHub, click **Compare & pull request**. Aditya reviews and merges. That is the only way code
reaches `main`.

### How to talk to the rest of the team

**Use task numbers.** Instead of *"I did the thing with the roads"*, say:

> *"C2 done. C3 blocked — I need check02 to pass first."*

Everyone knows what C2 and C3 are, because they are in this file.

**When you finish something someone is waiting for, tell them immediately.** They cannot see your
screen. Part 5 says exactly who is waiting on you.

**When you are stuck, say so the same day.** Being stuck quietly for two days is the most
expensive thing that can happen on a small team.

**When something breaks, send the WHOLE error.** Every line of it. Not a screenshot of part of it,
not *"it says something about a null value"*. The complete message.

> A trimmed error message costs the team a day. This is the single most expensive habit to get
> wrong, and it is the easiest one to fix.

### Working with your AI assistant

**It writes the code. You check whether the code is right.**

| The agent does | You do |
|---|---|
| Writes functions, boilerplate, tests | Run it and read what actually happens |
| Refactors, documents | Decide whether the output is correct |
| Explains errors | Judge whether a scenario looks like a real Indian road |

**Two things to refuse if your agent suggests them:**

1. **Editing section 3 of `AGENTS.md`** (the frozen contract) — four other people build against it
2. **Editing anything in `matlab/baseline/`** — that is our control arm and it must stay untouched

**And never let it write a number you have not produced.** If the agent puts a figure in a comment
or a document, ask yourself: did something actually compute that? If not, it should say
`TODO(unverified)` instead. Invented numbers are how projects like this lose.


---

# Part 3 — Your tasks

### C1 — Download the dataset  *(start today — this takes days)*

METEOR is **93.4 GB** in five pieces. **The official website is dead.** There is exactly one place
left to get it, and if that disappears our model has no data at all. So: start now.

On the supercomputer:
```bash
pip install --user huggingface_hub
huggingface-cli download XijunWang/METEOR --repo-type dataset --local-dir ./meteor
cd meteor
cat chunk_* > METEOR_Dataset.zip
unzip METEOR_Dataset.zip
rm chunk_*                    # only after unzip finishes successfully
```

**Run it inside `tmux`** so it keeps going if your connection drops:
```bash
tmux new -s meteor
# ... start the download ...
# press Ctrl+B then D to leave it running
# come back later with:  tmux attach -t meteor
```

**Check free disk before you start.** You need about **190 GB** — the pieces and the joined-up zip
exist at the same time before extraction.

### C2 — THE ONE CHECK THAT DECIDES WHAT OUR MODEL MEANS

The moment it finishes extracting, before anything else, open **one** annotation file:

```bash
find . -name "*.xml" | head -1 | xargs head -100
```

Answer one question and report it immediately:

> **Does an object that is NOT the ego vehicle have a `<attributes>` section containing `Yield`
> or `Cutting`?**

Why this matters: the dataset's own two programs both read behaviour labels **only** from the
object called `EgoVehicle`. Their paper implies the opposite. **Nobody outside the dataset can
settle it** — we have to look.

- **If yes** → our model learns *"will that scooter yield to me?"* — exactly as designed
- **If no** → our model learns *"given this situation, would a real Indian driver yield?"* — still
  useful, still real Indian behaviour, but it means something different

**Both answers are fine.** We built the design to survive either. But **report it before writing
the loader**, because it changes what the labels mean.

### C3 — ~~Write the loader~~ ALREADY DONE  *(superseded 1 Sep)*

`ml/python/meteor/loader.py` was never written and is not needed. `ml/python/meteor/build_dataset.py`
does the whole job — reads the XML, groups boxes into per-vehicle tracks, runs `frame_features()`
and writes sequences plus labels.

```bash
python3 ml/python/meteor/build_dataset.py --data <path> --out <path>/features --label <yield|assert>
```

**`--force` is required after any change to `features.py`.** Without it the script skips clips
that already have an `.npz`, and your run silently measures the old code. That failure looks
exactly like a training problem and it is not one.

Read the three things it prints: the positive count, the dead-feature list, and the **ego feature
ranges**. If an ego speed is above ~40 m/s the physical guard in `parse_xml.py` has been removed
— stop and say so.


### C4 — Train

Start simple: balanced classes, held-out clips the model has never seen, and report **precision
and recall separately** for yield and no-yield. A model that says "no" every time can look 80%
accurate and be useless.

Then train the **graph model** on the adjacency matrix the loader already produces. This is no
longer an optional upgrade — **as of 31 Aug 2026 both models are planned**, and the comparison is
a result we report, not a fallback we hope to avoid. That is why the adjacency matrix exists from
day one even though the LSTM ignores it.

Write message passing as a **dense adjacency matmul plus softmax**, never `Gather`/`Scatter` —
MATLAB's ONNX importer supports the first and not the second. Cap the agent count at `A`, fix it
at export, and record it in `config.json`. About 60 lines differ from the LSTM: same loader, same
labels, same training loop, same evaluation, same export.

**The LSTM ships first and the graph model never blocks it.** If the graph export refuses to
import, the fallbacks in order are: check it really is matmul-only → run it in Python over a
socket → reimplement with `dlnetwork` custom layers. Report which one you used.

**Eight GPUs means forty small experiments, not one huge model.** Say that honestly — it is what
we actually do and it is more defensible.

### C5 — Export, and send Stream D one number

```bash
python ml/python/export/to_onnx.py
```

This writes the model in four different formats. MATLAB accepts some and rejects others.
Stream D runs `derisk/check04_onnx_lstm.m` to find out which.

**Send Stream D the working format number the moment you have it. Do not wait for training to
finish.** That single number blocks their entire integration.

---

### C6 — Two things we LEARN, and a long list we do not  *(NEW 31 Aug)*

**The rule that keeps this honest.**

**Measured, never learned:** can I fit through a gap · can I turn around · point of no return ·
which way to re-route. These are geometry and search. Learning them would need data covering every
galli on earth, and the failure is catastrophic — a car that drives somewhere it cannot leave.

**Learned from METEOR — both are *parameters*, not policies:**

1. **The clearance Indians actually accept.** Mine the real lateral gaps drivers pass at, in the
   image plane. Stream D's `d_min` should be **fitted to observed behaviour, not guessed.** A
   margin chosen in an office is the difference between a car that flows and one that blocks a
   galli all day. **This is the single most useful number you can hand D.**
2. **Blockage patience** — how long a driver waits before treating an obstruction as permanent.

### C7 — What the data actually contains  *(verified 31 Aug, read this before you download)*

Confirmed by reading the archive directly, without downloading it:

- **The behaviour labels ARE per-agent.** Every non-ego object carries a populated `<attributes>`
  block. Measured 180 of 180 across 90 frames. The old worry (that `xml2rawframe.py` filters to
  `EgoVehicle`) was about *their script*, not the data.
- **Attributes present:** `Yield` · `Cutting` · `OverTaking` · `LaneChanging` · `LaneChanging(m)` ·
  `ZigzagMovement` · `OverSpeeding` · `RuleBreak` · `Behaviour` · **`track_id`** · `keyframe`.
- **`track_id` is the find** — stable IDs across frames mean **you do not write your own
  association** to compute the rate features. METEOR hands you the tracks.
- **Annotation is a full 30 Hz** — 1,800 frames per one-minute clip, numbered 0..1799. Take every
  third frame for the contract's 10 Hz.
- **The `x-axis/y-axis/z-axis` fields in `<bndbox>` are ECEF, and they are the EGO's position
  repeated on every object** (identical across objects, |r| = 6380.7 km). So there is **no
  per-agent 3-D** — which independently confirms the frozen "never lift METEOR to 3-D" rule. But it
  does give **ego speed and yaw rate for free** by differentiating. Use `ecef2enu` (Mapping Toolbox).
- **Class names in the wild:** `Car`, `MotorBike`, `Bus`, **`MotorizedTricycle`** (= auto-rickshaw,
  our ClassID 4), `EgoVehicle`.

### C8 — You do not need 93 GB  *(NEW)*

The archive is ordered by category, so the annotations sit contiguously at both ends of the file:

| section | files | download | extracted |
|---|---|---|---|
| **Frame XML Annotations** | 1,251 | **1.55 GB** | 2.04 GB |
| Raw Videos | 1,250 | 91.57 GB | 104.86 GB |
| **Video XML Annotations** | 1,251 | **0.27 GB** | 8.25 GB |

**Every feature comes from boxes and classes, which live in the XML. The video is only needed to
look at.** So the training download is **1.81 GB**, expanding to 10.28 GB.

```bash
python ml/python/meteor/fetch_annotations.py --out <somewhere-not-in-the-repo>
```
Resumable, CRC-checked, skips what is already there. Add `--videos 5` for sample clips.

**`huggingface-cli download` is dead** — renamed to `hf` in v0.34, removed in v1.0. If you use the
CLI instead, it is `hf download XijunWang/METEOR --repo-type dataset --local-dir ./meteor`.

**Consequence: METEOR no longer depends on the DGX.** 1.81 GB runs on a laptop. Start today.


### C9 — Your agent can now run the whole pipeline itself  *(NEW 1 Sep)*

The pipeline was run end to end on 1 Sep and seven things were broken. They are fixed and pushed.
**You do not have to drive it step by step any more.** In Antigravity, type:

| Command | What it does |
|---|---|
| **`/ml-run`** | Builds features, splits, trains both models, evaluates, exports to ONNX |
| **`/ml-parity`** | Checks the Python and MATLAB feature builders still agree |

Those live in `.agents/workflows/`. If the slash command does not work in your version, open the
file and tell your agent to follow it — it is ordinary markdown.

**The workflow stops on its own at anything a human must decide.** That is deliberate. When it
stops, send Aditya what it printed rather than pushing past it.

**Two things it will stop on right now:**

1. **We only have about 79 of METEOR's 1,251 clips.** On that slice the whole dataset holds
   **109 yields in 68,011 samples, and only 6 land in validation.** Every accuracy number from a
   set that small is noise. The fix is the full download — 1.81 GB, 10.28 GB on disk.
2. **The `Yield` label may be the wrong target.** At 1 in 620 it may not be learnable at all. The
   alternative is predicting **assertiveness** (`OverTaking OR LaneChanging OR Cutting`, about
   1 in 18), which for a planner means nearly the same thing. **Aditya decides this, not you and
   not your agent** — but decide it on the full dataset, not on 3% of it.

### C10 — Three things that were wrong and are worth knowing  *(NEW 1 Sep)*

**Features 28-31 were not empty, they were poisoned.** The GPS guard checked distance instead of
speed, so ego speed reached **557 m/s** and acceleration **±5,576 m/s²** — sitting in the same
input layer as features whose values live between 0 and 1. Fixed. If you ever see an ego speed
above about 40 m/s in the build output, the guard has been removed. Say so.

**`Gather` was never really a graph problem.** We had it written down that `Gather` comes from
message passing and blocks the MATLAB import. It also comes from ordinary indexing — `out[:, -1, :]`
emits one. Both models were producing it, including the LSTM. Fixed in both.

**PyTorch lies about the ONNX opset.** Ask for 9, 11 or 13 and you get a file stamped **18**. The
export script now reads the number back out of the file. This matters because that number is the
one thing Stream D is waiting on from you — sending the wrong one costs them a day.


### C11 — Your MATLAB install is SMALLER than the simulation people's  *(NEW 1 Sep)*

You are not using the simulation machine. You need MATLAB only for four things, and they need
far less than Stream A and D do.

| What you install | Why |
|---|---|
| MATLAB | everything |
| **Deep Learning Toolbox** | `check04`, and all three MATLAB models |
| **Computer Vision Toolbox** | the spotter and the road segmenter |
| **Lidar Toolbox** | PointPillars |
| **Add-On: "Deep Learning Toolbox Converter for ONNX Model Format"** | **`check04` fails without it** |
| **Add-On: "Automated Visual Inspection Library for Computer Vision Toolbox"** | **YOLOX training fails without it** |

**You do NOT need** Simulink, Stateflow, Automated Driving Toolbox, Sensor Fusion and Tracking,
or Navigation Toolbox. Those are the simulation side.

**Both add-ons come from `Home -> Add-Ons -> Get Add-Ons`, not the product installer.** Both are
free. They are the two things people miss, and both fail late with an error that reads like a
typo rather than a missing install.

**Do not tick every product on the licence.** There are 110+ on it; that is where the 30-40 GB
figure comes from. MATLAB itself is about 4-6 GB for a typical install.

### C12 — You can now train all five models  *(NEW 1 Sep)*

| Model | Where | Command |
|---|---|---|
| 1 · yield LSTM | Python | `/ml-run` |
| 2 · yield attention | Python | `/ml-run` |
| 3 · spotter, YOLOX | **MATLAB** | `/ml-models` |
| 4 · road, DeepLab v3+ | **MATLAB** | `/ml-models` |
| 5 · lidar, PointPillars | **MATLAB** | `/ml-models` |

Models 3-5 are trained natively in MATLAB and **never touch ONNX** - that is why they were
chosen. An imported YOLO fails on NMS and dynamic shapes.

**Their data cannot be downloaded by a script.** IDD needs a signup at
idd.insaan.iiit.ac.in/accounts/signup/ and a human accepting the terms. Do that before you
start model 3 or 4.

**Order matters. Model 1 is the only one the headline claim needs.** If you are short of time,
do `check04` first (Stream D is blocked on it), then `/ml-run`, and leave 3-5 until last.


# Part 4 — The contract

You produce **S2 (FeatureFrame)** and **S3 (YieldPrediction)** — section 3 of `AGENTS.md`.

The two things that must never change:
- **31 features, in that exact order.** Stream D's code reads them by position
- **The adjacency matrix is always produced**, even though the model ignores it

And one rule that is not obvious: **never convert METEOR into 3-D.** It needs depth estimation,
and one degree of camera tilt error causes about 31% distance error at 30 metres. We go the other
way — the simulation is flattened into the camera's view instead. The maths is already written.

---

# Part 5 — Done, and who is waiting

## Before any of this — run `/first-run`

Most of the MATLAB in this repo has **never been executed**. Checked against the MathWorks
documentation, yes; run, no. Four defects were already found that way. `/first-run` executes it
in the right order and says what to look for. **A task is not done if `/first-run` has not passed
on your machine.**

## A task is done when

| Task | Done means |
|---|---|
| C1 | Dataset extracted; `df -h` output sent before and after |
| C2 | **The ego-vs-agent question answered from a real file**, with the actual text pasted |
| C3 | *(superseded — `build_dataset.py` does this)* |
| C4 | Precision and recall reported **separately** for yield and no-yield, on unseen clips |
| C5 | `check04` imports a **real** exported file with **no placeholder layers**, and Stream D has the opset number |
| C9 | `/ml-run` completed end to end, or stopped at a decision and you reported it |
| C11 | `check01_environment` shows OK for Deep Learning, Computer Vision, Lidar, **and both add-ons** |
| C12 | All five models trained, each reported **per class** — cow, auto-rickshaw and pushcart by name |

**And four things are true of every task:**
1. It runs from a fresh copy of the repo, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 3 of `AGENTS.md` exactly
4. **Someone else could run it without asking you a question**

*"It works on my machine"* is not done. *"I know how to run it"* is not done.

## Your handoff

**You owe Stream D two things.**

**H3 — the format number (opset).** One number. It gates their entire integration. Send it the
moment you know, ahead of everything else.

**H4 — the trained model file.** Later, when training is done.

**You are waiting on nobody for C1 and C2.** Start the download today — it is the longest single
task in the project and everything about our model depends on it.

---

# Part 6 — Never do these

1. **Never edit `matlab/baseline/`.** That folder holds MathWorks' own planner, unmodified. It is
   what we compare against. If we change it, a judge calls it a rigged comparison and every result
   we have becomes worthless.
2. **Never invent a number.** If it is not in the claim ledger in the PRD (PDF), it does not go in a
   document, a comment, or a slide.
3. **Never change section 3 of `AGENTS.md`** (the frozen contract). If you genuinely need it
   changed, stop and ask Aditya. Do not edit it and hope.
4. **Never push code with a known bug.** We lost a previous hackathon by demoing something that
   had a bug we already knew about.
5. **Never summarise an error.** Send all of it.

---

# Where everything is

| You want | Look at |
|---|---|
| The whole idea, in plain language | the PRD (PDF) |
| **The contract you must match** | `AGENTS.md` **section 3** |
| What we measure | the PRD (PDF) |
| What we are allowed to claim | the PRD (PDF) |
| Who is waiting on you | the PRD (PDF) |

**The PRD is a PDF — ask Aditya for it.** Everything in this repo is code plus `AGENTS.md`.
