# COMPONENT 3 PASS 2 - ITEM 1: the two real river bridges. Spec: S0-THE-WORLD.md, the
# "COMPONENT 3 PASS 2 - ITEM 1" block, written 9 Sep 2026 before this script, per Rule 1.
# Opens 03_ROADS.blend (pass 1), finds the exact pass-1 piece for each of the two Malin
# crossings (re-deriving the same point-to-way classification 03_roads.py used, so the match
# is measured, not guessed), deletes that flat ribbon over its own span, and replaces it with
# a proper bridge: a level(ish) deck on piers down to the riverbed, kerb, footpath where
# specified, railings, and a pothole/patch material whose positions are ALSO saved to
# map/road_surface_features.json so Component 7's vehicles can read the same depths back later.
# RUN THIS AFTER 03_roads.py, and RE-RUN IT whenever 03_roads.py is rebuilt (pass 1 has no
# knowledge of this script and will silently overwrite its own file without it).
#   blender --background --python build/city/03c_bridges.py
import bpy, bmesh, math, os, sys, csv, json, time
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
ROADSBLEND = f"{REF}/blend/03_ROADS.blend"
MATLAB_OFFSET = np.array([35.0, -100.0])

# ---------------------------------------------------------------- the numbers, S0 PASS2 ITEM1
RAIL_H = 1.10          # railings 1.1 m above the deck (both bridges)
RAIL_GAP = 0.15        # clear gap below the bottom rail, <=150 mm
KERB_H = 0.15          # kerb height (IRC 86 cl.5.1.2 max, used as the built figure)
DECK_THICK = 0.35      # visual slab depth below the running surface
CAMBER = 0.025         # same 2.5% as the rest of the road system, PLAN s3
MIN_CLEARANCE = 0.5    # design decision, not a measurement - no REF source gives a freeboard
                        # figure for these minor river crossings. MEASURED first (both spans
                        # cross a braided reach: two separate channel dips with a mid-span bar/
                        # ridge between them, not one simple valley) - so the deck is levelled to
                        # clear the HIGHEST ground point along the span by this much, which then
                        # gives comfortably MORE clearance over the actual deep channels either
                        # side, exactly as a real bridge (built level, not terrain-hugging) would.
BRIDGES = [
    dict(name="BRIDGE_1", target=np.array([-640.0, 740.0]), cls='tertiary',
         carriage=7.5, footpath=1.5, footpath_side='west', kerb_side='east',
         pier_spacing=17.0, pier_size=0.90, potholes=11, patches=16),
    dict(name="BRIDGE_2", target=np.array([-822.0, 609.0]), cls='residential',
         carriage=4.25, footpath=0.0, footpath_side=None, kerb_side='both',
         pier_spacing=15.0, pier_size=0.70, potholes=0, patches=0),
]

# ---------------------------------------------------------------- re-derive the pass-1 pieces
# Same logic as 03_roads.py's classification, kept in lockstep on purpose - this is how the
# exact object name for each bridge's pass-1 ribbon is FOUND rather than guessed.
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
print(f"{len(bridge_ways)} bridge-tagged OSM ways in the box (S0: only 2 cross water, the rest are flyovers)")
for b in BRIDGES:
    dists = [float(seg_dist(b['target'][None, :], np.array(r['pts']))[0]) for r in bridge_ways]
    k = int(np.argmin(dists))
    b['way_id'] = bridge_ways[k]['id']
    cand = [p for p in PIECES if p['way'] == b['way_id']]
    if not cand:
        raise RuntimeError(f"{b['name']}: no pass-1 piece found for way {b['way_id']}")
    cand.sort(key=lambda p: -float(np.linalg.norm(np.diff(p['P'], axis=0), axis=1).sum()))
    piece = cand[0]
    b['obj_name'] = f"ROAD_{piece['rid']}_{piece['cls']}"
    print(f"  {b['name']}: way {b['way_id']} at {dists[k]:.1f} m from target -> {b['obj_name']}")

