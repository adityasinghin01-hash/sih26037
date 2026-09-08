# SPEC · THE FACADE PART LIBRARY, THE TEMPLE, THE STATUE
**Written 4 Sep 2026, BEFORE anything was built. RULE 1.**
Component 4 (BUILDINGS) of `PLAN.md` §4. Method: REF-09 §1 — parts scattered on plain boxes,
driven by vertex groups. This document is the only authority for the numbers below; the build
script asserts every one of them and fails loudly if the geometry disagrees (RULE 4).

## 0 · SOURCE DISCIPLINE
Every dimension carries its source. Three kinds only:
- **[REF]** — already in the reference library (REF-03, REF-09, REF-13, S0, S2, S5). Not re-derived.
- **[CODE]** — Indian standard / NBC figure named in REF-03 §2.
- **[PROD]** — a real manufactured product size (Sintex tank, split-AC outdoor unit, DTH dish,
  IS 4985 PVC pipe, IS 456 stair rule). Stated here so it is written, not invented at build time.
**Nothing is marked as sourced that is not.**

## 1 · THE PLACEMENT CONVENTION — how every part attaches
This is the contract between this library and whatever scatters it. It is asserted per part.

```
        +Z  up
         |
         |        +Y = OUT of the wall, towards the street
         |       /
         |      /
         +-----/------ +X = along the wall
        ORIGIN at (0,0,0)
```
- **The wall face is the plane Y = 0.** Nothing sits behind it except by design.
- **Origin = horizontal centre of the part, at the wall plane, at the part's own BASE.**
  So a part is placed by moving it to (x_along_wall, wall_Y, height_of_its_base). REF-09 §2:
  *"Set the origin to the BOTTOM of the object, so it scales from the ground up."*
- **Recessed parts** (window, door, shutter) occupy **Y ≤ 0** — they cut into the wall.
- **Projecting parts** (awning, balcony, AC box, sign, dish, tank) occupy **Y ≥ 0**.
- **A part that spans both** (window with a chajja over it) is allowed and is flagged as such.
- Every part is a **single joined mesh with scale applied** (REF-09 §2 checklist).
- Rotation about Z of ±2° is applied by the SCATTERER, not baked in [REF: REF-03 §1].

## 2 · THE THIRTY PARTS
Column "base Z" is the height at which the part's origin is normally placed on a wall.
`W × D × H` = along-wall × out-of-wall × vertical, in metres.

### Windows — 4 variants (the most repeated part, so it gets the most variation)
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| W1 | casement, 2 leaf, sill + 0.45 chajja | 1.20 × 0.28 × 1.50 | 0.90 | sill 0.90 [CODE REF-03 §2]; leaf sizes [PROD] |
| W2 | ventilator / hopper, high level | 0.60 × 0.18 × 0.45 | 2.10 | fits under a 2.75 m clear ceiling [CODE] |
| W3 | shop window, fixed, with grille | 1.80 × 0.26 × 1.50 | 0.90 | window area ≥10% of floor [CODE] |
| W4 | 3 leaf wide + projecting box grille | 1.80 × 0.42 × 1.35 | 0.90 | box grille projects 0.22 out [PROD] |

Frame section 60 × 60 mm timber or 50 mm steel [PROD]. Glass inset 12 mm behind the frame face.
**Chajja** (W1) 0.45 m projection, 0.075 m slab, top of opening + 0.10 [CODE: cantilever ≤0.9 m].

### Doors — 3 variants
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| D1 | single leaf panelled house door | 0.90 × 0.22 × 2.10 | 0.00 | 900 × 2100 leaf [PROD] |
| D2 | double leaf, main entrance | 1.50 × 0.24 × 2.10 | 0.00 | 2 × 750 leaves [PROD] |
| D3 | steel grille gate (over D1) | 1.05 × 0.14 × 2.10 | 0.00 | 12 mm sq bar at 110 mm [PROD] |

### Rolling shutters — 2 variants  [CODE IS 6248, REF-03 §2; size from S2]
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| S1 | shutter DOWN, closed | 3.00 × 0.22 × 2.90 | 0.00 | S2: "3.0 m wide × 2.9 m high" [REF] |
| S2 | shutter UP, rolled into head box, shop open | 3.00 × 0.30 × 2.90 | 0.00 | same opening, box 0.34 dia [PROD] |

