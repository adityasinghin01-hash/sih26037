# SIH26037 SCENARIO 1 - STAGE 2 BLOCKOUT
# Grey masses only, built to the Environment Script's dimensions.
# Run headless:
#   /Applications/Blender.app/Contents/MacOS/Blender --background --python stage2_blockout.py
import bpy, bmesh, math, os, random, sys
from mathutils import Vector, noise as mnoise

random.seed(26037)
AVOFF_B = float(os.environ.get("AVOFF_B","7.00"))
AVOFF_T = float(os.environ.get("AVOFF_T","8.45"))
AVEL  = float(os.environ.get("AVEL","1.10"))
AVSP  = float(os.environ.get("AVSP","10.0"))
D = math.degrees; R_ = math.radians
OUT = "/Users/aditya/Desktop/SIH26037-Reference/blend/S1_stage2_blockout.blend"

# ----------------------------------------------------------------------------
# 0 - CLEAN SCENE
# ----------------------------------------------------------------------------
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.unit_settings.system = 'METRIC'
sc.unit_settings.length_unit = 'METERS'

def newcol(name):
    c = bpy.data.collections.new(name); sc.collection.children.link(c); return c
COL = {n: newcol(n) for n in
       ("TERRAIN","ROAD","BRIDGE","BUILDINGS","TREES","FURNITURE","ACTORS","CAMERA")}

def mesh_obj(name, verts, faces, col):
    me = bpy.data.meshes.new(name); me.from_pydata(verts, [], faces); me.validate()
    me.update(); ob = bpy.data.objects.new(name, me); col.objects.link(ob); return ob

# ----------------------------------------------------------------------------
# 1 - HORIZONTAL ALIGNMENT
#     bearing: 0 = +Y (north), increases clockwise. dir = (sin b, cos b)
# ----------------------------------------------------------------------------
def dirv(b):  return Vector((math.sin(b), math.cos(b)))
def leftv(b): return Vector((math.sin(b - math.pi/2), math.cos(b - math.pi/2)))

CL = []   # (chainage, x, y, bearing, segment)
def emit(s, p, b, seg): CL.append((s, p.x, p.y, b, seg))

def run_straight(s0, p0, b, L, seg, step=2.0):
    n = max(1, int(round(L/step))); d = dirv(b)
    for i in range(1, n+1):
        t = L*i/n; emit(s0+t, p0 + d*t, b, seg)
    return s0+L, p0 + d*L, b

def run_spiral(s0, p0, b0, L, R, turn, seg, entry=True, step=1.0):
    """Euler spiral. turn=+1 right (bearing increases), -1 left.
       entry=True: curvature 0 -> 1/R.  entry=False: 1/R -> 0."""
    A2 = R*L; n = max(2, int(round(L/step)))
    p = p0.copy(); b = b0; s = s0
    for i in range(1, n+1):
        u0 = L*(i-1)/n; u1 = L*i/n; du = u1-u0
        def th(u):
            return (u*u)/(2*A2) if entry else (L*L/(2*A2)) - ((L-u)**2)/(2*A2)
        # midpoint integration on heading
        bm = b0 + turn*th(0.5*(u0+u1))
        p = p + dirv(bm)*du
        b = b0 + turn*th(u1); s = s0 + u1
        emit(s, p, b, seg)
    return s, p, b

def run_arc(s0, p0, b0, R, dtheta, turn, seg, step=2.0):
    L = R*dtheta; n = max(2, int(round(L/step)))
    p = p0.copy(); b = b0
    for i in range(1, n+1):
        db = turn*dtheta/n
        bm = b + db*0.5
        p = p + dirv(bm)*(L/n); b = b + db
        emit(s0 + L*i/n, p, b, seg)
    return s0+L, p, b

# ---- geometry constants ----
V_DES = 60.0; E_SUPER = 0.07; F_LAT = 0.15
R_BEND = 130.0            # = 60^2/(127*(0.07+0.15)) = 128.9 -> 130
L_SPIR = 60.0             # = V^3/(C R), V=16.67 m/s, C=80/(75+60)=0.593

def bearing(a, b):
    d = b - a; return math.atan2(d.x, d.y)
def wrap(a):
    while a >  math.pi: a -= 2*math.pi
    while a < -math.pi: a += 2*math.pi
    return a

# THE ROUTE - waypoints chosen so the road reaches every quarter of the 2 km box.
# (x, y, radius at this point).  First and last are line ends, not curves.
ROUTE = [
    (-300.0, -1000.0,   0.0),
    (-300.0,  -560.0, 130.0),   # the blind bend
    ( 190.0,   -70.0, 380.0),   # long sweep past the river
    ( 480.0,   330.0, 260.0),   # around the east flank of the hill
    ( 560.0,   700.0, 300.0),   # turn west across the north
    (  60.0,   880.0, 340.0),
    (-500.0,   760.0, 300.0),   # north-west farmland
    (-820.0,   330.0, 270.0),   # turn south down the west side
    (-700.0,  -180.0, 320.0),
    (-780.0,  -700.0, 240.0),
    (-800.0, -1000.0,   0.0),
]
PIS  = [Vector((p[0], p[1])) for p in ROUTE]
RADS = [p[2] for p in ROUTE]

