# Antigravity-specific rules

**Read [`HANDOFF.md`](HANDOFF.md) first** — dated, one section per person, says what changed and
what to do next. Tell your human what is in their section before doing anything else.

Then read `AGENTS.md` — it carries the project rules and the frozen contract, and applies to
every tool. This file adds only what is specific to Antigravity, and overrides `AGENTS.md` on
conflict.

## Open the repo root
`AGENTS.md` loads from the workspace root only. Open the whole repository, not a subfolder, or
you start blind — wrong function names, invented APIs, edits that break other people's work.

## Do not touch
- **Section 3 of `AGENTS.md`** — the frozen contract. Everyone else on the team builds against it.
  If you think it needs changing, stop and ask a human
- **`matlab/baseline/`** — MathWorks' shipped planner, unmodified. Never edit, never "fix", never tune

## Before proposing MATLAB code
Check section 3 of `AGENTS.md` for the struct you are producing or consuming, and name it in your
function's header comment. If your function invents its own struct shape, it is wrong.

## Verification, not confidence
Do not write a number you have not produced by running something. `TODO(unverified)` is an
acceptable answer; a plausible-sounding number is not.

## Errors
Report them in full — the whole message, the whole stack. Never summarise. A trimmed error costs
the team a day.

## Two things that will waste your day if you do not know them

**`runtests` needs the `.m`.** `runtests('matlab/tests/testPlannerGeometry.m')` works;
without the extension MATLAB reads it as a folder and errors with
`MATLAB:unittest:TestSuite:UnrecognizedSuite`. It is not a broken test file.

**OpenTrafficLab does not run unmodified on R2026a.** Stock `DrivingStrategy` dies on the
first `advance()` with `MATLAB:noSuchMethodOrField ... 'ReferencePoint'`. Two fixes, both
outside `OpenTrafficLab/`, both already applied. Read `plan/OPENTRAFFICLAB-R2026a.md` before
debugging any harness failure, and **never edit `OpenTrafficLab/`** — it is gitignored
third-party code and every teammate has their own clone.

## Current test counts, re-run on 4 September 2026 at 21:xx
`main` = **51 tests, 50 pass, 1 fail**. `stream-d-a` = **214 tests, 213 pass, 1 fail, 0 skipped**.
The old "42 passing" counted only three of the five files.
**`OpenTrafficLab/` must be cloned into the repo root**, or 7 `testNegotiatingStrategy` tests
report as Incomplete (skipped) and the total reads 206. **A skip is not a pass.**
**Re-run before quoting any of these.** The count has now been wrong in the docs four times.
