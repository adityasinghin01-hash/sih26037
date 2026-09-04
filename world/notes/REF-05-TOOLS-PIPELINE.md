# REF-05 · TOOLS, THE MAP PIPELINE, AND WHAT IS PROVEN
Written 3 Sep 2026. **Everything here was run, not read.**

## 1 · THE MAP PIPELINE — real place in, both tools out
1. **Choose by measuring, not looking.** Query Overpass for a 2 km box around each candidate,
   clip to the box, and count road km by class, junctions, bridges, water.
   Najibabad won: 42 km road · 3.7 km national highway · 20.3 km residential lanes ·
   32 junctions · the Malin river.
2. **Pull the data two ways.** `[out:json]` for analysis; `[out:xml] ... (._;>;); out meta;`
   for a real `.osm` file.
3. **MATLAB reads the .osm directly:** `roadNetwork(scenario,'OpenStreetMap',file)`.
   **It takes over 10 minutes — always run it in the background.**
   Export the road centres to CSV and that CSV is the source of truth.
4. **Blender is built from MATLAB's CSV**, not from an independent projection.
   **This is what removes the seam.** Same numbers, one source, cannot drift.
5. **Frame offset measured: (+35.0, −100.0) m** from MATLAB's frame to the OSM metric frame
   (origin 29.61180 N, 78.34210 E, equirectangular). After removing it: median agreement
   **1.05 m**, 90th percentile 3.08 m, 97.3 % within 5 m across 6.3 km.
   MATLAB splits ways at junctions (425 segments from 214 ways) and resamples centrelines —
   that resampling is the residual metre or two, not error.

**Do NOT trust tags without checking geometry.** The box has 11 tagged bridges; **only two
cross the river.** The other nine are highway flyovers 1.5 km from any water. Always measure
the distance from a bridge to the waterway before believing it.

**OSM building data is useless for small Indian towns** — 6 to 20 buildings mapped per town
where thousands exist. Take the roads; build the buildings ourselves.

## 2 · TOOLS THAT WORK ON THIS MACHINE
| Tool | Verified |
|---|---|
| Overpass API from plain Python `urllib` | yes — no addon, no account, no cost |
| MATLAB R2026a headless | `matlab -batch "run('/path/x.m')"` — **background it** |
| Blender 4.5.11 headless | `Blender --background <file> --python <script>` — 10 s builds |
| `pdftotext -layout` (poppler) | **the way to read IRC standards.** WebFetch cannot parse PDFs |
| `yt-dlp` + `ffmpeg` | download a tutorial, tile frames into a contact sheet, read it |
| **Headless Chrome → PNG** | `--headless --screenshot=out.png --window-size=W,H file://...` — how the city plan was drawn |
| `sips` (built-in macOS) | crop and upscale a frame to inspect detail — how the pole top was found |
**No paid Blender map importer is needed.** Blosm exists but we do not use it.

## 3 · BLENDER MEMORY RULES — researched, not guessed
- **Instancing is the single biggest lever.** Linked duplicates share one copy of the mesh data.
- **Textures cause out-of-memory far more often than geometry does.** A few 4K PBR sets will
  kill 8 GB while a million faces will not. **Cap textures at 1–2K** (Simplify panel).
- Stay under **150,000 instances**; past ~250,000 the 8 GB unified memory swaps.
- Grass textures 512–1024. 2K only for what is close to camera.
- Render 1920 × 1080 — the source footage is 848 × 478 anyway.
- **Never put Volume Scatter on the World** — it makes the sky infinitely distant and the render
  comes out pure black. Use a bounded box with the camera inside it.
- Split large scenes into linked library files; hide non-critical collections while working.

## 4 · MEASURE, DON'T ASSERT — the checks that caught real errors
- **Canopy cover:** cast 5 rays straight up per 2 m of road, count hits. Tuned the tree setback
  by sweeping until the measurement hit the 62 % / 45 % target.
- **Gradient audit:** walk the vertical profile and report the maximum, excluding the speed
  breaker. Caught a 9 % bridge ramp that should have been under 5 %.
- **Clearance audit:** lowest conductor minus sag, compared with the legal minimum.
- **Frame comparison:** point-to-**segment** distance, never point-to-point — point-to-point
  gives a false 46 m error simply because vertices are sparse.
- **Geometry beats assertion:** the bend is blind because the set-back is 4.0 m where the code
  needs 6.1 m. That is defensible; "I made it blind" is not.

## 5 · ERRORS THIS PROJECT HAS ALREADY MADE — do not repeat
1. Added transition curves **on top of** the full deflection — bend came out 60 m too long.
2. Bridge approach ramps of 30 m → a **9 % gradient**. A road is not a ramp.
3. Divided carriageways **swapped** — India drives on the left.
4. Put a hill at the **centre of a curve**, where a forward camera never sees it.
   **A road that circles a hill never faces it.** Put it ahead on the approach instead.
