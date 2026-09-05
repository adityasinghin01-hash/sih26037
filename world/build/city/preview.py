# FAST PREVIEW - the working loop. Build, look, fix, move on.
#   blender --background --python build/city/preview.py -- <file.blend> <tag> [cheap|full]
# Appends the real SUN and WORLD from 01_LIGHT.blend so geometry is judged under the real light,
# but leaves CLOUD and AIR out: those are volumetric and cost minutes, geometry costs seconds.
import bpy, sys, os, math, time
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND=a[0]; TAG=a[1] if len(a)>1 else "pv"; MODE=a[2] if len(a)>2 else "cheap"
ONLY=set(a[3].split(",")) if len(a)>3 else None   # render just these shots
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
OUT=f"{REF}/renders/city"; os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc=bpy.context.scene

SUN_ELEV,SUN_AZIM=33.11,246.87
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))

# --- the real sun and sky, matched to component 1
if not any(o.type=='LIGHT' for o in bpy.data.objects):
    sd=bpy.data.lights.new("SUN",'SUN'); sd.angle=math.radians(0.526); sd.energy=5.2
    sun=bpy.data.objects.new("SUN",sd); sc.collection.objects.link(sun)
    sun.rotation_euler=(-aim(SUN_ELEV,SUN_AZIM)).to_track_quat('-Z','Y').to_euler()
w=bpy.data.worlds.new("W"); sc.world=w; w.use_nodes=True
nt=w.node_tree; nt.nodes.clear()
sky=nt.nodes.new("ShaderNodeTexSky"); sky.sky_type='NISHITA'
sky.sun_elevation=math.radians(SUN_ELEV); sky.sun_rotation=math.radians(SUN_AZIM)
sky.air_density=1.7; sky.dust_density=1.0; sky.ozone_density=1.0; sky.sun_disc=False
bg=nt.nodes.new("ShaderNodeBackground"); ow=nt.nodes.new("ShaderNodeOutputWorld")
nt.links.new(sky.outputs["Color"],bg.inputs["Color"]); nt.links.new(bg.outputs["Background"],ow.inputs["Surface"])
sc.view_settings.view_transform='Standard'; sc.view_settings.exposure=-3.06

vl=bpy.context.view_layer
for name in ("CLOUD","AIR"):
    lc=vl.layer_collection.children.get(name)
    if lc: lc.exclude=True          # volumetrics cost MINUTES; geometry costs SECONDS

sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
if MODE=="cheap":
    sc.cycles.samples=16; sc.render.resolution_x=800; sc.render.resolution_y=450
else:
    sc.cycles.samples=64; sc.render.resolution_x=1600; sc.render.resolution_y=900
sc.cycles.use_denoising=True

cd=bpy.data.cameras.new("PV"); cd.clip_start=0.1; cd.clip_end=60000.0
cam=bpy.data.objects.new("PV",cd); sc.collection.objects.link(cam); sc.camera=cam

# angles chosen to SHOW the spec: the hill, the river, the plain, and eye level
SHOTS=(("hill",   (-1050.0,-100.0,240.0),  aim(-12.0,  0.0), 35.0),
       ("river",  ( -400.0, 300.0, 180.0),  aim(-22.0,315.0), 28.0),
       ("plain",  (  200.0,-1200.0, 90.0),  aim( -6.0,  0.0), 24.0),
       ("eye",    ( -700.0, 500.0,  1.3),   aim(  3.0,300.0), 13.0),
       ("wide",   (    0.0,-2600.0,700.0),  aim(-11.0,  0.0), 30.0),
       ("hillclose",(-1050.0, 300.0, 150.0),  aim(-10.0,  0.0), 60.0),
       # the SCREE FANS. Located by MEASUREMENT, not guessed: the biggest concentration of
       # eroder `deposit` low on the slope sits at (-858, 755), azimuth band 315-330 deg.
       ("scree",   ( -675.6, 614.6, 55.0),  aim( -6.0,307.5), 50.0),
       # component 3: the road network, at the five scenario centres (S0 s4)
       ("netwide", (  100.0,-1900.0,900.0),  aim(-22.0,  0.0), 24.0),
       ("chowk",   (  340.0, -830.0,150.0),  aim(-26.0,  0.0), 35.0),
       # ON the real roads, looking ALONG them - the points and headings are measured off
       # matlab_roads.csv at the S2/S3/S4 centres, not guessed. z<=3 is made ground-relative.
       ("s2road",  (  340.1, -579.9,  1.3),  aim( -1.0,232.2), 28.0),
       ("s3galli", ( -154.6, -475.7,  1.3),  aim( -1.0,118.6), 24.0),
       ("s4trunk", (  140.6, -818.6,  1.3),  aim( -1.0,168.7), 35.0))
dg=bpy.context.evaluated_depsgraph_get()
def ground_at(x,y):
    hit,loc_,_,_,_,_ = sc.ray_cast(dg, Vector((x,y,3000.0)), Vector((0,0,-1)))
    return loc_.z if hit else 0.0
for nm,loc,fwd,lens in SHOTS:
    if ONLY and nm not in ONLY: continue
    x,y,z = loc
    if z <= 3.0:
        # ANY eye-level shot is GROUND-RELATIVE. Only "eye" was, so the galli camera at an
        # absolute z=1.3 sat under the ground and rendered a grey wall.
        z = ground_at(x,y)+1.30      # 1.30 m ABOVE THE GROUND, not absolute
    cam.location=(x,y,z); cam.data.lens=lens
    cam.rotation_euler=fwd.to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=os.path.join(OUT,f"{TAG}_{nm}")
    t=time.time(); bpy.ops.render.render(write_still=True)
    print(f"  {TAG}_{nm}: {time.time()-t:.1f}s", flush=True)
print("PREVIEW DONE")
