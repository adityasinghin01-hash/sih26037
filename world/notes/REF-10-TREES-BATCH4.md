# REF-10 · TREES — FOUR METHODS, AND THE FIX FOR THE 51-MILLION-FACE FAILURE
**Batch 4 of Aditya's video study.** 5 videos, 1 h 36 m. **This is the batch that matters most:**
our trees have failed twice, and REF-06 defined *what* is wrong without saying *how* to build it.
This closes that.

## 0 · THE HEADLINE — the leaf problem is solved
We once killed the scene at **220,000 leaves × 7 trees = 51 million faces.**
**That was the wrong unit of work. A leaf is not a mesh. A whole branch of leaves is ONE ALPHA CARD.**
`Shift+A > Image > Mesh Plane` imports a plane with transparency already wired (image → Base Color
**and** image alpha → Alpha). Then **cut the plane down close to the silhouette** —
*"get relatively close to the outline as narrow as possible; we don't want to add too many faces
that's unnecessary."*
**Neem is the perfect case for this:** its leaf is pinnate with **20–31 leaflets** (REF-04), so a
single card carries an entire frond. What cost 220,000 faces costs about 8.
**Consequence, and it connects to REF-09 §9: transparency is not free at render.** Set Cycles
**Light Paths > Transparency to 8**, which Batch 3 recommended *specifically because of tree leaves.*

## 1 · FOUR METHODS, AND WHICH TO USE WHERE
| Method | Source | Use it for |
|---|---|---|
| **A · Sapling Tree Gen** (ships with Blender) | Bro3D | **The workhorse neem.** Fast, parametric, and it has a PRUNING tab |
| **B · Geometry-nodes generator from a curve** | Kenan Proffitt | **The eight constraint operators**, and mass instancing |
| **C · Sculpt → multires bake → alpha cards** | Grant Abbitt | **The one hero tree** the camera passes within 3 m of |
| **D · Skin modifier + deform + remesh** | Critical Giants | Gnarled character trees, and **ROOTS** |

## 2 · METHOD A — SAPLING TREE GEN, and it is free and built in
Enable **"Sapling Tree Gen"** in Preferences > Add-ons, then `Add > Curve > Sapling Tree Gen`.
Read straight off his panels:
- **Geometry:** Bevel · **Bevel Resolution · Curve Resolution** (these two are the polycount dials) ·
  Shape / Custom Shape · **Branch Distribution · Branch Rings · Random Seed · Tree Scale**
- **Branch Splitting** — the important tab: **Levels** (his caption labels them
  **trunk / branches / sub-branches**) · Base Splits · Trunk Height · **Split Angle + Split Angle
  Variation** · **Rotate Angle + Rotate Angle Variation** · Segment Splits · **Outward Attraction**
- **Leaves:** Show Leaves · Leaf Shape (Hexagonal / Rectangular) · **Leaf Object** · count ·
  **Leaf Distribution (Inverse Conical)** · Leaf Down Angle · Rotate · Scale X/Y · Horizontal Leaves
- **Pruning:** **Prune Ratio · Prune Width · Prune Width Peak · Prune Power High / Low**

**Three of these map straight onto our sourced research:**
- **Split Angle + Variation** → REF-06's measured **30° ± 15°**. The variation field exists precisely
  because the angle is not a constant.
- **Outward Attraction** → phototropism, the light-seeking that causes crown asymmetry.
- **THE PRUNING TAB IS REF-06'S CONSTRAINT MECHANISM, ALREADY BUILT.** Prune Ratio and Prune Width
  define the envelope the crown is allowed to fill. **A tree cut back by the electricity board, or by
  the road, or squeezed between two buildings, is a pruning envelope — not a different model.**
- **`Leaf Object` accepts a custom object.** So: **Sapling generates the branches, and the leaf object
  is our alpha-card neem frond.** That is the complete, cheap production tree.

## 3 · METHOD B — THE GEOMETRY-NODES GENERATOR, node by node
**Source: Kenan Proffitt (35:57).** Draw a curve, get a tree. This is the one that gives us total
control and mass variation.

**Trunk:**
```
Bezier Curve ─► Resample Curve (trunk resolution)
             ─► Trim Curve            ← enables a growth animation, optional
             ─► Set Curve Radius ◄── Float Curve ◄── Math(Subtract from 1) ◄── Spline Parameter[Factor]
             ─► Curve to Mesh   ◄── Curve Circle (profile)
```
- **`Spline Parameter > Factor` is the master value.** 0→1 along the curve. It drives taper, branch
  size, branch angle and leaf density. *"This can be used for a lot of different things."*
- **Float Curve** draws the trunk profile — root flare at the base, character up the stem.
- **Separate trunk resolution from branch count**: `Ctrl+Shift+D` duplicates the Resample node while
  keeping its input, so the two are independent.

**Which points grow a branch — this IS our constraint system:**
```
Spline Parameter[Index] ─► Compare (Less Than)    ─┐
Spline Parameter[Index] ─► Compare (Greater Than) ─┴► Compare(Equal) ─► Selection
Random Value (Boolean) ─► Boolean Math (NOT) ─► Pick Instance     [probability + SEED]
```
Less-Than kills branches above a height; Greater-Than kills them below; together they bracket the
crown. **Every one of REF-06's eight causes is a selection on this socket:**
wire cut = a Z threshold · road cut = an X/Y threshold · wall squeeze = a directional threshold ·
lopping = aggressive culling plus short regrowth · dieback = culling with no regrowth.

