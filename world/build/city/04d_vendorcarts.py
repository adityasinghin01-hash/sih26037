# COMPONENT 4 PASS 2 - ITEM 3 (closes Component 4): street vendor carts and stalls.
# Spec: S0-THE-WORLD.md "COMPONENT 4 PASS 2 - ITEM 3", written 11 Sep 2026 before this script,
# per Rule 1. REF-03 s8's own real manufacturer sizes for 3 cart types, placed causally on
# detailed shopfront buildings only (never kutcha huts or shells) at a 60% draw.
#   blender --background --python build/city/04d_vendorcarts.py
import bpy, bmesh, os, sys, time, math, zlib
import numpy as np
T0 = time.time()
REF = os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026-city/world")
OUT = f"{REF}/blend/04_BUILDINGS.blend"

bpy.ops.wm.open_mainfile(filepath=OUT)
sc = bpy.context.scene

if "VENDOR_CARTS" not in bpy.data.collections:
    c = bpy.data.collections.new("VENDOR_CARTS"); sc.collection.children.link(c)
CCOL = bpy.data.collections["VENDOR_CARTS"]
for ob in list(CCOL.objects):
    me = ob.data
    bpy.data.objects.remove(ob, do_unlink=True)
    if me and me.users == 0: bpy.data.meshes.remove(me)

# ---------------------------------------------------------------------------- mesh toolbox
def _recalc(me):
    bm = bmesh.new(); bm.from_mesh(me); bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free(); me.update()

def mat(name, color, rough=0.7, metallic=0.0, alpha=1.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metallic
    if alpha < 1.0:
        b.inputs["Alpha"].default_value = alpha
        m.blend_method = 'BLEND'
    return m

def _box_geo(x0, x1, y0, y1, z0, z1, vbase):
    verts = [(x0,y0,z0),(x1,y0,z0),(x1,y1,z0),(x0,y1,z0),
             (x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)]
    fs = [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)]
    return verts, [tuple(i+vbase for i in f) for f in fs]

def _bar_geo(p0, p1, w, vbase):
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
    return verts, [tuple(i+vbase for i in f) for f in fs]

def _cyl_geo(cx, cy, z0, z1, r, vbase, segs=8, axis='z'):
    # a small wheel/pole cylinder. axis='y' gives a wheel standing upright (axle along Y).
    verts = []
    for t in (0.0, 1.0):
        for i in range(segs):
            a = 2*math.pi*i/segs
            if axis == 'z':
                verts.append((cx+r*math.cos(a), cy+r*math.sin(a), z0+(z1-z0)*t))
            else:   # axis == 'y': a wheel disc, cx,cy,z0 is the hub centre, z1 is the axle length
                verts.append((cx+r*math.cos(a), cy+(z1-z0)*t, z0+r*math.sin(a)))
    fs = []
    for i in range(segs):
        j = (i+1) % segs
        fs.append((i, j, segs+j, segs+i))
    fs.append(tuple(range(segs-1, -1, -1)))
    fs.append(tuple(segs+i for i in range(segs)))
    return verts, [tuple(i+vbase for i in f) for f in fs]

def build_combined(name, parts, mats):
    all_verts, all_faces, all_matidx = [], [], []
    for verts, faces, mi in parts:
        all_verts.extend(verts)
        all_faces.extend(faces)
        all_matidx.extend([mi] * len(faces))
    me = bpy.data.meshes.new(name)
    me.from_pydata(all_verts, [], all_faces)
    me.update()
    _recalc(me)
    for m in mats: me.materials.append(m)
    for i, mi in enumerate(all_matidx):
        me.polygons[i].material_index = mi
    ob = bpy.data.objects.new(name, me); CCOL.objects.link(ob)
    return ob

M_STEEL = mat("CART_steel", (0.62, 0.63, 0.65), 0.35, metallic=0.75)
M_WOOD = mat("CART_wood", (0.42, 0.28, 0.16), 0.75)
M_TARP = [mat(f"CART_tarp_{i}", c, 0.85, alpha=0.97) for i, c in enumerate(
          [(0.15, 0.45, 0.20), (0.75, 0.15, 0.15), (0.85, 0.75, 0.20)])]   # green/red/yellow
M_PRODUCE = [mat(f"CART_produce_{i}", c, 0.6) for i, c in enumerate(
             [(0.75, 0.15, 0.12), (0.85, 0.60, 0.10), (0.35, 0.55, 0.15)])]   # tomato/mango/veg
M_WHEEL = mat("CART_wheel", (0.06, 0.06, 0.06), 0.9)
MATS = [M_STEEL, M_WOOD] + M_TARP + M_PRODUCE + [M_WHEEL]
MI = {m.name: i for i, m in enumerate(MATS)}

