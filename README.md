# SIH26037 — negotiating at unsignalled Indian junctions

**Smart India Hackathon 2026 · MathWorks · Smart Vehicles**

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

---

## Start here

**1. Read [`docs/PRD.md`](docs/PRD.md).** It is the only project document. Problem, solution, the
frozen contract, what we measure, what we may claim, the phases, the whole tech stack.

**2. Open your own file in [`teammates/`](teammates/) and follow it from the top.** Each one is
self-contained: how to install everything, how to work, what to build, and who is waiting on you.

| Stream | Owns | File |
|---|---|---|
| **A** | Scenarios, roads, junctions | [`teammates/A-world.md`](teammates/A-world.md) |
| **B** | Lidar, radar, tracking | [`teammates/B-perception.md`](teammates/B-perception.md) |
| **C** | Dataset, LSTM, training | [`teammates/C-prediction.md`](teammates/C-prediction.md) |
| **D** | The negotiating planner | [`teammates/D-planner.md`](teammates/D-planner.md) |
| **E** | Baseline, metrics, results | [`teammates/E-evidence.md`](teammates/E-evidence.md) |
| **F** | Blender, renders, demo | Aditya |

**Open the repository root in your editor, not a subfolder** — `AGENTS.md` and `GEMINI.md` only
load from the root, and without them your AI assistant works blind.

## Layout

```
docs/PRD.md         the only project document
docs/problem-statement.md   what MathWorks actually asked for
docs/research/      the research findings behind every claim
teammates/          five workstream files, one each
matlab/+sih/        planner, perception, prediction, metrics
matlab/baseline/    MathWorks' shipped planner - NEVER EDIT
matlab/tests/       run these first
python/             dataset pipeline, LSTM, ONNX export
derisk/             the checks that gate the build
blender/            rendering
```

## Five rules

1. **Never edit `matlab/baseline/`** — a tuned baseline is a strawman and kills the result
2. **Never invent a number** — if it is not in PRD section 9, it does not go on a slide
3. **Never change PRD section 7** (the frozen contract) without telling everyone
4. **Nothing ships with a bug already reproduced in the demo flow**
5. **Errors are reported in full** — never a summary

## Credits

Built on [`mathworks/OpenTrafficLab`](https://github.com/mathworks/OpenTrafficLab).
METEOR dataset (Chandra et al., ICRA 2023). COLREGs formulation after Kuwata et al.
and Tam & Bucknall. Cattle parameters from published GPS-collar studies.
3D assets CC-Attribution (Sketchfab); environment maps CC0 (Poly Haven).
**Borrow freely, cite loudly.**
