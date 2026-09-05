# COMPONENT 3 - ROADS. All 213 roads, built from map/matlab_roads.csv, which is MATLAB's own
# export and therefore the SOURCE OF TRUTH: the road the planner drives and the road the camera
# sees are the same numbers by construction. Spec: S0 s4 "COMPONENT 3 - HOW THE ROADS ARE BUILT".
#   blender --background --python build/city/03_roads.py
# Opens 02_LAND.blend, CONFORMS THE TERRAIN to each corridor (roads are cut into land, REF-07 s1),
# then lays the ribbons on the conformed ground with 2.5% camber. Asserts in metres, fails loudly.
import bpy, bmesh, math, os, sys, csv, json, time
import numpy as np
T0=time.time()
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
LAND=f"{REF}/blend/02_LAND.blend"; OUT=f"{REF}/blend/03_ROADS.blend"

# ---------------------------------------------------------------- the numbers
GEXT=2000.0; NG=600; CELL=2*GEXT/NG
MATLAB_OFFSET=np.array([35.0,-100.0])   # MATLAB frame -> OSM metric frame. ONE number, shared
                                        # with the integrator chat's ego_S1.csv. S0 s4.
BOX=1000.0                              # the "2 km box" the 42.1 km figure is measured in
# S0 s4's table, carriageway width in metres
WIDTH={'trunk':14.0,'trunk_link':7.0,'secondary':7.0,'tertiary':7.0,'unclassified':5.5,
       'residential':4.5,'living_street':3.2,'service':3.0,'track':3.0}
KACCHA={'service','track'}              # earth, not asphalt - a material mask, not geometry
CAMBER=0.025                            # 2.5%, PLAN s3
VERGE=3.2                               # how far the conform feathers out past the carriageway
MAX_GRADE=0.06                          # audit: 6% on the plain
SHOULDER=0.15                           # the road sits this far proud of the conformed ground
SKIRT=0.55                              # the shoulder drop hanging below each road edge
SHOULDER_W=1.25                         # earth shoulder each side: the FORMATION is wider than
                                        # the carriageway (IRC), and the grid needs the width
CONFORM_MIN=1.15                        # ...and never conform a corridor narrower than this many
                                        # terrain cells, or the grid cannot carry it at all

# ---------------------------------------------------------------- load, and put both in ONE frame
rows=[(float(a),float(b),int(float(c))) for a,b,c in csv.reader(open(f"{REF}/map/matlab_roads.csv"))]
segs={}
for x,y,rid in rows: segs.setdefault(rid,[]).append((x,y))
segs={k:np.array(v)+MATLAB_OFFSET for k,v in segs.items() if len(v)>=2}
J=json.load(open(f"{REF}/map/najibabad_metres.json"))['roads']
print(f"matlab_roads.csv: {len(rows)} points in {len(segs)} segments; OSM json: {len(J)} tagged ways")

def seg_dist(P, pts):
    """point-to-SEGMENT distance, vectorised. REF-05 s4: never point-to-point."""
    d=np.full(len(P),1e9)
    for i in range(len(pts)-1):
        a=pts[i]; b=pts[i+1]; ab=b-a; L2=float(ab@ab)
        if L2<1e-9: continue
        t=np.clip(((P-a)@ab)/L2,0,1)[:,None]
        d=np.minimum(d, np.linalg.norm(P-(a+t*ab),axis=1))
    return d

JP=[np.array(r['pts']) for r in J]

# CLASSIFY PER POINT, NOT PER SEGMENT - measured 5 Sep, and the measurement is why.
# Matching whole CSV segments to their nearest way left 11 of the 213 ways with nothing, and the
# class counts short. But every one of those 11 has CSV points sitting 0.07-4.58 m ON it: they are
# SHORT ways (39-134 m) that lost the arg-min to a longer neighbour. MATLAB's export covers them;
# the classifier was the bug. And a MATLAB segment can legitimately span several OSM ways with
# DIFFERENT classes, so one width per segment would be wrong anyway.
# So: assign every point to its own nearest way, smooth the assignment so it cannot flap at a
# junction, then SPLIT each segment into runs of one way. Class changes land where the tags change.
def assign_ways(P):
    D=np.empty((len(P),len(JP)))
    for k,q in enumerate(JP): D[:,k]=seg_dist(P,q)
    a=D.argmin(1)
    if len(a)>=3:                                  # 3-point mode filter: no single-point flapping
        b=a.copy()
        for i in range(1,len(a)-1):
            if a[i-1]==a[i+1] and a[i]!=a[i-1]: b[i]=a[i-1]
        a=b
    return a, D[np.arange(len(P)),a]

