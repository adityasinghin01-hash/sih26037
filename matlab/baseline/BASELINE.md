# The baseline — MathWorks' shipped planner, unmodified

**This folder is the competitor. Nobody edits anything in it. Ever.**

If we tune this planner so it performs worse, a judge calls the comparison rigged and **every
number this project produces becomes worthless.** That is the whole reason this file exists: so
anyone can verify, in one command, that we did not touch it.

---

## What it is

| | |
|---|---|
| **Example name** | Motion Planning in Urban Environments Using Dynamic Occupancy Grid Map |
| **MATLAB example ID** | `driving_fusion_nav/MotionPlanningUsingDynamicMapExample` |
| **Fetched with** | `openExample('driving_fusion_nav/MotionPlanningUsingDynamicMapExample')` |
| **MATLAB version** | 26.1.0.3346908 (R2026a) Update 5 |
| **Platform** | macOS (MACA64) |
| **Date copied in** | 4 September 2026 |
| **Licence** | 41087767 |
| **Modified?** | **No. Byte-for-byte as MathWorks shipped it.** Verified — see checksums below |

**Toolboxes it needs** — Automated Driving, Sensor Fusion and Tracking, Navigation. All three are
present on this licence (`derisk/check01_output.txt`). Note the example ID is `driving_fusion_nav`,
a *cross-product* ID: `driving/...`, `nav/...` and `fusion/...` all fail with
`MATLAB:examples:InvalidExample`, which is the trap that makes this hard to find.

---

## Why this one, and not an easier one

We picked MathWorks' **strongest** relevant planner on purpose:

- it uses **lidar** like us — six of them, fused into a dynamic occupancy grid
- it handles **pedestrians, bicyclists, cars and trucks** like us
- it targets an **urban intersection** like us
- it does **dynamic replanning** along a Frenet reference path — the same family as our D6

**It fails at an unmarked Indian junction for a structural reason, not a tuning one.** It needs a
*reference path* — a set of waypoints saying roughly where the road goes — and an unsignalled
Indian junction does not provide one. The coordinate system it thinks in does not exist there.

**That is a real finding. Tuning it to fail would not be.**

Per `plan/E-evidence.md` E8, this is baseline 1 of 3. The other two — ORCA and always-yield — are
ours to write, and they go somewhere else. **Only shipped, unmodified competitor code lives here.**

---

## The files

Seven files, exactly as `openExample` produced them.

| File | Bytes | SHA-256 |
|---|---|---|
| `MotionPlanningUsingDynamicMapExample.m` | 8378582 | `12bf1cfa7c1f2605d71ff1efb94c2bf55289db5e8098d25ca9f256767338a1b2` |
| `HelperDynamicMapValidator.m` | 20264 | `622f9731cd70fb76efc13ca2b4f6622b1af655c02cd784cada1f0c89296dd54c` |
| `helperGridPlanningDisplayPanel.m` | 16376 | `06ce6f88a78827b9d558a2365e15b5e0e3e8edba15bf50ce03f642386d5f9df3` |
| `helperGridBasedPlanningScenario.m` | 13667 | `94f3a3c3ecf02fa037572425c1244b54b4b92aabed1e1895082c995d9de13cb5` |
| `helperGridBasedPlanningDisplay.m` | 6734 | `86e03821291c67e1647c008bd837458bc5492aa677792375706dbb4aa1f8308d` |
| `helperGenerateTrajectory.m` | 2206 | `9733e4889f4a31a84cb8dde6490a8be437d3e88bb41b7426e114e642724e101e` |
| `helperAssembleTrajectoryForPlotting.m` | 695 | `69aec3817c4fb9ea305087f431eff68fd09a752079056ba3dcfe429da5cd9cee` |

### Prove we did not touch it

```bash
cd matlab/baseline && shasum -a 256 -c CHECKSUMS.txt
```

Every line must say `OK`. **Run this before quoting any comparison number**, and put the result in
the report. It is the cheapest possible answer to "how do we know you didn't nobble it?"

---

## DO NOT "CLEAN UP" THE BIG FILE

`MotionPlanningUsingDynamicMapExample.m` is **8.3 MB**, which looks absurd for a 399-line script.
It is not corrupt. It is a MATLAB live script in `.m` form, and lines **383–398** are MathWorks'
own **cached figure output** — base64 GIF and PNG images of the results, sitting inside
`%   data: {...}` comments. That is 8.35 MB of *pictures*, not algorithm.

**Stripping them would modify the file, break the checksums, and destroy the one thing this folder
is for.** Leave it exactly as it is.

---

## State — read this before quoting anything from here

| | |
|---|---|
| Copied in, unmodified, checksummed | **done, 4 September 2026** |
| Parses without error on R2026a | **done** — all 7 files, `checkcode`, 0 parse/syntax errors |
| **Actually executed** | **NO. Never run.** |
| Produces numbers we can compare against | **NO** |

**`checkcode` is not a run.** It proves the files are syntactically intact and complete, nothing
more. The example fetches scenario data and runs a six-lidar grid tracker, which will take real
time and may need a display.

**So E1 is done and E2 is not.** Until someone runs this, we still have no comparison, and the
honest statement remains: *no number this project produces is comparable to anything yet.*

### Next, in order

1. **Run it once, unmodified, and record what happens.** Full output, errors included. If it fails
   on R2026a the way OpenTrafficLab did, **that is a finding — write it down, do not fix it.**
2. Wire it into `sih.runExperiment` (E2) so it emits `metrics.json` in our format.
3. Only then compare. `results/<run>/config.json` must record this example ID and MATLAB version —
   a number without its config is not a result.

**If it errors, do not repair it.** Report it to Aditya. Editing anything here is the one action
that would invalidate the whole project's evidence.
