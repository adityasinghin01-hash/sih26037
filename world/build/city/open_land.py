# Runs INSIDE the Blender GUI at startup. Sets the things that cannot be saved into a file.
import bpy
def setup():
    for win in bpy.context.window_manager.windows:
        for ar in win.screen.areas:
            if ar.type!='VIEW_3D': continue
            sp=ar.spaces.active
            sp.clip_start=0.10; sp.clip_end=60000.0
            sp.shading.type='SOLID'                 # rasterised: instant, and form reads best
            sp.shading.light='STUDIO'
            sp.shading.color_type='MATERIAL'
            sp.shading.show_cavity=True             # THIS is what makes gullies and bunds visible
            sp.shading.cavity_type='BOTH'
            sp.shading.cavity_ridge_factor=1.4
            sp.shading.cavity_valley_factor=1.6
            sp.shading.curvature_ridge_factor=1.0
            sp.shading.curvature_valley_factor=1.0
            sp.overlay.show_overlays=False          # clean screenshots, no grid or gizmos
            for rg in ar.regions:
                if rg.type=='WINDOW' and rg.data: rg.data.view_perspective='CAMERA'
            ar.tag_redraw()
    print("[open_land] SOLID + cavity on, camera view, clip 60 km")
    return None
bpy.app.timers.register(setup, first_interval=0.4)
