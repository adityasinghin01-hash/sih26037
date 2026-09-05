# Stream E — Evidence

> ## You are **Role 2 · The Driver**, working with Stream D.
>
> You cannot measure a planner you do not understand, so you sit with the planner pair rather
> than alone. Read [`plan/ReadThis.md`](ReadThis.md) — the mechanism you are measuring is
> explained there.
>
> ### Your first task needs nobody, and it is blocking everyone
>
> **E1 IS DONE — `matlab/baseline/` is filled** (4 Sep 2026), unmodified and checksummed.
> **Your task is now to RUN it once, unmodified, and record exactly what happens.**
> `checkcode` passes on all 7 files, but that is not a run — so there is still no comparison.
> Read `matlab/baseline/BASELINE.md` first. If it errors on R2026a the way OpenTrafficLab did,
> **that is a finding: write it down, do not fix it.**
>
> ```bash
> # from the repo root, and then CHANGE NOTHING inside it
> ```
> The example is named in **task E1 below** — *Motion Planning in Urban Environments Using
> Dynamic Occupancy Grid Map*. **`AGENTS.md` section 2 does NOT name it** — it names the three
> baseline *types*. Do not go looking there and copy in the Frenet highway example by mistake.
> Copy it in unmodified and record the exact example name and MATLAB version alongside it.
>
> **Until that exists, no number this project produces is comparable to anything**, and the
> claim the whole project rests on has nothing behind it. It is a clone-and-don't-touch job,
> not a build, and it does not wait for WORLD or the planner.
>
> **If we tune the baseline so it fails, a judge calls it a strawman and every result we have
> dies.** That is why it must go in untouched and why nobody may edit it afterwards.


**You own the reason anyone believes us.**

A working planner with no numbers loses to a worse planner that has a graph. Every claim we make
in the final presentation comes from your work.

**Your machine:** Windows — that is where you develop.
**The demo machine is Aditya's Mac** (`TEAM.md`, "The main machine"). Every result that goes in the
report must be reproducible there, so no `C:\` paths anywhere near `runExperiment`.
**Your branch:** `stream-e-evidence`

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

### Step 3 — Install MATLAB

Go to **mathworks.com**, sign in with your **college email**, and associate licence **41087767**.

When the installer asks which products to install, tick **all nine**:

> MATLAB · Simulink · Automated Driving Toolbox · Computer Vision Toolbox ·
> Image Processing Toolbox · Deep Learning Toolbox · Stateflow ·
> **Sensor Fusion and Tracking Toolbox · Navigation Toolbox**

Then, inside MATLAB: **Home → Add-Ons → Get Add-Ons**, search for
**"Deep Learning Toolbox Converter for ONNX Model Format"** and install it. It is free.

**Now prove it worked.** In MATLAB, type:

```matlab
cd <where-you-cloned>/sih26037/derisk
check01_environment
```

You should see nine lines saying `[ OK ]` under REQUIRED PRODUCTS.
**If any line says `MISSING`, stop and tell Aditya** — with one exception:
`[ MISSING ] no ONNX import` blocks only the yield predictor (Stream C, and D's wiring of
it). D1-D5 and E1 do not need it. Carry on, and say which one you saw.

---

### Before you trust any MATLAB in this repo — run `/first-run`

Most of the MATLAB here was written on a machine with **no MATLAB installed**. Every function
name and signature was checked against the MathWorks documentation, but **checked is not run**.
Defects have already been found exactly that way, and **seven more on 4 September 2026** —
two of which stopped the simulation from running at all.

The first time you have MATLAB working, tell your AI assistant: **`/first-run`**. It runs
everything that has never been executed, in the right order, and says what to look for.

**Expect something to break.** That is the workflow doing its job, not the repo being broken.
Send the whole error, every line.


# Part 2 — How to work

### Your branch

**Never save your work directly to `main`.** Five people are working at once and you would
overwrite each other. You get your own branch:

```bash
git checkout -b stream-e-evidence
```

Do that once. From then on you are on your own branch and cannot break anyone.

### Saving your work

Do this **several times a day**, not once a week:

```bash
git add -A
git commit -m "E2: OSM import working, 14 roads found"
git push -u origin stream-e-evidence
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

