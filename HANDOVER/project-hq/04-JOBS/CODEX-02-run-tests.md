# CODEX JOB 02 — Run the MATLAB test suite and report exact numbers

## State you are starting from (already done, do not redo)
Repo `/Users/aditya/dev/sih2026` is on branch `main` at `f4d1f79`, clean, up to date with
origin. `OpenTrafficLab/` is present at the repo root. Do not run any git command that
WRITES (no fetch, pull, checkout, commit, push) — the sandbox blocks `.git` writes and it
will fail. Read-only git (`git status`, `git log`) is fine.

## Goal
Prove the MATLAB half runs green. Report exact numbers. **Fix nothing.**

## Steps
1. From the repo root, run the full suite:
   ```
   /Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); addpath(genpath('OpenTrafficLab')); r = runtests('matlab/tests','IncludeSubfolders',true); fprintf('TOTAL=%d PASS=%d FAIL=%d INCOMPLETE=%d\n', numel(r), sum([r.Passed]), sum([r.Failed]), sum([r.Incomplete]));"
   ```
   MATLAB is slow to start on this machine — allow several minutes before assuming it hung.
   If `runtests` on the folder errors, fall back to running each `matlab/tests/test*.m` file
   individually. The `.m` extension is required; its absence is a known MATLAB quirk, not a
   broken test.
2. Then confirm the planner package itself loads and the frozen contract is reachable:
   ```
   /Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); d = sih.planner.defaults(); disp(d); fprintf('PLANNER_OK\n');"
   ```
3. Read-only check: `git status --short matlab/baseline/` must print nothing.

## Report — write it to the output file
- the exact `TOTAL= PASS= FAIL= INCOMPLETE=` line
- **every failing or incomplete test by name, with its full error text, first line to last.
  Never summarise or trim an error.**
- whether `PLANNER_OK` printed, and the defaults struct it showed
- total wall-clock time the suite took

## Hard rules
- Never edit `matlab/baseline/`, `AGENTS.md`, or any test file.
- No commits, no pushes, no fixes. Report only.
- Never invent a number. If you did not run it, write `TODO(unverified)`.
- Do not start more than one MATLAB at a time — this machine has 8 GB of RAM.
