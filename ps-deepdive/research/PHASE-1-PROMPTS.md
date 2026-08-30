# PHASE 1 — PROMPTS FOR EXTERNAL AGENTS
Six prompts, one per agent. Each is self-contained. Paste as-is.
Save each answer as `phase1-<agentname>.md` and send back.

================================================================
## PROMPT A — PERPLEXITY  (fast cited sweep + fact-check)
================================================================
I am researching prior art for a university project: an autonomous vehicle path
planner for chaotic, unstructured Indian roads (no lane markings, mixed traffic of
cars/auto-rickshaws/two-wheelers/pedestrians/cattle, unsignalled intersections).

Fact-check these claims. For each, tell me TRUE, FALSE, or PARTLY TRUE, with links:

1. Rohan Chandra (PhD, University of Maryland, 2022) wrote a thesis titled "Towards
   Autonomous Driving in Dense, Heterogeneous, and Unstructured Traffic."
2. "B-GAP" (RA-L/IROS 2022) classifies surrounding drivers as aggressive or
   conservative and uses that for ego-vehicle navigation in dense traffic.
3. "GameOpt" and "GamePlan" (2022) handle unsignalised intersection negotiation using
   an auction mechanism and prove deadlock-freedom.
4. "METEOR" is an Indian unstructured traffic dataset with annotations for yielding,
   cut-ins, wrong-lane driving and lack of right-of-way at intersections.
5. Camara & Fox published "Unfreezing autonomous vehicles with game theory, proxemics,
   and trust" in Frontiers in Computer Science, 2022.

Then answer:
6. Which companies or research groups anywhere in the world are working on autonomous
   driving specifically for unstructured or disordered traffic? Name them with links.
7. Have Swaayatt Robots or Minus Zero (Indian AV companies) published any technical
   papers, or only demo videos? Give links to anything published.

RULES: every claim needs a working link. If you cannot verify something, say
"UNVERIFIED" rather than guessing. Mark each sentence [SOURCE SAYS] or [MY OPINION].

================================================================
## PROMPT B — GEMINI DEEP RESEARCH  (the long landscape report)
================================================================
Produce a research report on the state of the art in motion planning and decision-making
for autonomous vehicles in DENSE, HETEROGENEOUS, UNSTRUCTURED traffic — meaning roads
with no lane discipline, mixed vehicle types (cars, buses, auto-rickshaws, motorcycles,
bicycles, pedestrians, animals), and unsignalised intersections. India, Southeast Asia,
Africa and Latin America are the relevant contexts.

Cover:
1. The major research groups and labs working on this. Who leads it, where, since when.
2. The main technical approaches, grouped: game-theoretic, reinforcement learning,
   social-force / crowd-dynamics, interaction-aware prediction, optimisation-based.
   For each: what it does well and where it fails.
3. Datasets available for unstructured traffic. Size, annotations, licence, and whether
   they contain interaction or behaviour labels rather than just object boxes.
4. Which simulators are used. Is anyone doing this in MATLAB/Simulink, or is it all
   CARLA / SUMO / custom Python?
5. What the field states as OPEN PROBLEMS. Quote the "future work" and "limitations"
   sections of the most-cited papers.
6. Anything involving animals or livestock on roads in AV planning.

Search terms to use: "dense heterogeneous traffic", "unstructured traffic navigation",
"disordered traffic", "mixed traffic", "behavior-aware navigation", "interaction-aware
motion planning", "unsignalized intersection", "freezing robot problem",
"socially compliant navigation", "Indian traffic autonomous driving".

RULES: every claim linked. State plainly where you found nothing. Separate what papers
say from your own interpretation.

================================================================
## PROMPT C — CONSENSUS / GOOGLE SCHOLAR  (academic depth + newest work)
================================================================
Academic literature search. Topic: motion planning and decision-making for autonomous
vehicles in dense, heterogeneous, unstructured traffic (no lanes, mixed vehicle types,
unsignalised intersections), especially India.

