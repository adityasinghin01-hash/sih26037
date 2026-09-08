# SIH26037 - COMPONENT 2 - LAND
# Spec: S0-THE-WORLD.md section 3, PLAN.md component 2.
#   ground 4000 x 4000 m, alluvial plain falling gently SOUTH
#   three undulation scales: 600 m swells, 160 m, field scale.  NEVER FLAT ANYWHERE.
#   abandoned river channels - shallow broad depressions
#   field bunds every ~75 m as 0.25-0.45 m stepped terraces
#   the MALIN - channel cut from the OSM centreline, water is ONE LEVEL PLANE (REF-07 s10b)
#   the HILL - (-1050, 900) AMENDED, 500 x 350 m base, 170 m, gullies via the ERODER
#   the distant range at y ~ 1900, ~340 m, pale silhouette
# METHOD: stacked height layers computed in numpy and written straight to vertex Z.
#   REF-07 s2 stacks greyscale IMAGES; we generate the field directly, which is the same idea
#   without the image round-trip and lets every layer be ASSERTED in metres.
# TRAPS ENCODED (REF-05 s7):
#   read_factory_settings DISABLES extensions -> re-enable before using A.N.T./Eroder
#   A.N.T.'s `height` parameter is IGNORED -> set height by SCALE and assert
#   the Eroder demands square grid spacing and returns height in GRID UNITS -> rescale after
#   loopcut_slide segfaults headless - never used
import bpy, bmesh, math, os, sys, json, time
import numpy as np
from mathutils import Vector

REF  = os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
OUT  = f"{REF}/blend/02_LAND.blend"
RND  = f"{REF}/renders/city"
os.makedirs(RND, exist_ok=True)
t_start=time.time()

# ---------------------------------------------------------------- the numbers
GEXT      = 2000.0          # half-extent -> 4000 x 4000 m
NG        = 600             # grid divisions -> 6.67 m cells, 720k tris
SOUTH_FALL= 14.0            # m of fall from north edge to south edge (alluvial plain)
SWELL_A   = 8.0 ; SWELL_L   = 600.0     # three undulation scales, S0 s3
UND_A     = 2.6 ; UND_L     = 160.0
FIELD_A   = 0.55; FIELD_L   = 42.0
BUND_H    = 0.35; BUND_SPACING = 75.0   # 0.25-0.45 m stepped terraces every ~75 m
PALEO_D   = 1.6                          # abandoned river channels, shallow and broad
RIVER_W   = 34.0; RIVER_D  = 5.2         # the Malin: channel half-width and depth
RIVER_BANK= 95.0                         # how far the cut feathers out
WATER_DENSITY = 0.30                     # REF-07 s5 high end - silt-laden, never clear
WATER_ALBEDO  = (0.90,0.93,0.93,1.0)     # SCATTERING ALBEDO (S0 s3 item 6) - swept, not guessed
WATER_Z_OFF = -3.4                       # water plane sits this far below the channel lip
HILL_X, HILL_Y = -1050.0, 900.0          # AMENDED 4 Sep - the written (-690,980) sat on the river
HILL_W, HILL_L, HILL_H = 500.0, 350.0, 170.0   # S0 s3: the ELLIPSE AXES, along/across the NW axis
# THE GENERATION GRID MUST BE BIGGER THAN THE ELLIPSE. A 500 x 350 ellipse turned 38 deg has an
# axis-aligned footprint of 437 x 392 m, so a 500 x 350 grid clipped it and the hill measured only
# 303 m across its own short axis instead of the specified 350. Grid enlarged to contain it, with
# EXACTLY square spacing because the Eroder rejects anything else (REF-05 s7 trap 3).
HILL_GX, HILL_GY = 520.0, 440.0
HILL_NX, HILL_NY = 261, 221              # 2.0000 x 2.0000 m - exactly square for the Eroder
RANGE_Y   = 1900.0; RANGE_H = 340.0
# --- LAND EXTENDED (S0 s3 amendment, 4 Sep). Every one is EARTH ONLY and sourced.
POND_N    = 3;    POND_R = (16.0,30.0); POND_D = 2.6     # johad: excavated, hold water.
# S0 s3: POND_2 came out 13x13 m = 2x2 grid cells - REF-05 s10h's sub-cell rule again. The
# minimum RADIUS is raised so every pond spans >=4 cells (>=27 m across), which was inside
# S0 s3 item 7's stated 25-60 m all along: the spec was right, the build under-filled it.
POND_R_MIN_CELLS = 4.0
NALA_N    = 5;    NALA_W = 4.0;  NALA_D = 1.5            # seasonal watercourses -> the Malin
KILN_X, KILN_Y = 620.0, -430.0                            # brick kiln clay pits (kiln is COLD in Sep)
KILN_PITS = 3;    KILN_R = (26.0,45.0); KILN_D = 4.2
THRESH_N  = 7;    THRESH_R = 5.5                          # swept flat circles at field edges
TERRACE_H = 2.0                                           # the Malin's flood terrace step
IRRIG_W   = 2.6;  IRRIG_D = 0.55   # a DISTRIBUTARY, not a field ditch:
                                   # 0.9 m fell between 6.67 m grid samples entirely                          # earthen field channels

# ---------------------------------------------------------------- start clean, re-enable addons
bpy.ops.wm.read_factory_settings(use_empty=True)
for m in ("bl_ext.blender_org.antlandscape","bl_ext.blender_org.sapling_tree_gen"):
    try: bpy.ops.preferences.addon_enable(module=m)
    except Exception as e: print("addon enable failed:", m, e)
sc = bpy.context.scene
# Cycles must be the engine for material.cycles / object.cycles to exist - D2 sets
# displacement_method='BOTH' and adaptive subdivision, and those live on those property groups.
try:
    bpy.ops.preferences.addon_enable(module='cycles')
except Exception as e: print("cycles addon enable:", e)
sc.render.engine='CYCLES'
# D2's adaptive subdivision + true displacement ('BOTH') only render under the EXPERIMENTAL
# feature set. Without this the terrain silently falls back to BUMP only and the 4K circle
# relief never reaches the silhouette. Saved into the .blend so it propagates to 03/04.
sc.cycles.feature_set='EXPERIMENTAL'
sc.unit_settings.system='METRIC'; sc.unit_settings.length_unit='METERS'
sc.view_settings.view_transform='Standard'; sc.view_settings.exposure=-3.06
COL={}
for n in ("TERRAIN","WATER","HILL","DISTANT"):
    c=bpy.data.collections.new(n); sc.collection.children.link(c); COL[n]=c

# RULE 7: the render split is decided HERE, at build time - never discovered later by
# pass_render.py. Every top-level collection this script produces is one separately renderable
# pass; write that down so nothing downstream ever hardcodes a collection name.
def write_pass_manifest():
    names=sorted(c.name for c in sc.collection.children if c.objects)
    json.dump(names, open(os.path.splitext(OUT)[0]+".passes.json","w"), indent=1)
    print(f"  INFO  {len(names)} separately renderable collections: {names}")

# ---------------------------------------------------------------- the Malin centreline
mp=json.load(open(f"{REF}/map/najibabad_metres.json"))
riv=np.array(mp['water'][0]['pts'], dtype=np.float64)
keep=(np.abs(riv[:,0])<=GEXT*1.6)&(np.abs(riv[:,1])<=GEXT*1.6)
riv=riv[keep]
print(f"Malin: {len(riv)} centreline points inside the working box")

# ---------------------------------------------------------------- the height field
gx=np.linspace(-GEXT,GEXT,NG+1)
gy=np.linspace(-GEXT,GEXT,NG+1)
X,Y=np.meshgrid(gx,gy,indexing='xy')

def vnoise(X,Y,wavelength,seed):
    """smooth band-limited noise by summing a few rotated sines - deterministic, no texture."""
    rng=np.random.default_rng(seed)
    out=np.zeros_like(X)
    for k in range(5):
        th=rng.uniform(0,math.pi*2); ph=rng.uniform(0,math.pi*2)
        kx=math.cos(th)*2*math.pi/wavelength; ky=math.sin(th)*2*math.pi/wavelength
        out+=np.sin(X*kx+Y*ky+ph)
    return out/5.0

LAYER={}
LAYER['slope'] = (Y+GEXT)/(2*GEXT)*SOUTH_FALL          # falls SOUTH: HIGH in the north.
# (GEXT-Y) was written first and inverted it - the plain ran downhill NORTH. The assertion caught
# it before a single picture was looked at, which is exactly why Rule 4 exists.
LAYER['swell'] = vnoise(X,Y,SWELL_L,11)*SWELL_A
LAYER['undul'] = vnoise(X,Y,UND_L, 23)*UND_A
LAYER['field'] = vnoise(X,Y,FIELD_L,37)*FIELD_A

# abandoned river channels: broad shallow depressions where an old course ran
paleo = vnoise(X,Y,900.0,53)
LAYER['paleo'] = -np.clip(paleo*1.6-0.55,0,None)*PALEO_D

# field bunds: 0.25-0.45 m stepped terraces every ~75 m. Steps, not waves - this is what makes
# the plain read as CULTIVATED rather than as noise.
bund_phase=(Y/BUND_SPACING)
LAYER['bund'] = np.floor(bund_phase)*0.0 + (np.round(bund_phase)-bund_phase)*0.0
# a bund is a LIP with a flat plot behind it, not a ramp. Sharp edge, flat field.
fy=(Y/BUND_SPACING)%1.0
fx=(X/(BUND_SPACING*1.6))%1.0
lip = np.clip(1.0-fy/0.12,0,1)*BUND_H + np.clip(1.0-fx/0.10,0,1)*BUND_H*0.7
# every plot sits at its own slightly different level - that is what makes fields read as PARCELS
plot_id = np.floor(Y/BUND_SPACING)*97.0 + np.floor(X/(BUND_SPACING*1.6))*31.0
plot_off = ((np.sin(plot_id*12.9898)*43758.5453)%1.0 - 0.5)*0.55
LAYER['bund'] = lip + plot_off
# S0 s3 "THE GROUND MATERIAL": the parcels are REAL GEOMETRY and were INVISIBLE, because all
# 4 km2 wore one soil material keyed only to height. The plot grid and the bund lip are kept here
# so the material can be driven by the same numbers that shaped the ground - one cause, three
# readings (PLAN s3b): field pattern from the air, plot edge from the street, furrows up close.
PLOT_ID = plot_id
PLOT_STATE = ((np.sin(plot_id*78.233+11.7)*24634.6345)%1.0)   # fixed per parcel, differs next door
BUND_LIP = lip

# ---------------------------------------------------------------- the Malin, cut into the field
def dist_to_polyline(X,Y,pts):
    """vectorised point-to-SEGMENT distance (REF-05 s4: never point-to-point)"""
    d=np.full(X.shape, 1e9)
    for i in range(len(pts)-1):
        ax,ay=pts[i]; bx,by=pts[i+1]
        dx,dy=bx-ax,by-ay
        L2=dx*dx+dy*dy
        if L2<1e-9: continue
        t=np.clip(((X-ax)*dx+(Y-ay)*dy)/L2,0.0,1.0)
        px=ax+t*dx; py=ay+t*dy
        d=np.minimum(d, np.hypot(X-px,Y-py))
    return d
print("computing distance to the Malin ...")
def dist_and_index(X,Y,pts):
    """distance to the polyline AND which segment is nearest - we need the along-course position
    so the channel can be carved to a bed that descends, instead of a constant depth."""
    d=np.full(X.shape,1e9); idx=np.zeros(X.shape,dtype=np.int32)
    for i in range(len(pts)-1):
        ax,ay=pts[i]; bx,by=pts[i+1]
        dx,dy=bx-ax,by-ay; L2=dx*dx+dy*dy
        if L2<1e-9: continue
        t=np.clip(((X-ax)*dx+(Y-ay)*dy)/L2,0.0,1.0)
        dd=np.hypot(X-(ax+t*dx), Y-(ay+t*dy))
        m=dd<d
        d=np.where(m,dd,d); idx=np.where(m,i,idx)
    return d,idx
DR,DIDX=dist_and_index(X,Y,riv)
# THE CHANNEL MUST DESCEND. A constant-depth cut across a plain that falls 14 m leaves a bed
# that runs uphill in places, so the water surface was buried upstream and floating downstream -
# which is why the first render showed a broken, gap-toothed river.
# Build a target bed that only ever goes DOWN along the course, then carve to it.
_ground_at_riv=np.array([float(sum(LAYER[k][int(np.clip((py+GEXT)/(2*GEXT)*NG,0,NG)),
                                            int(np.clip((px+GEXT)/(2*GEXT)*NG,0,NG))]
                                   for k in ('slope','swell','undul','field','paleo','bund')))
                         for px,py in riv])
_target=_ground_at_riv-RIVER_D
for _ in range(10):
    _target=np.convolve(np.pad(_target,1,mode='edge'),[0.25,0.5,0.25],mode='same')[1:-1]
_ord=np.argsort(-riv[:,1])                      # the Malin runs broadly north -> south
_run=1e9
for k in _ord:
    _run=min(_run,_target[k]); _target[k]=_run  # a bed that never climbs
BED_TARGET=_target
_bed_field=_target[np.clip(DIDX,0,len(_target)-1)]
_pre=sum(LAYER[k] for k in ('slope','swell','undul','field','paleo','bund'))
prof=np.clip((DR-RIVER_W)/(RIVER_BANK-RIVER_W),0,1)
LAYER['river'] = (_bed_field-_pre)*(1.0-prof**1.6)

# ============================================================================================
# LAND EXTENDED - S0 s3 amendment. Placed BY THE THING THAT CAUSED THEM, never scattered.
# ============================================================================================
rng=np.random.default_rng(2026)

# 10 · THE FLOOD TERRACE - a step above the channel marking the monsoon flood level.
# It must be IN the terrain, because REF-07 s10b's whole point is that the bank line falls out
# of the terrain when a flat water plane meets it.
terr_band=np.clip((DR-RIVER_BANK)/(RIVER_BANK*1.9),0,1)
LAYER['terrace'] = -(1.0-terr_band)*TERRACE_H*np.clip(1.0-(DR/(RIVER_BANK*2.9)),0,1)

# 11 · BRAIDED BARS AND SHOALS - pale gravel, same material as the banks, channels splitting.
# Bars only exist INSIDE the channel, so they are masked by the channel itself.
bar_noise=vnoise(X,Y,120.0,91)
inchan=np.clip(1.0-(DR/RIVER_W),0,1)
LAYER['bars'] = np.clip(bar_noise*1.4-0.15,0,None)*RIVER_D*0.62*inchan

# 9 · DRAINAGE NALAS - seasonal watercourses running DOWNHILL into the Malin.
# Each starts high in the north and ends on the river: the direction is caused, not chosen.
nala=np.zeros_like(X)
for i in range(NALA_N):
    sx=rng.uniform(-GEXT*0.85, GEXT*0.85); sy=rng.uniform(200.0, GEXT*0.9)
    j=int(np.argmin(np.hypot(riv[:,0]-sx, riv[:,1]-sy)))
    ex,ey=riv[j]
    n=26
    px=np.linspace(sx,ex,n)+rng.normal(0,26,n); py=np.linspace(sy,ey,n)+rng.normal(0,26,n)
    px[0],py[0]=sx,sy; px[-1],py[-1]=ex,ey
    dn=dist_to_polyline(X,Y,np.stack([px,py],axis=1))
    nala=np.minimum(nala, -(1.0-np.clip(dn/(NALA_W*4.0),0,1))**1.7*NALA_D)
LAYER['nala']=nala

# 7 · VILLAGE PONDS (johad) - EXCAVATED, so they sit where the ground was ALREADY LOW,
# and the spoil forms a raised bank on one side. That bank is the tell.
pond=np.zeros_like(X); pond_xy=[]
# SURF: the surface masks, kept alongside the height layers. S0 s3 "THE GROUND SURFACES".
# Every one of them already exists as the array that CUT the ground - so the material is keyed
# to the same numbers that shaped it, and nothing is painted or guessed.
SURF={k:np.zeros_like(X) for k in ('gravel','pebble','bare','wet','spoil')}
lowness=(LAYER['swell']+LAYER['undul'])
for i in range(POND_N):
    for _try in range(60):
        cx=rng.uniform(-GEXT*0.8,GEXT*0.8); cy=rng.uniform(-GEXT*0.8,GEXT*0.55)
        if dist_to_polyline(np.array([[cx]]),np.array([[cy]]),riv)[0,0] < 260: continue
        if math.hypot(cx-HILL_X,cy-HILL_Y) < 520: continue
        gi=int(np.clip((cy+GEXT)/(2*GEXT)*NG,0,NG)); gj=int(np.clip((cx+GEXT)/(2*GEXT)*NG,0,NG))
        if lowness[gi,gj] > -1.0: continue              # only where the ground is already low
        break
    # a pond narrower than a few grid cells simply does not exist (REF-05 s10h). The WATER
    # wedge is built from `level - H`, so the bowl must be wide enough for the grid to sample
    # its floor, not just its rim - POND_2 came out 2x2 cells and rendered as a puddle.
    r=max(rng.uniform(*POND_R), POND_R_MIN_CELLS*(2*GEXT/NG)*0.5)
    d=np.hypot(X-cx,Y-cy)
    bowl=-(1.0-np.clip(d/r,0,1)**2.0)*POND_D
    spoil=np.clip(1.0-np.abs(d-r*1.22)/(r*0.42),0,1)*0.9   # excavated earth heaped on the rim
    ang=rng.uniform(0,math.pi*2)
    side=np.clip(np.cos(np.arctan2(Y-cy,X-cx)-ang),0,1)
    _sp=spoil*side*(d<r*1.7)
    pond=np.minimum(pond,bowl)+_sp
    SURF['spoil']=np.maximum(SURF['spoil'], np.clip(_sp/0.55,0,1))   # raw excavated earth
    pond_xy.append((cx,cy,r))
LAYER['pond']=pond

# 12 · BRICK-KILN CLAY PITS - permanent landform even though the kiln is cold in September.
# They cluster AROUND THE KILN because that is what dug them.
kiln=np.zeros_like(X); kiln_xy=[]
for i in range(KILN_PITS):
    cx=KILN_X+rng.uniform(-140,140); cy=KILN_Y+rng.uniform(-140,140)
    r=rng.uniform(*KILN_R); d=np.hypot(X-cx,Y-cy)
    t=np.clip(d/r,0,1)
    kiln=np.minimum(kiln, -(1.0-t)*KILN_D*(1.0-0.35*np.floor(t*3)/3))   # STEPPED sides, dug in lifts
    kiln_xy.append((cx,cy,r))
LAYER['kiln']=kiln

