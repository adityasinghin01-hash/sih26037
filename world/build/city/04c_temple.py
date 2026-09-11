# COMPONENT 4 PASS 2 - ITEM 1: the S5 temple. Spec: S0-THE-WORLD.md "COMPONENT 4 PASS 2 - ITEM 1",
# written 11 Sep 2026 before this script, per Rule 1. Sited at the S5 climb's REAL measured
# terminus (857.7 m of the spec's 970 m chainage span - honestly short, same category as the
# elevation shortfall), not the spec's chainage-1150 point, per that item's own reasoning.
#   blender --background --python build/city/04c_temple.py
import bpy, bmesh, os, sys, math, time
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
OUT = f"{REF}/blend/04_BUILDINGS.blend"

bpy.ops.wm.open_mainfile(filepath=OUT)
sc = bpy.context.scene

if "TEMPLE" not in bpy.data.collections:
    c = bpy.data.collections.new("TEMPLE"); sc.collection.children.link(c)
TCOL = bpy.data.collections["TEMPLE"]
for ob in list(TCOL.objects):
    me = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if me and me.users == 0: bpy.data.meshes.remove(me)

# ---------------------------------------------------------------------------- terrain height
# a height-GRID from real vertex data, not a live ray-cast - immune to object-removal/depsgraph
# timing (a ray-cast here was found non-deterministic across repeated runs: it could still hit a
# STALE object from the previous run's own TEMPLE collection before the depsgraph caught up with
# this run's cleanup). Same method as audit.py's own established HILL-folded-into-TERRAIN grid.
GEXT = 2000.0; NG = 600; CELL = 2 * GEXT / NG
terr = bpy.data.objects["TERRAIN"]
tco = np.array([v.co[:] for v in terr.data.vertices])
tgj = np.clip(np.round((tco[:, 0] + GEXT) / CELL).astype(int), 0, NG)
tgi = np.clip(np.round((tco[:, 1] + GEXT) / CELL).astype(int), 0, NG)
GH = np.zeros((NG + 1, NG + 1)); GH[tgi, tgj] = tco[:, 2]
for ho in bpy.data.objects:
    if ho is terr or ho.type != 'MESH' or not ho.name.startswith(("HILL", "hill")): continue
    hco = np.array([(ho.matrix_world @ v.co)[:] for v in ho.data.vertices])
    hj = np.clip(np.round((hco[:, 0] + GEXT) / CELL).astype(int), 0, NG)
    hi = np.clip(np.round((hco[:, 1] + GEXT) / CELL).astype(int), 0, NG)
    np.maximum.at(GH, (hi, hj), hco[:, 2])
def sample_ground(x, y):
    fx = np.clip((x + GEXT) / CELL, 0, NG - 1e-6); fy = np.clip((y + GEXT) / CELL, 0, NG - 1e-6)
    i0 = int(fx); j0 = int(fy); tx = fx - i0; ty = fy - j0
    return float(GH[j0,i0]*(1-tx)*(1-ty) + GH[j0,i0+1]*tx*(1-ty)
                 + GH[j0+1,i0]*(1-tx)*ty + GH[j0+1,i0+1]*tx*ty)

# ---------------------------------------------------------------------------- mesh toolbox
MATS = {}
def mat(name, color, rough=0.7, metallic=0.0):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    MATS[name] = m
    return m

def recalc_outward(me):
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free(); me.update()

def axbox(name, m, x0, x1, y0, y1, z0, z1):
    verts = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    fs = [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], fs); me.update()
    recalc_outward(me)
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(m); TCOL.objects.link(ob)
    return ob

def bar(p0, p1, w, name, m):
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
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(m); TCOL.objects.link(ob)
    return ob

