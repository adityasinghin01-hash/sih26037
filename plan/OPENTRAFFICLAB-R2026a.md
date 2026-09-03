# OpenTrafficLab does not run on R2026a unmodified — and here is the fix

**Answered by running it, 4 September 2026, MATLAB 26.1.0.3346908 (R2026a) Update 5, macOS.**
This is the answer to `derisk/check05_opentrafficlab.m`, which the project had listed as its
highest known risk since 31 August.

---

## The short version

**Stock, unmodified OpenTrafficLab fails on the first `advance()` under R2026a.** Two separate
incompatibilities, stacked. Both are fixed **outside** `OpenTrafficLab/` — nobody edits the
third-party folder, because it is gitignored and every teammate has their own clone.

| # | Symptom | Where the fix lives | Status |
|---|---|---|---|
| 1 | `Unrecognized method, property, or field 'ReferencePoint'` | our subclass | **fixed** |
| 2 | `ssf:sensorsim:invalidActorsAddedToSensorSim` | the scenario setup / harness | **fixed, one line** |

With both applied: **398 steps, 20 s of simulated time, no error, `h` logged every step.**

---

## Why this mattered

OpenTrafficLab's own README says *"This model has been tested with MATLAB R2020b."* We are six
years past that. `NegotiatingStrategy` extends `DrivingStrategy`, so if the foundation does not
run, D3 through D11 have nothing to stand on and Person B cannot build the harness at all.

It does run. It just needs two small things that did not exist in 2020.

---

## Breakage 1 — `ReferencePoint`

### What you see

```
MATLAB:noSuchMethodOrField
Unrecognized method, property, or field 'ReferencePoint' for class 'DrivingStrategy'.
  at actorPoses (line 23)
  at actorPoses (line 9)
  at drivingScenario.setUpSensorSimulation (line 329)
  at advance (line 8)
```

**This happens with plain `DrivingStrategy` and zero code of ours.** It is not our bug.

### What it is

A *motion strategy* is the object that decides where an actor goes each step. MathWorks ships
their own (`driving.scenario.Path`, `SmoothTrajectory`); OpenTrafficLab writes a custom one.

Since R2020b, `driving.scenario.Vehicle` gained a line that reads the strategy's
`ReferencePoint` — the point on the car its position refers to, front axle or rear axle:

```matlab
% R2026a: toolbox/shared/drivingscenario/+driving/+scenario/Vehicle.m line 63
if isequal(obj.MotionStrategy.ReferencePoint, "front-axle")
```

MathWorks added the property to **their own** concrete strategies but **not** to the abstract
base class `driving.scenario.MotionStrategy` that third parties subclass. So every custom motion
strategy written before that change now dies the moment sensor simulation is set up — and in
R2026a that happens unconditionally inside `advance()`.

### The fix

One property on our subclass, in `matlab/+sih/+planner/NegotiatingStrategy.m`:

```matlab
ReferencePoint = ""
```

`""` selects the rear-axle branch, which is exactly the pre-R2026a behaviour — so this restores
the old semantics rather than changing them.

**If you use plain `DrivingStrategy` for background traffic, it will still fail.** Use
`NegotiatingStrategy` for every vehicle, or add the same property to your own subclass. Do not
edit `OpenTrafficLab/`.

---

## Breakage 2 — invisible actors have NaN poses

### What you see

```
ssf:sensorsim:invalidActorsAddedToSensorSim
ActorProfile or ActorPose object contain invalid values.
  at addActors (line 0)
  at drivingScenario.setUpSensorSimulation (line 329)
  at advance (line 8)
```

### What it is

OpenTrafficLab injects vehicles over time. Its `DrivingStrategy` constructor hides every car
until its entry time:

```matlab
egoActor.IsVisible = false;      % DrivingStrategy constructor
```

In R2026a, `actorPoses` returns **NaN** for an invisible actor. `setUpSensorSimulation` then
validates the whole actor set and rejects it before step one. Confirmed directly:

```
before: IsVisible=0  pose1=[NaN NaN NaN]
after : IsVisible=1  pose1=[-433.325  2147.21  0]
```

The actor's `Position` was correct the whole time — only the *pose report* was NaN.

### The fix

Make the vehicles visible after creating them, before the first `advance()`:

```matlab
cars = createVehiclesForTJunction(s, net, rate, turnRatio, fnc);
for c = cars
    c.IsVisible = true;
end
```

**This is a harness fix, not a planner fix**, which is why it lives in the scenario setup and in
`matlab/tests/testNegotiatingStrategy.m`, not inside `NegotiatingStrategy`.

**Person B:** you need this in whatever builds your scenario. It costs the staggered-entry
effect — every car is visible from t=0 rather than appearing at its entry time. If that matters
for a demo, set `IsVisible` true at each vehicle's `EntryTime` instead of all at once.

---

## Reproduce it yourself

From the repository root, with OpenTrafficLab cloned beside it:

```matlab
addpath('matlab'); addpath(genpath('OpenTrafficLab'));
runtests('matlab/tests/testNegotiatingStrategy.m')
```

**9 tests. All pass on R2026a.** Without OpenTrafficLab they report as *Incomplete* (skipped),
never as failed — a missing third-party dependency is not a broken repository.

---

## What this does NOT tell us

- **Only the T-junction path is exercised.** `createFourWayJunctionScenario` has not been run.
- **`TrafficController` / `TrafficLight` were never used** — we delete the controller on
  purpose (D3), so its R2026a compatibility is untested and we do not need it.
- **`derisk/check05_opentrafficlab.m` cannot answer its own question.** It searches for
  `**/*Example*.m` and root-level `*.m`, which misses `OpenTrafficLab/Testing/*.m` and the
  `.mlx`, so it prints an empty example list and then says "open one of the above". It listed
  zero. Flagged for whoever owns `derisk/`; not edited here, it is not Stream D's folder.
