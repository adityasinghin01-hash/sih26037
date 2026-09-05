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

## 7 · CAPABILITY CHECK ON THIS BLENDER — **RE-RUN AND CORRECTED 4 Sep 2026**
**THE 3 SEP ENTRY WAS WRONG AND IS REPLACED.** It claimed Sapling, A.N.T. Landscape and the
Landscape Eroder were "verified working". **They were not installed at all.** They are not bundled
with Blender 4.5 — they moved to extensions.blender.org. Every one of them failed when actually
invoked on 4 Sep.
**Now genuinely installed and verified by running them:**
```
blender --online-mode --command extension sync
blender --online-mode --command extension install antlandscape       # A.N.T. + the Eroder
blender --online-mode --command extension install sapling_tree_gen
blender --online-mode --command extension install dynamic_sky
# then, once: bpy.ops.preferences.addon_enable(module="bl_ext.blender_org.<id>")
#             bpy.ops.wm.save_userpref()
```

### **THE RULE THAT MATTERS MOST — and it is new**
**`bpy.ops.wm.read_factory_settings(use_empty=True)` DISABLES EVERY EXTENSION.**
Every build script starts with that line. **So every script that uses A.N.T., the Eroder or Sapling
must re-enable them IMMEDIATELY AFTER it**, or the operator silently is not there:
```python
bpy.ops.wm.read_factory_settings(use_empty=True)
for m in ("bl_ext.blender_org.antlandscape","bl_ext.blender_org.sapling_tree_gen"):
    bpy.ops.preferences.addon_enable(module=m)
```
Proved by A/B: the same operators pass before the reset, fail after it, and pass again after
re-enabling. This is a stronger form of the extensions trap noted below.

### FOUR TRAPS FOUND BY RUNNING, NOT READING
1. **`bpy.ops.mesh.loopcut_slide` SEGFAULTS in background mode.** It is an interactive MACRO and
   needs a viewport. **Use `bpy.ops.mesh.subdivide(number_cuts=n)` or `bmesh.ops.subdivide_edges`.**
   Crash confirmed in `wm_macro_exec`. Assume the same of any macro operator.
2. **A.N.T.'s `height` parameter is IGNORED through the operator.** Asked for 170 m, got 1.0 m,
   three times over. **Set height by scaling the object and ASSERT it.** Exactly the silent
   scale-factor class of bug Rule 4 exists for.
3. **The Eroder rejects non-square grid spacing** (its own source, tolerance 1e-3):
   `500 x 350 m at 257 x 257` is **REJECTED** (spacing 1.9531 x 1.3672).
   `500 x 350 at 257 x 180` **passes** (1.9531 x 1.9553). `500 x 500 at 257 x 257` is exact.
   **And it rescales height into grid units** — a 0–1 m input came back 0–7478 m.
   **So: erode first, rescale to metres after, assert last.**
4. **Node name traps, in the same family as `GeometryNodeSplineParameter`:**
   `bpy.ops.mesh.inset` NOT `inset_faces` · `GeometryNodeInputTangent` NOT
   `GeometryNodeInputCurveTangent` · `GeometryNodeCurvePrimitiveCircle` NOT `GeometryNodeCurveCircle`.
   **`ShaderNodeTexMusgrave` no longer exists** in 4.5 (folded into the Noise Texture).

### THREE MORE TRAPS, found 4 Sep while building the clouds
5. **A GEOMETRY-NODES *VOLUME* IGNORES THE OBJECT'S MATERIAL SLOTS.** `object.data.materials.append()`
   sets the material on the MESH datablock; the modifier outputs a VOLUME component, which carries
   its own material list. **You must add a `GeometryNodeSetMaterial` INSIDE the tree**, after
   `MeshToVolume`. **Proved by A/B: "no material" and "my material" rendered pixel-identical** until
   Set Material was added, then the image changed completely. This silently wasted a whole shading pass.
6. **`MeshToVolume`'s `Interior Band Width` IS the edge falloff** the cloud work needed — it controls
   how far the density fills inward from the surface, so a large value gives the soft,
   semi-transparent boundary that stops a cloud reading as rock. It is a built-in, not something to
   build in the shader.
