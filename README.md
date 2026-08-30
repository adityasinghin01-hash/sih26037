# SIH26037 — negotiating at unsignalled Indian junctions

**Smart India Hackathon 2026 · MathWorks · Smart Vehicles**
Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles on Unstructured Indian Roads

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

---

## The problem in three sentences

Every self-driving car has one rule: when it isn't sure, it stops. At an Indian junction with no
signal nobody has priority, so the car is never sure — it stops, and never goes. India's own
driving dataset has **3,634 recorded decisions and every single one is the car giving way**; there
is not one example of going first.

## What this is

**Not a self-driving car.** India legally requires a driver in effective control.
**A test suite** — the missing benchmark for ADAS on Indian roads, released open, with a planner
that proves it works. Since **1 April 2026** ADAS is mandatory on new Indian buses and trucks, and
every such system today is validated against Western scenarios.

---

## Start here

| You are | Read |
|---|---|
| **Anyone, first time** | [`docs/PRD.md`](docs/PRD.md) — the whole idea in plain language |
| **Setting up** | [`docs/SETUP.md`](docs/SETUP.md) — 20 minutes |
| **Picking a workstream** | [`teammates/README.md`](teammates/README.md) |
| **Writing code** | [`docs/INTERFACES.md`](docs/INTERFACES.md) — **frozen contract, read first** |

## Documentation map

| File | What it is |
|---|---|
| `docs/PRD.md` | Problem, solution, user journey, scope |
| `docs/INTERFACES.md` | **The frozen contract.** 8 structs, every module boundary |
| `docs/ARCHITECTURE.md` | The pipeline diagram and module owners |
| `docs/ROADMAP.md` | Six phases, each with a gate |
| `docs/PS-COMPLIANCE.md` | Every requirement MathWorks stated, and where we meet it |
| `docs/CLAIM-LEDGER.md` | Every claim and its evidence. **Not in here → do not say it** |
| `docs/metrics.md` | M1–M10, pre-registered before any run |
| `docs/MODEL-PIPELINE.md` | Video → features → LSTM → ONNX → Simulink |
| `docs/SUPERCOMPUTER.md` | DGX access, METEOR download, training |
| `docs/OPENTRAFFICLAB.md` | Where we cut, and the R2020b risk |
| `docs/PITCH.md` | Six-minute demo script |

## Layout

```
matlab/+sih/        planner, perception, prediction, metrics
matlab/baseline/    MathWorks' shipped planner - NEVER EDIT
matlab/tests/       unit tests. Run these first
python/             METEOR pipeline, LSTM, ONNX export
blender/            rendering
derisk/             the checks that must pass before building
docs/  teammates/   documentation and workstream briefs
```

## Five rules

1. **Never edit `matlab/baseline/`.** A tuned baseline is a strawman and kills the result.
2. **Never invent a number.** If it isn't in `docs/CLAIM-LEDGER.md`, it doesn't go on a slide.
3. **Never change `docs/INTERFACES.md`** without a row in `docs/CHANGELOG.md`.
4. **Nothing ships with a bug already reproduced in the demo flow.**
5. **Errors are reported in full.** Never a summary.

## Status

Phases 1–3 complete (research, architecture, idea). Phase 0 open — MATLAB not yet installed.
See [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Credits

Built on [`mathworks/OpenTrafficLab`](https://github.com/mathworks/OpenTrafficLab).
METEOR dataset (Chandra et al., ICRA 2023). COLREGs formulation after Kuwata et al. and
Tam & Bucknall. Cattle movement parameters from published GPS-collar studies.
3D assets CC-Attribution (Sketchfab); environment maps CC0 (Poly Haven).
**Borrow freely, cite loudly.**
