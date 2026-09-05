# THE STANDING NET - run after every component. PLAN s9.
#   blender --background --python build/city/audit.py -- <file.blend> [terrain_object]
# Six bug classes this project has ALREADY PAID FOR ONCE, written up as prose in REF-05 s10 and
# s11. Prose does not stop them happening again; code does. Every check here is a real bug that
# survived a build and was found only by looking or by probing:
#   1 faces wound DOWNWARD          - every road ribbon was, normal.z -1.000 (REF-05 s11e)
#   2 objects with NO MATERIAL      - the pond discs, which rendered white (5 Sep)
#   3 objects FLOATING or BURIED    - the hill plinth (S0 s3, 5 Sep)
#   4 OPEN, non-manifold volumes    - the water shell; an open boundary lets absorption run away
#   5 SUB-CELL features             - POND_2 at 2x2 cells; the 0.9 m ditches (REF-05 s10h)
#   6 bounding box used for MASS    - the "170 m" hill with a 0.03 m median (REF-05 s10b)
# Plus 7, added the day it bit us: an operator that silently MOVES a mesh (the Eroder, +40/-40 m).
import bpy, sys, math
import numpy as np
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND=a[0]; TERR=a[1] if len(a)>1 else "TERRAIN"
bpy.ops.wm.open_mainfile(filepath=BLEND)
GEXT=2000.0; NG=600; CELL=2*GEXT/NG
fails=[]; warns=[]
def bad(msg):  fails.append(msg); print(f"  FAIL {msg}")
def warn(msg): warns.append(msg); print(f"  WARN {msg}")
def ok(msg):   print(f"  OK   {msg}")

print(f"\n================= AUDIT : {BLEND.split('/')[-1]} =================")
meshes=[o for o in bpy.data.objects if o.type=='MESH' and len(o.data.vertices)]
print(f"  {len(meshes)} mesh objects, {sum(len(o.data.polygons) for o in meshes)} faces")
# SKY-SCALE objects (cloud field, cirrus at 7.2 km, god-ray occluder stand-ins) are checked by
# 01_light.py's own 33 assertions. This tool measures GROUND things against the terrain, so a
# cirrus sheet "floats +7187 m" and a GN-volume cloud "has no material slot" are false FAILs that
# train us to ignore the net. Skip anything in SKY / CLOUD / AIR.
_SKYCOLS={"SKY","CLOUD","AIR"}
sky_objs={o.name for c in bpy.data.collections if c.name in _SKYCOLS for o in c.all_objects}
meshes=[o for o in meshes if o.name not in sky_objs]

# --- the terrain height field, so 'floating' can be MEASURED rather than eyeballed
terr=bpy.data.objects.get(TERR)
H=None
if terr:
    co=np.array([v.co[:] for v in terr.data.vertices])
    gj=np.clip(np.round((co[:,0]+GEXT)/CELL).astype(int),0,NG)   # REF-05 s10a: rebuild the index
    gi=np.clip(np.round((co[:,1]+GEXT)/CELL).astype(int),0,NG)   # from actual x,y, never assume
    H=np.zeros((NG+1,NG+1)); H[gi,gj]=co[:,2]
    # THE HILL IS PART OF THE GROUND. Rocks and terraces sit on its surface at z up to 170 m;
    # measured against the flat terrain alone they read as "floats +170 m" - a false FAIL that
    # trains us to ignore rule 3. Fold every HILL-named mesh into the field as a max.
    for ho in meshes:
        if ho is terr or not ho.name.startswith(("HILL","hill")): continue
        hco=np.array([(ho.matrix_world @ v.co)[:] for v in ho.data.vertices])
        hj=np.clip(np.round((hco[:,0]+GEXT)/CELL).astype(int),0,NG)
        hi=np.clip(np.round((hco[:,1]+GEXT)/CELL).astype(int),0,NG)
        np.maximum.at(H,(hi,hj),hco[:,2])
