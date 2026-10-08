# CODEX JOB 01 — Prove the MATLAB side is green, end to end

## Context
Repo: `<repo-root>`. MATLAB + Python project (SIH26037, a self-driving
planner for unstructured Indian roads). MATLAB R2026a lives at
`/Applications/MATLAB_R2026a.app/bin/matlab`. Always run it with `-batch`, never interactively.

## Goal
Bring the checkout onto current `origin/main` and prove the MATLAB half runs green.
Report exact numbers. **Fix nothing. Commit nothing. Push nothing.**

## Steps
1. `git fetch`. Record the current branch and HEAD short SHA.
2. Switch to `main` and fast-forward to `origin/main`.
   - **Do NOT delete or modify `matlab/renders/`** — it is gitignored and holds the two
     finished demo films and the cached planner recordings. Losing it costs the demo fallback.
   - **Do NOT touch `matlab/baseline/`** — it is MathWorks' shipped planner, kept unmodified
     on purpose. Editing it destroys the project's central comparison result.
3. Confirm `OpenTrafficLab/` exists at the repo root. If missing:
   `git clone https://github.com/mathworks/OpenTrafficLab.git`
   Without it, 9 tests silently report Incomplete instead of running.
4. Run the full suite from the repo root:
   ```
   /Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); addpath(genpath('OpenTrafficLab')); r = runtests('matlab/tests','IncludeSubfolders',true); fprintf('TOTAL=%d PASS=%d FAIL=%d INCOMPLETE=%d\n', numel(r), sum([r.Passed]), sum([r.Failed]), sum([r.Incomplete]));"
   ```
   If `runtests` on the folder errors, fall back to running each file individually —
   `runtests('matlab/tests/testPlannerGeometry.m')` — the `.m` extension is required, its
   absence is a known MATLAB quirk, not a broken test.
5. Verify the baseline is untouched: `git status --short matlab/baseline/` must print nothing.

## Report — write it to the output file
- branch and HEAD, before and after
- the exact `TOTAL= PASS= FAIL= INCOMPLETE=` line
- **every failing test by name, with its full error text, first line to last.
  Never summarise or trim an error** — a trimmed error costs a day
- whether `matlab/renders/` still holds `S1_cattle_crossing.mp4`, `S2_the_chowk.mp4`
  and the `demo_*.mat` cache files

## Hard rules
- Never edit `matlab/baseline/` or section 3 of `AGENTS.md`.
- No commits, no pushes, no fixes, no "while I was there" changes.
- Never invent a number. If you did not run it, write `TODO(unverified)`.
- If anything is ambiguous, stop and write down what you found.