7. **THE VIEW TRANSFORM INVALIDATES ANY COMPARISON AGAINST A PHOTOGRAPH.** Blender 4.x defaults to
   **AgX**, which desaturates hard and warms everything. Measuring a render against a measured photo
   through AgX is meaningless. **Use `scene.view_settings.view_transform='Standard'`** for any
   matching work. Also: **Nishita at background strength 1.0 is ~4 stops over** — it blows to pure
   white, and an auto-exposure computed from an already-clipped frame CANNOT converge in one step.
   **Iterate the exposure.** Ours settled at **-3.06 stops**.
8. **`camera.matrix_world` is STALE until `bpy.context.view_layer.update()`** — a camera-aim check
   read the default orientation and reported the camera looking 180 deg away from where it actually
   pointed. **Aim cameras the way the SUN is aimed** (`vector.to_track_quat('-Z','Y').to_euler()`),
   never with hand-built Euler angles.

9. **THE VIEWPORT FAR-CLIP IS 1000 m BY DEFAULT, AND IT HIDES THE SKY.** Our cumulus base is
   1400 m and the cloud field is 44 km across, so **on opening a build in the GUI every cloud sits
   behind the far plane and is simply not drawn** — the sky looks empty and nothing is wrong with
   the scene. **Volumes also do not appear in Solid or Material shading at all; only in Rendered.**
   **`clip_end` CAN be baked into the file and does persist** — set `space.clip_end=60000` in every
   build script. Done in `01_light.py` and in `build/city/viewport_setup.py`, which runs against any
   .blend.
   **`shading.type='RENDERED'` CANNOT be baked — Blender resets it to SOLID on save.** Verified by
   setting it, saving, reopening: it comes back SOLID every time, in background mode. **So the human
   must press it: `Z` then pick Rendered.** Do not waste time trying to script it.

### THE ERODER'S REAL PAYLOAD — 10 vertex groups, and they are the gully network
Running it produces **`rainmap, scree, avalanced, water, scour, deposit, flowrate, sediment,
sedimentpct, capacity`**. `water`/`flowrate` IS the drainage network as a mask; `scree` and
`deposit` place the debris. **That is measured drainage, not painted noise** — which is exactly
what S0 §3 and S5 need for the 4.55 km/km² figure. 64,816 of 66,049 vertices moved, in 4.3 s.

### FULL TECHNIQUE AUDIT — 37/37, every method in REF-01..REF-12, PERFORMED
Terrain + Eroder + image Displace (Non-Color, UV) + height-layer stacking + true displacement ·
height and slope masks · water as a solid with a volume depth gradient · 4D cloud shadows ·
inset/extrude storeys · spin · radial array by object offset · **the AO double-stack** ·
the texture-variation recipe · scatter-along-curve · Simplify 2K + split-sky + compositor ·
**Sapling with its prune envelopes** · alpha cards via images-as-planes · **multires normal bake** ·
Skin/Twist/Bend/Remesh for gnarled trees and roots · particle layers · **hair dynamics** ·
wind + turbulence · translucent grass · clumping by noise into density AND scale ·
road-as-material-mask · the volumetric cloud pipeline + Volume Displace · volume render settings
and passes · Nishita · the camera-parented sky plane · god-ray occluders · curve→road/tree chains ·
straight-strip road UVs · loop cuts · exact metre measurement · ray-cast · linked duplicates.

**Sapling's prune envelope measurably delivers REF-06's constraint operators**, in metres:
free-standing crown **8.91 m** → crowded 5.46 → wire-cut 4.50 → squeezed 2.57 → lopped 1.93.
**Note: `prune=True` also creates a helper object named `envelope` — delete it in the build.**

**Dynamic Sky installs but registers NO operator in 4.5 — unavailable.** Not a blocker; Nishita is
the specified method and REF-12 §2 only ever listed Dynamic Sky as a convenience.

**AND THE BETTER ANSWER FOR US:** we build headless, so viewport overlays are irrelevant.
**`edge.calc_length()` and `object.dimensions` return exact metres in the script** (re-verified:
a cube built at 7.0 measures 7.000000). **So every dimension gets ASSERTED IN THE BUILD SCRIPT.**
That is what caught the 5.6 m road, the 280 mm median and the 13 m poles.

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

