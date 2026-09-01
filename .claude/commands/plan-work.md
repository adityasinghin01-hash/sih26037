---
description: Stream D - what to build next in the planner, in order, with the maths already specified and the traps named.
---

# /plan-work — build the planner, in order

**Read `AGENTS.md` section 3 first.** S4 is what you produce, S1/S3/S9/S10 are what you consume.
Then check `plan/CONTRACT-AB.md` — Stream D is two people and they do not share files.

**You are Person A.** You write **pure MATLAB functions** in `matlab/+sih/+planner/`. They take
a state and return a command. **You never open the Simulink model** — that is Person B's, it is
a binary file, and two people editing it cannot merge. One of you simply loses their work.

## What already works — build on it, do not rewrite it

| File | What it gives you |
|---|---|
| `velocityObstacle.m` | `beta`, `lambda`, `tcpa`, `d`. **Collision iff `lambda < beta`** |
| `assignRoles.m` | the COLREGs role per track (S7) |
| `NegotiatingStrategy.m` | the OpenTrafficLab subclass that will call your work |
| `testPlannerGeometry.m` | **12 passing tests.** Run them before and after every change |

**`h = lambda - beta` is the safety number.** It must never go below zero, and it is logged every
step as our evidence. Everything below protects it.

---

## Build in this order. Each one is useful on its own.

### 1 · D2 · `chooseVelocity.m` — turn a role into a command
Small, and it gets you oriented. Input: a role (S7) plus the velocity-obstacle output.
Output: an `EgoCommand` (S4).

```
GIVE_WAY   -> ONE early, substantial move. Not creeping inch by inch - the whole point is that
              the other driver can SEE the decision
STAND_ON   -> hold course AND speed. Doing nothing is the action
HEAD_ON    -> both give way, to the same side, so the choice is predictable
OVERTAKING -> keep clear until past and clear
SAFE       -> no constraint from this agent
```
`Accel` is clamped to `[-6, +3]` m/s², `SteerAngle` to `[-0.6, +0.6]` rad. **S4 fixes those and
the planner must never emit outside them.**

### 2 · D6 · the contingency planner — the biggest job on the project
This is the mechanism the whole pitch rests on. Every cycle:

1. Generate **several candidate paths** a few seconds ahead (`trajectoryGeneratorFrenet`)
2. Roll each forward under **two futures for every agent — they yield, they assert** — weighted
   by `PYield` from S3
3. Collision-check with `dynamicCapsuleList`
4. **Commit only the shared trunk that is safe under BOTH futures**
5. Throw the rest away and redo it next cycle

**The trunk IS the probe.** That is the sentence the project is built on: the car edges forward
along the part of the plan that is safe whatever the other driver does, and that motion is
itself the question being asked.

**When `Valid` is false in S3, use the geometric role alone. Never 0.5** — S3 says so explicitly.
A made-up probability is worse than no probability, because the planner trusts it.

### 3 · D8 · the second barrier — the ground itself
```
h_agent = lambda - beta            >= 0    moving things
h_road  = EdgeDistance - dMin      >= 0    the ground
```
Both must hold. **No mode switch — the geometry decides which one binds.** On a 3 m ghat road
`h_road` binds; at an open junction `h_agent` does.

**`dMin` is asymmetric AND speed-dependent:**
- larger on a **drop** than on a **wall** — a wall dents a panel, a drop is fatal. Weighted by
  **consequence, not probability**
- larger with speed — centimetres at 2 km/h, ~1.5 m at 40 km/h
- the footprint is the **real body including mirrors**, and shrinks when `MirrorsFolded` is true
- check the **swept path of the whole body**, not the centreline. Corners sweep wider in a turn

**A khai returns no lidar points at all**, so it can never appear in S1. It arrives through S9 as
ground geometry. That is why this barrier exists separately.

### 4 · D7 · speed, which is one number for three reasons
```
v_max = min( sqrt(aLat * R),                              hold the road
             sqrt(2*aBrake*(VisibleRange - v*tReact)),    stop inside what you can see
             vRoute )
```
**There is no weather mode and there must not be one.** Fog shrinks `VisibleRange`, so the second
term shrinks, so the car slows down. That is exactly why a human slows in fog. Adding a weather
branch would be inventing a second mechanism for something that already falls out.

### 5 · D9 · reversibility — do not drive somewhere you cannot leave
Everything above asks *is this safe*. Nothing asks *if this goes wrong, can I get out*.

- **Escape breadcrumbs** — S10 `EscapePoints` is `[x y width]` of places wide enough to turn
  around in. When blocked we do not ask "can I turn here", we already know where the last place
  was
- **Point of no return** — the moment after which aborting is worse than continuing. Before it,
  abort freely. After it, set `Committed` and **stop re-deciding**
- **A planner at 10 Hz will dither in the middle of a crossing unless you forbid it, and
  dithering in the middle is what actually causes the accident**
- **Handover must be raised BEFORE `Committed` goes true.** Asking a human after the point of no
  return is not safety, it is abdication, and M11 logs it as a failure

### 6 · D10 · turns are derived, never classified
One planner. Only which constraint binds changes.

| turn | what binds |
|---|---|
| roundabout | it is a merge — the existing probe-and-commit handles it |
| **U-turn** | minimum turning radius → multi-point turn → **needs `Gear = -1`** |
| **side cut** | crossing two streams → **refuge points**, stop in the gap between them |
| sharp at speed | lateral grip → the first term of `v_max` |

**Derived from `S10.GoalHeading`:** ~180° plus a tight radius is a U-turn, ~90° across a stream is
a cut. **No sign detection, no classifier.** And a refuge point must not block the stream you
already crossed — while you wait there, you are an obstacle.

---

## How to work

**Write the function, then write its test, then run all 12 existing tests.** Your work must be
testable **without Simulink** — that is the whole reason the A/B split exists. Simulink iteration
is minutes; a MATLAB function is seconds.

```matlab
runtests('matlab/tests')
```

**Every function's header comment names the contract struct it produces or consumes.** A function
that invents its own struct shape is wrong, however well it works.

## Never

- **Never open the `.slx`.** Person B owns it. It cannot be merged
- **Never edit `matlab/baseline/`** — the control arm. Editing it makes every result worthless
- **Never change `AGENTS.md` section 3.** Stop and ask Aditya
- **Never use 0.5 as a fallback probability.** S3 says use the geometric role alone
- **Never write a number you did not produce by running something**

## Report like this
```
BUILT      : <function, and what it consumes and produces>
TESTS      : <n> passing, <n> new
VERIFIED   : <what you actually ran>
NOT DONE   : <what you noticed and left alone>
FOR B      : <the signature they should call>
```
