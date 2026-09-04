# HANDOFF — 4 September 2026  *(updated later the same day: the baseline has now been RUN)*

**If you are an AI assistant: read this file at the start of the session and tell your human what
is in their section, in plain words, before you do anything else.** It is short on purpose.

Everything below was **verified by running MATLAB R2026a**. Where something was not run, it says so.

---

## Everyone, in thirty seconds

| | |
|---|---|
| **THE MAIN MACHINE IS ADITYA'S MAC** | Decided 4 Sep by running every piece on it: the planner (**212/213 tests**), the Simulink model (**loads, simulates, logs `h`**), OpenTrafficLab (**9/9**) and the baseline all run there. **The demo runs on the Mac.** You still develop on your own machine — see `TEAM.md`, "The main machine". Write nothing Windows-only: no `C:\` paths |
| **`runtests` needs the `.m`** | `runtests('matlab/tests/testPlannerGeometry.m')`. Without it MATLAB errors `MATLAB:unittest:TestSuite:UnrecognizedSuite`. It is not a broken test |
| **Test counts, re-run on R2026a 4 Sep** | The repo has **51 tests in 5 files: 50 pass, 1 fails.** geometry **14** · chooseVelocity **19** · NegotiatingStrategy **9** · ClassIDMapping **6** · FeatureParity **2 of 3**. The old "42 passing" line counted only three of the five files — **do not put 42 in a deck** |
| **OpenTrafficLab does NOT run unmodified on R2026a** | Read `plan/OPENTRAFFICLAB-R2026a.md` before debugging any harness failure. **Never edit `OpenTrafficLab/`** |
| **`matlab/baseline/` is now FULL** | MathWorks' shipped planner, unmodified and checksummed. **Nobody edits it.** See `matlab/baseline/BASELINE.md` |
| **THE BASELINE HAS BEEN RUN — AND IT FAILS ON BOTH PLATFORMS** | It dies **19.7 s** into its own shipped scenario at **its own `error()`**, with **0 of 120 candidates collision-free**. Deterministic (`rng(2020)`). Reproduced **three times on two machines** — macOS/Apple Silicon headless and **Windows x86 with a full display — identical to the digit**. **`plan/BASELINE-R2026a.md`. Read it before quoting any comparison number, and do NOT fix it** |
| **ONNX import is confirmed absent** | Verified live on the Mac: `importNetworkFromONNX`, `importONNXNetwork`, `importONNXLayers` and `exportONNXNetwork` **all four NOT FOUND**. 9/9 required products ARE present. Only the free converter add-on is missing |
| **The one failing test is Stream C's** | `testFeatureParity/testEveryCaseMatchesPython`. Everything else passes |
| **Two rulings landed 4 Sep** | `plan/D6-TRUNK-RULING.md` (what the trunk is) and `plan/S3-PYIELD-RULING.md` (what `PYield` means). Read the one for your stream |

---

## Stream D, Person A (`matlab/+sih/+planner/*.m`)

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

### Arbitration is ruled, and it was never written down — `plan/ARBITRATION-RULING.md`

You asked whether `arbitrate` should take the role list plus positions (your Option 1) or the ego
and tracks (Option 2). **Neither. It takes the role list and nothing else.**

`assignRoles` already builds a full `vo` for every track at line 64 and throws it away. Return it:

```matlab
[roles, vos] = sih.planner.assignRoles(egoPos, egoVel, egoYaw, tracks);   % vos is NEW
[winner, k]  = sih.planner.arbitrate(roles);
cmd          = sih.planner.chooseVelocity(winner, vos(k), egoState);
```

**No positions in, so no frame to get wrong** — Option 1's silent-wrong-answer trap is not guarded
against, it is made unrepresentable. Nothing recomputed, so Option 2's duplication is gone too.
Adding an output is backward compatible; existing callers are untouched.

Winner is the **smallest `h = Lambda - Beta`** — tightest, not nearest. Ties: lowest `TrackID`.
Empty tracks: no winner, `h = NaN`. It must **not** read `PYield` and must **not** choose between
`h_agent` and `h_road`. Reasons in the file.

