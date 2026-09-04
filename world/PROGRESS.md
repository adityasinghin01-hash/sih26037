# THE WORLD — where Aditya's stream is, and what is done
**Updated 4 September 2026.** This folder is the 3-D world the car drives in: the map, the
environment scripts, the reference library, the build scripts and the progress renders.
**Aditya owns this stream.** Streams C, D and E do not need to build any of it — but this is where
you can see what the film will look like and what the simulation is driving through.

## THE PLACE IS REAL
**Najibabad, Bijnor district, western Uttar Pradesh.** Chosen by measuring five candidate towns from
OpenStreetMap, not by looking at pictures. In a 2 km box: **47.3 km of road in 213 separate pieces ·
NH534 + NH734 · 23.6 km of residential lanes · 23 junctions · the Malin river · 10.2 km of
electrified railway including Najibabad Junction.**
**Only the hill and the temple are invented. Everything else exists.**

**The seam that would have killed us is closed:** MATLAB imports the same `.osm` directly, and the
two frames differ by a pure translation of (+35.0, −100.0) m. After removing it the agreement is
**1.05 m median, 97.3 % within 5 m across 6.3 km.** So the road the planner drives and the road we
render are the same numbers by construction, not by coincidence.

## WHAT IS DONE
| | |
|---|---|
| Reference footage studied | 13 dashcam clips + 3 bus clips, 234 frames |
| The real map, proven in both MATLAB and Blender | `map/` |
| The city plan | `renders/map_02_cityplan.png` |
| **The reference library — REF-01 … REF-12** | `notes/`, indexed by `READ-FIRST.txt` |
| **Six environment scripts + the railway addendum** | `scenarios/` |
| **Component 1 — LIGHT** | built, 22 assertions passing |

## HOW IT IS BEING BUILT
**Component-major, not stage-major** — see `PLAN.md`. One component taken all the way through
(shape → detail → sculpt → texture) before the next begins.
**Order, and it is a dependency chain:**
`light → land → roads → buildings → infrastructure → vegetation → life → blending`

**Everything is a script, run headless.** Blender's GUI is never used to build. Each script
**asserts its own dimensions in metres and fails loudly** if they do not match the specification.
That is what catches the errors: on component 1 it caught a doubled scale factor and a silent
location reset before a single picture was looked at.

## THE SKY IS MEASURED, NOT GUESSED
Sampled from 43 daytime frames of Aditya's own dashcam:
**R191 G188 B183 — 4.6 % saturation, warm grey, NOT blue.** The Indo-Gangetic aerosol load flattens
the sky almost to white. The bus footage, shot at monsoon midday, measures **17.2 % and blue** — a
completely different sky. **The film uses the dashcam condition.**
Nishita parameters were then found by sweeping against that target: **Air 2.0 · Aerosols 10.0 ·
Ozone 1.0.** The sun is at **elevation 7.53°, azimuth 95.24°** — computed for 29.6118 N, 78.3421 E,
25 Sep 2026, 06:45 IST.

## WHAT IS DEFERRED, AND WHY
**See `DEFERRED.md`.** Nothing is forgotten; each item names what is wrong and what fixes it.
Headline: the dramatic volumetric cloud variant is built and working but **reads as rock rather than
vapour** — a shading problem, not a memory one. And **6 of the 13 clips are shot at night, a
condition no scenario script covers.**

## NEXT
**Component 2 — LAND.** Terrain, the Malin, the 170 m hill with its gully network, the distant range.