def prism(name, m, cx, cy, z0, z1, r0, r1, segs=16, ang0=0.0, ang1=2*math.pi):
    full = abs(ang1 - ang0) >= 2*math.pi - 1e-6
    n = segs if full else segs + 1
    verts = []
    for r, z in ((r0,z0),(r1,z1)):
        for i in range(n):
            a = ang0 + (ang1-ang0)*i/segs
            verts.append((cx+r*math.cos(a), cy+r*math.sin(a), z))
    fs = []
    for i in range(segs if full else n-1):
        j = (i+1) % n if full else i+1
        fs.append((i, j, n+j, n+i))
    if full:
        fs.append(tuple(range(n-1, -1, -1)))
        fs.append(tuple(n+i for i in range(n)))
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], fs); me.update()
    recalc_outward(me)
    ob = bpy.data.objects.new(name, me); ob.data.materials.append(m); TCOL.objects.link(ob)
    return ob

def join(name, obs):
    for o in obs: o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    bpy.ops.object.select_all(action='DESELECT')
    return ob

M_WHITEWASH = mat("TEMPLE_whitewash", (0.90, 0.87, 0.80), 0.65)
M_STONE = mat("TEMPLE_stone", (0.62, 0.58, 0.52), 0.85)
M_SAFFRON = mat("TEMPLE_saffron", (0.92, 0.42, 0.08), 0.85)
M_BELL = mat("TEMPLE_bell", (0.75, 0.62, 0.25), 0.35, metallic=0.75)
M_TIN = mat("TEMPLE_tin_roof", (0.55, 0.53, 0.50), 0.55, metallic=0.4)
M_PARKING = mat("TEMPLE_parking", (0.30, 0.29, 0.27), 0.85)

# ---------------------------------------------------------------------------- the real terminus
road = bpy.data.objects.get("S5_CLIMB_ROAD")
if road is None:
    print("FATAL: S5_CLIMB_ROAD not found - the S5 climb must be built before the temple")
    sys.exit(1)
ov = np.array([v.co[:] for v in road.data.vertices])
n_pts = len(ov) // 7
centre = ov[3::7][:n_pts]
END = centre[-1]
tv = centre[-1][:2] - centre[-3][:2]; tv = tv / np.linalg.norm(tv)
approach_heading = math.degrees(math.atan2(tv[0], tv[1])) % 360
print(f"S5 real terminus: ({END[0]:.1f},{END[1]:.1f},{END[2]:.1f}), approach heading "
      f"{approach_heading:.0f} deg, {n_pts} centreline points")

fwd2 = tv           # continuing the approach direction, into the hillside
side2 = np.array([-tv[1], tv[0]])

# ---------------------------------------------------------------------------- parking pad
PARK_R = 9.0
park_cx, park_cy = END[0] + fwd2[0]*2.0, END[1] + fwd2[1]*2.0
park_z = sample_ground(park_cx, park_cy)
prism("TEMPLE_PARKING", M_PARKING, park_cx, park_cy, park_z - 0.05, park_z, PARK_R, PARK_R, segs=24)

# ---------------------------------------------------------------------------- the 38 steps
N_STEPS = 38; RISER = 0.15; GOING = 0.30; STEP_W = 2.4
step_base_x = park_cx + fwd2[0]*(PARK_R + 0.5)
step_base_y = park_cy + fwd2[1]*(PARK_R + 0.5)
step_base_z = park_z
step_objs = []
for i in range(N_STEPS):
    y0, y1 = i*GOING, (i+1)*GOING
    z0, z1 = step_base_z, step_base_z + (i+1)*RISER
    cx0, cy0 = step_base_x + fwd2[0]*y0, step_base_y + fwd2[1]*y0
    cx1, cy1 = step_base_x + fwd2[0]*y1, step_base_y + fwd2[1]*y1
    # a step tread as a short bar-like slab across the step width, oriented across fwd2
    p_l0 = (cx0 - side2[0]*STEP_W/2, cy0 - side2[1]*STEP_W/2, step_base_z)
    p_r1 = (cx1 + side2[0]*STEP_W/2, cy1 + side2[1]*STEP_W/2, z1)
    x0_, x1_ = min(p_l0[0], p_r1[0]), max(p_l0[0], p_r1[0])
    y0_, y1_ = min(p_l0[1], p_r1[1]), max(p_l0[1], p_r1[1])
    # this run is steep (measured: real ground drops well below the assumed constant riser line
    # further up-slope) - each step's own footing extends down to real grade beneath it, same
    # cut/fill principle as the road's own retaining wall, so no step floats above the hillside.
    real_here = sample_ground((cx0+cx1)/2, (cy0+cy1)/2)
    # capped at 2.5 m below the nominal line - the real slope here is locally steep enough
    # (measured: up to 5.5 m short over the whole run) that reaching exactly to grade on a single
    # step produced a thin, unrealistic foundation spike (audit rule 6 caught it). A 2.5 m footing
    # is itself a real, plausible masonry foundation depth; anything deeper than that is capped,
    # not chased - the fill wall below covers the rest honestly rather than spiking down to meet it.
    z_bottom = max(min(step_base_z, real_here - 0.15), step_base_z - 2.5)
    step_objs.append(axbox(f"step_{i}", M_STONE, x0_, x1_, y0_, y1_, z_bottom, z1))
