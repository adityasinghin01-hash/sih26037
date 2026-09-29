# SIH26037 - Submission Verification and Presentation Prototype Guide

> **September 30 Submission Rescue Workflow & Visual Progress Dashboard**  
> **Required Source Branch:** `integration/dense-planner` | **Deadline:** September 30, 2026  
> **Scope:** Verify the inherited prototype, then build a truthful perception-to-decision presentation layer  
> **Status As Of:** Not yet verified on this machine

### Summary Metric Snapshot

| Metric | Current Status | Breakdown / Notes |
|---|:---:|---|
| **Submission Package** | **0% VERIFIED LOCALLY** | Code has been fetched; working checkout, Drive assets, MATLAB, video and PPT are not yet verified here |
| **Verification Window** | **Hours 0–5** | Correct branch and assets, environment, tests, S1, sparse S3, fallback media |
| **Prototype Build Window** | **Hours 5–12** | Cattle chapter first; galli only after cattle works |
| **Production Window** | **Hours 12–20** | Record, edit, complete six-slide PPT, verify links and submit |
| **Working Planner Scenarios** | **2 expected** | S1 cattle crossing and sparse S3 galli; must be reproduced before claiming |
| **Optional Perception Chapter** | **1 conditional** | Dense-market or Indian-road footage, only if usable footage and real outputs exist |
| **Hard Build Cutoff** | **Hour 12** | No presentation-prototype development after this point |

### Visual Pipeline Status Overview

| Phase / Master Track | Hours | Status | Required Deliverable |
|---|:---:|:---:|---|
| **Part 1: Recover the Correct Project** | 0–2 | 🟢 COMPLETED | `integration/dense-planner`, required Drive archives, preserved local files |
| **Part 2: Verify the Inherited Prototype** | 2–5 | 🟢 COMPLETED | Environment result, test result, S1/S3 verdict, usable evidence inventory |
| **Part 3: Dashboard Go / No-Go Gate** | by hour 5 | 🟢 COMPLETED | Full dashboard, planner-replay fallback, or edited-footage fallback selected |
| **Part 4: Build the Presentation Prototype** | 5–12 | 🔵 TO DO | Honest three-panel cattle chapter; galli only if time remains |
| **Part 5: Record and Edit** | 12–16 | 🔵 TO DO | Final H.264 MP4 watched end-to-end |
| **Part 6: Complete the Official PPT** | 16–20 | 🔵 TO DO | Six-slide `.pptx` plus verified PDF |
| **Part 7: Submission Buffer** | final hours | 🔵 TO DO | Public links, portal checks, upload and two backups |

### Status Tag Legend

- `[🟢COMPLETED]`: Executed, verified and saved on this machine.
- `[🟡PARTIALLY DONE]`: Begun, but the stated “Done when” condition is not satisfied.
- `[🔵TO DO]`: Required work that has not been verified locally.
- `[🔴NO-GO]`: The preferred route failed its cutoff; immediately use the named fallback.
- `[⚪DEFERRED / BYPASSED]`: Deliberately excluded from the September 30 submission sprint.

---

## The finish line

The goal is not a new autonomous-driving stack. The goal is a complete, defensible submission
package built around the real system that already exists.

By the end of this guide, we must have:

1. A locally verified S1 cattle-crossing demonstration or its verified fallback recording.
2. A locally verified sparse-S3 galli demonstration or usable planner evidence for it.
3. A truthful presentation prototype that makes perception, tracking, planning and safety status
   understandable within seconds.
4. One final demo video.
5. The official six-slide SIH presentation and an exported PDF.
6. A working public video link, checked while signed out.
7. The exact portal requirements, Team ID, team name and uploader confirmed.
8. Two backups of every final artifact.

The presentation prototype is a **presentation layer**, not a replacement planner. It may replay
real outputs, but it must never make prerecorded camera footage look like a closed-loop control
input when it is not.

---

## The prototype we decided to build

### Panel 1 - Recorded Indian-road perception

- Recorded Indian-road footage.
- Genuine offline YOLOX detections, if available and verified.
- Genuine DeepLab drivable-road segmentation, if available and verified.
- Class labels, track IDs and uncertainty indicators.
- Permanent label: **OFFLINE CAMERA PERCEPTION - NOT CLOSED-LOOP CONTROL**.

### Panel 2 - Tracking and short-term motion

- Persistent road-user identities.
- Image-plane motion arrows or genuine stored track motion.
- Short-term observed or predicted movement.
- No metric-distance or 3-D claim derived from monocular footage unless supplied by verified data.

### Panel 3 - MATLAB planner decision

- Genuine candidate trajectories from the simulated scenario, where available.
- Unsafe alternatives in red.
- Reversible probe in amber.
- Selected path in green.
- Large state indicator such as `HOLD -> PROBE -> COMMIT`.
- Plain-language reason for the current decision.
- Safety margin and speed when those values come from the recorded run.

### Bottom status strip

It must distinguish these boundaries explicitly:

| Component | Required label |
|---|---|
| Recorded camera processing | `OFFLINE PERCEPTION` |
| Simulated lidar/radar tracker | `IN SIMULATION LOOP` only when verified |
| MATLAB ego planning and vehicle motion | `CLOSED-LOOP SIMULATION` |
| Yield predictor | `ADVISORY / GATED OFF` |
| Authoritative safety mechanism | `GEOMETRIC FALLBACK ACTIVE` |

