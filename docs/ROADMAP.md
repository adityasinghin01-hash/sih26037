# Roadmap

Six phases. Each has a **gate** — a condition that must be true before the next begins. Gates are
what stop a team building on sand.

| Phase | Status |
|---|---|
| 0 · Unblock | **OPEN** |
| 1 · Research | ✅ complete |
| 2 · Architecture + API lock | ✅ complete |
| 3 · Idea finalized | ✅ complete |
| 4 · Build | blocked on Phase 0 |
| 5 · Evidence + report | blocked on Phase 4 |
| 6 · Team documents | briefs written; PDFs outstanding |

---

## Phase 0 — Unblock  *(blocks everything)*

| # | Task | Owner |
|---|---|---|
| 0.1 | **MATLAB + 7 products on a Windows machine** | teammate |
| 0.2 | Run `derisk/` checks 0–5, report full output | teammate |
| 0.3 | DGX: free disk, internet on the node, booking process | whoever has lab access |
| 0.4 | **Email licence admin: add RoadRunner to licence 41087767** | Aditya |

**Gate:** check 2 passes — lidar returns off the cow mesh.
**Highest risk:** check 5. OpenTrafficLab's `DrivingStrategy` was tested on **MATLAB 2020b only**,
per its own header. Fallback documented in `docs/OPENTRAFFICLAB.md`, ~2 days if it fires.

## Phase 4 — Build  *(six parallel streams, see `teammates/`)*

| # | Deliverable |
|---|---|
| 4.1 | **Scenario 1 — unsignalled urban junction.** Perfect first |
| 4.2 | **Scenario 2 — cattle crossing.** Perfect first |
| 4.3 | Perception: lidar **+ radar** fused, tracking, noise injection |
| 4.4 | Prediction: METEOR loader, LSTM trained, ONNX in the loop |
| 4.5 | Planner: velocity command, Stateflow chart, mode switching |
| 4.6 | Baseline arm running **unmodified** |
| 4.7 | Experiment runner: one command, `results/<run>/` out |
| 4.8 | **Scenarios 3–5** — market, village road, highway merge (coverage) |

**Gate:** scenarios 1 and 2 run clean end to end, five times consecutively.
**Rule:** 4.8 starts only after that gate. Two perfect before five rough — but **all five ship**,
because the problem statement requires five.

## Phase 5 — Evidence and report

| # | Deliverable |
|---|---|
| 5.1 | M1, M2, M3 curves — time-to-enter, completion vs density, perception degradation |
| 5.2 | M4–M10 tables |
| 5.3 | **Interactive demo** — density slider side-by-side, reasoning overlay, honk + habituation |
| 5.4 | **Technical report** → `report/TECHNICAL-REPORT.md` → PDF. *Required deliverable* |
| 5.5 | Demonstration video — Blender renders + Meerut composite |
| 5.6 | Public release: scenarios, metrics, baseline, results |

**Gate on 5.3:** the interactive demo is built **only after** 5.1 and 5.2 exist. A GUI over a
planner that does not negotiate is the "beautiful scenes, weak planner" tier — and TwinX already
won with that move, so it will not win twice.

**Every claim in 5.4 must appear in `docs/CLAIM-LEDGER.md` with its evidence.** No exceptions.

## Phase 6 — Team documents

6.1 One PDF per stream from `teammates/*.md`
6.2 Final compliance pass against `docs/PS-COMPLIANCE.md` — every stated requirement ticked or
    explicitly declared as a deviation

---

## Decisions already locked — do not reopen in Phase 4

- No RoadRunner. `drivingScenario` + OpenStreetMap + OpenDRIVE export. Deviation declared in
  `docs/PS-COMPLIANCE.md`
- Lidar and radar in the loop; camera offline and reported separately
- LSTM, not GNN. Adjacency matrix emitted from day one regardless
- METEOR, not IDD-X
- All five scenarios ship; two are perfected first
- The baseline is never modified
