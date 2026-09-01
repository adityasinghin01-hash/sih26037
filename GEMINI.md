# Antigravity-specific rules

Read `AGENTS.md` first — it carries the project rules and the frozen contract, and applies to
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
