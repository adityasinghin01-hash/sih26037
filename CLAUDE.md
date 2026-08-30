# SIH26037 — project brief

**Smart India Hackathon 2026, problem statement SIH26037 (MathWorks, theme Smart Vehicles):
Adaptive Path Planning and Collision Avoidance for Autonomous Vehicles on Unstructured Indian
Roads.** The problem statement is LOCKED. Seven phases of research are complete. Do not
re-litigate either.

## Read these first, in this order
1. `ps-deepdive/THE-IDEA.md` — the locked design
2. `ps-deepdive/research/PHASE-4-MERGED.md` — the architecture and its hard constraints
3. `ps-deepdive/research/PHASE-3-MERGED.md` — why the incumbents do not cover us
4. `ps-deepdive/SIH26037-official-text.md` — what MathWorks literally asked for

Detailed memory also lives at `~/.claude/projects/-Users-aditya-dev-sih2026/memory/`.

## The idea, in one line
> An Indian junction has no controller. We built the planner that negotiates instead of
> waiting — in MATLAB, where no one has built one, against a cow that behaves like a cow.

## Settled decisions — do not reopen
- **No RoadRunner.** Build everything with the `drivingScenario` API. This is a net positive:
  RoadRunner is a GUI tool that cannot be scripted.
- **In-loop perception is LIDAR, not camera.** The cuboid environment emits point clouds, not
  pixels. Camera perception is trained on IDD and benchmarked offline on real video.
- **The prediction model is an LSTM.** GNNs cannot be imported into MATLAB (Gather/Scatter
  unsupported); transformers import only partially. LSTM/GRU import cleanly.
- **Do not import YOLO.** Use MATLAB's built-in YOLOX.
- **Foundation is `mathworks/OpenTrafficLab`.** Subclass `DrivingStrategy`; delete
  `TrafficController` and replace it with COLREGs-style role negotiation.
- **Dataset is METEOR**, not IDD-X. IDD-X labels why the ego acted, which is the wrong direction.
- **Two scenarios perfect** for 7 Sept — the unsignalled junction and the cattle crossing.

## Working rules
- **Aditya does not write MATLAB.** You write every script; the team runs it and reports back.
  Assume zero MATLAB experience on the team.
- **Errors come back in full.** Never work from a summary of an error.
- **Verify, do not assume.** Before writing any number into a document, run the thing that
  produces it. This project's whole pitch is that its claims are checkable.
- **The baseline must be MathWorks' shipped planner, completely unmodified.** Record its exact
  example name and version in `docs/baseline.md`. A tuned baseline is a strawman and kills the
  result.
- **Novelty phrasing is always "no public work we could find"** — never "this has never been done."
- **Borrow freely, cite loudly.** Name the closest competitor and the closest patent ourselves.
- **Nothing ships with a bug already reproduced in the demo flow.** A previous hackathon was
  lost exactly that way.

## Communication style
Short, plain, precise. Lead with the result, put the number first, prefer tables to prose.
Define jargon before using it. No deadline framing. One recommendation, not a menu of options.

## The first task is de-risking, not building
Before any project code, prove the pipeline runs. In order:
1. MATLAB launches; record the **exact release** (decides ONNX opset support).
2. **THE CRITICAL ONE:** an unmarked road + a custom cow mesh + a non-empty lidar point cloud
   with returns off the cow. Everything rests on this.
3. A toy LSTM: PyTorch → ONNX → `importNetworkFromONNX` → Simulink Predict block.
4. `mathworks/OpenTrafficLab` clones and its examples run unmodified.
5. Supercomputer (NVIDIA DGX A100, 8x40GB): free disk, internet on the node, booking process.
   Then start the METEOR download — 93.4 GB, and its official page is already dead, so the
   HuggingFace mirror is the only route.

If check 2 fails, fall back to object lists for the in-loop planner and keep the trained
detector as an offline benchmark. The project still works.

## Two upgrade tracks — parallel only, never the critical path
Full detail in `~/.claude/projects/-Users-aditya-dev-sih2026/memory/sih26037-upgrade-tracks.md`.

1. **GNN instead of LSTM.** Possible after all: cap the agent count and write message passing as
   a **dense adjacency-matrix multiply**, which avoids the unsupported Gather/Scatter entirely.
   **From day one, make the data pipeline emit an adjacency matrix even though the LSTM ignores
   it** — that makes the swap a ~60-line change. Better still, train both at once on the eight
   GPUs and report the comparison as an ablation.
2. **A hand-built Unreal scene.** Free Unreal Editor plus the free "Automated Driving Toolbox
   Interface for Unreal Engine Projects" package lets us import Indian meshes and get photoreal
   camera images from our own scene. Windows/Linux only, and **the Unreal version must match the
   MATLAB release exactly**. Do not build a city — take `Empty Grass`, add a road texture, three
   Indian meshes and a cow. One person, one to two days.

Ship the working version first. Take these only if ahead of schedule.

## Positioning — how we describe this project
**Not** "a self-driving car for Indian roads" (years away, and India legally requires a driver
in effective control). **Instead:** *"the missing test suite for ADAS on Indian roads — released
open, with a planner that proves it works."*

India is mandating ADAS now. Every such system is currently validated against Western
scenarios, and METEOR's authors measured that models working on Waymo data fail on Indian data.
Our users are **ARAI and ICAT** (who homologate every vehicle sold in India) and validation
teams at Bosch India, Continental, Tata Elxsi, KPIT.

**Consequence: release the work publicly** — scenarios, metrics, baseline, results. A benchmark
is a citable contribution; a private demo is not. Costs nothing, and it is what raises novelty.

Detail in `memory/sih26037-positioning.md`. **REGULATORY CLAIM CORRECTED 30 Aug 2026.** AIS-189/190 are cybersecurity and
software-update standards, **not** ADAS. The real ADAS mandate is **MoRTH GSR 184(E)**,
in force **1 Apr 2026** for buses and trucks (AIS-162/184/186/187/188).
See `docs/CLAIM-LEDGER.md` section C.
