# Stream B — Perception

> ## You are **Role 1 · The World**, working with Stream A.
>
> Sensors attach to actors, so you and Stream A are one pair, not two people passing work over a
> wall. **Build together in the same sessions** — a scene appears, you put sensors on it, and
> what the sensors see immediately tells A whether the scene is right.
>
> **You produce `S1 TrackList` and `S9 DrivableSpace`** — and `S1` is the *only* interface
> between Role 1 and Role 2. Everything the planner knows about the world arrives through it.
> Get it right and the two halves of the team cannot break each other.
>
> **Do not open** `matlab/+sih/+planner/`, the Simulink model, `plan/`, or `ml/`. Those belong to
> other streams. If something there looks wrong, say so — do not go and fix it.


**You turn sensor data into a list of what is around the car.**

Everything downstream eats your output, so the shape of that output matters more than anything
else you do. Get it exactly right and nobody ever has to talk to you.

**Your machine:** Windows
**Your branch:** `stream-b-perception`

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

When the installer asks which products to install, tick **all seven**:

> MATLAB · Simulink · Automated Driving Toolbox · Computer Vision Toolbox ·
> Image Processing Toolbox · Deep Learning Toolbox · Stateflow

Then, inside MATLAB: **Home → Add-Ons → Get Add-Ons**, search for
**"Deep Learning Toolbox Converter for ONNX Model Format"** and install it. It is free.

**Now prove it worked.** In MATLAB, type:

```matlab
cd <where-you-cloned>/sih26037/derisk
check01_environment
```

You should see seven lines saying `[ OK ]`.
**If any line says `MISSING`, stop and tell Aditya.** Nothing else will work until it is fixed.

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
git checkout -b stream-b-perception
```

Do that once. From then on you are on your own branch and cannot break anyone.

### Saving your work

Do this **several times a day**, not once a week:

```bash
git add -A
git commit -m "B2: OSM import working, 14 roads found"
git push -u origin stream-b-perception
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

> *"B2 done. B3 blocked — I need check02 to pass first."*

Everyone knows what B2 and B3 are, because they are in this file.

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

### B1 — Get a laser point cloud out of the simulation

`derisk/check02_lidar_cow.m` already shows the exact way to call it. **Copy that pattern** — it is
tested and it works.

### B2 — Track things over time, and use the good tracker

Use **`trackerGridRFS`** — the same one MathWorks' own planner uses — or a PHD extended-object
tracker. Both are on our licence.

Why this specific type: it estimates **how big** an object is, not just where it is. That is built
for our hardest case — a bus and a scooter sitting in the same bit of road, with hundreds of laser
returns that all belong to one big vehicle.

### B3 — Produce the TrackList

This is your one real deliverable. It must match section 7 (S1) of the PRD (PDF) **exactly**.
Four rules you must not break:

1. Sorted by track number, smallest first
2. **Never** include our own car
3. **It may be empty** — and when it is, nothing downstream may crash. **Test this on purpose.**
   Write a test that passes an empty list and check nothing falls over
4. No `NaN`, no `Inf` in any position. If a track goes bad, drop it rather than pass it on

### B3b — Add radar

`drivingRadarDataGenerator`, fused with the lidar **before** you produce the TrackList.

The problem statement asks for *"camera, LiDAR, and radar"* and radar was missing from our first
design — that was our mistake, not yours. It also genuinely helps: radar measures **closing speed
directly** instead of calculating it, and it fails in different weather than lidar does.

Set the `SensorMask` field so we can tell which sensors saw each object.

### B3c — The near-field lidar ring  *(added 31 Aug)*

The roof lidar is like standing on top of the car with a torch: you see far down the street, but
**you cannot see your own feet.** There is a blind ring right around the car where the beams pass
over the top of anything close.

That blind ring is exactly where the scooty's mirror is when we squeeze past it in a galli.

**Add a ring of short-range lidars** — front, rear, both sides — that only look at the first
couple of metres. Same object, `lidarPointCloudGenerator`, just mounted low with a short
`MaxRange` and a wide vertical field of view. Real cars do this with parking sensors; it is not an
exotic claim.

**Rule of thumb: the roof lidar is how we DECIDE. The near-field ring is how we DON'T SCRATCH.**

What it must deliver:
- Free width beside the car, left and right, to a few centimetres
- The kerb, the wall, a dog, a child standing next to the door
- Enough coverage that there is **no blind sector within 2 m** of the body

Set **bit 3 of `SensorMask`** on any track a near-field sensor contributed to. The planner needs to
know a clearance measurement came from a sensor that can actually see that close — see S1.

Report the blind-zone geometry you measure: for each sensor, the nearest range at which it returns
points. **That number is what the squeeze manoeuvre is trusted against**, so do not estimate it.

### B4 — Make the sensors worse, on purpose

`matlab/+sih/+perception/injectNoise.m`. Three separate dials, each adjustable from a config file:
- position error
- objects randomly disappearing
- objects appearing that are not there

This produces **M3, the perception-degradation curve** — one of our three headline results.
**Nobody in this field publishes this curve.** B-GAP's own paper admits it needs "very good
sensing"; GameOpt runs with no sensors at all. This is entirely yours.

### B5 — The camera detector, offline only

YOLOX (built into MATLAB), trained on the IDD dataset, tested on real Indian video.

**Never import YOLO from ONNX** — it does not work, for several documented reasons. Use the
built-in one.

This never runs inside the simulation. It is a separate benchmark we report on its own. Here is
why, and it is a measured reason: **a full-size cow at 9.2 m is only 77 × 63 pixels** in a real
dashcam frame. By 25 m it is smaller than most detectors can reliably handle.

---

# Part 4 — The contract

**You produce S1 (TrackList).** Read section 3 of `AGENTS.md` before writing a line.
Get the field names and types exactly right — Streams C and D both read it, and if you rename one
field you break both of them at once.

---

# Part 5 — Done, and who is waiting

## A task is done when

| Task | Done means |
|---|---|
| B1 | A point cloud comes back with laser returns landing on a non-vehicle shape |
| B2 | Tracks keep the same ID across frames, and object size is estimated |
| B3 | TrackList matches S1 exactly — **and the empty case returns without crashing** |
| B3b | Radar detections fused; `SensorMask` correctly says which sensors saw each object |
| B4 | Three noise dials, each adjustable independently from a config file |
| B5 | YOLOX trained, accuracy reported on Indian video it has not seen |

**And four things are true of every task:**
1. It runs from a fresh copy of the repo, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 3 of `AGENTS.md` exactly
4. **Someone else could run it without asking you a question**

*"It works on my machine"* is not done. *"I know how to run it"* is not done.

## Your handoff

**You owe Streams C and D (handoff H2): the TrackList.**

Tell **both of them together** the moment it is stable. They are both blocked on it and they can
work in parallel once it exists.

**You are waiting on Stream A (H1)** for a scenario with actors. While you wait, read section 7 of
the PRD and write the empty-list test — that work does not need a scenario.

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
