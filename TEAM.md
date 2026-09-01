# Who is doing what

**One page. If you are not sure whose job something is, it is answered here.**
Last settled 1 September 2026. Idea submission deadline **20 September 2026**.

---

## The two roles

The five streams are grouped into two roles. Streams say *what* is owned; roles say *who works
together*.

| Role | Streams | What it is |
|---|---|---|
| **1 · The World** | A + B | Everything the car drives in, and everything it sees |
| **2 · The Driver** | D + E | Everything the car decides, and the proof it works |

**There is exactly ONE interface between them: `S1 TrackList`**, frozen in `AGENTS.md` section 3.
That is why the two halves cannot break each other.

---

## Everyone, by name of job

| Who | Role | Owns | Machine | Reads first |
|---|---|---|---|---|
| **Aditya** | 1 + F | **WORLD and Perception in MATLAB.** Plus integration, the demo and the pitch | Mac for WORLD, Windows main for integration | — |
| **World teammate** | 1 | Meerut footage, OSM exports, PPT, docs, the claim ledger, judging whether a scene looks Indian | any | `teammates/A-world.md` |
| **ML person** | C | METEOR, both yield models, ONNX export, the three MATLAB models | roomiest machine — datasets are tens of GB | **`ml/ReadThis.md`** |
| **Planner A** | 2 | `matlab/+sih/+planner/*.m` — pure functions | Windows | **`plan/ReadThis.md`** then `/plan-work` |
| **Planner B** | 2 | The Simulink model and Stateflow chart, **and the baseline** | **Windows — the MAIN machine** | **`plan/ReadThis.md`** then `/plan-harness` |

**Planner A uses Claude Code. Planner B uses Antigravity.** Every command exists for both tools,
so it does not matter which one you are holding.

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
World teammate -> teammates/A-world.md
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
| 1 | **MATLAB installed on three machines** | Aditya, Planner B, ML person | **The single biggest blocker.** Almost everything downstream needs it |
| 2 | **Fill `matlab/baseline/`** | Planner B | Empty today. Until it exists, **no number this project produces is comparable to anything** |
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
but checked is not run — and **six real defects have already been found that way.**

`/first-run` executes it in the right order and tells you what to look for. **Expect something to
break. That is the process working, not the repository being broken.** Send the whole error.
