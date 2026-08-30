# Interface changelog

`docs/INTERFACES.md` is **frozen**. Six streams build against it in parallel, so a silent change
breaks five people. Every change gets a row here and a message to every owner.

| Date | Change | Reason | Who signed off |
|---|---|---|---|
| 2026-08-30 | **Initial freeze.** S1–S8 defined | Phase 2 complete | — |
| 2026-08-30 | **S1: added `SensorMask` field; radar declared a fused in-loop source** | The problem statement names "camera, LiDAR, and radar". Radar was missing from our design — an unforced gap against a stated requirement. TrackList stays sensor-agnostic, so no consumer changes | Aditya |

## Two known reconciliations, deliberately left open

**AccBounds.** OpenTrafficLab's `DrivingStrategy` defaults to `[-5, 3]` m/s²; our `EgoCommand`
(S4) specifies `[-6, +3]`. Stream D decides which wins at integration and records it here. Do not
silently pick one.

**ClassID.** `drivingScenario` reserves its own ClassIDs 1–6; ours (S5) is METEOR's 16-way
taxonomy. `sih.util.toSimClassID()` converts. **Never hardcode either numbering** — if you find a
literal class number anywhere in the code, that is a bug.
