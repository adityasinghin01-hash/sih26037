# S0 · THE WORLD — the script every scenario inherits
Written 3 Sep 2026. **Nothing is built until this and the five scenario scripts are approved.**
Base map: the real road network of **Najibabad**, Bijnor district, western Uttar Pradesh.
Coordinates are metres, origin 29.61180 N 78.34210 E, x east, y north.
Source of truth for every road: `map/matlab_roads.csv` (MATLAB's own export).

## 1 · THE BOX
2000 × 2000 m of world; **ground extends to 4000 × 4000 m** so no cliff edge is ever visible.
Air volume: a closed box from z = −5 to **z = +2500 m**, 12 km across, with the camera inside it.
**CORRECTED 4 Sep while building.** The written 450 m box produced a visible horizontal seam in the
sky: above ~12.7° elevation a ray exits the box's TOP instead of its side, so the haze path length
jumps and the discontinuity shows. **The fix is also the physically correct one — real haze thins
with altitude.** Density is now `0.0049 × exp(−z / 1200 m)`, using the aerosol scale height, so the
box top carries almost no haze and there is nothing to seam.
**Never a world volume — that renders pure black.**

## 2 · TIME, LIGHT AND AIR — one sun for everything, no exceptions
**REWRITTEN 4 Sep 2026 after REF-13, the study of Aditya's own 43 photographs.**
The previous 06:45 dawn condition is superseded. **What he asked for is a CONDITION, not an hour:**
*"sun rays very good and peaceful · dense clouds, light clouds, every kind of cloud, properly
harmonizing · the light going above the clouds, beyond the clouds, coming through the streets,
houses, and everything."*

Date: **25 September** — **unchanged**, because every crop in S1 and S5 depends on it (paddy being
cut, cane standing, ploughing for rabi, the cold brick kiln).
Time: **15:30 IST.** **Sun elevation 33.11°, azimuth 246.87°** — computed with the NOAA algorithm
for 29.6118 N 78.3421 E, 25 Sep 2026. **West-south-west, so the light now comes from the OPPOSITE
side to the old dawn condition.**
**Why 15:30 and not another hour:** fair-weather cumulus is fully developed by mid-afternoon, which
is what he is asking for; the sun is still low enough to model form and throw real shafts; and it is
not yet golden hour, which he did not ask for. **It is one constant in the build script and can be
moved without touching anything else.**

**THE SKY — measured off his own photographs (REF-13 §1), three sources agreeing:**
| | R | G | B | saturation | hue |
|---|---|---|---|---|---|
| **target, plains** | ~138 | ~162 | ~179 | **23 %** | **202–206°** |
| toward zenith | | | | **~26 %** | |
| toward horizon | | | | **~20 %** | |
| *(alpine set, for contrast)* | 142 | 165 | 194 | 27 % | 213° |
| *(the old dawn condition)* | 191 | 188 | 183 | 4.6 % | warm grey |
**THE GRADIENT IS THE SPECIFICATION, NOT THE AVERAGE** — saturated above, pale at the horizon.
**Najibabad is plains, so hue ~204°, NOT the alpine 213°** — the aerosol load measurably shifts the
plains sky warmer and greener. This is a **five-fold** saturation change from the old dawn sky, so
Nishita's aerosols must come down hard from 10.0 and the haze colour must stop being warm tan.

**CLOUD — and the old "thin wispy cirrus, not cumulus, 25 %" is WRONG for this (REF-13 §2, §3):**
**Cover 50 ± 15 %, in the "broken" band.** Measured across his 39 sky photographs: median 45 %,
and the frames matching his description word for word measure 45–68 %.
**Three types in one sky, at two heights:**
1. **Cumulus** — cauliflower tops, bright, lit from above, grey-blue undersides.
2. **Stratocumulus** — flat-based, darker, lumpy-topped, in sheets.
3. **Fractus** — small torn shreds with no defined base, drifting across the holes.
Plus **thin fibrous cirrus much higher up**, not interacting with the others.
**THE RULE THAT MAKES A SKY READ, and nothing in REF-12 said it: EVERY CUMULUS AND STRATOCUMULUS
BASE SITS AT THE SAME HEIGHT.** They all condense at one level, so the bases line up horizontally
across the frame. **Vary the tops; never vary the base height.** Cloud bases at random heights is
the single loudest tell.
**Blue holes between them, of very different sizes.** A uniform deck is as wrong as a clear sky.

**THE LIGHT COMING THROUGH — the thing he actually asked for (REF-13 §4):**
This is an **occlusion** problem, not a shader problem. All of it already exists in our toolkit:
- **The sun sits BEHIND an occluder** — a treeline, a ridge, a cloud edge — never beside it.
- **Many small occluders, not one big one.** A single ridge gives a hard-edged beam; a pine canopy
  gives the soft luminous veil in `ref_42`, which is what he described. **This corrects REF-12 §6.**
- **Bounded volume, anisotropy 0.35** — forward scatter. Already built.
- **Halation on the cloud shader, coverage 3–6** (REF-12 §4) — the warm fringe on backlit edges.
- Backlit geometry goes **near-silhouette but never black**: measured, the shaded hillside in
  `ref_42` still sits at ~95/255.

**THE AIR — and haze must now do TWO things, not one (REF-13 §5):**
Measured off `ref_31` in depth bands, saturation collapses **53 % → 19 %** from foreground to the
far range, **and local contrast collapses with it, 43 → 21.**
**Haze flattens DETAIL as well as washing colour.** Ours only did the second.
Consequence for the build: **no crisp detail past ~2 km — let the volume do it.**
And: **the far range is the LEAST saturated thing in frame, less than the sky itself.** A distant
ridge painted pale blue is wrong; it is pale grey-blue and flatter than the sky behind it.
**VISIBILITY 20,000 m — derived, not chosen.** `ref_31` clearly shows a far range at ~15 km, pale
but readable. Koschmieder says at 6 km visibility that range transmits 0.0 % (invisible) and at
20 km it transmits 5.3 % (pale but there). **The photograph fixes the number.** 800 m was the dusty
dawn and is wrong for this condition by a factor of 25.
Density stays **Koschmieder α = 3.92 / visibility**, still with **noise into Density** so it is
wispy, and still an **altitude falloff** `× exp(−z / 1200)` so the box top carries none.
**Never a world volume — that renders pure black.**

**THE SKY PLANE IS NOW UNBLOCKED.** REF-12 §2's method needed a real sky photograph and we had none.
**We now have 43 of his own, which means they can also ship in the film.** Its sun must be on the
**west-south-west** side to match, or be mirrored with `S X -1`; its horizon aligned to the scene
horizon; its shadow disabled.

**AS BUILT, 4 Sep 2026 — component 1 v2, 31 assertions:**
Sun elev **33.11°** azim **246.87°**, energy 3.4→**4.0** · Nishita **air 1.7 / aerosols 1.0 /
ozone 1.0**, view transform **Standard**, exposure **−3.06** · haze **α = 3.92/20000**, warm tan
dropped for cool-neutral (0.72,0.75,0.80), anisotropy 0.35, altitude falloff exp(−z/1200) ·
**cumulus deck: base 1400 m, field 44,000 m, voxel 26 m, interior band 90 m, radial fade
14,000→21,000 m** · **cirrus: 7,200 m, streaked 1:0.14, shadowless** · **34 small god-ray occluders** ·
**volume bounces 6** — multiple scattering is why real cumulus undersides are bright rather than
near-black, and 2 was starving them of it.

**MEASURED ON THE FINAL RENDERS, the same way REF-13 measured his photographs:**
| render | cloud cover | blue-sky saturation |
|---|---|---|
| c2_a_driver | 34.5 % | 16.2 % |
| c2_b_intosun | **49.7 %** | 14.5 % |
| c2_c_skyward | 28.8 % | **19.9 %** |
| c2_d_wide | 28.7 % | 15.8 % |
**Targets: cover 50 ± 15 %, saturation 23.4 %.** Cover is **inside the band on the into-sun angle
and below it on the others**; saturation runs **3–9 points under** target. Both are honest misses,
not passes, and both have the same cause: **the cloud deck itself desaturates the sky it covers.**
Raising Nishita alone will not fix it — the fix is fewer/thinner clouds or a stronger blue, and that
is a look call for Aditya, not a number to sweep. **Recorded rather than papered over.**

**THREE THINGS THE BUILD ESTABLISHED THAT NO DOCUMENT SAID:**
1. **The radial fade must clear the camera's LOWEST sky ray.** A 1400 m cloud at 10° elevation is
   7,940 m away; at 6° it is 13,320 m. A fade ending at 12,000 m deleted most of the frame. **Fade
   geometry is decided by the camera's elevation angle, not by taste.**
2. **The field half-width must exceed the fade end**, or density is still high where the mesh stops
   and the edge reads as a hard line. **This was caught by an assertion, not by looking.**
3. **A flat envelope renders pancakes.** Cumulus develops vertically (REF-12 §3), so the envelope is
   nearly as tall as wide and the per-cloud **Z scale varies MORE than XY** — some tower, some stay
   shallow, which is what a real field does.

Wind 0.5 m/s from the north-west — it decides which way leaves drift and washing hangs.
**6 of the 13 dashcam clips are shot at NIGHT** — a condition the scripts still do not cover.

**THE 4K CLOUD PASS — AMENDED 6 Sep 2026. Pass 1 of the 2–3 promised; runs on the RTX.**
Four things the 4 Sep build did not have, each a named gap in DEFERRED.md / PLAN §9 C1:
1. **VOXEL SIZE VARIES WITH DISTANCE.** One 26 m voxel size across the whole 30 km field is what
   put the M1 at 11.97 GB. Split the joined cloud mesh into **three radial bands by XY distance
   from the origin** (the camera sits near it) and voxelise each at its own size:
   **near 0–5 km → 24 m · mid 5–10 km → 48 m · far 10–15 km → 96 m**, then join the *volumes*.
   The far annulus is ~5× the area of the near disc, so coarsening it is the largest single
   memory saving and it is invisible: past ~2 km the haze has already flattened all cloud detail
   (REF-13 §5). **This is the one change that makes a 4K cloud frame fit ~7.3 GB of VRAM.**
2. **BLUE HOLES ARE DRIVEN BY A LARGE-SCALE MASK, not by Poisson spacing.** Even Poisson gives an
   even deck. Feed every population's *Density Factor* a shared noise field at a **4–8 km
   wavelength**, ramped toward bimodal, so gaps **cluster and come in very different sizes** —
   S0 §2's "blue holes ... of very different sizes", made real. One mask for all three heights: a
   hole is a hole at every altitude.
3. **CAULIFLOWER: each lobe carries sub-lobes.** A second, **finer** noise (≈10–20 m wavelength)
   multiplied into the density ramp, plus a gentle normal-displace on the lobe mesh, so a 100 m
   lobe reads as knobbly cumulus, not a smooth ball.
4. **HALATION ON BACKLIT RIMS** (REF-12 §4, "coverage 3–6"; named in DEFERRED.md, never applied).
   A warm emission (≈1.0/0.93/0.82) gated to **low density only** — the thin edge glows, the core
   does not — plus anisotropy raised toward **~0.5** for the forward-scatter halo around the sun.
**Measured, not eyeballed:** after the pass, sweep cover %, hole-size spread and lobe scale off
the render against the 43 photographs, the same way the sky was fixed.
**Parked, and they stay parked until the whole city exists (PLAN §11):** cloud shadows landing on
real street/terrain geometry, haze collapsing local contrast as well as saturation, and the water
re-measured against REF-13 §6 — items 13–15.

## 3 · THE LAND
Alluvial plain, falling gently south. Three scales of undulation (600 m swells, 160 m, field
scale) plus **abandoned river channels** as shallow broad depressions and **field bunds every
~75 m** as 0.25–0.45 m stepped terraces. **The ground is never flat anywhere.**
**The Malin river** crosses the north-west, bed of boulders, cobbles and sand — Shivalik streams
carry heavy sediment, so never mud. Two real bridges cross it; the nine other tagged "bridges"
in this box are **highway flyovers 1.5 km from any water** and must not be built as river spans.

**THE ONE THING WE ADD: a hill**, centred **(−1050, 900)** — **AMENDED 4 Sep 2026, see below** —
roughly 500 × 350 m at the base, **170 m** high, long axis running north-west. Ridged, with a
**branching network of gullies** — the Shivalik drainage density is 4.55 km of channel per km², so
many small gullies, not two. It is marked as ours on the city plan. Nothing else in this world is
invented.

**AMENDMENT — the written centre (−690, 980) CANNOT BE BUILT, and this was found by measuring.**
The Malin's centreline passes **68 m from that point**, with **five river centreline points inside
the 500 × 350 m footprint**. A 170 m hill would have been built straight on top of the river.
Measured clearance from the footprint edge to the river, for each candidate:
| centre | clearance to river | distance from S5 centre | footprint inside the 2 km box |
|---|---|---|---|
| (−690, 980) *as written* | **8 m — fails** | 220 m | 56 % |
| (−690, 1180) due north | 84 m | 420 m | **0 %** |
| **(−1050, 900) — ADOPTED** | **82 m** | 386 m | **31 %** |
**Why north-west and not north:** it moves the hill **along its own stated long axis**, so the spec
is followed rather than fought; it keeps a third of the footprint inside the world box where due
north keeps none; and it puts **the river along the hill's southern toe**, which is the real
Bhabar / Shivalik pattern (REF-04 §10, §13) rather than an accident.
**And it is now correct by REF-05 §5's fourth recorded error** — *"a road that circles a hill never
faces it; put it ahead on the approach instead."* At 386 m the hill stands ahead of the S5 approach
instead of looming 220 m to the side. **The climb now begins immediately after the river bridge,
which is exactly what S5's action already describes.**
Behind it, a distant range at y ≈ 1900, ~340 m, a pale silhouette through the haze.

**LAND, EXTENDED — written 4 Sep 2026 before building, per Rule 1.**
The original §3 gives the terrain, the river, the hill and the range. What it does not give is
**the evidence that people have worked this ground for centuries**, and that is most of what makes
a plain read as *inhabited* rather than as generated. Every item below is sourced, is EARTH ONLY
(nothing grown, nothing built — those are components 6 and 4), and is visible at our camera height.

| # | feature | numbers | source |
|---|---|---|---|
| 1 | **Scree fans at every gully mouth** | triangular, apex at the gully, spreading downslope | REF-13 §6 — measured in ref_21/ref_15. Placed from the **Eroder's own `deposit` group**, not by hand |
| 2 | **Rock on the upper third**, foliated and slabby | flat plates splitting along bedding, tan/ochre/grey, stacked at an angle | REF-13 §6 (ref_33/34). **Not spheres, not Voronoi lumps** |
| 3 | **Three-scale debris law** | large slabs → medium boulders **that fell from them** → small pebbles caught by the small stuff | REF-07 §4. The medium ARE the debris of the large — placement is causal, never random |
| 4 | **The Bhabar apron** where the hill meets the plain | pebbly alluvial fan, shallow gradient, top layers full of small stones | REF-04 §10 — this is the real named landform for a Shivalik hill foot |
| 5 | **The quarry scar**, south-west face | cut benches, spoil heap below | S0 §3 as originally written |
| 6 | **Seasonal waterfall + plunge pool**, north flank | 22 m over a rock step, wet stain on the rock below | S5, REF-04 §13 — alive in late September |
| 7 | **Village ponds (johad)** ×3 | excavated depressions 25–60 m across, 2–3 m deep, holding water | Ubiquitous in UP villages; the excavated bank is the tell |
| 8 | **Irrigation channels** | earthen, 0.6–1.2 m wide, following plot edges, feeding from the bunds | REF-01 §15 — a village road crosses a field channel every few hundred metres |
| 9 | **Drainage nalas** | seasonal watercourses feeding the Malin, 2–6 m wide, dry-ish in late Sep | REF-04 §13 (choes/khads carry heavy sediment) |
| 10 | **The Malin's flood terrace** | a step 1.5–2.5 m above the channel, marking the monsoon flood level | REF-07 §10b — the bank line falls out of the terrain, so the terrace must be IN the terrain |
| 11 | **Braided bars and shoals** in the river | pale gravel, same material as the banks, channels splitting and rejoining | REF-13 §6 — measured off ref_21, the Malin at scale |
| 12 | **Brick-kiln clay pits** | 40–90 m excavated hollows, stepped sides, part water-filled | REF-04 §9 — the kiln is COLD in September but its pits are permanent landform |
| 13 | **Threshing floors** | swept flat circles 8–14 m across at field edges, hard bare earth | Kharif harvest is under way — REF-04 §9 |
| 14 | **Bare field shapes** | plot boundaries following the bund grid, ploughed vs stubble vs bare | S0 §7 — late September: paddy cut, cane standing, plots turned for rabi |

**THE GOVERNING PRINCIPLE APPLIES TO ALL OF IT** — *repeat what a reason would repeat; never repeat
what chance produced.* Ponds sit where the ground was already low. Nalas run downhill into the
Malin. Scree sits below gullies. Clay pits sit near the kiln. **Nothing is scattered; everything is
placed by the thing that caused it.**

**THE WATER BODY — SPECIFIED 5 Sep 2026, after the black bar was MEASURED rather than reasoned about.**
The 4 Sep build gave the Malin a **constant 2.5 m solidified slab** carrying a Principled Volume at
density 0.26. Two things were wrong with that, and the first one hid the second.
- **It rendered a hard black bar** across the base of the hill. Ray-cast through the black pixels:
  the hit object is `WATER_MALIN`, the hit normal is **+1.000** — the water's own TOP face, not a
  rim. The written "solidify rim" diagnosis was wrong. A/B, measured as the fraction of the strip
  below luminance 0.02: **as-is 36.3 % · volume unlinked 1.5 % · transmission off 0.0 % ·
  solidify removed 12.3 %.** **The volume is the cause.** At a grazing view 800 m away the refracted
  path through a constant 2.5 m of density-0.26 medium extinguishes to nothing.
- **A constant-thickness slab has NO DEPTH GRADIENT**, which is the entire reason REF-07 §10b puts a
  volume in the water at all. The build claimed the effect and did not have it.

**THE SPECIFICATION, and it fixes both at once because it is the physically true shape:**
1. **The water is a WEDGE, not a slab. Its top is the flowing surface; its bottom IS THE RIVER BED.**
   Depth at any point = `surface − terrain`, so it is **0 at the waterline** and reaches the channel
   depth mid-stream. Both sheets are built on the terrain grid (REF-05 §10f), so neither can
   self-intersect and the bed follows the carved channel exactly.
2. **The shell is CLOSED and manifold** — top sheet, bottom sheet, and a rim wall joining them at the
   waterline. **`use_rim=True` is correct and required:** a Principled Volume needs a closed boundary
   to bound its path length, and an open shell is what lets absorption run away. The rim cannot
   render as a bar because **the shell pinches to zero thickness exactly where it meets the bank** —
   the black bar is removed by construction, not by hiding a face.
3. **Depth does the work the slab was faking.** Density stays at REF-07 §5's sediment-laden value, so
   the shallows over the braided bars read pale and the channel reads dark, and the bars, shoals and
   cut banks fall out of the terrain for free — which is what REF-07 §10b actually asked for.
4. **Ponds, johads and clay pits keep their own levels** and are specified the same way: a lens
   pinching to zero at its own shoreline, never a disc floating at one height (S0 §3 items 7 and 12).
5. **Assertions, on MASS not on a bounding box** (Rule 4): median and maximum depth in metres; the
   fraction of the sheet shallower than 0.3 m must be non-zero, proving the wedge actually reaches
   the bank; the shell must be closed; and no rendered strip may sit below luminance 0.02.

6. **THE WATER'S SHADE — and it is the SCATTERING-ALBEDO error a second time.** Fixing the wedge
   shrank the black strip but did not remove it: ray-cast still hit `WATER_MALIN`'s top face at
   **luminance 0.000**. The cause is the one REF-12 §10 already recorded for the clouds —
   **`Principled Volume > Color` is the SCATTERING ALBEDO, not a paint colour.** The build carried
   `Color (0.58,0.62,0.55)` at density 0.26, so the water **absorbed ~40 % of every scattering
   event** and a grazing ray, which travels far through the medium, arrived at nothing.
   **A silt-laden river is the opposite of an absorber.** Suspended sediment is a strong scatterer:
   that is *why* such a river is pale and bright rather than dark and clear.
   **THE MEASURED TARGET, from Aditya's own photographs (REF-13 §6), not chosen:**
   | source | R | G | B | saturation |
   |---|---|---|---|---|
   | braided river, alpine `ref_21` | 143 | 148 | 156 | **8.7 %** |
   | plains water, Prayagraj `ref_05` | 128 | 141 | 145 | **12.4 %** |
   REF-13's own words: *"nearly colourless, just bright"* and *"a flat pale sheet, no visible depth
   colour at all, because it is shallow and silt-laden."*
   **So: albedo ~0.9 with only a faint grey-green tint, density kept at REF-07 §5's high end.**
   Opacity then comes from SCATTERING rather than absorption, which is what makes it read pale.
   **Swept against the measurement and not guessed**, the same way the sky was in §2.
7. **Recalculate normals on the solid** — REF-07 §5: *"select all and Shift+N ... the volume will
   not render otherwise."* The rim quads' winding is not guaranteed by the construction order.

**THE LESSON, recorded because it cost a whole session:** the fix that was written on 4 Sep
(`use_rim=False`) was **already applied in both the script and the .blend and the bar was still
there** — because the diagnosis had been reasoned from geometry instead of measured. **REF-05 §5's
rule held again: A/B it or ray-cast it, never argue about it.**

**THE GROUND MATERIAL — SPECIFIED 5 Sep 2026 before building, per Rule 1. It closes S0 §3 item 14
and it is what actually fixes "the plain reads featureless".**
The plain is NOT flat: measured, median slope 2.24°, p90 4.63°, and **3.8 m of relief in a 100 m
window**. The bund grid is real geometry — 75 m × 120 m parcels, each already carrying its own id
and its own level. **What is missing is that all 4 km² wears ONE soil material**, keyed only to
height and a single 50 m noise. So the parcels exist in the surface and are invisible in the image.
**This is LAND's job, not component 6's.** Crops sit ON the fields; the fields themselves are earth,
and earth is component 2.

**THE THREE-SCALE LAW (PLAN §3b) APPLIED TO THE GROUND — one cause, three readings:**
| | scale | what carries it | how it is built |
|---|---|---|---|
| **L** | from the air | the **field pattern** — parcels of different tone tiling the plain | per-plot tone driven by the EXISTING `plot_id` |
| **M** | from the street | the **plot boundary** — a bund lip, its dry crest, damp ground behind it | the bund height field, already built, reused as a mask |
| **S** | up close | **furrows** on ploughed plots, stubble rows on cut ones | anisotropic noise, direction per plot — a MATERIAL, never geometry |

**THE FOUR PLOT STATES, from REF-04 §9 and the 25 September date. Late September, western UP:
kharif harvest under way, monsoon retreated ~17 Sep, the ground DRYING, not wet.**
| state | share | colour | why |
|---|---|---|---|
| **ploughed for rabi** | ~30 % | darkest, damp-turned earth, **furrowed** | plots turned for the rabi sowing |
| **stubble** (paddy cut) | ~30 % | pale straw over dark soil, **row-structured** | paddy harvesting is under way |
| **standing cane** | ~20 % | earth barely visible — component 6 covers it | cane harvest runs Aug–Nov |
| **bare / fallow** | ~20 % | mid pebbly tan, dry | drying ground |
**The state is a HASH OF `plot_id`, so it is fixed per parcel and neighbours differ** — the same
mechanism that already gives each plot its own level. **Repeat what a reason would repeat.**

**COLOUR, MEASURED, NEVER PICKED.** REF-04 §10's two-tone rule stands — **near-black damp humus in
hollows, light pebbly tan on ridges and sunlit slopes**, boundary noise-masked, never a line. It is
now driven by the plot state as well as by height. And **REF-13 §7's plains correction governs
everything on this plain: ~31 % saturation, NOT the alpine 51 %.** Dust and haze sit on it.
**A saturated colour here reads as wrong immediately.**

**THE HILL'S ROCK — measured, and it is currently too pale.** Rock is on **28 % of hill faces** with
a base-colour ramp of only 0.115 → 0.330. REF-13 §6 reads foliated rock as **flat slabby plates,
tan / ochre / grey, stacked at an angle** — that is a wide value range, not a narrow one. Widen the
ramp, and **add a third, darker element for the shadowed splits between plates**, because what makes
foliated rock read is the dark line where two plates part.

**THE THREE-SCALE DEBRIS LAW ON THE HILL — S0 §3 item 3, and this is what survives Aditya's zoom
test.** REF-07 §4: **the medium rocks ARE the debris of the large ones.** So:
| | scale | what | placed by |
|---|---|---|---|
| **L** | the gully network | 4.55 km/km², many small gullies, not two | the Eroder's own `water`/`flowrate` groups — measured drainage |
| **M** | large slabs on the upper third + scree fans at every gully mouth | plates splitting along bedding | the Eroder's `deposit` group |
| **S** | boulders **below the slab that shed them**, pebbles caught by the boulders | same shape, smaller | derived from the M placement, never scattered |
**Scattering the small stuff randomly fails the zoom test instantly — that is the tell.**
**S is a material and a bump, not geometry** (PLAN §3b): modelling it would cost what the whole
terrain costs and would be invisible past 30 m.

**POND_2 — a measured failure, fixed by the numbers.** It came out **13 × 13 m = 2 × 2 grid cells**
on a 6.67 m grid, which is REF-05 §10h's sub-cell rule again. **Minimum pond radius is raised so
every johad spans at least 4 cells (≈ 27 m across)**, which is inside S0 §3 item 7's stated
25–60 m range anyway — the spec was right and the build under-filled it.

**THE GROUND SURFACES — SPECIFIED 5 Sep 2026 before building (Rule 1). PLAN §10 Phase 1.**
**The land is SHAPED but not SURFACED, and that is measurable, not an opinion:** the terrain is
**100 % one material**, and **not one of the 14 extended features has a material keyed to it.** A
threshing floor, a gravel bar, the Bhabar apron and a pond's spoil bank all wear farmland with plot
rectangles painted across them — **exactly the bug already fixed on the hill, never fixed on the
plain.** Every feature was placed by the thing that caused it; none of them looks like what it is.

**THE METHOD is the one already proved on the hill's `EROSION` attribute:** bake each layer's mask
into a colour attribute on the terrain, and key the material off it. The masks already exist — they
are the same arrays that cut the ground — so nothing is painted and nothing is guessed.

| feature | reads as | source |
|---|---|---|
| **braided bars + river banks** | **pale grey-tan gravel**, and *the bars are the same material as the banks* | REF-13 §6 |
| **the Bhabar apron** | pebbly alluvial fan, *top layers full of small stones* | REF-04 §10 |
| **threshing floors** | hard swept **bare** earth — no crop, no furrow, no plot tone | REF-04 §9 |
| **pond + clay-pit spoil banks** | raw excavated earth, darker, unvegetated — *the excavated bank is the tell* | S0 §3 items 7, 12 |
| **nala beds + irrigation channels** | damp sediment, darker than the plot they cross | REF-04 §13 |
| **the flood terrace** | the step reads as a tonal break, wet below and dry above | S0 §3 item 10 |
| **paleo channels** | damp low ground — REF-04 §10's *near-black humus in hollows* | REF-04 §10 |
| **the quarry spoil** | broken rock, not soil | S0 §3 item 5 |

**TWO FREQUENCIES PER SURFACE, NOT ONE — REF-07 §3, and this is the part that is easy to skip.**
The upgrade over "two materials mixed by a mask" is that the two maps must differ in **FREQUENCY**,
not merely in colour: one high-frequency, one low. **That, and not the colour, is what kills
tiling.** It applies to every surface in the table above.

**THE S SCALE ON THE PLAIN — PLAN §3b, and it is placed BY CAUSE, never scattered:**
- **stones** on the apron and on the gravel bars — the only two places stones actually are
- **clods** on the ploughed plots, because ploughing is what makes a clod
- **cracked, curling dry crust** on the fallow, because the monsoon left ~17 September and the
  ground is drying (REF-04 §9). **Not on the ploughed plots, which were turned wet.**
All three are **material and bump, never geometry** — 20 mm features on a 6.67 m grid (REF-05 §10h).

**SURFACES SMALLER THAN THE GRID — AMENDED 5 Sep 2026, and it was MEASURED, not assumed.**
The method above bakes each mask into a colour attribute on the terrain. That attribute lives on
**vertices**, so it can carry nothing finer than the 6.67 m grid — and one of the fourteen features
is finer than that. Measured, per instance, at the moment the mask is built:
| feature | its own size | grid nodes it lands on | verdict |
|---|---|---|---|
| clay pits | 52–90 m across | **51, 69, 72** | carried |
| ponds | 32–60 m across | **14, 28, 48** | carried |
| **threshing floors** | **11 m across** | **1, 1, 2, 2, 2, 2, 2** | **NOT carried** |
**And widening does not rescue it.** S0 §3 item 13 fixes threshing floors at **8–14 m across**;
even at that maximum the mask lands on **~3 nodes**. So this is not an under-built feature — the
terrain grid **cannot represent it at any size the specification allows.**

**THE RULE THIS IS AN INSTANCE OF — REF-05 §10h, already paid for twice** (the 0.9 m irrigation
ditch, POND_2 at 2×2 cells): *"either widen the feature to something the grid can carry, or build
it as a material, never as geometry."* Widening is closed by the spec, so it is a material.

**THE SPECIFICATION: a surface feature under ~3 terrain cells across is placed IN THE SHADER, from
its own centre, never through a vertex attribute.** The build already knows every centre — it chose
them — so they are passed to the material as constants and the mask is evaluated **per pixel**.
Resolution then stops being the grid's business, which is the whole point of PLAN §3b's rule that
**S is a material, never geometry**; this simply says the same of anything the grid cannot hold.
1. The floors keep everything else they already have: they still **level the ground** through the
   height field, and they still read as **hard swept bare earth, no crop, no furrow** (REF-04 §9).
2. **The assertion moves with the method.** Counting grid nodes tests nothing once the feature is
   not on the grid, so the check becomes: **one shader instance per floor, and that chain must
   reach Base Color** — the same three-link A/B/C test the other surfaces get.
3. **HONEST LIMIT, stated here rather than discovered later: the LEVELLING stays sub-cell.** A
   circle 11 m across cannot be flattened accurately by a 6.67 m grid, and no shader fixes
   geometry. **The tone will read; the flatness will not.** Making it read as *level* needs a finer
   terrain under the five circles, which is PLAN §10 Phase 2's displacement work, not this one.

**AND THE RULE THAT DECIDES WHAT IS *NOT* HERE:** these surfaces are EARTH. What grows on them is
component 6. The plain will still not read as *farmland* until the crops land — **that is expected
and is not a land defect.**

**THE HILL HAS NO PAD — AMENDED 5 Sep 2026, and it removes a whole class of bug.**
Fixing the water exposed what the black bar had been hiding: **the hill was standing on a flat
rectangular plate floating above the plain.** Three things combined to make it:
- The hill is generated on its own 500 × 350 m grid with the dome ellipse **inscribed**, so
  everything outside the ellipse is a **flat skirt** at one constant height.
- The terrain carried a `hillpad` layer that levelled the ground out to **2.45× the ellipse
  (612 m)** so that skirt would have something to stand on.
- **`river_guard` then punched a hole in that pad so it would not flatten the Malin** — leaving the
  skirt cantilevered over a dip, with a visible void under its straight south edge.
Each fix was locally reasonable; together they built a plinth.

**THE SPECIFICATION: the hill FOLLOWS THE GROUND and has no skirt.**
1. **No `hillpad` layer.** The plain keeps its own undulation right up to the hill foot.
2. **Every hill vertex is placed at `terrain height (x,y) + its own relief`** — the terrain is
   sampled bilinearly off the same height field the terrain mesh is built from, so hill and plain
   are the same surface by construction, not by tuning. The rim reaches zero relief at the ellipse
   and therefore lands exactly on the ground: **self-correcting, with nothing to sink or measure.**
3. **The skirt faces are DELETED** — any face whose vertices all carry under 0.4 m of relief. There
   is then no flat plate to catch the light, and no straight edge to read as a line.
4. **The Bhabar apron does the transition**, which is what S0 §3 item 4 always said it was for: a
   pebbly alluvial fan at the hill foot is the real landform, and a levelled plinth is not.
5. **`river_guard` is deleted with the pad it was guarding.** Nothing now flattens the Malin, so
   nothing needs to be excepted from it.
6. **The assertions change with it (Rule 4).** `dimensions.x/y` is a bounding box of a ROTATED
   ellipse and does not equal the spec's axes. Measure the footprint **along and across the hill's
   own north-west long axis**, over vertices carrying real relief — mass, not a box.

## 4 · THE ROAD NETWORK — real, and built at three levels
**42 km of real road inside the box.** Widths follow the map's own classification:
| tag | what it is | carriageway |
|---|---|---|
| trunk | NH534 / NH734 | 14.0 m divided |
| trunk_link | slip road | 7.0 m |
| secondary | main town road | 7.0 m |
| tertiary | town road | 7.0 m |
| unclassified | edge-of-town road | 5.5 m |
| residential | lane | 4.5 m |
| living_street | narrow lane | 3.2 m |
| service / track | yard road, kaccha rasta | 3.0 m |

**LEVEL 1 — everywhere.** All 42 km of road, the terrain, the river, the field pattern.
Roads are cheap; a whole network costs less than one detailed building.
**LEVEL 2 — inside the five scenario circles (~1/6 of the box).** Full detail. This is where
the film is made.
**LEVEL 3 — everywhere else. REVISED 3 Sep 2026 by Aditya. This supersedes the "shells" wording.**
**Everything, everywhere, must READ CORRECTLY AS WHAT IT IS.** A house must look like a house from
any angle a person looks at it — not a coloured box. A tree must look like a tree. A road like a road.
An animal like an animal. **The whole 4 km must give proper city vibes, alive, properly built.**

So Level 3 is no longer "shells". Every Level-3 building gets its real form: roof, parapet, water
tank, **real openings — doors, windows, a balcony where the type calls for one** — correct storey
count, and a colour per floor. Every Level-3 tree is a real tree of the right species with its real
constraint applied (REF-06), not a billboard. Every field carries its real crop for late September.

**What Level 3 still does NOT get, and why:** the close-up grime layer — the 0.6 m dust band, water
staining under each tank, individual posters, per-shutter wear, litter counted piece by piece.
That layer is authored per object and cannot be instanced, so it is the one thing that does not scale
to a thousand buildings. **It stays inside the five scenario circles (Level 2), where the camera is.**

**WHY THIS IS AFFORDABLE — and it is, because of instancing.** A thousand buildings sharing thirty
facade parts cost about what thirty parts cost (REF-03 §1, REF-09 §1). Giving all thousand real doors
and windows instead of blank walls is therefore nearly free. **What is expensive is unique texture and
unique grime per object, which is exactly what Level 3 does not get.**

**THE MEASURED LIMIT WE BUILD AGAINST:** stay under ~150,000 instances; past ~250,000 the 8 GB
unified memory swaps (REF-05 §3). The ground-cover layers are where that budget is actually spent, so
they get distance-based density falloff and the cheap texture method in the far field (REF-11 §10).
**Instance count gets measured after every component, not assumed.**

**COMPONENT 3 · HOW THE ROADS ARE BUILT — written 5 Sep 2026 before building, per Rule 1.**

**THE SOURCE OF TRUTH IS `map/matlab_roads.csv`, and that is the whole point.** It is MATLAB's own
exported centreline — 2,050 points in 425 resampled segments. Building Blender from it means the
road the planner drives and the road the camera sees are **the same numbers by construction**, not
by agreement. This was the biggest hidden risk in the project and this is what closes it.

**THE FRAME. One number, shared with the integrator chat.** MATLAB's frame and the OSM metric frame
differ by a pure translation. **Re-fitted 5 Sep by brute force over ±15 m: best (+34.0, −99.0),
median 2.24 m; the recorded (+35.0, −100.0) gives 2.50 m.** The difference is under a metre and
**the recorded value is kept**, because the integrator is exporting `map/ego_S1.csv` with exactly
that offset removed — agreeing on one number matters more than a metre of fit.
**Blender's frame = the OSM metric frame = MATLAB + (35.0, −100.0).**

**CLASS COMES FROM THE OSM JSON, GEOMETRY COMES FROM THE CSV.** `matlab_roads.csv` carries only
`x, y, road_id` — no tags. `najibabad_metres.json` carries all 213 ways with `class`, `name`,
`bridge`, `lanes`, `oneway`. So each CSV segment is matched to its nearest JSON way by
**point-to-SEGMENT** distance (REF-05 §4: never point-to-point) and inherits its class. Widths then
follow the S0 §4 table exactly.

**THE BUILD, and the order inside it is a dependency too:**
1. **Conform the terrain to the road first.** Roads are *cut into* land — REF-07 §1 and REF-08 §4.
   Each corridor is levelled across its width to the road's own longitudinal profile and feathered
   out over the verge, so the road never floats and never buries.
2. **The longitudinal profile is smoothed, then gradient-limited**, so a road follows the ground but
   never exceeds the audit figure. Smooth first, *then* enforce — REF-05 §10d proved the other order
   lets the smoothing put the violations back.
3. **The ribbon is built on the conformed profile with 2.5 % camber** (PLAN §3), crown at the
   centreline, and its own material by class.
4. **Two methods, deliberately** (PLAN §3): cut geometry where the section matters; **a material
   mask** for the kaccha rasta, field tracks and the crumbling edge.

**THE AUDIT — assertions, on MASS not on bounding boxes (Rule 4):**
- **213 roads present**, and every class count matches the OSM tally (residential 148, trunk 17,
  tertiary 15, unclassified 12, secondary 7, service 7, living_street 5, trunk_link 2).
- **Total centreline inside the 2 km box = 42.1 km**, the figure S0 §4 gives and PLAN §3 corrected.
  *(PLAN §3's audit line still says 47.3 km in one place; 42.1 km is the measured figure and wins.)*
- **Measured width per class**, sampled across the built ribbon, matching the S0 §4 table.
- **Gradient ≤ 6 %** on the plain roads (the hill road's own limits are a component-3 pass-2 item).
- **No road floats:** the ribbon's underside is within a tolerance of the conformed terrain
  everywhere, measured, not assumed.
- **Camber measured**, crown to edge, not asserted from the parameter that produced it.

**WHAT PASS 1 DOES NOT DO, stated so it is not mistaken for finished:** the 2 river bridges, the 9
flyover decks and piers, the railway, the S2 gyratory island and the S5 hill road are **pass 2**.
Pass 1 is every one of the 213 roads, at its real width, cut into the real ground.

## 5 · BUILDINGS — about 1000, from about 30 parts
**Do not model whole buildings.** Model ~30 facade parts — window, shutter, balcony, AC box,
sign board, awning, drainpipe, grille, staircase, water tank, parapet, door, meter box, dish,
drying washing, exposed rebar — and scatter them on plain boxes.
Vary: width 2.9–9.5 m · storeys 1/2/3 · colour, often per floor · clutter mix · ±2° rotation.
**No two buildings on screen may match.** ~400 detailed, ~600 shells.
Every wall: a dust band on the lower 0.6 m, water staining under the tank, one painted
advertisement or poster. Nothing clean, nothing plumb.

## 6 · THE SHARED LAYERS
**Vegetation, seven layers:** kans grass 2.2–3.0 m · sugarcane 2.25 m in rows 1.35 m ·
shrub 0.8–1.4 m · mid grasses 0.30–0.60 m · doob 0.05–0.15 m grazed · weeds · floor litter.
**Trees: neem is the hero, in TEN sculpted forms**, every copy varied in scale, spin and lean.
Eucalyptus only in plantation rows; gulmohar and amaltas only on medians; peepal only at a
shrine. **No banyan.**
**Power: one 132 kV lattice line crossing the fields at an angle, ignoring the roads**, towers
33 m at 320 m spacing with a 27 m cleared strip beneath. **11 kV candelabra poles** along every
road that has buildings, 9 m PCC, 45 m spans. Transformers where the town starts. Four-wire
415 V and service drops through the built-up stretches.
**One shared dust layer** over road, kerbs, pole bases, leaves, walls and every ledge. **This is
what ties separate objects together and it is the difference between a scene and a place.**

## 7 · THE FARMING SEASON — late September decides what the fields show
Kharif is being harvested. **Sugarcane standing at full height and being cut** (harvest runs
August–November). **Paddy being cut and stacked.** Some plots already ploughed for rabi.
The monsoon retreats around 17 September, so the ground is drying, not wet.
**The brick kiln is COLD — Bull's Trench kilns fire January to June only. No smoke plume.**

## 8 · THE DRIVE THAT JOINS THEM
One continuous route through the real network: out of the north-west past the river and the
hill (S5) → south into the fields (S1) → into the lanes (S3) → the gyratory (S2) → the
interchange (S4). **One car, one code, no cuts.** That drive is the demo.
