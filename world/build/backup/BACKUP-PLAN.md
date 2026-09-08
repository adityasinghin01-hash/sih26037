# THE BACKUP — two scenarios, demoable, for the KIET internal round on 7 Sep 2026
Written 4 Sep 2026 **before anything was built** (Rule 1). Scope set by Aditya the same evening.

## WHAT THIS IS
**A pure working demo of the project**, not the film and not peak realism. Two scenarios that
look good, run live, and can be handed to a judge. If the detailed city (being built in a
separate chat) lands in time, the city replaces the geometry and these two scenarios come back
on top of it. If it does not land, **this is what we show.**

**Budget:** 10–20 h of build. Then 1.5 days for Aditya's integration, testing and refining.

## THE FENCE — what this build may not touch
Another chat owns and will lose work if these change:
`PLAN.md` · `scenarios/*.md` · `build/city/*` · `notes/REF-*` · `blend/01_LIGHT.blend`.
This build writes **only** to `build/backup/**` and `blend/BACKUP_WORLD.blend`.
The MATLAB code lives in `build/backup/matlab/` and **not** in `~/dev/sih2026/matlab/`, because
that repo is fenced per stream and Stream D owns the planner package. It adds sih2026 to the path
at run time and calls the real `sih.planner.*` functions unmodified. Nothing is forked.

## THE ARCHITECTURE — and the correction that shapes it
**MATLAB does not take Blender geometry.** `AGENTS.md` §2 is settled: *"No RoadRunner.
`drivingScenario` + `roadNetwork(...,'OpenStreetMap',f)`."* The dependency runs the other way:

```
map/najibabad.osm ──► MATLAB drivingScenario ──► sih.planner ──► results/<run>/trajectories.csv
                                                                              │
                              blend/BACKUP_WORLD.blend ◄── reads the csv, drives actors, renders
```

Both ends land in the same frame because both come from the same `.osm`.
**MEASURED 4 Sep, independently of the earlier claim:** offset (+35.0, −100.0) m,
**median 1.05 m, 99.4 % within 5 m, p95 3.33 m** over 1,625 MATLAB points inside the 2 km box.

**Consequence, and it is the whole reason for the ordering below: the demo does not depend on
Blender at all.** T1 can be finished while the city chat is still building.

## THE THREE TIERS — built strictly in this order
| | What | If the 7th arrives and this is all we have |
|---|---|---|
| **T1 · THE DEMO** | MATLAB. Both scenarios, planner running live, metrics, baseline comparison | **A complete, scoreable project** |
| **T2 · THE PICTURES** | Blender. The two scenario circles, ~8 hero stills | A project that also looks real |
| **T3 · THE FILM** | EEVEE clips of the two moments, 8–12 s each | Garnish |

## THE TWO SCENARIOS — S1 and S2, and why this pair
They are **one mechanism proved twice, against two structurally different baseline failures.**

**S1 · THE CATTLE CROSSING** — `scenarios/S1-CATTLE-CROSSING.md`, centre (−280, +450), r 205 m.
An agent that will **never** react. Probe → no response → classify non-negotiable → **measure**
the gap → abort for the oncoming auto → retake → pass. Baseline: emergency stop, and it never
moves again. *The frozen-robot problem.*

**S2 · THE CHOWK** — `scenarios/S2-THE-CHOWK.md`, centre (+340, −580), r 165 m.
Agents that **do** react. Probe → read the yield → commit. Baseline: **cannot even start** —
it needs Cartesian waypoints for a reference path and an unsignalled gyratory supplies none.

Both already have second-by-second written action (S1 62 s, S2 48 s), so Rule 1 is already
satisfied for them and nothing is invented here. They are also the two cheapest useful circles:
r 205 m and r 165 m against a 4000 m world.

