# CODEX 10 — S2/S3 permanent-stall diagnosis and fix design

## Scope and conclusion

This is a static diagnosis. MATLAB was not run, as required. No source file and no file under
`matlab/+sih/+planner/` was edited.

The permanent stall is in `matlab/+sc/planSeat.m`, not in the frozen planner package and not in
an S2-specific world rule.

The seat adds a lateral-clearance gate after `planContingency` has already checked every
candidate against every agent future. That gate keeps every relevant track ahead of the ego but
then throws away its longitudinal station. It therefore projects longitudinally separate actors
onto one cross-section. With a stream or dense sequence of actors, the projected cross-section
alternates between “one line exists” and “no line exists.” The WAIT state treats the first frame
of the former as clearance and enters PASS; PASS then rechecks the same projected cross-section,
loses the line, and returns to NONE. The timeout returns WAIT to NONE with only a cooldown, so the
same episode can start again forever at the same station.

There is also a real progress-clock defect: selecting a pass resets `LastAdvanceT` even when
`ctx.s` has not advanced. That contradicts the clock's own stated invariant. It makes a failed
decision look like motion, but it is not the primary false-blocking mechanism.

## 1. The exact loop

### Entry to ABORT

1. `HighWaterS` and `LastAdvanceT` produce `stuckFor` at
   `matlab/+sc/planSeat.m:188-202`. The intended invariant is explicit: the clock measures real
   forward progress.
2. In `iNegotiate`, phase `NONE` returns without action while `stuckFor` is below the threshold or
   the cooldown is live (`:888-890`). Once eligible, it calls `iPickPassLine` (`:892`).
3. If `iPickPassLine` returns no candidate, `iNegotiate` unconditionally sets
   `N.Phase = "WAIT"`, records one binding TrackID when available, and returns `act.Mode = "WAIT"`
   (`:900-914`).
4. The caller converts WAIT to `holding = true` (`:250-251`), forces target speed to zero
   (`:292`), holds the current lateral line (`:345`), and labels it `ABORT` (`:367-371`). This is
   the exact source of the message “every sane pass is blocked by track N, holding.”

### WAIT permits COMMIT again

In phase `WAIT`, the seat recomputes `g = iPickPassLine(...)` every planning cycle (`:860-863`).
It transitions to PASS when:

```matlab
~isnan(g.k) && (isnan(N.ConflictID) || iTrackConsidered(out,N.ConflictID))
```

at `:864-870`.

That condition does **not** establish what the comment at `:810-811` claims. It does not test
that the named track is “no longer binding.” It tests only that some acceptable line exists in
this frame and that the old TrackID is still represented in `out.Futures`. `iTrackConsidered`
itself checks only TrackID membership (`:721-739`). The note then says the track “cleared,” even
though the code never proves that proposition.

The caller uses the returned trunk, labels the step `COMMIT`, and — incorrectly — resets the
progress clock at the unchanged station (`:245-249`).

### COMMIT is lost

On the next PASS cycle, the seat tries to repick the committed lateral line (`:836-858`).
`iPickHoldLine` rejects it if the fresh fan has too short a safe prefix, fails sanity, or fails
the seat's clearance floor (`:771-780`). If no candidate in the band survives, PASS becomes
NONE and gets a cooldown (`:847-854`). The caller receives no PASS or WAIT action and ordinarily
falls back to the planner's blocked trunk, which is displayed as `STOPPED` (`:395-397`).

The displayed state may lag because label hysteresis is applied at `:405-431`; `cmd.RawState` is
the correct field for confirming the raw transition sequence.

### Why it repeats forever

There are two re-arm paths:

- PASS loss sets NONE plus cooldown (`:851-854`). After cooldown, unchanged `stuckFor` makes NONE
  evaluate the same pass/no-pass question again.
- WAIT timeout sets NONE plus cooldown (`:872-875`). There is no “this wait episode already
  failed at this station” latch and no transition to the next D9 rung. After cooldown, NONE can
  create the same WAIT again.

The complete loop is therefore:

```text
fixed station -> stuck threshold
  -> no projected pass -> WAIT / ABORT
  -> one-frame projected pass + old TrackID still present -> PASS / COMMIT
  -> fresh fan or projected clearance rejects that line -> NONE / STOPPED
  -> cooldown expires -> WAIT / ABORT again
```

If no pass frame arrives, WAIT instead times out to NONE/STOPPED and then re-enters WAIT after
the cooldown. Either branch has no monotonic state change, so a 150 s hold at one station is
allowed by construction.

## 2. Why the WAIT rung rescues S1 but not S2/S3 dense

