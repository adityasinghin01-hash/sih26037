# Put NAMED INSPECTION CAMERAS into a build so Aditya can screenshot exactly the angles I need.
# Solid-mode viewport is rasterised, not raytraced, so this costs him nothing - unlike a render.
#   blender --background --python build/city/02b_land_cameras.py -- <file.blend>
import bpy, sys, os, math
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
F=a[0] if a else f"{REF}/blend/03_ROADS.blend"
bpy.ops.wm.open_mainfile(filepath=F)
sc=bpy.context.scene
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))
col=bpy.data.collections.get("INSPECT") or bpy.data.collections.new("INSPECT")
if "INSPECT" not in {c.name for c in sc.collection.children}: sc.collection.children.link(col)
for o in list(col.objects): bpy.data.objects.remove(o, do_unlink=True)

# name, location, (elev,azim) it looks along, lens, WHAT I AM CHECKING
SHOTS=(
 ("CAM_1_HILL_FROM_S",  (-1050.0,  -50.0, 210.0), (-14.0,   0.0), 40.0,
  "the hill's silhouette and whether the GULLIES read at all"),
 ("CAM_2_HILL_CLOSE",   (-1050.0, 480.0, 120.0), (-10.0, 180.0), 55.0,
  "gully depth and branching on the north flank, and the rim blend into the plain"),
 ("CAM_3_RIVER",        ( -500.0, 250.0, 120.0), (-24.0, 300.0), 30.0,
  "the Malin channel, the waterline, and whether banks and bars fall out of the terrain"),
 ("CAM_4_PLAIN",        (  300.0,-1100.0,  70.0), ( -7.0,   0.0), 26.0,
  "the three undulation scales and the field bunds - is it NEVER FLAT?"),
 ("CAM_5_EYE_LEVEL",    ( -700.0, 450.0,   1.3), (  2.5, 300.0), 13.0,
  "1.30 m driver's eye - the only height that actually matters for the film"),
 ("CAM_6_WIDE",         (    0.0,-2500.0, 620.0), (-12.0,   0.0), 28.0,
  "the whole 4 km: hill, river, plain, distant range, and the south fall"),
 ("CAM_7_RANGE",        ( -200.0,  600.0, 260.0), ( -3.0,   0.0), 50.0,
  "the distant range reading as a pale silhouette behind the hill"),
 # --- component 3. Points and headings measured off matlab_roads.csv, not guessed.
 ("CAM_8_NETWORK",     (  100.0,-1900.0, 900.0), (-22.0,   0.0), 24.0,
  "the whole 213-road network from above - does the town plan read?"),
 ("CAM_9_CHOWK",       (  340.0, -830.0, 150.0), (-26.0,   0.0), 35.0,
  "the S2 gyratory area and the NH534 trunk road"),
 ("CAM_DASH",          (  140.6, -818.6,   1.3), ( -1.0, 168.7), 35.0,
  "DRIVER'S EYE on the real NH534 trunk - the height the film is shot at"),
 ("CAM_11_GALLI",      ( -154.6, -475.7,   1.3), ( -1.0, 118.6), 24.0,
  "the S3 residential galli at eye level"),
)
dg=bpy.context.evaluated_depsgraph_get()
def ground_at(x,y):
    hit,l,_,_,_,_=sc.ray_cast(dg,Vector((x,y,3000.0)),Vector((0,0,-1)))
    return l.z if hit else 0.0
for nm,loc,(el,az),lens,why in SHOTS:
    cd=bpy.data.cameras.new(nm); cd.lens=lens; cd.clip_start=0.1; cd.clip_end=60000.0
    c=bpy.data.objects.new(nm,cd); col.objects.link(c)
    # any camera under 3 m is EYE LEVEL and must be ground-relative, or it renders a grey wall
    if loc[2] <= 3.0: loc=(loc[0],loc[1],ground_at(loc[0],loc[1])+1.30)
    c.location=loc
    c.rotation_euler=aim(el,az).to_track_quat('-Z','Y').to_euler()
    print(f"  {nm:20s} lens {lens:4.0f}mm   -> {why}")
sc.camera=bpy.data.objects["CAM_DASH"]
for scr in bpy.data.screens:
    for ar in scr.areas:
        if ar.type=='VIEW_3D':
            ar.spaces[0].clip_start=0.10; ar.spaces[0].clip_end=60000.0
bpy.ops.wm.save_mainfile(filepath=F)
print(f"\n{len(SHOTS)} inspection cameras saved into {F}")
