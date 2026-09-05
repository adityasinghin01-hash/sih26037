# Real Najibabad road network -> Blender, built from MATLAB's OWN exported coordinates
# so the road the AI drives and the road we render cannot drift apart.
import bpy, csv, json, math, os
from mathutils import Vector
OFFSET = (35.0, -100.0)     # measured: MATLAB frame -> OSM metric frame
REF = os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
MAP = f"{REF}/map"
OUT = f"{REF}/blend/S1_realnetwork.blend"
BOX = 1000.0                # our 2 km world box, centred on the town

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
col = bpy.data.collections.new("NETWORK"); sc.collection.children.link(col)

# MATLAB's roads, moved into the OSM metric frame
mr = {}
for r in csv.reader(open(os.path.join(MAP,"matlab_roads.csv"))):
    k = int(float(r[2]))
    mr.setdefault(k, []).append((float(r[0])+OFFSET[0], float(r[1])+OFFSET[1]))

# OSM classes, to give every road its real width
d = json.load(open(os.path.join(MAP,"najibabad_metres.json")))
segs = []
for w in d["roads"]:
    for i in range(len(w["pts"])-1):
        segs.append((tuple(w["pts"][i]), tuple(w["pts"][i+1]), w["class"], w["bridge"]))
WIDTH = {"trunk":14.0, "trunk_link":7.0, "primary":10.5, "secondary":7.0,
         "tertiary":7.0, "unclassified":5.5, "residential":4.5,
         "living_street":3.2, "service":3.0, "track":3.0, "path":1.5}
def seg_d(p,a,b):
    ax,ay=a; bx,by=b; px,py=p
    dx,dy=bx-ax,by-ay; L2=dx*dx+dy*dy
    if L2==0: return math.dist(p,a)
    t=max(0.0,min(1.0,((px-ax)*dx+(py-ay)*dy)/L2))
    return math.dist(p,(ax+t*dx,ay+t*dy))
def classify(pts):
    p = pts[len(pts)//2]
    best=(1e9,"residential",False)
    for a,b,c,br in segs:
        dd=seg_d(p,a,b)
        if dd<best[0]: best=(dd,c,br)
    return best[1], best[2]

def ribbon(name, pts, w, z=0.0):
    vs=[]; fs=[]
    for i,p in enumerate(pts):
        if i==0: dvec=Vector(pts[1])-Vector(pts[0])
        elif i==len(pts)-1: dvec=Vector(pts[-1])-Vector(pts[-2])
        else: dvec=Vector(pts[i+1])-Vector(pts[i-1])
        if dvec.length<1e-6: dvec=Vector((1,0))
        dvec.normalize(); n=Vector((-dvec.y, dvec.x))
        a=Vector(p)+n*(w/2); b=Vector(p)-n*(w/2)
        vs.append((a.x,a.y,z)); vs.append((b.x,b.y,z))
    for k in range(len(pts)-1):
        i=k*2; fs.append((i,i+1,i+3,i+2))
    me=bpy.data.meshes.new(name); me.from_pydata(vs,[],fs); me.validate(); me.update()
    o=bpy.data.objects.new(name,me); col.objects.link(o); return o

def clip(pts):
    """keep only the parts of a road inside the 2 km box"""
    out=[]; run=[]
    for p in pts:
        if abs(p[0])<=BOX and abs(p[1])<=BOX: run.append(p)
        else:
            if len(run)>1: out.append(run)
            run=[]
    if len(run)>1: out.append(run)
    return out

built=0; total=0.0; byclass={}
for k, pts in mr.items():
    for run in clip(pts):
        cls, br = classify(run)
        w = WIDTH.get(cls, 4.5)
        ribbon(f"RD_{k:04d}_{cls}", run, w, 0.30 if br else 0.0)
        L=sum(math.dist(run[i],run[i+1]) for i in range(len(run)-1))
        total+=L; byclass[cls]=byclass.get(cls,0)+L; built+=1
# the river
for i,wobj in enumerate(d["water"]):
    for run in clip([tuple(p) for p in wobj["pts"]]):
        ribbon(f"RIVER_{i:02d}", run, 45.0, -3.5)

cam=bpy.data.cameras.new("PLAN"); cam.type='ORTHO'; cam.ortho_scale=2100.0
co=bpy.data.objects.new("PLAN",cam); sc.collection.objects.link(co)
co.location=(0,0,900); co.rotation_euler=(0,0,0); sc.camera=co
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("\n============ REAL NETWORK IN BLENDER ============")
print(f"road pieces inside the 2 km box: {built}")
print(f"total road inside the box: {total/1000:.2f} km")
for c,L in sorted(byclass.items(), key=lambda x:-x[1]):
    print(f"   {c:15s} {L/1000:6.2f} km   built at {WIDTH.get(c,4.5):4.1f} m wide")
print(f"objects {len(bpy.data.objects)}")
print(f"saved -> {OUT}")
print("================================================\n")
