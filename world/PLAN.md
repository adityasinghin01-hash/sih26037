# THE BUILD PLAN — component-major
**Rewritten 3 Sep 2026, 23:45. Supersedes the stage-major ordering in `notes/BLENDER-PIPELINE.md`
Part Seven. The two RULES are unchanged and still govern everything.**

> **RULE 1 — Nothing is built until it is written.**
> **RULE 2 — A component is finished when it matches its specification exactly.** Not "good enough,
> I'll fix it later."

**5 Sep 2026: §9 AT THE END IS NOW THE AUTHORITATIVE STEP-BY-STEP.** §4 still holds for
each component's *specification*; §9 says how each one gets finished, in order, and where.

## 1 · THE STANDARD — what "done" means, in Aditya's words
**Everything, everywhere, must read correctly as what it is.** A house looks like a house from any
angle a person looks at it. A tree looks like a tree. A road like a road. An animal like an animal.
**The whole 4 km gives proper city vibes. It feels alive.**
Set 3 Sep 2026; written into `scenarios/S0-THE-WORLD.md` §4 as the Level-3 revision.

**Time is not the constraint. The specification is.** Build it properly.

**EXTENDED 5 Sep 2026 — Aditya's own definition of the target, in his words:**
*"Real mountains. I am on a plane looking at the Earth and I'm seeing the detailing. I can zoom in
from space and see the details."* He named six: **peak detailing · peak texturing · peak dangling ·
peak blending · peak graphics · peak lighting.**

**THE TEST THIS SETS, and it is a SCALE test, not a polygon test:** the world must hold up at
**three viewing distances** — from the air, from the street, and up close — and nothing may fall
apart at any of them. **Passing it by authoring unique detail over 4 km² is impossible on any
machine.** It is passed by the principle this project has already arrived at three times:
> **Repeat what a reason would repeat; never repeat what chance produced.**
A real mountain survives the zoom because its detail is **self-similar and CAUSED**: gullies branch
the same way at 1 km and at 10 m; big rock plates split into smaller plates of the same shape;
medium boulders are the debris of the slab above them. **That is cheap. Polygons are not.**

**AND THE TWO VIEWS ARE FIXED BY DIFFERENT THINGS — this decides where hours go:**
| view | what actually carries it | cost |
|---|---|---|
| **From the air / from space** | silhouette · haze depth · large-scale causal structure | **cheap** — mostly light finalisation |
| **From the street** | the five scenario circles at Level 2 | **expensive** — this is where the hours go |
Detail outside the five circles is detail the camera never reaches.

## 2 · THE MACHINE SPLIT
| Where | What |
|---|---|
| **This M1, 8 GB, headless** | **The whole world: built, sculpted, textured, blended, lit.** When it leaves here it should already look like the film |
| **The 64 GB / RTX A1000 machine** | MATLAB runs · animation · **render** · grade · output · deeper texture passes where the camera gets closest |
**Why the split falls there:** Blender has no reliable out-of-core. When a scene exceeds VRAM the
render *fails*, it does not slow down. 8 GB VRAM binds at RENDER time, not at build time.

**How full detail fits in 8 GB — three mechanisms, none of which lower the bar:**
1. **One scenario file at a time.** The camera only ever sees one.
2. **Procedural first, images second.** Procedural materials cost almost nothing and never repeat.
   Image textures are what kill 8 GB — they go only where the camera gets close, capped at 2K.
3. **Sculpt, then bake.** Multires sculpt the real form, bake to a normal map (verified working,
   REF-05 §7). The detail survives at a fraction of the memory.

## 3 · HOW EVERY COMPONENT IS BUILT — the same six steps, every time
| | Step | Gate |
|---|---|---|
| a | **Write** — the component's numbers, from the scripts and the REF library | nothing guessed |
| b | **Shape** — real dimensions, correct silhouette | dimensions **asserted in the script** |
| c | **Detail** — the parts, the variation, and **the constraints that CAUSE the variation** | nothing repeats without a reason |
| d | **Sculpt** — multires where close-range form matters, baked down to normals | — |
| e | **Texture** — procedural first; 2K images only near the camera | roughness always varying |
| f | **Audit + look** — measured checks, then pictures for Aditya | **Aditya's eye is the gate** |

**Then, and only then, the next component starts.**

## 3b · THE THREE-SCALE LAW — added 5 Sep 2026, and it is how §1's zoom test is passed
**Every component is built at THREE scales, and the same cause drives all three.** Not three levels
of polygon density — three expressions of one rule. This is what makes a zoom hold together.

