# REF-11 · GROUND COVER, SCATTER, AND THE WHOLE-SCENE ASSEMBLY
**Batch 5 of Aditya's video study — the last batch.** 6 videos, 1 h 07 m. Two had no captions and
were read frame by frame. Method only.

## 1 · BUILDING A PLANT FROM A REAL PHOTOGRAPH — the answer to "build it from the image"
**Source: CG Geek, confirmed by Ezekiel Vincent.** Both independently do the same thing, and this is
the method for **kans grass**, which is the hero plant in Aditya's footage and which no asset library
sells.

1. **Go outside and shoot the real plant against a blank sheet of paper, in the shade.** Shoot a
   variety — *"the more grass you forage for, the more variation you can get."*
2. Load the photo as a reference in Blender.
3. Add a plane at the base of the blade → edit mode → **grab the top two vertices and extrude along
   the blade** (**`Ctrl`+right-click** continues extruding), scaling to follow the shape, tapering to
   a point at the tip.
4. **`U > Project From View`** to unwrap, then rotate and scale the UVs onto the photographed blade.
5. New material, image texture → Base Color.
6. **`Ctrl+R` a loop down the length and pull it down slightly** — curvature. A flat blade reads dead.
7. Repeat for the stalk; **duplicate blades onto it and `Ctrl+J`** into one plant.
8. **Proportional editing (try Sharp) to bend and twist** — *"twisting it made it look nice."*
   Edit in **both** views or it is only convincing from one angle.
9. **`Alt`+right-click an edge loop, `Ctrl+B`** to round off the stalk.
10. **Dead blades at the base:** duplicate a few, hover and press **`L`**, give them their own material
    slot, and drop a **Hue/Saturation node with hue, saturation AND value all reduced.**
11. **Origin at the base of the plant**, blade facing up — *"particles spawn from the origin, so having
    it at the root means it won't clip through the surface."*
12. **Make several variations of the finished plant.**

**This is exactly the workflow for kans grass (2.2–3.0 m, feathery white plumes, REF-04 §8) and for
the neem frond alpha card (REF-10 §0).** Aditya can shoot both locally.

**Faster tuft, for background grass:** model one blade → **Array modifier, then a SECOND Array on top**
→ apply both → edit mode → **`F3` "Separate by Loose Parts"** → **`F3` "Randomize Transform"** →
**`Ctrl+J`** back into one object. A tuft that does not read as an array.

## 2 · THE LAYERED GROUND — arrived at independently, and it matches REF-04
> *"Grass grows in layers. Look at this — it's complicated, it's natural, and it can be broken down
> into layers."*
His five: **ground texture · dead grass · sprouting grass · short grass · medium grass · tall grass.**
**REF-04 §8 specifies seven for us** (kans 2.2–3.0 m · sugarcane 2.25 m · shrub 0.8–1.4 m · mid
grasses 0.30–0.60 m · doob 0.05–0.15 m · weeds · floor litter). **He confirms the principle from a
different direction, and supplies the mechanism:**
- **EACH LAYER GETS ITS OWN PARTICLE SYSTEM / SCATTER**, so density and scale are controlled per layer.
- The ground texture underneath *"won't really be viewable, so all you need is a texture with a little
  colour variation."* **Do not spend budget on the layer nothing sees.**
- **Bake each layer as you finish it**, or turn the viewport count down — *"things get pretty heavy
  for your computer quite quickly."*

## 3 · THE GRASS MATERIAL — root-to-tip, and the one that matters at 10° sun
- **`Texture Coordinate → Separate XYZ → ColorRamp`** → base colour. **Lighter at the tip, darker at
  the root.** Cheapest realism available.
- **Roughness UP, Specular DOWN** — grass should not reflect much.
- *"My secret ingredient is to actually lower the alpha value — it gives the grass a little more
  softness."*
- **`Add Shader` + `Translucent BSDF`** — *"this lets some light pass through the grass like it would
  in real life."* **This is not optional for us: S0 puts the sun at 10° elevation, so half our grass
  is backlit.** Translucency is the entire look of low-sun grass.

## 4 · WIND — the simple way, and the way that actually works
**Simple (fine for background):** a **Wind force field** (strength = how far it leans) plus a
**Turbulence field** (strength, and **Size** controls the texture scale → wind waves). Keyframe the
turbulence start and end, then **right-click the keys → Linear interpolation** so there is no ease.
**Turn gravity/wind down in Field Weights for the ground layers** — *"the ground layer wouldn't really
move like that in real life."*

**His own verdict on it:** *"it looks a little bit like wind but it's kind of just spinning a lot."*

**The method that bends properly — grass instanced on a cloth-simulated hair system:**
1. Grass object → **Particle Instance modifier**, Object = the ground plane.
2. The ground plane gets a **hair particle system**, low count, short hair.
3. **Enable Hair Dynamics** — *"it allows the hair particles to almost act like a cloth simulation."*
4. **Enable "Create Along Paths"** in the Particle Instance modifier; its sliders randomise rotation.
5. **BAKE the simulation** in Cache before adding more layers.
**Gotchas he hit, in order:** `Ctrl+A` apply scale and rotation · `Alt+G` clear location · rotate the
grass in edit mode if it comes out sideways · move the tuft onto its origin or it floats off the plane.

**A silent render bug worth knowing: the particle PATHS render as visible lines.**
**Fix: particle system > Render > Path → None.**