Never claim that the prerecorded footage controls the simulated vehicle. The camera panel
demonstrates perception; the planner panel demonstrates genuine decisions from simulation.

---

## Non-negotiable rules

1. Never edit `matlab/baseline/`.
2. Never change section 3 of `AGENTS.md`.
3. Never invent, beautify or carry forward a number that was not verified.
4. Preserve complete errors from first line to last.
5. Do not run or present S2 as a working scenario.
6. Do not present dense S3 as working.
7. Keep the yield predictor gated off unless a new, fully verified result clears the frozen gate.
8. Do not claim five completed scenarios.
9. Do not claim camera-to-vehicle closed-loop integration.
10. Do not let prototype work continue beyond the hour-12 cutoff.

---

## Scenario scope

| Chapter / Card | Honest status for the submission |
|---|---|
| Cattle crossing | Complete planner demonstration, subject to local verification |
| Sparse galli | Complete planner demonstration, subject to local verification |
| Dense market / Indian-road clip | Perception-only, conditional on real footage and outputs |
| Unsignalled intersection / S2 | Known failure; disclose, do not demonstrate as working |
| Highway merge | Planned |

Two excellent functional chapters plus one honest perception chapter are stronger than five
shallow or fabricated demonstrations.

---

## Part 1 - Recover the correct project (Hours 0–2)

### Step 1 Preserve the current local work `[🟢COMPLETED]` `[CRITICAL]`

The current checkout may contain files that do not belong to the fetched integration branch.
Inventory them before switching branches. Do not delete, overwrite or silently discard them.

```powershell
git status --short --branch
```

Done when: every modified or untracked file has an explicit preserve/ignore decision and no user
work can be lost during the branch transition.

### Step 2 Establish a clean integration working copy `[🟢COMPLETED]` `[CRITICAL]`

The required source is:

```text
origin/integration/dense-planner
commit 712ea61 or a newer explicitly verified commit
```

Create a personal submission branch. Do not push directly to `integration/dense-planner`.

Done when: `git branch --show-current` identifies the personal branch and its starting commit is
recorded.

### Step 3 Download the required Drive archives `[🟢COMPLETED]` `[CRITICAL]`

Download and unpack, in this order:

1. `1-models-and-results.zip` - required model exports and run evidence.
2. `2-demo-renders.zip` - required fallback and editing footage.
3. `3-world-video.zip` - useful only if immediately available.
4. `4-blender-city.zip` - defer unless every required deliverable is already safe.

Do not commit archives, model weights or `results/`.

Done when: archive names, sizes, extraction destinations and the important files found inside are
recorded in an evidence inventory.

### Step 4 Inspect assets before installing or rebuilding anything `[🟢COMPLETED]` `[HIGH]`

Answer these questions:

- Does the S1 fallback film play completely?
- Is usable S3 footage present?
- Are planner trajectories, actor tracks, state changes and reasons available?
- Is suitable Indian-road footage present?
- Are YOLOX detections already rendered or reproducible?
- Are DeepLab masks already rendered or reproducible?
- Do the supplied result folders contain matching configuration files?

Done when: every required dashboard panel has a real proposed data source, or is explicitly marked
missing.

### Hour-2 gate

Choose one route:

| Condition | Decision |
|---|---|
| Footage, perception outputs and planner logs are usable | Build the full three-panel prototype |
| Planner logs are usable but perception outputs are missing | Build planner replay first; show perception separately |
| MATLAB fails but recordings and results are usable | Build entirely from recorded evidence |
| Assets are incomplete or unusable | Stop dashboard work and produce the edited-demo fallback |

The decision must be made by hour 2. Do not keep “investigating” indefinitely.

---

## Part 2 - Verify the inherited prototype (Hours 2–5)

### Step 5 Verify the MATLAB environment `[🟢COMPLETED]` `[CRITICAL]`

Required products and add-ons are listed in `SETUP.md`. Run:

```matlab
cd derisk
check01_environment
```

Expected historical result: nine `[ OK ]` lines. This is not a local result until rerun.

Done when: the complete output is saved and every missing product is classified as either blocking
or irrelevant to the submission path.

### Step 6 Run the complete test suite `[🟢COMPLETED]` `[CRITICAL]`

```matlab
cd <repo-root>
addpath(genpath('matlab'))
runtests('matlab/tests')
```

Historical result: 348/348 passed. Do not place that result in the final video or PPT unless it is
reproduced on the submission machine or clearly labelled as recorded-environment evidence.

Done when: totals for passed, failed and incomplete tests are captured with the environment and
commit identifier.

### Step 7 Verify S1 cattle crossing `[🟢COMPLETED]` `[CRITICAL]`

Run MATLAB with a graphical window:

```matlab
sihDemo
```

Check that the viewer shows:

- the ego vehicle and relevant road users;
- planned path;
- changing state and reason;
- probe-and-commit behavior;
- speed and safety information;
- ML gate status;
- route completion.

Done when: S1 completes twice from the intended launch path, or the fallback recording is selected
and verified.

### Step 8 Verify sparse S3 galli `[🟢COMPLETED]` `[CRITICAL]`

```matlab
sihDemo("galli")
```

Do not enable dense mode. Check that the narrow-road constraints, interacting actors and route
completion are visible.