CURVES = []          # (chainage_in, chainage_out, radius, deflection_deg)
s = 0.0
p = PIS[0].copy()
b = bearing(PIS[0], PIS[1])
emit(s, p, b, "R")
for i in range(1, len(PIS)-1):
    A, B, C = PIS[i-1], PIS[i], PIS[i+1]
    b_in  = bearing(A, B); b_out = bearing(B, C)
    delta = wrap(b_out - b_in)
    turn  = 1 if delta > 0 else -1
    D     = abs(delta)
    R     = RADS[i]
    Ls    = L_SPIR
    if Ls/(2*R) > D/2: Ls = D*R*0.9              # spiral cannot eat the whole turn
    th_sp  = Ls/(2*R)
    th_arc = D - 2*th_sp
    shift  = Ls*Ls/(24*R)
    T      = (R+shift)*math.tan(D/2) + Ls/2
    TS     = B - dirv(b_in)*T
    L_str  = (TS - p).length
    if L_str > 0.5:
        s, p, b = run_straight(s, p, b, L_str, f"S{i}")
    c_in = s
    s, p, b = run_spiral(s, p, b, Ls, R, turn, f"C{i}", True)
    s, p, b = run_arc   (s, p, b, R, th_arc, turn, f"C{i}")
    s, p, b = run_spiral(s, p, b, Ls, R, turn, f"C{i}", False)
    CURVES.append((c_in, s, R, math.degrees(D)*turn))
    p = B + dirv(b_out)*T; b = b_out
L_end = (PIS[-1] - p).length
s, p, b = run_straight(s, p, b, L_end, "SE")
TOTAL = s

# where the named features sit along this route
SEG = {}
SEG["A_end"]  = CURVES[0][0]                     # start of the blind bend
SEG["B_end"]  = CURVES[0][1]                     # end of it
SEG["C_end"]  = SEG["B_end"] + 350.0             # the town
SEG["D_end"]  = SEG["C_end"] + 260.0             # the bridge (90+80+90)
SEG["E_end"]  = SEG["D_end"] + 472.0             # divided four-lane
A_end=SEG["A_end"]; B_end=SEG["B_end"]; C_end=SEG["C_end"]
D_end=SEG["D_end"]; E_end=SEG["E_end"]
R_HILL = RADS[3]

def at(ch):
    """interpolate the alignment at a chainage"""
    if ch <= CL[0][0]: r = CL[0]
    elif ch >= CL[-1][0]: r = CL[-1]
    else:
        lo, hi = 0, len(CL)-1
        while hi-lo > 1:
            m = (lo+hi)//2
            if CL[m][0] <= ch: lo = m
            else: hi = m
        a, c = CL[lo], CL[hi]
        t = (ch-a[0])/(c[0]-a[0]) if c[0] > a[0] else 0.0
        return (Vector((a[1]+(c[1]-a[1])*t, a[2]+(c[2]-a[2])*t)), a[3]+(c[3]-a[3])*t)
    return (Vector((r[1], r[2])), r[3])

# ----------------------------------------------------------------------------
# 2 - TERRAIN FIELD
# ----------------------------------------------------------------------------
_e0 = Vector((-300.0,-950.0))   # placeholder, recomputed after the alignment is built
HILL_C = Vector((760.0, 250.0))  # AHEAD on the E straight: seen head-on, then passed
HILL_RX = 300.0; HILL_RY = 205.0; HILL_ROT = math.radians(64.0); HILL_H = 168.0
RANGE_Y = 1900.0; RANGE_H = 340.0; RANGE_HW = 640.0
RIV_P = Vector((0.0,0.0)); RIV_DIR = Vector((0.0,0.0))

def smoothstep(e0, e1, x):
    t = min(1.0, max(0.0, (x-e0)/(e1-e0))); return t*t*(3-2*t)

def river_dist(x, y):
    d = Vector((x, y)) - RIV_P
    return abs(d.x*RIV_DIR.y - d.y*RIV_DIR.x)      # perp distance to river centreline

def rmf(x, y, sc, seed, oct_=5):
    """ridged multifractal - gives spurs and gullies instead of a smooth cone"""
    return mnoise.ridged_multi_fractal(Vector((x*sc, y*sc, seed)), 1.0, 2.0, oct_, 1.0, 2.0)

