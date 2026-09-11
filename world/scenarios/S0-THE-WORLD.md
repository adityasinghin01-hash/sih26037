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

**COMPONENT 3 PASS 2 · ITEM 1 — THE TWO RIVER BRIDGES, written 9 Sep 2026 before building, per Rule 1.**
Both real Malin crossings sit inside S5's circle (S5 §1 — "only two bridges in the entire 2 km box
cross water, and both of them are here").
- **BRIDGE 1, tertiary, near (−640, 740).** 89 m span at 132°, 46 m from the Malin centreline.
  Fully specified in S5: carriageway **7.5 m** (IRC 5, two lanes) · footpath **1.5 m clear, WEST
  side only** · safety kerb **750 mm, EAST side only** — deliberately asymmetric · railings
  **1.1 m** above the deck, bottom gap **≤150 mm**, steel tube + vertical bar panels, white and
  blue paint, rust bleeding at every weld, **3 panels bent**. Deck surface (S-scale, material not
  geometry, PLAN §3 method 2): **16 patches, 11 open potholes 0.2–0.7 m**. Approach embankments
  **90 m each side**, already carried by pass 1's gradient-limited profile.
- **BRIDGE 2, residential, near (−822, 609).** 46 m span at 162°, 21 m from the Malin centreline.
  **S5 does not separately describe this one** — built by IRC 5 class rule, stated as inference,
  not measurement: single-lane carriageway **4.25 m** (IRC 5, narrower than the 4.5 m residential
  road approaching it — a real, common rural detail, not an error) · safety kerb **750 mm both
  sides**, no footpath · railings matching Bridge 1's family, **1.1 m**, ≤150 mm bottom gap.
- **PIERS — a design decision, not a measurement**, because no REF source gives a span/pier
  figure for a MINOR river bridge (only the flyovers have one, REF-01 §11's 22 m spans, sized for
  highway load). Chosen as a realistic RCC slab-on-pier minor-bridge span: **piers at ~15–18 m
  centres**, cross-section **900×900 mm on Bridge 1, 700×700 mm on Bridge 2** (lighter deck,
  shorter span), founded in the riverbed, one pair per pier line under the two kerb lines.
- Both decks **replace the pass-1 flat ribbon exactly over their span** and are held level (or
  near-level) across the water crossing rather than following the conformed ground, which is what
  makes it read as a bridge and not a paved dip.

**COMPONENT 3 PASS 2 · ITEM 2 — THE 9 FLYOVER DECKS, written 10 Sep 2026 before building, per Rule 1.**
The 11 bridge-tagged OSM ways minus the 2 real river bridges (item 1) leave exactly 9 — REF-05 §1's
"the other nine are highway flyovers 1.5 km from any water," now individually identified and
measured, not guessed:
| way id | class | length | centre | note |
|---|---|---|---|---|
| 895269398 | trunk NH534 | 538.4 m | (608,−385) | the "outside S4" NH534 bridge S0b names at (655,−341) — far from every scenario circle |
| 895269401 | trunk NH534;NH734 | 186.4 m | (10,−706) | near S4, 58 m from the rail corridor |
| 895269402 | trunk NH534 | 237.2 m | (197,−656) | the bridge-tagged way closest to S2 (161 m from its centre) |
| 895269403 | trunk NH734 | 259.4 m | (147,−927) | **RAILWAY CROSSING** — 19 m from S0b's rail-crossing point (118,−748) |
| 895269404 | secondary | 69.3 m | (185,−963) | the one non-trunk flyover |
| 895269405 | trunk NH734 | 87.5 m | (106,−719) | **RAILWAY CROSSING** — 13 m from S0b's rail-crossing point (125,−737) |
| 1090943854 | trunk | 350.8 m | (138,−840) | 41 m from S4's own centre — the highway-merge complex deck |
| 1090943857 | trunk_link | 34.3 m | (126,−695) | one of S4's 2 slip roads (S0's own count) |
| 1097355586 | trunk NH534 | 15.8 m | (94,−692) | a short connecting span near S4 |