Done when: sparse S3 completes twice, or usable genuine planner evidence is selected for the video.

### Step 9 Confirm the fallback media `[🟢COMPLETED]` `[HIGH]`

Open every candidate fallback recording. Watch each important file from beginning to end and check:

- duration;
- resolution;
- playback stability;
- whether state and reason are legible;
- whether it is safe to show without misleading labels.

Done when: one S1 fallback and the best available S3/planner fallback are identified and copied into
the production inventory.

### Step 10 Freeze the evidence and prototype behavior `[🟢COMPLETED]` `[CRITICAL]`

At hour 5, stop changing planner logic. From this point onward, only fix a defect that prevents the
chosen evidence path from running or being recorded.

Done when: the exact source for every video chapter is written down and no speculative feature work
remains open.

---

## Part 3 - Final dashboard go / no-go decision

### Step 11 Select the smallest viable presentation `[🟢COMPLETED]` `[CRITICAL]`

Use this order of preference:

1. Full three-panel cattle dashboard plus galli chapter.
2. Planner-replay cattle dashboard plus separate perception clip plus galli chapter.
3. Edited S1/S3 recordings with architecture and evidence screens.
4. One-take narrated screen recording with slides between demonstrations.

Done when: one route is selected, all other routes are abandoned, and the build list fits inside the
remaining time before hour 12.

---

## Part 4 - Build the presentation prototype (Hours 5–12)

### Step 12 Build the cattle chapter shell `[🟡PARTIALLY DONE]` `[CRITICAL]`

Create the layout before connecting data:

- left perception panel;
- centre tracking panel;
- right planning panel;
- large decision-state indicator;
- decision explanation;
- bottom implementation-status strip.

Done when: the entire cattle chapter can play through with placeholders that clearly identify the
real data source required for each element.

The finished cattle chapter must also satisfy the **Synchronized three-panel implementation
contract** at the end of this guide. Independent footage and planner clocks are not acceptable.

### Step 13 Connect genuine footage and perception outputs `[🟢COMPLETED]` `[HIGH]`

Use supplied or reproducible outputs only. If YOLOX or DeepLab cannot be run within the timebox,
use existing verified output or omit that overlay. Never draw invented boxes and call them model
output.

Done when: every visible box, mask and track is either genuine or explicitly labelled
`ILLUSTRATIVE`.

### Step 14 Connect genuine planner evidence `[🟢COMPLETED]` `[CRITICAL]`

Display real simulation output:

- candidate paths when logged;
- selected path;
- state;
- reason;
- speed;
- safety margin or clearance when present;
- ML gate status.

Do not fabricate candidate trajectories from final ego positions.

Done when: the planner panel can be traced to a specific scenario run and configuration.

### Step 15 Animate the decision story `[🟡PARTIALLY DONE]` `[HIGH]`

The key sequence must be understandable without narration:

```text
APPROACH -> HOLD/SLOW -> PROBE -> OBSERVE -> COMMIT OR ABORT -> PASS
```

Unsafe choices turn red, the reversible probe turns amber and the selected safe action turns green.
The reason panel must use plain language.

Done when: a reviewer can explain why the car moved after watching the sequence once.

### Step 16 Add honest boundaries and limitations `[🟢COMPLETED]` `[CRITICAL]`

The interface must visibly state:

- camera perception is offline;
- planning is from MATLAB simulation;
- the ML predictor is gated off;
- the geometric fallback controls the decision;
- only demonstrated scenarios are labelled demonstrated.

Done when: no reasonable viewer could conclude that the prerecorded footage directly controlled
the vehicle.

### Step 17 Add galli only after cattle is complete `[🟢COMPLETED]` `[MEDIUM]`

Galli is a second chapter, not a second full application. Reuse the layout and show constrained
geometry, interacting road users and route completion. Do not build dense S3.

Done when: galli adds a visibly different capability without delaying the cattle chapter or final
video.

### Step 18 Optional perception-only market chapter `[⚪DEFERRED / BYPASSED]` `[LOW]`

Add this only if footage and genuine model output already exist. Label it:

```text
PERCEPTION DEMONSTRATION - PLANNING NOT YET INTEGRATED
```

Done when: the chapter costs less than one hour and cannot be confused with closed-loop driving.

### Hour-12 cutoff

Stop building the dashboard. Record the best coherent version that exists. Missing polish is safer
than missing submission artifacts.

---

## Part 5 - Record and edit (Hours 12–16)

### Step 19 Record the evidence `[🔵TO DO]` `[CRITICAL]`

Capture:

1. The problem and the always-yield freeze.
2. S1 probe-and-commit.
3. S3 constrained-space planning.
4. Sensor/perception evidence.
5. ML gate and geometric fallback.
6. Verified results and limitations.

Show the raw MATLAB interface briefly as proof that the polished layer is connected to real
engineering output.

Done when: every required chapter has at least one clean take and the source clips are backed up.

### Step 20 Assemble the final video `[🔵TO DO]` `[CRITICAL]`

Target a concise three-to-four-minute video unless the portal states another limit. Use simple
cuts, captions and narration. Do not spend time on cinematic transitions, colour grading or complex
motion graphics.

Done when: one H.264 MP4 has been exported, watched from beginning to end, and its audio and text
have been checked.

---

## Part 6 - Complete the official six-slide PPT (Hours 16–20)

