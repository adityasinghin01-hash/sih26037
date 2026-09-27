# ANTIGRAVITY JOB 01 — Correct the project's stale ML numbers

## Why this exists
The project's own documents quote a **20.18% dangerous-error rate** for the yield
predictor, measured 4 Sep 2026. On 11 Sep the ML stream re-measured it properly and got
**2.089%**. Nobody propagated the new number. The team is currently walking into a jury
quoting a figure that makes them look ten times worse than they are.

## Read these three files (read-only, do not edit them)
1. `/Users/aditya/dev/sih2026-hq/05-ASSETS/round2_final_handoff.md` — the 11 Sep ML
   handoff. This is the source of truth for the new numbers.
2. `/Users/aditya/dev/sih2026/plan/CLAIM-LEDGER.md` — the project's rulebook for what may
   be said out loud. It carries the stale 20.18% figure.
3. `/Users/aditya/Desktop/SIH26037-Archive/SIH26037-Idea-PPT-Source.md` — the slide source.
   Check whether it also carries stale numbers.

## What to produce
**Write exactly one new file:**
`/Users/aditya/dev/sih2026-hq/REPORTS/AGY-01-claim-ledger-corrections.md`

**Do not edit anything inside `/Users/aditya/dev/sih2026`.** Another agent is running git
operations in that repo right now. Your output is a proposal, not an edit.

In that file, give:
1. **Every place** the stale 20.18% (or any other superseded ML figure) appears, with file
   path and line number.
2. For each one, the **exact replacement sentence**, written in the same voice as the
   surrounding document.
3. The new numbers, each with its source and date. At minimum these, verified against the
   handoff, not assumed:
   - dangerous-error rate, point estimate and 95% confidence interval
   - what the pre-registered safety bar is, and whether the new figure clears it
   - what the system therefore does (the `Valid=false` fallback)
   - the YOLOX domain-adaptation result
   - the calibration result (ECE before and after)
4. **A short honesty section:** what is still NOT true even with the better number. The
   new figure still fails the project's own bar — say so plainly and say what that means.
   Do not let a better number turn into a claim the evidence does not support.

## Hard rules
- **Never invent a number.** If the handoff does not state it, write `TODO(unverified)`.
- Do not touch the repo. One output file, in the path given above.
- Do not run MATLAB. Another agent is using it.
- Precision over volume. This file gets read under time pressure.
