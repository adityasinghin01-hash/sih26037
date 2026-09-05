# The boundary between the two planner people

Stream D is two people. `AGENTS.md` section 3 stops the six *streams* colliding. This stops the
two of *you* colliding, which is a different problem and just as expensive.

## Who owns what

| | **Person A** — Claude Code | **Person B** — Antigravity |
|---|---|---|
| Writes | `matlab/+sih/+planner/*.m` | the Simulink model and Stateflow chart |
| Tests with | `runtests('matlab/tests')`, seconds | the model running, minutes |
| Branch | `stream-d-a` | `stream-d-b` |
| **Never touches** | **the `.slx` file** | **`+planner/*.m`** |

## Why this line and not another

**A Simulink `.slx` is a binary file.** Git cannot merge two people's edits to it — one version
simply overwrites the other and that person's day is gone. There is no warning and no conflict
marker. **So exactly one person opens it, and that is B.**

The reverse matters too: A's functions are plain MATLAB, so they can be unit-tested in seconds
without launching Simulink. If A had to test inside the model, iteration would drop from seconds
to minutes and the biggest job on the project would slow to a crawl.

## The interface between you is a function signature

B's chart calls A's functions. Nothing else crosses.

```matlab
cmd = sih.planner.chooseVelocity(role, vo, egoState, opts)
% in : role (S7), velocityObstacle output, ego state
% out: EgoCommand (S4)
```

**A publishes the signature before writing the body.** B builds the chart against a stub that
returns a fixed command, and the real function drops into a slot that already works.

**That is the whole trick: B is never blocked waiting for A.**

## Rules for both of you

1. **Agree the signature first, in writing, in this file.** Add a row when you add a function.
2. **A changes a signature only by telling B first.** Adding an output is safe; changing the
   order or meaning of an input is not.
3. **Both run `runtests('matlab/tests')` before every push.** A's tests are B's early warning.
4. **Neither of you edits `AGENTS.md` section 3.** Four other people build against it.
5. **Neither of you edits `matlab/baseline/`.** It is the competitor. Editing it makes every
   number this project produces worthless.

## The functions, as they are agreed

