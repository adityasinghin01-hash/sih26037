# CODEX JOB 04 — Confirm exactly how S2 is broken

## Why
S2 (the chowk/gyratory) is the project's one known-broken scenario. The last measurement was
10 Sep. The team presents tomorrow. **We need today's number, not September's**, because the
project's rule is to disclose the bug before a judge finds it — and we cannot disclose a
figure we have not re-run.

## Known prior result (10 Sep) — do NOT assume it still holds, re-measure
- Ground truth: grazes the wrong-way rider at **−0.003 m** at t = 17.65 s
- Real sensing: collides at **−0.909 m** at t = 12.70 s
- **In both cases** the planner then permanently stalls at s ≈ 116–121 m of a 244 m route
  and never reaches the ring exit

## Steps
Run `matlab/s2_planner_run.m` under BOTH sensing conditions. The two fail differently — a
ground-truth-only run misses half the picture.
```
/Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); SENSED=false; run('matlab/s2_planner_run.m')"
/Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); SENSED=true;  run('matlab/s2_planner_run.m')"
```
**The variable is `SENSED`, uppercase** — verified by reading the script's header. A
lowercase `Sensed` is silently ignored and you get the default (`SENSED=true`), i.e. two
identical sensed runs and no ground-truth comparison at all. There is also `INLOOP`
(default true) and `PLAN_EVERY` (default 1); leave both alone.

## Report
For each condition: minimum separation and the time it happened, the station (s) where the
ego stopped advancing, total route length, and whether it ever reached the exit.

Then one plain-English paragraph: **what a judge would see if we ran S2 live tomorrow.**

## Hard rules
- **Do not fix S2.** It defeated a dedicated person on a dedicated sprint. Measuring is the
  whole job.
- Never edit anything. No commits, no pushes.
- Report the whole error if it fails, first line to last.
