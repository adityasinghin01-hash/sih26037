# REF-01 · ROADS, JUNCTIONS, HILL ROADS, BRIDGES, FLYOVERS
Researched 3 Sep 2026. Every figure carries its source clause. **Look it up, never guess.**
Basic road geometry, markings and poles are in `BLENDER-PIPELINE.md` Part Six — not repeated here.

## 1 · ROAD CLASSIFICATION AND WIDTH  (IRC 73)
| Class | Carriageway | Roadway |
|---|---|---|
| National / State Highway, single lane | 3.75 m | 12 m |
| Two-lane, no kerb | **7.0 m** | — |
| Two-lane, with raised kerbs | 7.5 m | — |
| Major District Road (MDR), two lane | 7.0 m + 1.0 m shoulders | min 9 m |
| Other District Road (ODR) | 3.75 m | 7.5 m |
| **Village road** | **3.0 m** | 7.5 m |
Four-lane divided total right of way **26–27 m**: 14 m carriageway + 2.5 m paved shoulder +
1.5 m earthen shoulder each side + 4 m median + 0.5 m kerbs.

## 2 · MARKINGS  (IRC 35:2015) — the rules that matter
- **A two-way road under 5.5 m gets NO CENTRE LINE, edge lines only.** Table 4.3.
  This is exactly the pattern in Aditya's rural footage and it is why our rural road is 5.2 m.
- Edge line: continuous white **150 mm**, placed **150 mm** in from the edge (4.5.2).
  **100 mm** where the paved width is under 7 m (4.5.5). Expressway 200 mm.
  Setback from a raised kerb face: **not less than 200 mm** (4.5.4).
- Centre line, open country: **3 m mark + 6 m gap at 100 mm**. Urban/built-up: **150 mm** (4.6.9).
  Warning section: 6 m mark + 3 m gap.
- Divided road lane line, rural, design speed ≤100 km/h: **100 mm**, 3 m + 6 m gap (4.7.1/4.7.2).
  Above 100 km/h and expressways: 150 mm.
- **Lane-drop taper, Table 7.2:** desirable **1:40** at 50–65 km/h (absolute minimum 1:25).
  A 3.5 m lane therefore needs **140 m** of taper. 1:45 at 66–80 km/h, 1:50 above 80.
- Ladder hatching diagonals: 4 m spacing up to 65 km/h, 6 m above.
- Stop line: **double line, each 200 mm wide, 300 mm apart.**
- Direction arrows: first at 15 m from the stop line, then every 15 m back.

## 3 · SIGNS  (IRC 67)
Cautionary sign = equilateral triangle, apex up, red border, black symbol on white.
**Side 900 mm** normal (rural main roads), **600 mm** small (minor rural + all urban).
Border **70 mm** / 45 mm. **Bottom edge 2.0–2.5 m above ground in rural areas.**

## 4 · HORIZONTAL CURVES  (IRC 38)
`R_min = V² / [127 (e + f)]`, f = 0.15, e max **7 % plain / 10 % hill**.
60 km/h at e=0.07 → **128.9 m**. 40 km/h at e=0.10 → 50 m.
Transition = **Euler spiral (clothoid)**, `Ls = V³ / (C·R)`, `C = 80/(75+V)`.
**A spiral of length Ls turns the heading by Ls/(2R) radians — the circular arc only supplies
the REMAINDER of the deflection.** Getting this wrong made our first bend 60 m too long.
Superelevation rises linearly from 0 at the start of the transition to full at its end.
Set-back for sight distance: `m = R(1 − cos(S·90/(π·R)))`.

## 5 · GRADIENTS
Plain terrain: **3.3 % ruling · 5.0 % limiting · 6.0 % exceptional.**
A smooth (S-curve) ramp peaks at **1.5× its average grade** — size embankments for the peak,
not the average. Lifting a road 2.8 m therefore needs ~90 m of approach, not 30 m.

