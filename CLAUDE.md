# CLAUDE.md — read this before you touch anything

**Read [`HANDOFF.md`](HANDOFF.md) first** — it is dated, it says what changed and what each person
does next, and it is short. Tell your human what is in their section before doing anything else.

**Then read `AGENTS.md`. Its section 3 is the frozen contract** and it is the reason six people
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

**`TEAM.md` is the one-page version of this section** — point the person there when they ask
who does what, rather than re-explaining.

**Two streams are handed out through this repository. The World is not.** Stream C works from
`ml/`, streams D and E work from `plan/`. **The World — the scenarios and the sensing — is
Aditya's own work**, coordinated by call rather than through the repo, so there is no folder to
send anyone to and no task list here to follow.

It still matters to everyone else, because **the World produces `S1 TrackList`** — the single
interface the planner consumes, frozen in `AGENTS.md` section 3. That is why the two halves of
the team cannot break each other. Treat `S1` as arriving from Aditya.

| Stream | Owns | Files they own |
|---|---|---|
| **The World** *(Aditya — not handed out)* | Scenarios, roads, junction, galli, ghat, cow, pedestrians · lidar, radar, tracking, the near-field ring · produces **`S1`** and **`S9`** | `matlab/+sih/+scenario/`, `matlab/+sih/+perception/` |
| **C · Prediction (ML)** | METEOR, the yield models, ONNX export, the 3 MATLAB models | `ml/`, `matlab/+sih/+models/`, `matlab/+sih/+prediction/` |
| **D · Planner** *(Role 2)* | The brain: roles, barriers, contingency paths, Stateflow | `matlab/+sih/+planner/`, the Simulink model |
| **E · Evidence** *(Role 2)* | Three baselines, metrics, the report | `matlab/+sih/+metrics/`, `matlab/baseline/` |
| **F · Integration** | Aditya. Merging, the demo, the pitch | everything, but he reviews rather than writes |

**Stream D is two people and they do NOT share files.**

| | Person A | Person B |
|---|---|---|
| Writes | `matlab/+sih/+planner/*.m` — pure functions, testable without Simulink | the Simulink model and Stateflow chart |
| Branch | `stream-d-a` | `stream-d-b` |
| Must never touch | the `.slx` model | `+planner/*.m` |

**A Simulink `.slx` is a binary file. Two people editing it cannot merge** — one person's work is
simply lost. That is why B is the only one who opens it.

### The two big folders are separate on purpose

| If you are doing | Read | **Do not open** |
|---|---|---|
| machine learning | `ml/ReadThis.md`, `ml/ML.md` | `plan/`, `matlab/+sih/+planner/`, the Simulink model |
| the planner | `plan/ReadThis.md`, `plan/CONTRACT-AB.md` | **`ml/`**, `matlab/+sih/+prediction/`, `+models/` |

**They meet at the contract and nowhere else.** The planner consumes `S3 PYield`; it never opens
the model that produced it. The ML stream produces `S3`; it never opens the planner. If one side
thinks the other is wrong, that is a message to a human, not a reason to go and read their files.

Reading across that line is how two people end up with two different versions of the same thing
and nobody knows which one the demo used.

**Make the line real — install your fence.** `.claude/fences/` holds one small permission file per
stream. Copy the one for your stream to `.claude/settings.local.json` and the boundary stops
depending on anyone reading this carefully:

```bash
cp .claude/fences/ml.settings.local.json      .claude/settings.local.json   # Stream C
cp .claude/fences/planner.settings.local.json .claude/settings.local.json   # Stream D
```

Tested 1 Sep 2026: with the planner fence on, a read of `ml/ReadThis.md` is refused outright, and
`plan/ReadThis.md` still opens. It covers `cat`/`head`/`sed` in Bash too. Stream E and Aditya
install neither — integration and the World have to read everything.
Full note: `.claude/fences/README.md`.

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
- `matlab/+sih/+planner/`: `assignRoles`, `velocityObstacle`, `chooseVelocity` (D2, merged
  3 Sep) and `NegotiatingStrategy`
- **Test counts, re-run 4 September 2026 21:xx:** `main` = **51 tests, 50 pass, 1 fail**.
  `stream-d-a` = **214 tests, 213 pass, 1 fail, 0 skipped**. The old "42 passing" counted only
  three of the five files. **`OpenTrafficLab/` must be cloned into the repo root or 7 tests
  silently SKIP** (206 instead of 213) — a skip is not a pass. The `.m` extension is required for
  a FILE — `runtests('.../testX')` without it errors `MATLAB:unittest:TestSuite:UnrecognizedSuite`;
  the folder form `runtests('matlab/tests')` is fine without it
- **OpenTrafficLab runs, but NOT unmodified** on R2026a. Two fixes, both outside their folder.
  See `plan/OPENTRAFFICLAB-R2026a.md` before debugging any harness failure

### Written and CHECKED AGAINST DOCS, never executed — treat as unverified
- `matlab/+sih/+prediction/buildFeatureFrame.m` and `matlab/tests/testFeatureParity.m`
- `matlab/+sih/+models/` — the three MATLAB trainers
- `derisk/check04_onnx_lstm.m`

**Defects keep being found in this category — seven on 4 September 2026 alone**, two of which
stopped the simulation running at all. Function names and signatures were verified against the
MathWorks documentation, but **verified by reading is not verified.** `/first-run` exists to
close this. Expect it to find something.

### Built on a BRANCH, not yet on `main` — say which branch when you quote it
- **`stream-d-a`** (12 ahead of `main`, no PR open as of 4 Sep 22:00): **D6 and D8** —
  `planContingency`, `generateCandidates`, `predictAgentFutures`, `checkTrajectorySafety`,
  `findSharedTrunk`, `checkTerminalStop`, `followTrunk`, `roadBarrier`, `speedLimit`.
  Trunk mode **"B" is the default**. 214 tests.
- **`stream-d-b`** (3 ahead, **20 behind** `main`): `sih_planner.slx` — 38 blocks, Stateflow chart
  with seven outputs, a vehicle model and an `h` calculation. **Loads with 0 unresolved refs and
  simulates in 47 s on the Mac.** It is the only harness that actually consumes `SteerAngle` —
  see `plan/HARNESS-STEERING-FINDING.md`.

### Not built at all
- Everything in `matlab/+sih/+scenario/`, `+perception/`, `+metrics/`
- `matlab/+sih/+planner/` **D9, D10, D11** — reversibility, turns, handover
- **`arbitrate.m`** — ruled in `plan/ARBITRATION-RULING.md`, not yet written. It is what wires
  `chooseVelocity` into `NegotiatingStrategy.m:105`

### RUN, and the result was a finding
- **`matlab/baseline/` HAS been run — and it FAILS.** It dies **19.7 s** into its own shipped
  scenario at MathWorks' own `error()`, **0 of 120 candidates collision-free**, identically on
  macOS/Apple Silicon and Windows x86 under R2026a Update 5. **That is the result. Never edit
  that folder to make it survive.** `plan/BASELINE-R2026a.md`.
- **The planner DRIVES in the backup demo** — `~/Desktop/SIH26037-Reference/build/backup/` calls
  the real `sih.planner.*` unmodified and completes a 610 m route. **But the probe never fires,
  S1 contains a collision at 0.735 m, and the defensive stand-in currently beats us on both
  scenarios.** Read `plan/BACKUP-PROBE-FINDING.md` before repeating any demo claim.

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
| A stream's task list | inside its own folder: `ml/` or `plan/` |
| The de-risk checks | `derisk/HOW-TO-RUN.md` |