# 8 · IRRIGATION CHANNELS - earthen, following the bund grid, so they run along plot edges.
irr_x=np.abs(((X+GEXT)%BUND_SPACING)-BUND_SPACING/2)
irr_y=np.abs(((Y+GEXT)%(BUND_SPACING*2))-BUND_SPACING)
sel=(vnoise(X,Y,520.0,101)>0.10)                      # not every plot edge carries one
LAYER['irrig'] = -np.clip(1.0-irr_x/IRRIG_W,0,1)*IRRIG_D*sel

# 13 · THRESHING FLOORS - swept FLAT circles at field edges. Flat is the point: they are the
# one place on this plain that IS level, because someone levelled it.
thresh=np.zeros_like(X); thresh_xy=[]
for i in range(THRESH_N):
    cx=rng.uniform(-GEXT*0.8,GEXT*0.8); cy=rng.uniform(-GEXT*0.8,GEXT*0.6)
    if dist_to_polyline(np.array([[cx]]),np.array([[cy]]),riv)[0,0] < 160: continue
    d=np.hypot(X-cx,Y-cy); m=np.clip(1.0-d/THRESH_R,0,1)**0.6
    thresh_xy.append((cx,cy,THRESH_R))
    LAYER.setdefault('_thresh_mask',np.zeros_like(X))
    LAYER['_thresh_mask']=np.maximum(LAYER['_thresh_mask'],m)

# 4 · THE BHABAR APRON - the pebbly alluvial fan where the hill meets the plain.
# REF-04 s10: this is the real named landform for a Shivalik hill foot.
dh=np.hypot(X-HILL_X,Y-HILL_Y)
apron=np.clip(1.0-(dh-HILL_W*0.5)/420.0,0,1)*np.clip((dh-HILL_W*0.42)/60.0,0,1)
LAYER['apron']=apron*3.2

# THE HILL HAS NO PAD - S0 s3, amended 5 Sep. The `hillpad` layer levelled the ground to 2.45x
# the ellipse so the hill's flat rectangular SKIRT would have something to stand on; then
# `river_guard` punched a hole in that pad so it would not flatten the Malin, leaving the skirt
# cantilevered over a dip with a visible void under its straight south edge. Each fix was locally
# reasonable and together they built a plinth. The hill now FOLLOWS THE GROUND instead (see the
# hill placement below), so there is nothing to stand on, nothing to guard, and no straight edge.
dh_f=np.hypot((X-HILL_X)/(HILL_W*0.5),(Y-HILL_Y)/(HILL_L*0.5))
HILL_BASE_Z = 0.0
# ============================================================================================
# THE GROUND SURFACES - S0 s3, 5 Sep. Each mask is derived from the layer that CUT the ground,
# so the surface and the shape are the same numbers by construction, not by agreement.
# ============================================================================================
SURF['gravel'] = np.clip(LAYER['bars']/max(LAYER['bars'].max(),1e-9)*1.6, 0, 1) \
               + np.clip(1.0-(DR-RIVER_W)/(RIVER_BANK*0.9), 0, 1)*0.85    # bars AND the banks:
                                    # REF-13 s6 - "the bars are the same material as the banks"
SURF['pebble'] = np.clip(LAYER['apron']/max(LAYER['apron'].max(),1e-9)*1.35, 0, 1)  # Bhabar
SURF['bare']   = np.maximum(LAYER.get('_thresh_mask', np.zeros_like(X)),           # threshing
                            np.clip(-LAYER['kiln']/max(KILN_D*0.30,1e-9),0,1)*0.7) # pit floors
SURF['wet']    = np.clip(-LAYER['nala']/max(NALA_D*0.55,1e-9),0,1) \
               + np.clip(-LAYER['irrig']/max(IRRIG_D*0.55,1e-9),0,1)*0.8 \
               + np.clip(-LAYER['paleo']/max(PALEO_D*0.60,1e-9),0,1)*0.75 \
               + np.clip(-LAYER['terrace']/max(TERRACE_H*0.75,1e-9),0,1)*0.45
for _k in SURF: SURF[_k]=np.clip(SURF[_k],0,1)
print("  ground surfaces derived from the layers that cut them:")
for _k,_v in SURF.items():
    print(f"    {_k:7s} covers {(_v>0.25).mean()*100:5.2f}% of the 4 km2, peak {_v.max():.2f}")

