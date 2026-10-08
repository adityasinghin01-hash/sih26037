# Phase 1 finding — the dense world is scenery, not traffic

**16 Sep 2026.** `densityPlannerRun('s1')`, the real planner in S1's dense world, first run.

## What the run reported

```
route 610.1 m, 51 density actors, 1240 maximum steps
  step 300/1240  t=15.0  s=240.6 m  v=14.29 m/s  state=COMMIT  tracks=51
  step 600/1240  t=30.0  s=456.3 m  v=14.38 m/s  state=COMMIT  tracks=50
total steps: 817 | reached end of route: TRUE | plan-failure count: 0
```

Read alone that looks like a pass. It is not.

## The numbers that give it away

| | Real S1 (3 negotiation actors) | This run (51 density actors) |
|---|---|---|
| Duration | 75.2 s | **40.85 s** |
| Mean speed | 28.0 km/h | **51.6 km/h** |
| Max speed | 52.0 km/h | 52.0 km/h |
| Time stopped | 2.2 s | **0 s** |
| Min clearance | 0.618 m | **1.474 m** |
| Barrier `h` | real values | **NaN on all 817 steps** |
| State | PROBE at t=35 s, then COMMIT | **COMMIT the entire way** |

**The car drove at cruise speed from end to end and never slowed once.** It never probed,
never stopped, and its safety barrier never bound to anything — `h` is NaN at every single
step, which is what `planSeat` returns when no agent is binding.

## Why — measured, not guessed

```
road half-width: 3.50 m
density actors: 51
  ON the carriageway (|lateral| < 3.50 m):  1
  off it:                                  50
  lateral range: −5.60 .. 8.50 m
```

**Fifty of the fifty-one actors are not on the road.** They are shopkeepers, parked vehicles,
people on verges, tethered animals — the density layer's own memo says so plainly:
*"218 of 253 density actors are still permanently static… asleep/tethered/parked/grazing."*

It was built as **background**, and background is what it is. Handing it to a planner changes
nothing, because none of it is in the way.

**And the actual traffic was left out.** `sc.s1actors` — the cow, the tractor, the oncoming
vehicle, the set the real demo negotiates with — was never added to the TrackList. Phase 1
*replaced* the negotiation actors with scenery instead of *adding* scenery to them.

## What this means for the plan

"The planner drives the dense world" is now true and worthless. `tracks=51` on the HUD is
cosmetic. Phase 1 was scoped as a wiring job; the wiring works and the wiring was never the
problem.

**Phase 1 is really two jobs:**

**1a — Union, not replacement.** The TrackList must carry `sc.s1actors` (the negotiation set)
**and** the density actors. That restores the cow and gives a genuine comparison: does the
planner still make its 0.618 m pass with 51 more objects in the scene?

**1b — Put hazards in the road.** This is the part Aditya actually asked for back on 10 Sep —
*"one cow in one place, then another, in different positions"*, repeated real instances that
stress the planner. Today exactly **one** density actor stands on the carriageway. A real
stress test needs jaywalkers crossing the lane, a cow standing in it, parked vehicles
narrowing it — actors placed to obstruct, not to decorate.

**Do not report "the planner handles 51 actors."** It handled 1, and 1 was not in its way.

## Also worth fixing while in here
`M5_minBarrier_rad` came back `null` and all 817 `h` values are NaN. That is consistent with
"nothing ever bound" rather than a separate bug — the S2 timeline shows the same `h=NaN` at
COMMIT before an agent binds. Re-check it once 1a lands and real agents are present. If `h`
is still NaN with the cow in the road, that IS a bug.

---

# Phase 1a — density has a real compute cost. Measured, mid-run.

Phase 1a adds the negotiation actors back (cow, herd, auto, wrong-way rider, overtaker,
tractor) so the planner drives the **union**: real traffic + 51 background actors.

**The run is taking roughly an order of magnitude longer.**

| Run | Tracks | Wall clock |
|---|---|---|
| `demo_play('demo1')` — sparse | ~3 | 46.7 s planner time |
| `densityPlannerRun` — background only | 51 (none in the way) | ~5 min |
| `densityPlannerRun` — **negotiation + density** | ~57 | **45 min and still running** |

Confirmed computing, not hung: 102% CPU, 7 m 48 s of CPU time consumed at the 45-minute mark.

## Why this matters beyond Phase 1

`sc.planSeat` evaluates 35 candidate trajectories per step and capsule-checks each one
against every track. Adding 51 tracks multiplies that inner loop. On top of it,
`sc.adapterS9Real` ray-marches the sight term against this world's ~2200 occluders every
single step.