Lath pitch **75 mm** [CODE IS 6248]. Guide channels 0.075 m each side. Bottom rail 0.10 m.
Head box on S2: 0.34 × 0.34, its underside at 2.62 → 0.28 m of visible box above the opening.
**S2 (14 up, 8 down at the chowk) is why both exist** [REF].

### Balconies — 2 variants
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| B1 | cantilever slab + steel railing | 3.00 × 1.00 × 1.12 | 3.00 | projection ≤0.9 m struct + 0.10 nosing [CODE]; railing 1.00 [CODE parapet min] |
| B2 | small masonry balustrade balcony | 1.50 × 0.60 × 1.05 | 3.00 | ditto |

Slab 0.12 m thick. Railing 1.00 m above the balcony floor. Base Z 3.00 = first floor level [CODE].

### Parapets — 2 variants  (roof edge; base Z = roof slab top)
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| P1 | plain plastered + coping | 2.00 × 0.23 × 1.00 | roof | **minimum 1.0 m** [CODE REF-03 §2] |
| P2 | pierced, jali gaps | 2.00 × 0.23 × 1.00 | roof | same height, 5 openings 0.20 × 0.35 |

Modular at **2.00 m** so a run tiles. Coping 0.28 × 0.06 overhanging 0.025 each side.

### Awnings — 2 variants  [CODE max 4.5 long × 2.4 proj, ≥2.2 m clear; S2 gives the real range]
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| A1 | corrugated tin, sloping | 3.20 × 1.20 × 0.42 | 2.30 | S2: "0.9–1.4 m at 2.2–2.4 m clear" [REF] |
| A2 | tarpaulin sagging on light frame | 3.60 × 1.40 × 0.55 | 2.25 | ditto; sag 0.12 at mid-span |

Clear height beneath is asserted **≥ 2.20 m** [CODE]. Fall 0.18 m over the projection.
Corrugation pitch 0.076 m, depth 0.018 m [PROD, standard GC sheet].

### Sign boards — 3 variants
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| G1 | hand-painted Devanagari board | 2.40 × 0.08 × 0.60 | 2.95 | S2: "21 hand-painted Devanagari boards" [REF] |
| G2 | backlit box sign | 1.80 × 0.20 × 0.75 | 2.95 | S2: "6 backlit box signs, unlit" [REF] |
| G3 | projecting bracket sign | 0.10 × 0.78 × 0.90 | 2.60 | projects across the footpath |

Base Z 2.95 sits the board just above a 2.90 m shutter [REF S2] and below the 3.00 m slab [CODE].

### Water tanks — 2 variants  **[REF-13 §9 item 8: BLUE and RED, not black]**
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| T1 | 1000 L blue, on a steel stand | 1.09 × 1.09 × 1.62 | roof | Sintex 1000 L = 1090 dia × 1170 h [PROD]; stand 0.45 |
| T2 | 500 L red, direct on the slab | 0.88 × 0.88 × 0.94 | roof | Sintex 500 L = 880 dia × 940 h [PROD] |

Built by **spin** about the vertical axis from a drawn profile (REF-09 §3), 24 steps.
Ribbed body, tapered shoulder, a lid 0.34 dia standing 0.06 proud.

### The single-variant parts — 12
| id | part | W × D × H | base Z | source |
|---|---|---|---|---|
| C1 | AC outdoor unit on brackets | 0.80 × 0.45 × 0.55 | 2.40 | 800 × 300 × 550 unit + 0.15 bracket [PROD] |
| C2 | drainpipe, 3 storey run + shoe | 0.15 × 0.19 × 9.60 | 0.00 | 110 mm PVC [PROD IS 4985]; clamps at 1.60 m |
| C3 | window grille panel (fits W1) | 1.20 × 0.05 × 1.50 | 0.90 | 12 mm sq bar, 110 mm pitch [PROD] |
| C4 | external staircase flight + railing | 1.00 × 4.42 × 3.98 | 0.00 | 17 risers × 176 mm = 3.00 m rise, 260 tread [PROD IS 456: riser ≤190, tread ≥250] |
| C5 | electricity meter box + conduit | 0.30 × 0.16 × 1.55 | 1.20 | 300 × 400 × 160 box [PROD]; conduit to the eave |
| C6 | satellite dish on a bracket | 0.62 × 0.72 × 0.68 | roof | 0.60 m Ku-band offset dish [PROD] |
| C7 | drying washing on a line | 3.00 × 0.30 × 0.95 | roof+1.0 | S2: "19 balconies, 6 with washing" [REF] |
| C8 | exposed rebar column stub | 0.23 × 0.23 × 0.86 | roof | 230 sq column, 4 × 12 mm bars, 8 mm stirrups at 150 [PROD IS 456]; 0.75 m projection |
| C9 | chajja / sunshade, standalone | 1.60 × 0.60 × 0.10 | 2.45 | cantilever ≤0.9 m [CODE] |
| C10 | shop plinth step | 1.60 × 0.55 × 0.30 | 0.00 | 2 risers × 150 mm; shops sit above the street |
| C11 | wall-mounted junction + conduit run | 0.16 × 0.09 × 0.62 | 2.20 | service drop terminates here [REF-02 by reference only] |
| C12 | tin shed roof module | 3.20 × 2.40 × 0.55 | 3.20 | S2: "3 blue and green corrugated tin sheds, 3.2 m" [REF] |

