# SIH26037 — negotiating at unsignalled Indian junctions

**Smart India Hackathon 2026 · MathWorks · Smart Vehicles**

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

---

## Start here

1. **Read the PRD.** It is distributed as a PDF — ask Aditya. Problem, solution, what the judge
   sees, the metrics, and what we are allowed to claim.
2. **Open your own file in [`teammates/`](teammates/)** and follow it from the top. Each is
   self-contained: installing everything, how to work, what to build, who is waiting on you.
3. **Read section 3 of [`AGENTS.md`](AGENTS.md)** before writing code — the frozen contract.
4. **The first time you have MATLAB on a machine, run [`/first-run`](.agents/workflows/first-run.md).**
   Most of the MATLAB here has been checked against the MathWorks documentation but **never
   executed**. That workflow runs it in the right order and tells you what to look for.

**Open the repository root in your editor, not a subfolder.** `AGENTS.md`, `GEMINI.md` and
everything in `.agents/` only load from the root, and without them your AI assistant works blind.

## Ask your AI assistant for these by name

Type the slash command in Antigravity, or just open the file and tell your agent to follow it.

| Command | What it does |
|---|---|
| **`/first-run`** | Runs the MATLAB that has never been executed, in order. **Do this first.** |
| **`/ml-run`** | The whole yield-predictor pipeline: features → train → evaluate → export |
| **`/ml-parity`** | Proves the Python and MATLAB feature builders still agree |
| **`/ml-models`** | The three MATLAB-native models: YOLOX, DeepLab v3+, PointPillars |
| **`/plan-work`** | Stream D person A: the planner functions, in build order |
| **`/plan-harness`** | Stream D person B: the Simulink loop and Stateflow chart |
| **`/plan-test`** | The 12 planner geometry tests, and what a failure means |
| **`/state`** | Where the project is right now, and what is blocked |

Antigravity reads `.agents/workflows/`; Claude Code reads `.claude/commands/`. **Both are kept
in sync**, so either tool gets the same commands.

## How the team is organised

The five streams are grouped into **two roles**. This is the split that matters day to day —
the streams still describe *what* is owned, but the roles describe *who works together*.

| Role | Streams | What it is |
|---|---|---|
| **1 · The World** | **A + B** | Everything the car drives in, and everything it sees |
| **2 · The Driver** | **D + E** | Everything the car decides, and the proof it works |
| Stream C · ML | on its own | Mostly running workflows now — see [`ml/ReadThis.md`](ml/ReadThis.md) |
| Stream F · Integration | Aditya | Merging, the demo, the pitch, on the main machine |

**Why grouped this way**

- **Sensors go with scenarios, not with the planner.** A sensor is meaningless without actors to
  point at, so the same pair builds both and the handoff that usually kills small teams does not
  exist.
- **Metrics go with the planner, not on their own.** You cannot measure a planner you do not
  understand. An isolated metrics person measures the wrong thing.
- **There is exactly ONE interface between the two roles: `S1 TrackList`.** It is frozen in
  `AGENTS.md` section 3, so the two halves cannot break each other.

**Role 1 is the critical path** — nobody can test anything until a scenario exists.
**Role 2 is not blocked**, because the baseline can be cloned today.

### Two jobs that need nobody and are blocking everyone

1. **Fill `matlab/baseline/`** *(Role 2)* — clone MathWorks' shipped planner, **change nothing**.
   It is currently EMPTY. Until it is there, no number this project produces is comparable to
   anything and the "we beat the baseline" claim has nothing behind it. This is a
   clone-and-don't-touch job, not a build.
2. **The RoadRunner licence email** *(Aditya)* — the one problem-statement requirement we cannot
   currently meet.

| Stream | Owns | File |
|---|---|---|
| **A** | Scenarios, roads, junctions · **Role 1, with B** | [`teammates/A-world.md`](teammates/A-world.md) |
| **B** | Lidar, radar, tracking · **Role 1, with A** | [`teammates/B-perception.md`](teammates/B-perception.md) |
| **C** | Dataset, LSTM, training | **[`ml/ReadThis.md`](ml/ReadThis.md)** — start here, then [`teammates/C-prediction.md`](teammates/C-prediction.md) |
| **D** | The negotiating planner · **Role 2, with E** | **[`plan/ReadThis.md`](plan/ReadThis.md)** — start here, then [`teammates/D-planner.md`](teammates/D-planner.md) |
| **E** | Baseline, metrics, results · **Role 2, with D** | [`teammates/E-evidence.md`](teammates/E-evidence.md) |

## Layout

```
AGENTS.md           project rules + THE FROZEN CONTRACT (section 3)
GEMINI.md           Antigravity-specific rules
teammates/          five workstream files, one each
CLAUDE.md           what Claude Code loads - who owns what, and the build state
.claude/commands/   slash commands for Claude Code
plan/               THE PLANNER STREAM'S HOME
plan/ReadThis.md    the roadmap for Stream D
plan/CONTRACT-AB.md the boundary between its two people
ml/                 THE ML STREAM'S HOME
ml/ReadThis.md      the roadmap - read this first if you are Stream C
ml/CHEATSHEET.md    every command, in order
ml/TROUBLESHOOTING.md  errors we already hit, and what they really mean
ml/python/          dataset pipeline, both yield models, ONNX export
matlab/+sih/        planner, prediction, models, util
.agents/rules/      loaded automatically by your agent
.agents/workflows/  slash commands - see the table above
matlab/baseline/    MathWorks' shipped planner - NEVER EDIT
                    EMPTY as of 1 Sep 2026, and git does not track empty folders, so a
                    fresh clone will not have it at all. Stream E adds the baseline.
matlab/tests/       run these first
ml/derisk/             the checks that gate the build
blender/            rendering
```

## Five rules

1. **Never edit `matlab/baseline/`** — a tuned baseline is a strawman and kills the result
2. **Never invent a number** — if you did not run something to get it, do not write it
3. **Never change section 3 of `AGENTS.md`** without telling everyone
4. **Nothing ships with a bug already reproduced in the demo flow**
5. **Errors are reported in full** — never a summary

## Credits

Built on [`mathworks/OpenTrafficLab`](https://github.com/mathworks/OpenTrafficLab).
METEOR dataset (Chandra et al., ICRA 2023). COLREGs formulation after Kuwata et al. and
Tam & Bucknall. Cattle parameters from published GPS-collar studies.
3D assets CC-Attribution (Sketchfab); environment maps CC0 (Poly Haven).
**Borrow freely, cite loudly.**
