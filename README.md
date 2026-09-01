# SIH26037 — negotiating at unsignalled Indian junctions

**Smart India Hackathon 2026 · MathWorks · Smart Vehicles**

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

---

## Start here

1. **Read the PRD.** It is distributed as a PDF — ask Aditya. Problem, solution, what the judge
   sees, the metrics, and what we are allowed to claim.
2. **Open your own file in [`teammates/`](teammates/)** and follow it from the top. Each is
   self-contained: installing everything, how to work, what to build, who is waiting on you.
3. **Read section 3 of [`AGENTS.md`](AGENTS.md)** before writing code — the frozen contract.
4. **The first time you have MATLAB on a machine, run [`/first-run`](.agents/workflows/first-run.md).**
   Most of the MATLAB here has been checked against the MathWorks documentation but **never
   executed**. That workflow runs it in the right order and tells you what to look for.

**Open the repository root in your editor, not a subfolder.** `AGENTS.md`, `GEMINI.md` and
everything in `.agents/` only load from the root, and without them your AI assistant works blind.

## Ask your AI assistant for these by name

Type the slash command in Antigravity, or just open the file and tell your agent to follow it.

| Command | What it does |
|---|---|
| **`/first-run`** | Runs the MATLAB that has never been executed, in order. **Do this first.** |
| **`/ml-run`** | The whole yield-predictor pipeline: features → train → evaluate → export |
| **`/ml-parity`** | Proves the Python and MATLAB feature builders still agree |
| **`/ml-models`** | The three MATLAB-native models: YOLOX, DeepLab v3+, PointPillars |

| Stream | Owns | File |
|---|---|---|
| **A** | Scenarios, roads, junctions | [`teammates/A-world.md`](teammates/A-world.md) |
| **B** | Lidar, radar, tracking | [`teammates/B-perception.md`](teammates/B-perception.md) |
| **C** | Dataset, LSTM, training | **[`ml/ReadThis.md`](ml/ReadThis.md)** — start here, then [`teammates/C-prediction.md`](teammates/C-prediction.md) |
| **D** | The negotiating planner | [`teammates/D-planner.md`](teammates/D-planner.md) |
| **E** | Baseline, metrics, results | [`teammates/E-evidence.md`](teammates/E-evidence.md) |

## Layout

```
AGENTS.md           project rules + THE FROZEN CONTRACT (section 3)
GEMINI.md           Antigravity-specific rules
teammates/          five workstream files, one each
ml/                 THE ML STREAM'S HOME
ml/ReadThis.md      the roadmap - read this first if you are Stream C
ml/CHEATSHEET.md    every command, in order
ml/TROUBLESHOOTING.md  errors we already hit, and what they really mean
ml/python/          dataset pipeline, both yield models, ONNX export
matlab/+sih/        planner, prediction, models, util
.agents/rules/      loaded automatically by your agent
.agents/workflows/  slash commands - see the table above
matlab/baseline/    MathWorks' shipped planner - NEVER EDIT
                    EMPTY as of 1 Sep 2026, and git does not track empty folders, so a
                    fresh clone will not have it at all. Stream E adds the baseline.
matlab/tests/       run these first
ml/derisk/             the checks that gate the build
blender/            rendering
```

## Five rules

1. **Never edit `matlab/baseline/`** — a tuned baseline is a strawman and kills the result
2. **Never invent a number** — if you did not run something to get it, do not write it
3. **Never change section 3 of `AGENTS.md`** without telling everyone
4. **Nothing ships with a bug already reproduced in the demo flow**
5. **Errors are reported in full** — never a summary

## Credits

Built on [`mathworks/OpenTrafficLab`](https://github.com/mathworks/OpenTrafficLab).
METEOR dataset (Chandra et al., ICRA 2023). COLREGs formulation after Kuwata et al. and
Tam & Bucknall. Cattle parameters from published GPS-collar studies.
3D assets CC-Attribution (Sketchfab); environment maps CC0 (Poly Haven).
**Borrow freely, cite loudly.**
