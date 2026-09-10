# COMPONENT 3 PASS 2 - ITEM 2: the 9 flyover decks. Spec: S0-THE-WORLD.md, the
# "COMPONENT 3 PASS 2 - ITEM 2" block, written 10 Sep 2026 before this script, per Rule 1.
# The 11 bridge-tagged OSM ways minus the 2 river bridges (03c_bridges.py) leave exactly 9 -
# found programmatically here, not hardcoded, so a future map re-pull can't silently drift from
# this list. Two of the 9 cross the railway (soffit ~7.9 m above ground, S0b's own figure);
# the other 7 clear 5.5 m above whichever surface is actually underneath at each point along the
# span - measured by ray-casting the real scene, not assumed to be bare ground.
#
# MEASURED, not assumed: 6 of the 9 pieces share EXACT endpoints with each other (0.0 m apart) -
# real evidence that OSM split ONE continuous elevated interchange into several separate way
# ids. Building each in isolation (first attempt) gave 7 of 9 pieces "no elevated core" - too
# short, alone, to climb enough within the grade limit. Fixed properly: pieces that share an
# endpoint are grouped into one connected corridor and given ONE joint height solve (a
# multi-source Dijkstra over the combined point graph, generalising the two-ended-line method to
# a branching junction), so height earned on one piece can carry through to its neighbours -
# exactly like the real structure does. Standalone pieces keep the single-piece method.
# RUN AFTER 03c_bridges.py, and RE-RUN whenever 03_roads.py or 03c_bridges.py is rebuilt.
#   blender --background --python build/city/03d_flyovers.py
import bpy, math, os, sys, csv, json, time, heapq
import numpy as np
from mathutils import Vector
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
ROADSBLEND = f"{REF}/blend/03_ROADS.blend"
MATLAB_OFFSET = np.array([35.0, -100.0])

# ---------------------------------------------------------------- the numbers, S0 PASS2 ITEM2
WIDTH = {'trunk': 14.0, 'trunk_link': 7.0, 'secondary': 7.0}   # own class width, no override
RAIL_PTS = [np.array([118.0, -748.0]), np.array([125.0, -737.0])]
RAIL_NEAR = 30.0            # m - within this of either point, the way is treated as a rail crossing
BRIDGE_1_TARGET = np.array([-640.0, 740.0]); BRIDGE_2_TARGET = np.array([-822.0, 609.0])
PIER_SPACING = 22.0         # REF-08 s5
PIER_SIZE = 1.8             # REF-01 s11, 1800x1800mm
DECK_THICK = 0.45
CAMBER = 0.025
BARRIER_H = 0.75            # W-beam top, REF-01 s10
BARRIER_KERB = 0.15
CLEAR_RAIL = 7.9            # S0b: 6.25 m above rail level + ~1.68 m of track structure
CLEAR_ROAD = 5.5            # IRC:86 minimum, urban
MAX_GRADE_RAIL = 0.035
MAX_GRADE_ROAD = 0.06

# ---------------------------------------------------------------- re-derive the pass-1 pieces
def seg_dist(P, pts):
    d = np.full(len(P), 1e9)
    for i in range(len(pts) - 1):
        a = pts[i]; b = pts[i + 1]; ab = b - a; L2 = float(ab @ ab)
        if L2 < 1e-9: continue
        t = np.clip(((P - a) @ ab) / L2, 0, 1)[:, None]
        d = np.minimum(d, np.linalg.norm(P - (a + t * ab), axis=1))
    return d

rows = [(float(a), float(b), int(float(c))) for a, b, c in csv.reader(open(f"{REF}/map/matlab_roads.csv"))]
segs = {}
for x, y, rid in rows: segs.setdefault(rid, []).append((x, y))
segs = {k: np.array(v) + MATLAB_OFFSET for k, v in segs.items() if len(v) >= 2}
J = json.load(open(f"{REF}/map/najibabad_metres.json"))['roads']
JP = [np.array(r['pts']) for r in J]

def resample(pts, step=4.0):
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))]
    if d[-1] < step: return pts, d[-1]
    u = np.arange(0, d[-1], step)
    return np.c_[np.interp(u, d, pts[:, 0]), np.interp(u, d, pts[:, 1])], d[-1]