def wheels(parts, cx, cy, gz, axle_len, r=0.30):
    v, f = _cyl_geo(cx - axle_len/2, cy, gz + r, gz + r, r, 0, segs=10, axis='y')
    parts.append((v, f, MI["CART_wheel"]))
    v, f = _cyl_geo(cx + axle_len/2, cy, gz + r, gz + r, r, 0, segs=10, axis='y')
    parts.append((v, f, MI["CART_wheel"]))
    v, f = _bar_geo((cx-axle_len/2, cy, gz+r), (cx+axle_len/2, cy, gz+r), 0.04, 0)
    parts.append((v, f, MI["CART_steel"]))

def build_steel_thela(cx, cy, gz, heading_deg, seed):
    # REF-03 s8: 6x3x7 ft = 1.83x0.91x2.13 m, the 7ft including the canopy frame
    L, W, BED_H, TOTAL_H = 1.83, 0.91, 0.75, 2.13
    hd = math.radians(heading_deg)
    def w2(lx, ly):
        return (cx + lx*math.cos(hd) - ly*math.sin(hd), cy + lx*math.sin(hd) + ly*math.cos(hd))
    parts = []
    x0, y0 = w2(-L/2, -W/2); x1, y1 = w2(L/2, W/2)
    v, f = _box_geo(min(x0,x1), max(x0,x1), min(y0,y1), max(y0,y1), gz+0.3, gz+BED_H, 0)
    parts.append((v, f, MI["CART_steel"]))
    for lx, ly in ((-L/2+0.1, -W/2+0.1), (L/2-0.1, -W/2+0.1), (-L/2+0.1, W/2-0.1), (L/2-0.1, W/2-0.1)):
        px, py = w2(lx, ly)
        v, f = _bar_geo((px,py,gz+BED_H), (px,py,gz+TOTAL_H), 0.03, 0)
        parts.append((v, f, MI["CART_steel"]))
    rx0, ry0 = w2(-L/2-0.15, -W/2-0.1); rx1, ry1 = w2(L/2+0.15, W/2+0.1)
    sag = 0.08
    mx, my = w2(0, 0)
    verts = [(min(rx0,rx1),min(ry0,ry1),gz+TOTAL_H),(max(rx0,rx1),min(ry0,ry1),gz+TOTAL_H),
             (mx,my,gz+TOTAL_H-sag),
             (min(rx0,rx1),max(ry0,ry1),gz+TOTAL_H),(max(rx0,rx1),max(ry0,ry1),gz+TOTAL_H)]
    fs = [(0,1,2),(1,4,2),(4,3,2),(3,0,2)]
    parts.append((verts, fs, MI[M_TARP[seed % len(M_TARP)].name]))
    wheels(parts, cx, cy, gz, W*0.9)
    return build_combined(f"CART_{seed % 100000}_steel", parts, MATS)

def build_tea_cart(cx, cy, gz, heading_deg, seed):
    # REF-03 s8: chai thela ~4 ft (1.22 m) long. Simple counter, no canopy.
    L, W, H = 1.22, 0.55, 0.9
    hd = math.radians(heading_deg)
    def w2(lx, ly):
        return (cx + lx*math.cos(hd) - ly*math.sin(hd), cy + lx*math.sin(hd) + ly*math.cos(hd))
    parts = []
    x0, y0 = w2(-L/2, -W/2); x1, y1 = w2(L/2, W/2)
    v, f = _box_geo(min(x0,x1), max(x0,x1), min(y0,y1), max(y0,y1), gz, gz+H, 0)
    parts.append((v, f, MI["CART_wood"]))
    tx0, ty0 = w2(-L/2-0.03, -W/2-0.03); tx1, ty1 = w2(L/2+0.03, W/2+0.03)
    v, f = _box_geo(min(tx0,tx1), max(tx0,tx1), min(ty0,ty1), max(ty0,ty1), gz+H, gz+H+0.03, 0)
    parts.append((v, f, MI["CART_steel"]))
    # a kettle - a small cylinder on top
    kx, ky = w2(L*0.2, 0.0)
    v, f = _cyl_geo(kx, ky, gz+H+0.03, gz+H+0.20, 0.08, 0, segs=8, axis='z')
    parts.append((v, f, MI["CART_steel"]))
    wheels(parts, cx, cy, gz, W*0.85, r=0.22)
    return build_combined(f"CART_{seed % 100000}_tea", parts, MATS)