**You have already written the hard part**: `minBarrierFromRoles()` at line 141 is exactly this,
minus the index.

**And you were right that it was nowhere.** The word "arbitration" appeared in no file in this repo.
That is fixed.

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
| **Actually executed** | **DONE 4 Sep — and it FAILED** |
| **Produces numbers we can compare against** | **NO. It does not reach the end of its own scenario** |

### It has been run. It does not complete. Full finding: `plan/BASELINE-R2026a.md`

It errors at **t = 19.7 s** of its own shipped urban-intersection scenario:

```
Error using MotionPlanningUsingDynamicMapExample (line 193)
Unable to compute optimal trajectory
```

**120 candidates generated, 120 kinematically feasible, 0 collision-free.** That is MathWorks' own
`error()` call, under their own comment *"More behaviors on trajectory sampling may be needed."*
The example seeds itself with `rng(2020)`, so this is **deterministic, not an unlucky particle
filter** — it reproduced identically on a second run.

**Nothing was modified.** Checksums verified `OK` before and after; the run used a byte-identical
copy outside the repo so `matlab/baseline/` was never the working directory.

**So the honest sentence has changed but not improved:** it is no longer *"nobody has run the
baseline"*, it is *"the baseline has been run and it does not finish."* **We still have no
comparison.** E2, E3 and E4 are all blocked behind this, and it is Aditya's call which way out we
take — the three options are in `plan/BASELINE-R2026a.md`.

**Do NOT make it survive.** Tuning the baseline until it completes is the strawman that destroys
every number this project produces. The failure IS the result.

### CONFIRMED ON WINDOWS the same evening — Apple Silicon and headless are ruled out

Person B re-ran the identical seven files on the Windows machine, in the MATLAB desktop with
figures rendering, and got the same failure **to the digit**:

```
MATLAB 26.1.0.3346908 (R2026a) Update 5 on PCWIN64
reached t = 19.7000 s
collision-free: 0 of 120
```

Same `t = 19.7000 s`, same `0 of 120`, same ego state `[57.5349 -71...]`, same line 193. Identical
numbers across two CPU architectures means this is **not** floating-point divergence — it is
structural.

**Still NOT ruled out: R2026a itself.** Both machines are R2026a Update 5, so we varied the platform
and the display but held the version constant. The defensible sentence is *"it fails identically on
macOS/Apple Silicon and Windows x86 under R2026a Update 5"* — **not** *"it fails on every MATLAB."*

### What this means for the comparison, said plainly

