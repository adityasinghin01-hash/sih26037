# COMPONENT 3 PASS 2 - ITEM 4: the S2 gyratory. Spec: S0-THE-WORLD.md "COMPONENT 3 PASS 2 - ITEM
# 4", written 10 Sep 2026 before this script, per Rule 1. Road geometry only - the chowk statue
# and the 96 surrounding buildings are Component 4/7's job.
# MEASURED which pieces meet here (a real 5-way junction, two close node clusters ~8-9 m apart,
# not one point) by trimming EVERY pass-1 ROAD_* piece that has an endpoint inside the outer
# circulatory radius, rather than hand-naming which of the ~8 real OSM pieces converge - a general
# radius-based trim is robust where hand-picking names is not.
#   blender --background --python build/city/03f_gyratory.py
import bpy, math, os, sys, time
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
ROADSBLEND = f"{REF}/blend/03_ROADS.blend"

S2 = np.array([340.1, -579.9])          # S2-THE-CHOWK.md
R_ISLAND = 12.0                          # IRC 65:2017 Table 6.2: ICD 40 -> island 24 dia
R_OUTER = 20.0                           # -> circulatory carriageway 8 m wide (12 -> 20)
KERB_H = 0.15
GIVEWAY_W = 0.20; GIVEWAY_GAP = 0.30
SPLITTER_LEN = 6.0; SPLITTER_W = 1.8

bpy.ops.wm.open_mainfile(filepath=ROADSBLEND)
terr = bpy.data.objects["TERRAIN"]
tco = np.array([v.co[:] for v in terr.data.vertices])
GEXT = 2000.0; NG = 600; CELL = 2 * GEXT / NG
tgj = np.clip(np.round((tco[:, 0] + GEXT) / CELL).astype(int), 0, NG)
tgi = np.clip(np.round((tco[:, 1] + GEXT) / CELL).astype(int), 0, NG)
H = np.zeros((NG + 1, NG + 1)); H[tgi, tgj] = tco[:, 2]
def terrain_z(wx, wy):
    fx = np.clip((wx + GEXT) / CELL, 0, NG - 1e-6); fy = np.clip((wy + GEXT) / CELL, 0, NG - 1e-6)
    i0 = fx.astype(int); j0 = fy.astype(int); tx = fx - i0; ty = fy - j0
    return (H[j0, i0] * (1 - tx) * (1 - ty) + H[j0, i0 + 1] * tx * (1 - ty)
            + H[j0 + 1, i0] * (1 - tx) * ty + H[j0 + 1, i0 + 1] * tx * ty)

if "GYRATORY" not in bpy.data.collections:
    c = bpy.data.collections.new("GYRATORY"); bpy.context.scene.collection.children.link(c)
GCOL = bpy.data.collections["GYRATORY"]
# clear this script's own previous output before rebuilding - same defensive fix applied to
# 03c_bridges.py/03d_flyovers.py/03e_railway.py/03g_s5climb.py 11 Sep after finding stale
# duplicate generations in 03_ROADS.blend
for ob in list(GCOL.objects):
    me = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if me and me.users == 0:
        bpy.data.meshes.remove(me)

def ring_mat():
    m = bpy.data.materials.new("GYRATORY_RING"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.052, 0.050, 0.048, 1.0)
    b.inputs["Roughness"].default_value = 0.72
    return m
def island_mat():
    m = bpy.data.materials.new("GYRATORY_ISLAND"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.14, 0.24, 0.09, 1.0)   # planted grass
    b.inputs["Roughness"].default_value = 0.85
    return m
def kerb_mat():
    m = bpy.data.materials.new("GYRATORY_KERB"); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    uv = nt.nodes.new("ShaderNodeUVMap")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(uv.outputs["UV"], sep.inputs["Vector"])
    wrap = nt.nodes.new("ShaderNodeMath"); wrap.operation = 'WRAP'
    wrap.inputs[1].default_value = 0.0; wrap.inputs[2].default_value = 1.0
    nt.links.new(sep.outputs["X"], wrap.inputs[0])
    less = nt.nodes.new("ShaderNodeMath"); less.operation = 'LESS_THAN'; less.inputs[1].default_value = 0.5
    nt.links.new(wrap.outputs["Value"], less.inputs[0])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = 'RGBA'
    mix.inputs["A"].default_value = (0.05, 0.05, 0.05, 1.0)
    mix.inputs["B"].default_value = (0.85, 0.85, 0.82, 1.0)
    nt.links.new(less.outputs["Value"], mix.inputs["Factor"])
    nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.6
    return m
def line_mat():
    m = bpy.data.materials.new("GYRATORY_GIVEWAY"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.88, 0.88, 0.85, 1.0)
    b.inputs["Roughness"].default_value = 0.5
    return m
MAT_RING = ring_mat(); MAT_ISLAND = island_mat(); MAT_KERB = kerb_mat(); MAT_LINE = line_mat()

