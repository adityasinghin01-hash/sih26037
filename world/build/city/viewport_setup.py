# Make a .blend OPEN CORRECTLY in the GUI. Run on any build output.
#   blender --background --python build/city/viewport_setup.py -- <file.blend>
# WHY THIS EXISTS: the viewport far-clip defaults to 1000 m. Our cumulus base is 1400 m and the
# cloud field is 44 km across, so at the default clip EVERY CLOUD IS BEHIND THE FAR PLANE and is
# simply not drawn. The scene looks empty and nothing is actually wrong with it.
import bpy, sys, os
args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
REF=os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
F=args[0] if args else f"{REF}/blend/01_LIGHT.blend"
bpy.ops.wm.open_mainfile(filepath=F)

CLIP_END   = 60000.0     # past the 44 km cloud field and the 4 km ground
CLIP_START = 0.10        # 1 cm start makes distant depth precision worse; 10 cm is plenty at 1.3 m

for scr in bpy.data.screens:
    for ar in scr.areas:
        if ar.type!='VIEW_3D': continue
        sp=ar.spaces[0]
        sp.clip_start=CLIP_START
        sp.clip_end=CLIP_END
        sp.lens=13.0                                  # match the dashcam lens for free navigation
        sp.shading.type='RENDERED'                    # volumes DO NOT SHOW in Solid or Material.
        # NOTE: this one does NOT survive the save - Blender resets shading to SOLID. Verified.
        # The human presses Z -> Rendered. clip_end is the part that matters and it DOES persist.
        sp.shading.use_scene_world_render=True
        sp.shading.use_scene_lights_render=True
        sp.overlay.show_overlays=True
        for reg in ar.regions:
            if reg.type=='WINDOW' and reg.data:
                reg.data.view_perspective='CAMERA'    # open looking through CAM_DASH
# and make sure the scene camera is the dashcam
cam=bpy.data.objects.get("CAM_DASH")
if cam: bpy.context.scene.camera=cam
bpy.ops.wm.save_mainfile(filepath=F)
print(f"\nVIEWPORT FIXED in {F}")
print(f"  clip {CLIP_START} .. {CLIP_END} m   shading RENDERED   view = CAMERA ({cam.name if cam else 'none'})")
print( "  clip_end PERSISTS. shading does NOT - press Z -> Rendered after opening.")
