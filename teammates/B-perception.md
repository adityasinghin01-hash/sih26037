# Stream B · Perception

**You own turning sensor data into a TrackList.** Everything downstream consumes your output, so
`docs/INTERFACES.md` S1 is your contract. Meet it exactly and nobody ever has to talk to you.

## The decisive constraint, already settled
In-loop perception is **lidar, not camera**. The cuboid environment emits point clouds, not
pixels — `visionDetectionGenerator` gives object lists, which a detector cannot consume.

And a measured reason it is the right call: at the real dashcam spec (1920x1080, 140 deg FOV),
**a full-size cow at 9.2 m is only 77 x 63 pixels** — 3.98% of frame width. By 25 m it is below
what most detectors handle. Research section 17.

## Your job, in order

### B1 — Lidar to point cloud
`lidarPointCloudGenerator`, wired into the scenario Stream A builds. `derisk/check02_lidar_cow.m`
already shows the exact calling convention — copy it.

### B2 — Tracking, and use the good tracker
**`trackerGridRFS`** — the same one MathWorks' own planner uses — or a PHD extended-object
tracker. Both are on our licence via Sensor Fusion and Tracking Toolbox.

Why extended-object tracking specifically: it estimates an object's **spatial extent**, not just
a point. That is built for our hardest case — a bus and a scooter sharing the same lateral space,
with many returns belonging to one large body.

### B3 — Emit TrackList
`matlab/+sih/+perception/buildTrackList.m`. Four guarantees you must uphold (S1):
1. Sorted by ascending `TrackID`
2. Never contains the ego
3. **May be empty** — and downstream must not error. Test this case explicitly
4. No `NaN`, no `Inf` in `Position`. Drop the track instead

### B3b — Radar, fused with lidar
`drivingRadarDataGenerator`. The problem statement names **"camera, LiDAR, and radar"** and radar
was missing from our first design — an unforced gap against a stated requirement.

Radar earns its place beyond compliance: it gives **direct range-rate** (closing speed measured,
not differentiated) and it **degrades differently from lidar** in dust and rain. That makes the M3
sweep richer — you can knock out one modality at a time using the `SensorMask` field in S1.

Fuse before emitting TrackList. Nothing downstream should know which sensor saw what.

### B4 — Noise injection, for the curve nobody publishes
`matlab/+sih/+perception/injectNoise.m`. Three independent knobs, each sweepable:
position error sigma, dropout probability, false-positive rate.

This feeds **M3, the perception-degradation curve**. B-GAP admits it needs "very good sensing";
GameOpt runs with no sensors at all. **Nobody publishes this curve.** It is one of our three
headline results and it is entirely yours.

### B5 — Camera detector, offline only
YOLOX, MATLAB's built-in. Trained on IDD, benchmarked on real Indian video. **Do not import
YOLO from ONNX** — NMS is unsupported, dynamic shapes fail. This never enters the loop; it is
an offline benchmark we report separately.

---

## What you use

| | |
|---|---|
| **Stack** | MATLAB + Simulink (Automated Driving, Sensor Fusion & Tracking, Lidar, Computer Vision) |
| **Machine** | Windows |
| **IDE / agent** | Antigravity |
| **Key functions & tools** | `lidarPointCloudGenerator` · `drivingRadarDataGenerator` · `trackerGridRFS` · YOLOX (built-in) |

**Setup:** `docs/SETUP.md` — 20 minutes.
**Before you write any code:** read `docs/INTERFACES.md`. It is frozen; five other people build
against it. If your agent proposes editing it, the answer is no.

**Reference docs you will need:**
`docs/PRD.md` (the whole idea) · `docs/ROADMAP.md` (phases and gates) ·
`docs/metrics.md` (M1–M10) · `docs/CLAIM-LEDGER.md` (never state a number that is not in it)