| | scale | what it means | example, on the hill |
|---|---|---|---|
| **L** | reads from the air, 1 km+ | the silhouette and the drainage pattern | the ridge line, the gully network at 4.55 km/km² |
| **M** | reads from the street, 10–100 m | the features the pattern produces | individual gullies, scree fans at their mouths, quarry benches |
| **S** | reads up close, 0–10 m | the debris the features produce | plates split off the bedding, boulders below the slabs that shed them |

**THE RULE: S must be caused by M, and M by L.** Scattering small rocks randomly fails the test
instantly — that is the tell. Placing them *below the thing they fell off* passes it.
**Applied per component:** roads (network → carriageway → crumbling edge) · buildings (skyline →
facade module → grime under the tank) · vegetation (canopy line → single tree → the cut where the
wire crosses it) · land (as tabled above).
**COST NOTE:** L and M are geometry. **S is almost always a material or a sculpted-and-baked normal
map, never modelled** — that is the only reason peak detail fits in 8 GB.

## 4 · THE EIGHT COMPONENTS, IN BUILD ORDER
The order is a dependency chain, not a preference. **Each component can only be built correctly once
the thing that constrains it exists.**

### 1 · LIGHT — **BUILT 4 Sep 2026, 33 assertions passing**  *(rewritten after REF-12, rebuilt after REF-13)*
**`build/city/01_light.py` → `blend/01_LIGHT.blend`. Renders in `renders/city/c2_*.png`.**
**The condition changed** after Aditya supplied 43 of his own photographs (REF-13): **25 Sep 15:30,
sun elev 33.11° azim 246.87°** — not the 06:45 dawn every earlier document specifies.
Built: Nishita (**swept against the measurement**, air 1.7 / aerosols 1.0 / ozone 1.0, Standard
transform, −3.06 stops) · haze at **20 km visibility** with altitude falloff · **a cumulus deck with
all bases coplanar at 1400 m** · **high cirrus at 7200 m** · cloud shadows · **34 small god-ray
occluders** · the 1.70 m figure and haze posts at 50–1600 m.
**Peak memory 391 MB.** Memory was never the constraint on this component.

### 1b · LIGHT — the original specification, kept for the record
**Set FIRST so every material after it is judged under the real low, warm, hazy sun.
Finalised LAST, once there is geometry for the haze, the shafts and the cloud shadows to land on.**

**a · The sun — from real astronomy, not from taste**
**Elevation 7.53°, azimuth 95.24°** — computed for 29.6118 N 78.3421 E, **25 Sep 2026, 06:45 IST**.
Angular diameter 0.526° (the real sun) so shadow edges are correct. **Sun disc OFF in the sky
texture** — a separate SUN lamp is the direct light, so the cloud plane can block it.

**b · The sky — the split that four independent sources insist on (REF-12 §2)**
**The sky texture / HDRI gives LIGHT ONLY. A camera-facing image plane is what the camera SEES.**
Nishita **Air 1.5 · Aerosols 4.0 · Ozone 2.0 · background strength 0.25.**
The sky plane: parented to the camera, cube-projected, image into **Emission AND Base Color**,
**horizon aligned to the scene horizon**, **its shadow disabled**, and — the dead giveaway —
**its light direction matched to ours or mirrored with `S X -1`.**
**Our sun is east-south-east, so every sky image must have its sun on that side.**

**c · The air — physics, not taste**
Bounded volume box (never a world volume). **Density 0.0049** = Koschmieder α = 3.92 / 800 m
visibility, **noise into density** so it is wispy. **Anisotropy 0.35** — forward scatter is what makes
air glow around a low sun and is half of what makes shafts read.

**d · Clouds — S0 asks for thin high stratus, ~25 % cover**
Built as an image plane and/or the **Dynamic Sky** parametric world.
**Plus, now available and verified: the full procedural VOLUMETRIC cloud pipeline** — scattered
spheres → upward displacement (there is deliberately no height control, because vertical growth is
organic) → children → **Mesh/Points to Volume** → noise → wind with flip-Z for an anvil.
**Every node exists natively in 4.5.11. No addon, no purchase.** (REF-12 §3.)
Reserved for if Aditya wants a dramatic sky; **untested in 8 GB, and that is the open risk.**

**e · Cloud shadows — a sky casts none, and the mismatch reads as fake**
A high shadow-only plane, noise → ColorRamp → mix, tuned to ~25 % cover, camera/diffuse/glossy
visibility off. Animatable by driving the 4D noise W.

**f · God rays — the strongest effect available at a 7.5° sun (REF-12 §6)**
Shafts are **the gaps between shadow casters inside a scattering medium**. All three are required:
the bounded volume · anisotropy raised · **and something to occlude the light** — the canopy, a
building edge, the flyover deck, or a deliberate off-screen caster. **Without occluders there is fog,
not shafts.** Costs nothing extra: the occluders are geometry we are already building.