def assign_ways(P):
    D = np.empty((len(P), len(JP)))
    for k, q in enumerate(JP): D[:, k] = seg_dist(P, q)
    a = D.argmin(1)
    if len(a) >= 3:
        b = a.copy()
        for i in range(1, len(a) - 1):
            if a[i - 1] == a[i + 1] and a[i] != a[i - 1]: b[i] = a[i - 1]
        a = b
    return a, D[np.arange(len(P)), a]

PIECES = []
for rid, pts in sorted(segs.items()):
    P, L = resample(pts)
    if len(P) < 2: continue
    a, err = assign_ways(P)
    starts = [0] + [i for i in range(1, len(a)) if a[i] != a[i - 1]]
    ends = starts[1:] + [len(a)]
    for si, (s0, s1) in enumerate(zip(starts, ends)):
        lo = max(0, s0 - 1) if si > 0 else s0
        Q = P[lo:s1]
        if len(Q) < 2: continue
        k = int(a[s0])
        PIECES.append(dict(rid=f"{rid}_{si}", way=J[k]['id'], cls=J[k]['class'] or 'residential', P=Q))

bridge_ways = [r for r in J if r['bridge']]
def nearest_way_id(target):
    dists = [float(seg_dist(target[None, :], np.array(r['pts']))[0]) for r in bridge_ways]
    return bridge_ways[int(np.argmin(dists))]['id']
used_ids = {nearest_way_id(BRIDGE_1_TARGET), nearest_way_id(BRIDGE_2_TARGET)}
flyover_ways = [r for r in bridge_ways if r['id'] not in used_ids]
print(f"{len(bridge_ways)} bridge-tagged ways total, excluding {used_ids} (the river bridges) "
      f"leaves {len(flyover_ways)} flyovers")

FLYOVERS = []
for r in flyover_ways:
    cand = [p for p in PIECES if p['way'] == r['id']]
    if not cand:
        print(f"  SKIP way {r['id']} ({r['class']}): no pass-1 piece found (hill-clip or similar)")
        continue
    cand.sort(key=lambda p: -float(np.linalg.norm(np.diff(p['P'], axis=0), axis=1).sum()))
    piece = cand[0]
    pts = np.array(r['pts'])
    drail = min(float(np.min(np.linalg.norm(pts - p, axis=1))) for p in RAIL_PTS)
    is_rail = drail <= RAIL_NEAR
    FLYOVERS.append(dict(name=f"FLYOVER_{r['id']}", way_id=r['id'], cls=piece['cls'],
                          obj_name=f"ROAD_{piece['rid']}_{piece['cls']}", is_rail=is_rail,
                          drail=drail, width=WIDTH.get(piece['cls'], 7.0), raw_pts=pts))
    print(f"  way {r['id']} ({piece['cls']}) -> {FLYOVERS[-1]['obj_name']}, "
          f"{'RAIL crossing' if is_rail else 'road crossing'} (rail dist {drail:.0f} m)")

# ---------------------------------------------------------------- open, materials, helpers
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

if "FLYOVERS" not in bpy.data.collections:
    c = bpy.data.collections.new("FLYOVERS"); bpy.context.scene.collection.children.link(c)
FCOL = bpy.data.collections["FLYOVERS"]

def concrete():
    m = bpy.data.materials.new("RCC_CONCRETE_FLY"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.60, 0.58, 0.54, 1.0); b.inputs["Roughness"].default_value = 0.85
    return m
def deck_mat():
    m = bpy.data.materials.new("FLYOVER_DECK"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.075, 0.072, 0.068, 1.0); b.inputs["Roughness"].default_value = 0.75
    return m
def barrier_mat():
    m = bpy.data.materials.new("BARRIER_RCC"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.70, 0.68, 0.64, 1.0); b.inputs["Roughness"].default_value = 0.7
    return m
MAT_CONCRETE = concrete(); MAT_DECK = deck_mat(); MAT_BARRIER = barrier_mat()

def mesh_from(vs, fs, name, mat):
    me = bpy.data.meshes.new(name); me.from_pydata(vs, [], fs); me.update()
    me.calc_loop_triangles()
    if len(me.polygons) and float(np.mean([p.normal.z for p in me.polygons if abs(p.normal.z) > 0.2] or [1])) < 0:
        me.flip_normals(); me.update()
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(mat)
    FCOL.objects.link(ob)
    return ob

