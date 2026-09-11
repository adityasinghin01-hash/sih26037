# SIH26037 — negotiating at unsignalled Indian junctions

**Smart India Hackathon 2026 · MathWorks · Smart Vehicles**

> An Indian junction has no controller. We built the planner that negotiates instead of waiting —
> in MATLAB, where no public work we could find has built one, against a cow that behaves like a cow.

---

## Start here

**0a. Read [`HANDOFF.md`](HANDOFF.md) — what's true right now, and what YOU do next.**
One section per person, and the fastest way back into the project.

**0b. Read [`TEAM.md`](TEAM.md).** One page: who is doing what, what nobody may touch, and which
single file you open.

1. **Read the PRD.** It is distributed as a PDF — ask Aditya. Problem, solution, what the judge
   sees, the metrics, and what we are allowed to claim.
2. **Open your own folder and read the `ReadThis.md` at the top of it.** There are two:
   [`ml/`](ml/) for the ML track, [`plan/`](plan/) for the Planner track. Everything your track
   needs is inside one of them — installing, how to work, what to build, who is waiting on you.
   You do not need the other one.
   *(The World — the scenarios and the sensing — is Aditya's own work and is not handed out here.
   It still produces `S1 TrackList`; treat that as arriving from him.)*
3. **Read section 3 of [`AGENTS.md`](AGENTS.md)** before writing code — the frozen contract.
4. **The first time you have MATLAB on a machine, run [`/first-run`](.agents/workflows/first-run.md).**

**Open the repository root in your editor, not a subfolder.** `AGENTS.md`, `CLAUDE.md`,
`GEMINI.md` and everything in `.agents/` only load from the root, and without them your AI
assistant works blind.

## Ask your AI assistant for these by name

Type the slash command in Antigravity, or just open the file and tell your agent to follow it.
The same commands work whether your assistant is Claude Code, Antigravity, Gemini, or Codex —
they all read `AGENTS.md` from the repo root.

| Command | What it does |
|---|---|
| **`/first-run`** | Runs the MATLAB that has never been executed, in order. **Do this first.** |
| **`/ml-run`** | The whole yield-predictor pipeline: features → train → evaluate → export |
| **`/ml-parity`** | Proves the Python and MATLAB feature builders still agree |
| **`/ml-models`** | The three MATLAB-native models: YOLOX, DeepLab v3+, PointPillars |
| **`/plan-work`** | The planner functions, in build order |
| **`/plan-harness`** | The Simulink loop and Stateflow chart, if that piece of work is still live — check `HANDOFF.md` |
| **`/plan-test`** | The planner test suite, and what a failure means |
| **`/state`** | Where the project is right now, and what is blocked |

## How the team is organised

**Full detail in [`TEAM.md`](TEAM.md).** The short version:

**Three independent tracks**, not shared streams — the World (Aditya's own), the Planner (Antara
and Anjali, each independently), and ML (Shourya and Kishan, each independently), plus a Bridge
role (Aditya B.) getting ML actually live-gating the planner.

| Track | Who | What it is |
|---|---|---|
| **World + Integration** | **Aditya** | Everything the car drives in and sees, plus merging everyone's work, the demo, and the pitch |
| **Planner** | **Antara + Anjali**, independently | Everything the car decides, and the proof it works |
| **ML** | **Shourya + Kishan**, independently | The yield predictor and the other four models |
| **Bridge** | **Aditya B.** | Gets ML's output actually gating the planner's decisions live |

**Why the World and the Planner are separate tracks:** there is exactly ONE interface between
them — **`S1 TrackList`**, frozen in `AGENTS.md` section 3. That is why the two sides cannot
break each other, and why nobody needs to read the other side's code.

### Two jobs that need nobody and were blocking everyone — both resolved

1. **`matlab/baseline/` has been run.** It fails, at 19.7s, 0/120 candidates collision-free — that
   is the result, not a gap. **Never edit it to make it survive.**
2. The RoadRunner licence — the one problem-statement requirement not currently met — is a
   standing, disclosed limitation, not a live blocker.

| Track | Owns | File |
|---|---|---|
| **The World** | Scenarios, roads, junctions, the cow, sensing · lidar, radar, tracking | **Aditya's own work — nothing to open here.** Produces `S1` and `S9` |
| **ML** | Dataset, both yield models, calibration, evaluation | **[`ml/ReadThis.md`](ml/ReadThis.md)** — start here |
| **Planner** | The negotiating planner, live-obstacle-injection, safety verification | **[`plan/ReadThis.md`](plan/ReadThis.md)** — start here |

## Layout

```
THE ROOT - rules that apply to everyone, and nothing else
  README.md         this file
  TEAM.md           one page: who does what
  HANDOFF.md        what's true right now, and what each person does next
  AGENTS.md         project rules + THE FROZEN CONTRACT (section 3) - read by every AI tool
  CLAUDE.md         what Claude Code loads
  GEMINI.md         Antigravity-specific rules

THE TWO TRACK FOLDERS - open ONE, the one that is yours
  ml/               ML - the dataset and the prediction models
    ReadThis.md       start here
    ML.md             facts about the data, for your AI
    DGX.md            the supercomputer - read before running anything on it
    CHEATSHEET.md     every command, in order
    TROUBLESHOOTING.md  errors we already hit, and what they really mean
    python/           dataset pipeline, both yield models, ONNX export
  plan/             PLANNER - the negotiating planner, the baseline, the evidence
    ReadThis.md       start here

ADITYA'S OWN - not handed out, do not work from it
  world/            the scenarios and the sensing. Working notes kept here
                    because B-perception.md is where the S1 and S9 rules live

SHARED - code and tooling, not owned by one track
  matlab/+sih/      planner, prediction, models, util
  matlab/tests/     run these first
  matlab/baseline/  MathWorks' shipped planner - NEVER EDIT
  derisk/           the checks that gate the build
  blender/          rendering (the 3D city - a separate build track)
  .agents/rules/    loaded automatically by your agent
  .agents/workflows/  slash commands - see the table above
  .claude/commands/ the same slash commands, for Claude Code
  .claude/fences/   permission files that restrict reads to your own area
```

## Five rules

1. **Never edit `matlab/baseline/`** — a tuned baseline is a strawman and kills the result
2. **Never invent a number** — if you did not run something to get it, do not write it
3. **Never change section 3 of `AGENTS.md`** without telling everyone
4. **Disclose bugs, do not hide them** — this project's whole culture is built on saying so
5. **Errors are reported in full** — never a summary

## Credits

Built on [`mathworks/OpenTrafficLab`](https://github.com/mathworks/OpenTrafficLab).
METEOR dataset (Chandra et al., ICRA 2023). COLREGs formulation after Kuwata et al. and
Tam & Bucknall. Cattle parameters from published GPS-collar studies.
3D assets CC-Attribution (Sketchfab); environment maps CC0 (Poly Haven).
**Borrow freely, cite loudly.**
