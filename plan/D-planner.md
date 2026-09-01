# Stream D — The Planner

> ## Read [`plan/ReadThis.md`](ReadThis.md) first.
>
> `plan/` is your folder. It explains what you are building in plain language, the mechanism,
> and why each piece exists.
>
> - **[`plan/ReadThis.md`](ReadThis.md)** — the roadmap. Read once, top to bottom
> - **[`plan/CONTRACT-AB.md`](CONTRACT-AB.md)** — **the boundary between the two of you.
>   Read this before writing anything**
>
> **You are two people and you must not share files.** A Simulink `.slx` is binary — git cannot
> merge two people's edits, so one of you silently loses a day's work.
>
> ### Stay inside the planner
>
> **Yours:** `matlab/+sih/+planner/` (Person A), the Simulink model and chart (Person B), `plan/`.
> **Not yours, and you must not open them:** `ml/` and everything in it, `matlab/+sih/+prediction/`,
> `+models/`, `matlab/+sih/+scenario/`, `+perception/`, and `matlab/baseline/`.
>
> **The yield predictor is not yours.** You consume `S3 PYield` through the frozen contract and
> never open the model that produced it. If `PYield` looks wrong, **say so to a human** — do not
> retrain anything, and do not go reading `ml/` to work out why.
>
> Install the fence so this does not depend on memory:
> `cp .claude/fences/planner.settings.local.json .claude/settings.local.json`
>
> | | Person A | Person B |
> |---|---|---|
> | Writes | `matlab/+sih/+planner/*.m` | the Simulink model and Stateflow chart |
> | Command | **`/plan-work`** | **`/plan-harness`** |
> | Branch | `stream-d-a` | `stream-d-b` |
>
> **This file is your task list. The roadmap is how to do the work.**


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

### D0 — Clone OpenTrafficLab first, or nothing loads

**It is not in this repository.** `NegotiatingStrategy.m` extends `DrivingStrategy`, which is
OpenTrafficLab's class. It is third-party code so it is gitignored on purpose — which means a
fresh clone of our repo does not have it, and MATLAB says `Undefined base class
'DrivingStrategy'`. That reads like our code is broken. It is not.

```bash
git clone https://github.com/mathworks/OpenTrafficLab.git
```
```matlab
addpath(genpath('OpenTrafficLab'))
addpath('matlab')
runtests('matlab/tests')
```

**Both of you. Before anything else.**


# Part 3 — Your tasks

## Which of you does which — read this before you pick one up

| Task | Owner | Why |
|---|---|---|
| **D1** prove the maths works | **both**, five minutes | orientation |
| **D2** role → command | **A** | a pure function, tests without Simulink |
| **D3** Stateflow chart | **B** | it is the chart |
| **D4** mode switching | **B** | lives in the chart |
| **D5** log the safety number | **B** | the model writes the log |
| **D6** contingency planner | **A** | the biggest job, and pure maths |
| **D7** three rates | **A** designs, **B** wires | the speed limit is A's, the rates are B's |
| **D8** the road barrier | **A** | pure maths |
| **D9** reversibility | **A** designs, **B** holds `Committed` | the geometry is A's, the state is B's |
| **D10** turning | **A** | derived from geometry |
| **D11** handover | **B** | a signal the chart raises |

**The test:** *does it need Simulink to test?* No → A. Yes → B.
Full rules in [`plan/CONTRACT-AB.md`](CONTRACT-AB.md).



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

### D6 — The contingency planner  *(NEW 31 Aug — this is now the biggest job on the project)*

The old design checked "is my speed safe right now" and nothing more. **That is a reactive layer
with nothing above it.** The PS asks for a *path* that can be replanned in real time.

Every cycle:
1. `trajectoryGeneratorFrenet` generates **several candidate paths** 3–5 s ahead
2. Roll each forward under **two futures per agent — they yield, they assert** — weighted by
   `P(yield)` from Stream C
3. Collision-check with `dynamicCapsuleList`
4. **Commit only the shared trunk** — the first piece safe under *both* futures
5. Throw it away and redo it

**The trunk IS the probe.** Creeping forward is not a special behaviour; it is the committed part
of a plan that is safe whichever way they behave.

