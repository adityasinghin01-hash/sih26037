# SIH26037 — WHERE WE ARE, AND WHAT TO DO NEXT
**Written 16 September 2026, ~21:10. Hand this to Codex (or any agent) and it can continue.**

> A second copy lives at `~/dev/sih2026-hq/SIH26037-HANDOFF-FOR-CODEX.md`.
> **Read that one if this one is 0 bytes** — the Desktop is iCloud-synced and offloads files.

---

# 1 · READ THESE FIRST, IN THIS ORDER

| | |
|---|---|
| `~/dev/sih2026-hq/00-READ-FIRST.md` | what the project is, where everything lives, the scope lock |
| `~/dev/sih2026-hq/02-STATE-TODAY.md` | every number verified today, with its source |
| `~/dev/sih2026-hq/07-PHASE1-FINDING.md` | the four defects Phase 1 found, and how |
| `~/dev/sih2026-hq/08-PROFILING-RESULT.md` | where the planner's time actually goes |
| `~/dev/sih2026-hq/03-HOW-TO-DRIVE-THE-AGENTS.md` | the agent traps — **read before running Codex** |
| `~/dev/sih2026/AGENTS.md` **§3** | the frozen contract. Never change it |

---

# 2 · THE SCOPE, LOCKED

**Two scenarios, done properly: S1 (cattle crossing) and S3 (the galli).**
All phases are proven on those two before a third is touched. They are the only two that
work — S2 collides and then permanently stalls; S4 has no route or seat at all.

Then extend: S4 is a build from nothing (4–6 days), S2 is a fix that may not yield (3–5 days).
**S2 can be dropped without losing the deliverable.** It stays disclosed, as it always has.

The problem statement asks for *"an adaptive path planning system"* with scenarios and
results. It does not ask for four. Two done properly beats four done thinly — four-done-thinly
is the exact failure that lost Quiesce, Tenable and NETRA.

---

# 3 · WHAT IS DONE

## Branch `integration/dense-planner`, off `main`

| commit | what |
|---|---|
| `205595e` | **Phase 0** — merged the 5-scenario dense world onto the planner line. 28 files, 2,821 lines. Only `plannerView.m` was touched by both sides; git auto-merged cleanly. 348/348 tests pass after |
| `16d136f` | **Phase 1** — the real planner drives S1's full world |

## Phase 1 result — the real finding

`densityPlannerRun('s1')` puts `sc.planSeat` against **three** layers:
1. **traffic** — `sc.s1actors` via `s1_action_run.m` (9 tracked actors)
2. **scenery** — `sc.s1density` (51 background actors, 14 buildings, 3 poles)
3. **the road** — `sc.demo1Route`'s 14 hazards, speed caps 14–29 km/h

| | sparse S1 | dense S1 |
|---|---|---|
| tightest approach | 0.618 m | **0.135 m** |
| mean speed | 28.0 km/h | 22.7 km/h |
| duration | 75.2 s | 92.75 s |
| route completed | yes | yes |
| plan failures | 0 | 0 |
| steps against a frozen world | — | **0 of 1855** |

**A realistic world costs this planner ~80% of its safety margin while it never once fails to
plan.** The binding actor is the tractor's **trolley at 0.119 m** — not the cow, which sits at
1.015 m. The scenario's famous obstacle is not its hardest moment.

## The four defects Phase 1 found — all silent, none crashed anything

1. **The density layer is scenery.** 50 of 51 actors sit off the 3.5 m half-carriageway. Alone,
   the planner cruised past at 51.6 km/h with `h`=NaN on all 817 steps. Negotiation actors must
   be **added to** it, never swapped in.
2. **M6 measured the wrong actors.** `D.Poses` carried only the density set, so the headline
   clearance metric never saw the cow — it reported **+1.092 m while the ego overlapped a
   vehicle by 0.80 m.**
3. **A constant was copied where a mechanism was needed.** `T_END` hardcoded from the sparse
   config; once caps slowed the car the run silently stopped at 403 m of 610. Now
   `sc.estimateDuration`.
4. **Ghost tracks — 3,707 of them.** Actors that stop keep reporting their old velocity.
   `moto_over` sits at the route end claiming **17.22 m/s (62 km/h)** from t=49.95 s.
   `predictAgentFutures` propagates from that, so the planner believed a parked motorcycle was
   sprinting away and drove through it at 13.85 m/s. Zeroing velocity for non-moving actors
   turned a **−0.800 m overlap into +0.299 m** — the car now creeps past at 2.20 m/s.
   Same planner, same route. Only the honesty of the input changed.

## Profiling — and it killed the assumption the plan was built on

`profilePlanSeat(200)`. **`sc.planSeat` had never been timed before today.**

