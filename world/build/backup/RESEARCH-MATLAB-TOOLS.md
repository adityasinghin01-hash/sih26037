# RESEARCH — what MATLAB actually gives us for the two scenarios
**4 Sep 2026. Every line verified by RUNNING it on Aditya's Mac (R2026a Update 5, MACA64),
not by reading documentation.** REF-05 §7's rule: the 3 Sep toolchain entry was wrong because
it trusted docs over execution.

## THE HEADLINE — MATLAB IS THE RENDERER, NOT JUST THE SIMULATOR
| | per 1280×720 frame | a 62 s film at 24 fps |
|---|---|---|
| **Blender Cycles, `01_LIGHT.blend`, sky only, no geometry** | **> 760 s** (killed at 12 min 40 s) | **> 300 hours** |
| **MATLAB graphics, lit scene with 40 buildings** | **0.142 s** | **3.5 minutes** |
**~5,300× faster.** The film can be re-rendered on every iteration instead of being a one-shot.
This is the single fact that should shape the plan.

## INSTALLED (12 products, `ver`)
MATLAB · Simulink · Stateflow · **Automated Driving** · **Navigation** · **Sensor Fusion and
Tracking** · Computer Vision · Image Processing · Deep Learning · **Lidar** · **Mapping**

## PROVEN BY RUNNING — the tools the build will use
| Tool | Verified |
|---|---|
| `roadNetwork(sc,'OpenStreetMap',f)` | **425 segments, 59.9 km, 29.3 s** on `najibabad.osm` |
| `road(sc,centers,width)` | per-class carriageway width; 16/16 and 18/18 pieces accepted |
| `smoothTrajectory(actor,wp,speeds)` | jerk-limited motion, an **actor** method |
| **THE COW** `smoothTrajectory(cow,[a;b],[1.2 0])` | **walks out, then holds 0.650 m FOREVER.** Measured across a 12 s run. This is the hero behaviour and it is a built-in, not something to hand-code |
| `extendedObjectMesh` + `join/scale/translate/rotate` | custom meshes; actors take a `Mesh` property |
| actor properties | `Mesh`, `PlotColor`, `AssetType`, `ClassID`, `Length/Width/Height`, `Yaw` |
| `chasePlot(actor)` | driver's-eye view — an **actor** method, works headless |
| `plot(sc,'Parent',ax)` | plan view |
| `record(sc)` | whole run of poses in one call: `SimulationTime`, `ActorPoses` |
| `export(sc,…)` | **OpenDRIVE 1.4/1.5/1.6 · OpenSCENARIO XML 1.0/1.1 · RoadRunner HD Map** |
| `roadBoundaries` `targetPoses` `actorPoses` `targetOutlines` `roadMesh` `targetMeshes` | all present |
| sensors | `lidarPointCloudGenerator` · `drivingRadarDataGenerator` · `visionDetectionGenerator` |
| planning | `referencePathFrenet` · `trajectoryGeneratorFrenet` · `dynamicCapsuleList` · `controllerPurePursuit` · `vehicleCostmap` · `pathPlannerRRT` · `plannerHybridAstar` |
| tracking | `multiObjectTracker` · `trackerJPDA` · `trackingKF` · `objectDetection` |
| graphics | `patch` `surf` `light` `material` `camlight` — a real lit 3-D scene |
| `VideoWriter` MPEG-4 | 24 fps, quality 92, writes headless |
| Mapping Toolbox | `geoplot` / `geobasemap` — real satellite basemaps for the plan view |

## RULED OUT — and this one matters
**`plotSim3d` / Unreal Engine co-simulation DOES NOT WORK ON macOS.** Verified by running:
> `Co-simulation with Unreal Engine is not supported on this operating system.`

`sim3d.World` ships in the install and `plotSim3d` is a `drivingScenario` method, so it *looks*
available right up until it throws. MathWorks' own requirements confirm Windows/Linux only.
**So there is no photoreal path inside MATLAB on this machine.** The lit-patch renderer below is
the answer, and at 0.142 s/frame it is the better one anyway.

Also absent: **Scenario Builder for Automated Driving Toolbox** (`scenarioBuilder`,
`getScenarioDescriptor`, `updateVehicleDimensions` all MISSING) — not needed.

## SIX TRAPS, ALL FOUND BY RUNNING
1. **`daspect(ax,[1 1 1])` IS MANDATORY.** Without it the Z axis stretches to fill the box and
   every 4 m house renders as a tower. This was the entire difference between an unusable first
   render and a presentable one. **The single highest-value line in the renderer.**
2. **`plot(scenario)` silently renders nothing** unless given `'Parent',ax` explicitly.
3. **`trajectory`, `smoothTrajectory` and `chasePlot` are ACTOR methods, not scenario functions.**
   `exist('smoothTrajectory')` returns 0 and `which` finds nothing — they look missing and are not.
4. **`smoothTrajectory` rejects repeating zeros** in the speed vector:
   `driving:scenario:UnreachableWaypoints`. Two waypoints with speeds `[v 0]` is the correct
   idiom for "go there and stop".
5. **`roadNames()` does not exist in R2026a.** `derisk/check03_osm_import.m` calls it and would
   report a false import failure on a perfectly good import. Use `scenario.RoadSegments`.
6. **Actor `ClassID` is the drivingScenario numbering (1–6), not ours (S5, 0–15).**
   `sih.util.toSimClassID` exists for exactly this. Never hardcode either side.

## WHAT THIS MAKES POSSIBLE, THAT BLENDER DID NOT
- **Iterate.** 3.5 min per film means the look can be fixed by looking at it, repeatedly.
- **One geometry source for picture and planner.** The renderer draws `roadBoundaries(sc)` —
  literally the same road the planner drives. They cannot drift apart.
- **Sensors in the same scene.** Lidar/radar generators run on the same actors, so the perception
  story is available without a second world.
- **A standards export.** OpenDRIVE / OpenSCENARIO out of the same scenario is a real answer to
  "how does this integrate?", and it cost nothing.
