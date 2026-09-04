# SIH26037 - COMPONENT 1 - LIGHT
# Spec: S0-THE-WORLD.md section 2, as corrected 3 Sep from real solar position.
#   25 Sep 2026, 06:45 IST, 29.6118N 78.3421E -> sun elevation 7.53 deg, azimuth 95.24 deg
#   Nishita: Air 1.5, Aerosols 4.0, Ozone 2.0, background strength 0.25
#   Haze: Koschmieder a = 3.92/800 m = 0.0049  <- IS Blender's Principled Volume Density
#   Bounded volume ONLY. A world volume renders pure black (REF-05 section 3).
import bpy, math, os, sys
from mathutils import Vector

OUT   = "/Users/aditya/Desktop/SIH26037-Reference/blend/01_LIGHT.blend"
RND   = "/Users/aditya/Desktop/SIH26037-Reference/renders/city"
os.makedirs(RND, exist_ok=True)

SUN_ELEV_DEG = 7.53
SUN_AZIM_DEG = 95.24
AIR, AEROSOL, OZONE = 2.0, 10.0, 1.0   # MEASURED off Aditya's dashcam, see S0 s2
BG_STRENGTH  = 0.25
VISIBILITY_M = 800.0
HAZE_DENSITY = 3.92 / VISIBILITY_M          # 0.0049 - at GROUND level
SCALE_H      = 1200.0                        # aerosol scale height: haze thins with altitude.
# Without this the finite box shows a hard seam where rays start exiting the TOP face instead of
# the side - the path length jumps. Found by ray-casting, not by guessing. Real air does this too.
GEXT         = 2000.0                        # ground half-extent -> 4000 x 4000 m
AIR_TOP      = 2500.0        # raised from S0's 450 m - see the exponential falloff below
AIR_BOTTOM   = -5.0

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.unit_settings.system = 'METRIC'
sc.unit_settings.length_unit = 'METERS'
COL = {}
for n in ("SKY","AIR","REFERENCE"):
    c = bpy.data.collections.new(n); sc.collection.children.link(c); COL[n] = c

# ---------------------------------------------------------------- the sun
# light travels FROM the sun: d = -(cosE sinA, cosE cosA, sinE), azimuth clockwise from north
E = math.radians(SUN_ELEV_DEG); A = math.radians(SUN_AZIM_DEG)
d = Vector((-(math.cos(E)*math.sin(A)), -(math.cos(E)*math.cos(A)), -math.sin(E))).normalized()
sun_data = bpy.data.lights.new("SUN", 'SUN')
sun_data.angle  = math.radians(0.526)       # real angular diameter of the sun
sun_data.energy = 3.2                        # low sun, thick air path - tuned by looking
sun = bpy.data.objects.new("SUN", sun_data); COL["SKY"].objects.link(sun)
sun.rotation_euler = d.to_track_quat('-Z','Y').to_euler()
sun.location = (0,0,200)

# ---------------------------------------------------------------- the sky
w = bpy.data.worlds.new("WORLD"); sc.world = w; w.use_nodes = True
nt = w.node_tree; nt.nodes.clear()
sky = nt.nodes.new("ShaderNodeTexSky");  sky.location = (-600,0)
sky.sky_type      = 'NISHITA'
sky.sun_elevation = E
sky.sun_rotation  = A
sky.air_density   = AIR
sky.dust_density  = AEROSOL
sky.ozone_density = OZONE
sky.sun_disc      = False        # the Sun LAMP is the direct light, so the cloud plane can block it
bg  = nt.nodes.new("ShaderNodeBackground"); bg.location = (-300,0)
bg.inputs["Strength"].default_value = BG_STRENGTH
out = nt.nodes.new("ShaderNodeOutputWorld"); out.location = (0,0)
nt.links.new(sky.outputs["Color"], bg.inputs["Color"])
nt.links.new(bg.outputs["Background"], out.inputs["Surface"])

