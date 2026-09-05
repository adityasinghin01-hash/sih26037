# REAL VOLUMETRIC CLOUD - the pipeline from REF-12 s3 (adrien_ltn / Houdini method).
# Purpose: MEASURE what it actually costs on this 8 GB machine before deciding to defer it.
import bpy, math, os, time, sys
from mathutils import Vector
OUT="/Users/aditya/Desktop/SIH26037-Reference/renders/city"
os.makedirs(OUT, exist_ok=True)
t0=time.time()
bpy.ops.wm.read_factory_settings(use_empty=True)
sc=bpy.context.scene; sc.unit_settings.system='METRIC'

VOXEL = float(os.environ.get("VOXEL","6.0"))     # metres. THE cost dial.
print(f"\n### voxel size {VOXEL} m")

# 1 BASE SHAPE - a rough blob. "Vaguely cloudlike is enough."
bpy.ops.mesh.primitive_uv_sphere_add(radius=90, segments=32, ring_count=16, location=(0,0,420))
base=bpy.context.object; base.name="CLOUD_BASE"
base.scale=(1.9,1.25,0.62)                       # wide, flattened - a cumulus humilis
bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)

# 2 GEOMETRY NODES: scatter spheres, push them UP (vertical growth is organic - no height slider),
#   then convert the whole lot to a volume.
m=base.modifiers.new("CLOUD","NODES")
ng=bpy.data.node_groups.new("CLOUD","GeometryNodeTree"); m.node_group=ng
ng.interface.new_socket("Geometry",in_out='INPUT', socket_type='NodeSocketGeometry')
ng.interface.new_socket("Geometry",in_out='OUTPUT',socket_type='NodeSocketGeometry')
n=ng.nodes; l=ng.links
gi=n.new("NodeGroupInput");  gi.location=(-1200,0)
go=n.new("NodeGroupOutput"); go.location=( 900,0)
dist=n.new("GeometryNodeDistributePointsInVolume"); dist.location=(-700,0)
dist.mode='DENSITY_RANDOM'; dist.inputs["Density"].default_value=0.00028; dist.inputs["Seed"].default_value=7
m2v=n.new("GeometryNodeMeshToVolume"); m2v.location=(-950,0)
m2v.resolution_mode='VOXEL_SIZE'; m2v.inputs["Voxel Size"].default_value=VOXEL*1.6
# push points upward + spread - the "displacement" step
setp=n.new("GeometryNodeSetPosition"); setp.location=(-430,0)
noise=n.new("ShaderNodeTexNoise"); noise.location=(-780,-330)
noise.noise_dimensions='4D'; noise.inputs["Scale"].default_value=0.010; noise.inputs["Detail"].default_value=6.0
vmath=n.new("ShaderNodeVectorMath"); vmath.operation='MULTIPLY'; vmath.location=(-580,-330)
vmath.inputs[1].default_value=(46.0,46.0,86.0)   # more vertical than lateral
sub=n.new("ShaderNodeVectorMath"); sub.operation='SUBTRACT'; sub.location=(-680,-180)
sub.inputs[1].default_value=(0.5,0.5,0.35)
# radius varies per point -> lumpy, not uniform
rnd=n.new("FunctionNodeRandomValue"); rnd.location=(-430,-260)
rnd.data_type='FLOAT'; rnd.inputs[2].default_value=VOXEL*2.6; rnd.inputs[3].default_value=VOXEL*7.0
p2v=n.new("GeometryNodePointsToVolume"); p2v.location=(-120,0)
p2v.resolution_mode='VOXEL_SIZE'; p2v.inputs["Voxel Size"].default_value=VOXEL
l.new(gi.outputs[0], m2v.inputs["Mesh"])
l.new(m2v.outputs["Volume"], dist.inputs["Volume"])
l.new(dist.outputs["Points"], setp.inputs["Geometry"])
l.new(noise.outputs["Color"], sub.inputs[0])
l.new(sub.outputs["Vector"], vmath.inputs[0])
l.new(vmath.outputs["Vector"], setp.inputs["Offset"])
l.new(setp.outputs["Geometry"], p2v.inputs["Points"])
l.new(rnd.outputs[1], p2v.inputs["Radius"])
l.new(p2v.outputs["Volume"], go.inputs[0])

