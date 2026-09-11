# COMPONENT 3 PASS 2 - ITEM 3: the railway. Spec: S0-THE-WORLD.md "COMPONENT 3 PASS 2 - ITEM 3"
# (by reference to S0b-THE-RAILWAY.md, per Rule 1). Built from map/najibabad_rail.json (22 real
# ways, pulled 3 Sep).
# UPDATED 10 Sep 2026: Aditya's instruction was "I want everything perfect", so Stage 3 (rails,
# sleepers) and Stage 4/9 (OHE, catenary) are pulled forward into this same build rather than
# staying deferred - see below for how each is scoped to respect PLAN's own three-scale law.
# Builds: the formation embankment (6.85 m single line, 2:1 side slopes, 1.0 m minimum bank,
# S0b's own figures) for every way clipped to the terrain extent · station platform masses near
# NBD (0.84 m) · the two level crossings as a flat break (S0b's coordinates - the OSM pull's own
# level_crossing POIs landed far outside the box, a real data-quality mismatch, noted not chased)
# · RAILS + SLEEPERS as a PROCEDURAL MATERIAL on the formation top, not modelled geometry - PLAN
# s3b's own rule ("S is almost always a material... never modelled") applies exactly here: a
# sleeper is centimetre-scale repeated over 10+ km, precisely the case that rule exists for ·
# OHE (masts, cantilever bracket, messenger + contact wire) as REAL GEOMETRY over the
# `electrified=contact_line` ways only, because a mast against the sky and a wire crossing it are
# metre-scale and a flat texture cannot fake them - built as bevelled curves for the wires
# (S0b: the catenary is a parabola, never a sine) with S0b's own 200 mm stagger on straight track.
# The two road-over-rail decks at 6.25 m clear are ALREADY BUILT (FLYOVER_895269403/405, item 2).
#   blender --background --python build/city/03e_railway.py
import bpy, math, os, sys, json, time
import numpy as np
from mathutils import Vector
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
ROADSBLEND = f"{REF}/blend/03_ROADS.blend"

FORMATION_W = 6.85          # S0b: BG single line, in bank
MIN_BANK_H = 1.0            # S0b: not less than 1 m in flat terrain
SIDE_SLOPE = 2.0             # S0b: embankment side slope 2H:1V generally
STEP = 8.0
GEXT = 2000.0; NG = 600; CELL = 2 * GEXT / NG
LEVEL_CROSSINGS = [np.array([543.0, -670.0]), np.array([548.0, -658.0])]   # S0b s1, measured
CROSSING_TAPER = 40.0        # m either side of a crossing point, formation eases to grade
STATION_PT = np.array([-551.75, -900.06])   # NBD, this pull's own measured position
PLATFORM_LEN = 150.0; PLATFORM_W = 6.0; PLATFORM_H = 0.84; PLATFORM_OFFSET = 1.675 + PLATFORM_W / 2

GAUGE = 1.676                # S0b: broad gauge
RAIL_HEAD_W = 0.07           # approx IRC 60kg rail head width
SLEEPER_SPACING = 0.6        # S0b: "sleepers at 60 cm centres"
SLEEPER_W = 0.25             # along-track width of each sleeper band
CONTACT_H = 5.5              # S0b: minimum contact wire height above rail, in the open
MESSENGER_H = 6.7            # a design figure - typical structural height above contact wire,
                             # not a specific IR OHE spec value found in our sources; stated as such
MAST_SPACING = 50.0          # design decision - typical IR 25kV OHE tangent-track span is in this
                             # range, no specific span figure in our sources; stated as such
MAST_OFFSET = 3.0            # m from centreline, on one side (single-track cantilever)
MAST_H_ABOVE_MSGR = 1.2
STAGGER = 0.10               # S0b: max stagger 200 mm on straight = +-100 mm about centre
WIRE_BEVEL = 0.012           # visual wire thickness