def terrain_base(x, y):
    """the land WITHOUT the river cut - this is 'plain level'"""
    z = (y/2000.0)*3.0                                          # plain falls N->S
    # the plain is NOT a table: three scales of undulation
    z += 1.10*mnoise.noise(Vector((x*0.0016, y*0.0016, 0.0)))   # 600 m swells
    z += 0.45*mnoise.noise(Vector((x*0.006,  y*0.006,  7.0)))   # 160 m
    z += 0.14*mnoise.noise(Vector((x*0.022,  y*0.022, 21.0)))   # field scale
    # abandoned river channels - shallow, broad, meandering depressions
    ch1 = mnoise.noise(Vector((x*0.0011, y*0.0011, 61.0)))
    z -= 0.9*math.exp(-((ch1-0.18)**2)/0.0016)
    # field bunds: a stepped terrace every ~75 m, 0.25-0.45 m, following the contour
    bnd = mnoise.noise(Vector((x*0.0135, y*0.0135, 71.0)))
    z += 0.34*(round(bnd*3.0)/3.0)
    # ---- hill spur: elliptical, rotated, ridged, with gullies ----
    dx = x-HILL_C.x; dy = y-HILL_C.y
    ca, sa = math.cos(HILL_ROT), math.sin(HILL_ROT)
    u = (dx*ca + dy*sa)/HILL_RX; v = (-dx*sa + dy*ca)/HILL_RY
    r = math.hypot(u, v)
    if r < 1.0:
        mask = smoothstep(0.0, 1.0, 1.0-r)
        ridge = rmf(x, y, 0.0090, 3.0, 7)
        # a crest line running along the ellipse's long axis, not a dome
        crestf = math.exp(-(v*v)/0.55)
        z += HILL_H*(mask**1.15)*(0.22 + 0.62*ridge + 0.30*crestf)
        # two gullies cut down the flanks
        g = abs(mnoise.turbulence(Vector((x*0.019, y*0.019, 5.0)), 6, False))
        z -= HILL_H*0.38*mask*(g**1.45)
    # ---- main range: a ridge with variable crest and side spurs ----
    crest = RANGE_Y + 130.0*mnoise.noise(Vector((x*0.0012, 0.0, 31.0)))
    hw    = RANGE_HW*(0.75 + 0.35*mnoise.noise(Vector((x*0.0018, 0.0, 41.0))))
    dyr = abs(y - crest)
    if dyr < hw:
        f = smoothstep(0.0, 1.0, 1.0 - dyr/hw)
        h = RANGE_H*(0.68 + 0.32*mnoise.noise(Vector((x*0.0016, 0.0, 51.0))))
        z += h*(f**1.7)*(0.55 + 0.45*rmf(x, y, 0.0030, 11.0))
    return z

def river_cut(x, y):
    rd = river_dist(x, y)
    if rd >= 39.5: return 0.0
    if rd <= 27.5: return -5.0 + (2.0/27.5)*rd              # thalweg -5.0 -> -3.0
    return -3.0 + ((rd-27.5)/12.0)*3.0                      # bank 1:4 up to 0

def terrain_z(x, y):
    return terrain_base(x, y) + river_cut(x, y)

WATER_Z = None

# ----------------------------------------------------------------------------
# 3 - VERTICAL PROFILE OF THE ROAD
# ----------------------------------------------------------------------------
RIVER_CH = SEG["C_end"] + 130.0                     # centre of the 140 m bridge segment
_p, _b = at(RIVER_CH); RIV_P = _p.copy(); RIV_DIR = dirv(_b + math.pi/2)

prof = []
for (ch, x, y, bb, seg) in CL:
    prof.append(terrain_z(x, y))
# smooth the profile so the road is a road, not a blanket
for _ in range(60):
    for i in range(1, len(prof)-1):
        prof[i] = (prof[i-1] + 2*prof[i] + prof[i+1])*0.25
# force the bridge deck level and the embankments
DECK_Z = None
PLAIN = 0.0
BR0 = SEG["C_end"]; BR1 = SEG["D_end"]
for i, (ch, x, y, bb, seg) in enumerate(CL):
    if BR0+90 <= ch <= BR1-90:
        if DECK_Z is None:
            PLAIN = terrain_base(RIV_P.x, RIV_P.y)
            DECK_Z  = PLAIN + 2.70                  # deck sits 2.70 m above plain level
            WATER_Z = PLAIN - 3.80                  # water 3.80 m below plain
            # clearance deck->water = 6.50 m, as IRC-5 section of the Environment Script
        prof[i] = DECK_Z
for i, (ch, x, y, bb, seg) in enumerate(CL):       # 30 m embankment ramps, 1 in 14
    if BR0 <= ch < BR0+90:
        t = (ch-BR0)/90.0; t = t*t*(3-2*t)
        prof[i] = prof[i]*(1-t) + DECK_Z*t
    elif BR1-90 < ch <= BR1:
        t = (BR1-ch)/90.0; t = t*t*(3-2*t)
        prof[i] = prof[i]*(1-t) + DECK_Z*t
# named vertical features
def bump(ch0, half, h):
    for i, (ch, *_r) in enumerate(CL):
        if abs(ch-ch0) < half:
            prof[i] += h*(0.5+0.5*math.cos(math.pi*(ch-ch0)/half))
bump(388.0, 55.0, 0.90)                            # the crest before the bend
bump(300.0,  1.85, 0.10)                           # IRC:99 speed breaker

PROF = {round(CL[i][0],3): prof[i] for i in range(len(CL))}
def road_z(ch):
    if ch <= CL[0][0]: return prof[0]
    if ch >= CL[-1][0]: return prof[-1]
    lo, hi = 0, len(CL)-1
    while hi-lo > 1:
        m=(lo+hi)//2
        if CL[m][0] <= ch: lo=m
        else: hi=m
    t=(ch-CL[lo][0])/(CL[hi][0]-CL[lo][0]); return prof[lo]+(prof[hi]-prof[lo])*t