```
mean per step   735.8 ms      10 Hz budget is 100 ms  →  7.4× over
planContingency       131.46 s   (88% of everything)
  checkTrajectorySafety 123.48 s   204,587 calls   = 1,023 per step
  checkTerminalStop      80.66 s   125,977 calls
  DynamicCapsuleList     23.65 s   818,348 calls
  unique                 22.75 s  1,227,522 calls   20.71 s SELF
adapterS9Real          12.95 s   ← 8.7%. NOT the bottleneck
```

**The occluder ray-march was predicted to dominate. It does not.** The cost is MathWorks'
`dynamicCapsuleList` machinery called ~1M times per 200 steps. `unique` alone is 14% of total
runtime, inside their code — it cannot be fixed, only called less.

**Any plan to "spatially index the occluders" is cancelled.** It buys 8.7% at best.

---

# 4 · WHAT IS LEFT — in priority order

### 4.1 · Phase 2 — S3 integrated  *(IN FLIGHT)*
`matlab/densityPlannerRunS3.m` was written by Codex at 21:02 and is being run now.
Brief: `~/dev/sih2026-hq/04-JOBS/CODEX-06-phase2-s3.md`.
Expect the same class of defects Phase 1 hit, plus S3's own:
- **ego width is 1.90 m, not 1.80** — `writeDemoResults` had a real bug here before, and it
  understated clearances in the *unsafe* direction
- the squeeze is a measured **1.95 m** free width; `corridorFrom`'s 2.2 m sanity floor is wrong
  for S3 and it takes a `minCorridor` argument for exactly that reason
- `MirrorsFolded` changes the effective ego width through the squeeze

### 4.2 · Track pruning  — **the highest-value change available**  (~1 day)
1,023 collision checks per step against 60 tracks, **50 of which are scenery 5–8 m off the
road**. Prune tracks that provably cannot interact before they reach `planContingency`.

**This must be PROVED, not assumed.** Re-run and require the trajectory and M6 to come back
**bit-identical**. If anything moves, the threshold is too aggressive. *A faster planner that
drives differently is not the same planner.*

Unlocks Phase 6 and is the only credible route to Phase 9.

### 4.3 · `trajectories.csv` records 10 of 60 actors  (~0.5 day)
The frozen evidence file omits every background actor the planner reacted to. **Blocks Phase
6**, whose entire output is statistics computed from these files.

### 4.4 · `corridorFrom` never wired  (~0.5 day)
Only the **speed** half of the hazard layer is in. `corridorFrom` handles hazards that
physically occupy the carriageway and take lateral space away. It is private to `demo_play.m`
— lift it the same disclosed way as `sc.hazardCap` and `sc.estimateDuration`.

### 4.5 · Phase 5 — ML actually gating  (2–3 days)
The predictor emits `Valid=false` and drives nothing. Real figure is **2.089%** dangerous-error
(95% CI 1.315–2.854%), **not** the 20.18% still written throughout the repo. It fails its own
≤1% bar, so the geometric fallback is correct — make it a real fallback rather than the only path.

### 4.6 · Phase 6 — repeated randomised runs + confidence intervals  (1–2 days)
Turns a demo into a test. Gated on 4.2 and 4.3.

### 4.7 · Phase 7 — one command, four scenarios, clean HUD  (1.5 days)
**CORRECTION 17 Sep:** the MODEL STATUS overlap may be an artifact of MY headless snapshot,
not a real defect. `plannerView` already wraps Detail to `wrapStr(.,46,2)`, and its comment
records 46 chars as measured to fit at 9 pt on a real exported frame. In my snap the text
ALSO ran off the right edge, which points at a narrower figure than the presenting one.
**Verify by rendering at the demo figure size before changing any layout constant.**
**S1's MODEL STATUS panel is visibly broken** — text overlaps itself when an entry wraps to two
lines; S3 is fine because its entries are short. Frames at
`~/dev/sih2026-hq/05-ASSETS/render-check/`. Also: labels collide, strings truncate mid-word,
and the speed graph renders empty in a single-frame snap.

### 4.8 · Phase 8 — agents react to the ego  (4 days)
Every actor is a script playing back. The car negotiates with a recording. This is the phase
that most changes how the demo reads.

### 4.9 · Phase 9 — live planning at 10 Hz  (4–6 days, **may not land**)
7.4× away. If pruning gets it to ~1.5×, push. If it stalls at 4×, **cut it**, ship
pre-computed playback and disclose why. That is what most simulators do and it is not a failure.

**Total: ~16–21 working days ≈ 3½–4½ weeks at 4–6 h/day.**

---

# 4bis · DO NOT USE THESE TWO FLAGS (17 Sep)

`demo_play` declares `opts.Dense` and `opts.Reactive`. **They are DEAD - declared and
never read.** Flipping them runs a normal demo and changes nothing. They were left in the
committed file deliberately: the file WORKS as committed (verified 1108 gate decisions,
0 plan failures) and it was hours before a live round. Tidiness is not worth risking that.

