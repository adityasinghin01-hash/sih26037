
# References

Use **R01, R03–R06, R09, R13, R17, R20 and R22** as the short visible slide-6 list; this document is the linked backup. The titles below link to sources already used in the research files. “n.d.” means the linked page does not establish a publication year.

## Problem statement and Indian road safety data

- **R01.** Smart India Hackathon / MathWorks, “SIH26037 problem statement,” official PS page, 2026. [Link](https://www.sih.gov.in/sih2026PS).
- **R02.** Ministry of Education Innovation Cell, “SIH 2026 Guidelines,” competition guide, 2026. [College-hosted copy](https://sih-uit.vercel.app/assets/sih-2026-guidelines.pdf). Its printed September date is stale; use the live PS deadline in R01. [P0 check](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P0-RULES.md).
- **R03.** Ministry of Road Transport & Highways, *Road Accidents in India 2023*, Government of India report, 2023 data. [Link](https://morth.nic.in/sites/default/files/Road-Accident-in-India-2023-Publications.pdf).
- **R04.** Haryana Legislative Assembly, “To solve the problem of Stray Cattle,” Assembly answer, n.d. [Link](https://haryanaassembly.gov.in/wp-content/uploads/2023/01/14_13_US_1262_V4_signed.pdf). The answer reports the preceding five years; its exact answer date was not established in P1.
- **R05.** Ministry of Fisheries, Animal Husbandry & Dairying / PIB, “Livestock Census,” Lok Sabha reply, 2022, reporting the 2019 census. [Link](https://www.pib.gov.in/PressReleasePage.aspx?PRID=1813802).

## Indian traffic behaviour

- **R06.** Suman, Mondal and Lokesh, “Assessment of pedestrian safety margins at unsignalized mid block crossings in Patna,” *Scientific Reports*, 2026. [Link](https://www.nature.com/articles/s41598-026-55112-9).
- **R07.** Sahu, Parganiha and Pati, “A population estimation study reveals a staggeringly high number of cattle on the streets of urban Raipur in India,” *PLOS ONE*, 2021. [Link](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0234594).
- **R08.** Mohan and Chandra, “Investigating the influence of conflicting flow’s composition on critical gap under heterogeneous traffic conditions,” *International Journal of Transportation Science and Technology*, 2021. [Link](https://doi.org/10.1016/j.ijtst.2021.01.004).
- **R09.** Chennai Traffic Data / Rajput et al., “SPT Chennai traffic trajectories,” dataset project and *Transportation Research Part C* study, 2026. [Project](https://www.chennaitrafficdata.com/), [paper link cited in P4–P5](https://www.sciencedirect.com/science/article/pii/S0968090X25004358). File access and licence remain unverified. [P4–P5](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P4-P5-ML-PREDICTION-PERCEPTION.md)

## Indian datasets

- **R10.** IIIT Hyderabad, “India Driving Dataset (IDD),” dataset portal, n.d. [Link](https://insaan.iiit.ac.in/datasets/). Licence terms appear at download and were not verified in P4–P5.
- **R11.** IDD-3D authors, “IDD-3D: Indian Driving Dataset for 3D Unstructured Road Scenes,” arXiv preprint, 2022. [Link](https://arxiv.org/abs/2210.12878).
- **R12.** Shaik et al., “IDD-AW: A Benchmark for Safe and Robust Segmentation of Drive Scenes in Unstructured Traffic and Adverse Weather,” *WACV*, 2024. [Link](https://arxiv.org/abs/2311.14459).
- **R13.** Parikh, Saluja, Jawahar and Sarvadevabhatla, “IDD-X: A Multi-View Dataset for Ego-relative Important Object Localization and Explanation in Dense and Unstructured Traffic,” research paper, 2024. [Link](https://cdn.iiit.ac.in/cdn/cvit.iiit.ac.in/images/ConferencePapers/2024/IDDX_2024.pdf). Its labels are **not metric future trajectories**.
- **R14.** Bokkasam et al., “Pedestrian Intention and Trajectory Prediction in Unstructured Traffic Using IDD-PeD,” arXiv preprint, 2025. [Link](https://arxiv.org/abs/2506.22111). Dataset licence unverified.
- **R15.** Kumar, Reddy and Rajalakshmi, “DriveIndia: An Object Detection Dataset for Diverse Indian Traffic Scenes,” *ITSC*, 2025. [Link](https://arxiv.org/abs/2507.19912). TiHAN access requires an agreement; exact reuse terms need checking.
- **R16.** Khoba et al., “A Fine-Grained Vehicle Detection Dataset for Unconstrained Roads,” research paper, 2022. [Link](https://arxiv.org/abs/2212.14569).
- **R17.** TiHAN IIT Hyderabad, “TIAND: multimodal Indian driving scenes,” dataset portal and IEEE paper, 2024. [Portal](https://tihan.iith.ac.in/TiAND.html), [paper](https://ieeexplore.ieee.org/document/10588583/). Request and usage agreement required.
- **R18.** Chandra et al., “METEOR: A Dense, Heterogeneous, and Unstructured Traffic Dataset With Rare Behaviors,” arXiv preprint, 2021/2022. [Link](https://arxiv.org/abs/2109.07648). Dataset reuse terms need checking.
- **R19.** RoadText authors, “RoadText-1K: Text Detection & Recognition Dataset for Driving Videos,” arXiv preprint, 2020. [Link](https://arxiv.org/abs/2005.09496). Dataset licence unverified.

**Unfilled data needs:** Indian police hand gestures, siren/horn audio with direction labels, and driver-monitoring footage. The design must collect or simulate these and mark synthetic results as such. [P15](https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/research/P15-BUILD-PLAN.md)

## Planning and safety prior art; competitor evidence

- **R20.** Kruse, Yel, Senanayake and Kochenderfer, “Uncertainty-Aware Online Merge Planning with Learned Driver Behavior,” arXiv preprint, 2022. [Link](https://arxiv.org/abs/2207.05228).
- **R21.** Cai and Hsu, “Closing the Planning-Learning Loop with Application to Autonomous Driving” (*LeTS-Drive*), *IEEE Transactions on Robotics*, 2022. [Link](https://arxiv.org/abs/2101.03834).
- **R22.** Le Large et al., “Mosaic: An Extensible Framework for Composing Rule-Based and Learned Motion Planners,” *IROS*, 2026. [Link](https://arxiv.org/abs/2604.13853). Separate proposal and verification are prior art.
- **R23.** Trautman and Krause, “Unfreezing the Robot: Navigation in Dense, Interacting Crowds,” research paper, 2010. [Link](https://las.inf.ethz.ch/files/trautman10unfreezing.pdf).
- **R24.** “Multi-Agent Reachability Calibration with Conformal Prediction,” arXiv preprint, 2023. [Link](https://arxiv.org/abs/2304.00432). Calibration is conditional on its assumptions; it does not rescue missed detections.
- **R25.** ARAI, “Intelligent Vehicle Technology: Indian driving scenario repository for ADAS functions,” institutional page, n.d. [Link](https://www.araiindia.com/departments-laboratories/technology-group/intelligent-vehicle-technology).
- **R26.** Warwick WMG, “Crowdsourcing Indian Traffic Scenarios for ADAS Development and Testing,” research paper, 2026. [Link](https://wrap.warwick.ac.uk/196298/1/WRAP-Crowdsourcing-Indian-traffic-scenarios-ADAS-development-testing-26.pdf).
- **R27.** Swaayatt Robots, “Technology and autonomous-driving work,” company site, n.d. [Link](https://www.swaayattrobots.com/). Treat detailed performance as company claims.
- **R28.** Minus Zero, “How did a foundational model learn to navigate the busy streets of Bengaluru?”, company technical account, 2025. [Link](https://minuszero.ai/blog/how-did-foundational-model-learn-to-navigate-the-busy-streets-of-bengaluru). Its detailed runtime safety mechanism is unverified.

## MathWorks and simulation tools

- **R29.** MathWorks, “Client, Reader and Writer blocks for Eclipse SUMO co-simulation,” R2026a documentation. [Client](https://www.mathworks.com/help/driving/ref/client.html), [Reader](https://www.mathworks.com/help/driving/ref/reader.html), [Writer](https://www.mathworks.com/help/driving/ref/writer.html).
- **R30.** MathWorks, “Set Up and Connect to CARLA Simulator,” product documentation, n.d. [Link](https://www.mathworks.com/help/ros/ug/set-up-and-connect-to-carla-simulator.html).
- **R31.** CARLA project, “Windows build; add a new vehicle; add new props,” CARLA 0.9.15 documentation, n.d. [Build](https://carla.readthedocs.io/en/0.9.15/build_windows/), [vehicle](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_vehicle/), [props](https://carla.readthedocs.io/en/0.9.15/tuto_A_add_props/).
- **R32.** MathWorks, “Verify MEX Functions in the MATLAB Coder App,” product documentation, n.d. [Link](https://www.mathworks.com/help/coder/ug/how-to-test-mex-functions.html).
- **R33.** MathWorks, “Passenger Vehicle Dynamics Models,” Vehicle Dynamics Blockset documentation, n.d. [Link](https://www.mathworks.com/help/vdynblks/ug/passenger-vehicle-dynamics-models.html).

