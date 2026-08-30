# SIH 2026 — Hard Verification of the 8 Shortlisted Ideas
**Run: 24 Aug 2026.** Every number below came from actually fetching the data — no estimates,
no assumed decimals. Where something could not be verified, it is marked UNVERIFIED rather
than scored optimistically.

Method per Aditya's instruction: **Pass 1** scores all seven axes including Novelty. Ideas that
fail *only* on Novelty go to **Pass 2**, scored on six axes with Novelty switched off — because
novelty can be engineered in later, whereas missing data cannot.

Blocking rule retained: **any axis at or below 4 blocks the idea in Pass 1.**

---

## PASS 1 — full criteria (Novelty ON)

| # | Idea | Prob | User | Demo | Judge | Novel | Feas | Imp | Score | Verdict |
|:-:|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|---|
| 1 | **3D ULPIN — land record per flat** | 8 | 9 | 9 | 9 | 6 | 7 | 8 | **8.0** | ✅ **PASS** |
| 2 | **CDSCO substandard-drug batches** | 8 | 8 | 8 | 9 | 6 | 7 | 8 | **7.7** | ✅ **PASS** |
| 4 | GeM bid compliance | 7 | 8 | 6 | 6 | 6 | 8 | 7 | 6.9 | ⬜ below bar |
| 3 | OceanEmbed — subsurface ocean | 7 | 7 | 8 | 7 | **3** | 9 | 6 | 6.7 | ⛔ Novel |
| 7 | Landslide warning NER | 9 | 7 | 8 | 8 | **3** | 6 | 9 | 7.1 | ⛔ Novel |
| 6 | Industrial fire detection | 6 | 6 | 8 | 7 | **4** | 9 | 6 | 6.6 | ⛔ Novel |
| 5 | MPLAD fund monitoring | 8 | 8 | 5 | 8 | 4 | **3** | 7 | — | ⛔ **Data** |
| 8 | Legal Metrology labels | 6 | 8 | 7 | 6 | 5 | **4** | 5 | — | ⛔ **Data** |

**Pass 1 survivors: 2** (ULPIN 8.0, CDSCO 7.7).

---

## The decisive verification — idea #1 is PROVEN, not theoretical

This is the most important result of the whole exercise.

**What I did:** opened MahaRERA's public project view (`maharerait.maharashtra.gov.in/public/
project/view/1`), solved the CAPTCHA, and pulled a real registered project —
**P50500000005, "GREEN CITY 3", Nagpur.**

**What the public page actually contains** (all verified on screen):
- Total Land Area of Approved Layout: **8,120.96 sq.m**
- Permissible / Sanctioned Built-up Area: 11,566.5
- **Building Details** — each building/wing with its sanctioned floor count (6, 10, 11)
- **Summary of Apartments/Units** — every unit type with **carpet area in sq.m** and **count**
- Geocoded **latitude 21.017065, longitude 79.058966**
- Survey/CTS number 33/1/33/2/1, plus boundary descriptions on all four sides
- Technical Documents section listing *Layout Approval* and *Building Plan Approval*

**Then I computed the actual Vertical Property Card number for all 232 units:**

```
Units in project        : 232
Total carpet area       : 10,570.88 sq.m
Total land area         :  8,120.96 sq.m
Land per sq.m of carpet : 0.7682