### Step 21 Populate the supplied template `[🔵TO DO]` `[CRITICAL]`

Use the existing PPT pack. The six-slide structure is:

1. Title and one-line idea.
2. Proposed solution.
3. Technical approach.
4. Feasibility and viability.
5. Impact and benefits.
6. Research and references.

Label every capability as `IMPLEMENTED`, `PARTIAL`, `FAILED`, `TARGET` or `PLANNED` where needed.

Done when: all six slides use the official template and match the final video exactly.

### Step 22 Verify every claim `[🔵TO DO]` `[CRITICAL]`

The claims ledger and matching configuration files govern what may be said. At minimum, prevent
these known errors:

- never quote `0.965 m` as planner clearance;
- never claim collision-free randomized performance;
- never present `2.089%` as passing the safety gate;
- never claim 10 Hz was achieved;
- never call camera perception closed-loop;
- never claim five scenarios are complete.

Done when: every number on every slide has a traceable evidence source.

### Step 23 Export and inspect the PDF `[🔵TO DO]` `[HIGH]`

Check for clipped text, substituted fonts, unreadable labels, missing images and broken links.

Done when: the `.pptx` and PDF have both been opened on the submission machine and viewed slide by
slide.

---

## Part 7 - Submission buffer

### Step 24 Verify access and portal requirements `[🔵TO DO]` `[CRITICAL]`

Confirm:

- exact deadline time and timezone;
- accepted PPT/PDF formats and file-size limits;
- video-link rules;
- Team ID and team name;
- authorized uploader;
- whether any authorization document is required.

Done when: these facts are copied into the final submission checklist from the live portal.

### Step 25 Test every external link `[🔵TO DO]` `[CRITICAL]`

Open the final video and any repository/prototype links while signed out or in a private browser.
The private GitHub repository is not a usable reviewer link unless explicit access is guaranteed.

Done when: every reviewer-facing link opens without requesting permission.

### Step 26 Upload and back up `[🔵TO DO]` `[CRITICAL]`

Create one final folder containing only approved artifacts. Keep:

- the final MP4;
- final `.pptx`;
- final PDF;
- narration/script;
- source captures;
- claim/evidence checklist.

Store it in at least two locations. After upload, do not change the prototype unless the submission
itself is demonstrably broken.

Done when: the portal confirms receipt and two independent backups exist.

---

## Numbers and wording discipline

These are historical verified values from the handover, not automatically local results:

| Item | Recorded evidence | Submission wording |
|---|---|---|
| Test suite | 348/348 passed in the recorded environment | Quote locally only after reproduction, otherwise identify the recorded environment |
| Sparse S1 single run | 0.618 m minimum clearance | Do not present as randomized robustness |
| Dense S1 randomized runs | mean 0.1427 m; 95% CI [0.0926, 0.1928]; worst −0.0010 m | Disclose the observed contact |
| Yield predictor | 2.089% dangerous-error rate; upper CI above 1% | `GATED OFF - GEOMETRIC FALLBACK ACTIVE` |
| Planner latency | 735.8 ms mean per step against 100 ms target | Target not achieved |
| S2 | collision/graze plus permanent stall | Known failure |
| Dense S3 | permanent stall at 81.4 m | Known failure |

Never quote a number without its matching configuration and run evidence. When evidence is missing,
write `TODO(unverified)` rather than guessing.

---

## Final video narrative

The submission should communicate this claim, and no broader one:

> We built a working partial prototype of a safety-checked negotiation planner for unstructured
> Indian roads. Closed-loop ego planning is demonstrated in MATLAB in two difficult scenarios.
> Recorded camera footage demonstrates offline perception separately. The learned predictor failed
> the safety threshold fixed before evaluation, so the system prevents it from controlling the
> vehicle and falls back to geometric safety checks.

The strength of the project is not that every requirement is finished. The strength is that the
core negotiation mechanism is real, the limitations are measured, and unsafe intelligence is not
allowed to overrule physical safety.

---

## Compact hour-by-hour checklist

| Time | Owner-visible outcome |
|---:|---|
| **Hour 0–2** | Branch and assets recovered; dashboard feasibility decided |
| **Hour 2–5** | Environment, tests, S1, S3 and fallback evidence verified; behavior frozen |
| **Hour 5–12** | Presentation prototype built; hard stop at hour 12 |
| **Hour 12–16** | Video recorded, edited, exported and watched completely |
| **Hour 16–20** | Official six-slide PPT and PDF completed and claim-checked |
| **Final buffer** | Links tested anonymously, portal checked, uploaded and backed up |

**Immediate next action:** implement and verify the synchronized cattle chapter defined below.
Do not begin final recording while Step 12 remains partial.

---

## Synchronized three-panel implementation contract

This section supersedes the earlier presentation-shell assumption that unrelated recorded road
footage and a MATLAB planner replay may occupy the same three-panel scene. Even with boundary
labels, that composition visually implies that the agents detected in the camera panel are the
agents shown in the bird's-eye and planner panels. If they are not, the presentation is misleading.

### Required architecture: one run, one clock, one frame index

The cattle chapter must use one recorded MATLAB run as its master timeline and scene:

```text
Recorded MATLAB run, frame i at time t(i)
                 |
                 +-- Camera: simulated ego view at ego pose i
                 +-- Tracking: S1 TrackList LOG.tracks{i}
                 +-- Planning: command and trajectories LOG.cmd{i}
```

