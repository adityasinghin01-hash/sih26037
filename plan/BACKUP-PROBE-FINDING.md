# The probe never fires, and the demo scenarios do not do what the script says

**Finding, 4 September 2026, ~21:30 IST. Every number below was produced by RUNNING the backup
demo on Aditya's Mac, MATLAB `26.1.0.3346908 (R2026a) Update 5`, `MACA64`.**

**Read this before rehearsing the demo, before the deck, and before anyone repeats the S1 or S2
story from `SPEC.md`.**

---

## First, the good news, because it corrects this repository

**The planner DRIVES.** `INTEGRATION.md` and `plan/CLAIM-LEDGER.md` both say the planner does not
— that `NegotiatingStrategy.m` line 105 is a TODO, so `h` is only observed. That is true **of the
OpenTrafficLab harness** and it is false of the project.

The backup demo at `~/Desktop/SIH26037-Reference/build/backup/matlab/+backup/runScenario.m` calls
the **real, unmodified** planner out of this repository — `+backup/addSihPath.m` adds
`~/dev/sih2026/matlab` to the path and asserts `sih.planner.assignRoles` resolves. Nothing is
forked and nothing is copied, so a fix here is a fix there.

```
[S1] 16 road pieces built (0 rejected), route 610 m over 612 stations
  t= 22.8  COMMIT - offset 0.95 m, clearance 2.20 m
  t= 53.0  ROUTE COMPLETE at 610 m
  distance 611 m in 53.0 s | mean 41.4 km/h | min h -1.571 rad | min clearance 1.02 m
```

`assignRoles` → `velocityObstacle` → `chooseVelocity` → integrate, every step, world frame, real
ego pose. **The loop is closed. It has been closed since 18:32 on 4 September.**

**So "closing line 105 is the one thing that decides whether there is a demo" is wrong**, and this
file supersedes it. Line 105 still matters — it is what puts the planner in the *multi-agent*
OpenTrafficLab harness — but it is not the demo's blocker.

---

## THE FINDING: the probe never fires. In either scenario.

```
S1: any "probe" reason in 1060 samples -> 0
S2: any "probe" reason in  960 samples -> 0
```

**The creep-read-commit mechanism — the entire novelty of this project — does not execute in
either demo scenario.**

### Why

`runScenario.m` line 213, the probe gate:

```matlab
if norm(tracks(j).Velocity(1:2)) < 0.15 && vo.d < 26 && vo.d > 2.5 && v < 1.2
    accel  = 0.45;                       % creep at ~0.5 m/s: read the response
```

It requires the **binding agent to be nearly stationary**. But `arbitrate`-style selection picks
the agent with the smallest `h`, which is the *tightest* constraint — and a tight constraint is
almost always something **moving**. In S1 the binding agent is a moving motorcycle; in S2 it is
moving junction traffic. The cow is the only stationary agent in either scenario, and it is never
the one that binds.

`chooseVelocity` is stateless by design — `runScenario.m:175-179` says so — so it can only ever
**decelerate**. With the probe gate shut, the planner has exactly one behaviour available to it:
brake.

---

## Consequence 1 — S1 contains a COLLISION, not a near miss

Closest centre-to-centre approach, every actor, measured over the whole run:

| Actor | ClassID | min distance |
|---|---|---|
| COW | 10 | 3.656 m |
| AUTO_ONCOMING | 4 | 3.380 m |
| **MC_WRONGSIDE** | **5** | **0.735 m** |
| TRACTOR | 14 | 3.406 m |
| BULLOCKCART | 13 | 6.950 m |
| MC_PARKED | 5 | 4.738 m |

Ego half-width **0.95 m** (1.90 m with mirrors, `runScenario.m:47`) plus motorcycle half-width
**0.35 m** = **1.30 m required**. It reaches **0.735 m**. The bodies overlap by more than half a
metre.

The planner detects it correctly and does the only thing it can:

```
times      : [14.4  14.45  14.5  14.55  14.6]
ego v      : [5.07  4.77   4.47  4.17   3.87] m/s
mode       : [2 2 2 2 2]                        (EMERGENCY, S8 = 2)
reason     : "h < 0: safety barrier violated, maximum braking"
h          : -1.570796 = exactly -pi/2
```

**`h = -pi/2` here is NOT the ego-in-its-own-TrackList defect.** That defect pinned `h` at `-pi/2`
on *every step of every run*; this is 5 samples out of 1060, at one instant, against one named
actor, with `d` genuinely below `dMin`. It is `velocityObstacle`'s correct output for
`d <= dMin` — the same branch Aditya told Person B to add to her chart.

**The planner is not wrong. It brakes maximally and it is still hit**, because
`chooseVelocity` deliberately performs no lateral avoidance and the probe that would have created
a gap never fired. `+backup/lateralPolicy.m` exists and is not on this path.

### And the written S1 result is not what runs

`SPEC.md` says: *"52 km/h → treeline breaks → cow at 42 m → probe → measure → abort for the auto →
retake → through at 8 km/h with 0.95 m clearance."*

Measured: **no probe, no abort, no retake.** The cow is passed at **3.656 m**, not 0.95 m.
`h < 0` on **47 of 1060 samples (4.4%)**, median `-0.0699`.