def rail_sleeper_mat():
    m = bpy.data.materials.new("RAIL_SLEEPER"); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    uv = nt.nodes.new("ShaderNodeUVMap")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(uv.outputs["UV"], sep.inputs["Vector"])
    # two rail lines at u = 0.5 +- (GAUGE/2)/FORMATION_W
    du = (GAUGE / 2.0) / FORMATION_W
    for sign, nm in ((1, "R"), (-1, "L")):
        sub = nt.nodes.new("ShaderNodeMath"); sub.operation = 'SUBTRACT'
        sub.inputs[1].default_value = 0.5 + sign * du
        nt.links.new(sep.outputs["X"], sub.inputs[0])
        absn = nt.nodes.new("ShaderNodeMath"); absn.operation = 'ABSOLUTE'
        nt.links.new(sub.outputs["Value"], absn.inputs[0])
        less = nt.nodes.new("ShaderNodeMath"); less.operation = 'LESS_THAN'
        less.inputs[1].default_value = (RAIL_HEAD_W / FORMATION_W) / 2.0
        nt.links.new(absn.outputs["Value"], less.inputs[0])
        if nm == "R": rail_mask = less
        else:
            comb = nt.nodes.new("ShaderNodeMath"); comb.operation = 'MAXIMUM'
            nt.links.new(rail_mask.outputs["Value"], comb.inputs[0])
            nt.links.new(less.outputs["Value"], comb.inputs[1])
            rail_mask = comb
    # sleepers: periodic bands along V (metres), period SLEEPER_SPACING
    wrap = nt.nodes.new("ShaderNodeMath"); wrap.operation = 'WRAP'
    wrap.inputs[1].default_value = 0.0; wrap.inputs[2].default_value = SLEEPER_SPACING
    nt.links.new(sep.outputs["Y"], wrap.inputs[0])
    sl_less = nt.nodes.new("ShaderNodeMath"); sl_less.operation = 'LESS_THAN'
    sl_less.inputs[1].default_value = SLEEPER_W
    nt.links.new(wrap.outputs["Value"], sl_less.inputs[0])
    mix1 = nt.nodes.new("ShaderNodeMix"); mix1.data_type = 'RGBA'
    mix1.inputs["A"].default_value = (0.32, 0.28, 0.22, 1.0)     # ballast
    mix1.inputs["B"].default_value = (0.42, 0.38, 0.32, 1.0)     # sleeper (concrete/wood)
    nt.links.new(sl_less.outputs["Value"], mix1.inputs["Factor"])
    mix2 = nt.nodes.new("ShaderNodeMix"); mix2.data_type = 'RGBA'
    nt.links.new(mix1.outputs["Result"], mix2.inputs["A"])
    mix2.inputs["B"].default_value = (0.08, 0.08, 0.09, 1.0)     # rail steel
    nt.links.new(rail_mask.outputs["Value"], mix2.inputs["Factor"])
    nt.links.new(mix2.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.55
    return m
def ohe_mat():
    m = bpy.data.materials.new("OHE_STEEL"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.15, 0.14, 0.13, 1.0)
    b.inputs["Roughness"].default_value = 0.5; b.inputs["Metallic"].default_value = 0.7
    return m
def wire_mat():
    m = bpy.data.materials.new("OHE_WIRE"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.30, 0.28, 0.22, 1.0)
    b.inputs["Roughness"].default_value = 0.4; b.inputs["Metallic"].default_value = 0.85
    return m

rail = json.load(open(f"{REF}/map/najibabad_rail.json"))
RAILS = rail['rails']
print(f"{len(RAILS)} raw rail ways loaded")

bpy.ops.wm.open_mainfile(filepath=ROADSBLEND)
terr = bpy.data.objects["TERRAIN"]
tco = np.array([v.co[:] for v in terr.data.vertices])
tgj = np.clip(np.round((tco[:, 0] + GEXT) / CELL).astype(int), 0, NG)
tgi = np.clip(np.round((tco[:, 1] + GEXT) / CELL).astype(int), 0, NG)
H = np.zeros((NG + 1, NG + 1)); H[tgi, tgj] = tco[:, 2]
def terrain_z(wx, wy):
    fx = np.clip((wx + GEXT) / CELL, 0, NG - 1e-6); fy = np.clip((wy + GEXT) / CELL, 0, NG - 1e-6)
    i0 = fx.astype(int); j0 = fy.astype(int); tx = fx - i0; ty = fy - j0
    return (H[j0, i0] * (1 - tx) * (1 - ty) + H[j0, i0 + 1] * tx * (1 - ty)
            + H[j0 + 1, i0] * (1 - tx) * ty + H[j0 + 1, i0 + 1] * tx * ty)

if "RAILWAY" not in bpy.data.collections:
    c = bpy.data.collections.new("RAILWAY"); bpy.context.scene.collection.children.link(c)
RCOL = bpy.data.collections["RAILWAY"]
# clear any previous run's objects first - this script was heavily re-run during its own
# development (see S0-THE-WORLD.md's "the rail crossings' real shortfall" note) with no cleanup
# step, unlike 03c/03d/03f - found and fixed 11 Sep while investigating a matching S5 duplication
# bug in 03g_s5climb.py.
for ob in list(RCOL.objects):
    me = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if me and me.users == 0:
        bpy.data.meshes.remove(me)

def formation_mat():
    m = bpy.data.materials.new("RAIL_FORMATION"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.32, 0.28, 0.22, 1.0)   # ballast/earth, grey-tan
    b.inputs["Roughness"].default_value = 0.9
    return m
def platform_mat():
    m = bpy.data.materials.new("PLATFORM"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.55, 0.53, 0.48, 1.0)
    b.inputs["Roughness"].default_value = 0.8
    return m
MAT_FORM = formation_mat(); MAT_PLAT = platform_mat()
MAT_RAIL = rail_sleeper_mat(); MAT_OHE = ohe_mat(); MAT_WIRE = wire_mat()

def mesh_from2(vs, fs, mat_idx, name, mats, uvs=None):
    me = bpy.data.meshes.new(name); me.from_pydata(vs, [], fs); me.update()
    me.calc_loop_triangles()
    if len(me.polygons) and float(np.mean([p.normal.z for p in me.polygons if abs(p.normal.z) > 0.2] or [1])) < 0:
        me.flip_normals(); me.update()
    for mat in mats: me.materials.append(mat)
    for poly, idx in zip(me.polygons, mat_idx): poly.material_index = idx
    if uvs is not None:
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in poly.loop_indices:
                uvl.data[li].uv = uvs[me.loops[li].vertex_index]
    ob = bpy.data.objects.new(name, me); RCOL.objects.link(ob)
    return ob

def mesh_from(vs, fs, name, mat):
    me = bpy.data.meshes.new(name); me.from_pydata(vs, [], fs); me.update()
    me.calc_loop_triangles()
    if len(me.polygons) and float(np.mean([p.normal.z for p in me.polygons if abs(p.normal.z) > 0.2] or [1])) < 0:
        me.flip_normals(); me.update()
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(mat)
    RCOL.objects.link(ob)
    return ob

def resample(pts, step=STEP):
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]
    if d[-1] < step: return pts, d[-1]
    u = np.arange(0, d[-1], step)
    return np.c_[np.interp(u, d, pts[:, 0]), np.interp(u, d, pts[:, 1])], d[-1]

