# REF-17 · MATLAB — WHAT IS IN THE BOX, AND HOW TO BUILD FAST WITH IT
**Started 4 Sep 2026.** Everything here was **run on Aditya's Mac** (R2026a Update 5, MACA64).
Nothing in this file is from documentation alone — REF-05 §7 records what that costs.

> **Numbering note:** REF-14, 15 and 16 do not exist; the library stops at REF-13. This file
> was named REF-17 because the brief asked for that name.

---

## 0 · THREE CORRECTIONS TO EXISTING DOCUMENTS

### a · "The .osm import takes over 10 minutes" — IT DOES NOT. It takes 9–30 seconds.
`REF-05 §1` and `§2` both say *"It takes over 10 minutes — always run it in the background."*
**Timed three times on this machine, all returning 425 RoadSegments:**

| run | time |
|---|---|
| first (cold MATLAB) | **29.3 s** |
| trial 1 (warm) | **16.1 s** |
| trial 2 (warm) | **8.7 s** |

**Wrong by roughly 40×.** Backgrounding it costs nothing, but any plan built around a
10-minute import is planning around a number that is not real.

### b · `roadNames()` DOES NOT EXIST IN R2026a
`derisk/check03_osm_import.m` calls `roadNames(scenario)` and would report a **false import
failure on a perfectly good import**:
```
Undefined function 'roadNames' for input arguments of type 'drivingScenario'.
```
Use `scenario.RoadSegments`, which is what `map/gate_matlab.m` already does correctly.

### c · Unreal / `plotSim3d` DOES NOT WORK ON macOS
`sim3d.World` ships in the install and `plotSim3d` is a real `drivingScenario` method, so it
looks available right up until it throws:
> `Co-simulation with Unreal Engine is not supported on this operating system.`

**There is no photoreal path inside MATLAB on this machine.** Confirmed against MathWorks'
own platform requirements: Windows and Linux only.

---

## 1 · THE HEADLINE — MATLAB RENDERS 5,300× FASTER THAN OUR BLENDER SCENE
| | per 1280×720 frame | a 62 s film at 24 fps |
|---|---|---|
| Blender Cycles, `01_LIGHT.blend`, **sky only, no geometry** | **> 760 s** (killed at 12:40) | **> 300 hours** |
| MATLAB `patch`/`surf` + 2 lights, 40 buildings | **0.142 s** | **3.5 minutes** |

The consequence is not "MATLAB is cheaper". It is that **the look can be iterated** — rendered,
looked at, fixed, re-rendered — which is the only way anything visual gets good.

---

## 2 · WHAT IS ALREADY INSTALLED — nothing needs downloading
**10 add-ons, all enabled:** Automated Driving · Navigation · Sensor Fusion and Tracking ·
Lidar · Mapping · Computer Vision · Image Processing · Deep Learning · Simulink · Stateflow.

### The asset kit
- **Six shipped meshes**, all real `extendedObjectMesh` objects:
  `driving.scenario.carMesh` (**236 verts / 178 faces**) · `truckMesh` · `pedestrianMesh` ·
  `bicycleMesh` · `jerseyBarrierMesh` · `guardrailMesh`.
- **`extendedObjectMesh` primitives: `cuboid`, `sphere`, `cylinder` ONLY.**
  `tetrahedron` and everything else are rejected by name.
- **`join`, `scale`, `translate`, `rotate`, `applyTransform`, `scaleToFit`, `show`** — enough to
  compose any actor out of primitives. A zebu is a barrel, a hump, a dewlap, a head, four legs
  and a tail; that reads as a cow from every angle a camera will take.
- **`scaleToFit` takes a positive scale, not a bounding box** — the obvious 6-element call is
  rejected. Use `scale` and assert the result.

### The asset IMPORT path — exists, verified, and deliberately NOT used
`stlwrite` → `stlread` → `extendedObjectMesh(Points, ConnectivityList)` **round-trips**
(verified: 178 faces in, 178 out). `readSurfaceMesh` reads **PLY and STL** (Lidar Toolbox).
So a downloaded model *can* become an actor mesh.
**We are not using it:** downloaded assets carry licence conditions this project cannot verify,
and hand-composed primitives give exact dimensions for free. The path is recorded in case a
future asset is genuinely needed.

### The geometry kit — this is how the chowk gets built
`polyshape` · `nsidedpoly` · **`polybuffer`** · `subtract` · `triangulation(polyshape)` ·
`alphaShape` · `convhull` · `boundary`.
**`nsidedpoly(36,'Radius',11)` is the island; `subtract(polybuffer(isl,0.35), isl)` is its kerb
ring** — 378.2 m² and 24.5 m² measured. Extrude by pairing the polygon with a Z and walling the
edges. Same three lines build a building footprint, a plinth step or a fence line.

### Road-building
- `road(sc, centers, width)` — per-class carriageway width.
- **`lanespec` + `laneMarking('Solid'/'Dashed', 'Color', …)` WORK**, and
  **`laneMarkingVertices(sc)` returns the painted geometry** (1,680 doubles on a two-lane test
  road) — so real lane markings can be drawn, not faked.
- **`driving.scenario.RoadGroup` is the correct way to build a junction.** Add each arm with
  `road(rg, …)`, then `roadGroup(scenario, rg)`.
  **TRAP: roads added through a RoadGroup DO NOT appear in `scenario.RoadSegments`** — it
  returned **0** while the junction rendered perfectly. **Use `roadBoundaries(scenario)`**, which
  does return them. Anything counting `RoadSegments` will silently think the scenario is empty.
  MathWorks' own note: only the **first** lane specification of each segment is used.
- **57 prebuilt scenarios ship** under `shared/drivingscenario/PrebuiltScenarios/` — Euro NCAP
  AEB, U-turns, ACC, cut-in, left-turn. Stored as `tag`/`data` structs, useful to read for
  structure rather than to load directly.

### Everything else already present
Sensors `lidarPointCloudGenerator` · `drivingRadarDataGenerator` · `visionDetectionGenerator` ·
planning `referencePathFrenet` · `trajectoryGeneratorFrenet` · `dynamicCapsuleList` ·
`controllerPurePursuit` · `vehicleCostmap` · `plannerHybridAstar` · tracking `multiObjectTracker`
· `trackerJPDA` · export `OpenDRIVE 1.4/1.5/1.6`, `OpenSCENARIO XML 1.0/1.1`, `RoadRunner HD Map`
· `record(sc)` returns every pose in one call · `VideoWriter` MPEG-4.

---

## 3 · THE COW IS A BUILT-IN, NOT HAND-ROLLED MOTION
The hero behaviour of S1 — walk out, stop on the centreline, **never move again** — is one call:
```matlab
smoothTrajectory(cow, [x yStart 0; x yEnd 0], [1.2 0]);
```
**Verified over a 12 s run: the actor reaches 0.650 m and holds it to the last sample.**
- `smoothTrajectory` is an **ACTOR** method, not a scenario function.
- **It rejects repeating zeros in the speed vector** (`driving:scenario:UnreachableWaypoints`).
  Two waypoints with speeds `[v 0]` is the correct idiom for "go there and stop".
- The written gait is self-consistent: **1.68 m × 43 strides/min = 1.204 m/s** — stride ×
  cadence equals speed, so the feet cannot slide.

---

## 4 · RENDERING TRAPS — the ones that cost real time
1. **`daspect(ax,[1 1 1])` IS MANDATORY.** Without it the Z axis stretches to fill the axis box
   and every 4 m house renders as a tower. This single line was the whole difference between an
   unusable first render and a presentable one. **Highest-value line in the renderer.**
2. **`plot(scenario)` silently renders NOTHING** unless given `'Parent',ax` explicitly.
3. **`trajectory`, `smoothTrajectory` and `chasePlot` are ACTOR methods.**
   `exist('smoothTrajectory')` returns **0** and `which` finds nothing — they look missing and
   are not. `chasePlot` resolves to `+driving/+scenario/Actor.m`.
4. Two lights, not one: a warm infinite sun at the scene's real solar vector plus a cool sky
   fill, then `material dull`. One light gives black shadow sides and reads as a diagram.
5. `set(ax,'Clipping','off')` or geometry at the axis limits gets sliced.
6. Actor `ClassID` is the drivingScenario numbering (1–6), **not** our S5 numbering (0–15).
   `sih.util.toSimClassID` exists for exactly this. Never hardcode either side.
7. **THE GRASS RENDERS OVER THE ROAD.** Ground relief of ±0.11 m against tarmac laid at
   z = 0.03 m makes the terrain poke through in patches, and the road stops reading.
   Base the ground at **z = −0.25** and stack the road layers above it. Found by looking
   at a render, not by reasoning about it.
8. **`axis off` makes an axes background TRANSPARENT** — setting `'Color'` alone does
   nothing, and the 3-D scene shows straight through every HUD panel. Paint an explicit
   `patch` behind each panel.
9. **`Clipping','off'` lets the 3-D axes draw OUTSIDE its own position box**, straight over
   the HUD strip. It is still needed (or the sky gets sliced), so the cure is to paint one
   opaque backing strip over the whole HUD region first, in its own axes.

## 4b · MESH DIMENSIONS ARE NEVER RIGHT FIRST TIME — ASSERT THEM
The first `sc.meshes` was measured and **six of eight meshes were out of specification**:
the zebu came out **0.72 m wide against 0.85 m** and **1.71 m tall against 1.43 m**, the car
**1.12 m tall against 1.50 m** and **2.06 m wide against 1.90 m**. Nothing looked wrong.
Parts get added — a hump, horns, a mirror — and the bounding box moves silently.
**Every mesh now asserts its own [L W H] to 5 mm and reports the miss in millimetres.**
It took five rounds of assert→fix→re-measure to get all eight exact. That loop is the method.

---

## 5 · MEASURED AGAINST THE MAP — the frame holds
Re-verified independently, **point-to-segment** as REF-05 §4 requires (point-to-point gives a
false 46 m error because vertices are sparse). MATLAB CSV + offset **(+35.0, −100.0)** against
`najibabad_metres.json`, 1,625 points inside the 2 km box:

| | |
|---|---|
| median | **1.05 m** |
| p95 | **3.33 m** |
| within 5 m | **99.4 %** |
| max | 5.69 m |

Scenario geometry checked against the written scripts:
- **S1** junction measures **(−251.8, +370.5)** vs written (−252.8, +373.3) — **2.9 m**.
  Through tertiary **208.2 m at 132.9°** vs written "209 m at 133°".
- **S2** node measures **(341.6, −578.6)** vs written (340.1, −579.9) — **1.9 m**.
  All four arm bearings within **1°** of written (46/62/232/237).

**But S2's map geometry is NOT a crossroads.** Six road-ends meet at that point and the four
tertiary arms sit in two nearly-parallel pairs — a gyratory pattern. **There is no island in the
OSM data.** Recorded so nobody claims the S2 chowk is the real map: it is not, and S1 is what
carries the real-map claim.

---

## 6 · PHASE 1 — THE KIT, AS BUILT
`matlab/+sc/` — package `sc`, so nothing collides with Stream D's `sih` package.

| file | what it is |
|---|---|
| `refRoot.m` | finds the Reference folder from its own path — no hardcoded `/Users/` |
| `localRoads.m` | real Najibabad centrelines in a circle, at S0 §4 widths, offset removed |
| `routeFrom.m` | chains road pieces into one ego route; scores join + heading + goal so a six-arm node does not pick the wrong arm |
| `meshes.m` | 8 actor meshes, **every dimension asserted to 5 mm** |
| `scene.m` | the renderer: sky, ground, tarmac, meshes, fake shadows, world-space annotation, chase camera, MP4 |
| `hud.m` | the instrument strip: state, live numbers, barrier chart, locator |

**Meshes, all passing:**
`zebu 2.20×0.85×1.43` · `car 3.99×1.90×1.50` (body 1.70, **mirrors add 200 mm**) ·
`auto 2.63×1.30×1.70` · `motorcycle 1.90×0.70×1.30` · `tractor 3.40×1.90×2.60` ·
`trolley 3.20×2.00×1.70` · `bus 10.80×2.60×3.10` · `tataace 3.80×1.50×1.85`