# ---------------------------------------------------------------- the terrain, as a grid again
bpy.ops.wm.open_mainfile(filepath=LAND)
terr=bpy.data.objects["TERRAIN"]
co=np.array([v.co[:] for v in terr.data.vertices])
# REF-05 s10a: NEVER assume vertex order survives anything. Rebuild the index from actual x,y.
gj=np.clip(np.round((co[:,0]+GEXT)/CELL).astype(int),0,NG)
gi=np.clip(np.round((co[:,1]+GEXT)/CELL).astype(int),0,NG)
H=np.zeros((NG+1,NG+1)); H[gi,gj]=co[:,2]
X,Y=np.meshgrid(np.linspace(-GEXT,GEXT,NG+1),np.linspace(-GEXT,GEXT,NG+1),indexing='xy')
print(f"terrain re-read as a {NG+1}x{NG+1} grid, z {H.min():.2f}..{H.max():.2f} m")

def terrain_z(wx,wy,field=None):
    F=H if field is None else field
    fx=np.clip((wx+GEXT)/CELL,0,NG-1e-6); fy=np.clip((wy+GEXT)/CELL,0,NG-1e-6)
    i0=fx.astype(int); j0=fy.astype(int); tx=fx-i0; ty=fy-j0
    return (F[j0,i0]*(1-tx)*(1-ty)+F[j0,i0+1]*tx*(1-ty)+F[j0+1,i0]*(1-tx)*ty+F[j0+1,i0+1]*tx*ty)

# ---------------------------------------------------------------- resample + profile each road
def resample(pts, step=4.0):
    d=np.r_[0.0,np.cumsum(np.linalg.norm(np.diff(pts,axis=0),axis=1))]
    if d[-1]<step: return pts, d[-1]
    u=np.arange(0,d[-1],step)
    return np.c_[np.interp(u,d,pts[:,0]),np.interp(u,d,pts[:,1])], d[-1]

# THE PROFILE IS COMPUTED ONCE PER SEGMENT AND THEN SLICED - it must not be recomputed per piece.
# Smoothing and gradient-limiting each piece on its own made neighbouring pieces disagree at the
# vertex they share, and that step is the visible break in the trunk road at the chowk.
def profile(P):
    """the road's own longitudinal profile: sample, SMOOTH, then limit the gradient.
    REF-05 s10d: the other order lets the smoothing put the violations back."""
    z=terrain_z(P[:,0],P[:,1])
    for _ in range(14):
        z=np.convolve(np.pad(z,1,mode='edge'),[0.25,0.5,0.25],mode='same')[1:-1]
    d=np.r_[0.0,np.cumsum(np.linalg.norm(np.diff(P,axis=0),axis=1))]
    for i in range(1,len(z)):
        z[i]=min(z[i], z[i-1]+MAX_GRADE*(d[i]-d[i-1]))
    for i in range(len(z)-2,-1,-1):
        z[i]=min(z[i], z[i+1]+MAX_GRADE*(d[i+1]-d[i]))
    return z

ROADS=[]
for rid,pts in sorted(segs.items()):
    P,L=resample(pts)
    if len(P)<2: continue
    a,err=assign_ways(P)
    Z=profile(P)                                   # ONE profile for the whole segment
    starts=[0]+[i for i in range(1,len(a)) if a[i]!=a[i-1]]
    ends=starts[1:]+[len(a)]
    for si,(s0,s1) in enumerate(zip(starts,ends)):
        lo=max(0,s0-1) if si>0 else s0
        Q=P[lo:s1]; Zq=Z[lo:s1]
        if len(Q)<2: continue
        k=int(a[s0])
        d=float(np.linalg.norm(np.diff(Q,axis=0),axis=1).sum())
        ROADS.append(dict(rid=f"{rid}_{si}", way=J[k]['id'], cls=J[k]['class'] or 'residential',
                          bridge=bool(J[k]['bridge']), name=J[k]['name'], P=Q, L=d, z=Zq,
                          err=float(np.median(err[s0:s1]))))
print(f"classified per point and split at tag changes: {len(ROADS)} pieces covering "
      f"{len(set(r['way'] for r in ROADS))} of {len(J)} ways, median match error "
      f"{np.median([r['err'] for r in ROADS]):.2f} m")

