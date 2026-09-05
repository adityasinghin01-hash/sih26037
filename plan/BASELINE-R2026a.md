# The baseline does NOT run to completion on R2026a. Finding, 4 September 2026.

**This is E2's blocking result. Read it before you quote any comparison number, and before anyone
"fixes" anything in `matlab/baseline/`.**

> ### CONFIRMED ON WINDOWS, 4 September 2026 (evening)
> Person B re-ran it on the Windows machine, with a full display, and got the **identical
> failure to the digit**: `t = 19.7000 s`, `collision-free: 0 of 120`, same line 193.
> **Apple Silicon and headless execution are both ruled out.** See "Reproduced on a second
> platform" below for what this does and does not settle.

MathWorks' shipped planner — *Motion Planning in Urban Environments Using Dynamic Occupancy Grid
Map*, the one in `matlab/baseline/`, byte-for-byte unmodified — **was run for the first time on
4 September 2026 and it failed.** It dies **19.7 simulated seconds** into its own shipped scenario,
at **its own `error()` call**, with **0 of 120 candidate trajectories collision-free**.

**Nothing was modified to produce this.** Checksums verified `OK` before and after, and the run was
executed on a byte-identical copy outside the repository so that `matlab/baseline/` was never even
the working directory.

> **This is a finding, not a bug to fix. Per `matlab/baseline/BASELINE.md` and `plan/E-evidence.md`:
> if it fails, write it down and do not repair it. Editing anything in that folder is the one action
> that invalidates every number this project will ever produce.**

---

## The error, verbatim

```
identifier: <empty>
message   : Unable to compute optimal trajectory
--- stack (top first) ---
  1) MotionPlanningUsingDynamicMapExample  (line 193)
  2) run  (line 100)   /Applications/MATLAB_R2026a.app/toolbox/matlab/lang/run.m

--- getReport ---
Error using MotionPlanningUsingDynamicMapExample (line 193)
Unable to compute optimal trajectory

Error in run (line 100)
evalin('caller', strcat(scriptStem, ';'));
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

Run three times on two platforms. Identical error, identical line, every time.

| | Run 1 (Mac) | Run 2 (Mac) | Run 3 (Windows) |
|---|---|---|---|
| Result | `ERRORED` | `ERRORED` | `ERRORED` |
| Line | 193 | 193 | 193 |
| Message | `Unable to compute optimal trajectory` | same | same |
| Platform | `MACA64` | `MACA64` | **`PCWIN64`** |
| Display | headless (`-batch`) | headless (`-batch`) | **full GUI** |
| MATLAB | 26.1.0.3346908 (R2026a) Update 5 | same | **same** |

---

## Reproduced on a second platform — and this is the part that matters

Person B ran the same seven files on the Windows machine, in the MATLAB desktop with the
figures rendering normally, from `C:\Users\...\AppData\Local\Temp\baseline-run` so the repo
folder was never the working directory.

```
MATLAB 26.1.0.3346908 (R2026a) Update 5 on PCWIN64
>>> ERRORED <<<
Error using MotionPlanningUsingDynamicMapExample (line 193)
Unable to compute optimal trajectory

Error in run (line 100)
evalin('caller', strcat(scriptStem, ';'));
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

