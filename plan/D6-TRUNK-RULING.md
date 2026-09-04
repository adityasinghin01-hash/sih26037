# D6 — what "the trunk" means. Ruling, 4 September 2026.

**For Person A. You asked whether the trunk is (a) the longest collision-free stretch under both
futures, or (b) the longest stretch after which a safe continuation still exists under both
futures.**

**The answer is (b). Build (a) first anyway.** Both of those are true and the order matters.

You also spotted that `D-planner.md` reads like (a). You were right — that wording was loose, not a
decision, and it has been corrected in the same commit as this file.

---

## Why (b), and it is not because it is the textbook form

The decisive argument is that **`plan/` already requires (b) somewhere else and did not notice.**

`D-planner.md` D9 says: *"Point of no return — after it, set `Committed` and stop re-deciding."*

Now put an (a)-trunk underneath that. (a) gives you the longest stretch with no collision **on it**.
A stretch can be perfectly collision-free and still end in a state where every continuation
collides — an inevitable-collision state. So (a) plus `Committed` means:

> **the planner can commit, irrevocably, to a trajectory that has already lost.**

That is not a subtle failure mode. That is the crash, and we would have built it deliberately.

### Two more, both about what we are allowed to claim

**The barrier argument does not survive (a).** `ReadThis.md` §4 calls `h = lambda - beta` "a
recognised safety proof". What a barrier function actually guarantees is **forward invariance** —
that a safe control still exists at every future step. That is (b), definitionally. If we build (a)
and claim barrier-style safety, the first judge who knows the field takes the whole safety story
apart, and the safety story is the project.

**The probe stops meaning anything.** "The trunk IS the probe" only works if we can still back out
when the answer comes back wrong. Under (a) the car can creep into a spot where, if the other
driver asserts, there is no out. That is not asking a question. That is committing and hoping.

---

## You do NOT need a second round of path generation

You estimated (b) as needing a fresh generation pass from the end of the trunk. That is the
expensive version and we do not need it. **A terminal constraint buys the guarantee for a fraction
of the cost:**

> **The trunk must end in a state from which the ego can brake to a full stop inside the space that
> is free under both futures.**

Braking to a stop is **one known control action**. So you check **one continuation per candidate**,
not a new tree:

1. generate candidates with `trajectoryGeneratorFrenet` as planned
2. roll each under both futures, weighted by `PYield` (S3)
3. `dynamicCapsuleList`-check the candidate body — this is (a)
4. **`dynamicCapsuleList`-check a braking-to-stop segment appended at the end** — this is what makes
   it (b)
5. keep the longest shared prefix where **both** hold. That is the trunk.

Step 4 is the whole difference. It is one extra collision check per candidate.

### It is already how this project thinks

The speed law you are implementing in D8 is

```
v_max = min( sqrt(aLat*R), sqrt(2*aBrake*(VisibleRange - v*tReact)), vRoute )
```

That middle term **is a stopping-distance constraint** — never go faster than you can stop in what
you can see. The terminal condition above is the same idea applied at the **end of the trunk**
instead of at the current state. Same mechanism, no second concept, and nothing a judge has to be
taught twice.

**What this gives you, stated precisely:** recursive feasibility *with respect to the stop
fallback*. At every step you can either continue the plan or execute the stop, and the stop is
known-safe under both futures. A full second generation round would buy a *less conservative* (b) —
more trunk, same guarantee. That is a later optimisation, not a thing that ships on the 7th.

---

## Ship (a) first. Two guard rails, both cheap.

Your instinct to get the loop closed first is right and I would do the same. Two conditions:

**1. Name it honestly.** `trunkCollisionFree` now, `trunkRecursivelyFeasible` when step 4 lands — or
one `TrunkMode` field written into `results/<run>/config.json`. So that nobody, including us in
three weeks, reads (b)'s guarantee off (a)'s implementation.

**2. Do not wire `Committed` to an (a)-trunk.** This is the one combination that is actively
dangerous, for the reason at the top of this file. Until the terminal check exists, `Committed`
stays false and D9 waits. That is not a delay — D9's whole subject is *"if this goes wrong, can I
get out?"*, which is (b) restated. D9 was always going to need this.

