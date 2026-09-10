# COMPONENT 3 PASS 2 - ITEM 3: the railway, STAGE 2 BLOCKOUT SCOPE ONLY. Spec: S0-THE-WORLD.md
# "COMPONENT 3 PASS 2 - ITEM 3" (by reference to S0b-THE-RAILWAY.md, which already has every
# number, per Rule 1). Built from map/najibabad_rail.json (22 real ways, pulled 3 Sep).
# Builds: the formation embankment (6.85 m single line, 2:1 side slopes, 1.0 m minimum bank,
# S0b's own figures) for every way clipped to the terrain extent, built at its own real width
# rather than a synthetic double-line platform · station platform masses near NBD (0.84 m) ·
# the two level crossings as a flat break (S0b's coordinates - the OSM pull's own level_crossing
# POIs landed far outside the box, a real data-quality mismatch, noted not chased).
# Rails/sleepers/ballast (Stage 3) and OHE/catenary (Stage 4/9) are NOT this script, per S0b.
# The two road-over-rail decks at 6.25 m clear are ALREADY BUILT (FLYOVER_895269403/405, item 2).
#   blender --background --python build/city/03e_railway.py
import bpy, math, os, sys, json, time
import numpy as np
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
        vs = []; fs = []
        for i in range(n_pts):
            run_out = SIDE_SLOPE * bank_h[i]
            for o, z in ((-half_top - run_out, ground_s[i]), (-half_top, Zform[i]),
                         (half_top, Zform[i]), (half_top + run_out, ground_s[i])):
                q = P[i] + nor[i] * o
                vs.append((q[0], q[1], z))
        npr = 4
        for i in range(n_pts - 1):
            for k in range(npr - 1):
                a = i * npr + k; bq = a + 1; c = (i + 1) * npr + k; dd = c + 1
                fs.append((a, bq, dd, c))
        name = f"RAIL_{ri}_{int(s[0])}"
        ob = mesh_from(vs, fs, name, MAT_FORM)
        built += 1
        sample_widths.append(float(np.linalg.norm(np.array(vs[1][:2]) - np.array(vs[2][:2]))))
        sample_bank_h.append(float(np.max(bank_h)))

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
print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
bpy.ops.wm.save_mainfile(filepath=ROADSBLEND)
print(f"saved: {ROADSBLEND}")
if fails: sys.exit(1)