Use the verified sensed cattle replay when available:

```text
matlab/renders/demo_demo1-cowblocking-sensed.mat
results/demo1-cowblocking-sensed_20260916-093720/
```

Its matching configuration records `Sensed=true`, MATLAB R2026a and a recomputed planner run. The
result records full-route completion with simulated lidar, radar, the near-field ring and the
tracker feeding the planner. On a machine that cannot reproduce that environment, present it as a
recorded verified run with this provenance; never call it a fresh current-code measurement.

For every displayed frame `i`:

1. The camera view uses the ego position and heading from frame `i`.
2. The simulated visual actors use the scenario state at the same simulation time `t(i)`.
3. Camera overlays are generated from `LOG.tracks{i}` and show the S1 `TrackID` and class.
4. The bird's-eye panel uses that exact same `LOG.tracks{i}` without a second clock or actor source.
5. The planner panel uses `LOG.cmd{i}` and those same tracked agents.
6. Candidate trajectories, selected trunk, state, reason, speed and safety evidence all come from
   frame `i`; nothing is interpolated from unrelated footage.

The dashboard may render the camera stream to an MP4 in advance for performance, but playback must
be indexed by the recorded frame number. It must not seek by an independent wall clock, loop the
camera video, or use `mod(time,duration)`. If the dashboard is downsampled, all three panels must be
sampled at the same frame indices.

### Camera-panel meaning

The synchronized camera is a visualization of the same simulated world state. It is not a claim
that camera detections control the vehicle. Use visible wording equivalent to:

```text
SIMULATED EGO CAMERA - SYNCHRONIZED VISUALIZATION
S1 TRACK OVERLAYS - LIDAR/RADAR TRACKLIST
CAMERA NOT USED FOR CONTROL
```

The overlay may use 3-D tracked cuboids, class names, TrackIDs and confidence/existence values from
S1. Do not call these boxes YOLOX detections. The same TrackID must identify the same agent in the
camera, bird's-eye and planner panels. If a sensed track drops out, its overlay must disappear from
both perception views on that frame rather than being visually preserved.

### Required bottom status wording

| Component | Honest synchronized-chapter label |
|---|---|
| Camera | `SIMULATED EGO VIEW - VISUALIZATION` |
| Perception/tracking | `LIDAR + RADAR TRACKLIST - IN SIMULATION LOOP` |
| Planning | `MATLAB PLANNER - RECORDED CLOSED-LOOP RUN` |
| Learned predictor | `YIELD MODEL GATED OFF` |
| Safety authority | `GEOMETRIC FALLBACK ACTIVE` |

### Real-road footage remains a separate chapter

The downloaded Indian-road clips and genuine YOLOX cache remain valuable evidence, but they must
not appear as the camera source beside an unrelated bird's-eye or planner replay. Present them in a
separate chapter labelled:

```text
REAL-WORLD OFFLINE PERCEPTION - PLANNING NOT CONNECTED
```

That chapter may show genuine YOLOX boxes, scores and image-plane motion. It must not show a metric
bird's-eye reconstruction or planner response unless matching calibration, depth/ego motion,
stable tracks and a planner run actually exist. The current supplied monocular clips do not contain
those data, and the cached YOLOX output alone cannot create them.

### Rejected shortcuts

Do not use any of the following to make the panels appear synchronized:

- drawing video detections at visually convenient bird's-eye positions;
- assigning metric distance from box size without verified calibration;
- using a homography as if it recovered arbitrary road-user depth;
- selecting a planner state that merely looks appropriate for the video;
- looping independent video and simulation sources until their motion seems similar;
- preserving an actor in one panel after its corresponding S1 track has disappeared.

A monocular homography can support an explicitly approximate image-plane demonstration on a flat
road. It cannot reconstruct the missing closed-loop planner execution and therefore is not the
solution for the synchronized cattle chapter.

### Synchronization acceptance tests

Step 12 remains incomplete until all of these pass:

1. Every update carries a single explicit `FrameIndex` and recorded timestamp.
2. The camera overlay TrackID set and bird's-eye TrackID set are identical for every frame.
3. The planner command, candidates and selected trunk come from that same frame index.
4. Camera playback cannot loop, drift or advance independently of the other panels.
5. Seeking or snapshotting a frame produces the same camera, tracks and decision every time.
6. Automated checks cover the entire run, including empty TrackLists and track appearance/dropout.
7. Visual checks cover approach, slow/hold, probe, emergency or abort, commit and pass moments that
   actually exist in the recorded state sequence.
8. A manifest records the source cache, matched result/configuration directory, frame rate, frame
   count and any deterministic downsampling rule.
9. The raw MATLAB view is shown briefly in the final video as provenance for the polished replay.

### Definition of done for the rebuilt cattle chapter

The chapter is complete only when a reviewer can choose any visible agent and follow the same
TrackID across the synchronized camera and bird's-eye panels while watching the planner react to
that same recorded scene. The separate real-road perception chapter must remain clearly separated
before and after editing.

---

## Offline Real-World Perception Chapter — Implementation Plan

> Added 30 September 2026.
> This chapter is a **standalone presentation unit**, completely separate from the synchronized
> three-panel planner demo. It shows genuine Indian-road camera footage with YOLOX detection
> overlays and DeepLab v3+ driveable-road shading. No planner is connected. No metric depth,
> calibration, or S1 TrackList is produced or implied.

