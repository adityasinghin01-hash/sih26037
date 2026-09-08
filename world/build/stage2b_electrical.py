# SIH26037 SCENARIO 1 - STAGE 2b - THE ELECTRICAL SYSTEM + BIG SURROUNDING MASSES
# Runs the blockout first (single source of truth), then adds to it.
#   /Applications/Blender.app/Contents/MacOS/Blender --background --python stage2b_electrical.py
import os, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
exec(open(os.path.join(HERE, "stage2_blockout.py")).read())

import bpy
from mathutils import Vector
random.seed(770)
OUT2 = "/Users/aditya/Desktop/SIH26037-Reference/blend/S1_stage2_world.blend"

for n in ("POWER", "SURROUND"):
    c = bpy.data.collections.new(n); sc.collection.children.link(c); COL[n] = c

# remove the crude 11 m poles from the blockout - they are replaced below
for ob in [o for o in COL["FURNITURE"].objects if o.name.startswith("POLE_")]:
    bpy.data.objects.remove(ob, do_unlink=True)

# ---------------------------------------------------------------- beam builder
class MeshAcc:
    def __init__(self): self.v=[]; self.f=[]
    def beam(self, p0, p1, w, h=None):
        """rectangular prism from p0 to p1, section w x h"""
        h = w if h is None else h
        p0=Vector(p0); p1=Vector(p1); d=(p1-p0)
        if d.length < 1e-6: return
        d.normalize()
        up = Vector((0,0,1))
        if abs(d.dot(up)) > 0.999: up = Vector((1,0,0))
        a = d.cross(up).normalized(); b = d.cross(a).normalized()
        i=len(self.v)
        for p in (p0,p1):
            for sx,sy in ((-1,-1),(1,-1),(1,1),(-1,1)):
                self.v.append(tuple(p + a*(sx*w/2) + b*(sy*h/2)))
        self.f += [(i,i+1,i+2,i+3),(i+4,i+7,i+6,i+5),(i,i+4,i+5,i+1),
                   (i+1,i+5,i+6,i+2),(i+2,i+6,i+7,i+3),(i+3,i+7,i+4,i)]
    def tube(self, p0, p1, r, seg=6):
        p0=Vector(p0); p1=Vector(p1); d=(p1-p0)
        if d.length<1e-6: return
        d.normalize(); up=Vector((0,0,1))
        if abs(d.dot(up))>0.999: up=Vector((1,0,0))
        a=d.cross(up).normalized(); b=d.cross(a).normalized()
        i=len(self.v)
        for p in (p0,p1):
            for k in range(seg):
                t=2*math.pi*k/seg
                self.v.append(tuple(p + a*(r*math.cos(t)) + b*(r*math.sin(t))))
        for k in range(seg):
            k2=(k+1)%seg
            self.f.append((i+k, i+k2, i+seg+k2, i+seg+k))
    def make(self, name, col):
        me=bpy.data.meshes.new(name); me.from_pydata(self.v,[],self.f)
        me.validate(); me.update()
        ob=bpy.data.objects.new(name, me); col.objects.link(ob); return ob

# ============================================================================
# 1 - THE 132 kV DOUBLE-CIRCUIT LATTICE TOWER  (built once, then instanced)
# ============================================================================
TW_H      = 33.00          # to the earth-wire peak
TW_BASE   = 6.60           # base width = height/5  (IS practice)
TW_WAIST  = 1.80           # cage width
TW_WZ     = 17.50          # height at which the taper ends
ARMS = [(17.50, 4.40), (22.00, 3.60), (26.50, 2.70)]   # (z, half-length)
DISCS = 9                  # 132 kV suspension string
DISC_P = 0.145             # disc pitch, m  (255 mm dia x 145 mm)
STR_L = DISCS*DISC_P       # 1.305 m
PANEL = 2.00               # leg panel height (buckling rule)

def tower_halfwidth(z):
    if z <= TW_WZ:
        t = z/TW_WZ
        return (TW_BASE/2)*(1-t) + (TW_WAIST/2)*t
    if z <= 28.0: return TW_WAIST/2
    t = (z-28.0)/(TW_H-28.0)
    return (TW_WAIST/2)*(1-t) + 0.15*t