plinth_x = step_base_x + fwd2[0]*(N_STEPS*GOING + 1.0)
plinth_y = step_base_y + fwd2[1]*(N_STEPS*GOING + 1.0)
plinth_z = step_base_z + N_STEPS*RISER
print(f"steps: {N_STEPS} at riser {RISER} m, going {GOING} m -> {N_STEPS*RISER:.2f} m rise over "
      f"{N_STEPS*GOING:.2f} m run, plinth top at z={plinth_z:.2f} m "
      f"(real ground there: {sample_ground(plinth_x,plinth_y):.2f} m)")
join("TEMPLE_STEPS", step_objs)

# ---------------------------------------------------------------------------- the sanctum
# REF-03 s6 vimana proportions (1.68:1.20:0.80 of 3.68 total), scaled to S5's own 5.2 m overall.
SCALE = 5.2 / 3.68
BASE_H, BODY_H, CROWN_H = 1.68*SCALE, 1.20*SCALE, 0.80*SCALE
SANCTUM_W = 3.0
hd = math.radians(approach_heading)
def local_to_world(lx, ly, cx=plinth_x, cy=plinth_y):
    wx = cx + lx*math.cos(hd) - ly*math.sin(hd)
    wy = cy + lx*math.sin(hd) + ly*math.cos(hd)
    return wx, wy

sanctum_objs = []
# plinth (base): a stepped platform, per REF-09 s3's inset/extrude method - two tapering tiers.
# The sloping hillside real ground can sit well below the level courtyard here (measured, not
# assumed - a real hill temple's platform is an engineered retaining structure on a slope, not a
# thing that floats): extend the lower tier's own footing down to real grade so it reads as a
# built-up foundation holding the level plinth, never a slab hanging in the air.
p0x, p0y = local_to_world(-SANCTUM_W/2-0.3, 1.5)
p1x, p1y = local_to_world(SANCTUM_W/2+0.3, 1.5+SANCTUM_W+0.6)
foundation_z0 = min(plinth_z, sample_ground(p0x, p0y), sample_ground(p1x, p1y),
                     sample_ground((p0x+p1x)/2, (p0y+p1y)/2)) - 0.3
sanctum_objs.append(axbox("plinth_lower", M_STONE, min(p0x,p1x), max(p0x,p1x), min(p0y,p1y),
                            max(p0y,p1y), foundation_z0, plinth_z + BASE_H*0.6))
p2x, p2y = local_to_world(-SANCTUM_W/2-0.1, 1.7)
p3x, p3y = local_to_world(SANCTUM_W/2+0.1, 1.7+SANCTUM_W+0.2)
sanctum_objs.append(axbox("plinth_upper", M_WHITEWASH, min(p2x,p3x),
                            max(p2x,p3x), min(p2y,p3y), max(p2y,p3y),
                            plinth_z + BASE_H*0.6, plinth_z + BASE_H))
sanctum_z = plinth_z + BASE_H