| Function | In | Out | Status |
|---|---|---|---|
| `velocityObstacle` | ego pos/vel, agent pos/vel, dMin | `.beta .lambda .tcpa .d` | **done, tested** |
| `assignRoles` | ego state, TrackList (S1), `opts` | **`[roles, vos]`** — Role array (S4), and the full `velocityObstacle` result per track | **done, tested** |
| `chooseVelocity` | role (S7), vo output, `egoState` struct, `opts` | EgoCommand (S4) | **done, tested** (PR #3, 3 Sep) |
| `arbitrate` | **Role array (S4) and NOTHING else** | **`[winner, k, info]`** — winning role code (S7); its index in `roles` so the caller takes `vos(k)`; `info` with `.TrackID .H .NumConsidered` **`.NumUsable` `.AllUnknown`** `.Reason` | **done, tested** (**18 tests**, `stream-d-a`, run 5 Sep 2026) |
| `predictAgentFutures` | one track (S1), PYield and Valid (S3), `opts` | 1x2 futures, YIELD and ASSERT, each with `.States` `.Speeds` `.Probability` | **done, tested** — 17 tests |
| `generateCandidates` | `egoState` struct, `referencePathFrenet`, `opts` | candidate array, each with `.States` `.Global` `.LateralOffset_m` | **done, tested** — 13 tests |
| `checkTrajectorySafety` | one candidate, one future, `opts` | `.Safe` per timestep, `.SafePrefixSteps`, `.AllSafe`, `.FirstUnsafeTime` | **done, tested** — 14 tests |
| `findSharedTrunk` | candidate array, per-candidate safe steps, `opts` | `.States` `.Steps` `.Time` `.Blocked` `.Rule` | **done, tested** — 16 tests |
| `planContingency` | `egoState`, `referencePathFrenet`, TrackList (S1), YieldPrediction (S3), `opts` incl. **`trunkMode`** `"A"`/`"B"` | `.Trunk` `.Candidates` `.Futures` `.SafeSteps` `.TerminalPrefixSteps` **`.TrunkMode`** `.StopChecks` `.Blocked` | **done, tested** — 24 tests |
| `followTrunk` | `trunk` (from `findSharedTrunk`), `egoState` struct, `opts` | EgoCommand (S4), plus an `info` struct for logging | **done, tested** — 21 tests |
| `checkTerminalStop` | one candidate, one future, the step to brake from, `opts` | `.Safe` `.StopDistance_m` `.StopDuration_s` `.StopStates` | **done, tested** — 17 tests |
| `roadBarrier` | DrivableSpace (S9), speed, `opts` | `.h_road` `.Violated` `.dMin_m` `.Clearance_m` `.UsedFallback` `.Reason` | **done, tested** — 22 tests |
| `speedLimit` | DrivableSpace (S9), speed, `opts` (curvature, `vRoute_mps`) | `.v_max_mps` `.Binding` and the three terms | **done, tested** — 19 tests |
| *(add a row before you write the function, not after)* | | | |

### `assignRoles` gained a second output — 5 September 2026

`[roles, vos]`. It already computed a full `vo` for every track and threw it away, so returning it
costs **zero extra arithmetic**. MATLAB's output rules make it **backward compatible** — every
existing `roles = assignRoles(...)` call is untouched, and the 14 geometry tests still pass.

### `arbitrate` — the rule, and why the inputs are so thin

`assignRoles` gives a role to **every** road user. `chooseVelocity` accepts **one**. Arbitration
picks which single agent the car answers to this step.

**It takes the role list and nothing else — no ego pose, no TrackList.** A function that never
sees a position cannot be handed an ego-frame track list together with a world-frame ego pose,
which is this codebase's known silent-wrong-answer bug (`assignRoles.m` header). The trap is not
guarded against; it is **made unrepresentable**.

| Situation | Behaviour |
|---|---|
| Winner | smallest `h = Lambda - Beta` — **tightest, not nearest** |
| Exact tie | **lowest `TrackID`.** S1 guarantees IDs are stable and never reused, so the same scene gives the same answer every run instead of depending on perception's list order |
| Empty TrackList | **no winner, `k` is EMPTY**, `info.H = NaN`. S1 guarantee 3 — consumers must not error. **The caller MUST check `isempty(k)` before using `vos(k)`** |
| Every `h` is NaN | reported **separately** from empty — knowing nothing about everybody is not the same as the road being clear |
| All agents SAFE | still returns the smallest-`h` agent; `chooseVelocity` turns a SAFE role into a free-running command |

**Three things `arbitrate` must NOT do:** read `PYield` (it ranks, it does not permit —
`plan/S3-PYIELD-RULING.md`) · choose between `h_agent` and `h_road` (both must hold, geometry
decides which binds — `AGENTS.md` §2) · pick the nearest agent (nearest is not tightest).

Full reasoning: **`plan/ARBITRATION-RULING.md`**.
**Person B: this signature is frozen. Build the chart against it.**


**`egoState` is a struct** with `.Position`, `.Velocity` and `.Yaw`, packed by `NegotiatingStrategy`.
**`chooseVelocity` takes `opts`.** Settled by Aditya, 2 September 2026.
**What that means when you CALL it:** `opts` is a set of *optional name-value* tuning arguments,
not a fourth thing you must pass. Both of these are correct MATLAB:
```matlab
cmd = sih.planner.chooseVelocity(role, vo, egoState);                        % defaults
cmd = sih.planner.chooseVelocity(role, vo, egoState, 'gradient_rad', 0.1);   % tuned
```
So a three-argument call is **not** a bug — it just takes every default.
### `.Reason` is not carried inside the Simulink signal bus — 5 September 2026

Section 3 declares `.Reason` as a MATLAB `string`. Stateflow and Simulink signal buses
cannot carry dynamic MATLAB `string` objects without code-generation errors — they require
fixed-size, statically typed signals. The chart carries the seven numeric and boolean
contract outputs (`Accel`, `SteerAngle`, `Mode`, `Gear`, `Signal`, `Committed`,
`MirrorsFolded`). `.Reason` remains available in the pure MATLAB struct returned by
`chooseVelocity` and `followTrunk`, and can be logged from MATLAB workspace calls, but
it does not pass through the Simulink bus or the Stateflow chart.


**`followTrunk` needs the vehicle wheelbase** and nothing in this repository states it. It defaults
to 2.8 m. Person B should pass the real figure via `opts.wheelbase_m`.

**PERSON B — READ `.TrunkMode` BEFORE YOU SET `Committed`.** `planContingency` reports which
reading of the trunk produced its answer. `"A"` is the longest collision-free prefix; `"B"` also
requires that a braking-to-stop from the end of it is clear under both futures.
**While `.TrunkMode` is `"A"`, `Committed` must stay false** — `plan/D6-TRUNK-RULING.md` is
explicit that (a) plus `Committed` lets the planner commit irrevocably to a trajectory that has
already lost. **`"B"` is the DEFAULT from 4 September 2026** — a caller who passes no `trunkMode` gets the
ruling's answer automatically. `"A"` still exists but must now be asked for by name.

Measured on one scene, 5 Sep 2026 (ego 8 m/s, a car standing at x = 42 m): (a) commits 4.00 s and
32.0 m, leaving the car needing 8 m to stop with only 10 m to the obstacle. (b) commits 3.40 s and
27.2 m, which stops clear. It cost 56 terminal checks over 20 candidates and 2 futures.

**`roadBarrier` and `speedLimit` are D8, and they take a hand-made `DrivableSpace`.** S9 is frozen
in `AGENTS.md` section 3 but the World has not delivered it, so both are *built and unit-tested,
not validated*. Every header says so. `speedLimit` also needs `vRoute_mps` passed in, because S10
Route carries `GoalHeading`, `GoalPoint`, `BlockedEdges` and `EscapePoints` and **no speed**.

## When you disagree about where something belongs

Ask: **does it need Simulink to test?**

- No → it is A's
- Yes → it is B's

That question settles almost every case. If it genuinely does not, ask Aditya rather than both
writing it.
