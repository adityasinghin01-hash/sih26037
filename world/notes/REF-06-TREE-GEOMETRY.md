# REF-06 · TREE GEOMETRY, VARIATION, AND HOW THINGS MEET
Written 3 Sep 2026 from **Aditya's own bus footage (5.2 min, 170 frames)** plus peer-reviewed
tree-architecture research. **His footage is the primary evidence and it overrules the stock
photos.** Supersedes `trees-pass-01.md`.

## 0 · THE CORRECTION THAT MATTERS MOST
`trees-pass-01.md` concluded "build a ficus, the aerial roots are the differentiator."
**That is wrong for our location.** Those six stock images are southern India — banyan, aerial
root curtains, red laterite soil. **Aditya's own western-UP footage contains none of it:**
no banyan, no aerial roots, no laterite. REF-04 and S0 already said "no banyan"; the footage
now proves it. Build neem-type broadleaves, eucalyptus/poplar rows, and vine-smothered masses.

## 1 · THE GOVERNING RULE
**A tree's shape is not random variation on a template. It is a RECORD OF WHAT HAPPENED TO IT.**
Same species, same age, wildly different shapes — because each one was constrained differently.
Model the *cause*, and the variation comes out for free and reads as true.

### The eight causes, all seen in his footage
| # | Cause | What it does to the shape |
|---|---|---|
| 1 | **Utility pruning** | Crown cut on a **straight plane** along the wire run. An organic blob with one flat face. Visible in b2_083: the cable line and the foliage edge coincide exactly |
| 2 | **Road-side clearance** | Vertical plane where the crown stops at the carriageway edge. Crown is a **half-tree** |
| 3 | **Building on one side** | Crown squeezed narrow and pushed tall; leans out over the road toward light (b2_081) |
| 4 | **Neighbour crowding** | Crown **elongates along the row, narrows across it** (arboriculture, REF-04 §7) |
| 5 | **Fodder lopping** | Branches cut back to stubs every ~3 years; regrowth is a **dense broom of thin shoots** from a thick stub. Done in winter when fodder is scarce |
| 6 | **Vine smothering** | Whole crown draped in creeper → **bulbous, melted, drooping silhouette** with no readable branch structure. Seen twice in b2 (frames 117, 119). **Nothing in any tree library looks like this** |
| 7 | **Death / damage** | Bare fan of pale limbs standing inside a green mass (b2_079) |
| 8 | **Free-standing** | The only one that is actually round |
**Rule for the build: no more than 1 in 6 trees may be the round free-standing form.**

## 2 · THE NUMBERS — sourced
**Neem (*Azadirachta indica*), our hero:**
height **15–20 m** (occasionally 35–40) · **branches at 2–5 m** into a broad round or oval crown ·
crown **15–20 m** on old free-standing specimens · trunk **30–90 cm** ·
leaves pinnate **20–40 cm** long with **20–31 leaflets** of 3–8 cm.
Young roadside specimens 8–14 m — **and that is what his footage mostly shows.**

**Branching geometry (da Vinci / pipe model, PLOS One 2014):**
- **Sum of daughter cross-sectional areas = mother cross-sectional area.** So for two equal
  children, each child diameter = parent / √2 = **0.707 × parent**. This is the single most
  useful number for building a tree procedurally.
- Measured daughter/mother ratio sits **near 1.0** for two-way splits, and **deviates upward
  for three-or-more-way splits.**
- The ratio **rises gently with branching angle from 0–60°, then sharply from 80–90°.**
- Measured branch slope, broadleaf (*Fagus*): **30.5 ± 15.0°** at the base, **20.6 ± 15.3°**
  along the branch. Conifer (*Abies*): 14.7 ± 7.8°.
  **Use 30° ± 15 for broadleaf branch angles. The ±15 is the whole point — it is not a constant.**

**Crown asymmetry:** driven by trees rearranging the crown **away from light-limited space** —
directional lateral expansion on the open side, **self-pruning of branches** on the shaded side.
It is an active strategy, not damage. So the crown's centre of mass is **displaced off the trunk**,
and the trunk is **not in the middle of the crown.**