reached t = 19.7000 s
collision-free: 0 of 120
```

**Not merely "it also failed" — it failed to the digit.**

| | Mac (`MACA64`, headless) | Windows (`PCWIN64`, GUI) |
|---|---|---|
| Failure time | `19.7000 s` | **`19.7000 s`** |
| Collision-free candidates | `0 of 120` | **`0 of 120`** |
| Ego state at failure | `[57.5349 -71.3738 ...]` | **`[57.5349, -71...]`** |
| Line | 193 | **193** |

Identical results across two different CPU architectures means **this is not floating-point
divergence** through the seeded particle filter. It is a structural property of the example.

### What this rules out, and what it does NOT

| Candidate explanation | Status |
|---|---|
| Apple Silicon / macOS numerics | **RULED OUT** — Windows x86 gives the identical number |
| Headless execution (`-batch`, no display) | **RULED OUT** — the Windows run had figures rendering |
| **R2026a itself** | **NOT ruled out.** Both machines are R2026a Update 5 |

**Be precise about that third row.** We have varied the platform and the display and held the
MATLAB version constant, so we have not tested whether an earlier release behaves differently.
Testing that needs R2024b or R2025a, which nobody on this team has installed.

**So the defensible sentence is:** *"On MATLAB R2026a Update 5 it fails identically on macOS/Apple
Silicon and on Windows x86, headless and with a display."* Not *"it fails on every MATLAB."*

### What the display showed at the failing step

The Windows run rendered the figure MathWorks intends, so we can see the state it died in: the
ground-truth view shows the ego on a straight divided road with **two vehicles abreast directly
ahead of it** and a third further up, and the predicted cost maps at ΔT = 0.1, 0.7, 1.3 and 2.0 s
show those obstacles' guaranteed-collision regions sweeping forward across the whole horizon.

That is consistent with what the numbers say — the space ahead is occupied under every prediction
step, the sampler has no stop-in-place or hard-brake behaviour in its candidate set, and so all 120
candidates die. **Stated as an observation from one rendered frame, not as a claim we have
instrumented.**

---

## The state at the moment it failed

Captured from the workspace after the error, run 2:

| | |
|---|---|
| **Simulation time** | **19.7 s** (scenario `SampleTime` 0.1 s, so **step 197**) |
| `scenario.StopTime` | `Inf` — the scenario ends when the actors finish, not on a clock |
| Ego state `[x y theta kappa v a]` | `[57.5349 -71.3738 -1.51647 -0.00143987 15.1132 0.161762]` |
| Ego speed | **15.11 m/s** against a `speedLimit` of **15** — at the limit |
| `intersectionS` | 159.6 m |

**How the 120 candidates died:**

| Filter | Survivors |
|---|---|
| Generated by `helperGenerateTrajectory` | **120** |
| Kinematically feasible | **120 of 120** — every one |
| **Collision-free** (`isTrajectoryValid`) | **0 of 120** |
| Optimal trajectory selected | **0** |

So it is not a kinematics or tuning failure. The sampler produced a full set of physically flyable
trajectories and **the collision validator rejected all of them**, at 15 m/s, and the planner had
nothing left to do.

---

## This is deterministic. It is not particle-filter luck.

The obvious objection is that the dynamic occupancy grid tracker is a particle filter, so a bad run
is just an unlucky seed. **It is not.** The example seeds itself:

```matlab
MotionPlanningUsingDynamicMapExample.m:12
rng(2020);
```

Fixed seed, set by MathWorks, inside the shipped script. Two runs produced the identical failure.
**Anyone re-running this on the same machine will get the same result.**

---

## What MathWorks' own code says about this state

Lines 185–193 of the shipped example, read but not edited:

```matlab
    % Move ego with optimal trajectory
    if ~isempty(optimalTrajectory)
        currentEgoState = optimalTrajectory.Trajectory(2,:);
        helperMoveEgoVehicleToState(egoVehicle, currentEgoState);
    else
        % All trajectories either violated kinematic feasibility
        % constraints or resulted in a collision. More behaviors on
        % trajectory sampling may be needed.
        error('Unable to compute optimal trajectory');
    end
