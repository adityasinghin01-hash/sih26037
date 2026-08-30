# PHASE 2 — DATASET TRUTH
**The question: what do the Indian driving datasets ACTUALLY contain, can we actually get
them, and what does our own Meerut footage add that none of them have?**

Why this phase matters: Phase 1 killed our algorithmic novelty. What is left is
integration, Indian grounding, and evidence. All three depend on data we can actually
obtain and actually use. Three specific things must be settled:

1. Does IDD-X contain per-agent REACTIVITY, or only explanations of the EGO's own action?
   (We were about to build on an assumption here. Verify before any code is written.)
2. Is METEOR downloadable, and does it really annotate yielding and right-of-way?
   It looked closer to what we need than IDD-X.
3. **Does ANY Indian driving dataset include AUDIO?** If none do, our phone footage with
   sound may be genuinely unique data — the horn is central to Indian negotiation and no
   dataset appears to capture it. This is the single most interesting question in Phase 2.

================================================================
## PROMPT A — PERPLEXITY  (availability, licence, mechanics)
================================================================
I need hard facts about obtaining driving datasets for unstructured Indian traffic.
For EACH dataset below, tell me: (a) is it publicly downloadable today, (b) exact download
URL, (c) does it require registration or an email request, (d) licence and whether academic
/ student competition use is allowed, (e) total size in GB, (f) what sensors and annotations
it contains.

1. METEOR (dense, heterogeneous, unstructured traffic dataset with rare behaviors)
2. IDD-X (Indian Driving Dataset - eXplanations)
3. IDD-3D
4. IDD Multimodal
5. IDD Detection / IDD Segmentation / IDD Lite
6. TRAF (from the TraPHic paper)
7. HID (dense heterogeneous unsignalized intersection dataset, Zhang et al. 2024)
8. DATS_2022 (Indian dataset for object detection in unstructured traffic)

Then answer directly:
9. Do ANY of these datasets include AUDIO or sound recordings? Which ones, if any?
10. Do any of them label the OUTCOME of an interaction — e.g. "vehicle A yielded to
    vehicle B", "the ego vehicle was blocked for N seconds", "a deadlock occurred"?

RULES: working links required. If a dataset is dead, gated, or the link 404s, say so
plainly. Mark each statement [SOURCE SAYS] or [MY OPINION].

================================================================
## PROMPT B — CONSENSUS / SCHOLAR  (read the actual annotation schemas)
================================================================
I need the exact ANNOTATION SCHEMA of several driving datasets, taken from their papers,
not from marketing pages. For each, list every annotation field / label category, quoted
from the paper where possible.

1. **IDD-X** — it is described as having "19 explanation categories". List all 19 exactly.
   Then answer precisely: do these labels describe (a) why the EGO vehicle acted, or
   (b) how OTHER agents behaved/reacted? This distinction decides our whole design.
2. **METEOR** — list every annotated behaviour category. Confirm or deny that it labels
   yielding, cut-ins, overtaking, wrong-lane driving, and lack of right-of-way at
   intersections. How many clips, frames, boxes? Which city/cities in India?
3. **TRAF** (TraPHic, CVPR 2019) — size, agent categories, what interactions are labelled.
4. **HID** (Zhang et al. 2024) — what is in it, and is it public?
5. **IDD-Multimodal** — confirm whether it includes GPS and OBD data, at what frequency,
   and whether ego SPEED is directly recoverable.

Then answer: does ANY published driving dataset, anywhere in the world, annotate
NEGOTIATION — meaning a labelled interaction where two agents contest the same space and
one gives way? Name it, or write NO RESULTS.

RULES: quote the papers. Link everything. NO RESULTS is a valid and useful answer.

================================================================
## PROMPT C — GEMINI DEEP RESEARCH  (the comparison + the gap)
================================================================
Produce a comparison report of driving datasets for UNSTRUCTURED traffic (no lane
discipline, mixed vehicle types including auto-rickshaws, two-wheelers, pushcarts,
animals). Focus on India but include Southeast Asia, Africa and Latin America.

Deliver:
1. A comparison table: dataset name, year, country, size, sensors, number of annotated
   frames, annotation types, licence, download availability.
2. Which datasets contain BEHAVIOUR or INTERACTION labels rather than only object boxes
   and segmentation masks?
3. Which contain ego-vehicle trajectory or ego telemetry (speed, GPS, steering)?
4. **Which, if any, contain audio?** Search specifically for driving datasets with sound,
   horn detection datasets, and traffic audio datasets for India.
5. Which contain ANIMALS as an annotated class, and how many instances?
6. What do the dataset papers themselves state as their LIMITATIONS and what they do
   NOT capture? Quote the limitations sections.
7. What kind of data does the field say is still MISSING for unstructured traffic research?

RULES: link everything. Where you find nothing, say so explicitly rather than
substituting something adjacent.

================================================================
## PROMPT D — GROK  (the audio / horn data question)
================================================================
Three questions, search X/Twitter and the recent web:

1. Does any public dataset contain recordings of Indian road traffic AUDIO — horns,
   engine noise, street sound? Look for horn-detection datasets, traffic noise datasets,
   Indian city sound datasets, and noise-pollution monitoring projects.
2. Is anyone doing research on horn detection, horn classification, or using vehicle
   audio as an input to driving systems? Anywhere in the world.
3. Are there any Indian government or municipal projects measuring traffic noise or
   honking — for example noise-pollution monitoring in Delhi or Mumbai? What data do
   they publish?

RULES: links for everything. Say clearly if a question returns nothing.

================================================================
## PROMPT E — GITHUB  (paste these into github.com/search, Repositories tab)
================================================================
Run each search and report: repo name, link, stars, last commit, what it does.

    METEOR traffic dataset
    IDD-X indian driving
    trajectory prediction indian traffic
    horn detection audio
    traffic sound classification
    vehicle audio detection deep learning
    driving dataset audio

Question to answer: has anyone built anything that uses SOUND from traffic as an input
to a driving or traffic system? Confirm or refute.