# 3 SHADE IT - REF-12 s4: top/bottom gradient, and it is 90% lighting anyway
mat=bpy.data.materials.new("CLOUD"); mat.use_nodes=True; base.data.materials.append(mat)
nt=mat.node_tree; nt.nodes.clear()
vol=nt.nodes.new("ShaderNodeVolumePrincipled"); vol.location=(0,0)
vol.inputs["Color"].default_value=(1,1,1,1)
vol.inputs["Density"].default_value=0.14
vol.inputs["Anisotropy"].default_value=0.42       # forward scatter -> bright rim on the sun side
mo=nt.nodes.new("ShaderNodeOutputMaterial"); mo.location=(300,0)
nt.links.new(vol.outputs["Volume"], mo.inputs["Volume"])

# 4 SUN + SKY, same numbers as component 1
E=math.radians(7.53); A=math.radians(95.24)
d=Vector((-(math.cos(E)*math.sin(A)),-(math.cos(E)*math.cos(A)),-math.sin(E))).normalized()
sd=bpy.data.lights.new("SUN",'SUN'); sd.angle=math.radians(0.526); sd.energy=6.0
sun=bpy.data.objects.new("SUN",sd); sc.collection.objects.link(sun)
sun.rotation_euler=d.to_track_quat('-Z','Y').to_euler()
w=bpy.data.worlds.new("W"); sc.world=w; w.use_nodes=True
wnt=w.node_tree; wnt.nodes.clear()
sky=wnt.nodes.new("ShaderNodeTexSky"); sky.sky_type='NISHITA'
sky.sun_elevation=E; sky.sun_rotation=A; sky.air_density=1.5; sky.dust_density=4.0
sky.ozone_density=2.0; sky.sun_disc=False
bg=wnt.nodes.new("ShaderNodeBackground"); bg.inputs["Strength"].default_value=0.25
wo=wnt.nodes.new("ShaderNodeOutputWorld")
wnt.links.new(sky.outputs["Color"],bg.inputs["Color"]); wnt.links.new(bg.outputs["Background"],wo.inputs["Surface"])

cd=bpy.data.cameras.new("C"); cd.lens=50.0; cd.clip_end=20000
cam=bpy.data.objects.new("C",cd); sc.collection.objects.link(cam); sc.camera=cam
# frame the cloud properly: it sits at z=420, camera at 180, 950 m back -> look UP 14 deg.
# (in Blender rot.x=90 is horizontal, ABOVE 90 looks up)
cam.location=(-40,-950,180); cam.rotation_euler=(math.radians(104.5),0,0)

sc.render.engine='CYCLES'
sc.cycles.samples=64; sc.cycles.use_denoising=True
sc.cycles.volume_max_steps=24; sc.cycles.volume_step_rate=4.0; sc.cycles.volume_bounces=2
sc.render.resolution_x=1100; sc.render.resolution_y=700
sc.render.filepath=os.path.join(OUT,f"cloud_v{int(VOXEL)}.png")
t1=time.time()
bpy.ops.render.render(write_still=True)
t2=time.time()
st=bpy.app.driver_namespace
print("\n================ VOLUMETRIC CLOUD COST ================")
print(f"  voxel size        {VOXEL} m")
print(f"  build time        {t1-t0:6.1f} s")
print(f"  render time       {t2-t1:6.1f} s   (1100x700, 64 samples)")
print(f"  peak memory       {bpy.app.memory_statistics()['peak'] if hasattr(bpy.app,'memory_statistics') else 'n/a'}")
import resource
print(f"  process peak RSS  {resource.getrusage(resource.RUSAGE_SELF).ru_maxrss/1048576:6.0f} MB")
print("======================================================")