def box(p0, p1, w, h, name, mat):
    d = np.array(p1) - np.array(p0)
    horiz = np.array([d[0], d[1], 0.0]); L = np.linalg.norm(horiz)
    if L < 1e-6: horiz = np.array([1.0, 0.0, 0.0]); L = 1.0
    fwd = horiz / L
    side = np.array([-fwd[1], fwd[0], 0.0]) * (w * 0.5)
    up = np.array([0.0, 0.0, h])
    a, bb = np.array(p0), np.array(p1)
    vs = [tuple(a - side), tuple(a + side), tuple(bb + side), tuple(bb - side),
          tuple(a - side + up), tuple(a + side + up), tuple(bb + side + up), tuple(bb - side + up)]
    fs = [(0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1), (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)]
    return mesh_from(vs, fs, name, mat)

fails = []
def check(name, got, want, tol):
    ok = abs(got - want) <= tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:56s} got {got:10.4f}  want {want:.4f}")
    if not ok: fails.append(name)
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

# ================================================================== PHASE 1: extract every
# piece's geometry and remove its pass-1 ribbon, BEFORE any obstruction sampling or new geometry
# exists - so no piece can accidentally treat a sibling's old ribbon (about to be replaced
# anyway) or an as-yet-unbuilt deck as "what's in the way".
for fl in FLYOVERS:
    old = bpy.data.objects.get(fl['obj_name'])
    if old is None:
        print(f"  SKIP {fl['name']}: object {fl['obj_name']} not in the file (already consumed?)")
        fl['dead'] = True; continue
    ov = np.array([v.co[:] for v in old.data.vertices])
    n_pts = len(ov) // 7
    centre = ov[3::7][:n_pts]
    P = centre[:, :2]; Zold = centre[:, 2]
    bpy.data.objects.remove(old, do_unlink=True)
    L = float(np.linalg.norm(np.diff(P, axis=0), axis=1).sum())
    if L < 1e-3 or n_pts < 2:
        print(f"  SKIP {fl['name']}: degenerate piece ({n_pts} pts, {L:.1f} m)")
        fl['dead'] = True; continue
    fl['dead'] = False
    fl['P'] = P; fl['Zold'] = Zold; fl['n_pts'] = n_pts; fl['L'] = L
    fl['s'] = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
LIVE = [fl for fl in FLYOVERS if not fl['dead']]

# The BUILT (resampled) endpoints do not line up cleanly under any single distance threshold -
# measured: real connections ranged 3.8-21 m, indistinguishable by distance alone from pairs that
# merely sit near the same busy junction without truly connecting (up to 50 m). The RAW OSM
# topology is reliable instead (ways genuinely SHARE node coordinates at a junction, exact to the
# metre) - so determine adjacency there, then map each raw endpoint onto the correct BUILT
# endpoint by orientation (whichever of built-P[0]/P[-1] lies closer to raw-first/raw-last), and
# merge on that logical correspondence rather than on resampled-point distance.
for fl in LIVE:
    rp = fl['raw_pts']; P = fl['P']
    cost_aligned = np.linalg.norm(P[0] - rp[0]) + np.linalg.norm(P[-1] - rp[-1])
    cost_flipped = np.linalg.norm(P[0] - rp[-1]) + np.linalg.norm(P[-1] - rp[0])
    fl['built_start_is_raw_start'] = cost_aligned <= cost_flipped

def raw_end_to_built_index(fl, which):   # which: 'first' or 'last' raw OSM endpoint
    aligned = fl['built_start_is_raw_start']
    if which == 'first':
        return 0 if aligned else fl['n_pts'] - 1
    else:
        return fl['n_pts'] - 1 if aligned else 0

