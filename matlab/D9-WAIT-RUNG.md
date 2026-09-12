# D9 RUNG 1.5 — THE WAIT RUNG

**Written before building (Rule 1). Scope: `matlab/+sc/` only. `matlab/+sih/+planner/` is frozen
and is not touched. Branch `negotiation-wait-rung`, worktree
`~/Desktop/SIH26037-worktree-negotiation`.**

---

## 0 · WHAT IS ALREADY TRUE, AND IS NOT RE-DERIVED HERE

Phase 8 (`sih26037-phase8-option-a`) built and verified track-loss hysteresis
(`iTrackHysteresis`), a candidate-sanity reject (`iSaneCandidate` / `iPickSaneTrunk`), D9 rung 1
(creep, `iPickMovingSafe`), D9 rung 2 (go-around, `iPickGoAround`) and the stuck-progress clock
(`st.HighWaterS` / `st.LastAdvanceT`). Three real upstream bugs were found and fixed while
validating those. **None of that is revisited here.**

---

## 1 · THE MEASUREMENTS THIS DESIGN IS BUILT ON

Everything in this section was measured on 7 Sep 2026 in this worktree, not assumed.

### 1a · The Phase 8 baseline reproduces exactly
`s1_planner_run.m`, `matlab -batch`, 13:03 wall clock:
`closest approach -0.623 m to the cow at t=52.65 s`, `speed past her 27.22 km/h`,
`ego lateral while alongside: -0.001 .. +0.003 m`. Matches the recorded −0.623 m.

### 1b · RUNG 2 IS NOT A COMMITMENT. IT LASTS ONE 0.05 s TICK.
The go-around fires 5× (t = 37.25, 39.25, 43.25, 45.25, 47.25) and **every one of them** is
followed on the very next state change by
`EMERGENCY ... "following the trunk: aiming 0.6 m ahead ... asking for 0.0 m/s"`.
Four of the five revert after exactly one tick; the fifth lasts 0.6 s. Committing resets the
stuck clock, so for the next `GoAroundAfterStuck_s` the ordinary
`planContingency → followTrunk` route drives — and it brakes. **The ego's lateral never moves at
all**: it ends up passing the cow at e ≈ 0.000, dead centre. There is no go-around in the
trajectory, only in the label.

### 1c · THE −0.623 m COLLISION IS A HARNESS ARTEFACT, NOT A PLANNER FAILURE
`sc.buildTrackListSensed` precomputes every step's TrackList **before** the drive, using the
**scripted** driver's recorded trajectory as the sensor mount. Its own header discloses this and
calls it *"a reasonable, disclosed approximation … whose own trajectory the scripted one was
authored to sit close to."* Once the planner freezes, they are not close. Measured:

| t (s) | scripted ego = sensor mount | planner ego | tracks in the WHOLE TrackList |
|---|---|---|---|
| 34.0 | 285.8 | 285.6 | 3 |
| 43.5 | 307.1 | 286.7 | 1 |
| **44.0** | 308.8 | 286.7 | **0** |
| 49.75 | ~356 | 287.5 | 0 |
| 52.65 | ~389 | **300.0 — hits the cow** | 0 |

- divergence reaches **+89 m**;
- the cow's **last frame in the sensed TrackList is t = 43.75 s**;
- the TrackList is **completely empty from t = 44.0 to t = 59.5**;
- `TrackGrace_s = 6.0` bridges her to **t = 49.75 s**.

The arithmetic closes: ghost expires at 49.75 with the ego at s = 287.5, v = 0; `A_LON = 1.8`
gives 13 m in ~3 s, so alongside the cow (station 300) at ~52.7. **Measured collision: 52.65.**
The planner accelerates into a cow it can no longer see, through a world the harness has told it
is empty.

