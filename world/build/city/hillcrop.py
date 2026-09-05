# HILL CROP JUDGE - PLAN s10 Phase 2 item 9's judging method: a small crop, at FULL resolution
# and FULL samples, on the hill's close lit flank (same framing as the already-verified "scree"
# camera), where the fine subdivision+displacement detail actually needs to read.
#   blender --background --python build/city/hillcrop.py -- <blend> <tag> [samples]
# Runs on the RTX per PLAN s11 - 128+ samples at full res is too slow to iterate on the M1.
import bpy, sys, os, math, time
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND=a[0]; TAG=a[1] if len(a)>1 else "hillcrop"; SAMPLES=int(a[2]) if len(a)>2 else 128
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
OUT=f"{REF}/renders/city"; os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc=bpy.context.scene

SUN_ELEV,SUN_AZIM=33.11,246.87
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))
if not any(o.type=='LIGHT' for o in bpy.data.objects):
    sd=bpy.data.lights.new("SUN",'SUN'); sd.angle=math.radians(0.526); sd.energy=5.2
    sun=bpy.data.objects.new("SUN",sd); sc.collection.objects.link(sun)
    sun.rotation_euler=(-aim(SUN_ELEV,SUN_AZIM)).to_track_quat('-Z','Y').to_euler()
if sc.world is None or not sc.world.use_nodes:
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
    if lc: lc.exclude=True

sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
sc.cycles.samples=SAMPLES
sc.render.resolution_x=1920; sc.render.resolution_y=1080
sc.cycles.use_denoising=True

cd=bpy.data.cameras.new("HC"); cd.clip_start=0.1; cd.clip_end=60000.0; cd.lens=50.0
cam=bpy.data.objects.new("HC",cd); sc.collection.objects.link(cam); sc.camera=cam
# SAME camera as the already-verified "scree" shot - close on the hill's lit flank.
loc=(-675.6,614.6,55.0)
cam.location=loc; cam.data.lens=50.0
cam.rotation_euler=aim(-6.0,307.5).to_track_quat('-Z','Y').to_euler()

sc.render.use_border=True; sc.render.use_crop_to_border=True
sc.render.border_min_x=0.30; sc.render.border_max_x=0.70
sc.render.border_min_y=0.25; sc.render.border_max_y=0.65
sc.render.filepath=os.path.join(OUT,f"{TAG}_hillcrop")
t=time.time(); bpy.ops.render.render(write_still=True)
dt=time.time()-t

# --- MEASURE, don't eyeball: the crop must show real local variance, not a smooth blur -
# the whole point of the fine-detail step. Same ground-biased-crop lesson as zoom_test.py.
import numpy as np
img=bpy.data.images.load(sc.render.filepath+".png")
w_,h_=img.size
px=np.empty(len(img.pixels),dtype=np.float32); img.pixels.foreach_get(px)
px=px.reshape(h_,w_,4)
lum=0.2126*px[...,0]+0.7152*px[...,1]+0.0722*px[...,2]
std=float(lum.std())
print(f"hill crop: {w_}x{h_}, {SAMPLES} samples, {dt:.1f}s, luminance std {std:.4f} (want >0.02)")
print(f"saved: {sc.render.filepath}.png")