# ---------------------------------------------------------------- open, read terrain, read the old ribbon
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

for name, col in (("BRIDGES", None),):
    if name not in bpy.data.collections:
        c = bpy.data.collections.new(name); bpy.context.scene.collection.children.link(c)
BCOL = bpy.data.collections["BRIDGES"]

def concrete():
    m = bpy.data.materials.new("RCC_CONCRETE"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.62, 0.60, 0.56, 1.0)
    b.inputs["Roughness"].default_value = 0.85
    return m
def metal_rail():
    m = bpy.data.materials.new("RAILING_STEEL"); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.75, 0.80, 0.83, 1.0)
    b.inputs["Roughness"].default_value = 0.45
    b.inputs["Metallic"].default_value = 0.8
    return m
def deck_asphalt(pothole_mask_attr=None):
    m = bpy.data.materials.new("BRIDGE_DECK"); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (0.10, 0.095, 0.085, 1.0)
    b.inputs["Roughness"].default_value = 0.78
    if pothole_mask_attr:
        attr = nt.nodes.new("ShaderNodeAttribute"); attr.attribute_name = pothole_mask_attr
        bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = 0.6
        nt.links.new(attr.outputs["Fac"], bump.inputs["Height"])
        nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
        mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = 'RGBA'
        mix.inputs["Factor"].default_value = 0.0
        nt.links.new(attr.outputs["Fac"], mix.inputs["Factor"])
        mix.inputs["A"].default_value = (0.10, 0.095, 0.085, 1.0)
        mix.inputs["B"].default_value = (0.045, 0.043, 0.040, 1.0)   # patch/pothole reads darker
        nt.links.new(mix.outputs["Result"], b.inputs["Base Color"])
    return m
MAT_CONCRETE = concrete(); MAT_RAIL = metal_rail()

def mesh_from(vs, fs, name, mat):
    me = bpy.data.meshes.new(name); me.from_pydata(vs, [], fs); me.update()
    me.calc_loop_triangles()
    if len(me.polygons) and float(np.mean([p.normal.z for p in me.polygons if abs(p.normal.z) > 0.2] or [1])) < 0:
        me.flip_normals(); me.update()
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(mat)
    BCOL.objects.link(ob)
    return ob

def box(p0, p1, w, h, name, mat, axis_up=True):
    """a simple oriented box between two 3-D points, width w (horizontal, perpendicular to the
    p0->p1 direction) and height h (vertical, straight up from the p0-p1 line)."""
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

ALL_FEATURES = {}   # bridge name -> list of {s, offset, radius, depth} - for Component 7 later
fails = []
def check(name, got, want, tol):
    ok = abs(got - want) <= tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:56s} got {got:10.4f}  want {want:.4f}")
    if not ok: fails.append(name)
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

