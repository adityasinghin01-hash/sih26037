# CODEX JOB 10 — Phase 4: the S2 stall. Diagnose it, then design the fix.

## YOU CANNOT RUN MATLAB (requires neon, exit 137). Write; Claude runs. No git writes.
Reports go in ~/dev/sih2026/REPORTS/ (outside the repo is not writable for you).

## The defect, measured twice under both sensing conditions
S2 (the chowk, a 244 m gyratory) does not finish the route:
- ground truth: grazes the wrong-way rider at **-0.003 m** at t=17.65 s
- real sensing:  collides at **-0.909 m** at t=12.70 s
- **in BOTH** the planner then stalls permanently at **s ~ 116-121 m of 244 m**,
  cycling ABORT -> STOPPED -> ABORT, message: *"stuck 30.0 s - every sane pass is
  blocked by track N, holding"*. It never reaches the ring exit.

## AND IT IS NOT S2-SPECIFIC — that is the new information
S3 dense does the same thing: stops dead at **s = 81.4 m of 382.2 m**, 150 s at the
identical station, same ABORT/COMMIT cycling. S3 works fine SPARSE.
**Two scenarios, one signature. Treat this as a PLANNER property, not a scenario bug.**
A fix that only rescues S2 is the wrong fix.

## Read, in this order
1. `plan/CLAIM-LEDGER.md` — Part 2 and Part 3 on S2, plus the 17 Sep corrections block
2. `matlab/D9-WAIT-RUNG.md` — **the mechanism**. The ledger names it directly:
   *"a D9 WAIT-rung mechanism repeatedly finding, then losing, a viable pass."*
   Phase 8b solved S1's frozen-robot failure with this same rung. Understand why it
   works there and fails here.
3. `matlab/+sih/+planner/escapeMemory.m`, `pointOfNoReturn.m`, `arbitrate.m`
4. `matlab/+sc/planSeat.m` — the seat, and how it reaches ABORT

## The job — DIAGNOSIS FIRST, and do not skip to the fix
Produce `REPORTS/CODEX-10-s2-stall.md` answering, with code references:
1. **What is the exact loop?** Which condition sends it to ABORT, and which then
   allows COMMIT again, such that it oscillates forever without advancing?
2. **Why does the WAIT rung rescue S1 but not S2/S3?** S1's blocker is a cow that
   never moves. S2's is circulating traffic. Name the structural difference.
3. **Is there a state that should be cleared and is not** — `escapeMemory`,
   `HighWaterS`, `LastAdvanceT`, `TrackMem`? A stall that holds at a fixed station
   for 150 s smells like a latch that never resets.
4. **Then** the minimal fix, and exactly which file it belongs in.

## HARD RULES
- **Never edit `matlab/+sih/+planner/` without saying so explicitly and why.** That
  package is the frozen planner and 348 tests depend on it.
- **Do not fix the stall by raising the step budget, widening the corridor, or
  removing actors until it moves.** The stall IS the finding. Making it disappear
  without naming the mechanism converts a real result into a demo that happens to
  work — the exact opposite of what this project is for.
- Never invent a number. `TODO(unverified)` is a complete answer.
- Whatever you change, `Reactive=false` / default behaviour must stay reproducible:
  S1 dense currently gives M6 = 0.1614 m at PlanEvery=3, 0 plan failures.