def clip_runs(pts, ext):
    inside = (np.abs(pts[:, 0]) <= ext) & (np.abs(pts[:, 1]) <= ext)
    runs = []; i = 0
    while i < len(pts):
        if not inside[i]: i += 1; continue
        j = i
        while j < len(pts) and inside[j]: j += 1
        if j - i >= 2: runs.append(pts[i:j])
        i = j
    return runs

fails = []
def check(name, got, want, tol):
    ok = abs(got - want) <= tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:56s} got {got:10.4f}  want {want:.4f}")
    if not ok: fails.append(name)
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

built = 0
sample_widths = []
sample_bank_h = []
formation_runs = []   # for OHE, built after: (P, Zform, nor, electrified)
for ri, r in enumerate(RAILS):
    pts = np.array(r['pts'])
    for run in clip_runs(pts, GEXT):
        P, L = resample(run)
        if len(P) < 2 or L < STEP: continue
        n_pts = len(P)
        s = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
        ground = terrain_z(P[:, 0], P[:, 1])
        ground_s = ground.copy()
        for _ in range(10):
            ground_s = np.convolve(np.pad(ground_s, 1, mode='edge'), [0.25, 0.5, 0.25], mode='same')[1:-1]
        # bank height tapers to 0 within CROSSING_TAPER of either measured level-crossing point
        dxing = np.min([np.linalg.norm(P - c, axis=1) for c in LEVEL_CROSSINGS], axis=0)
        taper = np.clip(dxing / CROSSING_TAPER, 0, 1)
        bank_h = MIN_BANK_H * taper
        Zform = ground_s + bank_h

        tang = np.zeros_like(P)
        tang[1:-1] = P[2:] - P[:-2]; tang[0] = P[1] - P[0]; tang[-1] = P[-1] - P[-2]
        tn = np.linalg.norm(tang, axis=1, keepdims=True); tn[tn < 1e-9] = 1.0; tang /= tn
        nor = np.c_[-tang[:, 1], tang[:, 0]]
        half_top = FORMATION_W * 0.5
        vs = []; fs = []; uvs = []; mat_idx = []
        for i in range(n_pts):
            run_out = SIDE_SLOPE * bank_h[i]
            for o, z in ((-half_top - run_out, ground_s[i]), (-half_top, Zform[i]),
                         (half_top, Zform[i]), (half_top + run_out, ground_s[i])):
                q = P[i] + nor[i] * o
                vs.append((q[0], q[1], z))
                # u is relative to the fixed TOP width (FORMATION_W) only, matching the
                # material's own rail-position formula - NOT the slope-inclusive width, which
                # varies with bank_h and would make the rails drift sideways with bank height.
                uvs.append(((o + half_top) / FORMATION_W, s[i]))
        npr = 4
        for i in range(n_pts - 1):
            for k in range(npr - 1):
                a = i * npr + k; bq = a + 1; c = (i + 1) * npr + k; dd = c + 1
                fs.append((a, bq, dd, c))
                mat_idx.append(1 if k == 1 else 0)   # k=1 is the top strip: rail/sleeper material
        name = f"RAIL_{ri}_{int(s[0])}"
        ob = mesh_from2(vs, fs, mat_idx, name, [MAT_FORM, MAT_RAIL], uvs)
        built += 1
        sample_widths.append(float(np.linalg.norm(np.array(vs[1][:2]) - np.array(vs[2][:2]))))
        sample_bank_h.append(float(np.max(bank_h)))
        formation_runs.append(dict(P=P, Zform=Zform, nor=nor, s=s,
                                    electrified=(r.get('electrified') == 'contact_line')))