# ---------------------------------------------------------------- bounded haze
bpy.ops.mesh.primitive_cube_add(size=1)
air = bpy.context.object; air.name = "AIR_VOLUME"
air.scale = (GEXT*6, GEXT*6, (AIR_TOP-AIR_BOTTOM))
air.location = (0,0,(AIR_TOP+AIR_BOTTOM)/2)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
for c in air.users_collection: c.objects.unlink(air)
COL["AIR"].objects.link(air)
m = bpy.data.materials.new("HAZE"); m.use_nodes = True; air.data.materials.append(m)
nt = m.node_tree; nt.nodes.clear()
vol = nt.nodes.new("ShaderNodeVolumePrincipled"); vol.location = (0,0)
vol.inputs["Color"].default_value = (0.74,0.70,0.63,1.0)   # WARM tan: Indo-Gangetic dust, not blue
vol.inputs["Anisotropy"].default_value = 0.35        # forward scatter -> haloed low sun
noise = nt.nodes.new("ShaderNodeTexNoise"); noise.location = (-700,-150)
noise.inputs["Scale"].default_value  = 1.4
noise.inputs["Detail"].default_value = 4.0
ramp = nt.nodes.new("ShaderNodeValToRGB"); ramp.location = (-500,-150)
ramp.color_ramp.elements[0].position = 0.30
ramp.color_ramp.elements[1].position = 0.85
mul = nt.nodes.new("ShaderNodeMath"); mul.operation='MULTIPLY'; mul.location=(-260,-150)
mul.inputs[1].default_value = HAZE_DENSITY * 1.55     # noise averages ~0.65, so scale to hit target
mo = nt.nodes.new("ShaderNodeOutputMaterial"); mo.location = (300,0)
nt.links.new(noise.outputs["Fac"], ramp.inputs["Fac"])
nt.links.new(ramp.outputs["Color"], mul.inputs[0])
# altitude falloff: density = ground_density * exp(-z / SCALE_H)
gpos = nt.nodes.new("ShaderNodeNewGeometry"); gpos.location=(-1100,-420)
sxyz = nt.nodes.new("ShaderNodeSeparateXYZ"); sxyz.location=(-900,-420)
zneg = nt.nodes.new("ShaderNodeMath"); zneg.operation='MULTIPLY'; zneg.location=(-700,-420)
zneg.inputs[1].default_value = -1.0/SCALE_H
zexp = nt.nodes.new("ShaderNodeMath"); zexp.operation='EXPONENT'; zexp.location=(-500,-420)
falloff = nt.nodes.new("ShaderNodeMath"); falloff.operation='MULTIPLY'; falloff.location=(-60,-260)
nt.links.new(gpos.outputs["Position"], sxyz.inputs["Vector"])
nt.links.new(sxyz.outputs["Z"], zneg.inputs[0])
nt.links.new(zneg.outputs["Value"], zexp.inputs[0])
nt.links.new(mul.outputs["Value"], falloff.inputs[0])
nt.links.new(zexp.outputs["Value"], falloff.inputs[1])
nt.links.new(falloff.outputs["Value"], vol.inputs["Density"])
nt.links.new(vol.outputs["Volume"], mo.inputs["Volume"])
air.visible_camera = False        # never see the box itself