# ----------------------------------------------------------------------------
# 4 - GROUND MESH (flattened into the road corridor)
# ----------------------------------------------------------------------------
N = 500; EXT = 2000.0; STEP = 2*EXT/N
corr = [(ch, at(ch)[0], road_z(ch)) for ch in [i*4.0 for i in range(int(TOTAL/4)+1)]]
def corridor(x, y):
    """nearest distance to the road centreline and that point's road level"""
    best = (1e9, 0.0); pv = Vector((x, y))
    for (ch, p, z) in corr:
        d = (pv-p).length_squared
        if d < best[0]: best = (d, z)
    return math.sqrt(best[0]), best[1]

verts = []; faces = []
for j in range(N+1):
    for i in range(N+1):
        x = -EXT + i*STEP; y = -EXT + j*STEP
        z = terrain_z(x, y)
        if -1000 < x < 750 and -1050 < y < 1000:    # the route now crosses the box
            d, rz = corridor(x, y)
            if d < 70.0 and river_dist(x, y) > 45.0:
                w = 1.0 - smoothstep(12.0, 70.0, d)  # blend to road level
                z = z*(1-w) + (rz-0.35)*w
        verts.append((x, y, z))
for j in range(N):
    for i in range(N):
        a=j*(N+1)+i; faces.append((a, a+1, a+N+2, a+N+1))
ground = mesh_obj("GROUND", verts, faces, COL["TERRAIN"])

# ----------------------------------------------------------------------------
# 5 - ROAD SURFACES
# ----------------------------------------------------------------------------
def ribbon(name, ch0, ch1, halfwidth_fn, col, dz=0.0, step=2.0):
    vs=[]; fs=[]; n=max(2,int((ch1-ch0)/step)); rows=0
    for k in range(n+1):
        ch = ch0 + (ch1-ch0)*k/n
        p, bb = at(ch); z = road_z(ch)+dz
        lft = leftv(bb); hwL, hwR = halfwidth_fn(ch)
        a = p + lft*hwL; c = p - lft*hwR
        vs.append((a.x, a.y, z)); vs.append((c.x, c.y, z)); rows += 1
    for k in range(rows-1):
        i=k*2; fs.append((i, i+1, i+3, i+2))
    return mesh_obj(name, vs, fs, col)

A_end=SEG["A_end"]; B_end=SEG["B_end"]; C_end=SEG["C_end"]; D_end=SEG["D_end"]
def hw_main(ch):
    if ch <= A_end:            w = 5.2
    elif ch <= B_end:          w = 5.6                      # widening on the curve
    elif ch <= C_end:          w = 7.0
    elif ch <= D_end:          w = 7.5                      # IRC:5 two-lane bridge
    elif ch <= E_end:          w = 7.0
    else:                      w = 6.0
    return w/2.0, w/2.0
ribbon("ROAD_CARRIAGEWAY", 0.0, D_end, hw_main, COL["ROAD"], dz=0.0)
ribbon("ROAD_OUTER", E_end, TOTAL, hw_main, COL["ROAD"], dz=0.0)
# shoulders
def hw_sh(ch):
    hl, hr = hw_main(ch); return hl+1.2, hr+1.2
ribbon("ROAD_SHOULDER", 0.0, C_end, hw_sh, COL["ROAD"], dz=-0.06)
ribbon("ROAD_SHOULDER2", E_end, TOTAL, hw_sh, COL["ROAD"], dz=-0.06)
# divided section: two carriageways + median
MED_HW = 2.5; CW = 7.0
def hw_out(ch): return (MED_HW+CW), -(MED_HW)   # India drives LEFT: outbound is left of median
def hw_ret(ch): return -(MED_HW), (MED_HW+CW)   # return carriageway is the other side
ribbon("ROAD_DIV_OUTBOUND", D_end, E_end, hw_out, COL["ROAD"])
ribbon("ROAD_DIV_RETURN",   D_end, E_end, hw_ret, COL["ROAD"])
ribbon("MEDIAN",            D_end, E_end-20.0, lambda c:(MED_HW,MED_HW), COL["ROAD"], dz=0.15)

# ----------------------------------------------------------------------------
# 6 - BRIDGE
# ----------------------------------------------------------------------------
def box(name, ctr, size, col, rotz=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=ctr)
    ob = bpy.context.active_object; ob.name = name
    ob.scale = size; ob.rotation_euler[2] = rotz
    for c in ob.users_collection: c.objects.unlink(ob)
    col.objects.link(ob); return ob

pB, bB = at(BR0+130.0)
box("BRIDGE_DECK_SLAB", (pB.x, pB.y, DECK_Z-0.75), (80.0, 10.5, 1.5),
    COL["BRIDGE"], rotz=-bB)
for side, off in (("W", 5.25+0.75), ("E", -(5.25+0.75))):
    q = pB + leftv(bB)*off
    box(f"BRIDGE_RAIL_{side}", (q.x, q.y, DECK_Z+0.55), (80.0, 0.12, 1.10),
        COL["BRIDGE"], rotz=-bB)
