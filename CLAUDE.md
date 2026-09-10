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
who does what, rather than re-explaining. **Current as of the 10 September restructure** — if
you see "Stream C/D/E" or "Person A/Person B" elsewhere in this repo, that's the retired
structure; `TEAM.md`'s own footer explains the mapping.

**Three independent tracks. The World is not handed out.** The ML track (Shourya, Kishan) works
from `ml/`; the Planner track (Antara, Anjali) works from `plan/`. **The World — the scenarios
and the sensing — is Aditya's own work**, coordinated by call rather than through the repo, so
there is no folder to send anyone to and no task list here to follow.

It still matters to everyone else, because **the World produces `S1 TrackList`** — the single
interface the planner consumes, frozen in `AGENTS.md` section 3. That is why the two halves of
the team cannot break each other. Treat `S1` as arriving from Aditya.

| Track | Who | Owns | Files they own |
|---|---|---|---|
| **The World** *(not handed out)* | Aditya | Scenarios, roads, junction, galli, ghat, cow, pedestrians · lidar, radar, tracking, the near-field ring · produces **`S1`** and **`S9`** | `matlab/+sih/+scenario/`, `matlab/+sih/+perception/` |
| **ML** | Shourya + Kishan, independently | METEOR, the yield models, calibration, evaluation, ONNX export | `ml/`, `matlab/+sih/+models/`, `matlab/+sih/+prediction/` |
| **Planner** | Antara + Anjali, independently | The brain: roles, barriers, contingency paths, S2/S3 fixes, live-obstacle-injection, safety verification | `matlab/+sih/+planner/`, `matlab/+sc/` |
| **Bridge** | Aditya B. | Gets ML's output actually live-gating the planner's decisions | the demo panel: `sc.plannerView`, `sc.modelStatus` |
| **Integration** | Aditya | Merging, the demo, the pitch | everything, but he reviews rather than writes |

**Antara and Anjali are independent, not a shared job-split.** The old "Person A writes pure
functions, Person B owns the Simulink model, neither touches the other's files" arrangement
(`plan/CONTRACT-AB.md`) described a different, no-longer-current situation — neither of their
current task lists mentions the Simulink model. Don't treat that file as governing this pair.

### The two big folders are separate on purpose

| If you are doing | Read | **Do not open** |
|---|---|---|
| machine learning | `ml/ReadThis.md`, `ml/ML.md` | `plan/`, `matlab/+sih/+planner/` |
| the planner | `plan/ReadThis.md` | **`ml/`**, `matlab/+sih/+prediction/`, `+models/` |

**They meet at the contract and nowhere else.** The planner consumes `S3 PYield`; it never opens
the model that produced it. The ML stream produces `S3`; it never opens the planner. If one side
thinks the other is wrong, that is a message to a human, not a reason to go and read their files.

Reading across that line is how two people end up with two different versions of the same thing
and nobody knows which one the demo used.

**Make the line real — install your fence.** `.claude/fences/` holds one small permission file per
stream. Copy the one for your stream to `.claude/settings.local.json` and the boundary stops
depending on anyone reading this carefully:

```bash
cp .claude/fences/ml.settings.local.json      .claude/settings.local.json   # ML track (Shourya, Kishan)
cp .claude/fences/planner.settings.local.json .claude/settings.local.json   # Planner track (Antara, Anjali)
```

Tested 1 Sep 2026: with the planner fence on, a read of `ml/ReadThis.md` is refused outright, and
`plan/ReadThis.md` still opens. It covers `cat`/`head`/`sed` in Bash too. Aditya and Aditya B.
install neither — integration and the World have to read everything.
Full note: `.claude/fences/README.md`.

**Before you edit a file, ask whether it belongs to the track you are working for.** If it does
not, say so in one sentence and stop. Acting across that line is the most expensive mistake
available in this repository.

---

## 3 · What actually exists right now

