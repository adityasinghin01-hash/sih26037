# SIH26037 — set up the whole project on your laptop

Everything we made is in this one repository (branch **`integration/dense-planner`**), except the big
files, which are 4 zips on Google Drive (link in Step 3).

---

## Step 1 · Get access
- You need to be a collaborator on `github.com/adityasinghin01-hash/sih26037` (the repo is **private**).
  If you can't open that link while logged in to GitHub, ask to be added.
- Install **Git**: https://git-scm.com/downloads

## Step 2 · Download the code
Open a terminal (Windows: "Git Bash") and run:
```bash
git clone -b integration/dense-planner https://github.com/adityasinghin01-hash/sih26037.git
cd sih26037
```
`-b integration/dense-planner` matters: it is the newest branch. `main` is older.

## Step 3 · Download the big files (models, results, renders, videos, Blender city)
Google Drive folder: **https://drive.google.com/your-real-link**

| Zip | Size | What | Need it? |
|---|---|---|---|
| `1-models-and-results.zip` | 26 MB | exported ONNX models, `results/` run evidence | **Yes** |
| `2-demo-renders.zip` | 543 MB | pre-recorded demo films (`matlab/renders/`) | For demos |
| `3-world-video.zip` | 346 MB | world/video clips | Optional |
| `4-blender-city.zip` | 189 MB | Najibabad Blender city (parked) | Optional |

Put each zip **inside the `sih26037` folder** and unzip it there (the folders inside are already
named correctly — e.g. `ml/python/export/`, `matlab/renders/`). Say "yes / replace" if asked.

## Step 4 · Install MATLAB R2026a (KIET licence) with these products
MATLAB · Simulink · Automated Driving Toolbox · Computer Vision Toolbox · Image Processing Toolbox ·
Deep Learning Toolbox · Stateflow · Sensor Fusion and Tracking Toolbox · Navigation Toolbox
(optional: Lidar Toolbox, Mapping Toolbox, Parallel Computing Toolbox).

Then in MATLAB: **Home → Add-Ons → Get Add-Ons**, install:
- Deep Learning Toolbox Converter for ONNX Model Format
- Automated Visual Inspection Library for Computer Vision Toolbox

Check it worked:
```matlab
cd derisk
check01_environment      % expect nine [ OK ] lines
```

## Step 5 · Python (only for the ML track)
Python 3.10+:
```bash
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install torch numpy onnx onnxruntime onnxscript
python3 ml/python/tests/test_parity.py
```

## Step 6 · Run the tests and the demo
In MATLAB, **with a window** (not `-batch`):
```matlab
cd <path-to>/sih26037
addpath(genpath('matlab'))
runtests('matlab/tests')   % expect 348 / 348 pass
sihDemo                    % S1 cattle crossing, 610 m
sihDemo("galli")           % S3 narrow lane
```
Do **not** run `sihDemo("s2")` — it refuses on purpose (S2 still collides and stalls).
Full notes: `HANDOVER/project-hq/RUN-THE-DEMO.md`.

## Step 7 · Where everything is
| What | Where |
|---|---|
| Code: planner, sensing, demo | `matlab/` |
| ML training code | `ml/` (read `ml/ReadThis.md`) |
| Planner track notes | `plan/` |
| All research P0–P16 (rules, difficulties, planner, ML, sim, build plan, Indian traffic numbers) | `HANDOVER/project-hq/research/` |
| System design / PS compliance / 10-week build plan | `HANDOVER/project-hq/research/P13…`, `P14…`, `P15…` |
| PPT pack: 4 documents + 7 diagrams (D1–D7) | `HANDOVER/ppt-pack/` |
| Diagram source code (edit + rebuild) | `HANDOVER/ppt-pack/_build/` |
| CARLA test guide | `HANDOVER/carla-test/CARLA-Test-Guide.pdf` |
| State of the project, how agents were driven | `HANDOVER/project-hq/00-READ-FIRST.md`, `02-STATE-TODAY.md` |
| Frozen interface contract | `AGENTS.md` §3 |

## Step 8 · If you use CARLA (Windows PC, 8 GB+ GPU)
Follow `HANDOVER/carla-test/CARLA-Test-Guide.pdf`. Use **CARLA 0.9.15** (not the UE5 version).
Adding custom Indian vehicles needs a CARLA **source build**: 165 GB disk, Unreal 4.26 fork,
Visual Studio 2019, 4+ hours (see `HANDOVER/project-hq/research/P15-BUILD-PLAN.md`).

---
**Known open problems (be honest about them):** S2 collides + stalls; dense S3 stalls at 81.4 m;
planner is 736 ms/step vs 100 ms target; camera detector gives zero boxes on rendered frames; the
yield ML model fails its own ≤1% bar (2.089%) and is switched off.
