# SIH 2026 — Idea Funnel Results

Scored against the funnel in `~/.claude/projects/-Users-aditya/memory/hackathon-master-criteria.md`.
Full PS dataset: `all-226-problem-statements.csv` (226 PS, 18 themes).
Idea submission deadline: **20 Sept 2026**.

## Scoring method

Seven axes, each 0–10, overall = flat average (reproducible, no hidden weighting):

| Axis | Meaning |
|---|---|
| **Prob** | Is the problem real and measured by a credible published source? |
| **User** | Is the target user base precise, nameable, countable? |
| **Demo** | Is there a visible artifact a judge can watch work live? |
| **Judge** | Can a generalist judge get problem + cleverness in 60 seconds? |
| **Novel** | Post-competitor-sweep novelty. Never scored before the sweep. |
| **Feas** | Can WE get the data / access / validation needed? |
| **Imp** | Scale x severity, tied to the precise user base |

**Hard rule: any axis at or below 4 = BLOCKED, regardless of average.** A fatal axis is a
kill-check failure and an average must never mask it.

**Honesty rule** (`scoring-honesty-rule.md`): no number without evidence behind it. If a
competitor sweep has not run, the PS is marked NOT SCORED rather than estimated. Novel and
Feas are scored last, after the sweep — they are the two axes most prone to inflation.

---

## BATCH 1 — SIH26001–26025

### Survivors

| PS# | Name | Prob | User | Demo | Judge | Novel | Feas | Imp | Overall |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| **26011** | 3D ULPIN / vertical property mapping | 8 | 9 | 8 | 9 | 6 | 6 | 8 | **7.7** |
| **26001** | Landslide early warning, NER | 9 | 7 | 8 | 8 | 5 | 7 | 9 | **7.6** |
| **26002** | NER accessibility / cut-off villages | 8 | 7 | 7 | 8 | 5 | 7 | 8 | **7.1** |
| 26017 | Land acquisition delay prediction | 10 | 8 | 5 | 7 | 6 | **3** | 9 | **BLOCKED** |

**Score corrections made 23 Aug 2026** after Aditya's instruction not to inflate. Original
pass gave 26011 a 9.0; corrected to 7.7 because:
- Novel 8 -> 6: no evidence found that nobody is building this. Maharashtra is issuing VPCs
  now, so *someone* has a system for new projects. "Existing buildings are unserved" is
  inference, not verified absence.
- Feas 8 -> 6: approved building plans / floor plans are **not public**, and land-share
  computation needs them. A synthetic-data demo works; real data access is unproven.

26002 was originally scored 7.4 **before its solution space was swept at all** — only the
problem had been searched. Post-sweep it lands at 7.1.

#### 26011 — 3D ULPIN Generation & Vertical Property Mapping (Min. of Rural Development, SW)
Top candidate of the batch.
- Land records were designed for fields, not towers. A flat owner has no documented right
  to the land beneath the building — the record names the builder or society.
- **Maharashtra's Vertical Property Card went live 1 Jan 2026**, mandatory for all new flat
  registrations; existing societies may apply until Dec 2027 for Rs 500. Nagpur has ~45,000
  units mapped under a Svamitva vertical-7/12 pilot.
- New MahaRERA projects get the card automatically from registration data. **Existing
  buildings require "digital mapping of existing structures" — not automated by anyone found.**
- Components all mature, composition absent: footprint extraction is solved and open source
  (its4land QGIS plugin, U-Net/DeepLabv3, YOLOv8); ULPIN deployed (14-digit, lat/long,
  ECCMA/OGC, AP at 100%); LADM ISO 19152 is the 3D cadastre standard but **Part 6
  (implementation) only commenced late 2025**.
- Open risk to resolve: access to approved building plans.

#### 26001 — Landslide EWS, NER (MDoNER, SW)
- Incumbents: IIT Mandi's **iIoTs** startup (3-hour warning, claimed 99%) but on **60 ground
  sensors in Himachal**; IIT Delhi's free national susceptibility map; GSI national EWS
  programme; Amrita deployments in Western Ghats + NE.
- Gap: static susceptibility (the *where*) is free and national; dynamic sensor networks
  (the *when*) exist only where instrumented, and NER is largely uninstrumented.
- Angle: sensor-free dynamic warning from free satellite rainfall (GPM/IMERG) + susceptibility
  + InSAR slope creep.
- Risk: disaster PS attract many teams; a judge may see several landslide projects.

#### 26002 — NER Logistics & Accessibility (MDoNER, SW)
- Reframed from the vague PS title to: **"which villages are cut off right now, and for how long."**
- Evidence current: Manmao–Changlang highway collapse, Bailey bridge over Phee Khola washed
  away in North Sikkim, villages isolated across Arunachal/Assam/Nagaland (Jun–Aug 2026).
- Sweep result: the routing problem is a **mature academic field** (disrupted-network online
  routing, diversion-route vulnerability, arc routing for repair crews) but **no commercial
  product for this use case was found**. CDRI + MoRTH have a policy-level Disaster Management
  Plan, not a product.
- Buildable on public OSM road networks + disaster feeds. Pairs naturally with 26001.

#### 26017 — BLOCKED on Feasibility
Best numbers in the batch: land acquisition causes **35% of all infrastructure project
delays**; 773 NH projects / 28,432 km / **Rs 2.71 lakh crore** delayed; cost rose Rs 0.80
cr/hectare (FY13) to Rs 3.5+ cr/hectare. Clear payer (NHAI).
**Blocker:** Bhoomi Rashi already exists (1,467 NHAI projects, PFMS-integrated, e-Gazette).
It is a processing portal, not predictive — so the PS gap is real — but the case-level
historical timeline data needed to train a predictor sits inside it. Unblock only if that
data proves publicly obtainable.

### Killed — Batch 1

| PS# | Killed by |
|---|---|
| 26021 Honey Chain | NAFED blockchain honey traceability portal + Madhu Kranti Portal + IIT Delhi/Srijan study + TraceX, FoodTraze, Honeytrail |
| 26005 Solar cold storage | Ecozen (EcoFrost, $6M Series A, 70k farmers), Inficold (ColdVault PCM, 19 states) |
| 26008 Conveyor belt | Ripik.ai (Indian), Falconix, iFactory — 95% accuracy, deployed, 4–8 month payback |
| 26007 Mine vehicle fog | Hexagon Mining, Wabtec, MineSafeCAS, YUWEI; ISO Level 7/8/9; radar already works in fog |
| 26024 Coal mine compliance | Coal India + ISRO NRSC partnership building exactly this |
| 26025 Mine subsidence | PS is Hardware; Coal India/ISRO already building satellite version. (Correction: my first pass wrongly said "cannot validate" — Sentinel-1 InSAR is free and Indian coalfields are well published: Raniganj −21.18 mm/yr, Jharia, Talcher, Korba) |
| 26010 Rural land survey | SVAMITVA nearly complete — 3.26 lakh villages surveyed, 3.06 crore property cards, full coverage targeted Jul–Aug 2026 |
| 26016 / 26018 / 26019 | Bhoomi Rashi and DILRMP occupy these; 26019 has no precise deliverable |
| 26020 Khadi charkha | Solar charkha already gives 300% output, artisan income Rs 140 -> Rs 350/day, KVIC-deployed; Ambar Charkha iterating since 1954 |
| 26003 Dementia gaming | Crowded elder-care (Emoha, KITES, Antara, Primus — killed in this same lane at Hack4Crown) + fails ChatGPT test |
| 26004 Osteoarthritis / 26009 Manganese | No obtainable ground truth to validate — the Tenable failure mode |
| 26006 Freight/vessel chartering | Judge-legibility failure (shipping jargon) + Baltic Exchange data is paid |
| 26013 / 26014 / 26015 / 26023 | Abstract ETL or platform work with no visible artifact, or needs internal government/company data |
| 26012 Drone parcel mapping | Not standalone — footprint extraction is a solved CV task (Esri ships it). Survives only as a component of 26011 |
| 26022 Agarbatti drying | Precise and tangible but low innovation ceiling; KVIC programmes exist |

---

## BATCH 2 — SIH26026–26050

**Result: ZERO survivors above 7.0.** This is an honest null result, not a failure to look.
Batch 2 is dominated by (a) hardware we cannot validate, (b) defence/lab equipment,
(c) software categories with funded Indian incumbents.

### Best of a weak batch