## 10 · WHAT BUILDING THE LAND TAUGHT — 4 Sep 2026, component 2
**Nine real bugs, every one found by an assertion or by looking. Listed so nobody pays twice.**

**a · THE ERODER SCRAMBLES VERTEX ORDER — the most expensive trap of the day.**
After `bpy.ops.mesh.eroder`, vertex *i* is **no longer** at grid position `(i % NX, i // NX)`.
Measured: `|x − expected|` reached **573 m on a 500 m hill**. So every `.reshape(NY, NX)` after
erosion operated on shuffled data — smoothing averaged random neighbours, and a form-blend added
the dome's height at one place to the eroded height of somewhere else entirely. **That, and
nothing else, is what turned the hill into a field of spikes.**
**Fix: rebuild the grid index from each vertex's ACTUAL x,y after the operator runs.**
```python
gj = np.clip(np.round((co[:,0]+W/2)/(W/(NX-1))).astype(int), 0, NX-1)
gi = np.clip(np.round((co[:,1]+L/2)/(L/(NY-1))).astype(int), 0, NY-1)
```
**Never assume vertex order survives an operator.**

**b · `object.dimensions` IS A BOUNDING BOX AND IT WILL LIE TO YOU.**
A hill assertion passed at "170.0 m" while the **median height was 0.03 m** — one vertex of 46,260
reached the top and satisfied the box. **Assert on MASS: the median height, and the fraction of
vertices above half height.** A shape test that any single spike can pass is not a test.

**c · EROSION CARVES; IT DOES NOT BUILD.** Run alone on a dome it left a median of 10.6 m on a
170 m hill — a hollow shell. **Keep the analytic form as the skeleton (~80 %) and let erosion
supply the gully texture (~20 %).** And smooth the eroded component before blending.

**d · A LEVEL WATER PLANE ONLY WORKS LOCALLY.** REF-07 §10b's "drop a flat plane" is right for one
scene; across 4 km of plain that falls 14 m it leaves the river **buried upstream and floating
downstream.** **Rivers flow: carve the channel bed to a MONOTONIC descent along the course, then
sit the surface on it.** Smooth first, *then* enforce descent — the other order lets the smoothing
put uphill sections back, and an assertion caught exactly that.

**e · THE WATER SHEET MUST BE WIDER THAN THE CHANNEL, NOT NARROWER.** Measured cross-section: bed
0.29 m, water 3.13 m, bank still below water at ±70 m and only clearing at ±100 m. A 31 m sheet
**ended in mid-air.** REF-07 §10b's real point is that the TERRAIN cuts the bank line — so the
sheet must extend past the bank and let the ground rise through it.

**f · A RIBBON MESH SELF-INTERSECTS AT BENDS.** Offsetting ±125 m from a centreline sampled every
~54 m crosses the two edges over at every meander; the inverted quads render as **black holes.**
**Build the water on the SAME GRID as the terrain** — it follows the course exactly and cannot
self-intersect by construction.

**g · A SHAPE MUST REACH ZERO AT ITS OWN MESH BOUNDARY.** The hill's ellipse was 0.54× the
footprint, so at the edge midpoints it still stood **32 m in the air** — a floating rim with a
visible cavern under it. Inscribe the ellipse exactly, clamp the last few percent, and then
**sink the object by its OWN measured rim height** so it is self-correcting.

**h · SUB-CELL FEATURES SIMPLY DO NOT EXIST.** 0.9 m irrigation ditches on a 6.67 m grid fell
between samples entirely (max depth 0.03 m). **Either widen the feature to something the grid can
carry, or build it as a material, never as geometry.**

**i · SLOPE IS THE WRONG MASK ON A PLAIN**, and at fine cell sizes it is the wrong mask on a hill
too: on the raw eroded field **94 % of faces read as "steep"** because normal.z had a median of
0.046. Use HEIGHT as the primary mask; keep slope for genuinely vertical faces.

