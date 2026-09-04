# The Blender production pipeline — SIH26037
Written 2 Sep 2026 from tutorial research + everything verified on Aditya's own machine.
**This is the reference for the BUILD chat. Read it before touching Blender.**

---

## 0 · THE MACHINE — this dictates every decision

| | |
|---|---|
| Apple M1 base, **7-core GPU**, **8 GB unified RAM**, ~6.5 GB free disk | |
| Blender **4.5.11 LTS**, Cycles, **Metal enabled** (it was OFF — if renders crawl, check this first) | |
| Render times observed | 32 samples @1280x720 ≈ **80–110 s** |

**Reference weights from real tutorials (read off their status bars):**
- CG Boost landscape: 98k verts / 195k faces / **926 MB / 3.2 of 8 GB VRAM**
- Graswald meadow: 184k verts / 281k faces / **2.6 of 8 GB VRAM**

So a finished environment fits in ~3 GB. **We have room.** Stay under ~150k instances.

**Rules that follow:**
- Geometry Nodes **instancing**, never object copies
- Textures: **4K only for what the camera is close to** (~300 MB per PBR material). 2K mid. **512 for anything scattered.**
- `Distribute Points on Faces` → **method RANDOM**, never Poisson (far heavier)
- Heavy collections → Viewport Display **Bounds**, or the viewport locks up
- Delete instances outside the camera cone and past ~60 m

---

## 1 · THE PIPELINE — seven stages, in order, each gated

**1 · FOUNDATION** — shapes only, grey clay. Ground that undulates, road, verge zones.
*Gate: does the SHAPE read as a road?*

**2 · DETAIL** — everything standing on it. Poles, wires, walls, hoardings, shops, bricks,
debris, trees, grass layers, vehicles, animals, people.
*Gate: is anything in the reference footage missing?*

**3 · TEXTURE** — real PBR maps on every surface. **This is where a clay model becomes a place.**
*Gate: close-up render of each material alone.*

**4 · BLEND** — the sixteen points in [[sih26037-realism-bar]]. Ground into object bases,
contact shadows, shared dust, no straight material edges, nothing repeating.
*Gate: does anything look pasted on?*

**5 · TOUCH-UP** — specific imperfections. Stains, a leaning post, moss, a torn hoarding, tyre marks.

**6 · COLOUR GRADE** — match the reference footage: contrast, colour, haze, grain, lens
distortion, compression.
*Gate: side by side against a real dashcam frame.*

**7 · FIX** — whatever the side-by-side exposes.

---

## 2 · TECHNIQUES — all read off real tutorial frames, not guessed

### 2.1 Ground texture blending — THE most valuable one
From "Create REALISTIC Forest Roads in Blender". How they get worn paths instead of one flat surface:

```
Noise Texture (3D, fBM, Normalize ON)
  Scale 7.640 · Detail 2.000 · Roughness 0.500 · Lacunarity 2.000 · Distortion 0.000
    -> Color Ramp (RGB, Linear, stops at 0.000 and 0.445)
      -> Mix (Color) Factor
Texture Coordinate -> Mapping (Point) -> Image Texture (e.g. rocky_trail_02_diff_4k)
Surface: Mix Shader, Fac from the same Color Ramp, mixing two Principled BSDFs
```
Material settings they used: **Displacement = Bump Only**, Transparent Shadows ON,
Render Method Dithered, Light Probe Volume ON.

**Two ground materials blended by a noise mask.** Never one uniform ground.

### 2.2 Scatter, as the professionals do it
Also from the forest-road tutorial's geometry nodes:
- `Distribute Points on Faces` **RANDOM**, Density driven by a **Multiply** node
  (base density x mask) — Random has **NO Density Factor socket**, that is Poisson-only
- `Random Value` **FLOAT** for scale — their range was **narrow, 0.150–0.200**
- `Random Value` **VECTOR** for rotation
- **`Store Named Attribute`** for per-instance colour (`blueSpruceColor` in their tree)
- Their outliner had **three tree species** (Blue_Spruce, Red_Spruce, White_Fir_Mature_HD)

### 2.3 The attribute mask trick — how a road is carved through vegetation
Their spreadsheet showed named attributes: `position, smoothing, path, pathTracks, blueSpruceColor`.
**Paint or compute a mask ONCE as a named attribute on the terrain, then reuse it everywhere:**
remove trees where `path` is high, switch the ground texture, add tyre tracks.
One mask drives vegetation, material and detail together — which is why theirs looks coherent.

### 2.4 Camera
CG Boost used **102.7 mm** focal length for landscape (long lens compresses depth) and a
**"CameraWobble" empty with Influence 0.200** for a handheld feel.
**Our dashcam is different: 24 mm, sensor 36 mm, height 1.32 m.**

### 2.5 Volumetric haze — THE TRAP
**Never put Volume Scatter on the WORLD.** It makes the sky infinitely distant, extinguishes
all light and renders **pure black**. Cost an hour.
**Always a bounded box** around the scene with a Principled Volume, camera inside.
- Density **0.001–0.006** for haze (1–10 is thick fog)
- **Noise Texture into Density** or it is a flat uniform wash — real haze is wispy
- **Anisotropy 0.55–0.75 positive** = forward scatter, which is what headlights in fog do

### 2.6 Foliage alpha — the bug that made every tree a skeleton
Sketchfab/FBX foliage often imports with Alpha driven by a threshold Math chain that evaluates
to **0**, making leaves fully invisible. The tree renders as bare branches.
**Fix: wire the diffuse Image Texture's own `Alpha` output straight into Principled `Alpha`,
set the image `alpha_mode='CHANNEL_PACKED'`, material `blend_method='HASHED'`.**

### 2.7 The compositor chain for dashcam realism (run last)
```
Render Layers -> RGB Curves (crush blacks, clip whites)
 -> Filter SHARPEN 1.8            (cheap sensors over-sharpen; haloing on wires)
 -> Lens Distortion  Distort 0.06  Dispersion 0.025  Fit ON  Jitter ON
 -> Mix Color OVERLAY 0.15 with a noise Texture   (high-ISO grain)
 -> Separate Color YUV -> Blur U and V (Fast Gaussian 6px), Y untouched -> Combine Color YUV
 -> Scale Relative 0.25 -> Pixelate -> Scale Relative 4.0 -> Posterize Steps 32
 -> Mix Color 0.3 against the pre-block image -> Composite
```
Blender 4.5 has **no Chromatic Aberration node** (that is 5.x) — use `Lens Distortion`'s
**Dispersion** input instead. Every other node above is verified present in 4.5.11.

### 2.8 Lighting
- **Nishita Sky Texture.** `dust_density` max is **10** (a source claimed 777 — impossible).
  Our values: sun_elevation 22 deg, altitude 220, air 2.0, dust 2.2–4.5, ozone 6.0
- **Two skies:** camera sees a photographic HDRI, scene is lit by the Sky Texture, split with
  `Light Path > Is Camera Ray` into a `Mix Shader`. Stops a foreign HDRI background leaking in.