Do three things:

1. Find the 10 most-cited papers in this area. Title, authors, year, venue, citations, link.

2. CITATION CHASE — this is the important one. For each of these four papers, list the
   NEWER papers that cite them and extend them, from 2024, 2025 and 2026:
   - TraPHic (CVPR 2019)
   - B-GAP (RA-L 2022)
   - GameOpt / GamePlan (2022)
   - Trautman & Krause, "Unfreezing the Robot" (2010)
   I want to know what the newest state of the art is, not the 2019 state of the art.

3. Search specifically for any paper that does ALL of these together:
   (a) unstructured / non-lane traffic, (b) an EGO-VEHICLE planner (not just prediction
   or traffic simulation), (c) evaluated in simulation with published metrics.
   If none exists, say so explicitly.

RULES: paper links required. If a search returns nothing, write "NO RESULTS" for that
search rather than substituting something loosely related.

================================================================
## PROMPT D — GROK  (real-time, X/Twitter, industry chatter)
================================================================
Search X/Twitter and the recent web. Three questions:

1. What are people in the self-driving industry saying, in the last 18 months, about
   autonomous vehicles being too cautious, hesitating, freezing, or getting stuck?
   Any videos of Waymo/Zoox/Tesla cars frozen at junctions? Any data on how often it
   happens? Any statements from those companies about "assertiveness"?

2. What is the current state of Indian autonomous driving companies — Swaayatt Robots,
   Minus Zero, Hi-Tech Robotic Systemz, Flux Auto, Ati Motors? Recent demos, funding,
   technical claims, criticism. Have any published technical detail?

3. Is anyone — researcher, company or hobbyist — working on autonomous driving that
   uses the horn, headlight flashes, or gestures to negotiate with other road users?
   Anything about self-driving cars honking.

RULES: link every claim. Distinguish a company's own marketing from independent
reporting. Say clearly if you find nothing for a question.

================================================================
## PROMPT E — REDDIT  (practitioner reality check)
================================================================
Search Reddit — r/SelfDrivingCars, r/MachineLearning, r/robotics, r/india, r/CarsIndia,
r/developersIndia — and report what actual practitioners say, with links to threads.

1. What do people say about self-driving cars being too hesitant, freezing, or getting
   stuck at intersections? Real experiences with Waymo/Cruise/Zoox.
2. What do people say about whether self-driving could ever work on Indian roads?
   Look for informed comments, not jokes. What specific obstacles do they name?
3. Is there discussion of the horn as communication in Indian traffic, or of how
   Indian drivers negotiate without traffic rules?
4. Any discussion of the research approaches — game theory, social force models,
   reinforcement learning — actually working in the real world versus only in papers?

RULES: link threads. Quote directly. Distinguish informed comments (someone who clearly
works in the field) from casual opinion. This is for understanding what fails in
practice, not for citations in a paper.

================================================================
## PROMPT F — GITHUB SEARCH  (what code already exists)
================================================================
Search GitHub. I need to know what working code exists that I could build on.

1. Find repositories implementing planning or navigation for dense/unstructured/
   heterogeneous traffic. Include: B-GAP, TrackNPred/TraPHic, GameOpt, Frozone,
   SocialGym, and anything similar. For each: link, stars, last commit date, licence,
   language, and whether it looks runnable.

2. CRITICAL QUESTION: is there ANY repository doing autonomous driving path planning
   for unstructured or Indian traffic in **MATLAB or Simulink**? Search "MATLAB
   autonomous driving India", "Simulink path planning unstructured", "RoadRunner
   Indian road scenario". I strongly suspect the answer is no — please confirm or
   refute it.

3. Any repositories using the Indian Driving Dataset (IDD), IDD-X, or METEOR? What do
   they do with it?

4. Any repository that simulates animals, cattle or livestock as road agents?

RULES: give repo links, star counts and last-commit dates. Dead repos are still useful
information — mark them dead. Say clearly if a search returns nothing.
