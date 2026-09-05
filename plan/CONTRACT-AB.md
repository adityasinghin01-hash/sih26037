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
| `arbitrate` | **Role array (S4) and NOTHING else** | **`[winner, k, info]`** — winning role code (S7); its index in `roles` so the caller takes `vos(k)`; `info` with `.TrackID .H .NumConsidered .Reason` | **done, tested** (14 tests, `stream-d-a` `1d95faf`) |
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

## When you disagree about where something belongs

Ask: **does it need Simulink to test?**

- No → it is A's
- Yes → it is B's

That question settles almost every case. If it genuinely does not, ask Aditya rather than both
writing it.