### 1d · THE RECORDED PREMISE DOES NOT HOLD FOR THIS RUN
The scripted beats run **12.5 s earlier** than the written script — measured PASS-1 table:
`ABORT t=24.10`, `COMMIT t=30.20`, `CLEAR t=43.15`, against the written 36.6 / 42.7 / 47.0.
The oncoming auto-rickshaw is placed to pass on those beats, i.e. around **t ≈ 24–30**, while
the planner-driven ego is still ~20 m short and moving. By the time it freezes (t ≈ 35) the
oncoming traffic is gone. **So "waiting out the oncoming auto" cannot be what blocks the
go-around in this run**, whatever the written script says.

### 1e · CONSEQUENCE FOR HOW THIS IS MEASURED
A WAIT rung cannot be judged under `SENSED = true`: waiting is exactly what widens the
divergence in 1c, so any hold brings the empty-world collision forward. The runners already
carry the documented A/B — `SENSED = false` uses `sc.buildTrackList` on the poses directly and
depends on no ego pose — so **the negotiation rung is designed and measured against
`SENSED = false`, and reported under both.**

---

## 2 · THE CORRECTED DIAGNOSIS — THE FAN IS NOT SHORT OF A SAFE PASS

The whole fan was dumped at every planner tick (`out.TerminalPrefixSteps`,
`out.BindingFuture`, the sanity verdict and the realised progress per candidate, plus every
track in the route frame). At the first S1 freeze under exact sensing:

```
--- t=29.60  s=285.98  e=+0.000  v=0.00  stuck=2.00   out.Trunk.CandidateIndex = 16
      track #1 cls10 (the cow)   s=300.0 (+14.0 ahead)  e=+1.36  v=0.00
      track #5 cls4  (the auto)  s=297.0 (+11.0 ahead)  e=-1.72  v=8.33   oncoming
    off     vT   worst  term  sane  prog   binder
   -2.50    0.0   10.0   7.0    1   0.45   #5 ASSERT      <- the auto DOES bind the slow lines
** -2.50   11.0   41.0  41.0    1  22.85   -
** -1.58    8.0   41.0  41.0    1  16.71   -              <- the scripted pass line, unbound
** +0.00    0.0   41.0  41.0    1   0.60   -              <- candidate 16: STAND STILL
```

Three things follow, all measured:

1. **The two-body negotiation is real but never total.** The oncoming auto-rickshaw is 11 m
   ahead closing at 8.33 m/s and it genuinely cuts the low-speed candidates (`#5 ASSERT`,
   terminal prefix 7-10 steps). It does **not** cut every sane pass: the faster lines through
   the same gap stay safe for the full 41-step horizon. By t=31.60 the auto is 5 m *behind*
   the ego and the fan is wide open. The car sits at s ≈ 286 until t = 62 regardless.
2. **`findSharedTrunk` commits to standing still.** Its documented tie-break is longest safe
   stretch first — and a stopped car ties at the full horizon — then **smallest sideways
   offset**. Straightness beats a fully-safe 22.85 m pass. This is the documented behaviour
   working exactly as written; it is not a bug in the frozen package.
3. **Rung 1 cannot help and rung 2 lasts one tick.** Rung 1 needs `trunkProgress < 0.6` and the
   stand-still trunk's progress is exactly 0.60. Rung 2 finds the pass, uses it for one 0.05 s
   `followTrunk` call, resets the stuck clock — and the ordinary route reverts to candidate 16
   for the next 2 s. Measured **17 times in a row** under exact sensing, 0.0045 m each.

**So S1 does not need patience, it needs commitment.** A WAIT rung that could not say *"there is
nothing to wait for"* would just be a slower way to freeze.

## 2b · WHAT IS BUILT, AND WHY BOTH HALVES ARE NEEDED

```
NONE ──stuck, a real go-around exists now────────────────────▶ PASS
NONE ──stuck, none exists, and ONE named track is why────────▶ WAIT
WAIT ──that track still tracked, still planned against, no
        longer binding────────────────────────────────────────▶ PASS
WAIT ──WaitTimeout_s elapsed─────────────────────────────────▶ NONE (+cooldown)
PASS ──driven out, held too long, or the line went unsafe────▶ NONE
```

Held in `st.Neg`, threaded across steps exactly like `st.TrackMem` and `st.EscMem` already are.

