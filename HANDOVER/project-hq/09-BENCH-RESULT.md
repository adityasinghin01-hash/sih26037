# PHASE 6 RESULT — the deterministic run was hiding a collision. 17 Sep 2026.

`benchRuns('s1', 8)` — eight runs of dense S1, entry conditions perturbed by
±2.0 m station, ±0.25 m lateral, ±1.0 m/s speed. Nothing about the world, the traffic
script or the hazards changes. 36.5 minutes total.

## The table

```
metric                    mean        sd       min            95% CI
M1_distance_m         585.3777    1.3620  583.5974  [584.2388, 586.5165]
M2_duration_s          91.6188    1.0800   90.5500  [ 90.7157,  92.5218]
M3_meanSpeed_kmh       22.9958    0.2711   22.4827  [ 22.7690,  23.2225]
M6_minClearance_m       0.1427    0.0600  -0.0010  [  0.0926,   0.1928]
M7_stoppedTime_s        3.2875    1.0074    2.1500  [  2.4452,   4.1298]
M9_completed            1.0000    0.0000    1.0000  [  1.0000,   1.0000]
M10_latWobble_m         6.8318    0.1402    6.6569  [  6.7145,   6.9490]
```

**8 of 8 completed the route with 0 plan failures.**

## THE FINDING: `M6` minimum is −0.0010 m

**One of the eight runs made contact.** Negative separation means overlap.

Every run before today reported a single deterministic number — 0.1614 m, comfortably
positive — and it was true. It was also not the whole truth. **Moving the car's entry
point by less than two metres is enough to turn a 16-centimetre clearance into a touch.**

That run still reported `M9_completed = 1` and **0 plan failures**. The planner did not
know it had hit anything. Nothing in a single run's output would have revealed this.

## What may and may not be said

**May:** *"Across eight randomised runs the mean minimum clearance is 0.143 m, 95% CI
[0.093, 0.193]. The worst observed run reached −0.001 m — contact. The result is not
robust to a two-metre change in entry position."*

**May NOT:** *"S1 clears by 0.16 m."* One run's number is an anecdote. This is precisely
what `benchRuns`' own header warned about before the data existed: *a metric whose
interval sits near a safety threshold has not passed it.*

The CI lower bound is 0.093 m and does not include zero — but **the observed minimum
does**, and on a safety metric the observed minimum is what matters. A confidence
interval describes the mean, not the worst case.

## Why this is the most valuable number in the project
The locked end goal is *"a generalized self-driving test for India"* that OEMs compare
against. A comparison standard whose own headline number moves 30% — and crosses zero —
when you nudge the start is not a standard. **Phase 6 is what turns the demo into a
test, and its first act was to falsify a number we had been quoting all week.**

## Next
Identify which run and which actor produced the −0.0010 m, using `whoDidWeHit`
against that run's `results/` folder. Do not tune anything until it is known.