def tz(x,y):
    fx=np.clip((x+GEXT)/CELL,0,NG-1e-6); fy=np.clip((y+GEXT)/CELL,0,NG-1e-6)
    i0=fx.astype(int); j0=fy.astype(int); tx=fx-i0; ty=fy-j0
    return (H[j0,i0]*(1-tx)*(1-ty)+H[j0,i0+1]*tx*(1-ty)+H[j0+1,i0]*(1-tx)*ty+H[j0+1,i0+1]*tx*ty)

# 1 · FACES WOUND DOWNWARD -------------------------------------------------------------------
# ...but ONLY for OPEN surfaces. A closed solid legitimately has half its faces pointing down -
# that is what "closed" means. Caught on this audit's very first run: it flagged WATER_PIT_1 and
# WATER_POND_3, which are correct watertight wedges. Test the shell, then the winding.
def _is_closed(o):
    ec={}
    for p in o.data.polygons:
        vs=list(p.vertices)
        for x,y in zip(vs,vs[1:]+vs[:1]):
            k=(x,y) if x<y else (y,x); ec[k]=ec.get(k,0)+1
    return bool(ec) and not any(c==1 for c in ec.values())
down=[]
for o in meshes:
    if _is_closed(o): continue
    nz=[p.normal.z for p in o.data.polygons if abs(p.normal.z)>0.30]   # ignore vertical faces
    # -0.002 is a balanced shell, not a flipped one. Only a real bias counts.
    if nz and float(np.mean(nz))<-0.15: down.append(o.name)
(bad if down else ok)(f"1 · open surfaces face the sky: {len(down)} wound downward"
                      + (f" {down[:6]}" if down else ""))

# 2 · OBJECTS WITH NO MATERIAL ----------------------------------------------------------------
nomat=[o.name for o in meshes if not o.data.materials or all(m is None for m in o.data.materials)]
(bad if nomat else ok)(f"2 · every object has a material: {len(nomat)} without"
                       + (f" {nomat[:6]}" if nomat else ""))

