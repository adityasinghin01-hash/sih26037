# P1 — The Indian road difficulty catalogue (the requirement list)

Status: FINAL, 26 Sep 2026. Built by Codex (gpt-6-sol) and verified by Claude.
- Claude spot-checked the sources: MoRTH 2023 figures (from the PDF itself), the Haryana Assembly
  PDF, the SAE/Warwick paper, IDD-AW, FGVD, ASAM OpenODD. The Patna and red-phase numbers were
  confirmed against their exact abstract and body sentences.
- **Severity/frequency ratings are engineering judgement, NOT measured rates.**
- "U" = no item-specific number was found.

## Summary
- **90 difficulties in 9 groups:** other road users, pedestrians, animals, road/surface,
  junctions/rules, communication, environment, perception traps, rare events.
- **Top 25 must-handle items** and **10 composable simulation families (F1–F10)** cover all 90
  and map onto the PS's 5 required scenarios.
- **Competitor finding:** the "first Indian AV test suite" claim is dead.
  - ARAI has an Indian ADAS scenario repository.
  - WMG Warwick Safety Pool Studio crowdsources Indian scenarios (exports OpenDRIVE/OpenSCENARIO)
    into a 250k-scenario database.
  - SimDaaS sells Indian scenario generation.
  - What survives: a **reproducible, composable CLOSED-LOOP PLANNER benchmark** for unstructured
    Indian roads, with baselines and pass/fail metrics. **Not claimed as first.**