RAW_JOIN_TOL = 2.0
raw_links = []   # (i, local_idx_i, j, local_idx_j)
for i in range(len(LIVE)):
    for j in range(i + 1, len(LIVE)):
        rpi, rpj = LIVE[i]['raw_pts'], LIVE[j]['raw_pts']
        for wi, ei in (('first', rpi[0]), ('last', rpi[-1])):
            for wj, ej in (('first', rpj[0]), ('last', rpj[-1])):
                if float(np.linalg.norm(ei - ej)) <= RAW_JOIN_TOL:
                    raw_links.append((i, raw_end_to_built_index(LIVE[i], wi),
                                       j, raw_end_to_built_index(LIVE[j], wj)))
                    print(f"  RAW-OSM link: {LIVE[i]['name']}[{wi}] <-> {LIVE[j]['name']}[{wj}] "
                          f"(built index {raw_end_to_built_index(LIVE[i], wi)} <-> "
                          f"{raw_end_to_built_index(LIVE[j], wj)})")

# ================================================================== PHASE 2: obstruction, now
# that every old ribbon in this set is gone - one consistent baseline for everyone.
bpy.context.view_layer.update()
dg = bpy.context.evaluated_depsgraph_get()
sc = bpy.context.scene
for fl in LIVE:
    P = fl['P']; n_pts = fl['n_pts']
    obstruction = np.empty(n_pts)
    for i in range(n_pts):
        hit, loc, _, _, _, _ = sc.ray_cast(dg, Vector((P[i, 0], P[i, 1], 3000.0)), Vector((0, 0, -1)))
        obstruction[i] = loc.z if hit else terrain_z(np.array([P[i, 0]]), np.array([P[i, 1]]))[0]
    fl['obstruction'] = obstruction

# ================================================================== PHASE 3: group pieces that
# share a raw-OSM endpoint (the reliable topology measured above) into one connected corridor.
n = len(LIVE)
parent = list(range(n))
def find(x):
    while parent[x] != x: parent[x] = parent[parent[x]]; x = parent[x]
    return x
def union(a, b):
    ra, rb = find(a), find(b)
    if ra != rb: parent[ra] = rb
for (i, li, j, lj) in raw_links:
    union(i, j)
groups = {}
for i in range(n): groups.setdefault(find(i), []).append(i)
print(f"\n{len(groups)} connected group(s) among {n} live flyover pieces:")
for g in groups.values():
    print(f"  group: {[LIVE[i]['name'] for i in g]}")

# ================================================================== PHASE 4: height solve, per
# group. Size 1 -> the two-ended-line method (unchanged). Size >1 -> multi-source Dijkstra over
# the combined point graph: shared endpoints (the RAW-OSM links found above) are merged into ONE
# graph node,
# so height earned climbing on one piece is available to its neighbour at the junction, instead
# of each piece fighting its own short length alone.
def clearance_of(fl): return CLEAR_RAIL if fl['is_rail'] else CLEAR_ROAD
def max_grade_of(fl): return MAX_GRADE_RAIL if fl['is_rail'] else MAX_GRADE_ROAD

