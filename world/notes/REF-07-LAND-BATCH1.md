# REF-07 · LAND — TERRAIN, ROCK, HILL ROADS, RIVERS, BRIDGES
**Batch 1 of Aditya's video study.** 9 videos, 2 h 35 m, read via captions + frame-by-frame.
Everything here is a METHOD with the actual node, modifier, key or number. Nothing is a description.

## 1 · THE ROAD CUT INTO A HILLSIDE — the S5 problem, solved
**Source: Xoio, "How to do a Mountain Road" (20:02, no captions — read frame by frame).**
His own on-screen step titles: *Step 1 conform the base mesh to the terrain · Step 3 adjust and
smooth steep areas · Step 8 refining the road mesh.*

**The nine steps, in order:**
1. Terrain first — subdivided plane + Displace.
2. **The road path is a CURVE.** Drawn as a spline with the switchbacks in it.
3. **Conform a flat corridor mesh down onto the terrain** (shrinkwrap). This is the road's footprint.
4. **Smooth and flatten the terrain along the corridor** *before* cutting. A road cannot follow a
   noisy surface — the ground is made ready for the road, not the other way round.
5. **Extrude the corridor outline vertically into a cutting solid** and boolean it through the terrain.
6. **The cut leaves a flat bed with VERTICAL FACES on both sides** — and those vertical faces ARE
   the cut face on the hill side and the fill edge on the drop side. **This is exactly S5's
   "cut face 3–12 m" and it comes out of the geometry, not from modelling it separately.**
7. Delete the cutter; separate the road band as its own object with clean transverse quads.
8. **Sweep the road CROSS-SECTION along the curve** for the running surface.
9. **UV the road as a STRAIGHT RECTANGULAR STRIP** in the UV editor, however much it curves in 3-D.
   **This is how lane markings map correctly along a bending road.** Without it, markings smear.
10. **Bake a road MASK image from the layout** (road drawn pale on a dark terrain map). He uses it to
   blend materials at the verge and to kill scatter near the road. **Ours can come straight from
   `matlab_roads.csv` — we do not need to paint it.**

**How this maps to us:** every step is scriptable. Our curve is the real centreline; our cross-section
is the IRC profile (3.75 m hill carriageway, 9.0 m at the hairpin apex, 1:10 superelevation).

## 2 · TERRAIN — three independent sources agree
**A.N.T. Landscape** is bundled with Blender: `Shift+A > Mesh > Landscape`, presets, seed, height,
subdivisions X/Y (use 300+). **It also carries a "Landscape Eroder" in the N panel** — that is our
tool for the hill's gully network, and it is a real erosion sim, not noise.
**F9 reopens the operator panel** after you click away.

**The displacement stack that everyone uses:**
`Subdivision Surface (levels 3) → Displace (texture = image, Coordinates = UV)`.
- **Displacement image colour space MUST be Non-Color.** Getting this wrong is silent and wrong.
- **UV unwrap by `U > Project From View` from top view**, then scale the UVs to set texture size.
- For true Cycles displacement instead: Image → Displacement node → Material Output Displacement,
  and **Material Settings > Displacement = "Displacement and Bump"**, Mid Level **0**, Scale to taste.
- **Mapping must be set Repeat → EXTEND** or the terrain tiles visibly at the edges.

**Geometry budget, stated by a working artist:** a whole mountain range = a plane scaled ×1000,
**subdivided to ~500,000 triangles**, one Displace. That is the number to build our 4 km terrain to.

**STACKING HEIGHT LAYERS — the technique that gives us everything S0 asks for.**
Mix a second height image into the first with **MixRGB (Add)** before the Displace node, and use
**Invert** to turn a ridge into a channel. He paints the second layer by hand in Texture Paint.
**WE GENERATE IT INSTEAD.** One greyscale layer per feature, written by script:
600 m swells · 160 m undulation · field bunds every 75 m · abandoned river channels ·
the gully network · the quarry scar. **That is how S0's "never flat anywhere" gets built.**

## 3 · MATERIAL DRIVEN BY THE SURFACE, NOT PAINTED — confirmed three times
- **Height mask:** `Geometry > Position → Separate XYZ → Z → ColorRamp → Mix factor.`
- **Slope mask:** normal against Z. Rock on steep, soil on flat.
- **The refinement that matters:** the UE5 artist combines **two maps of DIFFERENT FREQUENCY** —
  one high-frequency, one low-frequency — for rock, and again for grass, *then* blends rock↔grass
  by the slope+height mask. **Our pipeline rule says "two materials mixed by a mask." The upgrade is
  that the two should differ in FREQUENCY, not just in colour.** That is what kills tiling.