| PS# | Name | Prob | User | Demo | Judge | Novel | Feas | Imp | Overall |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 26034 | Legal Metrology label compliance | 6 | 8 | 7 | 6 | 5 | 7 | 5 | **6.3** |
| 26036 | Weighing instrument verification | 6 | 8 | 5 | 5 | **4** | 5 | 6 | BLOCKED |
| 26048 | iKwath smart Kadha maker | 4 | 7 | 8 | 7 | 6 | **4** | 3 | BLOCKED |
| 26035 | NAWI test report generation | 5 | 8 | 4 | **4** | 6 | 5 | 4 | BLOCKED |

**26034** is the only one worth keeping on a reserve list. LM (Packaged Commodities) Rules
2011 Rule 6 mandates declarations (manufacturer, commodity, net quantity, mfg date, MRP,
consumer complaint contact); penalty up to Rs 25,000 per director. Sweep found **ArtworkFlow**
does pre-print artwork proofing (font-size measurement against LMPC), and compliance
consultancies (S.S. Rana, CliniExperts, Diligence) do it manually — but **post-market physical
package verification by an inspector does not appear productized**. Weaknesses: a multimodal
LLM does much of this (ChatGPT test pressure), and Rs 25,000 is a small penalty, so per the
"who pays for the failure" filter it creates little budget.

### Killed — Batch 2

