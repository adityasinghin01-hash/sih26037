# REF-12 · SKY, CLOUDS, ATMOSPHERE AND LIGHT
**Batch 6 of Aditya's video study.** 9 videos, 1 h 04 m. **Every capability below was verified by
running it in 4.5.11**, not assumed. This closes the two gaps REF-07/REF-11 left open: **volumetric
clouds** and **god rays**.

## 0 · THE HEADLINE — where realism actually comes from
> *"To make the cloud look realistic, I would say it's about **90 % in the LIGHTING and only 10 % in
> the shader**."* — adrien_ltn
This is the fourth independent statement of the same thing: Covingsworth (*"the sky carries much more
realism than you'd expect"*), Batch 5 (*"it's missing atmosphere — proper atmosphere is that secret
sauce"*), REF-09, and now this. **Stop trying to fix a flat image with materials. Fix the light.**

## 1 · THE LIGHTING PROCEDURE — Max Hay, and it starts with darkness
1. **Turn EVERY light off. Start from pitch black.** Unplug the world background, disable every lamp
   however dim. *"That's just going to simplify it as much as possible."*
2. **Add one light and judge it. Then the next.**

**THE ONE RULE THAT MATTERS MOST — never light from the camera's direction:**
> *"You want to avoid lighting from the same perspective as the camera, because the shadows fall
> behind the objects where you can't see them — which basically still means there's no shadows. That
> flattens everything out, makes it hard to determine the form of any object, and flattens the detail."*
**Put the sun off to one side.** Lighting from behind the camera is the single commonest way a render
dies, and a flat white world background is the same failure — *"equal light from every direction
means almost no shadows, and that creates an extremely boring image."*

**SHADOW CASTERS OFF-SCREEN — a real compositional tool:**
> *"I often throw objects off screen but casting shadows onto the area you're capturing. That creates
> much more interesting shadows and shows just the parts of the image you want."*
Duplicate anything, put it outside frame, set it shadow-only, and use it to darken a too-bright
foreground and steer the eye. **Same family as our cloud-shadow plane.**

**THE LIGHTING-COLLECTION WORKFLOW — use this to show Aditya options:**
Select every light → **`M` → new collection** ("golden hour") → disable the collection → the scene is
black again → build a completely different setup in another collection. Toggle between them.
**Zero risk, instant A/B.** This is how we present lighting variants.

## 2 · THE SKY — four independent sources say the same thing
> ***"Don't use HDRIs as a background — use them ONLY for lighting."*** — Split Graphics
> *"Sometimes I do use HDRIs, but I don't use it as the actual background. I just use an image."* — Max Hay

**THE SPLIT:** an HDRI or Sky Texture provides the **LIGHT**; a flat image plane provides **what the
camera SEES**. Hide the environment from camera with **Film > Transparent**.
**Max Hay's claim, and it is worth taking seriously:** *"It's way better than an HDRI — the
resolution is so much higher, **it doesn't add any extra render time**, and you have unlimited
variation."*
**This also solves REF-09 §9's problem** — the Simplify texture limit crushes an HDRI stretched
across the whole sky. A plane with its own image sidesteps that.

**THE SKY-PLANE RECIPE, step by step:**
1. Add a plane behind the camera view.
2. **Copy the camera's rotation:** select plane → shift-select camera → **`Ctrl+C` → Copy Rotation**.
   (Enable **Copy Attributes Menu** in Preferences — ships with Blender.)
3. **Parent it to the camera** (`Ctrl+P` → Object, **Keep Transform**) so it follows the view.
4. **UV: `Tab` `A` `U` `C`** — Cube Project. *"I use that for every single object."*
5. Image → **Emission Color AND Base Color.** Emission alone looks washed out; base colour lets it
   pick up environment light. Strength ~1–10. (Optionally image → Alpha as well.)
6. **ALIGN THE IMAGE HORIZON WITH THE SCENE HORIZON.** Roughly is enough.
7. **DISABLE ITS SHADOW:** Object Properties → Visibility → Ray Visibility → uncheck **Shadow**.
   Otherwise it casts a shadow across the entire scene.

**THE DEAD GIVEAWAY, and it applies to us directly:**
> *"You want the direction of light in the image to match the direction of light in the scene… there's
> a mismatch and that is going to instantly just ruin everything. **It's a dead giveaway that it's
> 3D.** Don't do that."*
Fix: **`S X -1`** to mirror the plane. Also **match the COLOUR** of the HDRI to the sky image.
**OUR SUN IS AT AZIMUTH 95.2°, EAST-SOUTH-EAST.** Every sky photo or HDRI we use must have its sun on
that side, or be flipped. Elevation matching matters less than direction.

**Also available and verified: the Dynamic Sky addon** (`bpy.ops.object.dynamic_sky_add`) — a
parametric world with sky colour, horizon colour, **cloud colour, cloud opacity, cloud density**, sun
direction, sun colour and brightness. Fast, controllable, no image needed. Good for quick variants.

## 3 · VOLUMETRIC CLOUDS — the gap, now closed
**Source: adrien_ltn, who rebuilt Houdini's cloud pipeline in geometry nodes.** He sells a tool, but
he describes the whole method and **every node it needs exists in our 4.5.11 (verified).**
He is explicit about why the alternatives fail: **VDBs** need other software, cannot be tweaked, are
rarely animated and get very heavy; **the usual Blender tutorials** *"fake the cloud using 2D cards,
noise displacement, or rely on a lot of manual modelling."*

**THE PIPELINE:**
1. **Base shape = scattered spheres.** *"You don't need to be too detailed as long as it's vaguely
   cloudlike."* Controls: seed · length · width · scale · **point separation** (sphere density) ·
   **distortion** (top-down shape) · **flatten bottom**.
2. **NO height parameter — and this is the insight.** *"Vertical growth in a cloud is quite organic."*
   Instead: a **displacement pass that adds small spheres and pushes them UPWARD**, with a *spread*
   control for how much goes sideways instead, plus a **cleanup factor** to delete strays.
3. **Children:** smaller offspring spheres for detail. Density, scale multiplier, repeat ×2.
4. **Cloud species presets — real meteorology:** *humilis · mediocris · congestus · fractus.*
5. **CONVERT GEOMETRY TO VOLUME.** `Mesh to Volume` / `Points to Volume`.
   - **Resolution = voxel size.** *"Think of it as pixel size but for volumes. The lower, the more
     detailed."* **⚠ Low values crash the machine — TYPE the value, never drag the slider.**
   - **Render subdivision: keep at 2–3 maximum**, the particle count explodes.
6. **Noise tab** for organic deformation; **flatten** with intensity + height (0 bottom, 1 top).
7. **Wind** — makes the trails and the spread at cloud base. Direction as X/Y/Z, omnidirectional
   toggle, **Z padding** for the height it acts at, and **flip-Z so the spread happens at the TOP —
   that is the cumulonimbus anvil.**
8. **Vortex** — an empty + radius + intensity + push, for directional swirl.
9. **CAMERA CULLING:** feed in resolution and focal length, then a padding slider deletes particles
   outside the frustum. **Then BAKE** the cloud (still or animation) so it is not recomputed —
   but render subdivision does not survive a bake.

**`Volume Displace` modifier** for final distortion. **⚠ Set its texture to COLOR, not greyscale —
greyscale displaces on one axis only; colour displaces in all directions.** (Verified present.)

## 4 · CLOUD SHADING — the parameters worth rebuilding
Top and bottom colour with a **Z-offset gradient** (makes a cloud stormy, or lets it pick up the
colour of what is beneath it) · a **billowy** factor driven by noise for puffiness · **internal
shadow control**, *"almost like an ambient occlusion"* inside the volume · **wind dispersion** matched
to the geometry wind (Z padding, blur, intensity, flip-Z).
**HALATION — and this one matters for us.** *"The fringing, rainbow-like effect you get around the
very edges of clouds."* Coverage (how far it wraps), mix (intensity), colour offset (hue).
**Coverage 3–6 is the pleasing range; 1 is extreme.**
**Our sun is at 7.5°, so every cloud in our sky is near-backlit — halation is exactly the effect that
sells a low-sun sky, and it is free.**

## 5 · RENDERING VOLUMES WITHOUT THE RENDER CATCHING FIRE
| Setting | Default in 4.5.11 | What to use | Why |
|---|---|---|---|
| **Volume Max Steps** | **1024** | **10–25** | *"The smaller the number the faster, but you might end up with blocky artifacts if you go too low."* |
| Volume Step Rate | 1.0 | leave alone | *"Some people change the step size, but that has created more issues than anything."* |
| **Volume Bounces** | **0** | raise a little | *"The higher, the nicer your volumes — but the slower."* |
EEVEE works if **volumetric shadows** are enabled, but Cycles is more realistic.

**COMPOSITING — and this is not optional:**
- **Enable the Volume Direct and Volume Indirect passes** (verified present). *"These can be
  lifesaving, especially for adding more detail to the final image."*
- **Render clouds on their own render layer.**
- For animation: render **every 2nd–10th frame** and interpolate the gaps. He rendered every 10th
  frame on still-camera shots, every 2nd where the camera moved fast.
- Export **EXR** for external compositing.

## 6 · GOD RAYS — the mechanism, stated plainly
No video in this batch was *about* god rays, so this is assembled rather than quoted, and I say so.
**Shafts are simply the gaps between shadow casters inside a scattering medium.** You need all three:
1. **A bounded volume with scatter** — a cube over the scene, **Volume Scatter** (or Principled
   Volume), density low. Set **Object Properties → Viewport Display → Display As: Bounds** so it does
   not obstruct the viewport.
2. **ANISOTROPY RAISED.** *"It's shifting it more towards where the light source is coming from."*
   Forward scattering is what makes air glow around a low sun. **Our haze already uses 0.35.**
3. **SOMETHING TO OCCLUDE THE LIGHT** — the canopy, a building edge, the flyover deck, the
   cloud-shadow plane, or a deliberate off-screen caster (§1).
**Without occluders there are no shafts, only fog.** At a 7.5° sun this is the strongest atmospheric
effect available to us, and it costs geometry we are already building.
**Warning from the same source:** on a clear sunny render keep volume density *low* — *"if you crank
it up it looks weird and overly foggy, like wildfire smoke."* Our 0.0049 is physically derived, so it
is right by construction, but resist raising it by eye.

## 7 · VERIFIED IN 4.5.11 — every one of these was run, not assumed
`object.dynamic_sky_add` · `image.import_as_mesh_planes` · **`MeshToVolume` · `VolumeToMesh` ·
`DistributePointsInVolume` · `PointsToVolume` · `VolumeCube` · `SimulationInput`** ·
`ShaderNodeVolumeScatter` / `VolumePrincipled` / `VolumeAbsorption` · **`VOLUME_DISPLACE` modifier** ·
`use_pass_volume_direct` · `use_pass_volume_indirect` · `cycles.volume_max_steps` /
`volume_step_rate` / `volume_bounces`.
**The full procedural cloud pipeline is buildable here with no addon and no purchase.**

## 8 · HONEST LIMITS
- **The cloud pipeline is a paid product** (Cloud Creator). The *method* is fully described and every
  node exists natively, so **we build our own** — but I have not yet built it, so the difficulty is
  unproven. **Nobody has measured what a volumetric cloud costs in 8 GB.** That is the open risk.
- **Five of the nine are one-minute videos** that all say the same thing (image plane for background,
  HDRI for light). Useful as confirmation, nothing more.
- One is in **Hindi** (CG Aman) and adds nothing the others do not.
- **God rays were assembled from parts, not taught.** The mechanism is sound but untested here.
- **None of this is Indian sky.** Post-monsoon western UP at 06:45 — the specific pale, hazy,
  white-pink horizon in S0 — still comes from **Aditya's own footage**, not from these.

## 9 · SOURCES
Max Hay *How to get good lighting in Blender* (27:52) · Max Hay *How to Create Beautiful Skies* (9:10) ·
adrien_ltn *Perfect Procedural Clouds — Geometry Nodes* (18:12) · blenderian *Dynamic Sky addon* ·
Split Graphics · BlenderVitals · Ankan Moyra · Blend Tweaks · CG Aman (Hindi).

## 10 · WHAT BUILDING IT ACTUALLY TAUGHT — 4 Sep 2026, added after component 1 v2
**Four things that no video in this batch said, all found by building and measuring.**

**a · `Principled Volume > Color` IS THE SCATTERING ALBEDO, NOT A PAINT COLOUR.**
This was the single biggest error and it cost three iterations. Real cloud droplets scatter
almost everything that hits them — **albedo ≈ 0.99**. Setting the underside to a "storm grey"
(0.70) makes the volume **absorb 30 % of every bounce**, so the cloud goes grey and heavy no
matter how much light is thrown at it. **A real cumulus underside is dark because light does not
REACH it** — self-shadowing through depth — **not because the material is grey.**
**Fix: albedo near white everywhere (0.90 → 1.00, a bare cool tint on the base), and let multiple
scattering produce the dark base by itself.** That is what makes tops read bright white.

**b · `volume_bounces` IS THE FORM CONTROL.** The default of 0 — and even 2 — starves a cloud of
the multiple scattering that lights its interior. **6 to 8 is where cumulus starts to look like
cumulus.** REF-12 §5 said "the higher the nicer"; it is stronger than that. It is the difference
between a lit shell and a cloud.

**c · `Interior Band Width` IS ABSOLUTE METRES, and that makes it dangerous with mixed sizes.**
It is the density falloff inward from the surface — the vapour-vs-rock control. But because it is
absolute, **a band larger than the smallest cloud turns that whole population into pure falloff:
grey mush with no form.** A 135 m band erased a fractus population whose lobes were ~20 m.
**Keep the band small relative to the SMALLEST population, then raise density to restore form.**

**d · ONE POPULATION CANNOT MAKE A SKY.** Measured against Aditya's photographs, a real sky has a
**max/median cloud-size ratio near 1800**; one Poisson population gave **37–103**. The fix is
**three populations with their own spacing, seed and size range** — large/mid/fractus — joined
before the volume conversion. That took the measure to **389–701**. *(The fractus population also
gets a deliberate Z jitter: cumulus and stratocumulus have flat coplanar bases, fractus does not.)*

**AND THE HONEST NOTE ON HARDWARE:** peak memory across all of this was **391 MB, 1.1 GB on the
heaviest frame, out of 8 GB**. **Not one of the four problems above was a memory or GPU problem.**
They were shading and geometry decisions and they would have looked identical on a 64 GB machine.