Route 2 is now the route: **report the baseline's failure as the result.** But that gives a finding
about the competitor, **not a head-to-head number** — the two planners do not run the same scenario
(theirs: MathWorks' six-lidar urban intersection; ours: the OpenTrafficLab T-junction). Putting both
on one scenario is E2's real content and it is not happening before the 7th. **Say that before a
judge says it for us.**

Then E2 (`runExperiment`), then E3. **Do not edit anything in `matlab/baseline/`, ever** — verify it
instead:

```bash
cd matlab/baseline && shasum -a 256 -c CHECKSUMS.txt      # every line must say OK
```

---

## Stream C — ML

**Both predictor models are trained and honestly measured. Good work.** Three things are settled
below, and **one of them stops you before ONNX export.**

Full ruling with the reasoning: **`plan/S3-PYIELD-RULING.md`**. Read it before you export anything.

### 1. Hurdle 5 is a torch VERSION problem. Do not edit `to_onnx.py`.

**Verified by running it here on 4 Sep 2026, torch 2.13.0, untrained weights** (shapes and
operators are real, which is exactly what this question is about):

```
yield_lstm: exported opsets [17, 18, 20]      forbidden ops: NONE
yield_gnn : exported opsets [17, 18, 20]      forbidden ops: NONE
numerics vs PyTorch: max abs diff 1.19e-07 (lstm) / 4.17e-07 (gnn)
```

`dynamo=True` succeeded on all six. **No `Gather`, no `Scatter`, nothing from `FORBIDDEN`.**
Shapes match the contract: `sequence [batch,20,31] -> yield_logits [1,2]`, and
`sequence [batch,16,20,31] + adjacency [batch,16,16] -> yield_logits [batch,16,2]`, `A = 16`.

So both failure paths you hit are artefacts of the torch on your laptop:
`aten.mkldnn_rnn_layer.default` under `dynamo=True` is a CPU decomposition gap that later torch
fixed, and the `Shape -> Gather` under `dynamo=False` is the TorchScript exporter, which newer
dynamo does not emit.

**Do this instead of changing code:**
1. `python3 -c "import torch; print(torch.__version__)"` — **your PROGRESS.md contradicts itself,
   H1 says 2.14.0 and H5 says 2.4.1. Settle which is real and write it down.**
2. Upgrade torch, re-run `to_onnx.py` unchanged.
3. **Do NOT relax `FORBIDDEN` in `to_onnx.py`.** Option A from your write-up risks MATLAB emitting a
   placeholder custom layer, and `/first-run` warns about exactly that: *read the output for
   PLACEHOLDER layers, not for the word "succeeded"*.

Operators outside MATLAB's built-in list, which become custom layers: LSTM has `Expand, Shape,
Slice, Transpose, Unsqueeze`; the GNN adds `Erf, Squeeze` at opsets 17/18 but **not at 20**, so
opset 20 is the cleanest candidate. `check04` is what settles whether they auto-generate.

### 2. The model is NOT allowed to say GO yet

Your own evaluation prints **Check 4 & 5 = FAIL**. Dangerous error rate **20.18%** against a
**≤1.0%** target — twenty times over. At threshold 0.99 it says GO 1,630 times out of 783,928, so
it is already maximally conservative and still wrong 1 in 5 times it commits.

Your "Immediate Next Steps" goes straight to ONNX export. **That would ship a model that failed its
own gate.** Three of our previous entries died that way.

**Ruling: emit `Valid = false` wherever the model cannot meet the ≤1% bar**, and let the planner
fall back to the geometric role — which S3 already mandates. Record the threshold and the measured
rate in `results/<run>/config.json`. That is a better thing to present than a hidden 20%.

### 3. `PYield` must carry `1 - P(assert)`

You trained on `assert`. The contract field is `PYield` and D6 weights its two futures by it. Since
**not asserting is not the same as yielding**, this is not a free `1-p` flip and it has to be
written down or the planner weights its branches backwards, silently.

**Ruling: `PYield = 1 - P(assert)` — the probability the other road user does NOT take the gap.**
Convert once, at the S3 boundary, on the MATLAB side. **The `.onnx` output tensor stays
`yield_logits`** — that file format is frozen in section 3.

Full reasoning, including why an optimistic `PYield` is not a safety hole: `plan/S3-PYIELD-RULING.md`.

### 4. `check04` is blocked, and it is blocking the planner

`importNetworkFromONNX` **does not exist on Aditya's Mac** — confirmed 4 Sep. The free
**"Deep Learning Toolbox Converter for ONNX Model Format"** add-on is not installed, and the product
installer does not include it. **Home -> Add-Ons -> Get Add-Ons.**

**Do you have MATLAB installed at all?** Nothing in PROGRESS.md says so. You need MATLAB *plus* that
add-on before `check04` can run — and the opset number it produces is the one thing blocking Stream D.

### 5. Models 3, 4 and 5 belong to the CITY, not to the 7th

**Recorded 4 Sep 2026 — this dependency was nowhere in the repo and it decides what you start.**

The World is being built in two versions: **the city** (the full rendered world) and **the backup**
(the cuboid fallback). They are separate efforts in separate sessions.

| Model | Needs | Verdict |
|---|---|---|
| **3 — Spotter (YOLOX)** | camera pixels | **CITY ONLY.** `AGENTS.md` line 36: *"camera offline. The cuboid environment emits object lists, not pixels."* No city, no pixels, no spotter |
| **4 — Road-Finder (DeepLab v3+)** | camera pixels | **CITY ONLY**, same reason |
| **5 — Laser Spotter (PointPillars)** | lidar returns | **Less dependent.** Lidar works in the cuboid world — `check02` put 429 points on a cow mesh. Could run either way |

**Consequences for Stream C:**

- **None of 3, 4, 5 is needed for the internal round on the 7th.** Model 1 alone carries it.
- **They are not cancelled.** They are the real project, and the KIET GPU cluster can train them.
  Keep going — just never at the cost of Model 1's opset number, which blocks two other people.
- **Do NOT start the IDD download or signup until the city decision is made.** 25 GB and a human
  terms acceptance, and it is wasted entirely if we fall back to the backup world.

### 6. For the claim ledger, before a judge asks

Your dead-feature finding is correct and it is a real limitation. Features `[23,24,25,27]` map to
S5 ClassID 11, 12, 13, 15 via `feature = 12 + ClassID` — **dog, pushcart, animal-drawn cart, static
obstacle**. METEOR contains none of them.

**Two of those, pushcart and animal-drawn cart, are classes this project specifically brags about.**
Cows and tractors *are* present. Get the honest sentence ready now rather than discovering it on
stage.

### 7. Fixed for you in the repo

- `.gitignore` had **no `*.npz` rule** — your own rule 2 says feature arrays never get committed and
  nothing enforced it. Added.
- `/ml-parity` (both copies) and `ml/CHEATSHEET.md` gave `runtests('matlab/tests/testFeatureParity')`
  **without the `.m`**, which errors with `MATLAB:unittest:TestSuite:UnrecognizedSuite`. Fixed.
- `ml/C-prediction.md` said "four real defects" and "four other people". Corrected.

### 8. Still yours to resolve

`testFeatureParity/testEveryCaseMatchesPython` fails on `main`:

```
case "empty": Data is [0 31], Python produced [0 0]
```

An empty-input shape disagreement between `buildFeatureFrame.m` and `features.py`. Both are
defensible; they just have to agree. **Work out which is right and say why — do not change one side
to match the other.**

## Aditya

- **`matlab/baseline/` has been run on BOTH machines and fails identically at 19.7 s** —
  `plan/BASELINE-R2026a.md`. Person B's Windows run closed the platform question the same evening.
  E1 is done; **E2 is blocked, not merely unstarted.** Route 2 (report the failure as the result) is
  now the only honest route, and it yields a finding about the competitor rather than a head-to-head
  number — the two planners do not share a scenario.
- **Nobody on your roster is Stream E.** `TEAM.md`'s by-name table gives the baseline to Planner B;
  its blocker table gives it to "Stream E"; `plan/ReadThis.md` §2 lists `matlab/baseline/` as
  **not** Planner B's; and `plan/E-evidence.md` describes Stream E as a separate person with their
  own Windows machine and `stream-e-evidence` branch. You have four people and none of them is that
  person. **The biggest gap before the 7th is assigned to nobody.**
- **The ONNX converter add-on is a five-minute job only you can do**, and it is what blocks
  `check04` -> the opset number -> Person A wiring the predictor.
  **Home -> Add-Ons -> Get Add-Ons -> "Deep Learning Toolbox Converter for ONNX Model Format".**
- **The planner fence is weaker than it reads.** `.claude/fences/planner.settings.local.json` denies
  `Edit(matlab/baseline/**)` but **not `Write` or `Bash`**, so `sed`, `cp` and heredocs all bypass it.
  The baseline rule still rests on people, not tooling.
- **`derisk/check05_opentrafficlab.m` cannot answer its own question** — its example search misses
  `OpenTrafficLab/Testing/*.m` and the `.mlx`, so it prints an empty list and then says "open one of
  the above". Not Stream D's folder, so flagged not edited.
- **`ml/` and `world/` still carry the stale "seven products" / "four defects" text.** Not touched.