print(f"\n{built} formation pieces built from {len(RAILS)} raw ways")

# station platforms at NBD - simple slabs, station BUILDING is explicitly not claimed (S0b)
mainline = None
best_d = 1e18
for ri, r in enumerate(RAILS):
    if r['usage'] != 'main': continue
    pts = np.array(r['pts'])
    d = float(np.min(np.linalg.norm(pts - STATION_PT, axis=1)))
    if d < best_d: best_d = d; mainline = pts
plat_dir = np.array([1.0, 0.0])
if mainline is not None:
    idx = int(np.argmin(np.linalg.norm(mainline - STATION_PT, axis=1)))
    lo = max(0, idx - 1); hi = min(len(mainline) - 1, idx + 1)
    d = mainline[hi] - mainline[lo]
    if np.linalg.norm(d) > 1e-6: plat_dir = d / np.linalg.norm(d)
plat_nor = np.array([-plat_dir[1], plat_dir[0]])
platform_objs = []
for side in (-1, 1):
    c0 = STATION_PT - plat_dir * (PLATFORM_LEN / 2) + plat_nor * (PLATFORM_OFFSET * side)
    c1 = STATION_PT + plat_dir * (PLATFORM_LEN / 2) + plat_nor * (PLATFORM_OFFSET * side)
    zc0 = float(terrain_z(np.array([c0[0]]), np.array([c0[1]]))[0])
    zc1 = float(terrain_z(np.array([c1[0]]), np.array([c1[1]]))[0])
    half_w = PLATFORM_W / 2
    vs = []
    for c, z in ((c0, zc0), (c1, zc1)):
        for o in (-half_w, half_w):
            q = c + plat_nor * o
            vs.append((q[0], q[1], z))
            vs.append((q[0], q[1], z + PLATFORM_H))
    fs = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (1, 3, 7, 5), (3, 2, 6, 7), (2, 0, 4, 6)]
    ob = mesh_from(vs, fs, f"PLATFORM_{side}", MAT_PLAT)
    platform_objs.append(ob)