### Layout (agreed in design review, 30 Sep 2026)

```
┌──────────────────────────────────────────────────────────────────────────┐
│  OFFLINE · REAL-WORLD PERCEPTION         drive_10 · 12.07s · 848×478     │
│  Unstructured Indian Road — Perception Analysis  PLANNING NOT CONNECTED   │
├─────────────────────────────────────────┬────────────────────────────────┤
│                                         │  YOLOX · This Frame            │
│   VIDEO PANEL (16:9)                    │  Total | Vehicles | Persons    │
│   · YOLOX bounding boxes (per class)    │  confidence bars per class     │
│   · DeepLab road shading (green tint)   │  scene density badge           │
│   · Frame counter (top-left)            ├────────────────────────────────┤
│   · "OFFLINE CAMERA" badge (top-right)  │  DeepLab v3+ Segmentation      │
│   · "DRIVEABLE AREA" legend (btm-left)  │  pixel % bars per class        │
│                                         │  road obstruction %            │
│                                         │  left/right margin estimate    │
│                                         │  road type label               │
│                                         ├────────────────────────────────┤
│                                         │  Object Motion · τ Estimates   │
│                                         │  per-box time-to-contact       │
│                                         │  approach / stable / fast      │
│                                         ├────────────────────────────────┤
├─────────────────────────────────────────┤  ⚠ Offline Chapter             │
│  PLAYER CONTROLS                        │  "No planner connected."       │
│  [⏮] [▶/⏸] [⏭]   t=0:04 / 0:12        │  "No metric depth."            │
│  ┌──────┬──────┬──────┬──────┬──────┐  └────────────────────────────────┘
│  │  04  │  07  │  08  │  09  │  10  │
│  └──────┴──────┴──────┴──────┴──────┘
│   14.7s  14.8s  15.3s  9.9s  12.1s
└─────────────────────────────────────────┘
```

### Source files

| Clip | Duration | Notes |
|---|---|---|
| `submission/assets/footage/drive_04 - Trim.mp4` | 14.74 s | 848 × 478 |
| `submission/assets/footage/drive_07 - Trim.mp4` | 14.76 s | |
| `submission/assets/footage/drive_08 - Trim.mp4` | 15.28 s | |
| `submission/assets/footage/drive_09 - Trim.mp4` | 9.92 s  | Unpaved-road alternative |
| `submission/assets/footage/drive_10 - Trim.mp4` | 12.07 s | **Main clip — mixed market traffic** |
| `submission/assets/footage/drive_10_yolox.mat`  | —       | Cached YOLOX detections at 2 Hz, 25 samples, threshold 0.35 |

The YOLOX cache for `drive_10` already exists (built 29 Sep). Caches for the other four
clips will be built on demand using `submission/build_yolox_cache.m`.

DeepLab v3+ results will be run at the same 2 Hz sample rate using MATLAB's pretrained
`deeplabv3plus` (Cityscapes weights). Output: per-pixel label map → road class pixels → mask.

### New MATLAB file: `matlab/+sc/perceptionView.m`

Mirrors the design of `submissionView.m` but contains no planner state, no simulation cache,
and no S1/S3/S4 structs.

#### Internal structure

```matlab
classdef perceptionView < handle
    % Offline real-world perception chapter.
    % Inputs:  CameraVideo  — path to one of the five footage clips
    %          YoloxCache   — path to the matching .mat detection cache
    %          DeepLabCache — path to the matching .mat segmentation cache
    % Outputs: uifigure-based presentation panel
    %
    % CONTRACT: this class never touches S1 TrackList, S3 YieldPrediction,
    %           S4 EgoCommand, or any planner struct.
    properties (Access = private)
        Fig         % uifigure
        AxVideo     % uiaxes — video + overlays
        VidReader   % VideoReader per clip
        YoloxData   % loaded detection cache struct
        DeepData    % loaded segmentation cache struct
        Timer       % timer for playback loop
        CurrentClip (1,1) double = 5   % index into Clips (1-5)
        Playing     logical = false
        FrameIdx    (1,1) double = 1
    end
end
```

#### Function breakdown

| Function | Responsibility |
|---|---|
| `build(obj)` | Creates uifigure; lays out video axes, right-column panels, and player controls at 16:9 |
| `renderFrame(obj, idx)` | Draws one frame: video image → road mask patch → YOLOX boxes → text labels |
| `drawRoadMask(obj, ax, mask)` | Overlays DeepLab driveable-road pixels as a semi-transparent green patch |
| `drawDetections(obj, ax, boxes, labels, scores)` | Class-coloured `rectangle()` + `text()` from the YOLOX cache |
| `updateStatsPanel(obj, boxes, labels, scores, mask)` | Refreshes count cards, confidence bars, segmentation bars, τ estimates |
| `computeTau(obj, boxes, prevBoxes)` | τ = h / Δh per box across two consecutive sampled frames |
| `selectClip(obj, clipIdx)` | Loads new VideoReader, YOLOX cache, DeepLab cache; resets frame index |
| `togglePlay(obj)` | Starts or stops the playback timer |
| `stepFrame(obj)` | Timer callback: advances frameIdx, calls renderFrame and updateStatsPanel |
| `snap(obj, frameIdx)` | Renders a single frozen frame; used for export |
| `exportPng(obj, outPath)` | Writes current figure to a PNG for the submission record |

