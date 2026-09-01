---
description: Stream D Person B - build the Simulink model and Stateflow chart that close the loop and call Person A's planner functions.
---


# /plan-harness — the closed loop, and the chart that drives it

**You are Person B.** You own **the Simulink model and the Stateflow chart**. Person A owns
`matlab/+sih/+planner/*.m` — the pure functions. Read `plan/CONTRACT-AB.md` before you start.

**You are the only person who opens the `.slx`.** It is a binary file; git cannot merge two
people's edits to it, so if A opens it too, one of you loses a day's work with no warning and no
conflict marker. That is why the split exists.

**Your branch is `stream-d-b`.**

---

## Step 0 — setup, and the one dependency that is not in the repo

**`NegotiatingStrategy.m` is `classdef NegotiatingStrategy < DrivingStrategy`, and
`DrivingStrategy` lives in OpenTrafficLab, which is NOT in this repository.** It is third-party
code, so it is gitignored deliberately. Clone it or nothing in `+planner` will even load - you
get `Undefined base class 'DrivingStrategy'` and it looks like our code is broken when it is not.

```bash
cd <repo root>
git clone https://github.com/mathworks/OpenTrafficLab.git
```
```matlab
addpath(genpath('OpenTrafficLab'))
addpath('matlab')
runtests('matlab/tests')
```

**Do this before anything else.** It needs only MATLAB and Automated Driving Toolbox.

---

## The thing that decides whether this works: build the loop with stubs, now

**Do not wait for Person A.** Every struct is already defined in `AGENTS.md` section 3, so you
can build the entire loop this week against fakes:

- a stub that emits a hand-written `S1 TrackList` — two agents, one crossing, one head-on
- a stub `PYield` that always returns 0.8, with `Valid = true`
- a stub planner that drives straight at constant speed

Then each real piece **drops into a slot that already works.**

The alternative is what kills small teams: everyone builds alone for three weeks, integration
starts in week four, nothing fits. **Integration is not a phase at the end.**

---

## Step 1 — the closed loop itself

This is the single most valuable finding in the project's research, so use it rather than
inventing something:

```
Scenario Reader -> Bus Selector -> Stateflow -> bicycle model
       ^                                            |
       +------ Non-ego Actor Poses INPUT PORT ------+
```

**Feeding poses back into that input port overwrites the programmed waypoints.** That is the
documented way to make the other vehicles react instead of following a fixed script. Without it
they drive their recorded path through your car and the demo is worthless.

Configure the Scenario Reader to **ignore the ego vehicle definition** — the ego comes from your
model, not from the scenario file.

**Validation:** run it and watch one non-ego actor change what it does because of where the ego
is. If nothing changes, the feedback port is not connected.

## Step 2 — the Stateflow chart

Modes are **S8**: `0 STRUCTURED` · `1 UNSTRUCTURED` · `2 EMERGENCY`.

| Transition | When |
|---|---|
| STRUCTURED → UNSTRUCTURED | the road has no usable lane structure |
| any → **EMERGENCY** | **`h < 0`.** This one overrides everything |
| EMERGENCY → UNSTRUCTURED | `h` recovers above a margin, not just above zero |

**Use a margin coming out of EMERGENCY, not the same threshold going in.** Equal thresholds make
the chart flip between states every step at the boundary, which looks like a bug in the planner
and is not.

**The chart decides WHEN. Person A's functions decide WHAT.** If you find yourself writing
geometry inside the chart, it belongs in `+planner/` and it is A's.

## Step 3 — call A's functions

```matlab
cmd = sih.planner.chooseVelocity(role, vo, egoState);
```

Until that exists, call a stub with the same signature. **The signature is agreed in
`plan/CONTRACT-AB.md` before A writes the body** — check there, do not guess.

## Step 4 — log the safety number, every step

```
h = lambda - beta
```

**This is our safety evidence and the whole proof rests on it.** Log it every step to
`results/<run>/`, never only when it looks interesting.

- `h < 0` is a violation. It must be **counted and reported**, never quietly clipped
- log the **minimum across all agents** each step, plus which `TrackID` produced it
- a run with no `h` log is not a result

## Step 5 — the signals, because legibility is the whole point

S4 `.Signal`: `0` none · `1` horn · `2` headlight flash · `3` declare blocked · `4` indicate left
· `5` indicate right · **`6` REQUEST DRIVER HANDOVER**.

**`Signal = 6` must be raised BEFORE `.Committed` goes true.** India requires a driver in the
seat, so handing back is our terminal state — but handing back *after* the point of no return is
abdication, not safety, and **M11 logs it as a failure.** Wire that check into the chart, not
into a comment.

---

## What to run before every push

```matlab
runtests('matlab/tests')
```

All of them, not just yours. **A's 12 geometry tests are your early warning** — if they break
after you change something, you changed something you do not own.

## Never

- **Never edit `matlab/+sih/+planner/*.m`.** Those are A's. Ask for a signature change instead
- **Never edit `matlab/baseline/`** — the competitor. Editing it makes every result worthless
- **Never change `AGENTS.md` section 3.** Six people build against it
- **Never clip `h < 0` to make a run look clean.** Report it. A hidden violation is the one
  thing that would actually invalidate the project
- **Never commit the `.slx` with unsaved library links or absolute paths**

## Report like this
```
BUILT      : <what part of the loop>
LOOP CLOSES: yes | no  <does a non-ego actor react to the ego?>
h LOGGED   : yes | no  <min per step, with TrackID>
STUBS      : <which pieces are still fake>
FOR A      : <signatures you need, and by when>
```
