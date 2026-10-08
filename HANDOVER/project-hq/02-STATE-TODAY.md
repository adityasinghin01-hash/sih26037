# Verified state — 16 September 2026

**Every number here was produced by running something today on this Mac. Nothing is
carried forward from a document.** Where something has not been re-run today, it says so.

## Environment — all verified working

| | |
|---|---|
| MATLAB | **R2026a Update 5** (`26.1.0.3346908`), MACA64, starts in **13.6 s** |
| Licence | **41087767** (KIET campus TAH), valid |
| Repo | `~/dev/sih2026`, branch `main`, HEAD `f4d1f79`, clean |
| OpenTrafficLab | present at repo root |
| Codex CLI | `0.154.0` — **must be invoked with `< /dev/null`**, or it hangs forever reading stdin |
| Antigravity CLI | `1.2.2` — installed, **blocked**: headless mode auto-denies file reads until a permission rule is added |

## Test suite — re-run today, 16 Sep

```
TOTAL=348  PASS=348  FAIL=0  INCOMPLETE=0        (46 seconds)
```

**This is better than every document in the repo says.** They all quote
*344 tests, 335 pass, 9 incomplete*. Two things changed:
- the 9 incomplete are gone — `OpenTrafficLab/` is now cloned, so those tests actually run
- 4 new tests arrived with the ML merge (`testPredictYield`)

**Quote 348/348 from now on, not 335/344.**

## What is still true from before (not re-run today — flagged honestly)

- **S1 (the cow):** 610 m real route, full route completed, 0.965 m clearance each side.
- **S3 (the galli):** 382.2 m, the 1.95 m squeeze, motorcycle + child + dog all cleared.
- **S2 (the chowk): broken.** Collides, then permanently stalls at s ≈ 116–121 m of 244 m,
  under both sensing modes.
- **`matlab/baseline/`** — MathWorks' shipped planner, run unmodified, fails at t = 19.7 s,
  0 of 120 candidates collision-free. Confirmed untouched today (`git status` prints nothing).

## Demo assets, confirmed present on disk today

| | |
|---|---|
| `matlab/renders/S1_cattle_crossing.mp4` | 62 s film — **the fallback if MATLAB dies on stage** |
| `matlab/renders/S2_the_chowk.mp4` | 48 s film |
| `demo_demo1.mat`, `demo_demo1-cowblocking.mat`, `demo_demo1-cownone.mat`, `demo_demo2.mat`, `demo_demo2-cowblocking.mat` | cached planner runs — this is why playback is real-time instead of crawling |

## Machine limits that shape everything

- **8 GB RAM.** 1.9 GB is kernel and cannot be freed. Realistic ceiling for work: ~3.5 GB.
- **Never run Blender and MATLAB together.** `demo_play.m`'s own header records frame times
  going from 10 ms to 241 ms purely from background load. A loaded machine makes a working
  demo look broken.
- Disk: 55 GB free after today's cleanup (was 24 GB).

## Fallback films — checked today, both intact

| File | Length | Resolution | Codec |
|---|---|---|---|
| `S1_cattle_crossing.mp4` | **61.9 s** | 2560 × 1440 | H.264 |
| `S2_the_chowk.mp4` | **34.1 s** | 2560 × 1440 | H.264 |

(The docs say S2's film is 48 s. It is 34 s — the trimmed cut. The 48 s figure refers to
`S2_the_chowk_full_untrimmed.mp4`, which also exists.)

## A real limitation found today: Codex cannot run the demo

Codex's `workspace-write` sandbox kills MATLAB the moment it needs graphics:

```
Incompatible processor. This Qt build requires the following features:
    neon
MATLAB is exiting because of fatal error
```

MATLAB dies in 1.6 seconds, before any project code runs. The same command works fine
outside the sandbox.

**So the split has to be:**
- **Codex** — non-graphical MATLAB only (the test suite, pure computation, file work)
- **Claude / a normal terminal** — anything that calls `demo_play` or opens a figure

