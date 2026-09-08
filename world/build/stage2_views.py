import bpy, math, os
from mathutils import Vector
R_=math.radians
OUTDIR="/Users/aditya/Desktop/SIH26037-Reference/renders"
os.makedirs(OUTDIR, exist_ok=True)
sc=bpy.context.scene

# neutral clay material on everything so form reads, not colour
m=bpy.data.materials.new("CLAY"); m.use_nodes=True
bsdf=m.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value=(0.55,0.55,0.54,1)
bsdf.inputs["Roughness"].default_value=0.85
def mat(name, rgb, rough=0.85):
    mm=bpy.data.materials.new(name); mm.use_nodes=True
    b=mm.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=(*rgb,1); b.inputs["Roughness"].default_value=rough
    return mm
M_GROUND=mat("GROUND",(0.60,0.585,0.55)); M_ROAD=mat("ROAD",(0.22,0.22,0.23))
M_BLD=mat("BLD",(0.72,0.70,0.66)); M_TREE=mat("TREE",(0.38,0.42,0.30))
M_STR=mat("STRUCT",(0.80,0.80,0.80))
M_PWR=mat("POWER",(0.42,0.44,0.46),0.55); M_SUR=mat("SURROUND",(0.66,0.62,0.56)); M_ACT=mat("ACTOR",(0.85,0.35,0.20))
PICK={"TERRAIN":M_GROUND,"ROAD":M_ROAD,"BRIDGE":M_STR,"BUILDINGS":M_BLD,
      "TREES":M_TREE,"FURNITURE":M_STR,"ACTORS":M_ACT,
      "POWER":M_PWR,"SURROUND":M_SUR}
for cname,mm in PICK.items():
    c=bpy.data.collections.get(cname)
    if not c: continue
    for o in c.objects:
        if o.type=='MESH':
            o.data.materials.clear(); o.data.materials.append(mm)

# sky + sun matching the script: 06:45, elevation 10 deg, azimuth 095
w=bpy.data.worlds.new("W"); sc.world=w; w.use_nodes=True
nt=w.node_tree; nt.nodes.clear()
sky=nt.nodes.new("ShaderNodeTexSky"); sky.sky_type='NISHITA'
sky.sun_elevation=R_(10.0); sky.sun_rotation=R_(95.0)
sky.air_density=1.5; sky.dust_density=4.0; sky.ozone_density=2.0
bg=nt.nodes.new("ShaderNodeBackground"); bg.inputs[1].default_value=0.25
out=nt.nodes.new("ShaderNodeOutputWorld")
nt.links.new(sky.outputs[0],bg.inputs[0]); nt.links.new(bg.outputs[0],out.inputs[0])
sun=bpy.data.lights.new("SUN",'SUN'); sun.energy=3.0; sun.angle=R_(1.5)
so=bpy.data.objects.new("SUN",sun); sc.collection.objects.link(so)
so.rotation_euler=(R_(80.0),0.0,R_(95.0+180))

sc.render.engine='BLENDER_EEVEE_NEXT'
sc.render.resolution_x=1280; sc.render.resolution_y=720
sc.render.film_transparent=False
sc.view_settings.view_transform='AgX'; sc.view_settings.look='AgX - Base Contrast'

def shot(name, camobj):
    sc.camera=camobj
    sc.render.filepath=os.path.join(OUTDIR,name)
    bpy.ops.render.render(write_still=True); print("  rendered",name)

order=[("s2_01_rural.png","CAM_01_rural"),("s2_02_bend_entry.png","CAM_02_bend_entry"),
       ("s2_03_cow_reveal.png","CAM_03_cow_reveal"),("s2_04_town.png","CAM_04_town"),
       ("s2_05_bridge_approach.png","CAM_05_bridge_app"),("s2_06_on_bridge.png","CAM_06_on_bridge"),
       ("s2_07_hill_curve.png","CAM_07_hill_curve"),("s2_08_bridge_side.png","CAM_08_bridge_side"),
       ("s2_09_valley.png","CAM_09_valley")]
for fn,cn in order:
    c=bpy.data.objects.get(cn)
    if c: shot(fn,c)
    else: print("  MISSING CAMERA",cn)

# overview + plan, built here
def aimcam(name, loc, target, lens):
    import mathutils, math as _m
    c=bpy.data.cameras.new("A"); c.lens=lens; c.sensor_width=36.0
    c.clip_start=0.05; c.clip_end=9000.0
    o=bpy.data.objects.new("A",c); sc.collection.objects.link(o)
    o.location=loc
    d=(mathutils.Vector(target)-mathutils.Vector(loc))
    o.rotation_euler=(_m.acos(d.z/d.length), 0.0, _m.atan2(d.y,d.x)-_m.pi/2)
    shot(name,o); bpy.data.objects.remove(o)

def freecam(name, loc, rot, lens):
    c=bpy.data.cameras.new("F"); c.lens=lens; c.sensor_width=36.0
    c.clip_start=0.1; c.clip_end=9000.0
    o=bpy.data.objects.new("F",c); sc.collection.objects.link(o)
    o.location=loc; o.rotation_euler=rot; shot(name,o); bpy.data.objects.remove(o)
# power-system shots
tw=bpy.data.objects.get("TOWER_04")
if tw:
    import mathutils
    o=tw.location
    aimcam("s2_12_tower.png",(o.x-52.0,o.y-44.0,16.0),(o.x,o.y,o.z+17.0),35.0)
    aimcam("s2_13_tower_base.png",(o.x-17.0,o.y-14.0,1.7),(o.x,o.y,o.z+9.0),22.0)
pl=bpy.data.objects.get("POLE_004")
if pl:
    o=pl.location
    aimcam("s2_14_pole_top.png",(o.x-11.0,o.y-9.0,2.4),(o.x,o.y,o.z+7.0),55.0)
def wcentre(ob):
    import mathutils
    pts=[ob.matrix_world @ mathutils.Vector(c) for c in ob.bound_box]
    return mathutils.Vector((sum(p.x for p in pts)/8, sum(p.y for p in pts)/8,
                             min(p.z for p in pts)))
dt=bpy.data.objects.get("DTR_00")
if dt:
    o=wcentre(dt)
    aimcam("s2_15_transformer.png",(o.x-14.0,o.y+9.0,3.4),(o.x,o.y,o.z+4.0),48.0)
kl=bpy.data.objects.get("BRICK_KILN")
if kl:
    o=wcentre(kl)
    aimcam("s2_16_kiln.png",(o.x-170.0,o.y-140.0,26.0),(o.x,o.y,o.z+14.0),34.0)
freecam("s2_10_overview.png",(-780.0,-1500.0,420.0),(R_(72),0,R_(-30)),20.0)
freecam("s2_11_plan.png",(-40.0,-300.0,1250.0),(0,0,R_(-20)),18.0)
print("done")