**g · Craft rules that govern how it is set up (REF-12 §1)**
**Start from pitch black** and add one light at a time. **Never light from the camera's direction** —
the shadows fall behind the objects and the image goes flat. **Sun off to one side.**
**Each lighting variant lives in its own collection**, toggled — that is how options get shown.
**Off-screen shadow casters** are legitimate and used deliberately to steer the eye.

**h · In the file for scale and for judging**
A **1.7 m human figure**, a test ground, and **posts at 50 / 100 / 200 / 400 / 800 m** so the haze
falloff is read off a measurement rather than guessed.

**Audit:** sun elevation and azimuth to 0.05° · haze density to 1e-6 · every sky parameter ·
figure height 1.70 m · camera 1.30 m and 13 mm · air volume −5 m to +450 m.

### 2 · LAND — everything sits on it
Terrain 4000 × 4000 m falling south · three undulation scales (600 m swells, 160 m, field scale) ·
abandoned river channels · field bunds every ~75 m · **the Malin** — channel cut from the OSM
centreline, **water is one level plane intersecting it** (REF-07 §10b) · **the hill: (−690, 980),
500 × 350 m base, 170 m**, gullies via the **Eroder**, rock on the upper third, the quarry scar,
the seasonal waterfall · the distant range at y ≈ 1900 · two-tone soil placed by slope and height ·
the bare field shapes.
**Built as stacked greyscale height layers, each generated by script** (REF-07 §2).
**THE HILL'S METHOD IS NOW PROVEN (REF-05 §7):** A.N.T. Landscape on a **square-spaced** grid →
**the Eroder** (it moved 64,816 of 66,049 verts in 4.3 s) → **rescale to 170 m and assert**.
The Eroder rejects non-square spacing, so **500 × 350 m must be built at 257 × 180, not 257 × 257**,
and it returns height in grid units — **erode first, rescale after, assert last.**
Its **`water` / `flowrate` vertex groups ARE the gully network as a mask**, and `scree` / `deposit`
place the debris — measured drainage, not painted noise.
**Audit:** never flat anywhere · drainage density ≈ 4.55 km/km² · only river run 0 used, not all 24.

### 3 · ROADS — every made surface, and the structures that carry one
All **213 roads**, and the length is **42.1 km inside the 2 km box** — **CORRECTED 4 Sep by
measuring**; the "47.3 km" written here matches no clip (57.1 km over the 4 km ground extent,
60.1 km unclipped). **S0 §4's 42 km is the right figure; build to it.** Real widths by class · markings, 2.5 % camber, crumbling edges, the
9 clustered potholes, the speed breaker · kerbs, footpaths, **open drains, culverts** ·
**the 2 real river bridges** at (−640, 740) and (−822, 609) · **the 9 flyover decks and piers**,
22 m spans, 1800 mm piers · **the whole railway** — formation 6.85/12.15 m, 2:1 sides, the
**grouped** yard (8–10 tracks, 4.3–5.4 m within groups), platforms 0.84 m, 2 level crossings ·
**the S2 gyratory** — ICD 40 / island 24 / circulatory 8 · **the S5 hill road** — corridor conformed,
terrain smoothed, then cut so the vertical faces ARE the cut face and the drop (REF-07 §1) —
retaining walls, gabions, parapets with their real gaps, W-beam, catch drain, the washout, the roadworks.
**Two methods, deliberately:** cut geometry where the section matters; **a material mask** for the
kaccha rasta, field tracks and the ragged 100–300 mm crumbling edge (REF-11 §6).
**UV as a straight strip** however much the road bends, or markings smear (REF-08 §3).
**Audit:** gradients ≤ 6 % and ≤ 2.5 % through hairpins · clearances 5.5 m over road, **6.25 m over
rail** · widths match the S0 table · total centreline 47.3 km.

### 4 · BUILDINGS — everything constructed and occupied
~1000 masses driven by **vertex groups choosing facade modules** (REF-09 §1) from ~30 parts ·
storeys by extruding 3 m at a time · shops, shutters, awnings, signage · kutcha huts ·
**the temple — latina shikhara, plinth, 38 steps, saffron flags** · **the chowk statue on its stepped
plinth** · school, fuel pump, bus shelter, police post, dhaba, station building · compound walls ·
water tanks, balconies, exposed rebar.
**Built by inset → extrude, repeated** — that stacked profile IS a shikhara, a plinth, a cornice
(REF-09 §3). **Spin + radial array via an empty** for anything circular.
**Every Level-3 building gets real openings** — doors, windows, a balcony where the type calls for
one. **Not coloured boxes.** (S0 §4, revised.)
**Audit:** no two neighbours share height, width or colour · storey heights 3.0–3.15 m · instance count.

