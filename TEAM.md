# Who is doing what

**One page. If you are not sure whose job something is, it is answered here.**
Last settled 1 September 2026. Idea submission deadline **20 September 2026**.

---

## The two roles

The five streams are grouped into two roles. Streams say *what* is owned; roles say *who works
together*.

| Role | Streams | What it is |
|---|---|---|
| **1 · The World** | Aditya — **not handed out** | Everything the car drives in, and everything it sees. Coordinated by call, not through this repo |
| **2 · The Driver** | D + E | Everything the car decides, and the proof it works |

**There is exactly ONE interface between them: `S1 TrackList`**, frozen in `AGENTS.md` section 3.
That is why the two halves cannot break each other.

---

## Everyone, by name of job

| Who | Role | Owns | Machine | Reads first |
|---|---|---|---|---|
| **Aditya** | 1 + F | **WORLD and Perception in MATLAB.** Plus integration, the demo and the pitch | **Mac — THE MAIN MACHINE. The demo runs here** | — |
| **World teammate** | 1 | Meerut footage, OSM exports, PPT, docs, the claim ledger, judging whether a scene looks Indian | any | **nothing here — Aditya briefs them on a call** |
| **ML person** | C | METEOR, both yield models, ONNX export, the three MATLAB models | roomiest machine — datasets are tens of GB | **`ml/ReadThis.md`** |
| **Planner A** | 2 | `matlab/+sih/+planner/*.m` — pure functions | Windows — develops here | **`plan/ReadThis.md`** then `/plan-work` |
| **Planner B** | 2 | The Simulink model and Stateflow chart, **and the baseline** | Windows — develops here, and our **second platform** | **`plan/ReadThis.md`** then `/plan-harness` |

**Planner A uses Claude Code. Planner B uses Antigravity.** Every command exists for both tools,
so it does not matter which one you are holding.

---

## The main machine is Aditya's Mac

**Decided 4 September 2026 — and decided by running every piece on it, not by assuming.**

Aditya is the integrator and Aditya presents, so the machine in the room has to be the one that is
proven. It now is. **The demo runs on the Mac.**

| Piece | On the Mac | Evidence |
|---|---|---|
| Stream D planner — D6, D8, D9, D10, arbitration | **304 tests in 18 files: 303 pass, 1 fail, 0 incomplete** | `stream-d-a` re-run on the Mac 5 Sep. The 1 failure is Stream C's `testFeatureParity`. **Requires `OpenTrafficLab/` cloned in the repo root** — without it 7 tests silently SKIP and the total reads 297 |
| Simulink model + Stateflow chart | **loads with 0 unresolved refs; simulates in 47 s; logs `h`** | `sih_planner.slx` from `stream-d-b`, loaded and simulated on the Mac |
| OpenTrafficLab subclass | **9/9** | `testNegotiatingStrategy.m` |
| `matlab/baseline/` | **runs, and fails at 19.7 s — identically to Windows** | `plan/BASELINE-R2026a.md` |
| Required toolboxes | **9/9 present** | `ver` |
| **ONNX converter add-on** | **MISSING — the only real gap left** | all four import/export functions absent |

### Three rules that come with it

1. **Nothing changes about where you work.** Everyone keeps developing on their own machine. This
   is only about where the demo runs and where integration happens.
2. **The `.slx` still has exactly ONE editor — Planner B.** It is a binary file and git cannot merge
   it, so two people editing it silently loses one person's day. Aditya **pulls and runs** it; he
   never edits it. If B changes it, Aditya's copy is stale until he pulls again — **tell him when
   you push.**
3. **The Windows machines stay valuable as our second platform.** Running the baseline on both is
   exactly what settled whether its failure was real or a Mac artefact. That could not have been
   done on one machine, and it will be true again.

---

## What nobody may touch

| | Why |
|---|---|
| **`AGENTS.md` section 3** | Six people build against it. A silent change breaks five of them. If it genuinely needs changing, that is a conversation with Aditya, not a commit |
| **`matlab/baseline/`** | MathWorks' shipped planner, unmodified. It is the competitor. **If we tune it so it fails, a judge calls it a strawman and every result we have dies** |
| **Another stream's folder** | See the table above. If something there looks wrong, say so in one sentence. Do not fix it |

