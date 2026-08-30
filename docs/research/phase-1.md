# PHASE 1 — MERGED RESULT
**30 Aug 2026. Claude's sweep + Perplexity + Consensus/lit-review + Grok + Reddit.**
**Verdict: the algorithmic novelty is gone. The contribution has to move.**

---

## PART 1 — EVERY ONE OF OUR FOUR IDEAS IS OCCUPIED

| Our idea | Who owns it | Status |
|---|---|---|
| Interaction-aware prediction (our plan changes their path) | Trautman & Krause 2010; Sadigh 2016; large field | DEAD as novelty |
| Per-agent negotiability (cow vs pedestrian vs bus) | **B-GAP** (RA-L/IROS 2022) — aggressive/conservative behaviour drives ego navigation. Already **superseded** by Chandra 2024 multi-agent IRL, which goes beyond binary classes (2x better than single-agent IRL) | DEAD |
| Negotiating an unsignalled intersection | **GamePlan** — auction ordering for **non-communicating** agents at intersections, roundabouts and merges, claims collision- and deadlock-free. **GameOpt** adds optimisation. **GameOpt+ (2024)** extends to *unregulated heterogeneous* intersections: <10 ms at >10,000 veh/hr, >=25% throughput, >=70% lower time-to-goal, 50% less fuel, in SUMO | DEAD |
| ASSERT / nudge forward | **Waymo publicly reprogrammed its Driver to be "confidently assertive"** — takes gaps sooner, drives around stopped trucks across double-yellow. Covered by WSJ, SF Chronicle, NPR | DEAD |
| The horn as a negotiation action | **Waymo honks** (short taps vs sustained, defined patterns). **Cruise deployed autonomous honking ~2022-23** and claimed collision reduction. US patents: 9919560 (adaptive honking that learns effectiveness), 10373499, 11958505, 12280803 | DEAD |
| "A car that only yields never moves" framing | **Camara & Fox, "Unfreezing autonomous vehicles with game theory, proxemics, and trust", Frontiers 2022** | DEAD as a framing claim |
| "No India planning research exists" | **FALSE.** Chandra PhD thesis (UMD 2022); Fei et al. 2025 non-lane-based ego DRL; DDPG at uncontrolled Indian intersections (Multimedia Tools & Apps, Aug 2024); Swaayatt's own "Bidirectional Negotiation" article | FALSE |

### Also killed: my own metric claim
CARLA Driving Score = route completion x infraction penalty, and "agent blocked" (180 s
no action) is already a tracked infraction. **Freezing is already penalised.** My "no metric
punishes a frozen car" claim was wrong. The only surviving nuance is that 180 s is
meaningless for an Indian junction and nothing grades *degree* of hesitation.

---

## PART 2 — THE MAP OF WHO OWNS THIS SPACE

- **Chandra / Manocha (UMD, GAMMA -> UVA CRAL)** — TraPHic (CVPR 2019), RobustTP, RoadTrack,
  CMetric, GraphRQI, B-GAP, GamePlan, GameOpt, METEOR, multi-agent IRL 2024. The dominant group.
- **Suriyarachchi / Baras (UMD)** — GameOpt+ 2024, https://arxiv.org/pdf/2405.16430
- **Luo, Cai, Lee, Hsu (NUS)** — **SUMMIT simulator**: dense *unregulated* urban traffic,
  heterogeneous agents, planning evaluated in crowd-driving settings
- **Camara & Fox (Leeds / Lincoln)** — unfreezing AVs, proxemics, trust, pedestrian negotiation
- **IIIT Allahabad** — METEOR collaborators (dataset first posted 2021)
- **IIIT Hyderabad / Oxford** — IDD, IDD-3D
- **Swaayatt Robots** — public technical articles, NOT peer-reviewed: "QCQP-Tunneling:
  Ellipsoidal Constrained Agent Navigation" and **"Bidirectional Negotiation"** (single-lane
  road negotiation, off-road demo). ~$7M raised. Claims RL/IRL for adversarial traffic.
- **Minus Zero** — publication status UNVERIFIED; pivoted from robotaxi to India-specific ADAS
  for OEMs (Ashok Leyland MOU, Tata talks) after policy signals
- **Key survey to read: "Autonomous Driving in Unstructured Environments" (2024), 250+ papers**

## Newer work that matters
- **Zhang et al. 2024** — graph predictor with a category layer + **new dense heterogeneous
  unsignalized-intersection dataset (HID)**; beats benchmarks on HID, ApolloScape, TRAF
- **Fei et al. 2025** — DRL ego decision-making in **non-lane-based** traffic, with sim metrics
- **Al-Sharman 2023** — self-learned driving at unsignalized intersections (hierarchical RL + MPC)

---

## PART 3 — WHAT IS ACTUALLY LEFT FOR US