- **`iBindingConflict`** reads `out.BindingFuture` (already computed) and counts which single
  `out.Futures(j).TrackID` blocks the most candidates that are sane over their **whole** length.
  Candidates cut by mode B's terminal-stop check carry `NaN` and are skipped — there is no
  vehicle to wait for. **Returning `NaN` is the useful answer**: it is the seat's signal to go.
- **`iTrackConsidered`** is the guard on the commit: the waited-on TrackID must still be present
  among this cycle's `out.Futures`. Without it the fan "opens" the instant the conflicting
  vehicle drops out of the sensor list — which is not hypothetical, it is the measured mechanism
  behind §1c.
- **`iPickHoldLine`** re-picks the committed **lateral line** against the fresh fan every cycle
  and abandons it if nothing in the band is still sane and safe. It ranks by **progress**, not by
  nearest offset: every offset column carries a trivially-safe terminal-speed-0 candidate, so a
  nearest-offset rule would re-select standing still on the next tick and re-create the freeze.
- **The timeout** hands back to the pre-existing rung 2 unchanged, so the floor is exactly the
  old behaviour and never worse.

**Deliberately unchanged:** `iPickGoAround` still ranks by maximum progress, so *which* candidate
is committed to is the Phase 8 rule untouched. That is one change at a time: this run measures
whether commitment alone unfreezes S1. Its known cost is that max-progress prefers the outermost
line (−2.50, 0.15 m from the carriageway edge) over the scripted pass line (−1.585, which scores
1.065 m each side). **If the clearance comes out poor, that is the next measured step, not a
tuning guess.**

## 2c · MEASURED, STEP BY STEP

Every row is a full `matlab -batch` run of the real runner, not a probe.

### Step 0 — baseline (Phase 8 as recorded)
| | `SENSED=true` | `SENSED=false` (exact) |
|---|---|---|
| ego at t = 30 / 45 / 60 | 286.0 / 286.7 / 390.8 | 286.0 / 286.1 / **286.1, never moves again** |
| closest approach | **-0.623 m** to the cow, t=52.65 | -0.027 m to the tractor, t=16.25 |
| gap to the cow | -0.623 m | never draws level |
| lateral alongside | -0.001 .. +0.003 m | - |
| go-arounds fired | 5, each lasting one 0.05 s tick | **17**, a 2.00 s metronome, 0.0045 m each |

### Step 1 — the WAIT rung + a commitment that outlives one tick
`iNegotiate` / `iBindingConflict` / `iTrackConsidered` / `iPickHoldLine`.

| | `SENSED=true` | `SENSED=false` (exact) |
|---|---|---|
| no collision | **true** (min sep **+0.092 m**, to the auto) | false (**-0.030 m**, the cow) |
| gap to the cow | **+0.343 m** (was -0.623) | -0.030 m |
| lateral alongside | -1.323 .. -0.963 m | -0.590 m |
| reaches | s = 482 (was 420) | s = 298.3 (was 286.1) |

**The freeze is broken in both.** Under exact sensing the commitment holds 3.7 s and carries the
ego 286.0 -> 296.5 m at v 0.09 -> 3.50 m/s, where before it never moved at all; the WAIT rung
then engages exactly as designed - *"stuck 3.1 s - every sane pass is blocked by track 1,
holding"* - times out at 10 s, cools down and re-arms.

**But the seat could not execute the line it committed to.** It committed to e=-2.50 and reached
only e=-0.590 before drawing level. Two causes, both measured:
1. `cmd.e` was taken from the LOOK-AHEAD point, 2-6 m ahead, where the chosen candidate has
   barely begun its lateral move - so the seat commanded "slightly over" every tick and never
   the committed line. `sc.s1drive`'s own COMMIT case sets `cmd.e = ctx.passE` outright.
2. `sc.lateralStep` caps the lateral rate at `tand(12)*v`, so a lateral move of dE needs at
   least 4.7*dE metres of forward travel. Committing from 14 m short and then accelerating to
   3.5 m/s spends the distance before the crab can deliver the offset.

