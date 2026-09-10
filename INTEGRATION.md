# INTEGRATION — the integrator's page

**Aditya only. One page. Current as of 10 September 2026, by running things.**

`README.md` orients. `TEAM.md` says who owns what. `HANDOFF.md` says what each person does next.
**This file says what is actually true right now, and what is blocking what.**

Everything below the "probe never fires" crisis that used to live on this page has been fixed —
that history is preserved in `plan/BACKUP-PROBE-FINDING.md` and `matlab/D9-WAIT-RUNG.md` if you
need it, but it is no longer the current state and this page no longer repeats it.

---

## TODO(unverified) — the chat structure

The old version of this page described **three chats**: CITY (the 3D Blender world, a separate
chat), BACKUP (a fallback demo), INTEGRATOR (this repo). Aditya has said the 3D city and game
build now happen in a genuinely separate chat from this one. Whether BACKUP is still a distinct
third chat, or has folded into one of the other two, was not confirmed when this page was
rewritten — say so here rather than guess. **Aditya: correct this section the next time you touch
this file.**

What's not in question: **this repo (the "INTEGRATOR" role) owns the MATLAB planner, the ML
pipeline, the baseline, the evidence, and the live 2D demo (`demo_play.m`).**

---

## THE DEMO RUNS ON ADITYA'S MAC

Confirmed by running every piece on it, not by assuming.

| Piece | State |
|---|---|
| Full test suite | **344 tests, 335 pass, 0 fail, 9 incomplete** (OpenTrafficLab-not-cloned skips — expected on a fresh clone, not a regression) |
| `matlab/baseline/` | Runs, **fails at 19.7s, 0/120 collision-free** — the result, not a bug to fix |
| S1 (the cow) | **Fully solved.** 610m real route, 0.965m clearance each side, full route |
| S2 (the chowk) | **Does not finish the route, under either sensing condition** — re-run 10 Sep: ground truth grazes at −0.003m, real sensing collides at −0.909m (the previously-documented figure, reproduced exactly), and BOTH then permanently stall around s≈116–121m of 244m, never reaching the ring exit. Antara's task — `plan/CLAIM-LEDGER.md` Part 2 has the full account |
| Real sensing in the live demo | **Done 10 Sep.** `demo_play.m`'s `Sensed=true` wires `sc.senseRig`/`sc.senseStep` into the per-step planning loop. 0.965m clearance holds under real sensing too. Default stays `Sensed=false` for the rehearsed path |

---

## What's currently being built (Aditya's own queue)

1. This documentation pass — bringing every orientation doc back in sync with the current
   6-person org and current state (in progress; this file is part of it)
2. **S3 — the galli scenario.** Spec exists and is fully measured (`world/scenarios/S3-THE-GALLI.md`),
   nothing built yet. Scoped to the actors the planner actually negotiates (oncoming motorcycle,
   a child crossing, a dog in the squeeze) — the spec's full cast (23 people, animals, birds) is
   3D-city scenery, not 2D-demo actors
3. **Wiring `demo_play.m` into the frozen `results/<run>/` format** — `trajectories.csv`,
   `metrics.json` (M1-M10), `config.json`. Currently the live demo produces neither; reusing the
   already-proven M1-M10 formulas from `world/build/backup/matlab/+backup/metrics.m`

## What's blocked on teammates, not on Aditya

- Antara's S2 fix and live-obstacle-injection MVP (the single biggest differentiator and the
  single biggest live-demo-day risk — per the locked pitch notes, worth rehearsing a fallback)
- Anjali's profiling (gates how fast Antara's live-injection can actually re-plan), the safety
  watchdog, and the randomized-run rigor upgrade
- Shourya's calibration and YOLOX domain-gap fix; Kishan's evaluation — until both land, the ML
  models stay off the critical path for the demo (the planner already falls back to the geometric
  role when a model isn't confident, so this fails safely either way)
- Aditya B.'s live-gating of the demo panel with real model status

**None of the above blocks the "already true today" list** — S1, the disclosed S2 bug, the
baseline result, and real sensing in the live demo are all real and don't depend on anyone
finishing anything else.

---

## Before quoting any number

1. `plan/CLAIM-LEDGER.md` — what may and may not be said, with the honest replacement for each.
   Worth a fresh read given how much has changed since it was written; don't assume it's current
   without checking.
2. **Re-run the test suite before quoting its count.** It has been wrong in these docs multiple
   times before, always from someone not re-running it.
3. `matlab/baseline/` — verify, never edit: `git status --short matlab/baseline/` must print nothing.
4. A number without its `config.json` is not a result (`AGENTS.md` §3).

---

## The rulings — still load-bearing, not retired

These were real decisions, made once, and nothing since has reopened them:

- `D6-TRUNK-RULING.md` — trunk is **(b)**, the longest prefix with a safe continuation under both
  futures, not merely the longest collision-free stretch
- `S3-PYIELD-RULING.md` — `PYield = 1 - P(assert)`; gate the model behind `Valid = false`
- `ARBITRATION-RULING.md` — `arbitrate(roles)` takes the role list only; winner is smallest `h`
- `plan/BASELINE-R2026a.md` — the baseline's failure, reproduced on two platforms, is the result
- `sih26037-s1-planner-fork` (memory) — Option A (a minimal D9 layer in the `+sc` adapter, not a
  change to the frozen `+sih/+planner/`) is how S1's negotiation actually got solved

`AGENTS.md` section 3 has not moved since any of this. That is the freeze doing its job.
