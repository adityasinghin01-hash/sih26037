I found no validated per-track confidence band or safe threshold in the repository or the cited 11 September handoff. Hardcoding one would violate the “never invent a number” rule.

Recommended design:

- Add `sih.prediction.gateYieldPrediction(track, pYield, config)`.
- Return `"USE"` only when:
  - a validation-backed confidence band is explicitly configured;
  - history has all 20 required S2 steps;
  - the class is supported;
  - all required track fields and `PYield` are finite;
  - `PYield` lies outside the uncertain band.
- Default configuration has no established band, so it produces `"FALLBACK"` for every track.
- `planSeat` optionally consumes calibrated predictions from `ctx.YieldPrediction`, applies the gate after track filtering, and otherwise constructs the current all-invalid S3 exactly as today.
- Add per-step output fields for USE count, FALLBACK count, track-level reasons, and the disclosure that ML is advisory while physical barriers remain binding.
- Do not change `+sih/+planner/`; therefore both futures remain physically checked and the all-FALLBACK path remains identical.

Alternatives are to hardcode an arbitrary confidence band, which is dishonest, or treat extreme probabilities as reliable without held-out evidence, which is also unsupported.

Please approve the recommended closed-by-default, externally-configured confidence-band design so I can implement it.

COMMAND:   repository inspection with sed, rg, find, and read-only git log/status
VALIDATION: NOT RUN
NUMBERS:   No new measurements produced; cited values verified against round2_final_handoff.md
NOT CHANGED: MATLAB code, git state, frozen contracts, baseline, demo_play.m, and S2 files