# Stream A · World

**You own everything the car drives on.** Without this nobody else can test anything, so you are
first in the critical path.

## Your job, in order

### A1 — Run the de-risk checks
`derisk/HOW-TO-RUN.md`. Checks 0 through 5. **Check 2 is the one everything rests on** — an
unmarked road, a custom cow mesh, and a lidar point cloud with returns off the cow.
Send the full output and the saved image.

### A2 — Real Meerut geometry, free
This is Team TwinX's headline move and it is two lines:
```matlab
scenario = drivingScenario;
roadNetwork(scenario,'OpenStreetMap','meerut.osm');
```
Download the `.osm` from openstreetmap.org (Export button). No RoadRunner, no licence.

### A3 — The two scenarios, perfect
**Only two. Not five.**
1. **Unsignalled four-way junction** — no markings, mixed traffic, nobody has priority
2. **Cattle crossing** — the zebu, on an unmarked road, with the ego approaching

Both need a density parameter, because our headline result is a curve against traffic density,
not a single video. Expose it as a config field.

### A4 — Unmarked roads
```matlab
road(scenario, centers, 'Lanes', lanespec(1,'Width',12,'Marking',laneMarking('Unmarked')));
```
**`lanespec` is lowercase.** `laneSpec` does not exist — this already cost us an hour.

### A5 — Replay real trajectories
Drive the non-ego agents from **recorded METEOR/IDD trajectories**, not scripted paths.
This permanently kills the "you scripted the traffic to freeze the baseline" attack. Highest
value item after A1, and Stream C can hand you the data.

### A6 — OpenDRIVE export
`export(scenario,'OpenDRIVE','scene.xodr')`. This is our answer to "where are the RoadRunner
scenes?" — they import the day a licence appears. Note the documented limitation: roadGroup
junctions are unsupported for HD-map export. Test it early and report what breaks.

## Do not
- Do not build all five scenarios. Two perfect ones beat five rough ones.
- Do not hand-place traffic where recorded trajectories will do.


## Done when

| Task | Done means |
|---|---|
| A1 | All six de-risk checks reported, full output sent |
| A2 | `check03_osm_import` prints >0 roads and saves the map image |
| A3 | Both scenarios run start to finish with a density parameter that visibly changes agent count |
| A4 | A road exists with `laneMarking('Unmarked')` and no painted lines appear in the plot |
| A5 | Non-ego agents follow **recorded** trajectories, not hand-written waypoints |
| A6 | `export(...,'OpenDRIVE')` produces a `.xodr` that reopens without error |

**Four conditions apply to every task** (`docs/WORKFLOW.md`): it runs from a clean clone, a test
covers it, it matches `docs/INTERFACES.md` exactly, and someone else could run it without asking
you a question.

## Your handoff

**H1 → B:** tell Stream B the moment a scenario has actors in it. They cannot attach sensors to nothing.

**Read `docs/WORKFLOW.md` before your first commit** — branch naming, commit format, how to report
a blocker, and what to do when the contract is not enough.

---

## What you use

| | |
|---|---|
| **Stack** | MATLAB + Simulink (Automated Driving Toolbox) |
| **Machine** | Windows or Mac |
| **IDE / agent** | Antigravity |
| **Key functions & tools** | `drivingScenario` · `roadNetwork` · `lanespec` · `laneMarking` · `export(...,'OpenDRIVE')` · OpenStreetMap |

**Setup:** `docs/SETUP.md` — 20 minutes.
**Before you write any code:** read `docs/INTERFACES.md`. It is frozen; five other people build
against it. If your agent proposes editing it, the answer is no.

**Reference docs you will need:**
`docs/PRD.md` (the whole idea) · `docs/ROADMAP.md` (phases and gates) ·
`docs/metrics.md` (M1–M10) · `docs/CLAIM-LEDGER.md` (never state a number that is not in it)
