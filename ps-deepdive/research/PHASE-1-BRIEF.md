# RESEARCH PHASE 1 — Find the foundation

## What we are building
A simulated self-driving car for chaotic Indian roads (no lane markings, mixed
cars/autos/bikes/pedestrians/cattle, no traffic signals). Our angle: a car that
only gives way never moves in that traffic, so ours negotiates — it treats each
road user differently depending on whether that road user will react to us.

## The single question for this phase
Who has ALREADY built a planner or navigation system for dense, disorderly,
mixed traffic of this kind — especially using Indian data? Rank the five
closest pieces of work.

We are NOT trying to prove nobody did it. We WANT to find the strongest existing
work so we can build on top of it. Finding a strong match is a success, not a
failure.

## Search in these words (this is important)
Our own phrasing returns nothing. Use the field's phrasing:

- "dense heterogeneous traffic" / "unstructured traffic" / "disordered traffic"
- "mixed traffic navigation" / "non-lane-based traffic"
- "behavior-aware navigation" / "driver behavior aware planning"
- "interaction-aware motion planning"
- "social value orientation autonomous driving"
- "game-theoretic planning autonomous driving"
- "freezing robot problem" / "frozen robot problem"
- "socially compliant navigation" / "social navigation dense crowds"
- "unsignalized intersection negotiation autonomous vehicle"
- "Indian traffic trajectory prediction"

Search Google Scholar, arXiv, IEEE Xplore, Semantic Scholar, GitHub, YouTube.

## Named leads to check FIRST
These are from my memory and may be misremembered. Verify each one exists
before reporting it, and correct me if the name or claim is wrong.

- Rohan Chandra (University of Virginia) and Dinesh Manocha (University of Maryland)
- Work possibly called: TraPHic, METEOR, B-GAP, GraphRQI
- Trautman & Krause, "Unfreezing the robot" (around 2010)
- Sadigh et al., "Planning for autonomous cars that leverage effects on human actions" (around 2016)
- Schwarting et al., social value orientation, PNAS (around 2019)
- Fisac et al., hierarchical game-theoretic planning
- Indian companies: Swaayatt Robots (Bhopal), Minus Zero (Bengaluru) — what have
  they actually PUBLISHED, as opposed to demonstrated in videos?

## What to return

For each of the top 5, in a table:
| Name | Authors + year + link | What it actually does, in plain English | Did it use Indian data? | What it does NOT do |

Then answer these four directly:

1. Does India-specific planning research for chaotic traffic exist? Yes or no.
   If yes, who owns that space and how much have they published?
2. Which single piece of work is the closest to our idea?
3. What is the strongest thing we could BUILD ON TOP OF, rather than compete with?
4. Name three things none of the top 5 do. Be specific, not vague.

## Rules
- Every claim needs a working link. No link = do not report it.
- If you find nothing for a search term, say so explicitly.
- Mark each sentence as either [PAPER SAYS] or [MY OPINION].
- Do not pad. A short honest answer beats a long confident one.
