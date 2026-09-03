---
description: Run the planner tests and explain what a failure actually means.
---

# /plan-test — the planner's tests

```matlab
runtests('matlab/tests/testPlannerGeometry.m')
```

**The `.m` is required.** Without it MATLAB reads the argument as a folder name and refuses to
build a suite at all:
```
MATLAB:unittest:TestSuite:UnrecognizedSuite
Unable to create a test suite from matlab/tests/testPlannerGeometry.
```

**14 tests. All passed on R2026a, 4 September 2026** — they are the oldest and best-verified
code in the repository, so a failure means something you just changed, not something that was
already broken. (Re-run before you quote that number: it said 12 for a week after two frame
tests were added, and 13 in `D-planner.md` when it was never 13.)

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
| `testWorldFrameAndEgoFrameGiveTheSameRole`, `testEgoFrameTracksWithAWorldEgoPoseAreWrong` | **the frame contract.** S1 is ego-frame; `assignRoles` needs tracks and ego pose in the SAME frame. Mixing them never errors, it just returns the wrong role |
| `testRoleCountMatchesTrackCount` | one role out per track in, same order |

## If one fails

**Report it in full and stop.** Do not adjust the test to match the code — these encode the
contract in `AGENTS.md` sections S4 and S7, and a test edited to go green hides a planner that
will drive into something.

The usual causes, in order of likelihood:
1. an angle in degrees where radians were expected, or the reverse
2. the sign of `tCPA` flipped — that is what separates closing from opening
3. `dMin` changed, which moves every cone at once

## The other planner suites

```matlab
runtests('matlab/tests/testChooseVelocity.m')       % 19 tests, D2
runtests('matlab/tests/testNegotiatingStrategy.m')  % 9 tests, the OpenTrafficLab subclass
```

`testNegotiatingStrategy` needs OpenTrafficLab, which is not in this repository. Without it the
tests report **Incomplete (skipped), never Failed** — a missing third-party dependency is not a
broken repo. Clone it and they run:
```bash
git clone https://github.com/mathworks/OpenTrafficLab.git
```

## Before you push
```matlab
runtests('matlab/tests')
```
Everything, not just yours. And say so in the commit if something fails.