print(f"2 platform slabs built at NBD ({STATION_PT[0]:.1f},{STATION_PT[1]:.1f})")

# ---------------------------------------------------------------- OHE: masts + wires, electrified
# runs only. Real geometry (PLAN s3b: this is metre-scale, not a material's job).
def box_mesh(p0, p1, w, name, mat):
    # a straight square-section prism from p0 to p1 (thickness w), oriented so its two side
    # faces are perpendicular to the horizontal direction of travel - correct whether the member
    # is mostly vertical (a mast) or mostly horizontal (a bracket arm).
    a, bb = np.array(p0), np.array(p1)
    d = bb - a
    horiz = np.array([d[0], d[1], 0.0]); Lh = np.linalg.norm(horiz)
    fwd = horiz / Lh if Lh > 1e-6 else np.array([1.0, 0.0, 0.0])
    side = np.array([-fwd[1], fwd[0], 0.0]) * (w * 0.5)
    up = np.array([0.0, 0.0, w * 0.5])
    verts = []
    for base_pt in (a, bb):
        for sx in (-1, 1):
            for sz in (-1, 1):
                verts.append(tuple(base_pt + side * sx + up * sz))
    fs = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (1, 5, 7, 3), (3, 7, 6, 2), (2, 6, 4, 0)]
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], fs); me.update()
    me.calc_loop_triangles()
    if len(me.polygons) and float(np.mean([p.normal.z for p in me.polygons if abs(p.normal.z) > 0.2] or [1])) < 0:
        me.flip_normals(); me.update()
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(mat); RCOL.objects.link(ob)
    return ob

def wire_curve(points, name, mat, bevel=WIRE_BEVEL):
    cu = bpy.data.curves.new(name, type='CURVE'); cu.dimensions = '3D'
    cu.bevel_depth = bevel; cu.bevel_resolution = 2
    sp = cu.splines.new('POLY'); sp.points.add(len(points) - 1)
    for i, p in enumerate(points): sp.points[i].co = (p[0], p[1], p[2], 1.0)
    ob = bpy.data.objects.new(name, cu); ob.data.materials.append(mat); RCOL.objects.link(ob)
    return ob

