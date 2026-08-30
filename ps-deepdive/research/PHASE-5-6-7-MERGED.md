# PHASES 5, 6, 7 — MERGED
**30 Aug 2026. Run together to conserve budget.**

---

# PHASE 5 — THE MEASURING STICK

## The field admits it has no consensus metric
Quoted from the community's own guidelines work:
> "Unlike traditional navigation where the community largely agrees on metrics like
> **Success weighted by Path Length (SPL)**, finding a consensus for social navigation metrics
> is challenging because we care about multiple aspects of human-robot encounters including
> safety and communication of the robot's intent."

**So proposing a metric here is legitimate, not arrogant.** But we must stop claiming "no metric
punishes freezing" — that was wrong and stays wrong.

## What already exists, and what we adopt
- **Principles and Guidelines for Evaluating Social Robot Navigation Algorithms** — arXiv 2306.16740
- **Metrics for Evaluating Social Conformity of Crowd Navigation Algorithms** — arXiv 2202.01045
- **SocNavBench** — simulator + curated scenarios from real pedestrian data + metric suite
- **"Don't Freeze, Don't Crash: Extending the Safe Operating Range of Neural Navigation in
  Dense Crowds"** — arXiv 2603.06729. Our exact framing, published 2026. **Cite it, don't fight it.**
- **Deadlock-free navigation via Discrete-Time Control Barrier Functions in "Social Mini-Games"**
  — arXiv 2308.10966. The term **"social mini-game"** — a small contested-space encounter — is
  exactly our unit of analysis. Borrow the vocabulary.

**The established four categories: Safety, Social Compliance, Efficiency, Comfort.**
Safety = collision count + minimum distance.

## Our metric contribution — narrow and defensible
Not "a new metric because none exist." Instead:
1. **Adopt** the four categories and SPL, which are established.
2. **Add what unstructured traffic needs and nobody measures:**
   - **Yield ledger** — over an episode, how many contested encounters did we win, lose, or
     deadlock? Recorded per agent class (truck / bus / car / auto / bike / pedestrian / animal).
   - **Time-to-enter** — seconds from arriving at a junction to committing. The baseline's
     failure shows up here before it shows up in collisions.
   - **Perception-degradation curve** — planner performance as a function of detection error.
     **Nobody reports this. Every incumbent assumes near-perfect sensing.**
3. Report the **safety-versus-progress Pareto frontier**, not a single operating point.

---

# PHASE 6 — THE IMPORTS

## IMPORT 1 — Maritime COLREGs. This is the strong one.

**The sea has no lanes either.** Shipping solved contested open space with a rulebook that
assigns **roles**, not positional right-of-way:
- **Give-way vessel:** "take early and substantial action to prevent collision"
- **Stand-on vessel:** "maintain its course and speed"
- Three defined situations: **head-on, overtaking, crossing**

And it is already a working planner formalism, not a metaphor:
- *Safe Maritime Autonomous Navigation with COLREGS, Using Velocity Obstacles* (IEEE)
- *VORRT-COLREGs* — arXiv 2109.00862
- *COLREGs-Informed RRT\** ; hybrid ASV avoidance for Rules 8 and 13-17 — arXiv 1907.00198

The mechanism transfers directly:
> "**VOs specify on which side of the obstacle the vehicle will pass** during avoidance
> manoeuvres, so **COLREGS are encoded in the velocity space in a natural way.**"

### Why this is the best idea we have found
It **reframes assertiveness as a duty rather than aggression.** The stand-on vessel's obligation
is to **hold course and speed** — predictability is the safety mechanism, not a risk.

Waymo made its car assertive and drew an NHTSA investigation and an NTSB probe, because the
assertiveness was unprincipled. **A declared role is defensible where "be pushier" is not.**

**Not found: COLREGs-style role assignment aimed at road traffic.** Say "no public work we could
find," never "never been done."

## IMPORT 2 — Movement ecology, for the cow
Published animal-movement models we can lift directly:
- **Correlated Random Walk (CRW)** — successive step orientations are correlated, giving
  "forward persistence": animals keep going rather than turning abruptly.
- **State-switching continuous-time CRW** (Michelot 2019, Methods in Ecology and Evolution) —
  one state for **directed transit**, another for **tortuous local movement**. That is exactly a
  cow crossing a road versus a cow grazing on it.
- **Agent-based cattle models** driven by internal state (hunger, hydration) plus environment.
- Lévy walks for search behaviour.

Combined with the livestock-science finding from Phase 3 — **a horn frightens rural cattle but
has "little effect on cattle accustomed to motorway traffic"** — the cow becomes a two-state
correlated random walk with a **habituation parameter**. Grounded in published ecology, not
invented by us, and it makes the demo memorable.

## Imports considered and rejected
- Cheap talk / costly signalling for the horn — the horn is patented (Motional US11567510B2)
  and shipped for sirens. Keep as a footnote.
- Auction / mechanism design — occupied by GameOpt, and it needs V2I which Indian roads lack.
- Proxemics — occupied by Camara & Fox 2022.

---

# PHASE 7 — THE COMPETITION

## MathWorks runs a webinar for its SIH problem statement. Attend it.
Confirmed: MathWorks has partnered with SIH **since 2019**, "guiding students through problem
statements, webinars, and mentorship." A past winner states plainly:
> "The MathWorks Webinar was helpful for understanding the MathWorks problem statement and
> **what was expected for the grand finale**."

**This is the highest-value, lowest-cost competitive intelligence available. Find the date.**

## Read the two winner write-ups — MathWorks published both
- **Team TwinX, SIH 2025** — "From Real Roads to Real Simulations", MathWorks Student Lounge
  blog, 6 Apr 2026. **Adjacent to our problem statement. Read every word.**
- **Solar Masters, SIH 2024** — Student Lounge, 13 Jun 2025.

These are the judges' own publisher describing what winning looks like. Nothing else we can
read is worth more.

## Field size
SIH 2026: 226 problem statements, 30 organisations, 18 themes.

## What rival teams will build (unchanged from Phase 1, still the read)
Tier A: MathWorks reference examples stitched together, a cow, a swerve.
Tier B: Tier A plus a detector trained on IDD.
Tier C: reinforcement learning that will not be reliable in seven days.
Tier D: beautiful scenes, weak planner — and TwinX already won with the scenes move.

**None of them will demo the crowded market or the signal-less junction, because their car
will sit there. They will not know that is why.**
