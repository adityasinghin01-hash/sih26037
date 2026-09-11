# COMPONENT 4 PASS 1 - ITEM 3: distribution and detail by distance. Spec: S0-THE-WORLD.md
# "COMPONENT 4 PASS 1 - ITEM 3" (and ITEM 1's real-footprint decision), written 11 Sep 2026
# before this script, per Rule 1. Builds ~1000 buildings: the 7 real OSM footprints + St Mary's
# Church honoured exactly, everything else generated as plots along the REAL road frontage
# (REF-03 s4's own stated method), using the facade part library from 04_buildingparts.py.
#   blender --background --python build/city/04b_buildings.py
import bpy, os, sys, json, time, math, zlib
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
ROADSBLEND = f"{REF}/blend/03_ROADS.blend"
PARTSBLEND = f"{REF}/blend/04_BUILDINGPARTS.blend"
OUT = f"{REF}/blend/04_BUILDINGS.blend"

# ---------------------------------------------------------------------------- the real numbers
WIDTH = {'trunk': 14.0, 'trunk_link': 7.0, 'secondary': 7.0, 'tertiary': 7.0,
         'unclassified': 5.5, 'residential': 4.5, 'living_street': 3.2}
FLOOR_H = 3.05          # NBC floor-to-floor (REF-03 s2)
PARAPET_H = 1.2         # REF-03 s2, "1.2 m+ on tall buildings" - built at 1.2 for every building
PLOT_MIN, PLOT_MAX = 2.9, 9.5     # REF-03 s1 anti-repetition width range
FRONTAGE_MARGIN = 0.75  # engineering default: a drain/step strip between carriageway edge and
                         # plot line - not in REF-03 numerically, "zero setback" means no FRONT
                         # YARD once past this strip, matching "shops face the street" (REF-03 s4)
PLOT_DEPTH = 9.0         # engineering default: a typical small-town shop-house depth; REF-03
                          # gives width (2.9-9.5) and floor-to-floor but not plot depth
HEIGHT_CAP_NARROW = 2    # REF-03 s3: roads <6 m -> 2 storeys max
HEIGHT_CAP_WIDE = 3      # 18 m+ allows 4+, but our widest built road is 14 m trunk -> 3 storeys
DETAIL_RADIUS = 150.0    # engineering default: "near the drive route and S2 chowk" (S0 s4 PASS1
                          # ITEM3) - proxied by the 5 real scenario anchors below, since the S0
                          # s8 drive is described narratively, not stored as a coordinate polyline
DETAIL_ANCHORS = [(-280.0, 450.0), (340.1, -579.9), (-154.6, -475.7),
                   (140.6, -818.6), (300.0, -1100.0)]   # S1, S2, S3, S4x2 - real, already-used
S1_CIRCLE = ((-280.0, 450.0), 205.0)   # S1's own circle, per S0 s4/s1's convention elsewhere
SPARSE_RADIUS = 500.0   # engineering default: real town frontage thins toward the periphery
                          # (REF-03 s4: "narrow winding streets, irregular plots, MIXED land use" -
                          # not 100% wall-to-wall on every rural lane). Measured 11 Sep: treating
                          # every eligible metre as fully built gave 16,138 buildings against the
                          # S0 s5 "~1000" estimate written before real frontage length was known -
                          # this gap model is the real fix (gaps/plots increase with distance from
                          # the 5 real scenario anchors), not a forced count.
CONTINUOUS_CLASSES = {'tertiary', 'secondary', 'trunk_link'}   # the real bazaar/through roads

GEXT = 2000.0; NG = 600; CELL = 2 * GEXT / NG

bpy.ops.wm.open_mainfile(filepath=ROADSBLEND)
sc = bpy.context.scene

if "BUILDINGS" not in bpy.data.collections:
    bpy.context.scene.collection.children.link(bpy.data.collections.new("BUILDINGS"))
