# Stream C — Prediction

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
pip install torch onnx numpy tqdm xmltodict
```

Prove it worked:
```bash
python python/model/yield_lstm.py
```
It should print the model size and some numbers. If it errors, send the whole error.

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

1. **Editing section 7 of `docs/PRD.md`** (the frozen contract) — four other people build against it
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

### C3 — Write the loader

`python/meteor/loader.py`. Read the XML files, group boxes into per-vehicle tracks over time, feed
them through `frame_features()` (already written for you), and produce sequences plus labels.

Ask your agent to write it. **You check the output** — print the shapes, and spot-check ten
examples against the actual video by eye. A loader that runs but produces nonsense is worse than
one that crashes.

### C4 — Train

Start simple: balanced classes, held-out clips the model has never seen, and report **precision
and recall separately** for yield and no-yield. A model that says "no" every time can look 80%
accurate and be useless.

Then train the **second version** using the adjacency matrix the loader already produces, and
report the comparison. That is why the adjacency matrix exists from day one even though the main
model ignores it.

**Eight GPUs means forty small experiments, not one huge model.** Say that honestly — it is what
we actually do and it is more defensible.

### C5 — Export, and send Stream D one number

```bash
python python/export/to_onnx.py
```

This writes the model in four different formats. MATLAB accepts some and rejects others.
Stream D runs `derisk/check04_onnx_lstm.m` to find out which.

**Send Stream D the working format number the moment you have it. Do not wait for training to
finish.** That single number blocks their entire integration.

---

# Part 4 — The contract

You produce **S2 (FeatureFrame)** and **S3 (YieldPrediction)** — section 7 of `docs/PRD.md`.

The two things that must never change:
- **31 features, in that exact order.** Stream D's code reads them by position
- **The adjacency matrix is always produced**, even though the model ignores it

And one rule that is not obvious: **never convert METEOR into 3-D.** It needs depth estimation,
and one degree of camera tilt error causes about 31% distance error at 30 metres. We go the other
way — the simulation is flattened into the camera's view instead. The maths is already written.

---

# Part 5 — Done, and who is waiting

## A task is done when

| Task | Done means |
|---|---|
| C1 | Dataset extracted; `df -h` output sent before and after |
| C2 | **The ego-vs-agent question answered from a real file**, with the actual text pasted |
| C3 | Loader produces `[20, 31]` sequences **and** the adjacency matrix, shapes verified |
| C4 | Precision and recall reported **separately** for yield and no-yield, on unseen clips |
| C5 | At least one exported file that MATLAB imports without error |

**And four things are true of every task:**
1. It runs from a fresh copy of the repo, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 7 of `docs/PRD.md` exactly
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
2. **Never invent a number.** If it is not in section 9 of `docs/PRD.md`, it does not go in a
   document, a comment, or a slide.
3. **Never change section 7 of `docs/PRD.md`** (the frozen contract). If you genuinely need it
   changed, stop and ask Aditya. Do not edit it and hope.
4. **Never push code with a known bug.** We lost a previous hackathon by demoing something that
   had a bug we already knew about.
5. **Never summarise an error.** Send all of it.

---

# Where everything is

| You want | Look at |
|---|---|
| The whole idea, in plain language | `docs/PRD.md` sections 1–5 |
| **The contract you must match** | `docs/PRD.md` **section 7** |
| What we measure | `docs/PRD.md` section 8 |
| What we are allowed to claim | `docs/PRD.md` section 9 |
| Who is waiting on you | `docs/PRD.md` section 11 |

**`docs/PRD.md` is the only other document.** Everything else is code.