## T1 — WHAT GETS BUILT, EXACTLY
### Road geometry
From `map/matlab_roads.csv` (**the source of truth**), clipped to each scenario circle, offset
(+35, −100) into the OSM metric frame, classified against `map/najibabad_metres.json`, and built
with `road(scenario, centers, width)` at the S0 §4 widths:
`trunk 14.0 · trunk_link 7.0 · secondary 7.0 · tertiary 7.0 · unclassified 5.5 · residential 4.5 ·
living_street 3.2 · service/track 3.0`.
**Why `road()` per class and not `roadNetwork('OpenStreetMap')` for the scenario itself:** the
importer gives no per-class carriageway width, and the width table is what the whole planning
argument rests on (S1's gap is 7.0 m − cow 2.5–3.2 m − ego 1.9 m = 0.95 m each side). The
importer is still run and logged as the provenance proof — it is the project's headline move —
but the scenario is built from the CSV so every width is ours and asserted.

### The ego — genuinely planned, never scripted
Every step: build the S1 TrackList from actor poses → `sih.planner.velocityObstacle` per track →
`sih.planner.assignRoles` → `sih.planner.chooseVelocity` → integrate. **World frame throughout,
with the real ego pose** — the frame rule in `assignRoles`'s header, which silently returns wrong
roles for every agent if broken.

### The other actors — and the honest line about them
- **The two hero agents** (S1's oncoming auto-rickshaw, S2's yielding auto) run a **reactive
  gap-acceptance rule**: they read the ego's probe and either lift off or hold. The negotiation
  is therefore real, not staged.
- **The cow does not react at all.** That is the point of S1 and it is a constant, not a model.
- **Every other ambient actor is on a scripted trajectory** taken from the written second-by-second
  action. **This gets said out loud in the deck.** They are traffic, not agents.

### Output, in the frozen format
`results/<run>/trajectories.csv` → `t,actor_id,class_id,x,y,z,yaw` (AGENTS.md §3 file formats) ·
`metrics.json` keys M1–M10 · `config.json` = a copy of the inputs, because **a number without its
config is not a result.**
ClassIDs via `sih.util.toSimClassID` — never hardcoded. Cow = 10, auto-rickshaw = 4.

### The baseline comparison — Route 2, and its honest limit
`matlab/baseline/` **has been run and it fails**: t = 19.7 s, 0 of 120 candidates collision-free,
identically on macOS/Apple Silicon and Windows x86 under R2026a Update 5. **Do not make it
survive** — the failure is the result.
Because that failure is in *its own* shipped scenario, it is **not** a head-to-head number. So T1
also runs a **defensive-planner stand-in** on OUR two scenarios — stop if any agent's footprint
intersects the path corridor, which is what a purely defensive planner does — to produce the
frozen-robot contrast on the same road. **It is labelled as a stand-in, not as MathWorks' planner.**
Saying that before a judge says it for us is the whole point.

## ASSERTIONS — every script checks itself and fails loudly
Road widths match the class table to 1 mm · ego speed never negative · the S1 clearance arithmetic
(7.0 m − cow − 1.9 m ego) is computed and asserted ≥ 0.9 m · `h = lambda − beta` is finite whenever
an agent is in range · no `NaN`/`Inf` in any logged position · the ego never appears in its own
TrackList (the defect that pinned `h` at −π/2 on every step).

## T2 — THE BLENDER SIDE, WHEN T1 IS DONE
The two circles only, not the 4 km world. Terrain (never flat), roads at the same widths from the
same CSV, plain buildings with real openings, 11 kV poles, a few vehicles, and the actors driven
from `trajectories.csv`. Sky by **appending** SKY/AIR/CLOUD from `01_LIGHT.blend` — not rebuilt,
and not one number changed.

**RENDER PATH — decided by measurement, 4 Sep.** One 1280×720 frame of `01_LIGHT.blend`, sky only
with **no geometry at all**, took **over 12 min 40 s** in Cycles at 64 samples on the M1 before it
was killed. A 62 s film at 24 fps is 1,488 frames — over 300 h. **Cycles cannot produce motion on
this machine.** So: **EEVEE for all motion**, Cycles for a handful of hero stills. The world is
built engine-agnostic so this is a switch, not a rebuild.

## TRAPS ALREADY PAID FOR
**MATLAB (R2026a):**
- `roadNames()` **does not exist** — `derisk/check03_osm_import.m` calls it and would report a
  false import failure. Use `scenario.RoadSegments`. Found 4 Sep by running it.
- `roadNetwork(...,'OpenStreetMap')` takes **29.3 s** on `najibabad.osm` → 425 segments, 59.9 km.
- OpenTrafficLab needs two fixes on R2026a (`plan/OPENTRAFFICLAB-R2026a.md`), one of which
  (`c.IsVisible = true`) must be repeated in whatever builds the scenario.
- `runtests` needs the `.m` on the path.

**Blender (4.5.11):**
- `read_factory_settings(use_empty=True)` **disables every extension** → re-enable immediately.
- `bpy.ops.mesh.loopcut_slide` **segfaults headless** → `subdivide` only.
- A geometry-nodes **volume ignores material slots** → Set Material inside the tree.
- Viewport `clip_end` defaults to 1000 m and **hides the sky** → 60000.
- `view_transform` must be `'Standard'`, exposure −3.06.
- `camera.matrix_world` is stale until `view_layer.update()`.
