# COMPONENT 4 PASS 1 - ITEM 2: the facade part library. Spec: S0-THE-WORLD.md "COMPONENT 4 PASS 1
# - ITEM 2", written 11 Sep 2026 before this script, per Rule 1. Every dimension is NBC
# India / IS 6248 (REF-03 s2), never guessed. Method is REF-09 s1-3: a plain box gets vertex
# groups per face and a module per group; each part here IS one of those modules, built by
# inset/extrude-style construction at real Blender-metre scale, origin at its own mounting base
# (REF-09 s2) so a later instancer places it correctly on a wall.
#   blender --background --python build/city/04_buildingparts.py
import bpy, os, sys, time, math, zlib, bmesh
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
PARTSBLEND = f"{REF}/blend/04_BUILDINGPARTS.blend"

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
COL = bpy.data.collections.new("BUILDING_PARTS"); sc.collection.children.link(COL)

# ---------------------------------------------------------------------------- mesh toolbox
MATS = {}
def mat(name, color, rough=0.7, metallic=0.0, alpha=1.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        m.blend_method = 'BLEND'
    MATS[name] = m
    return m

def recalc_outward(me):
    # hand-derived face winding is exactly the kind of thing this project's own rule says to
    # measure, not reason from - use Blender's own authoritative outward-normal solver instead
    # of trusting manually-ordered vertex loops (a real bug: axbox()'s original winding gave
    # every box INWARD normals, invisible/black from outside - caught on the balcony slab).
    bm = bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free(); me.update()

def axbox(name, m, x0, x1, y0, y1, z0, z1):
    verts = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    fs = [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], fs); me.update()
    recalc_outward(me)
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(m); COL.objects.link(ob)
    return ob

def bar(p0, p1, w, name, m):
    # a straight square-section prism from p0 to p1, thickness w - proven pattern from
    # 03e_railway.py's box_mesh(), copied here rather than imported (each build script is
    # self-contained per this project's own convention).
    a, bb = np.array(p0), np.array(p1)
    d = bb - a; L = np.linalg.norm(d)
    fwd = d / L if L > 1e-9 else np.array([0,0,1.0])
    ref = np.array([0,0,1.0]) if abs(fwd[2]) < 0.9 else np.array([1.0,0,0])
    side = np.cross(fwd, ref); side = side/np.linalg.norm(side) * (w*0.5)
    up = np.cross(side, fwd); up = up/np.linalg.norm(up) * (w*0.5)
    verts = []
    for base_pt in (a, bb):
        for sx in (-1,1):
            for sz in (-1,1):
                verts.append(tuple(base_pt + side*sx + up*sz))
    fs = [(0,1,3,2),(4,6,7,5),(0,4,5,1),(1,5,7,3),(3,7,6,2),(2,6,4,0)]
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], fs); me.update()
    recalc_outward(me)
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(m); COL.objects.link(ob)
    return ob

def prism(name, m, cx, cy, z0, z1, r0, r1, segs=16):
    verts = []
    for r, z in ((r0,z0),(r1,z1)):
        for i in range(segs):
            a = 2*math.pi*i/segs
            verts.append((cx+r*math.cos(a), cy+r*math.sin(a), z))
    fs = []
    for i in range(segs):
        j = (i+1) % segs
        fs.append((i, j, segs+j, segs+i))
    fs.append(tuple(range(segs-1, -1, -1)))            # bottom cap
    fs.append(tuple(segs+i for i in range(segs)))       # top cap
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], fs); me.update()
    recalc_outward(me)
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(m); COL.objects.link(ob)
    return ob

def join(name, obs):
    # deselect first - not a live risk here (this script starts from a genuinely empty scene,
    # read_factory_settings(use_empty=True), so nothing else exists to accidentally absorb), but
    # 04c_temple.py's own identical join() DID silently merge the scene's real HILL object into
    # TEMPLE_SANCTUM this way on its first run against a non-empty file (found 11 Sep) - matching
    # the fix here too, defensively, since this is the same operator with the same real footgun.
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs: o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    bpy.ops.object.select_all(action='DESELECT')
    return ob