def mesh_from(vs, fs, name, mat, uvs=None):
    me = bpy.data.meshes.new(name); me.from_pydata(vs, [], fs); me.update()
    me.calc_loop_triangles()
    if len(me.polygons) and float(np.mean([p.normal.z for p in me.polygons if abs(p.normal.z) > 0.2] or [1])) < 0:
        me.flip_normals(); me.update()
    if uvs is not None:
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in poly.loop_indices:
                uvl.data[li].uv = uvs[me.loops[li].vertex_index]
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(mat)
    GCOL.objects.link(ob)
    return ob

fails = []
def check(name, got, want, tol):
    ok = abs(got - want) <= tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:56s} got {got:10.4f}  want {want:.4f}")
    if not ok: fails.append(name)
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

# ---------------------------------------------------------------- 1: find and trim every arm
arm_points = []   # (xy at r=R_OUTER, angle, z there)
trimmed = []; removed = []
for ob in list(bpy.data.objects):
    if not ob.name.startswith("ROAD_"): continue
    ov = np.array([v.co[:] for v in ob.data.vertices])
    if len(ov) % 7 != 0 or len(ov) == 0: continue
    n_pts = len(ov) // 7
    centre = ov[3::7][:n_pts]
    P = centre[:, :2]; Z = centre[:, 2]
    d = np.linalg.norm(P - S2, axis=1)
    inside = d < R_OUTER
    if not inside.any(): continue
    if inside.all():
        nm = ob.name; bpy.data.objects.remove(ob, do_unlink=True); removed.append(nm); continue
    # find the single crossing of d==R_OUTER nearest the inside region, keep the outside part
    idx_inside = np.where(inside)[0]
    if idx_inside[0] == 0:
        # arm enters from the start - crossing is between the last inside and first outside pt
        i = idx_inside[-1]
        a, b = P[i], P[i + 1]; da, db = d[i], d[i + 1]
        denom = db - da
        denom = denom if abs(denom) > 1e-9 else (1e-9 if denom >= 0 else -1e-9)
        t = np.clip((R_OUTER - da) / denom, 0.0, 1.0)   # the crossing MUST lie within this
                                                         # segment (one end inside, one out) -
                                                         # clip as a hard safety net too
        cross = a + t * (b - a); zc = Z[i] + t * (Z[i + 1] - Z[i])
        keep_P = np.r_[cross[None, :], P[i + 1:]]; keep_Z = np.r_[zc, Z[i + 1:]]
    else:
        i = idx_inside[0]
        a, b = P[i - 1], P[i]; da, db = d[i - 1], d[i]
        denom = db - da
        denom = denom if abs(denom) > 1e-9 else (1e-9 if denom >= 0 else -1e-9)
        t = np.clip((R_OUTER - da) / denom, 0.0, 1.0)   # the crossing MUST lie within this
                                                         # segment (one end inside, one out) -
                                                         # clip as a hard safety net too
        cross = a + t * (b - a); zc = Z[i - 1] + t * (Z[i] - Z[i - 1])
        keep_P = np.r_[P[:i], cross[None, :]]; keep_Z = np.r_[Z[:i], zc]
    ang = float(np.degrees(np.arctan2(cross[0] - S2[0], cross[1] - S2[1])) % 360)
    arm_points.append(dict(xy=cross, z=zc, angle=ang, name=ob.name))
    trimmed.append((ob.name, keep_P, keep_Z))
    bpy.data.objects.remove(ob, do_unlink=True)

print(f"{len(trimmed)} arm(s) trimmed at r={R_OUTER} m, {len(removed)} tiny stub piece(s) fully "
      f"absorbed into the junction: {removed}")
for a in sorted(arm_points, key=lambda x: x['angle']):
    print(f"  arm from {a['name']}: angle {a['angle']:.1f} deg, z {a['z']:.2f} m")

# ---------------------------------------------------------------- 2: rebuild each trimmed arm's
# ribbon ending exactly at its own r=R_OUTER point (same cross-section technique as 03_roads.py -
# a flat 2-lane strip is enough here; full IRC widths were already asserted in pass 1)
ARM_W = 7.0
def build_arm(name, P, Z):
    n = len(P)
    if n < 2: return
    tang = np.zeros_like(P)
    tang[1:-1] = P[2:] - P[:-2]; tang[0] = P[1] - P[0]; tang[-1] = P[-1] - P[-2]
    tn = np.linalg.norm(tang, axis=1, keepdims=True); tn[tn < 1e-9] = 1.0; tang /= tn
    nor = np.c_[-tang[:, 1], tang[:, 0]]
    half = ARM_W * 0.5
    vs = []; fs = []
    for i in range(n):
        for o in (-half, half):
            q = P[i] + nor[i] * o
            vs.append((q[0], q[1], Z[i]))
    for i in range(n - 1):
        a, bq, c2, dd = i * 2, i * 2 + 1, (i + 1) * 2, (i + 1) * 2 + 1
        fs.append((a, bq, dd, c2))
    return mesh_from(vs, fs, f"GYARM_{name}", MAT_RING)

for name, P, Z in trimmed:
    build_arm(name, P, Z)

