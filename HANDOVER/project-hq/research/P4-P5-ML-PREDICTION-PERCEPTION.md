# P4 + P5 — Prediction ML and Perception ML

Status: FINAL, 26 Sep 2026. Built by Codex (session B, gpt-6-sol) and verified by Claude.
- Claude spot-checked: QCNet repo (the ~160 GB training-memory figure is confirmed in its README),
  IDD-PeD repo, NVIDIA's reachable-set monitor page, the Parallel ModeSeq report, SMART, SkyEye,
  multi-agent conformal reachability (2304.00432), neurad-studio, and the Chennai SPT data site.
- **Effort/risk ratings are estimates.**

## Headline decisions
1. **P4, prediction:**
   - **Stop predicting "will they yield (GO)".** Predict **top-K metric future trajectories /
     occupied regions** for each agent, **conditioned on our candidate path**. Make them safe with
     **conformal coverage**, plus conservative fallback tubes.
   - The yield gate stays closed.
   - No cattle-trajectory dataset exists, so animals = observed obstacle + conservative reachable
     region.
2. **P5, perception:**
   - First, **put a real camera → detection → tracker path into the loop** and diagnose the zero
     detections on renders.
   - Then fine-tune on randomised renders + Indian images.
   - Open-vocabulary models (Grounding DINO, YOLO-World) are for **label mining**, not the
     in-loop safety detector.
3. **Order:** perception in the loop first, then prediction learns from realistic observations.

## Added by Claude: the best Indian trajectory data found
- **SPT dataset — chennaitrafficdata.com** (Rajput et al. 2026, *Transportation Research Part C*;
  IIT Kanpur, IIT Tirupati, TU Dresden).
  - Drone trajectories of Chennai urban traffic.
  - Classes: two-wheeler, car, **three-wheeler**, LCV, HCV.
  - Longitudinal **and lateral** position, velocity, acceleration.
  - Size and licence: see its "How To Access" page. **UNVERIFIED**.
  - **This is the most direct data for training Indian agent prediction and for calibrating
    reactive sim agents.**
- Also: IDD-PeD (pedestrian intent + trajectory), METEOR (behaviour tags), IDD-X (explanation
  labels), and the SkyEye paper (Indian overhead mixed traffic).

---
## P4 — Prediction ML

