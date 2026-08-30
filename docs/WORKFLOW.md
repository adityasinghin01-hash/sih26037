# How we work

The briefs say *what* to build. This says *how to work* so six people don't collide.

---

## 1 · Git — one branch per stream

**Never push to `main` directly.**

```bash
git checkout -b stream-a-world        # a-world, b-perception, c-prediction,
                                      # d-planner, e-evidence, f-visual
# ... work ...
git add -A
git commit -m "A2: OSM import working, 14 roads from Begum Bridge junction"
git push -u origin stream-a-world
```

Then open a pull request on GitHub. Aditya merges.

**Commit message format:** `<task-id>: <what changed>` — e.g. `B3: TrackList emits SensorMask`.
The task ID makes it obvious which brief item moved.

**Commit often.** A day of uncommitted work is a day you can lose.

**Before every push:**
```matlab
runtests('matlab/tests')     % MATLAB streams
```
```bash
python -m pytest python/tests   # Python streams
```
If it fails, fix it or say so in the PR. **Do not push red and hope.**

## 2 · Definition of done

A task is done when **all four** are true:

1. **It runs** — from a clean clone, following only what is written down
2. **A test covers it** — or, where a test is impossible, a script that prints the evidence
3. **It matches the contract** — the struct you produce is exactly `docs/INTERFACES.md`
4. **Someone else could run it** without asking you a question

"It works on my machine" is not done. "I know how to run it" is not done.

## 3 · Who needs what from whom

```
        A ──scenario──► B ──TrackList──► C ──opset number──► D
        │                │                                    │
        │                └──TrackList────────────────────────►│
        │                                                     │
        └─────────────────────────────────────────────────────┤
                                                              ▼
                                            E ──trajectories.csv──► F
```

| Handoff | From → To | The one thing that crosses |
|---|---|---|
| **H1** | A → B | A working scenario with actors, so sensors have something to see |
| **H2** | B → C, D | `TrackList` (S1). **Sensor-agnostic — nothing downstream knows which sensor saw what** |
| **H3** | **C → D** | **Which ONNX opset MATLAB accepts.** One number. Gates all in-loop integration |
| **H4** | C → D | The trained `.onnx` file |
| **H5** | A,B,C,D → E | A pipeline that runs end to end, so it can be measured |
| **H6** | E → F | `results/<run>/trajectories.csv` — MATLAB computes, Blender only renders |

**When you complete a handoff, say so in the group.** Name the handoff ID. The person waiting
does not know you are done unless you tell them.

**If you are blocked on a handoff, do the parts that don't depend on it.** Every brief is ordered
so the independent work comes first.

## 4 · Reporting

**Errors come back in full.** The whole message, the whole stack trace. Never a summary, never a
screenshot crop, never "it says something about a null pointer."

A trimmed error costs the team a day. This is the single most expensive habit to get wrong.

**When you report progress, use the task ID:**
> *"A2 done — OSM import works, 14 roads. A3 blocked: need check02 to pass first."*

**Stop at the first failure and report it.** Do not push past a broken step and hope the next one
works — you will be debugging two problems instead of one.

## 5 · What a work session looks like

1. `git pull origin main` and rebase your branch
2. Open the repo **root** in your IDE (Antigravity needs the root for `AGENTS.md` to load)
3. Open your brief. Find the lowest-numbered task not yet done
4. Read the relevant section of `docs/INTERFACES.md` **before** writing code
5. Build the smallest thing that runs. Run the tests
6. Commit with the task ID
7. Report what moved and what is blocked

## 6 · When the contract is not enough

`docs/INTERFACES.md` is frozen. If you genuinely need it changed:

1. **Stop.** Do not edit it
2. Say what you need and why, in the group
3. Aditya decides. If accepted, it gets a row in `docs/CHANGELOG.md` and everyone is told

**If your AI agent proposes editing `docs/INTERFACES.md` or anything in `matlab/baseline/`, the
answer is no.** Both are load-bearing for other people.

## 7 · Working with your agent

**It writes code. You verify it.** The division that matters:

| Agent does | You do |
|---|---|
| Writes functions against the contract | Decides whether the output is actually right |
| Boilerplate, parsing, plumbing | Runs it and reads the errors |
| Refactoring, tests | Judges whether a scenario feels like a real Indian road |
| Documentation | Training runs, dataset downloads, anything with a real cost |

**Never let an agent invent a number.** If it writes a figure into a doc or a comment, check that
something produced it. `TODO(unverified)` is an acceptable answer; a plausible-sounding number is
the thing that loses hackathons.

## 8 · The five rules, again

1. Never edit `matlab/baseline/`
2. Never invent a number — if it is not in `docs/CLAIM-LEDGER.md`, do not say it
3. Never change `docs/INTERFACES.md` without a changelog row
4. Nothing ships with a bug already reproduced in the demo flow
5. Errors are reported in full
