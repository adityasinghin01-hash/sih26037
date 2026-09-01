---
description: Train the three MATLAB-native perception models - YOLOX spotter, DeepLab v3+ road segmenter, PointPillars lidar detector. Models 3, 4 and 5 of 5.
---

**The person you are helping has `ml/ReadThis.md`** — the plain-language roadmap for this
stream. Point them at it rather than re-explaining. `ml/TROUBLESHOOTING.md` has every error we
have already hit, with its real cause.

## Stay inside the ML stream

| Yours | NOT yours — say so in one sentence and stop |
|---|---|
| `ml/` and everything in it | `matlab/+sih/+planner/` and the Simulink model — Stream D |
| `matlab/+sih/+prediction/` — the feature twin | `plan/` and `plan/CONTRACT-AB.md` — Stream D's roadmap |
| `matlab/+sih/+models/` | `matlab/+sih/+scenario/`, `+perception/` — Streams A and B |
| `ml/python/tests/` | `matlab/baseline/` — the competitor. **Never** |

**You produce `S3 PYield`. You never consume it.** The planner reads it through the contract and
never opens your model; you never open theirs. If the planner looks like it is misusing your
output, that is a message to a human — **not** a reason to go and read `matlab/+sih/+planner/`.

Reading across that line is how two people end up with two versions of the same thing, and nobody
knows which one the demo used.

# /ml-models — the three models that live in MATLAB

`/ml-run` covers models 1 and 2, the yield predictor, in Python. **These three are trained
natively in MATLAB and never touch ONNX**, which is the whole reason they were chosen: an
imported YOLO fails on NMS and dynamic shapes, and RTMDet is inference-only here.

**Read `ML.md` first.** Section 0 applies: do the step you were asked for, and stop at anything
a human must decide.

---

## Before anything: what must already be installed

| Model | Needs |
|---|---|
| all three | MATLAB, Deep Learning Toolbox, Computer Vision Toolbox |
| **3 · YOLOX** | **the "Automated Visual Inspection Library for Computer Vision Toolbox" add-on** |
| 5 · PointPillars | Lidar Toolbox |

**The YOLOX add-on is the one that catches people out.** It is NOT installed by the product
installer. `yoloxObjectDetector` exists without it and only *training* is missing, so the error
arrives late and reads like a typo. Get it from **Home -> Add-Ons -> Get Add-Ons**, search that
exact name. It is free.

**The data cannot be downloaded by a script.** IDD requires a signup at
`idd.insaan.iiit.ac.in/accounts/signup/` and a human accepting terms. If the folder is not there,
**stop and say so** - do not write a downloader.

---

## Model 3 — the spotter (YOLOX on IDD Detection)

```matlab
detector = sih.models.trainSpotter("<idd-detection-root>", "<somewhere-outside-the-repo>/spotter.mat");
```

Expects `JPEGImages/` and `Annotations/` (Pascal VOC XML) under the root.

**Report average precision PER CLASS, and specifically cow, auto-rickshaw and pushcart.**
`AGENTS.md` requires those three by name. A high overall mAP carried by cars while the cow class
is empty is precisely the result this model exists to rule out - reporting mAP alone hides it.

**Watch the dropped-class list it prints.** IDD's vocabulary is not ours: it writes
`autorickshaw`, we use `auto-rickshaw` (S5 ClassID 4). Unmapped names are dropped rather than
guessed, and the counts are printed. **A large drop count means the alias table in
`readDetectionData.m` needs extending** - say which names and how many, and wait.

---

## Model 4 — the road segmenter (DeepLab v3+ on IDD Segmentation)

```matlab
net = sih.models.trainRoadSegmenter("<idd-segmentation-root>", "<outside-repo>/road.mat");
```

Expects `leftImg8bit/` and `gtFine/`.

**`deeplabv3plusLayers` has been REMOVED.** If you find it in an older example, do not use it.
The current pair is `deeplabv3plus` + `trainnet` - not `trainNetwork`.

**Report the DRIVABLE class IoU, not global accuracy.** Background is most of every image, so
global accuracy stays high while the road class is wrong.

---

## Model 5 — the lidar detector (PointPillars)

```matlab
detector = sih.models.trainLidarDetector(dsTrain, "<outside-repo>/lidar.mat");
```

`dsTrain` must return **three** columns: a `pointCloud`, an **M-by-9** box matrix
`[x y z length width height roll pitch yaw]`, and categorical labels. Build it with
`lidarObjectDetectorTrainingData`. **A 4-column box table is a 2-D image box and will fail.**

**This is the only learned perception model that could ever run in the loop**, because the cuboid
simulator produces real point clouds through `lidarPointCloudGenerator` while it produces no
pixels at all.

**Then do the thing that is actually worth doing:** run the trained detector on a point cloud from
our own scenario. If it detects there too, the simulated lidar is realistic enough to trust. If
it does not, that is a finding about the simulator and a more interesting one than the detector's
own score. Report it either way.

---

## Rules that apply to all three

- **Never save a `.mat` inside the repository.** `AGENTS.md` section 6 forbids committing model
  files and `.gitignore` blocks them.
- **Never renumber S5.** All three take their class list from `sih.util.classNames`, so the
  ordering matches features 12-27. A detector with its own ordering produces a feature vector
  the planner misreads with no error.
- **All three run OFFLINE.** Models 3 and 4 can never enter the driving loop - there are no
  pixels in the cuboid simulator. Do not wire them into the planner.
- **These are not on the critical path.** Model 1, the yield predictor, is what the headline
  claim needs. If time is short, say so rather than finishing these first.

Finish with the section 7 report from `ML.md`.
