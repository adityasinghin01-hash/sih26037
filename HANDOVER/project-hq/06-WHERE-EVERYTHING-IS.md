# The map — every SIH file on this machine

## Live code
| | |
|---|---|
| **The repo** | `~/dev/sih2026` — branch `main`, `f4d1f79`. 3 GB on disk, 143 MB on GitHub (the rest is gitignored build output) |
| The planner | `matlab/+sih/+planner/` — 18 files. Velocity obstacle, contingency, trunk, escape memory, the two barriers |
| The world + sensing | `matlab/+sih/+scenario/`, `+perception/` |
| The demo | `matlab/demo_play.m` (83 KB) + `matlab/+sc/` (62 files) |
| The ML | `ml/python/` + `matlab/+sih/+prediction/` |
| Tests | `matlab/tests/` — 21 files, **348 tests** |
| **Never touch** | `matlab/baseline/` (MathWorks' planner, unmodified) · `AGENTS.md` §3 (the frozen contract) |

## Things that are not in git and cannot be regenerated quickly
| | |
|---|---|
| `matlab/renders/*.mp4` | the two finished films — **the demo-day fallback** |
| `matlab/renders/demo_*.mat` | cached planner runs (~240 MB). Without these the demo recomputes for 45–100 s before it can play |
| `~/meteor-data/features/*.pt` | the two trained yield models |
| `results/<run>/` | every run's frozen evidence (gitignored) |

## The other two checkouts
| | |
|---|---|
| `~/dev/sih2026-city` | the Blender city, branch `city/land-and-light`. Land + roads + ~7,800 buildings + temple done |
| `~/dev/sih2026-worktree-models` | YOLOX and DeepLab imported into MATLAB |

## Documents
| | |
|---|---|
| `~/Desktop/SIH26037-Archive/` | 135 files — every research report, the 23-page case study, all 5 teammate briefs, the Idea PPT source |
| `~/Desktop/SIH26037-Reference-ARCHIVED-8Sep-merged/` | the old reference repo, already merged into the main one. History only |
| **`~/dev/sih2026-hq/`** | **this folder — the current truth** |

## Still only on Shourya's Windows machine
`spotter_yolox_tuned.mat` and `road_segmenter_deeplab.mat`. Everything else came across.

## Rescued out of Downloads today (they existed nowhere else)
In `05-ASSETS/`: `round2_final_handoff.md` (the real ML numbers), `Frame 1.png` (the
architecture flowchart — **it says COLREGs, which is wrong, see `01-ML-NUMBERS-CORRECTED.md`**),
`SIH2026-IDEA-Presentation-Format.pptx` (the official template), and three progress logs.

## Salvaged before deletion
`~/dev/_salvage/` — quiesce's uncommitted work and its one unpushed commit, as patches.
Quiesce was the only project whose HEAD was on no remote.
