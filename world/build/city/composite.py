# COMPOSITE - alpha-over N chunk-rendered passes (later = on top) and MEASURE the join against
# the REFERENCE single-pass render pass_render.py also wrote. PLAN s11 warns that lighting,
# shadows and reflections do not cross passes - this is what turns that warning into a number,
# on ONE still, instead of leaving it assumed.
#   blender --background --python build/city/composite.py -- <renders_dir> <tag> <shot> <pass1> ...
# Runs inside Blender (not a bare python3) so it shares numpy and needs no venv/pip - REF-05 s2.
import bpy, sys, os
import numpy as np
a=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
RND, TAG, SHOT = a[0], a[1], a[2]
PASSES = a[3:]

def load(name):
    p=os.path.join(RND, f"{TAG}_{SHOT}_{name}.png")
    img=bpy.data.images.load(p)
    w,h=img.size
    px=np.empty(len(img.pixels), dtype=np.float32)
    img.pixels.foreach_get(px)
    bpy.data.images.remove(img)
    return px.reshape(h,w,4)

out=None
for p in PASSES:
    layer=load(p)
    if out is None:
        out=layer.copy()
    else:
        al=layer[...,3:4]
        out[...,:3]=layer[...,:3]*al+out[...,:3]*(1-al)
        out[...,3:4]=al+out[...,3:4]*(1-al)

ref=load("REFERENCE")
diff=np.abs(out[...,:3]-ref[...,:3])
worst=diff.max(axis=-1)
print(f"\n===== COMPOSITE vs REFERENCE : {TAG}_{SHOT} =====")
print(f"  passes joined      {PASSES}")
print(f"  mean abs diff      {diff.mean()*255:.2f} / 255")
print(f"  p99  abs diff      {np.percentile(diff,99)*255:.2f} / 255")
print(f"  max  abs diff      {diff.max()*255:.2f} / 255")
print(f"  pixels differing >5/255:  {(worst*255>5).mean()*100:.2f}%")
print(f"  pixels differing >20/255: {(worst*255>20).mean()*100:.2f}%")
print("=================================================\n")

h,w = out.shape[:2]
outimg=bpy.data.images.new("COMPOSITE", w, h, alpha=True)
outimg.pixels.foreach_set(out.astype(np.float32).ravel())
outimg.filepath_raw=os.path.join(RND, f"{TAG}_{SHOT}_COMPOSITE.png")
outimg.file_format='PNG'
outimg.save()
print(f"saved: {outimg.filepath_raw}")
