# REF-08 · ROADS — THE SYSTEM, THE PROFILE, THE CLEARANCE
**Batch 2 of Aditya's video study.** 4 videos, 29 min. Two were under a minute and were read
frame by frame. Method only — every item is a node, a modifier, a key or a number.

## 1 · THE ROAD SYSTEM — one curve in, a whole road out
**Source: 3Dz "City Road Maker" (40 s, read frame by frame from the modifier panel).**
A Bezier curve gets a geometry-nodes modifier and becomes a complete road. **The exposed parameter
list is the design brief for what we must build**, and I read it straight off his panel:

| Group | Parameters visible |
|---|---|
| Carriageway | **Road Size · Road Lanes** |
| Markings | **External Lines Type / Count** (edge lines) · **Internal Lines Type / Count** (lane lines) |
| Shoulders | **External Shoulder · Internal Shoulder** — separate widths per side |
| Kerb / footpath | **RoadSide Type / Size**, External and Internal separately |
| Median | **Green Belt Type / Position / Size** |
| Furniture | **Lamp Poles Type / Lights / Position / Spacing · Boxwood Position / Spacing / Randomness · Barrier Type / Position** |
| Damage | **Patches Density** |

**Two things to take from this:**
1. **Every side parameter exists twice — external and internal.** The two sides of a road are never
   assumed equal. That is the same rule as S1's "the right side must not mirror the left," arrived at
   independently by a tool designer.
2. **Surface damage is a DENSITY PARAMETER, not hand-placed objects.** Our 9 clustered potholes and
   16 bridge patches become a density with a clustering seed.

**This is our architecture.** One node group, driven by the real centreline, with a parameter set per
OSM class: trunk 14.0 m / 4 lanes / 5 m median · tertiary 7.0 m / 2 lanes · residential 4.5 m /
no markings · living_street 3.2 m / no markings. 213 roads, one system.

## 2 · THE OTHER METHOD, AND WHY WE DO NOT USE IT
**Source: Rogue_Knight3D, forest highway.** The classic approach:
plane → `Ctrl+R` ×11 loop cuts → subdivide → **`Alt`-click the outer edge loops, `E` extrude,
`S` scale on X, and drop them a little** → repeat outward. Then `P` separate the carriageway from
the verge so they take different materials. Then a **Bezier curve + CURVE MODIFIER**, and slide the
mesh along it with `G Y`. **Subdivide the curve** or the mesh stretches at the ends.

**Verdict: good for one hero road, wrong for 213.** The Curve modifier stretches, needs manual
pre-subdivision, and gives no per-class parameters. **We use geometry nodes.**
**But keep his cross-section idea** — building the profile by extruding edge loops outward and
stepping them down is exactly how our IRC section should be defined:
carriageway at 2.5 % camber → crumbling edge band 100–300 mm → earthen shoulder 1.2 m → verge drop.

## 3 · UV — the thing that decides whether markings work
Confirmed twice, in Batch 1 and again here:
**the road's UV must be a STRAIGHT RECTANGULAR STRIP however much the road bends in 3-D.**
Rogue_Knight's steps: unwrap, **`R Z 90` to align the UVs to the texture**, then **scale on X until
the road reads at the right length**. Get this wrong and lane markings smear round every bend.

## 4 · CLEARING THE ROAD CORRIDOR — three methods found, and ours is the fourth
Nothing may scatter on the carriageway. Methods seen:
1. **Dynamic Paint** (Workflow Project) — the road paints a map onto the terrain; **Physics > Cache >
   Delete All Bakes, then Bake All Dynamics** before rendering. Powerful, but a bake step that can go
   stale silently.
2. **Weight-painted vertex group**, scatter culled to it (Batch 1).
3. **A baked road mask image** from the layout (Xoio, Batch 1).
4. **OURS: generate the mask directly from `matlab_roads.csv`.** We already have every centreline and
   every width. No painting, no baking, nothing to go stale. **Use this.**

## 5 · THE ELEVATED ROAD — S4's nine flyover decks
**Source: WebTechStuff road/highway/bridge addon (15 s, read frame by frame).**
The frames show a curved viaduct generated from **one curve**, carrying:
deck + parapet/crash barrier both edges + **piers dropped at regular span spacing** + traffic
instanced along the lanes. Several decks weaving over each other make the interchange.
**So an Indian flyover is the same system as a road, plus piers at span spacing.**
Our numbers come from REF-01, not from the video: **spans 22 m · piers 1800 × 1800 mm ·
deck 6 m over the road · minimum clearance 5.5 m over road, 6.25 m over the electrified railway**
(S0b) — which is why our interchange must be **stepped, not one flat table**.

## 6 · SCATTER — real budget numbers
- **"I recommend not to go over 10k [trees] — that's a bit overkill."** A working figure for tree
  instance count in one scene.
- **Two separate grass systems: one tight around the road, one across the whole area** — *"so we
  don't have empty space between the trees, which from above can look weird."* Two-tier density.
- **A separate, LOW-subdivision ground plane** for areas that will be hidden by vegetation —
  *"most of these areas will be hidden by trees so we do not need a lot of geometry."* LOD by
  occlusion, decided before building rather than after.
- Working practice: subdivision **2 in viewport / 5+ at render**; disable particle systems to navigate.

## 7 · PARAMETRIC TREES AND ROCKS — feeds REF-06
**A geometry-nodes tree with these exposed parameters** (Workflow Project):
**branch seed · branch density · branch size · leaf density · leaf size · leaf colour (season) ·
a ColorRamp controlling where the branch accent falls.**
**Branch seed switches between different results for the same settings** — that is the mechanism
REF-06 needs for its eight constraint operators. One tree, many outcomes, no extra geometry.

**Rocks entirely procedural, from the shader**: displacement driven by a Voronoi-type texture with
**seed · displacement size (texture scale) · displacement distance (pointiness)**.
Subdivision 0 while working, 6 to view. **No rock models needed.**

## 8 · CAMERA — a number to correct against
Rogue_Knight uses **18 mm for a "wide-angle shot."** Ours must be **12–14 mm** with barrel
distortion (BLENDER-PIPELINE §37, dashcam 140°). **Every one of these tutorials frames its scene
much narrower than our camera will.** Their compositions will not survive our lens.

## 9 · HONEST LIMITS OF THIS BATCH
- **Not one of these roads is Indian.** They are clean western highways and forest roads.
  **No crumbling edges, no unmarked lanes, no speed breakers, no open side drains, no encroachment.**
  The only damage feature anywhere was a "Patches Density" slider in a paid tool.
- **No camber, no IRC widths, nothing in metres.** All shape, no specification.
- Two of the four were **advertisements for paid addons.** I took the architecture, not the tool —
  we build the node group ourselves and depend on nothing.
- **The broken Indian road stays sourced where it already is:** IRC 35 and 99 for markings, humps
  and drains; REF-01 §13 for furniture; and **Aditya's own dashcam and bus footage for what
  "broken" actually looks like** — worn markings at 60 %, edges crumbling into dirt over 100–300 mm,
  no edge line at all on the smaller roads, and a pale dusty surface rather than black.

## 10 · SOURCES
3Dz *Blender road generator — Geometry Nodes* · WebTechStuff *roads, highways and bridges addon* ·
WORKFLOW PROJECT *Realistic Forest Road Scene* · Rogue_Knight3D *Forest Highway Scene, Part 1*.
