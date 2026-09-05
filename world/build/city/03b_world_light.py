# Put COMPONENT 1's real sun and sky permanently INTO a world file, so it can be opened and
# looked at without preview.py adding them at render time.
#   blender --background --python build/city/03b_world_light.py -- <file.blend>
# CLOUDS AND HAZE ARE DELIBERATELY LEFT OUT. The three-population cloud field peaked at 11.97 GB
# on this 8 GB machine and swapped (433 s -> 1335 s per frame). Geometry is seconds; volumetrics
# are minutes. A viewport carrying them would hang, and that is the one thing this project has
# actually proved about the hardware.
import bpy, sys, os, math
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
F=a[0] if a else f"{REF}/blend/03_ROADS.blend"
SUN_ELEV,SUN_AZIM=33.11,246.87          # 25 Sep 2026, 15:30 IST, 29.6118 N 78.3421 E
bpy.ops.wm.open_mainfile(filepath=F)
sc=bpy.context.scene
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))
for o in [o for o in bpy.data.objects if o.type=='LIGHT']:
    bpy.data.objects.remove(o, do_unlink=True)
sd=bpy.data.lights.new("SUN",'SUN'); sd.angle=math.radians(0.526); sd.energy=5.2
sun=bpy.data.objects.new("SUN",sd); sc.collection.objects.link(sun)
sun.rotation_euler=(-aim(SUN_ELEV,SUN_AZIM)).to_track_quat('-Z','Y').to_euler()
w=bpy.data.worlds.new("SKY"); sc.world=w; w.use_nodes=True
nt=w.node_tree; nt.nodes.clear()
sky=nt.nodes.new("ShaderNodeTexSky"); sky.sky_type='NISHITA'
sky.sun_elevation=math.radians(SUN_ELEV); sky.sun_rotation=math.radians(SUN_AZIM)
sky.air_density=1.7; sky.dust_density=1.0; sky.ozone_density=1.0; sky.sun_disc=False
bg=nt.nodes.new("ShaderNodeBackground"); ow=nt.nodes.new("ShaderNodeOutputWorld")
nt.links.new(sky.outputs["Color"],bg.inputs["Color"]); nt.links.new(bg.outputs["Background"],ow.inputs["Surface"])
sc.view_settings.view_transform='Standard'      # AgX invalidates any match to a photograph
sc.view_settings.exposure=-3.06
sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
sc.cycles.samples=64
sc.cycles.preview_samples=16                    # the viewport must stay usable on 8 GB
sc.cycles.use_preview_denoising=True
sc.cycles.preview_denoising_start_sample=1
sc.render.resolution_x=1600; sc.render.resolution_y=900
# REF-05 s7 trap 9: clip_end persists in the file; shading mode does not.
for scr in bpy.data.screens:
    for ar in scr.areas:
        if ar.type=='VIEW_3D':
            ar.spaces[0].clip_start=0.10; ar.spaces[0].clip_end=60000.0
print(f"sun elev {SUN_ELEV} azim {SUN_AZIM}, Nishita 1.7/1.0/1.0, Standard, exposure -3.06")
print(f"{len([o for o in bpy.data.objects if o.type=='CAMERA'])} cameras, "
      f"{len([o for o in bpy.data.objects if o.type=='MESH'])} meshes")
bpy.ops.wm.save_mainfile(filepath=F)
print(f"saved: {F}")
