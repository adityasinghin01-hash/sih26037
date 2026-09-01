# ReadThis — the planner, start to finish

**You are Stream D. This folder is yours.** You are building the part of the project everything
else exists to serve: **the thing that decides what the car does.**

It is the biggest job here and it is two people. Read this once before you start.

---

# 0 · What you are building, in plain words

A car arrives at an Indian junction. No traffic light. No priority rule. Nobody is going to stop
and wave it through.

Every self-driving car ever built handles this the same way: **when unsure, stop.** At a junction
where the traffic never breaks, that car waits forever.

**Ours asks a question instead.** It creeps forward a little — a *probe*. It watches whether the
other driver slowed, held, or pushed on. Then it commits or backs off. And the whole time it
keeps a number called `h` above zero, which is our proof it never crossed its own safety line.

That is the project. You are building it.

---

# 1 · The two of you, and why you must not share files

| | **Person A** | **Person B** |
|---|---|---|
| Tool | Claude Code | Antigravity |
| Writes | `matlab/+sih/+planner/*.m` — pure functions | the Simulink model and Stateflow chart |
| Command | **`/plan-work`** | **`/plan-harness`** |
| Branch | `stream-d-a` | `stream-d-b` |
| Tests in | seconds, no Simulink needed | minutes, model must run |

**A Simulink `.slx` file is binary.** Git cannot merge two people's edits to it — one version
silently overwrites the other. No conflict marker, no warning, just a lost day. **So B is the
only person who ever opens it.**

The full rules are in **`plan/CONTRACT-AB.md`**. Read it before you write anything.

**The question that settles almost every argument about whose job something is:**
*does it need Simulink to test?* No → A's. Yes → B's.

---

# 2 · What is yours, and what is not

| Yours | Not yours |
|---|---|
| `matlab/+sih/+planner/` — Person A | **`ml/`** — Stream C's folder, do not read it to debug your work |
| the Simulink model and chart — Person B | `matlab/+sih/+prediction/`, `+models/` — Stream C |
| | `matlab/+sih/+scenario/`, `+perception/` — Streams A and B |
| | **`matlab/baseline/`** — the competitor we compare against. Never |

**You consume the yield predictor, you do not own it.** It reaches you as `S3 PYield` through the
contract. If it looks wrong, tell Stream C. Do not open `ml/` and do not retrain anything — that
is how two people end up with two different models and nobody knows which one the demo used.

---

# 3 · Before anything: clone OpenTrafficLab

**It is not in this repository and nothing in `+planner` loads without it.**
`NegotiatingStrategy.m` extends `DrivingStrategy`, which is OpenTrafficLab's class. It is
third-party code so it is gitignored on purpose — but that means a fresh clone of our repo does
not have it, and MATLAB will say `Undefined base class 'DrivingStrategy'`, which reads like our
code is broken when it is not.

```bash
git clone https://github.com/mathworks/OpenTrafficLab.git
```
```matlab
addpath(genpath('OpenTrafficLab'))
addpath('matlab')
runtests('matlab/tests')
```

**Both of you need this. Do it first.**

---

# 4 · What already works — build on it, do not rewrite it

| File | What it gives you |
|---|---|
| `velocityObstacle.m` | `beta`, `lambda`, `tcpa`, `d` for one agent |
| `assignRoles.m` | which role each agent has (S7) |
| `NegotiatingStrategy.m` | the OpenTrafficLab subclass your work plugs into |
| `testPlannerGeometry.m` | 12 geometry tests, all passing. Run them before and after every change |

**These are the most trusted code in the repository.** If they break after you change something,
you changed something you did not mean to.

## The one number that matters

```
h = lambda - beta
```

`beta` is how wide the danger cone is. `lambda` is how far off it you are pointing.
**`lambda < beta` means you are on a collision course.** So `h` is your margin, and everything
you build exists to keep it above zero.

**It is logged every step. That log is our safety evidence.** A run without it is not a result.

---

# 5 · The mechanism, in the order it happens

Every cycle, roughly ten times a second:

1. **Generate several possible paths** a few seconds ahead — not one plan, several
2. **For each agent, imagine two futures**: they yield, or they assert. Weight them by `PYield`,
   the number the machine-learning model gives you
3. **Check every path against both futures**
4. **Commit only the part that is safe whichever way it goes** — the shared trunk
5. Throw the rest away and do it again next cycle

**The trunk IS the probe.** That is the sentence the whole project rests on. The car edges
forward along the part of the plan that is safe no matter what the other driver does — and that
motion is itself the question being asked. It is not a plan plus a separate signal. **The
movement is the message.**

## Three speeds, and why the car is never slow to react