This is a property of the sandbox, not a bug in the project.

## The demo runs — 16 Sep 2026, measured today

### S1 — `demo_play('demo1')`
```
reached the end of the route at step 1504
planner run done in 46.7 s (0 plan failures)
results: results/demo1-cowblocking_20260916-090612
```
| Metric | Value |
|---|---|
| M9 completed | **true** — full route |
| M1 distance | 584.37 m of a 610.13 m route |
| **M6 min clearance** | **0.618 m** ← the real planner number, NOT 0.965 (see `04-THE-0.965-PROBLEM.md`) |
| M2 duration | 75.2 s |
| M3 mean speed | 28.0 km/h |
| M7 stopped | 2.2 s |
| Barrier violations | 387 raw / **0 imminent** |
| Plan failures | **0** |

The probe visibly fires: `step 700  t=35.0 s  s=285.8 m  v=0.08 m/s  PROBE`, then it
commits and drives on. That is the whole mechanism, on the record.

### S3 — `demo_play('demo3')`
```
reached the end of the route at step 3226
planner run done in 102.6 s (0 plan failures)
results: results/demo3-cowblocking_20260916-092319
```
| Metric | Value |
|---|---|
| M9 completed | **true** — full route |
| M1 distance | 371.19 m of a 382.18 m route |
| **M6 min clearance** | **0.293 m** (ego width 1.9 m, correctly applied) |
| M2 duration | 161.3 s |
| M3 mean speed | 8.3 km/h |
| M7 stopped | 21.5 s |
| Barrier violations | 843 raw / **0 imminent** |
| Plan failures | **0** |

**Note:** the claim ledger quotes S3 separations of +0.175 / +0.999 / +0.550 m. Today's
single minimum-over-all-actors figure is **0.293 m**. Quote today's number, and say it is
the minimum across all three actors over the whole run.

**S3 had no cache** — the planner recomputed from scratch, 102.6 s. It is now cached at
`matlab/renders/demo_demo3-cowblocking.mat` (126 MB), so it will be fast from here.

### Both runs
- `M5_minBarrier_rad` is −π/2 in both. That is the documented raw-barrier false positive,
  which is exactly why `BarrierViolations_Imminent` exists. **Both runs: 0 imminent.**
- Neither run played back — `matlab -batch` has no display. The planner ran and cached; to
  actually watch it you need a MATLAB session with a display. **The cache makes that fast.**

## S2 — re-measured today, both conditions. It reproduces exactly.

`s2_planner_run.m`, **`SENSED` is uppercase** (a lowercase `Sensed` is silently ignored and
you get two identical sensed runs).

| | Ground truth (`SENSED=false`) | Real sensing (`SENSED=true`) |
|---|---|---|
| Ran end to end | true (960 steps) | true (960 steps) |
| **Reached the ring exit (s ≥ 145 m)** | **false** | **false** |
| Stalled at | **s = 121.2 m** of 244 m | **s = 116.2 m** of 244 m |
| **Minimum separation** | **−0.003 m** at t = 17.65 s | **−0.909 m** at t = 12.70 s |
| Committed at all | true | true |
| Blocking track | one stable ID (track 2) | three different IDs in sequence (43 → 123 → 291) |

**Both figures match the 10 September measurement to the digit.** The bug is stable and
precisely characterised, not intermittent. That is worth saying out loud — a reproducible
failure is a diagnosis; a flaky one is a mystery.

### What a judge would see if S2 ran live
The car approaches the chowk, probes, reads a 1.8 km/h yield, commits — and then grazes or
hits the wrong-way rider. After that it stops dead at roughly half way round the ring and
**never moves again**, cycling ABORT → STOPPED → ABORT with the message *"stuck 30.0 s —
every sane pass is blocked, holding."* It never reaches the exit.

**So: do not run S2 live.** Show S1 and S3, and disclose S2 in the words above before anyone
asks. The mechanism that fails here is the same D9 WAIT rung that makes S1 work — it finds a
viable pass, loses it, finds it again, and never fully clears.