### Step 2 — steer to the committed line, hold the pass speed until it is established,
### and choose the line by CLEARANCE rather than by raw progress
**Prediction recorded before running** (§2b): step 1's fix alone would make the reported number
*worse*, because e=-2.50 clears the cow by 1.94 m but the carriageway edge by only 0.10 m -
worse than the 0.343 m the *incomplete* move accidentally achieved. The three changes are
coupled and were therefore measured together.

`iPickPassLine` maximises the minimum lateral clearance among candidates planContingency has
already certified safe. **It lands on e = -1.585 - the scripted pass line - from the free-gap
geometry, not by being told.**

### Step 3 — a FLOOR on the clearance, not just a ranking
A real defect in the first version of `iPickPassLine`, found by measurement: it committed to
`"e=-0.90 m (clearance -0.73 m)"` - a NEGATIVE clearance, a guaranteed overlap - because -0.73
was simply the largest number on offer while the oncoming auto occupied e = [-2.37, -1.07]. It
clipped the auto by 0.095 m. **Taking the best available is not the same as taking an acceptable
one**, and when nothing acceptable exists the answer is to WAIT - which is what returning empty
now makes the ladder do. Five seconds later, with the auto gone, the same function finds
e=-1.58 at +1.02 m. `MinPassClearance_m = 0.5` sits deliberately BELOW the placeholder's own
0.965 m margin, so the floor cannot be what produces the headline number.

---

## 2d · THE FINAL NUMBERS

### S1, exact-position tracks (the uncontaminated test bed)
| | baseline (Phase 8) | with the rung |
|---|---|---|
| route reached | **frozen at s = 286.1**, t = 30 -> 62 | **s = 610 of 610, the complete route** |
| draws level with the cow | **never** | yes |
| gap to the cow | - | **+0.965 m** (placeholder 0.965) |
| gap to the edge | - | **+0.965 m** (placeholder 0.965) |
| `planner clearance vs 0.965` | false | **TRUE - first time this gate has been met** |
| ladder | 17 one-tick go-arounds, 0.0045 m each | freeze -> ABORT hold -> commit e=-1.585 -> clear |

Per-actor minimum separation, same run:

| actor | minSep | t | verdict |
|---|---|---|---|
| **cow** | **+0.965** | 35.95 | the negotiation, solved |
| **auto** | **+0.096** | 31.35 | was -0.095 before the clearance floor |
| moto_wrong | +0.693 | 14.85 | clear |
| trolley | +0.061 | 16.45 | clear |
| tractor | **-0.027** | 16.25 | **byte-identical to baseline** - pre-existing, 50 m before the freeze |
| moto_over | **-0.850** | 59.90 | **scenario artefact** - see below |

**`moto_over` is not a driving failure.** Measured: it reaches station **610.0 - the end of the
route - at t = 35.00 and never moves again**, parked at e = -0.45 on the carriageway. The
placeholder only reaches 485.9 by t = 62 so it never meets it; the planner-driven ego now
*completes* the route and stops on top of it, the gap pinned at exactly -0.850 for t = 60/61/62
with both stationary. **REF-17 s16a #3 recurring** - *"the bus finished its trajectory and PARKED
on the circulating carriageway, exactly where the ego later drove"*. Fix belongs in
`sc.s1actors.m`, outside this task's scope.

### S1, sensed tracks
| | baseline | with the rung |
|---|---|---|
| no collision | **false (-0.623 m to the cow)** | **true (min sep +0.092 m, to the auto)** |
| gap to the cow | -0.623 m | **+0.853 m** |
| gap to the edge | +2.549 m | +0.994 m |
| route reached | s = 420 | s = 477 |

### S2 — THE REGRESSION WAS A HARNESS ARTEFACT, AND IT IS NOW DISPROVED

The 6 Sep entry below recorded S2-sensed going -0.625 -> -1.123 with the rung, and blamed a
12 s hold at the give-way line. **Measured on 7 Sep, that was wrong on both counts.**

Dumping the fan at the contact showed the seat was on the ORDINARY route with an **empty track
list**:

