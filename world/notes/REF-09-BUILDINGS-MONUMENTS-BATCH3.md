# REF-09 · BUILDINGS, MONUMENTS, MATERIALS AND THE RENDER BUDGET
**Batch 3 of Aditya's video study.** 5 videos, 3 h 51 m, ~42,000 words of transcript read.
Method only. The two most valuable things in this batch are the **AO double-stack** (§5) and the
**Simplify + split-sky render workflow** (§9).

## 1 · THE THOUSAND BUILDINGS — the mechanism REF-03 was missing
REF-03 said "model ~30 facade parts and scatter them on plain boxes" but never said *how*.
**Source: Enhanced Sight, building generator.** The mechanism is:
> *"Depending on the VERTEX GROUP, different modules for walls and windows are used. To adjust the
> modules you adjust the vertex groups… whether you assign it manually or randomly is up to you."*
**A plain box, vertex groups on its faces, and a module chosen per group — manually where it matters,
randomly everywhere else.** That is the whole facade system, and it is scriptable.
- **Storeys are added by selecting the top faces and extruding by 3 m** (`E`, then **`Shift+R` repeats
  the last action**). Matches NBC floor-to-floor 3.0–3.15 m exactly.
- **Bevel modifier on kerbs and edges so they are not razor sharp** — and **disabled in the viewport**,
  enabled only at render. Sharp edges are one of the loudest CG tells.

## 2 · MAKING AN ASSET — his checklist, stated twice, word for word
`Object > Convert to Mesh` (this applies the modifiers) → **Join** → **Apply Scale** →
**Origin to Geometry** → **unwrap with a quick Cube Project** → save to the asset browser.
**Set the origin to the BOTTOM of the object**, so it scales from the ground up.
(Turn on *Options > Origins* in object mode to move an origin.)

## 3 · MODELLING INTRICATE ARCHITECTURE — the temple, the shikhara, the plinth
**Source: Max Hay, Modeling Temple Assets (1 h 49 m). He searched "ancient Indian temple" for his
own reference.** The entire method is simpler than it looks:
- **Cube → `I` inset → `E` extrude → repeat.** Stacked inset/extrude is what makes every layered,
  stepped, corniced profile. That IS a latina shikhara, a plinth and a cornice.
- **`S Shift Z`** scales on everything *except* Z (i.e. X and Y together) — the single most useful key
  for architectural profiles. Same for `S Shift X`, `S Shift Y`.
- **`Ctrl+B` bevel, scroll to ONE segment**, then `E` + `S Shift Z` inward, to separate stacked bands.
- **Bevel modifier over the whole object** at the end.
- His own note: *"a lot of these ancient things aren't perfectly lined up anyway, so it doesn't really
  matter if I'm spot on."* **Imprecision is authentic in old architecture. Do not build it plumb.**

