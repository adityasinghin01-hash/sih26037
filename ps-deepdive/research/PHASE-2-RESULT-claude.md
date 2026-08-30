# PHASE 2 — PARTIAL RESULT (Claude)
**30 Aug 2026. Source: IDD-X paper, arXiv 2404.08561, read directly.**
Remaining Phase 2 questions go to the external agents — my search quota is exhausted.

## IDD-X: THE ASSUMPTION IS DEAD

**The 19 explanation labels describe WHY THE EGO VEHICLE ACTED. Not how other agents react.**
Quoted from the paper, the 19 labels are:

> congestion, obstruction, on-road living being, stopped vehicle, avoid congestion,
> avoid obstruction, avoid on-road living being, avoid stopped vehicle, merging, cut-in,
> overtake, confrontation, crossing, slow down, deviate, left turn, right turn, u-turn,
> red light

Our build change #2 was "learn per-agent negotiability from IDD-X — the cow ignores us,
the pedestrian reacts, the bus asserts." **IDD-X cannot support this.** It records the
ego's reaction to the world, not the world's reaction to the ego. Causality runs the
wrong way. Had we not checked, days would have been lost.

## BUT — TWO GAPS CONFIRMED, BOTH USEFUL

### 1. India's flagship decision dataset only records YIELDING
The ego behaviour labels are exactly three:
> slowing down on straight roads, deviating on straight roads, slowing down on left/right/U-turns

And the annotation procedure, quoted:
> "annotators watch the driving videos and filter out video intervals or scenarios where
> the ego driver **either slows down or deviates** from the influence of any road entity"

**There is no label for asserting, pushing through, or refusing to give way.** Every one
of the 3,634 annotated scenarios is the ego vehicle giving way. The dataset was
constructed that way by design.

**This is a slide.** Even India's own driving-decision dataset only contains the
defensive half of the behaviour. The data itself is biased toward the frozen car.

### 2. The animals gap is confirmed BY THE DATASET'S OWN AUTHORS
- Object categories merge them: **"person/animal"** is a single class among 10.
- The authors' own stated limitation, quoted:
  > "The performance in categories such as 'Cut-in' and **'Avoid On-road Animal'** is low
  > across both variants, pointing out areas for improvement."

The dataset creators name on-road animals as an area needing improvement. That is far
stronger than us claiming a gap — the people who built the benchmark said it.

### 3. No audio
IDD-X has no audio. 85 hours of dual-view video (front 2560x1440, rear 1920x1080, 25 fps),
recorded in and around Hyderabad. 3,634 scenarios, 0.3 to 11 seconds each, 697K boxes,
9K tracks.

## CONSEQUENCE FOR THE DESIGN
- Per-agent negotiability **cannot** come from IDD-X. Candidate replacements, all
  UNVERIFIED and now the agents' job: **METEOR** (reported to label yielding),
  **HID** (Zhang 2024), **TRAF**.
- If no dataset labels how other agents respond to the ego, then that quantity has to be
  either (a) measured from our own footage, or (b) estimated online by the planner itself
  rather than learned offline. Option (b) is a design change, not a data problem.

## STILL OPEN FOR THE AGENTS
1. METEOR — downloadable? licence? does it really label yielding BY OTHER AGENTS?
2. Does any dataset in the world label a negotiation outcome?
3. Does any Indian driving dataset contain audio?
4. HID and TRAF availability.

---

# METEOR — VERIFIED, AND IT BEATS IDD-X FOR OUR PURPOSE

Sources: GAMMA project page, GitHub GAMMA-UMD/METEOR, HuggingFace dataset README.
Published ICRA 2023 (Chandra, Wang, Mahajan et al., UMD GAMMA).

| Fact | Value |
|---|---|
| Size | **93.4 GB**, five chunks on HuggingFace |
| Access | **Open — no registration gate.** https://huggingface.co/datasets/XijunWang/METEOR/tree/main |
| Licence | **CC BY-NC-SA 4.0** — non-commercial, attribution, share-alike. Fine for SIH. |
| Content | 1,000+ one-minute videos, 2M+ annotated frames, 13M+ bounding boxes |
| Agent categories | **16** (IDD-X has 10) |
| Ego data | **GPS trajectories included** |
| Video-level tags | weather, time of day, road type, traffic density |
| Behaviours | cut-ins, **yielding**, overtaking, overspeeding, zigzagging, sudden lane change, running signals, wrong-lane driving, wrong turns, **lack of right-of-way at intersections** |
| Grouping | traffic violations / atypical interactions / rare multi-agent behaviours |
| Raw format | XML, converted to COCO (detection) or rawframe (behaviour) |
| Reassembly | `cat chunk_* > METEOR_Dataset.zip` |
| Audio | not mentioned — assume none |
| Code | github.com/GAMMA-UMD/METEOR, 13 stars, 12 commits |

## THE CITATION THAT MATTERS MOST
The authors' own headline finding, from the HuggingFace README:
> "state-of-the-art models for object detection and behavior prediction... **fail on the
> METEOR dataset**", despite performing well on established benchmarks like **Waymo**.

**The dataset's authors measured that Western-trained models break on Indian roads.**
That is our problem statement, proven by a third party, in one sentence.

## DISK WARNING — feeds straight into the lab questions
`cat chunk_* > METEOR_Dataset.zip` means **93 GB of chunks + 93 GB zip = ~186 GB peak**
before extraction, and more once extracted. Chunks can be deleted after `cat`, but the
machine still needs roughly **190-280 GB free** at peak. This makes "how much free disk"
the single most important lab question.
Download needs internet ON the compute machine (HuggingFace CLI).

## METEOR vs IDD-X FOR OUR NEGOTIATION LAYER
| | IDD-X | METEOR |
|---|---|---|
| Size | 160 GB | **93.4 GB** |
| Access | login gate | **open** |
| What is labelled | **why the EGO acted** (19 categories) | behaviours incl. **yielding** and **right-of-way violations** |
| Ego trajectory | not stated | **yes, GPS** |
| Agent categories | 10 (person/animal merged) | **16** |
| Audio | none | none |

**RECOMMENDATION: METEOR, not IDD-X, for the negotiation layer.** Smaller, ungated,
has ego trajectories, more agent classes, and labels the behaviours we actually need.
IDD (detection/segmentation) is still the right choice for training perception.

## THE ONE QUESTION STILL OPEN
**Are METEOR's behaviour labels attached to SURROUNDING AGENTS, or to the ego vehicle?**
Strong indications it is per-agent — 13M boxes, 16 agent categories, "atypical
interactions", "multi-agent behaviors", and a benchmark task called "action-behavior
prediction". But the project page, the GitHub README and the HuggingFace README all
decline to say it outright, and the paper PDF is behind bot-verification.
**This must be settled before the negotiation layer is designed.** Settle it by reading
the ICRA 2023 paper PDF, or by opening one XML annotation file after download.
