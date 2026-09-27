PHASE P16 — INDIAN TRAFFIC NUMBERS (SIH26037, Indian-road autonomous driving system).

Purpose: these numbers will (a) set the behaviour of the simulated Indian road users (CARLA/SUMO/Simulink
actors) and (b) set the priors of our planner's per-actor "response propensity" belief, and (c) appear on
a national-round PPT read by expert judges. A wrong number is worse than a missing one.

RULES (non-negotiable):
- I (Claude) will open every URL you give me and check the exact number against the exact sentence/table.
- Every number needs: value, unit, city/site, sample size (n), year of data, road/junction type, and the
  exact link (DOI or publisher page; PDF if open). Quote the sentence or table/row it comes from.
- Primary sources only (peer-reviewed papers, government reports, IRC codes). No blogs, no AI summaries.
- If no Indian number exists for an item, write "NOT FOUND" and say what the closest thing is. Do not
  substitute a foreign number without labelling it FOREIGN.
- Label each line FACT (read in source) or JUDGMENT (your inference). Mark UNVERIFIED if you could not
  open the full text.
- Prefer Indian data; note when a number is site-specific and should not be generalised.

ALREADY IN HAND (do NOT re-search, but flag if any is wrong):
- Two-wheeler seepage lateral gap: observed mean 0.906 m; SUMO default minGap 2.5 m; calibrated model 0.609 m
  (ScienceDirect S1389128626005220, IDD/TIAND, 13,219 events).
- Patil & Sangole (Maharashtra T-junctions): ~22% of right-turning two-wheelers accept a 3 s gap vs a
  two-wheeler, ~10% vs a car (Springer s40534-014-0057-8).
- Kanagaraj et al., Chennai T-junction merges: group 37%, forced 26%, normal 21%, cover 16%
  (ScienceDirect S1369847815000224).
- Kanpur unsignalised: pedestrian critical headway 3.76 s mean, ~38% rolling-gap crossings
  (ScienceDirect S1369847820304927).
- Patna midblock: 722 interactions, 26% rolling, 54.8% group crossings (Nature Sci Rep s41598-026-55112-9).
- Red-phase pedestrian crossings: 3,608 of 8,089 arrivals, 12 intersections (S0925753521004446).
- MoRTH 2023: wrong-side/lane-indiscipline 5.5% of deaths (category is combined).
- Haryana Assembly: 3,383 stray-cattle crashes, 919 deaths over 5 years.

WHAT TO FIND (six items):
1. PEDESTRIAN YIELD RATE: share of Indian drivers who yield/slow for a crossing pedestrian, ideally by
   vehicle class (car, bus, two-wheeler, auto). Midblock and unsignalised. Also driver yielding vs speed.
   (Known lead: doi 10.1016/j.iatssr.2020.06.001 — open it and extract any actual numbers.)
2. CRITICAL GAPS BY VEHICLE CLASS: Mohan & Chandra, "Investigating the Influence of Conflicting Flow's
   Composition on Critical Gap under Heterogeneous Traffic Conditions" — find the publisher version
   (journal, year, DOI) and confirm Table 10 values: right turn major/minor: 2W 2.5/3.5 s, 3W 2.7/3.7,
   small car 2.7/3.8, bus 3.6/5.5, truck 3.8/5.7. If the publisher page is paywalled, find any open copy
   or another paper that reprints them. Also 1–2 other Indian per-class critical-gap sources, and the
   IRC value if IRC:SP:41 or Indo-HCM (CSIR-CRRI 2017) gives one.
3. TWO-WHEELER LATERAL GAPS: besides seepage mean, lateral clearance by speed and by the pair of vehicle
   classes (2W-car, 2W-bus, 2W-2W); lateral shift frequency. Indo-HCM or Indian papers.
4. CATTLE ON ROAD FREQUENCY: any Indian count of animals per km or per hour on roads, animal-involved
   crash share nationally (MoRTH has "animal" as an object/cause? check), stray cattle counts
   (Livestock Census 2019 stray cattle number), any per-state road-cattle survey.
5. WRONG-WAY SHARE: share of vehicles observed driving wrong-way on Indian roads (observational counts at
   sites, not only crash share); MoRTH's separate wrong-side crash/death figure if the report splits it.
6. SPEEDS IN MIXED TRAFFIC: free-flow and typical speeds by class (2W, car, auto, bus, truck, tractor,
   cycle, pedestrian walking speed) on Indian urban roads, village/rural roads, and highways; Indo-HCM
   is the obvious source. Also Indian pedestrian walking speed (mean, 15th percentile) and cattle
   walking speed if any source exists.

OUTPUT FORMAT (markdown):
- One table per item: | Number | Unit | Site / n / year | Road type | Source (link) | Quote or table ref | FACT/JUDGMENT | Verified full text? |
- Then "How to use in the sim" (one line per item, JUDGMENT).
- Then "NOT FOUND / UNVERIFIED" list.
- Then "Corrections to the ALREADY IN HAND list" (if any).
Keep it tight. No padding.