**Render speed as built: ~0.001 s/frame** for the composite 3-D + HUD frame at 1280×720
(the earlier 0.09–0.33 s figures included figure setup on every frame). A 62 s film at
24 fps is **seconds, not minutes**.
**>> CORRECTED IN §9. That was measured on THIS kit — 40 buildings, no forest — and it
does not survive contact with the S1 world. The real figure there is 0.341 s/frame. <<**

---

## 7 · PHASE 2 — THE S1 WORLD, AND THE FOUR TIMES THE PICTURE CAUGHT THE MODEL OUT

`sc.s1render` draws the static S1 world; `matlab/s1_world_shots.m` renders it from five
viewpoints and `matlab/s1_reveal_probe.m` answers the two questions the S1 result rests on.
**Every defect below was found by rendering the scene and LOOKING at it. Not one of them
was found by reasoning about the code, and three of them were live while every assertion
in the file was passing.**

### 7a · THE 2-D SIGHT MODEL IS ONLY TRUE IF THE GEOMETRY OBEYS IT
`sc.path/sightDistance` and `revealDistance` model occluders as **circles in plan**. That is
truthful only if every circle is a solid mass over the whole height the sight line occupies.
The sight line runs from the driver's eye at **1.35 m** (a 1.50 m hatchback, `sc.meshes "car"`)
to the top of the zebu at **1.43 m**, so it never rises above 1.43 m.

**BUG 1 — occluders drawn as DOMES.** A dome is at full radius only at its base, so a 2 m
dome is about half a metre tall where the sight line actually crosses it. **The cow rendered
plainly visible at 60 m while the model called it blocked.**
*Fix:* every occluder now carries `hFull`, the height to which it is at full radius, and is
drawn as a lathe — full-radius cylinder plus a cap — not a sphere. `sc.s1world` asserts
`hFull >= 1.58 m` (1.43 + 0.15 margin) and `sc.s1render` asserts it again before drawing.

**BUG 2 — decoration that occludes.** Six small bushes were drawn around the thicket to break
its silhouette, seated at `radius + 0.45*r`. They reached **5.96 m from the thicket centre
against a modelled 3.48 m — 2.48 m of silhouette the solver knew nothing about.** The cow
stayed hidden all the way down to **24 m** while the model said visible from 44 m.
*Fix:* decoration is seated **inside** the claimed circle and made taller than the core
instead, so it breaks the skyline rather than the plan outline. `sc.s1render` now asserts
`reach <= radius` and the shots script prints it every run: **3.15 m drawn / 3.48 m modelled.**

**The rule this leaves behind: nothing may be drawn that the occluder list does not know
about, and nothing in the occluder list may be drawn smaller than it claims to be.**

### 7b · CROWNS ARE NOT OCCLUDERS — MEASURED, NOT ASSUMED
A crown sits between 0.38h and 1.02h, i.e. **3.4-6.1 m up**, and cannot intersect a line that
never leaves 1.43 m. They were in the occluder list anyway. **Measured over 200 m of
ray-marching they moved the reveal by 0 m.** They are now out of the list; **trunks** are in,
at trunk radius, because a trunk really is an occluder - it simply never crosses this
particular line, being outside the 9.5 m corridor.

### 7c · THE REVEAL IS AUTHORED. THE WRITTEN SCRIPTS SAY IT IS NOT. THAT IS A FINDING.
`SPEC.md` says the treeline does the job "by geometry instead of by script" and that the
reveal is "*computed*, not authored". `S1-CATTLE-CROSSING.md` t=29.0 says "**Geometry decides
this, not a script**". **Measured, that is not what is built.**

| question | measurement |
|---|---|
| road curvature at the cow (station 300) | **radius 1020 m — straight** |
| tightest bend on the route | radius 63 m at station **511**, 211 m past the cow |
| natural reveal, trunks + scrub only, swept over 17 stations | **4 m to 134 m** |
| stations whose natural reveal lands in 30-60 m | **4 of 17** |
| earlier seed sweep (REF-17 s0 work) | 34-110 m across 8 seeds |

The forest as placed **cannot deliver a specified reveal**, and the road does not bend where
the cow is. The reveal therefore comes **entirely from one authored thicket** whose radius is
solved by bisection until the ray-marched reveal matches the written 42 m.

**That design is the right one and should stay** — authoring one occluder and then *measuring*
the consequence is honest, repeatable, and stronger than letting a random seed decide. What
must change is the **claim**: this is an authored occluder with a measured effect, not an
emergent property of the forest. Moving the cow to a station where the scatter happens to give
44 m would be worse - it would hide the authoring behind luck.

### 7d · POINT-VISIBILITY vs SILHOUETTE — THE REVEAL IS SHARP, AND IT MEANS "FIRST SLIVER"
The solver tests the line to **one point**, the cow's origin. Sampling five points across the
animal's 2.20 m body instead:

| gap | points clear |
|---|---|
| 60 m | 1/5 |
| 50 m | 2/5 |
| 46 m | 2/5 |
| **44 m** | **3/5** |
| 40 m | 3/5 |
| 36 m and closer | **5/5** |

So "visible at 44 m" honestly means **the leading 60 % of the animal**, and the whole animal is
clear by 36 m. The transition is sharp — 2/5 to 3/5 between 46 and 44 m — so the reveal is a
real event, not a fade. **Confirmed by eye in the renders: hidden at 60 m, a sliver at 44 m,
fully clear at 22 m.**

### 7e · RENDERER TRAPS — four more, all paid for
10. **`sky()` only works looking along +-x.** It paints a flat backdrop at constant x. The S1
    road runs at 133 deg and the camera turns with it, so the backdrop slides out of frame and
    the figure colour shows through as a black void. Added **`skydome`**, a graded hemisphere,
    which is correct from any bearing.
11. **A far-ground DISC punches up through the ground.** REF-17 trap 7 inverted. `ground()`
    bases its relief at -0.25 with +-0.126 of swing, so its dips reach **-0.376**, below a disc
    at -0.34, and the pale far colour appeared as a **bright plate ten metres from the camera**.
    Fixed by making it an **annulus** starting where the detailed ground ends — no overlap is
    possible, which beats tweaking a z.
12. **Haze has to live in the vertex colours.** A single flat colour on the detailed ground
    meets the hazed far annulus in a hard ring. `ground()` now takes `Haze`/`HazeFrom` and
    blends per vertex by distance.
13. **900 trees as 900 patches is 1,800 graphics objects and the render crawls.** Added
    `sc.scene/instances`, which concatenates N copies of one small mesh into ONE patch with
    per-instance colours - which is also what makes per-instance distance haze free.

### 7f · WHAT THE WORLD IS MADE OF, AND WHAT IS ONLY BACKDROP
**Real, measured, and what the planner sees:** the centreline (`map/matlab_roads.csv`, offset
removed) · the 7.000 m carriageway and 1.200 m shoulders · the marking geometry (edge line
150 mm set 150 mm in; centre 3 m mark + 6 m gap at 100 mm, both worn to 60 %) · every occluder
position, radius and height.
**Backdrop, massed but not measured:** trunk and crown proportions, leaf colour, ground relief,
haze, the far treeline, and the tree shadows across the carriageway (projected along the real
solar vector, elongated 1/sin(33.11 deg) = 1.83, road only - a shadow drawn flat would float
0.30 m above the forest floor).

### 7g · TWO MORE DEFECTS, ONE OF THEM INVISIBLE IN EVERY STILL
**BUG 3 — the forest was a hedge.** The stand was placed in a band `CorridorHalf + rand*32`,
i.e. **36 m wide**, with **bare ground to the horizon behind it**. From the driver's seat that
is invisible, because the near trees cover it; from the clearing camera the wood plainly ended
45 m out and the world behind was empty. Now `ch + 95*rand^1.6` with **2,200 trees** — density
stays high at the roadside and tails out to about **105 m**.

**BUG 4 — `scene/grab` skipped frames while filming.** It called `drawnow limitrate`
unconditionally. **`limitrate` caps updates at about 20 a second and SKIPS the ones that arrive
too fast**, so `getframe` would capture a stale figure and the film would carry duplicated
frames while the trajectory underneath had moved on. Right call for a live preview, wrong one
for a recording. It now uses plain `drawnow` whenever a `VideoWriter` is attached.
**This one was not visible in any still — it was found by reasoning about the film path while
measuring it, and it would have corrupted every Phase 4 deliverable silently.**

**The corridor camera** was also wrong: 62 m up at 160 m back is 21 degrees above the horizon,
and 16 m crowns flanking a 9.5 m half-corridor closed over the road completely. A shot of a
corridor has to look **into** it — now 145 m up at 120 m back.

### 7i · ONE ITEM PARKED FOR PHASE 4 — THE COW'S OCCUPIED BAND DOES NOT MATCH THE ANIMAL
`SPEC.md` and `S1` both state: carriageway 7.00 m, **cow occupies 2.5-3.2 m from the left
edge**, free width right 3.80 m. The free-width arithmetic closes (7.00 - 3.20 = 3.80), but the
occupied band is **0.70 m**, which is neither the zebu's 0.85 m width nor its 2.20 m length.
Phase 4 has to reproduce this arithmetic from the actual pose, so the discrepancy has to be
resolved then - flagged here so it is not discovered late.

---

## 8 · THE BASELINE COMPARISON — DECIDED BY ADITYA, 4 Sep 2026

The open item is closed. **Both**, with the labelling done explicitly on screen:

1. **Lead with MathWorks' shipped planner failing**, because that is the strongest result we
   have and it is *structural*, not tuned: `referencePathFrenet` fails at **t = 19.7 s with
   0 of 120 candidates collision-free**, identically on macOS/ARM and Windows/x86
   (`~/dev/sih2026/plan/BASELINE-R2026a.md`). It cannot run on Najibabad at all.
2. **Then a defensive stand-in beside ours**, so the frozen-robot problem is SEEN rather than
   described - it waits for a gap, and a cow never gives one.

**THE STAND-IN IS OURS AND MUST SAY SO IN THE FRAME.** PRD s8 warns that a tuned opponent is a
rigged fight, and the defence against that charge is the caption, not our good intentions. The
HUD carries three lines, and the middle one names the stand-in as ours:

```
MathWorks referencePathFrenet -> FAILS TO START on this map
                                 0/120 candidates, t = 19.7 s
DEFENSIVE STAND-IN (ours, not MathWorks') -> STOPPED, waiting for a gap that never comes
OURS -> THROUGH, 0.95 m each side
```

**Never let the stand-in be presented as MathWorks' planner.** The baseline's failure is
evidence; the stand-in is an illustration. They are different claims and the film says so.

---

## 9 · PHASE 2 AS BUILT, AND THE ONE NUMBER THAT GOT WORSE

### 9a · THE WORLD
| | |
|---|---|
| route | **610 m** of the real Najibabad tertiary, offset removed |
| carriageway / shoulder | **7.000 m / 1.200 m**, both asserted to 1 mm |
| markings | edge line 150 mm set 150 mm in; centre 3 m + 6 m gap at 100 mm; worn to 60 % |
| trees | **2,200**, corridor half-width wandering 9.5-13.5 m, stand tailing out to ~105 m |
| undergrowth | ~155 clumped bushes, at full radius to **1.60-2.05 m** |
| authored thicket | **r = 3.48 m**, h_full 2.40 m, at station 274, e = +6.4 m |
| drawn decoration reach | **3.15 m** against the modelled 3.48 m - asserted on every render |
| **reveal** | **44 m** solved, specification 42 m; hidden at 60 m, 3/5 at 44 m, 5/5 by 36 m |

