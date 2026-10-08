
# Fifteen hard questions and honest answers

1. **The PS explicitly says RoadRunner. Where are those scenes?**  
   We lack that licence. We propose two detailed **CARLA 0.9.15** village and junction scenes connected to the Simulink ego stack. This is a disclosed **literal deviation**, not a waiver. [P14](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P14-PS-COMPLIANCE.md)

2. **Is the complete Simulink system working today?**  
   No. The MATLAB 2D planner and some sensor tracking run; the Simulink bicycle model is a side model, and camera inference is outside the driving loop. [P2](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md)

3. **Why claim real-time replanning when you measured 735.8 ms?**  
   We do **not** claim it today. The build gate replaces the collision-check hotspot, compiles planner and verifier kernels, and reports full-loop p50/p95/p99 plus 100 ms deadline misses. [P15](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P15-BUILD-PLAN.md)

4. **Can your camera currently identify an auto or a cow in CARLA?**  
   Not reliably: YOLOX produced zero render boxes at the audited default threshold. Offline auto and cow AP are 38.2% and 16.3%; labelled in-loop recall is a required gate. [P2](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md)

5. **Does your yield model give the car permission to cross?**  
   No. Its dangerous-error rate is 2.089% against its ≤1% gate, so its output is disabled. The planned model predicts occupied regions; only the separate geometric/braking checker may permit movement. [P2](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P2-AUDIT-OUR-SYSTEM.md), [P13](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P13-SYSTEM-DESIGN.md)

6. **What prevents the independent checker from freezing the car forever?**  
   Nothing can guarantee progress in a truly blocked road. We fix today’s S2/S3 stall bugs, record **false** stalls when a feasible gap existed, and permit only a freshly checked, stoppable creep. [P3](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P3-PLANNER.md)

7. **What is new if learned proposals and separate verification already exist?**  
   Those mechanisms are prior art, including Mosaic. The proposed contribution is an **India-calibrated, measured** closed loop with responsive traffic, false-stall accounting and held-out baselines; its benefit is not proved yet. R20–R23.

8. **Fourteen AI models with two builders in ten weeks?**  
   Fourteen is the **design inventory**. Five form the target core; only YOLOX and DeepLab exist offline today. Nine are later extensions, and the RL policy is a comparison, not the driving authority. [P15](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P15-BUILD-PLAN.md)

9. **How will you obtain authentic autos and cattle in CARLA?**  
   A custom driveable vehicle needs a Windows UE4 source build; W2 must spawn one vehicle and one prop. If it fails, we disclose blueprint/prop surrogates and withdraw claims of realistic auto pixels or physics. R31.

10. **Will SUMO and CARLA both control the same actor?**  
    No. SUMO owns reactive traffic state; the bridge mirrors it into CARLA, while Simulink controls ego. Timestamp, actor-ID and pose assertions must pass before a run counts. [P13](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P13-SYSTEM-DESIGN.md)

11. **How do hand gestures and horns affect right of way?**  
    They raise caution or change an intent hypothesis. A police “proceed” gesture, horn, or siren cannot itself open the verifier; a siren triggers only a checked yield or stop. [P15](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P15-BUILD-PLAN.md)

12. **Does a real dashcam replay prove the car can drive on a real road?**  
    No. It is open-loop evidence for perception and tracking transfer. We report per-class recall on held-out real versus rendered frames; road-driving safety still needs much more evidence. [P15](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P15-BUILD-PLAN.md)

13. **How do you predict a cow’s sudden motion without a cattle-trajectory dataset?**  
    We do not claim a learned cattle-intent model. Cattle remain detected obstacles with conservative reachable regions, tested against sudden-onset scenarios. [P4–P5](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P4-P5-ML-PREDICTION-PERCEPTION.md)

14. **What do the large crash numbers prove about your expected impact?**  
    They establish the **problem’s scale**, not lives saved by our system. MoRTH totals are national 2023 counts; the cattle-crash count is Haryana-only over five years. We give no projected reduction. R03–R05.

15. **What will you hand over if the finale gates fail or data access is denied?**  
    The same model, scenario manifests, raw logs, failure reasons, measured PS metrics and a plainly marked partial result. Dataset access is checked before use; missing classes and the RoadRunner deviation remain visible. [P14](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P14-PS-COMPLIANCE.md), [P15](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P15-BUILD-PLAN.md)