# PLAN s10 PHASE 3 · LIGHT + LAND, COMBINED -> 04_WORLD.blend
#   blender --background --python build/city/04_world_combine.py
# Opens 03_ROADS.blend (land+roads+rocks+reference figure), APPENDS the SKY and CLOUD collections
# from 01_LIGHT.blend (sun, Nishita world, cumulus+cirrus+cloud-shadow-plane+god-ray occluders).
# 01_LIGHT.blend's own REFERENCE collection (ground plane, posts, its OWN scale figure, dashcam
# cam) is deliberately NOT brought in - land already carries its own 1.70 m reference figure and
# real cameras come from preview.py/02b_land_cameras.py; bringing the other one in would just be
# a second, redundant figure standing in the same world.
import bpy, os, sys, math, time
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
LAND_ROADS=f"{REF}/blend/03_ROADS.blend"
LIGHT=f"{REF}/blend/01_LIGHT.blend"
OUT=f"{REF}/blend/04_WORLD.blend"
T0=time.time()

bpy.ops.wm.open_mainfile(filepath=LAND_ROADS)
sc=bpy.context.scene

# the world file's own SUN/world, if 03b_world_light.py ever added a bare one, must go - the
# real component-1 sun and Nishita world are coming in via append below.
for o in [o for o in bpy.data.objects if o.type=='LIGHT']:
    bpy.data.objects.remove(o, do_unlink=True)

with bpy.data.libraries.load(LIGHT, link=False) as (src, dst):
    dst.collections=[c for c in src.collections if c in ("SKY","CLOUD")]
    dst.worlds=list(src.worlds)

for c in dst.collections:
    if c is not None and c.name not in sc.collection.children:
        sc.collection.children.link(c)
if dst.worlds:
    sc.world=dst.worlds[0]

sc.view_settings.view_transform='Standard'
sc.view_settings.exposure=-3.06
sc.render.engine='CYCLES'

n_sky=len(bpy.data.collections["SKY"].objects) if "SKY" in bpy.data.collections else 0
n_cloud=len(bpy.data.collections["CLOUD"].objects) if "CLOUD" in bpy.data.collections else 0
n_lights=len([o for o in bpy.data.objects if o.type=='LIGHT'])
print(f"appended SKY ({n_sky} objects), CLOUD ({n_cloud} objects), world set, "
      f"{n_lights} light object(s) in the file")

# ---------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 3->WORLD : PHASE 3 COMBINE =================")
fails=[]
def flag(name,cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

flag(f"exactly one SUN light in the combined file (got {n_lights})", n_lights==1)
flag("SKY collection present and populated", "SKY" in bpy.data.collections and n_sky>0)
flag("CLOUD collection present and populated", "CLOUD" in bpy.data.collections and n_cloud>0)
flag("world (Nishita sky) is set on the scene", sc.world is not None)
_land_cols={"TERRAIN","WATER","HILL","DISTANT","ROADS","ROADS_KACCHA","ROCKS_3D","REFERENCE"}
_present=_land_cols & {c.name for c in sc.collection.children}
flag(f"every land/road collection survived the append ({sorted(_present)})",
     _present==_land_cols)
flag("only ONE 'REFERENCE' collection exists (land's, not light's duplicate)",
     sum(1 for c in bpy.data.collections if c.name.startswith("REFERENCE"))==1)

print(f"  INFO  build time {time.time()-T0:.0f}s")
print("\n  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("="*66)
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print(f"saved: {OUT}")