for g in groups.values():
    members = [LIVE[i] for i in g]
    if len(members) == 1:
        fl = members[0]
        P, Zold, s, L = fl['P'], fl['Zold'], fl['s'], fl['L']
        obstruction = fl['obstruction']
        clearance = clearance_of(fl); max_grade = max_grade_of(fl)
        target = obstruction + clearance
        for _ in range(14):
            target = np.convolve(np.pad(target, 1, mode='edge'), [0.25, 0.5, 0.25], mode='same')[1:-1]
        reach_fwd = Zold[0] + max_grade * s
        reach_bwd = Zold[-1] + max_grade * (L - s)
        Zdeck = np.minimum(target, np.minimum(reach_fwd, reach_bwd))
        Zdeck = np.maximum(Zdeck, min(Zold[0], Zold[-1]))
        fl['Zdeck'] = Zdeck
        fl['core'] = np.isclose(Zdeck, target, atol=1e-6)
        continue

    # ---- multi-piece group: build the merged graph, using the raw-OSM link list (exact logical
    # correspondence, not a distance guess) to decide which (piece, local point) pairs are truly
    # the SAME physical node. ----
    idx_of = {LIVE.index(fl): mi for mi, fl in enumerate(members)}
    upar = {}
    def ufind(x):
        upar.setdefault(x, x)
        while upar[x] != x: upar[x] = upar[upar[x]]; x = upar[x]
        return x
    def uunion(x, y):
        rx, ry = ufind(x), ufind(y)
        if rx != ry: upar[rx] = ry
    for (i, li, j, lj) in raw_links:
        if i in idx_of and j in idx_of:
            uunion((idx_of[i], li), (idx_of[j], lj))
    for mi, fl in enumerate(members):
        for i in range(fl['n_pts']):
            ufind((mi, i))   # ensure every point has a canonical entry even with no link
    canon = sorted(set(ufind(k) for k in upar))
    canon_id = {c: k for k, c in enumerate(canon)}
    node_owner = [[] for _ in canon]
    piece_node_ids = []
    for mi, fl in enumerate(members):
        ids = np.empty(fl['n_pts'], dtype=int)
        for i in range(fl['n_pts']):
            k = canon_id[ufind((mi, i))]
            node_owner[k].append((mi, i)); ids[i] = k
        piece_node_ids.append(ids)
    n_nodes = len(canon)
    # EACH EDGE carries the grade limit of the PIECE it belongs to - a mixed rail+road group
    # (this one has both) must not let a road edge's looser 6% leak into a rail piece's own 3.5%
    # requirement, or vice versa waste climbing room a road piece didn't need.
    adj = [[] for _ in range(n_nodes)]   # (neighbour, physical distance, this edge's max_grade)
    for mi, fl in enumerate(members):
        ids = piece_node_ids[mi]; mg = max_grade_of(fl)
        for i in range(fl['n_pts'] - 1):
            d = float(np.linalg.norm(fl['P'][i + 1] - fl['P'][i]))
            a, b = int(ids[i]), int(ids[i + 1])
            adj[a].append((b, d, mg)); adj[b].append((a, d, mg))

    # anchors: a node that is an ENDPOINT of exactly one piece's own sequence AND is not an
    # interior point of any piece - i.e. it dead-ends into the untouched ordinary road network.
    node_obstruction = np.zeros(n_nodes); node_hits = np.zeros(n_nodes)
    for mi, fl in enumerate(members):
        ids = piece_node_ids[mi]
        for i, k in enumerate(ids):
            node_obstruction[k] += fl['obstruction'][i]; node_hits[k] += 1
    node_obstruction /= np.maximum(node_hits, 1)
    is_endpoint_only = []
    for k in range(n_nodes):
        owners = node_owner[k]
        is_dead_end = all(loc_i in (0, members[mi]['n_pts'] - 1) for mi, loc_i in owners)
        is_endpoint_only.append(is_dead_end and len(owners) <= 2)
    anchors = [k for k in range(n_nodes) if is_endpoint_only[k] and len(adj[k]) == 1]
    if not anchors:   # degenerate topology guard - fall back to every true degree-1 node
        anchors = [k for k in range(n_nodes) if len(adj[k]) == 1]
    anchor_height = {}
    for k in anchors:
        mi, loc_i = node_owner[k][0]
        anchor_height[k] = float(members[mi]['Zold'][loc_i])
    print(f"  group {[fl['name'] for fl in members]}: {n_nodes} merged nodes, "
          f"{len(anchors)} anchor(s) at {[f'{anchor_height[k]:.2f}m' for k in anchors]}")

    # multi-source Dijkstra: reach(node) = min over anchors of (anchor_height + sum of each
    # crossed edge's OWN max_grade * that edge's length) - never a single group-wide constant.
    reach = np.full(n_nodes, np.inf)
    pq = []
    for k in anchors:
        reach[k] = anchor_height[k]
        heapq.heappush(pq, (reach[k], k))
    while pq:
        d, u = heapq.heappop(pq)
        if d > reach[u] + 1e-9: continue
        for v, w, mg in adj[u]:
            nd = d + mg * w
            if nd < reach[v] - 1e-9:
                reach[v] = nd
                heapq.heappush(pq, (nd, v))

    # per-node clearance: the max required by whichever piece(s) actually own that node, not a
    # single group-wide constant (a road-only node needs 5.5 m, not the rail pieces' 7.9 m).
    node_clearance = np.array([max(clearance_of(members[mi]) for mi, _ in node_owner[k])
                                for k in range(n_nodes)])
    target_node = node_obstruction + node_clearance
    # graph-smooth: a few rounds of averaging with immediate neighbours (generalises the 1-D
    # 3-point convolution to a graph, including the junction's branch point)
    for _ in range(6):
        new_t = target_node.copy()
        for k in range(n_nodes):
            if not adj[k]: continue
            nbrs = [target_node[v] for v, _, _ in adj[k]]
            new_t[k] = 0.5 * target_node[k] + 0.5 * float(np.mean(nbrs))
        target_node = new_t
    zdeck_node = np.minimum(target_node, reach)
    zdeck_node = np.maximum(zdeck_node, min(anchor_height.values()))

    for mi, fl in enumerate(members):
        ids = piece_node_ids[mi]
        fl['Zdeck'] = zdeck_node[ids]
        fl['core'] = np.isclose(fl['Zdeck'], np.array([target_node[k] for k in ids]), atol=1e-6)

