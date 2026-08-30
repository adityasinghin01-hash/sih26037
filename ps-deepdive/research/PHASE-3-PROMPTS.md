# PHASE 3 — THE HOSTILE SWEEP
**Goal: find where the incumbents FAIL. That is where our floors go.**
Phase 1 proved every one of our ideas is occupied. Phase 3 asks the only useful follow-up:
what do the occupiers NOT do, and what do they admit they cannot do?

================================================================
## PROMPT A — CONSENSUS  (the limitations of the incumbents)
================================================================
For each paper below, I need the LIMITATIONS and FUTURE WORK sections, quoted directly.
I am not looking for a summary of what they achieved. I want what they admit they cannot do.

1. B-GAP: Behavior-Rich Simulation and Navigation for Autonomous Driving
   (Mavrogiannis, Chandra, Manocha — RA-L / IROS 2022, arXiv 2011.03748)
2. GameOpt / GamePlan (Suriyarachchi, Chandra, Baras, Manocha, 2022) and
   GameOpt+ (2024, arXiv 2405.16430)
3. Unfreezing autonomous vehicles with game theory, proxemics, and trust
   (Camara & Fox, Frontiers in Computer Science, 2022)
4. Deep reinforcement learning for autonomous driving in uncontrolled intersections of
   Indian roads (Multimedia Tools and Applications, Aug 2024)

For each, answer these specific questions:
- What agent types does it handle? Does it include pedestrians? **Animals?**
- Does it assume perfect/ground-truth perception, or does it run from raw sensors?
- Does it require vehicle-to-vehicle communication between agents?
- What simulator was used, and were the other agents scripted or reactive?
- Does it handle non-vehicle obstacles — pushcarts, potholes, parked vehicles?
- What does it explicitly say it does NOT do?

RULES: quote the papers. Link them. If a limitations section does not exist, say so.
Mark each statement [PAPER SAYS] or [MY OPINION].

================================================================
## PROMPT B — PERPLEXITY  (the animals question, hard)
================================================================
I need to know whether animals on roads have ever been treated as BEHAVING AGENTS in
autonomous vehicle research — not merely as obstacles to be detected and avoided.

1. Has any research modelled or predicted the MOTION or BEHAVIOUR of animals (cattle, cows,
   dogs, goats) on roads, for autonomous driving? Not detection — behaviour or trajectory
   prediction, or planning that reasons about how the animal will respond.
2. Is there any work on how animals RESPOND to vehicles — do they react to approach, to
   sound, to a horn? Look in animal behaviour and livestock science as well as robotics.
3. What datasets contain annotated animals on roads, with counts?
4. India-specific: how many road accidents involve stray cattle or animals? Look for MoRTH
   "Road Accidents in India" reports, state government stray cattle data, and news
   investigations. I need a citable number.
5. Are there any commercial products for animal detection on roads — railway, highway, or
   automotive?

RULES: every claim linked. If a question returns nothing, write "NO RESULTS" for it.
Mark each statement [SOURCE SAYS] or [MY OPINION].

================================================================
## PROMPT C — CHATGPT  (audio as an input to driving)
================================================================
Question: has anyone built an autonomous driving system that uses SOUND as an input to
decision-making or planning — not just perception?

Be precise about the boundary between what exists and what does not:

1. Emergency vehicle siren detection in AVs — who does it, is it in production (Waymo,
   Zoox, Cruise, Tesla, Mobileye), and what does the vehicle DO when it hears a siren?
2. Beyond sirens: has any AV used other sounds — horns, shouting, engine noise — as an
   input? Anything in research or patents.
3. Has anyone built a driving policy or planner where an ACOUSTIC observation changes the
   planned trajectory? Name it or say NO RESULTS.
4. Is there research on multimodal audio+vision fusion for driving scene understanding?
   What tasks does it cover, and does any of it reach planning rather than perception?
5. What are the known engineering problems with automotive microphones — wind noise, road
   noise, localising a sound source from a moving vehicle?

RULES: link everything. Distinguish research from shipped product. Distinguish patents from
deployed systems. Say plainly where you find nothing.

================================================================
## PROMPT D — GEMINI DEEP RESEARCH  (the MathWorks toolchain question)
================================================================
Research question: what does MathWorks actually ship for autonomous driving simulation, and
has anyone published work on UNSTRUCTURED or mixed traffic using MATLAB and Simulink?

Deliver:
1. A complete list of the autonomous-driving reference examples shipped in MathWorks'
   Automated Driving Toolbox, Navigation Toolbox and RoadRunner. For each: what scenario it
   covers, and whether it is highway/lane-based or unstructured.
2. Does ANY MathWorks shipped example do the following? Answer each yes/no with the example
   name: (a) unsignalised intersection negotiation, (b) mixed traffic with motorcycles,
   rickshaws or animals, (c) driving without lane markings, (d) a closed loop where the
   PREDICTION of other agents depends on the ego vehicle's own planned trajectory.
3. Does MathWorks ship an implementation of Responsibility-Sensitive Safety (RSS)? What
   does it do and which product is it in?
4. Search academic literature and technical reports for ANY published work implementing
   planning for unstructured, non-lane, or mixed traffic in MATLAB/Simulink. Include Indian
   university theses and conference papers.
5. What metrics does MathWorks itself use in its driving examples, and does it provide any
   built-in metric for scenario completion, progress, or blocking?
6. What has MathWorks published about Smart India Hackathon — webinars, past problem
   statements, winning teams?

RULES: link everything, prefer mathworks.com documentation as primary source. Where you find
nothing, say so explicitly rather than substituting something adjacent.

================================================================
## PROMPT E — GROK  (what is actually shipping, and India's market reality)
================================================================
Search X/Twitter and recent web. Four questions:

1. Do any autonomous vehicle companies in production classify individual surrounding road
   users by behaviour or aggressiveness and change their driving accordingly? Waymo, Zoox,
   Tesla, Mobileye, Wayve, Nuro. What have they said publicly about it?
2. Waymo has publicly described making its vehicle more "assertive". What exactly did they
   change, what did they say about it, and has anyone measured whether it worked? Any
   criticism or incidents attributed to the change?
3. What is the current regulatory position on autonomous vehicles in India — MoRTH policy,
   any statements about testing on public roads, and why Indian AV companies are pivoting to
   ADAS for OEMs instead of robotaxis?
4. Is anyone in the AV industry talking about animals on roads — cattle, deer, wildlife —
   as a planning problem rather than a detection problem?

RULES: link every claim. Separate company marketing from independent reporting. Say clearly
if you find nothing for a question.
