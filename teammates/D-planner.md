# Stream D · Planner

**You own the thing that makes this project novel.** Everything else is plumbing around it.

## What is already written for you
| File | State |
|---|---|
| `matlab/+sih/+planner/velocityObstacle.m` | **Written.** Full VO geometry, verified equations |
| `matlab/+sih/+planner/assignRoles.m` | **Written.** COLREGs roles from geometry alone |
| `matlab/tests/testPlannerGeometry.m` | **Written.** 13 unit tests |

## First thing you do — five minutes, no simulation needed
```matlab
cd <repo>
results = runtests('matlab/tests/testPlannerGeometry.m');
disp(results)
```
All 13 must pass. **Send me the full output either way.** This verifies the planner maths before
any simulation exists, and it needs no toolboxes beyond base MATLAB.

## Your job, in order

### D1 — Confirm the maths (above)

### D2 — The velocity command
`matlab/+sih/+planner/chooseVelocity.m`. Given roles and the VO cones, pick the ego command.
The rules, from the actual COLREGs text:
- **GIVE_WAY** → one **early and substantial** manoeuvre. Not creeping. Pass astern.
- **STAND_ON** → **hold course and speed.** Do nothing. This is the hard one to implement
  because doing nothing feels wrong, and it is the entire safety argument.
- **Rule 8** forbids "a series of small alterations." If your controller oscillates, it is wrong.

### D3 — The Stateflow chart
Subclass `DrivingStrategy` from `mathworks/OpenTrafficLab`. **Delete `TrafficController`.**
Each agent decides its own role inside its own chart, from geometry, with no broadcast.

### D4 — Mode switching
`docs/INTERFACES.md` S8. When lane structure exists, switch to `STRUCTURED` and defer.
We do not claim a win on the highway merge. *"Our planner knows when it isn't needed."*

### D5 — Log the barrier
Every step, log `h = lambda - beta` per track. That is our safety evidence and it is already
computed for you in `velocityObstacle.m`. `h >= 0` is safe; forward invariance of that set
is the guarantee.

## The one insight worth carrying
`h = lambda - beta` **is** a control barrier function. We do not bolt a safety filter onto the
planner — the planner is already written in the filter's own variable. Research section 15.

---

## What you use

| | |
|---|---|
| **Stack** | MATLAB + Simulink + Stateflow |
| **Machine** | Windows |
| **IDE / agent** | Antigravity |
| **Key functions & tools** | `sih.planner.*` (written) · Stateflow · OpenTrafficLab `DrivingStrategy` · `importNetworkFromONNX` · Predict block |

**Setup:** `docs/SETUP.md` — 20 minutes.
**Before you write any code:** read `docs/INTERFACES.md`. It is frozen; five other people build
against it. If your agent proposes editing it, the answer is no.

**Reference docs you will need:**
`docs/PRD.md` (the whole idea) · `docs/ROADMAP.md` (phases and gates) ·
`docs/metrics.md` (M1–M10) · `docs/CLAIM-LEDGER.md` (never state a number that is not in it)