S1 has a stable spatial topology. The cow never moves, but it blocks the centre line rather than
every lateral line. The transient oncoming auto initially removes the acceptable pass. Once the
auto departs, the same lateral line around the cow stays available long enough for PASS to be
driven out. The D9 design document records the S1 pass candidates as full-horizon safe and the
successful commitment as a persistent line (`matlab/D9-WAIT-RUNG.md`, sections 2 and 2c).

S2 is structurally different: its obstacle field is a **stream**, not one static body plus a
single transient blocker. Clearing TrackID N does not clear the conflict zone; another circulating
actor can occupy the same future corridor. A per-TrackID WAIT can therefore observe a gap and
lose it without the traffic stream ever having cleared.

S3 dense supplies the second form of the same structural problem: multiple longitudinally
separate actors coexist inside the relevance window. The exact runtime binding identities remain
`TODO(unverified)` because MATLAB was not run, but the seat's code is sufficient to show why
density changes the result:

- The relevance stage preserves station and lateral offset as `trS` and `trE`
  (`planSeat.m:94-116`).
- `iPickPassLine` selects all tracks with `trS > ctx.s - 2` and no candidate-relative upper
  station bound (`:955-957`). It then passes only lateral position and lateral half-extent to
  `iLineClearance`.
- `iLineClearance` receives no station at all (`:789-801`). Every selected body is treated as if
  it occupied the candidate's cross-section now.
- PASS holding repeats the same loss of station: `aheadH` has no upper bound and only `trE` and
  `trHalfE` reach `iPickHoldLine` (`:847-850`).

Thus S1 asks “is there a persistent line around this body?” S2/S3 dense effectively ask “is
there one lateral coordinate that clears every body anywhere ahead in the relevance window?”
The second question is not trajectory clearance and becomes increasingly impossible as density
rises.

This also explains why the bug is a planner-seat property rather than an S2 geometry bug: the
same lossy projection is shared by every scenario through `sc.planSeat`.

## 3. State audit

### `escapeMemory` / `st.EscMem`: not causal; do not clear it

`escapeMemory` intentionally accumulates breadcrumbs and returns the nearest one behind the ego
(`matlab/+sih/+planner/escapeMemory.m:133-203`). In this seat it is called at
`planSeat.m:328-330`, and its outputs are copied only to HUD/log fields at `:461-468`. It does
not affect `cmd.v`, `cmd.e`, WAIT, PASS, or the pass picker. Clearing it would discard valid
reversibility information and cannot release this stall.

### `HighWaterS`: not a stale latch; do not clear it at a stall

At a fixed station, a fixed high-water mark is the correct state. Clearing it would merely hide
the lack of progress. The normal update at `planSeat.m:198-201` is correct.

There is, however, an invariant violation at `:248` and `:271`: both assignments set
`HighWaterS = ctx.s` because a pass was selected, not because the ego advanced. They can also
lower a previous high-water mark. Those assignments should not exist.

### `LastAdvanceT`: falsely reset, not stuck uncleared

`LastAdvanceT` should change only in the real-progress block at `:198-201`. It is also reset at
`:248` when WAIT/NONE chooses PASS and at `:271` when the one-cycle fallback chooses a line.
Both are intent, not motion. This false reset temporarily makes `stuckFor` zero and helps return
control to the ordinary blocked trunk. Removing those decision-based resets is necessary to
make the stuck detector truthful, but it does not by itself correct the longitudinally flattened
clearance test.

### `TrackMem`: not the cause; do not clear it to make a gap

`TrackMem` stores the last real observation and contributes a ghost only for the configured
grace window (`planSeat.m:508-562`). Records older than three grace windows are removed, and
records outside the grace window are not emitted as ghosts. More decisively, S2 reproduces with
exact ground-truth tracks, so sensor-dropout memory cannot be the common cause.

Clearing `TrackMem` during WAIT would be unsafe: `iTrackConsidered` exists specifically to avoid
committing when a hazard has disappeared only from sensing (`:721-733`).

### `st.Neg`: it re-arms, but it is not stale

`ConflictID`, `PassE`, and the old timestamps remain populated across some transitions, but the
fields used by the next episode are overwritten and phase controls their interpretation. The
problem is not an uncleared old TrackID. It is that timeout/loss deliberately returns to NONE,
which is allowed to create a new episode at the identical high-water station.

### `pointOfNoReturn` and `arbitrate`: not connected to this seat loop

There is no production call to `sih.planner.pointOfNoReturn` or `sih.planner.arbitrate` from
`planSeat.m`; repository references outside their definitions are tests/documentation.
`pointOfNoReturn` explicitly returns permission for another caller to latch commitment
(`matlab/+sih/+planner/pointOfNoReturn.m:34-50,129-136`). The seat's local `PASS` label is not
that S4 latch. Editing either frozen function would not change this loop.