**Total 30.** (4+3+2+2+2+2+3+2+12 = 30.)

## 3 · WHAT MAKES A THOUSAND BUILDINGS OUT OF THIRTY PARTS
[REF-03 §1, REF-09 §1]. The library ships the parts; the scatterer supplies the variation:
width 2.9–9.5 m · storeys 1/2/3 · a colour per floor · a random clutter draw · ±2° rotation.
**The library's own job is only that each part reads correctly and attaches predictably.**

**Repetition rule** [REF-09 §11]: *repeat what a reason would repeat; never repeat what chance
produced.* A run of identical shutters along one shopfront is REAL and correct. The same
building twice at random is the tell.

## 4 · THE PALETTE  [REF-13 §8, measured off ref_31]
cream · yellow ochre · pink · white · pale blue · **and a lot of unpainted grey render**.
Water tanks blue and red. **The temple shikhara red-orange — the one thing above the roofline.**
Vegetation saturation ~31 % for the plains [REF-13 §9 item 6] — not this library's concern but
it sets how saturated a painted wall may be beside it.

## 5 · MATERIALS — shared, procedural, and that is the whole affordability argument
[S0 §4: *"What is expensive is unique texture and unique grime per object"*.]
One shared material set for the whole library. **No image textures at all in the parts** —
every material is procedural, so 30 parts cost 30 parts and 1000 buildings still cost 30 parts.
Materials: PAINT (colour driven per-instance), RENDER_GREY, WOOD, GLASS, STEEL_PAINTED,
GALV_STEEL, PVC_GREY, PLASTIC_BLUE, PLASTIC_RED, TIN, TARP_BLUE, CONCRETE, STONE, WHITEWASH,
REBAR_RUST, CLOTH, BRASS.

**Every one gets the AO DOUBLE-STACK** [REF-09 §5], which is the technique that stops a texture
looking pasted on:
- **(a) crevice grunge** — AO node, distance 0.1–0.3 m, ColorRamp, MULTIPLY into base colour at
  factor ~0.75, tinted brown rather than black.
- **(b) edge wear** — the same node with distance **very low** and **Inside + Only Local both on**,
  into a ColorRamp, **with noise mixed into the mask so the wear is not uniform.**
And the two-level variation recipe [REF-09 §6]: **the mask itself gets noise**, not just the colour.
Roughness always varies. Never a constant.

## 6 · THE TEMPLE  — `TEMPLE.blend`
S5: *"sanctum with a latina shikhara, whitewashed, 5.2 m overall on a raised plinth, a small
pillared hall in front, saffron flags on bamboo, a bell hung at the entrance … 38 stone steps"*.
REF-03 §6 gives the real proportional breakdown (base 1.68 + body 1.20 + crown 0.80 = 3.68 m;
another 1.75 + 1.55 + 1.50 = 4.80 m). Scaled to S5's 5.2 m:

| band | height | cumulative | source |
|---|---|---|---|
| plinth (adhisthana), 4.60 × 6.90 m | 0.90 | 0.90 | REF-03 §6 raised plinth [REF] |
| sanctum wall (jangha), 3.00 m square | 2.10 | 3.00 | REF-03 §6: "vimana 3.0 m square" [REF] |
| latina shikhara, curved, 14 bands | 1.85 | 4.85 | REF-03 §6 curved over the sanctum [REF] |
| amalaka + kalash | 0.35 | **5.20** | S5: "5.2 m overall" [REF] |

- **Shikhara method** [REF-09 §3]: **cube → inset → extrude → repeat**, 14 times, the horizontal
  inset following a curve so the profile is convex — *that stacked profile IS a latina shikhara.*
  A raised central band (the *lata*) on each of the four faces, 0.62 m wide, 0.05 m proud.