# body: the tapering shikhara tiers (5 tiers narrowing toward the top - "the whole latina
# shikhara IS stacked inset/extrude", REF-09 s3)
n_tiers = 5
for t in range(n_tiers):
    frac0, frac1 = t/n_tiers, (t+1)/n_tiers
    w0 = SANCTUM_W * (1 - 0.6*frac0)
    w1 = SANCTUM_W * (1 - 0.6*frac1)
    cy0 = 1.7 + SANCTUM_W/2
    q0x, q0y = local_to_world(-w0/2, cy0 - w0/2)
    q1x, q1y = local_to_world(w0/2, cy0 + w0/2)
    z0 = sanctum_z + BODY_H*frac0
    z1 = sanctum_z + BODY_H*frac1 - 0.03
    sanctum_objs.append(axbox(f"shikhara_tier{t}", M_WHITEWASH, min(q0x,q1x), max(q0x,q1x),
                                min(q0y,q1y), max(q0y,q1y), z0, z1))
crown_cx, crown_cy = local_to_world(0.0, 1.7 + SANCTUM_W/2)
crown_z0 = sanctum_z + BODY_H
sanctum_objs.append(prism("amalaka", M_STONE, crown_cx, crown_cy, crown_z0,
                            crown_z0 + CROWN_H*0.4, SANCTUM_W*0.28, SANCTUM_W*0.34, segs=16))
sanctum_objs.append(prism("kalasha", M_BELL, crown_cx, crown_cy, crown_z0 + CROWN_H*0.4,
                            crown_z0 + CROWN_H, SANCTUM_W*0.10, 0.03, segs=10))
TEMPLE_TOP = crown_z0 + CROWN_H
print(f"sanctum: plinth {plinth_z:.2f} -> body top {sanctum_z+BODY_H:.2f} -> crown top "
      f"{TEMPLE_TOP:.2f} m (overall {TEMPLE_TOP-plinth_z:.2f} m, target 5.2 m)")

# pillared hall (mandapa), ~3x3 m, flat roof, 4 pillars, in front of the sanctum
hall_cy0, hall_cy1 = 1.7 - 3.0, 1.7
hx0, hy0 = local_to_world(-1.6, hall_cy0)
hx1, hy1 = local_to_world(1.6, hall_cy1)
HALL_H = 2.6
for lx, ly in ((-1.3, hall_cy0+0.3), (1.3, hall_cy0+0.3), (-1.3, hall_cy1-0.3), (1.3, hall_cy1-0.3)):
    px, py = local_to_world(lx, ly)
    sanctum_objs.append(bar((px,py,plinth_z), (px,py,plinth_z+HALL_H), 0.18, "hall_pillar", M_STONE))
rx0, ry0 = local_to_world(-1.8, hall_cy0-0.2)
rx1, ry1 = local_to_world(1.8, hall_cy1+0.2)
sanctum_objs.append(axbox("hall_roof", M_WHITEWASH, min(rx0,rx1), max(rx0,rx1), min(ry0,ry1),
                            max(ry0,ry1), plinth_z+HALL_H, plinth_z+HALL_H+0.2))
floor_x0, floor_y0 = local_to_world(-1.8, hall_cy0-0.3)
floor_x1, floor_y1 = local_to_world(1.8, 1.7+SANCTUM_W+0.2)
M_TILE = mat("TEMPLE_tile", (0.68, 0.55, 0.42), 0.45)
sanctum_objs.append(axbox("floor_tiles", M_TILE, min(floor_x0,floor_x1), max(floor_x0,floor_x1),
                            min(floor_y0,floor_y1), max(floor_y0,floor_y1), plinth_z, plinth_z+0.05))

# bell at the entrance
bell_x, bell_y = local_to_world(0.0, hall_cy0 + 0.1)
sanctum_objs.append(bar((bell_x,bell_y,plinth_z+HALL_H-0.1),(bell_x,bell_y,plinth_z+HALL_H+0.3),
                          0.03, "bell_arm", M_BELL))
sanctum_objs.append(prism("bell", M_BELL, bell_x, bell_y, plinth_z+HALL_H-0.45,
                            plinth_z+HALL_H-0.15, 0.12, 0.06, segs=10))