## 6 · ROUNDABOUTS AND ROTARIES  (IRC 65:2017)
Design speed **40 km/h rural, 30 km/h urban**.
| Type | Inscribed circle diameter (ICD) | Circulatory carriageway |
|---|---|---|
| Urban single lane | 28–40 m | 12 m down to 8 m |
| Rural single lane | 35–40 m | 12 m down to 8 m |
| Double lane | 40–70 m | 1.0–1.2 × entry width |
| Multilane rotary | over 70 m | — |
**Table 6.2 — the pairing that must be obeyed for a single-lane roundabout:**
ICD 28 m → central island **4 m**, circulatory 12 m · 30 → 8 / 11 · 32 → 12 / 10 ·
36 → 18 / 9 · **40 → 24 / 8**.
A **truck apron** (raised paved ring round the central island) is desirable when the central
island is small, so long vehicles can mount it.
Turning radii (Table 6.4): central island 12 m → R1 7.0 m, R2 15.0 m, minimum ICD 32 m.
**An ICD above 36 m caters for all movements.**
Weaving length minimum **45 m** at 40 km/h, 30 m at 30 km/h; weaving width 6–18 m.
Roundabouts operate on **give-way at entry**; a rotary with a large central island operates on
**weaving** — they are not the same thing.

## 7 · AT-GRADE JUNCTIONS  (IRC SP-41 / IRC 35)
Corner / island control radius **12–15 m** — this is the number that shapes a junction.
Central median gap at a junction extends **at least 3 m beyond** the extended kerb line of the
minor road.
**Median openings for U-turns: 20 m or more where there is no storage lane** (NHAI practice),
to act as a neutral waiting place for small vehicles.
Spacing between median openings: **not closer than 2 km in open country, 500 m built-up.**
IRC:86 cl.5.6 — median widths for purpose: pedestrian refuge 1.2 m · right-turn protection
4.0 m (7.5 m recommended) · **9–12 m to protect a vehicle crossing at grade** · *"even greater
widths are required for U-turns."* Minimum 1.2 m, **desirable minimum 5 m**.
Median kerb height **150 mm MAXIMUM** (IRC:86 cl.5.1.2). Pedestrian refuge min 3 m on roads
of four or more lanes.

## 8 · HILL ROADS  (IRC 52)
**Hairpin bend:** design speed **20 km/h** · **minimum inner curve radius 14 m** ·
transition curve minimum **15 m** · superelevation **1 in 10** · **minimum 60 m between
successive hairpins** · **roadway widened to 9 m at the apex** for long-wheelbase vehicles.
Roadway widths **exclude the parapet**, which is **0.6 m** wide.

## 9 · RETAINING AND PROTECTION WORKS  (IS 14458 Parts 1–2)
Banded dry stone masonry up to **6 m** high; timber crib and dry stone only where the slope is
under **30°** and height under **4 m**. **Gabion / wire-crated walls** where the foundation is
poor or there is seepage — flexible, free-draining, tolerate differential settlement and some
slope movement. Real example: a **9 m** gabion wall with a coir mat above it to hold the
surcharge slope. Gabion baskets are typically 1 m modules.

## 10 · BRIDGES  (IRC 5:2015)
Carriageway **4.25 m single lane · 7.5 m two lane · +3.5 m per extra lane**.
Footpath clear width **≥ 1.5 m** (cl.104.3.6). **Safety kerb ≥ 750 mm** where there is no
footpath (cl.101.41). Median on a major bridge may reduce to **1.2 m** minimum, with crash
barriers. **No object other than a kerb or crash barrier within 600 mm of the carriageway edge.**
**Railing / parapet minimum 1.1 m** above the deck or footway kerb (cl.109.7.2.3); **+0.1 m for
bridges over 300 m**; 1.25 m where a cycle track runs alongside. **Clear gap below the bottom
rail ≤ 150 mm**, and all infill gaps ≤ 150 mm.
Approach: **W-beam crash barrier**, top of beam **700–750 mm** above road level, posts at
**2.0 m**, beam profile **312 × 83 × 3 mm** (MoRTH).