**j · THE BLACK BAR WAS THE WATER *VOLUME*, NOT THE SOLIDIFY RIM — and the wrong fix was already
applied.** 5 Sep 2026. The 4 Sep session ended having *reasoned* that a hard black bar across the
hill's base was the water shell's rim, and wrote the fix `solidify.use_rim=False`. Next session:
**that fix was already in the script AND in the saved .blend, and the bar was still there.**
Measured instead of argued:
- **Ray-cast through the black pixels.** Hit object `WATER_MALIN`, **hit normal +1.000** — the
  water's own TOP face, at a constant z=5.66 m over a 400 m span. Not a rim, not a wall.
- **A/B, one change per render, scored as the fraction of the strip under luminance 0.02:**
  as-is **36.3 %** · Volume unlinked **1.5 %** · Transmission Weight 0 **0.0 %** ·
  Solidify removed **12.3 %**. **The Principled Volume is the cause; solidify is secondary.**
- **Why:** density 0.26 in a *constant* 2.5 m slab, viewed at ~800 m grazing, refracts into a long
  in-medium path and extinguishes to nothing. Beer-Lambert does not care that it is "only 2.5 m
  thick" when the ray travels along it.
**AND THE SLAB HID A SECOND BUG:** constant thickness means **no depth gradient at all**, which is
the only reason REF-07 §10b puts a volume in water. The build claimed the effect and never had it.
**THE FIX IS A SHAPE CHANGE, NOT A FLAG:** the water is a **closed wedge whose bottom IS the river
bed** — depth = surface − terrain, zero at the waterline, full in the channel; top sheet and bottom
sheet **share their boundary ring**, so the solid is watertight and manifold with **no rim faces to
render**, and it pinches to nothing exactly where it meets the bank. The bar becomes impossible by
construction. Solidify is deleted; `use_rim` is irrelevant once the mesh is a real solid.
**THE PROCESS LESSON, which is the expensive half:** a diagnosis reasoned from geometry survived a
whole session and a rebuild because nobody made it prove itself. **One ray-cast settled it in 40 s.**
This is the fifth time on this project. REF-05 §5 error 4 and the sky-seam entry in §7 say the same
thing. **A/B it or ray-cast it. Never argue about it.**

## 11 · WHAT BUILDING THE ROADS TAUGHT — 5 Sep 2026, component 3 pass 1
`build/city/03_roads.py`. All 213 OSM ways, built from `map/matlab_roads.csv`, 587 pieces,
~21 s, every assertion passing. **Six bugs, every one caught by an assertion or by a probe.**

**a · CLASSIFY PER POINT, NOT PER SEGMENT.** Matching each of MATLAB's 425 exported segments to
its nearest OSM way left **11 of the 213 ways with nothing** and four class counts short. Measured:
all 11 have CSV points **0.07–4.58 m** from them — they are SHORT ways (39–134 m) that lost the
arg-min to a longer neighbour. **MATLAB's export was fine; the classifier was the bug.** Assign
each point to its own nearest way, mode-filter so it cannot flap at a junction, then split each
segment into runs of one way. **A MATLAB segment legitimately spans several ways of DIFFERENT
class, so one width per segment would have been wrong anyway.** 213/213 after the change.

**b · ONE PROFILE PER SEGMENT, SLICED — never recomputed per piece.** Smoothing and
gradient-limiting each split piece on its own made neighbours disagree at the vertex they share.
That was the **visible break and offset block in the trunk road at the chowk.**

**c · THE CONFORM AVERAGE MUST NOT START FROM THE TERRAIN.** Accumulating the road profile into
`Hc = H.copy()` and then dividing by the weight sum mixed the untouched ground into the weighted
mean: the ribbons came out a **median of 5.7 m above the ground**. Accumulate into a zero array.
**Caught by the float assertion, which is the only reason it was found at all.**

**d · MOST ROADS ARE NARROWER THAN ONE TERRAIN CELL — REF-05 §10h again.** The grid is 6.67 m and
a residential lane is 4.5 m, so however well the corridor is levelled the ground **interpolates
back up between nodes and pokes through a flat ribbon** — the ragged, half-buried edges. Two fixes,
both physically right: conform a corridor **never narrower than ~1.15 cells** (a real road sits on
a formation wider than its carriageway), and hang a **0.55 m shoulder skirt** below each road edge
so terrain cannot break the surface **by geometry rather than by tuning**.