def build_tower():
    m = MeshAcc()
    legs = [(-1,-1),(1,-1),(1,1),(-1,1)]
    zs = [i*PANEL for i in range(int(28.0/PANEL)+1)] + [28.0, TW_H]
    zs = sorted(set([z for z in zs if z <= TW_H]))
    # legs
    for (sx,sy) in legs:
        for k in range(len(zs)-1):
            z0,z1 = zs[k], zs[k+1]
            w0,w1 = tower_halfwidth(z0), tower_halfwidth(z1)
            sec = 0.16 if z0 < 12 else 0.11
            m.beam((sx*w0, sy*w0, z0), (sx*w1, sy*w1, z1), sec)
    # horizontal belts + X bracing on all four faces, 45 deg diagonals
    for k in range(len(zs)-1):
        z0,z1 = zs[k], zs[k+1]
        w0,w1 = tower_halfwidth(z0), tower_halfwidth(z1)
        for i in range(4):
            a0 = Vector((legs[i][0]*w0, legs[i][1]*w0, z0))
            b0 = Vector((legs[(i+1)%4][0]*w0, legs[(i+1)%4][1]*w0, z0))
            a1 = Vector((legs[i][0]*w1, legs[i][1]*w1, z1))
            b1 = Vector((legs[(i+1)%4][0]*w1, legs[(i+1)%4][1]*w1, z1))
            m.beam(a0, b0, 0.07)                       # belt
            m.beam(a0, b1, 0.06); m.beam(b0, a1, 0.06) # the X
    m.beam((-tower_halfwidth(28), -tower_halfwidth(28), 28.0),
           ( tower_halfwidth(28),  tower_halfwidth(28), 28.0), 0.07)
    # portal bracing in the bottom panel (wide legs need it)
    w0 = tower_halfwidth(0.0)
    for i in range(4):
        a=Vector((legs[i][0]*w0, legs[i][1]*w0, 0.0))
        b=Vector((legs[(i+1)%4][0]*w0, legs[(i+1)%4][1]*w0, 0.0))
        m.beam(a+ (b-a)*0.5 + Vector((0,0,0)), a+(b-a)*0.5+Vector((0,0,PANEL)), 0.08)
    # cross arms, both sides, tapered trusses
    for (az, half) in ARMS:
        w = tower_halfwidth(az)
        for s in (-1, 1):
            tip = Vector((s*half, 0.0, az))
            r0  = Vector((s*w, -w, az)); r1 = Vector((s*w, w, az))
            m.beam(r0, tip, 0.09); m.beam(r1, tip, 0.09)          # chords
            up0 = Vector((s*w, -w*0.6, az+1.7)); up1 = Vector((s*w, w*0.6, az+1.7))
            m.beam(up0, tip, 0.07); m.beam(up1, tip, 0.07)        # top ties
            m.beam(up0, r0, 0.06);  m.beam(up1, r1, 0.06)
            for q in (0.35, 0.65):                                 # web members
                p = r0.lerp(tip, q); pu = up0.lerp(tip, q)
                m.beam(p, pu, 0.05)
                p = r1.lerp(tip, q); pu = up1.lerp(tip, q)
                m.beam(p, pu, 0.05)
    # earth-wire peak
    m.beam((-TW_WAIST/2,-TW_WAIST/2,28.0), (0,0,TW_H), 0.09)
    m.beam(( TW_WAIST/2,-TW_WAIST/2,28.0), (0,0,TW_H), 0.09)
    m.beam(( TW_WAIST/2, TW_WAIST/2,28.0), (0,0,TW_H), 0.09)
    m.beam((-TW_WAIST/2, TW_WAIST/2,28.0), (0,0,TW_H), 0.09)
    # step bolts: ONE leg only, 400 mm apart, from 2.5 m to the top
    z = 2.5
    while z < 27.0:
        w = tower_halfwidth(z)
        m.beam((-w, -w, z), (-w-0.175, -w-0.175, z), 0.016)
        z += 0.40
    # anti-climbing device: a flared barbed collar at 3.5 m
    w = tower_halfwidth(3.5)
    for i in range(4):
        a=Vector((legs[i][0]*w, legs[i][1]*w, 3.5))
        b=Vector((legs[(i+1)%4][0]*w, legs[(i+1)%4][1]*w, 3.5))
        m.beam(a*1.0+Vector((0,0,0)), b*1.0+Vector((0,0,0)), 0.05)
        m.beam(a, a*1.35+Vector((0,0,0.9)), 0.045)
    # insulator strings: 9 discs hanging from every arm tip
    for (az, half) in ARMS:
        for s in (-1,1):
            for d in range(DISCS):
                zc = az - 0.10 - d*DISC_P
                m.tube((s*half, 0, zc), (s*half, 0, zc-0.085), 0.1275, 8)
    return m.make("TOWER_132kV_A", COL["POWER"])