### 5 · INFRASTRUCTURE — poles, wires, signs
**11 kV candelabra poles** 9 m PCC at 45 m, the real pole-top geometry measured off the footage ·
**the wire tangle, 9–14 parallel runs** at different sags, as a **parabola not a sine** ·
transformers on double poles · 415 V four-wire and service drops · **the 132 kV lattice line**
crossing the fields at an angle, ignoring the roads · mobile towers · signs, hoardings — **many more
than five, and some with the vinyl gone** · kilometre stones · the railway's overhead equipment with
its **200 mm stagger** · **the blue-painted posts, bollards and verandah columns** found in the footage.
**Audit:** conductor clearance against the legal minimum · pole spacing · sag.

### 6 · VEGETATION — and it comes AFTER infrastructure, deliberately
**Trees: one neem plus the eight constraint operators** (REF-06, built with Sapling's pruning
envelope and geometry-node branch selection, REF-10 §7) · eucalyptus rows · gulmohar and amaltas on
medians only · peepal at the shrine only · **no banyan** · sal forest on the hill · the mango grove ·
**roots**, which nobody builds · vines smothering at least two trees per scenario.
**Leaves are alpha cards, not meshes** (REF-10 §0).
**Ground: seven layers, one scatter system each** — kans 2.2–3.0 m · sugarcane 2.25 m in 1.35 m rows ·
shrub 0.8–1.4 m · mid grasses · doob grazed short · weeds · floor litter.
**Clumped by feeding noise into density and scale** (REF-11 §5). **Translucent BSDF is mandatory** —
our sun is at 10°, so half the grass is backlit (REF-11 §3).
**Crops for late September:** paddy being cut and stacked, cane standing and being cut, plots ploughed
for rabi. **The brick kiln is cold.**
**WHY IT FOLLOWS INFRASTRUCTURE:** the single biggest cause of tree shape is the electricity board's
pruning — in Aditya's own frame the cable line and the foliage edge are the same line. A tree can
only be cut correctly once the wires and the walls exist.
**Audit:** canopy cover by **ray-cast**, 38 % in the open rising to 55 % at the village end · spacing
8–12 m with the crowded ones elongated along the row · every gap has its written reason · instance count.

### 7 · LIFE — everything that moves, or was dropped
**239 people** at their written Fruin densities — crowded and empty at the same time, never uniform ·
**the cow** (zebu, withers 128 cm, hump 15 cm) · buffalo · **the 24 macaques** · dogs, goats,
~210 birds with their different flush distances · insects only in the two backlit volumes ·
every vehicle, parked and moving · vendor carts and thelas · hand pumps, charpais, fodder stacks ·
**litter in clusters only**, dung, wheel ruts, puddles.
**Audit:** gait — stride × cadence must equal travel speed or feet slide · densities match the script.

### 8 · BLENDING — across everything, once everything exists
**The AO double-stack** (REF-09 §5): crevice grunge at long distance; **edge wear at very short
distance with Inside + Only Local**, noise mixed in so it is not uniform.
**One shared dust layer** over road, kerbs, pole bases, leaves, walls and every ledge.
Contact shadows · ground creeping into every base · nothing repeating without a reason.
**This cannot be done per component by definition — it IS the relationships between them.**
**This is the stage our renders have died on twice.**

### THEN · LIGHT, FINALISED → **ADITYA'S GATE**
Fast previews, side by side against his own dashcam frames. **Nothing ships until he signs it.**

## 5 · PRACTICES THAT APPLY TO EVERY COMPONENT
- **Assert every dimension in the build script.** `object.dimensions` and `edge.calc_length()` return
  exact metres headless (REF-05 §7). Each script checks itself against the spec and **fails loudly**.
  This is what would have caught the 5.6 m road, the 280 mm median and the 13 m poles — and it is
  stronger than anything in the 29 tutorials, **none of which measured a single thing**.
- **Measure the instance count after every component.** Under ~150,000; past ~250,000 the 8 GB swaps
  (REF-05 §3). **Measured, never assumed.**
- **Save after every step**, to its own file. A scene was lost once with no save.
- **Everything is a script.** Nothing done by hand, so nothing can be lost and any component can be
  rebuilt from nothing.
- **Look at every step.** Small check renders for me, proper ones for Aditya. A passing numeric audit
  is not the same as a picture that reads.
- **Repeat what a reason would repeat; never repeat what chance produced.** The governing principle,
  arrived at independently in trees (REF-06), rock debris (REF-07 §4) and composition (REF-09 §11).

## 6 · DEFERRED
**See `DEFERRED.md`** — the hero cloud variant, the sky-image plane, sky brightness, and the
night condition. Each carries what is wrong, what fixes it, and an honest note on whether the
bigger machine actually helps. **Component 1 ships with the REFERENCE sky, matched to measurement.**

