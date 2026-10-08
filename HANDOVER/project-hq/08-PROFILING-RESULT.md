# Where the planner's time actually goes — measured 16 Sep 2026

`profilePlanSeat(200)` on S1's dense world. **`sc.planSeat` had never been timed before
today** — its own source comments said so.

## The headline

| | |
|---|---|
| mean per step | **735.8 ms** |
| median per step | 660.1 ms |
| p95 | 1483.4 ms |
| max | 2027.1 ms |
| **budget for 10 Hz live** | **100 ms — we are 7.4× over** |
| projected full 1240-step run | 15.2 min |

## MY HYPOTHESIS WAS WRONG, and this is the useful part

I predicted — twice, in writing — that `sc.adapterS9Real`'s sight term, ray-marching against
this world's ~2200 occluders every step, would dominate, and that a spatial index over the
occluders was "the single highest-value change available."

**`adapterS9Real` is 12.95 s of 149 s. 8.7%. It is not the bottleneck.**

Had I "optimised" on that reasoning I would have spent a day rewriting the fastest part of
the system.

## What actually costs the time

| function | total s | calls | calls/step |
|---|---|---|---|
| `planContingency` | 131.46 | 200 | — |
| → `checkTrajectorySafety` | 123.48 | **204,587** | **1,023** |
| → `checkTerminalStop` | 80.66 | 125,977 | 630 |
| → `DynamicCapsuleList.updateList` | 23.65 | **818,348** | 4,092 |
| → `unique` | 22.75 | **1,227,522** | 6,138 |

**88% of the time is inside `planContingency`, and nearly all of that is MathWorks'
`dynamicCapsuleList` collision machinery being called about a million times per 200 steps.**

`unique` alone burns **20.71 s of SELF time** — 14% of the entire runtime — across 1.23
million calls, inside MathWorks' own `DynamicObstacleList`. We cannot fix that code. We can
only call it less.

## The real lever: stop checking obstacles that cannot possibly matter

1,023 trajectory-safety checks per step, against 60 tracks, of which **50 are background
scenery sitting 5–8 m off a 3.5 m half-carriageway** — shopkeepers, parked carts, tethered
animals. Every one is capsule-checked against all 35 candidate trajectories, every step.

A planner does not need to run swept-volume collision detection against a man standing eight
metres off the road. Pruning tracks that cannot interact — far in lateral AND longitudinal
terms — should cut the work close to proportionally.

**This is not a cheat and it must be proved, not assumed.** The test: prune, re-run, and
require the trajectory and M6 to come back **bit-identical**. If they move at all, the prune
is too aggressive and the threshold is wrong. A faster planner that drives differently is not
the same planner.

## What this means for the plan
- **Phase 9 (live at 10 Hz) is 7.4× away**, not the 10× I guessed, and the path to it runs
  through obstacle pruning rather than the occluder index.
- **Phase 6 (repeated runs for CIs)** is gated on the same change.
- The occluder spatial index I had queued as a prerequisite is **cancelled**. It would have
  bought 8.7% at best.

---

# THE PRUNING EXPERIMENT — measured, and it FAILED. 17 Sep, 04:05.

I proposed track pruning as "the highest-value change available" and "the only credible route
to Phase 9." **It is worth nothing.** Recorded in full so nobody spends a day repeating it.

## The A/B, on an idle machine

| | runtime | M6 |
|---|---|---|
| unpruned baseline | **13m 12s** | 0.1347406069392747 |
| pruned, 27.4 tracks/step removed | **13m 07s** | 0.1347406069392747 |

**0.6%. Noise.** Removing 27 of ~60 tracks every step changed nothing.

## Why — the answer was already in the profile

`checkTrajectorySafety` runs **204,587 times = 1,023 per step**. That is
**35 candidate trajectories × ~29 horizon samples**. The call count is set by the CANDIDATE
GRID, not by the obstacle count. `DynamicCapsuleList.updateList` runs **4× per safety check**,
not 60× — obstacles were never the multiplier.

I had this profile in hand before writing the prune and did not do the arithmetic.

## Three wrong hypotheses in a row about this planner's cost
1. **the occluder ray-march** — predicted to dominate, measured at **8.7%**
2. **the first prune** — a "speedup" that was 25% SLOWER, because it called `P.inverse()`
   per track per step to decide what to skip
3. **pruning at all** — provably safe, measurably pointless

Every one was killed by measurement. That is the system working, but the hit rate is bad and
the lesson is specific: **derive the cost model from the profile arithmetic before writing
optimisation code.**

## The REAL lever for Phase 9
The candidate grid: `TermSpeeds` (5) × `LatOffsets` (7) = **35 candidates**, each sampled at
`TimeRes` 0.1 s across a 4.0 s horizon. Cutting the grid cuts cost close to proportionally.

**But unlike pruning this is NOT free.** Fewer candidates is a coarser search and may produce
worse plans. It changes behaviour, so it needs the bit-identical discipline AND a quality
comparison — M6, completion and plan-failure count across the bench, not one run.

Phase 9's honest position: 7.4× from 10 Hz, and the only lever left has a behavioural cost.

## The pruning code is KEPT, and demoted
It is correct by construction (static actors only — their station and lateral are exact for
all time) and proven neutral across three runs. It will matter more on S4's denser highway.
**It is not an accelerator and must not be described as one.**