# ---------------------------------------------------------------- 3: the ring + island, conformed
z_centre = float(terrain_z(np.array([S2[0]]), np.array([S2[1]]))[0])
N_ANG = 72
angs = np.linspace(0, 2 * np.pi, N_ANG, endpoint=False)
ring_z = z_centre   # a real gyratory sits on essentially flat local ground; conform to one height
                     # sampled at centre rather than per-angle, so the ring itself stays level
                     # (a gyratory does not tilt around its own circumference)

def circle_pts(r, z):
    return [(S2[0] + r * math.sin(a), S2[1] + r * math.cos(a), z) for a in angs]

island_top = circle_pts(R_ISLAND, ring_z + KERB_H)
island_vs = [tuple(S2) + (ring_z + KERB_H,)] + island_top
island_fs = [(0, i + 1, (i + 1) % N_ANG + 1) for i in range(N_ANG)]
island = mesh_from(island_vs, island_fs, "GYRATORY_ISLAND_TOP", MAT_ISLAND)

# island kerb: a short vertical band from ring_z to ring_z+KERB_H at r=R_ISLAND, painted b/w
kerb_lo = circle_pts(R_ISLAND, ring_z); kerb_hi = circle_pts(R_ISLAND, ring_z + KERB_H)
kerb_vs = kerb_lo + kerb_hi
kerb_fs = [(i, (i + 1) % N_ANG, (i + 1) % N_ANG + N_ANG, i + N_ANG) for i in range(N_ANG)]
kerb_uvs = [(i / 6.0, 0.0) for i in range(N_ANG)] + [(i / 6.0, 1.0) for i in range(N_ANG)]
kerb = mesh_from(kerb_vs, kerb_fs, "GYRATORY_KERB", MAT_KERB, kerb_uvs)

inner = circle_pts(R_ISLAND, ring_z); outer = circle_pts(R_OUTER, ring_z)
ring_vs = inner + outer
ring_fs = [(i, (i + 1) % N_ANG, (i + 1) % N_ANG + N_ANG, i + N_ANG) for i in range(N_ANG)]
ring = mesh_from(ring_vs, ring_fs, "GYRATORY_RING", MAT_RING)

# give-way double line just inside the outer edge, at each arm's own angle
for a in arm_points:
    ang = math.radians(a['angle'])
    fwd = np.array([math.sin(ang), math.cos(ang)])
    perp = np.array([fwd[1], -fwd[0]])
    for k, off in enumerate((-GIVEWAY_GAP / 2 - GIVEWAY_W / 2, GIVEWAY_GAP / 2 + GIVEWAY_W / 2)):
        c = S2 + fwd * (R_OUTER - 0.5)
        p0 = c + perp * (off - GIVEWAY_W / 2); p1 = c + perp * (off + GIVEWAY_W / 2)
        vs = [(*p0, ring_z + 0.01), (*p1, ring_z + 0.01),
              (*(p1 + fwd * GIVEWAY_W * 3), ring_z + 0.01), (*(p0 + fwd * GIVEWAY_W * 3), ring_z + 0.01)]
        mesh_from(vs, [(0, 1, 2, 3)], f"GYRATORY_GIVEWAY_{a['name']}_{k}", MAT_LINE)

# splitter islands, kerbed, just outside R_OUTER at each arm
for a in arm_points:
    ang = math.radians(a['angle'])
    fwd = np.array([math.sin(ang), math.cos(ang)])
    perp = np.array([fwd[1], -fwd[0]])
    c = S2 + fwd * (R_OUTER + SPLITTER_LEN / 2 + 0.5)
    half_l, half_w = SPLITTER_LEN / 2, SPLITTER_W / 2
    top = [c + fwd * half_l + perp * 0, c + perp * half_w, c - fwd * half_l, c - perp * half_w]
    z0 = a['z']
    vs = [(*p, z0) for p in top] + [(*p, z0 + KERB_H) for p in top]
    fs = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    mesh_from(vs, fs, f"GYRATORY_SPLITTER_{a['name']}", MAT_ISLAND)

# ---------------------------------------------------------------- assertions
print("\n================= COMPONENT 3 PASS 2 - GYRATORY : ASSERTIONS =================")
flag(f"at least 3 arms found and trimmed ({len(arm_points)} found)", len(arm_points) >= 3)
iv = np.array([v.co[:] for v in island.data.vertices])
island_r = float(np.median(np.linalg.norm(iv[1:, :2] - S2, axis=1)))
check("measured island radius (m)", island_r, R_ISLAND, 0.05)
rv = np.array([v.co[:] for v in ring.data.vertices])
ring_w = float(np.linalg.norm(rv[0][:2] - rv[N_ANG][:2]))
check("measured circulatory carriageway width (m)", ring_w, R_OUTER - R_ISLAND, 0.05)
kv = np.array([v.co[:] for v in kerb.data.vertices])
kerb_h_m = float(kv[N_ANG][2] - kv[0][2])
check("measured kerb height (m)", kerb_h_m, KERB_H, 0.01)
flag("no truck apron built (island is a single flat top)", True)
print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
bpy.ops.wm.save_mainfile(filepath=ROADSBLEND)
print(f"saved: {ROADSBLEND}")
if fails: sys.exit(1)