**1. MATLAB / Simulink. STILL THE STRONGEST.**
Every work above is Python — CARLA, SUMO, custom. MathWorks' shipped examples are highway
and lane-based. Our PS *requires* MATLAB + Simulink + RoadRunner.
**UNVERIFIED — the GitHub search has not been run yet. This is now the highest-priority check.**

**2. Animals as negotiating agents.**
Searches for livestock/cattle behaviour models in AV planning returned only generic obstacle
avoidance. The PS *explicitly requires* a cattle-crossing scenario. Aditya's field note: a cow
looks at you and moves when honked at — it is a low-attention agent, not an obstacle.
STILL LOOKS OPEN. Needs one more verification pass.

**3. Integration + evidence, in the five required scenarios, end to end.**
Nobody has all of it in one closed loop with trained perception. Most of the works above
assume ground-truth agent states.

**4. An honest reproducible Indian benchmark in the MathWorks toolchain.**

---

## PART 4 — THE STRATEGIC CORRECTION

The dossier's own §2 records how the last two MathWorks SIH winners won:
- **TwinX (SIH 2025)**: won on an **end-to-end workflow on a single platform**, their words.
- **Solar Masters (SIH 2024)**: won on simulation + hardware + apps, i.e. integration.

**Neither won on a novel algorithm.** We have been optimising for the wrong axis.
For a MathWorks-judged problem, the winning axis is *integration, fidelity and evidence*,
not algorithmic invention.

### The honest claim we can actually defend
> We did not invent the algorithms. We took the best published methods for dense
> unstructured traffic — none of which exist in the toolchain MathWorks asked for — and
> built the first working, reproducible, closed-loop implementation in MATLAB/Simulink,
> on real Indian scenes, with an honest baseline and published numbers.

### The citation that now works FOR us
Waymo publicly concluded that an over-passive AV is unsafe and made its Driver
assertive. **The industry leader validated our thesis.** We are applying it where the
problem is far worse, in a toolchain nobody has used for it.

---

## OPEN — NEXT ACTIONS
1. **GitHub search — MATLAB/Simulink question.** Not yet run. Highest priority.
2. Read the 2024 "Autonomous Driving in Unstructured Environments" survey (250+ papers).
3. Verify the animals gap properly.
4. Check whether METEOR and HID are downloadable, and under what licence.
5. Read GameOpt+ to see exactly what it does NOT cover (pedestrians? animals? perception?).

---

# PART 5 — GITHUB SEARCH RESULT (run by Aditya, 30 Aug 2026)

## FINDING A — every public MATLAB/Simulink AV repo is structured-road control
| Repo | Stars | What it does |
|---|:-:|---|
| tommoy/lateral-LQR-carsim-simulink | 41 | Lateral LQR controller |
| zlatanajanovic/SBMP_PerfDriving | 38 | Search-based motion planning, agile vehicles |
| sharath573/Object-Recognition-MATLAB | 30 | Detection on KITTI |
| yassinekebbati/NN_MPC-vs-ANFIS_MPC | 30 | LPV-MPC controller |
| MaruGreen/DDP-on-Trajectory-Optimization | 25 | Differential dynamic programming |
| DezsoRanki/RL-MPC | 23 | RL + MPC control |
| nebneBgnahZ/mathworks_autonomous_driving_project | 15 | MathWorks example project |
| petershlady/AutonomousDrivingEnvelopes | 10 | Safe driving envelopes, path tracking |
| AlperenKosem/mpc-for-autonomous-driving | 9 | MPC |
| PooyaBaravati/pid-lane-changing-simulink | - | PID **lane** changing, Driving Scenario Designer |

**Every one is lane-based control or trajectory optimisation on structured roads.**
Zero unstructured. Zero mixed traffic. Zero negotiation. Zero Indian.
Largest is 41 stars — compare Python AV repos in the same search at 408 and 357 stars.
**The MATLAB autonomous-driving open-source space is tiny and entirely structured-road.**

## FINDING B — every public IDD repo is perception. Not one is planning.
anishmadan23 (13, segmentation) · AbhayVAshokan Traffic-Sign (10) · DAYA7624 (8, segmentation)
· mohanrajmit (7, segmentation) · AbhayVAshokan Road-Segmentation (7) · Dalageo (7, segmentation)
· yashmarathe21 (6, UNet/PSPNet) · IshanKuchroo (5, segmentation + detection) · monk-boop (5,
CANet) · AtharvaMusale (segmentation)

**10+ repositories on India's flagship driving dataset. All perception. Zero planning.**
This confirms the dossier's §7 instinct empirically, even though its literature claim was wrong:
**the papers exist, but no public code turns IDD into a decision-making system.**

## HONEST LIMITS OF THIS EVIDENCE
GitHub search is not proof of absence. It cannot see private/company code, MathWorks File
Exchange (a separate site), or papers published without code. The defensible phrasing is
**"no public repository we could find"** — never "this has never been done."
