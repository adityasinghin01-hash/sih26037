---
description: Run the planner tests and explain what a failure actually means.
---

# /plan-test — the planner's tests

```matlab
runtests('matlab/tests/testPlannerGeometry')
```

**12 tests. They all pass today** — they are the oldest and best-verified code in the repository,
so a failure means something you just changed, not something that was already broken.

**Stay inside the planner.** These tests are Stream D's. `ml/`, `matlab/+sih/+prediction/` and
`+models/` belong to Stream C — if a test failure looks like it comes from the predictor, say so
in one sentence and stop. Do not open their files to investigate.

## What each group is checking

| Tests | What breaks if they fail |
|---|---|
| `testConeHalfAngleFormula`, `testInsideSafetyDiscIsCollision` | `beta = asin(dMin/d)`. The collision cone itself |
| `testHeadOnCollisionDetected`, `testOpeningIsSafe` | `lambda < beta` means collision. **Getting this backwards makes the car drive INTO things** |
| `testZeroRelativeVelocityStaysDefined` | two agents moving identically must not divide by zero |
| `testStarboardCrossingGivesWay`, `testPortCrossingStandsOn` | the COLREGs sectors: 22.5, 90, 112.5 degrees |
| `testEmptyTrackListReturnsEmpty` | **S1 guarantee 3** — an empty track list must never error |
| `testRoleCountMatchesTrackCount` | one role out per track in, same order |

## If one fails

**Report it in full and stop.** Do not adjust the test to match the code — these encode the
contract in `AGENTS.md` sections S4 and S7, and a test edited to go green hides a planner that
will drive into something.

The usual causes, in order of likelihood:
1. an angle in degrees where radians were expected, or the reverse
2. the sign of `tCPA` flipped — that is what separates closing from opening
3. `dMin` changed, which moves every cone at once

## Before you push
```matlab
runtests('matlab/tests')
```
Everything, not just yours. And say so in the commit if something fails.