This is **branch / contingency MPC**, whose standard form models exactly two modes, *Yield* and
*Assert* — precisely what our predictor outputs. Start from MathWorks' *Highway Trajectory Planning
Using Frenet Reference Path* example: it already uses all three objects, 5 s horizon, checked every
0.5 s. **This is integration, not invention.**

**When forward is blocked, bias generation toward LATERAL candidates** instead of giving up. Going
around is just another candidate path.

### D7 — Three rates, and why latency stays small  *(NEW)*

| layer | rate | may be slow? |
|---|---|---|
| Route (S10) | 2–5 Hz | yes, ~100 ms is fine |
| Contingency (D6) | ~10 Hz | yes |
| **Barriers (D8)** | **50–100 Hz** | **no — closed form, microseconds** |

Deliberation is allowed to be slow **because the barrier underneath always runs and can veto
anything.** Do not try to make the whole system fast; make the bottom layer fast.

### D8 — The second barrier: the ground itself  *(NEW — S9)*

A khai is not an object. **Lidar returns nothing from a drop-off**, so it can never appear in S1.
Stream B gives you `DrivableSpace` (S9).

```
h_agent = lambda - beta            >= 0    moving things
h_road  = d_edge - d_min(side,v)   >= 0    the ground
```
Both must hold. **No mode switch** — on a 3 m ghat road `h_road` binds, at an open junction
`h_agent` binds, geometry decides.

- **`d_min` is asymmetric AND speed-dependent.** Bigger on the drop side than the wall side — a
  wall dents a panel, a drop is fatal, so weight by **consequence**, not collision probability.
  Bigger with speed: 2 km/h needs centimetres, 40 km/h needs ~1.5 m.
- **Footprint is the real body including mirrors**, and shrinks when `MirrorsFolded` is true.
  Check the **swept path of the whole body**, not the centreline.
- **Speed is the minimum of three limits:**
  `v_max = min( sqrt(aLat*R), sqrt(2*aBrake*(VisibleRange - v*tReact)), vRoute )`
  On a hairpin the first two bind at once. **Weather needs no special mode** — bad weather shrinks
  `VisibleRange`, so the car slows by itself.

### D9 — Reversibility: do not drive somewhere you cannot leave  *(NEW)*

Everything above asks *is this safe?* This asks **if it goes wrong, can I get out?**

1. **Escape memory** — S10 carries breadcrumbs of every point wide enough to turn around in. When
   blocked you do not ask "can I turn here", you already know where the last place was.
2. **Point of no return + `Committed`** — compute the moment after which aborting is worse than
   continuing. Before it, abort freely. After it, **stop re-deciding.** A 10 Hz planner will dither
   halfway across a cut unless you forbid it, and dithering in the middle is what causes the crash.
3. **Blockage triage ends in a DECISION, not a stop:**
   `creep -> wait -> short horn -> long horn -> flash -> GO AROUND -> request driver handover`
   If it has not moved in T seconds after being asked, treat as permanent, mark the edge blocked in
   S10, and re-route — possibly a U-turn, possibly reverse to the last escape point.
4. **Nose-to-nose deadlock rule:** two cars meet in a galli, someone must reverse.
   **Whoever is nearer a passing place reverses.** Geometric, legible, and the same shape as the
   uphill-priority rule.

### D10 — Turning  *(NEW)*

**One planner, not five.** Only which constraint binds changes.

| turn | binds | needs |
|---|---|---|
| Normal | nothing | — |
| Roundabout | conflict — it's a merge | existing probe-commit |
| **U-turn** | **minimum turning radius** | multi-point turn, **needs `Gear = -1`** |
| **Side cut** | crossing two streams while exposed | **refuge points** — end the trunk at a safe intermediate stop that does not block the stream you already crossed |
| **Sharp at speed** | **lateral grip** | the `sqrt(aLat*R)` term in D8 |

**Turn type is DERIVED from `S10.GoalHeading`, never classified.** ~180° + tight radius = U-turn.
~90° across a stream = cut. **No sign detection.**

### D11 — Handover is the terminal state  *(NEW)*

India requires a driver in effective control, so **we need no remote operator.** When the car runs
out of moves it raises `Signal = 6`.

**The rule that matters: raise it BEFORE `Committed` goes true.** Handing over after the point of
no return is the known Level-3 failure mode — the human cannot help any more. A late handover is
logged as a **failure** (M11), not a handover.


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