---

## A fact worth having: the shipped baseline does (a)

`matlab/baseline/` now holds MathWorks' *Motion Planning in Urban Environments Using Dynamic
Occupancy Grid Map*. Reading it (never editing it), `HelperDynamicMapValidator.m` line 430 carries
their own comment:

> *"A trajectories is collision free if each point is collision free"*

`isTrajectoryValid` does per-point collision checking over a 2-second horizon. **No terminal set, no
recursive feasibility.** That is (a).

**Two things follow.**

Your (a) is **legitimate engineering, not a shortcut** — it is exactly what the shipped competitor
does, and you are in good company for as long as it takes to get the loop closed.

And **(b) becomes a real differentiator rather than a framing**:

> The shipped planner checks that the path is clear.
> Ours checks that the path leaves us somewhere we can still stop.

That is a defensible technical contribution, it is one line in a deck, and it costs one extra
collision check per candidate. **Do not let it get lost when the demo is being assembled.**

---

## Your other two questions

### Head-on steering — yes, LEFT. Settled.

*Rules of the Road Regulations, 1989*, **reg. 2**: a driver shall drive *"as close to the left side
of the road as may be expedient and shall allow all traffic which is proceeding in the opposite
direction to pass on his right hand side."* Oncoming passes on our right, so we go left. Your
default was correct and it is now cited in `chooseVelocity.m`'s header.

**COLREGs Rule 14 says the opposite** — alter to starboard, pass port to port, which is a keep-right
convention. Importing it literally would have steered us into oncoming traffic.

**Crossing needs no such correction.** COLREGs Rule 15 (give way to starboard) and RRR **reg. 9**
(at an unregulated intersection, give way to *"traffic approaching the intersection on his right
hand"*) give the **same answer** — which is why `assignRoles` can keep the maritime sectors
unchanged. The maritime analogy holds everywhere except head-on, and now we can say exactly why.

### `testFeatureParity` — not yours. Do not open it.

Confirmed Stream C's. It is an empty-input shape disagreement: `buildFeatureFrame.m` returns
`[0 31]`, the Python fixture expects `[0 0]`. Captured verbatim in `HANDOFF.md` and routed to them.
**Leave it alone** — it is the wrong side of the contract, and two people fixing one thing is how we
end up not knowing which version the demo used.

---

## Your third point was the sharpest thing in the message

> *"that date sets your finish, not your typing"*

You are right, and **Aditya still owes you that date.** S9 (`DrivableSpace`) and S10 (`Route`) come
from the World, which is his.

**But do not wait for it, and the contract is precisely why not.**

S9 and S10 are **frozen** in `AGENTS.md` section 3. You can write D8, D9 and D10 against hand-made
structs **today** — a `DrivableSpace` with `EdgeSide = 2` and a `VisibleRange` you set by hand, a
`Route` with a `GoalHeading` you choose. That is exactly what Person B was told to do with stubs,
and for the same reason: **when the real thing arrives it drops into a slot that already works.**

**D8 needs nothing from anyone.** `h_road = EdgeDistance - dMin(side, v)` and the three-term `v_max`
are pure functions of numbers in a struct. Unit-testable in seconds, no scenario, no Simulink, no
World. If you want something to do while the date is outstanding, D8 is it.

**So the honest version of your point is:** that date decides when D8–D10 can be **validated**, not
when they can be **built**. Only the first is on the critical path. Build now, validate when the
World lands.

---

## Summary

| | |
|---|---|
| **Trunk definition** | **(b)** — longest prefix after which a safe continuation exists under both futures |
| **How to get (b) cheaply** | terminal constraint: trunk must end where a braking-to-stop is collision-free under both futures. One extra check per candidate |
| **Build order** | (a) first to close the loop, then add the terminal check |
| **Hard rule while on (a)** | **`Committed` stays false.** Never commit irrevocably to an (a)-trunk |
| **Naming** | say which one you built, in the code and in `config.json` |
| **Head-on** | LEFT, RRR 1989 reg. 2. Settled |
| **`testFeatureParity`** | Stream C's. Do not open |
| **S9/S10 date** | outstanding from Aditya — build against stubs meanwhile, start with D8 |