TOWER = build_tower()
TOWER.location = (0,0,-1000)                 # master copy parked out of the way
TOWER.hide_render = True; TOWER.hide_viewport = True

# ---- the line route: crosses the rural straight, ignores the road entirely ----
TL_THRU = Vector((-300.0, -770.0)); TL_BRG = math.radians(105.0)
TL_DIR  = dirv(TL_BRG)
TL_SPAN = 320.0                              # 132 kV normal span (utility spec)
TL_N    = 9
tower_pts = []
for i in range(TL_N):
    t = (i - (TL_N-1)/2.0)*TL_SPAN
    p = TL_THRU + TL_DIR*t
    gz = terrain_z(p.x, p.y)
    ext = [0.0, 3.0, 6.0][ (0 if i in (0,TL_N-1) else (i*7)%3) ]   # +3/+6 m body extensions
    tower_pts.append((p, gz, ext))
    o = bpy.data.objects.new(f"TOWER_{i:02d}", TOWER.data)          # linked duplicate
    COL["POWER"].objects.link(o)
    o.location = (p.x, p.y, gz)
    o.rotation_euler = (0,0,-TL_BRG)
    o.scale = (1.0, 1.0, (TW_H+ext)/TW_H)

def wire_curve(name, pts, radius, col):
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions='3D'
    cu.bevel_depth = radius; cu.bevel_resolution = 1; cu.resolution_u = 2
    sp = cu.splines.new('POLY'); sp.points.add(len(pts)-1)
    for i,p in enumerate(pts): sp.points[i].co = (p[0],p[1],p[2],1)
    o = bpy.data.objects.new(name, cu); col.objects.link(o); return o

def sag_pts(a, b, sag, n=16):
    a=Vector(a); b=Vector(b); out=[]
    for i in range(n+1):
        t=i/n; p=a.lerp(b,t)
        out.append((p.x, p.y, p.z - 4.0*sag*t*(1.0-t)))     # parabola, not a sine
    return out

# conductors: 3 per side per circuit, hung under each arm tip; + earth wire on the peak
SAG_TL = 8.0
nw=0
for i in range(TL_N-1):
    (p0,g0,e0) = tower_pts[i]; (p1,g1,e1) = tower_pts[i+1]
    k0 = (TW_H+e0)/TW_H; k1 = (TW_H+e1)/TW_H
    lat = leftv(TL_BRG)
    for (az, half) in ARMS:
        for s in (-1,1):
            a = p0 + lat*(s*half*k0); b = p1 + lat*(s*half*k1)
            za = g0 + (az*k0) - 0.10 - STR_L
            zb = g1 + (az*k1) - 0.10 - STR_L
            wire_curve(f"TLW_{nw:03d}", sag_pts((a.x,a.y,za),(b.x,b.y,zb), SAG_TL),
                       0.011, COL["POWER"]); nw+=1
    wire_curve(f"TLE_{i:02d}", sag_pts((p0.x,p0.y,g0+TW_H*k0),(p1.x,p1.y,g1+TW_H*k1),
               SAG_TL*0.75), 0.006, COL["POWER"])