- **Black plane behind the camera** (Ray Visibility: Camera OFF) = negative fill, creates contrast.
  Without it outdoor renders go flat and washed.
- **Emission-shaded projected photo geometry with Camera visibility OFF** throws real coloured
  light into the scene while staying invisible.

### 2.9 Projecting real photographs onto geometry
Two methods. **Use the bake one** — it survives the camera moving.
1. `U` -> **Smart UV Project** on the target
2. `Texture Coordinate` **Window** -> `Mapping` -> `Image Texture` (**Extension = CLIP**)
   -> `Emission` -> Material Output
3. Add a second Image Texture, click **New**, leave **disconnected**, **select it**
4. Be in **Camera View (Numpad 0)** — Window coords depend on the view
5. Render Properties -> Bake -> **Bake Type = Emit** -> Bake (~20 s)
6. Delete the projection graph, plug the baked image into Base Color

Free depth from the photo: image Color -> `Bump` **Distance 0.1** -> Normal.
`fSpy` (free) recovers focal length and camera angle from a single photo.

### 2.10 Why renders read as fake — the consensus
- **A single flat Roughness value is the biggest single tell.** It must VARY across every
  surface, driven by noise or grunge. This is what made our tarmac look like plastic.
- Nothing in the real world is clean: scratches, dust, smudges, edge wear.
- **Bevel every hard edge** — perfectly sharp corners do not exist and catch no light.
- Displacement, not just normal maps, where the silhouette matters.
- A material needs colour + roughness + normal + AO, never colour alone.

---

## 3 · ASSETS — what exists and what does not

| Need | Source | Status |
|---|---|---|
| Ground, rock, rubble, bark, plants | **Quixel Megascans** (free, Fab Standard Licence, works in Blender via Quixel Bridge + Megascans Bridge addon) | **the fix for "one good asset"** |
| Surfaces, HDRIs, some trees | **Poly Haven** (MCP-connected, works now) | 20 asphalt textures, 106 brick, 992 HDRIs. **Only 4 usable broadleaf trees** — 14 of 18 are pine/fir/desert |
| Scatter system + free plants | **GScatter by Graswald** — free addon, ships plant assets | not installed yet |
| Trees | **Ficus microcarpa** CC-BY, 111k faces, real aerial roots — genuinely an Indian street tree despite the name | **our only photoscanned tree**. *F. benghalensis* exists but is NC-ND, unusable |
| Auto-rickshaw | Sketchfab — several, incl. a **real LIDAR scan from Ahmedabad** (116k faces, CC-BY) | available |
| Cows | Sketchfab — several, incl. an **animated idle** (56k, CC-BY) | available |
| People + animation | **Mixamo** — free with an Adobe account, 2000+ mocap clips, rigged | generic Western bodies |
| **Indian shops, stalls, buildings** | — | **NOTHING EXISTS. Must be built by hand.** The single biggest gap |
| Monkeys | — | nothing but skulls |
| AI-generated models | Hyper3D Rodin (free trial key set in the .blend) | **tested: produces cartoon/game-art, NOT photoreal.** Only usable for tiny background props |

**Sketchfab search behaves oddly with long queries** — use ONE or TWO words ("cow", not
"realistic indian cow"). The key is stored per-.blend and is lost on File > New.

---

## 4 · WHAT IS ALREADY BUILT

`~/Desktop/SIH26037-Reference/blend/tile01.blend` — **save after every step, it was lost once**

Ground (grid + vertex-group-masked displacement, flat under the road) · road with a
random-walk crumbling edge and camber · 4K asphalt with roughness variation and polished tyre
tracks · 7 vegetation layers (weeds/short/mid/tall, asymmetric left-right) · 5 ficus trees with
3 pruned variants, planted in soil mounds with root debris · X-braced twin poles with sagging
catenary wires · compound wall, hoarding, brick pile, 70 debris pieces · bounded noise haze ·
black light-blocker · dashcam camera 24 mm @1.32 m.
**~24,000 instances, renders in ~90 s.**

Reference: `~/Desktop/SIH26037-Reference/` — 13 dashcam clips, 64 frames, 6 tree photos,
notes in `notes/`.

---

## 5 · BUGS THAT COST HOURS — do not repeat

1. **Camera lens silently became 1.0 mm** — every render was a radial smear and I blamed the
   geometry. **Check `scene.camera.data.lens` when anything looks stretched.**
2. **119 orphaned mesh parts** from a bad hierarchy copy sat around the camera, 9 m underground.
   **After flattening an imported model, delete EVERY source object by name prefix.**
3. **Metal was off** — `compute_device_type` was NONE while `cycles.device` was GPU, so
   everything rendered on CPU.
4. **Modifier order** — displacement added after a geometry-nodes modifier runs *after* it and
   undoes the flattening. Order must be subsurf -> displace -> nodes.
5. **World volume = pure black render.**
6. **Foliage alpha threshold = invisible leaves.**
7. **The .blend was never saved** and the scene was lost to a crash. Autosave was useless
   (it captured the fresh session, not the work).

---

## 6 · HOW TO GET VISUAL INFORMATION

**`yt-dlp` is installed and working** (upgraded to 2026.08.19 — older versions get HTTP 403).
```bash
yt-dlp "ytsearch5:<query>" --flat-playlist --print "%(duration>%H:%M:%S)s %(id)s %(title)s"
yt-dlp -f "bv*[height<=720]+ba/b[height<=720]" -o "v.%(ext)s" "<url>"
ffmpeg -ss <t> -i v.webm -frames:v 1 -vf "scale=1100:-1" out.jpg
```
**Frames at 1100 px wide are readable enough to see node names, socket values and the status
bar.** That is how every technique above was obtained. Delete the video after extracting —
disk is tight.

---

## 7 · WHAT ADITYA WANTS — the standard, in his words

> "Realism. Natural. A seamless blend of everything. Detailed. A whole natural environment
> in the simulation, like a reality being made in Blender. Not less than any of that."

Specifically asked for: **every tree different** · greenery in patches **with a reason for each
gap** · leaves interconnecting between neighbouring trees · multiple road types (narrow rural,
highway) · shops · people · cows · monkeys · crowds · taller telecom lattice towers ·
clouds and full sky · colour grading · texture blending · sculpting.

**He judges by looking, side by side against his own dashcam footage. Never on its own.**
He does not read documents — give him images and one-line decisions.

---

# PART TWO — broader research, 2 Sep 2026
All read off tutorial frames. Node values and settings are what was actually on their screen.

## 8 · SAMPLING — I have been doing this wrong

From the cliff-environment tutorial's render panel:

| | Viewport | Render |
|---|---|---|
| **Noise Threshold** | 0.1000 | **0.0100** |
| Max Samples | 1024 | **4096** |
| Min Samples | 0 | 0 |
| Denoise | ON | ON |

