You are helping build the pitch deck for **SIH26037**, our Smart India Hackathon 2026 entry
(MathWorks · Smart Vehicles): *Adaptive Path Planning and Collision Avoidance for Autonomous
Vehicles on Unstructured Indian Roads.* **The KIET internal round is 7 September 2026.**

I own the PPT, the docs and the claim ledger. You are doing this with me, not for me.

## STEP 0 — READ BEFORE YOU WRITE A SINGLE SLIDE

Read these completely, in this order. Do not skim. Tell me in your own words what each one says
before you propose any slide, so I know you actually read them.

1. **`PRD.md`** — the whole thing. This is the master document. Pay special attention to:
   - **§9 "Every claim, and what backs it"** — this is the claim ledger, and it is the single most
     important section in the project for you.
   - **§5 "What the judge sees, start to end"** — this is effectively the deck's skeleton.
   - **§2 "The five scenarios, with honest expectations"** and **"The one deviation, declared"**
   - **§4 "What we are NOT building"**
   - **§8 "How we measure"** and **"The baseline is sacred"**
2. **`TEAM.md`** — who owns what, what nobody may touch, what is blocked on a human.
3. **`README.md`** — how the repo is organised and what the slash commands do.
4. **`plan/E-evidence.md`** — the ten measurements, the three graphs, and the three baselines.
   The deck's results slides come from here.
5. **`notes/READ-FIRST.txt`** in the SIH26037-Reference folder, then the REF docs it indexes
   (REF-01 to REF-10) and the six scenario scripts `S0`–`S5`. **You do not need to memorise these**
   — you need to know what is in them so you can pull a sourced number instead of inventing one.
6. **`renders/map_02_cityplan.png`** — the approved city plan. This is a real place: Najibabad,
   Bijnor district, western UP, pulled from OpenStreetMap.

## THE THREE RULES THAT OVERRIDE EVERYTHING

**RULE 1 — THE CLAIM LEDGER IS LAW.** PRD §9 says it plainly:
> *"If a claim is not in this table, it does not go on a slide, in the report, or in the repo."*

Every claim is in one of three states:
- **VERIFIED** — primary source or measured by us. Safe to put on a slide.
- **NOT YET RUN** — our own number, the run that will produce it is named, and it **does not go on a
  slide until that run has produced it.** M1–M10, the yield predictor's precision and recall, and
  whether OpenTrafficLab even runs on our MATLAB release are all currently in this state.
- **CORRECTED** — things we believed and that turned out to be false. Read these so you never
  reintroduce them. Two live examples: we must **not** say "AIS-189/190 mandate ADAS in India"
  (the real one is **MoRTH GSR 184(E)**, in force 1 Apr 2026), and we must **not** say "no standard
  metric punishes a frozen car" (CARLA does, at 180 simulation seconds — which is about an order of
  magnitude too coarse for us, and *that* is the sentence to use).

**RULE 2 — THE PHRASING RULES, verbatim from PRD §9:**
- Say **"no public work we could find"**. Never "this has never been done."
- Never write "approximately" where a measured value belongs. Write **`TODO(unverified)`** instead,
  and leave it visible on the working slide so it cannot ship by accident.
- **Name the closest competitor and the closest patent on our own slide, before a judge does.**

**RULE 3 — KEEP THE THREE OUTPUTS DISTINCT.** This is in the project's pipeline doc and it is what
stops the deck looking dishonest:
| | What it is | What it is for |
|---|---|---|
| **The numbers** | Hundreds of MATLAB runs, varied conditions, measured | **The proof. This is what wins.** |
| **MATLAB's own view** | Boxes on a plot | Honest, plain, re-runnable by a judge |
| **The Blender film** | *One* of those runs, rendered photoreal | So a human can see it |

**The film is presentation, not evidence.** It is not a screen recording — it is a render of the
identical run, driven by the same position data. If a judge asks "is that the real simulation?",
the answer is: *the plain one is the truth, the beautiful one is the same truth rendered.*
**A slide that blurs these three will lose us the round.**

## WHAT ACTUALLY MAKES THIS ENTRY DIFFERENT

Use these, because they are the defensible ones and every one is VERIFIED in PRD §9:

- **IDD-X has 3,634 scenarios and in every one the car gives way.** The Indian datasets encode
  yielding. We built the thing that negotiates instead.
- **METEOR's own authors measured that models that do well on Waymo fail on METEOR.**
- **5,021,587 stray cattle in India. 3,383 stray-cattle accidents in five years — 919 dead,
  3,017 injured** (Haryana Assembly reply).