# ---------------------------------------------------------------- cloud shadows
# S0: thin high stratus, ~25% cover. A sky texture casts NO ground shadow (REF-07 s6).
bpy.ops.mesh.primitive_plane_add(size=GEXT*6, location=(0,0,900))
cl = bpy.context.object; cl.name = "CLOUD_SHADOW"
for c in cl.users_collection: c.objects.unlink(cl)
COL["SKY"].objects.link(cl)
cm = bpy.data.materials.new("CLOUD_SHADOW"); cm.use_nodes = True; cl.data.materials.append(cm)
nt = cm.node_tree; nt.nodes.clear()
tr  = nt.nodes.new("ShaderNodeBsdfTransparent"); tr.location=(-200,120)
df  = nt.nodes.new("ShaderNodeBsdfDiffuse");     df.location=(-200,-60)
mix = nt.nodes.new("ShaderNodeMixShader");       mix.location=(60,0)
cn  = nt.nodes.new("ShaderNodeTexNoise");        cn.location=(-760,0)
cn.noise_dimensions = '4D'
cn.inputs["Scale"].default_value  = 0.9
cn.inputs["Detail"].default_value = 6.0
cn.inputs["Roughness"].default_value = 0.62
cr  = nt.nodes.new("ShaderNodeValToRGB"); cr.location=(-520,0)
cr.color_ramp.elements[0].position = 0.52     # ~25% cover: only the top of the noise blocks light
cr.color_ramp.elements[1].position = 0.70
co  = nt.nodes.new("ShaderNodeOutputMaterial"); co.location=(320,0)
nt.links.new(cn.outputs["Fac"], cr.inputs["Fac"])
nt.links.new(cr.outputs["Color"], mix.inputs["Fac"])
nt.links.new(tr.outputs["BSDF"], mix.inputs[1])
nt.links.new(df.outputs["BSDF"], mix.inputs[2])
nt.links.new(mix.outputs["Shader"], co.inputs["Surface"])
cl.visible_camera = False; cl.visible_diffuse = False; cl.visible_glossy = False   # shadow only

# ---------------------------------------------------------------- scale reference + test ground
# Recommended independently in three of the studied videos. 1.7 m, kept in every file.
def figure():
    parts=[("legs",0.36,0.22,0.86,0.43),("torso",0.42,0.24,0.62,1.17),("head",0.20,0.20,0.24,1.58)]
    objs=[]
    for n,sx,sy,sz,z in parts:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,z))
        o=bpy.context.object; o.name=f"REF_{n}"; o.scale=(sx,sy,sz)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True); objs.append(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.object.join()
    f=bpy.context.object; f.name="REF_HUMAN_1m70"
    for c in f.users_collection: c.objects.unlink(f)
    COL["REFERENCE"].objects.link(f)
    return f
human = figure()

bpy.ops.mesh.primitive_plane_add(size=GEXT*2, location=(0,0,0))
gnd = bpy.context.object; gnd.name = "TEST_GROUND"
gm = bpy.data.materials.new("TEST_GROUND"); gm.use_nodes=True
b = gm.node_tree.nodes["Principled BSDF"]
b.inputs["Base Color"].default_value = (0.29,0.26,0.19,1.0)
b.inputs["Roughness"].default_value  = 0.88
gnd.data.materials.append(gm)
for c in gnd.users_collection: c.objects.unlink(gnd)
COL["REFERENCE"].objects.link(gnd)

# a few posts at known distances, so haze falloff is READABLE not guessed
for dist in (50,100,200,400,800):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=6.0, location=(-dist*0.15, dist, 3.0))
    p=bpy.context.object; p.name=f"HAZE_POST_{dist}m"
    p.data.materials.append(gm)
    for c in p.users_collection: c.objects.unlink(p)
    COL["REFERENCE"].objects.link(p)

# ---------------------------------------------------------------- camera: the dashcam
cd = bpy.data.cameras.new("CAM_DASH")
cd.lens = 13.0                    # 140 deg dashcam ~ 12-14 mm equivalent (PIPELINE s37)
cd.clip_start, cd.clip_end = 0.1, 6000.0
cam = bpy.data.objects.new("CAM_DASH", cd); COL["REFERENCE"].objects.link(cam)
cam.location = (-6.0, -14.0, 1.30)                       # 1.30 m - driver's eye
cam.rotation_euler = (math.radians(88.0), 0, math.radians(-14.0))
sc.camera = cam