**This is the number Phase 9 lives or dies on.** Phase 9 wants the planner running live at
10 Hz — 100 ms per step. A dense scene currently costs far more than that per step. So:

- Phase 9's four levers (spatial index on the occluders, `PlanEvery`, `BuildCostmap=false`,
  profile first) are not optimisations to consider later. **They are prerequisites.**
- The honest read today: **live planning in a dense world is not close.** Sparse-world live
  was already out of reach; dense is roughly 10× further away.

Do not promise live planning in a dense scene until `sc.planSeat` has actually been profiled.
It still has never been timed — its own source comments say so.

---

# Phase 1a — where it landed, 16 Sep 2026

`densityPlannerRun('s1')` now drives the real planner against **three** layers, not one:

1. **Traffic** — `sc.s1actors` via `s1_action_run.m`: cow, herd, auto, wrong-way rider,
   overtaker, tractor, trolley (9 tracked actors)
2. **Scenery** — `sc.s1density`: 51 background actors, buildings, poles
3. **The road's own constraints** — `sc.demo1Route`: 14 hazards with speed caps of 14–29 km/h

Each was added because the run before it proved the layer was missing.

## The progression, in order, with what each step proved

| Run | What was in it | Result | What it proved |
|---|---|---|---|
| 1 | scenery only | route done, 51.6 km/h mean, `h`=NaN all 817 steps | 50 of 51 actors are off the carriageway — the planner had nothing to negotiate |
| 2 | + traffic | route done, 35.0 km/h, PROBE fires, `h` binds on 57% of steps | the mechanism works in a dense world |
| 2b | *(measurement fixed)* | M6 **−0.800 m** | M6 had been measuring clearance to scenery; the cow was never in the evidence file at all |
| 3 | + speed caps | M6 **+0.121 m**, 23.5 km/h, **route incomplete at 403 m** | the collision was caused by arriving early with no caps — but `T_END` was a copied constant |
| 4 | + computed duration | route done, **77.95 s, 27.0 km/h**, 0 plan failures | matches the sparse baseline's 28.0 km/h — the car drives the road properly now |

## Two real bugs found and fixed, both silent

- **M6 measured the wrong actors.** `D.Poses` carried only the density set, so the headline
  clearance metric never saw the cow. Reported `+1.092 m` while the car overlapped something
  else by 0.80 m. Nothing errored.
- **A constant was copied where a mechanism was needed.** `T_END = 62.0` was lifted from the
  sparse config; once the caps slowed the car, the route no longer fit in the budget and the
  run silently stopped at 403 m of 610 with `M9_completed=false`. Replaced with
  `sc.estimateDuration`, which recomputes from whichever caps are in force.

## Open, and NOT to be quoted until settled

**`M6 = −0.80006313535138085` is bit-identical across two runs whose timing differs by 18
seconds.** A moving collision cannot produce that. The evidence points at `moto_over` — the
overtaking motorcycle — finishing its scripted trajectory and stopping at s=610, the route
end, where the ego then arrives. Under investigation.

**Do not quote −0.800 as a collision.** It has headlined three reports and it appears to
measure a bookkeeping edge, not behaviour.

## Two files added, both disclosed duplicates of `demo_play.m` privates
`sc.hazardCap` and `sc.estimateDuration`, lifted verbatim rather than approximated, each
carrying a header warning that if `demo_play`'s copy changes these must change with it.
Precedent: `sc.activeDensityActorsAt`, which already does this for the same reason.

---

# PHASE 1a RESULT — 16 Sep 2026

`results/density-planner-s1_20260916-151318`

## The ghost-track defect, and what fixing it proved

**3,805 tracks** across the run were reporting a velocity while their position had not
moved. Not one actor — a systemic property of the recorded scenario.

The clearest case: `moto_over` reaches the route end (s=610 m) at t=49.95 s and stops, while
still reporting **17.22 m/s — 62 km/h**. `sih.planner.predictAgentFutures` propagates tracks
forward from their velocity, so the planner believed a motorcycle was sprinting away while it
was in fact parked in the carriageway.

**Same planner, same route, only the honesty of the input changed:**

| | ghost velocity | velocity zeroed when stationary |
|---|---|---|
| ego at s=601 m | 13.85 m/s, COMMIT, drove through | **2.20 m/s, crept past** |
| `moto_over` separation | **−0.800 m** (overlap) | **+0.299 m** |
| M6 overall | **−0.800 m** | **+0.121 m** |

