# CODEX JOB 07 — Phase 5: make the ML predictor actually gate decisions

## DO NOT RUN MATLAB. You cannot. Write the code; Claude runs it.
`Incompatible processor... requires neon`, exit 137. Confirmed 3x. Also no git writes.

## The situation
`matlab/+sih/+prediction/predictYield.m` enforces `Valid = false` by default, so the planner
NEVER uses the model - it always falls back to geometric right-of-way. That fallback is
CORRECT and must stay, because the model fails its own pre-registered bar. But right now the
fallback is the ONLY path, which means four trained models are decoration.

## The real numbers - use these, the repo is wrong everywhere else
- dangerous-error rate **2.089%**, 95% CI **[1.315%, 2.854%]**, measured 11 Sep on a
  233-clip / 694,864-sample test set opened exactly once
- pre-registered bar: **<= 1.00%**. The CI upper bound 2.854% exceeds it, so `Valid=false`
  is the honest call
- Safe-GO coverage 10.478% (72,806 GO decisions)
- Platt calibration: ECE 0.1117 -> 0.0091
- **The repo says 20.18% in every document. That is stale by 10x.** Source of truth:
  `~/dev/sih2026-hq/05-ASSETS/round2_final_handoff.md`

## The job - build the gated path, do not force the gate open
Read `matlab/+sih/+prediction/predictYield.m` and `matlab/+sc/planSeat.m` (its header says
"S3 = Valid:false for every track (Models 1&2 gated off - level 4)").

Build a **per-track confidence gate** so the planner can use the prediction where the model
is demonstrably reliable and fall back where it is not, instead of all-or-nothing:

1. A function that, given a track and the model's calibrated `PYield`, returns one of
   `USE` / `FALLBACK`, with the reason as a string.
2. The gate must be **conservative by construction**: `FALLBACK` on anything not positively
   established - missing history, a non-negotiating class (cow, dog), NaN inputs, or a
   calibrated confidence inside the uncertain band.
3. Wire it so `planSeat` can consume `Valid=true` tracks when the gate allows, with the
   geometric role as the fallback exactly as today. **Do not change
   `matlab/+sih/+planner/` behaviour when every track is FALLBACK** - that path is the
   already-verified one and must stay bit-identical.
4. Log per step how many tracks were USE vs FALLBACK, so the demo can show it honestly.

## The honesty requirement - this is not optional
The panel and any output must be able to say: *"the predictor is advisory; it gated ON for
N of M tracks; the planner's motion still rests on the physical barrier."* Never let this
turn into "our ML drives the car."

## Report
- every assumption you could not verify by reading
- which line you expect to break first
- exactly which existing behaviour you believe is unchanged, and why

## Hard rules
Never edit `matlab/baseline/`, `AGENTS.md` §3, `demo_play.m`, or anything S2. Never invent a
number. No commits.