# ---------------------------------------------------------------- 1 · CONFORM THE TERRAIN
# Roads are CUT INTO land (REF-07 s1, REF-08 s4). Level each corridor across its width to the
# road's own longitudinal profile, feathered out over the verge, so the road neither floats nor
# buries. Done on the height FIELD, then written back to the mesh once.
print("conforming the terrain to the road corridors ...")
Zc=np.zeros_like(H); Wsum=np.zeros_like(H)   # ACCUMULATE ONLY the road profile here:
# starting from H.copy() mixed the untouched ground into the weighted mean and left the
# ribbons a median of 5.7 m above the terrain. Measured by the float assertion, not guessed.
for r in ROADS:
    P=r['P']; z=r['z']
    # THE CONFORMED CORRIDOR MUST BE SOMETHING THE GRID CAN CARRY. REF-05 s10h: sub-cell features
    # simply do not exist. A 4.5 m residential lane is NARROWER THAN ONE 6.67 m terrain cell, so
    # levelling only its carriageway left the ground interpolating back up through the ribbon -
    # that is the ragged, half-buried edge in rd_chowk. Real roads sit on a FORMATION wider than
    # the carriageway anyway (carriageway + shoulders), so widening is right twice over.
    half=max(WIDTH[r['cls']]*0.5 + SHOULDER_W, CONFORM_MIN*CELL)
    # paint it into the height field over the corridor + verge
    lo=np.array([P[:,0].min()-half-VERGE-CELL, P[:,1].min()-half-VERGE-CELL])
    hi=np.array([P[:,0].max()+half+VERGE+CELL, P[:,1].max()+half+VERGE+CELL])
    j0=max(0,int((lo[0]+GEXT)/CELL)); j1=min(NG,int((hi[0]+GEXT)/CELL)+1)
    i0=max(0,int((lo[1]+GEXT)/CELL)); i1=min(NG,int((hi[1]+GEXT)/CELL)+1)
    if j1<=j0 or i1<=i0: continue
    sx=X[i0:i1+1,j0:j1+1].ravel(); sy=Y[i0:i1+1,j0:j1+1].ravel()
    Q=np.c_[sx,sy]
    dd=np.full(len(Q),1e9); zz=np.zeros(len(Q))
    for i in range(len(P)-1):
        a=P[i]; b=P[i+1]; ab=b-a; L2=float(ab@ab)
        if L2<1e-9: continue
        t=np.clip(((Q-a)@ab)/L2,0,1)
        dist=np.linalg.norm(Q-(a+t[:,None]*ab),axis=1)
        m=dist<dd
        dd=np.where(m,dist,dd); zz=np.where(m, z[i]+t*(z[i+1]-z[i]), zz)
    w=np.clip(1.0-(dd-half)/max(VERGE,1e-6),0,1)   # 1 on the carriageway, 0 past the verge
    w=w*w*(3-2*w)                                   # smoothstep, so no crease at the verge
    sel=w>1e-4
    if not sel.any(): continue
    ii=np.repeat(np.arange(i0,i1+1),(j1-j0+1)); jj=np.tile(np.arange(j0,j1+1),(i1-i0+1))
    ii=ii[sel]; jj=jj[sel]
    np.add.at(Zc,(ii,jj),zz[sel]*w[sel]); np.add.at(Wsum,(ii,jj),w[sel])
m=Wsum>1e-4
Zroad=np.where(m, Zc/np.maximum(Wsum,1e-9), H)   # weighted mean where corridors overlap (junctions)
a=np.clip(Wsum,0,1)
Hnew=H*(1-a)+Zroad*a
_moved=int((np.abs(Hnew-H)>0.02).sum())
print(f"  terrain conformed: {_moved} of {H.size} grid nodes moved, max {np.abs(Hnew-H).max():.2f} m")
for n,v in enumerate(terr.data.vertices): v.co.z=float(Hnew[gi[n],gj[n]])
terr.data.update()

# ---------------------------------------------------------------- 2 · THE RIBBONS
print("building the ribbons ...")
COL={}
for nm in ("ROADS","ROADS_KACCHA"):
    c=bpy.data.collections.new(nm); bpy.context.scene.collection.children.link(c); COL[nm]=c