**Branch angle, and the biology is correct:**
`Align Euler to Vector` → Rotation, with **Factor = the spline parameter through a Map Range**.
His reasoning, unprompted: *"branches lower down stretch out further than the branches at the top…
the ones at the top can be straight up because they're trying to find the sunlight; the ones at the
bottom go out further because they're also trying to find the sunlight."*
**Rotation around the trunk: `Random Value (Vector)` into the Align Euler node's rotation — zero X
and Y, spin Z.** Without it you get *"a mohawk."*

**Bending the branches (they are rigid by default):**
```
Curve Line ─► Resample Curve   ← MANDATORY: a straight line has no middle points, so nothing bends
           ─► Set Position ◄── Vector Rotate ◄── Position, and Index ─► Multiply ─► Angle (axis Y)
```

**Recursion — more branch levels:** duplicate the whole branch frame, and **instance the new level on
the previous level's curve, taken from the Set Position output** (after bending, before radius).
**Join AFTER the previous level's Set Curve Radius**, so each level's thickness is independent.
Organise with **`Shift+P`** to frame and colour the groups; **`Ctrl+G`** to make the taper a reusable
group; **`Alt`+click** lifts a node out of a chain.

## 4 · METHOD C — THE HERO TREE, and how bark detail gets to be free
**Source: Grant Abbitt.** For the one or two trees the camera gets close to:
1. **Multiresolution modifier** on the trunk, sculpt the bark at high level.
2. **Cycles > Bake > "Bake From Multires"**, type **Normal**, to a **2048** texture,
   **no alpha channel**.
3. Hide the high-poly. The low-poly now carries all the bark in a normal map. Bake **cavity** and
   **AO** the same way.
4. Branches and leaves as **alpha cards** (§0), cut close to the silhouette.
5. **LOD is explicit:** a second, lower version with fewer branch cards and a **decimated trunk** for
   distance. **`Alt+D` makes a LINKED duplicate** (shared mesh data) — use it, with pivot set to
   **Individual Origins** and snapping off.
**Version note: his video is Blender 5; we are on 4.5.11.** Multires baking and Import Images as
Planes both exist in 4.5, so this transfers — but check, do not assume.

## 5 · METHOD D — THE GNARLED TREE, AND ROOTS
**Source: Critical Giants.** Fast and sculptural:
plane → **`M` merge at centre** → one vertex → **extrude vertices** to draw the tree as a stick figure
→ **Skin modifier** (thickness per vertex with **`Ctrl+A`** in edit mode, soft-select for many at once)
→ **Subdivision Surface** → **Simple Deform (Twist)** for natural trunk twist → a second
**Simple Deform (Bend)** for lean → **Remesh (Voxel ~0.2)** to fuse the branches into one organic mass.

**The detail nobody builds, and he is right about it:**
> *"A feature I often see lacking when people are making trees are the ROOTS… quite often dirt and
> earth has been ripped up in the ground, and roots just really add the realism."*
**Extrude roots out of the base.** Our trees stand at scoured road edges where REF-06 already
observed litter and rubble collecting at the trunk. **Roots belong there and we have never built them.**

**And he independently confirms REF-09 §11:** he arrays branches radially, dislikes the repetition it
creates, then **applies the array and edits the individual branches to break it.** Structured
repetition first, then break it — not random placement.

## 6 · RADIAL ARRAY — the same method for the third time
`Empty at the centre` + **Array modifier with Relative Offset switched to OBJECT OFFSET** targeting
that empty; rotate the empty, then raise the count until the ring closes. **Origins of the object and
the empty must be in the same place.**
Seen now in St Paul's (dome), Critical Giants (branches) and REF-09. **It is the standard tool for
anything radial** — our temple's plan, the gyratory kerb, a wheel, a shikhara's tiers.

## 7 · HOW THIS PLUGS INTO REF-06
REF-06 said: build **one neem and eight constraint operators**, applied by what is actually next to
each tree. Batch 4 supplies the machinery:
| REF-06 cause | Built with |
|---|---|
| Wire cut | Sapling **Prune** envelope, or a Z-threshold Compare on the branch selection |
| Road cut | Directional threshold on the branch selection |
| Squeezed between buildings | Narrow **Prune Width** + increased **Outward Attraction** on the open side |
| Neighbour crowding | Prune envelope elongated along the row |
| Fodder lopping | Aggressive branch culling + a short second level = the regrowth broom |
| Vine smothering | A separate draped alpha-card layer over the crown |
| Dieback | Branch culling with the leaf object removed |
| Free-standing | Default envelope. **Max 1 in 6.** |

## 8 · HONEST LIMITS OF THIS BATCH
- **Not one of these is an Indian tree.** They are firs, conifers and generic broadleaves.
  **Form still comes from REF-04 and REF-06** — neem 15–20 m, branching at 2–5 m, crown 15–20 m,
  pinnate leaves with 20–31 leaflets — and from Aditya's own footage.
- **None of them built a tree that had been cut, lopped, smothered or damaged.** Every tree in every
  video is an undisturbed specimen. **The entire causal argument of REF-06 is absent from all of
  them** — which is precisely why our trees will look local and theirs look generic.
- Two are partly promotions for paid files/patreon. The techniques shown are complete regardless.
- **Nobody measured anything.** No metres, no face counts except by implication.

## 9 · SOURCES
Bro3D *How I Make Realistic Trees in Blender for free* (Sapling, read frame by frame — no captions) ·
Kenan Proffitt *Geo Nodes Tutorial: How to Make Trees* · Grant Abbitt *Realistic Trees – Blender 5* ·
Critical Giants *Artistic Trees In Blender* · CG Geek *Low Poly Tree in 1 Minute*.