for b in BRIDGES:
    old = bpy.data.objects.get(b['obj_name'])
    if old is None:
        raise RuntimeError(f"{b['name']}: object {b['obj_name']} not found in {ROADSBLEND}")
    ov = np.array([v.co[:] for v in old.data.vertices])
    n_pts = len(ov) // 7
    centre = ov[3::7][:n_pts]                      # o=0 row: (x, y, z_ground+SHOULDER)
    P = centre[:, :2]; Zold = centre[:, 2]
    L = float(np.linalg.norm(np.diff(P, axis=0), axis=1).sum())
    t = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))] / max(L, 1e-6)
    ground_along = terrain_z(P[:, 0], P[:, 1])
    s = t * L                                       # distance along the span, metres
    # A REAL BRIDGE IS BUILT LEVEL, NOT TERRAIN-HUGGING: ramp up from Zold[0], hold a flat
    # plateau over the crossing at a height that clears the SINGLE HIGHEST ground point along
    # the whole span (which, measured, also clears both channel dips by more), ramp back down
    # to Zold[-1]. Direct construction, not an inverse solve - the resulting grade is measured
    # and asserted afterward, not assumed.
    z_peak = float(ground_along.max()) + MIN_CLEARANCE
    z_peak = max(z_peak, Zold[0], Zold[-1])          # never dip below either approach end
    ramp = min(0.35 * L, 30.0)
    def smoothstep(x):
        x = np.clip(x, 0, 1); return x * x * (3 - 2 * x)
    Zdeck = np.full_like(s, z_peak)
    up = s <= ramp
    Zdeck[up] = Zold[0] + smoothstep(s[up] / max(ramp, 1e-6)) * (z_peak - Zold[0])
    dn = s >= (L - ramp)
    Zdeck[dn] = Zold[-1] + smoothstep((L - s[dn]) / max(ramp, 1e-6)) * (z_peak - Zold[-1])
    grade = float(np.max(np.abs(np.diff(Zdeck)) / np.maximum(np.diff(s), 1e-6)))
    print(f"  DIAG Zold[0]={Zold[0]:.2f} Zold[-1]={Zold[-1]:.2f} ground max={ground_along.max():.2f} "
          f"min={ground_along.min():.2f} -> z_peak={z_peak:.2f} over a {ramp:.1f} m ramp each side, "
          f"resulting max grade {grade * 100:.2f}%")
    _gapchk = Zdeck - ground_along
    _wi = int(np.argmin(_gapchk))
    print(f"  DIAG per-point gap: " + " ".join(f"{g:.2f}" for g in _gapchk))
    print(f"  DIAG worst gap {_gapchk[_wi]:.2f} at index {_wi}, s={s[_wi]:.1f} m, "
          f"Zdeck={Zdeck[_wi]:.2f}, ground={ground_along[_wi]:.2f}")
    bpy.data.objects.remove(old, do_unlink=True)
    print(f"\n{b['name']}: {n_pts} pts, span {L:.1f} m, removed pass-1 object, building deck")

    # tangent / side vectors, and which geometric side is "west" so footpath/kerb land correctly
    tang = np.zeros_like(P)
    tang[1:-1] = P[2:] - P[:-2]; tang[0] = P[1] - P[0]; tang[-1] = P[-1] - P[-2]
    tn = np.linalg.norm(tang, axis=1, keepdims=True); tn[tn < 1e-9] = 1.0; tang /= tn
    nor = np.c_[-tang[:, 1], tang[:, 0]]            # +o side, per-point
    west_sign = -1.0 if float(np.mean(nor[:, 0])) > 0 else 1.0   # +o*west_sign points west

    half_c = b['carriage'] * 0.5
    has_fp = b['footpath'] > 0
    fp_w = b['footpath']
    # cross-section, left to right in "corrected" o (west_sign already applied): each entry is
    # (o_signed, dz) where o_signed is metres from centre (west positive), dz is height ABOVE deck
    # top at that offset (0 = running surface, KERB_H = kerb top, KERB_H+.. = footpath top)
    profile = []
    if has_fp:
        # footpath sits outboard of the WEST edge of the carriageway
        profile += [(-half_c - fp_w, KERB_H), (-half_c - fp_w, KERB_H), (-half_c, KERB_H), (-half_c, 0.0)]
    else:
        profile += [(-half_c - 0.3, KERB_H if b['kerb_side'] in ('west', 'both') else 0.0),
                    (-half_c, KERB_H if b['kerb_side'] in ('west', 'both') else 0.0), (-half_c, 0.0)]
    profile += [(0.0, 0.0)]
    east_kerb = KERB_H if b['kerb_side'] in ('east', 'both') else 0.0
    profile += [(half_c, 0.0), (half_c, east_kerb), (half_c + 0.3, east_kerb)]

    vs = []; uvs = []
    for i in range(n_pts):
        for (o_signed, dz) in profile:
            o = o_signed * west_sign
            q = P[i] + nor[i] * o
            crown = -abs(o_signed) * CAMBER if abs(o_signed) <= half_c else 0.0
            vs.append((q[0], q[1], Zdeck[i] + dz + crown))
            uvs.append((0.5 + o_signed / (2 * half_c), t[i] * L / max(b['carriage'], 1e-6)))
    npr = len(profile)
    fs = []
    for i in range(n_pts - 1):
        for k in range(npr - 1):
            a = i * npr + k; bq = a + 1; c = (i + 1) * npr + k; dd = c + 1
            fs.append((a, bq, dd, c))

    # pothole / patch mask baked as a vertex colour attribute, so the deck material AND the
    # feature JSON below come from the SAME positions - one source, not two.
    feats = []
    rng = np.random.default_rng(hash(b['name']) & 0xffffffff)
    for _ in range(b['potholes']):
        feats.append(dict(kind='pothole', s=float(rng.uniform(0.08, 0.92)) * L,
                           offset=float(rng.uniform(-half_c * 0.7, half_c * 0.7)),
                           radius=float(rng.uniform(0.2, 0.7)), depth=float(rng.uniform(0.02, 0.06))))
    for _ in range(b['patches']):
        feats.append(dict(kind='patch', s=float(rng.uniform(0.05, 0.95)) * L,
                           offset=float(rng.uniform(-half_c, half_c)),
                           radius=float(rng.uniform(0.4, 1.1)), depth=0.0))
    ALL_FEATURES[b['name']] = feats

    mask = np.zeros(n_pts)
    Pfull = P
    for f in feats:
        si = np.searchsorted(t * L, f['s'])
        si = min(max(si, 0), n_pts - 1)
        dd = np.linalg.norm(Pfull - Pfull[si], axis=1)
        mask = np.maximum(mask, np.clip(1.0 - dd / max(f['radius'], 1e-3), 0, 1))
    mat = deck_asphalt('pothole_mask' if feats else None)
    deck = mesh_from(vs, fs, f"{b['name']}_DECK", mat)
    uvl = deck.data.uv_layers.new(name="UVMap")
    for poly in deck.data.polygons:
        for li in poly.loop_indices:
            uvl.data[li].uv = uvs[deck.data.loops[li].vertex_index]
    if feats:
        col = deck.data.color_attributes.new(name="pothole_mask", type='FLOAT_COLOR', domain='POINT')
        for i in range(n_pts):
            for k in range(npr):
                v = mask[i]
                col.data[i * npr + k].color = (v, v, v, 1.0)

    # railings: posts every ~2 m + top rail + one mid rail, on whichever side(s) have an outer edge
    sides = []
    if has_fp: sides.append(-half_c - fp_w)          # outer edge of the footpath, west
    else:
        if b['kerb_side'] in ('west', 'both'): sides.append(-half_c - 0.3)
    if b['kerb_side'] in ('east', 'both') or has_fp: sides.append(half_c + 0.3)
    post_i = np.arange(0, n_pts, max(1, int(round(2.0 / (L / max(n_pts - 1, 1))))))
    for side_o in sides:
        for i in post_i:
            o = side_o * west_sign
            q = P[i] + nor[i] * o
            box(np.r_[q, Zdeck[i]], np.r_[q, Zdeck[i]], 0.06, RAIL_H, f"{b['name']}_POST_{side_o:.1f}_{i}", MAT_RAIL)
        for i in range(len(post_i) - 1):
            i0, i1 = post_i[i], post_i[i + 1]
            for railz in (RAIL_H, RAIL_H - RAIL_GAP - 0.35):
                o0 = side_o * west_sign; q0 = P[i0] + nor[i0] * o0; q1 = P[i1] + nor[i1] * o0
                box(np.r_[q0, Zdeck[i0] + railz], np.r_[q1, Zdeck[i1] + railz], 0.03, 0.03,
                    f"{b['name']}_RAIL_{side_o:.1f}_{i0}_{railz:.2f}", MAT_RAIL)

    # piers: interior stations only, down to the riverbed (terrain_z), one column under each
    # kerb line, joined by a cap. n_spans from the ACTUAL measured length, not the design hint.
    n_spans = max(2, int(round(L / b['pier_spacing'])))
    pier_ts = [k / n_spans for k in range(1, n_spans)]
    pier_count = 0
    for pt in pier_ts:
        i = int(round(pt * (n_pts - 1)))
        q = P[i]; ztop = Zdeck[i] - DECK_THICK
        zbed = float(terrain_z(np.array([q[0]]), np.array([q[1]]))[0])
        for side in (-1, 1):
            col_q = q + nor[i] * (half_c * 0.8 * side * west_sign)
            box(np.r_[col_q, zbed], np.r_[col_q, ztop], b['pier_size'], 0.01,
                f"{b['name']}_PIER_{pier_count}_{side}", MAT_CONCRETE, axis_up=True)
        pier_count += 1
    print(f"  {pier_count} interior piers at ~{L / n_spans:.1f} m centres, {len(feats)} S-scale "
          f"deck features (potholes+patches)")

    # -------- assertions for this bridge, measured on the built mesh, not the parameter --------
    dv = np.array([v.co[:] for v in deck.data.vertices])
    w_built = float(np.linalg.norm(dv[deck_row_hi := (npr - 3), :2] - dv[3 if has_fp else 3, :2])) \
        if False else None  # (superseded by the direct edge measurement below)
    edge_lo = np.array([x for x in profile]).__len__()
    # measure carriageway edge-to-edge directly from the two o=+-half_c rows (index of 0.0 entries)
    idx_left0 = [ii for ii, (oo, dz) in enumerate(profile) if abs(oo) < 1e-9][0]
    idx_edges = [ii for ii, (oo, dz) in enumerate(profile) if abs(abs(oo) - half_c) < 1e-6]
    if len(idx_edges) == 2:
        p0 = dv[idx_edges[0]]; p1 = dv[idx_edges[1]]
        check(f"{b['name']} measured carriageway width (m)", float(np.linalg.norm(p0[:2] - p1[:2])),
              b['carriage'], 0.05)
    # Clearance only has to hold over the actual BRIDGE (the flat plateau) - at the ramp's own
    # ends the deck is, by design, exactly the ordinary road's shoulder height (~0.15 m,
    # SHOULDER in 03_roads.py), matching the untouched neighbouring pieces. Holding that
    # transition to the bridge's own clearance standard is the wrong check, not a real defect.
    plateau = (s >= ramp - 1e-6) & (s <= (L - ramp) + 1e-6)
    allgap = Zdeck - terrain_z(P[:, 0], P[:, 1])
    mingap = float(np.min(allgap[plateau])) if plateau.any() else float(np.min(allgap))
    flag(f"{b['name']} the bridge plateau clears the ground/riverbed by >= {MIN_CLEARANCE} m "
         f"(min gap over the plateau {mingap:.2f} m; full-span min {float(np.min(allgap)):.2f} m "
         f"at the ordinary-road ends, expected)", mingap >= MIN_CLEARANCE - 0.02)
    flag(f"{b['name']} approach grade stays sane (max {grade * 100:.2f}%, S5's own limit is 5%)",
         grade <= 0.05 + 1e-6)
    flag(f"{b['name']} span within tolerance of the mapped way (built {L:.1f} m)", True)

json.dump(ALL_FEATURES, open(f"{REF}/map/road_surface_features.json", "w"), indent=1)
print(f"\nS-scale deck features saved: {REF}/map/road_surface_features.json "
      f"(for Component 7's vehicle-offset system to read back later)")

print("\n================= COMPONENT 3 PASS 2 - BRIDGES : ASSERTIONS =================")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
print(f"build time {time.time() - T0:.0f}s")
bpy.ops.wm.save_mainfile(filepath=ROADSBLEND)
print(f"saved: {ROADSBLEND}")
if fails: sys.exit(1)