# ---- the right of way: 27 m cleared strip, no trees allowed under a 132 kV line ----
ROW_HALF = 13.5
def perp_dist_to_line(p):
    d = Vector((p[0],p[1])) - TL_THRU
    return abs(d.x*TL_DIR.y - d.y*TL_DIR.x)
cleared = 0
for ob in list(COL["TREES"].objects):
    if perp_dist_to_line((ob.location.x, ob.location.y)) < ROW_HALF:
        bpy.data.objects.remove(ob, do_unlink=True); cleared += 1

# ============================================================================
# 2 - THE 11 kV FEEDER  -  candelabra pole top, measured off Aditya's footage
# ============================================================================
PL_LEN = 9.00; PL_BURY = 1.50; PL_H = PL_LEN - PL_BURY      # 7.50 m above ground
XA_Z   = 6.90            # cross-arm height above ground
XA_W   = 1.80            # cross-arm length (MS channel 75x40x6)
V_OUT  = 0.60; V_UP = 0.45            # the two raised V-arms
TOP_UP = 0.75                          # centre pin, above the cross-arm
INS_H  = 0.17                          # pin insulator height
LT_Z   = 5.60            # low-voltage cross-arm

def build_pole_top():
    m = MeshAcc()
    # PCC pole, rectangular and tapering
    m.beam((0,0,-PL_BURY), (0,0,PL_H*0.5), 0.20, 0.14)
    m.beam((0,0,PL_H*0.5), (0,0,PL_H),     0.15, 0.11)
    # horizontal cross-arm
    m.beam((-XA_W/2,0,XA_Z), (XA_W/2,0,XA_Z), 0.075, 0.040)
    # the two V arms rising outward
    m.beam((0,0,XA_Z+0.10), (-V_OUT,0,XA_Z+V_UP), 0.055, 0.040)
    m.beam((0,0,XA_Z+0.10), ( V_OUT,0,XA_Z+V_UP), 0.055, 0.040)
    # diagonal braces from the cross-arm ends up to the V arms
    m.beam((-XA_W/2,0,XA_Z), (-V_OUT,0,XA_Z+V_UP), 0.04)
    m.beam(( XA_W/2,0,XA_Z), ( V_OUT,0,XA_Z+V_UP), 0.04)
    # centre stalk
    m.beam((0,0,XA_Z+0.10), (0,0,XA_Z+TOP_UP), 0.05)
    # three pin insulators - two on the V tips, one on top, higher
    for (x,z) in ((-V_OUT, XA_Z+V_UP), (V_OUT, XA_Z+V_UP), (0.0, XA_Z+TOP_UP)):
        m.tube((x,0,z), (x,0,z+INS_H), 0.075, 8)
        m.tube((x,0,z+INS_H*0.45), (x,0,z+INS_H*0.62), 0.105, 8)   # the skirt
    # LT cross-arm, 4 wires below
    m.beam((-0.55,0,LT_Z), (0.55,0,LT_Z), 0.06, 0.04)
    return m.make("POLE_11kV_TOP", COL["POWER"])

POLETOP = build_pole_top()
POLETOP.location = (0,0,-1000); POLETOP.hide_render=True; POLETOP.hide_viewport=True

HT_ATTACH = [(-V_OUT, XA_Z+V_UP+INS_H), (V_OUT, XA_Z+V_UP+INS_H), (0.0, XA_Z+TOP_UP+INS_H)]
LT_ATTACH = [(-0.45, LT_Z), (-0.15, LT_Z), (0.15, LT_Z), (0.45, LT_Z)]
PL_SPAN = 45.0

poles = []
ch = 15.0
while ch < C_end:
    side = +1 if ch < TOWN0 else (+1 if len(poles)%2==0 else -1)
    off  = 3.9 if ch < A_end else (5.6 if ch < TOWN0 else 6.2)
    p, bb = at(ch); q = p + leftv(bb)*(side*off)
    gz = terrain_z(q.x, q.y)
    o = bpy.data.objects.new(f"POLE_{len(poles):03d}", POLETOP.data)
    COL["POWER"].objects.link(o)
    o.location = (q.x, q.y, gz)
    o.rotation_euler = (0, 0, -bb + random.uniform(-0.035, 0.035))   # nothing is plumb
    poles.append((q, gz, bb, o, ch))
    ch += PL_SPAN*random.uniform(0.88, 1.12)