```

**Their own comment names the gap: *"More behaviors on trajectory sampling may be needed."***

And their own narrative text, line 198, says the opposite of what happened here:

> *"Notice that the ego vehicle successfully reached its desired destination and maneuvered around
> different dynamic objects, whenever necessary."*

---

## What we may claim, and what we may NOT claim

**Be strict about this line. The finding is strong enough that overstating it is the only way to
lose it.**

### Claim A — safe, platform-independent, and it is the one that matters

> **When every candidate trajectory is invalid, the shipped planner has no defined behaviour. It
> raises an error and the simulation stops.**

This is provable from their source, in one screenshot, on any machine. It does not depend on our
run at all. There is no fallback, no emergency-brake candidate, no stop-in-place branch — the
`else` is an `error()`.

### Claim B — true of this machine, and honestly bounded

> **Run unmodified on MATLAB R2026a Update 5, macOS Apple Silicon, headless, it reaches that state
> at t = 19.7 s in its own shipped urban-intersection scenario, with 0 of 120 candidates
> collision-free.**

### Claim C — still DO NOT MAKE IT

> ~~"MathWorks' planner crashes / is broken."~~

Two platforms is not every platform, and both were **R2026a Update 5**. A regression introduced in
R2026a remains a live explanation and we have not tested an earlier release. Say what we measured.

**The Windows experiment is done and it came back positive** — that was the cheapest high-value
test left and it is now spent. The remaining unknown (older MATLAB releases) is not worth buying
before the 7th.

---

## Why this matters more than "a baseline that errors"

**Careful — this is a DESIGN contrast, not yet a MEASURED one.** Our contingency planner does not
exist yet. State it as design, or a judge will take it apart.

`plan/D6-TRUNK-RULING.md` requires that the trunk end in a state from which **braking to a full stop
is collision-free under both futures**. That terminal constraint exists precisely so that *a safe
continuation always exists* — recursive feasibility with respect to the stop fallback.

The shipped planner checks that a path is clear. It does not check that the path leaves it anywhere
it can still stop — `HelperDynamicMapValidator.m` does per-point collision checking over a 2 s
horizon, with no terminal set. That is definition **(a)** in the D6 ruling.

**And at t = 19.7 s, doing 15 m/s, it arrived exactly where (a) permits you to arrive: a state with
no valid continuation.** The D6 ruling predicted this failure mode in the abstract — *"the planner
can commit, irrevocably, to a trajectory that has already lost"* — before anyone ran the baseline.
The competitor's own shipped code then demonstrated it.

**That is the strongest single argument this project has, and it cost one run.** It also means the
D6 terminal check is not a nice-to-have optimisation to be dropped when the demo is assembled.

---

## What this does to Stream E — say it out loud today

| | |
|---|---|
| E1 — baseline copied in, unmodified, checksummed | **done** |
| **E2 — run it and get comparable numbers** | **BLOCKED. It does not complete on this machine.** |
| E3 — the ten measurements M1–M10 from the baseline | blocked by E2 |
| E4 — the three graphs | blocked by E3 |

**The honest sentence has changed but has not improved:** it is no longer *"nobody has run the
baseline"*, it is *"the baseline has been run and it does not finish."* We still have **no
comparison**. Any deck claiming a head-to-head number before this is resolved is claiming something
untrue.

**Three routes out, in order of preference. This is Aditya's call, not a stream's.**

1. ~~**Run it on Windows** (Person B).~~ **DONE 4 Sep evening. It fails there too, identically.**
   This route is closed — the problem did not dissolve.
2. **Report the baseline's failure as the result.** ***This is now the route.*** It requires no edit
   to their folder and it is the honest description of what we measured. `config.json` must record
   the example ID, both MATLAB versions and platforms, and that the run was truncated by their own
   error at 19.7 s.
3. **Change the baseline so it survives.** ***No.*** This is the strawman that kills every number we
   have. Not available at any price.

### The consequence nobody should discover on stage

Route 2 gives us a **finding about the competitor**. It does **not** give us a head-to-head number,
because the two planners do not run the same scenario: the baseline runs MathWorks' six-lidar urban
intersection, ours runs the OpenTrafficLab T-junction. Putting both on one scenario is E2's real
content and it is not happening before the 7th.

**So the honest position for the internal round is:**

> We ran the shipped state of the art, unmodified, on two machines. It fails, and we can show
> exactly why from their own source. Here is our planner running with `h` logged every step. We do
> **not** yet have both planners on a common scenario — that is the next piece of work.

Say the last sentence out loud before a judge says it for us.

---

## Reproducing it

Copy the folder out and run the copy, so the original is never the working directory:

```bash
cd ~/dev/sih2026/matlab/baseline && shasum -a 256 -c CHECKSUMS.txt   # every line must say OK
mkdir -p /tmp/baseline-run && cp ~/dev/sih2026/matlab/baseline/*.m /tmp/baseline-run/
```

```matlab
cd /tmp/baseline-run
addpath('/tmp/baseline-run')
try
    run('/tmp/baseline-run/MotionPlanningUsingDynamicMapExample.m')
catch ME
    disp(getReport(ME,'extended','hyperlinks','off'))
    fprintf('failed at t = %.4f s\n', scenario.SimulationTime);
    fprintf('collision-free: %d of %d\n', nnz(isCollisionFree), numel(isCollisionFree));
end
```

Takes 2–5 minutes and spawns figure windows even under `-batch`.

**Report the whole error, first line to last. Do not repair anything.**

---

## Status

Run and recorded by Claude at Aditya's instruction, 4 September 2026, on
MATLAB `26.1.0.3346908 (R2026a) Update 5`, `MACA64`, headless.
Independently reproduced by Person B the same evening on `PCWIN64` with a full display, same
MATLAB version, identical result.
`matlab/baseline/` was not modified — checksums verified `OK` before and after, and both runs used
copies outside the repository.

**`matlab/baseline/BASELINE.md` still says "Actually executed: NO. Never run." That is now false.
It was deliberately left untouched, because the rule on that folder is absolute and does not get
lawyered. Correcting it is Aditya's call.**
