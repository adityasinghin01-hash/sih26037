# CLAUDE.md — read this before you touch anything

**Read `AGENTS.md` next. Its section 3 is the frozen contract** and it is the reason six people
can work at once. Everything below is what `AGENTS.md` does not carry: who is doing what right
now, what actually exists, and what has never been run.

Antigravity users get four rules automatically from `.agents/rules/`. **You do not** — so the
important parts of them are in section 5 of this file. Read them.

---

## 1 · What this project is, in one paragraph

An Indian junction has no traffic light and no priority rule. Every self-driving car stops when
it is unsure, so it never gets through. We build a planner that **probes**: it creeps forward a
little, reads whether the other road user gave way, and commits — and it can prove it never
crossed its own safety boundary while doing it. Built in MATLAB and Simulink, against a cow that
behaves like a real cow. Smart India Hackathon 2026, problem statement **SIH26037** (MathWorks).

**Idea submission deadline: 20 September 2026.**

---

## 2 · Who is doing what — check this before editing any file

| Stream | Owns | Files they own |
|---|---|---|
| **A · World** | Scenarios, roads, junction, galli, ghat, cow, pedestrians | `matlab/+sih/+scenario/` |
| **B · Perception** | Lidar, radar, tracking, the near-field ring | `matlab/+sih/+perception/` |
| **C · Prediction (ML)** | METEOR, the yield models, ONNX export, the 3 MATLAB models | `ml/`, `matlab/+sih/+models/`, `matlab/+sih/+prediction/` |
| **D · Planner** | The brain: roles, barriers, contingency paths, Stateflow | `matlab/+sih/+planner/`, the Simulink model |
| **E · Evidence** | Three baselines, metrics, the report | `matlab/+sih/+metrics/`, `matlab/baseline/` |
| **F · Integration** | Aditya. Merging, the demo, the pitch | everything, but he reviews rather than writes |

**Stream D is two people and they do NOT share files.**

| | Person A | Person B |
|---|---|---|
| Writes | `matlab/+sih/+planner/*.m` — pure functions, testable without Simulink | the Simulink model and Stateflow chart |
| Branch | `stream-d-a` | `stream-d-b` |
| Must never touch | the `.slx` model | `+planner/*.m` |

**A Simulink `.slx` is a binary file. Two people editing it cannot merge** — one person's work is
simply lost. That is why B is the only one who opens it.

**Before you edit a file, ask whether it belongs to the stream you are working for.** If it does
not, say so in one sentence and stop. Acting across that line is the most expensive mistake
available in this repository.

---

## 3 · What actually exists right now

Be precise about this with the person you are helping. There are three states and they are not
the same thing.

### Built and RUN — trust it
- The whole ML pipeline: fetch, features, split, train, evaluate, ONNX export. Both yield models
- Three Python test suites: contract, parity fixture, evaluation metrics
- `matlab/+sih/+planner/`: `assignRoles`, `velocityObstacle`, `NegotiatingStrategy`, and
  **12 passing geometry tests** in `matlab/tests/testPlannerGeometry.m`

### Written and CHECKED AGAINST DOCS, never executed — treat as unverified
- `matlab/+sih/+prediction/buildFeatureFrame.m` and `matlab/tests/testFeatureParity.m`
- `matlab/+sih/+models/` — the three MATLAB trainers
- `derisk/check04_onnx_lstm.m`

**Four real defects have already been found in this category, plus two broken paths.** Function
names and signatures were verified against the MathWorks documentation, but **verified by reading
is not verified.** `/first-run` exists to close this. Expect it to find something.

### Not built at all
- Everything in `matlab/+sih/+scenario/`, `+perception/`, `+metrics/`
- `matlab/+sih/+planner/` D2 through D11 — the command, the contingency planner, the barriers,
  reversibility, turns, handover
- The Simulink model and the Stateflow chart
- **`matlab/baseline/` is EMPTY.** That is the competitor we compare against. Until MathWorks'
  shipped planner is in there, unmodified, **no number this project produces is comparable to
  anything.**

---

## 4 · The decisions already made — do not reopen them

`AGENTS.md` section 2 has the full list. The five that get re-argued most:

1. **No RoadRunner.** The licence does not include it. We build scenes in code and export
   OpenDRIVE. This is our one declared deviation from the problem statement.
2. **Lidar and radar in the loop, camera offline.** The cuboid simulator emits an object list,
   not pixels — a model that reads pixels would have nothing to look at while the car drives.
3. **Never edit `matlab/baseline/`.** A tuned baseline is a strawman and a judge will say so.
4. **Never change `AGENTS.md` section 3.** Six people build against it. Stop and ask a human.
5. **The features are 31 values in a frozen order.** Append only at 32+. Stream D reads them by
   position, so reordering breaks the planner silently, with no error.

---

## 5 · How to work here

### You are the guide, not just the coder
The person you are helping is a student on a hackathon team. **They may not write MATLAB — that
is normal here and it is why you exist.** End every piece of work with:

1. what you did, in one sentence, in plain words
2. **the exact command to run**
3. **what to look for in the output** — the specific line, not "check it worked"
4. what to do if it fails, which is almost always *send the whole error to Aditya*

Explain a technical word in the same breath you use it, once, inline.

### Say which kind of confidence you have
Three different things. Never blur them.

| | |
|---|---|
| **I ran it** | it executed and this is the output |
| **I checked the docs** | the signature matches. **It has never run** |
| **I believe** | say so, and say what would settle it |

### Never write a number you did not produce
`TODO(unverified)` is a complete answer. A plausible-sounding number is not.

### Never summarise an error
The whole message, the whole stack. A trimmed error costs the team a day.

### Do only what you were asked
Complete the one task, report, stop. When you notice a second problem, name it in one sentence
and wait. **Never create, rename or refactor a file nobody named.**

### Judge the size of a decision
A couple of gigabytes onto the machine you are already on is a normal part of the task, not a
decision. **Ask first** for a shared machine, tens of gigabytes, or anything nobody asked for.
A decision belongs to Aditya when it changes **what the project claims**, not when it spends a
little disk.

### The failure mode this project actually has
Almost nothing here crashes. It produces a number and the number is wrong. An ONNX file stamped
with the wrong opset. A rebuild that silently kept stale features. An ego speed of 557 m/s that
drowned every other input. **So when something succeeds, say what you verified, not that it
worked.**

---

## 6 · Commands

Type these. They live in `.claude/commands/`.

| Command | What it does |
|---|---|
| `/state` | Where the project is right now, and what is blocked |
| `/first-run` | Runs the MATLAB that has never been executed. **Do this first on a new machine** |
| `/plan-work` | Stream D **person A**: the planner functions, in build order |
| `/plan-harness` | Stream D **person B**: the Simulink loop and Stateflow chart |
| `/plan-test` | Runs the planner tests and explains what a failure means |
| `/ml-run` | Stream C: the whole yield-predictor pipeline |
| `/ml-parity` | Checks the Python and MATLAB feature builders still agree |
| `/ml-models` | Stream C: the three MATLAB-native models |

---

## 7 · Where things are

| You want | Look at |
|---|---|
| **The frozen contract** | **`AGENTS.md` section 3** |
| The planner's roadmap | `plan/ReadThis.md` |
| The ML stream's roadmap | `ml/ReadThis.md` |
| Errors we already hit, with real causes | `ml/TROUBLESHOOTING.md` |
| A stream's task list | `teammates/<letter>-<name>.md` |
| The de-risk checks | `derisk/HOW-TO-RUN.md` |