q = pB + leftv(bB)*(3.75+0.75)
box("BRIDGE_FOOTPATH_W", (q.x, q.y, DECK_Z+0.10), (80.0, 1.5, 0.20), COL["BRIDGE"], rotz=-bB)
q = pB - leftv(bB)*(3.75+0.375)
box("BRIDGE_SAFETYKERB_E", (q.x, q.y, DECK_Z+0.15), (80.0, 0.75, 0.30), COL["BRIDGE"], rotz=-bB)
for k, t in enumerate((-26.7, 0.0, 26.7)):                       # 3 piers, 4 spans of 20 m
    q = pB + dirv(bB)*t
    gz = terrain_z(q.x, q.y)
    box(f"BRIDGE_PIER_{k+1}", (q.x, q.y, (gz+DECK_Z-1.5)/2), (1.6, 8.0, DECK_Z-1.5-gz),
        COL["BRIDGE"], rotz=-bB)
for k, t in enumerate((-41.0, 41.0)):
    q = pB + dirv(bB)*t; gz = terrain_z(q.x, q.y)
    box(f"BRIDGE_ABUTMENT_{k+1}", (q.x, q.y, (gz+DECK_Z-1.5)/2), (2.5, 10.5, DECK_Z-1.5-gz),
        COL["BRIDGE"], rotz=-bB)

# ----------------------------------------------------------------------------
# 7 - BUILDINGS  (48)  chainage, side(+1 left / -1 right), setback, w, d, storeys
# ----------------------------------------------------------------------------
TOWN0 = B_end
FRONT = [  # (offset into town, side, setback, width, depth, storeys)
 ( 28,+1, 6.0, 3.4, 7.0,1),( 31.6,+1,6.0,3.0,7.0,1),( 34.8,+1,6.0,3.6,7.0,1),
 ( 38.6,+1,6.0,3.0,7.0,1),( 41.8,+1,6.0,3.2,7.0,1),
 ( 60,+1, 5.5, 8.5, 9.0,2),( 70,+1, 5.5, 7.0, 9.0,2),( 79,+1, 5.6, 6.5, 8.0,2),
 ( 92,+1, 5.4, 9.0,10.0,3),(105,+1, 5.8, 7.5, 9.0,2),
 (118,+1, 6.2, 3.8, 6.5,1),(122,+1, 6.2, 3.1, 6.5,1),(125.4,+1,6.2,3.5,6.5,1),
 (129,+1, 6.2, 2.9, 6.5,1),
 (150,+1, 6.0, 9.5,10.0,2),(168,+1, 6.5, 6.0, 8.0,1),
 ( 22,-1, 6.5, 5.0, 6.0,1),( 34,-1, 6.2, 7.5, 9.0,2),( 46,-1, 6.0, 8.0, 9.5,2),
 ( 58,-1, 5.8, 6.5, 8.0,2),( 72,-1, 5.6,10.0,11.0,3),( 88,-1, 5.9, 7.0, 9.0,2),
 (102,-1, 6.4, 4.5, 6.0,1),(112,-1, 6.4, 8.5, 9.0,2),(128,-1, 6.0, 9.5,10.5,3),
 (145,-1, 6.3, 6.0, 8.0,2),(160,-1, 6.8, 5.5, 7.0,1),(174,-1, 7.0, 6.5, 8.0,2),
]
SECOND = [(40,+1,26,9,9,2),(58,+1,31,8,8,2),(76,+1,28,10,9,1),(96,+1,34,9,10,2),
          (120,+1,29,8,8,2),(150,+1,33,11,9,2),(30,-1,24,8,8,1),(50,-1,30,9,9,2),
          (70,-1,27,10,10,2),(92,-1,35,8,8,1),(114,-1,31,9,9,2),(140,-1,28,10,10,2),
          (162,-1,33,8,8,1),(182,-1,26,9,9,2)]
OUTLYING = [(10,+1,75,12,10,1),(60,+1,110,14,12,2),(120,+1,95,10,10,1),
            (200,+1,140,16,12,2),(250,+1,90,11,9,1),(300,+1,160,13,11,2),
            (20,-1,80,12,10,1),(80,-1,120,15,12,2),(140,-1,100,11,10,1),
            (210,-1,150,14,11,2),(270,-1,85,10,9,1),(320,-1,130,12,10,2)]
def place_buildings(lst, tag):
    n=0
    for (off, side, back, w, d, st) in lst:
        ch = TOWN0 + off
        if ch > C_end: continue
        p, bb = at(ch); base = road_z(ch)
        q = p + leftv(bb)*(side*(3.5+back))
        h = st*3.15 + 1.0                       # NBC floor-to-floor + 1.0 m parapet
        gz = terrain_z(q.x, q.y)
        z = max(base-0.35, gz)
        box(f"BLD_{tag}_{n:02d}", (q.x, q.y, z+h/2), (w, d, h),
            COL["BUILDINGS"], rotz=-bb + random.uniform(-0.05, 0.05))
        n+=1
    return n
nF = place_buildings(FRONT, "F"); nS = place_buildings(SECOND, "S")
nO = place_buildings(OUTLYING, "O")

