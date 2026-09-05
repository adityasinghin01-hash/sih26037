# DEFERRED WORK — things deliberately left, with the reason and where they go
**Nothing here is forgotten. Each item names what is wrong, what fixes it, and which machine.**

## SKY — the hero cloud variant  *(RESOLVED 4 Sep — superseded by the component 1 v2 rebuild)*
**The "reads as boulders, not vapour" problem is FIXED.** What actually fixed it, in order of effect:
1. **`MeshToVolume`'s `Interior Band Width` (90 m)** — the built-in edge falloff. Not a shader trick.
2. **`volume_bounces` 2 → 6.** Multiple scattering inside the cloud is why real cumulus undersides
   are bright rather than near-black. This was the single biggest change.
3. **A light grey-blue underside (0.70,0.74,0.80), not storm grey**, on a Z-offset gradient to white.
4. **Cluster-of-lobes geometry** instead of one ellipsoid — the shape was the problem, not the shader.
**And the honest note in the original entry was right: the 64 GB machine would not have fixed any of
this.** Peak memory was **391 MB**. Memory was never the constraint; the shading and the geometry were.

## SKY — the ORIGINAL hero-cloud entry, kept for the record
**State:** built and working. `CLOUD_HERO` collection in `blend/01_LIGHT.blend`, 16 real
volumetric cumulus from the REF-12 §3 pipeline. **Currently EXCLUDED; `CLOUD_REFERENCE` is active.**

**What is wrong:** they read as **boulders, not vapour.** Edges too hard, density too high, so the
volume looks solid. Real cumulus has soft, semi-transparent, wispy boundaries and a density that
falls off at the cloud's edge.

**What actually fixes it — and it is NOT more memory:**
- Density down (currently 0.045–0.075) with an **edge falloff** so the boundary is not a hard shell
- A **top/bottom colour gradient** with Z offset (REF-12 §4) so the underside picks up ground colour
- **Halation** — the warm fringing on backlit edges. Coverage 3–6. Our sun is at 7.5° so every cloud
  is near-backlit; this is the effect that will sell them
- Finer voxels near camera, and many more clouds for real sky coverage

**HONEST NOTE ON THE MACHINE:** 16 clouds cost **1.4 GB peak** — nothing. **The 64 GB machine does
not fix the look.** What it buys is *quantity and resolution*: many more clouds, finer voxels,
full-sky coverage, higher sample counts. **The shading tuning above still has to be done, and it
will look identical on either machine until it is.** Do not expect RAM to solve it.

**Where:** the final light pass, after the world exists — clouds should be judged against real
terrain and a real horizon, not a bare plane.

## SKY — the sky-image plane  *(deferred 4 Sep, component 1)*
Built and **hidden**. REF-12 §2's method (four independent sources) needs an actual **sky
photograph**, which we do not have. Without one it is a lower-quality copy of the Nishita sky with a
visible edge. **Un-hide the moment Aditya supplies a sky photo** — and check its sun is on the
east-south-east side, or mirror it with `S X -1`.

## SKY — brightness
Render reads **171 brightness / 3.4 % saturation** against the measured target of **187 / 4.6 %**.
Close, and the residual is a grading matter — his dashcam auto-exposes, so its absolute brightness
reflects the camera's metering, not the scene. **Match it properly in stage 14, not by pushing the
sun.**

## NIGHT — a condition no script covers  *(found 4 Sep)*
**6 of the 13 dashcam clips are shot at NIGHT.** Black sky, headlights, tail lights, street lamps,
wet-looking road. **No scenario script mentions night at all.** S0 fixes a single time of day, 06:45.
**This is a gap Aditya has to decide on**, not something to invent: either the film is dawn only, or
a night scenario gets written and built. Flagged, not actioned.

## THE TIME OF DAY — afternoon, not dawn  *(raised by Aditya 4 Sep, DECISION PENDING)*
**Every script specifies 25 September, 06:45 IST — sun elevation 7.65°, azimuth 95.24°.**
Aditya wants **afternoon: sun high, real cumulus, varied cloud shapes, sun rays, everything
harmonising.** His reference exists and is measured — `video/bus/bus_02.mp4`, **17.2 % saturation,
R155 G173 B187, blue with real cumulus** — against the dashcam's dawn condition of
**R191 G188 B183, 4.6 % saturation, warm grey**. Two completely different skies.
**This is a script change, not a sky tweak, and it is the last thing blocking component 1.**
Solar positions for 25 Sep 2026 at Najibabad, recomputed 4 Sep (NOAA):
| IST | elevation | azimuth |
|---|---|---|
| 06:45 *(as written)* | 7.65° | 95.24° |
| 14:00 | 49.51° | 226.09° |
| 15:00 | 38.97° | 241.09° |
| 15:30 | 33.11° | 246.87° |
| 16:00 | 27.01° | 251.91° |
| 16:30 | 20.74° | 256.40° |
**THE AFTERNOON SKY, MEASURED 4 Sep from 15 frames across the whole 4-minute clip:**
| | R | G | B | saturation | brightness | hue |
|---|---|---|---|---|---|---|
| **bus_02 clear sky** | **160.4** | **186.3** | **219.2** | **26.3 %** | 188.6/255 | 213.6° blue |
| … upper third (toward zenith) | 160.3 | 188.0 | 224.1 | **28.1 %** | 190.8 | 214.0° |
| … lower third (toward horizon) | 161.9 | 182.9 | 209.2 | **22.3 %** | 184.6 | 213.4° |
| dashcam dawn *(what S0 uses now)* | 191.0 | 188.0 | 183.0 | **4.6 %** | 187.0/255 | warm grey |
**The zenith→horizon desaturation (28.1 → 22.3 %) is measured, and it confirms REF-06 §6's
reading of the same footage** — saturated blue above, pale at the horizon.
**Cloud cover: mean 6 %, range 0–37 % across the 15 frames** (bright, low-saturation pixels inside
the sky region). Real cumulus, and the amount varies a lot shot to shot.
**Note on the earlier 17.2 % figure:** that averaged the whole sky region *including the white
clouds*, which pulls saturation down. **26.3 % is the blue sky itself**, and that is the number
Nishita must hit, because in our build the clouds are separate geometry, not part of the sky colour.

**AND THE THING THAT IS NOT JUST A TIME CHANGE: it is a different SEASON.**
The bus footage is **monsoon** — clean washed air, deep blue, lush green, wet road patches. S0 fixes
**25 September** with **800 m visibility and aerosols 10.0**, which is a dusty post-monsoon dawn.
**Those two cannot both be true.** The crops in S1 and S5 (paddy being cut, cane standing, ploughing
for rabi, the cold brick kiln) are all written for late September. **So the date should stay and the
AIR should change**, not the calendar — but that is Aditya's call and it is recorded here as open.

**What it changes is listed where the change lands, not here** — S0 §2 (sun, sky, haze colour,
cloud type), S2 (its action is keyed to "quarter to seven"), and every component built after,
because every material is judged under this light.