> *"E2 done. E3 blocked — I need check02 to pass first."*

Everyone knows what E2 and E3 are, because they are in this file.

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

1. **Editing section 3 of `AGENTS.md`** (the frozen contract) — five other people build against it
2. **Editing anything in `matlab/baseline/`** — that is our control arm and it must stay untouched

**And never let it write a number you have not produced.** If the agent puts a figure in a comment
or a document, ask yourself: did something actually compute that? If not, it should say
`TODO(unverified)` instead. Invented numbers are how projects like this lose.


---

# Part 3 — Your tasks

### E1 — Set up the comparison car, and never touch it again

We compare our planner against **MathWorks' own shipped planner**, completely unmodified. It is
called **"Motion Planning in Urban Environments Using Dynamic Occupancy Grid Map"** and it needs
three toolboxes we already have.

Copy it into `matlab/baseline/` and then **never edit anything in that folder. Ever.**

Write down in `BASELINE.md`: the exact example name, the MATLAB version, and the date.

**Why this matters more than it sounds.** If we adjust their planner to make it perform worse, a
judge calls it a rigged fight and every number we produce becomes worthless. We picked their
*strongest* planner on purpose — it uses lasers like us, handles pedestrians and cyclists like us,
and targets a city intersection like us.

It fails at an unmarked junction for a **structural** reason: it needs a reference path — a set of
waypoints saying roughly where the road goes — and an unsignalled Indian junction does not provide
one. The coordinate system it thinks in does not exist there. **That is a real finding. Tuning it
to fail would not be.**

### E2 — Build the experiment runner

`matlab/+sih/runExperiment.m`. One command in, a folder out:

```
results/<run-name>/
    metrics.json      all ten numbers
    config.json       a copy of exactly what was fed in
    trajectories.csv  for Stream F to render
```

**A number without its configuration is not a result.** Always save the config alongside.

### E3 — Implement the ten measurements

They are defined in the PRD (PDF). **Implement them exactly as written.**

**Do not add measurements. Do not change definitions.** They were fixed before anyone ran anything
precisely so that nobody can say we chose flattering measurements afterwards. That is the whole
point, and it is worth more than any individual number.

### E4 — Produce the three graphs

1. **How long the car sits waiting** — ours against theirs
2. **Success rate as traffic gets heavier** — the headline
3. **How performance holds up as the sensors get worse** — Stream B gives you the noise dials

**Nobody in this field publishes the third graph.** That is why it is one of our three headline
results.

### E5 — Guard against winning the wrong way

**Collisions (M4) and near-misses (M5) must not get worse than the baseline.**

A car that gets through faster but is less safe is a **failed project**, and if that is what the
numbers say, **that is what we report.** Your job includes being willing to deliver bad news.

### E6 — Make it reproducible

A stranger with a fresh copy of the repo should regenerate every number with one command.

A judge can re-run ours in twelve minutes. They cannot re-run the published competitors. **That is
a genuine advantage — your job is to make it true.**

### E7 — Write the technical report

A required deliverable. **Every claim in it must appear in the claim ledger in the PRD (PDF) with its
evidence.** If a number is not in that table, it does not go in the report.

---

### E8 — Three baselines, not one  *(NEW 31 Aug)*

One baseline is attackable as strawman-by-selection. Three is not.

| Baseline | Why it fails here |
|---|---|
| MathWorks Frenet + occupancy grid, **handed the reference path it needs** | No progress term for a contested junction. Give it its best case and beat it anyway |
| **ORCA / reciprocal velocity obstacles** | Splits avoidance 50/50 and **assumes every agent runs the same algorithm. A cow does not** |
| **Always-yield** — what real AVs actually do | Perfect safety, never arrives. Makes the M1-vs-M4 trade visible instead of asserted |

**A benchmark everyone passes is useless.** Three planners failing three different ways is the
evidence that ours discriminates — that is the scientific contribution, and it costs nothing extra
because we are building all three anyway.

### ~~E9 — Prove it, then break it~~  **CANCELLED 4 September 2026 — WE DO NOT HAVE THE LICENCE**

> **Do not attempt any part of this task. Every toolbox it depends on is absent.**
> The heading used to read *"we have the whole licence"*. That was never checked, and it is wrong.