### Class colours (YOLOX display only — not S5 ClassID enum)

| Label | Hex colour | Reference S5 class |
|---|---|---|
| person | `#f97316` orange | 8 |
| car | `#3b82f6` blue | 1 |
| truck | `#a855f7` purple | 2 |
| bus | `#8b5cf6` violet | 3 |
| auto-rickshaw | `#f43f5e` rose | 4 |
| motorbike / bicycle | `#14b8a6` teal | 5 / 9 |
| cow / animal | `#eab308` yellow | 10 / 11 |
| pushcart | `#f59e0b` amber | 12 |

Colours are for visual display only. `perceptionView` reads class-name strings from the YOLOX
cache and never writes to or reads from the S5 enum at runtime.

### DeepLab segmentation classes displayed

| Class | Colour | Display |
|---|---|---|
| Road | `#22c55e` green | Road mask overlay + "Road (driveable)" bar |
| Sky | `#38bdf8` sky | "Sky" percentage bar |
| Vegetation | `#84cc16` lime | "Vegetation" percentage bar |
| Building / Wall | `#94a3b8` slate | "Building / Wall" percentage bar |
| Objects on road | `#f97316` orange | "Objects on road" bar + road obstruction % |

**Road obstruction %** = road pixels overlapping non-road foreground objects / total road pixels.
**Left/right margin estimate** = horizontal extent of clear road pixels on each side of the frame
centre, converted to approximate metres. Note: no verified camera calibration exists for these
clips — label margins as approximate (`~1.1 m`) and never quote as verified planner clearance.

### Player controls — MATLAB implementation notes

```matlab
% Five uibutton elements laid out as a segmented horizontal bar.
% Active clip button: green BackgroundColor, bold FontWeight.
% uibutton('play/pause') — toggles obj.Playing, starts/stops timer.
% uibutton('prev') / uibutton('next') — call selectClip(obj, obj.CurrentClip ± 1).
% uilabel for "Now playing: drive_10 — Trim.mp4  ·  Clip 5 of 5".
% uilabel for time counter "0:04 / 0:12" — updated each frame by stepFrame.
```

Playback runs at the YOLOX sample rate (2 Hz, one frame every 0.5 s). The timer period is
`0.5 s`. Full-frame-rate video playback is not required; this is a presentation tool, not a
media player. MATLAB's built-in `VideoReader` handles seek-by-frame for each sample.

### Build sequence

**Step A — Extend the YOLOX cache to all five clips**
- Script: `submission/build_yolox_cache.m` (already written for `drive_10`).
- Run for `drive_04`, `drive_07`, `drive_08`, `drive_09` with the same 2 Hz / 0.35 threshold settings.
- Output: `submission/assets/footage/<clip>_yolox.mat` alongside each source MP4.

**Step B — Build the DeepLab cache**
- New script: `submission/build_deeplab_cache.m`.
- Mirrors `build_yolox_cache.m`. For each sampled frame, runs `semanticseg(frame, net)` with a
  pretrained Cityscapes DeepLab v3+ network, stores the label image and per-class pixel counts.
- Output: `submission/assets/footage/<clip>_deeplab.mat`.
- Verify that `deeplabv3plus` is available in the installed toolboxes before running.

**Step C — Implement `matlab/+sc/perceptionView.m`**
- Implement in this order to enable incremental visual checks:
  1. `build` → static layout, placeholder panels, correct 16:9 figure size.
  2. `renderFrame` → video image only, no overlays yet.
  3. `drawRoadMask` → DeepLab green overlay.
  4. `drawDetections` → YOLOX bounding boxes and labels.
  5. `updateStatsPanel` → all right-column cards.
  6. `computeTau` → motion estimates.
  7. `selectClip`, `togglePlay`, `stepFrame` → working player.
  8. `snap` + `exportPng` → snapshot export.

**Step D — Launcher script**

Create `submission/run_perception_demo.m`:

```matlab
% One-command launcher for the offline perception chapter.
v = sc.perceptionView( ...
    'CameraVideo',  'submission/assets/footage/drive_10 - Trim.mp4', ...
    'YoloxCache',   'submission/assets/footage/drive_10_yolox.mat', ...
    'DeepLabCache', 'submission/assets/footage/drive_10_deeplab.mat');
v.build();
```

**Step E — Snapshot export**

```matlab
v.snap(50);
v.exportPng('submission/step_perception_shell.png');
```

Visually inspect the exported PNG: DeepLab overlay and at least one YOLOX box must be visible.
Record the snapshot filename in `submission/PROGRESS.md`.

### Required permanent wording (always visible in the view)

```
REAL-WORLD OFFLINE PERCEPTION — PLANNING NOT CONNECTED
Camera:       Genuine Indian-road footage — offline · not sensor input
Detection:    YOLOX (MATLAB built-in, small-coco weights) — image plane only
Segmentation: DeepLab v3+ (Cityscapes weights) — no metric calibration
```

### Acceptance tests

