# SIH26037 — HQ. Read this first.

**Last updated: 16 September 2026.** One folder, one truth. If something here disagrees
with a document inside the repo, **this wins** — the repo docs were last synced 10 Sep and
have gone stale in three places (listed at the bottom).

---

## What the project is, in five lines

An Indian junction has no traffic light and no rule about who goes first. A cow can stand in
the road and never move. Every self-driving system built for Western roads waits for the road
to be clear — and it never clears. So it freezes.

Ours creeps forward, watches whether the other driver or the cow gives way, then decides.
And it can prove, at every step, that it never crossed its own safety line while doing it.

**Problem statement:** SIH26037, MathWorks, theme Smart Vehicles, Software category.
**Locked 29 Aug 2026. Not reopened.**

---

## Where everything lives

| | Path |
|---|---|
| **The code** | `~/dev/sih2026` — branch `main`, currently at `f4d1f79` |
| **This HQ** | `~/dev/sih2026-hq` (NOT on the Desktop — the Desktop is iCloud-synced and offloads files to 0 bytes) |
| The 3D city | `~/dev/sih2026-city`, branch `city/land-and-light` |
| Research archive | `~/Desktop/SIH26037-Archive` — 135 files, every research report |
| Trained models | `~/meteor-data/features/` |
| Job briefs for the agents | `04-JOBS/` in this folder |
| What the agents reported back | `REPORTS/` in this folder |

---

## Who does what now

**Aditya is the sole builder.** ML training runs on the KIET supercomputer — he writes the
command, a friend runs it there, the result comes back.

| | Role | Owns |
|---|---|---|
| **Claude** (this chat) | Plans, writes briefs and documents. **Writes no code.** | `~/dev/sih2026-hq` |
| **Codex CLI** | Executes MATLAB: runs, tests, fixes, commits | `matlab/` |
| **Antigravity CLI** | Executes ML and Python, docs | `ml/`, `plan/` |

**They must never touch the same folder.** That rule is what stops two agents producing two
versions of the same thing with nobody knowing which one the demo used.

---

## The state of the three scenarios

| | Status |
|---|---|
| **S1 — the cattle crossing** | **Works.** 610 m of real Najibabad road, full route, 0.965 m clearance each side. Holds under real sensing, not just ground truth. This is the headline result |
| **S2 — the chowk** | **Broken.** Collides with the wrong-way rider, then permanently stalls at s ≈ 116–121 m of a 244 m ring and never exits. Happens under BOTH sensing modes. Not fixed as of 16 Sep |
| **S3 — the galli** | **Works.** 382.2 m route, a 1.95 m squeeze, oncoming motorcycle + child + dog, all cleared, 0 plan failures |
| S4 highway, S5 mountain | Written specs only. Never built |

---

## The rules this project runs on — they are not optional

1. **Never invent a number.** If you did not run it, write `TODO(unverified)`.
2. **Never summarise an error.** The whole message, first line to last. A trimmed error costs a day.
3. **Disclose bugs before a judge finds them.** This is the project's actual competitive edge.
4. **Never edit `matlab/baseline/`** — it is MathWorks' shipped planner, kept unmodified. Tune
   it to survive and a judge calls it a strawman and the whole comparison dies.
5. **Never change section 3 of `AGENTS.md`** — the frozen contract everything is built against.
6. **Never ship a half-fix.** If it isn't clean by its cutoff, it reverts. An 80%-done fix is
   not 80% as good — it is a new, untested failure mode.

---

## Three places the repo's own docs are now wrong

- `CLAUDE.md` §3 says **S3 is "spec written, nothing built."** It is built and passing.
- `CLAUDE.md` §3 says **`+metrics/` is empty.** It exists and produces the frozen
  `results/<run>/` evidence format.
- `CLAUDE.md` §3 and `plan/CLAIM-LEDGER.md` both say S2 **"works, one disclosed bug."**
  It does not work — see the table above. The claim ledger's own Part 2 has the correct
  version; its older sections do not.
- Every doc quotes the ML dangerous-error rate as **20.18%**. The real figure is **2.089%** —
  see `01-ML-NUMBERS-CORRECTED.md`.

---

## SCOPE LOCKED — 16 Sep 2026

**Two scenarios, perfectly. S1 (the cattle crossing) and S3 (the galli).**
All ten phases get built and proven on those two before a third is touched.

**Why these two:** they are the only two that currently work. S2 collides and then stalls
permanently; S4 has no route and no seat at all. Building depth on a broken scenario means
you can never tell whether a failure is the new code or the old bug.

**Then, in order:** extend to a third (S4 is a build from nothing, ~4–6 days; S2 is a fix,
3–5 days, and may not yield). Then the fourth. **S2 can be dropped without losing the
deliverable** — it stays disclosed, as it has been from the start.

**This satisfies the problem statement.** It asks for *"an adaptive path planning system"*
with scenarios and results — it does not ask for four. Two done properly, with confidence
intervals and honest disclosure, beats four done thinly. Four-done-thinly is the exact
failure mode that lost Quiesce, Tenable and NETRA.

**Revised estimate: 15–18 working days on the pair, ≈3–4 weeks calendar** (down from 7–10
weeks for four).
