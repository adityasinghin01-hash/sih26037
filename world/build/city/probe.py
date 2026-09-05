# PROBE - the measurement tool for "why does that pixel look like that".
# Rule 5: when something looks wrong, MEASURE it. Do not reason from geometry - that has been
# wrong five times on this project (REF-05 s5 error 4, the sky seam, the black bar).
#   blender --background --python build/city/probe.py -- <blend> <render.png> <shot> [r0 r1 c0 c1]
# With no rect it finds the darkest coherent band itself. Reports, for each sampled pixel, the
# object hit, the distance in metres, the world position and the face normal; then reports the
# region's mean sRGB and saturation so it can be compared with REF-13's measured photographs.
import bpy, sys, os, math, numpy as np
from mathutils import Vector
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
BLEND, PNG, SHOT = a[0], a[1], (a[2] if len(a)>2 else "hill")
RECT = tuple(int(v) for v in a[3:7]) if len(a)>=7 else None
# the preview camera set, kept identical to build/city/preview.py
def aim(e,az):
    e=math.radians(e); az=math.radians(az)
    return Vector((math.cos(e)*math.sin(az),math.cos(e)*math.cos(az),math.sin(e)))
SHOTS={"scree":((-675.6,614.6,55.0),aim(-6.0,307.5),50.0),
       "s4trunk":((140.6,-818.6,None),aim(-1.0,168.7),35.0),
       "chowk":((340.0,-830.0,150.0),aim(-26.0,0.0),35.0),
       "hill":((-1050.0,-100.0,240.0),aim(-12.0,0.0),35.0),
       "river":((-400.0,300.0,180.0),aim(-22.0,315.0),28.0),
       "plain":((200.0,-1200.0,90.0),aim(-6.0,0.0),24.0),
       "wide":((0.0,-2600.0,700.0),aim(-11.0,0.0),30.0)}
loc,fwd,lens=SHOTS[SHOT]

img=bpy.data.images.load(PNG); W,H=img.size
px=np.array(img.pixels[:],dtype=np.float32).reshape(H,W,4)[::-1]
lum=px[:,:,:3].mean(axis=2)
if RECT is None:
    # the darkest coherent band: rows whose dark-pixel count is far above the frame's own median
    dk=(lum < np.median(lum)*0.40)
    cnt=dk.sum(axis=1); rows=np.where(cnt > max(30, cnt.mean()*4))[0]
    if not len(rows) or not dk.any():
        print("  no dark band found - falling back to the frame centre")
        r0,r1,c0,c1 = H//2-20, H//2+20, W//4, 3*W//4
    else:
        r0,r1=int(rows.min()),int(rows.max())
        cols=np.where(dk[r0:r1+1].any(axis=0))[0]
        c0,c1=int(cols.min()),int(cols.max())
else:
    r0,r1,c0,c1=RECT
print(f"{os.path.basename(PNG)} {W}x{H} - probing rows {r0}..{r1}, cols {c0}..{c1}")

reg=px[r0:r1+1, c0:c1+1, :3].reshape(-1,3)*255.0
mx=reg.max(axis=1); mn=reg.min(axis=1)
sat=np.where(mx>0,(mx-mn)/np.maximum(mx,1e-6),0)*100
print(f"  region colour: R{reg[:,0].mean():5.1f} G{reg[:,1].mean():5.1f} B{reg[:,2].mean():5.1f}"
      f"   saturation {sat.mean():4.1f}%   luminance {reg.mean()/255:.4f}"
      f"   {(reg.mean(axis=1)<2).mean()*100:.1f}% dead black")
print( "  REF-13 s6 targets: braided river R143 G148 B156 sat 8.7% | plains water R128 G141 B145 sat 12.4%")

bpy.ops.wm.open_mainfile(filepath=BLEND)
sc=bpy.context.scene
cd=bpy.data.cameras.new("PROBE"); cd.clip_start=0.1; cd.clip_end=60000.0; cd.lens=lens
cam=bpy.data.objects.new("PROBE",cd); sc.collection.objects.link(cam); sc.camera=cam
if loc[2] is None:   # ground-relative, same rule as preview.py
    bpy.context.view_layer.update()
    dg0=bpy.context.evaluated_depsgraph_get()
    hit,l0,_,_,_,_=sc.ray_cast(dg0,Vector((loc[0],loc[1],3000.0)),Vector((0,0,-1)))
    loc=(loc[0],loc[1],(l0.z if hit else 0.0)+1.30)
cam.location=loc; cam.rotation_euler=fwd.to_track_quat('-Z','Y').to_euler()
sc.render.resolution_x=W; sc.render.resolution_y=H
bpy.context.view_layer.update()      # REF-05 s7 trap 8: matrix_world is stale without this
sw=cd.sensor_width; mw=cam.matrix_world; origin=mw.translation
dg=bpy.context.evaluated_depsgraph_get()
print("\n   px(r,c)     hit object            dist(m)      world xyz                 normal.z")
hits={}
rs=np.linspace(r0,r1,min(4,r1-r0+1)).astype(int)
cs=np.linspace(c0,c1,min(9,c1-c0+1)).astype(int)
for r in rs:
    for c in cs:
        ndc_x=(c+0.5)/W*2-1; ndc_y=1-(r+0.5)/H*2
        hx=ndc_x*(sw/2)/lens; hy=ndc_y*(sw/2)*(H/W)/lens
        d=(mw.to_3x3() @ Vector((hx,hy,-1.0))).normalized()
        hit,l,n,i,ob,_=sc.ray_cast(dg,origin,d,distance=60000.0)
        nm = ob.name if hit else "SKY"
        hits[nm]=hits.get(nm,0)+1
        if c==cs[len(cs)//2] or c==cs[0]:
            print(f"  ({r:3d},{c:3d})  {nm:22s} {((l-origin).length if hit else 0):9.1f}  "
                  f"({l.x:8.1f},{l.y:8.1f},{l.z:7.2f})   {n.z:+.3f}")
print("\n  WHAT THE REGION IS: " + ", ".join(f"{k} {v*100//sum(hits.values())}%" for k,v in
      sorted(hits.items(), key=lambda kv:-kv[1])))