```
t=25.80  s=118.1  v=6.93  ORDINARY  tr:            <- nothing at all
t=25.95  collision, -1.123 m to "wrong"
```

The wrong-way rider **parks at s=118.0** and never moves again. It leaves the sensed TrackList
at **t=14.50**, because by then the SCRIPTED ego - where `buildTrackListSensed` mounts the
sensors - is up to **+66 m** further down the road. The planner-driven ego, still back at
s=99.3, then drives into an obstacle sitting **18.7 m directly ahead of it** that it would have
seen perfectly well from where it actually was. **Identical mechanism to S1's -0.623 m.**

**THE FIX WAS THE HARNESS, NOT A CONSTANT.** `sc.senseRig` + `sc.senseStep` sense from the
ego's own pose every step. Nothing new is simulated - `simulateSensors`/`trackObjects` were
already per-step calls and `buildTrackListSensed` only batched them against the wrong ego; same
seed, same sensor model, same tracker. Both runners take `INLOOP` (default true) and keep the
old path for an A/B.

| S2 sensed | broken harness | **fixed harness (in-loop)** |
|---|---|---|
| baseline (original seat) | -0.625 | **-0.909** |
| with the rung | -1.123 | **-0.909 - IDENTICAL to baseline** |

**The rung changes S2 by exactly nothing.** The "regression" was entirely the measurement.

### S2's REAL failure - pre-existing, different mechanism, NOT what a D9 rung addresses
Under honest sensing S2 still collides at -0.909 m, in baseline and rung alike. Traced:

```
t=10.00  s=104.7  e=+0.48  v=4.71  EMERGENCY      <- braking, never moving over
t=12.70  ................................          <- contact, -0.909 m
t=13.50  s=116.2  e=+0.87  v=0.00  EMERGENCY      <- stopped
t=15.00  s=116.2  ABORT "every sane pass is blocked by track 43, holding"   <- 2.3 s too late
```

**The ego never moves to the ring line.** It drives at **e = +0.87** while S2's ring line is
**e = -2.60**, and the parked rider sits at **e = +1.29** - only 0.42 m away laterally. There
IS room: measured, the rider leaves **4.91 m** clear on its right and the car needs 1.90 m.
The ego simply never takes it, because `findSharedTrunk`'s tie-break prefers the smallest
lateral offset - **the same root cause as S1's stand-still preference**, expressed as "won't
commit the lane-change" rather than "won't move at all". That is the structural gap
`sih26037-s1-planner-fork` recorded, it lives on the ORDINARY route, and it happens **before**
the D9 ladder can engage. Fixing it means overriding the ordinary route's lateral choice
continuously - a different and far more invasive change than a D9 rung, and the one most likely
to break S1 and the demo. **Not attempted here; reported.**

### A SCENARIO BUG FOUND, worth fixing wherever S2's actors live
The parked rider still reports **`Velocity = 5.00 m/s`** while its position is frozen at
s = 118.0 from t = 13 onward. Anything consuming the TrackList - `predictAgentFutures`
included - therefore rolls a stationary obstacle forward at 5 m/s. Measured, not inferred:
`riderS` is constant while `riderV` stays 5.00.

### Team suite
`runtests('matlab/tests')` at `~/dev/sih2026`: **344 passed, 0 failed, 0 incomplete, of 344.**

## 3 · WHAT THIS MUST NOT DO
- Must not touch `matlab/+sih/+planner/` — frozen.
- Must not make either scenario measure worse than the Phase 8 numbers.
- Must not hold a committed path without re-checking it.
- Must not treat "the track vanished" as "the track cleared".
- Team suite at `~/dev/sih2026` must stay **344/344**.

## 4 · HOW IT IS VERIFIED
1. `s1_planner_run.m` / `s2_planner_run.m` end to end under `matlab -batch`, `SENSED=false`
   (the honest test bed) **and** `SENSED=true` (the recorded configuration), both reported.
2. The S1 state timeline must show the mechanism, not just a number.
3. `runtests('matlab/tests')` at `~/dev/sih2026`: 344/344.
4. A negative result is reported as a negative result.