SAG_HT = 0.45     # 40 m span, sag:span about 1:90
for i in range(len(poles)-1):
    (q0,g0,b0,_,c0) = poles[i]; (q1,g1,b1,_,c1) = poles[i+1]
    L = (q1-q0).length
    for (ax, az) in HT_ATTACH:
        a = q0 + leftv(b0)*ax; b = q1 + leftv(b1)*ax
        wire_curve(f"HT_{i:03d}_{ax:+.2f}", sag_pts((a.x,a.y,g0+az),(b.x,b.y,g1+az),
                   SAG_HT*(L/40.0)**2), 0.006, COL["POWER"])
    if c0 > TOWN0 - 60:                       # LT only where there are customers
        for (ax, az) in LT_ATTACH:
            a = q0 + leftv(b0)*ax; b = q1 + leftv(b1)*ax
            wire_curve(f"LT_{i:03d}_{ax:+.2f}", sag_pts((a.x,a.y,g0+az),(b.x,b.y,g1+az),
                       SAG_HT*1.6*(L/40.0)**2), 0.005, COL["POWER"])

# stay (guy) wires where the line changes direction, 40-60 deg to the pole
nstay=0
for i in range(1,len(poles)-1):
    (q,g,b,o,c) = poles[i]
    db = abs(poles[i+1][2] - poles[i-1][2])
    if db > math.radians(4.0) or i in (1, len(poles)-2):
        ang = math.radians(random.uniform(40,60))
        top = Vector((q.x, q.y, g+XA_Z-0.3))
        run = (g+XA_Z-0.3)/math.tan(ang)
        bear = b + math.pi/2 + (math.pi if i%2 else 0.0)
        gnd = q + dirv(bear)*run
        wire_curve(f"STAY_{nstay:02d}", [(top.x,top.y,top.z),
                   (gnd.x,gnd.y,terrain_z(gnd.x,gnd.y)+0.45)], 0.010, COL["POWER"])
        m2=MeshAcc(); m2.beam((gnd.x,gnd.y,terrain_z(gnd.x,gnd.y)),
                              (gnd.x,gnd.y,terrain_z(gnd.x,gnd.y)+0.45), 0.019)
        m2.make(f"STAYROD_{nstay:02d}", COL["POWER"]); nstay+=1

# ============================================================================
# 3 - THE DISTRIBUTION TRANSFORMER  (where 11 kV becomes 415 V)
# ============================================================================
def build_dtr(q, bb, gz, name):
    m = MeshAcc(); lat = leftv(bb)
    for s in (-1,1):
        c = q + lat*(s*1.25)
        m.beam((c.x,c.y,gz-1.5), (c.x,c.y,gz+6.6), 0.20, 0.15)   # two 8 m PCC poles
    a = q + lat*(-1.25); b = q + lat*(1.25)
    for z in (3.30, 3.55):                                        # the platform
        m.beam((a.x,a.y,gz+z), (b.x,b.y,gz+z), 0.10, 0.08)
    m.beam((q.x,q.y,gz+3.55), (q.x,q.y,gz+4.75), 1.05, 0.85)      # the transformer tank
    m.beam((q.x,q.y,gz+4.75), (q.x,q.y,gz+4.95), 0.55, 0.45)      # conservator
    for s in (-1,0,1):                                            # 3 drop-out fuses
        c = q + lat*(s*0.5)
        m.tube((c.x,c.y,gz+5.6), (c.x,c.y,gz+6.3), 0.05, 6)
    for s in (-1,0,1):                                            # 3 lightning arresters
        c = q + lat*(s*0.5) + dirv(bb)*0.45
        m.tube((c.x,c.y,gz+4.9), (c.x,c.y,gz+5.6), 0.055, 6)
    m.beam((q.x,q.y,gz+2.2), (q.x,q.y,gz+2.9), 0.60, 0.30)        # LT distribution box
    m.beam((q.x,q.y,gz+3.9), (q.x,q.y,gz+4.15), 0.25, 0.02)       # danger plate 250x200
    return m.make(name, COL["POWER"])