# ----------------------------------------------------------------------------
# 8 - TREE PROXIES  (blockout: trunk cylinder + canopy sphere at real dimensions)
# ----------------------------------------------------------------------------
NEEM_FORMS = {  # id: (height, crown_dia, trunk_dia, first_branch)
 "N01":(8.0,5.0,0.30,3.2), "N02":(12.0,9.0,0.42,2.8), "N03":(15.0,12.0,0.55,2.1),
 "N04":(18.0,15.0,0.68,3.5), "N05":(22.0,18.0,0.90,2.4), "N06":(14.0,10.0,0.50,2.6),
 "N07":(11.0,8.0,0.22,1.4),  "N08":(16.0,12.0,0.60,2.9), "N09":(13.0,9.5,0.52,2.2),
 "N10":(19.0,16.0,0.72,3.0)}
def tree_proxy(name, x, y, z, form, scale, elong=1.0):
    h, cd, td, fb = NEEM_FORMS[form]
    h*=scale; cd*=scale; td*=scale; fb*=scale
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=td/2, depth=h*0.75,
                                        location=(x,y,z+h*0.375))
    t=bpy.context.active_object; t.name=name+"_trunk"
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=cd/2,
                                          location=(x,y,z+fb+(h-fb)*0.62))
    c=bpy.context.active_object; c.name=name+"_crown"
    c.scale=(elong, 1.0/max(elong,0.7), 0.72)
    for ob in (t,c):
        for cc in ob.users_collection: cc.objects.unlink(ob)
        COL["TREES"].objects.link(ob)

FORMS=list(NEEM_FORMS.keys()); ntree=0
def put_tree(ch, side, off, form, scale, elong=1.0):
    global ntree
    p, bb = at(ch); q = p + leftv(bb)*(side*off)
    z = terrain_z(q.x, q.y)
    tree_proxy(f"NEEM_{ntree:03d}_{form}", q.x, q.y, z, form, scale, elong); ntree+=1

# rural straight - both sides, irregular, with the two specified gaps
gapsL=[(60,95),(180,205)]
chs=[8,34,120,152,196,231,268,304,341]
for ch in chs:
    if any(a<=ch<=b for a,b in gapsL): continue
    put_tree(ch, +1, 4.2, FORMS[ch%10], random.uniform(0.85,1.2))
for ch in [22,66,101,158,214,262,318]:
    put_tree(ch, -1, 4.6, FORMS[(ch+3)%10], random.uniform(0.85,1.2))
# the grove on the inside of the bend - 11 trees, 9 m grid, 4.0 m from carriageway edge
gr=0
for row in range(4):
    for colx in range(3):
        if gr>=11: break
        ch = A_end + 18 + colx*9.0 + row*3.0
        off = 2.8 + 4.0 + row*9.0
        elong = 1.35 if (row==0 and 0<colx<2) else 1.0
        put_tree(ch, +1, off, FORMS[(gr*3)%10], random.uniform(0.9,1.15), elong); gr+=1
# town avenue - the canopy shed, 8-10 m spacing both sides, elongated forms
holes=[(402,410),(446,452),(494,500),(616,622)]
ch=A_end+10
while ch < TOWN0+180:
    if not any(a<=ch<=b for a,b in holes):
        f = "N10" if int(ch)%3 else "N03"
        av = AVOFF_B if ch < B_end else AVOFF_T
        put_tree(ch, +1, av, f, random.uniform(0.9,1.15), AVEL)
        put_tree(ch+AVSP*0.5, -1, av+0.4, f, random.uniform(0.9,1.15), AVEL)
    ch += random.uniform(AVSP-1.0, AVSP+1.5)
# eucalyptus double row on the divided section
for k in range(38):
    ch = D_end + 20 + k*6.0
    if ch > E_end-20: break
    p, bb = at(ch); q = p + leftv(bb)*(-(MED_HW+CW+3.0+ (k%2)*3.0))
    z = terrain_z(q.x,q.y)
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.175, depth=22.0,
                                        location=(q.x,q.y,z+11.0))
    o=bpy.context.active_object; o.name=f"EUCA_{k:02d}"
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=2.6,
                                          location=(q.x,q.y,z+18.5))
    c=bpy.context.active_object; c.name=f"EUCA_{k:02d}_crown"; c.scale=(1,1,1.5)
    for ob in (o,c):
        for cc in ob.users_collection: cc.objects.unlink(ob)
        COL["TREES"].objects.link(ob)
# median trees
for k in range(11):
    ch = D_end + 30 + k*36.0
    if ch > E_end-20: break
    p, bb = at(ch); z = road_z(ch)
    tree_proxy(f"MEDIAN_{k:02d}", p.x, p.y, z, "N02", 0.8)

# ----------------------------------------------------------------------------
# 9 - POLES  (PCC 11 m, 40 m spans)
# ----------------------------------------------------------------------------
npole=0; ch=20.0
while ch < E_end - 20.0:
    side = +1 if ch < TOWN0 else (+1 if npole%2==0 else -1)
    p, bb = at(ch); off = 3.6 if ch<A_end else (5.4 if ch<C_end else MED_HW+CW+3.5)
    q = p + leftv(bb)*(side*off)
    z = terrain_z(q.x,q.y)
    box(f"POLE_{npole:03d}", (q.x,q.y,z+5.5), (0.20,0.14,11.0), COL["FURNITURE"],
        rotz=-bb); npole+=1; ch += 40.0