**Verified by running `ver` on the Mac, R2026a Update 5, 4 September 2026:**

| Toolbox E9 needs | Installed? |
|---|---|
| Simulink Design Verifier | **NO** |
| Simulink Fault Analyzer | **NO** |
| Requirements Toolbox | **NO** |
| Simulink Test | **NO** |
| Simulink Coverage | **NO** |
| Embedded Coder | **NO** |
| MATLAB Coder | **NO** |
| Simulink Coder | **NO** |

**All eight. Not some of it — all of it.** The complete list of the 11 products we actually have:
MATLAB, Simulink, Stateflow, Automated Driving, Computer Vision, Deep Learning, Image Processing,
Lidar, Mapping, Navigation, Sensor Fusion and Tracking.

### What was lost, and what replaces it

| E9 promised | Reality |
|---|---|
| Formal proof that `h >= 0` inside the chart | **Not available.** We show `h` **measured** every step across a run, and report `min(h)` and the count of `h < 0`. That is evidence, not proof, and we call it evidence |
| Fault injection / FMEA as a standards artefact | **Not available.** Any robustness sweep we do is hand-rolled, and must be described that way |
| Requirement→test→result traceability report | **Not available.** `runtests('matlab/tests')` and the per-function contract headers are what we have |
| **Measured** C latency on a chip (PIL) | **Not available.** We may report MATLAB timings and must label them **simulation timings**, never "latency on hardware" |

### Two consequences that reach other people

- **Person B: the `.Reason` string concern is void.** It was raised because Embedded Coder restricts
  strings inside buses, and E9 needed that for the PIL numbers. There is no Embedded Coder, so the
  constraint does not exist. `.Reason` stays a MATLAB `string` exactly as S4 specifies, and nothing
  in `AGENTS.md` section 3 needs revisiting.
- **`%#codegen` directives in the Stateflow charts are inert.** Harmless, but they do not mean the
  model can generate code — nothing here can.

### The honest sentence, if a judge asks

> We did not do formal verification or hardware-in-the-loop timing. Those need toolboxes outside our
> licence. What we have instead is the barrier value logged every step of every run, and the runs are
> reproducible.

**That is a fine answer. Claiming a formal proof we did not run is not.**

### E10 — Two metrics changed  *(NEW)*

- **M9 is now `handover rate`**, not "deadlock rate". Same measurement, but for an ADAS product it
  is the headline quality number rather than an apology.
- **M11 handover lead time** — seconds of warning before the driver must act.
  **A handover requested after the point of no return counts as a FAILURE.**


# Part 4 — The contract

You read **everything** and produce the numbers. Your one output format is fixed in
section 3 of `AGENTS.md`:

- `results/<run>/metrics.json` — keys are the metric IDs `M1` to `M10`
- `results/<run>/trajectories.csv` — columns `t,actor_id,class_id,x,y,z,yaw`, all in metres,
  seconds and radians, with a header row

Stream F reads that CSV directly, so the column names and order cannot change.

---

# Part 5 — Done, and who is waiting

## A task is done when

| Task | Done means |
|---|---|
| E1 | `BASELINE.md` names the exact example and version, and records it as unmodified |
| E2 | One command produces the results folder with metrics **and** a copy of the config |
| E3 | All ten measurements computed, matching section 8 exactly |
| E4 | Three graphs plotted from real runs, not placeholders |
| E5 | Safety compared against the baseline and **reported even if we come out worse** |
| E6 | A fresh copy of the repo reproduces every number with one command |
| E7 | Technical report written, every claim traceable to section 9 |

**And four things are true of every task:**
1. It runs from a fresh copy of the repo, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 3 of `AGENTS.md` exactly
4. **Someone else could run it without asking you a question**

*"It works on my machine"* is not done. *"I know how to run it"* is not done.

## Your handoff

**You owe Stream F (handoff H6): `results/<run>/trajectories.csv`** in exactly the format
above. MATLAB does all the computing; Blender only draws what you produce.

**You are waiting on everyone (H5)** — you cannot measure a pipeline until it runs end to end.

**But E1 needs nothing but MATLAB.** Set up the baseline and write `BASELINE.md` on day one.
That is real progress while the others build.

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