for k, cc in enumerate((TOWN0+58.0, TOWN0+205.0, 190.0)):
    p, bb = at(cc); q = p + leftv(bb)*(+1 if k!=2 else -1)*7.4
    build_dtr(q, bb, terrain_z(q.x,q.y), f"DTR_{k:02d}")

# ---- service drops: LT pole -> house wall, sagging low ----
ndrop=0
lt_poles = [pp for pp in poles if pp[4] > TOWN0-60]
for ob in COL["BUILDINGS"].objects:
    if not ob.name.startswith("BLD_F"): continue
    best=None
    for (q,g,b,o,c) in lt_poles:
        d=(Vector((ob.location.x,ob.location.y))-q).length
        if best is None or d<best[0]: best=(d,q,g,b)
    if best and best[0] < 60.0:
        d,q,g,b = best
        a = q + leftv(b)*0.45
        wall = Vector((ob.location.x, ob.location.y, ob.location.z))
        tgt = (wall.x, wall.y, terrain_z(wall.x,wall.y)+4.4)
        wire_curve(f"DROP_{ndrop:03d}", sag_pts((a.x,a.y,g+LT_Z),tgt, 0.85),
                   0.007, COL["POWER"]); ndrop+=1

# ============================================================================
# 4 - BIG SURROUNDING MASSES
# ============================================================================
def kiln(cx, cy, rot):
    m=MeshAcc(); gz=terrain_z(cx,cy)
    m.tube((cx,cy,gz), (cx,cy,gz+30.0), 1.75, 12)                 # 27 m minimum in UP
    m.tube((cx,cy,gz+30.0), (cx,cy,gz+30.4), 1.05, 12)
    ca,sa2 = math.cos(rot), math.sin(rot)
    for (lx,ly,w,l,h) in ((0,0,25.0,100.0,1.9),):                 # the trench yard
        m.beam((cx-ca*l/2, cy-sa2*l/2, gz+h/2), (cx+ca*l/2, cy+sa2*l/2, gz+h/2), w, h)
    for i in range(9):                                            # green-brick stacks
        t=(i-4)*11.0
        bx=cx+ca*t - sa2*22.0; by=cy+sa2*t + ca*22.0
        m.beam((bx,by,gz), (bx,by,gz+2.6), 5.0, 2.6)
    return m.make("BRICK_KILN", COL["SURROUND"])
kiln(-620.0, -430.0, math.radians(18.0))

def telecom(cx, cy, h=40.0):
    m=MeshAcc(); gz=terrain_z(cx,cy)
    legs=[(math.cos(math.radians(a)), math.sin(math.radians(a))) for a in (90,210,330)]
    def hw(z): return 2.6*(1-z/h)+0.55*(z/h)
    zs=[i*2.0 for i in range(int(h/2.0)+1)]
    for (lx,ly) in legs:
        for k in range(len(zs)-1):
            z0,z1=zs[k],zs[k+1]
            m.beam((cx+lx*hw(z0),cy+ly*hw(z0),gz+z0),(cx+lx*hw(z1),cy+ly*hw(z1),gz+z1),0.09)
    for k in range(len(zs)-1):
        z0,z1=zs[k],zs[k+1]
        for i in range(3):
            a=Vector((cx+legs[i][0]*hw(z0), cy+legs[i][1]*hw(z0), gz+z0))
            b=Vector((cx+legs[(i+1)%3][0]*hw(z0), cy+legs[(i+1)%3][1]*hw(z0), gz+z0))
            a1=Vector((cx+legs[i][0]*hw(z1), cy+legs[i][1]*hw(z1), gz+z1))
            m.beam(a,b,0.05); m.beam(a,Vector((b.x,b.y,gz+z1)),0.045); m.beam(b,a1,0.045)
    for k,zz in enumerate((h-2.0, h-5.0, h-8.0)):                 # sector antennas
        for i in range(3):
            a=Vector((cx+legs[i][0]*(hw(zz)+0.9), cy+legs[i][1]*(hw(zz)+0.9), gz+zz))
            m.beam((a.x,a.y,a.z-0.65),(a.x,a.y,a.z+0.65), 0.30, 0.16)
    return m.make("TELECOM_TOWER", COL["SURROUND"])