def ribbon(r):
    P=r['P']; z=r['z']; half=WIDTH[r['cls']]*0.5
    tang=np.zeros_like(P)
    tang[1:-1]=P[2:]-P[:-2]; tang[0]=P[1]-P[0]; tang[-1]=P[-1]-P[-2]
    n=np.linalg.norm(tang,axis=1,keepdims=True); n[n<1e-9]=1.0; tang/=n
    nor=np.c_[-tang[:,1],tang[:,0]]
    vs=[]; fs=[]; uvs=[]
    d=np.r_[0.0,np.cumsum(np.linalg.norm(np.diff(P,axis=0),axis=1))]
    # 7 across: a SKIRT, then the carriageway with its crown, then a skirt.
    # The skirt is the shoulder drop a real road has, and it also solves a build problem: the
    # terrain grid is 6.67 m and most lanes are narrower than one cell, so however well the
    # corridor is conformed the ground INTERPOLATES back up between nodes and pokes through a
    # flat ribbon. A vertical fringe hanging below each edge makes that impossible by geometry
    # instead of by tuning. REF-05 s10h: match the feature to what the grid can carry.
    OFF=(-1.0,-1.0,-0.5,0.0,0.5,1.0,1.0)
    DROP=(SKIRT,0.0,0.0,0.0,0.0,0.0,SKIRT)
    for i in range(len(P)):
        for o,dz in zip(OFF,DROP):
            q=P[i]+nor[i]*(o*half)
            vs.append((q[0],q[1], z[i]+SHOULDER - abs(o)*half*CAMBER - dz))   # 2.5% crown-to-edge
            uvs.append((0.5+o*0.5, d[i]/max(WIDTH[r['cls']],1e-6)))      # STRAIGHT STRIP UV
    for i in range(len(P)-1):
        for k in range(len(OFF)-1):
            a=i*len(OFF)+k; b=a+1; c=(i+1)*len(OFF)+k; dd=c+1
            fs.append((a,b,dd,c))
    me=bpy.data.meshes.new(f"ROAD_{r['rid']}")
    me.from_pydata(vs,[],fs); me.update()
    # THE ROAD MUST FACE THE SKY. Probing rd_s4trunk returned normal.z = -1.000 across the whole
    # carriageway: every ribbon was built wound the wrong way and we were looking at its underside.
    # Whether (a,b,d,c) comes out clockwise depends on the sign of the normal vector and the
    # direction of travel, so it cannot be fixed by choosing an order once - MEASURE and flip.
    # REF-07 s5 says the same thing about the water solid: recalculate, never assume.
    me.calc_loop_triangles()
    if float(np.mean([p.normal.z for p in me.polygons])) < 0.0:
        me.flip_normals(); me.update()
    uvl=me.uv_layers.new(name="UVMap")
    for poly in me.polygons:
        for li in poly.loop_indices:
            uvl.data[li].uv=uvs[me.loops[li].vertex_index]
    ob=bpy.data.objects.new(f"ROAD_{r['rid']}_{r['cls']}",me)
    COL["ROADS_KACCHA" if r['cls'] in KACCHA else "ROADS"].objects.link(ob)
    return ob

def asphalt():
    m=bpy.data.materials.new("ASPHALT"); m.use_nodes=True
    nt=m.node_tree; b=nt.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=(0.052,0.050,0.048,1.0)
    b.inputs["Roughness"].default_value=0.72
    nz=nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value=180.0
    nz.inputs["Detail"].default_value=8.0
    bp=nt.nodes.new("ShaderNodeBump"); bp.inputs["Strength"].default_value=0.22
    nt.links.new(nz.outputs["Fac"],bp.inputs["Height"]); nt.links.new(bp.outputs["Normal"],b.inputs["Normal"])
    return m
def kaccha():
    m=bpy.data.materials.new("KACCHA"); m.use_nodes=True
    b=m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=(0.208,0.163,0.108,1.0)   # earth, REF-04 s soil
    b.inputs["Roughness"].default_value=0.94
    return m
MA=asphalt(); MK=kaccha()
built=[]
for r in ROADS:
    ob=ribbon(r); ob.data.materials.append(MK if r['cls'] in KACCHA else MA)
    r['ob']=ob; built.append(ob)
print(f"  {len(built)} ribbons built")

# ---------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 3 - ROADS : ASSERTIONS =================")
fails=[]
def check(name,got,want,tol):
    ok=abs(got-want)<=tol; print(f"  {'OK  ' if ok else 'FAIL'} {name:52s} got {got:12.4f}  want {want:.4f}")
    if not ok: fails.append(name)