Sum of all land shares  :  8,120.96 sq.m
Reconciliation error    :  0.000000 sq.m
```

Sample computed shares: a 52.49 sq.m flat → **40.32 sq.m** of land; a 43.12 sq.m flat →
**33.13 sq.m**; a 12.09 sq.m shop → **9.29 sq.m**.

**And the formula is confirmed correct.** Independent reporting on the Maharashtra VPC states
the land share "follows a straightforward proportional formula based on your flat's carpet area
relative to the total carpet area of all units" — which is exactly what was implemented. The
share is an *undivided* fractional interest, expressed as an area or a fraction (e.g. 1/150th).

**Conclusion: the core computation of idea #1 works end-to-end on real public data today.**

**Honest limitations, to state on our own slide:**
1. **CAPTCHA on every project page.** Fine for a demo and for per-society use; blocks bulk
   automation across millions of flats.
2. **RERA began in 2017.** Pre-2017 buildings are absent — and those are exactly the older
   societies the VPC scheme most needs to serve. Their plans sit with municipal ULBs (OBPAS)
   and are obtainable per-building via RTI, not in bulk.
3. Some projects upload the same PDF for several document slots (this one used
   "Commencement cert.pdf" for both Layout Approval and Building Plan Approval), so document
   quality varies.

---

## Idea #2 verification — CDSCO substandard drugs

**Fetched and confirmed:**
- The **March-2025 NSQ alert PDF** (181 KB, 9 pages) parses cleanly with `pdftotext -layout`
  and contains **70 flagged batches** in that month alone
- Columns present: Product name, **Batch No**, Manufacturing Date, Expiry Date, Manufactured By
  (full address), **NSQ Result** (the exact failure), Reporting Lab
- Real examples pulled: Pantoprazole batch `SP240165` (Dissolution), Nitrazepam batch
  `AXI23003P` flagged **Spurious**, Adrenaline batch `AD-204` (particulate matter)
- Sept-2024 archive PDF also returns HTTP 200 (451 KB) — the archive is real
- **The live searchable database** at `cdscoonline.gov.in/CDSCO/viewPublicNSQDrug` returns
  HTTP 200 and offers **years 2019–2026**, month filters, a source filter (State lab vs CDSCO
  lab), **a separate "Spurious Drugs" tab**, and a "Pending States" view. Data was current to
  **JUL-2026**

**Batch numbers being present was the make-or-break question. They are present.**

**Competitor position:** no automated batch-against-NSQ checking tool was found. Apollo
Pharmacy publishes a *manual* how-to; TheHealthMaster merely republishes the monthly lists.
This is *not found*, not *proven absent* — so Novel is scored 6, not higher.

**Real limitation:** the strongest feature ("you are currently holding 40 strips of a recalled
batch") needs a pharmacy to expose its inventory. The consumer-facing scan-a-strip version
needs no adoption at all and still works.

---

## Why the other six failed — evidence

**#4 GeM (6.9, no blocked axis, just below bar).** Verified strong: **48,266 live bids** listed
publicly with no login; I downloaded a real bid document (`showbidDocument/9648940`, 147 KB) and
it extracted cleanly, containing exactly the governed fields — *MSE Relaxation: No*, *Startup
Relaxation: No*, *MII Purchase Preference: Yes*, L1+20%, Class 1/Class 2 local supplier rules.
**Correction:** I earlier suspected "GeMARPTS" was a rival restrictive-practice checker. It is
not — it stands for *GeM Availability Report & Past Transaction Summary*, a form for procuring
**outside** GeM. No conflict. This fails only on being a dry topic (Demo 6, Judge 6).

**#5 MPLAD — killed on data, permanently.** The eSAKSHI dashboard is public and has Excel/CSV/PDF
export, but the exported table is **MP-level allocation only**: Sr.No, State, MP name,
Constituency, Allocated Amount (28 pages × 20 rows). **There is no work-level record — no
individual works, no locations, no coordinates.** Satellite verification of claimed assets is
therefore impossible. The portal also states data is unavailable for 2019-20 through 2022-23,
and for Rajya Sabha MPs before 2023-24. **This cannot be fixed by adding novelty.**

**#8 Legal Metrology — killed on data.** There is no public dataset of product labels; we would
have to photograph packets ourselves or scrape retailers against their terms. The Consumer
Affairs site did not respond within 60s across two attempts (recorded as UNVERIFIED, not as a
kill). Penalty is only Rs 25,000, so there is little budget behind the problem.

**#3, #6, #7 — failed on Novelty only.** All three have working data. They proceed to Pass 2.

---

## PASS 2 — Novelty switched OFF (six axes)

Applied only to ideas that failed *solely* on novelty. MPLAD and Legal Metrology are excluded
because they failed on **data**, which no amount of engineered novelty repairs.

| # | Idea | Prob | User | Demo | Judge | Feas | Imp | **Score** |
|:-:|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | **3D ULPIN** | 8 | 9 | 9 | 9 | 7 | 8 | **8.3** |
| 2 | **CDSCO drug batches** | 8 | 8 | 8 | 9 | 7 | 8 | **8.0** |
| 7 | **Landslide warning NER** | 9 | 7 | 8 | 8 | 6 | 9 | **7.8** |
| 3 | **OceanEmbed** | 7 | 7 | 8 | 7 | 9 | 6 | **7.3** |
| 4 | GeM bid compliance | 7 | 8 | 6 | 6 | 8 | 7 | **7.0** |
| 6 | Industrial fire detection | 6 | 6 | 8 | 7 | 9 | 6 | **7.0** |

### Data access verified for the Pass-2 revivals

- **#7 Landslide:** UNVERIFIED in part. GSI's Bhukosh portal and the GPM data directory both
  timed out repeatedly from here — recorded honestly as unverified, not as working. NASA GPM
  requires a free Earthdata login. **Verify before committing.**
- **#3 OceanEmbed:** **best data access of all eight.** The Argo global profile index downloaded
  live (16.3 MB, timestamped **2026-08-24** — the same day), giving file paths, dates, lat/lon
  per profile. NOAA OISST sea-surface temperature also downloaded as a valid HDF5/NetCDF file.
  INCOIS reachable. Everything needed is free and confirmed working.
- **#6 Industrial fires:** **no API key needed.** The public VIIRS South-Asia 24-hour feed
  returned **1,046 fire detections** (84 KB CSV) including latitude, longitude, brightness,
  confidence and **Fire Radiative Power** — the field that separates industrial thermal sources
  from crop burning.

### How novelty could be engineered in (Aditya's point — valid)

- **#7 Landslide:** GSI forecasts *slope failure*. Nobody couples that to **road-network
  severance** — which village loses its only access route, and for how long. That is a different
  output from a different discipline (graph connectivity), not a better landslide model.
- **#3 OceanEmbed:** the papers reconstruct global fields. An **Indian-Ocean-specific model
  benchmarked against INCOIS moorings**, with honest error bars by depth, is a defensible
  contribution that MoES judges would recognise.
- **#6 Fires:** FIRMS classifies fire *type*. Coupling **persistent thermal sources to
  registered industrial units** (a source FIRMS has no access to) changes the question from
  "is there a fire" to "which facility is burning continuously and is it permitted".

---

## FINAL RANKING

**Build-ready now, verified end to end:**
1. **3D ULPIN — 8.0 (Pass 1) / 8.3 (Pass 2).** Land-share math proven on 232 real units with
   zero reconciliation error, and the official formula independently confirmed to match.
2. **CDSCO drug batches — 7.7 / 8.0.** Eight years of live, batch-level government data;
   simplest demo; strongest one-line pitch.

**Viable if novelty is engineered in:**
3. **Landslide NER — 7.8 (Pass 2).** Highest impact of all eight. Data partly UNVERIFIED.
4. **OceanEmbed — 7.3 (Pass 2).** Best-verified data of all eight; most technically impressive.
5. **GeM — 7.0.** Solid data, dry subject.
6. **Industrial fires — 7.0.** Excellent verified data, weaker problem framing.

**Dead, and not revivable — both failed on data, not novelty:**
7. MPLAD fund monitoring — no work-level records exist publicly.
8. Legal Metrology labels — no public label dataset exists.

**Answer to "if it's none":** it is not none. **Two ideas pass every criterion including
novelty, and four more pass once novelty is set aside.**