| PS# | Killed by |
|---|---|
| 26031 Onion grading | **Intello Labs** works on onion specifically; Praman platform e-auctions onion with quality assaying, ~$40M monthly GTV, 95%+ accuracy vs ~70% manual, 15 min -> 2 min. AgNext also active |
| 26038 Diabetic retinopathy XAI | **Remidio Medios DR AI is CDSCO-approved** (India's first ophthalmic AI), deployed at Aravind with 50+ health workers; EyeArt offline; Forus 3nethra in public health centres; 5 AI companies (4 Indian) already benchmarked |
| 26028 Train ETA | ixigo claims ~100% accuracy at en-route stations in 95% of cases; RailYatri ML ETA; NTES official; RSTGCN (arXiv 2510.01262) railway-specific delay GCN |
| 26027 Block planning | Optym, DELMIA Rail Planning, MultiRail (Oliver Wyman), Hitachi Energy all sell track-possession optimization; also needs IR-internal data |
| 26032 Procurement scheduling | MP e-Uparjan (slot booking + token generation), Punjab Anaaj Kharid, Haryana e-Kharid (400+ mandis, 11 lakh farmers), Meri Fasal Mera Byora. Note: The Tribune reports "portal raj" *hindering* farmers — the real gap is the digital-literacy barrier, which needs API access to state portals we cannot get |
| 26041 AR vocational safety sim | TCS whitepaper on Indian mining immersive tech; Yeppar, CHRP-India, DevDen all sell commercial VR mining safety training |
| 26033 Intermediaries / farmer earnings | The most crowded lane in Indian agritech (eNAM, DeHaat, Ninjacart, WayCool, AgroStar) |
| 26042 Vernacular translation for education | Fails the ChatGPT test outright; Bhashini is the government incumbent |
| 26045 Ayurveda IP RAG assistant | Fails the ChatGPT test — "multilingual RAG assistant" is definitionally what a frontier model plus retrieval does |
| 26046 Ayurveda CTMS | GCP/CDISC/FHIR-compliant CTMS is a regulated enterprise category (Medidata, Veeva, OpenClinica). Feasibility fatal |
| 26047 Patient case-taking | Crowded EMR space, low novelty |
| 26043 Crowdsource societal challenges | Vague, no precise deliverable |
| 26044 Academia-industry skill portal | Killed in this same lane at Hack4Crown — Skill India Digital Hub already ships NCVET credentials into DigiLocker with a QR portable CV |
| 26037 Autonomous vehicles, Indian roads | Cannot test a real vehicle; simulation-only demo is a research exercise. Feasibility fatal |
| 26026 Narcotics/explosives quadruped | Hardware + regulated substances we cannot obtain for testing |
| 26029 / 26030 MCB & cable test rigs | Lab test automation, needs an actual accredited test lab |
| 26039 Underground mine safety | Hardware, DGMS domain, cannot validate in a real mine — Tenable failure mode |
| 26040 Water purification/monitoring | Hardware, crowded IoT water-quality space |
| 26049 / 26050 DRDO high-altitude & anti-drone | Defence hardware, cannot validate without Ladakh-condition test facilities |

---

## BATCH 3 — SIH26051–26075 (DRDO, MoSPI, MoES)

**Result: ZERO survivors.** Best score in the batch was 26056 at ~5.4. Two structural
causes, both worth carrying forward.

### Best of the batch (all blocked)

| PS# | Name | Prob | User | Demo | Judge | Novel | Feas | Imp | Verdict |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 26056 | Airfare price index for CPI | 6 | 7 | 5 | 6 | **4** | 5 | 5 | BLOCKED |
| 26073 | AWS sensor anomaly detection | 6 | 7 | 5 | 5 | **4** | 5 | 5 | BLOCKED |
| 26071 | Heavy rainfall EW + inundation | 8 | 7 | 7 | 8 | **4** | **4** | 8 | BLOCKED |
| 26051 | Shelter thermal comfort model | 5 | 6 | 6 | 5 | **4** | 6 | **4** | BLOCKED |

### Killed — Batch 3

| PS# | Killed by |
|---|---|
| **26074** Panchayat-level downscaling | **Already shipped by the government.** IMD + Ministry of Panchayati Raj launched Gram Panchayat-Level Weather Forecast on **24 Oct 2024** — hourly forecasts live at GP level via Mausamgram and the Meri Panchayat app. IMD forecasts at 12 km, piloting 3 km, targeting 1 km. GKMS runs 130 AMFUs across 127 agro-climatic zones. This looked like the batch's best candidate on paper and died on the sweep |
| 26070 Cyclone pattern ID | Saturated: Dvorak (30+ yrs), NASA **DeepTI**, **AiDT** at 7.7–8.2 kt global RMSE, attention-based rapid-intensification benchmarks, Dvorak-inspired interpretable ML |
| 26066 OceanEmbed subsurface temp | Saturated academic field — arXiv 2605.00860, RS 14133198, RS 17122005, LSTM thermohaline, ERA5-forced AI reconstruction, ESSD "Seeing through the Sea with Satellites", Neural-Mean Vecchia GP for Argo. Data is free (Argo + satellite SST/SSH) but novelty is gone |
| 26071 Rainfall/inundation EW | **C-Flood** covers Godavari/Tapi/Mahanadi with 2-day village-level inundation forecasts; IMD district warnings 4x/day; IIT Bombay + city agency doing 90-min radar nowcasts for Mumbai; Chennai/Mumbai live, Bengaluru/Kolkata planned. Real coverage gap exists beyond the big cities, but urban drainage network data is municipal and not public — Feas 4 |
| 26072 Thunderstorm/lightning nowcast | Same occupied space as 26070/26071 — IMD already nowcasts |
| 26073 AWS anomaly detection | IMD monitors AWS quality round-the-clock at Pune Central Receiving Servers with built-in QC; WMO QC guidelines exist; LSTM-autoencoder flatline detection already published. (Real pain is documented — Mungeshpur Delhi reported 52.9°C in May 2024 from a sensor running 3°C hot — but the method space is taken and raw IMD feeds are not public) |
| 26056 Airfare price index | **MoSPI is already doing it.** The new CPI series (base year 2024, expected Q1 FY2026) will use web-based platform data for airfares, telecom and OTT across 12 cities >25 lakh population. US BLS airline-fare CPI methodology is public and decades old |
| 26068 WeatherGPT | Fails the ChatGPT test definitionally |
| 26069 National weather big-data platform | Infrastructure work, vague scope, no visible artifact |
| 26075 CAPACITY CONNECT LMS | Generic learning-management portal, zero novelty |
| 26067 3D ocean visualization | Occupied by NOAA, Copernicus Marine, INCOIS viz platforms |
| **26059–26063** Polar block | **Impact fatal.** India operates two active Antarctic stations (Maitri, Bharati). Precise user base, but a few hundred personnel and roughly one expedition a year — station management, energy, logistics and outreach portals for that scale cannot carry an SIH win |
| 26057 Marine debris sonar / 26058 sonar payload / 26064 seafloor sensor / 26065 ocean platform | Need sonar/AUV hardware and at-sea validation we cannot obtain — the Tenable failure mode |
| **26052–26055** DRDO block | Data-locked. ANC needs defence noise corpora; 2.5D Lidar needs the sensor; UAV aero-piston digital twin needs engine telemetry; Electronic Warfare scan is classified. Feas 1–4 across the board |

### Structural lesson — apply to all remaining batches

Two ministry types are systematically bad hunting grounds, for opposite reasons:

1. **Technically strong, well-funded ministries have already built it.** MoES/IMD is the
   clearest case — supercomputing, AI forecasting, panchayat-level products, C-Flood,
   Mausamgram. Every plausible idea in their block was already shipped or is in flight.
   ISRO likely behaves the same way.
2. **Security/defence ministries are data-locked.** DRDO, NTRO and MHA can state a real
   problem, but the data needed to build or validate is classified or internal.

**The productive hunting ground is the inverse: ministries with genuine operational problems
and low internal technical capacity** — Rural Development, Social Justice & Empowerment,
MSME, Cooperation, Consumer Affairs, and state governments. Batch 1's three survivors all
came from exactly there (MDoNER x2, Rural Development x1). Prioritise those blocks in the
remaining batches and treat MoES/ISRO/DRDO/NTRO as low-yield.

---

## BATCH 4 — SIH26087–26111 (Cooperation, Social Justice, Petroleum, MoSPI, AICTE, Consumer Affairs, Dairying)

Taken out of sequence deliberately: per the Batch 3 lesson, this is the densest block of
low-technical-capacity ministries in the list, so it should have been the richest ground.

**Result: ZERO survivors above 7.0.** Best is 26100 at 6.4 (reserve).

### The near-miss worth recording — 26102 (MPLAD fraud detection)

Provisionally scored **7.1–7.6** and looked like a finalist, then died on the final sweep.
Recording the whole arc because it is a clean demonstration of scoring Novel last.

What made it look strong:
- MPLADS-eSAKSHI portal (mplads.mospi.gov.in, live since 1 Apr 2023) publishes real-time
  works and expenditure data — **a genuinely public dataset**
- CAG documented irregularities: ineligible works, encroachment, **non-existence of some
  assets**, diversion of use, works awarded to ineligible trusts, excess payments,
  substandard construction. Rs 489 crore of irregularities found in one state alone
- The import move looked excellent: cross-check claimed works against satellite imagery to
  verify the asset physically exists. Visual, demoable, damning

**What killed it:** that exact technique is already operational at national scale.
**GeoMGNREGA** — MoRD + NRSC/ISRO + NIC MoU signed Jun 2016, geotagging live since Sept
2016, **2.9 crore assets geotagged**, mandatory within 30 days of completion since Apr 2017,
validated by block-level GIS Asset Supervisors, approved by state nodal officers, published
on Bhuvan. ISRO already runs multi-temporal high-resolution EO analysis over MGNREGA works,
and Bhuvan "Yuktdhara" plans new works from RS/GIS.

So the honest read: extending a proven, operational verification stack from MGNREGA to
MPLADS is an **administrative action, not an invention**. A judge would say "then just
extend GeoMGNREGA." Novel drops to 4 -> BLOCKED.

| PS# | Name | Prob | User | Demo | Judge | Novel | Feas | Imp | Verdict |
|---|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 26100 | GeM bid compliance verification | 7 | 8 | 6 | 6 | 5 | 7 | 6 | **6.4** reserve |
| 26102 | MPLAD anomaly/fraud detection | 8 | 8 | 7 | 8 | **4** | 6 | 7 | BLOCKED |
| 26109 | Bovine mastitis prediction | 8 | 8 | 6 | 7 | **4** | **4** | 7 | BLOCKED |

**26100** is the only keeper-adjacent item. CCI penalised **HP India and resellers in July
2026** for cartelisation/bid rigging on GeM via selective Manufacturer Authorisation Forms.
DPIIT's OM P-45014/33/2021-BE-II documents common "restrictive and discriminatory conditions
against local suppliers" that breach the PPP-MII Order. Product = scan a draft tender against
that documented rule set before publication. GeM tenders and the DPIIT list are both public.
Passes the no-adversarial-products rule because the buyer is self-checking, not being exposed.
Held back by ChatGPT-test pressure and no verified absence of competitors.

**26109 mastitis** had the best raw number in the batch — **Rs 6,000 crore/year** in Indian
dairy losses, Rs 1,390 per lactation (49% milk value, 37% vet costs). Killed anyway: ML
prediction from milk yield + rumination time + electrical conductivity is already published,
infrared thermography for udder health is published, precision-dairy sensors are commercial,
the PS is tagged Hardware, and Indian smallholder dairy has no sensor data to train on.
(Note: one source claims "US$98,228 million" in Indian mastitis losses — that is an obvious
error, roughly 3x India's entire dairy sector. **Do not use it.** Use Rs 6,000 crore.)

### Killed — Batch 4

| PS# | Killed by |
|---|---|
| 26092 Scheme matching | **myScheme** is the official GoI portal (launched Jul 2022, MeitY, **4,700+ schemes**) doing exactly demographic -> eligible-scheme matching; plus SchemesForMe, MyBharat finder |
| 26104 Voice cloning detection | **Pindrop Pulse** claims 99% accuracy across billions of calls; Reality Defender; 8+ platforms in 2026 roundups; ASVspoof is a standing academic challenge |
| 26111 Feed/silage quality | AgNext **Qualix** does spectroscopy+AI quality testing; NIR feed analysis has been standard in commercial labs for years; portable NIR silage dry-matter published |
| 26105 Cyber risk quantification | Safe Security (Indian, well funded), Axio, Kovrr; FAIR is the standard model |
| 26106 Email threat forensics | Proofpoint, Mimecast, Abnormal Security |
| 26107 / 26108 BIS standards assistant | RAG assistant — fails the ChatGPT test; **BIS standards are paywalled**, so the corpus is also a data blocker |
| 26101 iGOT Karmayogi learning platform | MCQ/quiz generation is definitionally LLM work; also needs iGOT integration (government rail) |
| 26088 Multilingual governance chatbot | Fails the ChatGPT test outright |
| 26090 Artisan cataloging / 26091 micro-entrepreneur advisory | Okhai, GoCoop, Amazon Karigar occupy artisan commerce; advisory fails the ChatGPT test |
| **26093 / 26094** Trauma & mental-health assessment for atrocity victims | **Blocked on validation and ethics.** We cannot clinically validate a distress-prediction model, and the population is vulnerable enough that a false negative causes real harm. Not a hackathon-appropriate build |
| 26097 Livelihood/NSQF voice assistant | Skill India Digital Hub already ships NCVET credentials into DigiLocker with a QR portable CV — killed in this same lane at Hack4Crown |
| 26099 CPSE material code harmonisation | Needs internal CPSE master data |
| 26110 Milk chilling can | Promethean Power, Inficold occupy milk chilling |
| 26087 Cooperative ERP / 26089 gig platform / 26095 inspection app / 26096 heritage archive / 26103 project monitoring | Generic platform/portal builds, no novelty, no distinctive artifact |
| 26098 Artillery fuze | Defence hardware, cannot validate |

---

## BATCH 5 — SIH26112–26136 (Autodesk, MRPL, Oil India, BEL, Maharashtra)

**Result: ZERO survivors, and nothing even reaching reserve.** Best in batch ~5.0.

### Killed — Batch 5

| PS# | Killed by |
|---|---|
| 26124 Urban intelligence via bus fleet | Bus-based drive-by sensing is a well-established academic field — multiple papers on bus air-quality sensing, fleet sensing power via active scheduling, trip-based sensor deployment; **ExpoLIS** is a deployed bus-sensor + exposure-routing system |
| 26119 Indigenous GPU optimization solver | **NVIDIA open-sourced cuOpt** (github.com/NVIDIA/cuopt) — GPU LP/QP/VRP with MILP beta, 8x over open-source CPU solvers, 2x over commercial; **HiGHS** (MIT) already integrates cuOpt acceleration; PDLP published (Applegate 2021). The sovereignty argument is real but cuOpt being open source largely answers it, and a competitive solver is a multi-year effort, not a hackathon build. Technically the most interesting PS in the batch and still unbuildable |
| 26136 Startup public procurement | **GeM Startup Runway (and 2.0) already exists** — dedicated startup marketplace, EMD/turnover/prior-experience exemptions; startup procurement crossed **Rs 19,000 crore in 2025-26, +36% YoY** |
| 26130 Industrial approvals single window | **MAITRI 2.0 launched 4 Feb 2025** — 119 services across 15 departments, real-time tracking, 3,000+ cases resolved. Plus MIDC's own SWC |
| 26115 Medical waste segregation/tracking | Barcode/QR tracking **already mandatory** under BMW Rules 2016; CPCB published bar-code system guidelines for HCFs and CBWTFs; RFID + digital disposal records; commercial software exists |
| 26131 Crop disease/pest detection | The single most crowded lane in Indian agritech (Plantix, AgroStar, BharatAgri) + fails the ChatGPT test |
| 26132 Market linkage/price discovery | eNAM plus the entire agritech stack |
| 26128 Livestock disease | Bharat Pashudhan national animal-health database; image diagnosis fails the ChatGPT test |
| 26129 Govt platform interoperability | API Setu / India Enterprise Architecture; abstract, no artifact |
| 26134 / 26135 Skilling alignment & outcomes | Skill India Digital Hub — killed in this same lane at Hack4Crown |
| 26133 Rural healthcare accessibility | As written, too broad to be a deliverable |
| 26112 / 26123 Warehouse AMRs | GreyOrange and Addverb (both Indian, well funded), Locus Robotics |
| 26127 ANPR trajectory tracking | BEL itself builds ANPR; crowded vendor market; mass-surveillance framing is its own risk |
| 26125 Blockchain identity/access | Crowded, and blockchain here is decoration rather than mechanism |
| 26117 Sovereign agentic AI workbench | Ollama, vLLM, Dify, OpenWebUI, LangChain |
| 26114 / 26116 Autodesk Forma & Revit challenges | These are architecture/design exercises inside Autodesk's own tools, not software engineering |
| 26120 / 26121 Oil India well optimization | Needs proprietary well and drilling data |
| 26113 human augmentation / 26118 H2S wristband / 26122 project data capture / 26126 UGV navigation | Vague hardware, unvalidatable chemistry, generic PM tooling, or needs a physical vehicle |

### Verdict on assigned-ministry PS generally

125 of 226 swept; **3 survivors, all from Batch 1**. The pattern is now overwhelming and
consistent across five batches:

- **Government ministries have already built it.** myScheme, MAITRI 2.0, GeoMGNREGA, GeM
  Startup Runway, panchayat-level forecasts, C-Flood, BMW barcode tracking, ULPIN, SVAMITVA,
  Bhoomi Rashi, Madhu Kranti. Repeatedly, the ministry writing the PS has an in-flight
  programme covering it.
- **Corporate PS (BEL, Oil India, MRPL, Autodesk) are gated by proprietary data** or sit
  inside the sponsor's own product line.
- **Defence/security PS (DRDO, NTRO, MHA) are data-locked.**

**Still worth a targeted look in the remaining assigned PS** (do not blanket-kill these):
- **26149** secure data erasure + file recovery tool, **26150** multi-vendor DVR/NVR forensic
  tool (NTRO) — CCTV evidence acquisition across fragmented vendor formats is a real police
  pain and the tooling is genuinely fragmented
- **26182 / 26183** crypto wallet-to-VASP attribution (MHA) — unusually, the data here is
  **public by construction** (public blockchains), which breaks the usual MHA data lock

**The highest-yield remaining territory is SIH26193–26226 — the 34 AICTE "Student Innovation"
slots.** They carry no assigned title, only a theme, so we invent the idea. Both failure modes
that killed Batches 2–5 (ministry already built it; internal data gate) structurally do not
apply. That block should be worked with the full 4-step method in `hackathon-idea-method`,
not with PS-matching.

---

## TARGETED PASS — the 4 flagged PS (26149, 26150, 26182, 26183)

All four killed. Assigned-ministry PS territory is now exhausted.

| PS# | Killed by |
|---|---|
| 26150 DVR/NVR forensics | **Magnet Witness** (formerly DVR Examiner by DME Forensics, acquired by Magnet Forensics) is the established commercial tool — direct file-system acquisition from DVR drives incl. deleted/overwritten video, native + proprietary formats. Also UFS Explorer, DiskInternals. Academically covered too: MDPI 16/11/983 on automated Hikvision/Dahua recovery, arXiv 2605.07430 on Honeywell surveillance filesystems |
| 26182 / 26183 Crypto wallet attribution | **Chainalysis** (market leader), TRM Labs, Elliptic, Nominis. Decisive point: their moat **is** the proprietary labelled-address database. We would have no labels, so we cannot compete on the only axis that matters. USENIX Sec '25 "Ghost Clusters" documents how hard attribution evaluation already is |
| 26149 Secure erasure + recovery | nwipe, ShredOS, DBAN are open source and cover DoD 5220.22-M, Gutmann, ATA Secure Erase, NVMe Sanitize. The one real gap (tamper-proof erasure certificates for NIST 800-88 / IEEE 2883 compliance) is owned commercially by Blancco and Certus |

---

## AICTE STUDENT INNOVATION BLOCK — SIH26193–26226 (34 open slots)

No assigned titles, only themes. We invent the idea, so neither failure mode that killed
Batches 2–5 applies structurally. Worked with the full method in [[hackathon-idea-method]].

Software themes available: Smart Resource Conservation, Fitness & Sports, Heritage &
Culture, MedTech, Agriculture/FoodTech/Rural Dev, Transportation & Logistics, Travel &
Tourism, Renewable/Sustainable Energy, Miscellaneous, Smart Education, Disaster Management,
Space Technology.

### CANDIDATE A — Monument encroachment & loss monitoring (Heritage & Culture)

**Score 7.6.** Ties with 26001 for second overall.

| Prob | User | Demo | Judge | Novel | Feas | Imp | Overall |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 8 | 8 | 9 | 9 | **5** | 7 | 7 | **7.6** |

**The problem, all CAG-verified:**
- CAG physically inspected 1,655 of 3,678 centrally protected monuments and found **92 (6%)
  untraceable**. ASI later located 42; **24 completely untraceable, 14 lost to urbanisation,
  12 submerged** under dams/reservoirs. Per the 2025 report **31 remain untraceable**
- **414 protected monuments have encroachments**; 96 in the UP circle alone
  (CAG compliance audit tabled in Parliament **March 2026** — very fresh)
- "The 100-metre buffer is widely breached, and regularisation pressures are constant"

**The legal geometry is hard and codified** — this is what makes it automatable:
AMASR Act **Sec 20A** = 100 m prohibited area (no construction at all);
**Sec 20B** = a further 200 m regulated area (construction needs an NMA-recommended NOC).

**The actual gap — ASI is reactive.** Its own stated process: *"As and when any unauthorized
construction is **reported**, ASI initiates action."* Nobody proactively watches 3,678 sites.

**The sharpest framing (and the differentiator):** the NMA runs **NOAPS**, an online NOC
portal live since Sept 2015 with automated distance measurement. So the composition is
satellite change detection **cross-referenced against the NOC registry** — a structure that
appears in the regulated zone with **no matching NOC** is unauthorised by construction, not
by inference. That is automated legality determination, not just change detection.

**Why Novel is only 5 — do not inflate this.** Satellite change detection for heritage is an
active, tooled field: **EAMENA MLACD** (online ML change-detection tool on Google Earth
Engine with Sentinel-1 SAR, deployed for MENA and Gaza), **WATCH** (arXiv 2605.08160,
month-level wide-area archaeological change detection), RS 8090781 "Cultural Heritage Sites
in Danger — Towards Automatic Damage Detection from Space", plus published GIS buffer-zone
encroachment workflows. Pointing an existing method at India is a **deployment gap**, and
that is exactly the reasoning that killed 26102 (GeoMGNREGA). The NOC cross-reference is
what lifts it above pure deployment — the claim must rest there, not on "nobody watches
monuments from space."

**Open feasibility risks to resolve before promoting this:**
1. Are precise monument **boundaries** public, or only point coordinates? The 100 m ring is
   measured from the protected limit, not the centre
2. Sentinel-2 at 10 m may be too coarse for small encroachments; higher-resolution is paid
3. Is the **granted-NOC registry publicly queryable**? The whole differentiator depends on it

**Passes the no-adversarial-products rule:** the tool serves ASI/NMA enforcing their own
statute. CAG already did the exposing; we build the remediation instrument, not the accusation.

### AICTE round 2 — six seeds researched, zero survivors

| Seed | Verified numbers | Why it failed |
|---|---|---|
| **Blood bank wastage** | Discards rose **8 lakh -> 17.43 lakh units (+118%)** while collection rose only 24%; **expiry causes 45–46% of discards**; ~1.5–2M units wasted against a **3M unit annual shortage**; 4,260 licensed centres on e-RaktKosh; **e-RaktKosh APIs are published on APISetu** (a rare open government rail) | **Novel 4 -> BLOCKED.** Lateral transshipment for perishable blood is a mature OR field — two-stage stochastic models with ABO substitution, and **Emory achieved ~20% reduction in platelet outdates** in real deployment. Indian products already ship transfer features (**RAKT**, **Bagmo**), and the "national blood grid" is already an articulated vision. **Feas 5**: per-unit expiry dates are almost certainly not in the public API, and that is the one field the whole idea needs |
| **Road accident black spots** | **13,795 black spots identified** on NHs; they cause 29.6% of accidents and **35% of NH fatalities**; 57,329 accidents / 28,765 killed on 3,996 spots; only **5,036 got long-term rectification**; Haryana identified 136 spots 2022–24 with **none rectified** | **Novel 4, Feas 4 -> BLOCKED.** The spots are *already identified* — the failure is rectification (money, engineering, political will), which information does not fix. Outcome-verification framing needs iRAD accident data, which is closed |
| **Rooftop solar underperformance** | PM Surya Ghar targets 30 GW / 10M households; **only 13% of target met**; application-to-installation conversion 22.7%; Down To Earth calls it a "generation blind spot"; soiling/shading/inverter faults "persist undetected" | **Novel 4 -> BLOCKED.** Draft PM Surya Ghar guidelines **already propose the Remote Monitoring System architecture** (inverter dongles / data loggers). The hardware-free alternative (satellite irradiance + net-metering billing) needs DISCOM billing data — closed |
| **Non-revenue water** | Indian urban utilities lose **38% on average** vs the 15–20% global benchmark; **Delhi ~58%**, Nagpur 39%, Mumbai 27% | **Feas 3 -> BLOCKED.** Needs utility SCADA, DMA metering and pipe-network maps, all closed. Autodesk/Innovyze already sell hydraulic modelling into exactly this Indian problem |
| **CRZ coastal violations** | 7,516 km coastline regulated; **CAG found 180+ violations** of the CRZ 2019 notification; NGT and Supreme Court routinely order demolition | **Novel 4 -> BLOCKED.** Satellite estimation of CRZ violations is already published (Maharashtra 2002/2008/2014/2019); remote sensing is the standard method where official data is missing. Also fails the **no-adversarial-products** rule — the value would come from proving developers violated |
| **Unauthorized building deviation** | Extra floors and FAR breaches are "generally not regularizable and attract demolition" | **Feas 3 -> BLOCKED.** Sanctioned building plans are not public. Also adversarial, and states run **regularisation schemes** (e.g. Telangana LRS) that monetise the violation rather than prevent it — the enforcer is not motivated to detect |

### The refined search heuristic (this is the transferable finding)

The monument idea works because of a specific structure, not because heritage is interesting:

> **a codified geometric/legal rule + a public registry to check against + an enforcer who
> only acts on complaints + the enforcer is the *victim*, not the embarrassed party.**

That last clause is what separates it from CRZ and building-deviation, which have the first
three but make the tool adversarial. ASI *wants* encroachment found; a municipal corporation
running a regularisation scheme does not.

Hunt that four-part structure directly rather than hunting "big problems" — big problems in
India are almost universally already-instrumented or data-locked.

### Seeds examined and deprioritised

- **Groundwater** (Smart Resource Conservation) — excellent numbers (CGWB: 7,089 assessed
  units, 14% over-exploited, 4% critical, 12% semi-critical; Punjab extracting >150% of
  recharge, projected below 300 m by 2039). **Fails the "choosing vs losing" test**: farmers
  largely know, and MSP/procurement incentivises the water-intensive crop anyway. Information
  does not fix an incentive. Same shape as the gutka kill
- **Manuscripts** (Heritage) — ~10 million manuscripts, only 3.5 lakh digitised (3.5 crore
  pages) and just a third of those online; Gyan Bharatam Mission funded at Rs 482.85 crore
  (2024–31), NMM going autonomous with Rs 500 crore. Budget clearly exists, but the tech gap
  (Indic handwritten text recognition) takes heavy ChatGPT-test pressure from multimodal models
- **Sports talent ID** (Fitness & Sports) — occupied by the government programme itself:
  Khelo India already states it uses "data analytics based on AI to predict sporting acumen",
  runs KIRTI, and operates 1,066 Khelo India Centres across 759 districts

---

## BATCH 6 — the remaining 63 assigned PS. ALL KILLED.

Four had genuinely public data and got full sweeps. The rest are called on decisive
structural blockers, stated per PS.

### Swept and killed

| PS# | Killed by |
|---|---|
| 26162 Industrial fire / thermal source detection | **FIRMS itself now ships fire-type identification** (NASA Earthdata feature release). VIIRS Nightfire is the standard published method for gas-flaring detection worldwide |
| 26143 Oil spill + AIS vessel attribution | **EMSA CleanSeaNet** is an operational SAR oil-spill service across EU waters; KONGSBERG sells near-real-time spill situational awareness; ICEYE does SAR spill response. The exact SAR+AIS attribution method is published (Bohai Sea illegal-discharge tracing; "ship tracing from oil spills based on multi-source data") |
| 26191 Hazard red zones / relocation | **BMTPC publishes a national Landslide Hazard Zonation Map of India**; GSI runs national susceptibility mapping; HP SDMA has a hazard/vulnerability/risk atlas; Wayanad GIS-AHP and Joshimath remote-sensing studies published. Also overlaps our own 26001 — the useful parts fold into that, it is not a separate idea |
| 26161 Dam break inundation | HEC-RAS dam-break analysis is effectively an M.Tech project template in India — published case studies for Ukai, Damanganga, Hidkal and Dantiwada, plus a documented Tier-3 EAP methodology; CWPRS already does disaster management planning |

### 26148 — declined on principle, not on competition

*"Creation of scripts/functions with new programming language to commence Computer & Network
forensic analysis **without triggering security solutions**."* That is detection-evasion
tooling regardless of the forensics framing. Not built, and not scored. Recorded here so the
decision is explicit rather than silently skipped.

### Structural kills — MoES tail (26076–26086, 11 PS)

Same block Batch 3 proved is occupied by IMD's own programmes. 26077 / 26084 nowcasting and
26085 urban flood and 26086 hyperlocal monsoon all die to the Batch 3 findings (IMD
nowcasting, C-Flood + IIT Bombay Mumbai system, live panchayat forecasts). **26082**
(air-pollution/weather coupled, Delhi NCR) dies to **SAFAR**, CPCB and IITM Pune's Decision
Support System, all operational in Delhi. **26083** heatwave dies to IMD heat warnings, NDMA
heat action plans and standard UTCI/WBGT indices. **26079 / 26080 / 26081** (forecast-bust
detection, regime-aware post-processing, AI-NWP blending) are internal met-agency tooling
needing IMD forecast and NWP archives — user base is IMD forecasters alone. **26076** is a
UI feature request for the Mausam app, not a project.

### Structural kills — Egreen Quanta (26137–26141, 5 PS)

"Quantum-inspired" here is branding for classical metaheuristics. 26137 traffic routing and
26138 fleet/fuel are crowded commercial spaces; 26139 quantum ML for disease detection
compounds an unvalidatable medical claim with a technique that has no demonstrated advantage
on real clinical data; **26140** dies to IBM's free Qiskit textbook, Composer and Quantum Lab;
26141 is too vague to be a deliverable (the real adjacent topic, post-quantum migration, is
not what the PS asks).

### Structural kills — NTRO (26142–26165, 22 remaining PS)

Data-locked, crowded, or both. Highlights: **26142** super-resolution is a saturated DL field;
**26146** Bitcoin monitoring dies to the same Chainalysis/TRM finding as 26182/83; **26154**
GenAI content transformation fails the ChatGPT test definitionally; **26156** universal log
pre-processing is Logstash/Fluentd/Vector/Cribl plus the OCSF standard; **26155** multi-vendor
security compliance auditing is Tufin/AlgoSec/FireMon/Titania; **26158** single-pass drone-to-3D
is COLMAP/Agisoft/RealityCapture plus Gaussian Splatting; **26159** email crypto posture is
covered free by Hardenize, internet.nl and MECSA; **26164** ECDAT (cryptographic discovery for
PQC migration) is genuinely hot but owned by IBM Quantum Safe, SandboxAQ AQtive Guard,
Keyfactor and Venafi; **26163** assesses a specific internal application we have no access to;
**26165** needs Oil India's internal near-miss safety corpus; **26151** dark-web deanonymisation
is ethically fraught and needs data we should not be acquiring.

### Structural kills — ISRO (26166–26176, 11 PS)

Per the Batch 3 lesson, low yield. **26167** SatQuery duplicates an active VLM-for-remote-sensing
literature (RSGPT, GeoChat, EarthGPT) under ChatGPT-test pressure; **26175** DepthWizard is
monocular depth, mature via MiDaS and Depth Anything V2; **26172** wake-word detection is mature
(Porcupine, openWakeWord); **26173** iTantra is squeezed between AI4Bharat/Bhashini on Indic
speech and EnCodec/Lyra/Codec2 on low-bitrate audio; **26166**, **26169**, **26170**, **26174**
all need ISRO-internal data or serve a handful of specialists; **26171** browser-agent perception
sits in a crowded frontier race we cannot win on compute.

### Structural kills — Qualcomm (26177–26181, 5 PS)

All five are Hardware and presuppose Snapdragon developer kits. 26180 smart farming is the most
crowded lane in Indian agritech; 26179 retail intelligence is Trax/Standard AI territory; 26181
personal health companion compounds crowded wearables with medical validation we cannot do;
26177 SAR drone and 26178 environmental sensing are both crowded and hardware-gated.

### Structural kills — MHA (26184–26192, 9 PS)

**26184** needs NCRP complaint data (closed); **26186** repeats the 26093/26094 ethics-and-
validation block on stress prediction for a vulnerable population; **26187** border surveillance
is defence-gated and duplicates commercial VMS analytics; **26188** fake-document screening is
IDfy/Signzy/Jumio/Onfido and needs forged-document corpora; **26189** criminal network analysis
is effectively **NETRA again** (our own KSP Datathon project) against i2 Analyst's Notebook and
Palantir, and is data-locked; **26190** is a generic DMS; **26185** is RF hardware needing an
anechoic chamber; 26191 and 26192 are covered above.

---

## DEEP RE-SWEEP — the 20 Batch-6 kills that rested on unverified competitor claims

Batch 6 was originally done as grouped structural calls, and in it I **named competitors from
memory instead of searching** — the exact practice that produced the "Alvor" fabrication during
Quiesce (see [[verify-ideas-before-presenting]]). Aditya caught the inconsistency and asked for
a deep re-check. All 20 were re-swept with dedicated searches.

**Result: 20 of 20 kills confirmed. No fabricated competitors this time.** Recording the
verification evidence so these kills are defensible under a judge's question.

| PS# | Verified incumbent evidence |
|---|---|
| 26155 Network compliance auditor | **Titania Nipper** (checks configs against PCI DSS/CIS/STIG, Nipper InfraSight covers 180+ devices), AlgoSec, Tufin, FireMon. Enterprise pricing runs tens of thousands to six figures annually |
| 26164 ECDAT cryptographic discovery | **CBOM is a formal CycloneDX standard**; IBM Research CBOM; Encryption Consulting "CBOM Secure"; ReversingLabs Spectra Assure; Sectigo; Cycode. **OMB M-23-02 mandates** federal crypto inventories, so the category has a regulatory driver and funded vendors |
| 26159 Email crypto posture | **Hardenize** gives "the best single-shot view of your email TLS posture" (MTA-STS, DANE, TLS-RPT, cert validity, TLS versions); plus uriports, ScanTower, dmarcian, Red Sift Investigate, Mailhardener — **most of them free** |
| 26160 IPsec VPN analyzer | ike-scan, psk-crack, IKEForce, hashcat, HackTricks methodology, NSA's own IPsec configuration guidance. Tooling is fragmented CLI rather than a product, but the audience is tiny and judge-legibility is poor |
| 26157 SOC assessment | **SOC-CMM is free and open source** and is described as the de facto standard — 26 aspects across 5 domains with NIST CSF mapping. Killed by a free incumbent |
| 26156 Log pre-processing | Cribl Stream, Fluentd, Fluent Bit, Vector; **OCSF is a Linux Foundation project**, plus ASIM and ECS; Datadog ships an OCSF processor |
| 26175 Single-view height/depth | **MiDaS 3.1** (Intel Labs), **Depth Anything V1/V2**. Saturated |
| 26158 Drone video to 3D | COLMAP + 3DGS pipelines, **DroneSplat (CVPR 2025)**, and **Splatica** already automates the single-pass video-to-3DGS workflow commercially |
| 26167 SatQuery VLM | **GeoChat, EarthGPT, RSGPT, SkySenseGPT, SkyEyeGPT, LHRS-Bot, Falcon, EarthGPT-X** — there is a survey repo tracking the field. Among the most saturated areas checked |
| 26188 Document forgery screening | **Signzy** ("spots forgeries, validates expiry dates, auto-classifies 200+ ID types from 150+ countries"), IDfy, Shufti Pro, HyperVerge, Veriff, Kwik.ID |
| 26189 Criminal network analysis | **i2 Analyst's Notebook — 30+ years, 2,000+ organizations**; Palantir Foundry. Also effectively re-runs our own NETRA |
| 26179 Retail on-device intelligence | Trax, SES-imagotag, Focal Systems, Pensa Systems, WiseShelf, Standard AI, Actuate. A defined market with its own analyst coverage |
| 26147 SDR IQ signal analysis | GNU Radio, the **SigMF** metadata standard, PySDR, sdr-iq-visualizer; automatic modulation classification has a deep literature and patents |
| 26173 iTantra low-bitrate speech | **Codec 2** (open source, 700–3200 bps, explicitly "for low bandwidth HF/VHF digital radio") + FreeDV; **RADE** is a neural codec purpose-built for speech over HF radio (arXiv 2505.06671); LMCodec2 targets satellite voice. This was the one I expected might survive — it did not |
| 26171 On-device browser agents | Qwen-GUI-3B, **ShowUI (CVPR 2025, 2B model, 75.1%)**, GUI-Actor, LiteGUI, iSHIFT, R-VLM, MobileExplorer, plus a curated Awesome-GUI-Agent list |
| 26153 Network attack forecasting | Deep ML literature, IBM's predictive threat-intelligence product, granted patents, SDN anomaly prediction services |
| 26142 Satellite super-resolution | Multiple comprehensive surveys (arXiv 2505.23248, MDPI 14/21/5423), a curated papers repository, benchmark datasets (Land2Sent) |
| 26180 Smart farming assistant | **Plantix: 135 million downloads, ~10 million farmers annually, 800 symptoms across 60 crops, >90% accuracy.** Decisive |
| 26152 Social media analytics | Brandwatch (Cision, 2021), Meltwater, Talkwalker — **Talkwalker explicitly markets itself as the leading OSINT tool for public-sector agencies and security teams**. The PS is also literally two words, too vague to deliver |
| 26181 Personal health companion | **Bodytrak** (earpiece, on-device AI heat-stress analysis), Fitbit Sense 2, a scoping review of wearable heat interventions, and granted patents on ear-wearable heat-stroke detection |

**Method note worth keeping:** the re-sweep changed no verdicts, but that is the point — before
it ran, I could not have told Aditya which verdicts were evidence and which were recall. Grouped
structural kills are acceptable **only** when the blocker is a fact about *our* access (no
Snapdragon kit, no NCRP data, two Antarctic stations). The moment a kill rests on "product X
already does this," it needs a search.

---

## ASSIGNED-PS BOOK CLOSED — 226 of 226 checked

**Final yield from all 192 assigned (non-AICTE) problem statements: 3 candidates + 2 reserves.**

| PS# | Name | Score |
|---|---|:-:|
| 26011 | 3D ULPIN / vertical property mapping | **7.7** |
| 26001 | Landslide early warning, NER | **7.6** |
| 26002 | NER accessibility / cut-off villages | **7.1** |
| 26100 | GeM bid compliance (reserve) | 6.4 |
| 26034 | Legal Metrology label compliance (reserve) | 6.3 |
| 26017 | Land acquisition delays | blocked on data access |

Everything else in the assigned set is already built by the sponsoring ministry, gated behind
internal data, occupied by funded incumbents, unvalidatable by us, or (26148) something we
decline to build.

---

### AICTE round 3 — remaining themes worked, one reserve produced

| Seed | Verified numbers | Verdict |
|---|---|---|
| **CDSCO NSQ recall matching** (MedTech) | **168 medicines flagged NSQ in March 2026 alone; 576 flags in Q1 2026**. CDSCO publishes monthly NSQ lists publicly and has a "Guidelines on Recall and Rapid Alert System". Documented gaps: a drug made in State A declared NSQ in State B creates jurisdictional confusion (DCC is still harmonising), reverse logistics from thousands of retail outlets is costly, and stock is pulled "with no advance warning to the facilities carrying it" | **RESERVE, 6.7.** Distinct from counterfeit detection — NSQ is a *genuine* pack from a *real* manufacturer that failed lab testing, which PharmaSecure-style authenticity checks do not catch. But Novel is only 5 (cannot verify absence of a competitor) and the adoption blocker is real: it needs pharmacies to expose their batch-level inventory |
| **Fake doctors / quackery** (MedTech) | IMA estimates **10 lakh quacks** in allopathy + 4 lakh in Indian medicine; Telangana Medical Council caught 117 via decoy patients in 2025, ~500 police cases by Aug 2025 | **Novel 4 -> BLOCKED.** The **Maharashtra Medical Council is already building "Know Your Doctor"**, a credential-verification app, and NMC maintains the National Medical Register. Also edges into adversarial territory — the output accuses named individuals |
| **Unclaimed financial assets** (Miscellaneous) | **Rs 2.2 lakh crore unclaimed** across banks, EPF, insurance, stocks and MFs — Rs 78,000 cr bank deposits, Rs 89,004 cr IEPF shares/dividends, Rs 20,062 cr insurance. RBI's campaign returned ~Rs 2,000 crore in three months to Dec 2025 | **Novel 3 -> BLOCKED.** Four official portals already exist (**UDGAM, IEPF, Bima Bharosa, MITRA**) and the government has **just launched a unified portal** across financial services. Perfect fit for the heuristic, and the government got there first |
| **PMFBY crop insurance yield** (Agriculture) | Madhya Pradesh farmers documented struggling with satellite-based assessment | **Novel 3 -> BLOCKED.** **YES-TECH** has been in use since 2023; **Smart Sampling** by MNCFC + ISRO since 2019 across 23 districts in 11 states. PMFBY's own framework already mandates satellite/drone/remote sensing for yield disputes |
| **Adventure tourism safety** (Travel & Tourism) | Sector USD 16.7bn (2024) heading to USD 86bn (2033); **~30 paragliding deaths in Himachal in 5 years**, Bir-Billing notorious for unlicensed pilots | **Feas 4 -> BLOCKED.** Ministry of Tourism safety guidelines are **voluntary** — "anyone can launch an adventure sports company without mandatory licensing". No national registry exists to check an operator against, so the heuristic's second leg is missing. The fix is regulation, not software |
| **UDISE+ school infrastructure** (Smart Education) | 99.3% drinking water, 97.3% girls' toilets, 93.7% electricity; **94,000 schools still without electricity** | **BLOCKED.** The headline gaps are nearly closed. The real issue is self-reported data tied to Samagra Shiksha grants (an over-reporting incentive), but verifying toilets from orbit is impossible and the framing is adversarial |
| **NavIC applications** (Space Technology) | Only **4 of 11 satellites fully operational** for PNT (2026); recurring atomic-clock failures; "the common man cannot use the NavIC signal and depends on GPS" | **Feas 2 -> BLOCKED.** The bottleneck is silicon and satellites, not software. Nothing we build changes chipset integration |
| **Manual scavenging robots** (Hardware) | 1,470 deaths 2010–17; 300+ deaths 2018–23 | **Novel 2 -> BLOCKED.** **Genrobotics Bandicoot** has 300+ robots deployed across 19 states and 3 UTs |

---

## GAP-CLOSING PASS — the 7 software PS that were unwritten or assumption-killed

Aditya asked whether every *software* PS had truly been researched. Four had verdicts I
reasoned but never wrote down (26078, 26145, 26168, 26176), and three were killed on an
**assumed** data blocker I never verified (26079, 26080, 26081). All seven swept properly.

**Correction to the record — my data assumption was wrong.** I had killed 26079/26080/26081
saying IMD forecast archives are internal. In fact IMD runs a **Data Supply Portal**
(dsp.imdpune.gov.in, data on payment), publishes gridded daily rainfall (0.25°, 1901–present)
and temperature (1.0°, 1951–present), has an **API portal** (api.imd.gov.in) and datasets on
data.gov.in, and there is an `imdR` package for pulling gridded data. Free global alternatives
(ERA5, GFS, ECMWF open data) also cover India. **Feasibility was not the blocker.** The three
still die — but on Novelty, which is the honest reason.

(One incidental find that *supports* an earlier call: IMD **locked its AWS/ARG portal to the
public around May 2025**, which retroactively justifies the Feas score on 26073.)

| PS# | Verdict | Evidence |
|---|---|---|
| **26079** Forecast bust detection | **Novel 4 -> BLOCKED** | Forecast busts are formally defined in the field (ACC of 500 hPa geopotential below 40% at day 6). **NOAA published ML forecast-skill prediction** framed as POOR/FAIR/GOOD multiclassification, outperforming persistence and spread baselines. A patent exists on weather-model forecast bias explainability |
| **26080** Regime-aware post-processing | **Novel 3 -> BLOCKED** | Statistical post-processing "has become **standard practice in research and operations**" (BAMS review, 2021). CNN, XGBoost and graph-neural-network approaches all published; **operationally deployed at the Finnish Meteorological Institute** |
| **26081** Hybrid AI-NWP blending | **Novel 2 -> BLOCKED** | **ECMWF's AIFS has been operational since July 2025**, running in parallel with IFS; ECMWF already publishes a hybrid that spectrally nudges IFS large scales to AIFS; **ECCC pioneered the same with a GraphCast variant + GEM**. This is the live frontier of the world's largest met centres |
| **26078** Extreme-weather anomaly tracking | **Novel 2 -> BLOCKED** | **TempestExtremes v2.1** is a community framework doing exactly this — already used for tropical and extratropical cyclones, **monsoonal depressions**, atmospheric blocks, atmospheric rivers and mesoscale convective systems. Plus a large hand-labelled dataset for DL segmentation/tracking of extreme weather (Nature Scientific Data, 2025) |
| **26145** Threats in unidirectional IP traffic | **Novel 3, Feas 3 -> BLOCKED** | Data diodes are a mature commercial category — OPSWAT, Waterfall Security, Owl Cyber Defense, Everfox, Garland, 4Secure, SASA, Elisity. Also needs classified/OT network traffic |
| **26168** AI dead reckoning | **Novel 2 -> BLOCKED** | Saturated: **AI-IMU Dead-Reckoning**, Avnet (Satellite Navigation, 2025), **PiDR** physics-informed inertial DR, a standing survey ("Deep Learning for Inertial Positioning"), lane-detection-aided DR, plus Advanced Navigation's commercial AI-based INS |
| **26176** ORCA marine ecosystem agents | **Novel 3 -> BLOCKED** | **OceanAI** already applies LLMs to oceanographic reports; MARINA alliance; multi-agent environmental monitoring and Earth Science Foundation Models are active fields. The PS framing is also too vague to deliver |

**Software book is now genuinely complete: 154 of 154 assigned software PS closed with written,
evidence-backed verdicts, plus all 12 AICTE software themes worked. No new candidates.**

---

## FINAL RESULT — ALL 226 PS CHECKED, ALL AICTE THEMES WORKED

### Candidates (>= 7.0) — RESCORED after the data-access checks

| # | ID | Name | Score | Core strength |
|:-:|---|---|:-:|---|
| 1 | **26011** | 3D ULPIN / vertical property mapping | **7.9** ▲ | Maharashtra's VPC mandate live 1 Jan 2026; existing buildings unserved; **floor plans confirmed public on MahaRERA** |
| — | ~~AICTE-A~~ | ~~Monument encroachment monitoring~~ | **DEAD** | ASI+ISRO already run the platform; WFS disabled; boundaries exist for ~10 Karnataka monuments only |
| — | ~~26001~~ | ~~Landslide early warning, NER~~ | **DEAD** | **GSI's Regional LEWS goes operational in phases from 2026**; Assam has already signed an MoU with GSI |
| — | ~~26002~~ | ~~NER cut-off villages~~ | **DEAD** | NDEM + Bhuvan Disaster Services occupy it; no public real-time road-closure feed exists |

### The hard-verification pass killed all three NER/heritage candidates, 23 Aug 2026

After AICTE-A fell to direct inspection, the same treatment was applied to 26001 and 26002
rather than trusting their search-based scores. Both failed.

**26001 Landslide EWS for NER — Novel 3, BLOCKED.** The framing was "susceptibility maps are
free and national, NER is uninstrumented, so build sensor-free dynamic warning." That gap is
being closed right now by the incumbent:
- **GSI is making a Regional Landslide Early Warning System operational in phases from 2026**,
  targeting nationwide by 2030
- Already issuing experimental warnings in **Darjeeling, Kalimpong and the Nilgiris**
- Built through **LANDSLIP** with the British Geological Survey since 2017; prototype 2020 on
  terrain-specific rainfall thresholds
- The Regional Landslide Forecasting System (since 2020) **already combines rainfall thresholds,
  weather prediction models and real-time data with IMD, NCMRWF, ISRO and state DMAs** — which
  is precisely our proposed architecture
- **Assam has signed an MoU with GSI** for exactly this. Our target region is taken
- Data already flows through NGDR, the Bhukosh portal and the **Bhooskhalan mobile app**
- ISRO's own catalogue additionally holds `LS_ARUNACHAL_2023`, `LS_ASSAM_2023`, `AR_SLIM_2017`,
  `AS_SLIM_2017` and LHZ hazard-zonation layers

**26002 NER cut-off villages — Novel 4 and Feas 4, BLOCKED.**
- **Bhuvan Disaster Services** runs live modules for Cyclone, Drought, Earthquake, Flood, Forest
  Fire and Landslide, backed by **NDEM (National Database for Emergency Management)** — which is
  **VPN-gated for authorised emergency managers**, so we cannot reach it
- NRSC already holds every ingredient: `pmgsy_v2:Habitation_*` for Assam, Meghalaya, Manipur,
  Mizoram and Nagaland, 110 PMGSY rural-road layers, 54 NHAI layers, `disaster:Bridges`, and
  FEWS village/river/gauge layers
- **Fatal feasibility point I had glossed over:** I scored this on "OSM + disaster feeds are
  public," but never named the feed. There is **no public real-time road-closure feed for NER**.
  Which roads are currently blocked comes from police and PWD reporting, and that is the one
  input the whole idea depends on

### New screening asset — use this first from now on

`scratchpad/wms_cap.xml` holds ISRO Bhuvan's full **GetCapabilities: 7,088 layers across ~40
workspaces** (disaster 368, pmgsy 110, nhai_data 54, asi 78, forest, school, moef, tribal, lulc…).
Grepping it answers "does ISRO already have data or a system here?" in seconds, and that question
has now killed three candidates. **Check this catalogue before scoring any geospatial idea.**
Re-fetch with:
`curl "https://bhuvan-vec2.nrsc.gov.in/bhuvan/wms?service=WMS&version=1.1.1&request=GetCapabilities"`
Note WFS is disabled server-wide, so layers are viewable but not downloadable as vectors.

### The two data-access checks — results

**26011: ANSWERED YES. Feas 6 -> 7, score 7.7 -> 7.9.**
MahaRERA's public project search (no login required) lets anyone **view and download the
approved building layout, floor plans, and the commencement certificate** for any registered
project. Maharashtra mandates registration for every project with more than 8 units or over
500 sq m. That is exactly the input the land-share computation needs, and it is free.
**Limitation to state honestly on the deck:** RERA registration began in 2017, so pre-2017
buildings are not covered — and the VPC problem is largely about *older* existing buildings.
For those, sanctioned plans sit with the ULB (OBPAS portals, eDCR format) and are obtainable
per-building via RTI, but not in bulk. So: **demo on real public RERA data, and name the
pre-2017 gap ourselves before a judge finds it.**

### AICTE-A IS DEAD — killed by opening the actual portals, 23 Aug 2026

Web search said "boundary data looks limited." Opening the real systems with a browser gave a
**stronger and different** answer. Recording the full trail because the search-only conclusion
was wrong in both directions.

**What the NMA portal (nmanoc.nic.in) actually shows:** every NOC path is behind a login
(Applicant / Competent Authority / NMA). No public register of *granted* NOCs. The
"Details on Large Building Projects" page renders empty. **The cross-reference differentiator
has no data source.**

**What the portal led to — the decisive find.** Its "Maps" link goes to
**`bhuvan-app1.nrsc.gov.in/culture_monuments/`**: an ASI + ISRO joint portal titled
*"All India Inventory of Sites and Monuments"*, with a state selector covering 30 states and
this disclaimer: *"The location and the protected boundary of the monuments have been mapped
in association with Archaeological Survey of India."* It also links a **SMARAC citizen mobile
app** on Bhuvan. **ASI and ISRO are already building the geospatial monument platform.**

**What the GeoServer actually holds** (`bhuvan-vec2.nrsc.gov.in/bhuvan/wms`, layer
`asi:monuments2` drives the live map). Pulling GetCapabilities (7,088 layers) and filtering to
the `asi:` workspace returns **37 layers** — and they are almost entirely a **Karnataka pilot**:
Golgumbaz, Devanahalli, Srirangapatna, Tipu Palace, plus BLR / DHD / HMP circle point layers.
They include exactly what this idea needed — `DEVANAHALLI_PROTECTEDBND`,
`Srirangapatna_100M_buf`, `Srirangapatna_300M_buf`, `GOLGUMBAZ_100M`, `GOLGUMBAZ_300M`,
`TIPU_palace_100mbuf`, `GEOTAG_100_300M` — **protected boundaries and pre-computed 100 m/300 m
buffers, already built by ASI+ISRO, for roughly ten monuments.**

**Verdict — Novel 4 and Feas 4, both fatal:**
- **Novel 4.** The claim "nobody watches monuments from space" is **false**. ASI + ISRO have the
  national inventory, mapped protected boundaries, pre-computed AMASR buffers and a citizen app.
  This is the "sponsoring ministry already building it" pattern for the tenth time in this exercise.
- **Feas 4.** **WFS is disabled** on the server (`"Service WFS is disabled"`), so vector geometry
  cannot be downloaded — only rendered tiles. National protected boundaries do not exist publicly;
  only ~10 Karnataka pilot monuments have them, against 3,678 CPMs. Buffer analysis is impossible
  without boundaries, and the Delhi-scoping fallback fails too (that dataset was third-party
  OpenCity, not this).

**Method lesson: open the actual system before scoring a data-access risk.** Two rounds of web
search produced a soft "limited coverage" read; ten minutes in a browser and two curl calls
produced a hard kill with a quoted server error. Cheap, decisive, and it saved us from building
on a false novelty claim.

**(superseded) Earlier partial assessment, kept for the record:**
Two problems:
1. **Monument boundary data is not national.** ASI publishes the CPM list as a PDF
   (asi.nic.in/pdf/CPM_List.pdf) covering 3,679–3,698 monuments, but comprehensive GIS
   boundaries are not published. The only geospatial boundary dataset found is
   **OpenCity's Delhi ASI monuments boundary map — Delhi only.** The 100 m ring is measured
   from the protected *limit*, not a centre point, so a point coordinate is not sufficient.
2. **The granted-NOC registry was not found to be public.** nmanoc.nic.in exposes the
   application procedure, FAQ and competent-authority list, but no searchable list of *granted*
   NOCs surfaced. This is **not-found, not proven-absent** — worth checking the portal directly
   before finalising. But the NOC cross-reference was the whole differentiator, so until it is
   confirmed, the idea reduces to change detection, which EAMENA/WATCH already do.

**Consequence:** the idea survives but must be **scoped to Delhi**, where boundary data exists
and encroachment pressure is high. Scoping it is honest and buildable; pretending to national
coverage is not.

### Reserves (6.0–6.9)

| # | ID | Name | Score |
|:-:|---|---|:-:|
| 5 | **CDSCO-NSQ** | Substandard-drug batch recall matching | 6.7 |
| 6 | **26100** | GeM bid compliance verification | 6.4 |
| 7 | **26034** | Legal Metrology label compliance | 6.3 |

### Conditional
**26017** land acquisition delay prediction — the best problem numbers in the entire exercise
(35% of infrastructure delays, 773 NH projects, Rs 2.71 lakh crore) but blocked on whether
Bhoomi Rashi case-level history is publicly obtainable. Unblock that and it becomes a candidate.

### Why the yield is 7 and not 20

Across 226 assigned PS and roughly a dozen invented AICTE seeds, ideas died overwhelmingly on
two axes: **Novel** (the sponsoring ministry or a funded incumbent already shipped it) and
**Feas** (the data needed is internal). This is structural, not pessimism — ministries write
problem statements about programmes they are already funding. Nine separate seeds died to a
government product that already exists: myScheme, MAITRI 2.0, GeoMGNREGA, GeM Startup Runway,
panchayat forecasts, C-Flood, BMW barcode tracking, YES-TECH, and the unified unclaimed-assets
portal.

**Seven honestly-scored ideas is a better hand than twenty inflated ones**, especially since
SIH permits only **two idea submissions per team** (per the sih.gov.in FAQ — worth confirming
with the college SPOC). Five for the team to choose from is already covered.

---

## Running tally — COMPLETE

| Rank | PS# | Name | Overall |
|---|---|---|:-:|
| 1 | 26011 | 3D ULPIN / vertical property mapping | 7.7 |
| 2 | 26001 | Landslide early warning, NER | 7.6 |
| 3 | 26002 | NER accessibility / cut-off villages | 7.1 |
| — | 26034 | Legal Metrology label compliance (reserve) | 6.3 |
| — | 26017 | Land acquisition delays (blocked on data access) | — |

**Pattern worth carrying into later batches:** almost every loser scores acceptably on
Prob/User/Demo and dies on **Novel** (someone shipped it) or **Feas** (data we cannot get).
Sweep those two axes first in future batches — it is the cheapest path to a verdict.