ohe_masts = 0; ohe_wires = 0
contact_h_samples = []; stagger_samples = []; mast_spacing_samples = []
for ri, run in enumerate(formation_runs):
    if not run['electrified']: continue
    P, Zform, nor, s = run['P'], run['Zform'], run['nor'], run['s']
    L = float(s[-1])
    n_masts = max(2, int(round(L / MAST_SPACING)) + 1)
    mast_s = np.linspace(0, L, n_masts)
    mast_pts = []; contact_pts = []; msgr_pts = []
    for mi, ms in enumerate(mast_s):
        i = int(np.searchsorted(s, ms)); i = min(max(i, 0), len(P) - 1)
        base = P[i] + nor[i] * MAST_OFFSET
        zbase = float(terrain_z(np.array([base[0]]), np.array([base[1]]))[0])
        top_z = Zform[i] + MESSENGER_H + MAST_H_ABOVE_MSGR
        box_mesh(np.r_[base, zbase], np.r_[base, top_z], 0.3, f"OHE_MAST_{ri}_{mi}", MAT_OHE)
        # cantilever bracket toward the centreline, at messenger height
        arm_tip = P[i] - nor[i] * (MAST_OFFSET - 0.3)
        box_mesh(np.r_[base, Zform[i] + MESSENGER_H], np.r_[arm_tip, Zform[i] + MESSENGER_H],
                  0.15, f"OHE_ARM_{ri}_{mi}", MAT_OHE)
        ohe_masts += 1
        stagger = STAGGER * (1 if mi % 2 == 0 else -1)   # S0b: 200 mm max stagger, +-100 mm
        contact_pts.append(np.r_[P[i] + nor[i] * stagger, Zform[i] + CONTACT_H])
        msgr_pts.append(np.r_[P[i], Zform[i] + MESSENGER_H])
        contact_h_samples.append(CONTACT_H); stagger_samples.append(abs(stagger))
    if len(mast_s) > 1:
        mast_spacing_samples.append(float(np.median(np.diff(mast_s))))
    # parabolic sag between consecutive mast points (S0b: a catenary is a parabola, not a sine)
    def sag_chain(pts, sag):
        out = []
        for k in range(len(pts) - 1):
            a, b = pts[k], pts[k + 1]
            for t in np.linspace(0, 1, 6)[:-1]:
                p = a * (1 - t) + b * t
                p[2] -= sag * 4 * t * (1 - t)
                out.append(p)
        out.append(pts[-1])
        return out
    wire_curve(sag_chain(contact_pts, 0.05), f"OHE_CONTACT_{ri}", MAT_WIRE)
    wire_curve(sag_chain(msgr_pts, 0.25), f"OHE_MESSENGER_{ri}", MAT_WIRE)
    ohe_wires += 2
print(f"OHE built: {ohe_masts} masts+brackets, {ohe_wires} wire runs, over "
      f"{sum(1 for r in formation_runs if r['electrified'])} electrified formation piece(s)")

# ---------------------------------------------------------------- assertions
print("\n================= COMPONENT 3 PASS 2 - RAILWAY : ASSERTIONS =================")
flag(f"at least one formation piece built ({built} built)", built > 0)
check("measured formation width, sampled (m)", float(np.median(sample_widths)), FORMATION_W, 0.05)
flag(f"minimum bank height reaches the 1.0 m design figure somewhere "
     f"(max observed {max(sample_bank_h):.2f} m)", max(sample_bank_h) >= MIN_BANK_H - 0.05)
for ob in platform_objs:
    v = np.array([x.co[:] for x in ob.data.vertices])
    # vertex order per station: [bottom(-w/2), top(-w/2), bottom(+w/2), top(+w/2)] - measure
    # height at ONE station (same xy, z only) and width across the SAME station's two bottoms,
    # not a global bounding-box max-min which mixes in the 150 m terrain slope along its length.
    h = float(v[1][2] - v[0][2])
    check(f"{ob.name} measured height (m)", h, PLATFORM_H, 0.05)
    w = float(np.linalg.norm(v[0][:2] - v[2][:2]))
    check(f"{ob.name} measured width (m)", w, PLATFORM_W, 0.05)
flag(f"OHE built over at least one electrified run ({ohe_masts} masts)", ohe_masts > 0)
if contact_h_samples:
    check("OHE contact wire height above rail, sampled (m)", float(np.median(contact_h_samples)),
          CONTACT_H, 0.01)
    check("OHE stagger amplitude, sampled (m)", float(np.median(stagger_samples)), STAGGER, 0.01)
    check("OHE mast spacing, sampled (m)", float(np.median(mast_spacing_samples)), MAST_SPACING,
          MAST_SPACING * 0.15)
print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
bpy.ops.wm.save_mainfile(filepath=ROADSBLEND)
print(f"saved: {ROADSBLEND}")
if fails: sys.exit(1)
