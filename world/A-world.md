# Stream A — The World

**You build the roads and the scenarios. Everything the car drives on is yours.**

Nobody else can test anything until you have a working scenario, so you are first. That is a lot
of responsibility and also means you are never waiting on anyone.

**Your machine:** Windows or Mac
**Your branch:** `stream-a-world`

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

**Do not tick every product.** There are 110+ on this licence and that is where the
"MATLAB needs 30-40 GB" story comes from. MATLAB itself is about 4-6 GB for a normal install.

Tick these:

> MATLAB · Simulink · Stateflow · **Automated Driving Toolbox** ·
> **Navigation Toolbox** · **Sensor Fusion and Tracking Toolbox** ·
> Computer Vision Toolbox · Image Processing Toolbox · Deep Learning Toolbox

Navigation and Sensor Fusion are on that list because the **baseline** we compare against needs
them, and you are the one who builds the scene it runs in. Leaving them out means discovering it
much later.

Then, inside MATLAB: **Home → Add-Ons → Get Add-Ons**, search for
**"Deep Learning Toolbox Converter for ONNX Model Format"** and install it. It is free, and the
product installer does not include it.

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
git checkout -b stream-a-world
```

Do that once. From then on you are on your own branch and cannot break anyone.

### Saving your work

Do this **several times a day**, not once a week:

```bash
git add -A
git commit -m "A2: OSM import working, 14 roads found"
git push -u origin stream-a-world
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

> *"A2 done. A3 blocked — I need check02 to pass first."*

Everyone knows what A2 and A3 are, because they are in this file.

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

### A1 — Run the seven checks  *(do this first, today)*

Open `derisk/HOW-TO-RUN.md` and follow it exactly. Seven checks, about an hour in total.

**Check 2 is the most important thing in this entire project.** It puts an unmarked road, a
cow-shaped mesh and a simulated lidar together and asks one question: do laser returns actually
come off the cow? If the answer is no, the whole design changes — and we need to know now, not in
two months.

Send back **the full text output and the saved image**, whatever the result.

**Then run `/first-run`.** Most of the MATLAB in this repo has been checked against the MathWorks
documentation but **never actually executed** — it was written on a machine with no MATLAB. That
workflow runs it in the right order and tells you what to look for. **Expect something to break.
That is the point of it, not a sign the repo is broken.**

### A2 — Get a real Meerut road into MATLAB

This is the move that won last year's team their prize, and for us it is two lines.

First get the map. In your browser:
1. Go to **openstreetmap.org**
2. Search for a Meerut junction — try *"Begum Bridge Road, Meerut"*
3. Zoom in so one junction and its approach roads fill the screen
4. Click **Export** at the top, then the blue **Export** button
5. It downloads `map.osm`. **Rename it `meerut.osm`** and put it in the `derisk` folder

Then in MATLAB:
```matlab
check03_osm_import
```

If the Export button is greyed out, click the **Overpass API** link just underneath it instead.

### A3 — Build the two main scenarios

**Only these two matter first:**
1. **A four-way junction with no traffic signal** — nobody has priority
2. **A cattle crossing** — a cow on an unmarked road, our car approaching

Each one needs a **density setting** you can turn up and down, because our headline result is a
graph of success rate against how busy the road is. One cow on an empty road cannot produce that
graph.

### A4 — Roads with no lane markings

```matlab
road(scenario, centers, 'Lanes', ...
     lanespec(1,'Width',12,'Marking',laneMarking('Unmarked')));
```

**`lanespec` is all lowercase.** `laneSpec` does not exist. This already cost us an hour once.

### A5 — Use real recorded traffic, not made-up traffic

Instead of writing waypoints by hand, drive the other vehicles from **real recorded Indian
traffic** (Stream C can give you the data).

This matters more than it sounds. If we script the traffic ourselves, a judge can say *"you
arranged the traffic so the other car would fail."* If it is recorded reality, that objection
disappears permanently. **This is the highest-value thing you do after A1.**

### A6 — Export the scenes

```matlab
export(scenario,'OpenDRIVE','scene.xodr');
```

This is our answer when a judge asks *"where are the RoadRunner scenes?"* — ours import into
RoadRunner the day a licence arrives. Note: junctions built with `roadGroup` are documented as
unsupported for this export. **Test it early and tell us what breaks.**

### A7 — The other three scenarios

Only after 1 and 2 are perfect: dense market · unmarked village road · highway merge.
All five must ship — the problem statement requires five.

---

### A8 — The galli, the ghat and the ground  *(NEW 31 Aug)*

**A8a · The galli squeeze.** A narrow lane, a scooty blocking one side, centimetres to spare. This
is our *dense market* scenario and **the Frenet baseline cannot even start** — no lane, no
reference path, no gap in a traffic stream. Build it narrow enough that mirrors matter.

**A8b · The ghat road.** `road()` takes elevation in the z column, so a climbing road with hairpins
is buildable. **First run `derisk/check07_negative_obstacle.m`** — we do not yet know whether the
cuboid world models any ground *beside* the road, and if it does not, a drop-off cannot be
represented geometrically. Report which fallback is needed. Real Indian terrain elevation is
available through Mapping Toolbox.

**A8c · Potholes and speed breakers.** The PS says "potholes are common". They are **not the same
thing**: a pothole is a *cost* (sometimes hitting it beats swerving into a scooter), a speed
breaker is a *speed limit pinned at a place*. Both are small vertical features — model them as
geometry, not as actors.

**A8d · Pedestrians need behaviour, not just boxes.** The cow has an internal state; our
pedestrians are currently just cuboids, which is backwards for a market scene. Give them a
**social force model** for crowd avoidance plus a small state machine —
`waiting -> committing -> crossing -> hesitating` — and an **assertive/deferent parameter** swept
exactly like the cow's habituation. **The hesitater** (steps out, sees the car, stops) is the
dangerous one.

**A8e · Wrong-way drivers.** The PS background says drivers "drive against traffic." Add one. Our
`HEAD_ON` role already handles it — this scenario just proves it.


# Part 4 — The contract

You produce a **scenario**, not a struct. But Stream B attaches sensors to your actors,
so two things must be true:

- Every actor has a sensible **ClassID** from section 5 of the contract — auto-rickshaw is **4**,
  pedestrian **8**, cow **10**, pushcart **12**
- Every actor has real dimensions in metres. A cow is roughly **1.9 m long, 0.65 m wide, 1.4 m tall**

---

# Part 5 — Done, and who is waiting

## A task is done when

| Task | Done means |
|---|---|
| A1 | All seven checks run, full output and every image sent |
| A2 | `check03_osm_import` prints more than 0 roads and saves the map picture |
| A3 | Both scenarios run start to finish, and turning the density up visibly adds traffic |
| A4 | A road exists with no painted lines in the plot |
| A5 | Other vehicles follow **recorded** traffic, not hand-written paths |
| A6 | `.xodr` file is produced and reopens without error |
| A7 | All five scenarios exist |

**And four things are true of every task:**
1. It runs from a fresh copy of the repo, following only what is written down
2. A test covers it, or a script prints the evidence
3. It matches section 3 of `AGENTS.md` exactly
4. **Someone else could run it without asking you a question**

*"It works on my machine"* is not done. *"I know how to run it"* is not done.

## Your handoff

**You owe Stream B (handoff H1): a working scenario with actors in it.**

Tell them the moment A3 has moving actors — even a rough version. They cannot attach sensors to
nothing, so every day you delay is a day they lose.

**Nobody is blocking you.** You can start A1 right now.

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