## 7 · STILL OPEN
- **Two scenarios deep, or all five?** Needed at the vegetation and life components, not before.
- **THE TIME OF DAY.** Aditya wants **AFTERNOON, not the 06:45 dawn every script specifies.**
  This is a script change, not a sky tweak — see `DEFERRED.md`. **Blocks the completion of
  component 1.**
- **NIGHT.** 6 of the 13 dashcam clips are night and no scenario covers it.

### CLOSED SINCE
- ~~**S0 §2 azimuth conflict**~~ — **SETTLED.** Recomputed independently 4 Sep with the NOAA
  algorithm: at 29.6118 N 78.3421 E on 25 Sep 2026, 06:45 IST the sun is **elevation 7.65°,
  azimuth 95.24°**. The number 095° was right, and S0 §2 already carries the corrected wording
  ("5° SOUTH of due east"). Nothing left to settle.
- ~~**Road total 47.3 km**~~ — measured: **42.1 km in the box.** See §4 above.
- ~~**The hill at (−690, 980)**~~ — **it sat on the Malin.** Amended to **(−1050, 900)**;
  measurements and the three candidates are in **S0 §3**.
- ~~**Toolchain "verified 3 Sep"**~~ — **it was not.** Sapling, A.N.T. Landscape and the Eroder
  were never installed. Now installed and **37/37 techniques verified by execution**;
  **REF-05 §7 is rewritten** and carries four new traps that would each have cost rebuilds.


---

# 9 · THE FINAL STEP-BY-STEP — written 5 Sep 2026, and this is the authoritative order
**Supersedes the ordering in §4.** §4 still holds for each component's specification.
Every component follows §3's six steps and §3b's three-scale law. **Where it runs is stated,
because it is decided by whether the work can be JUDGED, not by whether it can be built.**

## THE STANDING NET — build this first, it protects everything after it
**`build/city/audit.py`, run after every component.** Six bug classes already paid for once, in
REF-05 §10 and §11. Written as prose they will happen again; written as code they cannot:
1. faces wound **downward** (every road ribbon was, normal.z −1.000)
2. objects with **no material** (the pond discs, which rendered white)
3. objects **floating above or buried in** the terrain (the hill plinth)
4. **open, non-manifold** volumes (the water shell — an open boundary lets absorption run away)
5. features **smaller than one grid cell** (POND_2 at 2×2 cells; the 0.9 m ditches)
6. `dimensions` used where **mass** should be (the "170 m" hill with a 0.03 m median)

---

## COMPONENT 1 · LIGHT — built to 85 %, FINALISED LAST
**Built:** `blend/01_LIGHT.blend`, 33 assertions. 25 Sep 15:30, sun elev 33.11° azim 246.87°,
Nishita 1.7/1.0/1.0, Standard, exposure −3.06, visibility 20 km.
**The remaining 15 % needs the world to exist, so it runs AFTER component 8.**
1. Cull the cloud field: **make it a disc, not a square** (~21 % free — the corners are past the
   20 km visibility), tie the fade end to visibility, **coarsen voxels with distance** (26 m across
   the whole 44 km is the likely biggest saving). **Measure per population and per distance band
   BEFORE cutting.**
2. Fix the field edge: half-width 22 km vs a fade ending at 21 km is only 1 km of margin, so density
   is still high where the mesh stops.
3. Blue holes: the three populations use even Poisson spacing → an even deck. **Drive density with a
   large-scale noise mask** so gaps cluster and come in very different sizes.
4. Cauliflower: **Volume Displace with a finer second noise**, so each lobe carries sub-lobes.
5. **Halation on backlit rims**, coverage 3–6 (REF-12 §4) — named in DEFERRED.md, never applied.
6. Shafts through the streets, cloud shadows on real terrain, haze depth, drift, grade.
**Method:** measure cover %, hole-size spread and lobe scale off the render and sweep against the
43 photographs — the same way the sky was fixed. **Not taste. Numbers.**
**Where:** RTX. On the M1 one cloud look costs 20 minutes; there it is minutes, and this component
is the only one that ever breached 8 GB (11.97 GB, swapping, 433 s → 1335 s).

## COMPONENT 2 · LAND — **M1 WORK COMPLETE 5 Sep**, steps 1-6 done, 7-8 on the RTX
**Built:** `02_land.py` → `02_LAND.blend`, 8 s, **46 assertions, 0 fail**, 720k + 141k tris.
Black bar closed (it was the water *volume*), hill plinth closed, ponds closed, rock banding closed.
**DONE 5 Sep — all six M1 steps, 50 assertions passing, 15 s build, audit clean:**
1. **Per-plot earth tone keyed to the bund grid** — S0 §3 item 14, the last unfinished feature, and
   **the actual cause of the featureless plain.** Ploughed / stubble / bare.