**The noise threshold is the real control, not the sample count.** Cycles stops each tile as
soon as it is clean enough. Setting max samples to 4096 with a 0.01 threshold gives a CLEAN
image that often finishes early — far better than my fixed 32–40 samples, which just gives a
noisy image in a fixed time.

Also on their panel: **Feature Set = Experimental**, Device = GPU Compute,
**Subdivision Dicing Rate: Render 1.00 px / Viewport 8.00 px, Offscreen Scale 4.00**
(Experimental enables adaptive subdivision, which is how they get real displacement.)

Their scene: 118k verts / 112k faces / **5.34 GB memory / 3.82 of 8.0 GB VRAM.**
**They are working on an 8 GB card — the same ceiling as ours.** It is enough.

## 9 · EEVEE FOR ITERATION — the fix for working blind

The water tutorial used **EEVEE** (Viewport 16 samples, Render 64). EEVEE renders in
**seconds**, Cycles in ~90 s.

**Use EEVEE to judge composition, placement, scale and colour. Switch to Cycles only for the
final.** This directly addresses the biggest practical limit — that I get ~20 looks per hour
instead of hundreds. Most decisions do not need path tracing.

## 10 · THE UNIVERSAL PATTERN — mix two materials with a mask

This same structure appeared in every single tutorial, for every surface type:

```
<mask source>  ->  Color Ramp  ->  Mix Shader / Mix Color  Fac
      material A ->  Shader 1
      material B ->  Shader 2
```

- **Ground / road:** mask = Noise Texture (Scale 7.640, Detail 2.0, Roughness 0.5, fBM,
  Normalize ON), ramp stops 0.000 and 0.445. Blends tarmac into worn trail.
- **Buildings:** mask = a **painted image texture** ("blue paint"), blending a paint layer over
  a "Red Plaster" node group. Their building: 1.9 M verts, 236 objects, 2.69 GB.
- **Terrain:** same, with a hand-painted or attribute mask.

**Never give any surface a single flat material.** That one habit is most of the difference
between clay and photoreal.

## 11 · THE ATTRIBUTE MASK — how one decision drives everything
Their terrain spreadsheet carried named attributes: `position, smoothing, path, pathTracks,
blueSpruceColor`.

**Compute or paint the mask ONCE onto the terrain as a named attribute, then read it everywhere:**
- remove scattered vegetation where `path` is high
- switch the ground material to worn tarmac
- add tyre tracks
- drive per-instance colour

One mask, three effects, all consistent. **This is why their scenes look coherent and an
assembled scene does not.** Do this for our road corridor.

## 12 · WATER
From the water tutorial (EEVEE):
```
Texture Coordinate -> Mapping -> Wave Texture -> Bump -> Principled Normal
```
Wave Texture drives surface ripple through a Bump node. For puddles on our road: the same,
masked to the low points of the ground, with high Transmission and low Roughness.
Puddles matter — every one of Aditya's rainy frames has standing water at the road edge.

## 13 · BUILDINGS — and this is the biggest gap we have
Indian shops do not exist as free assets. They must be built. What the buildings tutorial shows:
- **Modular construction** — their building was **236 separate objects**, not one mesh
- Materials are **node groups** ("Red Plaster W...") reused across pieces
- Blending done with a **painted mask image**, not procedural noise, so it is art-directed
- Displacement wired from the material node group, not just normals

For our roadside shops: build a small kit — shutter, awning, pillar, signboard, step, counter —
then combine them differently per shop. That is how a street of unique shops comes from six pieces.

## 14 · TREE SPECIES — confirmed by every tutorial
Both environment tutorials had **three distinct tree species** in their outliner, each with
several duplicates (`island_tree_01/.001`, `island_tree_02/.001`, `island_tree_03/.001/.002`;
`Blue_Spruce`, `Red_Spruce`, `White_Fir_Mature_HD`).

**Three species with variants is the professional minimum.** One species repeated is the single
most obvious tell, and it is exactly what Aditya called out.

## 15 · FREE SCATTER ADDON
**GScatter by Graswald** — free, ships its own plant assets. Seen in "The Key to Realistic
Environments in Blender", scattering six species (Golden Marguerite, Musk Mallow, Hoary Alison,
Viper's Bugloss, Wild Chamomile) with Distance Min / Density / Seed and separate
Distribution / Scale / Rotation / Geometry effect layers.
Their meadow: 184k verts, **2.6 of 8 GB VRAM**.
Worth installing — the paid alternative (Geo-Scatter / Scatter5) is what the CG Boost course uses.

## 16 · RESEARCH METHOD — repeatable
```bash
yt-dlp "ytsearch3:<topic>" --flat-playlist --print "%(duration>%H:%M:%S)s %(view_count)9d %(id)s  %(title).60s"
yt-dlp -f "bv*[height<=720]+ba/b[height<=720]" --no-playlist -o "v.%(ext)s" "https://www.youtube.com/watch?v=<id>"
ffmpeg -ss <t> -i v.webm -frames:v 1 -vf "scale=1100:-1" out.jpg
```
**1100 px wide frames are readable enough for node names, socket values, and the status bar**
(vert count, memory, VRAM). Sample 8–14 frames evenly across the video. Talking-head frames are
useless — skip to timestamps where the screen is shared. Delete the video after extracting.

**Do not trust a value quoted in text without seeing it on screen.** A Gemini extraction claimed
Sky Texture "Dust 777" when the maximum is 10.

---

# PART THREE — technique sweep, 2 Sep 2026
Read off frames. Every number below was on their screen.

## 17 · THE WASHED-OUT RENDER — solved

From "Make realistic environment lighting in Blender" (Obaidur Rahman), World node graph:

```
Sky Texture (Nishita)              Background
  Sun Disc      ON                   Strength  0.250      <-- NOT 1.0
  Sun Size      0.545 deg
  Sun Intensity 1.000
  Sun Elevation 90 deg
  Sun Rotation  16.4 deg
  Altitude      0 m
  Air 1.000 · Dust 1.000 · Ozone 1.000
```

**Background Strength 0.250.** Every render of ours was at 1.0, which floods the scene with
ambient light from every direction, kills contrast and washes everything to pale beige.
**This is the single biggest cause of our flat renders.** Sun does the lighting; the sky is
fill, and fill should be quarter strength.

Their scene at those settings: 1,137,561 verts / 812,703 faces / **2.92 GB / 4.1 of 6.0 GB VRAM.**

## 18 · PROCEDURAL BUILDINGS — the answer to "Indian shops do not exist"

From "How to Create Procedural Buildings | Geometry Nodes". Their outliner had exactly three
collections: **`Collection`, `Facade_Assets`, `Ground Floor Assets`.**

The method: **a Plane + Geometry Nodes that instances facade panels from a collection, bay by
bay and floor by floor.** Ground-floor pieces come from a different collection than upper floors.

**For our Indian street:** build a small kit once —
`shutter · awning · pillar · signboard · step · counter · window · AC unit · hoarding bracket`
— put ground-floor pieces in one collection and upper-floor pieces in another, then let geometry
nodes pick randomly per bay. **Six to nine pieces produce a street of buildings where no two
are the same.** That is the only realistic route, since nothing exists to download.

