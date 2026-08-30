# Setup — get working in 20 minutes

Two different tools on this team. Both read the same rules, so nobody maintains two sets.

| Who | Tool | Reads |
|---|---|---|
| **Aditya** | Claude Code (terminal) | `CLAUDE.md` + `AGENTS.md` |
| **Everyone else** | Google Antigravity | `GEMINI.md` + `AGENTS.md` |

`AGENTS.md` is the shared rules file — Antigravity, Cursor and Claude Code all read it. That is
why there is only one copy of the project rules.

---

## 1 · Get the repo

```
git clone <repo-url>
cd sih2026
```

## 2 · If you are using Antigravity

1. **Open the repo root as your workspace.** Not a subfolder — `AGENTS.md` only loads from the
   root, and without it the agent starts blind.
2. Antigravity picks up `GEMINI.md` and `AGENTS.md` automatically. Nothing to configure.
3. Open your own brief in `teammates/` and point the agent at it.

**Two things to refuse if your agent proposes them:**
- Editing `docs/INTERFACES.md` — five other people build against it
- Editing anything in `matlab/baseline/` — that is our control arm

## 3 · If you are using Claude Code

```
claude
```
from the repo root. It reads `CLAUDE.md` and `AGENTS.md` automatically.

## 4 · MATLAB

Install with **all seven** products ticked:

> MATLAB · Simulink · Automated Driving Toolbox · Computer Vision Toolbox ·
> Image Processing Toolbox · Deep Learning Toolbox · Stateflow

Plus the free add-on **Deep Learning Toolbox Converter for ONNX Model Format**
(Home → Add-Ons → Get Add-Ons → search ONNX).

Licence **41087767** (Total Headcount, Academic) carries all of them.

Then verify:
```matlab
cd <repo>/derisk
check01_environment
```
Send the full output. If anything says MISSING, stop — nothing else will run.

## 5 · Python

```
python3 -m venv .venv && source .venv/bin/activate     # Windows: .venv\Scripts\activate
pip install torch onnx numpy tqdm xmltodict
```

## 6 · Blender  *(Stream F only)*

Blender 4.x + the blender-mcp addon. Enable Poly Haven and Sketchfab in the BlenderMCP sidebar
panel (press **N** in the viewport).

## 7 · Prove your setup works

| You are | Run this | Expect |
|---|---|---|
| Any stream | `derisk/check01_environment` | seven `[ OK ]` lines |
| Stream A | `derisk/check02_lidar_cow` | points landing on the cow |
| Stream D | `runtests('matlab/tests/testPlannerGeometry.m')` | **13 passed** |
| Stream C | `python python/model/yield_lstm.py` | shapes printed |

---

## Where things live

```
docs/PRD.md              start here - the whole idea in plain language
docs/INTERFACES.md       THE FROZEN CONTRACT. Read before writing any code
docs/ROADMAP.md          phases, gates, who does what
docs/PS-COMPLIANCE.md    every requirement MathWorks stated, and where we meet it
docs/CLAIM-LEDGER.md     every claim and its evidence. If it is not here, do not say it
docs/metrics.md          M1-M10, pre-registered
docs/SUPERCOMPUTER.md    DGX access, METEOR download, training
docs/MODEL-PIPELINE.md   PyTorch -> ONNX -> MATLAB -> Simulink, end to end
teammates/               your brief
matlab/  python/  blender/
```
