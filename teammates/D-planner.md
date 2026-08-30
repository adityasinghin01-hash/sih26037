# Stream D — The Planner

**You own the thing that makes this project novel.** Everything else is plumbing around it.

Good news: the hardest maths is already written and tested for you.

**Your machine:** Windows
**Your branch:** `stream-d-planner`

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

# Part 2 — How to work

### Your branch

**Never save your work directly to `main`.** Five people are working at once and you would
overwrite each other. You get your own branch:

```bash
git checkout -b stream-d-planner
```

Do that once. From then on you are on your own branch and cannot break anyone.

### Saving your work

Do this **several times a day**, not once a week:

```bash
git add -A
git commit -m "D2: OSM import working, 14 roads found"
git push -u origin stream-d-planner
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

> *"D2 done. D3 blocked — I need check02 to pass first."*

Everyone knows what D2 and D3 are, because they are in this file.

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

### D1 — Prove the maths works  *(five minutes, do it first)*

Two files are already written: the collision geometry and the role assignment. Thirteen tests
check them. Run this the moment MATLAB is installed:

```matlab
cd <where-you-cloned>/sih26037
results = runtests('matlab/tests/testPlannerGeometry.m');
disp(results)
```

**All thirteen must pass.** Send the full output either way. This needs no simulation and no extra
toolboxes — it checks the planner's maths on its own.

### D2 — Turn a role into an actual command

`matlab/+sih/+planner/chooseVelocity.m`. The rules come straight from the real maritime rulebook:

- **GIVE_WAY** → one **early and large** move. Not creeping forward inch by inch
- **STAND_ON** → **hold course and speed. Do nothing.** This is the hard one, because doing
  nothing feels wrong to write — and it is the entire safety argument
- **Rule 8 forbids "a series of small alterations."** If your car wobbles or oscillates, it is
  wrong, and metric M10 will catch it

### D3 — Build the Stateflow chart

Subclass `DrivingStrategy` from OpenTrafficLab. **Delete the `TrafficController`.**

That class is a central referee — it holds a list of junctions and a flag saying whether each may
be entered. A vehicle asks permission and obeys. **A traffic signal is exactly that.** An Indian
junction has no such thing, so we remove it and let each vehicle decide from geometry.

`NegotiatingStrategy.m` is already written as your starting point. It deliberately falls back to
the original behaviour for now, so the simulation runs end to end from day one while you fill in
the real logic.

**Read the PRD (PDF) first** — there is a real risk noted there. OpenTrafficLab's own
code says it was only tested on MATLAB 2020b and may not work on newer versions. **Find out early.**

### D4 — Know when to switch off

When the road actually has lane markings, switch to `STRUCTURED` mode and defer to normal
lane-based planning.

We do not claim to beat lane-based methods on a proper highway — they are genuinely better there.
**"Our planner knows when it isn't needed"** is a stronger thing to say than pretending otherwise.

### D5 — Log the safety number

Every step, for every tracked object, record `h = lambda - beta`.

That number is already calculated for you inside `velocityObstacle.m`. When it is above zero we
are safe; below zero is a violation. **It is also, mathematically, a recognised safety proof** —
which means our negotiation logic and our safety guarantee are the same equation. We do not bolt a
safety system on top; the planner is already written in its language.

---

# Part 4 — The contract

You read **S1 (TrackList)** and **S3 (YieldPrediction)**, and produce **S4 (Role and
EgoCommand)** — section 3 of `AGENTS.md`.

One rule that is easy to get wrong: **when a prediction is marked invalid** (the vehicle has not
been tracked long enough), **fall back to the geometric role alone.** Do not treat an invalid
prediction as "50/50". That is a real bug waiting to happen.

---

# Part 5 — Done, and who is waiting

## A task is done when

| Task | Done means |
|---|---|
| D1 | **13 tests passed**, full output sent |
| D2 | Give-way makes one clear move; stand-on makes **no** change at all |
| D3 | Stateflow chart runs in the scenario with the central controller removed |
| D4 | Planner switches mode when lane markings are present |
| D5 | `h` logged every step, per object, and can be plotted |

**And four things are true of every task:**
1. It runs from a fresh copy of the repo, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 3 of `AGENTS.md` exactly
4. **Someone else could run it without asking you a question**

*"It works on my machine"* is not done. *"I know how to run it"* is not done.

## Your handoff

**You owe Stream E (handoff H5): a planner that runs end to end.** They cannot measure a
pipeline that does not complete.

**You are waiting on:**
- Stream B (H2) for the TrackList
- Stream C (H3) for the format number, then (H4) the trained model

**But D1 needs nothing.** Run the thirteen tests the day MATLAB exists — that is real, verifiable
progress on day one.

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