5. Called a troop of **macaques** "dogs" until the frame was cropped and enlarged.
6. Called kans grass "scrub".
7. Built **11 m** poles when the standard is 9 m.
8. Guessed a flat 3-pin cross-arm when every real pole is a **candelabra**.
**Every one of these was caught by measuring or by looking closely at the real footage.**

## 6 · THE ORDER OF WORK
place → map → city plan → **research scoped BY the plan** → scripts → build stages.
**Research after the map, never before.** The map decides what exists, so it decides what is
worth looking up — and it gives the research a stopping rule: *nothing on the map lacks a number.*

## 7 · CAPABILITY CHECK ON THIS BLENDER — run 3 Sep 2026, 4.5.11 LTS
**Everything REF-06 to REF-11 depends on was verified by running it, not by assuming.**

| Capability | Operator / type | Status |
|---|---|---|
| **Sapling Tree Gen** (REF-10 §2) | `bpy.ops.curve.tree_add` | **works** |
| **A.N.T. Landscape** (REF-07 §2) | `bpy.ops.mesh.landscape_add` | **works** |
| **Landscape Eroder** — the gully tool | `bpy.ops.mesh.eroder` | **works** |
| **Images as planes** — alpha cards (REF-10 §0) | `image.import_as_mesh_planes`, `import_image.to_plane` | **works** |
| **Multires + bake from multires** (REF-10 §4) | `object.multires_subdivide`, `render.use_bake_multires` | **works — Grant Abbitt's Blender-5 method transfers to 4.5.11** |
| **Ambient Occlusion node** — the double-stack (REF-09 §5) | `ShaderNodeAmbientOcclusion` | **works** |
| **Particle Instance modifier** — cloth-sim grass (REF-11 §4) | `PARTICLE_INSTANCE` | **works** |
| Every geometry node the tree and scatter graphs need | see below | **works** |
| Edge Length overlay (REF-09 §4) | `View3DOverlay.show_extra_edge_length` | **exists** |

**A NAMING TRAP that cost one wrong result:** the spline factor node is **`GeometryNodeSplineParameter`**,
NOT `GeometryNodeInputSplineParameter`. Also: **bundled add-ons are EXTENSIONS in 4.5 and do not appear
in `addon_utils.modules()`** — they showed as "missing" until I tested the operator instead. **Test the
operator, never the module list.** Same for RNA properties: `hasattr(type, prop)` returns False for
properties that exist; search `bl_rna.properties` instead.

**AND THE BETTER ANSWER FOR US:** we build headless, so the viewport overlay is irrelevant.
**`edge.calc_length()` and `object.dimensions` return exact metres in the script** (verified: a cube
built at size 7.0 measures 7.0). **So every dimension gets ASSERTED IN THE BUILD SCRIPT rather than
eyeballed in an overlay.** That is stronger than what any of the tutorials do, and it is what would
have caught the 5.6 m road, the 280 mm median and the 13 m poles.

## 8 · THE RAILWAY DATA — pulled 3 Sep 2026, `map/najibabad_rail.json`
The first Overpass query for the railway was **never saved to disk**; the geometry was lost with that
session and only the numbers in `scenarios/S0b-THE-RAILWAY.md` survived. Re-pulled and saved.
**Projection verified against S0b:** Najibabad Junction **NBD lands at (−552, −900)**; S0b recorded
(−552, −895). **5 m apart — the rail frame and the road frame are the same frame.**
- **22 rail ways · 44,373 m total · 10,217 m inside the 2 km box** (S0b said 12,055 m — my clip test is
  stricter, requiring both segment ends inside; **the honest figure is ~10.2 km**).
- **9 ways tagged `electrified=contact_line`; 7,208 m of electrified track inside the box.**
- **The yard, measured by counting track crossings on vertical section lines:**
  8 tracks at x=−900 · 9 at x=−700 · **9 at the station (x=−552)** · **10 at x=−400** · 6 at x=−200 ·
  4 at x=0 · 3 at x=200. **Track spacings measured at 4.3–5.4 m in the core, with wider 8.8–17.7 m
  gaps between groups.** S0b assumed a uniform 5.30 m; **the real yard is grouped, not evenly spaced.**
- `landuse=railway` polygon: **x −1447…62, y −1071…−752** (S0b estimated −1400…0, −1100…−760).
- **Two level crossings in the box at (544, −665) and (542, −671)** — S0b said (543,−670), (548,−658).
- **Nearest rail to S4 centre: 45 m. To S2 centre: 74 m.** S0b said 48 m and 56 m.
- **No railway way is tagged `bridge`** — the crossings are carried on the ROAD ways, which is
  consistent with the 11 bridge-tagged highway ways we already have.