## S1 under real sensing — the claim HOLDS

`demo_play('demo1', Sensed=true, Recompute=true)`, recomputed from scratch, 91.6 s.

```
reached the end of the route at step 1515
planner run done in 91.6 s (0 plan failures)
results: results/demo1-cowblocking-sensed_20260916-093720
```

| | Ground truth | **Real sensing** |
|---|---|---|
| Completed full route | true | **true** |
| Plan failures | 0 | **0** |
| **M6 min clearance** | 0.618 m | **0.625 m** |
| Distance | 584.37 m | 583.76 m |
| Duration | 75.2 s | 75.75 s |
| Barrier violations | 387 / 0 imminent | 372 / **0 imminent** |

**This is the strongest verified claim on the project.** Swapping exact knowledge of the
world for simulated lidar + radar + a near-field ring + a real tracker changes the measured
clearance by **7 millimetres**, and the car still completes the whole route with zero plan
failures. Say it exactly like that, with both numbers.

**One honest difference to disclose if asked:** at the cow, ground truth enters `PROBE`
(v = 0.08 m/s); under real sensing the same moment enters `EMERGENCY` (v = 0.30 m/s). Same
outcome, more conservative route to it. The sensed car reacts harder because its picture of
the cow is noisier. That is the system behaving correctly, not a defect — but do not claim
the two runs are behaviourally identical, because they are not.

---

# THE INTEGRATION BUILD — started 16 Sep 2026

Aditya chose option **B**: start the integration now. His five teammates take the PPT, deck
and presentation for the 17 Sep round; he builds.

## The plan, ten phases

| | | Status |
|---|---|---|
| **0** | Merge the dense world onto the planner line | ✅ **DONE** — `205595e` |
| **1** | S1: the real planner drives the full dense world | 🔨 running |
| **2** | S3: same wiring | |
| **3** | S4: build the highway route and seat from scratch | |
| **4** | S2: fix the ring stall, then integrate | time-boxed |
| **5** | ML actually gates the planner's decisions | |
| **6** | Repeated randomised runs with confidence intervals | |
| **7** | One command, four scenarios, clean HUD | |
| **8** | Agents react to the ego instead of replaying a script | |
| **9** | Live planning at 10 Hz instead of pre-computed | riskiest |

## Phase 0 — done and verified
Branch **`integration/dense-planner`**, commit **`205595e`**.
Merged `worktree-5-scenario-density` (13 commits, 28 files, 2,821 lines) onto `main`.

- **Only one file was touched by both sides:** `matlab/+sc/plannerView.m` — `main` added the
  turn/escape HUD fields, the density branch added `drawWorldFurniture`. Git placed them in
  different regions. **Zero conflicts.**
- **Test suite after the merge: 348 / 348 pass, 0 fail, 0 incomplete.** The merge is not just
  textually clean, it is semantically sound.
- `demo_play.m`, `matlab/baseline/` and `AGENTS.md` untouched.

## Phase 1 — what is actually being attempted
The two halves have never met. `densityDemo.m` drives a **fake constant-speed ego** through
51 actors and 14 buildings; `sc.planSeat` is a **real planner** that has only ever seen 3
scripted actors.

The join is cleaner than expected: **`densityDemo.m` already builds a correct `S1 TrackList`**
in the frozen contract shape. It hands it to a drawing function instead of to a planner.

New file: `matlab/densityPlannerRun.m`. Copies `s1_planner_run.m`'s proven integration loop
(referencePathFrenet, accel limits, `sc.lateralStep`) and swaps the scripted ego for
`sc.planSeat`.

**Predicted outcome, written BEFORE the result so it cannot be spun afterwards:** the planner
was tuned against 3 actors and is about to meet 51. Expect failure. The likely modes are a
permanent stall like S2's, or a per-step cost high enough to make the run impractical.
**How it fails against a real world is the finding of this phase.** Codex has been told to
stop on failure and not fix it.