## 11 · FLYOVERS / GRADE SEPARATORS
Typical Indian highway flyover spans **19.5–35 m** (commonly 20–22 m in a long run).
Piers **1800 × 1800 mm** square, on 1000 mm diameter piles.
Deck width **24.1 m** for six lanes. Post-tensioned or cast-in-situ box girders.
**Minimum vertical clearance on urban roads 5.5 m** (IRC:86).

## 12 · THE SIX PIECES OF MATHS THAT WERE SILENTLY WRONG BEFORE
1. Lens — 140° dashcam ≈ 8 mm equivalent; we used 24 mm.
2. Haze — `α = 3.92 / visibility_metres`, and that IS Blender's volume Density.
3. Catenary — a hanging wire is a **parabola** `z = h − 4·s·t·(1−t)`, not a sine.
4. Road curves — R_min and the clothoid, and the spiral eats part of the deflection.
5. Gait — stride × cadence must equal travel speed or feet slide.
6. Sky — three scattering parameters, never painted colours.

## 13 · ROAD FURNITURE  (added 3 Sep, second research pass)
**Kilometre stone (IRC 8 / IRC 26): 600 × 300 × 100 mm.** 200-metre stone **450 × 200 × 75 mm**.
Placed **2.0 m from the road centreline on the left**. Colour by road class:
**NH green · SH yellow · MDR blue.** Cast concrete now, cast iron historically.

**Speed breaker (IRC 99):** hump **3.7 m along the road × 0.10 m high, 17 m radius, parabolic —
not a flat-topped sawtooth.** Full carriageway width. Painted **alternating black-and-white (or
black-and-yellow) bands across the full width**; diagonal stripes **300 mm** wide. Thermoplastic
paint plus cat's-eyes for night. Advisory 25 km/h, **minimum 300 m apart**.
**Rumble strips:** 25 mm high, 300 mm wide, **1 m centre to centre, 4–6 in series** — advance
warning, not primary speed control.

**Roadside drains (IRC SP 50 / SP 42):** urban side drain **300–500 mm wide × 300–450 mm deep**,
rectangular concrete, often grated. Rural longitudinal side drains **0.3–1.0 m wide and deep**,
rectangular / trapezoidal / hemispherical, lined in brick or stone where flow is high and
**unlined in low-flow rural stretches**. Covered RCC drain: **600 × 600 mm internal, 150 mm
walls and raft, 150 mm cover slab, 200 mm of earth over.** Minimum bed slope **0.5 %**.
Manholes every **30–50 m** on straight runs.

**Rural bus stop (IRC 80):** simple shelter **5.0–6.5 m long × 1.6 m deep × ~2.8 m high.**

**India Mark II hand pump: 1.50 m tall**, cylinder 63.5 mm, stroke 125 mm, lifts from 50–80 m.
It is the standard village pump and the silhouette is instantly recognisable.

**Hoardings and unipoles:** unipole **28–40 ft tall (8.5–12 m)**, board **20×10 ft to 40×20 ft**.
Hoardings 20×10 to 60×30 ft; smaller billboards 10×10 to 30×15 ft. Double-sided on one steel pole.

## 14 · NOT FOUND — must be measured off Aditya's own footage
- **The chowk statue.** Everything published is about the giant monuments (38 m Ambedkar
  statues), which are useless as reference. A real small-town chowk statue is a person-scale
  figure on a plinth — **measure it against a known object in a frame instead of guessing.**
- Exact vendor-stall footprints as actually used on a street (manufacturer sizes are below).

## 15 · CULVERTS  (IRC SP 13 / IRC 5)
**A culvert is a structure up to 6 m long. A small bridge is up to 30 m with spans up to 10 m.**
Types: **RCC hume pipe · RCC slab · stone slab · box cell · masonry or RCC arch.**
Hume pipes run **150 mm to 3000 mm** diameter; a road-crossing culvert on a district road is
typically **900–1200 mm**. Fitted with toe walls, headwalls and splayed wing walls.
A village road crosses a field channel on one of these every few hundred metres — they are the
most common structure in the whole landscape and they are almost always half silted.