**A spec correction, same class as several this project has already made:** S2's illustrative text
("NH534 trunk, 2 lanes, on BRIDGES — 124 m at 239°, 121 m at 229°, plus 55 m at grade") does not
match any single OSM way in the real data at those exact lengths — the nearest bridge-tagged way to
S2's centre is 895269402 at 237 m. **No arbitrary override is applied**; each flyover deck uses its
own already-classified pass-1 carriageway width (trunk 14.0 m, trunk_link 7.0 m, secondary 7.0 m)
rather than guessing which piece S2's text meant.

**CLEARANCE — two classes, both measured against what is actually underneath, not generic ground:**
- **The 2 railway crossings** (895269403, 895269405) target a soffit **~7.9 m above local ground**
  — S0b's own derived figure (6.25 m clearance above rail level + ~1.0 m formation + ~0.68 m
  ballast/sleeper/rail). The railway itself (item 3) is not built yet, so this is measured against
  the ground at the crossing today and will still be correct once the formation exists, because
  S0b's figure is already ground-relative. Approach ramp **≤3.5%** (IRC:SP:90 §6.14).
- **The other 7** clear **5.5 m** (IRC:86, minimum vertical clearance on urban roads) above the
  HIGHEST surface actually beneath the span at each sampled point — ground, or another road's own
  deck where one flyover crosses a second road. Approach ramp **≤6%**, the same plain limit as pass 1.