def build_fruit_cart(cx, cy, gz, heading_deg, seed):
    # REF-03 s8: 5x3 ft (1.52x0.91 m), bed height ~0.75m. Open bed, no canopy.
    L, W, BED_H = 1.52, 0.91, 0.75
    hd = math.radians(heading_deg)
    def w2(lx, ly):
        return (cx + lx*math.cos(hd) - ly*math.sin(hd), cy + lx*math.sin(hd) + ly*math.cos(hd))
    parts = []
    x0, y0 = w2(-L/2, -W/2); x1, y1 = w2(L/2, W/2)
    v, f = _box_geo(min(x0,x1), max(x0,x1), min(y0,y1), max(y0,y1), gz, gz+BED_H, 0)
    parts.append((v, f, MI["CART_wood"]))
    # a heap of produce on the bed - a low tapered pile, per-cart colour
    px, py = w2(0.0, 0.0)
    pcol = MI[M_PRODUCE[seed % len(M_PRODUCE)].name]
    v = []
    for r, z in ((L*0.4, gz+BED_H), (L*0.15, gz+BED_H+0.22)):
        for i in range(10):
            a = 2*math.pi*i/10
            v.append((px+r*math.cos(a), py+r*math.sin(a)*(W/L), z))
    fs = []
    for i in range(10):
        j = (i+1) % 10
        fs.append((i, j, 10+j, 10+i))
    fs.append(tuple(range(9, -1, -1)))
    fs.append(tuple(10+i for i in range(10)))
    parts.append((v, fs, pcol))
    wheels(parts, cx, cy, gz, W*0.9)
    return build_combined(f"CART_{seed % 100000}_fruit", parts, MATS)

CART_BUILDERS = [build_steel_thela, build_tea_cart, build_fruit_cart]
CART_DRAW_PROB = 0.60   # engineering default, S0's own item 3: "not every shopfront has a cart"

n_carts = 0
n_eligible = 0
for ob in list(bpy.data.objects):
    if not ob.name.startswith("BLDG_"): continue
    if not ob.get("detailed", False) or not ob.get("ground_shop", False): continue
    n_eligible += 1
    seed = zlib.crc32(f"vendorcart_{ob.name}".encode())
    rng = np.random.RandomState(seed % (2**31))
    if rng.rand() >= CART_DRAW_PROB: continue

    heading = math.degrees(ob.rotation_euler.z)
    width, height = ob.scale.x, ob.scale.z
    hd = math.radians(heading)
    # front edge = local y=0 (matches 04b_buildings.py's own front-face convention), offset
    # sideways along local x by a per-building hashed fraction so a row of buildings does not
    # place every cart at the exact same spot relative to its own frontage.
    lx_frac = (rng.rand() - 0.5) * 0.7
    front_offset = 0.9   # metres out from the wall, clear of the frontage itself
    wx = ob.location.x + (lx_frac*width)*math.cos(hd) - (-front_offset)*math.sin(hd)
    wy = ob.location.y + (lx_frac*width)*math.sin(hd) + (-front_offset)*math.cos(hd)
    gz = ob.location.z
    cart_heading = heading + rng.uniform(-8.0, 8.0)

    builder = CART_BUILDERS[int(rng.rand() * len(CART_BUILDERS))]
    builder(wx, wy, gz, cart_heading, seed)
    n_carts += 1

print(f"{n_eligible} eligible detailed shopfront buildings, {n_carts} vendor carts placed "
      f"({n_carts/max(n_eligible,1)*100:.0f}% draw)")

# ---------------------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 4 PASS 2 - VENDOR CARTS : ASSERTIONS =================")
fails = []
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

flag(f"at least some detailed shopfront buildings found ({n_eligible})", n_eligible > 0)
flag(f"carts placed ({n_carts})", n_carts > 0)
draw_frac = n_carts / max(n_eligible, 1)
flag(f"draw fraction near the spec's 60% (got {draw_frac*100:.0f}%)", 0.45 <= draw_frac <= 0.75)
n_steel = sum(1 for o in CCOL.objects if o.name.endswith("_steel"))
n_tea = sum(1 for o in CCOL.objects if o.name.endswith("_tea"))
n_fruit = sum(1 for o in CCOL.objects if o.name.endswith("_fruit"))
flag(f"all 3 real cart types present (steel {n_steel}, tea {n_tea}, fruit {n_fruit})",
     n_steel > 0 and n_tea > 0 and n_fruit > 0)

print(f"\nbuild time {time.time() - T0:.0f}s")
print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 70)
bpy.ops.wm.save_mainfile(filepath=OUT)
print(f"saved: {OUT}")
if fails: sys.exit(1)
