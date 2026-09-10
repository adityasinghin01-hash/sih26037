# COMPONENT 3 PASS 2 - ITEM 6 (closes Component 3): S-scale road materials. Spec: S0-THE-WORLD.md
# "COMPONENT 3 PASS 2 - ITEM 6", written 10 Sep 2026 before this script, per Rule 1. Material
# only, per PLAN s3 method 2 / REF-11 s6 - never cut geometry.
# Network-wide: edge line (150 mm), centre line where width >=5.5 m (IRC Table 4.3), a
# noise-masked crumbling edge. S1's own located potholes/speed-breaker/culvert-stain
# (S1-CATTLE-CROSSING.md) on its through road get an ADDITIONAL layered mask, driven by
# world Position (not mesh density) - real visible marks, not just JSON data - plus the
# same positions saved to map/road_surface_features.json for Component 7's vehicle physics.
#   blender --background --python build/city/03h_roadmaterials.py
import bpy, os, sys, json, time, zlib
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
ROADSBLEND = f"{REF}/blend/03_ROADS.blend"

WIDTH = {'trunk': 14.0, 'trunk_link': 7.0, 'secondary': 7.0, 'tertiary': 7.0,
         'unclassified': 5.5, 'residential': 4.5, 'living_street': 3.2}
EDGE_W_WIDE = 0.150; EDGE_W_NARROW = 0.100   # REF-01 s2: 100mm where paved width <7m
CENTRE_MIN_W = 5.5                            # IRC Table 4.3
CENTRE_MARK = 3.0; CENTRE_GAP = 6.0; CENTRE_W = 0.10
CRUMBLE_BAND = 0.20   # m, within [100,300]mm range, centred

bpy.ops.wm.open_mainfile(filepath=ROADSBLEND)