### 9b · WHAT A PICTURE COSTS
| path | cost |
|---|---|
| still, `exportgraphics` at Resolution 110, 1400x800, 1,400-2,050 trees | **27-69 s** each |
| the five-shot verification run, end to end | **about 4 minutes** |
| **film, `drawnow` + `getframe`, 1280x720, 989 trees** | **0.341 s/frame** |
| **a 62 s film at 24 fps** | **8.5 minutes** |

**THE FILM NUMBER IS 340x WORSE THAN s6 CLAIMED, AND s6 IS NOW CORRECTED.** 0.001 s/frame was
a real measurement, but it was taken on the Phase 1 kit - 40 buildings and no forest. A stand of
a thousand instanced trees costs 0.341 s a frame even though the geometry is drawn once and only
the camera moves. **Measured on the actual S1 world, which is the only measurement that counts.**

8.5 minutes a film is workable, but it is not free, and Phase 4 should budget it: one look at
the finished film costs nine minutes, not nine seconds. The lever if that hurts is `Radius` -
the driver cannot see past about 150 m of forest anyway, and cost is roughly linear in trees.

### 9c · STATE
**Phase 2 is DONE.** `sc.s1render` + `s1_world_shots.m` (five shots, every one looked at and
fixed) + `s1_reveal_probe.m`. Renders in `matlab/renders/`.

---

## 10 · PHASE 3 — THE ACTION, AND THE COW THAT WAS THE WRONG SIZE

`sc.s1actors` builds the drivingScenario and every scripted actor; `sc.s1drive` is the
PLACEHOLDER driver; `s1_action_run.m` integrates, logs and asserts; `s1_action_shots.m`
renders the beats so they can be looked at.

### 10a · THE ZEBU WAS OUT OF SPECIFICATION, AND IT IS THE WHOLE ARITHMETIC
`SPEC.md` said **"Zebu: 2.20 x 0.85 x 1.43 m ... (REF-04)"**. **REF-04 says no such thing.**
Its s2 gives zebu **body width 57-71 cm**, so 0.85 m was **140 mm above the top of the
documented range**, and the citation was to a document that contradicts it.

This is not cosmetic. **The cow's width IS the S1 gap arithmetic.** `S1-CATTLE-CROSSING.md`
carries its own complete set - **body 205 cm long, 64 cm wide, withers 128 cm, height with
hump 146 cm** - and every one of those sits inside REF-04's ranges. Rebuilt to them:

| | with 0.85 m (as built) | with 0.64 m (S1's own) | written S1 |
|---|---|---|---|
| occupies, in from the left edge | 2.43-3.28 m | **2.53-3.17 m** | 2.5-3.2 m |
| free width to the right | 3.72 m | **3.83 m** | 3.80 m |
| margin each side, ego 1.90 m | 0.910 m | **0.965 m** | 0.95 m |

**Every written number closes to 30 mm once the animal is the right size.** The Phase 1
dimension assertion passed throughout, because it only ever compared the mesh to `dim` and
`dim` was the thing that was wrong. `sc.meshes` now **also** checks the zebu against REF-04's
ranges, so a mesh has to answer to the reference document and not only to itself.
**S1's own numbers are internally inconsistent by 3 cm** (128 withers + "hump 15 cm" is 143,
but it also states "height with hump 146 cm"); 146 is taken, making the hump 18 cm, still
inside REF-04's 10-20 cm, and it is the conservative reading for occlusion. `HFULL_MIN` and
`SIGHT_MAX` are now **derived from the mesh** rather than retyped, so they moved with it.

### 10b · `smoothTrajectory(cow,[verge; stop],[1.2 0])` DOES NOT WALK AT 1.2 m/s
REF-17 s3 called this "verified" and quoted the gait check "1.68 x 43/60 = 1.204 m/s, so the
feet cannot slide". **Phase 1 verified the END STATE and never once looked at the speed
profile.** Measured:

| | two waypoints `[1.2 0]` | five waypoints, explicit gait leg |
|---|---|---|
| speed while walking | 0.134-1.200 m/s, **mean 0.678** | **1.2040-1.2040 m/s** |
| within 5 % of 1.204 m/s | **7 %** | **100 %** of the gait leg |
| time for the 4.25 m walk | **6.92 s** (constant would be 3.53 s) | 3.9 s |

It decelerates across the **whole** segment. The feet slide for 93 % of it. The cure is a
waypoint at which the speed is still 1.204, so the constant-speed leg is explicit.
**The final deceleration cannot be shorter than about 1.8 m** - swept, and 1.50 m and below
are rejected outright with *"Unable to create smooth trajectory"*. So 1.85 m is used, and
**47 % of the whole crossing is at gait speed with the last 1.85 m a jerk-limited stop.**
Nothing pretends otherwise.

**The hero claim, now properly tested:** gait leg **100 %** within 0.5 % of 1.2040 m/s, stops
at **e = +0.6500 m** exactly, and **0.000000 m of movement over the remaining 45.2 s.**

### 10c · SHE HAS TO TURN, AND THE RENDER IS WHAT SAID SO
`smoothTrajectory` yaws an actor along its direction of travel. She walks **across** the road,
so at the instant she stops she is **broadside**, occupying her 2.05 m LENGTH. The gap
arithmetic assumed her 0.64 m width. **The render showed it; the arithmetic did not.**

| yaw off the road axis | lateral extent |
|---|---|
| 0 deg | 0.64 m |
| 3 deg | 0.75 m |
| 20 deg | 1.30 m |
| 90 deg (as smoothTrajectory leaves her) | **2.05 m** |

The written band - 2.5-3.2 m from the left edge - is **0.70 m**, reachable only within about
**3 degrees of parallel**. She therefore turns over 2 s once at rest, which is what S1's
*"Stands. Head turns away."* describes. **It is an authored rotation and is labelled one.**
Her footprint is then measured off the mesh at the pose she actually ends in and asserted
against the arithmetic - the design is not trusted, it is checked.

### 10d · TWO HAND-PICKED NUMBERS, BOTH CAUGHT BY THE CLEARANCE ASSERTION
Where the ego stops short of her decides whether it can finish moving into the gap before it
draws level. Picked by hand it failed twice: at **12 m** the clearance came out **0.856 m**
against the 0.90 m SPEC requires; at **18 m** the ego could not physically stop in the room it
had left itself (17.4 m of braking, 7.7 m available) and **overlapped her by 1.30 m**.
It is now **derived** - lateral distance, pass speed and crab-angle limit, plus both
half-lengths. Result: the ego sits at exactly the pass line and clears **0.965 m on both sides**.

**Lateral motion is limited by CRAB ANGLE, not by a flat m/s.** A flat 0.75 m/s at the 8 km/h
pass speed is an **18.7 degree** crab angle, which is not a car, and while stopped it would let
the ego slide sideways with its wheels still. 12 degrees, scaled by speed.

### 10e · THE WRITTEN 62-SECOND TIMELINE CANNOT BE REPRODUCED, BECAUSE IT DOES NOT CLOSE
Our beats run **8-10 s ahead** of the written ones, converging to -1.3 s by CLEAR. Before
treating that as our error, the written timeline was integrated:

- t=0 to 11.2 s at 52 km/h = **161.8 m**; t=11.2 to 26.1 at 34 km/h = **140.7 m**, so
  **302.5 m at t=26.1** - but S1 puts the speed breaker at **268 m** and the ego on it at t=26.1.
- S1 also puts the cow at 296 m, visible at 42 m, so the ego is at **254 m at t=29.0**.
- **Either way the ego travels backwards: -14 m in 2.9 s on S1's own station, -48 m on its
  own speeds.**

So the written times, speeds and stations are not simultaneously satisfiable. Ours are
integrated from physics and reported against the written ones with the delta shown. Part of
the lead is traceable: the t=26.1 slowdown is for the **speed breaker at 268 m**, which is on
SPEC's DELIBERATELY-NOT-BUILT list, so there is nothing here to slow for.

### 10f · TWO MORE MATLAB TRAPS
14. **`advance()` returns false when the last TRAJECTORY finishes, not at StopTime.** Measured:
    a 3-waypoint cow alone ended a **14 s** scenario at **5.02 s**. A 62 s film must either run
    on its own clock or keep one trajectory alive to the end. The S1 run does the latter.
15. **`actor()` rejects the vehicle class IDs.** `actor(S,'ClassID',1,...)` warns *"Class ID 1
    is not supported for an actor"* and quietly **builds a vehicle instead**. `actor()` takes
    3 Bicycle, 4 Pedestrian, 5 Jersey Barrier, 6 Guardrail and nothing else; everything
    wheeled goes through `vehicle()`.

### 10g · THE DRIVER IS A PLACEHOLDER AND THE CODE SAYS SO IN CAPITALS
`sc.s1drive` **senses nothing**. It follows the written beats by station and by time-in-state.
It does not look at the cow and it does not look at the auto - the reason it "aborts" is that
the script says to abort there. **Say this out loud in any demo.** What it is for is the SEAT:
Stream D's planner replaces the body of that one function and nothing else - same inputs, same
outputs, same integration loop, and the frozen S1 TrackList stays the boundary.

The ego is integrated by the caller rather than given a trajectory, because a planner has to be
able to react and a baked trajectory cannot. The scripted traffic is placed by arithmetic:
each oncoming actor's start is speed x time backwards from where it has to be, and an oncoming
vehicle's meeting station is **the ego's own station at the meeting time** - fixing it instead
put the wrong-side motorcycle 9 m behind the ego and the frame showed empty road.

### 10h · NOTHING WAS CHECKING FOR COLLISIONS, AND SOMETHING WAS COLLIDING
Every assertion in the file passed while the ego and the wrong-side motorcycle **overlapped
by 0.65 m** as they passed. The motorcycle's swing back to its own side was keyed to a
fraction of its OWN trajectory - it swung at 86 % of a 70 s run, long after it had passed us -
so at the meeting instant it was still at e = +2.20 in our lane. It is now keyed to the
**meeting station**: it returns to its own side over the last 14 m before it reaches us.

`s1_action_run.m` now measures separation from **every** scripted actor at every step, in path
coordinates, with each actor's extents rotated by its own yaw, and asserts it. Closest approach
across the whole run is now **0.900 m to the overtaking motorcycle** - which is the written
"0.9 m lateral gap", so the tightest thing in the scenario is the thing the script asked for.

### 10i · THE EGO CANNOT START AT CHAINAGE ZERO
An **overtaking** vehicle is faster than the ego, so to draw level at a given station it must
have started **behind** the ego's start. With the ego at chainage 0 there is no road behind it:
the motorcycle's start clamped to 0 and it was alongside at **t = 0.65 s** instead of the
written **6.4 s**. Found by the separation check, not by looking. The ego now starts at
**station 25 m** and the overtake lands at **t = 5.85 s with 0.900 m** - written 6.4 s and 0.9 m.
`sSlow` moved with it so the first beat still lands on the written 11.2 s exactly.

### 10k · A SHOT TIME IS A MEASUREMENT TOO
The two stills whose whole job is to show the **clearance** were shot at `COMMIT + 5.4 s`,
which was a guess. At that instant the ego was still **8.6 m short of her and halfway through
its lateral move**, so both frames showed the approach rather than the pass, and the number
they exist to demonstrate was not in either of them. The moment is now taken from the log -
the step at which `|s_ego - s_cow|` is smallest - and printed. **If a still is evidence for a
number, the instant it is taken at has to come from the run, not from arithmetic in my head.**

### 10j · WHAT PHASE 3 LEAVES FOR PHASE 4
The numbers below are **computed by the run**, not typed, and Phase 4 has to reproduce them
live on the HUD from the same log:

| | |
|---|---|
| cow's footprint, off the mesh at her real pose | **e = +0.330 to +0.970 m**, 0.0 deg off parallel |
| in from the left edge | **2.53-3.17 m** (written 2.5-3.2) |
| free width to the right | **3.83 m** (written 3.80) |
| ego on the pass line | **e = -1.585 m**, held exactly |
| **clearance** | **0.965 m to the cow, 0.965 m to the right edge** (written 0.95) |
| speed past her | **8.00 km/h** (written 8) |
| cow after stopping | **0.000000 m over 45.2 s** |

