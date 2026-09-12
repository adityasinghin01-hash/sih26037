# THE TWO BACKUP SCENARIOS — MATLAB
Written 4 Sep 2026 **before building** (Rule 1). This is the BACKUP. The detailed city is being
built in a separate Blender chat; if it lands, its geometry replaces what is here and these two
scenarios come back on top of it. **Nothing in this folder touches Blender.**

**THE STANDARD: less, but properly built.** Everything the planner can see, hit or measure
against is REAL and ASSERTED. Everything that is only scenery is massed — but massed *well*.

## S1 · THE FOREST CATTLE CROSSING
**Road: the REAL Najibabad tertiary centreline**, from `map/matlab_roads.csv`, offset
(+35.0, −100.0) removed. 7.0 m carriageway (S0 §4), earthen shoulders 1.2 m, no kerb.
It curves through ~133°, and that curve is load-bearing — see the occluder note below.

**Setting: forest to both shoulders.** Trunks, canopy line, undergrowth. One clearing on the
left where the cattle emerge.

**THE REVEAL — CORRECTED 4 Sep AFTER MEASURING IT. This paragraph used to overclaim.**
It said the treeline and the road's curvature did the hiding, so the reveal was "*computed*,
not authored". **Measured, that is false**, and REF-17 s7c carries the numbers:
- road curvature at the cow (station 300) is **radius 1020 m — straight**; the tightest bend
  on the route is radius 63 m at station **511**, 211 m past her;
- the natural reveal from trunks and scrub alone, swept over 17 stations, ranges **4 m to
  134 m**, and only 4 of 17 land in a usable 30-60 m; across 8 seeds it ranged 34-110 m.

**The forest cannot deliver a specified reveal, and the road does not bend where the cow is.**
So ONE thicket is **authored** at the verge 26 m short of her, and its radius is **solved by
bisection** until the ray-marched reveal matches the written 42 m. It solves to **r = 3.48 m,
reveal 44 m** — the 2 m residual is the ray-march step.

**What is honest to claim, and all that is claimed:** the occluder is authored, its effect is
**measured** by marching the sight line, and the result is repeatable rather than left to a
random seed. Verified by eye as well as by number - the cow is hidden at 60 m, a sliver of her
shows at 44 m (3 of 5 points across her body), and she is fully clear by 36 m.
**Do not let anyone present this as an emergent property of the forest.**

**The cow — THE HERO. Everything else in S1 exists to make this moment happen.**
- Zebu: **2.05 × 0.64 × 1.46 m**, withers 1.28 m. **CORRECTED 4 Sep.** This line used to
  read 2.20 × 0.85 × 1.43 "(REF-04)", and REF-04 says no such thing — its §2 gives body
  width **57–71 cm**, so 0.85 was 140 mm above the top of the documented range. The figures
  now here are S1-CATTLE-CROSSING.md's own (205 × 64 × 146 cm) and all sit inside REF-04.
  **This is not cosmetic: the cow's width IS the gap arithmetic.** With 0.64 m the written
  numbers close to 30 mm; with 0.85 m they cannot close at all.
- Gait: **1.2 m/s, stride 1.68 m, 43 strides/min.** 1.68 × 43/60 = **1.204 m/s** — stride ×
  cadence equals speed, so the feet cannot slide.
- Walks from the left verge to the centreline, then **STOPS AND NEVER MOVES AGAIN.**
  It does not negotiate. It does not care that we are there.
- Built with `smoothTrajectory(cow,[verge; centreline],[1.2 0])` — **verified 4 Sep: the actor
  holds its final position for the rest of the run.** This is a MathWorks primitive, not
  hand-rolled motion.
- **2–3 more cattle** waiting in the clearing, so it reads as a herd crossing rather than one
  animal placed on a road.

**THE ARITHMETIC THAT IS THE RESULT — computed and asserted, never assumed:**
carriageway 7.00 m · cow occupies 2.5–3.2 m in from the left edge · **free width right = 3.80 m**
· ego 1.70 m, **1.90 m with mirrors** · **margin 0.95 m each side.**