2. **Hill rock contrast** — rock is on 28 % of faces with a shallow ramp; the hill reads pale.
3. **Multi-scale rock and debris (§3b)** — plates splitting into smaller plates of the same shape,
   boulders placed **below the slab that shed them**. This is what survives the zoom.
4. **POND_2** widened from 13 m (2×2 cells) to ≥ 25 m.
5. **A camera that actually shows the scree fans**, then verify — or say plainly that they don't read.
6. Rebuild land (8 s) **and roads (21 s — land is upstream now)**, render the set, look.
**TOMORROW — the render-bound layer, on the RTX:**
7. **Multires sculpt + normal bake** on the hill.
8. **4K displacement inside the five circles only.**
   *Why not on the M1: you cannot judge 4K displacement on an 800×450 / 16-sample preview.*
**AT LAND FINALISATION:** water brightness vs REF-13 (needs haze) · cloud shadows (needs light) ·
fields reading as fields (needs component 6 crops).

## COMPONENT 3 · ROADS — pass 1 done, pass 2 deferred
**Built:** `03_roads.py` → `03_ROADS.blend`. **All 213 OSM ways, 587 pieces, 21 s, all assertions.**
Class counts exact, widths and camber measured off the built ribbon, gradient ≤ 6 %, 43.7 km in the
2 km box, median road-to-ground gap 5 cm. Six bugs in REF-05 §11.
**PASS 2 — after buildings, because bridges and flyovers do not block them:**
1. The **2 real river bridges** at (−640, 740) and (−822, 609). Only two cross the Malin; the other
   nine tagged bridges are **flyovers 1.5 km from any water.**
2. The **9 flyover decks and piers** — 22 m spans, 1800 mm piers.
3. The **railway** — formation 6.85/12.15 m, the **grouped** yard (8–10 tracks, 4.3–5.4 m within
   groups, 8.8–17.7 m between), platforms 0.84 m, 2 level crossings.
4. The **S2 gyratory** — ICD 40 / island 24 / circulatory 8. **It is a gyratory, not a crossroads.**
5. The **S5 hill road** — cut so the vertical faces ARE the cut face; retaining walls, gabions,
   parapets, W-beam, catch drain.
6. **S-scale as material, never geometry:** markings, the 9 clustered potholes, the speed breaker,
   the 100–300 mm crumbling edge, kaccha rasta.

## COMPONENT 4 · BUILDINGS — TOMORROW'S MAIN JOB, ~1000 from ~30 parts
**The single biggest jump in "this is a city", and instancing makes it affordable.**
1. **Model ~30 facade parts, not 25 buildings** — window, shutter, balcony, AC box, sign, awning,
   drainpipe, grille, staircase, water tank, parapet, door, meter box, dish.
2. Masses along the real road network; **vertex groups choose which module goes where** (REF-09 §1).
3. Storeys by **inset → extrude, 3 m at a time** — that stacked profile *is* a shikhara, a plinth,
   a cornice.
4. **Every Level-3 building gets real openings** — doors, windows, a balcony where the type calls
   for one. Not coloured boxes.
5. **The temple** (latina shikhara, plinth, 38 steps, saffron flags) and **the chowk statue** —
   spin + radial array via an empty.
6. **The AO double-stack** (crevice grunge + edge wear, REF-09) for the L2 grime layer.
7. **The close-up grime layer stays inside the five circles** — it is authored per object and cannot
   be instanced. That is the one thing that does not scale to a thousand buildings.
**Audit:** no two neighbours share height, width or colour · storeys 3.0–3.15 m · instance count.

## COMPONENT 5 · INFRASTRUCTURE — before vegetation, and that order is not a preference
1. **11 kV candelabra poles**, 9 m PCC at 45 m, pole-top geometry measured off our own footage.
2. **The wire tangle** — 9–14 parallel runs at different sags, **as a parabola, not a sine**.
3. Transformers on double poles · 415 V four-wire · service drops.
4. The **132 kV lattice line** crossing the fields at an angle, **ignoring the roads**.
5. Signs, hoardings, mobile towers.
**Why it precedes vegetation:** the biggest cause of tree shape is the electricity board's pruning.
In Aditya's own frame the cable line and the foliage edge are the same line. **A tree can only be
cut correctly once the wires exist.**

## COMPONENT 6 · VEGETATION — the second-biggest memory risk after clouds
1. **Alpha cards, not modelled leaves** — modelled foliage was the 51M-face failure (REF-10).
2. **Sapling's prune envelope IS REF-06's constraint mechanism**, measured in metres:
   free-standing 8.91 m → crowded 5.46 → **wire-cut 4.50** → squeezed 2.57 → lopped 1.93.
   *(`prune=True` also makes a junk `envelope` object — delete it.)*