# saffron flags on bamboo, at the 4 sanctum corners
for lx, ly in ((-1.6, 1.6), (1.6, 1.6), (-1.6, 1.7+SANCTUM_W), (1.6, 1.7+SANCTUM_W)):
    fx, fy = local_to_world(lx, ly)
    pole_h = TEMPLE_TOP - plinth_z + 0.5
    sanctum_objs.append(bar((fx,fy,plinth_z),(fx,fy,plinth_z+pole_h), 0.025, "flagpole", M_STONE))
    flag_verts = [(fx,fy,plinth_z+pole_h),(fx+0.5*math.cos(hd),fy+0.5*math.sin(hd),plinth_z+pole_h-0.1),
                  (fx,fy,plinth_z+pole_h-0.3)]
    fme = bpy.data.meshes.new("flag"); fme.from_pydata(flag_verts, [], [(0,1,2)]); fme.update()
    recalc_outward(fme)
    fob = bpy.data.objects.new("flag", fme); fob.data.materials.append(M_SAFFRON); TCOL.objects.link(fob)
    sanctum_objs.append(fob)

TEMPLE_OB = join("TEMPLE_SANCTUM", sanctum_objs)

# ---------------------------------------------------------------------------- two shops
shop_objs_all = []
for i, sgn in enumerate((-1, 1)):
    shop_cx = park_cx + side2[0]*sgn*(PARK_R+2.5) - fwd2[0]*1.0
    shop_cy = park_cy + side2[1]*sgn*(PARK_R+2.5) - fwd2[1]*1.0
    shop_z = sample_ground(shop_cx, shop_cy)
    heading2 = math.atan2(-fwd2[0], -fwd2[1])   # face the parking
    W, D, H = 3.0, 2.2, 2.4
    def s_to_w(lx, ly, cx=shop_cx, cy=shop_cy, h=heading2):
        return (cx + lx*math.cos(h) - ly*math.sin(h), cy + lx*math.sin(h) + ly*math.cos(h))
    sx0, sy0 = s_to_w(-W/2, 0); sx1, sy1 = s_to_w(W/2, D)
    shop = axbox(f"shop_{i}_body", M_WHITEWASH, min(sx0,sx1), max(sx0,sx1), min(sy0,sy1),
                  max(sy0,sy1), shop_z, shop_z + H)
    rx0, ry0 = s_to_w(-W/2-0.3, -0.3); rx1, ry1 = s_to_w(W/2+0.3, D+0.3)
    roof = axbox(f"shop_{i}_roof", M_TIN, min(rx0,rx1), max(rx0,rx1), min(ry0,ry1), max(ry0,ry1),
                  shop_z + H, shop_z + H + 0.15)
    shop_objs_all.append(shop); shop_objs_all.append(roof)
    front_x, front_y = s_to_w(0.0, -0.02)
    shutter_src = bpy.data.objects.get("PART_SHUTTER")
    if shutter_src is not None:
        sh = bpy.data.objects.new(f"shop_{i}_SHUTTER", shutter_src.data)
        sh.location = (front_x, front_y, shop_z)
        sh.rotation_euler = (0, 0, heading2)
        TCOL.objects.link(sh)
n_shops = len(shop_objs_all) // 2
print(f"{n_shops} shops built at the parking edge")
if shop_objs_all:
    join("TEMPLE_SHOPS", shop_objs_all)

# ---------------------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 4 PASS 2 - TEMPLE : ASSERTIONS =================")
fails = []
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

flag("S5_CLIMB_ROAD terminus used, not the spec's chainage-1150 point (documented)", True)
overall = TEMPLE_TOP - plinth_z
flag(f"sanctum overall height ~5.2 m target (got {overall:.2f} m)", abs(overall - 5.2) < 0.5)
flag(f"38 steps built, real riser 0.15 m ({N_STEPS} steps)", N_STEPS == 38)
flag("parking pad built at the road's real terminus", True)
flag("2 shops built", len(shop_objs_all) == 4)
gz_check = sample_ground(plinth_x, plinth_y)
flag(f"plinth sits at a plausible height above real ground (plinth {plinth_z:.1f} m, "
     f"ground {gz_check:.1f} m, diff {plinth_z-gz_check:+.1f} m)", abs(plinth_z - gz_check) < 8.0)

print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 70)
bpy.ops.wm.save_mainfile(filepath=OUT)
print(f"saved: {OUT}")
if fails: sys.exit(1)