- **The competitors, named on our own slide:** B-GAP lists pedestrians, bicycles and intersections
  as future work, needs "very good sensing", and admits it acts conservatively. GameOpt+ assumes
  **V2I communication**. GamePlan was demonstrated with **2–3 vehicles**.
- **At the IIT-Madras hackathon, 47 teams entered and all three winners built detect-and-warn.
  Not one built a planner.**
- **The world is a real place**, not a synthetic test track: 42 km of the real Najibabad road
  network, imported into MATLAB and Blender from the *same* source file so the road the planner
  drives and the road we render are the same numbers by construction.

## THE STRONGEST SLIDE IN THE DECK IS THE ONE WHERE WE SAY WE LOSE

Scenario S4 is the structured highway case. **Ordinary lane-based planners genuinely beat us there,
and we say so on our own slide**, then show that the car detects the road has structure and switches
to lane-following: *"our planner knows when it isn't needed."*

Do not let anyone talk us out of this slide. Three of our hackathon entries have died from shipping
claims that did not survive contact with a judge. Volunteering the weakness before it is found is
the cheapest credibility available.

## HOW TO ACTUALLY BUILD THE DECK

**Use the `document-skills:pptx` skill. Load it first, before writing anything.**
Do **not** hand-write `python-pptx` layout code with guessed inch coordinates. We tried that on a
previous hackathon deck — about 400 lines of it — and the geometry audit passed while the deck
looked bad enough to be thrown out. **A passing bounds check is not the same as a deck that looks
designed.**

If there is a mandated KIET template:
1. **Measure the template's real geometry** from the PDF rather than eyeballing it —
   `pdftotext -bbox` for text positions, and pixel-scan a 300 dpi render for the frame edges.
2. **Sample the template's actual colours** out of the file. Do not guess a palette.
3. Lay everything on **one declared grid**.
4. Watch for this trap: a PDF-page background carries the template's own placeholder text with it.
   **Paint it out of the raster before compositing**, or it bleeds through every gap in the layout.

**Then look at it. Every slide, every time.**
Build → `soffice --convert-to pdf` → `pdftoppm -jpeg` → **open the images and actually read them** →
fix → re-render. **The first render always has real defects. Finding them is the job.**
Never substitute a programmatic audit for looking at the output.

**First, check what this environment has** — do not assume. Run `which soffice libreoffice pdftoppm
pdftotext` and tell me what came back. If LibreOffice is not available in the web sandbox, say so
immediately rather than shipping a deck nobody has looked at; we will render it on a local machine
instead.

## THINGS I WANT YOU TO SET UP WITHOUT ME ASKING

1. **A claim-check command.** Before any slide text is final, check every factual sentence against
   PRD §9. Anything not in the ledger gets flagged, not written. Make this a repeatable command,
   e.g. `.claude/commands/claim-check.md`, so it can be run on the whole deck at once.
2. **A `TODO(unverified)` sweep** that fails loudly if any placeholder survives into a final export.
3. **Speaker notes on every slide**, written for someone else to deliver. Per `TEAM.md` two team
   members are being chosen as the judge-facing presenters, and neither of them wrote the deck.
4. **A one-page "if the judge asks" sheet** — the hostile questions and our honest answers.
   Start with: *"Is that video the real simulation?"*, *"Why not just use RoadRunner?"*,
   *"What is your baseline and did you cripple it?"*, and *"Which of these numbers have you
   actually run?"*
5. **A version log** of what changed between drafts, so we do not silently reintroduce a
   CORRECTED claim.

## WHAT TO ASK ME FOR, RATHER THAN INVENT

- Any M1–M10 result, or the yield predictor's precision and recall — **these have not been run yet.**
- Renders or stills from the Blender world — **the world is still being built.**
- Anything about the five scenarios beyond what the `S0`–`S5` scripts say.
- Whether a number is allowed on a slide, if you cannot find it in PRD §9.

## THE STANDARD

Give me real, defensible statements only. The exact standard on this project is:
**don't put a 9 on a slide if a hostile judge pass gives it a 7.** If a number cannot be backed by
evidence already in hand, research it first — do not estimate and move on. If I ask "why does this
slide say that?", the answer must be a fact with a source, not a feeling.

**Start by reading everything in Step 0 and telling me what you found — including anything in those
documents that contradicts something else, or that you think is wrong.** I would rather hear it now
than from a judge on the 7th.
