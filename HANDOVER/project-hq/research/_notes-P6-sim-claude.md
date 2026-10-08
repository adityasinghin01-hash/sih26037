# P6 simulation world — Claude's raw findings

## PS toolchain (must host the running system)
- MATLAB `drivingScenario` (cuboid) + RoadRunner + RoadRunner Scenario + Unreal (`sim3d`). As of
  R2026a, RoadRunner Scenario imports ASAM OpenSCENARIO. Scenario Builder (a free add-on) rebuilds
  scenarios from recorded camera, lidar, GPS and IMU.
- **RoadRunner licence: still missing.** TwinX (SIH 2025 winner) exported to RoadRunner, so SIH
  teams appear to get access. The MathWorks Student Competition Software Request Form route
  exists. **ACTION: chase the mentor's August request / hackathon@mathworks.com.**
- MATLAB ↔ CARLA: officially supported through the ROS Toolbox (CARLA ROS bridge) and
  "RoadRunner Scenario: cosimulate with CARLA".
  https://www.mathworks.com/help/ros/ug/set-up-and-connect-to-carla-simulator.html

## The neural-fields / world-model route (the "beyond PS" tech)
- **NVIDIA AlpaSim** (open source, NVlabs/alpasim): closed-loop AV simulator built as microservices
  (Driver, Renderer, TrafficSim, Controller, Physics), running on Docker Compose on one machine or
  on SLURM. https://github.com/NVlabs/alpasim
- **NuRec**: 3D Gaussian Splatting reconstruction from real sensor logs, rendered with gsplat. It
  plugs into AlpaSim **and CARLA** over gRPC. https://developer.nvidia.com/omniverse/nurec
- **Instant NuRec** (arXiv 2607.14203, Jul 2026; github NVIDIA/instant-nurec): turns a SHORT
  MULTI-VIEW driving log into a simulatable 3DGS world in one forward pass.
  **OPEN QUESTION: does it work from a single dashcam plus GPS (what we can record in Najibabad or
  Meerut)?**
- **OmniDreams** (arXiv 2606.03159): a real-time generative world model as the renderer.
- `alpasim-carla` (SimForge): a CARLA renderer for AlpaSim.
- **So the "real Indian road reconstructed from our own video → closed-loop test" pipeline now
  exists in open source.** This is what makes a "neural fields" claim real.
  Cost: it needs an NVIDIA GPU. The DGX A100 fits, but the A100 has **no RT cores**, which matters
  for Unreal/CARLA rendering, not for gsplat.

## Assets
- Auto-rickshaw and cow 3D models exist as commercial or free game assets (TurboSquid, CGTrader,
  itch.io). **No dedicated Indian asset pack for CARLA/Unreal was found.**