---

## Consequence 2 — at S2 OUR planner is the frozen robot

```
route length 382.6 m
reached       90.9 m
first v < 0.05 at t = 12.8 s -- and it never moves again
final ego speed 0.000 m/s
h < 0 on 573 of 960 samples (59.7%),  min h -0.062287
reasons: 573x "h < 0: safety barrier violated, maximum braking"
         387x "no constraint - cruise to target speed"
```

It alternates between full braking and cruising — **dithering**, exactly what `plan/ReadThis.md`
§7 warns is the thing that actually causes the accident — and then stops dead at 24% of the route.

**It is a deadlock by construction:**

> it never commits → `ctx.Committed` stays false → the reactive agent never lifts off
> (`actorPoses.m`, `case "reactive"`) → `h` never clears → it never commits.

`min h` is only `-0.062`, i.e. barely negative. The car is not in danger at S2. It is stuck.

---

## Consequence 3 — the frozen-robot contrast is INVERTED

All four combinations, run tonight:

| Scenario | Planner | completed | dist_m | mean km/h | stopped_s | minClearance_m |
|---|---|---|---|---|---|---|
| S1 | **negotiating (ours)** | 1 | 610.6 | 41.4 | 0.0 | 1.022 |
| S1 | defensive (stand-in) | 1 | 610.6 | **43.3** | 0.0 | 0.921 |
| S2 | **negotiating (ours)** | 0 | **90.9** | 6.7 | 35.2 | 2.495 |
| S2 | defensive (stand-in) | 0 | **208.5** | 15.5 | 14.3 | 0.608 |

`BACKUP-PLAN.md` promises the stand-in will show *"the frozen-robot problem — emergency stop, and
it never moves again."*

**It does not.** On S1 the defensive planner finishes the same route **2.4 s faster** than ours.
On S2 it travels **more than twice as far** before stalling. **Today, the naive baseline beats us
on both scenarios.**

Note also that `defensive` returns `h = NaN` on every sample — it never computes a barrier — so
"min h" cannot be compared between the two columns. Only distance, time and clearance can.

---

## What must NOT be said on the 7th, until this is fixed

| ✗ Do not say | Why not |
|---|---|
| *"The car probes, reads the response, and commits"* | The probe fires **zero** times in both scenarios |
| *"We pass the cow with 0.95 m clearance"* | Measured **3.656 m**. The 0.95 m figure describes a manoeuvre that does not happen |
| *"A defensive planner freezes; ours gets through"* | Ours stops at 90.9 m of 382.6 m at S2. The stand-in reaches 208.5 m |
| *"h stays above zero"* | S1: 47/1060 negative, min `-pi/2`. S2: 573/960 negative |
| Anything about S1 being collision-free | `MC_WRONGSIDE` closes to 0.735 m against 1.30 m of body. That is contact |

---

## The fix, in the order that matters

**This is the BACKUP chat's folder. This file records the finding; it does not change the code.**
Per `plan/ReadThis.md` §10.1 and the parallel-chat rule, nothing here edits
`~/Desktop/SIH26037-Reference/build/backup/`.

1. **Open the probe gate.** Trigger on *"the gap is not opening"* — `h < 0` persisting for N steps
   with closing speed not decreasing — instead of *"the binding agent is stationary"*. This is one
   condition and it is the whole mechanism. It fixes S2's deadlock directly.
2. **Resolve the S1 wrong-side motorcycle.** Either put `lateralPolicy.m` on the live path so the
   ego can move over, or reposition `MC_WRONGSIDE` so the encounter is survivable without lateral
   movement. **Do not delete it** — a motorcycle on the wrong side is the most Indian object in
   the scenario and it is exactly the case the project claims to handle.
3. **Re-run all four combinations** and confirm the contrast has inverted back: ours must complete
   S2 where the stand-in does not.
4. **Then, and only then**, put the probe-and-commit sentence back in the deck.

---

## A drift found while writing this, flagged not fixed

At 21:55 tonight `SPEC.md` was corrected to give the zebu as **2.05 x 0.64 x 1.46 m**, noting the
old `0.85 m` width was 140 mm above REF-04's documented 57-71 cm range, and that *"the cow's width
IS the gap arithmetic."*

**The code was not updated with it.** As of 22:0x:

- `+backup/scenarioSpec.m:62` still builds the cow as `[2.20 0.85 1.43]`
- `+backup/runScenario.m:50` still reasons from *"cow half-width 0.43 m"* (= 0.85/2) when sizing
  `DMIN = 2.00`

So the document and the running code now disagree about the number the document itself calls
load-bearing. One sentence, for the BACKUP chat to resolve.

---

## Reproduce every number in this file

```matlab
addpath('/Users/aditya/Desktop/SIH26037-Reference/build/backup/matlab');
o = backup.runScenario('S1');                          % or 'S2'
o = backup.runScenario('S2', 'Planner', 'defensive');  % the stand-in
any(contains(o.Reason, "probe"))                       % -> 0, the finding
```

Code measured at mtime 18:23-18:32, 4 Sep 2026. `matlab/baseline/` untouched and verified clean.
`AGENTS.md` section 3 untouched.