Their render settings: Cycles, **Feature Set Supported**, GPU Compute, Noise Threshold 0.1000,
Max Samples 1024, Min 0, Denoise ON.

## 19 · VEHICLES DRIVEN BY A PATH — exactly what MATLAB will feed us

From the **Rigacar** tutorial (free Blender addon). This is the bridge from MATLAB trajectories
to moving cars, and it removes all hand-animation of wheels.

**Follow Path bone constraint on the car rig Root:**
```
Target        NurbsPath
Follow Curve  ON        Fixed Position ON
Curve Radius  OFF
Forward       -Y        Up  Z
Influence     1.000
[Animate Path]
```

**Then "Bake car steering":**
```
Start Frame 1 · End Frame 1000
Keyframe tolerance 0.40
Rotation factor    1.00
```
Rigacar also exposes **Wheels on Y axis, Suspension factor 0.200, Suspension rolling factor 0.200**.

**Wheel rotation, steering angle and body roll are all computed from the path automatically.**
So the workflow is: MATLAB writes positions -> import as a curve -> Follow Path -> bake steering.
Nothing hand-keyed.

## 20 · EXCLUDE FROM VIEW LAYER — stronger than hiding

From the optimisation tutorial: the outliner checkbox **"Exclude from View Layer"** removes a
whole collection from the dependency graph entirely. `hide_render` still evaluates the objects;
exclude does not. **Use it for anything not needed in the current shot** — it frees real memory,
which matters at 8 GB.

Also confirmed there, from the Blender manual on screen: **Min Samples at 0 is automatically
derived from the Noise Threshold.** So set the threshold and leave min samples alone.

## 21 · MODULAR KITS AND TRIM SHEETS — the game-art way
The kit approach appeared across several tutorials and is what makes large environments cheap:
- Build a **small set of interchangeable pieces** that snap on a fixed grid
- **One texture atlas / trim sheet** shared by the whole kit, so the entire building is one
  material and one texture — enormous memory saving
- Variation comes from **combination and rotation**, not from unique assets

At 8 GB this is not a stylistic choice, it is how the scene fits at all.

## 22 · CONSOLIDATED SETTINGS — what to actually use

```
Render Engine     Cycles (final) / EEVEE (all iteration)
Feature Set       Experimental   (needed for adaptive subdivision)
Device            GPU Compute (Metal)
Noise Threshold   0.0100 render / 0.1000 viewport
Max Samples       4096 render / 1024 viewport      Min Samples 0
Denoise           ON both
Dicing Rate       1.00 px render / 8.00 px viewport   Offscreen Scale 4.00
View Transform    AgX          Look: Medium High Contrast
World Background  Strength 0.250        <-- the fix for washed-out frames
Sky               Nishita, Sun Disc ON, Sun Size ~0.545 deg
```

## 23 · SUMMARY — the ten things that matter most, in order

1. **World background strength 0.25**, not 1.0. Contrast comes back.
2. **Noise threshold, not sample count.** 0.01 for final.
3. **EEVEE for every look, Cycles only for the final.** Seconds instead of 90.
4. **Two materials mixed by a mask, on every surface.** Never one flat material.
5. **One named attribute mask** drives vegetation removal, ground material and detail together.
6. **Three tree species minimum**, each with variants.
7. **Roughness must vary** across every surface. A flat roughness value is the biggest tell.
8. **Modular kits + one shared texture** for buildings. Nine pieces, a whole street.
9. **Rigacar + Follow Path** turns a MATLAB trajectory into a driving car with working wheels.
10. **Exclude from View Layer** for anything out of shot.

---

# PART FOUR — the film look, and where to start

## 24 · HALATION — the warm bloom real film has
From "How to Emulate Film in Blender (Color, Grain & Halation)". Exact node values on screen:

```
Render -> Glare
            Type       Fog Glow
            Quality    Medium
            Mix       -0.700
            Threshold  0.025
            Size       8
       -> Mix RGB (ADD, Clamp OFF)
            Image 1 = the render
            Image 2 = a flat ORANGE colour
       -> Composite
```
Bright areas bleed a warm orange halo into what surrounds them. **This is one of the strongest
single cues that an image was photographed rather than computed** — real film stock and real
sensors both do it, and no renderer does it by default.

Combine with the dashcam chain in section 2.7. Order: **grade first, then halation, then lens
distortion, then grain, then compression.** Damage goes last, always.

## 25 · WHAT THE RESEARCH DID NOT FIND
Being explicit so nobody wastes time re-searching:
- **No good crowd tutorial.** What exists is either one-minute gimmicks or basic rigging. For our
  pedestrians: Mixamo clips on instanced characters, offset in time, is the practical route.
- **No Indian street environment tutorials at all.** The nearest is generic "custom buildings".
  Confirms section 18 — the shop kit must be built from scratch.
- **Rodin / AI generation is not usable for hero assets** — tested, produces game-art trees.

## 26 · WHERE THE BUILD CHAT SHOULD START

In this order, because each fixes something measured, not guessed:

1. **World Background Strength 1.0 -> 0.250.** One number. Fixes the washed-out flatness that
   has been wrong in every render so far.
2. **Switch iteration to EEVEE.** Composition, scale, placement, colour — none of it needs Cycles.
   Then Cycles with **Noise Threshold 0.01 / Max 4096** for the final only.
3. **Give every material a varying roughness.** Flat roughness is the biggest single tell.
4. **Every surface = two materials mixed by a mask.** Ground, road, wall, everything.
5. **One named attribute on the terrain** driving vegetation removal + ground material + tracks.
6. **Build the shop kit** — nine pieces, two collections, geometry nodes instancing.
7. **Get more tree species.** Three minimum, each with variants.
8. **Then blend** (the sixteen points), **then grade** (dashcam chain + halation).

## 27 · TUTORIALS ACTUALLY MINED — for re-reference
| id | what it gave |
|---|---|
| `md8mbgTEfIk` | GScatter free addon, meadow at 2.6 GB VRAM |
| `fFBX1A776-o` | **ground texture blending by noise mask** — the most valuable single technique |
| `ilaD-V8R1gI` | buildings as 236 modular pieces, materials mixed by painted mask |
| `eduPidSJrsg` | **noise threshold sampling**, adaptive subdivision, 8 GB VRAM is enough |
| `PNUjeJ0ugaA` | water: Wave Texture -> Bump; **EEVEE is viable** |
| `hGgAEp-n0uk` | **procedural buildings from facade collections** |
| `O2H1CUh1Zh4` | **Background Strength 0.250** — the washed-out fix |
| `MN6CXG83Wdw` | **Rigacar + Follow Path** — MATLAB trajectory to driving car |
| `a0GW8Na5CIE` | Exclude from View Layer; min samples derives from threshold |
| `0M0-TESgB7E` | **halation** — Glare Fog Glow into an orange Add |
| `yBP5x87HNXE` | CG Boost: 102.7 mm lens, CameraWobble 0.200, scene at 3.2 GB |