def finish(ob):
    # REF-09 s2's checklist: convert (n/a, already mesh) -> join (done by caller) -> apply
    # scale -> origin to geometry is WRONG for wall parts (we set the origin explicitly per
    # part, at its real mounting base, not at the bounding-box centre) -> so just apply
    # transform and leave the origin where the geometry itself was built (already at the
    # mounting base by construction).
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    ob.select_set(False)

# real materials, once each
M_CONCRETE  = mat("PART_concrete", (0.62,0.58,0.52), 0.85)
M_PLASTER   = mat("PART_plaster",  (0.80,0.74,0.62), 0.75)
M_METAL_GAL = mat("PART_metal_galv", (0.55,0.56,0.58), 0.35, metallic=0.7)
M_METAL_RUST= mat("PART_metal_rust", (0.32,0.20,0.14), 0.75, metallic=0.3)
M_GLASS     = mat("PART_glass", (0.10,0.14,0.16), 0.10, metallic=0.0, alpha=0.35)
M_WOOD      = mat("PART_wood_door", (0.30,0.18,0.10), 0.65)
M_PLASTIC_TANK = mat("PART_tank_plastic", (0.10,0.35,0.55), 0.30)
M_FABRIC    = [mat(f"PART_fabric_{i}", c, 0.9) for i,c in enumerate(
               [(0.75,0.15,0.15),(0.85,0.80,0.70),(0.20,0.35,0.55),(0.90,0.85,0.20)])]
M_STAINED   = mat("PART_stained_concrete", (0.40,0.38,0.34), 0.9)
M_REBAR     = mat("PART_rebar", (0.25,0.22,0.20), 0.6, metallic=0.5)

FLOOR_H = 3.05   # NBC floor-to-floor 3.0-3.15 m (REF-03 s2)
parts = []

# ------------------------------------------------------------------------------- 1. WINDOW
# sill 0.9 m (REF-03 s2); origin at the sill line, z=0. Frame 1.05x1.35, bar 0.07 thick.
def build_window():
    W,H,T = 1.05, 1.35, 0.07
    obs = []
    obs.append(axbox("w_bot",  M_PLASTER, -W/2,W/2, 0,T,      0,T))
    obs.append(axbox("w_top",  M_PLASTER, -W/2,W/2, 0,T,      H-T,H))
    obs.append(axbox("w_left", M_PLASTER, -W/2,-W/2+T, 0,T,   0,H))
    obs.append(axbox("w_right",M_PLASTER,  W/2-T,W/2, 0,T,    0,H))
    obs.append(axbox("w_glass",M_GLASS,  -W/2+T,W/2-T, T*0.4,T*0.6, T,H-T))
    obs.append(axbox("w_sill", M_CONCRETE, -W/2-0.05,W/2+0.05, -0.06,T+0.02, -0.04,0.0))
    ob = join("PART_WINDOW", obs)
    return ob
parts.append(("PART_WINDOW", build_window(), (1.15,0.15,1.39)))  # incl. the sill's own overhang

# ------------------------------------------------------------------------------- 2. SHUTTER
# rolling shutter, 2.4-3.7 m wide / up to 3.0 m tall, laths 75 mm (REF-03 s2). Origin at floor.
def build_shutter():
    W,H = 3.0, 2.7
    obs = []
    lath = 0.075
    n = int(H/lath)
    for i in range(n):
        z0 = i*lath
        obs.append(axbox(f"sh_{i}", M_METAL_GAL, -W/2,W/2, 0,0.03, z0,z0+lath*0.92))
    obs.append(axbox("sh_box", M_CONCRETE, -W/2-0.08,W/2+0.08, 0,0.15, H,H+0.30))
    ob = join("PART_SHUTTER", obs)
    return ob
parts.append(("PART_SHUTTER", build_shutter(), (3.0,0.15,3.0)))

