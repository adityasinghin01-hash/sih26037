# CODEX JOB 08 — Phase 8: make the agents react to the ego

## DO NOT RUN MATLAB. You cannot. Write the code; Claude runs it. No git writes either.

## Why this phase exists
Every actor in every scenario is a **recording**. The cow ignores the car because a cow would,
and that is honest. But the auto, the motorcycle, the pedestrians all follow a fixed script and
do not respond to anything the ego does. So the car does not negotiate with traffic — it
threads a replay. That gap is the single biggest difference between how this demo reads and
how a real road behaves.

## What already exists — build on it, do not reinvent it
- **S2 proves an agent CAN respond to the ego.** `sc.s2drive` reads `ctx.YieldDrop` — the
  circulating auto's measured 1.8 km/h speed lift, read as a yield and committed on. Read that
  file. It is one real reactive mechanism and the pattern to generalise.
- **The ML yield predictor was trained on exactly this decision** — yield vs assert, from
  METEOR. Calibrated, 2.089% dangerous-error. It is gated OFF for driving (correctly), but it
  encodes real Indian yielding behaviour and is a legitimate source for a reaction model.
- `sc.activeDensityActorsAt` turns a spec row into a per-frame pose. Reactions have to live
  somewhere that can see the ego, which that function currently cannot.

## The job
Write `matlab/+sc/reactStep.m`:

```
A = sc.reactStep(A, egoState, dt)
```
Given the current actor array and the ego's state (position, heading, speed, station,
lateral), return the actor array with reactive adjustments applied for this step.

**The rules that make it defensible, not a puppet show:**
1. **Class-dependent.** A cow does not yield. A pedestrian does. A bus asserts. The project's
   own novelty framing is *per-agent negotiability* — encode exactly that, and put the
   reasoning in the header.
2. **Bounded authority.** A reaction may only change **speed along the actor's existing path**,
   within a physically sane accel/decel limit. It may NOT teleport an actor, reverse it, or
   move it laterally off its scripted line. A reaction model that can do anything can hide
   any planner failure.
3. **Reactions must be logged**, per step, per actor: who reacted, to what, by how much. An
   unlogged reaction is indistinguishable from a scripted one, and a judge will ask.
4. **Off by default.** `opts.Reactive = false` must reproduce today's behaviour
   **bit-identical** — that is the acceptance test, not a nicety. Every current number was
   measured against scripted actors and must stay reproducible.
5. **Never make an agent react so as to rescue the ego.** If the planner would have hit
   something, a reactive agent that dodges is an invisible home-field advantage — the exact
   thing `sih26037-end-goal-locked` forbids. Reactions must be derived from the agent's own
   situation, never from whether a collision is imminent.

## Report
- every assumption you could not verify by reading
- which line you expect to break first
- how you would PROVE rule 4 (the bit-identical requirement)

## Hard rules
Never edit `matlab/baseline/`, `AGENTS.md` §3, `demo_play.m`, `matlab/+sih/+planner/`, or
anything S2 — S2 is the reference mechanism, read it, do not modify it.
Never invent a number. No commits.
