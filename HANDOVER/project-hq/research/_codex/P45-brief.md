You are my research partner on SIH26037 (Smart India Hackathon 2026, MathWorks PS "Adaptive Path Planning
and Collision Avoidance for Autonomous Vehicles on Unstructured Indian Roads"). Vision: a full self-driving
system for Indian roads, tested in simulation (MATLAB/Simulink must host the running system; Python allowed
for training; college has a DGX A100). I (Claude) check every source you give. Rules: live web search,
every fact with a working URL, UNVERIFIED if unsure, never invent. Concise tables.

PHASES P4 (PREDICTION ML) and P5 (PERCEPTION ML).
Context - the requirement list (top priorities from our catalogue): no markings/road edge; two-wheeler
seepage; midblock pedestrian crossing; occluded pedestrians behind buses; informal merge; uncontrolled
T-junction; wrong-way vehicle; abrupt braking; cut-in; cattle standing/crossing; slow tractor; rolling
pedestrian crossing; dense overlapping users; potholes; construction diversion; bus pull-out; auto stops;
rain; fog; unlit night; hairpins; negotiated right of way.
Our current ML (audit):
| 2 | **Prediction ML** | LSTM (25k params) + attention model (58k params) over 31 depth-free image-plane features, trained on METEOR (1,251 clips); Platt calibration; ONNX opset 18 with no Gather/Scatter; `predictYield.m` plus the `gateYield` gate | Test set (233 clips): **dangerous-error 2.089%**, CI [1.315, 2.854] vs bar ≤1%; covers 10.5% of GO decisions; ECE 0.0159 | **Weak** | **Fails its own bar, so it drives nothing** (Valid=false). Label is "assert" (took the gap), not true yield; the ego features 28–31 are nearly empty in METEOR; it predicts intent only, not trajectories; no multi-agent joint prediction |
| 3 | **Perception ML** | YOLOX spotter (IDD, A100); DeepLab v3+ road segmenter; PointPillars (script only) | DeepLab: **drivable IoU 96.0%, mIoU 86.3%**. YOLOX: mAP 29.1% (cow AP 16.3%, auto 38.2%). On rendered frames: **0 detections at the default threshold** | **Weak** | **Offline only**, nothing in the driving loop. Camera not in the loop. PointPillars never trained. Two of the model files are only on Shourya's Windows PC |
| 4 | **Sensing and tracking** | Simulated lidar, radar and near-field ring → `trackerGNN` (constant-velocity EKF) → S1 TrackList | S1 under sensing: 0.625 m vs 0.618 m ground truth (7 mm change) | **Partial** | Sensor numbers are not from a datasheet; no real ray-cast occlusion; no false alarms; no weather model |

P4 PREDICTION - research:
1. How Tesla, Waymo (MotionLM, Wayformer, foundation model), NVIDIA, Wayve, Mobileye predict other agents;
   joint multi-agent vs marginal; intent vs trajectory; occupancy-flow prediction.
2. SOTA models 2024-2026 (MTR/MTRv3, QCNet, DeMo, SMART/sim-agent tokenisers, diffusion predictors) with
   benchmark numbers (WOMD/Argoverse2/nuPlan), compute cost, code availability.
3. Prediction in HETEROGENEOUS/Indian traffic: every paper and dataset (METEOR, IDD-X, IDD-PeD, TIAND, any
   Indian drone/BEV trajectory dataset). Pedestrian intent models for India. Animal motion prediction.
4. Ego-conditioned / interactive prediction (predictions that depend on the ego's candidate action).
5. How to make a predictor SAFE to use: calibration, conformal prediction for trajectories, OOD detection,
   gating. Our model fails its 1% dangerous-error bar - what published methods fix this class of problem.
6. Deployability in MATLAB: which architectures import via ONNX (no Gather/Scatter trouble), or run via
   MATLAB Python co-execution / Deep Learning Toolbox; latency on CPU/GPU.
P5 PERCEPTION - research:
1. Leaders: Tesla occupancy networks/vision-only BEV, Waymo camera+lidar+radar fusion, Mobileye.
2. SOTA: BEV fusion (BEVFusion etc.), 3D occupancy prediction, open-vocabulary detection for rare classes
   (Grounding DINO, YOLO-World, OWL) - relevant for pushcarts/animals/jugaad vehicles not in datasets.
3. Drivable-space & road-edge detection without markings; pothole/speed-breaker detection; negative
   obstacles (drop-offs) from lidar.
4. Indian perception datasets 2023-2026 (IDD family, IDD-AW adverse weather, DriveIndia, DATS, FGVD,
   RoadText, pothole datasets) with sizes/licences.
5. Sim-to-real: making detectors work on simulated camera frames (our YOLOX gives 0 detections on renders):
   domain randomisation, style transfer, neural rendering / 3D Gaussian splatting / NeRF-based sensor sim
   (UniSim, NeuRAD, etc.) - what is usable by students.
6. What MATLAB supports natively (Lidar Toolbox, PointPillars, YOLOX, camera-lidar calibration, Unreal
   camera sim) and what needs Python.
End each phase with: 3 concrete options for us (good/better/best) with effort and risk.