**Wiring them properly is a real job, not a patch.** Three attempts failed, each
differently, and the third left the demo throwing on startup:
  1. the run loaded a CACHED planner result, so the new code never executed and still
     printed a pass - a green result that tested nothing
  2. the edit script died on a format-string error, never applied, and the demo printed
     the identical old numbers, which looked like success
  3. `opts.Dense` was referenced inside `builtinRoute`/`builtinRouteS3`, LOCAL functions
     where `opts` does not exist - MATLAB only fails at runtime

The flags must be threaded as plain arguments through four nested local functions:
`demo_play -> builtinRoute/builtinRouteS3 -> builtinTracks/builtinTracksS3`. Read each
enclosing scope BEFORE editing. `demo_play.m` is 83 KB with deep local nesting and regex
patching does not survive it.

**Always verify with `Recompute=true`.** Without it the demo replays its cache and any
change inside the planning loop is never executed.

# 5 · THE TRAPS — every one of these cost real time today

| trap | what happens | the fix |
|---|---|---|
| **Codex cannot run MATLAB. At all.** | `Incompatible processor. This Qt build requires the following features: neon`, exit 137, in 1.6 s. Not just figures — a plain headless `-batch` dies | **Codex writes the code. A human or Claude runs it.** |
| **Codex hangs on stdin** | when its output is piped it prints *"Reading additional input from stdin…"* and waits forever | **always `< /dev/null`** |
| **Codex hangs AFTER finishing** | wrote the file at 15:58, sat until 18:05 — 2h10m, 2.78 s CPU, never exited | `tools/codex-run.sh` kills it if the log stops growing for 8 min |
| **Codex cannot write to `.git`** | `cannot open '.git/FETCH_HEAD': Operation not permitted` | a human does all git operations |
| **Antigravity auto-denies file reads headless** | *"a tool required the read_file permission that headless mode cannot prompt for"* | add scoped `permissions.allow` to `~/Library/Application Support/Antigravity/User/settings.json` — exact JSON in `03-HOW-TO-DRIVE-THE-AGENTS.md` |
| **`SENSED` is uppercase** | a lowercase `Sensed` is silently ignored → you get two identical sensed runs and think you compared both conditions | `SENSED=false` / `SENSED=true` |
| **`runtests` needs the `.m`** | `MATLAB:unittest:TestSuite:UnrecognizedSuite` | `runtests('matlab/tests/testX.m')` |
| **Never run two MATLABs** | 8 GB machine; the demo's own frame timing degrades 20× under load | one at a time |
| **Never run Blender and MATLAB together** | same reason | one at a time |

---

# 6 · THE COMMANDS

```bash
# is Codex alive / busy / rate-limited?
~/dev/sih2026-hq/tools/codex-status.sh

# run a brief through Codex, survive a rate limit, auto-resume, watchdog on stalls
~/dev/sih2026-hq/tools/codex-run.sh <brief.md> <report.md>

# the full test suite   (348 tests, 348 pass, 0 fail, 0 incomplete — 46 s)
/Applications/MATLAB_R2026a.app/bin/matlab -batch "addpath(genpath('matlab')); \
  addpath(genpath('OpenTrafficLab')); r = runtests('matlab/tests','IncludeSubfolders',true); \
  fprintf('TOTAL=%d PASS=%d FAIL=%d INCOMPLETE=%d\n', numel(r), sum([r.Passed]), \
  sum([r.Failed]), sum([r.Incomplete]));"

# the dense S1 run           (~15 min)
matlab -batch "addpath(genpath('matlab')); densityPlannerRun('s1');"

# what did we hit, and when  (seconds — never re-run a 15-min job to find out)
matlab -batch "addpath(genpath('matlab')); whoDidWeHit('<results/dir>');"

# where does the time go
matlab -batch "addpath(genpath('matlab')); profilePlanSeat(200);"

# the real demo, needs a DISPLAY — batch mode skips playback entirely
matlab -batch "addpath(genpath('matlab')); demo_play('demo1');"
```

---

# 7 · THE RULES — not optional, they are why this project is different

1. **Never invent a number.** If you did not run it, write `TODO(unverified)`.
2. **Never summarise an error.** Whole message, first line to last. A trimmed error costs a day.
3. **Disclose bugs before a judge finds them.** This is the actual competitive edge.
4. **Never edit `matlab/baseline/`** — MathWorks' shipped planner, kept unmodified. Tune it to
   survive and a judge calls it a strawman and the whole comparison dies.
5. **Never change `AGENTS.md` §3** — everything is built against it.
6. **Never ship a half-fix.** If it is not clean by its cutoff it reverts. An 80%-done fix is
   not 80% as good; it is a new, untested failure mode.
7. **When something succeeds, say what you verified — not that it worked.** Almost nothing here
   crashes. It produces a number, and the number is wrong.

