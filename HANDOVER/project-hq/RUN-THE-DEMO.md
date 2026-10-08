# HOW TO RUN THE DEMO

## Open MATLAB with a window (NOT -batch — batch has no display and skips playback)

```matlab
cd ~/dev/sih2026
addpath(genpath('matlab'))
```

## THE COMMAND

```matlab
sihDemo                 % S1 — the cattle crossing, 610 m of real Najibabad road
sihDemo("galli")        % S3 — the 1.95 m squeeze
sihDemo("all")          % both, in order
```

**Keys while it plays:** `SPACE` pause · `→` or `N` step one frame · `Q` quit
**Click on the road** to drop an obstacle live — the car re-plans around it.

## OPTIONAL SWITCHES

```matlab
sihDemo("s1", Dense=true)      % + 51 background actors, buildings, poles
sihDemo("s1", Reactive=true)   % + agents that respond to the car (35 reactions)
```

**Leave both OFF for the main run.** Every verified number was measured without
them, and `Dense=true` makes the run take ~4x longer.

## WHAT IS ON SCREEN

- the road, the car, its planned path in green, hazards labelled with their speed caps
- **WHERE / STATE / HAZARD / WHY** — what the car is doing and why, live
- **MODEL STATUS** — the four models, and the **ML GATE** row showing
  `OFF for all 1108 / no validated band: 2.089% vs <=1% — geometry drives`
  That count is live, not a caption.

## IF SOMETHING BREAKS ON THE DAY

```matlab
demo_play('demo1')      % the demo directly, bypassing sihDemo
```
Pre-recorded fallback films, already rendered:
`matlab/renders/S1_cattle_crossing.mp4` (62 s) · `S2_the_chowk.mp4` (34 s)
Have them open and paused before you start.

## DO NOT

- **Do not run `sihDemo("s2")`** — it refuses on purpose. S2 collides and then
  stalls permanently. The refusal prints the real numbers; that is the disclosure.
- **Do not run a dense S3** — it collides at −0.093 m then stalls at 81.4 m of 382.
- **Do not open Blender or anything heavy** while demoing. Measured: background
  load moves frame time from 10 ms to 241 ms and makes a working demo look broken.

## THE NUMBERS YOU MAY QUOTE

| | |
|---|---|
| tests | **348 / 348 pass** |
| S1 sparse, tightest approach | **0.618 m** |
| S1 dense, tightest approach | **0.135 m** — a realistic world costs ~80% of the margin |
| what actually binds | the tractor's **trolley at 0.119 m**, NOT the cow at 1.015 m |
| 8 randomised runs | mean **0.1427 m**, 95% CI **[0.093, 0.193]**, **worst run −0.001 m (contact)** |
| ML dangerous-error | **2.089%**, CI [1.315, 2.854] — fails its own ≤1% bar, so it drives nothing |
| MathWorks' own planner | run unmodified, **does not complete** — dies at t=19.7 s, 0/120 candidates |

**Never quote 0.965 m.** That is geometry — half the gap's spare width — not a
result. The claim ledger's own scope note calls using it as a planner claim
"forbidden".

**Never quote one run's clearance.** Quote the interval and the worst case.

## THE THREE SENTENCES TO SAY BEFORE A JUDGE ASKS

> S2, the chowk, does not finish the route. It collides with the wrong-way rider
> and then stalls. That is the open item, not a hidden gap.

> Our ML predictor has not cleared its own safety bar, so the planner does not let
> it drive anything. That fallback is designed behaviour, not a missing feature.

> We put the planner in a realistic version of a road it had already solved — and
> its safety margin dropped by 80%. We found that by testing ourselves.
