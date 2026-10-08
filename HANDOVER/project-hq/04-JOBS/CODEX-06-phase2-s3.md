# CODEX JOB 06 — Phase 2: the same treatment for S3 (the galli)

## DO NOT RUN MATLAB. You cannot.
Confirmed twice: MATLAB dies in your sandbox with `Incompatible processor. This Qt build
requires the following features: neon`, exit 137. **Write the file. Claude runs it.**
Do not run any git command that writes either. Reading and grep work fine.

## Context
Branch `integration/dense-planner` in `<repo-root>`.

`matlab/densityPlannerRun.m` now drives the real planner through S1's full world. Getting
there took five runs and found four real defects. **Read that file first — it is the
template, and its comments record every trap.** The four, so you do not repeat them:

1. **The density layer is scenery.** 50 of S1's 51 density actors sit off the carriageway.
   Alone they change nothing — the planner cruised past at 51.6 km/h with `h`=NaN on every
   step. The negotiation actors must be loaded too, and **added to**, never instead of.
2. **The evidence metric measured the wrong actors.** `D.Poses` carried only the density set,
   so M6 reported clearance to scenery while the ego overlapped a vehicle by 0.80 m. Both
   sets must go in, density IDs offset by 1000.
3. **A constant was copied where a mechanism was needed.** `T_END` was hardcoded from the
   sparse config; once speed caps were applied the route no longer fit and the run silently
   stopped at 403 m of 610. Use `sc.estimateDuration`.
4. **Ghost tracks.** 3,805 actor samples reported a velocity while their position had not
   moved — `moto_over` sat at the route end claiming 62 km/h. The planner drove through it.
   Zeroing velocity for non-moving actors turned a −0.80 m overlap into +0.30 m.

## The job
Write `matlab/densityPlannerRunS3.m` — or, better, **generalise `densityPlannerRun.m` to take
`"s3"`** if the differences are small enough. Read both and decide; say which you chose and why.

S3's equivalents of S1's three layers:
- world: `sc.s3world`, geometry in `sc.s3geom`
- density: `sc.s3density` (54 buildings, 39 actors)
- negotiation actors + hazards: **S3 does not use `s1_action_run.m`.** Its actors are defined
  in `demo_play.m` as `actorSpecS3`, and its route/hazards in `sc.demo3Route`. Read
  `demo_play.m`'s `actorSpecS3` header and `+sc/demo3Route.m`'s header in full — the S3 build
  found four real planner-interaction bugs and both headers document the exact arithmetic.

## Things that are genuinely different about S3, do not assume S1's values
- **Ego width is 1.90 m, not 1.80** (`sc.s3geom`). `writeDemoResults` had a real bug here once
  — a hardcoded width understated S3's clearances in the unsafe direction. Check it.
- The squeeze is a measured **1.95 m** free width. `corridorFrom`'s 2.2 m sanity floor is wrong
  for S3 and it takes a `minCorridor` argument for exactly this reason.
- `MirrorsFolded` exists in S3 and changes the effective ego width through the squeeze.

## Report
- which approach you took and why
- every assumption you could not verify by reading
- which line you expect to break first
- what you copied verbatim from `densityPlannerRun.m` versus wrote fresh

## Hard rules
Never edit `matlab/baseline/`, `AGENTS.md`, `demo_play.m`, `matlab/+sih/+planner/`, or
anything S2. Never invent a number — `TODO(unverified)` is a complete answer. No commits.
