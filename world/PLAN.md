# THE BUILD PLAN — component-major
**Rewritten 3 Sep 2026, 23:45. Supersedes the stage-major ordering in `notes/BLENDER-PIPELINE.md`
Part Seven. The two RULES are unchanged and still govern everything.**

> **RULE 1 — Nothing is built until it is written.**
> **RULE 2 — A component is finished when it matches its specification exactly.** Not "good enough,
> I'll fix it later."

## 1 · THE STANDARD — what "done" means, in Aditya's words
**Everything, everywhere, must read correctly as what it is.** A house looks like a house from any
angle a person looks at it. A tree looks like a tree. A road like a road. An animal like an animal.
**The whole 4 km gives proper city vibes. It feels alive.**
Set 3 Sep 2026; written into `scenarios/S0-THE-WORLD.md` §4 as the Level-3 revision.

**Time is not the constraint. The specification is.** Build it properly.

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

## 4 · THE EIGHT COMPONENTS, IN BUILD ORDER
The order is a dependency chain, not a preference. **Each component can only be built correctly once
the thing that constrains it exists.**

### 1 · LIGHT — set first, finalised last  *(rewritten after REF-12)*
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
**Audit:** never flat anywhere · drainage density ≈ 4.55 km/km² · only river run 0 used, not all 24.

### 3 · ROADS — every made surface, and the structures that carry one
All **213 roads / 47.3 km**, real widths by class · markings, 2.5 % camber, crumbling edges, the
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
- **S0 §2 internal conflict:** azimuth is written **095°**, described as "just north of due east."
  095° is 5° *south* of east. **Building the number as written; flag for Aditya to settle.**