def flag(name,cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

import collections
cls_json=collections.Counter(r['class'] or 'residential' for r in J)
ways=set(r['way'] for r in ROADS)
flag(f"every OSM way is represented: {len(ways)} of {len(J)} ways carry at least one segment",
     len(ways)==len(J))
cls_built=collections.Counter()
for w in ways:
    cls_built[[r['class'] or 'residential' for r in J if r['id']==w][0]]+=1
for k,v in sorted(cls_json.items()):
    check(f"class count '{k}'", float(cls_built.get(k,0)), float(v), 0.0)

def clip_len(P,half=BOX):
    tot=0.0
    for i in range(len(P)-1):
        a,b=P[i],P[i+1]
        if max(abs(a[0]),abs(a[1]))<=half and max(abs(b[0]),abs(b[1]))<=half:
            tot+=float(np.linalg.norm(b-a))
    return tot
L_box=sum(clip_len(r['P']) for r in ROADS)/1000.0
L_all=sum(r['L'] for r in ROADS)/1000.0
check("total centreline inside the 2 km box (km) - S0 s4", L_box, 42.1, 2.5)
print(f"  INFO  centreline over the whole 4 km ground: {L_all:.1f} km")

for cls in sorted(set(r['cls'] for r in ROADS)):
    ob=[r for r in ROADS if r['cls']==cls][0]['ob']
    v=np.array([x.co[:] for x in ob.data.vertices])
    # measure the built width ACROSS the ribbon, not from the parameter that produced it
    w=float(np.linalg.norm(v[5,:2]-v[1,:2]))   # carriageway edges, inside the skirts
    check(f"measured carriageway width '{cls}' (m)", w, WIDTH[cls], 0.05)

r0=[r for r in ROADS if r['cls']=='trunk'][0]
v=np.array([x.co[:] for x in r0['ob'].data.vertices])
crown=float(v[3,2]-v[1,2]); halfw=WIDTH['trunk']*0.5   # crown minus carriageway edge
check("measured camber, crown to edge (%)", crown/halfw*100.0, CAMBER*100.0, 0.15)

grades=[]
for r in ROADS:
    d=np.r_[0.0,np.cumsum(np.linalg.norm(np.diff(r['P'],axis=0),axis=1))]
    if len(d)>1:
        g=np.abs(np.diff(r['z'])/np.maximum(np.diff(d),1e-6))
        if len(g): grades.append(g.max())
flag(f"gradient never exceeds {MAX_GRADE*100:.0f}% on the plain (worst {max(grades)*100:.2f}%)",
     max(grades)<=MAX_GRADE+1e-6)

# NO ROAD FLOATS. Measure the ribbon against the CONFORMED terrain, everywhere, not assume it.
gaps=[]
for r in ROADS:
    v=np.array([x.co[:] for x in r['ob'].data.vertices])
    keep=np.ones(len(v),dtype=bool); keep[0::7]=False; keep[6::7]=False   # skip the skirt verts:
    v=v[keep]                                                            # they hang below by design
    tz=terrain_z(v[:,0],v[:,1],Hnew)
    gaps.append(np.abs(v[:,2]-SHOULDER-tz))
G=np.concatenate(gaps)
check("road-to-ground gap, MEDIAN over every ribbon vertex (m)", float(np.median(G)), 0.0, 0.12)
flag(f"no road floats: 99th pct gap {np.percentile(G,99):.2f} m, worst {G.max():.2f} m (want <1.5)",
     float(np.percentile(G,99))<1.5)
_down=[]
for r in ROADS:
    nz=[p.normal.z for p in r['ob'].data.polygons if abs(p.normal.z)>0.3]   # skip vertical skirts
    if nz and float(np.mean(nz))<0.0: _down.append(r['ob'].name)
flag(f"every road faces the sky: {len(_down)} of {len(ROADS)} ribbons wound downward", not _down)
print(f"  INFO  {len(built)} road objects, {sum(len(o.data.polygons) for o in built)} faces, "
      f"{len(bpy.data.objects)} objects in the file")
print(f"  INFO  build time {time.time()-T0:.0f}s")
print("\n  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("="*66)
bpy.ops.wm.save_mainfile(filepath=OUT)
print(f"\nsaved: {OUT}")
if fails: sys.exit(1)
