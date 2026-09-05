# COMPONENT 1b - TWO SKIES, switchable collections (REF-12 s1 workflow).
#   CLOUD_REFERENCE : matched to Aditya's measured dashcam sky - pale, hazy, faint cirrus wisps
#   CLOUD_HERO      : real volumetric cumulus, the pipeline from REF-12 s3
import bpy, math, os, sys, time
from mathutils import Vector
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
BLEND=f"{REF}/blend/01_LIGHT.blend"
RND =f"{REF}/renders/city"
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc=bpy.context.scene
t0=time.time()

# ---- brightness: measured 125 against a target of 187. Raise the sky, keep the physics.
wnt=sc.world.node_tree
bg=[n for n in wnt.nodes if n.type=='BACKGROUND'][0]
bg.inputs["Strength"].default_value = 0.62
sun=bpy.data.objects["SUN"]; sun.data.energy = 4.6

# ---- rename the existing wisp dome into the REFERENCE variant
ref=bpy.data.collections.get("CLOUD")
if ref: ref.name="CLOUD_REFERENCE"
hero=bpy.data.collections.new("CLOUD_HERO"); sc.collection.children.link(hero)

# ---- HERO: real volumetric cumulus, scattered across the sky
VOX=11.0     # bigger clouds tolerate bigger voxels - cost stays flat
def make_cloud(idx, loc, size, seed, dens):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=24, ring_count=12, location=loc)
    o=bpy.context.object; o.name=f"CUMULUS_{idx}"
    o.scale=size; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for c in o.users_collection: c.objects.unlink(o)
    hero.objects.link(o)
    m=o.modifiers.new("CLOUD","NODES")
    ng=bpy.data.node_groups.new(f"CLOUD_{idx}","GeometryNodeTree"); m.node_group=ng
    ng.interface.new_socket("Geometry",in_out='INPUT', socket_type='NodeSocketGeometry')
    ng.interface.new_socket("Geometry",in_out='OUTPUT',socket_type='NodeSocketGeometry')
    n=ng.nodes; l=ng.links
    gi=n.new("NodeGroupInput"); go=n.new("NodeGroupOutput"); go.location=(700,0)
    m2v=n.new("GeometryNodeMeshToVolume"); m2v.location=(-800,0)
    m2v.resolution_mode='VOXEL_SIZE'; m2v.inputs["Voxel Size"].default_value=VOX*1.7
    dp =n.new("GeometryNodeDistributePointsInVolume"); dp.location=(-560,0)
    dp.mode='DENSITY_RANDOM'; dp.inputs["Density"].default_value=0.00115; dp.inputs["Seed"].default_value=seed
    sp =n.new("GeometryNodeSetPosition"); sp.location=(-300,0)
    nz =n.new("ShaderNodeTexNoise"); nz.location=(-700,-300); nz.noise_dimensions='4D'
    nz.inputs["Scale"].default_value=0.011; nz.inputs["Detail"].default_value=6.0
    nz.inputs["W"].default_value=float(seed)
    sub=n.new("ShaderNodeVectorMath"); sub.operation='SUBTRACT'; sub.location=(-560,-260)
    sub.inputs[1].default_value=(0.5,0.5,0.34)
    mul=n.new("ShaderNodeVectorMath"); mul.operation='MULTIPLY'; mul.location=(-420,-260)
    mul.inputs[1].default_value=(size[0]*0.55, size[1]*0.55, size[2]*1.5)
    rv =n.new("FunctionNodeRandomValue"); rv.location=(-300,-200); rv.data_type='FLOAT'
    rv.inputs[2].default_value=VOX*2.2; rv.inputs[3].default_value=VOX*4.6; rv.inputs["Seed"].default_value=seed
    p2v=n.new("GeometryNodePointsToVolume"); p2v.location=(-40,0)
    p2v.resolution_mode='VOXEL_SIZE'; p2v.inputs["Voxel Size"].default_value=VOX
    l.new(gi.outputs[0],m2v.inputs["Mesh"]); l.new(m2v.outputs["Volume"],dp.inputs["Volume"])
    l.new(dp.outputs["Points"],sp.inputs["Geometry"])
    l.new(nz.outputs["Color"],sub.inputs[0]); l.new(sub.outputs["Vector"],mul.inputs[0])
    l.new(mul.outputs["Vector"],sp.inputs["Offset"])
    # second, finer displacement - this is what turns clusters of spheres into billows
    sp2=n.new("GeometryNodeSetPosition"); sp2.location=(-170,0)
    nz2=n.new("ShaderNodeTexNoise"); nz2.location=(-560,-500); nz2.noise_dimensions='4D'
    nz2.inputs["Scale"].default_value=0.055; nz2.inputs["Detail"].default_value=8.0
    nz2.inputs["Roughness"].default_value=0.62; nz2.inputs["W"].default_value=float(seed)*2.3
    sb2=n.new("ShaderNodeVectorMath"); sb2.operation='SUBTRACT'; sb2.location=(-420,-500)
    sb2.inputs[1].default_value=(0.5,0.5,0.5)
    ml2=n.new("ShaderNodeVectorMath"); ml2.operation='MULTIPLY'; ml2.location=(-290,-500)
    ml2.inputs[1].default_value=(size[0]*0.30, size[1]*0.30, size[2]*0.42)
    l.new(nz2.outputs["Color"],sb2.inputs[0]); l.new(sb2.outputs["Vector"],ml2.inputs[0])
    l.new(sp.outputs["Geometry"],sp2.inputs["Geometry"]); l.new(ml2.outputs["Vector"],sp2.inputs["Offset"])
    l.new(sp2.outputs["Geometry"],p2v.inputs["Points"]); l.new(rv.outputs[1],p2v.inputs["Radius"])
    l.new(p2v.outputs["Volume"],go.inputs[0])
    mat=bpy.data.materials.new(f"CLOUD_{idx}"); mat.use_nodes=True; o.data.materials.append(mat)
    nt=mat.node_tree; nt.nodes.clear()
    v=nt.nodes.new("ShaderNodeVolumePrincipled")
    v.inputs["Color"].default_value=(1,1,1,1); v.inputs["Density"].default_value=dens
    v.inputs["Anisotropy"].default_value=0.55   # strong forward scatter: bright sunlit rim
    out=nt.nodes.new("ShaderNodeOutputMaterial"); out.location=(300,0)
    nt.links.new(v.outputs["Volume"],out.inputs["Volume"])
    return o