**e · THE RIBBONS WERE ALL WOUND UPSIDE DOWN.** A probe returned **normal.z = −1.000** across the
whole carriageway: we had been looking at the underside of every road. Whether `(a,b,d,c)` comes
out clockwise depends on the sign of the offset normal and the direction of travel, so **it cannot
be fixed by choosing an order once** — measure the mean face normal and flip. Same lesson as
REF-07 §5's `Shift+N` for the water solid. **Now asserted per road.**

**f · A ROAD SEEN AT A GRAZING ANGLE IS PALE, AND THAT IS CORRECT.** At driver's eye height the
carriageway measured R63 G69 B74, blue-tinted, and looked wrong next to the dark asphalt of the
overhead shots. It is **Fresnel reflection of the sky at ~89° incidence** — every photograph of a
road running to the horizon shows it. **A probe confirmed the same object, normal +1.000, in both.
Do not "fix" it.**

**THE FRAME, RE-FITTED.** Brute force over ±15 m gives **(+34.0, −99.0), median 2.24 m**; the
recorded **(+35.0, −100.0)** gives 2.50 m. **The recorded value is kept** — the integrator chat is
exporting `map/ego_S1.csv` with exactly that offset removed, and agreeing on one number beats a
metre of fit.

**THE TOOL THIS PRODUCED: `build/city/probe.py`.** Give it a blend, a render and a shot name and it
reports, per pixel, the object hit, the distance in metres, the world position and the face normal,
plus the region's mean sRGB and saturation against REF-13's measured photographs. **Every one of the
5 Sep bugs was found with it or with an A/B. None was found by reasoning.**

**k · A MASK THAT GATES AN EFFECT MUST ALSO WEIGHT IT.** The quarry's bench quantisation
(`floor(z/9)*9`) ran at full strength wherever the quarry mask merely *exceeded a threshold*
(`qm > 0.02`, which is everywhere within 89 m of the centre). So a vertex with a 0.5 m cut was
still snapped into 9 m contour bands, and the whole hill face rendered as a **ziggurat**.
**Gating tells you WHERE an effect applies; it does not tell you HOW MUCH.** Blend by the mask:
`z = z*(1-w) + stepped*w`. Any quantising or stepping effect needs this or its edge is a cliff.

## 12 · THE ERODER TRANSLATES THE MESH — 5 Sep 2026, and it invalidated every later mask
**A second member of the family §10a already opened.** That entry says the Eroder **scrambles the
vertex order**. This one says it also **MOVES THE MESH**.
Traced by printing the mesh bounds through the pipeline, after two wrong theories cost a rebuild each:
```
in:   x -260..260,  y -220..220      (the 520 x 440 generation grid)
out:  x -220..300,  y -260..180      (same spans, centre moved +40, -40)
```
**It is a pure translation of (+40, −40) m** — 20 cells on a 2 m grid.

**WHY IT MATTERS FAR MORE THAN IT SOUNDS.** Everything downstream of the Eroder is expressed in
**local mesh coordinates**: the inscribed ellipse, the quarry at 215°, the waterfall on the north
flank, the fan boundary mask, and **the grid index rebuilt from x,y that §10a's own fix depends on**.
All of them were landing **40 m from where they were specified**, and the ellipse test was cutting
live hill off one side — which is what produced a **straight-line hole at y = 180 with an 18 m
cliff round it**, rendering as a black staircase at the hill's foot.
**Fix: measure the offset from the mesh's own bounds and remove it, immediately after the operator.
Never hardcode 40 — measure, remove, then ASSERT the centre is back at zero.**
**Result: worst boundary gap 17.93 m → 0.40 m, and the footprint came back to 498.2 m against a
specified 500.**

**THE PROCESS LESSON, and it is the same one as §10j.** I theorised the cause twice — "the skirt
delete is removing the quarry floor", then "the ellipse test is wrong" — and **both were wrong, and
each cost a rebuild.** Printing four numbers settled it immediately.
**When a shape is wrong, TRACE THE DATA THROUGH THE PIPELINE. Do not reason about the geometry.**

