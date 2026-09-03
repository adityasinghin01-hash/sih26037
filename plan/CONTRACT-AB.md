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
| `assignRoles` | ego state, TrackList (S1) | Role array (S4) | **done, tested** |
| `chooseVelocity` | role (S7), vo output, `egoState` struct, `opts` | EgoCommand (S4) | **done, tested** — 19 tests |
| `predictAgentFutures` | one track (S1), PYield and Valid (S3), `opts` | 1x2 futures, YIELD and ASSERT, each with `.States` `.Speeds` `.Probability` | **done, tested** — 17 tests |
| `generateCandidates` | `egoState` struct, `referencePathFrenet`, `opts` | candidate array, each with `.States` `.Global` `.LateralOffset_m` | **done, tested** — 13 tests |
| `checkTrajectorySafety` | one candidate, one future, `opts` | `.Safe` per timestep, `.SafePrefixSteps`, `.AllSafe`, `.FirstUnsafeTime` | **done, tested** — 14 tests |
| `findSharedTrunk` | candidate array, per-candidate safe steps, `opts` | `.States` `.Steps` `.Time` `.Blocked` `.Rule` | **done, tested** — 13 tests |
| `planContingency` | `egoState`, `referencePathFrenet`, TrackList (S1), YieldPrediction (S3), `opts` | `.Trunk` `.Candidates` `.Futures` `.SafeSteps` `.Blocked` | **done, tested** — 15 tests |
| *(add a row before you write the function, not after)* | | | |

**`egoState` is a struct** with `.Position`, `.Velocity` and `.Yaw`, packed by `NegotiatingStrategy`.
**`chooseVelocity` takes `opts`** — four arguments, not three. Both settled by Aditya, 2 September 2026.

## When you disagree about where something belongs

Ask: **does it need Simulink to test?**

- No → it is A's
- Yes → it is B's

That question settles almost every case. If it genuinely does not, ask Aditya rather than both
writing it.