Method to mine more is in section 16. It works; use it rather than guessing.

---

# PART FIVE — the two gaps I named, now closed

## 28 · ANIMATING LIVING THINGS — the cow, and anything that breathes

### 28.1 Rigify has a QUADRUPED metarig, built in
From "How to Rig a Four-Legged Animal in Blender | Rigify Quadruped".
Blender ships **Rigify** (enable in Preferences > Add-ons). It includes a **four-legged metarig**
— spine, four legs, neck, head, tail, all pre-built.

Workflow: add the quadruped metarig -> scale and fit the bones inside the animal mesh ->
**Rigify panel > `Generate Rig`** -> a full IK control rig appears. Then parent the mesh with
automatic weights.

Their panel showed bone groups like `Arm.L (IK)`, Viewport Display `Octahedral`, with
Shapes / Bone Colors / In Front all on.

**Fitting the bones is the one genuinely manual step.** Everything before and after it scripts.

### 28.2 The F-CURVE NOISE MODIFIER — organic motion with zero keyframes
From "Blender Encyclopedia — Noise Animation Modifier". Their exact settings:

```
F-Curve > Modifiers > Noise
   Blend Mode  Replace
   Scale       6.500      (how fast it wobbles)
   Strength   10.800      (how far it moves)
   Phase       1.000      (offset the pattern - use a different value per object)
   Depth       0          (roughness / added octaves)
   Offset      0.000
   Restrict Frame Range   Start 50.0  End 200.0  Blend In 69.4  Out 116.9
```

**This is the single most useful animation tool for us**, because it needs no animation skill
and it scripts completely:

```python
fc = obj.animation_data.action.fcurves.new('rotation_euler', index=0)
m  = fc.modifiers.new('NOISE')
m.scale, m.strength, m.phase, m.depth = 6.5, 0.08, seed, 0
```

Use it for **cow head bob · tail swish · ear flick · weight shift · breathing · branches
drifting · a standing person fidgeting · handheld camera wobble**. Give every instance a
different `phase` and nothing moves in sync — which is exactly what breaks the CG look.

CG Boost's "CameraWobble" with Influence 0.200 (section 2.4) is almost certainly this.