---

# 8 · NUMBERS THE REPO STILL GETS WRONG — fix before anything is presented

| written everywhere | the truth |
|---|---|
| "344 tests, 335 pass, 9 incomplete" | **348 / 348 / 0 / 0** — re-run today |
| "0.965 m clearance" as a planner result | **geometry, not a result.** `(3.830 − 1.900)/2`. The claim ledger's own scope note calls using it as a planner claim *"forbidden"*. Sparse S1 measures **0.618 m**; dense S1 measures **0.135 m** |
| ML dangerous-error rate "20.18%" | **2.089%**, 95% CI [1.315%, 2.854%], measured 11 Sep |
| S3 separations "+0.175 / +0.999 / +0.550" | re-measure and quote what today's run gives |
| "S2 works, one disclosed bug" | **it does not finish the route under either sensing condition.** Ground truth −0.003 m, real sensing −0.909 m, then stalls at s≈116–121 m of 244 m and never exits. Re-confirmed today |

`Frame 1.png` (the architecture flowchart, in `05-ASSETS/`) says the planner follows **COLREGs**.
It does not — give-way is derived from **Indian RRR 1989 reg. 2**, and COLREGs says the opposite
and would steer into oncoming traffic. Caught during design, corrected in code, never corrected
in the diagram. **Do not present it as-is.**

---
# 17 Sep, LATE UPDATE — PHASES 6 AND 8 ARE GREEN

**Phase 8 FIRES.** `demo_play('demo1','Recompute',true,'Reactive',true)` ->
`PHASE 8 reactive: 35 agent reactions over 2366 steps`, 0 plan failures. Root cause of
the earlier zero was that `opts.Reactive` was dropped at the top-level `loadRoute` call,
so every downstream builder defaulted to false. The chain is complete now.

**Phase 6 COMPLETED: 8 of 8 runs, and it falsified our headline number.**
`M6_minClearance_m: mean 0.1427, sd 0.0600, min -0.0010, 95% CI [0.0926, 0.1928]`
**One run in eight made CONTACT (-0.0010 m) while still reporting M9_completed=1 and
0 plan failures.** Moving the entry point under two metres does it. Full analysis in
`~/dev/sih2026-hq/09-BENCH-RESULT.md`. Quote the interval and the observed minimum -
never a single run's 0.16 m.


---
# 17 SEP, MIDDAY — PHASE 7 DONE

**One command:** `sihDemo` / `sihDemo("galli")` / `sihDemo("all")`, with
`Dense=true` and `Reactive=true` as options. It calls `demo_play` and reimplements
nothing. **It REFUSES S2 loudly**, throwing with the real numbers (-0.003 m ground
truth, -0.909 m sensed, stall at s~116-121 m of 244) and a pointer to the ledger,
because a menu entry that stalls in front of a judge is worse than no entry.
`testSihDemo` 3/3 asserts that refusal keeps its numbers.

**The HUD shows a LIVE ML GATE row:** `OFF for all 1108 / no validated band:
2.089% vs <=1% - geometry drives`. Previously a hand-written caption the audience
had to trust; now the run's own tally. Absent counts print "not reported", never
zero - a missing measurement and a measurement of zero are different claims.

**The panel was unreadable and is now fixed.** Every row's 2-line Detail collided
with the next row's name. The arithmetic nobody had done: 6 rows x 3 lines = 18
lines, and the panel holds ~18 with zero margin. Details are ONE line now.
The "Fusion" row was dropped - Status and Detail both read "stub".
**Verified by rendering the frame and reading it**, not by reading code: three
earlier passes over this file missed the overlap entirely.

## BOARD
| phase | state |
|---|---|
| 0 merge · 1 S1 dense · 5 ML gate · 6 bench+CI · 7 HUD+one command · 8 reactive | **DONE** |
| 2 S3 dense | **stalls at s=81.4 m** - under diagnosis |
| 4 S2 fix | not started. Same stall mechanism as S3 - likely ONE fix for both |
| 3 S4 build | not started |
| 9 live 10 Hz | not started, 7.4x away, lever costs plan quality |

## THE S3 STALL - how to diagnose it, and what NOT to do
`densityPlannerRunS3('TEnd',60,'PlanEvery',3)` - a SHORT run reaches the stall
(it happens by t=30 s) **and still writes results/**. A timeboxed kill writes
nothing, which is why two earlier attempts produced no evidence at all.
Then `whyStalled('<results dir>', 81.4)` ranks every actor within 60 m ahead. If
it reports nothing there, the block is the CORRIDOR, not an actor - completely
different fix.

**DO NOT raise the step budget, loosen the corridor, or delete actors until it
moves.** The stall IS the finding. S2 and S3 showing one pathology makes it a
property of the planner, not a quirk of a scenario.
