# P0 — The rules of the round (SIH 2026, SIH26037)

Status: FINAL. Claude and Codex agree; every source has been opened by Claude.
Rule: each line is either **VERIFIED** (the source has been opened) or **UNVERIFIED** (flagged).

## 1. The problem statement
- The full official text is saved in `PS-SIH26037-verbatim.md`.
  Source: https://www.sih.gov.in/sih2026PS. **VERIFIED**
- Organisation MathWorks · Category Software · Theme Smart Vehicles. **VERIFIED**
- **Competition size: 125 of 500 idea slots already filled on SIH26037 (26 Sep 2026).** **VERIFIED** (same page)
  - For comparison: nearby problem statements show 21 to 500 of 500.
    Our statement is mid-crowded, not empty.

### What the problem statement MANDATES (the checklist every document must meet)
1. A simulation pipeline in MATLAB and Simulink that joins up: perception → prediction →
   path planning → decision logic → vehicle motion.
2. Sensing with multiple sensors, for example camera, LiDAR and radar.
3. Identifying auto-rickshaws, pushcarts, pedestrians and animals.
4. Predicting the short-term motion of other road users, including movement that ignores
   lanes and moves irregularly.
5. A safe, collision-free path that can be replanned in real time.
6. Handling: missing lane markings, informal merging, sudden pedestrian movement, and
   unexpected obstacles.
7. **At least 5 scenarios:**
   - an unmarked village road
   - an unsignalled urban intersection
   - a highway merge with slow vehicles
   - a dense market
   - a sudden cattle crossing
8. **At least 2 detailed RoadRunner scenes** (village road and urban intersection).
9. Metrics: **replanning latency, path smoothness, scenario completion rate**.
10. Deliverables:
    - simulation model
    - scenarios
    - results
    - short technical report
    - demo video
    - **closed-loop validation** in mixed traffic

Tools it encourages (not required): RoadRunner, Automated Driving Toolbox, Navigation Toolbox,
Stateflow, Vehicle Dynamics Blockset or a bicycle model, Deep Learning Toolbox.
Datasets allowed: MathWorks built-in datasets, RoadRunner samples, synthetic data, IDD,
Mendeley, and "publicly available Indian datasets" (this covers METEOR).

## 2. Timeline and process
- **Idea submission deadline: 30 September 2026.** **VERIFIED**
  (on every problem-statement card on sih.gov.in)
- The college SPOC logs in and submits for nominated teams. **VERIFIED** (sih.gov.in/faqs)
- The idea screening is **online**. The Grand Finale is **offline**. **VERIFIED** (faqs)
- Each team may submit at most 2 ideas. **VERIFIED** (faqs)
- **What the team leader uploads** (SIH 2026 guidelines, MoE Innovation Cell, p.10):
  - idea title
  - idea description
  - **idea presentation as a PDF** (not PPTX)
  No video field is listed there. Secondary guides claim a video is also uploaded; **check the
  portal with the SPOC.**
  Source: https://sih-uit.vercel.app/assets/sih-2026-guidelines.pdf
  (a college-hosted copy; its "15 Sep" deadline is stale, and the live 30 Sep deadline wins).
- **Only 4–5 teams per problem statement are selected for the finale.** MathWorks is also
  **not obliged to declare a winner** if no proposal meets its expectations. (Same guidelines,
  p.11.) With 125+ ideas already submitted, **only about 3–4% get through.**
- The Grand Finale is offline at nodal centres, **proposed for December 2026** (p.13). The exact
  shortlist date is **UNVERIFIED**.

## 3. The PPT template
- Official template (`05-ASSETS/SIH2026-IDEA-Presentation-Format.pptx`): **maximum 6 slides
  including the title slide**, which are:
  1. Title
  2. Idea
  3. Technical approach
  4. Feasibility
  5. Impact
  6. Research and references
- Template instructions: points, not paragraphs · diagrams and pictures · "idea should be unique
  and novel" · the idea pointers must not be changed. **VERIFIED** (the file itself)
- Warning: some third-party guides say "max 10 slides". **This is wrong; follow the template.**

## 4. How ideas are judged
- **Official criteria** (SIH 2026 guidelines, p.13; same list in SIH's own 2024 SPOC guidance), judged by "experts":
  - novelty
  - complexity
  - clarity and detail in the prescribed format
  - feasibility and practicability
  - sustainability
  - scale of impact
  - user experience
  - potential for future work
- One secondary guide gives weights: problem understanding 20 · innovation 25 · feasibility 20 ·
  impact 20 · presentation 15. **UNVERIFIED, no official source.**
- Secondary claim: evaluators spend about 2–3 minutes per PPT, and the PPT is judged alone with
  no presenter. **UNVERIFIED.** Treat it as a design constraint anyway: the slides must be
  readable in 2 minutes without anyone explaining them.

## 5. AI or keyword screening
- **No evidence found that SIH uses AI or keyword matching** to screen PPTs. Every source
  describes human evaluators. **This is an absence of evidence, not proof.**
- There is no official free scoring tool.
- A practice scorer we can run for free: upload the PS text, the template and our PDF to any
  LLM (e.g. ChatGPT Free, which accepts PDF/PPTX:
  https://help.openai.com/en/articles/8983675-what-types-of-files-are-supported).
  Ask it to score each official criterion with slide evidence and to flag missing PS
  requirements. **This does not predict SIH's decision.**
- What we can do ourselves: run the finished deck through an LLM against the problem statement's
  own wording plus the criteria in §4, and check coverage. This is the test we control.

## 6. MathWorks history
- **SIH 2025 MathWorks winner: Team TwinX** (K.K. Wagh, Nashik), on a **different** problem
  statement: a road-network digital-twin generator.
  - Pipeline: OpenStreetMap → auto-populated vehicles, behaviours and Indian assets (potholes,
    barricades) → export to Driving Scenario Designer, RoadRunner and Simulink.
  - What won it, in their words: a real gap (tools assume orderly roads), one end-to-end platform,
    and iterating on judges' feedback during the 36-hour finale.
  - Source: https://blogs.mathworks.com/student-lounge/2026/04/06/from-real-roads-to-real-simulations-how-team-twinx-won-smart-india-hackathon-2025/ **VERIFIED**
- **What this means for us:** TwinX built the road; we build the driver. MathWorks visibly values
  an **end-to-end MATLAB workflow** and **real Indian conditions**.

## Open items
- Official evaluation rubric
- Whether the video upload is an official field
- Shortlist and finale dates

## Update 27 Sep 2026 — "AI/Hugging Face keyword screener" rumour re-checked (Claude)
- A rumour (via Aditya) says SIH idea PPTs are scored by a Hugging Face model that matches keywords. **No evidence found** (7 searches: official pages, guides, Reddit, LinkedIn, HF Spaces).
- **Strongest counter-evidence:** an SIH 2025 grand-finale idea evaluator (Ashutosh Pandey, LinkedIn post) wrote after evaluating his batch: "I do wish SIH adopted some kind of automated checks/AI based evaluation to help with the high workload." That implies human evaluation in 2025. https://www.linkedin.com/posts/ashupdsce_smartindiahackathon-evaluator-evaluation-activity-7393303113408905216-q6D5
- The same evaluator's complaints: AI-generated content, illegible slides, no rigour, no metrics.
- Decision: optimise for BOTH anyway — use the PS's exact keywords (helps human skimming and any matcher), and run our own keyword-coverage + LLM rubric check on the final PDF.