3. Seven ground layers, **one scatter per layer**, clumped by noise into density **and** scale.
4. **Distance-based density falloff** — safe under ~150k instances; past ~250k the 8 GB swaps.
5. **The crops that finally define the fields** — late September: paddy being cut, cane standing,
   plots turned for rabi. **This is what closes land's last open item.**

## COMPONENT 7 · LIFE
Zebu and buffalo with correct gait · macaques · people at Fruin crowd densities · vehicles · birds.
Instanced, low counts — no memory risk.

## COMPONENT 8 · BLENDING — cannot be done per component, by definition
It **is** the relationships: contact shadows, dust where wheels run, stains where water falls, wear
where hands touch, the canopy interlock, colour bleeding between neighbours.

## THEN · LIGHT FINALISED → **ADITYA'S GATE**

---

## THE SCHEDULE AS AGREED, 5 Sep 2026
| when | where | what |
|---|---|---|
| **today** | M1 | Land steps 1–6, then `audit.py` |
| **tomorrow, ~8 h** | **RTX** | **Account A (the chain): component 4 BUILDINGS** · **B: facade parts + temple + statue → `assets/buildings/`, logs REF-14** · **C: trees + ground layers → `assets/vegetation/`, logs REF-15**. **Last 1–1.5 h: light finalisation**, because that is what makes the wide shot read |
| after | — | roads pass 2 · infrastructure · vegetation · life · blending |

**THE TWO RULES THAT MAKE THE PARALLEL ACCOUNTS WORK:** no account edits another's files —
especially not `S0-THE-WORLD.md`, `PLAN.md`, or a `.blend` the chain owns; and **every account
writes its findings to its own REF doc, because chats cannot talk.**

**STATED PLAINLY: 8 hours does not finish the city.** Buildings alone is a full session, and
infrastructure, vegetation, life and blending are four more. The backup covers the demo, so the
right call is **buildings finished properly rather than five components at 60 %** — that 60 %
failure is exactly what cost Quiesce, Tenable and NETRA.


---

# 10 · FINISHING THE LAND — the complete phase plan, written 5 Sep 2026
**Aditya's instruction: gather everything, build it in phases, ONE BUILD AT A TIME, and show it in
Blender after each. After this we do not come back to the land.**
Everything below is gathered from: S0 §3 (original + the 14 extended features + THE WATER BODY +
THE HILL HAS NO PAD + THE GROUND MATERIAL) · PLAN §3b (the three-scale law) · REF-04 §9 §10 §13 ·
REF-07 §3 §4 §6 §7 §8 §10b · REF-11 §2 · REF-13 §5 §6. Nothing here is invented.

## WHAT IS ALREADY DONE — not repeated below
Terrain 4 km² / 720k tris / three undulation scales · the Malin carved to a descending bed · the
water as a closed watertight WEDGE with a real depth gradient · the hill at 170 m following the
ground with no pad and no skirt, its footprint 498 × 342 m on the NW axis · the Eroder's drainage
network with gullies at Shivalik density · scree fans placed from the `deposit` group · quarry
benches · waterfall and plunge pool · the distant range · all 14 extended features **as geometry** ·
the per-plot farmland material at three scales · one hill material blending earth→rock per pixel ·
`audit.py` · 52 assertions.

## THE GAP THIS PLAN CLOSES, stated once
**The land is SHAPED but not SURFACED.** Measured 5 Sep: the terrain is **100 % one material**, and
**zero of the 14 features have any material keyed to them.** A threshing floor, a gravel bar, the
Bhabar apron and a pond's spoil bank all currently wear farmland with plot rectangles painted across
them — **the same bug already fixed on the hill, not yet fixed on the plain.**

---

## PHASE 1 · SURFACE THE GROUND — M1, ~1 build
**Spec first: amend S0 §3 with a materials table, then build.**
1. **Bake every layer mask into a terrain colour attribute**, the method already proved on the hill's
   `EROSION` attribute. Channels carry: gravel/bar · apron/pebble · worked-bare · wet/sediment.
2. **Key the material off them.** Each is REF-sourced, none invented:
   | feature | reads as | source |
   |---|---|---|
   | braided bars, river banks | **pale grey-tan gravel**, same material as the banks | REF-13 §6 |
   | Bhabar apron | pebbly alluvial fan, small stones in the top layer | REF-04 §10 |
   | threshing floors | hard swept bare earth, no crop, no furrow | REF-04 §9 |
   | pond + clay-pit spoil banks | raw excavated earth, darker, unvegetated | S0 §3 items 7, 12 |
   | nala beds + irrigation channels | damp sediment, darker than the plot | REF-04 §13 |
   | flood terrace | the step reads as a tonal break | S0 §3 item 10 |
   | paleo channels | damp low ground, REF-04 §10's near-black humus | REF-04 §10 |
   | quarry spoil | broken rock, not soil | S0 §3 item 5 |
