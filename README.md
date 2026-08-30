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

**Open the repository root in your editor, not a subfolder.** `AGENTS.md` and `GEMINI.md` only
load from the root, and without them your AI assistant works blind.

| Stream | Owns | File |
|---|---|---|
| **A** | Scenarios, roads, junctions | [`teammates/A-world.md`](teammates/A-world.md) |
| **B** | Lidar, radar, tracking | [`teammates/B-perception.md`](teammates/B-perception.md) |
| **C** | Dataset, LSTM, training | [`teammates/C-prediction.md`](teammates/C-prediction.md) |
| **D** | The negotiating planner | [`teammates/D-planner.md`](teammates/D-planner.md) |
| **E** | Baseline, metrics, results | [`teammates/E-evidence.md`](teammates/E-evidence.md) |

## Layout

```
AGENTS.md           project rules + THE FROZEN CONTRACT (section 3)
GEMINI.md           Antigravity-specific rules
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