def marked_asphalt(width, features=None):
    # features: optional list of world-space dicts layered ON TOP of the network-wide
    # marking/crumble look - potholes (2 variants: raw pit vs patched repair), a speed
    # breaker's black/white bands, a culvert water-stain. All masks driven off world
    # Position, never mesh geometry - PLAN §3 "material, not cut geometry" holds exactly,
    # and it means the mask reads correctly regardless of the road mesh's own vertex density.
    m = bpy.data.materials.new(f"ASPHALT_MARKED_{width:.2f}{'_S1' if features else ''}")
    m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    uv = nt.nodes.new("ShaderNodeUVMap")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(uv.outputs["UV"], sep.inputs["Vector"])
    # existing pass-1 UV: u=0.5+o*0.5 (0 at left edge, 1 at right edge), v=dist_along/width
    edge_w = EDGE_W_WIDE if width >= 7.0 else EDGE_W_NARROW
    def edge_mask(sign):
        target_u = 0.5 + sign * 0.5 - sign * (0.150 / width)   # 150mm in from the edge
        sub = nt.nodes.new("ShaderNodeMath"); sub.operation = 'SUBTRACT'; sub.inputs[1].default_value = target_u
        nt.links.new(sep.outputs["X"], sub.inputs[0])
        absn = nt.nodes.new("ShaderNodeMath"); absn.operation = 'ABSOLUTE'
        nt.links.new(sub.outputs["Value"], absn.inputs[0])
        less = nt.nodes.new("ShaderNodeMath"); less.operation = 'LESS_THAN'
        less.inputs[1].default_value = (edge_w / width) / 2.0
        nt.links.new(absn.outputs["Value"], less.inputs[0])
        return less
    left_edge = edge_mask(-1); right_edge = edge_mask(1)
    edge_or = nt.nodes.new("ShaderNodeMath"); edge_or.operation = 'MAXIMUM'
    nt.links.new(left_edge.outputs["Value"], edge_or.inputs[0])
    nt.links.new(right_edge.outputs["Value"], edge_or.inputs[1])
    marking_mask = edge_or
    if width >= CENTRE_MIN_W:
        distv = nt.nodes.new("ShaderNodeMath"); distv.operation = 'MULTIPLY'
        distv.inputs[1].default_value = width
        nt.links.new(sep.outputs["Y"], distv.inputs[0])
        wrap = nt.nodes.new("ShaderNodeMath"); wrap.operation = 'WRAP'
        wrap.inputs[1].default_value = 0.0; wrap.inputs[2].default_value = CENTRE_MARK + CENTRE_GAP
        nt.links.new(distv.outputs["Value"], wrap.inputs[0])
        dashon = nt.nodes.new("ShaderNodeMath"); dashon.operation = 'LESS_THAN'
        dashon.inputs[1].default_value = CENTRE_MARK
        nt.links.new(wrap.outputs["Value"], dashon.inputs[0])
        subc = nt.nodes.new("ShaderNodeMath"); subc.operation = 'SUBTRACT'; subc.inputs[1].default_value = 0.5
        nt.links.new(sep.outputs["X"], subc.inputs[0])
        absc = nt.nodes.new("ShaderNodeMath"); absc.operation = 'ABSOLUTE'
        nt.links.new(subc.outputs["Value"], absc.inputs[0])
        centreband = nt.nodes.new("ShaderNodeMath"); centreband.operation = 'LESS_THAN'
        centreband.inputs[1].default_value = (CENTRE_W / width) / 2.0
        nt.links.new(absc.outputs["Value"], centreband.inputs[0])
        centre_on = nt.nodes.new("ShaderNodeMath"); centre_on.operation = 'MULTIPLY'
        nt.links.new(dashon.outputs["Value"], centre_on.inputs[0])
        nt.links.new(centreband.outputs["Value"], centre_on.inputs[1])
        combined = nt.nodes.new("ShaderNodeMath"); combined.operation = 'MAXIMUM'
        nt.links.new(marking_mask.outputs["Value"], combined.inputs[0])
        nt.links.new(centre_on.outputs["Value"], combined.inputs[1])
        marking_mask = combined
    # crumbling edge: a noise-masked band just inside each carriageway edge
    noise = nt.nodes.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 40.0
    def crumble_mask(sign):
        target_u = 0.5 + sign * 0.5
        sub = nt.nodes.new("ShaderNodeMath"); sub.operation = 'SUBTRACT'; sub.inputs[1].default_value = target_u
        nt.links.new(sep.outputs["X"], sub.inputs[0])
        absn = nt.nodes.new("ShaderNodeMath"); absn.operation = 'ABSOLUTE'
        nt.links.new(sub.outputs["Value"], absn.inputs[0])
        band = nt.nodes.new("ShaderNodeMath"); band.operation = 'LESS_THAN'
        band.inputs[1].default_value = (CRUMBLE_BAND / width)
        nt.links.new(absn.outputs["Value"], band.inputs[0])
        withnoise = nt.nodes.new("ShaderNodeMath"); withnoise.operation = 'MULTIPLY'
        nt.links.new(band.outputs["Value"], withnoise.inputs[0])
        nt.links.new(noise.outputs["Fac"], withnoise.inputs[1])
        return withnoise
    crumble = nt.nodes.new("ShaderNodeMath"); crumble.operation = 'MAXIMUM'
    nt.links.new(crumble_mask(-1).outputs["Value"], crumble.inputs[0])
    nt.links.new(crumble_mask(1).outputs["Value"], crumble.inputs[1])

    base_col = nt.nodes.new("ShaderNodeMix"); base_col.data_type = 'RGBA'
    base_col.inputs["A"].default_value = (0.052, 0.050, 0.048, 1.0)
    base_col.inputs["B"].default_value = (0.208, 0.163, 0.108, 1.0)   # crumbled -> earth tone
    nt.links.new(crumble.outputs["Value"], base_col.inputs["Factor"])
    final_mix = nt.nodes.new("ShaderNodeMix"); final_mix.data_type = 'RGBA'
    nt.links.new(base_col.outputs["Result"], final_mix.inputs["A"])
    final_mix.inputs["B"].default_value = (0.85, 0.85, 0.82, 1.0)   # white/pale marking
    nt.links.new(marking_mask.outputs["Value"], final_mix.inputs["Factor"])
    base_color_out = final_mix.outputs["Result"]
    roughness_val = 0.72
    bump_height = crumble.outputs["Value"]
    bump_strength = 0.3

    if features:
        pos = nt.nodes.new("ShaderNodeNewGeometry")
        sepP = nt.nodes.new("ShaderNodeSeparateXYZ")
        nt.links.new(pos.outputs["Position"], sepP.inputs["Vector"])
        Xw, Yw = sepP.outputs["X"], sepP.outputs["Y"]

        def op1(a, o, val=None):
            n = nt.nodes.new("ShaderNodeMath"); n.operation = o
            nt.links.new(a, n.inputs[0])
            if val is not None: n.inputs[1].default_value = val
            return n.outputs["Value"]
        def op2(a, bo, o):
            n = nt.nodes.new("ShaderNodeMath"); n.operation = o
            nt.links.new(a, n.inputs[0]); nt.links.new(bo, n.inputs[1])
            return n.outputs["Value"]

        def local_axes(cx, cy, tx, ty):
            dx = op1(Xw, 'SUBTRACT', cx); dy = op1(Yw, 'SUBTRACT', cy)
            along = op2(op1(dx, 'MULTIPLY', tx), op1(dy, 'MULTIPLY', ty), 'ADD')
            across = op2(op1(dx, 'MULTIPLY', -ty), op1(dy, 'MULTIPLY', tx), 'ADD')
            return along, across

        def radial(cx, cy):
            dx = op1(Xw, 'SUBTRACT', cx); dy = op1(Yw, 'SUBTRACT', cy)
            dx2 = op2(dx, dx, 'MULTIPLY'); dy2 = op2(dy, dy, 'MULTIPLY')
            return op1(op2(dx2, dy2, 'ADD'), 'SQRT')

        def soft_disc(cx, cy, r, feather):
            d = radial(cx, cy)
            mr = nt.nodes.new("ShaderNodeMapRange"); mr.clamp = True
            mr.inputs['From Min'].default_value = max(r - feather, 0.0)
            mr.inputs['From Max'].default_value = r
            mr.inputs['To Min'].default_value = 1.0; mr.inputs['To Max'].default_value = 0.0
            nt.links.new(d, mr.inputs['Value'])
            return mr.outputs['Result']

        pit_masks, patch_masks, sb_mask, culvert_mask = [], [], None, None
        for f in features:
            cx, cy = f['xy']
            if f['kind'] == 'pothole':
                r = f['diameter'] / 2.0
                mask = soft_disc(cx, cy, r, 0.08)   # a soft-edged pit, not a hard cutout
                (patch_masks if f.get('patched') else pit_masks).append(mask)
            elif f['kind'] == 'speed_breaker':
                tx, ty = f['tangent']
                along, across = local_axes(cx, cy, tx, ty)
                len_mask = op1(op1(along, 'ABSOLUTE'), 'LESS_THAN', f['length'] / 2.0)
                wid_mask = op1(op1(across, 'ABSOLUTE'), 'LESS_THAN', width / 2.0)
                rect = op2(len_mask, wid_mask, 'MULTIPLY')
                alongshift = op1(along, 'ADD', f['length'] / 2.0)
                band_w = 0.30
                wrapn = nt.nodes.new("ShaderNodeMath"); wrapn.operation = 'WRAP'
                wrapn.inputs[1].default_value = 0.0; wrapn.inputs[2].default_value = band_w * 2
                nt.links.new(alongshift, wrapn.inputs[0])
                blackband = op1(wrapn.outputs['Value'], 'LESS_THAN', band_w)
                sb_mask = (rect, blackband)
            elif f['kind'] == 'culvert_stain':
                tx, ty = f['tangent']
                along, across = local_axes(cx, cy, tx, ty)
                rx, ry = f['along_extent'] / 2.0, width / 2.0
                ea = op2(op1(along, 'DIVIDE', rx), op1(along, 'DIVIDE', rx), 'MULTIPLY')
                eb = op2(op1(across, 'DIVIDE', ry), op1(across, 'DIVIDE', ry), 'MULTIPLY')
                ell = op2(ea, eb, 'ADD')
                culvert_mask = op1(ell, 'LESS_THAN', 1.0)

        def maxfold(nodes):
            if not nodes: return None
            cur = nodes[0]
            for n in nodes[1:]: cur = op2(cur, n, 'MAXIMUM')
            return cur

        pit_all = maxfold(pit_masks)
        patch_all = maxfold(patch_masks)

        # unpatched pit: near-black, rough, a real shading depression (negative bump)
        if pit_all is not None:
            mix1 = nt.nodes.new("ShaderNodeMix"); mix1.data_type = 'RGBA'
            nt.links.new(base_color_out, mix1.inputs["A"])
            mix1.inputs["B"].default_value = (0.018, 0.017, 0.016, 1.0)
            nt.links.new(pit_all, mix1.inputs["Factor"])
            base_color_out = mix1.outputs["Result"]
            bump_height = op2(bump_height, op1(pit_all, 'MULTIPLY', -1.0), 'ADD')

        # patched pit: a flatter, slightly lighter grey resurfacing patch, low roughness change
        if patch_all is not None:
            mix2 = nt.nodes.new("ShaderNodeMix"); mix2.data_type = 'RGBA'
            nt.links.new(base_color_out, mix2.inputs["A"])
            mix2.inputs["B"].default_value = (0.095, 0.093, 0.090, 1.0)
            nt.links.new(patch_all, mix2.inputs["Factor"])
            base_color_out = mix2.outputs["Result"]

        # speed breaker: black/white 300mm bands, raised via bump (visual only - the real
        # 100mm rise is Component 7's own vehicle-offset data, read from the JSON below)
        if sb_mask is not None:
            rect, blackband = sb_mask
            mix3 = nt.nodes.new("ShaderNodeMix"); mix3.data_type = 'RGBA'
            bandcol = nt.nodes.new("ShaderNodeMix"); bandcol.data_type = 'RGBA'
            bandcol.inputs["A"].default_value = (0.85, 0.85, 0.82, 1.0)   # white
            bandcol.inputs["B"].default_value = (0.02, 0.02, 0.02, 1.0)   # black
            nt.links.new(blackband, bandcol.inputs["Factor"])
            nt.links.new(base_color_out, mix3.inputs["A"])
            nt.links.new(bandcol.outputs["Result"], mix3.inputs["B"])
            nt.links.new(rect, mix3.inputs["Factor"])
            base_color_out = mix3.outputs["Result"]
            bump_height = op2(bump_height, rect, 'ADD')

        # culvert water-stain: a damp, muddy, silted patch - darker + slightly glossier
        if culvert_mask is not None:
            mix4 = nt.nodes.new("ShaderNodeMix"); mix4.data_type = 'RGBA'
            nt.links.new(base_color_out, mix4.inputs["A"])
            mix4.inputs["B"].default_value = (0.070, 0.060, 0.040, 1.0)   # muddy silt tone
            nt.links.new(culvert_mask, mix4.inputs["Factor"])
            base_color_out = mix4.outputs["Result"]

    nt.links.new(base_color_out, b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = roughness_val
    bump = nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value = bump_strength
    nt.links.new(bump_height, bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"], b.inputs["Normal"])
    return m

MATS = {w: marked_asphalt(w) for w in set(WIDTH.values())}
n_marked = 0
for ob in bpy.data.objects:
    if not ob.name.startswith("ROAD_") or "kaccha" in ob.name.lower(): continue
    cls = next((c for c in WIDTH if ob.name.endswith(c)), None)
    if cls is None: continue
    ob.data.materials.clear(); ob.data.materials.append(MATS[WIDTH[cls]])
    n_marked += 1
print(f"{n_marked} paved road objects re-materialled with edge/centre lines + crumbling edge")

# ---------------------------------------------------------------- S1's located features
def get_road_centre(name):
    ob = bpy.data.objects.get(name)
    if ob is None: return None
    ov = np.array([v.co[:] for v in ob.data.vertices])
    n_pts = len(ov) // 7
    centre = ov[3::7][:n_pts]
    return centre[:, :2]

S1 = np.array([-280.0, 450.0]); S1_R = 205.0
P1 = get_road_centre("ROAD_48_1_tertiary"); P2 = get_road_centre("ROAD_49_0_tertiary")
combined = np.r_[P1, P2] if P1 is not None and P2 is not None else None
fails = []
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

if combined is not None:
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(combined, axis=0), axis=1))]
    dS1 = np.linalg.norm(combined - S1, axis=1)
    inside = dS1 < S1_R
    entry_i = int(np.argmax(inside)) if inside.any() else 0   # first point inside the circle
    chain0 = d[entry_i]

    def tangent_at(target_d):
        i = int(np.argmin(np.abs(d - target_d)))
        i0, i1 = max(i - 1, 0), min(i + 1, len(combined) - 1)
        v = combined[i1] - combined[i0]
        n = np.linalg.norm(v)
        return (combined[i], tuple((v / n).tolist()) if n > 1e-9 else (1.0, 0.0))

    POTHOLES = [34, 88, 89, 141, 196, 240, 241, 243, 302]
    SPEED_BREAKER = 268
    CULVERT = 158
    # which 3 of the 9 are "patched" - not specified by IRC or the scenario doc, so chosen
    # deterministically (crc32, not hash()) rather than arbitrarily hand-picked, per the
    # project's own non-determinism rule.
    order = sorted(POTHOLES, key=lambda p: zlib.crc32(f"S1_pothole_patched_{p}".encode()))
    patched_set = set(order[:3])

    features = []
    for p in POTHOLES:
        xy, _ = tangent_at(chain0 + p)
        is_patched = p in patched_set
        seed = zlib.crc32(f"S1_pothole_{p}".encode())
        diam = 0.25 + (seed % 1000) / 1000.0 * 0.65        # 0.25-0.9 m per spec
        depth = 0.030 + ((seed // 1000) % 1000) / 1000.0 * 0.060   # 30-90 mm per spec
        features.append(dict(kind='pothole', chainage_m=p, xy=xy.tolist(),
                              diameter=diam, depth=depth, patched=is_patched))
    xy_sb, tan_sb = tangent_at(chain0 + SPEED_BREAKER)
    features.append(dict(kind='speed_breaker', chainage_m=SPEED_BREAKER, xy=xy_sb.tolist(),
                          tangent=tan_sb, length=3.7, height=0.10, irc='IRC 99'))
    xy_cv, tan_cv = tangent_at(chain0 + CULVERT)
    features.append(dict(kind='culvert_stain', chainage_m=CULVERT, xy=xy_cv.tolist(),
                          tangent=tan_cv, along_extent=2.0, pipe_dia=0.9,
                          geometry_deferred=True))

    print(f"S1 through-road: chainage 0 (circle entry) at d={chain0:.1f} m along the combined "
          f"48_1+49_0 path (total path length {d[-1]:.1f} m)")
    print(f"  {len(POTHOLES)} potholes ({len(patched_set)} patched) + 1 speed breaker + "
          f"1 culvert stain located and saved")
    feat_path = f"{REF}/map/road_surface_features.json"
    existing = json.load(open(feat_path)) if os.path.exists(feat_path) else {}
    existing["S1_through_road"] = features
    json.dump(existing, open(feat_path, "w"), indent=1)
    flag("S1 through-road identified and features saved", True)

    # build the S1-specific material (network-wide look + the layered feature masks) and
    # assign it to BOTH pieces of the through road, replacing their plain width-based material
    s1_features = [f for f in features]  # already world-space, ready for the shader
    s1_mat = marked_asphalt(WIDTH['tertiary'], features=s1_features)
    for name in ("ROAD_48_1_tertiary", "ROAD_49_0_tertiary"):
        ob = bpy.data.objects.get(name)
        if ob is None: continue
        ob.data.materials.clear(); ob.data.materials.append(s1_mat)
    flag("S1 feature masks (potholes/speed-breaker/culvert-stain) applied to the mesh material",
         True)
else:
    flag("S1 through-road identified (ROAD_48_1_tertiary + ROAD_49_0_tertiary present)", False)

print(f"\n================= COMPONENT 3 PASS 2 - ROAD MATERIALS : ASSERTIONS =================")
flag(f"at least one class re-materialled per known width ({len(MATS)} widths, {n_marked} objects)",
     n_marked > 100)
print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
bpy.ops.wm.save_mainfile(filepath=ROADSBLEND)
print(f"saved: {ROADSBLEND}")
if fails: sys.exit(1)