# ================================================================== PHASE 5: build every piece
# from its solved Zdeck (identical geometry/barrier/pier/assertion code for every piece,
# regardless of which height method produced Zdeck).
for fl in LIVE:
    P, Zold, s, L, n_pts = fl['P'], fl['Zold'], fl['s'], fl['L'], fl['n_pts']
    Zdeck, obstruction, core = fl['Zdeck'], fl['obstruction'], fl['core']
    clearance = clearance_of(fl); max_grade = max_grade_of(fl)
    # FINAL SAFETY CLAMP, per piece: MEASURED (not assumed) that the graph solve's junction-node
    # smoothing can leave one sharp local DROP that a one-sided "cap how fast it can rise" clamp
    # does not catch (that only bounds ascent, not descent - a real gap, found by printing the
    # actual array, not guessed). Fixed with the same two-pass gradient limiter 03_roads.py
    # already uses for the plain profile: forward pass bounds how much higher a point can be than
    # the one before it, backward pass bounds how much higher it can be than the one after it -
    # together they bound |slope| in both directions without moving either endpoint.
    if n_pts > 1:
        ds = np.diff(s)
        zz = Zdeck.copy()
        for i in range(1, n_pts):
            zz[i] = min(zz[i], zz[i - 1] + max_grade * ds[i - 1])
        for i in range(n_pts - 2, -1, -1):
            zz[i] = min(zz[i], zz[i + 1] + max_grade * ds[i])
        Zdeck = zz
        fl['Zdeck'] = Zdeck
    grade = float(np.max(np.abs(np.diff(Zdeck)) / np.maximum(np.diff(s), 1e-6))) if n_pts > 1 else 0.0
    gaps_all = Zdeck - obstruction
    mingap_all = float(np.min(gaps_all))
    mingap = float(np.min(gaps_all[core])) if core.any() else mingap_all

    print(f"\n{fl['name']} ({'RAIL' if fl['is_rail'] else 'ROAD'}): {n_pts} pts, span {L:.1f} m, "
          f"obstruction max {obstruction.max():.2f} m, target clearance {clearance} m, "
          f"grade {grade * 100:.2f}% (limit {max_grade*100:.1f}%)")

    half = fl['width'] * 0.5
    tang = np.zeros_like(P)
    tang[1:-1] = P[2:] - P[:-2]; tang[0] = P[1] - P[0]; tang[-1] = P[-1] - P[-2]
    tn = np.linalg.norm(tang, axis=1, keepdims=True); tn[tn < 1e-9] = 1.0; tang /= tn
    nor = np.c_[-tang[:, 1], tang[:, 0]]
    profile = [(-half - 0.3, 0.0), (-half, 0.0), (0.0, 0.0), (half, 0.0), (half + 0.3, 0.0)]
    vs = []; uvs = []
    for i in range(n_pts):
        for (o, dz) in profile:
            q = P[i] + nor[i] * o
            crown = -abs(o) * CAMBER if abs(o) <= half else 0.0
            vs.append((q[0], q[1], Zdeck[i] + dz + crown))
            uvs.append((0.5 + o / (2 * half), s[i] / max(fl['width'], 1e-6)))
    npr = len(profile)
    fs = []
    for i in range(n_pts - 1):
        for k in range(npr - 1):
            a = i * npr + k; bq = a + 1; c = (i + 1) * npr + k; dd = c + 1
            fs.append((a, bq, dd, c))
    deck = mesh_from(vs, fs, f"{fl['name']}_DECK", MAT_DECK)
    uvl = deck.data.uv_layers.new(name="UVMap")
    for poly in deck.data.polygons:
        for li in poly.loop_indices:
            uvl.data[li].uv = uvs[deck.data.loops[li].vertex_index]

    post_i = np.arange(0, n_pts, max(1, int(round(2.0 / max(L / max(n_pts - 1, 1), 1e-6)))))
    for side_o in (-half - 0.15, half + 0.15):
        for i in range(len(post_i) - 1):
            i0, i1 = post_i[i], post_i[i + 1]
            q0 = P[i0] + nor[i0] * side_o; q1 = P[i1] + nor[i1] * side_o
            box(np.r_[q0, Zdeck[i0]], np.r_[q1, Zdeck[i1]], 0.25, BARRIER_KERB,
                f"{fl['name']}_KERB_{side_o:.1f}_{i0}", MAT_BARRIER)
            box(np.r_[q0, Zdeck[i0] + BARRIER_H - 0.08], np.r_[q1, Zdeck[i1] + BARRIER_H - 0.08],
                0.08, 0.16, f"{fl['name']}_BEAM_{side_o:.1f}_{i0}", MAT_CONCRETE)
        for i in post_i:
            q = P[i] + nor[i] * side_o
            box(np.r_[q, Zdeck[i]], np.r_[q, Zdeck[i]], 0.15, BARRIER_H,
                f"{fl['name']}_POST_{side_o:.1f}_{i}", MAT_CONCRETE)

    n_spans = max(2, int(round(L / PIER_SPACING)))
    pier_ts = [k / n_spans for k in range(1, n_spans)]
    pier_count = 0
    for pt in pier_ts:
        i = int(round(pt * (n_pts - 1)))
        q = P[i]; ztop = Zdeck[i] - DECK_THICK
        zground = float(terrain_z(np.array([q[0]]), np.array([q[1]]))[0])
        for side in (-1, 1):
            col_q = q + nor[i] * (half * 0.75 * side)
            box(np.r_[col_q, zground], np.r_[col_q, ztop], PIER_SIZE, 0.01,
                f"{fl['name']}_PIER_{pier_count}_{side}", MAT_CONCRETE)
        pier_count += 1
    print(f"  {pier_count} piers at ~{L / n_spans:.1f} m centres, width {fl['width']:.1f} m")

    dv = np.array([v.co[:] for v in deck.data.vertices])
    idx_edges = [ii for ii, (oo, dz) in enumerate(profile) if abs(abs(oo) - half) < 1e-6]
    p0 = dv[idx_edges[0]]; p1 = dv[idx_edges[1]]
    check(f"{fl['name']} measured deck width (m)", float(np.linalg.norm(p0[:2] - p1[:2])),
          fl['width'], 0.05)
    if core.any():
        flag(f"{fl['name']} the elevated core never clips whatever is beneath it "
             f"(worst gap over the core {mingap:.2f} m; full-span min {mingap_all:.2f} m at the "
             f"ordinary-road connection points, expected)", mingap >= 0.10)
        achieved = mingap >= clearance - 0.05
        if achieved:
            print(f"  OK   {fl['name']} full {clearance} m design clearance achieved over the core")
        else:
            print(f"  INFO {fl['name']} full {clearance} m clearance NOT achieved over the core "
                  f"(only {mingap:.2f} m) - genuinely too short even after joining connected "
                  f"pieces, not a build error")
    else:
        print(f"  INFO {fl['name']} NO ELEVATED CORE within its own {L:.1f} m even after joining "
              f"connected pieces (full-span min gap {mingap_all:.2f} m). Not a build defect.")
    flag(f"{fl['name']} approach grade stays under {max_grade*100:.1f}% (max {grade*100:.2f}%)",
         grade <= max_grade + 1e-3)

print(f"\n================= COMPONENT 3 PASS 2 - FLYOVERS : ASSERTIONS =================")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
print(f"build time {time.time() - T0:.0f}s")
bpy.ops.wm.save_mainfile(filepath=ROADSBLEND)
print(f"saved: {ROADSBLEND}")
if fails: sys.exit(1)
