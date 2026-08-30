# Claim ledger

**Every claim we intend to make, and what backs it.** If a claim is not in this table, it does not
go on a slide, in the report, or in the repo README.

Three states only:

| | Meaning |
|---|---|
| **VERIFIED** | Traced to a primary source, or measured by us. Safe to say |
| **NOT YET RUN** | Our own number. The run that produces it is named. **Never state it until run** |
| **CORRECTED** | We believed something false. Recorded so we never say it again |

---

## A · The problem — VERIFIED

| Claim | Source |
|---|---|
| India's own driving-decision dataset IDD-X has **3,634 scenarios and every one is the car giving way** | IDD-X paper, arXiv 2404.08561. Their annotation procedure filters for the ego "slows down or deviates" |
| METEOR's authors measured that models performing well on **Waymo fail on METEOR** | METEOR paper, arXiv 2109.07648 |
| **3,383 stray-cattle road accidents in 5 years, 919 dead, 3,017 injured** | Haryana Assembly, Agriculture Minister's reply |
| **5,021,587 stray cattle in India**, with no national record of deaths they cause | Government livestock census |
| A cow at 9.2 m is **77 × 63 pixels** in a 1920×1080 140° dashcam frame — 3.98% of frame width | **Measured by us**, Blender, research §17 |

## B · Why the incumbents do not cover us — VERIFIED, in their own words

| Work | Their own admission |
|---|---|
| **B-GAP** | pedestrians and bicycles are "future work"; intersections are "future work"; needs "very good sensing"; admits it acts "conservatively" |
| **GameOpt+** | "assumes connected autonomous vehicles equipped with V2I communication" |
| **GamePlan** | "does not plan beyond computing turn-based orderings"; demonstrated with **2–3 vehicles** |
| **MathWorks baseline** | requires `referencePathFrenet` — Cartesian waypoints. An unsignalled junction supplies none |
| **Camara & Fox** | a review article. No system, no simulator |

## C · The regulatory case — CORRECTED 30 Aug 2026

> **We were citing the wrong standards.** This mattered: our stated users are ARAI and ICAT, the
> people who wrote them.

| | |
|---|---|
| ~~"AIS-189/190 mandate ADAS in India"~~ | **WRONG.** AIS-189 is a Cyber Security Management System; AIS-190 is a Software Update Management System. Neither is an ADAS performance standard |
| **The correct citation** | **MoRTH notification GSR 184(E), March 2025** mandates a full ADAS suite for **M2, M3 (buses) and N2, N3 (trucks)** |
| **In force** | **1 April 2026** for new models; **1 October 2026** for existing models |
| The five standards | **AIS-162** (AEBS), **AIS-184** (driver drowsiness), **AIS-186** (blind spot), **AIS-187** (moving off information), **AIS-188** (lane departure warning) |
| AIS-189 / AIS-190, correctly stated | Cybersecurity (in force Oct 2025) and software updates. Aligned to UNECE R155/R156 and ISO/SAE 21434 |

**The corrected version is stronger.** The ADAS mandate is not coming — **it has been law since
April 2026**. And AIS-188 is lane departure warning, which is a lane-based standard being applied
to roads that frequently have no lanes. That is our argument, sharpened.

## D · Toolchain facts — VERIFIED

| Claim | Source |
|---|---|
| Real Indian geometry imports free: `roadNetwork(scenario,'OpenStreetMap',f)` | mathworks.com |
| Automated Driving Toolbox runs on **Apple Silicon macOS** | mathworks.com platform availability |
| Unreal co-simulation is **Windows/Linux only** and needs **8 GB VRAM + 32 GB RAM** | mathworks.com requirements |
| RoadRunner is **not in the student licence**; Windows/Linux only | MATLAB Answers + platform page |
| Licence **41087767** carries all seven required products | The licence page itself |
| `importNetworkFromONNX` does not support Gather/Scatter → **GNNs cannot import** | mathworks.com |
| **OpenTrafficLab's `DrivingStrategy` was "tested in MATLAB 2020b and may not work in future releases"** | **Their own header comment.** Our licence is R2024b+ |
| `lanespec` is lowercase; `laneSpec` does not exist | MATLAB docs |
| CARLA's agent-blocked threshold is **180 simulation seconds** | leaderboard.carla.org |

## E · Competitive position — VERIFIED

| Claim | Source |
|---|---|
| **TwinX used RoadRunner only as an export target.** No RoadRunner workflow is described | MathWorks Student Lounge, 6 Apr 2026 |
| MathWorks assigns every SIH team an **expert mentor** | Same post, quoted |
| At IIT Madras' road-safety hackathon, **47 teams, and all three winners built detect-and-warn** — not one built a planner | Event results |

## F · Our own numbers — NOT YET RUN

**None of these may be stated until the named run produces them.**

| Claim we intend to make | Produced by | State |
|---|---|---|
| Lidar returns come off a custom cow mesh | `derisk/check02_lidar_cow.m` | **NOT YET RUN** |
| OpenTrafficLab examples run on our MATLAB release | `derisk/check05_opentrafficlab.m` | **NOT YET RUN — highest risk** |
| Which ONNX opset MATLAB accepts | `python/export/to_onnx.py` + `check04` | **NOT YET RUN** |
| METEOR labels attach per-agent or ego-only | Open one dynamic XML (Stream C, task C2) | **NOT YET RUN — decides what our model means** |
| M1 time-to-enter, ours vs baseline | `runExperiment` | **NOT YET RUN** |
| M2 completion vs density | density sweep | **NOT YET RUN** |
| M3 perception-degradation curve | noise sweep | **NOT YET RUN** |
| M4–M10 | see `docs/metrics.md` | **NOT YET RUN** |
| Yield predictor precision / recall | Stream C training | **NOT YET RUN** |

## G · Phrasing rules

- **"No public work we could find"** — never "this has never been done."
- Never "approximately" where a measured value belongs. If it is not measured, say `TODO(unverified)`.
- Name the closest competitor and the closest patent **on our own slide**, before a judge does.
- On metrics: the standard's resolution is **an order of magnitude too coarse**, not "no metric exists."