telecom(TOWN0 and (at(TOWN0+240.0)[0] + leftv(at(TOWN0+240.0)[1])*95.0).x,
        (at(TOWN0+240.0)[0] + leftv(at(TOWN0+240.0)[1])*95.0).y)

def watertank(cx, cy):
    m=MeshAcc(); gz=terrain_z(cx,cy)
    for a in (45,135,225,315):
        lx=math.cos(math.radians(a)); ly=math.sin(math.radians(a))
        m.beam((cx+lx*3.2,cy+ly*3.2,gz),(cx+lx*1.9,cy+ly*1.9,gz+14.0),0.34)
    for z in (5.0, 9.5):
        for i,a in enumerate((45,135,225,315)):
            b_=(i+1)%4; a2=(45,135,225,315)[b_]
            r=3.2-(3.2-1.9)*(z/14.0)
            m.beam((cx+math.cos(math.radians(a))*r, cy+math.sin(math.radians(a))*r, gz+z),
                   (cx+math.cos(math.radians(a2))*r, cy+math.sin(math.radians(a2))*r, gz+z), 0.14)
    m.tube((cx,cy,gz+14.0),(cx,cy,gz+18.6), 3.10, 14)
    m.tube((cx,cy,gz+18.6),(cx,cy,gz+19.4), 2.20, 14)
    return m.make("WATER_TANK", COL["SURROUND"])
_p,_b = at(TOWN0+150.0); _q=_p+leftv(_b)*(-46.0)
watertank(_q.x, _q.y)

bpy.ops.wm.save_as_mainfile(filepath=OUT2)
nv=sum(len(o.data.vertices) for o in bpy.data.objects if o.type=='MESH')
print("\n=============== STAGE 2b - ELECTRICAL SYSTEM ===============")
print(f"132 kV line: {TL_N} towers, {TW_H:.1f} m to peak, base {TW_BASE:.2f} m "
      f"(= H/5), span {TL_SPAN:.0f} m, sag {SAG_TL:.1f} m")
print(f"   arms at {[a[0] for a in ARMS]} m, half-lengths {[a[1] for a in ARMS]} m")
print(f"   shielding angle to top conductor = "
      f"{math.degrees(math.atan(ARMS[2][1]/(TW_H-(ARMS[2][0]-STR_L)))):.1f} deg (spec 20)")
print(f"   insulator strings {DISCS} discs x {DISC_P*1000:.0f} mm = {STR_L*1000:.0f} mm")
lowc = ARMS[0][0]-0.10-STR_L
print(f"   lowest conductor at tower {lowc:.2f} m, mid-span {lowc-SAG_TL:.2f} m "
      f"(IRC/CEA minimum 6.10 m) -> {'PASS' if lowc-SAG_TL>6.1 else 'FAIL'}")
print(f"   right of way {2*ROW_HALF:.0f} m cleared: {cleared} trees removed")
print(f"11 kV feeder: {len(poles)} poles, {PL_LEN:.1f} m PCC ({PL_H:.1f} m above ground), "
      f"span {PL_SPAN:.0f} m, {nstay} stays")
print(f"   candelabra top: cross-arm {XA_W:.2f} m, V tips +/-{V_OUT:.2f} m at +{V_UP:.2f} m, "
      f"centre pin +{TOP_UP:.2f} m")
print(f"   phase gaps: side-to-side {2*V_OUT:.2f} m, side-to-top "
      f"{math.hypot(V_OUT, TOP_UP-V_UP):.2f} m  (rule: >= 1% of span = {PL_SPAN*0.01:.2f} m)")
print(f"3 distribution transformers, {ndrop} service drops to houses")
print(f"brick kiln chimney 30.0 m (UP minimum 27), telecom tower 40 m, water tank 19.4 m")
print(f"objects {len(bpy.data.objects)}   mesh verts {nv}")
print(f"saved -> {OUT2}")
print("===========================================================\n")
