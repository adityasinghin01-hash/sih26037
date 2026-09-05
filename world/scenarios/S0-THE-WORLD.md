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
Date: **25 September.** Time **06:45.**
**Sun elevation 7.5°, azimuth 95.2°.** — **CORRECTED 3 Sep 2026 by computing the real solar position
for 29.6118 N 78.3421 E, 25 Sep 2026, 06:45 IST (NOAA algorithm).**
The written azimuth of **095° was already correct** — it is the real value to within 0.2°.
What was wrong was the description: at this date and time the sun is **5° SOUTH of due east**, not
north of it. And the elevation at 06:45 is **7.5°, not 10°** — 10° does not occur until about 07:00.
**06:45 is kept because S2 depends on it** ("14 shutters up, 8 down, at quarter to seven"), so the
elevation moves to match reality instead. **A lower sun is also the better picture:** longer shadows,
and more backlight through the kans grass, which is what the Translucent BSDF is for (REF-11 §3).
Sky: Nishita. **Air 2.0 · Aerosols 10.0 · Ozone 1.0 · Background strength 0.25.**
**MEASURED 4 Sep from Aditya's own 13 dashcam clips, not guessed.** 43 daytime frames sampled:
**R191 G188 B183 — saturation 4.6 %, brightness 187/255, and WARM grey, not blue.**
This is the Indo-Gangetic plain; the aerosol load flattens the sky almost to white.
For contrast, his BUS footage (monsoon midday) measures **17.2 % saturation and blue-dominant** —
a completely different sky. **The film uses the dashcam condition.**
Parameters found by sweeping Nishita against that target; **above aerosols 10 the result stops
changing**, so the remaining warmth comes from the HAZE COLOUR, which must be warm tan, not blue.
Cloud: **thin, wispy, warm-lit cirrus streaks — NOT cumulus and not a solid stratus sheet.**
At 4.6 % saturation the sky is nearly featureless; cloud reads as faint warm streaks only.
**6 of the 13 clips are shot at NIGHT** — a condition the scripts do not yet cover.
**Haze: visibility 800 m → Koschmieder α = 3.92/800 = 0.0049**, and that number IS Blender's
Principled Volume Density. A **noise texture into Density** so it is wispy, never uniform.
Wind 0.5 m/s from the north-west — it decides which way leaves drift and washing hangs.

## 3 · THE LAND
Alluvial plain, falling gently south. Three scales of undulation (600 m swells, 160 m, field
scale) plus **abandoned river channels** as shallow broad depressions and **field bunds every
~75 m** as 0.25–0.45 m stepped terraces. **The ground is never flat anywhere.**
**The Malin river** crosses the north-west, bed of boulders, cobbles and sand — Shivalik streams
carry heavy sediment, so never mud. Two real bridges cross it; the nine other tagged "bridges"
in this box are **highway flyovers 1.5 km from any water** and must not be built as river spans.

**THE ONE THING WE ADD: a hill**, centred about (−690, 980), roughly 500 × 350 m at the base,
**170 m** high, long axis running north-west. Ridged, with a **branching network of gullies** —
the Shivalik drainage density is 4.55 km of channel per km², so many small gullies, not two.
It is marked as ours on the city plan. Nothing else in this world is invented.
Behind it, a distant range at y ≈ 1900, ~340 m, a pale silhouette through the haze.

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
