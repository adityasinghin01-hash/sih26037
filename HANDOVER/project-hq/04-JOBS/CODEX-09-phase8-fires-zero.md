# CODEX JOB 09 — Phase 8 fires ZERO times. Find out why and fix it.

## DO NOT RUN MATLAB. You cannot (`requires neon`, exit 137). Write the fix; Claude runs it.
No git writes either. Reading, grep, and reasoning all work.

## The symptom, measured twice
`sc.reactStep` is wired into two places and has **never produced a single reaction**:

1. **`densityPlannerRun('s1','Reactive',true)`** -> `0 agent reactions`, M6 bit-identical to
   the non-reactive run (0.16142231374573646).
2. **`demo_play('demo1','Recompute',true,'Reactive',true)`** -> output byte-identical to
   baseline: same 1108 gate decisions, same 0 plan failures, same ~41 s runtime.

Its 10 unit tests all pass, including ones that assert a pedestrian DOES slow down. So the
function works in isolation and does nothing in the real scenarios. **That gap is the job.**

## What is already known - do not re-derive it
- In `densityPlannerRun` the explanation is understood: `reactStep` was applied only to the
  DENSITY actors, and **50 of those 51 sit off the 3.5 m half-carriageway**, parked/tethered/
  asleep. Nothing is ever in the ego's lane. That wiring is a dead end by construction.
- In `demo_play` it SHOULD work, and that is the interesting case: `builtinTracks` regenerates
  actors every step from `actorSpec` via `activeActorsAt`, and those actors - cow, herd, auto,
  wrong-way motorcycle, overtaker, tractor, trolley - are genuinely ON the road. An oncoming
  wrong-way motorcycle in particular ought to trigger any sane "something is in my lane" test.

## Read these, in this order
1. `matlab/+sc/reactStep.m` - especially the trigger block: `ahead`, `lateral`, `reach`, and
   the three `continue` guards. **One of those guards is almost certainly rejecting everything.**
2. `matlab/demo_play.m` -> `builtinTracks` and the local `egoNominalXY`. **Suspect #1:**
   `egoNominalXY` fakes the ego position as `25 + 12*(i-1)*DT` along the route because the
   track list is built BEFORE the planner runs. If that estimate is far from where the ego
   really is, the geometry never lines up and no reaction can ever fire.
3. `matlab/demo_play.m` -> `actorSpec` - what the S1 actors actually do, and when.

## What to produce
`~/dev/sih2026-hq/REPORTS/CODEX-09-phase8-report.md` containing:
1. **Which specific guard rejects the actors**, quoted with its line, and the arithmetic that
   proves it - e.g. "for the wrong-way motorcycle at t=20 s, `ahead` = X, `reach` = Y, so
   `ahead > reach` and it is skipped."
2. The minimal fix. **Minimal.** Do not redesign the reaction model.
3. Whether the fix is in `reactStep`, in `egoNominalXY`, or in how demo_play calls it.

Then apply the fix to the MATLAB files.

## Hard rules - these are what make the phase worth having
- **The reaction must NEVER be derived from the planner's state, its candidates, or whether a
  collision is imminent.** An agent that dodges exactly when our planner would have hit it is a
  home-field advantage and `sih26037-end-goal-locked` forbids it. If your fix needs the ego's
  real pose, say so and explain why it is still not planner-state.
- `Reactive=false` must remain **byte-identical**. `testReactStep`'s first test asserts this.
- Never edit `matlab/baseline/`, `AGENTS.md` §3, `matlab/+sih/+planner/`, or anything S2.
- Never invent a number. `TODO(unverified)` is a complete answer.
- No commits.