import random
random.seed(4)
CLOUDS=[]
for i in range(16):
    ang=random.uniform(0,math.tau); rad=random.uniform(1200,11000)
    x=math.cos(ang)*rad; y=math.sin(ang)*rad
    z=random.uniform(950,1750)
    s=random.uniform(0.8,2.2)
    # lower density = brighter and softer; big clouds need less to read as thick
    CLOUDS.append(make_cloud(i,(x,y,z),(330*s,225*s,95*s),i*17+3,random.uniform(0.045,0.075)))
print(f"  built {len(CLOUDS)} volumetric cumulus")

sc.cycles.volume_max_steps=20; sc.cycles.volume_step_rate=5.0
sc.render.resolution_x=1280; sc.render.resolution_y=720; sc.cycles.samples=80

def setcol(name, on):
    lc=bpy.context.view_layer.layer_collection.children.get(name)
    if lc: lc.exclude = not on
def shoot(tag):
    for nm,loc,pitch,az,lens in (
        ("driver",(-6.0,-14.0,1.30), 90.0, 20.0, 13.0),
        ("sky",   (-6.0,-14.0,1.30),122.0, 95.24,13.0)):
        cam=sc.camera; cam.location=loc
        cam.rotation_euler=(math.radians(pitch),0,math.radians(180.0-az)); cam.data.lens=lens
        sc.render.filepath=os.path.join(RND,f"c1_{tag}_{nm}.png")
        bpy.ops.render.render(write_still=True)
    print("  rendered", tag)

setcol("CLOUD_HERO",False); setcol("CLOUD_REFERENCE",True);  shoot("REFERENCE")
setcol("CLOUD_HERO",True);  setcol("CLOUD_REFERENCE",False); shoot("HERO")
setcol("CLOUD_HERO",False); setcol("CLOUD_REFERENCE",True)   # REFERENCE is the active sky; HERO deferred, see DEFERRED.md
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
import resource
print(f"\n  peak RSS {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1048576:.0f} MB   total {time.time()-t0:.0f} s")