**Crown shyness:** gaps open between neighbouring crowns through **mechanical abrasion** — tips
collide in wind and snap. **Stronger in slender trees** (high height:diameter ratio), which sway
more (Sc vs slenderness, R² = 0.484, P < 0.01). Broadleaf-to-broadleaf gaps are **wider** than
conifer-to-conifer. No published gap width in metres — so **derive it from sway, do not invent it.**

## 3 · HOW THEY MEET — measured off the footage
- Crowns **merge into one continuous green mass** when close, **but the top edge still reads as
  separate lumps.** Never a smooth hedge silhouette.
- **Height varies ±25 % along any row.** One tree always stands clearly above the rest.
- **A treeline is closed at the bottom.** From ~1 m up it is a solid dark wall — you do not see
  through it and you do not see individual trunks. Trunks are only visible on isolated trees.
- **Species are MIXED, never a monoculture avenue** — broadleaf, palm and ornamental in the same
  30 m (b2_075). Our "neem in ten forms" is not enough on its own.
- Vertical layering: **dark and closed at the base, lighter at the top** where sun hits new growth.

## 4 · HOW THEY BLEND — the thing Aditya actually asked for
**With buildings:**
- Trees sit **behind and between** buildings and fill every gap, so the skyline is
  **building–tree–building–tree.** A continuous run of building with no tree in it reads false.
- Crowns **rise above the roofline and drape down onto roofs.**
- Crowns are **flattened on the building face** and pushed out over the road.
- Foliage **partly hides shop signage.** Signs are never fully clear.
- Trees are planted **in the raised concrete shop plinth**, not in soil beside it.
- **Wires and poles pass THROUGH the crown**, not around it. The tree grew into them.

**With open ground:**
- Verge grass runs 2–3 m and then the tree mass starts — **no transition, no mulch ring, no bed.**
- **Under a dense crown the ground layer dies.** Bare dark damp earth, no grass. The shade
  footprint is a visible hole in the vegetation.
- **Litter and rubble collect at the base** of the roadside trees, never in the open.
- The far treeline is **layered by haze**, not by detail — silhouette only past ~300 m.

**Trunk treatment:** a **whitewashed band** at the base on trees near settlement, and blue
paint on poles, bollards and verandah columns alike — the local convention is to paint whatever
vertical thing stands near the road.

## 5 · WHAT THIS CHANGES IN OUR BUILD
1. Ten neem sculpts is not the unit of work. **Build one neem and eight CONSTRAINT OPERATORS**
   (wire cut, road cut, wall squeeze, neighbour elongation, lopping, vine drape, dieback, free)
   and apply them by what is actually next to each tree. Variation becomes automatic and *caused*.
2. **Branch children at 0.707 × parent diameter, angle 30° ± 15°.** Not a guessed taper.
3. **Mix species in every run.** Add a palm and an ornamental to the neem library.
4. **Kill the ground layer under every dense crown** — that shade footprint is free realism.
5. **Route wires THROUGH crowns**, then cut the foliage on the wire plane.
6. **Vine-smothered form is mandatory** — at least two per scenario. Nothing else looks so local.
7. **±25 % height variation along every row**, with one tree standing above.
8. Treelines: **closed from 1 m up.** No visible trunks in a mass.

## 6 · COLOUR AND GRADE, read off his footage
Sun high and hard. **Shadows dense, blue-black, not lifted.** Highlights clip on white vehicles
and sky. Sky strongly saturated blue at zenith, **pale and desaturated at the horizon**.
Greens are **yellow-green in sun, blue-green in shade** — two different hues, not one lit twice.
**The road is light warm grey, never black** — dust lightens it.
Visible **compression blocking in the shadows.** Our S0 stays late-September 06:45; this footage
is monsoon midday, so take the STRUCTURE from it, not the light.

## 7 · SOURCES
Aditya's bus footage `video/bus/` (3 clips, 170 frames, sheets in `video/bus/sheets/`).
PLOS One 2014 *Tree Branching: Leonardo da Vinci's Rule versus Biomechanical Models*.
*Trees* 2024, asymmetric crown spread of street trees. *Annals of Botany* 2021, crown shyness in 3-D.
Neem morphology: Winrock/EAFRINET factsheets.
