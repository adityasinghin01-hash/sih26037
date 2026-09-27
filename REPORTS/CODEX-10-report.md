Created [CODEX-10-s2-stall.md](/Users/aditya/dev/sih2026/REPORTS/CODEX-10-s2-stall.md).

Key diagnosis:

- `planSeat` discards actors’ longitudinal separation when applying its clearance floor, creating false blockers in circulating/dense traffic.
- WAIT can commit on a one-frame gap, PASS then loses the line, and timeout/cooldown permits the identical episode to re-arm forever.
- `LastAdvanceT` is also incorrectly reset when a pass is selected rather than when the vehicle advances.
- The minimal fix belongs exclusively in `matlab/+sc/planSeat.m`.

No MATLAB was run. No source, frozen-planner, or git changes were made.