# DEFERRED WORK — things deliberately left, with the reason and where they go
**Nothing here is forgotten. Each item names what is wrong, what fixes it, and which machine.**

## SKY — the HERO cloud variant  *(deferred 4 Sep, component 1)*
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
