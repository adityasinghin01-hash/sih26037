PPT DOCUMENT PACK for the SIH26037 national idea round (6-slide official template, uploaded as PDF, due 30 Sep 2026).
A teammate will feed these documents to her own AI (Gemini) to build the slides. Write FOUR documents, as markdown,
in ONE reply, each starting with a line exactly `=====DOC n: <filename>.md=====`.

Sources you must use (read them): research/PS-SIH26037-verbatim.md, P0-RULES.md (incl. the 27 Sep update at the end),
P1, P2, P13-SYSTEM-DESIGN.md, P14-PS-COMPLIANCE.md, P15-BUILD-PLAN.md, P16-INDIAN-TRAFFIC-NUMBERS.md.
Style reference: an SIH 2025 winning-style deck (team Invariants, AR heritage). Its layout per slide:
S1 title fields (PS ID, title, theme, category, team ID, team name). S2 "Proposed Solution" left column bullets with
bold keywords, a central hub diagram of the product with ~10 feature bubbles, right column "It addresses the problem by",
a small platform strip, and a tagline. S3 "Technical Approach": tech-stack logo wall grouped by layer + prototype link.
S4 "Feasibility and Viability": boxes Financials (cost pie), Feasibility, Viability, Challenges→Mitigation table.
S5 "Impact and Benefits": stakeholder list + big bold numbers. S6 "Research and References": papers, competitor
tick/cross table, industry numbers, prototype link. NO survey (we skip it). Beat that deck on information, numbers,
keywords and rigour, but every number must be SOURCED (that deck's numbers mostly were not — do not copy that habit).

LOCKED CONTENT:
- Child line: "The car watches and listens, guesses what might move, and drives only when it has room to stop."
- Expert line: one Simulink ego stack, Indian-road sensing + prediction, learned manoeuvre scorer, independent
  movement verifier, measured closed-loop tests.
- Hierarchy: 1 idea → 5 layers (SENSE, UNDERSTAND, DECIDE, ACT, PROVE) → 13 parts (Sensors | Perception ML, Hearing,
  Gesture reader, Tracker, Prediction ML | Planner, Safety checker, Safety monitor | Control, Signals & driver screen |
  World, Test & learn loop) → components (see P15 car spec).
- AI stack = 14 models, TWO TIERS. Prototype core (5): object detector (YOLOX), road/pothole mask (DeepLab v3+),
  hand-signal reader (on pretrained pose), motion predictor (top-K, ego-conditioned, conformal), move scorer.
  Full system (+9): lidar 3D detector, BEV free-space/occupancy, sign & Indian-text reader, siren/horn recogniser,
  visibility estimator, driver watcher, crossing-intent model, RL policy (comparison only), learned traffic agents.
  Rule: no AI model can move the car; the physics-based safety checker gives the only "go".
- Datasets: IDD, IDD-3D, IDD-AW, IDD-X, IDD-PeD, DriveIndia, FGVD, TIAND, METEOR, SPT Chennai, RoadText + simulator
  data. Mark licence/access as per research. Gaps: siren audio, driver monitoring, Indian police gestures.
- Compute: KIET DGX A100 for training; cloud A100 rental as backup — price must be SOURCED or written "to confirm".
- Tools: MATLAB/Simulink R2026a (Automated Driving Toolbox, Navigation Toolbox, Stateflow, Deep Learning Toolbox,
  Vehicle Dynamics Blockset, MATLAB Coder), SUMO via official R2026a Simulink blocks, CARLA 0.9.15 (substitute for
  RoadRunner — disclosed), Python/PyTorch → ONNX for training.
- Competitors to compare (tick/cross): our system vs The Syndicate (same PS; stock CARLA, YOLOv11+LiDAR, 3-tier planner,
  3 easy scenes, no numbers), ARAI Indian scenario repository, WMG Safety Pool India, Swaayatt Robots, Minus Zero.
  Only tick what is verified in research; else "?".
- Impact numbers: MoRTH 2023 (4,80,583 crashes, 1,72,890 deaths; pothole 2,161 deaths; wrong-side etc.), Haryana cattle
  crashes, 50 lakh stray cattle — all from research docs with source.
- Honesty: use the P14 claims ledger. Forbidden: "first Indian test suite", "real-time today", "ML drives the car",
  "RoadRunner scenes". Today's state may be described only as P2 allows.
- Keywords: use the PS's exact wording heavily (adaptive path planning, unstructured Indian road conditions,
  multi-sensor camera LiDAR radar, short-term motion prediction, non-lane-based movement, real-time replanning,
  collision-free, informal merging, closed-loop validation, replanning latency, path smoothness, scenario completion
  rate, RoadRunner→CARLA substitution disclosed) plus our system terms.

THE FOUR DOCUMENTS:
DOC 1 `01-SLIDE-BY-SLIDE-BRIEF.md` — for each of the 6 slides: layout (which box where, following the reference), exact
  bullet text (short, bold keywords marked **like this**), which diagram file goes where (D1–D7 below), max words per
  box. Slide 1 leaves team ID/name as placeholders. Add a "Keyword glossary" at the end: every keyword used + one plain
  line meaning (for the team, not the slides).
DOC 2 `02-NUMBERS-AND-CLAIMS.md` — table of every allowed number: number | meaning | source link | slide. Then the
  claims ledger: SAY / SAY ONLY AS PLANNED / NEVER SAY.
DOC 3 `03-REFERENCES.md` — slide-6-ready references grouped (Indian road safety data; Indian traffic behaviour; datasets;
  planning & safety prior art; MathWorks/simulation tools), each "Authors/org, title, venue, year [link]". Only sources
  present in the research docs.
DOC 4 `04-JUDGE-QA.md` — 15 hard questions a MathWorks expert would ask + honest 1–2 line answers.
Diagrams (Claude draws them; just reference by ID): D1 full system (5 layers/13 parts, end-to-end loop), D2 one decision
  step-by-step, D3 14-model AI stack (two tiers), D4 five PS scenarios, D5 10-week build plan, D6 PS coverage/beyond,
  D7 competitor table + cost pie.
Tight, no padding. Plain words in explanations.
