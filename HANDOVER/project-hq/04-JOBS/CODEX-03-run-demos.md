# CODEX JOB 03 — Run the real demos end to end and capture the evidence

## Context
Repo `/Users/aditya/dev/sih2026`, branch `main` at `f4d1f79`, clean. MATLAB R2026a at
`/Applications/MATLAB_R2026a.app/bin/matlab`, always `-batch`. **Do not run any git command
that writes** — the sandbox blocks `.git` writes. Read-only git is fine.

`matlab/demo_play.m` is THE demo — the real planner driving a real route. It computes the
plan once, caches it, then plays it back at true speed. Cached runs already exist in
`matlab/renders/demo_*.mat`; that is why playback is fast. **Do not delete that folder.**

## Goal
Prove all three scenarios still run, and capture the numbers each one produces.
**Fix nothing. Change no behaviour.**

## Steps — one MATLAB at a time, this machine has 8 GB of RAM
1. **S1, the headline run:**
   ```
   /Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); R = demo_play('demo1'); disp(R);"
   ```
2. **S3, the galli:** same, with `demo_play('demo3')`.
3. **S1 under real sensing** (this is the claim that sensing does not change the headline):
   ```
   ... demo_play('demo1', Sensed=true) ...
   ```
4. After each run, find the newest folder under `results/` and print all three files it
   wrote: `metrics.json`, `config.json`, and the first 3 lines of `trajectories.csv`.

## Report — write it to the output file
For each of the three runs:
- did it complete the full route, yes or no
- the full `metrics.json` contents (M1–M10, RouteLength, BarrierViolations and
  BarrierViolations_Imminent — report BOTH, they mean different things)
- number of plan failures, and any NaN or Inf
- wall-clock time
- the exact `results/<run>/` folder name it produced

Then state plainly:
- **does S1 still give 0.965 m clearance each side, full route?** If the number moved, say
  the new number — do not round it to the expected one.
- **does S1's number hold under `Sensed=true`?**
- **does S3 still clear the motorcycle, child and dog** (expected separations +0.175 m /
  +0.999 m / +0.550 m)?

## Hard rules
- **Never edit `matlab/baseline/`, `AGENTS.md`, `demo_play.m`, or anything in `matlab/+sih/`.**
- No commits, no pushes, no fixes. If a run fails, report the whole error, first line to last,
  and stop. Do not attempt a fix.
- **Never invent a number.** `TODO(unverified)` is a complete answer.
- If a number differs from what this brief expects, **report the number you got.** A number
  that matches expectations because you assumed it is worse than useless here.