Be precise about this with the person you are helping. **This section describes 10 September
2026 — the repos are merged, the old branch-per-person model is gone, and the "probe never
fires" crisis documented in older commits is resolved.** If you find an older date's claim
still sitting in some other file, this section wins.

### Built, run, and trust it
- **Full test suite: 344 tests, 335 pass, 0 fail, 9 incomplete.** The 9 incomplete are
  OpenTrafficLab-not-cloned skips — clone it into the repo root or they show up. A skip is not a
  pass, but it's expected on a fresh clone, not a regression.
- `matlab/+sih/+planner/`, `+scenario/`, `+perception/` — the full planner, plus real S9
  DrivableSpace and a noisy S1 TrackList via `trackerGNN`. All one package now, all on `main`.
- **S1 (the cow), fully solved:** 610m real road, full route, 0.965m clearance each side.
- **S2 (the chowk):** works, one honestly disclosed bug (−0.909m, a lateral-commit tie-break) —
  on Antara's task list, not yet fixed.
- **Real sensing in the live demo:** `demo_play.m`'s `Sensed=true` (done 10 Sep) — verified, the
  0.965m number holds under real sensing too. Default stays `Sensed=false`.
- **`matlab/baseline/` has been run, and it fails** — 19.7s in, 0/120 collision-free, identically
  on macOS and Windows. **That is the result. Never edit it to make it survive.**
  `plan/BASELINE-R2026a.md`.
- The whole ML pipeline (fetch, features, split, train, evaluate, ONNX export) for the yield
  models. `.m` extension required for `runtests` on a single file, not a folder.

### Not yet built
- `+metrics/` — folder exists, empty. `demo_play.m` doesn't yet produce the frozen
  `results/<run>/` format (`trajectories.csv`, `metrics.json`, `config.json`) either — that's on
  Aditya's current build queue (`HANDOFF.md`).
- S3 (the galli) — spec fully written (`world/scenarios/S3-THE-GALLI.md`), nothing built.
- Model calibration, YOLOX domain-gap fix, and independent evaluation — Shourya's and Kishan's
  current work, not started as of this writing per Aditya.
- Live-obstacle-injection and the S2 fix — Antara's current work, not started.

### Historical findings, resolved — don't re-litigate these
The repo used to document a "probe never fires" crisis (S1 collided, S2 deadlocked, the
defensive placeholder beat the real planner on both scenarios). **That was fixed** — a WAIT rung
was added to the `+sc` adapter layer (not the frozen `+sih/+planner/`) and S1 now completes the
full route at 0.965m clearance. Full history in `matlab/D9-WAIT-RUNG.md` and
`plan/BACKUP-PROBE-FINDING.md` if you need it, but treat it as resolved, not current.

---

## 4 · The decisions already made — do not reopen them

`AGENTS.md` section 2 has the full list. The five that get re-argued most:

1. **No RoadRunner.** The licence does not include it. We build scenes in code and export
   OpenDRIVE. This is our one declared deviation from the problem statement.
2. **Lidar and radar in the loop, camera offline.** The cuboid simulator emits an object list,
   not pixels — a model that reads pixels would have nothing to look at while the car drives.
3. **Never edit `matlab/baseline/`.** A tuned baseline is a strawman and a judge will say so.
4. **Never change `AGENTS.md` section 3.** Six people build against it. Stop and ask a human.
5. **The features are 31 values in a frozen order.** Append only at 32+. The planner reads them
   by position, so reordering breaks it silently, with no error.

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
| `/plan-work` | Planner track: the planner functions, in build order |
| `/plan-harness` | Planner track: the Simulink loop and Stateflow chart, if that piece is still live |
| `/plan-test` | Runs the planner tests and explains what a failure means |
| `/ml-run` | ML track: the whole yield-predictor pipeline |
| `/ml-parity` | Checks the Python and MATLAB feature builders still agree |
| `/ml-models` | ML track: the three MATLAB-native models |

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
