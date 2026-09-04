# S0b · THE RAILWAY — addendum to [S0] and [S4]
Written 3 Sep 2026, BEFORE any railway object exists. Rule 1.
**Reason this addendum exists:** the original Overpass pull asked only for highways and
waterways, so the railway was absent from `najibabad_metres.json`. S4 was written saying the
interchange "crosses a road and a rail line on stacked bridges" — that was correct, but there
was no geometry for it. Re-queried 3 Sep: the line, the station and the yard are all real.

## WHAT IS ACTUALLY THERE — measured, not invented
- **12,055 m of railway inside the 2 km box.** Broad gauge, 1676 mm, **electrified 25 kV AC**
  (`electrified=contact_line`, `voltage=25000`, `frequency=50`), `usage=main`.
- **Najibabad Junction station at (−552, −895)** — station code **NBD**, Northern Railway.
  Inside the box, south-west corner.
- **A yard / station throat**: ~10 parallel tracks between x −1400…0, y −1100…−760.
- **1,826 m of track runs through the S4 circle**, passing **48 m from its centre**.
- **56 m from the S2 chowk centre** — so the line is visible from the chowk too.
- **NH734 crosses the railway ON A BRIDGE at (118, −748)**, and a second trunk deck at
  (125, −737). Both tagged `bridge=yes`. **This is S4's "stacked bridges" and it is real.**
- **NH534 crosses on a bridge at (655, −341)** — inside the box, outside S4.
- **TWO LEVEL CROSSINGS at (543, −670) and (548, −658)** where a *secondary* road crosses the
  rails **at grade**, 220 m east of the chowk. Tagged `railway=level_crossing`.
- `landuse=railway` corridor polygon, and a **`landuse=residential` "Railway Colony"**
  at x −851…−233, y −1136…−903.

## THE DIMENSIONS — every one sourced, none guessed
**Formation** (IPWE *Track Structure Ch. V — Formation*, Table I, basis 300 mm ballast cushion):
| | in bank | in cutting |
|---|---|---|
| BG single line | **6.85 m** | 6.25 m |
| BG double line | **12.15 m** | 11.55 m |
- **Track centres, double line: 5.30 m.**
- **Ballast cushion 300 mm**; ballast side slope 1:1 to 1:1.5.
- **Embankment side slope 2H:1V** generally (1.5:1 permissible to 3 m, 1.8:1 to 8 m).
  Cutting slope 1:1 in good soil.
- **Bank height / cutting depth not less than 1 m** in flat terrain (drainage + trespass).
- Cess **900 mm** in embankment, 600 mm in cutting.
- On curves widen the formation **+0.15 m single / +0.30 m double**.

**Overhead equipment** (*Indian Railways Schedule of Dimensions, 1676 mm BG, rev. 2004*, Ch. V-A):
- Minimum contact wire height above rail level: **5.50 m in the open · 5.50 m at level
  crossings · 4.80 m under bridges and in tunnels** · 5.80 m in sheds.
- **Maximum stagger of the live conductor: 200 mm on straight, 300 mm on curves** — this is the
  zigzag that makes OHE read correctly. It is never a straight wire.
- Pantograph collector width 1800 mm.

**Structures over the line** (SOD Ch. I item 10(iii), and IRC:SP:90 §6.22):
- SOD, heavy overhead structure (ROB / flyover) over 25 kV AC: **minimum 5.870 m above rail
  level**, for 1600 mm either side of track centre. Light structures (FOB) 6.250 m.
- SOD note (5): provide **+275 mm** for future track raising.
- IRC:SP:90 §6.22.1: **minimum 6.25 m above rail level**, and defers to the railway.
- **WE BUILD 6.25 m clear above rail level.** It satisfies both, and it is the higher number.
- IRC:SP:90 §6.22.2 — clear distance between abutments, BG at right angles:
  **2 lines 11.0 m · 4 lines 22.0 m.**

**Platforms** (SOD Ch. I item 3–6):
- Centre of track to platform coping face **1670–1680 mm**.
- High passenger platform **760–840 mm above rail level**. Medium 455 mm max.
  Goods platform 1065 mm max.

## THE CONSEQUENCE FOR S4 — a corrected silhouette
The rail-crossing deck sits **6.25 m above rail level**, and the rail is itself ~1.0 m of
formation plus ~0.68 m of ballast+sleeper+rail above local ground. **So its soffit is ~7.9 m
above the ground, against 5.5 m for the decks that only cross roads.**
**The interchange is therefore STEPPED, not one flat table** — the rail deck is the high one.
That is a visible, real difference and it is what makes the place read as a real interchange.
Approach ramps at **IRC:SP:90 §6.14 — "in any case gradient greater than 3.5 percent should not
be provided"** — so lifting a deck ~9 m needs **~260 m of ramp each side**, which is exactly why
the map's trunk bridge ways here are 121–351 m long. The data and the code agree.

## WHAT GETS BUILT, BY STAGE
**Stage 2 (blockout):** the formation as an embankment solid at 6.85 / 12.15 m with 2:1 sides ·
the yard as ~10 parallel formations at 5.30 m centres · the station platform masses at 0.84 m ·
the two road bridge decks over the line at 6.25 m clear · the two level crossings as a flat
break in the formation · the Railway Colony as building masses.
**Stage 3:** rails, sleepers at 60 cm centres, ballast shoulders, check rails at the crossings.
**Stage 4:** OHE masts and portals, the level-crossing gates, signals, the station building.
**Stage 9:** the contact wire with its 200 mm stagger, and the catenary as a **parabola**.

## WHAT IS NOT CLAIMED
The station building itself is not mapped — only the station node. Its form is invented and
**must be marked as invented**, like the hill. Track count in the yard is read off the OSM way
count, not a survey. No train is scheduled in any scenario; if one appears it is set dressing.
