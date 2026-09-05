# Wiring the planner into OpenTrafficLab makes the safety number worse. Finding, 5 September 2026.

**Two ways of putting `sih.planner.chooseVelocity` behind the wheel were built and measured on
5 September 2026. Both made `h` worse than leaving the base class to drive. Neither is shipped.
`NegotiatingStrategy.m` line 105 still defers, exactly as `main` has it, which is also what the
demo already says on stage — so nothing is lost by not shipping them.**

This file exists so the next person does not spend an evening rediscovering it, and so the
number can be quoted honestly if anyone asks whether our planner drives the car.

---

## What was tried

Both attempts were complete, tested, and reverted. Neither was a sketch.

**Attempt 1 — replace.** `determineDrivingInputs` returns `[cmd.Accel, 0]`, where `cmd` comes from
`arbitrate` → `chooseVelocity`, gated on `isempty(k) || info.AllUnknown`.

**Attempt 2 — blend.** The same, but `[min(cmd.Accel, baseInputs(1)), 0]`, with the base class
consulted unconditionally first. The reasoning was the project's own rule from `AGENTS.md`
section 2 — both barriers hold, no mode switch, whichever is more conservative binds — extended
one layer down so that negotiation could only ever slow the car further than car-following would.

## What was measured

The same T-junction, same seed, same vehicles, `StopTime` 20 s, `SampleTime` 0.05 s, R2026a.
Minimum `h = lambda - beta` per actor over the whole run. `h = -pi/2` is `velocityObstacle`'s
floor, reached when separation is at or inside `dMin`.

| actor | base class drives | attempt 1, replace | attempt 2, blend |
|---|---|---|---|
| 11 | 2.8917 | 2.8876 | **−0.2629** |
| 12 | 2.8285 | **−0.2416** | **−1.0112** |
| 13 | 2.8387 | **−0.2476** | **−1.0166** |
| 14 | 2.9382 | 2.6716 | 2.6716 |
| 15 | 1.3013 | 1.3513 | 1.3513 |
| 16 | −0.7821, 0 steps at floor | **−1.5708, 38 of 197 steps** | **−1.5708, 38 of 197 steps** |

Replacing put two previously clean vehicles into violation and drove actor 16 to the floor for
19% of its run. Blending was **worse still**: it put a third vehicle into violation and made 12
and 13 about four times worse, while doing nothing at all for 16.

## Why — and this part is measured, not argued

The obvious reading of attempt 2 is that braking harder should never hurt. That reading is wrong
here, and the reason is visible in the data.

On every step where `h < 0`, the binding agent was located relative to the ego:

| actor | binding agent ahead | binding agent behind |
|---|---|---|
| 3 | 36 | 0 |
| 7 | 29 | 270 |
| 8 | 291 | 9 |
| 9 | 43 | 10 |
| **11** | **0** | **33** |
| 12 | 21 | 13 |
| 13 | 14 | 0 |
| **16** | **0** | **37** |
| **total** | **434** | **372** |

**46% of all barrier violations are caused by a vehicle BEHIND the ego. For actors 11 and 16 —
the two the blend hurt most — it is 100%.**

That is the whole explanation. `h` is relative geometry, so a vehicle closing from behind lowers
your barrier just as surely as one you are closing on. `chooseVelocity`'s `GIVE_WAY` is a flat
−2.5 m/s², usually harsher than Gipps would ask for, so `min()` selects it most of the time. The
car brakes harder, is closed on from behind, and its own `h` falls.

**Slowing down is only unambiguously safer when something can steer.** In this harness nothing
can — `plan/HARNESS-STEERING-FINDING.md` records that OpenTrafficLab's `move()` never executes a
steering input, so braking is the only axis available and there is no lateral escape. The
"whichever is more conservative binds" rule is sound where it is used today, between `h_agent`
and `h_road`, because those are two different geometries of the same instant. Extending it to a
longitudinal command in a harness with one axis of control does not hold, and the measurement is
what showed it rather than the argument.

A second, independent cause is in attempt 1 and survives into attempt 2: `chooseVelocity` answers
about exactly **one** agent, the tightest barrier, while Gipps was keeping headway from the
vehicle directly **ahead**. Those are frequently not the same vehicle, so replacing one with the
other deletes headway control. The blend was meant to fix that and did, in the ahead direction —
which is why actors 14 and 15 are unchanged — while making the behind direction worse.

## What this does and does not mean

**It does not mean the planner is wrong.** `chooseVelocity`, `arbitrate` and `assignRoles` are
unchanged by this finding and all their tests pass. What was measured is a property of putting a
single-agent longitudinal command into a harness that cannot steer.

**It does not mean the Simulink model will behave this way.** `sih_planner.slx` is the only
harness that consumes `SteerAngle`, so it has the lateral axis this one lacks. This finding says
nothing about it either way, and must not be quoted as if it did.

**It does mean no claim may be made that our planner drives the vehicle in OpenTrafficLab.**
`runExperiment.m` already writes `plannerInLoop: false` and a note saying `h` there is a
measurement of a simulation our planner is watching. That note is correct and stays correct.

## What was deliberately not done

**Actor 16 was not chased.** Its violations are 100% from behind and 38 of its 197 steps sit at
the floor under both attempts and 0 under neither — it is the one vehicle whose problem is
untouched by the command at all. That is a separate investigation and it was stopped rather than
started late at night on the eve of a deadline.

**The failing test was not edited.** `testBarrierIsNeverPinnedAtTheSelfCollisionValue` failed
under both attempts and it was failing for the right reason. Its diagnostic message says "which
means it saw itself", which was true of the defect it was written for on 4 September but is not
true here — `testEgoIsNeverInItsOwnTrackList` passes throughout. If that test is ever revisited,
the message deserves widening to "separation is at or inside dMin", because `-pi/2` means that
and not only self-collision.

## Reproducing it

Twelve lines. Run the T-junction, print the minimum `h` per actor:

```matlab
addpath('matlab'); addpath(genpath('OpenTrafficLab'));
s = createTJunctionScenario(); net = createTJunctionNetwork(s);
s.StopTime = 20; s.SampleTime = 0.05;
fnc  = @(varargin) sih.planner.NegotiatingStrategy(varargin{:}, 'CarFollowingModel','Gipps');
cars = createVehiclesForTJunction(s, net, [900 900 900], [40 60], fnc);
for c = cars, c.IsVisible = true; end
while advance(s); end
for c = cars
    h = c.MotionStrategy.Data.UDStates(:);
    fprintf('actor %d: %d of %d steps at floor, min h = %.4f\n', ...
            c.ActorID, sum(abs(h + pi/2) < 1e-9), numel(h), min(h));
end
```

`OpenTrafficLab/` must be cloned into the repository root or the scenario functions are not on
the path.

---

**Status: both attempts reverted. Line 105 defers to the base class, as on `main`. Full suite
after the revert: re-run before quoting, and note that the counts in this file were taken on
5 September 2026 with the wiring temporarily in place.**