## 5 · CLUMPING — how scatter stops looking sprayed
**Source: Covingsworth.** In the geometry-nodes scatter, **feed a Noise Texture into DENSITY and into
SCALE** (through a Math node for height).
> *"The noise texture allows you to form these really organic and realistic clumps of plants, just
> like in real life."*
**That is the mechanism for S1's "clustered, never uniform" and for REF-04 §6's rule that a real
street is crowded and empty at the same time.**
Then **duplicate the whole node group per species, change the instance collection, and CHANGE THE
SEED** so no two species share a distribution.
Confirmed from a second package: the Maya artist sets his distribution ID to **random, not linear,
"so the distribution isn't so perfect"**, and adds a random node for position, rotation and scale.
**Two different applications, same architecture as ours.**

## 6 · A ROAD AS A MATERIAL, NOT AS GEOMETRY — and this complements Batch 1
**Source: The Adam (29 min, no captions — read frame by frame).** He lays a stone path across a
grassy hillside **without cutting any geometry**: a **black-and-white mask ribbon** drives a mix
between the ground material and the stone material.

**This is the cheap counterpart to Xoio's geometry cut (REF-07 §1), and for parts of our map it is the
better answer:**
- **Cut geometry** where the road is engineered and the section matters — the trunk roads, the hill
  road with its cut face and drop, the flyover approaches.
- **Material mask** where the surface is just worn earth — **the kaccha rasta, the field tracks, the
  service roads, and the ragged 100–300 mm band where S1's tarmac crumbles into dirt.**
The mask edge blends naturally, which is exactly what a crumbling edge needs and what a hard geometry
cut cannot give.
**Our mask comes free from `matlab_roads.csv`** — the same source as everything else (REF-08 §4).

## 7 · SKY — the combination worth stealing
**Source: Covingsworth.** *"The sky carries much more realism than you'd expect."*
**Use a Sky Texture for the LIGHT and an HDRI for what the camera SEES:**
```
Background(Sky Texture) ─┐
                         ├─ Mix Shader ─► World Output
Background(HDRI)      ───┘        Factor ◄── Light Path > Is Camera Ray
```
*"You've retained the lighting of the sky texture, but it's also now using the HDRI as a back plate."*
**Relevant to us:** S0 fixes the sun physically (Nishita, Air 1.5 / Aerosols 4.0 / Ozone 2.0) but
Nishita gives no clouds, and S0 asks for 25 % thin stratus. **This is how we keep the physical light
and still get a real sky** — and it pairs with the cloud-shadow plane (REF-07 §6) and the
extruded cloud planes through a Subsurface Scattering node (REF-09 §12b).

## 8 · ATMOSPHERE IS THE SECRET SAUCE — a fourth independent confirmation
He renders a fully-built mountain scene and says:
> *"This is the exact moment where past me would have been confused and dismayed at why it just looks
> terrible. Why does it look so bad? It's missing atmosphere. Proper atmosphere is that secret sauce,
> and we want it to behave just like in real life."*
Our haze is already set by physics — **Koschmieder, α = 3.92 / visibility, so 800 m → 0.0049**
(BLENDER-PIPELINE §38, S0 §2). **The lesson is about ORDER: a scene that looks bad before atmosphere
is not necessarily broken.** Do not rebuild geometry to fix what is actually a missing volume.

## 9 · DISTANT VEGETATION EXISTS FOR TWO REASONS, NOT ONE
> *"Our objective is just to cover this mountain completely in foliage, not only to break up the CG
> look of the terrain but also **so that light reacts correctly to it.**"*
**The second reason is the one we would have missed.** Scattered foliage changes the bounce light on
the whole hillside. It is not only silhouette. Directly relevant to S5's sal forest and to S0's
Level-3 "real but plain" zones — **they still have to be there, even if nothing looks at them.**
**`Alt+D` for a linked duplicate, never `Shift+D`** — third source in this study saying so.

## 10 · THE CHEAP LAWN — for what the camera never approaches
**Source: 45-second short.** Image-as-plane → **50 subdivisions** → proportional editing for
topography → hair particle system, Advanced on, **~880,000 particles, hair length 0.04**, then
**Physics: raise Brownian and Damp slightly.** No modelled blade at all.
**Use for the far fields and the Level-3 verge.** Not for anything within 20 m of the camera.

## 11 · HONEST LIMITS OF THIS BATCH
- **All of it is temperate grass.** Wet green lawns, British fields, alpine mountains.
  **Nothing here is kans grass, sugarcane, doob, paddy stubble or a dusty Indian verge.**
  Species, heights and the farming calendar stay sourced in REF-04 §8–9 and in Aditya's own footage.
- **Ezekiel Vincent contradicts himself, honestly, and the second answer is the right one:** he
  demonstrates particle **Children (Interpolated)** for density, then says *"I'm actually going to go
  back on myself here and say avoid using children — as nice as it is, it can also make really
  repetitive patterns that become quite noticeable."* **Do not use children. Use more instances.**
- **Two of the six are essentially product promos**, and one is Maya. Architecture only.
- **Nothing measured in metres anywhere in this batch.**
- The photogrammetry workflow in The Adam's video is real but **not available to us** — we have no
  scans, and building one is out of scope before 7 September.

## 12 · SOURCES
Ezekiel Vincent *Grass in Blender* · CG Geek *The Best Way To Create Nature In 3D* ·
Covingsworth *Creating an Epic Kingdom* · The Adam *Realistic Environment With Blender 3D*
(no captions — read frame by frame) · Blender Tips *Grass in 45 seconds* ·
Summer Day Studios *3D Grass Fields* (Maya; method mapped to geometry nodes).
