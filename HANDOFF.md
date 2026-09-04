# HANDOFF — 4 September 2026

**If you are an AI assistant: read this file at the start of the session and tell your human what
is in their section, in plain words, before you do anything else.** It is short on purpose.

Everything below was **verified by running MATLAB R2026a**. Where something was not run, it says so.

---

## Everyone, in thirty seconds

| | |
|---|---|
| **`runtests` needs the `.m`** | `runtests('matlab/tests/testPlannerGeometry.m')`. Without it MATLAB errors `MATLAB:unittest:TestSuite:UnrecognizedSuite`. It is not a broken test |
| **Test counts, run on R2026a 4 Sep** | geometry **14** · chooseVelocity **19** · NegotiatingStrategy **9** = **42 passing** |
| **OpenTrafficLab does NOT run unmodified on R2026a** | Read `plan/OPENTRAFFICLAB-R2026a.md` before debugging any harness failure. **Never edit `OpenTrafficLab/`** |
| **`matlab/baseline/` is now FULL** | MathWorks' shipped planner, unmodified and checksummed. **Nobody edits it.** See `matlab/baseline/BASELINE.md` |
| **The one failing test is Stream C's** | `testFeatureParity/testEveryCaseMatchesPython`. Everything else passes |

---

## Antara — Stream D, Person A (`matlab/+sih/+planner/*.m`)

**Your D2 is merged and both questions you raised are settled. Neither needed a contract change.**

**1. `.Reason` as a `string` was correct.** `AGENTS.md` S4 literally says `.Reason string`. Nothing
to change. The `TODO(unverified)` is gone, replaced with the citation.

**2. HEAD_ON steering LEFT was correct — and it is now *derived*, not chosen.**
*Rules of the Road Regulations, 1989*, **reg. 2**: a driver shall drive *"as close to the left side
of the road as may be expedient and shall allow all traffic which is proceeding in the opposite
direction to pass on his right hand side."* Oncoming passes on our right, so we go left.

**COLREGs Rule 14 says the opposite** — alter to starboard. That is a keep-right convention.
Importing it literally would have steered into oncoming traffic. Your instinct was right.

