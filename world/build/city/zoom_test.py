# ZOOM TEST - the assertion PLAN s1 never had. Aditya's standard is a SCALE test: "I can zoom in
# from space and see the details." This renders ONE site from three fixed distances - 2 km,
# street (~80 m), close (~2 m) - and FAILS LOUDLY if a scale is not actually reading as something:
# a ray-cast at the frame centre must hit real geometry (never empty space or the sky), and the
# frame must carry local luminance VARIANCE, not read as a single flat colour block.
# STEP 0 ITEM 4.
#   blender --background --python build/city/zoom_test.py -- <blend> <tag> <x> <y> [heading_deg]
# Near-ground cameras (street/close) are made GROUND-RELATIVE the way preview.py already does -
# a fixed z would bury or float depending on local relief. CLOUD/AIR excluded - never judge
# geometry with clouds on (the working method).
import bpy, sys, os, math, time
import numpy as np
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND=a[0]; TAG=a[1]; SX=float(a[2]); SY=float(a[3]); HEAD=float(a[4]) if len(a)>4 else 0.0
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
# D2: the 4K circle displacement only shows under EXPERIMENTAL + adaptive subdivision. The .blend
# should already carry both (02_land.py), but set it here too - this is the render that JUDGES it,
# and at 2 m range the dicing wants to be fine.
sc.cycles.feature_set='EXPERIMENTAL'
for _o in bpy.data.objects:
    if _o.name=='TERRAIN' and hasattr(_o.cycles,'use_adaptive_subdivision'):
        _o.cycles.use_adaptive_subdivision=True; _o.cycles.dicing_rate=1.5
sc.cycles.samples=32
sc.render.resolution_x=960; sc.render.resolution_y=540
sc.cycles.use_denoising=True
sc.render.film_transparent=False
sc.render.image_settings.file_format='PNG'

cd=bpy.data.cameras.new("ZT"); cd.clip_start=0.05; cd.clip_end=60000.0
cam=bpy.data.objects.new("ZT",cd); sc.collection.objects.link(cam); sc.camera=cam

def ground_at(x,y):
    dg=bpy.context.evaluated_depsgraph_get()
    hit,loc_,_,_,_,_=sc.ray_cast(dg, Vector((x,y,3000.0)), Vector((0,0,-1)))
    return loc_.z if hit else 0.0

gz=ground_at(SX,SY)
target=Vector((SX,SY,gz))
h=math.radians(HEAD)
heading=Vector((math.sin(h),math.cos(h),0.0))   # unit vector the FRAME advances along
away=heading                                     # kept for the "air" mode: stand back opposite it

def tilt(vec_flat, down_deg):
    """vec_flat rotated to look DOWN by down_deg - a level heading alone puts the horizon dead
    centre and a distant flat plain reads as sky (found by LOOKING, first zoom_test run)."""
    p=math.radians(down_deg)
    d=Vector((vec_flat.x*math.cos(p), vec_flat.y*math.cos(p), -math.sin(p)))
    return d.normalized()

# scale -> (mode, standoff m, eye/camera height ABOVE ITS OWN ground, lens mm, ground-relative, down-tilt deg)
# "at"   = stand back and aim AT the point (the air view - confirmed good by looking)
# "along"= stand just short of the point, ALONG the heading, looking THROUGH it and past it -
#          the same convention preview.py's on-road cameras already use. Standing back and
#          staring at a single point from 80 m across dead-flat land is mostly horizon and sky,
#          which is not a street photograph - the first run's own render proved that.
SCALES=[
    ("air",    "at",   1150.0, 1650.0, 35.0, False,  0.0),  # ~2.0 km slant range, looking down
    ("street", "along",  15.0,    1.6, 32.0, True,   4.0),  # standing before it, heading through
    ("close",  "along",   2.0,    1.2, 24.0, True,  12.0),  # right up against it, tipped down more
]
fails=[]
results=[]
for name, mode, standoff, height, lens, ground_rel, down_deg in SCALES:
    if mode=="at":
        camxy = Vector((SX,SY,0.0)) + away*standoff
    else:
        camxy = Vector((SX,SY,0.0)) - heading*standoff
    camz  = (ground_at(camxy.x,camxy.y) if ground_rel else gz) + height
    cam.location=(camxy.x,camxy.y,camz)
    cam.data.lens=lens
    if mode=="at":
        look_dir=(target-cam.location).normalized()
    else:
        look_dir=tilt(heading, down_deg)
    cam.rotation_euler=look_dir.to_track_quat('-Z','Y').to_euler()
    tag=f"{TAG}_zoom_{name}"
    sc.render.filepath=os.path.join(OUT, tag)
    t0=time.time(); bpy.ops.render.render(write_still=True); dt=time.time()-t0

    # --- A: the frame centre hits REAL GEOMETRY, not empty space
    dg2=bpy.context.evaluated_depsgraph_get()
    hit,loc_,nrm_,idx,ob,_=sc.ray_cast(dg2, Vector(cam.location), look_dir)
    hit_name=ob.name if hit else None
    if not hit: fails.append(f"{name}: centre ray hit NOTHING")
    if hit:
        print(f"    PROBE cam={tuple(round(c,2) for c in cam.location)} hit_dist={(Vector(cam.location)-loc_).length:.2f}m normal={tuple(round(n,2) for n in nrm_)}")

    # --- B: the frame is not a flat colour block - luminance std over the BOTTOM two-thirds,
    # full width. Restricted to the ground-biased crop on purpose: the first zoom_test run
    # found that a whole-frame or centred-box check is satisfied by SKY GRADIENT alone (the
    # "street" render was mostly horizon and still passed) - a false OK, same species of bug as
    # audit.py's own PRINCIPLED_VOLUME string mismatch. This crop tests the GROUND, not the sky.
    img=bpy.data.images.load(sc.render.filepath+".png")
    w_,h_=img.size
    px=np.empty(len(img.pixels),dtype=np.float32); img.pixels.foreach_get(px)
    px=px.reshape(h_,w_,4)
    lum=0.2126*px[...,0]+0.7152*px[...,1]+0.0722*px[...,2]
    cy0=int(h_*0.34)
    var=float(lum[cy0:,:].std())
    bpy.data.images.remove(img)
    THRESH=0.015
    if var<THRESH: fails.append(f"{name}: frame reads FLAT (std {var:.4f} < {THRESH})")

    print(f"  {name:6s} standoff {standoff:7.1f} m  hit={hit_name!s:16s} luminance-std={var:.4f}  render {dt:.1f}s")
    results.append((name,standoff,hit_name,var))

print("\n================= ZOOM TEST : site (%.0f,%.0f) heading %.0f =================" % (SX,SY,HEAD))
for name,standoff,hit_name,var in results:
    print(f"  {name:6s}  standoff {standoff:7.1f} m  hit={hit_name!s:20s}  std={var:.4f}")
print("  " + ("ALL THREE SCALES READ" if not fails else f"FAILED: {fails}"))
print("="*70)
sys.exit(1 if fails else 0)