**Other actors** (written script): oncoming auto-rickshaw 2.63 × 1.30 × 1.70 (forces the abort) ·
motorcycle 1.90 × 0.70 × 1.30 **on our side of the road** · tractor-trolley 5.60 × 2.30 × 2.60 ·
a static bullock cart and a parked motorcycle.

**The action:** 52 km/h → treeline breaks → cow at 42 m → probe → measure → abort for the auto →
retake → through at 8 km/h with 0.95 m clearance. The cow never moves.

## S2 · THE CHOWK — an unsignalled GYRATORY
**CORRECTED 5 Sep. This section used to say "a designed 4-arm chowk... four arms at 90 deg"
and called the real node unusable. That was the cautious reading and it was the weaker one.**

`S2-THE-CHOWK.md` §0 concludes *"this is not two roads crossing. It is a gyratory"*, and
REF-17 §5 measured the same thing independently: six road-ends, four tertiary arms in **two
near-parallel pairs** — two leaving north-east, two returning south-west. Those agree, so S2
is now built on them.

**REAL, and S2 carries a map claim of its own:** the node measures **(341.6, −578.6)** against
a written (340.1, −579.9) — 1.9 m — and the arm bearings **46 / 62 / 232 / 237** are every one
within **1°** of the map.

**OURS, authored, and never to be presented as the map: THE ISLAND.** There is no island in
the OSM data. The gyratory is built to **IRC 65:2017 Table 6.2**, whose three numbers are a
fixed pairing and are asserted as a set: **central island 24 m + 2 × circulatory carriageway
8 m = inscribed circle 40 m.** Design speed 30 km/h; weaving length comes out at 47 m against
a 30 m minimum. Splitter islands, kerb bands, give-way lines, plinth, statue and railing are
authored too.

**THE CIRCULATING CARRIAGEWAY CARRIES NO LANE MARKINGS.** That is the fact the scenario turns
on: there is no Cartesian reference path to follow, which is exactly what MathWorks' shipped
planner requires and cannot synthesise. **It cannot start.** Structural, not tuned.

**Scope: no buildings.** Kerbed island, stepped plinth and statue, grass verges, post-and-rail
fence, and a massed backdrop treeline. "Less, but properly built."

**Actors:** the circulating auto whose **measured 1.80 km/h lift IS the yield** the ego reads ·
a motorcycle the wrong way round the island · a bus taking the gyratory wide and leaving along
the exit arm · **two cows lying on the island** — off the carriageway, so they change nothing,
which is the deliberate contrast with S1 · a parked Tata Ace leaving **2.90 m** of lane.

**The action:** arrive on arm D at 26 km/h → give-way line, nobody yields → nose forward at
0.4 m/s and read the response → the auto lifts → commit → circulate 1.4 m off the island kerb
→ hold the line past the wrong-way rider → exit onto arm A.

## WHAT IS DELIBERATELY NOT BUILT
Potholes, the speed breaker, the culvert · 21 people, 45 birds, insects, litter, dung ·
buildings beyond massing · crops and the seven vegetation layers · sky, cloud and weather ·
sensor noise models · **Stream D's planner** · **Stream C's ONNX model**.
Each is either the Blender chat's job or a teammate's. Building them here throws the work away.

## THE DRIVER IS A PLACEHOLDER AND IS LABELLED ONE
Enough to move the ego through the written beats so the world can be seen and filmed.
It makes **no planning claim**. Stream D's planner drops into the same seat unchanged, because
the boundary is the frozen **S1 TrackList** (`AGENTS.md` §3) and that boundary does not move.

## OUTPUT
`map/ego_S1.csv`, `map/ego_S2.csv` → `time, x, y, heading, speed` in the SHARED frame, so the
Blender chat drives the film along what the planner actually did.
Check renders in `matlab/renders/`. Findings logged to `notes/REF-17-MATLAB-PLANNER.md`.

## ASSERTIONS EVERY SCRIPT MAKES, AND FAILS LOUDLY ON
Carriageway width to 1 mm · cow gait: stride × cadence = speed to 1 mm/s · the S1 clearance
arithmetic ≥ 0.90 m each side · cow final position held to 1 mm for the rest of the run ·
ego never in its own TrackList · no NaN/Inf in any logged pose · route joins closed.
