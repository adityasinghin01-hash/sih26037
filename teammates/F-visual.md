# Stream F · Visual  — Aditya, Mac

**You own how this looks.** Built last, after the planner works. Beautiful scenes with a weak
planner is the losing tier, and TwinX already won with the scenes move — it will not win twice.

## Already done and proven
The pipeline is live and tested in Blender via MCP:
- **Zebu Bull** — correct hump, dewlap, upward horns. **Rigged**, so the walk/graze model drives it
- **Ahmedabad auto-rickshaw photoscan** — real scan, correct CNG livery, for hero shots
- **rSquare auto-rickshaw** (12.6k faces) for background traffic
- `kloofendal_43d_clear_puresky` HDRI + `asphalt_02` tiled every 3 m
- Two cameras: **140 deg dashcam** (matches METEOR exactly) and **50 mm hero** with depth of field
- Cycles, AgX, adaptive sampling 0.01/1024, volumetric haze

## The principle
**Do not model. Assemble.** Quality order: lighting > colour management > surface imperfection >
camera imperfection > atmosphere > geometry. Mesh detail is sixth.

## Your job, in order
### F1 — MATLAB writes `results/<run>/trajectories.csv`, Blender reads it
Columns `t,actor_id,class_id,x,y,z,yaw`. MATLAB computes; Blender only renders.
### F2 — Drive the zebu's armature from the two-state model
Walking 0.41 m/s, grazing 0.06 m/s, with the turning angles from research section 13.
A cow that *moves* like a cow beats a prettier static one.
### F3 — The side-by-side
Because the virtual camera matches METEOR's dashcam exactly — 1920x1080, 140 deg, 30 fps — put a
**real METEOR frame beside our render on one slide**. Strongest visual argument available, and it
costs nothing because we matched intrinsics anyway for the feature vector.
### F4 — The real-footage composite
Your own Meerut footage with the planner's reasoning overlaid. **Nothing rendered beats real
video.** This is the hero shot.
### F5 — Credit every asset
All four models are CC Attribution. Poly Haven is CC0. Names go in the repo. Borrow freely,
cite loudly.

---

## What you use

| | |
|---|---|
| **Stack** | Blender 4.x (Cycles) + MATLAB for trajectories |
| **Machine** | Mac |
| **IDE / agent** | **Claude Code** (Aditya) |
| **Key functions & tools** | Blender MCP · Poly Haven (CC0) · Sketchfab · Cycles · AgX |

**Setup:** `docs/SETUP.md` — 20 minutes.
**Before you write any code:** read `docs/INTERFACES.md`. It is frozen; five other people build
against it. If your agent proposes editing it, the answer is no.

**Reference docs you will need:**
`docs/PRD.md` (the whole idea) · `docs/ROADMAP.md` (phases and gates) ·
`docs/metrics.md` (M1–M10) · `docs/CLAIM-LEDGER.md` (never state a number that is not in it)
