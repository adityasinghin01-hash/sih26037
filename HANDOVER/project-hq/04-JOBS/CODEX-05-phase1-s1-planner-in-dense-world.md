# CODEX JOB 05 — Phase 1: put the REAL planner into S1's dense world

## Context
Branch `integration/dense-planner` in `<repo-root>`, at `205595e`.
It now contains BOTH halves for the first time:
- the real planner (`sc.planSeat`, `matlab/+sih/+planner/`) — drives, but only ever saw
  three scripted actors
- the dense world (`sc.s1world`, `sc.s1density`, 14 buildings + 51 background actors) —
  fully built, but driven by a **fake constant-speed ego** that does no planning at all

**Your job is to make them meet.** Nothing else.

## DO NOT RUN MATLAB. You cannot.
Confirmed twice today: MATLAB dies instantly inside your sandbox with
`Incompatible processor. This Qt build requires the following features: neon`, exit 137.
This is a property of the sandbox, not of the project. **Your job is to WRITE the file.
Claude runs it and reports the result back to you if a fix is needed.**

Do not run any git command that WRITES either — the sandbox blocks `.git`. Read-only git,
reading files, and grep all work fine.

## What already exists — read these first, do not re-derive them
| File | What it gives you |
|---|---|
| `matlab/densityDemo.m` | the scripted version. **It already builds a correct TrackList** in the frozen contract shape (TrackID/ClassID/Position/Velocity/Extent/Yaw/Existence/Age/SensorMask) from `sc.activeDensityActorsAt`. Reuse that loop verbatim |
| `matlab/s1_planner_run.m` | **the pattern to copy.** The full runner: referencePathFrenet, the per-step context, the integration loop with accel limits and `sc.lateralStep`, the measurement pass |
| `matlab/+sc/planSeat.m` | the seat. Read its header. `ctx` must carry `.s .e .v .t .W .Path .RefPath .Tracks .EgoXY .EgoYaw .Kappa .CruiseV` |
| `matlab/+sc/s1drivePlanner.m` | proof the wrapper is thin — it is one line |

## Build exactly one new file
`matlab/densityPlannerRun.m`

```
densityPlannerRun("s1")      % later: "s3", "s4", "s5" — but ONLY do s1 in this job
```

It must:
1. Build the world and the density spec: `sc.s1world()`, `sc.s1density()`.
2. Build `RefPath` from `W.Path` exactly the way `s1_planner_run.m` does.
3. Step at the same DT `s1_planner_run.m` uses. Each step:
   - build `Tracks` from `sc.activeDensityActorsAt(spec, W.Path, t)` — the same conversion
     `densityDemo.m` already does
   - call `sc.planSeat(st, ctx)`
   - integrate `cmd.v` and `cmd.e` through the SAME accel limits and `sc.lateralStep` call
     `s1_planner_run.m` uses. Do not invent a different integrator
4. Log per step: t, s, e, v, x, y, yaw, state, and the barrier values planSeat returns.
5. At the end, write evidence via `sih.metrics.writeDemoResults` — the same
   `results/<run>/{trajectories.csv,metrics.json,config.json}` every other run produces.
6. Print, at the end: total steps, whether it reached the end of the route, plan-failure
   count, any NaN/Inf, and M1–M10.

## Write the file. Do not execute it.
Read the three reference files closely enough that the code is right the first time, because
you will not get to test it yourself. State plainly at the end of your report which parts you
are confident in and which parts you are guessing at — that is what Claude will check first
when the run fails.

## The point of the job — this is what is actually being tested
The planner has **never** seen this many objects. S1's density layer is 51 actors plus 14
buildings, against the 3 actors it was built and tuned on. **Expect it to fail.** That is
the finding, not a problem to hide.

In your report, state:
- every assumption you made about a function's behaviour that you could not verify by reading
- which line you expect to break first, and why
- what you copied verbatim from `s1_planner_run.m` versus what you had to write fresh

## Hard rules
- Never edit `matlab/baseline/`, `AGENTS.md`, `demo_play.m`, `matlab/+sih/+planner/`, or
  anything S2.
- **One new file.** Do not refactor, rename, or "improve" anything you find.
- **Never invent a number.** `TODO(unverified)` is a complete answer.
- No commits, no pushes.
- If a number comes out different from what this brief implies, report the number you got.