## 13 · WHAT THE AUDIT CAUGHT ON ITS FIRST RUN — including a bug in the audit itself
`build/city/audit.py`, written 5 Sep, runs against any .blend. **It found three things immediately,
and the third is the one worth remembering.**
1. **A false positive of its own making.** It flagged `WATER_PIT_1` and `WATER_POND_3` as "wound
   downward". They are correct **closed solids**, and a closed solid legitimately has half its faces
   pointing down — that is what closed *means*. **The winding rule only applies to OPEN surfaces.**
2. **"Closed" was defined wrongly.** `all(edges used twice)` calls a **pinched** edge (used by four
   faces) open. Closed means **no edge used only once**; a pinch is non-manifold but not open, and
   now gets its own warning. `WATER_PIT_1` has exactly one, where two lobes of the pond meet.
3. **THE VOLUME CHECK WAS SILENTLY PASSING EVERYTHING.** It tested `n.type == 'VOLUME_PRINCIPLED'`.
   **The real string is `PRINCIPLED_VOLUME`** — verified by running it, the same trap family as
   §7's node names. So the check matched **no node in any material** and reported a confident OK.
   **A false OK is worse than a missing check**, because it is trusted. Every audit rule must be
   proved to FIRE on a known-bad case before it is believed.

## 14 · THE GROUND MATERIAL — 5 Sep 2026, and three bugs that only LOOKING could find
**S0 §3 "THE GROUND MATERIAL". The plain read featureless not because the terrain was flat — it
is not; median slope 2.24°, 3.8 m of relief per 100 m window — but because all 4 km² wore ONE
material keyed to height and a single noise. The bund grid was real geometry and invisible.**

**a · A DEAD-STRAIGHT LATTICE IS THE TELL.** Driving the tone from the existing `plot_id` worked
immediately — and rendered a **perfect chequerboard**: every parcel the same size, every boundary
exactly straight. Real holdings are irregular because they are **inherited and divided**, not laid
out. Two fixes, both causal: **warp the coordinate before the floor** so boundaries wander a few
metres like real bunds, and **let neighbours MERGE on a coarser "holding" grid**, because one
farmer works several adjacent parcels as one crop. Field sizes then vary on their own.

**b · FIELDS WERE BEING PAINTED ON THE MOUNTAIN.** The hill shares the soil material with the
terrain, so **plot rectangles and furrows appeared across a 170 m hillside** as a translucent grid.
It read as a "veil" and the probe said 97 % HILL — correct, and useless, because the object *was*
the hill. **A/B settled it in one pass: hide HILL and the veil goes.** Farmland is farmland;
`soil_material(fields=False)` gives the hill REF-04 §10's two-tone earth without the cultivation
layers, which is what that clause actually describes.

**c · A PER-FACE MATERIAL BOUNDARY CAN ONLY EVER BE JAGGED.** Assigning SOIL/ROCK per face by a
height threshold rendered a **hard horizontal band** straight across the hill — a flat threshold on
a dome is a **contour line**. Jittering the threshold with noise removed the contour and replaced it
with a **sawtooth ring of triangles**, because the boundary still had to follow face edges.
**REF-04 §10 says it plainly: "the boundary is a noise-masked gradient, never a line."** The fix is
architectural: **ONE material for the hill**, earth and rock mixed **per pixel** by a noise-jittered
mask. No face boundary exists, so none can show.
**And the mask must be HEIGHT *OR* SLOPE, not height alone** — REF-13 §6 reads rock as appearing
where soil cannot hold, which is on steep ground at any height. Relief-only stripped the texture
off every gully wall on the lower slope. *(§10i's "slope is the wrong mask" is about the PLAIN,
where nothing is steep — not about the hill.)*
**Relief is baked into the EROSION colour attribute's ALPHA** so the shader can mask by the hill's
height above the ground it stands on, not by world z, which changes as the plain rises.

**d · TWO PYTHON LOOPS COST 5× THE BUILD TIME.** A per-face centroid loop over 70k faces took the
build from **15 s to 96 s**, and a per-vertex colour-attribute loop added another 50 s. Both became
one `foreach_get`/`foreach_set` call. **The 8-second loop IS the method — a 96 s build breaks it.**