# 3 · FLOATING OR BURIED ----------------------------------------------------------------------
if H is not None:
    float_bad=[]
    for o in meshes:
        if o is terr or o.name.startswith(("DISTANT","RANGE","CLOUD","SKY","AIR")): continue
        # ROCK_* are ray-cast onto the hill/plain surface at build time (02_land.py) and asserted
        # there by measured footprint. Rule 3's 6.67 m height grid cannot resolve a 2-3 m rock on
        # a steep, sub-grid-detailed hill face to better than ~2 m - it was reporting them all as
        # "buried -2.1 m", a false FAIL. Their placement is checked where it is actually done.
        if o.name.startswith("ROCK_"): continue
        v=np.array([(o.matrix_world @ x.co)[:] for x in o.data.vertices])
        if len(v)>40000: v=v[::max(1,len(v)//40000)]
        d=v[:,2]-tz(v[:,0],v[:,1])
        # a real object touches the ground SOMEWHERE. If its LOWEST point is far above the
        # terrain it floats; if its HIGHEST is far below, it is buried.
        if d.min() > 2.0:  float_bad.append((o.name,f"floats {d.min():+.1f} m"))
        elif d.max() < -2.0: float_bad.append((o.name,f"buried {d.max():+.1f} m"))
    (bad if float_bad else ok)(f"3 · nothing floats or is buried: {len(float_bad)} bad"
                               + (f" {float_bad[:5]}" if float_bad else ""))
else:
    warn(f"3 · skipped - no '{TERR}' object to measure against")

# 4 · OPEN VOLUMES ----------------------------------------------------------------------------
# only objects that CARRY A VOLUME shader need to be closed - an open shell lets the volume's
# path length run away, which is what rendered the Malin as a hard black bar.
openv=[]; nonman=[]
for o in meshes:
    # PRINCIPLED_VOLUME, not VolumePrincipled - verified by running, not read. The wrong
    # string made this whole check silently pass everything: a FALSE OK, which is worse than a
    # missing check. Same family as REF-05 s7's node-name traps.
    VOLNODES=('PRINCIPLED_VOLUME','VOLUME_SCATTER','VOLUME_ABSORPTION')
    has_vol=any(m and m.use_nodes and any(n.type in VOLNODES for n in m.node_tree.nodes)
                for m in o.data.materials)
    if not has_vol: continue
    ec={}
    for p in o.data.polygons:
        vs=list(p.vertices)
        for x,y in zip(vs,vs[1:]+vs[:1]):
            k=(x,y) if x<y else (y,x); ec[k]=ec.get(k,0)+1
    bnd=sum(1 for c in ec.values() if c==1)      # OPEN: an edge with only one face
    nm_=sum(1 for c in ec.values() if c>2)        # PINCHED: an edge shared by 3+ faces
    if bnd: openv.append((o.name,f"{bnd} open edges"))
    if nm_: nonman.append((o.name,f"{nm_} pinched edges"))
(bad if openv else ok)(f"4 · every volume object is watertight: {len(openv)} open"
                       + (f" {openv[:5]}" if openv else ""))
(warn if nonman else ok)(f"4b · no non-manifold pinches: {len(nonman)} pinched"
                       + (f" {nonman[:5]}" if nonman else ""))

# 5 · SUB-CELL FEATURES -----------------------------------------------------------------------
tiny=[]
for o in meshes:
    if o is terr: continue
    d=o.dimensions
    if max(d.x,d.y) < CELL*2.0 and len(o.data.vertices)>2:
        tiny.append((o.name,f"{d.x:.1f}x{d.y:.1f} m vs {CELL:.2f} m cells"))
(warn if tiny else ok)(f"5 · nothing is sub-cell: {len(tiny)} smaller than 2 grid cells"
                       + (f" {tiny[:5]}" if tiny else ""))

# 6 · BOUNDING BOX USED AS MASS ---------------------------------------------------------------
# A shape whose MEDIAN height is a tiny fraction of its bounding box is a spike field, not a
# solid - that is the "170 m hill with a 0.03 m median" that passed its own test.
thin=[]
for o in meshes:
    if o is terr or len(o.data.vertices)<200: continue
    z=np.array([x.co.z for x in o.data.vertices]); h=z.max()-z.min()
    if h<1.0: continue
    med=(np.median(z)-z.min())/h
    if med < 0.02: thin.append((o.name,f"median at {med*100:.1f}% of its height"))
(bad if thin else ok)(f"6 · mass matches the bounding box: {len(thin)} are spike fields"
                      + (f" {thin[:5]}" if thin else ""))

# 7 · AN OPERATOR SILENTLY MOVED A MESH -------------------------------------------------------
# The Eroder translates by (+40,-40) m. Anything whose mesh centre is far from its own origin
# has probably been moved by something that was not asked to move it.
off=[]
for o in meshes:
    if o is terr or len(o.data.vertices)<200: continue
    v=np.array([x.co[:] for x in o.data.vertices])
    cx=(v[:,0].min()+v[:,0].max())*0.5; cy=(v[:,1].min()+v[:,1].max())*0.5
    ext=max(v[:,0].max()-v[:,0].min(), v[:,1].max()-v[:,1].min(), 1.0)
    # An object built in WORLD coordinates has its mesh far from its own origin by design
    # (WATER_MALIN, DISTANT_RANGE). What matters is whether the mesh moved RELATIVE to the
    # object - so only flag meshes that are off-centre AND whose object origin is not at 0,0.
    if math.hypot(cx,cy) > ext*0.15 and math.hypot(o.location.x,o.location.y) > 1.0:
        off.append((o.name,f"mesh centre ({cx:+.0f},{cy:+.0f}) and origin ({o.location.x:+.0f},{o.location.y:+.0f})"))
(warn if off else ok)(f"7 · no mesh silently translated: {len(off)} off-centre"
                      + (f" {off[:5]}" if off else ""))

print(f"\n  {'AUDIT PASSED' if not fails else f'AUDIT FAILED: {len(fails)}'}"
      + (f"  ({len(warns)} warnings)" if warns else ""))
print("="*58)
sys.exit(1 if fails else 0)