### 28.3 The practical plan for our cow
1. Get an animated cow from Sketchfab if the baked animation is good enough (one exists, "Cow
   Idle", 56k faces, CC-BY), **or**
2. Rigify quadruped metarig on a static cow mesh, then:
   - **Path/trajectory from MATLAB** drives the body position (section 19 method)
   - **Noise modifiers** on head, neck and tail bones give the idle life
   - A simple 4-step walk cycle looped, speed matched to travel speed or the feet slide

**Feet sliding is the classic failure.** Walk cycle distance per cycle must equal the distance
actually travelled per cycle.

## 29 · DETAIL WITHOUT SCULPT MODE — what a script can actually do

Sculpt mode is interactive and I cannot use it. Everything below produces hand-crafted-looking
detail from code, which is the workaround.

| Want | Scriptable method |
|---|---|
| **Potholes, ruts, dips** | `Displace` modifier + a texture, masked by a **vertex group** — exactly how our road band was flattened. Paint or compute the group from position. |
| **Cracks, chips in a kerb** | Boolean difference with small randomly-rotated cubes/spheres |
| **Worn, rounded edges** | `Bevel` modifier, or the `Bevel` **shader node** for a fake rounded highlight with no geometry cost |
| **Crumbling road edge** | Per-vertex random-walk offset (built already — random walk beats a sine wave, which reads as a sawtooth) |
| **A leaning post, a bent sign** | Simple rotation and a `SimpleDeform` bend modifier |
| **Surface micro-detail** | **Displacement map in the material** with `Displacement = Bump Only`, or true displacement with **Experimental feature set + adaptive subdivision** (dicing 1.0 px) |
| **Two-material wear** | The universal mask pattern — section 10 |
| **Dirt in crevices** | `ShaderNodeAmbientOcclusion` as a mask feeding a dirt colour |
| **Damage that follows the object** | `Geometry Proximity` to another object -> `Map Range` -> displacement or scale |

**The honest limit:** all of the above is *rule-based*. I can say "put bites in the edge at
random", not "put a specific bite exactly there because it looks right". Genuinely art-directed,
one-off detail still needs a human at the mouse. **Aditya being the eyes is the substitute** —
he says where it looks wrong and I change the rule.

## 30 · REVISED SELF-ASSESSMENT
Closed by this research: animal animation, organic idle motion, detail-without-sculpting.
**Still genuinely weak:** art-directed one-off detail, and judging "does this look real" —
which is why every render gets compared side by side against Aditya's own footage rather than
judged on its own.

---

# PART SIX — REAL SPECIFICATIONS
Sourced from IRC (Indian Roads Congress) standards and Indian electricity practice, 2 Sep 2026.
**Everything I built before this was guessed. This section replaces the guesses.**

## 31 · ROAD GEOMETRY — IRC

| | |
|---|---|
| **Lane width** | **3.5 m** standard · 3.75 m expressway · 3.0 m minimum on access roads |
| **Two-lane carriageway** | **7.0 m** |
| **Median width** | 1.2 m minimum, 1.2–5 m typical by road class |
| **Median kerb height** | **150 mm MAXIMUM** |
| **Speed breaker (IRC-99)** | **3.7 m wide · 0.10 m high · 17 m radius rounded hump** · advisory 25 km/h · **minimum 300 m apart** |

**WHAT I BUILT WAS WRONG:** road **5.6 m** (that is 1.6 lanes — should be 7.0 m for two lanes,
or ~3.5–5 m for a genuine single-lane village road). Median **280 mm** high — nearly double the
legal maximum of 150 mm.

## 32 · ROAD MARKINGS — IRC 35:2015

| | |
|---|---|
| **Centre line width** | **100–150 mm** |
| **Single carriageway centre line** | **3 m line / 6 m gap** (50/50 on high-speed roads) |
| **Lane line, divided road** | **3 m line / 4.5 m gap** |
| **Lane line width** | 100 mm, segment 1.5 m |
| **4-lane undivided centre** | solid 150 mm |
| **6-lane undivided centre** | double solid 150 mm, separated by 100 mm |
| **No-overtaking zone** | continuous **yellow** (double yellow on undivided two-way) |

**I had NO markings at all in the last build.** Aditya's own rural frames show **solid white
edge lines both sides and no centre line** — that is a real and specific pattern, and it must be
built to these widths.

## 33 · ELECTRICITY POLES — Indian practice

| | |
|---|---|
| **Type** | **PCC (pre-cast concrete), RECTANGULAR cross-section**, not square, not round |
| **Height** | **11 m** for 11 kV HT lines |
| **Span between poles** | **40 m** typical (40–50 m) |
| Earthing | continuous earth wire, bonded at 3 points per km |

**WHAT I BUILT WAS WRONG:** poles **8.2 m** tall at **13 m** spacing. Real ones are **11 m tall,
40 m apart** — so mine were too short and **three times too close together**, which is why they
read as a fence rather than a power line.

## 34 · TREES — I chose the wrong species entirely

**Aditya is right: the banyan is NOT a common Indian roadside tree.** I built the whole scene
around it because it was the only good photoscanned asset I could find. That is choosing by
availability rather than by truth, and it is backwards.

**What actually lines Indian roads:**

| Species | Character | Where |
|---|---|---|
| **Neem** (*Azadirachta indica*) | **feathery pinnate compound leaves**, dense, medium canopy | **the most widely planted roadside tree in India** |
| **Gulmohar** (*Delonix regia*) | fine fern-like leaves, umbrella canopy, blazing red-orange flowers May–June | *"on nearly every national highway median in peninsular India"* |
| **Amaltas / Golden Shower** (*Cassia fistula*) | cascading yellow flower chains, April–June | *"a defining feature of Indian highway dividers"* |
| **Peepal** (*Ficus religiosa*) | heart-shaped leaf with a long **drip tip**, spreading | common, often at junctions and temples |
| **Rain Tree** | very wide umbrella canopy | highways, wide roads |
| **Ashoka, Silver Oak** | tall, narrow, straight | **city streets where space is tight** |
| Jamun, Arjun, Karanj | | mixed avenue planting |
| Banyan | huge, aerial roots | temples, village centres, old trunk roads — **not the default** |

**Consequences for the build:**
- The hero roadside tree should be **neem** — feathery compound leaves, not the big glossy
  ficus leaf we have.
- **Gulmohar and Amaltas belong on the median**, not the verge.
- **City roads get narrow trees** (Ashoka), highways get wide canopies (Rain Tree, Gulmohar).
- Our ficus is still usable — as the **occasional big tree at a junction or shrine**, which is
  exactly where a real one would be. **One of them, not eight.**

## 35 · HOW TO THINK ABOUT IT — Aditya's method, and he is right

> "First think, build, go back, think, see, build. Don't keep just building, building, building."

**What went wrong before:** I built continuously and only checked at the end, so errors
compounded — a 5.6 m road, 280 mm median, poles at 13 m, and the wrong tree species, all baked
in before anyone looked.

**The method from now on:**
1. **Establish the real dimension first** (this section) — never invent a number
2. Build ONE element to it
3. **Look at it** — EEVEE, seconds not minutes
4. Compare against a real frame from his footage
5. Only then move to the next element

## 36 · STILL NOT RESEARCHED — be honest about it
- **Warning and traffic sign geometry** (IRC 67) — sizes, heights, mounting
- **How wires actually attach and wrap at the pole** — insulator arrangement, jumpers, stays
- **Telecom lattice tower** geometry and spacing
- **Bird flight** — flocking, wing cycles
- **Forest structure** — how canopies interlock to read as continuous woodland, layering,
  understory density, why gaps occur and what occupies them
- **Speed breaker markings** — the painted stripes on the hump

---

# PART SEVEN — THE PIPELINE (authoritative)
Set by Aditya, 2 Sep 2026. **This supersedes every earlier ordering in this document.**

## THE TWO RULES THAT GOVERN EVERYTHING

**RULE 1 — Nothing is built until it is written.**
Every scenario gets a complete written Environment Script first. Every count, every position,
every gap and the reason for it. Birds and how many. Insects. Leaves and where they collected.
**The build is execution, never invention.**

**RULE 2 — A stage is finished when it matches its specification exactly.**
Not "good enough, I'll fix it in the next stage." That habit is what produced a 5.6 m road,
a 280 mm median, poles at 13 m and the wrong tree species, all discovered at the end.
**No stage begins until the one before it is signed off by Aditya.**

## THE THREE OUTPUTS — keep these distinct or the project looks dishonest

| | What it is | What it is for |
|---|---|---|
| **The numbers** | Hundreds of MATLAB runs, varied conditions, measured | **The proof.** This is what wins |
| **MATLAB's own view** | Boxes on a plot | Honest, plain, re-runnable by a judge |
| **The Blender film** | ONE of those runs, rendered photoreal | So a human can see it |

**The film is presentation, not evidence.** It is not a screen recording — it is a render of the
identical run, driven by the same position data. If asked "is that the real simulation?", the
answer is: **the plain one is the truth, the beautiful one is the same truth rendered.**

Testing = running the simulation many times and measuring. The video shows one run.

## THE STAGES

**0 · REFERENCE**
Frames from Aditya's own 13 clips. Real dimensions from IRC (Part Six). Study how trees
actually line up left and right — spacing, where gaps fall, what occupies them.

**1 · THE ENVIRONMENT SCRIPT** — written, approved, before any object exists
One per scenario, five scenarios, five scripts. Contents:
- **The place** — region, road class, time of day, season, weather
- **The road** — width, surface condition, markings, speed breakers, potholes, camber
- **Left side, metre by metre** — an inventory with distances
- **Right side, metre by metre** — the same, and it must NOT mirror the left
- **Buildings** — how many, how many storeys, what type, spacing, roof, water tanks
- **Shops** — how many, what kind, awnings, shutters, signage, what is outside them
- **Vegetation** — species by name, count, spacing, canopy width, **and every gap with its reason**
- **People** — how many, exactly where, what each is doing, standing or moving
- **Density map** — where it is crowded, where it is empty. **Never uniform**
- **Vehicles** — how many, what type, parked or moving, where
- **Animals** — cows, dogs, birds and **how many**, insects
- **Ground detail** — litter, bricks, leaves and where they collected, puddles
- **Sky** — cloud type and cover, sun angle, haze density
- **The action** — what happens in the shot, second by second
**Gate: Aditya reads it and approves. Every number becomes a build instruction.**

**2 · BLOCKOUT** — grey shapes to the script's dimensions. Gate: does the shape read?
**3 · ROAD** — width, camber, crumbling edge, markings, speed breaker, potholes
**4 · ASSETS** — each in its own .blend, built and judged ALONE before use
**5 · VEGETATION** — layers scattered to the script's counts, gaps where the script says
**6 · SURROUNDINGS** — distant treelines, fields, horizon. *The world must not stop at the verge*
**7 · TEXTURE** — two materials mixed by a mask on every surface, roughness always varying
**8 · BLENDING** — ground into every base, contact shadows, shared dust, nothing repeating
**9 · LIGHT AND AIR** — sky at 0.25 strength, sun, bounded volumetric haze
**10 · LOOK DEV** — EEVEE, seconds per look, **side by side against a real frame.** Aditya judges
**11 · MATLAB** — the simulation runs. Trajectories out, frame by frame
**12 · ANIMATION** — Rigacar for vehicles (path -> wheels, steering, roll).
     F-curve Noise modifiers for cow head bob, tail, breathing, branch drift
**13 · RENDER** — Cycles, headless from the terminal, noise threshold not sample count.
     Image sequence, never straight to video
**14 · GRADE** — DaVinci Resolve. Match his footage: contrast, colour, haze, grain,
     lens distortion, compression. **Match the camera's flaws, do not fight them**
**15 · OUTPUT** — the film, and the table of numbers from hundreds of runs

## WORKING METHOD — settled by what went wrong
- **Headless from the terminal.** Blender's GUI cost 228 MB before loading anything; the same
  scene rendered from the command line peaked at 1.25 GB instead of dying
- **SAVE AFTER EVERY STEP.** A scene was lost once with no save
- **EEVEE to look, Cycles to finish.** 5 s versus 90 s
- **Do the arithmetic before scaling anything.** 220k leaves x 7 trees = 51 M faces killed it
- Aditya does manual work and judges by looking. He does not read documents.

---

# PART EIGHT — THE MEASUREMENT BOOK
Researched 2 Sep 2026 from standards, building codes and peer-reviewed papers.
**Every number here is sourced. Nothing is invented. Use these instead of guessing.**

## 37 · THE DASHCAM — and a correction that affects every frame

**Thinkware F800: 140-degree field of view**, Sony Exmor R STARVIS sensor, 1080p30.

**Our renders have been at 24 mm. That is far too narrow.**
140 deg diagonal on a full-frame equivalent works out at roughly **8 mm**; even read as
horizontal it is about **13 mm**. A dashcam sees vastly more than a 24 mm lens.

**Use 12-14 mm equivalent plus barrel distortion in the compositor**, then check against a real
frame. A too-narrow lens is why our renders feel "zoomed in" compared to his footage — the
perspective is wrong before anything else is considered.

## 38 · HAZE — set it by physics, not by eye

**Koschmieder:  α = 3.92 / V**
where α is the extinction coefficient per metre and V is meteorological visibility in metres.

**Blender's Principled Volume `Density` IS that extinction coefficient**, in per-metre units.
So visibility converts straight into a density value:

| Visibility | Density | Looks like |
|---|---|---|
| 3000 m | 0.0013 | clear, slight distance fade |
| 1500 m | 0.0026 | light haze |
| 1000 m | 0.0039 | **typical Indian daylight haze** |
| 500 m | 0.0078 | heavy haze |
| 300 m | 0.0131 | **the morning-fog clip, drive_02** |
| 150 m | 0.0261 | thick fog |

Meteorological definition: **fog is visibility under 1 km; over 1 km is haze.**
Estimate visibility off one of his frames, divide 3.92 by it, and that is the number. Done.

## 39 · VEHICLES — real dimensions (L x W x H, mm)

| | Length | Width | Height | Wheelbase |
|---|---|---|---|---|
| **Bajaj RE auto-rickshaw** | **2635** | **1300** | **1700** | 2000 |
| **Tata Ace** | **3800** | **1500** | **1850** | 2100 |

These set the spacing. His footage shows gaps of about **one metre** between vehicles — that
figure only means anything if the vehicles themselves are the right size.

## 40 · CATTLE — zebu, which is what an Indian road cow is

| | |
|---|---|
| **Height at withers** | 110-140 cm (bulls 135-150, cows 120-135) |
| **Standing height incl. hump** | 124-158 cm |
| **Body length** | 180-226 cm |
| **Body width** | 57-71 cm |
| **Hump** | 10-20 cm above the shoulder line |
| **Horns** | 15-46 cm |
| **Weight** | cows 300-600 kg |

**Not a Holstein.** The hump and dewlap are the silhouette.

### Gait — peer-reviewed, and this is what stops the feet sliding
| | |
|---|---|
| **Walking speed** | **1.2 ± 0.05 m/s** (free-walking range 0.52-1.37 m/s) |
| **Stride length** | **1.68 ± 0.1 m** |
| **Stride rate** | **43 per minute** |
| Gait | symmetrical walk, head bob increases with speed |

**Check: 1.68 m x 43/min = 72 m/min = 1.20 m/s.** Consistent. Match the animation to this or
the hooves slide.

## 41 · HUMANS — gait

| | |
|---|---|
| **Comfortable speed** | **1.2-1.4 m/s** |
| **Step length** | **~0.70 m** (stride 1.44 m) |
| **Cadence** | 90-120 steps/min, average ~102 |

Same rule: stride length x cadence must equal travel speed, or they moonwalk.

## 42 · SHOPS — Indian standards, and nothing exists to download so these matter

**Rolling shutter (IS 6248:1979)**
- Laths **75 mm wide**, 0.8-1.2 mm steel
- Commercial shutters **2.4-3.7 m wide** (8-12 ft), **up to 3.0 m high** (10 ft)

**Awning / canopy (building bye-laws)**
- Maximum **4.50 m long x 2.40 m projection**
- **Minimum clear height beneath: 2.20 m** — no projection may sit lower
- Commercial cantilever projection typically up to **0.9 m** (3 ft)

**Structure**
- Beam soffit minimum **2.4 m**, slab soffit maximum **2.7 m**

So a typical roadside shop: **3 m wide shutter, 3 m tall opening, awning projecting 0.9-2.4 m
at 2.2-2.4 m above the ground.** Build the kit to these.

## 43 · BUILDINGS — National Building Code of India

| | |
|---|---|
| **Floor to floor** | **3.0-3.15 m** including slab |
| **Minimum clear ceiling** | 2.75 m (IS 875 Part 2) |
| **Parapet** | minimum **1.0 m**, 1.2 m+ on tall buildings |
| **Window sill** | **0.9 m** above finished floor |
| **Window area** | at least 10% of floor area (NBC 2016) |

So a **two-storey shop-house is about 6.3 m to the roof slab, plus a 1 m parapet = 7.3 m**,
plus a water tank on top. A three-storey is ~10.4 m.

## 44 · STILL NOT MEASURED — the honest remainder
- Junction corner radii and how markings terminate at a crossing (IRC 65 / IRC 35)
- Traffic sign sizes and mounting heights (IRC 67)
- Milestone and guard-stone dimensions
- Crowd density figures — people per square metre in an Indian market
- Crop row spacing and plant heights by crop
- **How distant canopies interlock to read as continuous woodland** — still unanswered
- Bird flight and flocking

---

# PART NINE — SKY, LIGHT AND THE MATHS

## 45 · WHY THE SKY IS THE COLOUR IT IS — and which knob does it

Blender's Nishita sky is **physically simulated**, so you do not paint colours, you set
atmosphere. Three parameters, each doing one physical job:

| Parameter | Physics | What it does | 1.0 means |
|---|---|---|---|
| **Air** | **Rayleigh** scattering off molecules, ∝ 1/λ⁴ | makes the sky **blue** | urban city air |
| **Aerosols** (was "Dust") | **Mie** scattering off particles | **darkens and hazes the lower sky**, oranges the horizon | urban aerosols |
| **Ozone** | Chappuis absorption band | **deepens and saturates the blue**; drives the **blue-purple of twilight** | urban ozone |

**The physics, briefly:** short wavelengths scatter far more (1/λ⁴), so a clear day is blue.
At sunset the light travels through far more atmosphere, blue and violet are scattered away
entirely, and only orange and red survive the trip — that is why low sun is warm. Particles
larger than a wavelength scatter **all** colours equally, which is why dust and cloud are
**white or grey**, not blue.

### Recipes — sun elevation is the master control
| Look | Sun elev | Air | Aerosols | Ozone |
|---|---|---|---|---|
| **Deep blue midday** | 60-80° | 1.0-1.5 | 0.3-0.8 | **4-8** (high ozone = saturated blue) |
| **Indian hazy daylight** | 40-60° | 1.5-2.0 | **3-6** | 2-3 |
| **Grey overcast** | any | 1.0 | **8-10** | 0-1 (aerosols flatten everything) |
| **Golden hour** | **5-12°** | 1.0-1.5 | 2-4 | 1-3 |
| **Orange/red sunset** | **0-4°** | 1.0-2.0 | **4-8** | 1-2 |
| **Pink-purple twilight** | **-2 to -6°** | 1.0-1.5 | 1-2 | **6-10** (ozone makes the purple) |
| **Night** | below -10° | — | — | — |

**Background Strength stays at 0.25** regardless (Part Three, section 17).

**Nishita produces NO STARS.** For night you need a starfield HDRI, or a procedural one
(Noise/Voronoi through a sharp ColorRamp into Emission). Plan for that rather than expecting
the sky node to provide it.

Note: newer Blender renamed Nishita to **"Single Scattering"** and Dust to **"Aerosols"**.
4.5.11 still calls them Nishita and Dust.

## 46 · CATENARY — my wires were wrong

A hanging cable is **y = a·cosh(x/a)**, where a = horizontal tension / weight per length.
I used a **sine** curve, which is neither.

**The practical form:** the parabolic approximation **y = x²/(2a)** is accurate to **0.5% for
any sag-to-span ratio under 1:8** — which covers every power line we will ever build. So:

```python
# span L, sag s at midpoint, parametrised t in 0..1
z = h - 4.0*s*t*(1.0-t)        # parabola: exact enough, and simpler than cosh
```
Real distribution spans are **40 m** (Part Six) with sag of roughly **0.3-0.6 m**, i.e. a
sag:span near 1:80 — comfortably inside the approximation.

Where supports differ in height the curve is asymmetric and the lowest point shifts toward the
lower support. Worth knowing for a ghat road.

## 47 · ROAD CURVES — IRC 38, needed for the ghat and any bend

**Minimum radius:  R_min = V² / [127 × (e + f)]**
 V in km/h · e = superelevation as a decimal · **f = 0.15** (lateral friction)

**Maximum superelevation: 7% on plain terrain, 10% in hills.**

**Transition curve: IRC specifies Euler's spiral (clothoid)** — radius decreases at a uniform
rate so centrifugal acceleration builds uniformly. That is what makes a real road feel smooth
and a naively-modelled one feel wrong.
**L_min = V³ / (C·R)**, C = allowable jerk.
Superelevation rises **linearly from zero at the start of the transition to full at its end.**

**Worked example, 40 km/h hill road, e = 10%:**
R_min = 1600 / (127 × 0.25) = **50 m**. So a ghat hairpin tighter than ~50 m radius is below
standard — useful when building the ghat scenario, and a real fact to state in the report.

## 48 · THE MATHS THAT ACTUALLY MATTERS HERE — summary
1. **Lens:** FOV and focal length. 140° ≈ 8 mm equivalent. We were at 24 mm. Section 37.
2. **Haze:** α = 3.92/V. Physical, not by eye. Section 38.
3. **Catenary:** parabola, not sine. Section 46.
4. **Road curves:** R_min and the clothoid transition. Section 47.
5. **Gait:** stride × cadence must equal travel speed, or feet slide. Sections 40-41.
6. **Sky:** three scattering parameters, not painted colours. Section 45.

**Everything else is arithmetic. These six are the ones that were silently wrong.**

---

# PART TEN — THE LAST THREE GAPS, CLOSED

## 49 · HOW CANOPIES INTERLOCK — Aditya's question, answered

From arboriculture research on street trees:

> **Street trees begin having crown interactions at 10-15 m spacing.**
> **Below 10 m, crowns elongate** — they grow *away from* the direction of interaction.

**The rule for building:**

| Spacing | What it reads as |
|---|---|
| **8-12 m** | **crowns touch and merge — a continuous green tunnel** |
| 12-15 m | crowns just meeting, an avenue |
| **over 15 m** | **separate trees standing apart.** This is what ours looked like |

**And the shape rule that makes it convincing:** a tree with neighbours on both sides grows
**elongated along the row and narrower across it.** An isolated tree is round. So when placing
an avenue, do not use the same canopy shape for every tree — stretch the ones with close
neighbours along the road axis, and leave the isolated ones round.

**Crown cover can be 100% while crown closure is under 100%** — overlapping parasol crowns give
complete cover from above while light still enters at oblique angles. **That is exactly the
dappled light on the road in his reference image.**

Ours were at 12-15 m in a straight line with identical canopies. **Move to 8-12 m, elongate the
crowded ones, and leave real gaps where the script says there is a reason for one.**

## 50 · JUNCTION GEOMETRY — IRC SP-41 and IRC 35

| | |
|---|---|
| **Corner / island control radius** | **12-15 m** — this is the number that shapes a junction |
| **Central median gap at a junction** | extends **at least 3 m beyond** the extended kerb line of the minor road |
| **Stop line** | **double line, each 200 mm wide, 300 mm apart** |
| Stop line position | 1 m before the nearest signal; equidistant from the junction centre on each arm |
| **Direction arrows** | first at **15 m** from the stop line, then every **15 m** back |

So a four-way junction is not two roads crossing at right angles with sharp corners — the
corners are **12-15 m radius curves**, and the median stops short and reopens 3 m past the
side road. Get those two things and the junction reads correctly.

## 51 · CROWD DENSITY — Fruin levels of service

The international standard, in square metres **per person**:

| m² per person | persons per m² | Reads as |
|---|---|---|
| 12.1 | 0.08 | empty, free flow |
| 6.0 | 0.17 | comfortable |
| 3.7 | 0.27 | busy |
| **2.2** | **0.45** | **crowded — a busy market pavement** |
| — | **4-5** | dangerous crush |
| — | 5-7 | lethal |

**For the junction scene:** the busy pavement outside the shops should be around
**0.4-0.6 people per m²**; a quiet stretch of verge more like **0.05-0.1**. Anything above
1 per m² is a crush, not a street.

**Use these to write the density map in the Environment Script** rather than guessing "busy".

## 52 · RESEARCH STATUS — closed
Junction geometry, canopy interlocking and crowd density are done. What remains
(sign sizes, milestones, crop spacing, bird flight) are **five-minute lookups at point of use**,
not research projects.

**Research has hit diminishing returns. The limit now is that none of this has been applied
end to end, and that the assets do not exist yet.**