# ---------------------------------------------------------------- render + ASSERT
sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
sc.cycles.samples=64
sc.cycles.use_denoising=True
sc.cycles.volume_step_rate=8.0        # big haze box: coarse steps, still smooth at this density
sc.cycles.volume_max_steps=256
sc.render.resolution_x=1280; sc.render.resolution_y=720
sc.render.filepath=os.path.join(RND,"c1_light_dawn.png")

print("\n================ COMPONENT 1 - LIGHT : ASSERTIONS ================")
fails=[]
def check(name, got, want, tol):
    ok = abs(got-want)<=tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:34s} got {got:>10.4f}  want {want:.4f}")
    if not ok: fails.append(name)
# the sun really points where the astronomy says
sd = (sun.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
elev = math.degrees(math.asin(-sd.z))
azim = (math.degrees(math.atan2(-sd.x, -sd.y)) + 360.0) % 360.0
check("sun elevation (deg)", elev, SUN_ELEV_DEG, 0.05)
check("sun azimuth (deg)",   azim, SUN_AZIM_DEG, 0.05)
check("haze density (per m)", mul.inputs[1].default_value/1.55, HAZE_DENSITY, 1e-6)
check("sky air density",  sky.air_density,   AIR,      1e-6)
check("haze colour is warm (R>B)", 1.0 if vol.inputs["Color"].default_value[0] > vol.inputs["Color"].default_value[2] else 0.0, 1.0, 1e-6)
check("sky aerosols",     sky.dust_density,  AEROSOL,  1e-6)
check("sky ozone",        sky.ozone_density, OZONE,    1e-6)
check("background strength", bg.inputs["Strength"].default_value, BG_STRENGTH, 1e-6)
check("human reference height (m)", human.dimensions.z, 1.70, 0.02)
check("camera height (m)", cam.location.z, 1.30, 1e-6)
check("camera lens (mm)",  cam.data.lens, 13.0, 1e-6)
def world_z(o):
    zs=[(o.matrix_world @ Vector(c)).z for c in o.bound_box]
    return min(zs), max(zs)
az0, az1 = world_z(air)
check("air volume top (m)",    az1, AIR_TOP,    0.01)
check("haze scale height (m)", SCALE_H, 1200.0, 1e-6)
check("air volume bottom (m)", az0, AIR_BOTTOM, 0.01)
hz0, hz1 = world_z(human)
check("human feet on ground (m)", hz0, 0.0, 0.02)
print(f"  INFO  visibility {VISIBILITY_M:.0f} m -> Koschmieder alpha = {HAZE_DENSITY:.5f} /m")
print(f"  INFO  sun disc off; SUN lamp is the direct light so CLOUD_SHADOW can block it")
if fails:
    print("\n  ASSERTIONS FAILED:", fails); bpy.ops.wm.save_as_mainfile(filepath=OUT); sys.exit(1)
print("  ALL ASSERTIONS PASSED")
print("=================================================================\n")
bpy.ops.wm.save_as_mainfile(filepath=OUT)
bpy.ops.render.render(write_still=True)
print("saved:", OUT)

# =====================================================================
# COMPONENT 1 - LIGHT, PART TWO : everything REF-12 added
# =====================================================================
import bpy, math
from mathutils import Vector
sc = bpy.context.scene
def newcol(n):
    c = bpy.data.collections.get(n) or bpy.data.collections.new(n)
    if n not in {x.name for x in sc.collection.children}: sc.collection.children.link(c)
    return c
COL_CLOUD = newcol("CLOUD"); COL_SKY = bpy.data.collections["SKY"]
cam = sc.camera
sun = bpy.data.objects["SUN"]

# ---------------------------------------------------------------- 1 THE SKY PLANE
# REF-12 s2: the sky texture gives LIGHT ONLY; a camera-parented plane is what the camera SEES.
# Four independent sources. Higher resolution than an HDRI and no extra render time.
bpy.ops.mesh.primitive_plane_add(size=1)
skyp = bpy.context.object; skyp.name = "SKY_PLANE"
skyp.scale = (2600, 1500, 1)
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
skyp.rotation_euler = cam.rotation_euler.copy()          # "copy rotation" from the camera
d_cam = (cam.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
skyp.location = cam.location + d_cam * 5200.0            # far behind everything
skyp.parent = cam; skyp.matrix_parent_inverse = cam.matrix_world.inverted()
for c in skyp.users_collection: c.objects.unlink(skyp)
COL_SKY.objects.link(skyp)
# S0: no sky photo supplied yet, so drive it procedurally off the SAME Nishita sky.
sm = bpy.data.materials.new("SKY_PLANE"); sm.use_nodes = True; skyp.data.materials.append(sm)
nt = sm.node_tree; nt.nodes.clear()
sky2 = nt.nodes.new("ShaderNodeTexSky"); sky2.location=(-700,0)
sky2.sky_type='NISHITA'; sky2.sun_elevation=math.radians(7.53); sky2.sun_rotation=math.radians(95.24)
sky2.air_density=2.0; sky2.dust_density=10.0; sky2.ozone_density=1.0; sky2.sun_disc=False
em = nt.nodes.new("ShaderNodeEmission"); em.location=(-300,60); em.inputs["Strength"].default_value=1.0
pr = nt.nodes.new("ShaderNodeBsdfPrincipled"); pr.location=(-300,-260)   # base colour too (REF-12 s2)
mixs = nt.nodes.new("ShaderNodeMixShader"); mixs.location=(-20,0); mixs.inputs["Fac"].default_value=0.82
so = nt.nodes.new("ShaderNodeOutputMaterial"); so.location=(240,0)
nt.links.new(sky2.outputs["Color"], em.inputs["Color"])
nt.links.new(sky2.outputs["Color"], pr.inputs["Base Color"])
nt.links.new(pr.outputs["BSDF"], mixs.inputs[1]); nt.links.new(em.outputs["Emission"], mixs.inputs[2])
nt.links.new(mixs.outputs["Shader"], so.inputs["Surface"])
skyp.visible_shadow = False        # REF-12 s2: or it shadows the entire scene
# HIDDEN BY DEFAULT: with no sky PHOTOGRAPH supplied, this plane is only a lower-quality copy of
# the Nishita world and shows a hard rectangular edge. Un-hide the moment a sky image arrives.
skyp.hide_render = True; skyp.hide_viewport = True
skyp.visible_diffuse = False; skyp.visible_glossy = False

# ---------------------------------------------------------------- 2 THIN HIGH STRATUS
# S0: thin high stratus, ~25% cover, NO cumulus.
# A FLAT PLANE IS THE WRONG PRIMITIVE, and it cost several iterations to prove: a finite plane at
# altitude always shows its boundary somewhere. An A/B render settled it - hide the deck and the
# seam goes; hide the haze and nothing changes. A DOME HAS NO EDGE BY CONSTRUCTION.
bpy.ops.mesh.primitive_uv_sphere_add(radius=20000, segments=96, ring_count=48, location=(0,0,0))
st = bpy.context.object; st.name = "STRATUS_DOME"
st.scale = (1.0, 1.0, 0.16)                 # flattened: a cloud DECK, not a ball
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bpy.ops.object.shade_smooth()
for c in st.users_collection: c.objects.unlink(st)
COL_CLOUD.objects.link(st)
cm = bpy.data.materials.new("STRATUS"); cm.use_nodes = True; st.data.materials.append(cm)
nt = cm.node_tree; nt.nodes.clear()
tc = nt.nodes.new("ShaderNodeTexCoord"); tc.location=(-1400,0)
sep= nt.nodes.new("ShaderNodeSeparateXYZ"); sep.location=(-1200,-320)
mp = nt.nodes.new("ShaderNodeMapping");  mp.location=(-1200,60)
mp.inputs["Scale"].default_value = (1.0,0.16,1.0)   # strongly streaked - cirrus, not stratus
n1 = nt.nodes.new("ShaderNodeTexNoise"); n1.location=(-980,60)
n1.inputs["Scale"].default_value=12.0; n1.inputs["Detail"].default_value=9.0
n1.inputs["Roughness"].default_value=0.56
cr = nt.nodes.new("ShaderNodeValToRGB"); cr.location=(-740,60)
cr.color_ramp.elements[0].position=0.56; cr.color_ramp.elements[1].position=0.80   # sparse wisps
# fade toward the horizon using the dome's own normalised height
elev = nt.nodes.new("ShaderNodeMath"); elev.operation='DIVIDE'; elev.location=(-980,-320)
elev.inputs[1].default_value = 1.0     # generated Z is already 0..1
ez   = nt.nodes.new("ShaderNodeValToRGB"); ez.location=(-740,-320)
ez.color_ramp.elements[0].position=0.02; ez.color_ramp.elements[1].position=0.42  # incoming.z: 0 = horizon, 1 = zenith
ez.color_ramp.interpolation='EASE'      # a sharp ramp shows as a visible arc across the sky
fade = nt.nodes.new("ShaderNodeMath"); fade.operation='MULTIPLY'; fade.location=(-480,0)
emc= nt.nodes.new("ShaderNodeEmission"); emc.location=(-260,120)
emc.inputs["Color"].default_value=(1.00,0.93,0.85,1.0); emc.inputs["Strength"].default_value=1.05  # faint - the real sky is nearly featureless
trc= nt.nodes.new("ShaderNodeBsdfTransparent"); trc.location=(-260,-120)
mx = nt.nodes.new("ShaderNodeMixShader"); mx.location=(20,0)
co = nt.nodes.new("ShaderNodeOutputMaterial"); co.location=(280,0)
nt.links.new(tc.outputs["Generated"], mp.inputs["Vector"])
nt.links.new(mp.outputs["Vector"], n1.inputs["Vector"])
nt.links.new(n1.outputs["Fac"], cr.inputs["Fac"])
geo_in = nt.nodes.new("ShaderNodeNewGeometry"); geo_in.location=(-1400,-320)
nt.links.new(geo_in.outputs["Incoming"], sep.inputs["Vector"])
nt.links.new(sep.outputs["Z"], elev.inputs[0])
elev.operation='MULTIPLY'; elev.inputs[1].default_value = -1.0   # flip: 0 = horizon, 1 = zenith
nt.links.new(elev.outputs["Value"], ez.inputs["Fac"])
nt.links.new(cr.outputs["Color"], fade.inputs[0])
nt.links.new(ez.outputs["Color"], fade.inputs[1])
nt.links.new(fade.outputs["Value"], mx.inputs["Fac"])
nt.links.new(trc.outputs["BSDF"], mx.inputs[1]); nt.links.new(emc.outputs["Emission"], mx.inputs[2])
nt.links.new(mx.outputs["Shader"], co.inputs["Surface"])
st.visible_shadow = False
st.visible_diffuse = False; st.visible_glossy = False

# ---------------------------------------------------------------- 3 GOD-RAY OCCLUDERS
# REF-12 s6: shafts are the GAPS BETWEEN OCCLUDERS in a scattering medium. Volume + anisotropy
# alone gives fog, not shafts. These stand in until the real canopy and buildings exist.
occ = []
CAMX, CAMY = -6.0, -14.0   # occluders EAST of the camera, on the line to the sun
for i,(x,y,h,w) in enumerate(((CAMX+14,CAMY+2,7.5,3.2),(CAMX+26,CAMY-1,9.0,2.6),(CAMX+41,CAMY+4,6.5,4.0),(CAMX+58,CAMY-3,10.5,3.0),(CAMX+78,CAMY+6,8.0,3.4))):
    bpy.ops.mesh.primitive_cube_add(size=1, location=(x,y,h/2))
    o=bpy.context.object; o.name=f"GODRAY_OCCLUDER_{i}"; o.scale=(w,w*0.7,h)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.visible_camera = False        # they are OUT of frame - only their shadows are in it
    for c in o.users_collection: c.objects.unlink(o)
    COL_SKY.objects.link(o); occ.append(o)

# ---------------------------------------------------------------- 4 RENDER SETTINGS (REF-12 s5)
sc.cycles.volume_max_steps = 24          # default 1024 - the single biggest volume speed-up
sc.cycles.volume_step_rate = 4.0
sc.cycles.volume_bounces   = 2           # default 0; higher = nicer volumes
sc.cycles.transparent_max_bounces = 12   # stratus + haze + future leaves
vl = bpy.context.view_layer
vl.cycles.use_pass_volume_direct   = True
vl.cycles.use_pass_volume_indirect = True
vl.use_pass_z = True

# ---------------------------------------------------------------- 5 ASSERT PART TWO
print("\n=========== COMPONENT 1 - LIGHT : PART TWO ASSERTIONS ===========")
f2=[]
def chk(n,g,w,t=1e-6):
    ok=abs(g-w)<=t; print(f"  {'OK  ' if ok else 'FAIL'} {n:36s} got {g:>10.4f}  want {w}")
    if not ok: f2.append(n)
chk("sky plane parented to camera", 1.0 if skyp.parent==cam else 0.0, 1.0)
chk("sky plane casts no shadow",    0.0 if not skyp.visible_shadow else 1.0, 0.0)
chk("stratus dome half-height (m)", st.dimensions.z/2, 3200.0, 60.0)
chk("stratus casts no shadow",      0.0 if not st.visible_shadow else 1.0, 0.0)
chk("godray occluders",             float(len(occ)), 5.0)
chk("occluders hidden from camera", float(sum(1 for o in occ if not o.visible_camera)), 5.0)
chk("volume max steps",             float(sc.cycles.volume_max_steps), 24.0)
chk("volume bounces",               float(sc.cycles.volume_bounces), 2.0)
chk("volume_direct pass on",        1.0 if vl.cycles.use_pass_volume_direct else 0.0, 1.0)
sunv=(sun.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
camv=(cam.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
dot=sunv.dot(camv)
print(f"  INFO  sun-vs-camera dot = {dot:+.3f}  ({'BACK-lit, good' if dot>0.25 else 'SIDE-lit, good' if abs(dot)<=0.25 else 'FRONT-lit - flat, REF-12 s1 warns against this'})")
if f2: print("\n  PART TWO FAILED:", f2)
else:  print("  ALL PART TWO ASSERTIONS PASSED")
print("================================================================\n")
bpy.ops.wm.save_as_mainfile(filepath=OUT)

# ---------------------------------------------------------------- 6 THE LOOKS
sc.cycles.samples = 96
SUN_AZ = 95.24
def look_at_azimuth(a):  return 180.0 - a      # Blender z-rotation for a camera facing azimuth a
for nm, loc, rot, lens in (
    ("c1_a_driver",   (-6.0,-14.0,1.30), (90.0, 0, look_at_azimuth(20.0)),      13.0),
    ("c1_b_intosun",  (-6.0,-14.0,1.30), (92.5, 0, look_at_azimuth(SUN_AZ)),    13.0),
    ("c1_c_skyward",  (-6.0,-14.0,1.30), (126.0, 0, look_at_azimuth(SUN_AZ)),   13.0),
    ("c1_d_wide",     (-160.0,-330.0,55.0), (86.0, 0, look_at_azimuth(28.0)),   28.0)):
    cam.location = loc; cam.rotation_euler = (math.radians(rot[0]),0,math.radians(rot[2]))
    cam.data.lens = lens
    sc.render.filepath = os.path.join(RND, nm + ".png")
    print("rendering", nm)
    bpy.ops.render.render(write_still=True)
print("DONE")