---

## The one file each person opens

```
Aditya         -> nothing, we work session by session
World teammate -> nothing here, Aditya briefs them on a call
ML person      -> ml/ReadThis.md
Planner A      -> plan/ReadThis.md, then plan/CONTRACT-AB.md
Planner B      -> plan/ReadThis.md, then plan/CONTRACT-AB.md
```

**Open the repository ROOT in your editor, never a subfolder.** `AGENTS.md`, `CLAUDE.md`,
`GEMINI.md` and everything in `.agents/` and `.claude/` load only from the root. Open a subfolder
and your AI assistant works blind — it invents function names and breaks other people's code.

---

## Commands, and who uses them

| Command | Who |
|---|---|
| `/first-run` | **everyone, the first time they have MATLAB on a machine** |
| `/state` | anyone, any time — where the project actually is |
| `/ml-run`, `/ml-parity`, `/ml-models` | ML person |
| `/plan-work` | Planner A |
| `/plan-harness` | Planner B |
| `/plan-test` | either planner person |

---

## Blocked on a human, right now

| # | What | Who | Notes |
|---|---|---|---|
| 1 | **The ONNX converter add-on** | Aditya | **Mostly closed.** MATLAB R2026a with 9/9 required products is confirmed on Aditya's Mac AND on both Windows machines — Planner A ran the test suite, Planner B ran the baseline. **The ML person's machine is still unconfirmed.** What remains is the free **Deep Learning Toolbox Converter for ONNX Model Format** add-on, missing on the Mac: Home -> Add-Ons -> Get Add-Ons. It blocks `check04`, which blocks the opset number, which blocks the planner |
| 2 | ~~**RUN `matlab/baseline/`**~~ **DONE — and it fails** | Aditya | **Run 4 Sep on both platforms. It does not complete** — it dies 19.7 s into its own scenario with 0 of 120 candidates collision-free. `plan/BASELINE-R2026a.md`. **E2 is now blocked rather than unstarted**, and there is still no head-to-head number because the two planners do not share a scenario. **Never edit that folder to make it survive** |
| 3 | **RoadRunner licence 41087767** | Aditya | The one problem-statement requirement we cannot currently meet |
| 4 | Which label to train on | ML person applies the rule in `ml/ReadThis.md` | Only escalates if BOTH labels come out worse than 1 in 200 |

**What can start today with no MATLAB at all:** the ML person's entire Python pipeline; the world
teammate's footage and OSM exports; the RoadRunner email.

---

## Handoffs — tell people the moment these land

| From | To | What | Why it matters |
|---|---|---|---|
| ML person | **Planner** | **the working ONNX opset number** | The planner cannot wire the predictor without it. **Send it the moment `check04` passes — do not wait until the rest of your work is done** |
| Role 1 | Role 2 | `S1 TrackList` from a real scenario | Everything the planner knows about the world arrives through it |
| Planner | Aditya | the closed loop running | Integration and the demo start there |

---

## Five rules everyone follows

1. **Never invent a number.** If you did not run something to get it, write `TODO(unverified)`
2. **Never summarise an error.** All of it, first line to last. A trimmed error costs a day
3. **Never push code with a known bug.** We lost a previous hackathon demoing something we knew was broken
4. **Never work on `main`.** Branch, then a pull request Aditya reviews
5. **Say when you are stuck, the same day.** Being quietly stuck for two days is the most expensive thing that can happen on a team this size

---

## An honest note about the code

**Most of the MATLAB in this repository has never been executed.** It was written on a machine
with no MATLAB installed. Every function name was checked against the MathWorks documentation,
but checked is not run — and **defects have been found exactly that way, including seven on
4 September 2026** — two of which stopped the simulation running at all.

`/first-run` executes it in the right order and tells you what to look for. **Expect something to
break. That is the process working, not the repository being broken.** Send the whole error.
