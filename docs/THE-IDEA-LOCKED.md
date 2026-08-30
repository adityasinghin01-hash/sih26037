# The idea — locked

**Phase 3, 30 August 2026.** Supersedes `ps-deepdive/THE-IDEA.md` where they differ.
Every claim traces to `docs/CLAIM-LEDGER.md`. Nothing in this document is unverified.

## One line

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

## The problem

Every autonomous vehicle has the same safe default: **when uncertain, stop.** At an unsignalled
Indian junction nobody has priority, so the car is always uncertain. It stops, and never goes.
That is not safety — it is a blocked road.

The evidence we did not have to generate: **India's own driving-decision dataset contains 3,634
recorded decisions, and every single one is the car giving way.** There is no recorded example of
going first. Even the data only knows how to be defensive.

## What we build

| # | Thing | Why it is not obvious |
|---|---|---|
| 1 | **Delete the TrafficController** | OpenTrafficLab resolves junctions with a central authority. A signal is a controller. We remove the object and let each agent decide from geometry alone — no broadcast, no shared channel. It is one method: `getNextNodeState()` |
| 2 | **COLREGs roles, imported from shipping** | The sea has no lanes either. Give-way acts early and substantially; **stand-on holds course and speed.** Predictability is the safety mechanism — Waymo made its car assertive and drew an NHTSA investigation. A declared role is defensible; "pushier" is not |
| 3 | **A learned yield predictor** | Predicts a *decision*, not a trajectory, and takes the ego's candidate action as input — which is what actually closes the loop. Kept in the image plane, which sidesteps monocular depth entirely |
| 4 | **A cow with an internal state** | Two-state correlated random walk with measured parameters, plus a habituation scalar. A parameter means a curve, not an anecdote |
| 5 | **Evidence, not a demo** | The car we beat is MathWorks' shipped planner, unmodified. Not one video — three curves |

## The two technical results worth stating on their own

**Project down, never lift up.** The instinct is to lift METEOR into 3-D to match the simulator.
That needs monocular depth, and 1° of camera pitch error is ~31% depth error at 30 m. So we go the
other way: the simulator's exact 3-D is projected *into* the image plane, where METEOR already
lives. Downward projection is arithmetic; upward lifting is ill-posed.

**The negotiation geometry is the safety proof.** The velocity obstacle gives
`h = λ − β ≥ 0` as its safety condition — and that is already a control barrier function. We do not
bolt a safety filter onto the planner. The planner is written in the filter's own variable.

## Why it matters now, stated correctly

**MoRTH notification GSR 184(E) mandates a full ADAS suite for buses and trucks — in force since
1 April 2026.** One of the five required standards, **AIS-188, is lane departure warning**: a
lane-based standard being applied to roads that frequently have no lanes.

Every such system is currently validated against Western scenarios, and METEOR's authors measured
that models working on Waymo data fail on Indian data.

## Positioning

**Not** "a self-driving car for India" — India legally requires a driver in effective control.
**Instead:** *the missing test suite for ADAS on Indian roads — released open, with a planner that
proves it works.*

Users are **ARAI and ICAT**, who homologate every vehicle sold in India, and validation teams at
Bosch India, Continental, Tata Elxsi and KPIT.

**Consequence: we release publicly.** Scenarios, metrics, baseline, results. A benchmark is a
citable contribution; a private demo is not. It costs nothing and it is what raises novelty.

## What we say before a judge says it

| They ask | We answer |
|---|---|
| "You didn't invent this" | Correct. We took the best published methods — none of which exist in the toolchain MathWorks asked for — and built the first working closed-loop implementation in MATLAB on Indian scenes with an honest baseline |
| "Where are the RoadRunner scenes?" | We do not have a licence. Our scenes are built programmatically from real Meerut geometry via OpenStreetMap and **exported as OpenDRIVE** — they import into RoadRunner the day a licence arrives |
| "Is your perception real?" | In-loop is lidar, because the cuboid environment produces point clouds and no pixels. Camera perception is trained on IDD and benchmarked offline. We report both separately, **and we report how the planner degrades when perception is wrong** |
| "Isn't this Swaayatt?" | They build a proprietary vehicle. We build the reproducible, open, measurable test framework — and we publish our numbers |
| "Didn't TwinX already do this?" | They built the scenario *generator*. **Their output is our input.** Nothing in their pipeline decides anything |

## Scope — settled

**Two scenarios perfect**, not five rough: the unsignalled junction and the cattle crossing.

**We do not claim a win on the highway merge.** With proper lanes, lane-based methods are better
suited. The planner detects road structure and switches mode. *"Our planner knows when it isn't
needed."* A weakness converted into evidence of judgement.

## The five open risks, ranked

1. **OpenTrafficLab's `DrivingStrategy` was tested on MATLAB 2020b only**, per its own header. Our
   licence is R2024b+. It is the foundation of everything. Fallback documented in
   `docs/OPENTRAFFICLAB.md` — two days if it fires
2. **Lidar returns off a custom mesh** — `check02`, unrun. Fallback: object lists in the loop
3. **METEOR's ego-vs-agent labelling** — undecidable from public artifacts. Decides what our model
   means. Both answers are survivable by design
4. Supercomputer disk, internet and booking — unanswered
5. METEOR is 93.4 GB and its official page is dead; only the HuggingFace mirror lives