| Layer | Rate | What it does |
|---|---|---|
| Route | 2–5 Hz | which exit, which direction |
| Contingency | 10 Hz | the paths and the trunk above |
| **Safety barrier** | **50–100 Hz** | closed form, microseconds, **can veto anything** |

**The thinking is allowed to be slow because the barrier underneath is always running.** That is
why a heavy planner does not make an unsafe car.

## Two barriers, not one

```
h_agent = lambda - beta          >= 0     moving things
h_road  = EdgeDistance - dMin    >= 0     the ground itself
```

A *khai* — a drop at the edge of a hill road — **returns no lidar points at all.** Nothing comes
back, so it can never appear in the track list as an object. It is not a thing to avoid; it is
the absence of ground. That is why the second barrier exists and why it comes through S9 instead.

**No mode switch. The geometry decides which one binds.** On a 3 m ghat road it is the road. At
an open junction it is the agents.

**And the margin is not symmetric.** Scraping a wall dents a panel. Going over the edge is fatal.
So `dMin` is larger on the drop side — **weighted by consequence, not by probability.**

---

# 6 · Speed is one number for three reasons

```
v_max = min( sqrt(aLat * R),                             hold the road
             sqrt(2*aBrake*(VisibleRange - v*tReact)),   stop inside what you can see
             vRoute )
```

**There is no weather mode, and there must not be one.** Fog does not need special handling: it
shrinks how far you can see, the second term shrinks, and the car slows down. **That is exactly
why a human slows in fog.** Adding a rain branch would invent a second mechanism for something
that already falls out of the first.

---

# 7 · The question nobody usually asks

Everything above asks *is this safe*. Almost nothing in the literature asks:

> **If this goes wrong, can I get out?**

A manoeuvre is not a single decision. It has an entry, a point after which you cannot abort, and
an exit. Most planners model only the entry.

- **Escape breadcrumbs** — remember where you have been, and which of those places were wide
  enough to turn around in. When blocked, you already know where the last one was
- **Point of no return** — the moment after which aborting is worse than continuing. Before it,
  abort freely. After it, set `Committed` and **stop re-deciding**
- **A planner running at 10 Hz will dither in the middle of a crossing unless you forbid it —
  and dithering in the middle is what actually causes the accident**
- **Handover before commitment.** A driver is always in the seat in India, so giving the car back
  is our last resort. But handing it back *after* the point of no return is not safety, it is
  abdication. **`Signal = 6` must be raised BEFORE `Committed` goes true**, and M11 counts a late
  one as a failure

---

# 8 · What you consume and what you produce

`AGENTS.md` section 3 is the contract. **Read it, and name in every function header which struct
you consume or produce.**

| In | From |
|---|---|
| **S1** TrackList | Stream B — the things around us |
| **S3** YieldPrediction | Stream C — `PYield` per track |
| **S9** DrivableSpace | Stream B — the ground, the edge, how far we can see |
| **S10** Route | the thin route layer — goal direction only |

| Out | To |
|---|---|
| **S4** EgoCommand | the vehicle model, and the logs |

**Two rules that are easy to get wrong:**

- **When S3 says `Valid = false`, use the geometric role alone. Never 0.5.** A made-up
  probability is worse than none, because the planner trusts the number it is given.
- **`Accel` is clamped to `[-6, +3]` m/s², `SteerAngle` to `[-0.6, +0.6]` rad.** S4 fixes those.
  Never emit outside them.

---

# 9 · Where to start

**Person A:** type `/plan-work`. It has the build order and the maths already specified.
Start with D2 — turning a role into a command. Small, and it gets you oriented.

**Person B:** type `/plan-harness`. **Start today, with stubs.** Do not wait for A — every struct
is already defined, so you can build the whole loop against fakes this week and let the real
pieces drop into slots that already work.

**Both:** run `runtests('matlab/tests')` before every push. All of them, not just yours.

---

# 10 · Never do these

1. **Never open a file the other person owns.** A does not open the `.slx`; B does not edit
   `+planner/*.m`
2. **Never edit `matlab/baseline/`** — that is MathWorks' planner, the competitor we compare
   against. Change it and a judge calls the whole comparison rigged
3. **Never change `AGENTS.md` section 3.** Six people build against it
4. **Never use 0.5 as a fallback probability**
5. **Never clip `h < 0` to make a run look clean.** Report it. A hidden violation is the one
   thing that would genuinely invalidate this project
6. **Never write a number you did not produce by running something**
7. **Never summarise an error.** All of it

---

# 11 · If you remember five things

1. **The trunk is the probe.** The car's movement is the question, not a signal beside it.
2. **`h = lambda - beta`, and it never goes below zero.** Log it every step.
3. **B builds the loop with stubs now.** Do not wait for A.
4. **A tests in seconds, B tests in minutes.** That is the whole reason for the split.
5. **A failing test is information.** Never edit a test to make it pass.