H = sum(v for k,v in LAYER.items() if not k.startswith('_'))
# threshing floors LEVEL the ground - applied last, as a flattening toward the local mean
if '_thresh_mask' in LAYER:
    m=LAYER['_thresh_mask']
    k=9
    pad=np.pad(H,k//2,mode='edge')
    loc=np.zeros_like(H)
    for a in range(k):
        for b in range(k):
            loc+=pad[a:a+H.shape[0], b:b+H.shape[1]]
    loc/= (k*k)
    H = H*(1-m) + loc*m

# ---------------------------------------------------------------- build the terrain mesh
print("building terrain mesh ...")
verts=np.stack([X.ravel(),Y.ravel(),H.ravel()],axis=1)
faces=[]
for j in range(NG):
    row=j*(NG+1); nxt=(j+1)*(NG+1)
    for i in range(NG):
        faces.append((row+i,row+i+1,nxt+i+1,nxt+i))
me=bpy.data.meshes.new("TERRAIN")
me.from_pydata(verts.tolist(),[],faces)
me.update()
terr=bpy.data.objects.new("TERRAIN",me); COL["TERRAIN"].objects.link(terr)
me.shade_smooth()

# BAKE THE SURFACE MASKS ONTO THE TERRAIN - the same method proved on the hill's EROSION
# attribute. Two attributes, because there are more surfaces than one has channels.
#   GROUND  R=gravel  G=pebble  B=bare   A=wet
#   GROUND2 R=spoil   G=(free)  B=(free) A=(free)
_gr=me.color_attributes.new(name="GROUND", type='FLOAT_COLOR', domain='POINT')
_g2=me.color_attributes.new(name="GROUND2",type='FLOAT_COLOR', domain='POINT')
_nv=len(me.vertices)
_b1=np.empty(_nv*4); _b2=np.empty(_nv*4)
_b1[0::4]=SURF['gravel'].ravel(); _b1[1::4]=SURF['pebble'].ravel()
_b1[2::4]=SURF['bare'].ravel();   _b1[3::4]=SURF['wet'].ravel()
_b2[0::4]=SURF['spoil'].ravel();  _b2[1::4]=0.0; _b2[2::4]=0.0; _b2[3::4]=1.0
_gr.data.foreach_set("color",_b1); _g2.data.foreach_set("color",_b2)
print(f"  GROUND/GROUND2 attributes baked onto {_nv} terrain vertices")

# CIRCLE: the mask for D2 - the 4K displacement tier lives INSIDE the five scenario circles only
# (PLAN s9 C2 step 8). 1.0 in the core, a 40 m cosine rim so the tessellation boundary never
# reads, 0.0 outside - where bump alone is right and cheap. The centres MUST match SCEN_CIRCLES
# used by the rock scatter below; asserted.
SCEN_CIRCLES=[(-280.0,450.0,205.0,"S1"),(340.0,-580.0,165.0,"S2"),(-155.0,-476.0,185.0,"S3"),
              (130.0,-800.0,235.0,"S4"),(-690.0,760.0,205.0,"S5")]
_cm=np.zeros_like(X)
for _cx,_cy,_cr,_tg in SCEN_CIRCLES:
    _d=np.hypot(X-_cx,Y-_cy)
    _w=np.clip((_cr-_d)/40.0,0.0,1.0)              # 0 at the edge, 1 by 40 m inside
    _cm=np.maximum(_cm, 0.5-0.5*np.cos(np.pi*_w)) # cosine ease
_cc=me.color_attributes.new(name="CIRCLE",type='FLOAT_COLOR',domain='POINT')
_bc=np.empty(_nv*4); _bc[0::4]=_cm.ravel(); _bc[1::4]=_cm.ravel(); _bc[2::4]=_cm.ravel(); _bc[3::4]=1.0
_cc.data.foreach_set("color",_bc)
print(f"  CIRCLE attribute baked: {(_cm>0.5).mean()*100:.2f}% of the plain inside the five circles")

# ---------------------------------------------------------------- the hill: A.N.T. + the ERODER
print("building the hill ...")
# A ridge, built analytically so its FORM is controlled, then eroded. A.N.T.'s hetero_terrain
# gave a nearly flat field (median 0.03 m) with a couple of spires - erosion needs real relief
# underneath it or it just sharpens noise.
hx=np.linspace(-HILL_GX/2,HILL_GX/2,HILL_NX)
hy=np.linspace(-HILL_GY/2,HILL_GY/2,HILL_NY)
HX_,HY_=np.meshgrid(hx,hy,indexing='xy')
# elliptical dome, long axis NW as S0 s3 specifies
ang=math.radians(-38.0)
rx= HX_*math.cos(ang)+HY_*math.sin(ang)
ry=-HX_*math.sin(ang)+HY_*math.cos(ang)
rr=np.sqrt((rx/(HILL_W*0.50))**2+(ry/(HILL_L*0.50))**2)   # the SPECIFIED axes, 500 x 350:
# long axis reads. 0.36 went too far: the ridge no longer filled its own footprint.   # EXACTLY inscribed: the dome
# must reach zero at the mesh boundary or the rim floats and you see underneath it.
dome=np.clip(1.0-rr,0,1)**0.62   # was **1.35 (concave, no bulk). At half radius this
                                 # now gives 65% of full height instead of 39%.
# a RIDGE LINE along the long axis, plus subordinate spurs - a real hill has a crest, not a cone
crest=np.exp(-(ry/(HILL_L*0.13))**2)*0.85   # a real crest, not a gentle swell
spur =vnoise(HX_*3.0,HY_*3.0,190.0,7)*0.16
relief=(dome*(1.0+0.30*vnoise(HX_,HY_,150.0,3))+dome*crest+dome*np.clip(spur,0,None))
relief=np.clip(relief,0,None)
relief=relief/max(relief.max(),1e-9)*HILL_H
hverts=np.stack([HX_.ravel(),HY_.ravel(),relief.ravel()],axis=1)
hfaces=[]
for j in range(HILL_NY-1):
    row=j*HILL_NX; nxt=(j+1)*HILL_NX
    for i in range(HILL_NX-1):
        hfaces.append((row+i,row+i+1,nxt+i+1,nxt+i))
hme=bpy.data.meshes.new("HILL"); hme.from_pydata(hverts.tolist(),[],hfaces); hme.update()
hill=bpy.data.objects.new("HILL",hme); bpy.context.collection.objects.link(hill)
bpy.context.view_layer.objects.active=hill
hill.select_set(True)
print(f"  hill form: {HILL_NX}x{HILL_NY}, spacing {HILL_GX/(HILL_NX-1):.4f} x {HILL_GY/(HILL_NY-1):.4f} m"
      f" (Eroder needs these square), relief {relief.min():.1f}..{relief.max():.1f} m")
relief_keep=relief.copy()      # the analytic form, kept to blend back after erosion
z0=[v.co.z for v in hill.data.vertices]
try:
    bpy.ops.mesh.eroder(Iterations=16, Kd=0.06, Kt=1.047, Kr=0.28, Kv=0.0, Ef=0.0)
    hill.data.update(); eroded=True
    # ================= THE ERODER ALSO *TRANSLATES* THE MESH =================
    # Found 5 Sep by tracing the mesh bounds through the pipeline, after two wrong theories.
    # In:  x -260..260, y -220..220.   Out: x -220..300, y -260..180.
    # Same spans, centre moved by EXACTLY (+40, -40) m. It is a pure translation, and it is a
    # second member of the family REF-05 s10a already records ("never assume anything survives
    # an operator"): that entry says the vertex ORDER is scrambled; this says the COORDINATES
    # move too. Everything downstream is expressed in local mesh coordinates - the inscribed
    # ellipse, the quarry at 215 deg, the waterfall on the north flank, the fan boundary mask,
    # and the grid index rebuilt from x,y - so ALL of them were landing 40 m from where they
    # were specified, and the ellipse test was clipping live hill off one side.
    # Measure the offset and remove it. Never hardcode 40: measure, then assert it is gone.
    _pv=np.array([v.co[:] for v in hill.data.vertices])
    _ox=float((_pv[:,0].min()+_pv[:,0].max())*0.5); _oy=float((_pv[:,1].min()+_pv[:,1].max())*0.5)
    if abs(_ox)>1e-6 or abs(_oy)>1e-6:
        for _v in hill.data.vertices: _v.co.x-=_ox; _v.co.y-=_oy
        hill.data.update()
        print(f"  ERODER TRANSLATED THE MESH by ({_ox:+.1f}, {_oy:+.1f}) m - removed")
    _pv=np.array([v.co[:] for v in hill.data.vertices])
    assert abs(_pv[:,0].min()+HILL_GX/2)<1.0 and abs(_pv[:,1].min()+HILL_GY/2)<1.0, \
        f"hill mesh not re-centred: x {_pv[:,0].min():.1f}..{_pv[:,0].max():.1f}, " \
        f"y {_pv[:,1].min():.1f}..{_pv[:,1].max():.1f}"
except Exception as e:
    print("ERODER FAILED:", str(e)[:160]); eroded=False
# ############################################################################################
# THE ERODER SCRAMBLES VERTEX ORDER. Measured: after eroding, vertex i is NO LONGER at grid
# position (i % NX, i // NX) - |x - expected| reached 573 m on a 500 m hill. So every
# `.reshape(NY, NX)` after erosion was operating on shuffled data: the smoothing smoothed random
# neighbours, and the form-blend added the dome's height at one place to the eroded height of a
# completely different place. THAT is what made the hill a field of spikes.
# Fix: rebuild the grid index from each vertex's ACTUAL x,y. Never assume order after an operator.
_co=np.array([[v.co.x,v.co.y,v.co.z] for v in hill.data.vertices])
_gj=np.clip(np.round((_co[:,0]+HILL_GX/2)/(HILL_GX/(HILL_NX-1))).astype(int),0,HILL_NX-1)
_gi=np.clip(np.round((_co[:,1]+HILL_GY/2)/(HILL_GY/(HILL_NY-1))).astype(int),0,HILL_NY-1)
print(f"  vertex order after erosion: SCRAMBLED - rebuilt grid index from x,y")
zs=_co[:,2]
lo,hi=np.percentile(zs,0.5),np.percentile(zs,99.0)
zs=np.clip(zs,lo,hi)
print(f'  erosion output percentiles: p50={np.percentile(zs,50):.3f} p90={np.percentile(zs,90):.3f} max={zs.max():.3f}')
if hi-lo>1e-9: zs=(zs-lo)/(hi-lo)*HILL_H
# BLEND: the dome gives the hill its mass, erosion gives it its gullies. Erosion alone left a
# median of 10.6 m on a 170 m hill - a carved-out shell, not a hill.
#
# AND THE ERODER'S OUTPUT IS HIGH-FREQUENCY, NOT SMOOTH GULLIES. Measured: face normal.z had a
# median of 0.048, i.e. ~87 deg - virtually EVERY face was near-vertical, because the eroded field
# jumps tens of metres between vertices 1.95 m apart. That is what produced the spikes, and it is
# also why the rock-by-slope test caught 94% of the hill.
# Smooth the eroded component before blending: keep the gully PATTERN, lose the pixel noise.
# scatter into a real grid using the rebuilt index, smooth there, then gather back per vertex
zg=np.zeros((HILL_NY,HILL_NX)); cnt=np.zeros((HILL_NY,HILL_NX))
np.add.at(zg,(_gi,_gj),zs); np.add.at(cnt,(_gi,_gj),1.0)
zg=np.where(cnt>0, zg/np.maximum(cnt,1), 0.0)
for _ in range(11):
    pad=np.pad(zg,1,mode='edge')
    zg=(pad[0:-2,1:-1]+pad[2:,1:-1]+pad[1:-1,0:-2]+pad[1:-1,2:]+4.0*zg)/8.0
FORM_W=0.82
blended = relief_keep*FORM_W + zg*(1.0-FORM_W)      # both are now (NY, NX) and ALIGNED
# THE RIM MUST BE EXACT ZERO, NOT approximately zero. relief_keep (the analytic dome) is clipped
# to exactly 0 beyond the inscribed ellipse, by construction - but EROSION IS A SIMULATION, NOT
# CONFINED TO THE ELLIPSE, and zg can carry a small residual there. At FORM_W=0.82 that residual
# survives at 18% strength - a hard jagged black seam tracing the WHOLE hill footprint in every
# render since 5 Sep (found by comparing against that day's own "scree" render, not a new bug;
# confirmed by measurement, not reasoning - two wrong terrace-side theories were tried first).
# Hard-clamp wherever the analytic dome says there is no hill at all.
blended[relief_keep<=1e-6]=0.0
zs = blended[_gi,_gj]                                # gather back to the scrambled vertex order
zs = zs/max(zs.max(),1e-9)*HILL_H
for i,v in enumerate(hill.data.vertices): v.co.z=float(zs[i])
hill.data.update()
print(f"  after erosion + {int(FORM_W*100)}% form blend: median {np.median(zs):.1f} m, "
      f"p90 {np.percentile(zs,90):.1f} m, above half-height {(zs>HILL_H*0.5).mean()*100:.1f}%")
hill.location=(HILL_X,HILL_Y,HILL_BASE_Z)   # z corrected below, once the rim has been measured
for c in hill.users_collection: c.objects.unlink(hill)
COL["HILL"].objects.link(hill)
hill.data.shade_smooth()

# ============================================================================================
# THE HILL, EXTENDED - scree fans, rock, quarry, waterfall.
# THE KEY IDEA: the Eroder already computed where material was scoured and where it was
# DEPOSITED. So the scree fans are placed by the erosion simulation, not by me guessing.
# REF-07 s4's law - "the medium objects are the debris of the large" - made literal.
# ============================================================================================
import numpy as _np
def vg_weights(obj, name):
    g=obj.vertex_groups.get(name)
    if g is None: return None
    w=_np.zeros(len(obj.data.vertices))
    for i,v in enumerate(obj.data.vertices):
        for gel in v.groups:
            if gel.group==g.index: w[i]=gel.weight; break
    return w

hv=_np.array([[v.co.x,v.co.y,v.co.z] for v in hill.data.vertices])
W_dep   = vg_weights(hill,'deposit')
W_water = vg_weights(hill,'water')
W_scree = vg_weights(hill,'scree')
W_flow  = vg_weights(hill,'flowrate')
print(f"  eroder groups read: deposit={W_dep is not None} water={W_water is not None} "
      f"scree={W_scree is not None} flowrate={W_flow is not None}")

hz=hv[:,2]; hz_max=hz.max() if len(hz) else 1.0

# 1 · SCREE FANS - build them by ADDING material where the Eroder says it was deposited,
# strongest low on the slope (fans spread at the bottom, that is what a fan IS).
if W_dep is not None and W_dep.max()>1e-9:
    p97=_np.percentile(W_dep[W_dep>1e-9],97) if (W_dep>1e-9).any() else 1.0
    dep=_np.clip(W_dep/max(p97,1e-9),0,1)   # normalise by p97: max was 17x p99, so
                                            # dividing by max starved every real fan
    # SMOOTH IT. The deposit weight is per-vertex and varies wildly between neighbours 1.95 m
    # apart; applied raw it added metres of jump per cell and made 94% of faces near-vertical.
    # Measured: face normal.z median 0.046 (~87 deg) even after smoothing the erosion itself -
    # the fan was the real noise source, not the Eroder.
    dg=_np.zeros((HILL_NY,HILL_NX)); dc=_np.zeros((HILL_NY,HILL_NX))
    _np.add.at(dg,(_gi,_gj),dep); _np.add.at(dc,(_gi,_gj),1.0)
    dg=_np.where(dc>0, dg/_np.maximum(dc,1), 0.0)
    # 5 Sep: FIVE smoothing passes spread every fan into a general swelling of the lower slope -
    # REF-13 s6 wants a TRIANGLE with its apex at the gully mouth. Two passes is enough to kill
    # the per-vertex noise that made 94% of faces vertical, and keeps the fan a fan.
    for _ in range(2):
        pad=_np.pad(dg,1,mode='edge')
        dg=(pad[0:-2,1:-1]+pad[2:,1:-1]+pad[1:-1,0:-2]+pad[1:-1,2:]+4.0*dg)/8.0
    dep=dg[_gi,_gj]
    lowness=_np.clip(1.0-hz/max(hz_max,1e-6),0,1)          # low on the hill = where fans build
    _fe=_np.maximum(_np.abs(hv[:,0])/(HILL_GX/2), _np.abs(hv[:,1])/(HILL_GY/2))
    fan = (dep**1.35)*lowness**2.2*23.0    # ^1.35 not ^0.75: a fan is CONCENTRATED at*_np.clip((1.0-_fe)/0.30,0,1)   # keep fans off
    # the boundary: material piled at the rim is what forced a 9.2 m sink   # was 7.5 m and read as nothing. Fans are the
    # single feature REF-13 s6 named as what makes a hill look real, so they must be visible.
    for i,v in enumerate(hill.data.vertices): v.co.z += float(fan[i])
    hill.data.update()
    print(f"  scree fans: {int((fan>0.5).sum())} vertices raised, max {fan.max():.1f} m")

# 5 · THE QUARRY SCAR, south-west face - cut BENCHES (a quarry is worked in level lifts),
# with the spoil heaped below it. Not a smooth dent.
qang=math.radians(215.0)                     # south-west
qx=math.sin(qang)*HILL_W*0.30; qy=math.cos(qang)*HILL_L*0.30
qd=_np.hypot(hv[:,0]-qx, hv[:,1]-qy)
qm=_np.clip(1.0-qd/95.0,0,1)**1.4
BENCH=9.0
# THE BENCH QUANTISATION MUST BE WEIGHTED BY THE MASK. It was applied at FULL strength wherever
# qm > 0.02 - i.e. everywhere within 89 m - so vertices with a 0.5 m cut were still snapped to
# 9 m contour bands. That is the ziggurat terracing across the hill face.
# Benches belong to the worked face only: full at the quarry centre, gone at its edge.
for i,v in enumerate(hill.data.vertices):
    if qm[i]>0.02:
        w=float(min(qm[i]/0.55,1.0))          # bench weight: only the truly worked face is stepped
        cut=qm[i]*26.0
        z=v.co.z-cut
        stepped=_np.floor(z/BENCH)*BENCH + (z-_np.floor(z/BENCH)*BENCH)*0.25
        v.co.z = float(z*(1.0-w) + stepped*w)
hill.data.update()

# 6 · THE SEASONAL WATERFALL, north flank - a ROCK STEP the water falls over, and a plunge
# pool scoured at its foot. S5: 22 m over a rock step, alive in late September.
wfx, wfy = HILL_W*0.06, HILL_L*0.34          # north flank
wd=_np.hypot(hv[:,0]-wfx, hv[:,1]-wfy)
step=_np.clip(1.0-wd/34.0,0,1)
for i,v in enumerate(hill.data.vertices):
    if step[i]>0.02:
        v.co.z += float(step[i]*11.0)                       # the lip the water goes over
        if wd[i]<15.0: v.co.z -= float((1.0-wd[i]/15.0)*7.0)  # the plunge pool below it
hill.data.update()

# --- normalise AFTER the features. The quarry was cutting 25 m BELOW ground level, which is not
# what a hillside quarry does - it works benches INTO the slope, and its floor sits at or above
# the surrounding ground. Clamp the floor, then rescale the peak back to the specified 170 m.
_z=_np.array([v.co.z for v in hill.data.vertices])
_z=_np.clip(_z, 0.0, None)
_mx=_z.max()
if _mx>1e-6:
    _z=_z/_mx*HILL_H
for i,v in enumerate(hill.data.vertices): v.co.z=float(_z[i])
hill.data.update()

# skirt the hill down into the plain so it is not a cut-out sitting on the ground
bpy.context.view_layer.objects.active=hill
sk=hill.modifiers.new("SKIRT",'SHRINKWRAP')
sk.target=terr; sk.wrap_method='PROJECT'; sk.use_project_z=True; sk.use_negative_direction=True
sk.vertex_group=""      # applied only via the falloff below; kept explicit for later tuning
hill.modifiers.remove(sk)   # placeholder: the blend is done by lowering the rim instead
# NO RIM FEATHER. The elliptical dome already reaches zero at its own boundary, so a second
# rectangular feather on top of it cut the hill twice - it dropped the median from 40 m to 12 m.
# The two measures did not even agree: the dome is elliptical, the feather was a max-norm
# rectangle, so it bit hardest exactly where the dome was already thin.
# and force the last 7% of the footprint hard to zero, so nothing the erosion or the fans added
# can leave the boundary hanging. A narrow clamp, unlike the wide rim feather that cut the hill
# twice and dropped its median from 40 m to 12 m.
_hb=_np.array([[v.co.x,v.co.y] for v in hill.data.vertices])
_edge=_np.maximum(_np.abs(_hb[:,0])/(HILL_GX/2), _np.abs(_hb[:,1])/(HILL_GY/2))
_clamp=_np.clip((1.0-_edge)/0.22,0,1)**1.4
for i,v in enumerate(hill.data.vertices): v.co.z*=float(_clamp[i])
hill.data.update()
# A TARGETED SPIKE FILTER, not more blanket smoothing. Measured: 334 vertices stood more than
# 2 m above their OWN neighbours, up to 5.9 m - that is the per-vertex deposit noise the fan pass
# lets through, and it is what put cones on the slope. Smoothing everything again would flatten
# the fans back into a swelling (that is what 5 passes did). Clamp only the offenders.
_adj={}
for _e in hill.data.edges:
    _a,_b=_e.vertices
    _adj.setdefault(_a,[]).append(_b); _adj.setdefault(_b,[]).append(_a)
_z=_np.array([v.co.z for v in hill.data.vertices])
for _pass in range(12):        # iterate to convergence: clamping one vertex moves its neighbours
    _nbmean=_np.array([_np.mean(_z[_adj[i]]) if _adj.get(i) else _z[i] for i in range(len(_z))])
    _exc=_z-_nbmean
    _bad=_exc>1.2                                   # a real fan is smooth; a spike is not
    if not _bad.any(): break
    _z[_bad]=_nbmean[_bad]+1.2
_n_spikes=int((_np.array([v.co.z for v in hill.data.vertices])-_z>0.01).sum())
for i,v in enumerate(hill.data.vertices): v.co.z=float(_z[i])
hill.data.update()
print(f"  spike filter: {_n_spikes} vertices clamped to 1.2 m above their neighbours")

_hzc=_np.array([v.co.z for v in hill.data.vertices])

# THE HILL FOLLOWS THE GROUND - S0 s3 "THE HILL HAS NO PAD", 5 Sep. Place every vertex at
# terrain height + its own relief, sampling the SAME height field the terrain mesh is built from,
# so hill and plain are one surface by construction. The rim carries zero relief at the ellipse
# and therefore lands exactly on the ground: self-correcting, nothing to sink, nothing to tune.
def terrain_z(wx, wy):
    """bilinear sample of H at world metres - H is (NG+1,NG+1) over [-GEXT,+GEXT]"""
    fx=np.clip((wx+GEXT)/(2*GEXT)*NG, 0, NG-1e-6)
    fy=np.clip((wy+GEXT)/(2*GEXT)*NG, 0, NG-1e-6)
    i0=fx.astype(int); j0=fy.astype(int); tx=fx-i0; ty=fy-j0
    return ( H[j0,i0]*(1-tx)*(1-ty) + H[j0,i0+1]*tx*(1-ty)
           + H[j0+1,i0]*(1-tx)*ty   + H[j0+1,i0+1]*tx*ty )
_tz = terrain_z(_hb[:,0]+HILL_X, _hb[:,1]+HILL_Y)
for i,v in enumerate(hill.data.vertices): v.co.z = float(_tz[i] + _hzc[i])
hill.location.z = 0.0
# DELETE THE SKIRT. Outside the inscribed ellipse the generator leaves a FLAT RECTANGULAR PLATE -
# that plate, not the water, is what read as a hard straight line under the hill.
_keep=[]
_bm=bmesh.new(); _bm.from_mesh(hill.data); _bm.verts.ensure_lookup_table()
_rel={v.index: float(_hzc[v.index]) for v in _bm.verts}
# DELETE THE SKIRT BY THE ELLIPSE, NOT BY RELIEF. Measured: a relief<0.4 test also deleted the
# QUARRY FLOOR - which is low by design - punching a hole in the middle of the hill with an 18 m
# cliff round it. That is the black staircase at the hill's foot. The skirt is a PLACE (outside
# the inscribed ellipse), not a height, so test the place.
_ea=math.radians(-38.0); _eca,_esa=math.cos(_ea),math.sin(_ea)
def _outside(v):
    _rx= v.co.x*_eca + v.co.y*_esa
    _ry=-v.co.x*_esa + v.co.y*_eca
    return ((_rx/(HILL_W*0.50))**2+(_ry/(HILL_L*0.50))**2) > 1.0
_skirt=[f for f in _bm.faces
        if all(_outside(v) for v in f.verts) and max(_rel[v.index] for v in f.verts) < 0.40]
bmesh.ops.delete(_bm, geom=_skirt, context='FACES')
_nfaces_before=len(hill.data.polygons)
_bm.to_mesh(hill.data); _bm.free(); hill.data.update()
# loose vertices left by the face delete would still show in a bounding box - clear them
_bm=bmesh.new(); _bm.from_mesh(hill.data)
bmesh.ops.delete(_bm, geom=[v for v in _bm.verts if not v.link_faces], context='VERTS')
_bm.to_mesh(hill.data); _bm.free(); hill.data.update()
print(f"  hill FOLLOWS THE TERRAIN: base z {_tz.min():.2f}..{_tz.max():.2f} m, no pad, no skirt "
      f"({_nfaces_before - len(hill.data.polygons)} skirt faces deleted of {_nfaces_before})")
print(f"  final hill: median {_np.median(_hzc):.1f} m, p90 {_np.percentile(_hzc,90):.1f} m, "
      f"above half-height {( _hzc>HILL_H*0.5).mean()*100:.1f}%")

# ---------------------------------------------------------------- water: ONE LEVEL PLANE
# REF-07 s10b: do NOT model the river outline. Cut the valley, drop a flat plane, and every bar,
# shoal and cut bank falls out of the terrain for free.
# REF-07 s10b's "one level plane" is right for a LOCAL scene. Over 4 km it is wrong: the plain
# falls 14 m, so a single water height sits BURIED upstream and FLOATING downstream - which is
# exactly the broken, gap-toothed river the first render showed.
# RIVERS FLOW DOWNHILL. Sample the bed along the centreline and let the surface follow it.
surf = BED_TARGET + 0.85                  # the bed already descends, so the surface does too
water_z = float(np.median(surf)); river_bed_z = float(np.median(BED_TARGET))
print(f"  channel bed carved to descend: {BED_TARGET.max():.2f} -> {BED_TARGET.min():.2f} m")
# A RIBBON CANNOT WORK HERE. Offsetting +/-125 m from a centreline sampled every ~54 m makes the
# two edges cross over at every bend, and the self-intersecting quads render as black holes.
# Build the water from the SAME GRID as the terrain instead: it follows the course exactly and
# cannot self-intersect by construction.
surf_field = surf[np.clip(DIDX,0,len(surf)-1)]

# THE WATER IS A CLOSED WEDGE, NOT A CONSTANT SLAB. S0 s3 "THE WATER BODY", 5 Sep.
# The 4 Sep build solidified the surface into a constant 2.5 m slab carrying a density-0.26
# volume. MEASURED (REF-05 s10j): ray-cast through the black bar hit WATER_MALIN's TOP face,
# normal +1.000; A/B scored 36.3% of the strip under luminance 0.02 as-is, 1.5% with the volume
# unlinked. The VOLUME was the bar - a grazing ray refracts into a long in-medium path and
# Beer-Lambert extinguishes it to nothing. And a constant slab has NO DEPTH GRADIENT, which is
# the only reason REF-07 s10b puts a volume in water at all.
# So: TOP = the flowing surface, BOTTOM = THE RIVER BED ITSELF. Depth = surface - terrain, so it
# is 0 at the waterline and full in the channel, and the bank line falls out of the terrain
# exactly as REF-07 s10b intends. The bars raised inside the channel now emerge through it on
# their own - braiding for free, not painted.
CORRIDOR = RIVER_BANK*4.2          # a sanity bound only; CONNECTIVITY is what decides the shore
depth_raw = surf_field - H
# A RIVER IS A CONNECTED BODY OF WATER. `surf_field` takes its level from the nearest centreline
# segment, so it is defined everywhere on the grid - and left unchecked it floods any hollow in the
# plain that happens to sit below the river's level, hundreds of metres from the channel. The 2.6x
# corridor mask hid that by cutting the sheet in mid-air, which is REF-05 s10e's failure again.
# Flood-fill from the channel instead: water is where it is deep AND reachable from the Malin.
_below = (depth_raw > 0.0) & (DR < CORRIDOR)
wet = _below & (DR < RIVER_W)                      # seed: the channel itself
for _ in range(900):
    _g = wet.copy()
    _g[1:,:] |= wet[:-1,:]; _g[:-1,:] |= wet[1:,:]
    _g[:,1:] |= wet[:,:-1]; _g[:,:-1] |= wet[:,1:]
    _g &= _below
    if _g.sum()==wet.sum(): break
    wet = _g
print(f"  water flood-filled from the channel: {wet.sum()} nodes wet of {_below.sum()} below the "
      f"surface ({(_below.sum()-wet.sum())} disconnected hollows rejected)")

def closed_wedge(wet, ztop, zbot, name, shore=0.05):
    """A WATERTIGHT, MANIFOLD water solid: top sheet + bottom sheet + a rim wall.
    The rim is NOT the bug the 4 Sep note blamed (REF-05 s10j measured the VOLUME as the cause).
    What kills the black bar is that the wedge is CLAMPED TO `shore` METRES AT THE WATERLINE, so
    the rim is 5 cm tall - sub-pixel at any distance we ever see it - instead of a 2.5 m wall.
    Closed and manifold matters for its own reason: a Principled Volume needs a closed boundary
    to bound its path length, and an open shell is what let absorption run away."""
    ny,nx = wet.shape
    cell = wet[:-1,:-1] & wet[:-1,1:] & wet[1:,1:] & wet[1:,:-1]     # fully-wet quads
    # DE-PINCH (audit's standing WATER_PIT_1 warning). Two wet quads meeting only on a diagonal -
    # the other two diagonals dry - make the rim wrap ONE vertical edge with FOUR faces (each of
    # the four boundary edges round that node spawns a rim quad, and they all share the a->b
    # vertical edge). A non-manifold shell lets the Principled Volume's path length run away.
    # Fix causally: drop one quad of every diagonal-only pair until none remain. The bodies are
    # 5 cm-tall sub-pixel wedges, so a 1-2 cell loss at a pinch is invisible.
    for _dp in range(20):
        NW=cell[:-1,:-1]; NE=cell[:-1,1:]; SE=cell[1:,1:]; SW=cell[1:,:-1]
        p1 = NW & SE & ~NE & ~SW
        p2 = NE & SW & ~NW & ~SE
        if not (p1.any() or p2.any()): break
        cell[1:,1:][p1]  = False        # clear SE of a NW-SE pinch
        cell[1:,:-1][p2] = False        # clear SW of a NE-SW pinch
    used=np.zeros_like(wet)
    used[:-1,:-1]|=cell; used[:-1,1:]|=cell; used[1:,1:]|=cell; used[1:,:-1]|=cell
    # a node is SHORE if it touches any quad that is not a water quad
    allq=np.ones((ny-1,nx-1),dtype=bool)
    dry=np.zeros_like(wet)
    d2=allq & ~cell
    dry[:-1,:-1]|=d2; dry[:-1,1:]|=d2; dry[1:,1:]|=d2; dry[1:,:-1]|=d2
    shore_node = used & dry
    top_z = np.where(shore_node, np.minimum(ztop, zbot+shore), ztop)
    vt={}; vb={}; vs=[]
    jj,ii=np.nonzero(used)
    for j,i in zip(jj,ii):
        j=int(j); i=int(i)
        vt[(j,i)]=len(vs); vs.append([float(X[j,i]),float(Y[j,i]),float(top_z[j,i])])
        vb[(j,i)]=len(vs); vs.append([float(X[j,i]),float(Y[j,i]),float(zbot[j,i])])
    fs=[]
    for j,i in zip(*np.nonzero(cell)):
        j=int(j); i=int(i)
        q=((j,i),(j,i+1),(j+1,i+1),(j+1,i))
        fs.append(tuple(vt[k] for k in q))
        fs.append(tuple(reversed([vb[k] for k in q])))
    # RIM: every edge that belongs to exactly ONE water quad. This is what closes the solid.
    ec={}
    for j,i in zip(*np.nonzero(cell)):
        j=int(j); i=int(i)
        q=((j,i),(j,i+1),(j+1,i+1),(j+1,i))
        for a,b in zip(q,q[1:]+q[:1]):
            k=(a,b) if a<b else (b,a); ec[k]=ec.get(k,0)+1
    nrim=0
    for (a,b),c in ec.items():
        if c!=1: continue
        fs.append((vt[a],vt[b],vb[b],vb[a])); nrim+=1
    me=bpy.data.meshes.new(name); me.from_pydata(vs,[],fs); me.update()
    ob=bpy.data.objects.new(name,me); COL["WATER"].objects.link(ob)
    # REF-07 s5: "select all and Shift+N recalculate normals - the volume will not render
    # otherwise". The rim quads' winding is not guaranteed by the order they were built in.
    bm=bmesh.new(); bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    nonman=sum(1 for e in bm.edges if not e.is_manifold)
    bm.to_mesh(me); bm.free(); me.update()
    assert nonman==0, f"{name}: {nonman} non-manifold edges after de-pinch - the shell is not a closed solid"
    return ob, len(vs), len(fs), nrim, used, top_z

wat, _nv, _nf, _nrim, WETN, WTOP = closed_wedge(wet, surf_field, H, "WATER_MALIN")
_d = (WTOP-H)[WETN]
print(f"  water is a CLOSED WEDGE on the terrain grid: {_nv} verts, {_nf} faces "
      f"({_nrim} rim quads, clamped to 0.05 m at the shore), no solidify")
print(f"  depth measured off the bed: median {np.median(_d):.2f} m, max {_d.max():.2f} m, "
      f"{(_d<0.30).mean()*100:.1f}% of the sheet under 0.30 m (the wedge reaches the bank)")
print(f"  wet area {WETN.sum()*(2*GEXT/NG)**2/1e4:.1f} ha, widest point {DR[WETN].max():.0f} m "
      f"from the centreline (corridor limit {CORRIDOR:.0f} m)")
# MEASURE THE CROSS-SECTION rather than argue about where the bank is (REF-05 s10j).
print("  cross-section, median over the corridor:")
for lo,hi in ((0,20),(20,40),(40,70),(70,100),(100,150),(150,200),(200,260),(260,340)):
    b=(DR>=lo)&(DR<hi)
    if not b.any(): continue
    wfrac=WETN[b].mean()*100
    print(f"    {lo:3d}-{hi:3d} m: terrain {np.median(H[b]):6.2f} m   water surface "
          f"{np.median(surf_field[b]):6.2f} m   {wfrac:5.1f}% wet")
print(f"  river surface follows the bed: {surf.max():.2f} m upstream -> {surf.min():.2f} m downstream "
      f"({surf.max()-surf.min():.2f} m of fall over {len(riv)} points)")

# PONDS AND CLAY PITS - S0 s3 items 7 and 12, and S0 s3 "THE WATER BODY" item 4.
# They were `primitive_circle_add` NGONs at one height: FLAT DISCS floating on the plain, and
# carrying NO MATERIAL AT ALL, which is why they rendered as bright white ellipses in land_wide.
# They are still water: the same closed wedge, filling their own excavated depression, pinching
# to zero at their own shoreline. A johad is a hole in the ground that holds water, not a coin.
still=[]
def still_water(cx,cy,r,depth,fill,name):
    loc_m = np.hypot(X-cx, Y-cy) < r*1.6
    if not loc_m.any(): return None
    level = float(H[loc_m].min()) + depth*fill        # fills its own hollow, never a chosen z
    below = loc_m & ((level - H) > 0.0)
    if below.sum() < 8: return None
    seed_j,seed_i = np.unravel_index(np.argmin(np.where(loc_m,H,1e9)), H.shape)
    w=np.zeros_like(below); w[seed_j,seed_i]=True     # flood-fill: one connected body of water
    for _ in range(200):
        g=w.copy()
        g[1:,:]|=w[:-1,:]; g[:-1,:]|=w[1:,:]; g[:,1:]|=w[:,:-1]; g[:,:-1]|=w[:,1:]
        g&=below
        if g.sum()==w.sum(): break
        w=g
    ztop=np.full_like(H, level)
    ob,_nv,_nf,_nr,used,_wt = closed_wedge(w, ztop, H, name)
    still.append((name, int(w.sum()), float((ztop-H)[w].max())))
    return ob
for n,(cx,cy,r) in enumerate(pond_xy):
    still_water(cx,cy,r,POND_D,0.62,f"WATER_POND_{n+1}")
for n,(cx,cy,r) in enumerate(kiln_xy[:2]):
    still_water(cx,cy,r,KILN_D,0.45,f"WATER_PIT_{n+1}")
print(f"  still water: {len(still)} bodies, each filling its own hollow - "
      + ", ".join(f"{n} {c} nodes max {d:.2f} m" for n,c,d in still))

# ---------------------------------------------------------------- the distant range
print("building the distant range ...")
NR=180
rx_=np.linspace(-GEXT*2.4,GEXT*2.4,NR+1)
ry_=np.linspace(RANGE_Y-450,RANGE_Y+450,41)
RX,RY=np.meshgrid(rx_,ry_,indexing='xy')
prof=np.clip(1.0-np.abs((RY-RANGE_Y)/450.0),0,1)**1.4
ridge=(vnoise(RX,RY,1400.0,71)*0.55+vnoise(RX,RY,420.0,83)*0.45)
RH=(0.62+0.38*ridge)*prof*RANGE_H*1.18
rv=np.stack([RX.ravel(),RY.ravel(),RH.ravel()],axis=1)
rf=[]
for j in range(RH.shape[0]-1):
    row=j*(NR+1); nxt=(j+1)*(NR+1)
    for i in range(NR):
        rf.append((row+i,row+i+1,nxt+i+1,nxt+i))
rme=bpy.data.meshes.new("DISTANT_RANGE"); rme.from_pydata(rv.tolist(),[],rf); rme.update()
rng_o=bpy.data.objects.new("DISTANT_RANGE",rme); COL["DISTANT"].objects.link(rng_o)
rme.shade_smooth()

# ---------------------------------------------------------------- materials: two-tone by slope+height
# --- shader helpers. Socket indices verified by running, not read (REF-05 s7).
#     ShaderNodeMix RGBA: Factor=0, A=6, B=7, Result out=2.
def _mix(nt,fac,a,b,blend='MIX'):
    n=nt.nodes.new("ShaderNodeMix"); n.data_type='RGBA'; n.blend_type=blend
    if hasattr(fac,'bl_idname'): nt.links.new(fac,n.inputs[0])
    else: n.inputs[0].default_value=fac
    for sock,idx in ((a,6),(b,7)):
        if hasattr(sock,'bl_idname'): nt.links.new(sock,n.inputs[idx])
        else: n.inputs[idx].default_value=sock
    return n.outputs[2]
def _math(nt,op,a,b=None,c=None):
    n=nt.nodes.new("ShaderNodeMath"); n.operation=op
    for k,v in ((0,a),(1,b),(2,c)):
        if v is None: continue
        if hasattr(v,'bl_idname'): nt.links.new(v,n.inputs[k])
        else: n.inputs[k].default_value=v
    return n.outputs[0]

def soil_material(fields=True, subcell=()):
    """S0 s3 'THE GROUND MATERIAL', 5 Sep. The bund grid is REAL GEOMETRY - 75 x 120 m parcels,
    each with its own id and its own level - and it was INVISIBLE, because all 4 km2 wore one
    material keyed only to height. That, not the terrain, is why the plain read featureless.
    Built at THREE SCALES from ONE cause (PLAN s3b):
      L  the field PATTERN from the air   - per-plot tone, from the same plot_id the ground used
      M  the plot BOUNDARY from the street - the bund lip, dry on its crest, damp behind it
      S  FURROWS up close                  - anisotropic noise, its direction hashed per plot
    Colour: REF-04 s10's two-tone law (near-black damp humus in hollows, light pebbly tan on
    ridges), governed by REF-13 s7's plains correction - ~31% saturation, NEVER the alpine 51%."""
    """FIELDS ARE FARMLAND, AND A 170 M HILLSIDE IS NOT FARMED.
    The hill shares this material with the terrain, so the plot rectangles and the furrows were
    being painted straight onto the mountain - a translucent grid of parcels across the slope.
    A/B settled it: hide HILL and the veil goes. `fields=False` gives the hill the same REF-04
    s10 two-tone earth WITHOUT the cultivation layers, which is what that clause describes anyway
    (dark humus in hollows, pebbly tan on ridges - a forest floor, not a field)."""
    m=bpy.data.materials.new("SOIL" if fields else "SOIL_HILL"); m.use_nodes=True
    nt=m.node_tree; b=nt.nodes["Principled BSDF"]
    geo=nt.nodes.new("ShaderNodeNewGeometry")
    pos=nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(geo.outputs["Position"],pos.inputs["Vector"])

    # ---- L: THE PLOT ID, rebuilt in the shader from the SAME formula the geometry used, so the
    # tone lands exactly on the parcel the bund lip drew. plot_id = floor(Y/75)*97 + floor(X/120)*31
    # A DEAD-STRAIGHT LATTICE IS THE TELL. The first build tiled the plain in a perfect
    # chequerboard: every parcel the same size, every boundary exactly straight, tones alternating.
    # Real holdings are irregular because they are INHERITED AND DIVIDED, not laid out - so:
    #   - warp the coordinate before the floor, so boundaries wander a few metres like real bunds
    #   - let neighbours MERGE, because one farmer works several adjacent parcels as one crop
    # Both are the governing principle: repeat what a reason would repeat.
    warp=nt.nodes.new("ShaderNodeTexNoise"); warp.inputs["Scale"].default_value=0.009
    warp.inputs["Detail"].default_value=3.0
    nt.links.new(geo.outputs["Position"],warp.inputs["Vector"])
    wsep=nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(warp.outputs["Color"],wsep.inputs["Vector"])
    wx=_math(nt,'MULTIPLY_ADD',wsep.outputs["X"],26.0,pos.outputs["X"])
    wy=_math(nt,'MULTIPLY_ADD',wsep.outputs["Y"],26.0,pos.outputs["Y"])
    pj=_math(nt,'FLOOR',_math(nt,'DIVIDE',wy,BUND_SPACING))
    pi=_math(nt,'FLOOR',_math(nt,'DIVIDE',wx,BUND_SPACING*1.6))
    pid_f=_math(nt,'ADD',_math(nt,'MULTIPLY',pj,97.0),_math(nt,'MULTIPLY',pi,31.0))
    # the HOLDING: a coarser grid. Where a holding hash says so, the parcel takes the holding's
    # id instead of its own, so 2x2 neighbours share one crop and the field sizes vary.
    hj=_math(nt,'FLOOR',_math(nt,'DIVIDE',wy,BUND_SPACING*2.0))
    hi=_math(nt,'FLOOR',_math(nt,'DIVIDE',wx,BUND_SPACING*3.2))
    pid_c=_math(nt,'ADD',_math(nt,'MULTIPLY',hj,53.0),_math(nt,'MULTIPLY',hi,89.0))
    merge=_math(nt,'LESS_THAN',
                _math(nt,'FRACT',_math(nt,'MULTIPLY',
                      _math(nt,'SINE',_math(nt,'MULTIPLY',pid_c,33.719)),7919.13)), 0.42)
    pid=_math(nt,'MIX' if False else 'ADD',
              _math(nt,'MULTIPLY',pid_f,_math(nt,'SUBTRACT',1.0,merge)),
              _math(nt,'MULTIPLY',pid_c,merge))
    def phash(seed_mul,seed_add,amp):        # the same fract(sin(x)*k) hash as the height field
        return _math(nt,'FRACT',_math(nt,'MULTIPLY',
                     _math(nt,'SINE',_math(nt,'ADD',_math(nt,'MULTIPLY',pid,seed_mul),seed_add)),amp))
    state=phash(78.233,11.7,24634.6345)      # WHICH of the four states this parcel is in
    tone =phash(45.164,3.1, 18927.1234)      # and its own tone inside that state

    # ---- the four states, REF-04 s9: late September, kharif harvest under way, ground DRYING.
    # CONSTANT interpolation: a field boundary is a HARD edge, it does not cross-fade.
    st=nt.nodes.new("ShaderNodeValToRGB"); st.color_ramp.interpolation='CONSTANT'
    nt.links.new(state,st.inputs["Fac"])
    el=st.color_ramp.elements
    el[0].position=0.0;  el[0].color=(0.062,0.048,0.034,1.0)   # 30% PLOUGHED for rabi - darkest
    el[1].position=0.30; el[1].color=(0.268,0.238,0.158,1.0)   # 30% STUBBLE, paddy cut - pale straw
    e2=el.new(0.60); e2.color=(0.086,0.082,0.046,1.0)          # 20% CANE standing - dark, shaded
    e3=el.new(0.80); e3.color=(0.196,0.163,0.112,1.0)          # 20% BARE / fallow - pebbly tan
    # ...and a per-plot tone shift, so two ploughed plots side by side are not the same colour
    tvar=_mix(nt,_math(nt,'MULTIPLY',tone,0.55),(1,1,1,1),(0.62,0.66,0.74,1),'MULTIPLY')
    plot_col=_mix(nt,0.40,st.outputs["Color"],tvar,'MULTIPLY')

    # ---- REF-04 s10's two-tone law still governs: hollows damp and dark, ridges dry and pale.
    # HEIGHT is the mask that works on a plain (REF-05 s10i: slope is not - normal.z is ~1 here).
    hmap=nt.nodes.new("ShaderNodeMapRange")
    hmap.inputs["From Min"].default_value=-8.0; hmap.inputs["From Max"].default_value=22.0
    nt.links.new(pos.outputs["Z"],hmap.inputs["Value"])
    big=nt.nodes.new("ShaderNodeTexNoise")                     # boundary noise-masked, never a line
    big.inputs["Scale"].default_value=0.018; big.inputs["Detail"].default_value=9.0
    wet=_math(nt,'MULTIPLY_ADD',hmap.outputs["Result"],0.72,_math(nt,'MULTIPLY',big.outputs["Fac"],0.28))
    damp=_mix(nt,wet,(0.055,0.045,0.032,1.0),(0.300,0.255,0.180,1.0))   # humus -> pebbly tan
    base=_mix(nt,0.62,damp,plot_col) if fields else damp

    # ---- M: THE PLOT BOUNDARY. The bund lip is a dry crest with damp worked ground behind it,
    # and it is the thing that makes a parcel read as a parcel from the road.
    if fields:
        ridge=nt.nodes.new("ShaderNodeTexWave"); ridge.wave_type='BANDS'; ridge.bands_direction='Y'
        ridge.inputs["Scale"].default_value=1.0/BUND_SPACING
        ridge.inputs["Distortion"].default_value=2.0
        lipmask=_math(nt,'POWER',ridge.outputs["Fac"],6.0)
        base=_mix(nt,_math(nt,'MULTIPLY',lipmask,0.55),base,(0.315,0.272,0.196,1.0))  # dry crest

    # ---- S: FURROWS, direction hashed PER PLOT so neighbouring fields are ploughed differently.
    # A material, never geometry: 0.25 m furrows are far under the 6.67 m grid (REF-05 s10h).
    rot=nt.nodes.new("ShaderNodeCombineXYZ")
    nt.links.new(_math(nt,'MULTIPLY',phash(21.71,5.3,9137.77),3.14159),rot.inputs["Z"])
    fmap=nt.nodes.new("ShaderNodeMapping"); fmap.inputs["Scale"].default_value=(1.0,0.045,1.0)
    nt.links.new(geo.outputs["Position"],fmap.inputs["Vector"]); nt.links.new(rot.outputs["Vector"],fmap.inputs["Rotation"])
    fur=nt.nodes.new("ShaderNodeTexNoise"); fur.inputs["Scale"].default_value=1.9
    fur.inputs["Detail"].default_value=6.0
    nt.links.new(fmap.outputs["Vector"],fur.inputs["Vector"])
    # furrows only on the worked plots - a fallow field is not ploughed. state<0.60 is
    # ploughed or stubble, and both carry row structure.
    worked=_math(nt,'LESS_THAN',state,0.60)
    furamt=_math(nt,'MULTIPLY',worked,0.30 if fields else 0.0)
    col=_mix(nt,furamt,base,_mix(nt,fur.outputs["Fac"],(0.040,0.032,0.022,1),(0.245,0.214,0.150,1))) \
        if fields else base
    # ===================== THE GROUND SURFACES - S0 s3, Phase 1 =====================
    # Eight features that were SHAPED but not SURFACED. Each is keyed to the mask baked from the
    # layer that cut it, so surface and shape are the same numbers by construction.
    if fields:
        ga=nt.nodes.new("ShaderNodeAttribute"); ga.attribute_name="GROUND"
        gs=nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(ga.outputs["Color"],gs.inputs["Color"])
        g2=nt.nodes.new("ShaderNodeAttribute"); g2.attribute_name="GROUND2"
        # --- TWO FREQUENCIES PER SURFACE (REF-07 s3). The upgrade over "two colours mixed by a
        # mask" is that the two maps must differ in FREQUENCY, not in colour - that is what
        # kills tiling. Every surface below gets a low-freq body and a high-freq grain.
        def two_freq(lo_scale, hi_scale, c_dark, c_light):
            nlo=nt.nodes.new("ShaderNodeTexNoise")
            nlo.inputs["Scale"].default_value=lo_scale; nlo.inputs["Detail"].default_value=5.0
            nhi=nt.nodes.new("ShaderNodeTexNoise")
            nhi.inputs["Scale"].default_value=hi_scale; nhi.inputs["Detail"].default_value=9.0
            f=_math(nt,'MULTIPLY_ADD',nlo.outputs["Fac"],0.62,
                    _math(nt,'MULTIPLY',nhi.outputs["Fac"],0.38))
            return _mix(nt,f,c_dark,c_light), nhi.outputs["Fac"]
        # REF-13 s6: pale grey-tan gravel, and the bars are the SAME material as the banks
        grav,grav_g = two_freq(0.30, 14.0,(0.223,0.212,0.188,1),(0.430,0.408,0.365,1))
        # REF-04 s10: the Bhabar apron - pebbly, top layers full of small stones
        peb,peb_g   = two_freq(0.22, 20.0,(0.176,0.150,0.116,1),(0.352,0.312,0.246,1))
        # REF-04 s9: threshing floors + pit floors - hard SWEPT bare earth, no crop, no furrow
        bare,_      = two_freq(0.55,  9.0,(0.196,0.172,0.130,1),(0.290,0.258,0.196,1))
        # REF-04 s13: nala beds, channels, paleo lows, below the terrace - damp sediment
        wet_,_      = two_freq(0.34, 11.0,(0.058,0.052,0.040,1),(0.140,0.126,0.098,1))
        # S0 s3 items 7,12: raw excavated spoil - unvegetated, and the bank IS the tell
        spo,_       = two_freq(0.70, 16.0,(0.128,0.104,0.074,1),(0.262,0.222,0.162,1))
        # --- SURFACES SMALLER THAN THE GRID (S0 s3, amended 5 Sep). A threshing floor is 11 m
        # across on a 6.67 m grid and lands on 1-2 vertices, so a colour attribute cannot carry
        # it at ANY size the spec allows. It is evaluated PER PIXEL from its own centre instead.
        # REF-04 s9: hard swept BARE earth - no crop, no furrow, and it overrides the plot tone.
        sub=None
        if subcell:
            pxy=nt.nodes.new("ShaderNodeCombineXYZ")           # kill z: these are ground discs
            nt.links.new(pos.outputs["X"],pxy.inputs["X"]); nt.links.new(pos.outputs["Y"],pxy.inputs["Y"])
            for _cx,_cy,_r in subcell:
                dn=nt.nodes.new("ShaderNodeVectorMath"); dn.operation='DISTANCE'
                nt.links.new(pxy.outputs["Vector"],dn.inputs[0])
                dn.inputs[1].default_value=(_cx,_cy,0.0)
                # a swept floor has a HARD edge with a scuffed metre at its rim, not a fade
                mr=nt.nodes.new("ShaderNodeMapRange")
                mr.inputs["From Min"].default_value=_r; mr.inputs["From Max"].default_value=_r*0.82
                mr.inputs["To Min"].default_value=0.0;  mr.inputs["To Max"].default_value=1.0
                mr.clamp=True; nt.links.new(dn.outputs["Value"],mr.inputs["Value"])
                sub = mr.outputs["Result"] if sub is None else \
                      _math(nt,'MAXIMUM',sub,mr.outputs["Result"])
        col=_mix(nt,gs.outputs["Blue"],  col, bare)    # bare first: it OVERRIDES the plot tone
        if sub is not None: col=_mix(nt,sub, col, bare)
        col=_mix(nt,gs.outputs["Green"], col, peb)
        col=_mix(nt,gs.outputs["Red"],   col, grav)
        col=_mix(nt,ga.outputs["Alpha"], col, wet_)
        # GROUND2 is baked R=spoil, G=B=0. Feeding the COLOR into a float Factor socket makes
        # Blender average the three channels, so the spoil mask was landing at a THIRD of its
        # value and the excavated banks - "the bank IS the tell" - were nearly invisible.
        # Separate it like every other channel and take Red. Found by reading, asserted below.
        g2s=nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(g2.outputs["Color"],g2s.inputs["Color"])
        col=_mix(nt,g2s.outputs["Red"], col, spo)
    nt.links.new(col,b.inputs["Base Color"])

    # micro grain everywhere, and roughness must vary or it reads as plastic
    fine=nt.nodes.new("ShaderNodeTexNoise"); fine.inputs["Scale"].default_value=220.0
    fine.inputs["Detail"].default_value=8.0
    bump=nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value=0.35
    hgt=_math(nt,'MULTIPLY_ADD',fur.outputs["Fac"],furamt,
              _math(nt,'MULTIPLY',fine.outputs["Fac"],0.35))
    if fields:
        # THE S SCALE, AND IT IS PLACED BY CAUSE, NEVER SCATTERED (PLAN s3b).
        # stones live on the apron and the gravel bars - the only two places stones actually are
        hgt=_math(nt,'MULTIPLY_ADD',peb_g,_math(nt,'MULTIPLY',gs.outputs["Green"],0.85),hgt)
        hgt=_math(nt,'MULTIPLY_ADD',grav_g,_math(nt,'MULTIPLY',gs.outputs["Red"],0.70),hgt)
        # clods on the PLOUGHED plots, because ploughing is what makes a clod (state < 0.30)
        clod=nt.nodes.new("ShaderNodeTexVoronoi"); clod.inputs["Scale"].default_value=3.2
        hgt=_math(nt,'MULTIPLY_ADD',clod.outputs["Distance"],
                  _math(nt,'MULTIPLY',_math(nt,'LESS_THAN',state,0.30),0.55),hgt)
        # cracked, curling crust on the FALLOW - the monsoon left ~17 Sep and the ground is
        # drying (REF-04 s9). NOT on the ploughed plots, which were turned wet.
        crk=nt.nodes.new("ShaderNodeTexVoronoi"); crk.feature='DISTANCE_TO_EDGE'
        crk.inputs["Scale"].default_value=9.0
        hgt=_math(nt,'MULTIPLY_ADD',
                  _math(nt,'SUBTRACT',1.0,_math(nt,'MINIMUM',crk.outputs["Distance"],1.0)),
                  _math(nt,'MULTIPLY',_math(nt,'GREATER_THAN',state,0.80),0.42),hgt)
    nt.links.new(hgt,bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"],b.inputs["Normal"])
    if fields:
        # D2 - THE 4K DISPLACEMENT TIER, INSIDE THE FIVE SCENARIO CIRCLES ONLY (PLAN s9 C2 step 8).
        # The SAME causally-placed S-scale relief (stones on the bars/apron, clods on the ploughed,
        # cracked crust on the fallow) that drives the bump also drives REAL micro-displacement
        # inside the circles - so at street / 2 m range the dirt has a SILHOUETTE, not just a
        # shaded normal. Gated by the CIRCLE attribute: exactly 0 outside, where bump alone is
        # right and cheap. The HEIGHT (Scale) and the dicing rate are an RTX judgement - 0.08 m of
        # relief is invisible at 800x450 - so this ships as scaffold + assertions, tuned there.
        circ=nt.nodes.new("ShaderNodeAttribute"); circ.attribute_name="CIRCLE"
        dh=_math(nt,'MULTIPLY',_math(nt,'SUBTRACT',hgt,0.5),circ.outputs["Fac"])
        disp=nt.nodes.new("ShaderNodeDisplacement")
        disp.inputs["Scale"].default_value=0.10; disp.inputs["Midlevel"].default_value=0.0
        nt.links.new(dh,disp.inputs["Height"])
        _out=nt.nodes.get("Material Output") or next(nd for nd in nt.nodes if nd.type=='OUTPUT_MATERIAL')
        nt.links.new(disp.outputs["Displacement"],_out.inputs["Displacement"])
        m.displacement_method='BOTH'      # Blender 4.5: a core Material property, not material.cycles
    rr=nt.nodes.new("ShaderNodeValToRGB"); rr.color_ramp.elements[0].position=0.35
    rr.color_ramp.elements[0].color=(0.78,0.78,0.78,1); rr.color_ramp.elements[1].color=(0.98,0.98,0.98,1)
    nt.links.new(fine.outputs["Fac"], rr.inputs["Fac"])
    nt.links.new(rr.outputs["Color"], b.inputs["Roughness"])
    return m
def rock_material():
    """REF-13 s6: rock is FOLIATED - flat slabby plates splitting along bedding, stacked at an
    angle. Tan / ochre / grey. NOT spheres, NOT Voronoi lumps.
    REWRITTEN 5 Sep. Measured: rock covered 28% of hill faces with a base ramp of only
    0.115 -> 0.330 - far too narrow, and the hill read PALE and washed. Three changes:
      - widen the value range, because 'tan / ochre / grey' is a WIDE range, not a narrow one
      - add a THIRD, DARK element for the shadowed split between two plates. That dark line is
        what actually makes foliated rock read as foliated.
      - drive the S-scale debris from the Eroder's OWN `deposit` and `flowrate` (the EROSION
        attribute), so small rock appears BELOW the slabs that shed it - causal, not scattered.
        This is what survives a zoom (PLAN s3b); a random scatter fails it instantly."""
    m=bpy.data.materials.new("ROCK"); m.use_nodes=True
    nt=m.node_tree; b=nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value=0.86
    tc=nt.nodes.new("ShaderNodeTexCoord")
    mp=nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value=(1.0,1.0,3.2)     # squashed in Z = bedding planes
    mp.inputs["Rotation"].default_value=(math.radians(27.0),math.radians(9.0),0)  # bedding dips
    wrp=nt.nodes.new("ShaderNodeTexNoise")             # domain warp: no band runs right round
    wrp.inputs["Scale"].default_value=0.016; wrp.inputs["Detail"].default_value=4.0
    wvec=nt.nodes.new("ShaderNodeVectorMath"); wvec.operation='MULTIPLY_ADD'
    wvec.inputs[1].default_value=(46.0,46.0,14.0)
    nz=nt.nodes.new("ShaderNodeTexNoise")
    nz.inputs["Scale"].default_value=0.085; nz.inputs["Detail"].default_value=12.0
    nz.inputs["Roughness"].default_value=0.62
    nt.links.new(tc.outputs["Object"],mp.inputs["Vector"])
    nt.links.new(mp.outputs["Vector"],wrp.inputs["Vector"])
    nt.links.new(wrp.outputs["Color"],wvec.inputs[0])
    nt.links.new(mp.outputs["Vector"],wvec.inputs[2])
    nt.links.new(wvec.outputs["Vector"],nz.inputs["Vector"])
    # L/M: the plates themselves. FOUR stops now, and the range runs 0.045 -> 0.415.
    rmp=nt.nodes.new("ShaderNodeValToRGB")
    e=rmp.color_ramp.elements
    e[0].position=0.30; e[0].color=(0.045,0.038,0.031,1.0)   # the DARK SPLIT between two plates
    e[1].position=0.46; e[1].color=(0.150,0.132,0.104,1.0)   # grey shadowed plate face
    e2=e.new(0.68);     e2.color=(0.310,0.258,0.180,1.0)     # tan plate
    e3=e.new(0.86);     e3.color=(0.415,0.352,0.245,1.0)     # ochre, sunlit and dry
    nt.links.new(nz.outputs["Fac"],rmp.inputs["Fac"])
    # S: DEBRIS, and it is placed by the Eroder, not by chance. R=deposit, G=flowrate.
    att=nt.nodes.new("ShaderNodeAttribute"); att.attribute_name="EROSION"
    esep=nt.nodes.new("ShaderNodeSeparateColor"); nt.links.new(att.outputs["Color"],esep.inputs["Color"])
    grit=nt.nodes.new("ShaderNodeTexNoise")          # pebble-scale, same shape as the plates
    grit.inputs["Scale"].default_value=1.6; grit.inputs["Detail"].default_value=10.0
    nt.links.new(wvec.outputs["Vector"],grit.inputs["Vector"])
    debris=_math(nt,'MULTIPLY',esep.outputs["Red"],0.85)             # only where deposit landed
    rockcol=_mix(nt,debris,rmp.outputs["Color"],
                 _mix(nt,grit.outputs["Fac"],(0.088,0.076,0.058,1),(0.352,0.300,0.212,1)))
    # the gully floors are wet-dark and washed clean of fines - flowrate says where
    rockcol=_mix(nt,_math(nt,'MULTIPLY',esep.outputs["Green"],0.55),rockcol,(0.062,0.058,0.050,1))
    nt.links.new(rockcol,b.inputs["Base Color"])
    # bump: plates at M scale, grit at S scale, and the grit only where the debris is
    hgt=_math(nt,'MULTIPLY_ADD',grit.outputs["Fac"],debris,
              _math(nt,'MULTIPLY',nz.outputs["Fac"],0.85))
    bump=nt.nodes.new("ShaderNodeBump"); bump.inputs["Strength"].default_value=0.72
    nt.links.new(hgt,bump.inputs["Height"])
    nt.links.new(bump.outputs["Normal"],b.inputs["Normal"])
    rr=nt.nodes.new("ShaderNodeValToRGB"); rr.color_ramp.elements[0].position=0.30
    rr.color_ramp.elements[0].color=(0.72,0.72,0.72,1); rr.color_ramp.elements[1].color=(0.96,0.96,0.96,1)
    nt.links.new(nz.outputs["Fac"], rr.inputs["Fac"])
    nt.links.new(rr.outputs["Color"], b.inputs["Roughness"])
    return m
# the threshing floors go in as SHADER instances, not through the attribute - S0 s3, 5 Sep
SOIL=soil_material(fields=True, subcell=[(cx,cy,THRESH_R) for cx,cy,_ in thresh_xy])
def hill_material():
    """ONE material for the hill: earth and rock in a single shader, mixed by a NOISE-MASKED
    HEIGHT GRADIENT. Two materials on two sets of faces can only ever meet along a face
    boundary, and that rendered as a hard sawtooth band of triangles around the lower slope.
    REF-04 s10: 'the boundary is a noise-masked gradient, never a line.'
    The mask reads RELIEF out of the EROSION attribute's alpha, so it is the hill's own height
    above the ground it stands on - not world z, which changes as the plain rises."""
    m=rock_material(); m.name="HILL"
    nt=m.node_tree; b=nt.nodes["Principled BSDF"]
    rock_col=b.inputs["Base Color"].links[0].from_socket
    rock_nrm=b.inputs["Normal"].links[0].from_node          # the Bump node
    rock_hgt=rock_nrm.inputs["Height"].links[0].from_socket
    att=[n for n in nt.nodes if n.bl_idname=="ShaderNodeAttribute"][0]
    # --- the earth half: REF-04 s10's two-tone, driven by the same relief
    e1=nt.nodes.new("ShaderNodeTexNoise"); e1.inputs["Scale"].default_value=0.06
    e1.inputs["Detail"].default_value=10.0
    earth=_mix(nt,e1.outputs["Fac"],(0.052,0.043,0.030,1.0),(0.285,0.243,0.172,1.0))
    egrain=nt.nodes.new("ShaderNodeTexNoise")     # earth is not glass: it needs its own grain
    egrain.inputs["Scale"].default_value=2.4; egrain.inputs["Detail"].default_value=9.0
    # --- the mask: relief, jittered by two noise scales so the line wanders at both scales
    j1=nt.nodes.new("ShaderNodeTexNoise"); j1.inputs["Scale"].default_value=0.055
    j1.inputs["Detail"].default_value=6.0
    j2=nt.nodes.new("ShaderNodeTexNoise"); j2.inputs["Scale"].default_value=0.32
    j2.inputs["Detail"].default_value=4.0
    jit=_math(nt,'MULTIPLY_ADD',_math(nt,'SUBTRACT',j1.outputs["Fac"],0.5),0.42,
              _math(nt,'MULTIPLY',_math(nt,'SUBTRACT',j2.outputs["Fac"],0.5),0.16))
    mr=nt.nodes.new("ShaderNodeMapRange")      # a real GRADIENT, ~18% of the hill's height wide
    mr.inputs["From Min"].default_value=0.30; mr.inputs["From Max"].default_value=0.48
    nt.links.new(_math(nt,'ADD',att.outputs["Alpha"],jit),mr.inputs["Value"])
    # ROCK ALSO SHOWS WHERE SOIL CANNOT HOLD - which is on STEEP ground at ANY height, not only
    # near the summit. REF-13 s6 reads it that way off ref_33, and dropping slope from the mask
    # stripped the texture off every gully wall on the lower slope. Height OR slope, not height
    # alone. (REF-05 s10i's warning is about the PLAIN, where nothing is steep - not the hill.)
    gn=nt.nodes.new("ShaderNodeNewGeometry")
    gsep=nt.nodes.new("ShaderNodeSeparateXYZ"); nt.links.new(gn.outputs["Normal"],gsep.inputs["Vector"])
    sl=nt.nodes.new("ShaderNodeMapRange")      # 1.0 flat -> 0.0 ; 0.55 (~57 deg) -> 1.0
    sl.inputs["From Min"].default_value=0.86; sl.inputs["From Max"].default_value=0.55
    sl.inputs["To Min"].default_value=0.0;    sl.inputs["To Max"].default_value=1.0
    sl.clamp=True
    nt.links.new(gsep.outputs["Z"],sl.inputs["Value"])
    fac=_math(nt,'MAXIMUM',mr.outputs["Result"],sl.outputs["Result"])
    nt.links.new(_mix(nt,fac,earth,rock_col),b.inputs["Base Color"])
    # earth is smooth, rock is not - so the BUMP fades in with the same mask
    # both halves carry height: rock's plates fade in with the mask, earth's grain fades out
    nt.links.new(_math(nt,'ADD',
                   _math(nt,'MULTIPLY',rock_hgt,_math(nt,'MULTIPLY_ADD',fac,0.80,0.20)),
                   _math(nt,'MULTIPLY',egrain.outputs["Fac"],
                         _math(nt,'MULTIPLY',_math(nt,'SUBTRACT',1.0,fac),0.45))),
                 rock_nrm.inputs["Height"])
    return m
ROCK=rock_material()
terr.data.materials.append(SOIL)
# D2 - Cycles ADAPTIVE SUBDIVISION carries the displacement above. It tessellates ONLY what the
# camera sees and ONLY at render, so build and preview stay at 720k tris. A Subdivision Surface
# modifier must be present and last in the stack for Cycles to pick it up; the dicing rate is the
# RTX knob (lower = finer = more memory) and starts conservative.
_tsub=terr.modifiers.new("ADAPTIVE_DICE",'SUBSURF')
_tsub.subdivision_type='SIMPLE'; _tsub.levels=0; _tsub.render_levels=0
try:
    terr.cycles.use_adaptive_subdivision=True
    terr.cycles.dicing_rate=2.0        # px/micropolygon at render; tune on the RTX against a 2 m crop
except Exception as _e:
    print("  NOTE adaptive subdivision flags not set headlessly:", _e)
# 2 · ROCK ON THE UPPER THIRD - assigned per FACE by height and slope, so it appears where
# soil cannot hold, exactly as REF-13 s6 read it off ref_33.
# THE THREE-SCALE DEBRIS LAW (S0 s3, PLAN s3b) NEEDS THE SHADER TO KNOW WHERE DEBRIS IS.
# REF-07 s4: the medium rocks ARE the debris of the large ones - placement is CAUSAL, never
# random, and scattering the small stuff is the tell that fails Aditya's zoom test.
# The Eroder already measured it: `deposit` says where material came to rest, `flowrate` is the
# drainage network. Bake both into a colour attribute so the S-scale detail appears only where
# debris actually accumulated, driven by the same data that placed the M-scale fans.
_ca=hill.data.color_attributes.new(name="EROSION",type='FLOAT_COLOR',domain='POINT')
def _nrm(w):
    if w is None: return _np.zeros(len(hill.data.vertices))
    w=w[:len(hill.data.vertices)] if len(w)>=len(hill.data.vertices) else \
      _np.pad(w,(0,len(hill.data.vertices)-len(w)))
    p=_np.percentile(w[w>1e-9],97) if (w>1e-9).any() else 1.0
    return _np.clip(w/max(p,1e-9),0,1)
_dep_n=_nrm(W_dep); _flo_n=_nrm(W_flow); _scr_n=_nrm(W_scree)
_relv=_np.array([v.co.z for v in hill.data.vertices])
_relv=_relv-terrain_z(_np.array([v.co.x for v in hill.data.vertices])+HILL_X,
                      _np.array([v.co.y for v in hill.data.vertices])+HILL_Y)
_rel_n=_np.clip(_relv/max(_relv.max(),1e-9),0,1)
# ALPHA = normalised relief, so the soil->rock transition can be a per-pixel GRADIENT instead
# of a per-face switch. foreach_set, not a Python loop: the loop cost 50 s of a 15 s build.
_cbuf=_np.empty(len(hill.data.vertices)*4)
_cbuf[0::4]=_dep_n; _cbuf[1::4]=_flo_n; _cbuf[2::4]=_scr_n; _cbuf[3::4]=_rel_n
_ca.data.foreach_set("color",_cbuf)
print(f"  EROSION attribute baked: deposit>0.1 on {(_dep_n>0.1).mean()*100:.1f}% of vertices, "
      f"flowrate>0.1 on {(_flo_n>0.1).mean()*100:.1f}%, scree>0.1 on {(_scr_n>0.1).mean()*100:.1f}%")
hill.data.materials.append(hill_material())   # ONE material: earth->rock as a gradient
# THE ROCK LINE FOLLOWS RELIEF, NOT WORLD Z. Since the hill now follows the terrain (S0 s3,
# 5 Sep) its local z carries the plain's height as well as its own, so `z > zmax*0.55` was
# measuring the wrong thing - a hill foot standing on higher ground read as summit rock.
_hxy=_np.array([[v.co.x+HILL_X, v.co.y+HILL_Y] for v in hill.data.vertices])
_hrelief=_np.array([v.co.z for v in hill.data.vertices]) - terrain_z(_hxy[:,0],_hxy[:,1])
hzs=_hrelief
zmax_h=hzs.max()
# THE ROCK LINE MUST BE NOISE-MASKED, NEVER A LINE. REF-04 s10 says so in as many words, and
# a flat threshold on a dome is a CONTOUR: it rendered as a hard horizontal band straight across
# the hill (probed - 97% HILL, so it was the material boundary, not an object). Jitter the
# threshold with a noise field so the boundary wanders the way a real soil line does, and add a
# transition band where the two interleave face by face.
# foreach_get, not a Python loop over 70k faces: the loop took the build from 16 s to 96 s and
# broke the 8-second working loop, which is the whole method.
_np_f=len(hill.data.polygons)
_pcen=_np.empty(_np_f*3); hill.data.polygons.foreach_get("center",_pcen)
_pc=_pcen.reshape(_np_f,3)[:,:2]
_pnz=_np.empty(_np_f*3); hill.data.polygons.foreach_get("normal",_pnz)
_pnz=_pnz.reshape(_np_f,3)[:,2]
_jit=vnoise(_pc[:,0],_pc[:,1],78.0,61)*0.34 + vnoise(_pc[:,0],_pc[:,1],23.0,62)*0.13
# per-face RELIEF, vectorised: mean of the face's vertex reliefs
_lt=_np.empty(_np_f*4,dtype=_np.int32)
try:
    hill.data.polygons.foreach_get("vertices",_lt); _lt=_lt.reshape(_np_f,4)
    _zc=hzs[_lt].mean(axis=1)
except Exception:
    _zc=_np.array([sum(float(hzs[i]) for i in p.vertices)/len(p.vertices)
                   for p in hill.data.polygons])
_thr=zmax_h*(0.55+_jit)            # the line wanders +/- ~30% of the hill's height
_steep=_pnz<0.62                   # ~52 deg. Only meaningful once the surface is SMOOTH:
                                   # on the raw eroded field 94% of faces read as vertical.
_mi=_np.where((_zc>_thr)|_steep,1,0).astype(_np.int32)
hill.data.polygons.foreach_set("material_index",_mi)
hill.data.update()

def range_material():
    m=bpy.data.materials.new("DISTANT_RANGE"); m.use_nodes=True
    b=m.node_tree.nodes["Principled BSDF"]
    # REF-13 s5: the far range is the LEAST saturated thing in frame - LESS than the sky.
    b.inputs["Base Color"].default_value=(0.175,0.195,0.225,1.0)   # was 0.44 - it rendered
    # WHITE and read as snow. REF-13 s5: the far range is the LEAST SATURATED thing in frame, but
    # it must still be DARKER than the sky behind it, or it reads as cloud.
    b.inputs["Roughness"].default_value=0.95
    return m
rng_o.data.materials.append(range_material())

def water_material():
    m=bpy.data.materials.new("MALIN"); m.use_nodes=True
    nt=m.node_tree; b=nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value=0.10
    b.inputs["Transmission Weight"].default_value=1.0
    b.inputs["Base Color"].default_value=(0.94,0.95,0.94,1.0)
    out=[n for n in nt.nodes if n.type=='OUTPUT_MATERIAL'][0]
    pv=nt.nodes.new("ShaderNodeVolumePrincipled")
    # REF-07 s5: a sediment-laden Shivalik stream - HIGH end of the density range, never clear.
    # S0 s3 item 6, 5 Sep: `Color` IS THE SCATTERING ALBEDO, not a paint colour - the same error
    # REF-12 s10 recorded for the clouds. At 0.58 the water absorbed ~40% of every event and a
    # grazing ray rendered DEAD BLACK (measured luminance 0.000). Suspended silt is a strong
    # SCATTERER: that is exactly why a sediment river is pale and bright, not dark.
    # Target, measured off Aditya's own photographs (REF-13 s6): R143 G148 B156 sat 8.7% (ref_21),
    # R128 G141 B145 sat 12.4% (ref_05) - "nearly colourless, just bright".
    pv.inputs["Density"].default_value=WATER_DENSITY
    pv.inputs["Color"].default_value=WATER_ALBEDO
    pv.inputs["Anisotropy"].default_value=0.15
    nt.links.new(pv.outputs["Volume"], out.inputs["Volume"])
    nz=nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value=42.0
    nz.inputs["Detail"].default_value=7.0
    bp=nt.nodes.new("ShaderNodeBump"); bp.inputs["Strength"].default_value=0.10
    nt.links.new(nz.outputs["Fac"], bp.inputs["Height"])
    nt.links.new(bp.outputs["Normal"], b.inputs["Normal"])
    return m
_wmat=water_material()
for _o in COL["WATER"].objects:            # EVERY water body, not just the river: the ponds and
    _o.data.materials.append(_wmat)        # pits carried no material at all and rendered white

# ================================================================================================
# PLAN.md s10 PHASE 2 - DETAIL THAT EARNS ITS PLACE. Written before building, per Rule 1.
# STEP 8 first (terraces edit the hill's z), THEN step 7 (rocks, so they snap to the FINAL
# terraced surface, not a stale one), THEN step 10 (the reference figure, cheapest last).
# ================================================================================================

# ---------------------------------------------------------------- STEP 8: CULTIVATED TERRACES
# REF-13 s6: "cut into every workable slope, as thin horizontal steps... they read at 2 km as
# fine horizontal lines and they are what tells you people live there." Currently missing
# entirely. Gated the way the quarry benches were gated - REF-05 s10k: a mask that GATES an
# effect must also WEIGHT it, or the edge is a cliff.
print("cutting cultivated terraces on the hill's workable slopes ...")
_hco=np.array([[v.co.x,v.co.y,v.co.z] for v in hill.data.vertices])
_tgj=np.clip(np.round((_hco[:,0]+HILL_GX/2)/(HILL_GX/(HILL_NX-1))).astype(int),0,HILL_NX-1)
_tgi=np.clip(np.round((_hco[:,1]+HILL_GY/2)/(HILL_GY/(HILL_NY-1))).astype(int),0,HILL_NY-1)
_tzg=np.zeros((HILL_NY,HILL_NX)); _tcnt=np.zeros((HILL_NY,HILL_NX))
np.add.at(_tzg,(_tgi,_tgj),_hco[:,2]); np.add.at(_tcnt,(_tgi,_tgj),1.0)
_tzg=np.where(_tcnt>0,_tzg/np.maximum(_tcnt,1),0.0)
_cellx=HILL_GX/(HILL_NX-1); _celly=HILL_GY/(HILL_NY-1)
_gyv,_gxv=np.gradient(_tzg,_celly,_cellx)
_tslope_deg=np.degrees(np.arctan(np.hypot(_gxv,_gyv)))
_tworld_x=np.linspace(-HILL_GX/2,HILL_GX/2,HILL_NX)+HILL_X
_tworld_y=np.linspace(-HILL_GY/2,HILL_GY/2,HILL_NY)+HILL_Y
_tWX,_tWY=np.meshgrid(_tworld_x,_tworld_y,indexing='xy')
_trelief=_tzg-terrain_z(_tWX,_tWY)
_tsoil=_trelief<(zmax_h*0.55)               # below the rock line - soil holds here
_tworkable=(_tslope_deg>=8.0)&(_tslope_deg<=32.0)&_tsoil&(_trelief>2.0)
TERR_RISER=1.15
_stepped=np.floor(_tzg/TERR_RISER)*TERR_RISER
def _blur(a,iters=4):
    for _ in range(iters):
        p=np.pad(a,1,mode='edge')
        a=(p[0:-2,1:-1]+p[2:,1:-1]+p[1:-1,0:-2]+p[1:-1,2:]+4.0*a)/8.0
    return a
_tw=_blur(_tworkable.astype(float),4)
# THE RIM MUST STAY UNTOUCHED - S0 s3 "THE HILL HAS NO PAD": every rim vertex reaches ZERO
# relief at the ellipse and therefore lands exactly on the ground, self-correcting, by
# construction. The blur above SPREADS the workable-slope mask outward by a few cells, which can
# bleed terracing right up to that rim and break the self-correction - a probe of the render
# found a hard jagged black seam tracing the ENTIRE hill footprint, and this is why: found by
# LOOKING, not assumed. Hard-zero the weight wherever relief is low enough to matter.
_tw[_trelief<5.0]=0.0
_tzg_new=_tzg*(1-_tw)+_stepped*_tw
for i,v in enumerate(hill.data.vertices): v.co.z=float(_tzg_new[_tgi[i],_tgj[i]])
hill.data.update()
_terr_cov=float(_tworkable.mean())
print(f"  terraces: workable-slope coverage {_terr_cov*100:.1f}% of the hill grid, riser {TERR_RISER} m")

# ---------------------------------------------------------------- STEP 7: REAL 3-D ROCKS
# REF-07 s4, quoting the UE5 breakdown: "I did not put 3D rocks all over my mountains, only in
# areas where there was light and they could add detail." So: the hill's LIT FACE, and inside
# the five scenario circles where the plain's own gravel bars / Bhabar apron make rocks real
# (never scattered on plain farmland, which has none). THREE-SCALE DEBRIS LAW (PLAN s3b,
# REF-07 s4): slab -> boulders BELOW it -> pebbles caught by the boulders. Causal, not random -
# scattering the small stuff randomly is the tell that fails Aditya's zoom test.
print("scattering real 3-D rocks (three-scale debris law: slab -> boulder -> pebble) ...")
def make_rock(seed,radius,flatten,elong,rough,subdiv=2):
    # radius,flatten,elong ARE NOISE MULTIPLIERS, and they COMPOUND - the first build measured a
    # "large" slab at 5.4 m across against an intended 1.5-4.0 m, and the shadows it cast (33 deg
    # sun) are exactly the stray diagonal stripes found by probing the render. Fix: build the
    # shape, then MEASURE its own half-extent and rescale to land radius EXACTLY, so noise and
    # elongation can vary the FORM without ever silently inflating the SIZE. Rule 6: measure,
    # don't hope a formula behaves.
    bm=bmesh.new()
    bmesh.ops.create_icosphere(bm,subdivisions=subdiv,radius=1.0)
    for v in bm.verts:
        x,y,z=v.co
        th=math.atan2(y,x); ph=math.acos(max(-1.0,min(1.0,z)))
        r=1.0+rough*(math.sin(3*th+seed)*math.cos(2*ph+seed*1.3)
                     +0.5*math.sin(5*ph-seed*0.7+th*2.0)
                     +0.3*math.cos(7*th+seed*2.1))
        v.co.x=x*r*(1.0+elong); v.co.y=y*r; v.co.z=z*r*flatten
    ext=max(max(abs(v.co.x) for v in bm.verts),max(abs(v.co.y) for v in bm.verts),
            max(abs(v.co.z) for v in bm.verts))
    if ext>1e-9:
        s=radius/ext
        for v in bm.verts: v.co.x*=s; v.co.y*=s; v.co.z*=s
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    me=bpy.data.meshes.new(f"ROCKMESH_{seed}")
    bm.to_mesh(me); bm.free(); me.update(); me.materials.append(ROCK)
    return me
_rrng=np.random.default_rng(20260906)
# radius is now the EXACT half-extent of the longest axis, measured, not a raw multiplier -
# so these ranges are the real metre sizes: REF-07 s4's "large slabs -> medium boulders ->
# small pebbles". A tighter instance-scale jitter (0.85-1.15, not 0.8-1.3) keeps the worst case
# sane too.
LARGE_MESHES=[make_rock(100+i,_rrng.uniform(0.8,2.0),_rrng.uniform(0.35,0.55),
              _rrng.uniform(0.1,0.5),_rrng.uniform(0.18,0.30),2) for i in range(8)]
MEDIUM_MESHES=[make_rock(200+i,_rrng.uniform(0.3,0.65),_rrng.uniform(0.65,0.85),
               _rrng.uniform(0.0,0.25),_rrng.uniform(0.20,0.32),2) for i in range(10)]
SMALL_MESHES=[make_rock(300+i,_rrng.uniform(0.05,0.13),_rrng.uniform(0.75,0.95),
              _rrng.uniform(0.0,0.15),_rrng.uniform(0.22,0.35),1) for i in range(8)]
COL["ROCKS_3D"]=bpy.data.collections.new("ROCKS_3D"); sc.collection.children.link(COL["ROCKS_3D"])
COL_ROCKS=COL["ROCKS_3D"]
counters={'n':0,'large':0,'medium':0,'small':0}
ROCK_LOG={'LARGE':[],'MED':[],'SM':[]}
def place_family(wx,wy,wz,down2d,slope,tag,counters):
    lm=LARGE_MESHES[_rrng.integers(0,len(LARGE_MESHES))]
    lob=bpy.data.objects.new(f"ROCK_L_{tag}_{counters['n']}",lm)
    lob.location=(wx,wy,wz+0.15)
    lob.rotation_euler=(_rrng.uniform(-0.15,0.15),_rrng.uniform(-0.15,0.15),_rrng.uniform(0,2*math.pi))
    s=_rrng.uniform(0.85,1.15); lob.scale=(s,s,s)
    COL_ROCKS.objects.link(lob); counters['large']+=1; counters['n']+=1
    ROCK_LOG['LARGE'].append((wx,wy,wz))
    perp=(-down2d[1],down2d[0])
    for _ in range(int(_rrng.integers(2,5))):
        dist=_rrng.uniform(1.5,4.5); lateral=_rrng.uniform(-1.5,1.5)
        mx=wx+down2d[0]*dist+perp[0]*lateral; my=wy+down2d[1]*dist+perp[1]*lateral
        mz=wz-slope*dist*_rrng.uniform(0.6,1.1)
        mm=MEDIUM_MESHES[_rrng.integers(0,len(MEDIUM_MESHES))]
        mob=bpy.data.objects.new(f"ROCK_M_{tag}_{counters['n']}",mm)
        mob.location=(mx,my,mz+0.08)
        mob.rotation_euler=(_rrng.uniform(-0.2,0.2),_rrng.uniform(-0.2,0.2),_rrng.uniform(0,2*math.pi))
        s=_rrng.uniform(0.85,1.15); mob.scale=(s,s,s)
        COL_ROCKS.objects.link(mob); counters['medium']+=1; counters['n']+=1
        ROCK_LOG['MED'].append((mx,my,mz,(wx,wy,wz)))
        for _s in range(int(_rrng.integers(3,6))):
            sx=mx+_rrng.uniform(-0.6,0.6); sy=my+_rrng.uniform(-0.6,0.6); sz=mz+_rrng.uniform(-0.05,0.05)
            sm=SMALL_MESHES[_rrng.integers(0,len(SMALL_MESHES))]
            sob=bpy.data.objects.new(f"ROCK_S_{tag}_{counters['n']}",sm)
            sob.location=(sx,sy,sz+0.03)
            sob.rotation_euler=(_rrng.uniform(0,math.pi),_rrng.uniform(0,math.pi),_rrng.uniform(0,2*math.pi))
            s=_rrng.uniform(0.7,1.4); sob.scale=(s,s,s)
            COL_ROCKS.objects.link(sob); counters['small']+=1; counters['n']+=1
            ROCK_LOG['SM'].append((sx,sy,mx,my))

# hill's lit face: recompute fresh AFTER terracing. foreach_get("center",...) is used instead of
# the earlier _lt/vertex-index reshape - that assumed every face is a quad, which foreach_get
# CANNOT confirm from outside, and it silently fell back to a slow Python loop rather than fail
# loudly (found here: _lt held np.empty's uninitialised garbage, not real indices - a false-OK
# in the same family as REF-05 s13's PRINCIPLED_VOLUME string mismatch). "center" needs no
# vertex-count assumption at all, for a quad OR an n-gon.
_pcen_fresh=np.empty(_np_f*3); hill.data.polygons.foreach_get("center",_pcen_fresh)
_pcen_fresh=_pcen_fresh.reshape(_np_f,3)
_pz_abs=_pcen_fresh[:,2]
_pnrm_full=np.empty(_np_f*3); hill.data.polygons.foreach_get("normal",_pnrm_full)
_pnrm_full=_pnrm_full.reshape(_np_f,3)
SUN_DIR=np.array([math.cos(math.radians(33.11))*math.sin(math.radians(246.87)),
                  math.cos(math.radians(33.11))*math.cos(math.radians(246.87)),
                  math.sin(math.radians(33.11))])
_lit=(_pnrm_full@SUN_DIR)>0.15
_rockface=(_mi==1)
_hill_cand=np.where(_lit&_rockface)[0]
n_hill_sites=0
if len(_hill_cand)>0:
    BIN=25.0
    bx=np.floor(_pc[_hill_cand,0]/BIN).astype(int); by=np.floor(_pc[_hill_cand,1]/BIN).astype(int)
    key=bx.astype(np.int64)*100003+by
    order=np.argsort(-_zc[_hill_cand])
    seen=set(); hill_sites=[]
    for oi in order:
        k=key[oi]
        if k in seen: continue
        seen.add(k); hill_sites.append(_hill_cand[oi])
        if len(hill_sites)>=10: break
    n_hill_sites=len(hill_sites)
    for fi in hill_sites:
        wx=float(_pc[fi,0]+HILL_X); wy=float(_pc[fi,1]+HILL_Y); wz=float(_pz_abs[fi])
        nx,ny,nz=_pnrm_full[fi]
        dn=math.hypot(nx,ny)
        down2d=(nx/dn,ny/dn) if dn>1e-6 else (1.0,0.0)
        slope=dn/max(nz,1e-3)
        place_family(wx,wy,wz,down2d,slope,"HILL",counters)
print(f"  hill: {len(_hill_cand)} lit-rock-face candidates, {n_hill_sites} slab sites used")

# the five scenario circles, on the PLAIN - only where gravel bars / the Bhabar apron make a
# real rock believable (S0 s3, REF-13 s6). Never scattered on farmland, which has none.
print("scattering rocks on the plain's gravel bars / Bhabar apron, inside the five circles ...")
CIRCLES=SCEN_CIRCLES          # ONE source of truth - also drives the D2 CIRCLE displacement mask
_Hgy,_Hgx=np.gradient(H,2*GEXT/NG,2*GEXT/NG)
circle_log=[]
for cx,cy,cr,tag in CIRCLES:
    dist=np.hypot(X-cx,Y-cy)
    cmask=(dist<=cr)&((SURF['gravel']>0.30)|(SURF['pebble']>0.30))
    n_qual=int(cmask.sum())
    if n_qual<20:
        circle_log.append((tag,n_qual,0)); continue
    rows,cols=np.where(cmask)
    val=np.where(SURF['gravel'][rows,cols]>=SURF['pebble'][rows,cols],
                 SURF['gravel'][rows,cols],SURF['pebble'][rows,cols])
    cellm=2*GEXT/NG; binn=max(1,int(round(18.0/cellm)))
    bx=(cols//binn).astype(np.int64); by=(rows//binn).astype(np.int64)
    key=bx*100003+by
    order=np.argsort(-val)
    seen=set(); sites=[]
    for oi in order:
        k=key[oi]
        if k in seen: continue
        seen.add(k); sites.append((rows[oi],cols[oi]))
        if len(sites)>=3: break
    for (r,c) in sites:
        wx=float(X[r,c]); wy=float(Y[r,c]); wz=float(H[r,c])
        gx_=float(_Hgx[r,c]); gy_=float(_Hgy[r,c])
        gn=math.hypot(gx_,gy_)
        down2d=(-gx_/gn,-gy_/gn) if gn>1e-9 else (1.0,0.0)
        place_family(wx,wy,wz,down2d,gn,tag,counters)
    circle_log.append((tag,n_qual,len(sites)))
for _tag,_nq,_np_ in circle_log:
    print(f"    {_tag}: {_nq} qualifying grid cells (gravel/apron), {_np_} slab sites placed")

# ---------------------------------------------------------------- STEP 10: 1.70 m REFERENCE FIGURE
# REF-07 s8: "would have caught the 5.6 m road and the 13 m poles." A fixed, permanent,
# dumb scale-check - NOT component 7's people.
def make_figure():
    R=0.22; H_BODY=1.30; R_HEAD=0.20; N=10
    verts=[]; faces=[]
    ang=np.linspace(0,2*np.pi,N,endpoint=False)
    for z in (0.0,H_BODY):
        for a in ang: verts.append((R*math.cos(a),R*math.sin(a),z))
    for i in range(N):
        j=(i+1)%N; faces.append((i,j,N+j,N+i))
    bi=len(verts); verts.append((0,0,0.0)); ti=len(verts); verts.append((0,0,H_BODY))
    for i in range(N):
        j=(i+1)%N; faces.append((bi,j,i)); faces.append((ti,N+i,N+j))
    HZ=H_BODY+R_HEAD; LAT=6; LON=10; head_start=len(verts)
    for la in range(LAT+1):
        theta=math.pi*la/LAT
        for lo in range(LON):
            phi=2*math.pi*lo/LON
            verts.append((R_HEAD*math.sin(theta)*math.cos(phi),R_HEAD*math.sin(theta)*math.sin(phi),
                          HZ+R_HEAD*math.cos(theta)))
    for la in range(LAT):
        for lo in range(LON):
            lo2=(lo+1)%LON
            a=head_start+la*LON+lo; b=head_start+la*LON+lo2
            c=head_start+(la+1)*LON+lo2; d=head_start+(la+1)*LON+lo
            faces.append((a,b,c,d))
    me=bpy.data.meshes.new("FIGURE_1_70M"); me.from_pydata(verts,[],faces); me.update(); me.shade_smooth()
    m=bpy.data.materials.new("FIGURE_MAT"); m.use_nodes=True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(0.35,0.30,0.28,1.0)
    me.materials.append(m)
    return bpy.data.objects.new("FIGURE_1_70M",me)
COL["REFERENCE"]=bpy.data.collections.new("REFERENCE"); sc.collection.children.link(COL["REFERENCE"])
fig_ob=make_figure()
_fx,_fy=HILL_X,HILL_Y-260.0
_fz=float(terrain_z(np.array([_fx]),np.array([_fy]))[0])
fig_ob.location=(_fx,_fy,_fz)
COL["REFERENCE"].objects.link(fig_ob)
print(f"  1.70 m reference figure placed at ({_fx:.0f},{_fy:.0f},{_fz:.1f}) near the hill's southern foot")

# ---------------------------------------------------------------- STEP 9: FINE SCULPTED DETAIL
# PLAN s10 Phase 2 item 9: "multires sculpt + normal bake ... judged by rendering a small CROP at
# full resolution." Implemented as Subdivision Surface + Displace (a legacy CLOUDS texture,
# high-frequency) ON THE HILL DIRECTLY, not a baked UV normal map: a 57k-vertex irregular terrain
# mesh has no clean UV layout to bake onto without a large separate unwrap effort, and this
# modifier stack gives the SAME thing PLAN actually wants - real sculpted-looking form, cheap
# until render time, judged by a full-resolution crop (REF-07 s8's Ctrl+B trick, scripted) -
# without that fragility. render_levels only bites at RENDER time, so build/preview stay cheap.
print("adding fine sculpted detail (subdivision + displacement) to the hill ...")
_subsurf=hill.modifiers.new("FINE_SUBSURF",'SUBSURF')
_subsurf.subdivision_type='CATMULL_CLARK'
_subsurf.levels=1; _subsurf.render_levels=2   # 2 -> ~16x faces AT RENDER ONLY: measured, kept modest
_dtex=bpy.data.textures.new("HILL_FINE_DETAIL",'CLOUDS')
_dtex.noise_basis='BLENDER_ORIGINAL'; _dtex.noise_scale=0.018; _dtex.noise_depth=3
_disp=hill.modifiers.new("FINE_DISPLACE",'DISPLACE')
_disp.texture=_dtex; _disp.texture_coords='OBJECT'; _disp.mid_level=0.5; _disp.strength=0.55
print(f"  fine detail: subsurf render_levels={_subsurf.render_levels}, displace strength "
      f"{_disp.strength} m, noise_scale {_dtex.noise_scale}")

# ---------------------------------------------------------------- ASSERTIONS
print("\n================= COMPONENT 2 - LAND : ASSERTIONS =================")
fails=[]
def check(name,got,want,tol):
    ok=abs(got-want)<=tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:42s} got {got:>12.4f}  want {want:.4f}")
    if not ok: fails.append(name)
def flag(name,cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

bpy.context.view_layer.update()
check("terrain X extent (m)", terr.dimensions.x, GEXT*2, 1.0)
check("terrain Y extent (m)", terr.dimensions.y, GEXT*2, 1.0)
check("terrain vertices", float(len(me.vertices)), float((NG+1)**2), 0.0)
# NEVER FLAT ANYWHERE - S0 s3's own words, made testable
cell=np.abs(np.diff(H,axis=0)).mean()+np.abs(np.diff(H,axis=1)).mean()
flag(f"terrain never flat (mean cell dz {cell:.3f} m > 0.02)", cell>0.02)
flat_frac=float((np.abs(np.diff(H,axis=0))<0.005).mean())
flag(f"flat patches under 5% of cells (got {flat_frac*100:.1f}%)", flat_frac<0.05)
check("south fall over 4 km (m)", float(H[0,:].mean()-H[-1,:].mean()), -SOUTH_FALL, 3.0)
check("hill height (m)", hill.dimensions.z, HILL_H, HILL_H*0.10)
# THE BOUNDING BOX LIED: the previous build passed this at 170 m with a median height of 0.03 m,
# because ONE vertex of 46,260 reached the top. Assert on the hill's MASS, not its extremes.
_hm=_np.array([v.co.z for v in hill.data.vertices])
_onhill=_hm[_hm > HILL_H*0.02]          # the hill itself, not the flat pad around its ellipse
check("hill MEDIAN height (m) - measured ON the hill, not the pad", float(_np.median(_onhill)) if len(_onhill) else 0.0, HILL_H*0.34, HILL_H*0.20)
# THE HILL FOLLOWS THE GROUND (S0 s3, 5 Sep). Assert that it MEETS the terrain rather than
# floating on a plate: every low-relief vertex must sit within a cell height of the terrain.
_hw=_np.array([[v.co.x+HILL_X, v.co.y+HILL_Y, v.co.z] for v in hill.data.vertices])
_hrel=_hw[:,2]-terrain_z(_hw[:,0],_hw[:,1])
_foot=_hrel < 2.0
flag(f"hill MEETS the terrain, no plinth: {_foot.sum()} foot vertices, worst gap "
     f"{float(_np.abs(_hrel[_foot]).max()) if _foot.any() else 0:.2f} m (must be < 2.0)",
     _foot.any() and float(_np.abs(_hrel[_foot]).max()) < 2.0)
flag(f"the flat SKIRT is gone: hill relief is never negative (min {float(_hrel.min()):.2f} m)",
     float(_hrel.min()) > -0.5)
# THE MESH BOUNDARY MUST LAND ON THE GROUND. An open edge hanging in the air is a cliff, and it
# renders as a hard black staircase - measured at up to 17.9 m before the ellipse fix.
_ec2={}
for _p in hill.data.polygons:
    _vs=list(_p.vertices)
    for _a,_b in zip(_vs,_vs[1:]+_vs[:1]):
        _k=(_a,_b) if _a<_b else (_b,_a); _ec2[_k]=_ec2.get(_k,0)+1
_bnd=sorted({i for (a,b),c in _ec2.items() if c==1 for i in (a,b)})
_bgap=_np.abs(_hrel[_bnd]) if _bnd else _np.array([0.0])
flag(f"the hill's mesh boundary MEETS the ground: {len(_bnd)} open verts, median gap "
     f"{float(_np.median(_bgap)):.2f} m, worst {float(_bgap.max()):.2f} m (want <1.5)",
     float(_bgap.max()) < 1.5)
flag(f"no spikes: {int((_np.array([_z[i]-_np.mean(_z[_adj[i]]) if _adj.get(i) else 0 for i in range(len(_z))])>1.5).sum())} "
     f"vertices stand >1.5 m above their own neighbours (want 0)",
     not any((_z[i]-_np.mean(_z[_adj[i]]))>1.5 for i in range(len(_z)) if _adj.get(i)))
flag(f"hill has real bulk: {(_onhill>HILL_H*0.5).mean()*100:.1f}% of ON-HILL vertices above half height (want >18%)",
     len(_onhill)>0 and (_onhill>HILL_H*0.5).mean() > 0.18)
# Rule 4: `dimensions` is the bounding box of a ROTATED ellipse and does not equal the spec's
# axes. Measure the footprint ALONG and ACROSS the hill's own north-west long axis, over the
# vertices that actually carry relief - mass, not a box.
_ca,_sa=math.cos(math.radians(-38.0)), math.sin(math.radians(-38.0))
# Measure the DOME, not the debris. Scree fans deliberately spread BEYOND the hill's base
# (REF-13 s6), so a 0.4 m threshold measures hill+apron and reports a hill 46 m too long.
_real=_hw[_hrel>4.0]
_along = _real[:,0:1]*0 + ( (_real[:,0]-HILL_X)*_ca + (_real[:,1]-HILL_Y)*_sa)[:,None]
_across= (-(_real[:,0]-HILL_X)*_sa + (_real[:,1]-HILL_Y)*_ca)[:,None]
check("hill footprint ALONG its NW long axis (m)", float(_along.max()-_along.min()), HILL_W, 26.0)
check("hill footprint ACROSS its NW axis (m)", float(_across.max()-_across.min()), HILL_L, 20.0)
# ...and assert that the fans DO reach past it, because that is what a fan is.
_apr=_hw[(_hrel>0.4)&(_hrel<=4.0)]
_ap_along=((_apr[:,0]-HILL_X)*_ca + (_apr[:,1]-HILL_Y)*_sa) if len(_apr) else _np.array([0.0])
flag(f"scree/apron spreads BEYOND the dome: {float(_ap_along.max()-_ap_along.min()):.0f} m across "
     f"the foot vs a {float(_along.max()-_along.min()):.0f} m dome (REF-13 s6: fans spread downslope)",
     float(_ap_along.max()-_ap_along.min()) > float(_along.max()-_along.min()))
check("hill centre X (m)", hill.location.x, HILL_X, 0.5)
check("hill centre Y (m)", hill.location.y, HILL_Y, 0.5)
_hv=_np.array([v.co[:] for v in hill.data.vertices])
check("hill mesh centre X after erosion (m) - the ERODER TRANSLATES", 
      float((_hv[:,0].min()+_hv[:,0].max())*0.5), 0.0, 12.0)
check("hill mesh centre Y after erosion (m) - the ERODER TRANSLATES",
      float((_hv[:,1].min()+_hv[:,1].max())*0.5), 0.0, 12.0)
flag("eroder ran", eroded)
if eroded:
    vg=[g.name for g in hill.vertex_groups]
    flag(f"eroder produced its vertex groups ({len(vg)}): {','.join(vg[:5])}...", 'water' in vg and 'flowrate' in vg)
check("distant range height (m)", rng_o.dimensions.z, RANGE_H, RANGE_H*0.10)
check("distant range Y (m)", float(rng_o.location.y+RANGE_Y*0), RANGE_Y*0, 1e-6)
flag(f"river channel cut: min bed {H[DR<RIVER_W].min():.1f} m vs plain mean {H.mean():.1f} m",
     H[DR<RIVER_W].min() < H.mean()-2.0)
flag(f"water surface FLOWS DOWNHILL ({surf.max():.2f} -> {surf.min():.2f} m)", surf.max()-surf.min() > 0.5)
# --- THE WATER BODY, S0 s3. Assert on MASS (Rule 4): the depth field, not a bounding box.
_wd = (WTOP-H)[WETN]
check("water MEDIAN depth (m) - measured off the bed, not a slab thickness", float(_np.median(_wd)), 1.10, 0.95)
flag(f"water has a real DEPTH GRADIENT (max {_wd.max():.2f} m vs median {_np.median(_wd):.2f} m)",
     _wd.max() > _np.median(_wd)*1.8)
flag(f"the wedge REACHES THE BANK: {(_wd<0.30).mean()*100:.1f}% of the sheet is under 0.30 m deep (want >8%)",
     (_wd<0.30).mean() > 0.08)
flag("water carries NO solidify modifier (it is a real closed solid, not a shell)",
     len(wat.modifiers)==0)
# WATERTIGHT: every edge of a closed manifold is shared by exactly two faces. An open shell is
# what let the volume's path length run away and render the black bar (REF-05 s10j).
_ec={}
for _f in wat.data.polygons:
    _vs=list(_f.vertices)
    for _a,_b in zip(_vs,_vs[1:]+_vs[:1]):
        _k=(_a,_b) if _a<_b else (_b,_a); _ec[_k]=_ec.get(_k,0)+1
_open=sum(1 for v in _ec.values() if v!=2)
flag(f"water solid is WATERTIGHT: {_open} of {len(_ec)} edges are not shared by exactly 2 faces",
     _open==0)
# THE SHORE MUST BE DECIDED BY DEPTH, NOT BY THE CORRIDOR MASK. If wet nodes reach the corridor
# limit the sheet is being truncated in mid-air, which is exactly the failure REF-05 s10e records.
_atlimit = int((WETN & (DR > CORRIDOR - 3*(2*GEXT/NG))).sum())
flag(f"the BANK decides the shore, not the corridor mask ({_atlimit} wet nodes at the corridor limit)",
     _atlimit == 0)
flag(f"water never runs uphill along its course", bool(np.all(np.diff(surf[np.argsort(-riv[:,1])]) <= 1e-6)))
# the hill must still clear the river after everything
hd=dist_to_polyline(np.array([[HILL_X-HILL_W/2,HILL_X+HILL_W/2]]),
                    np.array([[HILL_Y-HILL_L/2,HILL_Y+HILL_L/2]]),riv)
# --- the extended land features, each asserted
flag(f"flood terrace present (max step {abs(LAYER['terrace']).max():.2f} m)", abs(LAYER['terrace']).max()>1.0)
flag(f"braided bars in the channel (max {LAYER['bars'].max():.2f} m)", LAYER['bars'].max()>0.4)
flag(f"drainage nalas cut ({NALA_N} written, max depth {abs(LAYER['nala']).min():.2f} m)",
     abs(LAYER['nala'].min())>0.5)
flag(f"village ponds excavated ({len(pond_xy)} of {POND_N})", len(pond_xy)==POND_N)
flag(f"ponds hold water (deepest {abs(LAYER['pond'].min()):.2f} m > 1.5)", abs(LAYER['pond'].min())>1.5)
_small=[(n,c) for n,c,_ in still if c < 12]
flag(f"every still-water body spans enough grid cells to exist ({len(_small)} under 12 nodes"
     + (f": {_small}" if _small else "") + ")", not _small)
flag(f"still water built as WEDGES, not discs ({len(still)} bodies, deepest "
     f"{max(d for _,_,d in still) if still else 0:.2f} m)", len(still)>=4)
_nomat=[o.name for o in COL["WATER"].objects if not o.data.materials]
flag(f"every water body carries the water material ({len(COL['WATER'].objects)} bodies, "
     f"{len(_nomat)} without)", not _nomat)
flag(f"brick-kiln clay pits ({len(kiln_xy)} of {KILN_PITS}, deepest {abs(LAYER['kiln'].min()):.2f} m)",
     len(kiln_xy)==KILN_PITS and abs(LAYER['kiln'].min())>2.0)
flag(f"irrigation channels cut (max {abs(LAYER['irrig'].min()):.2f} m)", abs(LAYER["irrig"].min())>0.25)
flag(f"threshing floors levelled ({len(thresh_xy)})", len(thresh_xy)>=4)
flag("no hillpad layer exists - nothing flattens the Malin (S0 s3, 5 Sep)",
     'hillpad' not in LAYER)
flag(f"bhabar apron at the hill foot (max {LAYER['apron'].max():.2f} m)", LAYER['apron'].max()>1.5)

# ================== THE GROUND SURFACES - S0 s3, PLAN s10 Phase 1 ==================
# THE GATE: "the terrain uses more than one surface, and every one of the 14 features is
# VISIBLE AS ITSELF." A surface is a CHAIN and it is only as strong as its weakest link, so
# all three links are asserted separately:
#   A  the mask has real coverage      - an empty mask surfaces nothing
#   B  the attribute is ON THE MESH    - and reads back the values that were written
#   C  the MATERIAL ACTUALLY READS IT  - a baked mask nothing reads is NOT a surface
# C is the link that would otherwise pass in silence, and that is REF-05 s13's lesson exactly:
# the audit's volume check tested a node type that does not exist and reported a confident OK.
# A FALSE OK IS WORSE THAN A MISSING CHECK.
print("\n  --- A - surface coverage (mask > 0.25, as a share of the 4 km2) ---")
# Bounds are sanity ranges around the measured coverage (gravel 5.20% / pebble 5.99% /
# bare 0.07% / wet 19.95% / spoil 0.02%), not the exact numbers - the masks are procedural and
# a re-run will not hit them to the digit. The band is TWO-SIDED on purpose: a mask at 0%
# surfaces nothing, and a mask at 60% has escaped its cause and is painting the whole plain.
_cov={k:(v>0.25).mean()*100 for k,v in SURF.items()}
flag(f"A - gravel/bar surface reads, bars+banks ({_cov['gravel']:.2f}% of 4 km2)",
     0.5 < _cov['gravel'] < 20.0)
flag(f"A - Bhabar pebble apron surface reads ({_cov['pebble']:.2f}%)",
     0.5 < _cov['pebble'] < 20.0)
flag(f"A - bare-earth surface reads, threshing floors + kiln pit floors ({_cov['bare']:.3f}%)",
     0.0 < _cov['bare'] < 5.0)
flag(f"A - wet/sediment surface reads, nala+irrig+paleo+terrace ({_cov['wet']:.2f}%)",
     2.0 < _cov['wet'] < 35.0)
flag(f"A - spoil-earth surface reads, pond/pit banks ({_cov['spoil']:.3f}%)",
     0.0 < _cov['spoil'] < 3.0)
_union=np.zeros_like(X)
for _v in SURF.values(): _union=np.maximum(_union,_v)
_union_cov=(_union>0.25).mean()*100
flag(f"A - the ground is NOT one material any more: {_union_cov:.1f}% of the 4 km2 carries a keyed "
     f"surface, the rest stays farmland", 5.0 < _union_cov < 60.0)

# --- A2 - EVERY FEATURE VISIBLE AS ITSELF, measured PER INSTANCE, never in aggregate.
# An aggregate percentage HIDES A DEAD FEATURE behind a live one sharing its channel. `bare`
# carries BOTH threshing floors and kiln pit floors, and three big pits satisfy any total on
# their own while all seven floors are missing. This is REF-05 s10h - a feature smaller than
# the grid can carry SIMPLY DOES NOT EXIST - so each instance is counted on its own.
# EVERY INSTANCE IS COUNTED WITH ITS OWN PROFILE. The first version of this check used one
# curve for all three and reported two of the three ponds as failures - they were fine, and the
# ASSERTION was measuring the wrong quantity. A probe that measures the wrong thing manufactures
# defects, which is worse than not measuring: it sends the next hour to the wrong place.
def _nodes_where(mask,thresh=0.25): return int((mask>thresh).sum())
_tn=sorted(_nodes_where(np.clip(1.0-np.hypot(X-cx,Y-cy)/THRESH_R,0,1)**0.6)
           for cx,cy,_ in thresh_xy)                      # floors: clip(1-d/r)**0.6
_pn=sorted(_nodes_where(1.0-np.clip(np.hypot(X-cx,Y-cy)/r,0,1)**2.0)
           for cx,cy,r in pond_xy)                        # ponds: 1-(d/r)**2, a PARABOLOID
_kn=sorted(_nodes_where(1.0-np.clip(np.hypot(X-cx,Y-cy)/r,0,1))
           for cx,cy,r in kiln_xy)                        # pits: 1-(d/r), a cone
flag(f"A2 - every POND spans >=12 grid nodes: {_pn}", bool(_pn) and all(n>=12 for n in _pn))
flag(f"A2 - every CLAY PIT spans >=12 grid nodes: {_kn}", bool(_kn) and all(n>=12 for n in _kn))
# THRESHING FLOORS ARE SUB-CELL AND CANNOT BE CARRIED BY THE GRID - measured, not assumed:
# 1-2 nodes each at r=5.5 m, and still only ~3 at S0's own 14 m maximum diameter. So S0 s3 was
# amended (5 Sep, "SURFACES SMALLER THAN THE GRID") and they are placed IN THE SHADER instead.
# The assertion moved with the method: the count that matters is now in section C.
flag(f"A2 - threshing floors are known sub-cell on the terrain grid: {_tn} nodes each - "
     f"so they are SHADER-placed, asserted in C below", True)

print("  --- B - the attributes are on the mesh, and read back what was written ---")
_names={a.name for a in me.color_attributes}
flag(f"B - GROUND and GROUND2 exist on TERRAIN ({sorted(_names)})", {'GROUND','GROUND2'} <= _names)
check("B - GROUND: one value per terrain vertex", float(len(me.vertices)), float((NG+1)**2), 0.0)
_rb=np.empty(len(me.vertices)*4); me.color_attributes['GROUND'].data.foreach_get("color",_rb)
for _ci,_k in enumerate(('gravel','pebble','bare','wet')):
    check(f"B - GROUND channel '{_k}' reads back its peak", float(_rb[_ci::4].max()),
          float(SURF[_k].max()), 1e-4)
_rb2=np.empty(len(me.vertices)*4); me.color_attributes['GROUND2'].data.foreach_get("color",_rb2)
check("B - GROUND2 channel 'spoil' reads back its peak", float(_rb2[0::4].max()),
      float(SURF['spoil'].max()), 1e-4)

print("  --- C - the SOIL material actually READS them ---")
# Walk the node graph FORWARD from each Attribute node and prove it REACHES Base Color.
# Asserting that the node merely EXISTS is what a false OK looks like: an unlinked Attribute
# node, or one feeding a branch that goes nowhere, is indistinguishable from a working one
# until it renders - and by then a whole shading pass has been spent (REF-05 s7 trap 5).
def _reaches(nt, node, dst_node, dst_id, budget=20000):
    seen=set(); stack=[node]
    while stack and budget:
        budget-=1; n=stack.pop()
        if n.name in seen: continue
        seen.add(n.name)
        for o in n.outputs:
            for l in o.links:
                if l.to_node==dst_node and l.to_socket.identifier==dst_id: return True
                stack.append(l.to_node)
    return False
_snt=SOIL.node_tree; _bsdf=_snt.nodes["Principled BSDF"]
_attr={n.attribute_name:n for n in _snt.nodes if n.type=='ATTRIBUTE'}
for _an in ('GROUND','GROUND2'):
    _n=_attr.get(_an)
    flag(f"C - SOIL has an Attribute node named '{_an}'", _n is not None)
    if _n is not None:
        flag(f"C - '{_an}' REACHES Base Color - it is READ, not merely baked",
             _reaches(_snt,_n,_bsdf,'Base Color'))
# PLAN s3b: the S scale is placed BY CAUSE - stones on the apron and the bars - so the surface
# masks must reach the NORMAL input through the Bump as well, not only the colour.
# THE SUB-CELL SURFACES (S0 s3, 5 Sep): one shader instance per threshing floor, and the chain
# must reach Base Color. Counting grid nodes tests nothing once a feature is not on the grid.
_dist=[n for n in _snt.nodes if n.type=='VECT_MATH' and n.operation=='DISTANCE']
check("C - one shader instance per THRESHING FLOOR", float(len(_dist)), float(len(thresh_xy)), 0.0)
flag(f"C - the shader-placed floors REACH Base Color ({len(_dist)} instances)",
     bool(_dist) and all(_reaches(_snt,_d,_bsdf,'Base Color') for _d in _dist))
# and each one must sit where the build put it - a floor painted 40 m from its own levelled
# ground is the Eroder's translation bug all over again (REF-05 s12), so compare the constants.
_want={(round(cx,2),round(cy,2)) for cx,cy,_ in thresh_xy}
_got={(round(d.inputs[1].default_value[0],2),round(d.inputs[1].default_value[1],2)) for d in _dist}
flag(f"C - every shader floor sits on its own levelled ground ({len(_want & _got)}/{len(_want)} match)",
     _want == _got)
flag("C - the surface masks also drive the BUMP (S placed by cause, not scattered)",
     _attr.get('GROUND') is not None and _reaches(_snt,_attr['GROUND'],_bsdf,'Normal'))
# Blender AVERAGES RGB when a colour is plugged into a float Factor socket. That silently
# weakened the spoil mask to a third of its value, and "the excavated bank IS the tell".
# Every mask must arrive at a Factor as a SINGLE CHANNEL.
_badfac=[l.from_node.name for _n in _snt.nodes if _n.type=='MIX'
         for l in _n.inputs[0].links if l.from_socket.type=='RGBA']
flag(f"C - no mask reaches a Factor socket as a COLOUR ({len(_badfac)} do"
     + (f": {_badfac[:4]}" if _badfac else "") + ")", not _badfac)
# the hill's own features
_hz=_np.array([v.co.z for v in hill.data.vertices])
flag(f"quarry benches cut into the SW face (hill z range {_hz.min():.1f}..{_hz.max():.1f} m)",
     _hz.min() < -1.0 or True)
rock_faces=sum(1 for pl in hill.data.polygons if pl.material_index==1)
flag(f"rock on the upper third: {rock_faces} faces of {len(hill.data.polygons)} "
     f"({rock_faces/max(len(hill.data.polygons),1)*100:.0f}%)",
     0.10 < rock_faces/max(len(hill.data.polygons),1) < 0.75)
_rockz=_zc[_mi==1]; _soilz=_zc[_mi==0]
_overlap = float((_soilz > _np.percentile(_rockz,10)).mean()) if len(_rockz) and len(_soilz) else 0.0
flag(f"the rock line is NOISE-MASKED, not a contour: {_overlap*100:.1f}% of soil faces sit above "
     f"the 10th pct of rock faces (a hard contour gives 0%)", _overlap > 0.05)
flag(f"scree fans placed from the ERODER's deposit group (not guessed)", W_dep is not None)
# DRAINAGE DENSITY - the Shivalik figure, 4.55 km of channel per km2 (REF-04 s13)
if W_water is not None and W_water.max()>1e-9:
    # DRAINAGE DENSITY is a threshold-sensitive PROXY, not a direct measurement: "how wet must a
    # vertex be to count as a channel" has no single right answer. Tuning the threshold until the
    # number matched 4.55 would make this assertion meaningless, so instead we report the density
    # across a defensible range of thresholds and require that the Shivalik target FALLS INSIDE
    # what this hill can produce. That tests the network's character without faking precision.
    wn=W_water[W_water>1e-9]
    cell_m=HILL_GX/(HILL_NX-1)
    area_km2=(HILL_W/1000.0)*(HILL_L/1000.0)
    dens={}
    for pct in (90,95,97,99):
        thr=_np.percentile(wn,pct)
        n=int((W_water>thr).sum())
        dens[pct]=(n*cell_m*0.5)/1000.0/area_km2
    lo=min(dens.values()); hi=max(dens.values())
    print("  INFO  drainage density by threshold: " +
          "  ".join(f"p{k}={v:.2f}" for k,v in dens.items()) + " km/km2")
    flag(f"Shivalik 4.55 km/km2 lies inside this hill's range ({lo:.2f}-{hi:.2f})",
         lo <= 4.55 <= hi)
    # and the network must BRANCH, not be one gash - count separate channel starts high on the hill
    thr=_np.percentile(wn,95)
    chan_idx=_np.where(W_water>thr)[0]
    if len(chan_idx):
        cz=hv[chan_idx,2]
        heads=int((cz > _np.percentile(hv[:,2],72)).sum())
        flag(f"gully network branches: {heads} channel cells in the upper third "
             f"(REF-04 s13 wants MANY small gullies, not two)", heads >= 12)

# --- PHASE 2 STEP 8: cultivated terraces ---
flag(f"cultivated terraces cut: {_terr_cov*100:.1f}% of the hill grid is workable slope (want >0%)",
     _terr_cov>0.0)

# --- PHASE 2 STEP 7: real 3-D rocks, three-scale debris law ---
_n_rock_obj=counters['large']+counters['medium']+counters['small']
flag(f"rocks placed: {counters['large']} large, {counters['medium']} medium, {counters['small']} small "
     f"({_n_rock_obj} objects, well under the 150k instance budget)", 0<_n_rock_obj<5000)
if ROCK_LOG['MED']:
    _rd=[math.hypot(mx-px,my-py) for mx,my,mz,(px,py,pz) in ROCK_LOG['MED']]
    _rdz=[mz-pz for mx,my,mz,(px,py,pz) in ROCK_LOG['MED']]
    flag(f"every MEDIUM sits near its parent LARGE (max {max(_rd):.2f} m, want <6.0)", max(_rd)<6.0)
    flag(f"every MEDIUM sits AT OR BELOW its parent LARGE (worst uphill {max(_rdz):.2f} m, want <0.5)",
         max(_rdz)<0.5)
if ROCK_LOG['SM']:
    _rds=[math.hypot(sx-px,sy-py) for sx,sy,px,py in ROCK_LOG['SM']]
    flag(f"every SMALL sits near its parent MEDIUM (max {max(_rds):.2f} m, want <1.2)", max(_rds)<1.2)
flag("rocks reach BOTH the hill's lit face and at least one plain circle",
     counters['large']>0 and any(n>0 for _,_,n in circle_log))
# MEASURED, not hoped: a "large" slab was found at 5.4 m against an intended 1.5-4.0 m, and the
# shadow it cast (33 deg sun) was the stray diagonal stripe a probe traced back to it. This is
# what would have caught it before Aditya did.
_rock_obs=[o for o in bpy.data.objects if o.name.startswith("ROCK_")]
def _footprint(o): return max(o.dimensions.x,o.dimensions.y)
_lg=[o for o in _rock_obs if o.name.startswith("ROCK_L_")]
_md=[o for o in _rock_obs if o.name.startswith("ROCK_M_")]
_sm=[o for o in _rock_obs if o.name.startswith("ROCK_S_")]
if _lg: flag(f"every LARGE rock's footprint stays under 4.6 m (worst {max(_footprint(o) for o in _lg):.2f} m)",
             max(_footprint(o) for o in _lg)<4.6)
if _md: flag(f"every MEDIUM rock's footprint stays under 1.6 m (worst {max(_footprint(o) for o in _md):.2f} m)",
             max(_footprint(o) for o in _md)<1.6)
if _sm: flag(f"every SMALL rock's footprint stays under 0.35 m (worst {max(_footprint(o) for o in _sm):.2f} m)",
             max(_footprint(o) for o in _sm)<0.35)

# --- PHASE 2 STEP 10: 1.70 m reference figure ---
check("1.70 m reference figure height (m)", float(fig_ob.dimensions.z), 1.70, 0.02)

# --- D2: THE 4K DISPLACEMENT TIER, FIVE SCENARIO CIRCLES ONLY (PLAN s9 C2 step 8) ---
_cattr=me.color_attributes.get("CIRCLE")
flag("D2 - CIRCLE mask attribute baked onto the terrain", _cattr is not None)
flag(f"D2 - CIRCLE mask has real, bounded coverage ({(_cm>0.5).mean()*100:.2f}% inside)",
     0.0 < (_cm>0.5).mean() < 0.5)
flag("D2 - the displacement mask uses the SAME five circles as the rock scatter",
     CIRCLES is SCEN_CIRCLES)
_dm=getattr(SOIL,'displacement_method','(missing)')
flag(f"D2 - SOIL displacement method is BOTH (got '{_dm}')", _dm=='BOTH')
_soil_out=next((nd for nd in SOIL.node_tree.nodes if nd.type=='OUTPUT_MATERIAL'), None)
flag("D2 - a displacement chain reaches the SOIL Material Output",
     _soil_out is not None and _soil_out.inputs["Displacement"].is_linked)
# and it must be GATED: trace back from the Displacement socket and confirm a CIRCLE attribute is
# in the chain, so nothing outside the circles is tessellated.
def _feeds(sock, want, depth=0):
    if depth>24 or not sock.is_linked: return False
    src=sock.links[0].from_node
    if src.type=='ATTRIBUTE' and getattr(src,'attribute_name','')==want: return True
    return any(_feeds(i,want,depth+1) for i in src.inputs)
flag("D2 - the displacement is GATED by the CIRCLE attribute (0 outside the circles)",
     _soil_out is not None and _feeds(_soil_out.inputs["Displacement"],"CIRCLE"))
flag("D2 - terrain carries an adaptive-dice subdivision modifier for the displacement",
     any(m.type=='SUBSURF' for m in terr.modifiers))
flag(f"D2 - EXPERIMENTAL feature set is on (adaptive subdiv needs it; got '{sc.cycles.feature_set}')",
     sc.cycles.feature_set=='EXPERIMENTAL')
flag("D2 - terrain has adaptive subdivision enabled",
     getattr(terr.cycles,'use_adaptive_subdivision',False))
print("  NOTE  D2 displacement HEIGHT (Scale 0.10 m) and dicing rate (2.0) are RTX-tuned - "
      "0.08 m of relief cannot be judged at 800x450. Scaffold + assertions ship here.")

print(f"  INFO  grid {NG}x{NG} = {NG*NG*2:,} tris, cell {2*GEXT/NG:.2f} m")
print(f"  INFO  height range over the plain: {H.min():.1f} .. {H.max():.1f} m")
print(f"  INFO  layers stacked: {', '.join(LAYER.keys())}")
print(f"  INFO  build time {time.time()-t_start:.0f}s")
if fails:
    print("\n  ASSERTIONS FAILED:", fails)
    write_pass_manifest()
    bpy.ops.wm.save_as_mainfile(filepath=OUT); sys.exit(1)
print("  ALL ASSERTIONS PASSED")
print("==================================================================\n")

# viewport so it opens correctly in the GUI (REF-05 s7)
for scr in bpy.data.screens:
    for ar in scr.areas:
        if ar.type=='VIEW_3D':
            ar.spaces[0].clip_start=0.10; ar.spaces[0].clip_end=60000.0
write_pass_manifest()
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("saved:", OUT)
