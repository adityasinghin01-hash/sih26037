# FAST PREVIEW - the working loop. Build, look, fix, move on.
#   blender --background --python build/city/preview.py -- <file.blend> <tag> [cheap|full]
# Appends the real SUN and WORLD from 01_LIGHT.blend so geometry is judged under the real light,
# but leaves CLOUD and AIR out: those are volumetric and cost minutes, geometry costs seconds.
import bpy, sys, os, math, time
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND=a[0]; TAG=a[1] if len(a)>1 else "pv"; MODE=a[2] if len(a)>2 else "cheap"
ONLY=set(a[3].split(",")) if len(a)>3 else None   # render just these shots
REF=os.environ.get("SIH_REF", "/Users/aditya/dev/sih2026/world")
OUT=f"{REF}/renders/city"; os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BLEND)
sc=bpy.context.scene

SUN_ELEV,SUN_AZIM=33.11,246.87
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))

# --- the real sun and sky, matched to component 1
if not any(o.type=='LIGHT' for o in bpy.data.objects):
    sd=bpy.data.lights.new("SUN",'SUN'); sd.angle=math.radians(0.526); sd.energy=5.2
    sun=bpy.data.objects.new("SUN",sd); sc.collection.objects.link(sun)
    sun.rotation_euler=(-aim(SUN_ELEV,SUN_AZIM)).to_track_quat('-Z','Y').to_euler()
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
    if lc: lc.exclude=True          # volumetrics cost MINUTES; geometry costs SECONDS

sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
if MODE=="cheap":
    sc.cycles.samples=16; sc.render.resolution_x=800; sc.render.resolution_y=450
else:
    sc.cycles.samples=64; sc.render.resolution_x=1600; sc.render.resolution_y=900
sc.cycles.use_denoising=True

cd=bpy.data.cameras.new("PV"); cd.clip_start=0.1; cd.clip_end=60000.0
cam=bpy.data.objects.new("PV",cd); sc.collection.objects.link(cam); sc.camera=cam

# angles chosen to SHOW the spec: the hill, the river, the plain, and eye level
SHOTS=(("hill",   (-1050.0,-100.0,240.0),  aim(-12.0,  0.0), 35.0),
       ("river",  ( -400.0, 300.0, 180.0),  aim(-22.0,315.0), 28.0),
       ("plain",  (  200.0,-1200.0, 90.0),  aim( -6.0,  0.0), 24.0),
       ("eye",    ( -700.0, 500.0,  1.3),   aim(  3.0,300.0), 13.0),
       ("wide",   (    0.0,-2600.0,700.0),  aim(-11.0,  0.0), 30.0),
       ("hillclose",(-1050.0, 300.0, 150.0),  aim(-10.0,  0.0), 60.0),
       # the SCREE FANS. Located by MEASUREMENT, not guessed: the biggest concentration of
       # eroder `deposit` low on the slope sits at (-858, 755), azimuth band 315-330 deg.
       ("scree",   ( -675.6, 614.6, 55.0),  aim( -6.0,307.5), 50.0),
       # component 3: the road network, at the five scenario centres (S0 s4)
       ("netwide", (  100.0,-1900.0,900.0),  aim(-22.0,  0.0), 24.0),
       ("chowk",   (  340.0, -830.0,150.0),  aim(-26.0,  0.0), 35.0),
       # ON the real roads, looking ALONG them - the points and headings are measured off
       # matlab_roads.csv at the S2/S3/S4 centres, not guessed. z<=3 is made ground-relative.
       ("s2road",  (  340.1, -579.9,  1.3),  aim( -1.0,232.2), 28.0),
       ("s3galli", ( -154.6, -475.7,  1.3),  aim( -1.0,118.6), 24.0),
       ("s4trunk", (  140.6, -818.6,  1.3),  aim( -1.0,168.7), 35.0),
       # component 3 pass 2: the two real river bridges (S0 s4 PASS2 ITEM1). S5's own "near
       # (x,y)" figures turned out to be an END of each span, not its middle - the drive
       # cameras below use the ACTUAL built deck midpoint/heading, measured off the mesh
       # (diag_deck_pos.py), not the approximate scenario-doc coordinate. Drive shots sit on
       # the deck itself (z<=3 makes them deck-relative); side shots are offset+elevated from
       # the true midpoint so the whole span, piers and water are framed.
       ("bridge1_drive", ( -673.1,  773.4,  1.3), aim( -1.0,132.3), 28.0),
       ("bridge1_side",  ( -703.4,  740.1, 20.0), aim(-20.0, 42.3), 24.0),
       ("bridge2_drive", ( -827.9,  634.1,  1.3), aim( -1.0,162.3), 28.0),
       ("bridge2_side",  ( -861.3,  623.4, 18.0), aim(-18.0, 72.3), 24.0),
       # component 3 pass 2 item 2: the S4 flyover cluster (most of the 9 decks are near here)
       ("s4_flyovers", (  300.0,-1100.0,180.0), aim(-27.0,330.5), 28.0),
       ("s4_ground",   (  130.0, -900.0,  1.3), aim( -3.0,  0.0), 24.0),
       # component 3 pass 2 item 3: the railway yard + station (NBD)
       ("rail_yard", ( -900.0, -700.0,150.0), aim(-18.0,200.0), 26.0),
       ("rail_station",(-650.0, -940.0, 20.0), aim( -8.0,110.0), 30.0),
       # close-up on the rails/sleepers material + OHE masts, near the NBD main line
       # aimed at the measured position of an actual OHE mast (-485.4,-906.6), not guessed
       ("rail_close", (-500.0, -930.0,  4.0), aim( -8.0, 32.0), 24.0),
       # component 3 pass 2 item 5: the S5 hill switchback, viewed from further out along its
       # own approach bearing (110 deg from hill centre) so the whole zigzag is visible
       ("s5_switchback", (-627.0, 746.0, 150.0), aim(-18.0, 290.0), 28.0),
       # component 3 pass 2 item 6: the S1 through-road's potholes/speed-breaker/culvert-stain.
       # position+heading measured off the road's own tangent at chainage 100 m (interpolated
       # from road_surface_features.json's own chainage-100 bracket), looking forward along the
       # road toward the 141/158/196/240-268/302 feature cluster.
       ("s1_road", (-313.48, 570.81, 1.3), aim(-1.0, 132.2), 28.0),
       # close range on the pothole cluster itself (chainage 240/241/243) with the speed
       # breaker just beyond it at 268 m - the S-scale distance these features are meant to
       # be seen at, not a wide establishing shot.
       ("s1_potholes", (-218.77, 490.28, 1.3), aim(-2.0, 132.2), 40.0),
       # component 4 pass 2 item 1: the S5 temple, at the climb's real measured terminus.
       # camera position/aim measured off TEMPLE_SANCTUM's own real bounding box (diag script),
       # not guessed - same method as every other scenario-specific shot in this list.
       ("temple", (-1056.79, 871.16, 31.49), aim(-20.3, 303.7), 24.0))