---
### A. Other road users

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 1 | Car cuts across the ego path with little warning. | U | H/H: side impact; dense traffic | Pr, Pl, Sa | Short notice cut-in and variable gap. |
| 2 | Two-wheelers seep through gaps between vehicles. | **0.906 m sample mean**, [study](https://www.sciencedirect.com/science/article/pii/S1389128626005220) | H/H: rider exposure; congestion | Pe, Pr, Pl | Small gaps, lateral motion, rider envelope. |
| 3 | Two-wheeler follows off-centre, then changes side. | **294 lateral shifts** in a Bengaluru study, [paper](https://www.sciencedirect.com/science/article/pii/S2095756418300084) | H/H: close conflict; mixed traffic | Pr, Pl | Oblique following and stochastic shift. |
| 4 | Rider passes on either side, including the left. | U | H/H: close pass; mixed traffic | Pe, Pr, Pl | Two-sided passing with narrow clearance. |
| 5 | Vehicle approaches against traffic. | **5.5% of deaths** in combined wrong-side/lane-indiscipline category, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: head-on risk; route-dependent | Pe, Pr, Pl, Sa | Counterflow actor and escape constraints. |
| 6 | Lead vehicle brakes abruptly at short headway. | **1,10,656 rear-end crashes** as collision proxy, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/H: rear impact; common following | Pr, Sa, Co | Braking onset, reaction delay, stopping distance. |
| 7 | Oncoming vehicle occupies the ego path while overtaking. | **84,348 head-on crashes** as proxy, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: fatal conflict; undivided roads | Pr, Pl, Sa | Opposing-lane incursion and blocked shoulder. |
| 8 | Vehicle makes a U-turn across moving traffic. | U | H/M: crossing conflict; median openings | Pr, Pl, Sa | Wide turning arc and uncertain yield. |
| 9 | Auto-rickshaw stops for pickup without a bay. | U; documented in [Bengaluru fieldwork](https://anthrosource.onlinelibrary.wiley.com/doi/10.1111/ciso.12440) | M/H: abrupt obstruction; urban routes | Pr, Pl | Sudden stop and passenger emergence. |
| 10 | Bus stops, then pulls out into the flow. | U; bus-stop effects studied in [Delhi](https://www.sciencedirect.com/science/article/pii/S2046043016300946) | H/M: large occluder; bus corridors | Pe, Pr, Pl | Dwell, indicator uncertainty, broad merge. |
| 11 | Slow tractor-trolley occupies a faster road. | U | H/M: speed differential; rural routes | Pe, Pr, Pl | Long/slow vehicle and passing sight distance. |
| 12 | Overloaded vehicle has a protruding or unstable load. | U | H/M: strike/load loss; freight routes | Pe, Pl, Sa | True load envelope and shifting mass. |
| 13 | Pushcart moves at walking speed in the carriageway. | U; included in [SIH26037](https://www.sih.gov.in/sih2026PS) | M/M: vulnerable operator; markets | Pe, Pr, Pl | Pushcart silhouette, slow irregular path. |
| 14 | Cycle-rickshaw changes direction slowly and widely. | U | M/M: vulnerable rider; local routes | Pe, Pr, Pl | Three-wheel geometry and turning radius. |
| 15 | Animal-drawn cart shares the road. | U | M/L: slow, unpredictable; localized | Pe, Pr, Pl | Animal plus cart as linked bodies. |
| 16 | Traffic merges informally without lane alignment. | U; required context in [SIH26037](https://www.sih.gov.in/sih2026PS) | H/H: side conflict; mixed traffic | Pr, Pl, Sa | Negotiated gaps and non-lane trajectories. |
| 17 | Parked vehicle door opens or it pulls away. | U; **13,810 parked-vehicle collisions** are only a broad proxy, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: close strike; kerbside areas | Pe, Pr, Pl | Door sweep and start-from-rest. |
| 18 | Ambulance or fire vehicle approaches from behind. | U; priority rule in [government reply](https://www.pib.gov.in/Pressreleaseshare.aspx?PRID=2039979) | H/M: urgent passage; episodic | Pe, Pl, HMI | Siren/flasher localization and safe yield. |
| 19 | VIP convoy or escort changes surrounding traffic flow. | U | M/L: unexpected blockage; rare | Pe, Pr, Pl | Convoy spacing and externally stopped traffic; **no assumed emergency priority**. |

### B. Pedestrians

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 20 | Person crosses away from a marked crossing. | **722 interactions** studied at three Patna midblock sites, [paper](https://www.nature.com/articles/s41598-026-55112-9) | H/H: vulnerable user; urban roads | Pe, Pr, Sa | Crossing start and accepted vehicle gap. |
| 21 | Person crosses in stages, pausing between streams. | **26% rolling crossings** in that Patna sample, [paper](https://www.nature.com/articles/s41598-026-55112-9) | H/H: trajectory changes; busy roads | Pr, Pl, Sa | Stop–go pedestrian trajectory. |
| 22 | Group crosses with members moving at different speeds. | **54.8% group crossings** in that Patna sample, [paper](https://www.nature.com/articles/s41598-026-55112-9) | H/M: multiple conflicts; busy sites | Pe, Pr, Pl | Linked group that can split. |
| 23 | Pedestrian crosses against a red phase. | **3,608 of 8,089 red-phase arrivals** crossed in a 12-intersection study, [paper](https://www.sciencedirect.com/science/article/abs/pii/S0925753521004446) | H/M: cross-traffic conflict; signals | Pr, Pl, Sa | Signal phase and late crossing. |
| 24 | Child runs into the road near a school. | **1.4% reported running while crossing** in a survey of 497 children aged 12–15, [study](https://pubmed.ncbi.nlm.nih.gov/33614589/) | H/M: small, fast target; school zones | Pe, Pr, Sa | Child size, acceleration, occlusion. |
| 25 | Person walks on the road when footpath is blocked. | **59,409 pedestrians observed** in a Kolkata study of such behaviours, [paper](https://pubmed.ncbi.nlm.nih.gov/40266192/) | H/H: sustained exposure; urban streets | Pe, Pr, Pl | Longitudinal walking at road edge. |
| 26 | Vendor and customer step into the traffic path. | **59,409-person study** examines footpath vending encroachment, [paper](https://pubmed.ncbi.nlm.nih.gov/40266192/) | H/M: sudden entry; markets | Pe, Pr, Pl | Stall footprint and customer spawn points. |
| 27 | Bus passengers board or alight into the carriageway. | U; roadside bus-waiting behaviour in [Kolkata study](https://pubmed.ncbi.nlm.nih.gov/40266192/) | H/M: bus occlusion; bus corridors | Pe, Pr, Sa | Doors, stopped bus, hidden passengers. |
| 28 | Pedestrian raises a hand to request traffic stop. | U | H/M: ambiguous intent; local crossings | Pe, Pr, HMI | Gesture recognition and conservative yield. |
| 29 | Procession, baraat, or crowd occupies a road. | U; road closures appear in [Mumbai Traffic Police notices](https://mtperp.mahatrafficechallan.gov.in/PublicNotice.htm) | H/L: crowd exposure; episodic | Pe, Pl, Sa | Dense moving crowd and stop/turnback. |
| 30 | Elderly or mobility-impaired person crosses slowly. | U | H/M: long exposure; any crossing | Pe, Pr, Pl | Broad walking-speed and pause range. |

### C. Animals

The [Haryana Assembly answer](https://haryanaassembly.gov.in/wp-content/uploads/2023/01/14_13_US_1262_V4_signed.pdf) confirms **3,383 stray-cattle road crashes and 919 deaths over five years**. It does not distinguish posture or crossing pattern; those rows remain U. The claimed **August 2022 answer date is UNVERIFIED** from that PDF.

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 31 | Cattle stands or lies on the carriageway. | **3,383 cattle-related crashes** aggregate, [Assembly](https://haryanaassembly.gov.in/wp-content/uploads/2023/01/14_13_US_1262_V4_signed.pdf); posture U | H/M: large obstacle; regional | Pe, Pl, Sa | Standing/low body and safe stopping. |
| 32 | Cattle suddenly crosses the road. | U; cattle crash aggregate [Assembly](https://haryanaassembly.gov.in/wp-content/uploads/2023/01/14_13_US_1262_V4_signed.pdf) | H/M: sudden conflict; regional | Pe, Pr, Sa | Delayed dash from verge. |
| 33 | Herd spreads across both directions. | U | H/L: no free path; rural pockets | Pe, Pr, Pl | Multiple independently moving animals. |
| 34 | Buffalo enters or rests on a village road. | U | H/L: large mass; localized | Pe, Pr, Sa | Species size and slow-to-fast movement. |
| 35 | Dog darts from behind an obstacle. | U | H/M: abrupt swerve pressure; settlements | Pe, Pr, Sa | Small target and fast emergence. |
| 36 | Monkey moves across road or down from roadside. | U | M/L: sudden motion; hill/town pockets | Pe, Pr, Sa | Small erratic target and elevation. |
| 37 | Wild animal crosses a forest corridor. | U; wildlife crossings recognized by [NHAI](https://nhai.gov.in/nhai/sites/default/files/mix_file/HO-FAQ.pdf) | H/L: large/fast animal; corridor-specific | Pe, Pr, Sa | Limited sight distance and variable size. |

### D. Road geometry and surface

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 38 | Lane markings and road edge are absent. | **10,000 images** in [IDD](https://idd.insaan.iiit.ac.in/) represent unstructured roads; prevalence U | H/H: uncertain drivable space; broad ODD | Pe, Pl, Sa | Road versus safe fallback area. |
| 39 | Pothole requires steering or speed change. | **5,840 crashes, 2,161 deaths**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | M/H: damage/loss of control; widespread | Pe, Pl, Co | Hole depth, width, tire path. |
| 40 | Speed breaker is unmarked or irregular. | U | M/M: control upset; local streets | Pe, Pl, Co | Hump profile, visibility, suspension. |
| 41 | Broken shoulder or drop-off limits avoidance. | U | H/M: run-off-road risk; damaged edges | Pe, Pl, Sa | Edge height and no-go shoulder. |
| 42 | Bridge or culvert constricts road width. | **10,308 culvert-road crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf); narrowness U | H/M: little escape room; localized | Pe, Pl, Co | Structure width and opposing traffic. |
| 43 | Gravel, dirt, or unpaved surface changes grip. | U | M/M: slip risk; rural routes | Pe, Pl, Co | Variable friction and loose surface. |
| 44 | Waterlogging hides depth and road defects. | U; recognized in [NHAI monsoon notice](https://nhai.gov.in/nhai/sites/default/files/2025-06/NHAI_Press_Release-_NHAI-Takes-23-06-2025.pdf) | H/M: hidden hazard; monsoon routes | Pe, Pl, Sa | Water depth uncertainty and submerged edge. |
| 45 | Construction diverts traffic into a temporary path. | **9,425 road-work crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: altered geometry; project sites | Pe, Pl, Sa | Cones, barriers, opposing-flow diversion. |
| 46 | Sharp curve hides the onward road. | **58,626 curved-road crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/H: sight-limit conflict; network-wide | Pe, Pl, Co | Curvature and visible stopping distance. |
| 47 | Steep grade stresses braking or traction. | **5,094 steep-grade crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: control loss; hilly routes | Pl, Sa, Co | Grade, mass, brake/traction limits. |
| 48 | Ghat hairpin needs near-stop turning and shared width. | U | H/L: drop-off/opposing traffic; hills | Pe, Pl, Co | Tight radius, slope, opposing encroachment. |
| 49 | Narrow galli is shared with people and parked objects. | U | M/M: low-speed contact; older areas | Pe, Pl, Co | Vehicle clearance and frequent yielding. |
| 50 | Railway level crossing changes from open to closed. | **17,777 total crossings** reported for April 2024, [Railways report](https://rdso.indianrailways.gov.in/railwayboard/uploads/directorate/stat_econ/2025/Indian%20Railways%20Annual%20Report%20%20Accounts%202023-24%20-English.pdf); incidents U | H/M: train conflict; route-dependent | Pe, Pl, Sa | Gate, warning, track, queue and train state. |
| 51 | Median opening admits cross traffic unexpectedly. | U; median cuts recognized in [NHAI works manual](https://nhai.gov.in/nhai/sites/default/files/2023-06/NHAI_Works_Manual_2006.pdf) | H/M: side impact; divided roads | Pe, Pr, Pl | Hidden gap and turning vehicles. |
| 52 | Service road rejoins a faster carriageway. | U; service-road access in [NHAI manual](https://nhai.gov.in/nhai/sites/default/files/2023-06/NHAI_Works_Manual_2006.pdf) | H/M: speed mismatch; highways | Pr, Pl, Sa | Short merge and limited acceleration. |

### E. Junctions and rules

The following counts are **crashes at junction/control types**, not counts of unsafe manoeuvres. [MoRTH Tables 3.6–3.7](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf)

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 53 | Uncontrolled T-junction has negotiated priority. | **40,440 T-junction crashes**; **76,455 uncontrolled-crossing crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/H: crossing conflict; common type | Pr, Pl, Sa | Variable gap acceptance and yielding. |
| 54 | Four-arm junction has simultaneous conflicts. | **23,171 crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: multi-direction impact; junctions | Pr, Pl, Sa | All turn paths and cross traffic. |
| 55 | Y-junction creates ambiguous branch/priority. | **16,417 crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: crossing/route error; localized | Pe, Pl, Sa | Fork geometry and conflicting paths. |
| 56 | Staggered junction creates two quick conflicts. | **15,457 crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: repeated crossing; localized | Pr, Pl | Short intermediate storage and turns. |
| 57 | Roundabout users enter or exit irregularly. | **13,182 crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: circulating conflict; localized | Pr, Pl, Sa | Multiple entry/exit intentions. |
| 58 | Police officer directs traffic over the signal. | **9,068 police-controlled junction crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: authority ambiguity; episodic | Pe, Pl, HMI | Officer position and hand commands. |
| 59 | Cross traffic violates a red signal. | U; Indian intersection violations studied [here](https://www.sciencedirect.com/science/article/pii/S2095756418304409) | H/M: high-speed side conflict; signals | Pr, Pl, Sa | Late red entry despite ego green. |
| 60 | Stop sign, flashing signal, or stop line is unclear. | **5,673 stop-sign** and **7,747 flashing-signal** junction crashes, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf); ambiguity U | H/M: priority error; junction subsets | Pe, Pl, Sa | Visibility and conflicting interpretations. |
| 61 | Informal right-of-way evolves through mutual yielding. | U | H/H: uncertain intent; mixed junctions | Pr, Pl, HMI | Reciprocal yielding and deadlock escape. |

### F. Communication

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 62 | Horn can warn, request space, or express impatience. | U; meanings documented in [Chennai field study](https://www.research.ed.ac.uk/en/publications/a-bip-a-beeeep-and-a-beep-beep-how-horns-are-sounded-in-chennai-t/) | M/H: ambiguous cue; traffic | Pe, Pr, HMI | Direction, distance, competing horns. |
| 63 | Oncoming driver flashes headlights ambiguously. | U | H/M: mistaken yield; junctions/night | Pe, Pr, HMI | Flash timing and conflicting manoeuvre. |
| 64 | Driver/rider uses a hand signal. | U; [Kolkata Traffic Police guidance](https://kolkatatrafficpolice.gov.in/guidelines_for_drivers.html) recognizes hand signals | M/M: missed intent; mixed traffic | Pe, Pr | Visible pose versus actual turn. |
| 65 | Indicator is absent, left on, or contradicts motion. | U | H/H: false intent; everyday turns | Pe, Pr, Sa | Signal reliability and motion evidence. |
| 66 | Emergency siren and flasher require safe passage. | U; [government rule explanation](https://www.pib.gov.in/Pressreleaseshare.aspx?PRID=2039979) | H/M: urgent routing; episodic | Pe, Pl, HMI | Source localization and yield corridor. |

### G. Environment

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 67 | Heavy rain reduces visibility and tire grip. | **37,316 rainy-weather crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: sight/braking loss; monsoon | Pe, Sa, Co | Rain rate, spray, wet friction. |
| 68 | Fog or mist shortens detection range. | **34,266 foggy/misty crashes**, [MoRTH](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf) | H/M: late detection; seasonal/regional | Pe, Pl, Sa | Visibility range and sensor degradation. |
| 69 | Dust or smoke obscures a road section. | U | H/M: abrupt visibility loss; localized | Pe, Pl, Sa | Dense moving plume and safe slowdown. |
| 70 | Unlit night road offers little scene contrast. | U; low-light examples in **5,000-pair** [IDD-AW dataset](https://arxiv.org/abs/2311.14459) | H/M: missed hazards; unlit routes | Pe, Pl, Sa | Lux, lamp coverage and headlamp range. |
| 71 | Oncoming high beam overwhelms the camera/driver view. | U | H/M: temporary blindness; night | Pe, Sa | Saturation, recovery time, safe speed. |
| 72 | Low-angle sun creates forward glare. | U | H/M: lost contrast; time/location-specific | Pe, Pl, Sa | Sun angle, exposure and shadow. |
| 73 | Monsoon flood or deep water makes route impassable. | U; flood/waterlogging recognized by [NHAI](https://nhai.gov.in/nhai/sites/default/files/2025-06/NHAI_Press_Release-_NHAI-Takes-23-06-2025.pdf) | H/L: vehicle loss; seasonal | Pe, Pl, Sa | Rising depth and refusal/turnback. |
| 74 | Snow or ice alters grip on Himalayan routes. | U; snow examples in [IDD-AW](https://arxiv.org/abs/2311.14459) | H/L: low grip; regional | Pe, Sa, Co | Surface friction and stopping envelope. |

### H. Perception and localization traps

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 75 | Bus or truck hides a crossing person or rider. | U; pedestrian occlusion covered by [IDD-PeD](https://cvit.iiit.ac.in/research/projects/cvit-projects/iddped) | H/H: late VRU appearance; traffic | Pe, Pr, Sa | Occluder geometry and emergence. |
| 76 | Dense overlapping users cause missed tracks/IDs. | U; **10,000 images, 34 classes** in [IDD](https://idd.insaan.iiit.ac.in/) | H/H: missed actor; markets | Pe, Pr, Sa | Overlap, track swaps, uncertainty. |
| 77 | Jugaad or modified vehicle defeats familiar silhouettes. | U; **210 vehicle labels** in [FGVD](https://arxiv.org/abs/2212.14569) show appearance diversity | H/M: wrong envelope; localized | Pe, Pl | Odd geometry, loads, pose and scale. |
| 78 | Wet/reflected surfaces look drivable or hide edges. | U | H/M: false free space; rain/night | Pe, Pl, Sa | Specular reflection and water boundary. |
| 79 | Sign is missing where a turn or hazard needs warning. | **200 missing-sign scenes** in an [IIIT-H challenge](https://cvit.iiit.ac.in/ncvpripg2023/c4mtschallenge/) | H/M: route/priority error; local defects | Pe, Pl | No sign, map disagreement, conservative approach. |
| 80 | Hindi or regional-language road text must be read quickly. | U; English/Hindi/Telugu video in [RoadText-3K paper](https://cvit.iiit.ac.in/images/ConferencePapers/2022/Text_Tracking_in_road_videos_for_autonomous_navigation.pdf) | M/M: missed instruction; regional | Pe, Pl | Script, short exposure and text confidence. |
| 81 | Blurred, faded, or partly hidden sign is misread. | U; road-text challenges in [RoadText-3K](https://cvit.iiit.ac.in/images/ConferencePapers/2022/Text_Tracking_in_road_videos_for_autonomous_navigation.pdf) | H/M: wrong action; damaged signs | Pe, Sa | Blur, occlusion and uncertain classification. |
| 82 | GNSS/localization drifts in underpasses or dense streets. | U; illumination/occlusion localization challenges in [IDD-VPR](https://cvit.iiit.ac.in/research/projects/cvit-projects/iddvpr) | H/M: wrong path position; localized | Pe, Pl, Sa | GNSS loss, map drift, fallback localization. |

### I. Rare but consequential events

| # | Difficulty | Evidence | S/F and reason | Layers | Simulation must model |
|---|---|---|---|---|---|
| 83 | Cargo falls from a vehicle ahead. | U | H/L: sudden obstacle; episodic | Pe, Pr, Sa | Drop timing, bounce and evasive space. |
| 84 | Lead vehicle has a tyre burst and yaws or stops. | U | H/L: rapid multi-object conflict; episodic | Pr, Sa, Co | Yaw, debris and emergency braking. |
| 85 | Landslide or rockfall blocks a mountain road. | U; landslides recognized in [NHAI monsoon notice](https://nhai.gov.in/nhai/sites/default/files/2025-06/NHAI_Press_Release-_NHAI-Takes-23-06-2025.pdf) | H/L: large obstruction; hills/monsoon | Pe, Pl, Sa | Falling debris and no safe passage. |
| 86 | Tree or large branch falls onto the route. | U | H/L: sudden blockage; storms | Pe, Pr, Sa | Falling-object motion and stop decision. |
| 87 | Protest or temporary roadblock prevents passage. | U | M/L: route failure; episodic | Pe, Pl, HMI | Crowd/barrier, safe stop and reroute. |
| 88 | Stalled vehicle sits beyond a blind bend. | U | H/M: late obstacle; hill roads | Pe, Pl, Sa | Sight distance, stopping margin, oncoming lane. |
| 89 | Downed cable or pole crosses the road. | U | H/L: uncertain electrical/physical hazard; rare | Pe, Pl, Sa | Thin object as no-go region. |
| 90 | Crash scene, debris, and responders occupy the road. | U | H/L: people plus obstruction; episodic | Pe, Pr, Pl, Sa | Stopped vehicles, responders, safe bypass/refusal. |

### Formal ODD and scenario frameworks

| Source | Correct role |
|---|---|
| [ISO 34503:2023](https://www.iso.org/standard/78952.html) | Published hierarchical taxonomy and format for an ADS **operational design domain**. Use it to define where this system claims to work. |
| [BSI PAS 1883:2025](https://knowledge.bsigroup.com/products/operational-design-domain-implementation-of-bs-iso-34503-2023-guide) | Current guide to implementing ISO 34503. The [2020 PAS was withdrawn](https://knowledge.bsigroup.com/products/operational-design-domain-odd-taxonomy-for-an-automated-driving-system-ads-specification). |
| [ASAM OpenODD 1.0.0](https://www.asam.net/standards/detail/openodd/) | Machine-readable ODD description/exchange; not an Indian hazard list. |
| [SAE J3016](https://saemobilus.sae.org/standards/j3016_202104-taxonomy-definitions-terms-related-driving-automation-systems-road-motor-vehicles) | Driving-automation levels and terminology; not a scenario catalogue. |
| [ARAI-hosted AIS 191 ALKS draft](https://hmr.araiindia.com/api/AISFiles/Draft%20D1_AIS_191_ALKS_8194ad96-8889-444e-8c49-eb37a9906b91.pdf) | Draft ODD declaration for **automated lane keeping**, not a national unstructured-road taxonomy. |
| [TiHAN IIT Hyderabad testbed](https://tihan.iith.ac.in/infrastructure.html), [IIIT-H IDD](https://idd.insaan.iiit.ac.in/), [Indian scenario-crowdsourcing paper](https://saemobilus.sae.org/papers/crowdsourcing-indian-traffic-scenarios-adas-development-testing-2026-26-0046) | Indian test infrastructure, dataset and scenario-collection approach, respectively; none is a verified, exhaustive Indian ODD taxonomy. |

**Still UNVERIFIED:** national encounter rates for most individual manoeuvres, animal species and rare events; the claimed August 2022 date of the Haryana answer; and an authoritative, exhaustive India-specific ODD catalogue. The S/F ratings above are therefore **test-priority hypotheses**, to recalibrate with route-specific exposure data.
---

## 2. Competitor check: the “Indian AV test suite” claim

| Organisation or resource | What is documented | Access, scale, and limits |
|---|---|---|
| **WMG Safety Pool Studio, India work** | Warwick describes a free, multilingual, visual tool for crowdsourcing Indian traffic scenarios. It describes exports as **OpenDRIVE, OpenSCENARIO XML, and OpenLABEL**. The paper acknowledges support from **UKRI Future Leaders Fellowship MR/S035176/1 and the UK Department for Transport**. [Warwick paper](https://wrap.warwick.ac.uk/196298/1/WRAP-Crowdsourcing-Indian-traffic-scenarios-ADAS-development-testing-26.pdf) | **Indian scenario count: UNVERIFIED.** No named ARAI or iCAT partner was found in the paper; a wider partnership is **UNVERIFIED**. At the paper’s writing, external retrieval of Studio exports was still being implemented, and the authoring tool could not model an actor slowing or restarting after stopping. [Warwick paper](https://wrap.warwick.ac.uk/196298/1/WRAP-Crowdsourcing-Indian-traffic-scenarios-ADAS-development-testing-26.pdf) |
| **Safety Pool Scenario Database** | Its FAQ reports **over 250,000 scenarios globally**, stored at the *logical* level; it does not give an India subset. Its native description language is SPSDL. “Public” libraries mean available to authorised member organisations. [Database FAQ](https://docs.safetypooldb.ai/docs/faq) | The database advertises **credit-based access**; a public, free download of all scenarios is not established. [Safety Pool offering](https://www.safetypool.ai/solution-offering) WMG and Deepen AI are the founders; Warwick also identifies a UK Department for Transport project. [Warwick projects page](https://warwick.ac.uk/fac/sci/wmg/research/research-areas/safeautonomy/projects-initiatives/) |
| **ARAI** | ARAI explicitly lists an **“Indian driving scenario repository for ADAS functions.”** Its published workflow connects Indian traffic data, scenario digitisation, and simulation validation; a [2024 ARAI paper](https://saemobilus.sae.org/papers/synthetic-scenario-generation-real-road-data-indian-specific-adas-function-verification-validation-2024-26-0020) describes generating Indian ADAS scenarios from road data. [ARAI repository listing](https://www.araiindia.com/departments-laboratories/technology-group/intelligent-vehicle-technology), [ARAI validation workflow](https://www.araiindia.com/centre-of-excellence/intelligent-vehicle-technology-coe/adas-integrated-approach) | Repository count, file formats, public access, and whether it benchmarks a complete closed-loop planner: **UNVERIFIED**. ARAI also lists a physical [ADAS test track](https://www.araiindia.com/centre-of-excellence/intelligent-vehicle-technology-coe/adas-smart-city-track-for-indian-scenario); that is a separate facility. |
| **iCAT** | Its [ASPIRE portal](https://aspire.icat.in/) has a general automotive resource library. | A named Indian AV scenario library, scenario count, formats, or planning benchmark at iCAT: **UNVERIFIED** from the public material found. |
| **SimDaaS** | Advertises Indian scenario generation, a scenario library, variations, and **OpenSCENARIO 1.x/2.x** output. [SimDaaS scenario generation](https://simdaas.com/scenario-generation/) | Indian library count, downloadable catalogue, and price: **UNVERIFIED**. |
| **TiHAN, IIT Hyderabad** | [TiAND](https://tihan.iith.ac.in/TiAND.html) lists **15+ datasets overall**, including six terrestrial datasets, with access requests and a data-use agreement. Its [testbed](https://tihan.iith.ac.in/infrastructure.html) includes simulation facilities and road intersections. | These are documented datasets and facilities; a downloadable, executable **closed-loop Indian planning benchmark** is **UNVERIFIED**. |

**Format caution:** the Warwick manuscript prints “OpenSCENARIO XML 1.6,” while [ASAM lists 1.4.0 as the current XML version](https://www.asam.net/standards/detail/openscenario-xml/). Treat the manuscript’s *specific version number* as **UNVERIFIED** until an exported file is inspected.

**PPT implication:** retire **“first Indian AV test suite.”** A defensible *proposed contribution* is a **reproducible, composable closed-loop benchmark for unstructured Indian roads**, with published scenario parameters, planner baselines, coverage, and pass/fail metrics. Do not claim it is uniquely first: ARAI, Safety Pool, and SimDaaS already work on Indian scenarios. SIH26037 specifically asks for a closed-loop system tested on five Indian situations, so demonstrate that capability before expanding the catalogue. [SIH26037 statement](https://www.sih.gov.in/sih2026PS)

## 3. Top 25 build order

This is **my engineering priority**, not a measured frequency ranking. I weighted immediate collision risk, the [MoRTH 2023 casualty and road-feature evidence](https://morth.gov.in/backend/documents/uploaded/Road-Accident-in-India-2023-Publications.pdf), and direct coverage of the [five SIH26037 scenarios](https://www.sih.gov.in/sih2026PS). IDs refer to the previous 90-item catalogue. The last column names **one problem to solve or test**, not a claim that it has already been solved.

| Rank | ID | Difficulty | Hardest technical sub-problem |
|---:|---:|---|---|
| 1 | 38 | No markings or clear road edge | Infer a safe drivable boundary without lane geometry. |
| 2 | 2 | Two-wheeler seepage | Predict a rider’s lateral gap choice before overlap. |
| 3 | 20 | Midblock pedestrian crossing | Estimate crossing commitment from uncertain body motion. |
| 4 | 75 | Pedestrian or rider hidden by a bus/truck | Maintain a useful belief about an unseen road user. |
| 5 | 16 | Informal merge | Predict whether another driver will yield or close the gap. |
| 6 | 53 | Uncontrolled T-junction | Select a safe crossing gap without a signal or agreed priority. |
| 7 | 5 | Wrong-way vehicle | Detect counterflow early enough to preserve an escape path. |
| 8 | 6 | Abrupt lead-vehicle braking | Keep a safe stopping margin despite uncertain road friction. |
| 9 | 1 | Close cut-in | Predict the cut-in before the vehicle enters ego’s path. |
| 10 | 31 | Cattle standing or lying on road | Detect the animal’s full occupied space at distance. |
| 11 | 32 | Sudden cattle crossing | Handle abrupt motion when intent cues are weak. |
| 12 | 11 | Slow tractor-trolley | Decide whether passing is safe with limited opposing-road visibility. |
| 13 | 21 | Rolling or paused pedestrian crossing | Predict the next stop–go phase. |
| 14 | 76 | Dense, overlapping road users | Preserve tracks and free-space estimates through occlusion. |
| 15 | 39 | Pothole | Estimate whether its depth requires braking or avoidance. |
| 16 | 45 | Construction diversion | Identify the temporary drivable corridor. |
| 17 | 10 | Bus stop and pull-out | Predict bus re-entry while watching for people it hides. |
| 18 | 9 | Auto-rickshaw stopping for pickup | Detect stopping intent before hard braking begins. |
| 19 | 67 | Heavy rain | Estimate both visibility and grip for the same manoeuvre. |
| 20 | 68 | Fog | Set speed from the reliably visible stopping distance. |
| 21 | 70 | Unlit road at night | Detect vulnerable users within the effective headlamp range. |
| 22 | 46 | Sharp curve or hairpin | Couple limited sight distance to a feasible speed profile. |
| 23 | 61 | Negotiated right of way | Yield or proceed without unsafe assertion or indefinite deadlock. |
| 24 | 25 | Pedestrian walking in road | Separate continued roadside walking from a turn into ego’s path. |
| 25 | 52 | Service-road re-entry | Judge a closing mainline gap while controlling acceleration. |

The pedestrian priorities also have direct Indian observational support: the [Patna study](https://www.nature.com/articles/s41598-026-55112-9) documents rolling and group crossings; the [signalised-crossing study](https://www.sciencedirect.com/science/article/abs/pii/S0925753521004446) documents red-phase violations. Neither study establishes a national frequency for every item above.

## 4. Ten composable simulation families covering IDs 1–90

**PS key:** V = unmarked village road; U = unsignalled urban intersection; H = highway merge with slow vehicles; M = dense market; C = sudden cattle crossing. These are the [five situations named in SIH26037](https://www.sih.gov.in/sih2026PS). Each row below is a **proposed test template**: vary actor speed, starting position, intent, visibility, and timing within the listed base road and weather.

| Family | Catalogue IDs covered | Base road + parameterised actors + weather | PS use |
|---|---|---|---|
| **F1 Village mixed traffic** | 11–15, 31, 33, 34, 38, 43, 49 | Unmarked village road; tractors, carts, cycles, roadside cattle; dry/rain | V, C |
| **F2 Market seepage** | 1–4, 9, 26, 28, 29, 76, 77 | Narrow market street; bikes, autos, vendors and crowd; daylight/night/rain | M, U |
| **F3 Pedestrian and bus corridor** | 10, 17, 20–25, 27, 30, 75 | Urban bus-stop road; buses, walkers and crossing groups; dusk/rain | M, U |
| **F4 Junction negotiation** | 7, 8, 16, 53–61, 63–65 | Uncontrolled junction; cross traffic, turners and informal signals; day/night | U, H |
| **F5 Highway approach and merge** | 5, 6, 18, 19, 52, 66 | Highway plus service-road entry; slow trucks, wrong-way and merging vehicles; clear/fog | H |
| **F6 Animal movement** | 32, 35–37 | Village or peri-urban road; cattle, dogs and other animals with varied onset; day/dusk/rain | C, V |
| **F7 Surface and terrain** | 39–42, 46–48, 51 | Rural road or ghat curve; oncoming traffic, holes and edge defects; dry/wet/fog | V, C |
| **F8 Disrupted road layout** | 44, 45, 50, 79–81 | Construction or crossing approach; workers, queues, temporary signs and barriers; clear/rain/night | V, U, H |
| **F9 Visibility and sensing** | 67–74, 78, 82 | Reusable overlay on a village, market, junction or highway base; rain, fog, dust, glare, darkness or flooding | V, U, H, M, C |
| **F10 Acute incident** | 62, 83–90 | Two-lane approach; stopped vehicle, fallen load, tyre event or road blockage; clear/storm/dusk | V, U, H |

The ID sets assign **all 90 previous items once**. Cross-family tests should combine them—for example, **F2 + F3 + F9** creates a rainy market with bike seepage and a pedestrian emerging from behind a bus. That composition is a proposed design method; its value must be shown with coverage and outcome metrics.

**Still unverified:** Safety Pool’s India-only scenario count; a current public download of Studio’s Indian exports; the exact version of a real Studio export; any ARAI/iCAT partnership with the Warwick India work; ARAI repository count, access and formats; an iCAT AV scenario library; SimDaaS Indian scenario count and price; and whether any existing public resource already matches the complete proposed closed-loop benchmark.