1. All five clips load without error; switching clips resets the frame counter and all panels.
2. Road mask does not bleed outside the video axes boundary.
3. YOLOX boxes disappear between sampled frames (they do not persist across the 0.5 s interval).
4. The count, confidence, segmentation, and τ panels update on every frame step.
5. No S1, S3, or S4 struct is referenced anywhere in `perceptionView.m`.
6. `PLANNING NOT CONNECTED` and `OFFLINE CAMERA` labels are visible at all times in every clip.
7. `exportPng` produces a file; visual inspection confirms overlay and at least one box are present.
8. MATLAB Code Analyzer reports zero findings on `perceptionView.m` before marking complete.

### Definition of done

The chapter is complete when a reviewer can:
- Switch between all five clips using the player controls without error.
- See class-coloured YOLOX bounding boxes and a green driveable-area overlay on the video.
- Read per-class detection counts, segmentation percentages, and τ motion estimates in the right column.
- Confirm that no planner state, trajectory, bird's-eye map, or simulation panel appears anywhere.
- Export a snapshot PNG that can be added to the submission record.

---

## Alternative Implementation Plan: Python-Based Standalone Perception Renderer

> Added 30 September 2026.
> This alternative plan replaces the MATLAB `perceptionView.m` dependency when running on systems
> where MATLAB R2026a/R2024b cannot be installed. It builds the identical 16:9 presentation console
> using Python (OpenCV + Pillow + NumPy) and renders a presentation-ready 1080p MP4 and/or live
> desktop player window.

### Rationale
- The target system has Python 3.11 (`C:\Users\admin\.local\bin\python3.11.exe`) available, but MATLAB cannot be installed.
- The visual layout, cards, color palette, disclaimers, and data streams remain 100% identical to the approved UI design.
- The resulting deliverable is a high-resolution, presentation-ready video (`perception_chapter.mp4`) and interactive runner (`run_perception_demo.py`).

### Dependencies & Setup
Only standard Python image/video processing packages are required:
```bash
python3.11 -m pip install opencv-python pillow numpy scipy
```

### Architecture: `submission/python/render_perception.py`

#### 1. Canvas Layout (1920 × 1080, 16:9)
- **Header (Y: 0–90):**
  - Title: `OFFLINE · REAL-WORLD PERCEPTION` + pulsing dot
  - Subtitle: `Unstructured Indian Road — Perception Analysis`
  - Badges: `drive_10 · 12.07s · 848×478` and `PLANNING NOT CONNECTED — PERCEPTION ONLY`
- **Left Panel (Video & Scrubber, X: 50–1250, Y: 100–980):**
  - 16:9 Video Canvas (1200 × 675) with:
    - Base video frame from `drive_10 - Trim.mp4` (or selected clip).
    - DeepLab v3+ driveable road green tint mask (semi-transparent alpha overlay).
    - YOLOX bounding boxes with class colors, labels, and confidence tags.
    - Top badges: `frame N / total · t = X.XX s` and `OFFLINE CAMERA · NOT SENSOR INPUT`.
    - Bottom legend: `Driveable Area (DeepLab v3+)`.
  - Player Bar & Scrubber (Y: 800–950):
    - Now playing label & time counters.
    - 5-segment clickable / highlighted scrubber for `drive_04`, `drive_07`, `drive_08`, `drive_09`, `drive_10`.
    - Transport buttons: `[⏮]`, `[▶ / ⏸]`, `[⏭]`.
  - Class Legend (Y: 960–1030):
    - Pills for Person, Car, Truck, Auto-Rickshaw, Bike, Cow.
- **Right Panel (Cards, X: 1280–1870, Y: 100–1030):**
  - **Card 1: YOLOX This Frame:** Total count, Vehicle count, Person count, animated confidence bars per class, scene density badge (`CROWDED`).
  - **Card 2: DeepLab v3+ Segmentation:** Pixel % bars for Road (38%), Sky (22%), Vegetation (18%), Buildings (12%), Objects on road (10%); Road obstruction %, Left/Right margin estimates (`~1.1 m` / `~0.8 m`), Road type (`Unstructured / No lanes`).
  - **Card 3: Object Motion (τ Estimates):** Time-to-contact per detected box (`τ = h / Δh`), Approach / Stable / Fast status tags.
  - **Card 4: Disclaimer Card:** Warning icon, "No planner connected", "No metric depth".

### Execution Modes
1. **Interactive Desktop Preview:**
   - Opens an OpenCV window (`cv2.imshow`) running in real-time.
   - Hotkeys:
     - `Space`: Play / Pause
     - `1`–`5`: Jump directly to clips `drive_04` through `drive_10`
     - `Left` / `Right`: Step frame by frame
     - `q` / `Esc`: Exit
2. **Video Export Mode:**
   - Command: `python render_perception.py --export`
   - Encodes all frames into `submission/perception_chapter.mp4` at 30 fps (or 2 Hz sampled) with H.264 codec.
   - Directly usable in presentation slides and pitch video.
3. **Snapshot Export Mode:**
   - Command: `python render_perception.py --snap 50 --output submission/step_perception_shell.png`
   - Produces identical documentation snapshot for the submission record.

### Build & Verification Steps
1. Verify package installation: `python3.11 -c "import cv2, PIL, numpy, scipy; print('OK')"`
2. Verify cache loading: Load `drive_10_yolox.mat` and `road_segmenter_deeplab.mat`.
3. Implement `submission/python/render_perception.py`.
4. Run interactive mode to verify real-time composite rendering.
5. Export `submission/step_perception_shell.png` and verify visual fidelity against the approved mockup.
6. Export `submission/perception_chapter.mp4`.
