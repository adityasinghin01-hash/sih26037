---
description: Run the MATLAB files that have never been executed, in the right order, before trusting any of them. Do this the first time MATLAB is available on any machine.
---


# /first-run — the code that has never been run

## Read this first, and tell the person you are helping

**Most of the MATLAB in this repository has never been executed.** It was written on a Mac with
no MATLAB installed, and every function name and signature was checked against the MathWorks
documentation — but **checked-against-docs is not the same as run.** **Seven more defects were found
on 4 September 2026**, two of which stopped the simulation running at all. There are very
likely more.

**This is normal and it is not a reason to distrust the repo.** It is the reason this workflow
exists. Expect something to break. When it does, that is the workflow working.

**Say this to the person before they start**, in your own words. Somebody who thinks they are
running finished code reacts to an error very differently from somebody who was told to go
hunting for one.

---

## Order matters — do not skip ahead

Each step is cheap and each one rules out a class of problem for the next.

### 1 · Does MATLAB have what we need
```matlab
cd derisk
check01_environment
```
**Nine** `[ OK ]` lines under REQUIRED PRODUCTS. **If any says MISSING, stop** — except
`no ONNX import`, which blocks only step 3 and Stream C's handoff. Everything else can proceed.
The two free add-ons the product installer does NOT provide, both from
**Home -> Add-Ons -> Get Add-Ons**:
- **"Deep Learning Toolbox Converter for ONNX Model Format"** — step 3 fails without it
- **"Automated Visual Inspection Library for Computer Vision Toolbox"** — YOLOX training
  fails without it, and only *training*: the detector object exists either way, so the error
  arrives late and reads like a typo

### 2 · Do the two feature builders agree — 2 minutes, no data needed
```bash
python3 ml/python/tests/test_parity.py
```
```matlab
runtests('matlab/tests/testFeatureParity.m')
```
**This is the highest-value check here and the cheapest.** The model is trained by
`ml/python/meteor/features.py` and run by `matlab/+sih/+prediction/buildFeatureFrame.m`. If they
disagree, the network is fed different numbers at inference than it saw in training — **nothing
throws**, accuracy quietly collapses, and it surfaces as a planner bug days later in someone
else's code.

A failure names the feature number and both values. Feature numbers are `AGENTS.md` S2
positions: 10 is tau, 11 the lateral time-to-cross, 12-27 the class one-hot, 28-31 ego state.
**Do not "fix" one side to match the other** — work out which is right, then say which and why.

### 3 · Can our real model get into MATLAB
```bash
python3 ml/python/export/to_onnx.py --model <checkpoint.pt>
```
```matlab
cd derisk
check04_onnx_lstm
```
**Read the output for PLACEHOLDER layers, not for the word "succeeded".** An operator MATLAB
cannot convert does not throw — it arrives as a custom layer holding a function a human has to
write. A network full of placeholders imported "successfully" and is useless.

**Send Stream D the opset number the moment you have it. It is the one thing blocking them.**

### 4 · The planner tests
```matlab
runtests('matlab/tests/testPlannerGeometry.m')      % 14 - the maths and the frame contract
runtests('matlab/tests/testChooseVelocity.m')       % 19 - D2, role to command
runtests('matlab/tests/testNegotiatingStrategy.m')  %  9 - the OpenTrafficLab subclass
```
**The `.m` is not optional** — without it MATLAB reads the path as a folder and errors with
`MATLAB:unittest:TestSuite:UnrecognizedSuite`.

**42 tests, all passing on R2026a as of 4 September 2026.** These are the oldest and
best-verified code in the repo. If they fail, the problem is probably the MATLAB path — make
sure you are at the repository root.

`testNegotiatingStrategy` needs OpenTrafficLab
(`git clone https://github.com/mathworks/OpenTrafficLab.git`). Without it those 9 report
**Incomplete/skipped, never Failed**.

### 4b · Does OpenTrafficLab run at all — ANSWERED
**It does not, unmodified, on R2026a.** Stock `DrivingStrategy` dies on the first `advance()`
with `MATLAB:noSuchMethodOrField ... 'ReferencePoint'`. Both fixes and the full evidence are in
[`plan/OPENTRAFFICLAB-R2026a.md`](../../plan/OPENTRAFFICLAB-R2026a.md). This was the project's
highest-listed risk since 31 August; it is closed.

### 5 · The three model trainers — only when their data exists
These need IDD, which **requires a human signup** at `idd.insaan.iiit.ac.in/accounts/signup/`
and cannot be downloaded by a script. **Do not write a downloader.**

Before training anything, prove the file loads and its checks fire:
```matlab
help sih.models.trainSpotter
sih.models.trainSpotter("nonexistent", "/tmp/x.mat")     % must fail with a CLEAR message
```
A clear error here is a pass — it means the preflight checks work. A syntax error or an
`Undefined function` is a real defect: report it in full.

Then, with real data, follow **`/ml-models`**.

---

## What to send back

For every step: **the whole output, every line, errors especially.** Never a summary, never a
screenshot of part of it, never "it says something about a null value".

> A trimmed error message costs the team a day. It is the single most expensive habit to get
> wrong and the easiest one to fix.

## What to do when something breaks

1. **Report it in full and stop.** Do not try three fixes and report the third.
2. **Do not edit `AGENTS.md` section 3** to make an error go away. Four people build against it.
3. **Do not touch `matlab/baseline/`.** It is MathWorks' shipped planner, unmodified, and it is
   our experimental control. Editing it makes every result we have worthless.
4. If the fix is obvious and confined to one file the operator named, say what you would change
   and why, **then wait**.

## When all five pass

Say so plainly, and say which ones you actually ran versus skipped for missing data. Then the
repository has moved from *verified against documentation* to *verified by running*, and that
distinction is worth stating out loud once.
