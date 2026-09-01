# The fences — how to make the stream boundary real

`CLAUDE.md` and `AGENTS.md` **ask** an agent to stay inside its stream. These two files **stop
it**. Pick the one for your stream, copy it, and the boundary stops depending on anyone reading
a document carefully.

## Install yours — one command, once

**Stream C (ML — METEOR, the yield models, ONNX):**

```bash
cp .claude/fences/ml.settings.local.json .claude/settings.local.json
```

**Stream D (planner — Person A and Person B both):**

```bash
cp .claude/fences/planner.settings.local.json .claude/settings.local.json
```

Restart Claude Code. That is all. **Do not commit `.claude/settings.local.json`** — it is
personal, and it is already in `.gitignore`.

Streams A, B, E and Aditya install neither. Integration has to read everything.

## What it actually does

A `deny` rule refuses the read before it happens. It covers the file tools **and** `cat`, `head`,
`tail` and `sed` run through Bash, and it applies the moment the file exists — no approval step,
no trust prompt.

**What it does not cover:** a script that opens files itself, such as a Python or Node program.
Nothing here is a security control. It is a guard rail against the honest mistake — the agent
that wanders into the next stream's folder while trying to be helpful, and quietly builds on a
second copy of something that already exists.

## Everyone gets one rule, whether they install a fence or not

`.claude/settings.json` is committed, so every clone gets it:

```json
"deny": ["Edit(/matlab/baseline/**)"]
```

**`matlab/baseline/` is the competitor we measure ourselves against.** A tuned baseline is a
strawman and a judge will say so. Reading it is fine and necessary. Changing it invalidates every
number this project reports, so nothing may edit it — including Aditya, including by accident.

## If a fence blocks something you genuinely need

Do not edit your local file to punch a hole in it. **That is the moment to message a human** —
either the contract is missing something, or the work has drifted into someone else's stream.
Both are worth ten minutes of a person's time.
