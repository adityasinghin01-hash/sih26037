# SIH26037 - STAGE 5 - CITY BLOCKOUT on the REAL Najibabad network
#   /Applications/Blender.app/Contents/MacOS/Blender --background --python city_blockout.py
import bpy, csv, json, math, os, random
from mathutils import Vector, noise as mnoise
random.seed(26037)
R_=math.radians
MAP="/Users/aditya/Desktop/SIH26037-Reference/map"
OUT="/Users/aditya/Desktop/SIH26037-Reference/blend/CITY_blockout.blend"
OFFSET=(35.0,-100.0)          # MATLAB frame -> OSM metric frame (measured)
BOX=1000.0                     # our world box half-size
GEXT=2000.0                    # ground extends 1 km past the box on every side

bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene
sc.unit_settings.system='METRIC'
COL={}
for n in ("TERRAIN","ROAD","RIVER","BUILDINGS","ZONES","CAMERA"):
    c=bpy.data.collections.new(n); sc.collection.children.link(c); COL[n]=c
def mesh_obj(name,v,f,col):
    me=bpy.data.meshes.new(name); me.from_pydata(v,[],f); me.validate(); me.update()
    o=bpy.data.objects.new(name,me); col.objects.link(o); return o

# ---------------------------------------------------------------- 1 the network
mr={}
for r in csv.reader(open(os.path.join(MAP,"matlab_roads.csv"))):
    mr.setdefault(int(float(r[2])),[]).append((float(r[0])+OFFSET[0], float(r[1])+OFFSET[1]))
D=json.load(open(os.path.join(MAP,"najibabad_metres.json")))
WIDTH={"trunk":14.0,"trunk_link":7.0,"primary":10.5,"secondary":7.0,"tertiary":7.0,
       "unclassified":5.5,"residential":4.5,"living_street":3.2,"service":3.0,
       "track":3.0,"path":1.5}