# ------------------------------------------------------------------------------ 3. BALCONY
# cantilever up to 0.9 m (REF-03 s2), 2.0 m bay, railing 0.9 m per IS residential guard height.
def build_balcony():
    Wd,Dp,SlabT,RailH = 2.0, 1.0, 0.12, 0.9
    obs = [axbox("b_slab", M_CONCRETE, -Wd/2,Wd/2, 0,Dp, -SlabT,0)]
    for x in np.linspace(-Wd/2, Wd/2, 8):
        obs.append(bar((x,Dp,0),(x,Dp,RailH), 0.025, "b_post", M_METAL_GAL))
    for y in (0, Dp):
        obs.append(bar((-Wd/2,y,RailH),(Wd/2,y,RailH), 0.03, "b_rail", M_METAL_GAL))
    obs.append(bar((-Wd/2,0,RailH),(-Wd/2,Dp,RailH), 0.03, "b_rail_s", M_METAL_GAL))
    obs.append(bar(( Wd/2,0,RailH),( Wd/2,Dp,RailH), 0.03, "b_rail_s2", M_METAL_GAL))
    ob = join("PART_BALCONY", obs)
    return ob
parts.append(("PART_BALCONY", build_balcony(), (2.0,1.0,0.9)))

# ------------------------------------------------------------------------------- 4. AC BOX
def build_acbox():
    W,D,H = 0.80,0.30,0.28
    obs = [axbox("ac_body", M_METAL_GAL, -W/2,W/2, 0,D, 0,H)]
    for i in range(5):
        y = D*0.15 + i*D*0.14
        obs.append(axbox(f"ac_vent{i}", M_METAL_RUST, -W/2+0.05,W/2-0.05, y,y+0.02, H*0.2,H*0.85))
    ob = join("PART_ACBOX", obs)
    return ob
parts.append(("PART_ACBOX", build_acbox(), (0.80,0.30,0.28)))

# ----------------------------------------------------------------------------- 5. SIGNBOARD
def build_signboard():
    W,H,T = 2.4,0.6,0.05
    obs = [axbox("sb_board", M_METAL_GAL, -W/2,W/2, 0,T, 0,H)]
    obs.append(bar((-W/2+0.15,0,0),(-W/2+0.15,-0.35,H*0.3), 0.03, "sb_brk1", M_METAL_RUST))
    obs.append(bar(( W/2-0.15,0,0),( W/2-0.15,-0.35,H*0.3), 0.03, "sb_brk2", M_METAL_RUST))
    ob = join("PART_SIGNBOARD", obs)
    return ob
parts.append(("PART_SIGNBOARD", build_signboard(), (2.4,0.4,0.6)))