# ----------------------------------------------------------------------------
# 10 - ACTORS  (cow at its specified standing spot, ego at t=0)
# ----------------------------------------------------------------------------
COW_CH = TOWN0 + 33.0
globals()["COW_CH"]=COW_CH
p, bb = at(COW_CH); q = p + leftv(bb)*(3.5+1.4)
box("COW_BLOCK", (q.x,q.y,terrain_z(q.x,q.y)+0.73), (2.05,0.64,1.46), COL["ACTORS"],
    rotz=-bb+R_(70))
p, bb = at(0.0)
box("EGO_BLOCK", (p.x,p.y,road_z(0.0)+0.75), (4.0,1.7,1.5), COL["ACTORS"], rotz=-bb)

# ----------------------------------------------------------------------------
# 11 - CAMERA  (dashcam: eye height 1.3 m, wide lens)
# ----------------------------------------------------------------------------
CAM_CH = A_end + 120.0
p, bb = at(CAM_CH)
cam_d = bpy.data.cameras.new("DASHCAM"); cam_d.lens = 12.0; cam_d.sensor_width = 36.0
cam_d.clip_start = 0.1; cam_d.clip_end = 4000.0
cam = bpy.data.objects.new("DASHCAM", cam_d); COL["CAMERA"].objects.link(cam)
cam.location = (p.x, p.y, road_z(CAM_CH)+1.30)
cam.rotation_euler = (R_(90.0), 0.0, -bb)
sc.camera = cam
sc.render.resolution_x = 1920; sc.render.resolution_y = 1080

def add_cam(name, ch, lens=12.0, h=1.30, yaw=0.0, lift=0.0, pitch=0.0):
    p, bb = at(ch)
    c = bpy.data.cameras.new(name); c.lens=lens; c.sensor_width=36.0
    c.clip_start=0.05; c.clip_end=6000.0
    o = bpy.data.objects.new(name, c); COL["CAMERA"].objects.link(o)
    o.location=(p.x, p.y, road_z(ch)+h+lift)
    o.rotation_euler=(R_(90.0+pitch), 0.0, -bb + R_(yaw))
    return o
add_cam("CAM_01_rural",       120.0)
add_cam("CAM_02_bend_entry",  A_end-8.0)
add_cam("CAM_03_cow_reveal",  COW_CH-45.0)
add_cam("CAM_04_town",        TOWN0+70.0)
add_cam("CAM_05_bridge_app",  BR0+45.0)
add_cam("CAM_06_on_bridge",   BR0+105.0)
add_cam("CAM_07_hill_curve",  D_end+230.0, lens=14.0)
# a side elevation of the bridge, derived from the deck object
_pb, _bb = at(BR0+130.0)
_off = leftv(_bb)*135.0
cS = bpy.data.cameras.new("CAM_08_bridge_side"); cS.lens=42.0; cS.sensor_width=36.0
cS.clip_start=0.1; cS.clip_end=6000.0
oS = bpy.data.objects.new("CAM_08_bridge_side", cS); COL["CAMERA"].objects.link(oS)
_sx,_sy = _pb.x+_off.x, _pb.y+_off.y
oS.location=(_sx, _sy, max(terrain_z(_sx,_sy), DECK_Z) + 6.0)
oS.rotation_euler=(R_(93.0), 0.0, -(_bb - math.pi/2))
# oblique over the river valley
cV = bpy.data.cameras.new("CAM_09_valley"); cV.lens=24.0; cV.sensor_width=36.0
cV.clip_start=0.1; cV.clip_end=8000.0
oV = bpy.data.objects.new("CAM_09_valley", cV); COL["CAMERA"].objects.link(oV)
_o2 = leftv(_bb)*300.0
_vx,_vy = _pb.x+_o2.x, _pb.y+_o2.y-200.0
oV.location=(_vx, _vy, terrain_z(_vx,_vy) + 130.0)
oV.rotation_euler=(R_(62.0), 0.0, -(_bb - math.pi/2) - R_(28.0))

# ----------------------------------------------------------------------------
# 12 - SAVE + REPORT
# ----------------------------------------------------------------------------
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT)

def canopy_cover(ch0, ch1):
    dg = bpy.context.evaluated_depsgraph_get()
    hit_n = tot = 0
    ch = ch0
    while ch < ch1:
        p, bb = at(ch); lf = leftv(bb); hw = hw_main(ch)[0]
        for lat in (-0.8, -0.4, 0.0, 0.4, 0.8):
            q = p + lf*(lat*hw); z0 = road_z(ch)+0.1
            ok, *_ = sc.ray_cast(dg, (q.x, q.y, z0), (0.0, 0.0, 1.0), distance=40.0)
            tot += 1; hit_n += 1 if ok else 0
        ch += 2.0
    return 100.0*hit_n/max(tot,1)
