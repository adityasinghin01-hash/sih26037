# Antigravity-specific rules

Read `AGENTS.md` first — it carries the project rules and applies to every tool. This file adds
only what is specific to working in Antigravity, and it overrides `AGENTS.md` on conflict.

## Open the repo root
`AGENTS.md` loads from the workspace root only. Open the whole repository, not a subfolder, or
the agent starts blind.

## Do not touch these files
- **Section 7 of `docs/PRD.md`** — the frozen contract. Four other people build against it. If you
  think it needs to change, stop and ask a human.
- `matlab/baseline/` — MathWorks' shipped planner, unmodified. Never edit, never "fix", never tune.
- **Section 8 of `docs/PRD.md`** — metrics, pre-registered before any run. Adding one invalidates it.

## Before proposing MATLAB code
Check **section 7 of `docs/PRD.md`** for the struct you are producing or consuming, and name it in your
function's header comment. If your function invents its own struct shape, it is wrong.

## Verification, not confidence
This project's pitch is that every claim is checkable. Do not write a number you have not
produced by running something. `TODO(unverified)` is an acceptable answer; a plausible-sounding
number is not.

## When you hit an error
Report it in full — the whole message, the whole stack. Do not summarise, do not paraphrase, do
not "clean it up". A trimmed error costs the team a day.