**Recommendation:** Keep `gateYield` closed. The **2.089% dangerous-error rate and its CI above the ≤1% bar are from your audit**. A new model, lower ECE, or a strong public leaderboard result does not establish that the gate is safe. The next useful output is a *set of possible agent trajectories* that the planner can check against each ego candidate, with a conservative fallback when tracks or calibration fail. [Waymo’s conditional prediction research](https://waymo.com/research/identifying-driver-interactions-via-conditional-behavior-prediction/), [NVIDIA’s reachable-set safety monitor](https://research.nvidia.com/labs/aspire/publication/chakraborty.feng.etal.arxiv2025/).

### What leading systems and research predict

| Approach | Verified finding | Relevance here |
|---|---|---|
| Waymo | [Wayformer](https://waymo.com/research/wayformer/) predicts multimodal trajectories from agents and scene context. [MotionLM](https://waymo.com/research/motionlm/) generates **joint** agent futures and can condition on a queried agent trajectory. [Occupancy Flow Fields](https://waymo.com/research/occupancy-flow-fields-for-motion-forecasting-in-autonomous-driving/) also represents future occupancy, flow, and agents that may emerge from occlusion. [EMMA](https://waymo.com/blog/2024/10/introducing-emma/) is multimodal **ego planning** research; Waymo identifies inference time and missing lidar/radar input as limitations. | Joint samples help at merges and crossings; occupancy helps behind buses. Do not treat EMMA as a ready agent predictor. |
| Tesla | Tesla publicly describes [video-to-BEV networks](https://www.tesla.com/AI) producing road layout, infrastructure, and 3D objects for planning. **UNVERIFIED:** its current production architecture for forecasting *other agents*; the public description does not specify it. | BEV is a useful representation, not evidence for a reproducible prediction model. |
| NVIDIA | Published work includes [guided conditional diffusion for multi-agent traffic](https://research.nvidia.com/publication/2023-05_guided-conditional-diffusion-controllable-traffic-simulation) and a [trajectory-predictor-based safety monitor](https://research.nvidia.com/labs/aspire/publication/chakraborty.feng.etal.arxiv2025/). | More useful as research patterns than as a disclosed production stack. |
| Wayve | [FIERY](https://wayve.ai/wp-content/uploads/2024/04/2104.10490.pdf) forecasts future BEV instances from cameras. [GAIA-2](https://wayve.ai/thinking/gaia-2/) is an ego-action-conditioned *video world model* with controllable agent behaviour; [GAIA-4](https://wayve.ai/thinking/gaia-4/) addresses closed-loop evaluation. | World models can generate tests; they are a much larger project than replacing `predictYield.m`. |
| Mobileye | Its published [RSS methodology](https://www.mobileye.com/technology/safety-methodology/) uses bounded worst-case assumptions to define safe distances and responses, rather than relying on precise human-behaviour forecasts for its safety argument. | Keep a rule/reachability safety layer even if ML trajectories improve. |

**Marginal vs joint:** Six plausible paths *per agent* can combine into an implausible scene. Joint prediction scores complete scenes, including how a pedestrian and two-wheeler react to each other. Ego-conditioned prediction asks a different question: “what might they do **if ego takes candidate path A**?” Waymo explicitly studies that query interface. [MotionLM](https://waymo.com/research/motionlm/), [conditional behaviour prediction](https://waymo.com/research/identifying-driver-interactions-via-conditional-behavior-prediction/), [joint-metrics study](https://arxiv.org/abs/2305.06292).

### Models worth benchmarking

Results below are **different tasks and splits; do not rank the numbers against each other**. Compute entries describe published *training* requirements; **CPU/GPU inference latency for your MATLAB loop is UNVERIFIED** until measured there. [Waymo challenge metrics](https://waymo.com/open/terms/), [WOMD format](https://waymo.com/open/data/motion/), [AV2 format](https://www.argoverse.org/av2.html).

| Model | Published result; code and compute | Fit for SIH |
|---|---|---|
| [MTR v3](https://storage.googleapis.com/waymo-uploads/files/research/2024%20Technical%20Reports/2024%20WOD%20Motion%20Prediction%20Challenge%20-%201st%20Place%20-%20MTR%20v3.pdf) | 2024 WOMD motion test **0.4967 soft mAP**, using an ensemble; trained on **8 A100s for 30 epochs**. The [public MTR repo](https://github.com/sshaoshuai/MTR) is for the earlier MTR family; an exact v3 reproduction package is **UNVERIFIED**. | Expensive reference, especially its lidar encoder and ensemble. |
| [QCNet](https://github.com/ZikangZhou/QCNet) | AV2 test **minFDE₆ 1.24 m, minADE₆ 0.64 m, miss rate₆ 0.15**; code and checkpoint published. Repo says training consumes about **160 GB GPU memory**. | Strong reproducible trajectory baseline; map and PyG preprocessing need adaptation. |
| [DeMo / DeMo++](https://github.com/fudan-zvg/DeMo) | Open code; separates directional modes from evolving states using attention and Mamba. [DeMo++](https://arxiv.org/abs/2507.17342) reports forecasting and planning benchmarks. Comparable deployment latency is **UNVERIFIED**. | Research candidate; Mamba and scatter dependencies raise import work. |
| [Parallel ModeSeq](https://storage.googleapis.com/waymo-uploads/files/research/2025%20Technical%20Reports/2025%20WOD%20Interaction%20Prediction%20Challenge%20-%201st%20Place%20-%20Parallel%20ModeSeq.pdf) | 2025 WOMD **two-agent interaction** test: **0.2978 soft mAP₆**, **11.2M parameters**, no ensemble in the report. Exact public code/checkpoint: **UNVERIFIED**. | Relevant architecture for negotiated right of way; not a drop-in build. |
| [SMART](https://github.com/rainmaker22/SMART) / [TrajTok](https://arxiv.org/abs/2506.21618) | Joint next-token simulation. SMART reports **0.7591** for tiny on 2024 WOMD Sim Agents; TrajTok reports **0.7852** on the **2025** challenge. SMART code is open; its repo says the Waymo-trained weights cannot be released under dataset terms. | Good source of reactive background agents for simulation; realism score is not a collision-safety score. |
| [MotionDiffuser](https://arxiv.org/abs/2306.03083) | Samples joint futures with controllable diffusion. | Useful research comparator; sampling cost and ONNX export in your setup are **UNVERIFIED**. |

### Indian evidence and missing coverage

| Data or paper | What it actually supplies |
|---|---|
| [METEOR](https://arxiv.org/abs/2109.07648) | Indian unstructured traffic videos, agent boxes, GPS trajectories, rare-behaviour tags, and 16 agent categories. Its authors report poor transfer from established perception and behaviour models. Your **1,251-clip training count is user-supplied**, not independently established by that paper. |
| [IDD-PeD paper](https://arxiv.org/abs/2506.22111), [authors’ code/data instructions](https://github.com/Ruthvik9/IDD-PeD) | Crossing intent **and** trajectory baselines for Indian pedestrians, including occlusion and unsignalized interactions. The repo reports **3,284 train and 1,632 test pedestrians**. The linked project page currently serves unrelated content; use the paper and repo. Dataset licence: **UNVERIFIED**. |
| [IDD-X](https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2024/IDDX_2024.pdf) | **9K important-object tracks** and ego-relative explanations including cut-in, merging, crossing, obstruction, animals, and potholes. These are useful supervision/context labels; they are **not metric future trajectories**. |
| [TIAND](https://ieeexplore.ieee.org/document/10588583/) | **150 Hyderabad scenes**, camera/lidar/radar/GPS/IMU, aimed at perception and fusion. Metric trajectory labels suitable for direct forecasting training: **UNVERIFIED**. [Access requires a usage agreement](https://tihan.iith.ac.in/TiAND.html). |
| [SkyEye paper](https://arxiv.org/abs/1912.04801), [Chennai drone trajectories](https://www.chennaitrafficdata.com/about-our-data) | Overhead mixed-traffic trajectories useful for lateral seepage and junction interaction; Chennai publishes vehicle coordinates, velocity, acceleration, and class fields. Whether either source supplies the ego-camera observations needed for direct in-car inference: **UNVERIFIED**. |
| [INDRA](https://arxiv.org/abs/2211.07916) | Pedestrian-view Indian road-crossing safety, a different viewpoint and target from ego-camera pedestrian trajectory prediction. |

I found **no verified Indian-road cattle future-trajectory dataset or validated cattle predictor** in this search. Treat standing/crossing cattle as an observed obstacle plus a conservative reachable region, and test sudden-motion cases in simulation; claiming learned animal intent would be unsupported. [IDD-X’s combined person/animal category](https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2024/IDDX_2024.pdf) illustrates the label limitation.

### Safety and MATLAB deployment

| Decision | Evidence and consequence |
|---|---|
| Replace “yield/GO” as the ML output | Predict **top-K metric trajectories or occupied regions over time** from tracked positions, velocities, class, visibility, and ego candidate path. The planner can test each candidate against all plausible occupied regions. [Waymo conditional prediction](https://waymo.com/research/identifying-driver-interactions-via-conditional-behavior-prediction/), [occupancy flow](https://waymo.com/research/occupancy-flow-fields-for-motion-forecasting-in-autonomous-driving/). |
| Calibrate *trajectory coverage* | [Multi-agent conformal reachability](https://arxiv.org/abs/2304.00432), [CUQDS under shift](https://ojs.aaai.org/index.php/AAAI/article/view/33915), and [NVIDIA’s calibrated reachable sets](https://research.nvidia.com/labs/aspire/publication/chakraborty.feng.etal.arxiv2025/) give published methods. Coverage depends on calibration assumptions; **it does not certify your ≤1% dangerous-error bar or cure missed detections**. Measure false GO, coverage, and fallback rate separately on held-out Indian and rendered scenarios. |
| Gate failures explicitly | Missing/old tracks, occlusion, unknown class, weather degradation, OOD scene, excessive prediction width, or missed runtime deadline should expand the reachable set or trigger conservative behaviour. This is a **proposed SIH policy**, informed by [RSS limited-visibility rules](https://www.mobileye.com/technology/responsibility-sensitive-safety/) and [NVIDIA’s OOD-aware monitor](https://research.nvidia.com/labs/aspire/publication/chakraborty.feng.etal.arxiv2025/). |
| Import path | MathWorks [ONNX import](https://www.mathworks.com/help/deeplearning/ref/importnetworkfromonnx.html) is release dependent: **Gather** can now map to built-in layers in R2026b, with limitations; unsupported operators can become custom layers/placeholders. “No Gather/Scatter” is a constraint of *your present export*, not a universal MATLAB rule. Start with fixed-size dense tensors and a small MLP/GRU or dense-attention predictor; test import, numerical agreement, and latency before selecting an architecture. |
| Python path | [Simulink can call Python](https://www.mathworks.com/help/simulink/ug/overview-of-integrating-python-code-with-simulink.html) through MATLAB Function/System blocks for simulation. [Extrinsic calls](https://www.mathworks.com/help/coder/ref/coder.extrinsic.html) execute in the MATLAB engine and are unsuitable as proof of standalone code generation. Use this to compare QCNet/SMART in a MATLAB-hosted run, with deadline and fallback measurements. |

**P4 options — effort/risk are my estimates for a student team:**

| Option | Concrete deliverable | Effort | Main risk |
|---|---|---:|---|
| **Good** | Keep `gateYield` closed; add class-specific constant-velocity/braking/turn reachable tubes, occlusion zones, and candidate-path collision checks in Simulink. | 1–2 weeks | Conservative stopping in dense traffic. |
| **Better — recommended** | Add a compact, fixed-shape **top-K 2–3 s trajectory model** trained on usable Indian tracks plus simulated interactions; conformalize its occupied tubes and retain the deterministic fallback. | 3–6 weeks | Labels and metric-coordinate alignment, not GPU capacity. |
| **Best** | Benchmark a joint ego-conditioned model such as QCNet/SMART-style decoding in Python co-execution, distil a small model, then verify closed-loop benefit and latency in MATLAB. | 6–10+ weeks | Integration and domain shift; leaderboard gains may not improve safety. |

## P5 — Perception ML

**Recommendation:** First connect an actual camera inference path to the driving loop and diagnose the **zero detections on rendered frames** from your audit. A 96% offline road IoU cannot establish usable road edges or safe traversability in the simulator until camera, labels, coordinate transforms, and deadlines are exercised together. MathWorks supplies [Unreal camera/sensor simulation](https://www.mathworks.com/help/driving/driving-scenario-simulation.html), [YOLOX inference](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.detect.html), and [lidar generation](https://www.mathworks.com/help/driving/ref/lidarpointcloudgenerator.html).

### Architecture and hazards

| Topic | Verified evidence → practical choice |
|---|---|
| Leaders | [Tesla](https://www.tesla.com/AI) describes multicamera video-to-BEV road layout and 3D objects. [Waymo’s sixth-generation Driver](https://waymo.com/blog/2024/08/meet-the-6th-generation-waymo-driver/) combines cameras, lidar, and radar; its [2026 description](https://www.waymo.com/blog/2026/02/ro-on-6th-gen-waymo-driver/) explains weather redundancy. [Mobileye Drive](https://www.mobileye.com/blog/mobileye-drive-self-driving-system/) describes separate camera and radar/lidar perception paths. These are design references, **not published recipes for reproducing their production accuracy**. |
| BEV and occupancy | [BEVFusion](https://proceedings.neurips.cc/paper_files/paper/2022/file/43d2b7fbee8431f7cef0d0afed51c691-Paper-Conference.pdf) fuses camera and lidar in BEV; [SurroundOcc](https://github.com/weiyithu/SurroundOcc) predicts camera-based 3D occupancy. Their public benchmarks do **not** establish performance on Indian animals, unmarked edges, potholes, or your renderer. Start with a 2D traversability grid plus tracked obstacles; use 3D occupancy as a research comparator. |
| Rare classes | [Grounding DINO](https://github.com/IDEA-Research/GroundingDINO) and [YOLO-World](https://github.com/AILab-CVC/YOLO-World) accept open-vocabulary prompts. Use them to **mine and label** pushcarts, cattle, and local vehicle types, then evaluate a small fixed-class detector in-loop. A text prompt alone supplies no validated safety recall or distance. |
| No markings or road edge | Segment road surface, shoulder, sidewalk, barrier, and unknown separately; project the mask using calibrated camera geometry, compare against lidar ground/height, then erode by localization uncertainty and vehicle footprint. This is a **proposed fusion design** supported by [IDD’s unstructured-road labels](https://insaan.iiit.ac.in/datasets/) and MathWorks’ [ground/obstacle lidar workflows](https://www.mathworks.com/help/driving/detection-and-tracking.html). **Drivable colour ≠ safe geometry** at a drop-off, water-filled pothole, or diversion. |
| Potholes and drop-offs | [IDD-X](https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2024/IDDX_2024.pdf) labels damaged road and speed breakers as important objects. Lidar negative-obstacle methods reason about **missing ground returns and depth discontinuity**; absence of returns alone can also mean occlusion, so keep unknown cells non-drivable. [Negative-obstacle study](https://www.patternrecognition.asia/perception/negative2015a.pdf). |

### Indian perception data

“Size” means the units published by the source; **licence is UNVERIFIED where the distributor shows it only at sign-in or under a data agreement**.

| Dataset | Verified size/use | Access or licence |
|---|---|---|
| [IDD segmentation/detection, IDD-117K](https://insaan.iiit.ac.in/datasets/) | Segmentation **20K images**; IDD-117K combines detection releases for about **117K images**. Road surface and local traffic classes. | [Licence displayed before download](https://idd.insaan.iiit.ac.in/accounts/login/); terms **UNVERIFIED** here. |
| [IDD-AW, IDD-3D, FGVD](https://insaan.iiit.ac.in/datasets/) | **19 GB** paired RGB/NIR rain, fog, low light and snow; **12K annotated lidar frames** in IDD-3D ([paper](https://arxiv.org/abs/2210.12878)); **5,502 images / 210 fine vehicle labels** in FGVD. | Distributor terms **UNVERIFIED**. |
| [IDD-X](https://insaan.iiit.ac.in/datasets/) | **1,140 videos**, **697K important-object boxes**, including damaged road and animals ([paper](https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2024/IDDX_2024.pdf)). | Distributor terms **UNVERIFIED**. |
| [DriveIndia](https://arxiv.org/abs/2507.19912) | **66,986 images / 24 classes**, reported fog, rain, and mixed traffic; authors report **78.7% mAP50** for their best baseline, which is **not comparable** to your YOLOX mAP without the same test and metric. | [TiHAN access requires a usage agreement](https://tihan.iith.ac.in/TiAND.html); exact licence **UNVERIFIED**. |
| [TIAND](https://ieeexplore.ieee.org/document/10588583/) | **150 multimodal scenes**, 2–4 minutes each, Hyderabad. | [Request and agreement](https://tihan.iith.ac.in/TiAND.html). |
| [DATS_2022](https://www.sciencedirect.com/science/article/pii/S2352340922006643) | **>10K images / 45 classes**; the article says **>7K annotations** at submission. | Article is open access under Creative Commons; **the dataset’s exact reuse terms are UNVERIFIED**. |
| [RoadText-1K](https://arxiv.org/abs/2005.09496) | Driving-video text detection/recognition, useful for signs and shopfront context, **not** road-edge or obstacle training. | Dataset licence **UNVERIFIED**. |

### Fixing simulation transfer and running in MATLAB

| Step | Evidence and test |
|---|---|
| Diagnose before retraining | On identical rendered frames, log image dimensions/colour order, resize and normalization, class mapping, raw pre-threshold scores, NMS output, and boxes at several thresholds. Then manually label a stratified render set and report **per-class recall and false positives**. A threshold change is a diagnostic, not a safety fix. The [MATLAB YOLOX API](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.detect.html) exposes detection threshold; [SimROD](https://openaccess.thecvf.com/content/ICCV2021/papers/Ramamonjison_SimROD_A_Simple_Adaptation_Method_for_Robust_Object_Detection_ICCV_2021_paper.pdf) documents synthetic-to-real detector shifts. |
| Adapt to renders | Fine-tune on labelled renders mixed with real IDD/DriveIndia images; vary camera height/FOV, exposure, shadows, textures, actor shapes, occlusion, rain and fog. Hold out **entire render styles and real scenes** for validation. Domain randomization and adaptation have published support, but their effect on *your* YOLOX is **UNVERIFIED**. [Domain-randomization study](https://openaccess.thecvf.com/content_cvpr_2018_workshops/papers/w14/Tremblay_Training_Deep_Networks_CVPR_2018_paper.pdf), [SimROD](https://openaccess.thecvf.com/content/ICCV2021/papers/Ramamonjison_SimROD_A_Simple_Adaptation_Method_for_Robust_Object_Detection_ICCV_2021_paper.pdf). |
| Rendering choice | MathWorks’ [Unreal scene configuration](https://www.mathworks.com/help/driving/ref/simulation3dsceneconfiguration.html) directly controls sun, fog, rain, snow and lens raindrops. [UniSim](https://arxiv.org/abs/2308.01898) uses recorded logs for neural closed-loop sensor simulation; [NeuRAD/SplatAD code](https://github.com/georghess/neurad-studio) requires a substantial Python/CUDA reconstruction pipeline. **Inference:** Unreal variations are the student-ready first step; neural rendering is an optional research track, not a quick fix for zero boxes. |
| Native tools | MathWorks documents [YOLOX train/detect](https://www.mathworks.com/help/vision/ref/yoloxobjectdetector.html), [PointPillars train/detect](https://www.mathworks.com/help/lidar/ug/object-detection-using-pointpillars-network.html), [lidar-camera calibration](https://www.mathworks.com/help/pointcloud/gs/get-started-lidar-camera-calibrator.html), [Simulink Predict block](https://www.mathworks.com/help/deeplearning/ref/predict.html), and [Unreal sensor simulation](https://www.mathworks.com/help/driving/driving-scenario-simulation.html). Python is the practical path for Grounding DINO, YOLO-World, BEVFusion and neural renderers; use [Simulink’s Python interface](https://www.mathworks.com/help/simulink/ug/overview-of-integrating-python-code-with-simulink.html) only after measuring simulation latency and fallback. |

**P5 options — effort/risk are my estimates:**

| Option | Concrete deliverable | Effort | Main risk |
|---|---|---:|---|
| **Good** | Put camera and existing YOLOX/DeepLab inference in Simulink; fix preprocessing/threshold issues; fuse road mask with geometric obstacles; report rendered per-class recall. | 1–3 weeks | Detector may still miss rare classes. |
| **Better — recommended** | Fine-tune on labelled, randomized renders plus Indian images; add road-edge/unknown and pothole/negative-obstacle checks; feed detections and uncertainty into `trackerGNN`. | 4–7 weeks | Annotation and calibration quality; weather/occlusion misses. |
| **Best** | Train Indian-domain camera–lidar BEV perception with temporal occupancy, using open-vocabulary models for label mining; run a distilled detector/fusion model inside the MATLAB-hosted loop. | 8–12+ weeks | High integration cost and insufficient rare-event validation. |

**Order of work:** P5’s camera-to-track path must produce measured detections before P4 can learn from realistic observations. Keep ground-truth tracks as a separate diagnostic input while comparing predictors; otherwise a prediction score can conceal perception failures. This sequencing is my recommendation based on your audit and the published separation of [perception, forecasting and planning benchmarks](https://waymo.com/open/challenges/).