3. **TWO FREQUENCIES PER MATERIAL, not one** — REF-07 §3's refinement: blend a high-frequency and a
   low-frequency map for each surface. **That, not colour, is what kills tiling.**
4. **S-scale on the plain** (PLAN §3b): stones, clods and cracked dry patches — **placed by cause**
   (stones on the apron and bars, cracks on the drying fallow, clods on the ploughed), never scattered.
5. **Fix `WATER_PIT_1`'s non-manifold pinch** — one edge shared by four faces where two lobes meet.
6. Rebuild → `audit.py` → render → **open in Blender.**
**GATE: the terrain uses more than one surface, and every one of the 14 features is visible as itself.**

## PHASE 2 · DETAIL THAT EARNS ITS PLACE — M1, ~1 build
7. **REAL 3-D ROCKS, AND ONLY WHERE THEY EARN IT.** REF-07 §4, quoting the UE5 breakdown:
   *"I did not put 3D rocks all over my mountains, only in areas where there was light and they could
   add detail."* So: **inside the five scenario circles, and on the hill's lit face** — nowhere else.
   Placed by the **three-scale debris law**: slabs → boulders **that fell from them** → pebbles caught
   by the boulders. Instanced, so the cost is ~30 rocks however many are placed.
8. **CULTIVATED TERRACES on the hill's workable slopes** — REF-13 §6: *"cut into every workable
   slope, as thin horizontal steps… they read at 2 km as fine horizontal lines and they are what
   tells you people live there."* Currently missing entirely.
9. **MULTIRES SCULPT + NORMAL BAKE on the hill.** Verified working (REF-05 §7). Judged on this
   machine by **rendering a small CROP at full resolution** (`render.use_border` — REF-07 §8's
   `Ctrl+B` trick, scripted), which is a real check, not a compromise.
10. **A 1.7 m human reference figure** in the scene — REF-07 §8. *"Would have caught the 5.6 m road
    and the 13 m poles."* Cheap, permanent, and it makes scale errors impossible to miss.
11. Rebuild → `audit.py` → render → **open in Blender.**
**GATE: the hill holds up close AND from 2 km, and nothing is the wrong size.**

## PHASE 3 · LIGHT + LAND, COMBINED — `04_WORLD.blend`, ~1 build
**This is the one Aditya asked to see, and it is also LAND FINALISATION.**
12. **CULL THE CLOUD FIELD FIRST — it is a prerequisite, not a tidy-up.** The three-population field
    peaked at **11.97 GB on an 8 GB machine** and swapped (433 s → 1335 s/frame). Three cuts, all
    real fixes and all already listed in §9:
    **make the field a DISC, not a square** (~21 % free — the corners sit past the 20 km visibility) ·
    **tie the fade end to visibility** so it is derived, not chosen · **coarsen voxels with distance**
    (26 m across the whole 44 km is the likely biggest saving).
    **Measure memory per population and per distance band BEFORE cutting.**
13. **CLOUD SHADOWS ON THE TERRAIN** — REF-07 §6 Method A: a large plane above the scene, **4D Noise
    → ColorRamp → Alpha**, blocking light in patches; animate W and they drift. *"A sky texture alone
    casts no cloud shadow, and the mismatch reads as fake immediately."*
14. **HAZE, and it must do TWO things** — REF-13 §5, measured in depth bands off ref_31: saturation
    collapses 53 → 19 % **and local contrast collapses with it, 43 → 21.** Ours only did the first.
15. **NOW measure the water against REF-13 §6** — braided river R143 G148 B156 sat 8.7 %, plains
    water R128 G141 B145 sat 12.4 %. This could not be judged before, because the comparison is only
    valid with haze present.
16. Combine into **`04_WORLD.blend`**: sun · sky · culled cloud · haze · land · roads · all cameras.
17. `audit.py` → render the full set → **open in Blender.**
**GATE: Aditya looks. If it passes, LAND IS CLOSED.**

## HONEST LIMITS — stated now, not discovered later
- **Fields will not fully read until component 6 puts crops on them.** The earth is component 2's
  job and will be finished; what grows on it is not.
- **4K displacement inside the five circles stays on the RTX.** It can be authored here but not
  judged at 800 × 450 — and a crop render only validates the hill, not five whole circles.
- **If the cloud cull does not bring the field under ~4 GB, Phase 3 ships without volumetric cloud**
  and says so, rather than handing over a file that hangs the machine.