cov_bend = canopy_cover(A_end, B_end)
cov_town = canopy_cover(B_end, B_end+180.0)
print(f"CANOPY COVER over carriageway: bend {cov_bend:.1f} %   town {cov_town:.1f} %"
      f"   (spec target: 62 % bend, 45 % town)")
pA,_=at(A_end); pB2,_=at(B_end); pC,_=at(C_end); pD,_=at(D_end); pE,_=at(TOTAL)
print("\n================ STAGE 2 BLOCKOUT REPORT ================")
print(f"bend: spiral turns {D(th_sp):.3f} deg each, arc {D(TH_ARC):.3f} deg,"
      f" arc len {R_BEND*TH_ARC:.1f} m, TOTAL BEND {2*L_SPIR + R_BEND*TH_ARC:.1f} m")
print(f"hill curve: spiral {D(th_sp2):.3f} deg each, arc {D(TH_ARC2):.3f} deg,"
      f" arc len {R_HILL*TH_ARC2:.1f} m")
for k,(nm,ch,pt) in enumerate([("A end",A_end,pA),("B end",B_end,pB2),
        ("C end",C_end,pC),("D end",D_end,pD),("E end",TOTAL,pE)]):
    print(f"  {nm:6s} ch={ch:8.2f}  ({pt.x:8.2f}, {pt.y:9.2f})  z={road_z(ch):7.2f}")
print(f"TOTAL CENTRELINE  {TOTAL:.1f} m over {len(CURVES)} curves")
for k,(ci,co,rr,dd) in enumerate(CURVES):
    print(f"   curve {k+1}: ch {ci:7.1f}-{co:7.1f}  R={rr:6.1f} m  deflection {dd:+7.2f} deg")
xs=[c[1] for c in CL]; ys=[c[2] for c in CL]
print(f"   route spans x {min(xs):.0f}..{max(xs):.0f}  y {min(ys):.0f}..{max(ys):.0f}")
print(f"river ch {RIVER_CH:.1f}  plain z {PLAIN:.2f}  deck z {DECK_Z:.2f}  water z {WATER_Z:.2f}"
      f"  -> clearance {DECK_Z-WATER_Z:.2f} m")
print(f"bridge embankment: {DECK_Z-road_z(BR0):.2f} m rise over 90 m ramps")
gmax=0.0; gch=0.0
for i in range(1,len(CL)):
    dl = CL[i][0]-CL[i-1][0]
    if dl > 0 and abs(CL[i][0]-300.0) > 3.0:
        g = abs(prof[i]-prof[i-1])/dl*100.0
        if g > gmax: gmax, gch = g, CL[i][0]
print(f"MAX GRADIENT {gmax:.2f} % at ch {gch:.1f}  "
      f"(IRC plain terrain: 3.3 % ruling, 5.0 % limiting, 6.0 % exceptional)")
cl_min=1e9; cl_ch=0.0
for ch in [D_end + i*4.0 for i in range(int((TOTAL-D_end)/4)+1)]:
    q,_=at(ch); dx=q.x-HILL_C.x; dy=q.y-HILL_C.y
    ca_,sa_=math.cos(HILL_ROT), math.sin(HILL_ROT)
    uu=(dx*ca_+dy*sa_)/HILL_RX; vv=(-dx*sa_+dy*ca_)/HILL_RY
    rr=math.hypot(uu,vv)
    toe=(1.0-rr)*min(HILL_RX,HILL_RY)
    if toe < cl_min: cl_min, cl_ch = toe, ch
# verify the hill really sits at the curve's centre of curvature
_ps,_bs = at(D_end+60.0)
_cc = _ps + leftv(_bs)*R_HILL
print(f"curve centre of curvature = ({_cc.x:.1f}, {_cc.y:.1f});  hill centre = "
      f"({HILL_C.x:.1f}, {HILL_C.y:.1f});  offset {(Vector((HILL_C.x,HILL_C.y))-_cc).length:.1f} m")
_near=1e9;_nch=0
for ch in [D_end + i*4.0 for i in range(int((TOTAL-D_end)/4)+1)]:
    q,_=at(ch); dx=q.x-HILL_C.x; dy=q.y-HILL_C.y
    ca_,sa_=math.cos(HILL_ROT), math.sin(HILL_ROT)
    uu=(dx*ca_+dy*sa_)/HILL_RX; vv=(-dx*sa_+dy*ca_)/HILL_RY
    rr=math.hypot(uu,vv); d=(rr-1.0)*math.hypot(dx,dy)/max(rr,1e-6)
    if d<_near:_near,_nch=d,ch
print(f"HILL: {HILL_H:.0f} m high, {2*HILL_RX:.0f} x {2*HILL_RY:.0f} m base; "
      f"road passes its toe with {_near:.0f} m clearance at ch {_nch:.0f}")
print(f"buildings: front {nF}  second {nS}  outlying {nO}  TOTAL {nF+nS+nO}")
print(f"neem placed {ntree}   poles {npole}")
print(f"objects {len(bpy.data.objects)}   verts "
      f"{sum(len(o.data.vertices) for o in bpy.data.objects if o.type=='MESH')}")
print(f"saved -> {OUT}")
print("=========================================================\n")
