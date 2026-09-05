import bpy, os, math
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
sc=bpy.context.scene
def mat(n,rgb):
    m=bpy.data.materials.new(n); m.use_nodes=True
    b=m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value=(*rgb,1); b.inputs["Roughness"].default_value=0.9
    e=m.node_tree.nodes.new("ShaderNodeEmission"); e.inputs[0].default_value=(*rgb,1)
    e.inputs[1].default_value=1.0
    out=m.node_tree.nodes["Material Output"]
    m.node_tree.links.new(e.outputs[0], out.inputs["Surface"])
    return m
C={"trunk":mat("t",(0.95,0.35,0.15)),"trunk_link":mat("tl",(0.95,0.55,0.25)),
   "secondary":mat("s",(0.98,0.78,0.22)),"tertiary":mat("te",(0.95,0.93,0.60)),
   "unclassified":mat("u",(0.75,0.75,0.72)),"residential":mat("r",(0.55,0.57,0.60)),
   "living_street":mat("l",(0.45,0.75,0.95)),"service":mat("sv",(0.50,0.50,0.50)),
   "river":mat("w",(0.20,0.42,0.75))}
for o in bpy.data.objects:
    if o.type!='MESH': continue
    if o.name.startswith("RIVER"): o.data.materials.append(C["river"]); continue
    cls=o.name.split("_")[-1]
    o.data.materials.append(C.get(cls, C["residential"]))
bg=bpy.data.worlds.new("W"); sc.world=bg; bg.use_nodes=True
bg.node_tree.nodes["Background"].inputs[0].default_value=(0.06,0.06,0.07,1)
bg.node_tree.nodes["Background"].inputs[1].default_value=1.0
sc.render.engine='BLENDER_EEVEE_NEXT'
sc.render.resolution_x=1600; sc.render.resolution_y=1600
sc.view_settings.view_transform='Standard'
sc.render.filepath=f"{REF}/renders/map_01_network.png"
bpy.ops.render.render(write_still=True)
print("rendered plan")
