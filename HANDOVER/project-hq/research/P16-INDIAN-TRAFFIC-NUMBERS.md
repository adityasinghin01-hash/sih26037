# P16 — Indian traffic numbers

Status: ROUND 1, 26 Sep 2026. Codex (new session, gpt-6-sol, high) researched; Claude spot-checked.
Brief and raw output: `_codex/P16-brief.md`, `_codex/P16-codex-r1.md`.

**Check key**
- **C✓** = Claude opened the source and matched the number.
- **X✓** = only Codex read the full text; Claude was blocked (403/paywall), but the paper's identity is confirmed via Crossref.
- **X?** = Codex saw only the abstract, or couldn't open it.

## Claude's corrections to Codex
- Raipur cattle survey data year: Codex said "not reported". It is **16 Feb – 11 Apr 2019** (stated in the paper).
- Bengaluru speed study also gives **IQRs** (the middle 50% of speeds). Use them for sim speed spreads (added below).
- Bonus found in the Bhopal/Indore paper: pedestrians' **mean accepted gap is 4.29 s** (adults 4.21, elderly 4.90). C✓

## 1. Do drivers stop for people crossing? — WEAK
| Number | Where / n | Source | Check |
|---|---|---|---|
| 6.58% / 12.24% of drivers yield | 2 Mumbai midblock sites; n not reported | Chaudhari et al., doi 10.1016/j.iatssr.2020.06.001, Table 5 | X✓ (preproof) |
| 67.92% of interactions, driver yields | 1 New Delhi midblock; n=452 | Khan et al., Springer s41062-026-02547-8 | X? abstract only |

**Verdict:** no usable number by vehicle type exists. The two studies disagree by about 10×. The sim must **sweep** the yield rate. It must not assume one.

## 2. Minimum gap before turning, by vehicle type — GOOD
| Number (s) | Where / n | Source | Check |
|---|---|---|---|
| Right turn from major/minor road: 2W 2.5/3.5 · 3W 2.7/3.7 · car 2.7/3.8 · bus 3.6/5.5 · truck 3.8/5.7 (fitted base values) | 6 unsignalised junctions; 1,262 + 1,488 turns | Mohan & Chandra, IJTST vol 10, 2021, doi 10.1016/j.ijtst.2021.01.004, Table 10 | X✓ (previously blocked) |
| Minor/major: car 4.30/3.80 · 2W 3.50/2.60 · 3W 3.85/3.00 | 1 semirural T-junction, 2006; n=76–325 per class | Ashalatha & Chandra, doi 10.1007/s12205-011-1392-5 | X✓ |
| Roundabout entry: 2W 1.21–1.45 · 3W 1.50–1.74 · car 1.78–1.94 | Jaipur and Thiruvananthapuram | Mathew et al., doi 10.1016/j.trpro.2017.12.147 | X✓ |
| Car design value: 4.8 major / 5.8 minor | IRC:SP:41 (1994) code | IRC PDF | X✓ |

**Verdict:** consistent pattern: **2W < 3W ≈ car < bus < truck**. Mohan & Chandra is the main source.

## 3. How close bikes pass other vehicles — GOOD
| Number | Where / n | Source | Check |
|---|---|---|---|
| Side gap (cm) = 118 + 0.22·speed (bike–bike, n=87) · 125 + 0.61·speed (car–bike, n=1,372) · 117 + 0.74·speed (auto–bike, n=417); speed in km/h | 6 cities | Budhkar & Maurya, J. Modern Transportation 2017, doi 10.1007/s40534-017-0130-1, Table 4 | X✓ |
| Squeeze-through gap: mean 0.906 m | IDD/TIAND, 13,219 events | S1389128626005220 (already in hand) | — |

**Verdict:** a bike passing at ~30 km/h leaves about **1.2–1.5 m**. When squeezing through queues it leaves about **0.9 m**. Bike–bus gap: NOT FOUND.

## 4. Cattle on the road — PARTIAL
| Number | Where / n | Source | Check |
|---|---|---|---|
| 7.28 cattle per km of street (range 0.40–23.58) | Raipur; 20 grids, 141.68 km; Feb–Apr 2019 | Sahu et al., PLOS ONE 10.1371/journal.pone.0234594 | **C✓** |
| 50 lakh stray cattle in India | 20th Livestock Census 2019 | PIB release 1813802 | **C✓** |
| 3,383 cattle crashes, 919 deaths, 5 yrs | Haryana | Assembly answer (already in hand) | — |

**Verdict:** one city only. What share of all crashes involve animals nationally: NOT FOUND (MoRTH has no animal row).

## 5. Wrong-way driving — PARTIAL
| Number | Where / n | Source | Check |
|---|---|---|---|
| 7.6 wrong-way vehicles per 5 min | 1 Hyderabad road, 1 hour, 2019 | Singh & Kumar, Springer s13369-020-05213-y | X✓ |
| 5.1% of highway crashes, 5.3% of highway deaths (3,358 deaths) | All national highways, 2023 | MoRTH 2023, Table 2.9 | X✓ |
| 5.46% of all deaths (wrong side + lane indiscipline combined) | All India, 2023 | MoRTH 2023, Table 3.1 | X✓ (corrects our 5.5%) |

**Verdict:** there is no number for what share of vehicles on the road go the wrong way. Use it only as a stress case.

## 6. Speeds — GOOD
Bengaluru region, May–Oct 2022, 172,164 vehicles. Median speed in km/h (middle-50% range). **C✓**
Source: Journal of Road Safety, "Urban and rural differences in driver speeds… India", Table 2.

| Class | Urban | Rural |
|---|---|---|
| Motorcycle | 45 (39–56) | 50 (42–59) |
| Car (sedan) | 50 (41–67) | 68 (57–77) |
| Auto (3W) | 38 (33–43) | 43 (38–49) |
| Bus | 41 (35–49) | 64 (55–71) |
| Truck | 44 (36–52) | 51 (44–58) |
| All, national highway | 63 (51–74) | 59 (48–73) |

- Slow commercial street, Hyderabad, 1 hour: 2W 11.4 · auto 6.5 · car 5.9 km/h. X✓
- **Pedestrian crossing speed** (Bhopal/Indore, 6 sites, n=2,616): adult 1.22 m/s mean (slowest 15% below 0.81) · elderly 0.99 (0.71). **C✓**
- Village-road speeds, tractors, cycles, cattle walking speed: NOT FOUND.

## Still open
- Pedestrian-yield rate by vehicle type: needs our own measurement (or the sim sweeps it).
- Bike–bus side gap; cattle encounters per hour; wrong-way share of traffic; village-road speeds.
- Items marked X✓ need a Claude open if they go on a slide as a headline number.