# ------------------------------------------------------------------------------- 6. AWNING
# max 4.5 m long x 2.4 m projection, >=2.2 m clear beneath (REF-03 s2). Origin at wall mount.
def build_awning():
    # origin at the wall mount line (z=0), per REF-09 s2 - the instancer places this mount
    # line at the real absolute height (2.55 m, so the front edge after the slope clears the
    # required 2.2 m, REF-03 s2), not baked into this object's own geometry.
    L,Proj,T = 3.6, 2.0, 0.05
    drop = 0.30
    verts = [(-L/2,0,0),(L/2,0,0),(L/2,Proj,-drop),(-L/2,Proj,-drop),
             (-L/2,0,-T),(L/2,0,-T),(L/2,Proj,-drop-T),(-L/2,Proj,-drop-T)]
    fs = [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
    me = bpy.data.meshes.new("aw_slab"); me.from_pydata(verts, [], fs); me.update()
    recalc_outward(me)
    ob0 = bpy.data.objects.new("aw_slab", me); ob0.data.materials.append(M_FABRIC[0]); COL.objects.link(ob0)
    obs = [ob0]
    obs.append(bar((-L/2+0.2,0.05,0),(-L/2+0.2,Proj-0.1,-drop), 0.03, "aw_rod1", M_METAL_RUST))
    obs.append(bar(( L/2-0.2,0.05,0),( L/2-0.2,Proj-0.1,-drop), 0.03, "aw_rod2", M_METAL_RUST))
    ob = join("PART_AWNING", obs)
    return ob
parts.append(("PART_AWNING", build_awning(), (3.6,2.0,0.35)))

# ---------------------------------------------------------------------------- 7. DRAINPIPE
def build_drainpipe():
    H = FLOOR_H
    obs = [bar((0,0,0),(0,0,H), 0.04, "dp_pipe", M_METAL_GAL)]
    for z in (0.3, H*0.5, H-0.2):
        obs.append(axbox(f"dp_brk{z:.1f}", M_METAL_RUST, -0.06,0.06, 0.04,0.10, z-0.03,z+0.03))
    ob = join("PART_DRAINPIPE", obs)
    return ob
parts.append(("PART_DRAINPIPE", build_drainpipe(), (0.12,0.10,FLOOR_H)))

# -------------------------------------------------------------------------------- 8. GRILLE
def build_grille():
    # standing proud of the wall on its own mounting brackets, not floating - a real security
    # grille bolts to the wall face (y=0) and holds its bar-frame out at the standoff distance.
    W,H,T = 1.05,1.35,0.03
    standoff = 0.08
    obs = [axbox("gr_bot", M_METAL_RUST, -W/2,W/2, standoff,standoff+T, 0,0.05),
           axbox("gr_top", M_METAL_RUST, -W/2,W/2, standoff,standoff+T, H-0.05,H),
           axbox("gr_left", M_METAL_RUST, -W/2,-W/2+0.05, standoff,standoff+T, 0,H),
           axbox("gr_right", M_METAL_RUST, W/2-0.05,W/2, standoff,standoff+T, 0,H)]
    for x in np.linspace(-W/2+0.12, W/2-0.12, 7):
        obs.append(bar((x,standoff,0.02),(x,standoff,H-0.02), 0.012, "gr_bar", M_METAL_RUST))
    for x, z in ((-W/2+0.05, H*0.15), (W/2-0.05, H*0.15), (-W/2+0.05, H*0.85), (W/2-0.05, H*0.85)):
        obs.append(bar((x,0.0,z),(x,standoff,z), 0.015, "gr_bracket", M_METAL_RUST))
    ob = join("PART_GRILLE", obs)
    return ob
parts.append(("PART_GRILLE", build_grille(), (1.05,0.11,1.35)))

# ----------------------------------------------------------------------------- 9. STAIRCASE
# real riser/going: 0.15 m rise, 0.28 m going (IS building bye-laws residential range).
def build_staircase():
    riser, going, width = 0.15, 0.28, 1.0
    n = int(round(FLOOR_H/riser))
    obs = []
    for i in range(n):
        z0, z1 = i*riser, (i+1)*riser
        y0, y1 = i*going, (i+1)*going
        obs.append(axbox(f"st_{i}", M_CONCRETE, -width/2,width/2, y0,y1, 0,z1))
    railH = 0.9
    obs.append(bar((width/2,0,railH),(width/2,n*going,railH+n*riser), 0.03, "st_rail", M_METAL_GAL))
    for i in range(0, n, 3):
        y = i*going
        obs.append(bar((width/2,y,i*riser),(width/2,y,railH+i*riser), 0.02, "st_post", M_METAL_GAL))
    ob = join("PART_STAIRCASE", obs)
    return ob
_n_steps = int(round(FLOOR_H/0.15))
parts.append(("PART_STAIRCASE", build_staircase(),
              (1.0, _n_steps*0.28, _n_steps*0.15 + 0.9)))  # rise + the top railing's own height

# ---------------------------------------------------------------------------- 10. WATERTANK
# a ~1000 L Sintex-style roof tank, ~1.1 m diameter (r=0.55) x 1.0 m (REF-03's own rooftop note).
def build_watertank():
    r, h, legH = 0.55, 1.0, 0.3
    obs = [prism("wt_body", M_PLASTIC_TANK, 0,0, legH,legH+h, r,r*0.92, segs=14)]
    obs.append(prism("wt_lid", M_PLASTIC_TANK, 0,0, legH+h,legH+h+0.08, r*0.5,r*0.5, segs=14))
    for a in (45,135,225,315):
        rad = math.radians(a)
        x,y = (r*0.75)*math.cos(rad), (r*0.75)*math.sin(rad)
        obs.append(bar((x,y,0),(x,y,legH), 0.03, "wt_leg", M_METAL_RUST))
    ob = join("PART_WATERTANK", obs)
    return ob
parts.append(("PART_WATERTANK", build_watertank(), (1.1,1.1,1.3)))

# ----------------------------------------------------------------------------- 11. PARAPET
# minimum 1.0 m, 1.2 m+ on tall buildings (REF-03 s2) - built at 1.2 m so it satisfies both.
def build_parapet():
    L,H,T = 2.0,1.2,0.12
    obs = [axbox("pp_wall", M_CONCRETE, -L/2,L/2, 0,T, 0,H)]
    obs.append(axbox("pp_cap", M_CONCRETE, -L/2-0.02,L/2+0.02, -0.02,T+0.02, H,H+0.04))
    ob = join("PART_PARAPET", obs)
    return ob
parts.append(("PART_PARAPET", build_parapet(), (2.0,0.16,1.24)))

# -------------------------------------------------------------------------------- 12. DOOR
# standard door 0.9 x 2.1 m opening.
def build_door():
    W,H,T = 0.9,2.1,0.06
    obs = [axbox("dr_frame_l", M_CONCRETE, -W/2-0.05,-W/2, 0,T, 0,H+0.05),
           axbox("dr_frame_r", M_CONCRETE,  W/2, W/2+0.05, 0,T, 0,H+0.05),
           axbox("dr_frame_t", M_CONCRETE, -W/2-0.05,W/2+0.05, 0,T, H,H+0.05),
           axbox("dr_leaf", M_WOOD, -W/2+0.02,W/2-0.02, 0.005,T-0.005, 0,H)]
    for y in (H*0.3, H*0.7):
        obs.append(axbox(f"dr_batten{y:.1f}", M_WOOD, -W/2+0.08,W/2-0.08, T*0.6,T-0.005, y-0.02,y+0.5))
    obs.append(axbox("dr_handle", M_METAL_GAL, W/2-0.12,W/2-0.09, T*0.7,T-0.005, H*0.45,H*0.45+0.15))
    ob = join("PART_DOOR", obs)
    return ob
parts.append(("PART_DOOR", build_door(), (1.0,0.06,2.15)))

# ---------------------------------------------------------------------------- 13. METERBOX
def build_meterbox():
    W,H,D = 0.35,0.45,0.15
    obs = [axbox("mb_body", M_METAL_GAL, -W/2,W/2, 0,D, 0,H)]
    obs.append(axbox("mb_window", M_GLASS, -W/2+0.05,W/2-0.05, D-0.02,D+0.01, H*0.3,H*0.85))
    for x in (-0.06,0.06):
        obs.append(bar((x,0,0),(x,0,-0.4), 0.015, "mb_conduit", M_METAL_RUST))
    ob = join("PART_METERBOX", obs)
    return ob
parts.append(("PART_METERBOX", build_meterbox(), (0.35,0.17,0.85)))  # incl. conduits running down

# ---------------------------------------------------------------------------- 14. SAT DISH
def build_dish():
    obs = [prism("di_bowl", M_METAL_GAL, 0,0.15,0.0, 0.10, 0.30,0.05, segs=14)]
    obs.append(bar((0,0.10,0.05),(0,0.45,0.20), 0.015, "di_arm", M_METAL_RUST))
    obs.append(axbox("di_lnb", M_METAL_RUST, -0.02,0.02, 0.43,0.47, 0.18,0.24))
    obs.append(bar((0,0,-0.5),(0,0,0.0), 0.025, "di_pole", M_METAL_GAL))
    ob = join("PART_DISH", obs)
    return ob
parts.append(("PART_DISH", build_dish(), (0.6,0.5,0.7)))

# ----------------------------------------------------------------------- 15. DRYING WASHING
def build_washing():
    span = 1.8
    obs = [bar((-span/2,0,0),(-span/2,0,-0.15), 0.02, "wl_anchor1", M_METAL_RUST),
           bar(( span/2,0,0),( span/2,0,-0.15), 0.02, "wl_anchor2", M_METAL_RUST)]
    obs.append(bar((-span/2,0,0),(span/2,0,-0.06), 0.008, "wl_line", M_METAL_RUST))
    for i, mm in enumerate(M_FABRIC):
        x0 = -span/2 + 0.25 + i*(span-0.5)/max(len(M_FABRIC)-1,1)
        # a real hung garment/sheet billows well out from the line, not a near-flat drape -
        # front face bows out to +0.30 m, back face stays close to the line at -0.05 m.
        billow = 0.30
        verts = [(x0-0.20,-0.05,-0.02),(x0+0.20,-0.05,-0.02),
                 (x0+0.17,billow,-0.10),(x0-0.17,billow,-0.10),
                 (x0-0.15,billow*0.6,-0.62),(x0+0.15,billow*0.6,-0.62)]
        fs = [(0,1,2,3),(3,2,5,4),(0,3,4),(1,5,2)]
        me = bpy.data.meshes.new(f"wl_cloth{i}"); me.from_pydata(verts, [], fs); me.update()
        recalc_outward(me)
        ob0 = bpy.data.objects.new(f"wl_cloth{i}", me); ob0.data.materials.append(mm); COL.objects.link(ob0)
        obs.append(ob0)
    ob = join("PART_WASHING", obs)
    return ob
parts.append(("PART_WASHING", build_washing(), (1.8,0.35,0.62)))

# ------------------------------------------------------------------------------- 16. REBAR
# "the storey that never got built" (REF-03 s7) - a bare roof-corner slab stub + bent rods.
def build_rebar():
    seed = zlib.crc32(b"PART_REBAR")
    obs = [axbox("rb_slab", M_STAINED, 0,0.6, 0,0.6, 0,0.12)]
    rng = np.random.RandomState(seed % (2**31))
    for i in range(6):
        x,y = 0.08+rng.rand()*0.44, 0.08+rng.rand()*0.44
        h = 0.5 + rng.rand()*0.4
        lean = (rng.rand()-0.5)*0.15
        obs.append(bar((x,y,0.12),(x+lean,y+lean,0.12+h), 0.008, f"rb_rod{i}", M_REBAR))
    ob = join("PART_REBAR", obs)
    return ob
parts.append(("PART_REBAR", build_rebar(), (0.6,0.6,0.95)))

# ------------------------------------------------------------------------------------ finish
for name, ob, _ in parts:
    finish(ob)

# ---------------------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 4 PASS 1 - FACADE PARTS : ASSERTIONS =================")
fails = []
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

flag(f"all 16 parts built ({len(parts)})", len(parts) == 16)
for name, ob, expect in parts:
    dims = np.array(ob.dimensions)
    exp = np.array(expect)
    ok = bool(np.all(np.abs(dims - exp) < np.maximum(exp*0.25, 0.05)))
    flag(f"{name} real dimension {tuple(round(d,2) for d in dims)} ~ expected {expect}", ok)
    if not ob.data.materials or len(ob.data.materials) == 0:
        flag(f"{name} has a material", False)

print(f"\nbuild time {time.time()-T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 70)
os.makedirs(os.path.dirname(PARTSBLEND), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=PARTSBLEND)
print(f"saved: {PARTSBLEND}")
if fails: sys.exit(1)
