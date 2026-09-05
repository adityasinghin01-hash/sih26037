# Arbitration — which road user the car answers to. Ruling, 4 September 2026.

**Person A asked which shape `arbitrate` should take. The answer is neither of the two she
proposed, and the third shape is cheaper than both.**

She also found something worth acting on: **arbitration is not written down anywhere.** The word
appears nowhere in `plan/`, nowhere in `AGENTS.md`. It existed only as a spoken decision relayed
through Aditya. This file fixes that, so nobody has to remember it correctly.

---

## What arbitration is, and why it has to exist

`assignRoles` gives a role to **every** road user. `chooseVelocity` accepts **one**:

```matlab
cmd = sih.planner.chooseVelocity(role, vo, egoState, opts)
```

An Indian junction has a dozen agents at once. Something has to decide **which single one the car
is answering to this step.** That decision is arbitration, and until now it lived in nobody's file.

---

## The ruling

> **`arbitrate` takes the role list and nothing else. The winner is the agent with the smallest
> `h = Lambda - Beta`.**

```matlab
[roles, vos] = sih.planner.assignRoles(egoPos, egoVel, egoYaw, tracks);   % vos is NEW
[winner, k]  = sih.planner.arbitrate(roles);
cmd          = sih.planner.chooseVelocity(winner, vos(k), egoState);
```

`assignRoles` gains a **second output**. It already computes a full `vo` for every track at line 64
and then discards everything except `Beta`, `Lambda` and `TCPA`. Returning what it already built
costs **zero extra arithmetic**, and MATLAB's output rules make it backward compatible — every
existing `roles = assignRoles(...)` caller is untouched.

### Why not Person A's Option 1 — `arbitrate(roles, tracks, egoPos, egoVel)`

It re-does the geometry for the winner, which means it takes **positions**, which means it inherits
the frame contract — and that is the one failure mode this codebase has already been bitten by.
From `assignRoles.m`'s own header:

> *"Passing an S1 ego-frame TrackList together with the real world ego pose is the obvious"* way to
> get it wrong — **and it does not error. It silently returns the wrong role for every agent.**

Every test before 4 September used `egoPos = [0 0], egoYaw = 0`, where the two frames coincide, so
none of them could catch it. **Do not build a second front door into that trap.**

### Why not Option 2 — `arbitrate(egoPos, egoVel, egoYaw, tracks)`

Self-contained and safe, but it recomputes every role the caller has usually just computed. That
creates a second source of truth for a number we log as safety evidence. Cheap in CPU, expensive in
"which one produced the figure in the report".

### Why Option 3 beats both

**`arbitrate(roles)` has no positions in its inputs, so there is no frame to get wrong.** Option 1's
trap cannot exist. Nothing is recomputed, so Option 2's duplication cannot exist. The unsafe thing
is not guarded against — it is made unrepresentable.

**And it is already written.** `NegotiatingStrategy.m` line 141:

```matlab
function h = minBarrierFromRoles(obj)
    if isempty(obj.Roles), h = NaN;
    else, h = min([obj.Roles.Lambda] - [obj.Roles.Beta]); end
end
```

Arbitration is that function, returning the index as well as the value.

---

## The rules `arbitrate` must follow

| Situation | Behaviour |
|---|---|
| **Winner** | smallest `h = Lambda - Beta` — the **tightest** constraint, not the nearest agent |
| **Exact tie** | lowest `TrackID`. S1 guarantees IDs are stable and never reused, so this is deterministic and reproducible across runs |
| **Empty track list** | **no winner**, `h = NaN`. S1 says the list *may be empty and consumers must not error* |
| **Every agent SAFE** | still return the smallest-`h` agent. A SAFE role produces a free-running command in `chooseVelocity` — that is correct, not a special case |
| **`h < 0`** | arbitration does not decide this. `chooseVelocity` reads `vo.h < 0` and raises EMERGENCY (S8 = 2) |

### Three things arbitration must NOT do

**1. It must not read `PYield`.** `plan/S3-PYIELD-RULING.md` is explicit: *"`PYield` ranks; it does
not permit."* Arbitration picks the **binding safety constraint**, which is a safety question, so it
is decided on geometry alone. If you find yourself weighting the winner by `PYield`, stop — that is
outside both rulings.

**2. It must not choose between the two barriers.** `AGENTS.md` section 2: *"Two barriers... **No
mode switch — geometry decides which binds.**"* `h_agent` and `h_road` (S9) must **both** hold.
Arbitration operates only on the agent side. The road barrier is not a competitor in this contest.

**3. It must not pick the nearest agent.** Nearest is not tightest. A close agent moving away has a
large `h`; a distant agent on a collision course has a small one. **The barrier is the criterion,
because the barrier is what we claim as our safety evidence.**

---

## Where it fits in the last day

Person A is right that this is the smallest of her three remaining jobs and the only one blocked on
nobody. **D9 (reversibility) and D10 (turning) both need things from Person B or from S9/S10 that do
not exist**, and S9/S10 are not coming before the internal round.

So: **arbitration, then D10 if there is time, and D9 gets written up rather than half-built.**

---

## Status

**A ruling by Claude at Aditya's instruction, 4 September 2026, not a decision Aditya made
personally.** It touches how the safety number is selected, so he can overturn it — but until he
does, build against it.

`AGENTS.md` section 3 is **not** changed by this file. S4's `Role` struct already carries `TrackID`,
`Role`, `Beta`, `Lambda` and `TCPA`, which is everything arbitration reads. Adding a second output
to `assignRoles` is a function signature, not a contract struct, and `plan/CONTRACT-AB.md` locks
`chooseVelocity`'s signature — not `assignRoles`'.
