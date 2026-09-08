# THE MATLAB BACKUP DEMO — S1 AND S2

**What this is:** a complete, self-contained demo of both SIH26037 scenarios, built in MATLAB
so it can be rendered and iterated in minutes rather than hours. It is the **safety net**. If
the detailed Blender city lands in time, its geometry replaces this and the two scenarios come
back on top of it. If it does not, **this is the demo.**

**Full findings: `../notes/REF-17-MATLAB-PLANNER.md`. Read it before changing anything.**

---

## RUN IT

```bash
MAT=/Applications/MATLAB_R2026a.app/bin/matlab
$MAT -batch "run('<repo>/matlab/veh_look.m')"          # the ego alone, 3 views, 13 s
$MAT -batch "VEH='bus'; run('<repo>/matlab/veh_look.m')"
$MAT -batch "VEH='bus'; PARTS=true; run('<repo>/matlab/veh_look.m')"  # every part, own hue
$MAT -batch "run('<repo>/matlab/s1_world_shots.m')"    # S1 world, 5 stills
$MAT -batch "run('<repo>/matlab/s1_result_run.m')"     # S1 numbers + map/ego_S1.csv
$MAT -batch "run('<repo>/matlab/s1_film.m')"           # S1 film, ~15 min
$MAT -batch "run('<repo>/matlab/s2_world_shots.m')"    # S2 world, 4 stills
$MAT -batch "run('<repo>/matlab/s2_action_run.m')"     # S2 numbers + map/ego_S2.csv
$MAT -batch "run('<repo>/matlab/s2_film.m')"           # S2 film
```
Everything writes to `matlab/renders/`. Nothing needs Blender at run time; the Blender-authored
assets are committed as STL in `matlab/assets/`.

---

## THE TWO RESULTS, AND WHY BOTH ARE NEEDED

**S1 — an agent that never reacts.** A cow walks out, stops on the centreline, and never moves
again. A purely defensive planner waits for the road to clear; a cow never clears it. That is
the **frozen-robot problem**, and it is a structural failure, not a tuned one.

**S2 — an agent that does react.** The ego probes at an unsignalled gyratory; the circulating
auto lifts off by a measured 1.80 km/h; that lift is read as a yield and committed on. This is
**negotiation**, which S1 cannot test.

Either one alone is half the argument.

| | S1 | S2 |
|---|---|---|
| route | 610 m of the **real** Najibabad tertiary | 245 m through the chowk |
| the result | **0.965 m clearance each side**, past her at 8.00 km/h | **1.80 km/h lift read as a yield**, committed at t=8.05 s |
| the stand-in | **STOPPED 4.0 m short, never passed** | stops at the give-way line, nobody yields to it |
| MathWorks' planner | fails at t=19.7 s, 0/120 candidates | **cannot start** — a gyratory has no reference path |
| output | `map/ego_S1.csv`, 1,240 rows | `map/ego_S2.csv`, 960 rows |
| film | `S1_cattle_crossing.mp4`, 62 s | `S2_the_chowk.mp4`, 48 s |

---

## WHAT IS REAL AND WHAT IS OURS — say this plainly, always

**S1 carries the real-map claim.** The centreline is MATLAB's own export of the Najibabad
tertiary, offset (+35.0, −100.0) removed, verified at 1.05 m median / 99.4 % within 5 m over
1,625 points. The 7.000 m carriageway and 1.200 m shoulders are S0 §4.
**But the reveal is AUTHORED.** The forest cannot deliver a specified sight distance (measured
4–134 m by station) and the road does not bend where the cow is (radius 1020 m — straight).
One thicket is authored and its radius **solved by bisection** until the ray-marched reveal
matches the written 42 m. Honest and repeatable — but never call it emergent.

**S2's arm bearings are real; its island is not.** The node measures (341.6, −578.6) against a
written (340.1, −579.9) — 1.9 m — and all four arm bearings are within 1° of the map. They sit
in **two near-parallel pairs**, which is a gyratory, not a crossroads. **There is no island in
the OSM data.** The gyratory geometry is built to **IRC 65:2017 Table 6.2** — island 24 m,
circulatory carriageway 8 m, inscribed circle 40 m, the three of which must go together — and
it is authored, not traced.

**The driver is a placeholder in both scenarios and the code says so in capitals.**
`sc.s1drive` senses nothing at all. `sc.s2drive` reads exactly one real quantity — the binding
agent's measured speed change — and is scripted otherwise. Neither makes a planning claim.
**They are the SEAT.** Stream D's planner replaces the body of one function and nothing else:
same inputs, same outputs, same integration loop, and the frozen S1 TrackList stays the boundary.

**The defensive stand-in is OURS and must be captioned as ours in the frame.** PRD §8 warns
that a tuned opponent is a rigged fight; the caption is the defence, not our good intentions.
It is the textbook rule — *keep your lane; if the lane ahead is blocked, stop and wait* — which
is correct and safe, and which never finishes S1 because a cow never clears.

**One third-party asset:** the zebu is built on a **CC-BY** Sketchfab cow and **must be
credited wherever the render is shown**. See `assets/ATTRIBUTION.md`.

---

## THE FILES

| file | what it is |
|---|---|
| `+sc/refRoot` `localRoads` `routeFrom` `path` | the map, the frame, the station/lateral geometry |
| `+sc/meshes` `treeAsset` `asset` `zebuColours` | actor meshes, asserted; Blender-authored assets |
| `+sc/partAsset` `carAsset` `busAsset` | Blender-authored vehicles: N parts, one mesh, a face→part index |
| `+sc/carColours` `busColours` | one colour per part — the only texture MATLAB allows |
| `+sc/scene` `hud` | the renderer and the instrument strip |
| `+sc/s1world` `s1render` `s1actors` `s1drive` `s1gap` `s1defensive` | S1 |
| `+sc/s2world` `s2render` `s2actors` `s2drive` | S2 |
| `s1_*.m` `s2_*.m` | the runnable scripts |
| `veh_look.m` | ONE vehicle alone, 3 views, 13 s — and `PARTS=true` colours every part |
| `assets/*.stl` | Blender-authored geometry; `ATTRIBUTION.md` holds the licence obligation |

---

## IF SOMETHING LOOKS WRONG

**Render it and look at it.** Every defect in this project was found by looking at an image,
and several were live while every assertion was passing — a canopy of confetti, a fence
standing on a carriageway, a bus parked on a roundabout, a cow floating 2.94 m off the ground,
and six parts of the ego that were built, exported and asserted and drew no pixel at all,
because they sat inside the shell.

**And when a shape is unidentifiable, COLOUR IT rather than reason about it.** MATLAB has no
textures, so a defect and a deliberate part look identical. `PARTS=true; run veh_look.m` gives
every part its own hue and a printed legend. It found the buried rims — there was no rim hue
anywhere in the frame — and it also stopped a fix that was not needed.
REF-17 §4, §7, §10, §12 list twenty traps already paid for. Read them before re-deriving one.