# spatial hash of the OSM segments, for classification and for the corridor test
CELL=50.0
grid={}
for w in D["roads"]:
    for i in range(len(w["pts"])-1):
        a=tuple(w["pts"][i]); b=tuple(w["pts"][i+1])
        seg=(a,b,w["class"],bool(w["bridge"]))
        x0,x1=sorted((a[0],b[0])); y0,y1=sorted((a[1],b[1]))
        for cx in range(int(x0//CELL),int(x1//CELL)+1):
            for cy in range(int(y0//CELL),int(y1//CELL)+1):
                grid.setdefault((cx,cy),[]).append(seg)
def near_segs(p,rad=1):
    cx,cy=int(p[0]//CELL),int(p[1]//CELL); out=[]
    for i in range(-rad,rad+1):
        for j in range(-rad,rad+1):
            out+=grid.get((cx+i,cy+j),[])
    return out
def seg_d(p,a,b):
    ax,ay=a; bx,by=b; dx,dy=bx-ax,by-ay; L2=dx*dx+dy*dy
    if L2==0: return math.dist(p,a)
    t=max(0.0,min(1.0,((p[0]-ax)*dx+(p[1]-ay)*dy)/L2))
    return math.dist(p,(ax+t*dx,ay+t*dy))
def classify(p):
    best=(1e9,"residential",False)
    for a,b,c,br in near_segs(p,2):
        d=seg_d(p,a,b)
        if d<best[0]: best=(d,c,br)
    return best[1],best[2]

# ---------------------------------------------------------------- 2 the land
HILL_C=Vector((-690.0,980.0)); HILL_RX=250.0; HILL_RY=175.0
HILL_ROT=R_(-38.0); HILL_H=170.0
RANGE_Y=1900.0; RANGE_H=340.0; RANGE_HW=640.0
RIVER=[tuple(p) for p in D["water"][0]["pts"]]
rgrid={}
for i in range(len(RIVER)-1):
    a,b=RIVER[i],RIVER[i+1]
    x0,x1=sorted((a[0],b[0])); y0,y1=sorted((a[1],b[1]))
    for cx in range(int(x0//CELL),int(x1//CELL)+1):
        for cy in range(int(y0//CELL),int(y1//CELL)+1):
            rgrid.setdefault((cx,cy),[]).append((a,b))
def river_dist(p):
    cx,cy=int(p[0]//CELL),int(p[1]//CELL); best=1e9
    for i in range(-3,4):
        for j in range(-3,4):
            for a,b in rgrid.get((cx+i,cy+j),()): best=min(best,seg_d(p,a,b))
    return best
def smooth(e0,e1,x):
    t=min(1.0,max(0.0,(x-e0)/(e1-e0))); return t*t*(3-2*t)
def rmf(x,y,s,seed,oc=6):
    return mnoise.ridged_multi_fractal(Vector((x*s,y*s,seed)),1.0,2.0,oc,1.0,2.0)
def land(x,y):
    z=-(y/2000.0)*2.5
    z+=1.10*mnoise.noise(Vector((x*0.0016,y*0.0016,0.0)))
    z+=0.45*mnoise.noise(Vector((x*0.006,y*0.006,7.0)))
    z+=0.14*mnoise.noise(Vector((x*0.022,y*0.022,21.0)))
    ch=mnoise.noise(Vector((x*0.0011,y*0.0011,61.0)))       # old river channels
    z-=0.9*math.exp(-((ch-0.18)**2)/0.0016)
    bnd=mnoise.noise(Vector((x*0.0135,y*0.0135,71.0)))      # field bunds
    z+=0.34*(round(bnd*3.0)/3.0)
    dx=x-HILL_C.x; dy=y-HILL_C.y
    ca,sa=math.cos(HILL_ROT),math.sin(HILL_ROT)
    u=(dx*ca+dy*sa)/HILL_RX; v=(-dx*sa+dy*ca)/HILL_RY
    r=math.hypot(u,v)
    if r<1.0:
        m=smooth(0.0,1.0,1.0-r)
        z+=HILL_H*(m**1.15)*(0.22+0.62*rmf(x,y,0.0090,3.0,7)+0.30*math.exp(-(v*v)/0.55))
        g=abs(mnoise.turbulence(Vector((x*0.019,y*0.019,5.0)),6,False))
        z-=HILL_H*0.38*m*(g**1.45)                          # the gully network
    crest=RANGE_Y+130.0*mnoise.noise(Vector((x*0.0012,0.0,31.0)))
    hw=RANGE_HW*(0.75+0.35*mnoise.noise(Vector((x*0.0018,0.0,41.0))))
    if abs(y-crest)<hw:
        f=smooth(0.0,1.0,1.0-abs(y-crest)/hw)
        h=RANGE_H*(0.68+0.32*mnoise.noise(Vector((x*0.0016,0.0,51.0))))
        z+=h*(f**1.7)*(0.55+0.45*rmf(x,y,0.0030,11.0))
    return z
def river_cut(x,y):
    d=river_dist((x,y))
    if d>=42.0: return 0.0
    if d<=28.0: return -5.0+(2.0/28.0)*d
    return -3.0+((d-28.0)/14.0)*3.0
def terrain(x,y): return land(x,y)+river_cut(x,y)

# road level = terrain, smoothed along each road
print("building road ribbons ...")
def ribbon(name,pts,w,dz,col):
    v=[];f=[]
    for i,p in enumerate(pts):
        if i==0: d=Vector(pts[1])-Vector(pts[0])
        elif i==len(pts)-1: d=Vector(pts[-1])-Vector(pts[-2])
        else: d=Vector(pts[i+1])-Vector(pts[i-1])
        if d.length<1e-6: d=Vector((1,0))
        d.normalize(); n=Vector((-d.y,d.x))
        z=p[2]+dz
        a=Vector((p[0],p[1]))+n*(w/2); b=Vector((p[0],p[1]))-n*(w/2)
        v.append((a.x,a.y,z)); v.append((b.x,b.y,z))
    for k in range(len(pts)-1):
        i=k*2; f.append((i,i+1,i+3,i+2))
    return mesh_obj(name,v,f,col)

def clip(pts):
    out=[];run=[]
    for p in pts:
        if abs(p[0])<=BOX and abs(p[1])<=BOX: run.append(p)
        else:
            if len(run)>1: out.append(run)
            run=[]
    if len(run)>1: out.append(run)
    return out

roadpts=[]      # (x,y,z) samples for the corridor flattening
built=0; total=0.0; byclass={}
for k,pts in mr.items():
    for run in clip(pts):
        cls,br=classify(run[len(run)//2])
        w=WIDTH.get(cls,4.5)
        # resample to 4 m and give it a smoothed height
        rs=[run[0]]
        for i in range(1,len(run)):
            while math.dist(rs[-1],run[i])>4.0:
                a=Vector(rs[-1]); b=Vector(run[i]); t=4.0/(b-a).length
                rs.append(tuple(a+(b-a)*t))
            rs.append(run[i])
        zs=[terrain(p[0],p[1]) for p in rs]
        for _ in range(24):
            for i in range(1,len(zs)-1): zs[i]=(zs[i-1]+2*zs[i]+zs[i+1])*0.25
        if br: 
            m=sum(zs)/len(zs)
            zs=[m+2.4 for _ in zs]
        p3=[(rs[i][0],rs[i][1],zs[i]) for i in range(len(rs))]
        ribbon(f"RD_{k:04d}_{cls}",p3,w,0.0,COL["ROAD"])
        roadpts+= [(p[0],p[1],p[2],w) for p in p3]
        L=sum(math.dist(rs[i],rs[i+1]) for i in range(len(rs)-1))
        total+=L; byclass[cls]=byclass.get(cls,0)+L; built+=1
# spatial hash of road points for the corridor test
pg={}
for (x,y,z,w) in roadpts:
    pg.setdefault((int(x//CELL),int(y//CELL)),[]).append((x,y,z,w))
def corridor(x,y):
    cx,cy=int(x//CELL),int(y//CELL); best=(1e9,0.0,4.5)
    for i in range(-2,3):
        for j in range(-2,3):
            for (px,py,pz,pw) in pg.get((cx+i,cy+j),()):
                d=(px-x)**2+(py-y)**2
                if d<best[0]: best=(d,pz,pw)
    return math.sqrt(best[0]),best[1],best[2]

# ---------------------------------------------------------------- 3 ground
print("building ground ...")
N=500; STEP=2*GEXT/N
verts=[];faces=[]
for j in range(N+1):
    for i in range(N+1):
        x=-GEXT+i*STEP; y=-GEXT+j*STEP
        z=terrain(x,y)
        if abs(x)<BOX+120 and abs(y)<BOX+120:
            d,rz,rw=corridor(x,y)
            if d<70.0 and river_dist((x,y))>45.0:
                wgt=1.0-smooth(rw*0.6+3.0,70.0,d)
                z=z*(1-wgt)+(rz-0.30)*wgt
        verts.append((x,y,z))
for j in range(N):
    for i in range(N):
        a=j*(N+1)+i; faces.append((a,a+1,a+N+2,a+N+1))
mesh_obj("GROUND",verts,faces,COL["TERRAIN"])

# river surface
rv=[p for p in RIVER if abs(p[0])<=BOX+200 and abs(p[1])<=BOX+200]
if len(rv)>1:
    wz=min(land(p[0],p[1]) for p in rv)-3.8
    ribbon("RIVER_SURFACE",[(p[0],p[1],wz) for p in rv],34.0,0.0,COL["RIVER"])

# ---------------------------------------------------------------- 4 the five zones
ZONES=[("Z1_CATTLE",-280,450,205),("Z2_CHOWK",340,-580,165),("Z3_GALLI",-155,-476,185),
       ("Z4_MERGE",130,-800,235),("Z5_MOUNTAIN",-690,760,205)]
nb=0
for (nm,cx,cy,rad) in ZONES:
    bpy.ops.mesh.primitive_circle_add(vertices=48,radius=rad,fill_type='NOTHING',
        location=(cx,cy,terrain(cx,cy)+0.5))
    o=bpy.context.active_object; o.name=nm
    for c in o.users_collection: c.objects.unlink(o)
    COL["ZONES"].objects.link(o)
    # building masses along the roads inside the zone
    cand=[p for p in roadpts if math.dist((p[0],p[1]),(cx,cy))<rad and p[3]>=3.0]
    random.shuffle(cand)
    placed=[]
    for (px,py,pz,pw) in cand:
        if nb>1000: break
        if any(math.dist((px,py),q)<9.0 for q in placed): continue
        d,rz,rw=corridor(px,py)
        for side in (-1,1):
            # find the road direction from two nearby samples
            nb2=[q for q in cand if 3.0<math.dist((px,py),(q[0],q[1]))<9.0]
            if not nb2: continue
            q=nb2[0]; dv=Vector((q[0]-px,q[1]-py)).normalized()
            nv=Vector((-dv.y,dv.x))
            off=rw/2+random.uniform(3.0,7.0)
            bx=px+nv.x*side*off; by=py+nv.y*side*off
            if math.dist((bx,by),(cx,cy))>rad: continue
            st=random.choice([1,1,2,2,2,3])
            h=st*3.15+1.0
            wd=random.uniform(2.9,9.5); dp=random.uniform(6.0,11.0)
            gz=max(rz-0.3, terrain(bx,by))
            bpy.ops.mesh.primitive_cube_add(size=1.0,location=(bx,by,gz+h/2))
            b=bpy.context.active_object; b.name=f"BLD_{nb:04d}"
            b.scale=(wd,dp,h); b.rotation_euler[2]=math.atan2(dv.y,dv.x)+random.uniform(-.04,.04)
            for c in b.users_collection: c.objects.unlink(b)
            COL["BUILDINGS"].objects.link(b); nb+=1
        placed.append((px,py))

# ---------------------------------------------------------------- 5 cameras
def cam(name,loc,tgt,lens):
    c=bpy.data.cameras.new(name); c.lens=lens; c.sensor_width=36.0
    c.clip_start=0.1; c.clip_end=9000.0
    o=bpy.data.objects.new(name,c); COL["CAMERA"].objects.link(o)
    o.location=loc
    d=Vector(tgt)-Vector(loc)
    o.rotation_euler=(math.acos(d.z/d.length),0.0,math.atan2(d.y,d.x)-math.pi/2)
    return o
for (nm,cx,cy,rad) in ZONES:
    z=terrain(cx,cy)
    cam(f"CAM_{nm}",(cx-rad*1.5,cy-rad*1.5,z+rad*0.55),(cx,cy,z+8),34.0)
cam("CAM_CITY",(-1500,-1900,700),(0,0,60),26.0)
sc.render.resolution_x=1920; sc.render.resolution_y=1080

os.makedirs(os.path.dirname(OUT),exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
nv=sum(len(o.data.vertices) for o in bpy.data.objects if o.type=='MESH')
print("\n============ CITY BLOCKOUT ============")
print(f"road pieces {built}   road inside the box {total/1000:.2f} km")
for c,L in sorted(byclass.items(),key=lambda x:-x[1]):
    print(f"   {c:14s} {L/1000:6.2f} km at {WIDTH.get(c,4.5):4.1f} m")
print(f"building masses {nb}")
print(f"hill {HILL_H:.0f} m at ({HILL_C.x:.0f},{HILL_C.y:.0f}), base {2*HILL_RX:.0f} x {2*HILL_RY:.0f} m")
print(f"ground {2*GEXT:.0f} x {2*GEXT:.0f} m, {N}x{N} cells = {STEP:.1f} m")
print(f"objects {len(bpy.data.objects)}   verts {nv}")
print(f"saved -> {OUT}")
print("=======================================\n")
