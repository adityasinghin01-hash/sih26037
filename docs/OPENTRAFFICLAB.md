# Phase 2.4 — the OpenTrafficLab integration

Read from the actual source at `mathworks/OpenTrafficLab`, not from documentation.
This is the exact seam where we cut.

## The class we inherit

```matlab
classdef DrivingStrategy < driving.scenario.MotionStrategy ...
                         & driving.scenario.mixin.PropertiesInitializableInConstructor
```

### RISK, quoted from their own header — flag this on day one
> "DrivingStrategy inherits from a MATLAB class meant for **internal use**. It has been tested in
> **MATLAB 2020b**, and **may not work in future or earlier releases**."

Our licence is R2024b+. **This is the single largest unverified risk in the build**, because it is
the foundation everything else sits on. It is de-risk check 5, and it is now the highest-priority
part of that check: cloning is not enough — an example must actually *run*.

**If it breaks on R2024b+:** `driving.scenario.MotionStrategy` is internal, so the fallback is the
closed-loop recipe we already verified — Scenario Reader → Stateflow → bicycle model, with poses
fed back into the **Non-ego Actor Poses input port**, which overwrites the programmed waypoints.
Same result, more wiring, no dependency on an internal class. Budget two days if this fires.

## The override points

`move(obj, SimulationTime)` runs on every `advance()`. Two of its six steps are ours.

| Method | Line | What it does | Ours? |
|---|---|---|---|
| `move` | 533 | the per-step loop | no — leave it alone |
| `determineDrivingMode(obj,tNow)` | 446 | picks the mode | **OVERRIDE** |
| `determineDrivingInputs(obj,tNow)` | 479 | produces the control input | **OVERRIDE** |
| `carFollowing(obj,spacing,speed,speedDiff)` | 510 | Gipps / IDM longitudinal model | keep — it is a good baseline |
| `updateUDStates(obj,t)` | 323 | user-state hook, empty by design | **USE** — log the barrier |
| `initializeUDStates(obj,t)` | 326 | user-state init, empty by design | **USE** |
| `getVehiclesInSegment(obj)` | 431 | **how a vehicle sees others** | use — our perception hook |
| `getNextNodeState(obj)` | 435 | **asks the node whether it may enter** | **THIS IS WHAT WE DELETE** |
| `getLeader(obj,tNow)` | 405 | nearest vehicle ahead | use |

## What "delete the TrafficController" means, exactly

```matlab
classdef TrafficController < driving.scenario.MotionStrategy ...
    properties (SetAccess = protected)
        Nodes          % nodes it manages
        IsOpen         % boolean per node - whether the node may be entered
    end
```

Each `Node` holds `node.TrafficController = obj`. A vehicle calls `getNextNodeState()`, the node
answers from its controller's `IsOpen`, and the vehicle obeys. **That is the central authority.**
`StopSign` and `TrafficLight` are its two subclasses — a signal is a controller.

**Our cut is one method.**

```
BEFORE   vehicle --> node --> TrafficController.IsOpen --> go / wait
AFTER    vehicle --> getVehiclesInSegment() --> sih.planner.assignRoles() --> role --> act
```

No broadcast. No shared channel. No node state. **A cow cannot query a TrafficController, but a
cow has a bearing and a course.**

## Their defaults, for the record

| Property | Default | Note |
|---|---|---|
| `DesiredSpeed` | 10 m/s | |
| `ReactionTime` | 0.8 s | |
| `SpeedBounds` | [0, 15] m/s | |
| `AccBounds` | [-5, 3] m/s² | ours is [-6, +3] — INTERFACES S4. **Reconcile before integration** |
| `CarFollowingModel` | `'Gipps'` | `'IDM'` also available |
| `StaticLaneKeeping` | true | **must become false** — lane keeping is exactly what we do not have |

## What we build

`matlab/+sih/+planner/NegotiatingStrategy.m` — subclasses `DrivingStrategy`, overrides the two
methods above, stores roles in `UDStates`, never touches `move`.

Their `Testing/createFourWayJunctionScenario.m` is our starting scenario. Stream A adapts it to an
unmarked Indian junction; Stream D swaps in the strategy.
