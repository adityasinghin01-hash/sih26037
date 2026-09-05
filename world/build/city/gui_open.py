# Runs INSIDE the Blender GUI at startup, after the .blend has loaded.
#   blender <file.blend> --python build/city/gui_open.py
# Sets the things that cannot be saved into the file (shading mode resets to SOLID on save),
# so the scene is ready to look at with no keystrokes.
import bpy

def setup():
    n=0
    for win in bpy.context.window_manager.windows:
        scr = win.screen
        for ar in scr.areas:
            if ar.type != 'VIEW_3D':
                continue
            sp = ar.spaces.active
            sp.clip_start = 0.10
            sp.clip_end   = 60000.0        # cumulus base is 1400 m, field is 44 km
            sp.lens       = 13.0           # match the dashcam so flying matches what renders
            # SOLID + cavity on open. RENDERED on a 596-object, 550k-face world is what makes
            # an 8 GB laptop hang, and hanging is the one failure mode we know this machine has.
            # Cavity shading shows the FORM - gullies, bunds, the road corridor - instantly, and
            # it is rasterised, not ray-traced. Press Z -> Rendered when you want materials.
            sp.shading.type = 'SOLID'
            sp.shading.light = 'STUDIO'
            sp.shading.color_type = 'MATERIAL'
            sp.shading.show_cavity = True
            sp.shading.cavity_type = 'BOTH'
            sp.shading.cavity_ridge_factor = 1.4
            sp.shading.cavity_valley_factor = 1.6
            sp.shading.use_scene_world_render  = True
            sp.shading.use_scene_lights_render = True
            for rg in ar.regions:
                if rg.type == 'WINDOW' and rg.data:
                    rg.data.view_perspective = 'CAMERA'   # look through CAM_DASH
            ar.tag_redraw()
            n += 1
    # --- make the RENDERED viewport actually usable on an 8 GB M1.
    # Default preview_samples is 1024: with 6 volume bounces over a 44 km cloud field that grinds
    # for minutes and reads as "the render is not working". 24 samples + denoising resolves in
    # seconds and looks the same at viewport scale. The FINAL render is unaffected (64 samples).
    cy = bpy.context.scene.cycles
    cy.preview_samples = 16
    cy.use_preview_denoising = True
    cy.preview_denoising_start_sample = 1
    cy.volume_preview_step_rate = 8.0        # coarser volume steps in the viewport only
    print(f"[gui_open] viewport: {cy.preview_samples} preview samples, denoising on")

    cam = bpy.data.objects.get("CAM_DASH")
    if cam:
        bpy.context.scene.camera = cam
    cams=[o.name for o in bpy.data.objects if o.type=='CAMERA']
    print(f"[gui_open] {n} viewport(s): SOLID+cavity, camera view, clip 0.1-60000 m")
    print(f"[gui_open] {len(cams)} cameras. Ctrl+numpad0 to look through the selected one.")
    for c in sorted(cams): print(f"             {c}")
    print("[gui_open] press Z -> Rendered for materials, light and sky (slower).")
    return None      # timer: run once

# run on a timer so the window manager is fully up before we touch it
bpy.app.timers.register(setup, first_interval=0.4)