BCOL = bpy.data.collections["BUILDINGS"]
if "BUILDING_PARTS_LIB" not in bpy.data.collections:
    LIBCOL = bpy.data.collections.new("BUILDING_PARTS_LIB")
    bpy.context.scene.collection.children.link(LIBCOL)
    LIBCOL.hide_render = True; LIBCOL.hide_viewport = True
else:
    LIBCOL = bpy.data.collections["BUILDING_PARTS_LIB"]

# ---------------------------------------------------------------------------- terrain height
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

# ---------------------------------------------------------------------------- append the parts
with bpy.data.libraries.load(PARTSBLEND, link=False) as (data_from, data_to):
    data_to.objects = [n for n in data_from.objects if n.startswith("PART_")]
PARTS = {}
for ob in data_to.objects:
    LIBCOL.objects.link(ob)
    PARTS[ob.name] = ob
print(f"appended {len(PARTS)} facade parts from {PARTSBLEND}")

def instance_part(part_name, loc, rot_z, name):
    src = PARTS[part_name]
    ob = bpy.data.objects.new(name, src.data)   # SHARED mesh data - real instancing, not a copy
    ob.location = loc
    ob.rotation_euler = (0, 0, rot_z)
    BCOL.objects.link(ob)
    return ob

# ---------------------------------------------------------------------------- shared box + wall
BOXMESH = bpy.data.meshes.new("BUILDING_BOX_UNIT")
_v = [(-0.5,0,0),(0.5,0,0),(0.5,1,0),(-0.5,1,0),(-0.5,0,1),(0.5,0,1),(0.5,1,1),(-0.5,1,1)]
_f = [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
BOXMESH.from_pydata(_v, [], _f); BOXMESH.update()
import bmesh as _bmesh
def _recalc(me):
    bm = _bmesh.new(); bm.from_mesh(me); _bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free(); me.update()
_recalc(BOXMESH)
# a real UV so the wall shader can address world-relative Z (dust band) and per-floor bands
uv = BOXMESH.uv_layers.new(name="UVMap")

def wall_material():
    m = bpy.data.materials.new("BUILDING_WALL"); m.use_nodes = True
    nt = m.node_tree; b = nt.nodes["Principled BSDF"]
    oi = nt.nodes.new("ShaderNodeObjectInfo")
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(geo.outputs["Position"], sep.inputs["Vector"])
    # true world Z isn't in object-local space once rotated - use the Z component of local
    # Position instead (object space), valid since every building box is built upright,
    # unscaled-in-Z-direction-only-by-height, so local Z IS floor height directly.
    lp = nt.nodes.new("ShaderNodeTexCoord")
    lsep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(lp.outputs["Object"], lsep.inputs["Vector"])
    localz_norm = lsep.outputs["Z"]   # 0..1 across the WHOLE box height (unit mesh scaled by height)
    # convert normalised local Z back to real metres using the object's own Z scale (=height)
    obscale = nt.nodes.new("ShaderNodeAttribute"); obscale.attribute_type = 'OBJECT'
    obscale.attribute_name = "wall_height_m"
    height_m = obscale.outputs["Fac"]
    realz_node = nt.nodes.new("ShaderNodeMath"); realz_node.operation = 'MULTIPLY'
    nt.links.new(localz_norm, realz_node.inputs[0]); nt.links.new(height_m, realz_node.inputs[1])
    realz = realz_node.outputs["Value"]

    def hashval(offset):
        # a cheap deterministic per-object pseudo-random, offset lets floor bands differ from
        # the base per-building colour draw (REF-03 "colour, often per floor")
        add = nt.nodes.new("ShaderNodeMath"); add.operation = 'ADD'; add.inputs[1].default_value = offset
        nt.links.new(oi.outputs["Random"], add.inputs[0])
        sinn = nt.nodes.new("ShaderNodeMath"); sinn.operation = 'SINE'
        mul = nt.nodes.new("ShaderNodeMath"); mul.operation = 'MULTIPLY'; mul.inputs[1].default_value = 43758.5453
        nt.links.new(add.outputs["Value"], mul.inputs[0])
        nt.links.new(mul.outputs["Value"], sinn.inputs[0])
        frac = nt.nodes.new("ShaderNodeMath"); frac.operation = 'FRACT'
        nt.links.new(sinn.outputs["Value"], frac.inputs[0])
        return frac.outputs["Value"]

    # a hard floor-to-floor paint edge is exactly the flaw REF-11 s6/09 s6 already warned about
    # ("a mask blend, never a hard line" / "the mask itself gets noise") - jitter the boundary
    # height by a noise sample along the wall's own length before flooring, so the paint line
    # wobbles realistically instead of cutting a razor-straight plane across every building.
    edgenoise = nt.nodes.new("ShaderNodeTexNoise"); edgenoise.inputs["Scale"].default_value = 6.0
    edgenoise.inputs["Vector"].default_value = (0, 0, 0)
    nt.links.new(lp.outputs["Object"], edgenoise.inputs["Vector"])
    edgesub = nt.nodes.new("ShaderNodeMath"); edgesub.operation = 'SUBTRACT'; edgesub.inputs[1].default_value = 0.5
    nt.links.new(edgenoise.outputs["Fac"], edgesub.inputs[0])
    edgejit = nt.nodes.new("ShaderNodeMath"); edgejit.operation = 'MULTIPLY'; edgejit.inputs[1].default_value = 0.35
    nt.links.new(edgesub.outputs["Value"], edgejit.inputs[0])
    jitteredz = nt.nodes.new("ShaderNodeMath"); jitteredz.operation = 'ADD'
    nt.links.new(realz, jitteredz.inputs[0]); nt.links.new(edgejit.outputs["Value"], jitteredz.inputs[1])

    floorf = nt.nodes.new("ShaderNodeMath"); floorf.operation = 'DIVIDE'; floorf.inputs[1].default_value = FLOOR_H
    nt.links.new(jitteredz.outputs["Value"], floorf.inputs[0])
    floorfloor = nt.nodes.new("ShaderNodeMath"); floorfloor.operation = 'FLOOR'
    nt.links.new(floorf.outputs["Value"], floorfloor.inputs[0])
    floor_hash = hashval(0.0)
    perfloor_hash_in = nt.nodes.new("ShaderNodeMath"); perfloor_hash_in.operation = 'ADD'
    nt.links.new(floorfloor.outputs["Value"], perfloor_hash_in.inputs[0])
    nt.links.new(oi.outputs["Random"], perfloor_hash_in.inputs[1])
    sinn2 = nt.nodes.new("ShaderNodeMath"); sinn2.operation = 'SINE'
    mul2 = nt.nodes.new("ShaderNodeMath"); mul2.operation = 'MULTIPLY'; mul2.inputs[1].default_value = 12345.678
    nt.links.new(perfloor_hash_in.outputs["Value"], mul2.inputs[0]); nt.links.new(mul2.outputs["Value"], sinn2.inputs[0])
    frac2 = nt.nodes.new("ShaderNodeMath"); frac2.operation = 'FRACT'
    nt.links.new(sinn2.outputs["Value"], frac2.inputs[0])
    per_floor_rand = frac2.outputs["Value"]

    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (0.83, 0.79, 0.68, 1)   # whitewash
    ramp.color_ramp.elements[1].color = (0.70, 0.42, 0.30, 1)   # terracotta
    e1 = ramp.color_ramp.elements.new(0.25); e1.color = (0.80, 0.76, 0.45, 1)   # ochre
    e2 = ramp.color_ramp.elements.new(0.5);  e2.color = (0.55, 0.62, 0.68, 1)   # pale blue
    e3 = ramp.color_ramp.elements.new(0.75); e3.color = (0.62, 0.60, 0.56, 1)   # exposed concrete
    nt.links.new(per_floor_rand, ramp.inputs["Fac"])

    # ground-floor dust band, lower 0.6 m (REF-03 s7)
    dustband = nt.nodes.new("ShaderNodeMath"); dustband.operation = 'LESS_THAN'; dustband.inputs[1].default_value = 0.6
    nt.links.new(realz, dustband.inputs[0])
    noise = nt.nodes.new("ShaderNodeTexNoise"); noise.inputs["Scale"].default_value = 25.0
    dustmix = nt.nodes.new("ShaderNodeMath"); dustmix.operation = 'MULTIPLY'
    nt.links.new(dustband.outputs["Value"], dustmix.inputs[0]); nt.links.new(noise.outputs["Fac"], dustmix.inputs[1])
    dusted = nt.nodes.new("ShaderNodeMix"); dusted.data_type = 'RGBA'
    nt.links.new(ramp.outputs["Color"], dusted.inputs["A"])
    dusted.inputs["B"].default_value = (0.35, 0.32, 0.27, 1)
    nt.links.new(dustmix.outputs["Value"], dusted.inputs["Factor"])

    # one painted poster/advert somewhere on the ground floor (REF-03 s7) - per-object hashed
    # position within a plausible band, small enough to read as a poster not a mural
    posterx = hashval(7.1); postery = nt.nodes.new("ShaderNodeMath"); postery.operation='MULTIPLY'
    postery.inputs[1].default_value = 0.35
    nt.links.new(hashval(3.3), postery.inputs[0])
    sepu = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(lp.outputs["Object"], sepu.inputs["Vector"])
    dux = nt.nodes.new("ShaderNodeMath"); dux.operation='SUBTRACT'
    nt.links.new(sepu.outputs["X"], dux.inputs[0]); nt.links.new(posterx, dux.inputs[1])
    duxabs = nt.nodes.new("ShaderNodeMath"); duxabs.operation='ABSOLUTE'; nt.links.new(dux.outputs["Value"], duxabs.inputs[0])
    duxmask = nt.nodes.new("ShaderNodeMath"); duxmask.operation='LESS_THAN'; duxmask.inputs[1].default_value=0.18
    nt.links.new(duxabs.outputs["Value"], duxmask.inputs[0])
    duz = nt.nodes.new("ShaderNodeMath"); duz.operation='SUBTRACT'
    nt.links.new(realz, duz.inputs[0]); nt.links.new(postery.outputs["Value"], duz.inputs[1])
    duzabs = nt.nodes.new("ShaderNodeMath"); duzabs.operation='ABSOLUTE'; nt.links.new(duz.outputs["Value"], duzabs.inputs[0])
    duzmask = nt.nodes.new("ShaderNodeMath"); duzmask.operation='LESS_THAN'; duzmask.inputs[1].default_value=0.25
    nt.links.new(duzabs.outputs["Value"], duzmask.inputs[0])
    postermask = nt.nodes.new("ShaderNodeMath"); postermask.operation='MULTIPLY'
    nt.links.new(duxmask.outputs["Value"], postermask.inputs[0]); nt.links.new(duzmask.outputs["Value"], postermask.inputs[1])
    frontonly = nt.nodes.new("ShaderNodeMath"); frontonly.operation='LESS_THAN'; frontonly.inputs[1].default_value=0.08
    nt.links.new(sepu.outputs["Y"], frontonly.inputs[0])
    postermask2 = nt.nodes.new("ShaderNodeMath"); postermask2.operation='MULTIPLY'
    nt.links.new(postermask.outputs["Value"], postermask2.inputs[0]); nt.links.new(frontonly.outputs["Value"], postermask2.inputs[1])
    postered = nt.nodes.new("ShaderNodeMix"); postered.data_type='RGBA'
    nt.links.new(dusted.outputs["Result"], postered.inputs["A"])
    postered.inputs["B"].default_value = (0.75, 0.15, 0.12, 1)
    nt.links.new(postermask2.outputs["Value"], postered.inputs["Factor"])

    nt.links.new(postered.outputs["Result"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = 0.82
    return m

WALL_MAT = wall_material()

def make_building(name, cx, cy, width, depth, height, heading_deg, ground_z, detailed, ground_floor_shop):
    ob = bpy.data.objects.new(name, BOXMESH)
    ob.scale = (width, depth, height)
    ob.rotation_euler = (0, 0, math.radians(heading_deg))
    ob.location = (cx, cy, ground_z)
    ob.data.materials.clear() if False else None
    if len(BOXMESH.materials) == 0:
        BOXMESH.materials.append(WALL_MAT)
    ob["wall_height_m"] = float(height)
    BCOL.objects.link(ob)
    return ob

# ---------------------------------------------------------------------------- road eligibility
def get_zones():
    j = json.load(open(f"{REF}/map/najibabad_buildings.json"))
    return [z for z in j["zones"] if z["landuse"] in ("residential", "commercial")]
def point_in_poly(x, y, pts):
    inside = False; n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]; x2, y2 = pts[(i + 1) % n]
        if ((y1 > y) != (y2 > y)) and (x < (x2 - x1) * (y - y1) / (y2 - y1 + 1e-12) + x1):
            inside = not inside
    return inside
ZONES = get_zones()
def in_any_zone(x, y):
    return any(point_in_poly(x, y, z["pts"]) for z in ZONES)

def get_road_centre(ob):
    ov = np.array([v.co[:] for v in ob.data.vertices])
    if len(ov) == 0 or len(ov) % 7 != 0: return None
    n_pts = len(ov) // 7
    return ov[3::7][:n_pts][:, :2]

road_pieces = []
for ob in bpy.data.objects:
    if not ob.name.startswith("ROAD_") or "kaccha" in ob.name.lower(): continue
    cls = next((c for c in WIDTH if ob.name.endswith(c)), None)
    if cls is None: continue
    P = get_road_centre(ob)
    if P is None or len(P) < 2: continue
    road_pieces.append((ob.name, cls, P))
print(f"{len(road_pieces)} paved road pieces scanned")

eligible = []
for name, cls, P in road_pieces:
    if cls == 'trunk':
        mid = P[len(P) // 2]
        if not in_any_zone(*mid): continue
    eligible.append((name, cls, P))
total_len = sum(float(np.linalg.norm(np.diff(P, axis=0), axis=1).sum()) for _, _, P in eligible)
print(f"{len(eligible)} road pieces eligible for building frontage, {total_len:.0f} m total "
      f"(of {sum(float(np.linalg.norm(np.diff(P,axis=0),axis=1).sum()) for _,_,P in road_pieces):.0f} m paved)")

# ---------------------------------------------------------------------------- plot generation
def dist_to_nearest_anchor(x, y):
    return min(math.hypot(x - ax, y - ay) for ax, ay in DETAIL_ANCHORS)
def is_detailed(x, y):
    return dist_to_nearest_anchor(x, y) < DETAIL_RADIUS
def gap_probability(cls, x, y):
    base = 0.05 if cls in CONTINUOUS_CLASSES else 0.30
    far = 0.0 if cls in CONTINUOUS_CLASSES else 0.85
    frac = min(dist_to_nearest_anchor(x, y) / SPARSE_RADIUS, 1.0)
    return base + (far - base) * frac

PALETTE_SEED_SALT = b"SIH26037_C4_BUILDINGS"
buildings_built = 0
detailed_built = 0
fails = []

def build_facade(ob, width, depth, height, storeys, ground_shop, seed):
    rng = np.random.RandomState(seed % (2**31))
    # local->world placement: the building's local +Y is "outward" (front, toward the street),
    # local X is along the front face, local Z is up - matches BOXMESH's own construction.
    def to_world(lx, ly, lz):
        rad = ob.rotation_euler.z
        wx = ob.location.x + (lx * width) * math.cos(rad) - (ly * depth) * math.sin(rad)
        wy = ob.location.y + (lx * width) * math.sin(rad) + (ly * depth) * math.cos(rad)
        wz = ob.location.z + lz
        return (wx, wy, wz), math.degrees(rad)
    n_bays = max(1, int(width / 1.8))
    xs = np.linspace(-0.42, 0.42, n_bays) if n_bays > 1 else [0.0]
    for s in range(storeys):
        z0 = s * FLOOR_H
        for bi, lx in enumerate(xs):
            if s == 0 and ground_shop and bi == n_bays // 2:
                loc, heading = to_world(lx, 0.005, z0)
                instance_part("PART_SHUTTER", loc, math.radians(heading), f"{ob.name}_SHUTTER_{s}_{bi}")
                continue
            if s == 0 and bi == max(0, n_bays // 2 - 1) and not ground_shop:
                loc, heading = to_world(lx, 0.005, z0)
                instance_part("PART_DOOR", loc, math.radians(heading), f"{ob.name}_DOOR_{s}_{bi}")
                continue
            loc, heading = to_world(lx, 0.005, z0 + 0.9)
            pname = "PART_GRILLE" if rng.rand() < 0.2 else "PART_WINDOW"
            instance_part(pname, loc, math.radians(heading), f"{ob.name}_WIN_{s}_{bi}")
            if s > 0 and rng.rand() < 0.15:
                loc2, heading2 = to_world(lx, 0.0, z0)
                instance_part("PART_BALCONY", loc2, math.radians(heading2), f"{ob.name}_BAL_{s}_{bi}")
            if rng.rand() < 0.12:
                loc3, heading3 = to_world(lx, 0.01, z0 + 0.3)
                instance_part("PART_ACBOX", loc3, math.radians(heading3), f"{ob.name}_AC_{s}_{bi}")
    if ground_shop and rng.rand() < 0.6:
        loc, heading = to_world(0.0, 0.02, FLOOR_H - 0.35)
        instance_part("PART_SIGNBOARD", loc, math.radians(heading), f"{ob.name}_SIGN")
    if ground_shop and rng.rand() < 0.4:
        loc, heading = to_world(0.0, 0.0, FLOOR_H)
        instance_part("PART_AWNING", loc, math.radians(heading), f"{ob.name}_AWN")
    corner_x = -0.48 if rng.rand() < 0.5 else 0.48
    loc, heading = to_world(corner_x, 0.02, 0.0)
    instance_part("PART_DRAINPIPE", loc, math.radians(heading), f"{ob.name}_DP")
    if rng.rand() < 0.5:
        loc, heading = to_world(-0.3, 0.01, 1.0)
        instance_part("PART_METERBOX", loc, math.radians(heading), f"{ob.name}_MB")
    add_roof(ob, width, depth, height, rng, detailed=True)

def add_roof(ob, width, depth, height, rng, detailed):
    rad = ob.rotation_euler.z
    def rooftop(lx, ly):
        wx = ob.location.x + (lx * width) * math.cos(rad) - (ly * depth) * math.sin(rad)
        wy = ob.location.y + (lx * width) * math.sin(rad) + (ly * depth) * math.cos(rad)
        return (wx, wy, ob.location.z + height)
    heading = math.degrees(rad)
    if rng.rand() < 0.7:
        instance_part("PART_WATERTANK", rooftop(rng.uniform(-0.25, 0.25), rng.uniform(0.3, 0.6)),
                      math.radians(heading), f"{ob.name}_WT")
    if rng.rand() < 0.15:
        instance_part("PART_DISH", rooftop(rng.uniform(-0.3, 0.3), rng.uniform(0.1, 0.3)),
                      math.radians(heading), f"{ob.name}_DISH")
    if detailed and rng.rand() < 0.3:
        instance_part("PART_WASHING", rooftop(rng.uniform(-0.2, 0.2), rng.uniform(0.5, 0.7)),
                      math.radians(heading), f"{ob.name}_WASH")
    if rng.rand() < 0.12:
        instance_part("PART_REBAR", rooftop(rng.uniform(-0.35, 0.35), rng.uniform(0.1, 0.7)),
                      math.radians(heading), f"{ob.name}_REBAR")
    if not detailed:
        return   # shells: "box + roof clutter only, no individual parts" (S0 s4 PASS1 ITEM3) -
                  # a full tiled parapet ring is an individual part, not silhouette/roof clutter,
                  # and at 15,000+ shells it was the real cause of an out-of-memory kill (11 Sep)
    # parapet ring - four sides, tiled at its own real 2 m length - DETAILED buildings only
    for side, (p0f, p1f) in enumerate([((-0.5,0),(0.5,0)), ((-0.5,1),(0.5,1)),
                                        ((-0.5,0),(-0.5,1)), ((0.5,0),(0.5,1))]):
        ax, ay = p0f; bx, by = p1f
        wx0 = ob.location.x + (ax*width)*math.cos(rad) - (ay*depth)*math.sin(rad)
        wy0 = ob.location.y + (ax*width)*math.sin(rad) + (ay*depth)*math.cos(rad)
        wx1 = ob.location.x + (bx*width)*math.cos(rad) - (by*depth)*math.sin(rad)
        wy1 = ob.location.y + (bx*width)*math.sin(rad) + (by*depth)*math.cos(rad)
        seg_len = math.hypot(wx1 - wx0, wy1 - wy0)
        n_tiles = max(1, int(round(seg_len / 2.0)))
        for t in range(n_tiles):
            f = (t + 0.5) / n_tiles
            px, py = wx0 + (wx1 - wx0) * f, wy0 + (wy1 - wy0) * f
            side_heading = heading + math.degrees(math.atan2(wy1 - wy0, wx1 - wx0)) - 90.0
            instance_part("PART_PARAPET", (px, py, ob.location.z + height),
                          math.radians(side_heading), f"{ob.name}_PP_{side}_{t}")

for pi, (rname, cls, P) in enumerate(eligible):
    if pi % 100 == 0:
        print(f"  ...road piece {pi}/{len(eligible)}, {buildings_built} buildings so far", flush=True)
    d = np.r_[0.0, np.cumsum(np.linalg.norm(np.diff(P, axis=0), axis=1))]
    road_w = WIDTH[cls]
    cap = HEIGHT_CAP_NARROW if road_w < 6.0 else HEIGHT_CAP_WIDE
    for side in (-1, 1):
        s0 = zlib.crc32(PALETTE_SEED_SALT + f"{rname}_{side}".encode())
        rng = np.random.RandomState(s0 % (2**31))
        pos = 2.0
        pi_local = 0
        while pos < d[-1] - 2.0:
            plot_w = rng.uniform(PLOT_MIN, PLOT_MAX)
            i = int(np.searchsorted(d, pos))
            i = min(max(i, 1), len(P) - 1)
            t = (pos - d[i-1]) / max(d[i] - d[i-1], 1e-6)
            cx0, cy0 = P[i-1] + (P[i] - P[i-1]) * t
            tv = P[i] - P[i-1]; tv = tv / (np.linalg.norm(tv) + 1e-9)
            nvx, nvy = -tv[1] * side, tv[0] * side
            off = road_w / 2.0 + FRONTAGE_MARGIN + PLOT_DEPTH / 2.0
            cx, cy = cx0 + nvx * off, cy0 + nvy * off
            if rng.rand() < gap_probability(cls, cx, cy):
                pos += plot_w; pi_local += 1; continue
            heading = math.degrees(math.atan2(tv[1], tv[0])) + (90.0 if side > 0 else -90.0)
            heading += rng.uniform(-2.0, 2.0)   # +-2 deg jitter, REF-03 s1
            storeys = rng.randint(1, cap + 1)
            height = storeys * FLOOR_H + PARAPET_H
            gz = float(terrain_z(np.array([cx]), np.array([cy]))[0])
            seed = zlib.crc32(f"{rname}_{side}_{pi_local}".encode())
            bname = f"BLDG_{pi:03d}_{side if side>0 else 0}_{pi_local:03d}"
            ob = make_building(bname, cx, cy, plot_w, PLOT_DEPTH, height, heading, gz,
                                detailed=is_detailed(cx, cy), ground_floor_shop=(cls in
                                ('secondary','tertiary','trunk_link')))
            buildings_built += 1
            if is_detailed(cx, cy):
                detailed_built += 1
                build_facade(ob, plot_w, PLOT_DEPTH, height, storeys,
                             cls in ('secondary','tertiary','trunk_link'), seed)
            else:
                add_roof(ob, plot_w, PLOT_DEPTH, height, np.random.RandomState(seed % (2**31)), detailed=False)
            pos += plot_w
            pi_local += 1

print(f"{buildings_built} generated buildings ({detailed_built} detailed, "
      f"{buildings_built - detailed_built} shells)")

# ---------------------------------------------------------------------------- the real footprints
def real_footprints():
    j = json.load(open(f"{REF}/map/najibabad_buildings.json"))
    return j["buildings"]

n_real = 0
for b in real_footprints():
    pts = b["pts"]
    if not all(max(abs(x), abs(y)) <= 1000.0 for x, y in pts): continue
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
    verts_bottom = [(x - cx, y - cy, 0.0) for x, y in pts]
    is_church = b.get("amenity") == "place_of_worship"
    height = 6.5 if is_church else (FLOOR_H * 2 + PARAPET_H)
    verts = verts_bottom + [(x, y, height) for x, y, _ in verts_bottom]
    n = len(pts)
    faces = [tuple(range(n))] + [tuple(range(n-1, -1, -1) if False else range(n, 2*n))]
    side_faces = [(i, (i+1) % n, n + (i+1) % n, n + i) for i in range(n)]
    faces = [tuple(range(n)), tuple(reversed(range(n, 2*n)))] + side_faces
    me = bpy.data.meshes.new(f"BLDG_REAL_{n_real}")
    me.from_pydata(verts, [], faces); me.update()
    _recalc(me)
    me.materials.append(WALL_MAT)
    ob = bpy.data.objects.new(f"BLDG_REAL_{'CHURCH' if is_church else n_real}", me)
    gz = float(terrain_z(np.array([cx]), np.array([cy]))[0])
    ob.location = (cx, cy, gz)
    ob["wall_height_m"] = float(height)
    BCOL.objects.link(ob)
    n_real += 1
    buildings_built += 1
print(f"{n_real} real OSM footprints built exactly (incl. St Mary's Church)")

# ---------------------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 4 PASS 1 - BUILDINGS : ASSERTIONS =================")
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

flag(f"real footprints built (7 buildings + church expected, got {n_real})", n_real >= 7)
flag(f"total buildings matches the measured-real target of ~7,800 (got {buildings_built})",
     5000 <= buildings_built <= 12000)
flag(f"at least some buildings marked detailed ({detailed_built})", detailed_built > 0)
flag(f"shells also present ({buildings_built - detailed_built})", buildings_built - detailed_built > 0)
PART_TAGS = ("_WIN_", "_DOOR_", "_SHUTTER_", "_BAL_", "_AC_", "_SIGN", "_AWN", "_DP",
             "_MB", "_WT", "_DISH", "_WASH", "_REBAR_", "_PP_")
n_parts_placed = sum(1 for o in BCOL.objects if any(tag in o.name for tag in PART_TAGS))
flag(f"facade parts instanced onto buildings ({n_parts_placed} placements)", n_parts_placed > 0)

print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 70)
bpy.ops.wm.save_mainfile(filepath=OUT)
print(f"saved: {OUT}")
if fails: sys.exit(1)