### 10l · STATE
**Phase 3 is DONE.** `sc.s1actors` + `sc.s1drive` + `s1_action_run.m` + `s1_action_shots.m`.
Five action stills in `matlab/renders/s1act_*.png`, every one looked at, and three rounds of
fixes came out of looking at them: the ego's own bonnet filling the driver's-eye frames, the
wrong-side motorcycle absent from its own shot, and both clearance shots taken 4.45 s early.

Every assertion the run makes, and all of them pass:
carriageway 7.000 m · shoulder 1.200 m · zebu inside REF-04's ranges · stride x cadence =
1.2040 m/s to 0.5 mm/s · cow's final e to 1 mm · cow motionless afterwards to 1 um ·
her footprint within 30 mm of the arithmetic's assumption · **separation from every scripted
actor > 0** · clearance >= 0.90 m each side · no NaN in any logged pose.

**Phase 4 next:** the live gap arithmetic on the HUD, the defensive stand-in beside us
(REF-17 s8 - the documented baseline failure PLUS a stand-in labelled as ours, never as
MathWorks'), `map/ego_S1.csv` in the shared frame, and the film. Budget **8.5 min per film
pass** (s9b) and remember `advance()` ends with the last trajectory (s10f).

---

## 11 · PHASE 4 — THE RESULT, AND FOUR MORE THINGS THE MEASUREMENT CAUGHT

`sc.s1gap` is the live gap arithmetic; `sc.s1defensive` is the stand-in; `s1_result_run.m`
runs both drivers, measures, and writes the CSV; `s1_hud_check.m` proves the instrument strip
on stills; `s1_film.m` makes the MP4.

### 11a · THE GAP IS MEASURED EVERY STEP, NOT COMPUTED ONCE
The Phase 3 arithmetic was a constant worked out at the top of a script. `sc.s1gap` re-measures
it from wherever the obstacle actually is, every step, projecting each actor's band onto the road
normal using **its own yaw and its own asserted mesh dimensions** - which is the machinery that
caught the broadside cow in Phase 3.

**BUG: an obstacle you are level with stopped being an obstacle.** The first version skipped
anything with `range < 0`, so the cow dropped out of the calculation the instant the ego drew
alongside and the HUD read **free = 7.00 m — the whole carriageway — at exactly the moment the
number matters most.** Anything still overlapping longitudinally now stays in, and level-with
sorts first. At the pass it reads **free 3.83 m, margin 0.965 m**, which is what Phase 3 designed.

### 11b · A NUMBER THAT LOOKED LIKE A FAILURE AND WAS NOT
The measured margin dips to **0.588 m**, under the 0.90 m SPEC requires, and the first assertion
fired on it. It is right and the assertion was wrong. It happens at **t = 22.50 s while the cow
is still turning** - broadside she genuinely occupies more of the road - and the ego is **22 m
back and stopped**. What has to hold is the clearance from the instant the planner **commits**,
because that is the width it actually drives through. From COMMIT onward: **0.965-2.550 m.**
**Do not loosen an assertion until you understand the number that tripped it.**

### 11c · THE SAME CLAMPED-STOP TRAP, A SECOND TIME
`sc.s1defensive` computed `stopAt = max(0.5, d - 4.0)`, so it commanded
`sqrt(2 x 2.5 x 0.5) = 1.58 m/s` forever and **never actually stopped** - it drove straight past
the cow to 460 m. This is the identical bug that `sc.s1drive`'s `SLOWING` state had in Phase 3.
A floor on a stopping distance is a floor on the commanded speed. **Command a real zero.**

### 11d · THE HUD WAS ASSERTING A NUMBER THE BACKUP DOES NOT HAVE
`sc.hud` hardcoded the row and the chart title `h = lambda - beta` - the planner's safety
barrier. **The placeholder driver does not compute one**, and putting any value under that label
would be inventing a result. The chart is now named by the caller: the backup shows the
clearance it **measured**, against a red line at the 0.90 m requirement. When Stream D's planner
takes the seat it passes its real `h` and the label changes with it.

Also fixed: **the note and the state disagreed on transition frames.** Each case set its note and
*then* decided whether to transition, so a still captured at exactly the transition step - which
is what `find(State=="ABORT",1)` returns - read **"ABORT / probing - no response"**. One frame in
a film is invisible; in a deck it is a wrong caption.

### 11e · THE RESULT
| | |
|---|---|
| **defensive stand-in (OURS, labelled)** | **STOPPED at t=22.90 s, 4.0 m short of her, still stopped at t=62.0 s. Travelled 271 m and never passed her.** |
| **ours** | **460 m, past her at 8.0 km/h with 0.965 m each side** |
| MathWorks' shipped planner | cannot run on this map at all (0/120 candidates, t=19.7 s) |

The defensive rule is **not tuned to lose**. It is the textbook one - *"keep your lane; if the
lane ahead is blocked, stop and wait for it to clear"* - which is correct and safe. On a road with
a cow standing in it, the wait never ends, because a cow never clears. **Structural, not tuned.**

`map/ego_S1.csv`: **1,240 rows, 61.95 s, 460.0 m**, columns `time,x,y,heading,speed`, in the
**OSM-metric frame** - the shared one - so the Blender film can be driven along what the planner
actually did.

---

## 12 · BLENDER-AUTHORED ASSETS — THE IMPORT PATH, USED AT LAST

Aditya's call, 5 Sep: build the assets in Blender and import them, rather than composing
everything from primitives. **REF-17 §2 had recorded that this path works and then declined it,
because "downloaded assets carry licence conditions this project cannot verify."** That objection
does not apply to assets we author, and for the one third-party asset the licence is now verified
and written down. `matlab/assets/` holds the meshes and `assets/ATTRIBUTION.md` the obligations.

### 12a · WHAT DOES NOT TRANSFER, AND IT IS THE CENTRAL CONSTRAINT
**REF-10 §0's whole answer to the leaf problem — "a leaf is not a mesh, a whole branch of leaves
is ONE ALPHA CARD" — does not survive the trip.** MATLAB patches have no alpha textures. A card is
a flat quad with nothing on it, and it vanishes edge-on.

Measured, not assumed: a canopy built from **150 fronds at 0.17 m** across a 6 m crown rendered as
**confetti** — bare poles with green flakes floating round them, plainly worse than the crude blobs
it replaced. A 6 m crown needs **volume**, and alpha cards are how Blender fakes volume for free.

**The MATLAB-appropriate synthesis:** let Sapling place the leaves — it carries the real
inverse-conical distribution — then **cluster those leaf positions and put MASS at each centroid.**
22 clumps sized from each cluster's own spread. Real distribution, real volume, 2,088 tris.

### 12b · FOUR THINGS I GOT WRONG BY NOT READING THE METHOD
The tutorial notes were already on disk. I grepped REF-10 and REF-11 for keywords instead of
reading them, and paid for it four times:
1. **`prune=False`.** REF-10 §2: *"THE PRUNING TAB IS REF-06'S CONSTRAINT MECHANISM, ALREADY
   BUILT."* Prune Ratio and Prune Width are the envelope the crown may fill — the whole
   eight-causes system from REF-06, and I had it switched off.
2. **Ignored that `Leaf Object` takes a custom mesh**, so Sapling will distribute foliage properly
   instead of my hand-placed blobs.
3. **One grass layer, not several.** REF-11 §2: *"EACH LAYER GETS ITS OWN PARTICLE SYSTEM."*
   The layer that actually matters was missing — **doob, 0.05-0.15 m** (REF-04 §8), the mat that
   stops a verge reading as bare dirt with spikes stuck in it.
4. **No root-to-tip gradient.** REF-06 §3 says a canopy is *"dark and closed at the base, lighter
   at the top"*; REF-11 §3 says the same of a blade. One flat colour per instance cannot say it.
   `sc.scene/instances` now takes a **`Tip`** colour and blends each face by its own height in the
   unit mesh — flat shading still, so it costs nothing.

### 12c · TRAPS PAID FOR IN THE ASSET PIPELINE
16. **Decimating a beveled curve destroys the trunk.** Ratio 0.075 collapsed the lower trunk away
    entirely: a 12.29 m tree became 9.35 m of geometry and **every tree would have floated 2.94 m
    off the ground**. `curveRes` and `bevelRes` are the polycount dials — turn them down at
    generation and leave the geometry intact. 736 tris natively, base at exactly z = 0.000.
17. **Splitting the tree list for LOD silently removed every shadow inside the detail radius** —
    i.e. exactly the ones falling on the road in front of the camera. The dapple vanished and
    nothing failed. Shadows are cast from the full list, before the split.
18. **The Blender viewport misleads about seated geometry.** An untextured grey blob intersecting
    a brown body reads as a detached balloon; in MATLAB, where the whole actor is one colour, the
    same geometry merges into a hump. **Judge an asset in the renderer that will ship it.**
19. **Probe the midline, not the slice maximum.** Placing the zebu's hump off `max(z)` over a
    15 cm band put it on the **mid-back**, and the "neck underside" it found was the **chest** —
    so the dewlap came out as a goitre under the jaw. Tight 8 cm slices restricted to |y| < 0.06
    give the true back ridge: withers at x = 0.50, z = 1.250, body narrowing to 0.189 half-width.
20. **`bpy.context.active_object` is None over the MCP bridge.** Sapling creates the object and
    leaves it unselected, so `bpy.context.view_layer.objects.active = ob` is required before any
    `bpy.ops` that acts on a selection. Also: GLTF imports arrive **parented with a scale on the
    parent**, so `transform_apply` alone leaves mesh coordinates 2x the object's dimensions -
    `parent_clear(CLEAR_KEEP_TRANSFORM)` first.

### 12d · THE ASSETS, AND WHAT GATES THEM
| asset | tris | origin | gate |
|---|---|---|---|
| `neem_branches` + `neem_foliage` | 856 + 1232 | ours: Sapling with the REF-06 numbers (0.707 taper via ratioPower, split angle 30 ± 15, prune envelope), canopy clustered onto Sapling's own leaf positions | crown starts 37 % up the tree - REF-06 says branches at 2-5 m |
| `zebu` | 2,696 | **third party, CC BY** - see ATTRIBUTION.md - with hump and dewlap added | **2.050 × 0.640 × 1.460 exactly**, feet at z = 0, and REF-04's ranges still assert |
| `grass_tuft` / `doob_patch` / `kans_clump` | 84 / 128 / 189 | ours | inside REF-04 §8's layer heights |

**LOD is mandatory:** 2,088 tris x 2,200 trees is 4.6 M. The authored neem draws inside
`opts.Detail` (48 m) and the primitive carries the mass behind it - about **120 authored against
1,280 primitive** in a driver's-eye frame. Stills went from ~28 s to ~26-92 s.


---

## 13 · THE MEASURED-COLOUR PASS — APPLIED TO THE CODE, **NOT YET RENDERED**

**5 Sep, after Aditya said "Don't skim. Read every single thing."** REF-13 had never been
opened. It measures **his own 43 photographs**, and it contradicted three things I had guessed:

| | I had built | REF-13 measured |
|---|---|---|
| sky zenith | 44.7 % saturation | **23.5 %**, RGB 146.4/171.5/191.4, hue ~204 deg (plains, not 213 alpine) |
| sky horizon | 8.4 % | **20.3 %** — *"the gradient is the thing, not the average"* |
| vegetation | 51.6 % — **alpine** | **plains 92.3/116.1/95.0, ~31 %** — *"a saturated alpine green in our world would read as wrong immediately"* |

**Changes applied to `sc.scene` and `sc.s1render`:**
1. Sky rebuilt on the measured zenith/horizon values.
2. Every green rebuilt around the measured plains value (`PLAINS = [0.362 0.455 0.373]`).
3. **Two-tone forest floor** (REF-04 §10): near-black humus in hollows, pale tan on ridges,
   masked by noise so the boundary is a gradient and never a line.
4. **The treeline is closed from the bottom** (REF-06 §3, REF-13 §7): far crowns ran 0.38h-1.02h,
   so daylight showed under the whole stand and the mass read as a plantation of poles.
   They now start at 0.13h.
5. **Haze collapses LOCAL CONTRAST as well as saturation** (REF-13 §5, 43 → 21): the per-tree
   colour variation is compressed with distance, not only the hue.
6. **Colour varies WITHIN a layer, not only between layers** (REF-13 §7) — the per-tuft spread
   in the grass scatter is deliberately wide.

**⚠ NONE OF THIS HAS BEEN RENDERED. The verification run was killed before it finished.**
The next session must run `s1_world_shots.m`, LOOK at the five stills, and fix what is wrong
before trusting any of it. Every previous visual change in this project was wrong in some way
on the first render.

**STILL OUTSTANDING from the same reading, not yet applied:**
- **REF-11 §5 clumping.** The scatter is still a uniform spray. The note is explicit: feed a
  **noise texture into DENSITY and into SCALE** — *"the noise texture allows you to form these
  really organic and realistic clumps of plants, just like in real life"* — and that is also the
  mechanism for S1's "clustered, never uniform" and REF-04 §6's crowded-and-empty rule.
- **REF-04 §7 canopy interlock:** crowns merge below 10 m spacing and a crowded tree grows
  **elongated along the row and narrower across it**; build target **8-10 m spacing, ~62 %
  measured cover, with real holes in it.** Our spacing has never been measured against this.
- **REF-06 §1's eight constraint causes.** Sapling's Pruning tab is now on, but only one
  envelope is used. The eight causes (wire cut, road cut, wall squeeze, neighbour crowding,
  fodder lopping, vine smothering, dieback, free-standing) are still not applied per-tree,
  and REF-06 sets a hard rule: **no more than 1 in 6 trees may be the round free-standing form.**


---

## 14 · THE SPECULAR BUG — one line that had been wrong since Phase 1

**`material(o.Ax,'dull')` ONLY TOUCHES OBJECTS THAT ALREADY EXIST.** It is called in the
`sc.scene` constructor, where there is no geometry yet, so **it has never done anything**, and
every surface created afterwards silently took MATLAB's default **`SpecularStrength` of 0.9**.

The ground was therefore one enormous specular highlight. An overhead S2 shot came back as a
flat blue-green blur with a roundabout floating in it, and it looked exactly like broken haze —
I spent two edits tuning haze that was not the problem. **The test that found it was rendering
a bare ground plane with the sky, the haze and the two-tone all switched OFF and looking at
what was left.** REF-11 §3 states the physical rule outright: *"Roughness UP, Specular DOWN —
grass should not reflect much."*

Every lit surface now sets `SpecularStrength` explicitly. **When a render looks wrong, strip it
to one element rather than adjusting the element you suspect.**

---

## 15 · PHASE 5 — S2, THE CHOWK, AND IT IS A GYRATORY

**The written script and my own measurement agree, and they disagree with `SPEC.md`.**
`S2-THE-CHOWK.md` §0 concludes *"this is not two roads crossing. It is a gyratory"*, and REF-17
§5 measured the same thing independently: six road-ends, four tertiary arms in **two
near-parallel pairs**. `SPEC.md` had said "a designed 4-arm chowk... four arms at 90°", which
was the more cautious call and the weaker one. **S2 is now built at the real bearings — 46, 62,
232, 237, every one within 1° of the map — so S2 carries a real-map claim of its own.**
The island remains authored; there is none in the OSM data.

**IRC 65:2017 Table 6.2 is asserted as a SET**, because the three numbers are a pairing and not
three free choices: island 24 m + 2 × carriageway 8 m = inscribed circle 40 m. Weaving length
comes out at 47 m against a 30 m minimum at 30 km/h.

### 15a · THE ARMS ARE 5 AND 16 DEGREES APART, SO A VERGE LANDS ON THE NEXT ARM'S TARMAC
The first render put **46 fence posts and 315 grass tufts on drivable carriageway** — solid
obstacles on a road the planner drives. Nothing may now be planted without `onAnyRoad` clearing
it against every arm and the ring. **Found by looking at the approach shot, not by an assert.**

---

## 16 · PHASE 6 — THE S2 ACTION, AND THE NEGOTIATION THAT S1 CANNOT TEST

| | measured | written |
|---|---|---|
| the circulating auto's lift | **1.80 km/h** | 1.8 |
| PROBE begins | **6.40 s** | 6.0 |
| COMMIT, on reading that lift | **8.05 s** | 8.3 |
| closest approach, any actor | **0.930 m** | — |
| the parked Tata Ace leaves | **2.90 m** | 2.9 |
| `map/ego_S2.csv` | 960 rows, 47.95 s | — |

**The lift is measured back off the recorded poses, not taken from the script**, so the number
the driver reads is the number the actor actually did.

### 16a · FIVE FAULTS, EVERY ONE CAUGHT BY AN ASSERT OR THE BEAT TABLE
1. **`smoothTrajectory` rejects ANY speed change on a densely sampled arc.** Swept: a flat
   speed always builds; a ramp fails at 46 and 20 waypoints and only builds at 12, where the
   chord error is 0.31 m on a 16 m radius and the ring visibly becomes a polygon. Sweeping
   jerk at full resolution: **3 and 4 fail, 5 is the threshold**, and 5 holds the chord error
   at 0.019 m. A throttle lift-off is a brisk event, so 5 m/s³ is honest.
2. **Actors placed by start angle put the auto's lift-off BEFORE the ego arrived** — so the
   driver read a yield it had not asked for and **the PROBE state never executed at all**.
   Every circulating actor is now placed by *when it passes the ego's entry*, solved from
   `v·t` of arc lead.
3. **The bus finished its trajectory and PARKED on the circulating carriageway**, exactly where
   the ego later drove — a 3.33 m overlap. An actor holds its final pose when its trajectory
   ends (§10f). Its path now continues out along the exit arm and off the scene.
4. **The ring line's sign was inverted.** Positive lateral is LEFT of travel, and clockwise
   round an island that is *outward*: +2.60 put the ego at radius 18.59 m, hard against the
   outer edge where the wrong-way rider passes, and it grazed by **7 mm**. Measured, −2.60
   gives 13.39 m — the written *"1.4 m off the island kerb"*. **Verified by measuring, not by
   deriving**, and now asserted.
5. **The ego cannot start at the far end of the arm.** The written script has it at the
   give-way line at t=5.2 s, which at 26 km/h is 37.6 m of approach, not the 94 m the arm
   provides. Starting at the end put every beat 6 s late.

### 16b · A WRITTEN NUMBER THAT ONLY REPRODUCES ON THE RIGHT READING
*"A parked Tata Ace narrows the lane to 2.9 m."* Parked fully on the tarmac it leaves **5.25 m**
of a 7.0 m carriageway, and no placement of a 1.5 m vehicle makes that 2.9. The sentence is
about **one direction's 3.5 m lane**, and it needs the Ace to intrude **0.60 m** into it —
straddling the edge with 0.90 m of its width still on the verge, which is how an Ace actually
parks. Read that way it reproduces exactly. **When a written number will not close, re-read
the sentence before adjusting the geometry.**

### 16c · WHERE OURS STILL DIFFERS FROM THE WRITTEN TIMELINE
HOLD lands at 10.15 s against a written 14.6, and EXIT at 18.30 against 24.8. Ours is a 40 m
inscribed circle at IRC's 30 km/h design speed; the written beats imply a longer time on the
ring than that geometry takes. **Reported, not tuned away.** The 48 s total is unchanged.

---

## 16d · THE FILM NO LONGER FITS IN MEMORY AT FULL DETAIL

**This is an 8 GB machine, and the Blender-authored assets changed the arithmetic.** An
authored neem is **1,604 triangles** against the primitive's ~117, and a driver's-eye frame
holds about 140 of them plus a thousand primitives, grass, doob and scrub. The first film
attempt after the assets went in was **killed by the system partway through, leaving a
truncated 28 MB MP4.**

Measured at the time of the kill: **0.7 GB free of 8 GB**, with MATLAB itself holding 0.96 GB.
**Blender was not the cause** — it did not appear in the process list at all, which is worth
recording because it was my first assumption and it was wrong.

**The fix costs nothing a chase camera can see:** for the FILM only, the detail radius drops
from 48 m to 28 m and the refocus distance rises from 45 m to 70 m, so fewer authored trees are
resident and the world is rebuilt less often. **The stills still render at full detail** — it is
only the 1,486-frame loop that cannot afford it.

**AND THE REAL BUG WAS NOT MEMORY AT ALL — IT WAS AN ORPHANED SHADOW PER FRAME.**
Instrumenting the film loop over 400 frames showed **RSS flat at 584-662 MB with no growth**,
so there was no leak in the sense I had assumed. But the graphics **object count grew by exactly
+1 per frame**. `scene/mesh` creates the actor's fake shadow as a second patch and returned only
the mesh handle, so every film loop - which deletes what `mesh` returns each frame - left the
shadow behind. A 1,486-frame film ends with thousands of orphaned patches stacked on the road.
`mesh` now returns **both** handles; measured after the fix: **+2 objects over 60 frames**
(the live frame), down from +60.

**Two wrong assumptions on the way, both worth recording.** I blamed Blender for the memory -
it was not in the process list at all, and holds 0.04 GB. Then I blamed a leak - there was none.
Total process RSS on this machine is **3.7 GB of 8 GB**; it is simply a tight machine, and the
harness stops background work when it runs short.

**And one self-inflicted wound while fixing it:** `clear poses tS OBS` freed the very array the
film reads every frame, and the run died at line 49 with *"Unrecognized function or variable
'poses'"*. Only `OBS` is genuinely dead by then.

---

## 17 · PHASE 7 — HANDOVER

`matlab/README.md` is written: how to run it, the two results side by side, what is real and
what is ours, the file map, and the instruction that outranks all of it — **render it and look
at it.**

**PHASES 1-7 ARE COMPLETE.** Both scenarios build, assert, render, film and export their
trajectories in the shared frame.

**THE THREE OUTSTANDING ITEMS ARE NOW CLOSED. §13 and the first draft of §17 are stale
on all three; this section supersedes them.**

### 17a · REF-11 §5 CLUMPING — DONE
The tree scatter was `rand` in station and `rand^1.6` in offset: an even wash with no
clumps and no real holes, which is precisely REF-04 §6's *"uniform spread is the tell"*.
It now feeds a noise field into **density AND scale**, as REF-11 §5 specifies — three
incommensurate sines in (s,e), so there is no grid and no findable period, and the same
field drives both, which is what makes a clump read as a thicket of big trees rather
than as more small ones. The grass layers use the same field.

### 17b · REF-06 §1's EIGHT CAUSES — DONE, WITH TWO DELIBERATELY ABSENT
Six forms are built and applied by what is actually next to each tree: road cut,
neighbour crowding, fodder lopping (clustered at the village end, because S1 says people
cut fodder *near settlements*), vine smothering, dieback, and free-standing.
**The 1-in-6 cap on the round free-standing form is asserted**, and only trees with no
neighbour inside 15 m are eligible for it.
**Wire cut and wall squeeze are absent on purpose:** they need an electricity run and a
building within a crown's width, and S1's forest stretch has neither. Inventing them
would be decoration pretending to be causation — REF-06 §0's exact correction.

### 17c · REF-04 §7 CANOPY INTERLOCK — MEASURED, AND IT FOUND A REAL MISS
Measured cover over the carriageway was **0.7 %** against S1's written **38 %**, and the
cause was a drawn-versus-modelled split of the same family as the confetti canopy and
the widened thicket: **the crown offset lived only in `sc.s1render`, so the world did not
know where its own crowns were.** The offset now lives in `sc.s1world` (columns 10-11)
and both the renderer and the measurement read it.

**Two REF statements pull opposite ways and both are true — they are about different
heights.** REF-06 §1 cause 2: *"the crown stops at the carriageway edge, crown is a
half-tree."* REF-06 §4: *"crowns are pushed out over the road."* A roadside tree is cut
vertically below vehicle clearance — buses and loaded trolleys prune it — and leans out
above it, where nothing touches it and the light is. Modelling the cause produced the
shape, which is REF-06 §0's instruction.

Two numbers, and the corridor was the upstream cause:
- **`CorridorHalf` was 9.5 m**, leaving a 6 m verge — a mown park edge. REF-06 §4:
  *"verge grass runs 2-3 m and then the tree mass starts — no transition."* **Now 6.0 m**,
  which puts the first trunk 2.5 m beyond the carriageway edge.
- **The lean magnitude is SOLVED, not chosen**, the same method as the thicket radius.
  REF-06 gives no metres for a lean; the sourced number is on the other side. Bisected
  until measured open-country cover equals the written 38 %: **lean = 0.18 × crown
  radius, cover 38 % open.**

**TWO DOCUMENTS DISAGREE AND S1 WINS.** REF-04 §7's general build target is *"8-10 m
spacing, ~62 % cover"*; S1's own script says 38 %. Rule 1 — the scenario scripts ARE the
specification — so the scenario-specific number governs its own scenario. 62 % is
reachable here and looks defensible until you check which document is talking about this
road.

**AND THE 8-10 m SPACING TARGET IS NOT APPLIED, DELIBERATELY.** Ours measures **2.23 m
median, 99 % below 10 m.** REF-04 §7's spacing is for an **avenue** — neem planted along
a road. **S1 is a forest**, and REF-06 §3 describes exactly that: *"a treeline is closed
at the bottom; from ~1 m up it is a solid dark wall — you do not see through it and you
do not see individual trunks."* A 2 m spacing is what a forest is. Forcing 8-10 m would
have hit a number and destroyed the scenario. **Recorded rather than silently skipped.**

### 17d · WHAT IS STILL NOT DONE
- **The village end reaches 40 % cover, not the written 55 %.** It is asserted only for
  DIRECTION (it must be denser than the open, and is). The two written facts fight each
  other: S1 puts fodder lopping near the settlement, and a lopped tree has a small tight
  crown, which thins cover exactly where cover is supposed to rise. Reported, not tuned.
- **THE TWO LOD LEVELS DISAGREE ON CROWN WIDTH BY 2.04x, MEASURED.** The authored neem's
  foliage is **0.418 x its height** (4.60 m across at h = 11 m); the primitive crown is
  drawn from `cr`, which `s1world` draws independently of height and which comes out at
  **0.852 x height** — twice as wide. Invisible from the driver's seat, where haze covers
  the swap, but plain in the steep overhead corridor shot: the near stand reads as small
  detailed trees and the far stand as big blobs. **The fix is to derive `cr` from height
  using the authored tree's own proportion**, so the swap is invisible and one number
  governs both. Not applied: it changes the world, and every still and both films had
  just been rebuilt on the current one. **It affects no measured claim** — cover is
  computed from the same `cr` the far LOD draws.
- **S2 has no HUD stills** equivalent to `s1hud_*`; its HUD exists only in the film.
- The written S1 62-second timeline **does not close** (§10e) and ours is reported
  against it with the delta shown.
- **A rendered-pixel check is worth keeping:** canopy measures **RGB 84/107/81, sat
  25.9 %** against REF-13 §7's measured plains green 92/116/95 at 31 %. Within 8 points
  per channel. It *looks* paler than that in a wide shot, and the eye is wrong — the
  pallor is haze on the distant stand, not the albedo.

---

## 18 · A PROBE THAT MEASURED THE WRONG THING, AND MANUFACTURED THREE DEFECTS

**5 Sep, later session.** `s1_forest_probe.m` was written to close §13's outstanding
items and then **never run** — it did not even parse. Fixing and running it produced a
report that looked like three serious findings and was three bugs in the probe.

### 18a · IT DID NOT PARSE, WHICH IS WHY IT SURVIVED REVIEW
```
'a' ...
'b'          % <- syntax error inside a call
['a' ... 'b']  % <- what MATLAB requires
```
A continued string inside `fprintf(...)` needs **brackets**. The rest of the file used
the bracketed form correctly, so the error was invisible to reading.
**A probe that has never been executed is not a probe. It is a plan for one.**

### 18b · THE THREE "DEFECTS", ALL MINE
| reported | actual | cause |
|---|---|---|
| cover **25.6 %** against s1world's own 38 % — *"one of them is a lie"* | **38.4 %** vs written 38 % | the probe measured cover at the **TRUNK** positions. `s1world` measures at the **CROWN** positions, after the roadside lean it solves by bisection (columns 10-11, REF-06 §2 phototropism). Ignoring the lean undercounts every roadside tree — exactly the 12-point gap |
| vine smothering **0**, dieback **0** | **43 vine, 50 dieback** | the probe carried its own hard-coded list of **eight** form names against a world that has **six**, so every row was mislabelled and two real causes were read off as zero |
| spacing 2.93 m against 8-10 m | the number is right, the **target** is wrong | REF-04 §7's 8-10 m is an **avenue** spec; SPEC builds S1 as forest (§17c reached this independently) |

**The rule this leaves behind, and it is the expensive one:**
**a probe that measures a different quantity from the thing it is checking is worse
than no probe.** It manufactures defects, and it sends someone to fix a file that was
never wrong. Both fixes are now structural rather than remembered — the probe reads
crown offsets from the world, and takes its form names from `W.FormNames` instead of a
local copy that goes stale the moment the cause set changes.

### 18c · THE QUALITY PASS — APPLIED, **NOT YET RENDERED**
Same status discipline as §13. Everything below is in the code and **none of it has
been looked at yet**; every visual change in this project has been wrong in some way on
the first render.

**`sc.scene`** — `Grain`, a per-FACE tonal noise on `instances()` and `mesh()`, hashed
from each face's own world centroid so it is deterministic and cannot crawl between
film frames. **MATLAB has no textures, so intra-surface variation is the only texture
available**, and one flat colour per crown is what made the canopy read as poster art.

**`sc.s1render`**
- **Lumpy crowns, at zero cost.** A crown was a smooth ellipsoid; REF-06 §3 measured
  the real thing — *"crowns merge into one continuous green mass, BUT THE TOP EDGE
  STILL READS AS SEPARATE LUMPS. Never a smooth hedge silhouette."* Two or three offset
  spheres per tree would triple the geometry on a 1,300-tree stand, so the **unit
  sphere's radius** is perturbed instead: same vertex and face count, one mesh, lumps
  in the silhouette. Each crown is then **spun by its own hash** — using the road
  bearing alone would line every lump up along the row.
- **The scrub lathe is lumped ABOVE `hFull` only.** Below it the silhouette is the
  promise the 2-D sight model relies on (§7a), so it is untouched; the flat cap is the
  giveaway and the cap is what moves.
- **The ragged crumbling edge**, which S1 specifies in metres and nobody built:
  *"Edges crumble into dirt over a ragged 100-300 mm band. No kerb."* The carriageway
  met the shoulder along a dead-straight line for 610 m. Drawn **under** the paint, so
  the edge line still reads over it.

**`sc.s2render`** — the chowk had never had the treatment S1 already paid for:
- the statue was **four cuboids** (square shoulders, a cube head) — rebuilt from round
  stock: a lathed dhoti and torso, spherical head and shoulders, one raised arm;
- the backdrop was **lollipops** — bare trunks, pom-pom crowns, daylight under the whole
  stand, i.e. REF-06 §3's closed treeline ignored a second time. Now closed from below
  and **clumped** rather than sprayed in an even ring;
- **no shadows at all**, which was most of why S2 read flat next to S1;
- island grass ~3× denser, and its tip pulled back from `PLAINS*1.55`, which clipped to
  white and read as pale spikes;
- the far annulus was tinted toward **dirt** while the near ground is **grass**, so they
  met in a visible step, and the horizon band was **paler than the wood in front of
  it** — which inverts REF-13 §5;
- the **two shrubs** and the municipal signboard S2 counts were simply absent.

**New: `s2_hud_check.m`** — the S2 HUD existed only inside the film, so there was no
still for a slide and no way to check the strip without paying for a film pass. It
reuses `s2_film.m`'s caption **verbatim**: a still and a film that caption the same
instant differently is how a deck contradicts itself.
**New: `build_all.m`** — the ten steps in dependency order, films last, one summary
table, and a missing step is REPORTED rather than skipped in silence.

### 18d · TWO SESSIONS, ONE REPO — AND IT CORRUPTED A FILM
Another chat was rendering while this one edited. **`s1render.m` was edited at 11:23
while `s1_film` was still writing** — the file was 241 MB and read as finished, and it
ran on to 267 MB. That film therefore has a **discontinuity partway through**, where
crowns become lumpy and the road edge ragged mid-scene. It is superseded by the
re-render and **must not be shown**.
**The rule: no edit to anything under `+sc/` while any MATLAB batch is running.**
Check `pgrep -f "MATLAB.*batch"` first. A file size that has stopped growing is not
evidence that a render has finished.

---

## 19 · THE QUALITY PASS, RENDERED AT LAST — AND EVERY VISUAL CHANGE IN §18c WAS WRONG

**5 Sep, later session.** §13 and §18c both ended with the same warning: *"none of this has
been looked at yet; every visual change in this project has been wrong in some way on the
first render."* It was applied a third time and it was right a third time. **Nine defects,
all found by rendering and looking, none by an assertion — and every assertion passed
throughout.**

### 19a · `pgrep -f "MATLAB.*batch"` IS STILL WRONG, AND SO IS `pgrep -f MATLAB_maca64`
§18d's fix was to check `pgrep -f MATLAB_maca64` instead. **It has the identical bug**, and
this session opened by finding five processes it had deadlocked. Any shell running
`until ! pgrep -f MATLAB_maca64; do sleep; done` has that string **in its own command line**,
so it matches itself and waits forever. Five orphaned shells from an earlier session were
still spinning, one of them holding a wait on a render that had finished long before.

**THE CHECK THAT ACTUALLY WORKS — match the executable, not the command line:**
```bash
ps -Ao pid,etime,comm | grep -i 'MATLAB_R2026a'      # blank = idle
```
`comm` is the executable path only. A grep or a shell **cannot** appear in it, so it cannot
self-match by construction, rather than by being careful about the pattern.

### 19b · A CLUMP WIDER THAN IT IS TALL IS A CYLINDER, AND NO RENDERER CAN FIX IT
The verge scrub rendered as **grain silos** — smooth-sided drums with crumpled caps, four in a
row on the right verge. The renderer had already spent two rounds trying to break that
silhouette with lobes and lumping, and could not, **because the shape below `hFull` is pinned
by the 2-D sight model** (§7a): pulling it in is BUG 1, pushing it out is BUG 2.

**The radius was never drawn against the height.** It ran to 2.30 m — a clump **4.60 m across**
— against a full-radius section about 2.0 m tall. **Aspect 2.3 : 1 wide, so the pinned part is
a machined cylinder by construction, whatever is drawn above it.** The cure had to be in
`s1world`, in the shape that gets *claimed*, not in the renderer. Radius capped, and the
aspect **asserted against the height the lathe actually draws** so a later edit cannot quietly
put the drums back.

**The same bug was live in two more places, both found by fixing the first:**
the S1 understorey wall (2.9 m tall, 6.9 m wide — a row of tanks), and the S2 backdrop.

### 19c · THE BASE/TOP GRADIENT WAS INVERTED, AND IT MEASURED
REF-06 §3 is quoted **twice** in `s1render` — *"dark and closed at the base, lighter at the
top"* — and `UNDER` had been pulled to `CROWN*0.44` for exactly that reason. **The near scrub
never got the same correction and sat at `CROWN*0.92`.** Measured, the verge undergrowth was
the **brightest vegetation in the frame**: scrub 123.2 against canopy 114.2.

| | before | after |
|---|---|---|
| forest floor | — | **67.7** |
| verge scrub | **123.2** | **83.4** |
| near canopy | 114.2 | **104.7** |

**Monotonic now, and it is the rule the file already knew.** A number quoted in a comment is
not a number that is being obeyed.

### 19d · A 16-METRE COLONNADE NOBODY HAD QUESTIONED
The understorey wall was drawn only outside `|e| > 22 m`. **The corridor edge is at 6.0 m**, so
trees from 6 to 22 m — *the whole of what the driver looks into* — carried bare trunks with
nothing under them, and the left stand rendered as a plantation of poles on a pale void.

The justification was REF-06 §4, *"trunks stay visible on isolated trees"*. **Ours are not
isolated: 2.23 m median spacing, 99 % below 10 m** (§17c), and REF-06 §3 governs that case —
*"you do not see individual trunks."* **The right citation, applied to the wrong situation.**

**AND THE FIX WAS CAUGHT BY AN ASSERT, CORRECTLY.** Closing the stand at 10.5 m fired
`s1rUnderReach`: the wall radius is derived from the crown and **reaches 8.9 m**, not the
~3.4 m I had assumed, so a mass at 10.5 m sat on the cow's sight line. Capping the radius
keeps the proof *and* closes the stand; pushing the distance back out would have restored the
colonnade to buy the proof. **The assert was right and the instinct to loosen it was wrong**
— §11b, a second time.

### 19e · THE SIGHT-LINE ASSERT MEASURED THE CLAIMED RADIUS, NOT THE DRAWN ONE
`s1rUnderReach` compared against the radius the world **claims** plus a guessed 1.0 m margin.
The lobes are drawn at offset + radius = **1.47 × that**. On the old 22 m threshold the gap was
covered by distance and nothing showed; after the stand closed it cleared the cow's line by
**0.68 m by luck**. It now computes the worst-case drawn reach from the same numbers the draw
uses — off the tree's stored signed `e`, so it costs no path lookups. **§18's rule, in a new
place: a check that measures a different quantity from the one that matters passes while the
geometry is wrong.**

**The proof is also not symmetric and the assert now says so.** The line to the cow lives
entirely at positive `e`, so right-side mass is safe **by sign** and only the left has to clear
by distance. One combined `min()` over both sides would fail on mass that cannot matter.

### 19f · A HEIGHT SCALE USED AS A RADIUS — 55 % OF THE S2 APPROACH SHOT WAS BLACK
**The worst single defect, and S2's most important still.** `sc.treeAsset` returns the neem
**unit-height**, so `T(:,4)` is a *scale factor* (8–14). `s2render` used it directly as a lathe
**radius**, drawing understorey masses **3–4× wider than the crowns above them**. One engulfed
the approach camera: a near-black octagon over 55 % of the frame.

**Measured off the asset — and REF-17 §17d wants this number too:**
`CrownR = 0.241 × height`, foliage starts at `0.360 × height`. Both are now **derived in
`sc.treeAsset` and asserted**, so no caller retypes them and no caller can confuse the two
quantities again.

**The placement guard had the same disease.** It cleared the trunk POSITION by a flat 6.5 m
while the mass drawn there reached far past it — REF-17 §7a BUG 2 and §15a's own
carriageway rule, both defeated by **checking a point instead of an extent**. The guard is now
extent-aware and shares one set of constants with the draw. **The clump trees never had the
guard at all.**

### 19g · TWO OVERCORRECTIONS, BOTH CAUGHT BY LOOKING, NEITHER BY A NUMBER
Worth recording because the intermediate states each looked plausible in code review:
1. **Scrub → cypress spires.** The lobe z-scale is multiplied *again* by the lathe's own 1.55,
   so 1.67 × hFull put tops at 5.3 m on a 3.4 m clump. Drums straight past bushes to conifers.
2. **S2 wall → dark boulders, then giant dark slabs.** Shrinking the radius made the backdrop
   lollipops again; tying height to radius then buried the trees in 19 m masses. **The radius
   was never the bug — the guard not knowing the radius was.** It resolved only once the mass
   was made *narrower than the crown* and *tall enough to overlap the foliage*, so the two read
   as one silhouette instead of a rock beside a tree.

**Both were fixed by rendering, looking, and changing one thing — which is the only loop that
has ever worked here.**

### 19h · WHAT I NEARLY "FIXED" AND SHOULD NOT HAVE
**The road is neutral grey on purpose.** REF-06 §6 says *"light warm grey, never black"*, and
the code overrules it with a measurement off **12 of Aditya's own dashcam frames of this road
class** (median 88.8/93.3/90.0, R−B = −1.2). I was about to warm it back up. **A comment that
cites its own measurement and explains why it overrules a REF is not a defect** — the §18b
trap, avoided this time only because the file said so in full. Its flatness (contrast 7.4) is a
real gap and is listed below; its hue is not.

Likewise the canopy's whole-frame saturation reads 4–5 points under REF-13's target **because
most of the frame is hazed distance**, and haze is *supposed* to collapse saturation (REF-13
§5). Measured on the **near** canopy it is within 2.5/255. **Sampling the wrong region
manufactures a defect exactly as measuring the wrong quantity does.**

### 19i · WHERE IT LANDED
| | measured |
|---|---|
| sky, top gap | **142.0/166.0/182.8, hue 204.7°** vs REF-13 plains 146.4/171.5/191.4 |
| near canopy | **90.6/116.1/82.9**, per-pixel sat **29.3 %** vs REF-13 92.3/116.1/95.0 at 31 % |
| base→top gradient | floor **67.7** → scrub **83.4** → canopy **104.7** — monotonic |
| S1 reveal | **44 m** (spec 42), thicket r = 3.48 m — unchanged by any of this |
| all S1/S2 asserts | pass |

**Crown blue was still 12 short after the hue swap** (the canopy had gone yellow-green) and is
corrected; that value has not been re-measured yet.

### 19j · STILL NOT DONE, AND HONESTLY
- **THE ROAD AND GROUND TEXTUREMAP IS NOT STARTED.** §12a's correction proved
  `surface` + `FaceColor','texturemap'` works, which makes a generated road image possible —
  wheel paths, aggregate, the patched potholes. It is **the largest available win** and the
  road still measures at contrast 7.4, i.e. flat.
- **`Grain` and the lumpiness amounts are still guesses.** Nobody has swept them against a
  measured target; they were set by eye and they are the kind of number this project has been
  wrong about every previous time.
- **The S1 LOD crown-width mismatch (§17d) is now fixable for free** — `TREE.CrownR` exists and
  is asserted, which is exactly the number that note asked for. Not applied.
- **The S2 island tufts still read as dead twigs** against the doob mat, and the trunk
  whitewash band (REF-06 §4) is deliberately unbuilt rather than faked by paling whole trunks.
- **Both films are stale and the S1 one is corrupt** (§18d). Neither has been re-rendered.

---

## 20 · PHASE 2 — THE EGO, AND SIX PARTS THAT WERE BUILT AND NEVER DREW A PIXEL

**5 Sep, evening session.** The car stopped being eight cuboids. `blend/vehicles/car.py`
builds it as 11 separate parts, `sc.carAsset` loads them into one mesh with a **per-face
part index**, `sc.meshes("car")` returns that, and `sc.carColours` colours **by part id**.
Nothing else changed: `s1_film`, `s1_hud_check`, `s1_action_shots`, `s2_film`,
`s2_hud_check` and `s2_action_shots` all call the same two functions unchanged.

**The S1 result is untouched and was re-run to prove it:** free width **3.830 m**, margin
**0.965 m each side**, past her at **8.00 km/h**, `map/ego_S1.csv` 1,240 rows. Every actor
number in this project comes from `dim`, never from mesh vertices - `sc.s1geom`, `sc.s1gap`
and the separation check all read `[~, d] = sc.meshes(...)` - so swapping the geometry
**cannot** move an arithmetic claim as long as `dim` still asserts. That is worth knowing
before the bus and the rest of the traffic go the same way.

### 20a · THE CAR WAS 1.808 m WIDE WITHOUT ITS MIRRORS, AGAINST A WRITTEN 1.700
The handover said the asset measured "exactly 3.990 x 1.900 x 1.500", and as a bounding
box it did. **Measured per part off the exported STL, three parts stood outside the body:**
the sills at **+-0.904** (57 mm proud), the door handles at **+-0.888**, and the tyres at
**+-0.862** - the last from a `+ 0.015` whose own comment read *"outer face flush with the
body side"*. So the car was **1.808 m** wide without its mirrors.

**This is not cosmetic, for the same reason the zebu's width was not** (s10a). SPEC and S1
both state *"ego 1.70 m, 1.90 m with mirrors"*, `sc.meshes` asserts the 1.70, and folding
the mirrors is a planner action worth exactly that 200 mm. The assert would have fired the
moment the asset was wired in. **Loosening it to 1.808 was the available shortcut and it
was the wrong one** - s11b and s19d, a third time.

**AND ONE UNIFORM SCALE CANNOT FIX IT, WHICH IS THE REAL FINDING.** 1.700 and 1.900 are two
independent load-bearing widths. The old normaliser scaled the full 1.906 m span to 1.900 and
left the body wherever it fell; it hit neither number. Normalisation is now **two-stage in y**:
scale so the **non-mirror** body is exactly 1.700, then slide the mirrors until the overall
is exactly 1.900. The stalk length is not a sourced dimension and the 1.900 is, so the stalk
absorbs the residual (measured: 3.0 mm) rather than the body being stretched to swallow it.
`car.py` now **asserts all four numbers itself** and fails, instead of printing its miss.

### 20b · POLYGONS ARE NOT TRIANGLES — 2,888, NOT 2,708
`car.py` reported `len(ob.data.polygons)`. The shell is lofted as **quads** and the loft caps
are 36-gons, and STL triangulates on export, so the file MATLAB reads holds **2,888** where
the script said 2,708. Both are now printed side by side. Not a defect - but the ego went
from 96 triangles to 2,888 and any film budget should carry the right number.

### 20c · SIX PARTS WERE BUILT, EXPORTED, ASSERTED — AND DREW NOTHING
`car.py` already carried the rule in capitals: *"EVERY DETAIL MUST PROTRUDE. The shell is a
closed opaque solid, so anything flush with it is simply invisible."* **It was then broken
six times in the same file.** Every one passed every assertion, because an assertion checks
a bounding box and burial does not change one.

| part | what it did | why |
|---|---|---|
| **windscreen** | the front view showed a car with **no windscreen** | typed as four fixed corners against a cabin that was later re-raked into a hatchback; the shell closed over it |
| **rims x4** | every wheel a **flat black disc** | the fix for the z-fighting chevron inset the rim 30 mm from the sidewall, putting its outer face **20 mm inside the tyre's closed cap** |
| **front bumper** | nothing | centred at 1.880 with half-length 0.08, so it ended at 1.960 - **30 mm inside the shell's own end cap at 1.990** |
| **rear bumper** | nothing | identical |
| **rear number plate** | did not exist | only the front one was built, and **the chase camera sits behind the ego for the whole of both films** |
| **sills** | the INVERSE - a **running board** slung between the wheels | a straight box cannot lie flush on a ROUNDED lofted section: at the rocker the corner radius pulls the body in to 0.824 and the sill sat at 0.846 |

**The rims are the instructive one. The cure for burial is not "less inset".** Three
concentric discs on one axle have to **step outward** - tyre 0.836, rim 0.845, hub 0.850 -
each proud of the last, none coincident with another, and none outside the 0.850 the body
is asserted to. A single number cannot satisfy "not coincident" and "not hidden" at once.

**The sills were deleted rather than repaired.** Pulling them in far enough to sit flush
buries them; leaving them out makes a side step no Indian hatchback has. The dark rocker
band they existed to provide is the **shell's own vertical shade** in `sc.carColours`, which
follows the real curved surface instead of floating outside it.

**And the glass is now built from the profile rather than against it.** `screen()` reads
`cab_prof`'s own numbers and offsets along the local normal, so it cannot be buried when the
cabin changes shape. Fixed coordinates could not survive one re-rake; reading the profile can.

### 20d · `sc.carColours` COLOURS BY PART, NOT BY GUESSED REGION
The old version recovered the parts geometrically - *glass is above z = 0.72 and inboard of
|y| = 0.82*, *a tyre is below 0.62 within 0.42 m of an axle*, *a mirror is |y| > 0.80 between
z 0.90 and 1.14*. **Those bands were exactly right for the primitive, because on eight
cuboids the regions WERE the parts.** On a lofted shell they are not: the glass band also
contains the door skin and the handles, the tyre band contains the wheel arches and the
sills, the mirror band contains the roof rails. The parts are separate files, so nothing has
to be inferred, and **a part index cannot drift when the model changes shape.**
The same applies to the body-width assert in `sc.meshes`, which excluded the mirrors as a
**z-band** - true of the primitive only because its mirrors were the sole geometry at that
height. It now excludes them **as a part**, and additionally asserts that the mirrors really
do span the 1.900, so the two numbers cannot become unrelated.

### 20e · `matlab/car_look.m` — AN ACTOR LOOP THAT COSTS 13 SECONDS, NOT FIVE MINUTES
The only loop that has ever worked here is render → LOOK → fix (s7, s19). For the WORLD it
costs 4-9 minutes, which is why `s1_look.m` exists; for an **actor** there was nothing, and
the car was being judged inside a full HUD still that spends its whole budget on 2,200 trees
the car is not. `car_look.m` renders one vehicle alone from the three views that decide a
vehicle - and the **rear three-quarter is first, because that is the chase camera's view and
the judges look at it for 110 seconds.** Three views, **13 s.**

**It also answers the question a still cannot: WHICH PART AM I LOOKING AT.** Run with
`PARTS=true` every part gets its own hue and a printed legend. **This paid for itself twice
in one session, in both directions:**
- it identified the running board as the **sills** (green) rather than an exhaust, and proved
  the rims drew **no pixels at all** - there was no rim hue anywhere in the frame;
- and it stopped a fix that was not needed. Two dark strips ran down each side of the cabin
  in the HUD still and looked like stray geometry. Coloured, they are the **roof rail**, the
  **B-pillar trim** and the **side glass standing proud of the cabin** - three real parts.
  **s19h, avoided this time by colouring rather than by reasoning.**

**MATLAB has no textures, so a defect and a deliberate part look identical.** That is the
whole argument for the parts diagnostic, and it is the same argument s19f paid for the hard
way when a height scale used as a radius filled 55 % of the S2 approach shot with black.

---

## 21 · PHASE 3 — THE BUS, AND THE SAME BURIAL BUG A SEVENTH TIME

**5 Sep, same session.** `sc.meshes("bus")` was **eight cuboids in one flat colour** - a
body, a roof slab and six wheel stubs - and in the S2 chowk it is the largest object in
frame after the island. It rendered as a **solid yellow box on legs**. It is now
`blend/vehicles/bus.py` → 14 parts → `sc.busAsset` → `sc.busColours`, at
**10.8000 x 2.6000 x 3.1000** asserted, base at z = 0, **3,312 triangles**.

### 21a · WHAT READS ON A BUS, IN ORDER, AND ALL FOUR ARE GEOMETRY
1. **The window band** - a long row of dark glass divided by pillars. Nothing else says
   "bus" so fast, and the primitive had none of it.
2. **The two-tone.** An Indian state bus is banded horizontally, never one colour. It is
   built as three lofts - skirt, waist rail, upper - so the livery is **geometry** and
   survives any change to the palette.
3. **The wheels**, which are what say "vehicle" rather than "shed".
4. **The destination board and the entrance.**

**And the seventh burial.** The window pillars were at 1.298 against glass at 1.300, so
they sat **2 mm inside it** and the whole band rendered as **one continuous black slab**.
They showed only at a grazing angle, off their own 30 mm thickness - which is why the
front three-quarter looked right and the profile did not. On a real body the pillar IS
the outermost surface and the glazing sits in it, so **the pillars now carry the 2.60**.
**That is six parts on the car and one on the bus, all built, exported, asserted, and
drawing nothing.** A bounding-box assertion cannot see burial, and neither can Blender's
viewport (s12c trap 18). Only the renderer that ships it can.

### 21b · NO MIRRORS, AND IT IS SAID OUT LOUD
A real bus has large ones. `sc.meshes` asserts **2.60 m over the body** (REF-04 s1) and
mirrors would break it, so they are absent. Recorded rather than silently widened,
because S2's clearances are measured off that box.

### 21c · `blend/vehicles/_veh.py` — THE SHARED KIT
Extracted when the bus needed the car's helpers. It holds the rounded section, the loft,
the profile reader, the profile-following screen, the **three stepped wheel discs**, and
the **normalise-and-assert**, with the four things that cost something to learn written
at the top. Five actors are still primitives - auto, motorcycle, tractor, trolley,
Tata Ace - and that is five more chances to retype the two-stage width normalisation
slightly differently. `sc.s1geom` is the record of what two sources for one number cost.
**`car.py` has NOT been moved onto the kit yet** - it works and is verified, and
refactoring a verified asset for tidiness while the bus was unproven was the wrong order.
The kit is proven now, so that move is available and is listed as outstanding.

### 21d · THE MATLAB SIDE, GENERALISED
`sc.partAsset(prefix, names)` does the loading, the part index and the integrity
assertions for any vehicle; `sc.carAsset` and `sc.busAsset` exist to own **one thing
each - the part ORDER**, which is the contract every per-face colour depends on.
`car_look.m` became **`veh_look.m`**, taking `VEH` and scaling its three camera
distances off the vehicle's own length, so a 10.8 m bus frames like a 3.99 m hatchback
instead of falling out of the picture.

### 21e · THE HUD WAS CUTTING THE EGO IN HALF, IN BOTH SCENARIOS
Not the car's fault and not found by looking for it. With `'Ahead', 13` the ego sits
**13.7 deg below the view axis against a 16.5 deg half-frame - 83 % of the way to the
bottom** - so the bumper, both rear wheels and half the number plate were behind the
instrument panel **in every HUD still and for the whole of both films**. A shorter
look-ahead steepens the view axis and pitches the subject up the frame; at **10** it
clears. Applied to `s1_hud_check`, `s1_film`, `s2_hud_check` and `s2_film` - and S2 was
**verified on `s2hud_hud_commit` before changing it**, not assumed from S1.
**Five files carried that same magic-number tuple.** They still do; one source for the
HUD chase geometry is outstanding.

---

## 22 · PHASE 5 — THE ROAD TEXTUREMAP, AND THE NUMBER THAT SAID IT WAS NOT THE BIG WIN

**5 Sep, same session.** `sc.roadTexture` + `sc.scene/carpet`, wired into `sc.s1render`
(the carriageway) and `sc.s2render` (four arms and the ring).

### 22a · THE MECHANISM WAS VERIFIED BEFORE ANYTHING WAS BUILT ON IT
s19j says *"s12a's correction proved `surface` + `FaceColor','texturemap'` works"*.
**That claim had never been executed** - it is a note about a note. Run:
- it **binds**, `CDataMapping` scaled, CData accepted at any size;
- **a 2 x 2 grid carrying a 512-wide image renders at luminance std 65.4.** So the
  IMAGE resolution genuinely beats the GRID resolution, which is the whole reason this
  is affordable: the ribbon can stay at 7 x 137 quads and the detail lives in a picture.
**s18a's rule, in a new place: a probe that has never been executed is not a probe.**

### 22b · THE ROAD IS NOT FLAT PAPER, AND THE CLAIM THAT IT IS RESTS ON AN UNCOMPARED NUMBER
s19j calls the road *"flat paper"* at local contrast 7.4 and **"the largest available
win"**. 7.4 was never compared to anything. **Measured, off Aditya's own 64 dashcam
frames - the same source s19h took the road's HUE from, which nobody had asked for its
CONTRAST:**

| pass | what it sampled | contrast | why it was wrong |
|---|---|---|---|
| 1 | a fixed lower-centre rectangle | **13.2** | the accepted crops were **verge and edge line**. Looked at, not assumed |
| 2 | the most desaturated of 20 candidate rectangles per frame | **8.0** | still holding guardrails, a bumper, a motorcycle wheel and lane markings |
| 3 | + markings, vehicles and shadow edges rejected | **6.1** (p25 4.6, p75 8.5) | 59 of 64 frames; contact sheet looked at |

**The real road of this class runs at local contrast 6.1 at matched pixels-per-metre.
Ours was 5.4. The gap is about ONE LEVEL, not a chasm.** Excluding the markings is not
a convenience: ours are separate measured geometry, so what a surface texture has to
represent is the road BETWEEN them.

**Each refinement lowered the number, which is the tell that the first one was
contamination and not signal** - REF-17 s18b, in the other direction. Pass 1 would have
sent someone to triple the amplitude of a texture that was already nearly right, and
the result would have looked like gravel.

**What the flat patch genuinely lacked was not contrast but STRUCTURE.** One `patch` in
one colour has no wheel paths, no streaking, no oil line and no patches at all, at any
contrast. That is what this buys, and it is a smaller win than advertised. **Phase 5's
GROUND half - the 1.2 m shoulders and the verge - has not been measured and may now be
the better half of it.**

### 22c · THE AMPLITUDE IS SOLVED, THE CHARACTER IS CHOSEN, AND THE FILE SAYS WHICH IS WHICH
`sc.roadTexture` returns a **multiplier around 1.0, asserted to 0.2 %**, so it *cannot*
move the tarmac grey that s19h measured and that deliberately overrules REF-06 s6. The
relative weights - aggregate, streaking, patchiness, wheel paths, oil line - set the
character and are stated as chosen. The **amount** is solved: the deviation field is
scaled until its coefficient of variation equals the measured **0.0561**.
Matching CoV rather than absolute contrast is the physical choice - the texture is an
ALBEDO variation, and our road renders at brightness 92 against the dashcam's 109, so
matching absolute levels would over-state the albedo. Rendered result: **near road 5.0
against a measured 6.1 (p25 4.6)**, i.e. exactly the measured CoV, and the residual is
the lighting and dirt the dashcam frames also carry.

### 22d · TWO THINGS THE RENDER CAUGHT THAT NO NUMBER DID
**BUG - A SIN-HASH ON A REGULAR LATTICE ALIASES INTO A VISIBLE CHEQUER.** The first
version hashed `sin(a*I + b*J)` per texel, the idiom the rest of the package uses for
per-face grain, with two incommensurate terms specifically to avoid banding. **It banded
anyway** - a diagonal chequer across the near foreground. A hash evaluated at scattered
world centroids is not the same problem as one evaluated at every cell of a
128 x 5600 grid. Replaced with `rng(seed)` + `rand`, **with the global stream saved and
restored** - just as deterministic, so the film cannot crawl, which was the only reason
to avoid `rand` here.

**BUG - `texturemap` MAGNIFIES NEAREST-NEIGHBOUR AND THERE IS NO FILTERING.** With the
chequer gone, the texel grid itself was visible: at 2 m from a 1.35 m eye each texel
covers several screen pixels, and any hard edge between neighbours is drawn as one.
No MATLAB surface property controls this, **so the cure has to be in the SOURCE** - the
aggregate is now band-limited to a ~2-texel cell and interpolated. Fine enough to read
as aggregate, correlated enough to have no edges.
**Both were invisible in the texture previewed as a flat image, and obvious the moment
it was on a surface under a camera.**

### 22e · S2 GETS IT TOO, AND THE RING IS DELIBERATELY ONE LANE
The four arms use a grid version of the same band helper. **The ring needs no helper at
all - an annulus is already a grid**, rows radius and columns theta.
**It is generated with `Lanes` 1 on purpose.** S2 turns on the circulating carriageway
carrying **no lane markings**; there are not two lanes to wear two pairs of wheel paths
into, there is one circulating stream and one broad worn band. Passing 2 would have
drawn a lane structure onto the single surface in the scenario whose whole point is
that it has none.