**Circular and radial architecture — dome, kalash, pillar, roundabout kerb (St Paul's video):**
- Draw the profile → move the **3D cursor to the circle's origin** → set pivot to 3D cursor →
  **Spin tool**, with a set step count for uniform topology.
- **Radial array the correct way: add an EMPTY at the centre, and in the Array modifier switch
  Relative Offset → OBJECT OFFSET targeting that empty.** Rotate the empty for the first two copies,
  then raise the count until the ring closes. Merge will *not* close first-to-last on composite meshes.
- **Apply mirror modifiers before texturing** — a mirror mirrors the UVs too and the texture comes out
  visibly symmetrical.

## 4 · BUILDING TO REAL DIMENSIONS — the overlay we should have been using
**St Paul's: *"added a cube, enabled the EDGE LENGTH option from the overlays, and started scaling up
to the desired dimension."*** Edge Length shows live metre measurements while you model.
**This is the tool that would have caught the 5.6 m road, the 280 mm median and the 13 m poles.**
Order of work: **get proportions right first, then set real-world scale.**

## 5 · THE AMBIENT OCCLUSION DOUBLE-STACK — the most valuable technique in the batch
This is our **Stage 8 (blending)** answer, and it is what stops a texture looking pasted on.
The AO node does **two opposite jobs** depending on its distance setting.

**(a) CREVICE GRUNGE — darkens where the model folds into itself.**
```
Base Color ──► Mix (Color, MULTIPLY) ◄── AO map from the texture set
                    │        (note: Ctrl+Shift+T does NOT plug the AO map in — do it by hand)
                    ▼
              Mix (Color, MULTIPLY) ◄── ColorRamp ◄── Ambient Occlusion node
                    │                    (dial ~0.1–0.3; he warns this value is per-object,
                    ▼                     "don't just type 0.3 and expect it to work")
              Principled Base Color        factor ~0.75, not full
```
*"Anytime the mesh is close to another part of the mesh, it makes that area darker."*
**Tint the AO with a brown eyedropped from the texture** rather than pure black if it reads fake.

**(b) EDGE WEAR — the same node, inverted, highlighting convex edges.**
**Ambient Occlusion node with the distance set VERY LOW, both checkboxes on (Inside + Only Local),
into a ColorRamp** → that mask isolates the edges of any object.
*"It's kind of the opposite of what the AO node is intended for, but it works for edge wear."*
**Then mix noise into it so the wear is not uniform.** Keep it subtle.

**Both are procedural, need no baking, and cost almost nothing.** Every kerb, parapet, pole, shutter,
step and the whole temple gets these.

## 6 · MAKING A TEXTURE STOP LOOKING UNIFORM — the recipe, and it is our pipeline rule specified
**Source: Enhanced Sight, asphalt.** Our rule says "two materials mixed by a mask, roughness always
varying." Here is the actual graph:
- **Albedo → RGB Curves, whose FACTOR is a Noise Texture through a ColorRamp.** "This makes the
  texture darker only in certain areas."
- **The same principle applied again to the roughness map** → "more reflective areas."
- Debris and dirt layered on with a **Mix Shader using their alpha maps as the factor**…
- **…and that alpha is itself multiplied by a noise texture, "which reduces the density of the debris
  in some places so that it doesn't look uniformly distributed."**
**The upgrade over our written rule: the MASK ITSELF gets noise. Two levels of variation, not one.**

**Worn road markings:** *"connect the texture of your road lines with a Color Mix node to a noise
texture and adjust the alpha channel."* He used a wear value of 3 — *"so they only look slightly
damaged."* **That is exactly S1's "worn to about 60 %."**

**A reusable IMPERFECTION NODE GROUP:** two imperfection textures (scratches, wipe marks) combined
with a Color Mix in **Lighten** mode, then multiplied into roughness, wrapped in a group with one
exposed slider. **Build it once, drop it on anything.** *"I find it too clean without any
imperfections."*

## 7 · KILLING THE CUBE-PROJECTION LOOK
After a Cube Project unwrap every face shares one projection and it reads as fake. His fix:
**hover a UV island, press `L` to select linked, then OFFSET and ROTATE each island individually** —
and **rotate by 90°** where the brick courses should run the other way.
*"It doesn't really make sense that a brick here would continue over this pattern — that's not how it
works."* Also: **two textures on one object, assigned per face** (`Assign` in edit mode) where one
material suits some faces and not others.

## 8 · SCATTERING ALONG A CURVE — the complete node graph
**Source: Enhanced Sight.** This is the graph for our poles, trees, barriers, signs and roadside stalls:
```
Curve ─► Resample Curve (Count, or Length e.g. every 1.8 m)
      ─► Instance on Points ─► output
Collection Info  [Separate Children ✓, Reset Children ✓] ─► Instance socket
        Pick Instance ✓  ◄── Random Value (Boolean) — probability slider + SEED
        Rotation socket  ◄── Align Rotation to Vector ◄── Curve Tangent
```
- **Drop the Resample node and feed a MESH instead** → objects land on its vertices; move or extrude
  vertices to move or add objects. He used this to place and stack containers.
- **Add a small random Z rotation** so nothing is perfectly aligned. (Our ±2° rule.)
- **Each traffic lane gets its own duplicated, slightly tweaked curve**, so cars occasionally change
  lanes instead of running on rails. Directly useful for S4.

## 9 · THE RENDER BUDGET AND THE 8 GB ANSWER
**Real numbers from a finished urban animation:**
- **5 million faces total, of which the buildings are only 1 million** — *"that's not much considering
  the many buildings and the level of detail"* — **because they are instance collections.**
- Cycles **~300 samples**; **light paths 5**, but **transparency 8** — *"if you have many transparent
  shaders such as tree leaves you can increase this value."* **Our trees need this.**
- **Simplify ON, Texture Limit = 2048.** *"4K or 8K isn't necessary; higher resolution consumes more
  graphics memory and increases render time."*

**THE SPLIT-SKY WORKFLOW — this is the direct answer to our 8 GB problem.**
Texture Limit also crushes the HDRI, which is stretched across the whole sky and goes visibly blurry.
The fix:
1. Main scene: **Film > Transparent ON** → the sky is not rendered.
2. Make a **linked copy of the scene named "sky"**, deactivate every object, turn Transparent OFF,
   set Simplify texture limit to **No Limit**.
3. **Combine the two render layers in the compositor.**
**So the world renders at 2K textures and the sky renders at full resolution, and neither compromises
the other.** Passes to enable: Image, Alpha, **Emission** (for masks), **Denoising Data**, **Z**.

**Viewport discipline:** *"simply hiding them isn't enough as they are still processed in the
background — fully deactivate the objects"* (exclude from view layer). Confirms BLENDER-PIPELINE §20.
Background buildings stay deactivated and are enabled only for the render.

## 10 · COMPOSITION AND ORGANISATION
- **A 2 m cube, roughly one person, kept in the scene to judge scale.** Recommended independently in
  three of these videos. **We should have one in every file.**
- **Foreground / midground / background as a deliberate structure**, with a structure placed far in
  the distance purely to create depth.
- **Scatter procedurally FIRST, then hand-place a few hero objects AFTER animating the camera**, where
  the camera actually looks. That is the efficient version of "detail follows the camera."
- **Parent every loose piece to the main chunk. `Shift+]` selects everything parented to it**, and
  duplication keeps the chain. Essential when a structure is 100 loose pieces — ours will be.
- Composition by geometry, not by restricting the camera: he **curves the tunnel steeply at both ends
  so its exit can never be seen**, whatever direction the camera faces. Same family as raising the far
  river bank in Batch 1.
- **Scatter plants onto a small domed plane, then move that patch wherever you want it.** A portable
  clump — which is how you get S1's "clustered, never uniform" instead of an even spread.

## 11 · A DISAGREEMENT WITH OUR OWN BAR — flagged, not buried
Aditya's standard says **"nothing repeats."** Max Hay argues the opposite, deliberately:
> *"Repetition is not a bad thing… even painters will purposely paint a repeating object as a
> technique to improve the image… don't be too afraid of duplication, because although it feels easy
> and cheaty, just because it's easy doesn't mean it's ineffective."*
**He is right, and our rule needs refining rather than abandoning:**
- **Structured repetition is REAL and should be built** — a colonnade, a row of identical poles at
  45 m, the blue posts every 4–8 m, a run of identical shutters, the piers of a flyover.
  Aditya's own footage is full of it.
- **Unstructured repetition is the tell** — the same tree, the same building, the same rock appearing
  at random intervals where nothing would have caused them to match.
**Revised rule: repeat what a REASON would repeat; never repeat what chance produced.**
This is the same causal principle as REF-06 (trees) and REF-07 §4 (rock debris).

## 12 · HONEST LIMITS OF THIS BATCH
- **The first 12 minutes of the urban video are paid-addon advertising** (Transportation, Launch
  Control, Urbaniac, City Generator, Procedural Traffic). I took the architecture and the vertex-group
  mechanism; **we depend on none of these tools.**
- **The temples are fantasy/Aztec-flavoured, not Indian.** The *modelling method* transfers completely;
  **the form must come from REF-03 §6** (latina shikhara, 3.5–5 m shrine, 6–7 m with a hall,
  raised plinth, saffron flag) and from real photographs, not from these videos.
- **Nothing here is in metres except St Paul's 111 m.** Every dimension still comes from NBC, IRC,
  or Aditya's footage.
- Max Hay states his own fidelity limit plainly: *"for medium to long distance renders it's totally
  fine… it's a little messy in some areas."* **Our camera is 1.3 m from the shopfront. His standard is
  not automatically ours** — the facade parts near the camera need more care than he gives.

## 12b · GAP CLOSED — the Fantasy Tower video, which I had listed but not read
**I listed this video as a source without actually reading it. Corrected.** It adds five things:

1. **"A very rough blob… and then the TEXTURE is what's going to carry out all the detail."**
   The sculpt is deliberately crude; the material does the work. But he also hits the failure mode:
   *"there weren't quite enough polygons for the displacement, ends up being kind of messy — if I had
   done the multi-resolution properly I would have been able to subdivide it more."*
   **Displacement needs enough geometry underneath it or it goes to mush. Set up multires first.**
2. **The slope mask, with the actual node path: `Texture Coordinate > Normal → Separate Color`.**
   Cheaper than computing a dot product, and it is the node chain REF-07 §3 was missing.
3. **Weight paint to drive scatter — and the generalisation that matters:** paint a vertex group,
   then set the scatter density to that group, choosing **inside OR outside** it.
   *"That doesn't just work in the add-on. You can do that with geometry nodes. You can do that with
   a normal particle system."* **Fourth independent confirmation of the corridor-clearing method.**
4. **Radial duplication without an Array modifier**, for one-offs: select the structure →
   **Cursor to Selected** → set pivot point to **3D Cursor** → rotate. Faster than empty + array when
   you only need a few copies.
5. **CLOUDS, cheap:** *"these are not VDB clouds — these are actually just images of clouds on a
   slightly extruded plane, running into a SUBSURFACE SCATTERING node, mixed with a transparent."*
   **This is how S0's 25 % thin stratus gets built**, and it pairs with the cloud-shadow plane in
   REF-07 §6 — the image gives the look, the shadow plane gives the ground shadows.

## 13 · SOURCES
Enhanced Sight *Easy Realistic Urban Environments* · Max Hay *Modeling Temple Assets* ·
Max Hay *Making an Overgrown Temple* · Max Hay *Fantasy Tower Environment* ·
hbitproject *I recreated St Paul's Cathedral in 3D*.