# the temple shot came back BLACK on the lab's own independent full-chain rebuild (11 Sep) even
# though every other shot in the same batch was fine - a hardcoded camera position measured off
# ONE local build cannot be trusted across separate rebuilds. Recompute it live from
# TEMPLE_SANCTUM's own real bounding box, same method as the diag script that found the working
# numbers in the first place, so this shot is self-correcting regardless of the root cause.
_temple_ob = bpy.data.objects.get("TEMPLE_SANCTUM")
if _temple_ob is not None:
    _corners = [_temple_ob.matrix_world @ Vector(co) for co in _temple_ob.bound_box]
    _minv = Vector((min(c.x for c in _corners), min(c.y for c in _corners), min(c.z for c in _corners)))
    _maxv = Vector((max(c.x for c in _corners), max(c.y for c in _corners), max(c.z for c in _corners)))
    _center = (_minv + _maxv) / 2
    _size = (_maxv - _minv).length
    _dist = _size * 2.2
    _camloc = _center + Vector((_dist*0.9, -_dist*0.6, _dist*0.4))
    _fwd = (_center - _camloc).normalized()
    _elev = math.degrees(math.asin(_fwd.z))
    _az = math.degrees(math.atan2(_fwd.x, _fwd.y)) % 360
    SHOTS = tuple((nm, tuple(_camloc), aim(_elev, _az), lens) if nm == "temple" else (nm, loc, fwd_, lens)
                  for nm, loc, fwd_, lens in SHOTS)
    print(f"temple shot recomputed live: cam {tuple(round(v,1) for v in _camloc)}, "
          f"elev {_elev:.1f}, az {_az:.1f}")

dg=bpy.context.evaluated_depsgraph_get()
def ground_at(x,y):
    hit,loc_,_,_,_,_ = sc.ray_cast(dg, Vector((x,y,3000.0)), Vector((0,0,-1)))
    return loc_.z if hit else 0.0
for nm,loc,fwd,lens in SHOTS:
    if ONLY and nm not in ONLY: continue
    x,y,z = loc
    if z <= 3.0:
        # ANY eye-level shot is GROUND-RELATIVE. Only "eye" was, so the galli camera at an
        # absolute z=1.3 sat under the ground and rendered a grey wall.
        z = ground_at(x,y)+1.30      # 1.30 m ABOVE THE GROUND, not absolute
    cam.location=(x,y,z); cam.data.lens=lens
    cam.rotation_euler=fwd.to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=os.path.join(OUT,f"{TAG}_{nm}")
    t=time.time(); bpy.ops.render.render(write_still=True)
    print(f"  {TAG}_{nm}: {time.time()-t:.1f}s", flush=True)
print("PREVIEW DONE")
