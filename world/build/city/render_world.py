# RTX JUDGEMENT RENDER - 04_WORLD.blend WITH the clouds and haze ON. This is the one render
# preview.py cannot do (it excludes CLOUD/AIR on purpose, because on the M1 a cloud look costs
# 20 min). On nvidiapc1 with OptiX + the distance-banded voxels it is minutes, and this is where
# L1-L4 (voxel-coarsen / blue holes / cauliflower / halation), the haze, and the
# cloud-darkening-at-the-horizon finding are actually judged.
#   blender -b blend/04_WORLD.blend --python build/city/render_world.py -- [shot,shot] [samples]
# Renders the named INSPECT cameras baked into the file (CAM_6_WIDE, CAM_1_HILL_FROM_S, ...).
import bpy, sys, os, time
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
WANT=set(a[0].split(",")) if a and a[0] else {"CAM_6_WIDE","CAM_1_HILL_FROM_S","CAM_3_RIVER","CAM_DASH"}
SAMPLES=int(a[1]) if len(a)>1 else 96
REF=os.environ.get("SIH_REF","/Users/aditya/Desktop/SIH26037-Reference")
OUT=f"{REF}/renders/city"; os.makedirs(OUT,exist_ok=True)
sc=bpy.context.scene
sc.render.engine='CYCLES'
# OptiX if the box has it (nvidiapc1 does), else CUDA, else CPU - never silently fall back to a
# 20-minute CPU volume render without saying so.
prefs=bpy.context.preferences.addons['cycles'].preferences
picked="CPU"
for dt in ('OPTIX','CUDA'):
    try:
        prefs.compute_device_type=dt
        prefs.get_devices()
        for d in prefs.devices: d.use = (d.type==dt)
        if any(d.type==dt for d in prefs.devices): sc.cycles.device='GPU'; picked=dt; break
    except Exception: pass
print(f"  render device: {picked}")
sc.cycles.samples=SAMPLES
sc.cycles.use_denoising=True
sc.cycles.volume_bounces=8
sc.cycles.volume_max_steps=24
# D2 adaptive subdivision is for the 2 m circle crops, NOT for a 2 km wide shot: at this range a
# dicing_rate of 2 would tessellate the whole visible plain into millions of micropolygons for
# 8 cm of relief nobody can see. Crank it coarse here so the displacement effectively sleeps.
for _o in bpy.data.objects:
    if _o.name=='TERRAIN' and hasattr(_o.cycles,'dicing_rate'):
        _o.cycles.dicing_rate=16.0
sc.render.resolution_x=1600; sc.render.resolution_y=900; sc.render.resolution_percentage=100
sc.view_settings.view_transform='Standard'; sc.view_settings.exposure=-3.06
cams=[o for o in bpy.data.objects if o.type=='CAMERA' and o.name in WANT]
if not cams:
    print(f"  no cameras matched {WANT}; available: {[o.name for o in bpy.data.objects if o.type=='CAMERA']}")
for c in sorted(cams,key=lambda o:o.name):
    sc.camera=c
    sc.render.filepath=os.path.join(OUT,f"w_{c.name}")
    t=time.time(); bpy.ops.render.render(write_still=True)
    print(f"  {c.name}: {time.time()-t:.1f}s -> renders/city/w_{c.name}.png", flush=True)
print("RENDER_WORLD DONE")