## 4 · ROCK — where to put real geometry, and where not to
**The single most useful efficiency rule found in this batch**, from the UE5 breakdown:
> *"I did not put 3D rocks all over my mountains, only in areas where there was light and they
> could add detail."*
**Rocks go only where they catch light and cast a shadow.** Everywhere else, the material does it.

**And the three-scale set-dressing law, derived from his own reference photos:**
| Scale | What | And the causal link |
|---|---|---|
| Large | granite slabs, trees | the parents |
| Medium | boulders **that fell off the slabs and rolled down beside them** | **caused by the large** |
| Small | pebbles held in place by needles, cones, sticks, grass | caught by the small stuff |
**The medium objects are the debris of the large ones.** This is the same law REF-06 found in trees:
**shape and placement are a record of what happened.** It is now confirmed in two independent domains
and should be treated as the governing principle of the whole project.
Also: *"it's rare to see a forest completely undisturbed from rocks and landslides"* — scree belongs
**inside** the forest floor, not only on open slopes.

## 5 · WATER — a complete recipe, two independent sources
**Make the water a SOLID, not a plane:** extrude the surface downward, then
**select all and `Shift+N` recalculate normals** — the volume will not render otherwise.
| Node | Setting |
|---|---|
| **Principled Volume** (Volume socket) | Density **0.07 → 0.3**, slight blue/turquoise |
| Principled BSDF | Roughness **0.1**, Transmission **1.0**, Alpha **0–0.6**, base colour white |
| Ripples | **Noise Texture → Bump (Height) → BSDF Normal**, bump strength **~0.1**, high scale+detail |
**Why the volume matters: it makes shallow water clear and deep water coloured.** That depth gradient
is what makes it read as a river rather than a sheet of glass.
**For the Malin: use the HIGH end of the density range.** It is a sediment-laden Shivalik stream,
not a clear mountain brook. REF-04 §13 — heavy sediment, boulders, cobbles and sand.

**River channel shaping (Ryan King):** plane → `Ctrl+R` loop cut at centre → subdivide 100 →
`Alt`-click the centre loop → drop it → **rotate and move loops with PROPORTIONAL EDITING**
(mouse wheel sizes the falloff) to meander it → move random vertices to break the regularity.
**We do not hand-shape ours — the Malin's centreline comes from OSM — but the profile idea holds:
a channel is a falloff applied along a centreline.**
He also deliberately **raises the far bank to control how much sky is visible**, and keeps
**a blurred clump of near-camera shoreline for depth**. Both are composition tools, both free.

## 6 · CLOUD SHADOWS — found twice, independently, and we need it
S0 specifies 25 % thin high stratus. A sky texture alone casts **no cloud shadow on the ground**,
and the mismatch reads as fake immediately.
- **Method A (Bro3D):** a huge plane above the scene; material = **Noise Texture (4D) → ColorRamp →
  Alpha**. It blocks light in patches. **Animate the 4D W value and the shadows drift.**
- **Method B (UE5 artist):** large invisible shapes above the scene purely as shadow casters.
Same idea, arrived at separately. **Build Method A.**

## 7 · SCATTER CONTROL — how to place and how to NOT place
- **Weight-paint a vertex group, then cull the scatter to it.** Rocks only on the banks; nothing in
  the water; **weight 0 everywhere outside the camera frustum.**
- **Curve proximity:** scatter follows or avoids a curve. Our road and river centrelines are curves
  already, so verge planting and bank boulders come free.
- **Camera culling on for grass and small stuff — OFF for trees**, because trees still cast shadows
  into frame from outside it. Getting this wrong loses the shadows.
- Tools seen: **OpenScatter** (free), **BagaPie** (free, `J` then scatter-paint), Blender's own
  geometry-nodes scatter. We script geometry nodes; no addon dependency.

## 8 · DISTANT FOG, AND A TIME-SAVER
- Distance haze = a **separate large object with Principled Volume at very low density**, and a
  **Math (Multiply) node into Density** so a usable number controls a tiny one. Confirms REF-05:
  never a world volume.