That is a clean causal chain, not an argument.

## What actually binds — and it is not the cow

| actor | worst separation |
|---|---|
| **trolley** | **0.119 m** ← the tightest moment in the whole run |
| auto | 0.132 m |
| tractor | 0.211 m |
| moto_wrong | 0.253 m |
| moto_over | 0.299 m |
| **cow** | **1.015 m** |
| background actors | 1.09 m and wider |

The tightest point is **t = 20.00 s, s = 217 m**, threading past the tractor's trolley at
e = −2.20 m with **12 centimetres**.

**The scenario's famous obstacle is not its hardest moment.** The cow is the sixth-tightest
approach. What actually squeezes this planner is ordinary traffic it has to get past — which
is a more honest and more interesting claim than "it avoids the cow."

## The headline comparison

| | sparse S1 (`demo_play`) | dense S1, all three layers |
|---|---|---|
| tightest approach | **0.618 m** | **0.121 m** |
| mean speed | 28.0 km/h | 22.7 km/h |
| duration | 75.2 s | 92.65 s |
| route completed | yes | yes |
| plan failures | 0 | 0 |

**Adding a realistic world to a scenario the planner already solved cuts its safety margin by
about 80%.** It still completes, still never fails to plan — but it is operating five times
closer to contact.

## Not settled — do not quote the numbers above as final

- **454 of 1,853 steps (24% of the run) ran past the end of the recording**, with every actor
  frozen. The run is 92.65 s; the recording is 1,399 frames. A quarter of this result is the
  ego driving through a still photograph.
- My argmin replica gives 0.1193 m where the official M6 gives 0.12109 m — a **1.8 mm**
  disagreement, because the replica recovers the ego's Frenet position from logged XY rather
  than reading `LOG.s`/`LOG.e` directly. Close enough to identify the actor, not close enough
  to quote. Use the metric's own number.
- `trajectories.csv` still records only 10 of the 60 actors.

---

# PHASE 2 (S3) — IT IS NOT SLOW, IT IS STUCK. 17 Sep 08:07.

Three attempts were written off as "too slow": killed at 3h48m, killed at a 50-minute
timebox, and blamed on a 220 s `T_END`. **All three diagnoses were wrong.** The fourth run
was allowed to print its step trace:

```
step  900/4400  t= 45.0 s  s=81.4 m  v=0.00 m/s  ABORT
step 1200/4400  t= 60.0 s  s=81.4 m  v=0.00 m/s  ABORT
step 1800/4400  t= 90.0 s  s=81.4 m  v=0.00 m/s  ABORT
step 2700/4400  t=135.0 s  s=81.4 m  v=0.00 m/s  COMMIT
step 3900/4400  t=195.0 s  s=81.4 m  v=0.00 m/s  ABORT
```

**The ego stops dead at s = 81.4 m of a 382.2 m route and never moves again** — 150
seconds at the identical station, cycling ABORT -> COMMIT -> ABORT. The runs were not
computing slowly; the car was standing still, burning its full step budget going nowhere.

## This is S2's pathology, reproduced in S3

`plan/CLAIM-LEDGER.md` on S2: *"the planner then permanently stalls partway around the ring
and never reaches the exit - a D9 WAIT-rung mechanism repeatedly finding, then losing, a
viable pass."* S3 dense now does the same thing at s=81.4 m.

**S3 works sparse.** `demo_play('demo3')` completes all 382.2 m with 0 plan failures and a
measured 0.293 m clearance, re-verified 16 Sep. Adding the dense world breaks it.

## What this means for the two-scenario scope
- **S1 dense**: completes, 0 plan failures, margin cut from 0.618 m to 0.135 m
- **S3 dense**: **does not complete. Permanent stall at 21% of the route.**

So the honest headline is stronger and worse than "a dense world costs 80% of the margin":
**on one of the two scenarios, a realistic world does not cost margin - it stops the car
completely.** One in two, on the only two scenarios that worked.

## Do not paper over this
Do not raise the step budget, do not loosen the corridor, do not remove actors until it
moves. The stall is the result. It is the same mechanism already disclosed on S2, now shown
to be general rather than an S2 quirk - which makes it a finding about the planner, not about
one scenario.

**Next diagnostic, cheap:** S3's stall is at s=81.4 m. Identify which actor or corridor
constraint binds there, the same way `whoDidWeHit` identified the trolley on S1. Do not start
fixing before that is known.