**UPDATE 10 Sep 2026 — the rail crossings' real shortfall, investigated and partly closed.**
MEASURED: at the actual crossing points, the first build gave only 4.83–5.85 m against the 7.9 m
target — 7.9 m at 3.5% grade needs ~226 m of ramp, more than the 9 tagged pieces alone provide.
**Fix: the elevated profile now extends into the CONNECTING ordinary road** at any true dead end
of a rail piece (built-space matching, tolerance 6 m — a real elevated corridor's approach
embankment is not limited to the officially "bridge"-tagged segment). Result: **895269403 and
895269405 now reach 7.80 m and 7.86 m — within 10 cm of the 7.9 m target.** **895269403's own
group also picked up 4 more built pieces this way** (`EXT_1..4`, chained through a genuinely
messy real junction of very short OSM segments) and **1090943857 picked up 5** (`EXT_5..9`).
**895269854 and the 1090943857 sub-group remain short (4.83 m and 0.14–0.81 m)** — traced to a
genuine graph-distance limit, not a bug: their governing anchor is far enough away (through
edges that must also respect a DIFFERENT connecting piece's own grade limit) that even the
extended corridor's reachability bound caps them below target. Closing this fully would need
extending the high-value anchor's OWN side further, a different, deeper change from extending
the low side. Documented so this is a known, explained limit, not a silently accepted miss.

**PIERS — 1800×1800 mm square RCC (REF-01 §11), on piles, at ~22 m spacing (REF-08 §5)** along each
deck's own measured length, same construction as the river bridges' piers but at the flyover's own
(bigger) cross-section. Pier count follows directly from length: 1 on the 15.8 m piece, ~24 on the
538.4 m one.

**BARRIER — not the two river bridges' pedestrian railing.** A crash barrier: **W-beam profile, top
of beam 700–750 mm, posts at 2.0 m** (REF-01 §10), the standard approach-barrier detail, run the
full deck length on both edges.

**COMPONENT 3 PASS 2 · ITEM 4 — THE S2 GYRATORY, written 10 Sep 2026 before building, per Rule 1.**
Numbers from S2-THE-CHOWK.md and REF-01 §6 (IRC 65:2017 Table 6.2, the fixed ICD 40 → island 24 →
circulatory 8 pairing). **Scope is the ROAD GEOMETRY only** — the chowk statue/monument and the
96 surrounding buildings are Component 4/7's job, not this one.
**MEASURED, not assumed, which pieces actually meet here:** every pass-1 `ROAD_*` piece with an
endpoint inside the outer circulatory radius (20 m) gets trimmed at exactly that radius (found by
walking its own points, not guessed) rather than hand-naming which of the ~8 real OSM pieces
converge here — this is a real 5-way junction with two close, separate node clusters ~8–9 m apart
(itself real, not merged into a single point) and at least one one-way pair, and a general
radius-based trim handles that robustly where hand-picking names would not.
- **Central island: radius 12 m** (24 m diameter), raised kerb ~150 mm, planted/grassed top.
- **Circulatory carriageway: 8 m wide** (r 12→20 m), conformed to local ground height, **no lane
  markings at all** — S2's own point: vehicles take whatever line they want.
- **Give-way line at each entry: double line, 200 mm wide, 300 mm apart** (IRC 65:2017), placed
  where each trimmed arm meets the outer edge.
- **Splitter islands**, kerbed, 150 mm high, at each arm — channelization only, not a precise
  one-way-pair reconstruction (the pass-1 pieces already carry the real one-way split).
- **Kerb paint: black-and-white 500 mm bands** on the island edge (S2's own detail: "chipped,
  repainted over old paint" — a wear/dirt pass is Component 8, not this build).
- **No truck apron** — S2/REF-01 §6: the 24 m island is large enough without one.
- NH534's elevated crossing is **already built** (FLYOVER_895269402, pass 2 item 2) — not touched
  here; only the at-grade arms are this item's job.

**COMPONENT 3 PASS 2 · ITEM 5 — THE S5 HILL SWITCHBACK, written 10 Sep 2026 before building, per
Rule 1.** Full numbers already in `S5-THE-MOUNTAIN-ROAD.md` — this is Rule 1 by reference for the
climb's own numbers, plus a new design decision for the PATH ITSELF (S5 never gave hairpin
coordinates, only chainage-based facts along whatever path exists).
**MEASURED the real built hill first, not assumed:** ray-cast (not the ellipse formula) against
the actual `HILL` object (a separate mesh from `TERRAIN`, peaks at 183 m) at 15° bearing steps
around its centre (−1050,900). **The SE-facing flank, bearing ≈90–150°, has the slowest height
falloff** (still 139–150 m at r=50 even where other bearings have dropped to 100–103) — this is
the hill's own long axis, and it is where the real approach road (S5's bridge, already built)
already sits. The climb is designed on this flank, not guessed elsewhere.
**PATH DESIGN — a decision, stated as one:** 4 hairpins as a radius-decreasing zigzag sweeping
bearing 90°↔150° each leg (apexes roughly at r≈245/185/125/65, bearing alternating 150°/90°),
ending near r≈20 (temple parking area — the temple building itself is Component 4's job, not
built here). Height sampled by ray-cast along the actual path, not assumed from the radial probe.
**Scope for this build:** the road itself (3.75 m, widening to 9.0 m at each hairpin apex, 1-in-10
superelevation at hairpins) · retaining wall on the inside (hill side) · parapet/gap/W-beam on the
outside per S5's own chainage table, mapped onto this path's own chainage starting at 0 (matching
S5's "180 m" mark, where the climb begins after the bridge) · the 5-stretch surface material
(good/cracked/washout/patched/good). **Deferred, stated plainly, not a corner cut:** the 5
individual culverts as pipe objects, the landslide JCB/equipment (Life/set-dressing, Component 7),
and the temple + parking loop + hillside settlement (Component 4's buildings).

**COMPONENT 3 PASS 2 · ITEM 6 — S-SCALE ROAD MATERIALS, written 10 Sep 2026 before building, per
Rule 1.** Closes Component 3. Material only, per PLAN §3 method 2 and REF-11 §6 (a mask ribbon,
not cut geometry) — sourced from IRC 35:2015 (REF-01 §2), never invented.
**Network-wide, every paved (non-kaccha) `ROAD_*` object:**
- **Edge line: 150 mm white**, 150 mm in from the carriageway edge (100 mm where paved width <7 m).
- **Centre line only where width ≥5.5 m** (IRC Table 4.3 — a two-way road under 5.5 m gets NO
  centre line): open-country dash, 3 m mark + 6 m gap, at 100 mm.
- **Crumbling edge**: a soft, noise-masked darkening/roughening band **100–300 mm** at the very
  pavement edge before the shoulder — a mask blend, never a hard line (REF-11 §6's own point).
**S1's own located features** (S1-CATTLE-CROSSING.md, measured chainage along the through road
`ROAD_48_1_tertiary`→`ROAD_49_0_tertiary`, chainage 0 = where this combined path crosses the S1
circle boundary, r=205 from (−280,450) — S1's own "209 m" figure is the within-circle length,
matching the S2/S0 convention elsewhere):
- **9 potholes at 34, 88, 89, 141, 196, 240, 241, 243, 302 m**, 0.25–0.9 m diameter, 30–90 mm deep,
  3 patched darker.
- **Speed breaker at 268 m** (IRC 99): 3.7 m long, 100 mm high, black-and-white 300 mm bands.
- **Hume pipe culvert at 158 m**, 900 mm — geometry deferred (a real pipe object), the visible
  water-stain/silting is this item's job as a material mark only.
Positions saved to `map/road_surface_features.json` (the same file bridges already write to), so
Component 7's vehicle-offset system reads one source for every located road-surface feature.

**COMPONENT 3 PASS 2 · ITEM 3 — THE RAILWAY, written 10 Sep 2026 before building, per Rule 1.**
Full numbers already exist in `S0b-THE-RAILWAY.md` — this item is Rule 1 by reference, not a
duplicate. Built from `map/najibabad_rail.json` (22 real rail ways, pulled and saved 3 Sep,
station NBD confirmed at (−551.75,−900.06) against S0b's (−552,−900)).
**Scope for THIS build is Stage 2 blockout only, per S0b's own "WHAT GETS BUILT, BY STAGE" table:**
the formation as an embankment solid (6.85 m single line, 2:1 side slopes, minimum 1.0 m bank
height in flat terrain) · the yard tracks built individually from their own real pulled geometry,
not forced into an idealised even spacing (the real spacing is already IN the data) · station
platform masses at 0.84 m near NBD · the two level crossings as a flat break (the formation tapers
to grade within a short window either side of each crossing point). **Rails, sleepers, ballast are
Stage 3; OHE masts, portals and the catenary are Stages 4 and 9 — explicitly not this build**,
same staging S0b itself specifies. The two road-over-rail decks at 6.25 m clear are **already
built** — they are FLYOVER_895269403 and FLYOVER_895269405 from pass 2 item 2, not a separate task.
**Every way is built individually at its own real width** (6.85 m single line) rather than forcing
a synthetic 12.15 m double-line embankment — a real double track is two adjacent formations with
their own ballast prisms, not one shared platform, and OSM's own way split already reflects that.

## 5 · BUILDINGS — about 1000, from about 30 parts
**Do not model whole buildings.** Model ~30 facade parts — window, shutter, balcony, AC box,
sign board, awning, drainpipe, grille, staircase, water tank, parapet, door, meter box, dish,
drying washing, exposed rebar — and scatter them on plain boxes.
Vary: width 2.9–9.5 m · storeys 1/2/3 · colour, often per floor · clutter mix · ±2° rotation.
**No two buildings on screen may match.** ~400 detailed, ~600 shells.
Every wall: a dust band on the lower 0.6 m, water staining under the tank, one painted
advertisement or poster. Nothing clean, nothing plumb.

**COMPONENT 4 PASS 1 · ITEM 1 — REAL FOOTPRINTS, MEASURED FIRST, written 11 Sep 2026 before
building, per Rule 1.** Sourced from `map/pull_buildings.py` (run 11 Sep), which pulls OSM
`building=*`/`shop=*`/`amenity=place_of_worship` ways plus `landuse=*` zoning polygons in the same
2 km box and frame as the road/rail pulls, saved to `map/najibabad_buildings.json`.
**The honest finding: OSM has almost no traced individual building footprints here** — 8 ways
total in the whole 2 km box (7 generic `building=yes`, 1 place-of-worship), against 42 km of
richly-mapped road. This is normal for a small Indian town on OSM — routing apps map roads,
nobody traces buildings — and it is the same kind of real limit the flyover corridor shortfall
and the S5 grade tension were: measured, not assumed, and it changes the method rather than being
patched over.
**What IS real and is honoured exactly:**
- **7 `building=yes` footprints** at their real OSM polygon and position (none named, no
  `building:levels` tag on any of them — height per REF-03 §3's road-width rule below).
- **St. Mary's Church**, a real place-of-worship node at (1264,−280) plus its own way footprint —
  built as a real, specific building at Component 4 Pass 2, not a generic box.
- **10 real `landuse` zones** (7 residential, 1 commercial, 1 industrial, 1 railway), several
  overlapping the 1 km world box — used to set character/density (commercial = taller, tighter
  frontage, more shopfront parts; residential = the REF-03 §5 kutcha mix further from the paved
  network; industrial = left alone, Component 4 does not build sheds there).
**What is NOT real and must be generated, per REF-03 §4's own stated method for how these towns
actually work — "the frontage is a continuous wall of building, shops face the street with
nothing in front of them, residential sits directly behind"**: every other building is a plot
placed directly on the REAL road network's own frontage line (the roads are real; this is
generating from real geometry, not inventing a location). Plot width drawn from REF-03's own
2.9–9.5 m anti-repetition range, zero setback, both sides of every road that has ANY buildings on
it per the source imagery (S2 chowk and the through-roads — not the open trunk/highway stretches
between villages, which stay fields per Component 3/§3).

**COMPONENT 4 PASS 1 · ITEM 2 — THE FACADE PART LIBRARY, written 11 Sep 2026 before building, per
Rule 1.** REF-03 §2 dimensions (NBC India / IS 6248), REF-09 §1–2 mechanism (a plain box, vertex
groups per face, a module chosen per group — manually where it matters, randomly everywhere else;
storeys added by extruding the top face group by one floor-to-floor height and repeating).
**The part library, each a real NBC/IS-6248 dimension, never guessed:**
window (with sill at 0.9 m, ≥10% of its bay's face area) · rolling shutter (2.4–3.7 m wide, up to
3.0 m high, 75 mm laths) · balcony · AC box · sign board · awning (max 4.5 m long × 2.4 m
projection, ≥2.2 m clear beneath) · drainpipe · grille · exterior staircase · water tank (on the
roof, always with a water-stain module below it) · parapet (≥1.0 m, 1.2 m+ on 3-storey) · door ·
meter box · satellite dish · drying washing · exposed rebar (roof corners, "the storey that never
got built," a fraction of buildings only). Each built by the REF-09 §3 method — inset/extrude/
bevel, real-world scale via Blender's own Edge Length overlay, never eyeballed — then converted,
joined, scale-applied, origin-to-geometry, origin moved to its own base so it instances correctly
onto a wall vertex group.
**Floor-to-floor 3.0–3.15 m** (NBC), extrusion height for every storey. **Height by road width**
(REF-03 §3): roads <6 m → 2 storeys max; the S2 chowk's wider frontage and the trunk-adjacent
stretch → 3 storeys allowed. Two-storey shop-house plinth-to-parapet **7.3 m**; three-storey
**~10.45 m** — these are the two target silhouette heights the box generator builds to, not a
free height roll.
**Anti-repetition draws, per building, all seeded by `zlib.crc32` on the building's own footprint
ID (never Python `hash()`, per the project's own non-determinism rule)**: width from its real or
generated footprint · storeys 1/2/3 per the road-width cap · base colour, often re-rolled per
floor · a clutter draw across the part library · ±2° rotation on the whole box. **Structured
repetition is kept where a real reason repeats it** (a colonnade of identical shutters along one
shopfront, a candelabra-pole spacing) **per REF-09 §11 — the "nothing repeats" rule targets
unstructured repetition (the same building appearing at random), never a row a real cause would
produce.**

**COMPONENT 4 PASS 1 · ITEM 3 — DISTRIBUTION AND DETAIL BY DISTANCE, written 11 Sep 2026 before
building, per Rule 1; REVISED 11 Sep 2026 after building, once more per Rule 1 ("finished means
matches spec exactly" — the spec is what got revised, not the build).**
**The original "~1000 buildings" estimate was written before the real frontage length was known,
and measuring it (same honest-shortfall pattern as the flyover corridor and the S5 climb) showed
it was simply too low a guess: the real network has 50.2 km of paved road eligible for frontage
(every non-kaccha piece except open-country `trunk` stretches outside a real landuse zone). Built
at REF-03's own real plot-width range (2.9–9.5 m) with ZERO gaps, that is ~16,100 buildings — a
100% continuous wall on every residential lane in the whole 2 km box, which is not what REF-03 §4
actually describes ("narrow winding streets, irregular plots, MIXED land use", not uniform
wall-to-wall coverage everywhere). The real fix is a density model, not a forced count: a gap
probability per plot, low (5%) on the real bazaar/through classes (tertiary/secondary/trunk_link)
and rising with distance from the 5 real scenario anchors (S1/S2/S3/S4×2) on the quieter
residential/unclassified/living_street classes, from 30% near the town core to 85% by 500 m out —
dense where REF-03 says the frontage is continuous, thinning into the fields where it says
residential neighbourhoods and irregular plots take over. Built this way: measured 11 Sep 2026, is
**7,819 buildings (546 detailed + 7,266 shells + 7 real footprints)**. This is the corrected
number this spec now commits to — not ~1000. Shell buildings are genuinely cheap (box + at most
one roof item, no tiled parapet — an earlier version gave every shell a full tiled parapet ring
and it out-of-memory-killed the M1 at 15,000+ shells; shells now skip individual parts entirely,
per this item's own "no individual parts" rule taken literally) so this count is not a render-time
concern by construction.
**Detail radius 150 m** (engineering default — the S0 §8 drive is described narratively, not
stored as a coordinate polyline, so proximity to the 5 real scenario anchor points is the
measured proxy for "near the drive route and the S2 chowk") gets full facade-part coverage; beyond
it, box + roof clutter only, correct silhouette (REF-03 §1 — the haze has eaten detail past ~400 m
regardless). The 7 real footprints and the church are always full-shape (their real polygon, not a
template box) regardless of distance, since they are named, real, specific places.
Every wall gets the §5 base treatment (dust band, per-floor colour variation, one painted poster)
via the shared `BUILDING_WALL` procedural material, driven by each object's own hashed Random
value (REF-09's own per-instance-colour mechanism) — cheap, and applied at every detail level
including shells, since it is the dust layer that "ties separate objects together," per §6 below.
**Deferred, honestly, not forgotten**: street vendor carts and stalls (REF-03 §8) — its own
Component 4 Pass 2 item, written before it is built, same as Component 3's items were.

**COMPONENT 4 PASS 2 · ITEM 1 — THE S5 TEMPLE, written 11 Sep 2026 before building, per Rule 1.**
S5-THE-MOUNTAIN-ROAD.md's own "THE TEMPLE — at the top, 1150 m": sanctum with a **latina
shikhara**, whitewashed, **5.2 m overall** on a raised plinth, a small pillared hall in front,
saffron flags on bamboo, a bell at the entrance, tiles worn smooth. **38 stone steps** up from a
small levelled parking area where the road ends in a loop. Two shops at parking: prasad/flowers/
cold drinks, tin-roofed, 3.0 m shutters. A water tank, a hand pump.
**MEASURED before siting, per Rule 1 and the same honesty already applied to the elevation
shortfall**: fixing the duplicate-geometry bug (see the 11 Sep commit) gave one unambiguous real
`S5_CLIMB_ROAD` object — **857.7 m built of S5's own 970 m chainage span, ending at
(−1069.7, 873.8, 101.6), approach heading 311°**. The chainage-1150 spec figure is ~112 m past
this real terminus (the same shortfall category as the 94.6 m of 170 m elevation gain — the built
road is honestly short of the full spec on BOTH axes, not just height). **The temple sits at the
real terminus, not the spec's chainage-1150 point** — wherever a mountain road actually stops is
where its car park and temple steps go, by definition, so this siting decision costs nothing
geometrically; it only means the temple's elevation is ~101.6 m rather than whatever a full 1150 m
climb would have reached.
**Real dimensions (REF-03 §6, its own vimana proportions, scaled to S5's stated 5.2 m overall)**:
base:body:crown 1.68:1.20:0.80 (of a 3.68 m reference total) scales to **base 2.37 m, body 1.69 m,
crown 1.13 m** — the plinth+walls, the tapering shikhara tiers, and the amalaka/kalasha cap.
Modelled by the REF-09 §3 method (inset/extrude repeated, real-world scale, deliberately not
perfectly plumb — "a lot of these ancient things aren't perfectly lined up anyway"). Pillared hall:
~3×3 m, flat roof, 4 pillars, attached to the sanctum's front, per REF-03 §6.
**Steps**: 38 stone steps, same real riser 0.15 m as Component 4's own staircase part (5.7 m total
rise, matching the plinth height above the parking pad). **Parking**: a levelled pad at the road's
real terminus, the loop itself being the turning circle a hill road ends in.
**Two shops**: PART_SHUTTER (3.0 m, already in the library) on a small tin-roofed box, at the
parking edge.
**Deferred to Component 6/7**: the peepal beside it (a tree, not a building), the monkeys, the
water-tank/hand-pump's own small geometry (the roof water tank part already exists; a ground hand
pump does not yet and is a small future item, not blocking).

**COMPONENT 4 PASS 2 · ITEM 2 — THE KUTCHA/RURAL HOUSE MIX, written 11 Sep 2026 before building,
per Rule 1.** REF-03 §5's own real form: frame of wood/bamboo, matting + cow-dung/mud plaster,
thatched roof (grass/leaves/bamboo) that **sags**, **400–600 sq ft** (37.2–55.7 m²), single
storey, 2 rooms + a verandah. **A round bhunga variant, ≈18 ft (5.49 m) diameter**, "found
extensively in Uttar Pradesh" — real, not invented, so both forms are built, not just one.
Every hut gets: uneven wall surfaces, a swept earth yard, a low mud boundary, a fodder stack.
**Deferred to Component 7 (Life)**: the tethered animal — that is a living thing, not geometry.
**Placement, closing the gap Item 3 left open**: `04b_buildings.py`'s own density model already
computes real "gap" plots on the quieter residential/unclassified/living_street classes (30–85%
skip probability, rising with distance from the 5 scenario anchors) — those gaps were left
genuinely empty. **A fraction of them (40%, an engineering default — REF-03 does not give a
rural-infill ratio, and "not a town, a scatter" per S5's own hillside-settlement language argues
against 100%) now get a kutcha hut instead of staying empty**, seeded the same deterministic
crc32 way as every other draw in that script. The other 60% of gaps stay open ground — a real
rural scatter has working fields and yards between houses, not continuous building.
**Never on the town's own paved-frontage classes** (tertiary/secondary/trunk_link) — kutcha
housing is specifically the rural counterpart to the pucca shop-house frontage, per REF-03 §5's
own title, so it only fills gaps on residential/unclassified/living_street.

**COMPONENT 4 PASS 2 · ITEM 3 — STREET VENDOR CARTS AND STALLS, written 11 Sep 2026 before
building, per Rule 1.** Closes Component 4. REF-03 §8's own real manufacturer sizes, never
invented: **tea cart (chai thela) ~4 ft (1.22 m) long** · **steel thela 6×3×7 ft
(1.83×0.91×2.13 m, the 7 ft including the canopy frame)** · **fruit/vegetable cart 5×3 ft
(1.52×0.91 m), bed height ~0.75 m**. Rule of thumb for the shared frame: **1.2–1.8 m long,
0.7–0.9 m wide, bed at 0.75 m, canopy at 2.0–2.2 m**, bicycle-type wheels ~0.6 m diameter (two
at one end, a prop stand at the other), a tarpaulin/sheet on a light frame, weighted with bricks,
**sagging between corners** — REF-03's own explicit point, same "never a hard line/flat plane"
principle already applied to the road markings and the kutcha roof.
**Placement, causally — carts cluster where there is foot traffic to sell to, never scattered at
random** (REF-09 §11's own "repeat what a reason would repeat"): one cart per **detailed**
building only (the ~150 m-of-a-scenario-anchor tier already computed in Item 3's own
`is_detailed()`), at a **60% draw** (engineering default — not every shopfront has a cart outside
it, but enough do that a real bazaar frontage reads busy), positioned at the building's own front
edge, offset sideways per-building so a row of carts does not overlap. **Never on kutcha
plots or shells** — a vendor cart belongs to the paved shopfront frontage a real customer walks
along, not a rural yard or a background box nobody will get close enough to see.
**Three real cart types, drawn per-placement** (REF-03 §8's own three named sizes, not one
generic box): the steel thela (tallest, a canopy frame + tarp), the tea cart (shortest, a simple
counter), the fruit/veg cart (open bed, no canopy — REF-03 does not describe one on this type).
Each built as one combined multi-material mesh per instance (same `material_index` technique
`04b_buildings.py`'s kutcha huts already use, for the same reason: thousands of tiny separate
objects measurably cost real Blender-side overhead at this project's own object counts).

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