- **Hall (mandapa)** in front: 3.00 × 2.60 m, **4 pillars**, flat roof, soffit 2.40 m above the
  plinth [CODE beam soffit min 2.40].
- **Door** to the sanctum 0.85 × 1.80 — deliberately low, as temple doors are.
- **38 stone steps** [REF S5]: riser **0.165** m, tread **0.30** m, width 2.40 m →
  rise **6.27 m**, run **11.40 m**. Built as its own object so it can meet any terrain.
- **Saffron flag** on a 2.60 m bamboo at the shikhara, cloth 0.90 × 0.55, sagging.
- **Bell**, brass, 0.26 dia × 0.34, hung from the hall beam at 2.05 m — built by **spin**.
- **Imprecision is authentic** [REF-09 §3]: *"a lot of these ancient things aren't perfectly lined
  up anyway."* Bands get ±0.4° and ±8 mm. **Do not build it plumb.**
- Whitewashed [REF S5]; shikhara **red-orange** [REF-13 §8].

## 7 · THE CHOWK STATUE — `STATUE.blend`
S2: *"a person-scale statue on a plinth … figure ~2.4 m on a stepped plinth 2.6 m high and
3.2 m square … Painted, garlanded, a small railing round it, four floodlights on short posts
aimed up (unlit at 06:45)"*. S2 also states plainly that **published data is about 38 m monuments
and is useless**, and that the working figure stands until measured off Aditya's footage.

| element | dimensions | source |
|---|---|---|
| stepped plinth, 3 steps by inset → extrude | 3.20 sq base → 1.60 sq top, **2.60** high | S2 [REF] |
| figure, standing, robed, right arm raised | **2.40** high | S2 [REF] |
| **total** | **5.00** | derived |
| railing round the plinth | 0.90 high, 4.40 sq, 12 posts | S2 "a small railing" [REF] |
| garland | 0.42 dia at the neck | S2 [REF] |
| 4 floodlights on short posts, aimed up | 0.75 posts at the plinth corners | S2 [REF] — own collection, so the infrastructure build can exclude it |

**Figure proportion:** head = 1/7.5 of height = 0.32 m; shoulder width 0.58 m; the figure must
read as a person **from any angle** [PLAN §1]. Built from an edge skeleton + **Skin + Subdivision**
(verified in REF-05 §7), with a dhoti and a shawl as separate lofted surfaces.

## 8 · THE AUDIT EACH SCRIPT RUNS  (RULE 4 — fails loudly)
1. Every part's `dimensions` match this table to **±5 mm**.
2. Every part's origin is at its base: world `min Z == 0` to ±1 mm.
3. Every part's origin is horizontally centred on the part to ±5 mm (except the deliberately
   asymmetric C2, C3-on-W1, G3, C4, C11 — each declared in the script).
4. The wall-plane rule: recessed parts have `max Y ≤ +0.001`; projecting parts have
   `min Y ≥ -0.001`; the declared both-sides parts are listed by name.
5. Scale is applied: `scale == (1,1,1)` exactly.
6. Awning clear height ≥ **2.20 m** [CODE]. Parapet height ≥ **1.00 m** [CODE].
   Shutter ≤ 3.00 m high and 2.4–3.7 m wide [CODE]. Stair riser ≤ 0.190, tread ≥ 0.250 [CODE].
7. Face count per part and for the library as a whole, printed and bounded.
8. Temple: total **5.20 m** ±0.01; 38 steps counted from the geometry, not from the loop variable;
   step rise/run measured off the mesh.
9. Statue: figure 2.40 ±0.02, plinth 2.60 ±0.01, plinth base 3.20 sq ±0.01, total 5.00 ±0.02.
10. Peak memory printed. Nothing here should approach the 8 GB limit.

## 9 · WHAT THIS LIBRARY DELIBERATELY DOES NOT CONTAIN
- **The buildings themselves.** The boxes, the vertex groups and the scatter are component 4's
  build script, not the library.
- **The close-up grime layer** — the 0.6 m dust band, staining under each tank, posters, per-shutter
  wear. [S0 §4: authored per object, cannot be instanced, stays inside the scenario circles.]
- **Anything electrical beyond the meter box and its conduit** — poles, wires, transformers and
  service drops are component 5 and another chat is building them.
- **Vendor carts, charpais, hand pumps** — component 7 (LIFE).
