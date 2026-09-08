# PASS RENDER - render one .blend as several passes BY CONTENT ONLY (never by tile or frame -
# both load the whole scene into VRAM anyway, PLAN s11). Rule 7: each pass is a REAL separate
# render - its own collections visible, every other top-level collection EXCLUDED (the same
# mechanism preview.py already uses for CLOUD/AIR) - saved as an RGBA PNG (film_transparent) so
# composite.py can lay them over one another. Also writes ONE reference render with every listed
# collection visible together, opaque, so the join can be MEASURED, not assumed.
#   blender --background --python build/city/pass_render.py -- <blend> <tag> <shot> \
#       <passname>=<coll,coll,...> [<passname>=<coll,coll,...> ...]
# NAMED "pass_render", not "chunk_render": .gitignore's `chunk_*` rule (meant for chunked render
# OUTPUT files) was silently swallowing a script called chunk_render.py - found only because git
# status didn't list it. STEP 0 ITEM 3. The price PLAN s11 names: lighting, shadows and
# reflections do not cross passes - this script + composite.py is how that price gets a number.
import bpy, sys, os, math, time
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND=a[0]; TAG=a[1]; SHOT=a[2]; PASSDEFS=a[3:]
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
OUT=f"{REF}/renders/city"; os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc=bpy.context.scene

SUN_ELEV,SUN_AZIM=33.11,246.87
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))

# --- the real sun and sky, matched to component 1 - same block as preview.py, duplicated on
# purpose: every script here is self-contained (REF-05), nothing imports another.
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

sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
sc.cycles.samples=64
sc.render.resolution_x=1600; sc.render.resolution_y=900
sc.cycles.use_denoising=True

cd=bpy.data.cameras.new("CR"); cd.clip_start=0.1; cd.clip_end=60000.0
cam=bpy.data.objects.new("CR",cd); sc.collection.objects.link(cam); sc.camera=cam

# the SAME points preview.py uses, so a chunked render and a normal preview point at the
# identical frame - the only fair way to judge the join.
SHOTS={
    "wide":   ((    0.0,-2600.0,700.0), aim(-11.0,  0.0), 30.0),
    "chowk":  ((  340.0, -830.0,150.0), aim(-26.0,  0.0), 35.0),
    "s2road": ((  340.1, -579.9,  1.3), aim( -1.0,232.2), 28.0),
}
loc,fwd,lens=SHOTS[SHOT]
x,y,z=loc
if z<=3.0:
    dg=bpy.context.evaluated_depsgraph_get()
    hit,loc_,_,_,_,_=sc.ray_cast(dg, Vector((x,y,3000.0)), Vector((0,0,-1)))
    z=(loc_.z if hit else 0.0)+1.30
cam.location=(x,y,z); cam.data.lens=lens
cam.rotation_euler=fwd.to_track_quat('-Z','Y').to_euler()

vl=bpy.context.view_layer
ALL=[c.name for c in sc.collection.children]

def set_visible(names):
    for nm in ALL:
        lc=vl.layer_collection.children.get(nm)
        if lc: lc.exclude = (nm not in names)

manifest=[]
for pd in PASSDEFS:
    pname, cols = pd.split("=",1)
    names=set(cols.split(","))
    set_visible(names)
    sc.render.film_transparent = True
    sc.render.filepath=os.path.join(OUT, f"{TAG}_{SHOT}_{pname}")
    t=time.time(); bpy.ops.render.render(write_still=True)
    print(f"  pass {pname} ({sorted(names)}): {time.time()-t:.1f}s")
    manifest.append(pname)

# the REFERENCE - every pass's collections visible TOGETHER, ONE render, opaque. Composite.py
# measures against this.
all_names=set()
for pd in PASSDEFS: all_names |= set(pd.split("=",1)[1].split(","))
set_visible(all_names)
sc.render.film_transparent = False
sc.render.filepath=os.path.join(OUT, f"{TAG}_{SHOT}_REFERENCE")
t=time.time(); bpy.ops.render.render(write_still=True)
print(f"  pass REFERENCE: {time.time()-t:.1f}s")
print(f"CHUNK RENDER DONE: passes {manifest} + REFERENCE, shot {SHOT}")