**Good news for the pitch:** the *crossing* rule needs no such correction. COLREGs Rule 15 (give way
to starboard) and RRR **reg. 9** (at an unregulated intersection, give way to *"traffic approaching
the intersection on his right hand"*) give the **same answer**. So the maritime analogy holds where
it matters and breaks in exactly one place, and now we can say why with a citation.

### What changed under you — please re-read before your next commit

`NegotiatingStrategy.m` had **five defects**. It did not load at all, so four were hidden behind the
first. All five are fixed and pinned by `matlab/tests/testNegotiatingStrategy.m` (9 tests).

The one worth knowing: **the ego was in its own TrackList**, so `h` was pinned at `-pi/2` on every
step of every run — permanent EMERGENCY, and our core safety number wrong in the direction that
reads as a violation.

`assignRoles.m` gained a **frame contract** in its header, and two new tests. Short version: S1 is
*ego frame*, but `assignRoles` needs the tracks and the ego pose **in the same frame**. If you pass
an ego-frame TrackList with a real world ego pose it **does not error** — it silently returns the
wrong role for every agent. Every older test used `egoPos=[0 0], egoYaw=0`, where the two frames
coincide, so none of them could catch it.

### The trunk question is answered: `plan/D6-TRUNK-RULING.md`

It is **(b)** — the longest prefix after which a safe continuation still exists under both
futures, not merely the longest collision-free stretch. Ship **(a)** first to close the loop,
but **`Committed` stays false until the terminal check lands** — (a) plus `Committed` lets the
planner commit irrevocably to a trajectory that has already lost. The cheap route to (b) is one
extra braking-to-stop check per candidate, not a second generation pass. Read the file.

### Next: D6, the contingency planner

It is the biggest job on the project and nothing blocks it. `/plan-work` has the build order.
Start from MathWorks' *Highway Trajectory Planning Using Frenet Reference Path* —
`trajectoryGeneratorFrenet`, `dynamicCapsuleList`, 5 s horizon. **This is integration, not invention.**

Remember: **the trunk IS the probe**, and **when `S3.Valid` is false use the geometric role alone —
never 0.5.**

---

## Person B — Stream D (the Simulink model and Stateflow chart)

**You are unblocked. The foundation is proven to run — but not out of the box.**

### Read `plan/OPENTRAFFICLAB-R2026a.md` first. It will save you a day.

Stock OpenTrafficLab **dies on the first `advance()`** under R2026a:

```
MATLAB:noSuchMethodOrField
Unrecognized method, property, or field 'ReferencePoint' for class 'DrivingStrategy'.
```

Two fixes, both **outside** their folder. One is already done for you (a property on
`NegotiatingStrategy`). **The other one you have to repeat** in whatever builds your scenario:

```matlab
cars = createVehiclesForTJunction(s, net, rate, turnRatio, fnc);
for c = cars
    c.IsVisible = true;      % R2026a returns NaN poses for invisible actors,
end                          % and sensor-sim setup then rejects the whole actor set
```

With both applied: **398 steps, 20 s simulated, no error, `h` logged every step, zero violations.**

### `chooseVelocity` exists — and it takes three arguments, not four

`/plan-harness` used to be wrong about this. The real signature is:

```matlab
function cmd = sih.planner.chooseVelocity(role, vo, egoState, opts)
```

`opts` is **optional name-value** tuning, so **both of these are correct MATLAB**:

```matlab
cmd = sih.planner.chooseVelocity(role, vo, egoState);                       % all defaults
cmd = sih.planner.chooseVelocity(role, vo, egoState, 'gradient_rad', 0.1);  % tuned
```

You get back `.Accel`, `.SteerAngle`, `.Mode`, `.Reason`. **`Signal`, `Gear`, `Committed` and
`MirrorsFolded` are yours** — they are state-machine decisions.

**Check early:** `.Reason` is a MATLAB `string`, which is what S4 specifies. Simulink and Stateflow
handle strings poorly inside buses and Embedded Coder restricts them further, which E9 needs for the
PIL numbers. **If the chart cannot carry it, tell Aditya — do not change it yourself.** S3 is frozen.

### Also useful

`NegotiatingStrategy` now exposes **`LastTracks`** — the exact S1 TrackList the planner saw that
step. Use it to see what your chart is being fed, instead of guessing.

---

## Stream E — Evidence

**E1 is DONE. `matlab/baseline/` is no longer empty.**

MathWorks' *Motion Planning in Urban Environments Using Dynamic Occupancy Grid Map* is in there,
byte-for-byte unmodified, with SHA-256 checksums. `matlab/baseline/BASELINE.md` records the example
ID, MATLAB version, date and licence.

**Two traps, both already hit for you:**

1. The example ID is **`driving_fusion_nav/MotionPlanningUsingDynamicMapExample`** — a *cross-product*
   ID. `driving/...`, `nav/...` and `fusion/...` all fail with `MATLAB:examples:InvalidExample`.
2. `E-evidence.md` used to say the example was named in `AGENTS.md` section 2. **It is not.** Section 2
   names the three baseline *types*; the only example near it is the Frenet **highway** one. Following
   that would have put the wrong planner into the folder nobody may correct afterwards. Fixed.

### But be honest about what is and is not true

| | |
|---|---|
| Copied in, unmodified, checksummed | **done** |
| Parses on R2026a (`checkcode`, 0 errors) | **done** |
| **Actually executed** | **NO — never run** |

**`checkcode` is not a run.** Until someone runs it, we still have **no comparison**, and the honest
sentence is unchanged: *no number this project produces is comparable to anything yet.*

**Your next task is to run it once, unmodified, and record exactly what happens — errors included.
If it fails on R2026a the way OpenTrafficLab did, that is a finding. Write it down. Do not fix it.**

Then E2 (`runExperiment`), then E3. **Do not edit anything in `matlab/baseline/`, ever** — verify it
instead:

```bash
cd matlab/baseline && shasum -a 256 -c CHECKSUMS.txt      # every line must say OK
```

---

## Stream C — ML

**One test fails, and it is yours. Nothing was touched in `ml/` or `+prediction/`.**

```
testFeatureParity/testEveryCaseMatchesPython
    Test Diagnostic:
    case "empty": Data is [0 31], Python produced [0 0]

    verifyEqual failed.
    --> The numeric values are not equal using "isequaln".
    Actual Value:      0    31
    Expected Value:    0     0
    In matlab/tests/testFeatureParity.m (testEveryCaseMatchesPython) at 54
```

An **empty-input shape disagreement**: `buildFeatureFrame.m` returns `[0 31]` for an empty track
list, the Python fixture expects `[0 0]`. Both are defensible; they just have to agree.
**Work out which is right and say why — do not change one side to match the other.**

**Two more things in your folder, flagged not fixed** (they are Stream C's to change):

- `/ml-parity` (both copies) and `ml/CHEATSHEET.md` give
  `runtests('matlab/tests/testFeatureParity')` **without the `.m`**, which errors. Same bug Antara
  found in `/plan-test`.
- `ml/C-prediction.md` still says "seven products" and "four defects". check01 checks **nine**
  required products.

**Still blocking Stream D:** the **ONNX opset number**. `check01` on Aditya's Mac reports
`[ MISSING ] no ONNX import` — the free *Deep Learning Toolbox Converter for ONNX Model Format*
add-on is not installed, so `check04` cannot run yet.

---

## Aditya

- **`matlab/baseline/` has never been run.** That is the single biggest gap before the 7th. E1 is
  done; E2 is not, and without it there is still no comparison and no graph.
- **The planner fence is weaker than it reads.** `.claude/fences/planner.settings.local.json` denies
  `Edit(matlab/baseline/**)` but **not `Write` or `Bash`**, so `sed`, `cp` and heredocs all bypass it.
  The baseline rule still rests on people, not tooling.
- **`derisk/check05_opentrafficlab.m` cannot answer its own question** — its example search misses
  `OpenTrafficLab/Testing/*.m` and the `.mlx`, so it prints an empty list and then says "open one of
  the above". Not Stream D's folder, so flagged not edited.
- **`ml/` and `world/` still carry the stale "seven products" / "four defects" text.** Not touched.