- **`Ctrl+B` in the viewport renders only a boxed region.** Use it to judge a material without
  rendering the frame. This is the fastest look-check available and I will use it constantly.
- Put a **1.7 m human reference figure in the scene** to sanity-check real-world scale. Cheap, and it
  would have caught the 5.6 m road and the 13 m poles.

## 9 · REPEATED STRUCTURE — bridges, barriers, railings
**Source: Reality Fakers bridge (30:22).**
- **Model ONE unit, then Array.** He counts the real gap and derives the count (12 per bay).
- **`Ctrl+R` edge loops + `Ctrl+E > Bridge Edge Loops`** is how two separate members become one joint.
- **Proportional editing with "Sharp" falloff** bends a straight array into an arch.
- His stated discipline, unprompted: *"I'm trying to not add too much detail to these shapes —
  adding more detail is going to cost us really bad, because we're duplicating this hundreds of
  times."* **That is our instancing rule, in a working artist's own words.**
- The human-purpose detail that sells it: a **maintenance walkway under the deck** "so workers can
  fix the lamps." Every structure needs one thing that exists because a person uses it.

**HONEST LIMIT: this video is a STEEL TRUSS bridge. Indian highway flyovers are precast box girders
on hammerhead piers.** The technique transfers; the shape does not. **Our real reference for the
flyover is Aditya's own bus clip 1**, which is filmed under a viaduct for its entire length —
hammerhead piers, box deck, red-and-white hazard stripes on the pier bases, black-and-yellow
chevrons on the parapet. That footage beats any tutorial for this.

## 10 · REAL INDIAN HILL-ROAD CONDITION — researched, for S5
- **Syanachatti, Uttarkashi, July 2026: a landslide took out ~100 m of the Yamunotri National
  Highway.** Cut for two days; about 100 pilgrims crossed the gap on a rope.
  **120 roads blocked in Uttarakhand in a single weekend.** 25 national highways damaged in Himachal.
  **So S5's 60 m washout is conservative and defensible.**
- Retaining-wall failure modes to build: **overturning · sliding · bearing failure · bulging and
  blowout from water pressure behind the wall.**
- **Dry stone walls, breast walls and timber cribs are the least durable and fail first** (IS 14458).
  S5 already specifies dry stone breast walls "broken at 6 places, leaning outward at 2" — that is
  now sourced, not invented.

## 10b · GAP CLOSED — the waterline comes from the terrain, not from modelling a river
**Fattu's river video finished downloading and I went back for it** (no captions — read frame by
frame). It confirms a technique that Ryan King also used without naming it, and it is the simplest
useful idea in the whole batch:

**YOU DO NOT MODEL THE RIVER'S OUTLINE. You cut a valley in the terrain, then intersect it with a
FLAT, LEVEL PLANE, and slide the plane up and down until the waterline sits where you want it.**

The bank line then falls out of the terrain automatically — irregular, following every bit of noise
and every boulder, and *correct*, because that is exactly what a real water surface does. Modelling a
river outline by hand produces a shape that is subtly too smooth and too deliberate.
**For the Malin: build the channel into the terrain from the OSM centreline, then drop one level
plane. Every bar, shoal and cut bank comes free.**
Also in that video: A.N.T. Landscape for the base, a boolean cylinder to flatten a plateau, and the
same **height + slope mask** driving green vegetation low and pale rock high.

## 11 · WHAT I DID NOT GET FROM BATCH 1 — stated plainly
- **The second half of the bridge video** — read the first half only.
- **No tutorial in this batch measured anything in metres.** They are all hero-shot workflows with
  no real-world scale and no geometry budget except the one 500k figure. **Every dimension we build
  still has to come from IRC, from the map, or from Aditya's own footage — not from these.**
- **None of them tested their scene from a moving camera at 1.3 m.** Every one is a static hero
  angle. The rock-only-where-light-catches rule in particular must be re-checked at eye level.

## 12 · SOURCES
Xoio *How to do a Mountain Road* · Gabe Tandy *Photorealistic Mountain Landscape* (UE5, method
mapped to Blender) · LightArchitect *Mountains and Canyons* · ChuckCG *Terrain and Landscapes* ·
Yeho *Realistic River Landscape* · Bro3D *River Landscape* · Ryan King Art *Rocky River* ·
Reality Fakers *Bridge Realistic Modeling*. Hill-road condition: The Better India (Syanachatti,
July 2026), Tribune India (Himachal NH damage), IS 14458.
