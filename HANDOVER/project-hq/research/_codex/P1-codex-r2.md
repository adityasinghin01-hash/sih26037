## 1. Corrections to the pedestrian evidence

| Claim | Check |
|---|---|
| **3,608 of 8,089 red-phase arrivals** | **Verified, but the counts are in the paper’s body, not its abstract.** The abstract says: “The study results show that approximately 44.6% of pedestrians arriving during the red phase violate the signals.” The body gives 8,089 arrivals and 3,608 violations. This is the [Kumar and Ghosh signalised-crossing study](https://www.sciencedirect.com/science/article/abs/pii/S0925753521004446), separate from the [Patiala study reporting 8,205 conflicts and 2,495 pedestrians](https://link.springer.com/article/10.1007/s42452-025-06945-y). |
| **Patna: 722 interactions; 26% rolling; 54.8% group crossing** | **Verified.** The [Scientific Reports abstract](https://www.nature.com/articles/s41598-026-55112-9) states that three Patna locations yielded 722 pedestrian–vehicle interactions. Its next sentence is: “Field observations show that 26% of pedestrians adopted rolling crossing behavior, while 54.8% crossed in groups.” |

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