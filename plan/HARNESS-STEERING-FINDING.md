# The OpenTrafficLab harness cannot steer. Finding, 4 September 2026, 21:0x IST.

**Produced by reading MathWorks' own source and running the suite, not by inference.**
This decides what "closing the loop at line 105" can and cannot mean, so read it before
anyone wires `NegotiatingStrategy.m` line 105.

---

## The finding

`NegotiatingStrategy.determineDrivingInputs` overrides a base-class method whose entire output is:

```matlab
% OpenTrafficLab/@DrivingStrategy/DrivingStrategy.m:505
inputs = [acc,0];
```

A 1x2 vector. The caller, thirty lines further down, does this:

```matlab
% DrivingStrategy.m:608-610
inputs = determineDrivingInputs(obj,tNow);
obj.Acceleration        = inputs(1);
obj.AngularAcceleration = inputs(2);
```

and then integrates:

```matlab
% DrivingStrategy.m:614-618
obj.Position = obj.Position + dt*car.Velocity;
obj.Speed    = obj.Speed + dt*obj.Acceleration;
    % Forward Vector
%obj.ForwardVector = ... to be implemented
```

**`AngularAcceleration` is assigned and never read again.** MathWorks left the heading update
commented out as an unimplemented stub. Heading comes from `getLaneInformation(obj)` — the road
network geometry — and `obj.Station` advances along a segment. The vehicle is a point on a rail.

**So in the OpenTrafficLab T-junction, our planner can change acceleration and nothing else.**
`inputs(2)` is a dead input. Writing `cmd.SteerAngle` into it changes no trajectory.

---

## Three consequences, in the order they cost us

### 1. `followTrunk` has no home in this harness, and it is not the route to a demo

`followTrunk` computes `.SteerAngle` by pure pursuit along the committed trunk. That is its main
product and this harness discards it. `planContingency` also requires
`refPath (1,1) referencePathFrenet` — the S10 route centreline — and
`matlab/+sih/+scenario/` is empty, so that input does not exist either.

**Two independent blockers. Do not attempt the `planContingency -> followTrunk` route before the
7th.** It is the better piece of engineering and it is 12 commits of tested code, but it cannot
drive anything in the only scenario we can run.

### 2. The route that DOES close the loop is the arbitration route, and it is small

```matlab
[roles, vos] = sih.planner.assignRoles(egoPos, egoVel, egoYaw, tracks);  % second output is NEW
[winner, k]  = sih.planner.arbitrate(roles);                            % NEW file, ~20 lines
cmd          = sih.planner.chooseVelocity(winner, vos(k), egoState);
inputs       = [cmd.Accel, 0];                                          % line 105
```

Needs no S10, no S3, no ONNX, no Simulink. `arbitrate` is `minBarrierFromRoles()` at
`NegotiatingStrategy.m:141` plus an index — already written, per `plan/ARBITRATION-RULING.md`.
`chooseVelocity` has 19 passing tests. **This is the whole job.**

`inputs(2)` stays `0` with a comment saying why, so nobody later reads the zero as a planner
decision. It is the harness's dead slot, not our choice of steering.

### 3. What we may say about the demo changes, and it changes for the better if we say it first

The honest sentence is **longitudinal**, and it is still the real problem statement:

> At an unregulated Indian junction with no referee, the car decides from geometry alone
> whether to go, creep or give way. That decision is longitudinal, and it is the one our
> planner makes in this run.

**We must NOT say "adaptive path planning" over a run where the path is fixed by the road
network.** A judge who opens OpenTrafficLab finds line 505 in a minute.

---

## Where the trunk story CAN be shown: Person B's Simulink model

`sih_planner.slx` on `stream-d-b` — 38 blocks, loaded and listed on the Mac, 4 Sep:

```
sih_planner/Chart            -> Accel, Mode, Gear, SteerAngle, Signal, Committed, MirrorsFolded
sih_planner/MATLAB Function  -> takes Accel + SteerAngle, outputs Position, Velocity, Yaw, Speed
sih_planner/MATLAB Function1 -> takes Position + Velocity, outputs h
```

**That vehicle model consumes `SteerAngle`.** So the two harnesses have different powers and the
project needs both:

| | OpenTrafficLab T-junction | `sih_planner.slx` |
|---|---|---|
| Many interacting agents | **yes**, 16 actors | no, single ego |
| Steering is executed | **no** — `inputs(2)` is dead | **yes** |
| Where `h` comes from | every agent, 1815 samples | one ego trajectory |
| What it can demonstrate | negotiation, arbitration, give-way | the trunk, D6, contingency |

Neither one alone shows the whole project. **Say that rather than letting a judge find it.**

---

## Status

Finding by Claude at Aditya's instruction, 4 September 2026. It is a reading of third-party
source plus a block listing, both reproducible in minutes. `OpenTrafficLab/` was not modified and
is gitignored third-party code. `matlab/baseline/` untouched. `AGENTS.md` section 3 untouched.