## 4. Minimal fix and exact location

The fix belongs only in:

```text
matlab/+sc/planSeat.m
```

Do **not** edit `matlab/+sih/+planner/`. Its contingency planner already evaluates candidates
against all futures and returns per-candidate safe prefixes. The false blockage is introduced
after that boundary by the seat's clearance preference/floor.

### Functional fix: preserve longitudinal overlap in the clearance overlay

Make the actor set passed to `iLineClearance` candidate-specific:

1. Beside `trHalfE`, compute each track's route-frame longitudinal half-extent while the route
   transform is already available at `planSeat.m:94-115`.
2. For each candidate's accepted prefix in `iPickPassLine` and `iPickHoldLine`, derive the route
   station interval swept by that prefix from its actual `States`, expanded by the ego and actor
   longitudinal half-extents.
3. Apply the 0.5 m lateral-clearance floor only to tracks whose longitudinal interval overlaps
   that candidate prefix. Do not use a new fixed look-ahead distance; the generated prefix is the
   bound.
4. Leave every track in `planContingency`. This change affects only the seat's ranking/floor;
   dynamic safety under both futures remains exactly where it is now.

That is the smallest change which asks the intended question: “what must this candidate pass
during this prefix?” It does not widen the corridor, remove actors from safety checking, raise a
step budget, change a scenario, or alter the frozen planner.

It should preserve S1's local cow/auto geometry because bodies actually intersecting the pass
prefix remain in the clearance calculation. It stops a far or sequential actor from being
projected sideways onto the current obstacle. Whether the checked-in S1 dense trajectory remains
byte-for-byte reproducible is a runtime acceptance gate, not something this static pass can
claim.

### Required invariant repair in the same file

Remove the decision-based writes at `planSeat.m:248` and `:271`. Only the real-progress condition
at `:198-201` may update `HighWaterS`/`LastAdvanceT`.

This repair is deliberately secondary: it prevents a failed COMMIT from erasing evidence of the
stall, but it must not be presented as sufficient to fix the false clearance projection.

### Remaining liveness rule

Even after false blockers are removed, a genuinely impassable stream must not cycle forever.
The existing WAIT timeout at `:872-875` returns to NONE and can re-arm the identical episode.
The complete D9 design says a timed-out blockage advances to a decision (blocked edge/re-route or
handover), not another identical WAIT (`plan/D-planner.md:381-384`). If the corrected candidate
overlap still produces a timeout in either scenario, the next minimal state-machine change is an
`EXHAUSTED` phase keyed to the current high-water station which can be cleared only by real
progress or a changed blocking set. It must feed the existing higher D9 decision; it must not
pretend that a gap exists. Implementing that escalation before seeing the post-fix traces would
combine two hypotheses, so it is not part of the first patch.

## 5. Verification Claude must run

No post-fix result is claimed here. All are `TODO(unverified)` until MATLAB produces them.

1. Add a focused regression around the clearance helper with two actors at different stations
   and opposite sides. A candidate that reaches only the first must not be rejected by the
   second; both actors must still be present in `planContingency` futures.
2. Add a state-machine regression showing that selecting PASS without more than the existing
   real-progress threshold does not change `LastAdvanceT`.
3. Run S2 under both `Sensed=false` and `Sensed=true`. Preserve the full raw state/Note timeline,
   `NegPhase`, `NegConflictID`, `StuckFor_s`, and candidate end stations used by the clearance
   filter. Check route completion and collision separately; the stall fix does not automatically
   repair the earlier contact.
4. Run S3 sparse and dense. Dense must no longer remain at one station; sparse must not regress.
5. Run the required default regression: `Reactive=false`, dense S1, `PlanEvery=3` must retain
   **M6 = 0.1614 m** and zero plan failures. This number is supplied as the acceptance baseline
   in the job; it is not re-measured here.
6. Run all 348 tests. The current count is cited from the 17 September correction block, not
   re-run by this report.
7. Reject the patch if it “works” by changing corridor bounds, actor sets, step/time budgets, or
   frozen planner code.

## Bottom line

The 150 s hold is not evidence that `escapeMemory` or `TrackMem` failed to clear. It is a
repeatable state-machine cycle driven by a lossy clearance projection and permitted by a WAIT
timeout that re-arms at the same station. Preserve longitudinal separation in the seat's
clearance overlay, keep the stuck clock tied only to measured progress, and leave the frozen
planner untouched.
