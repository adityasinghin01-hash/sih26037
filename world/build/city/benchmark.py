# BENCHMARK - one identical scene, every Cycles device this machine actually has, seconds each.
#   blender --background --python build/city/benchmark.py
# STEP 0.1 of PLAN.md s9's step-0. Mac (M1, METAL) already measured: 24.88 s on this exact scene
# (Suzanne, subsurf render_levels 5, one sun, 256 samples, 1280x720). This script is the ONE LAB
# COMMAND - run unchanged on nvidiapc1 and it prints CUDA / OptiX / CPU without editing anything.
# Never quote 3-5x as fact until this number comes back (sih26037-lab-gpu-machine).
import bpy, time, os

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene

bpy.ops.mesh.primitive_monkey_add(size=2.0)
ob = bpy.context.active_object
mod = ob.modifiers.new("SS", 'SUBSURF')
mod.levels = 5
mod.render_levels = 5

ld = bpy.data.lights.new("SUN", 'SUN')
ld.energy = 3.0
lo = bpy.data.objects.new("SUN", ld)
sc.collection.objects.link(lo)
lo.rotation_euler = (0.6, 0.0, 0.8)

cd = bpy.data.cameras.new("CAM")
co = bpy.data.objects.new("CAM", cd)
sc.collection.objects.link(co)
sc.camera = co
co.location = (0, -6, 2)
co.rotation_euler = (1.35, 0, 0)

sc.render.engine = 'CYCLES'
sc.cycles.samples = 256
sc.render.resolution_x = 1280
sc.render.resolution_y = 720
sc.render.resolution_percentage = 100
sc.cycles.use_denoising = False
OUT = os.path.join(os.environ.get("TMPDIR", "/tmp"), "sih_benchmark")
sc.render.filepath = OUT

prefs = bpy.context.preferences.addons['cycles'].preferences
results = []

# CPU pass - always available, always the fallback that can address all system RAM
sc.cycles.device = 'CPU'
t0 = time.time()
bpy.ops.render.render(write_still=True)
results.append(("CPU", time.time() - t0))

# GPU passes - try every backend Blender ships; only the one(s) with hardware present return devices.
# METAL on the M1, CUDA + OPTIX on the RTX A1000 - same script, no machine-specific edit needed.
for backend in ('CUDA', 'OPTIX', 'METAL', 'HIP', 'ONEAPI'):
    try:
        prefs.compute_device_type = backend
    except TypeError:
        continue
    prefs.get_devices()
    found = [d for d in prefs.devices if d.type == backend]
    if not found:
        continue
    for d in prefs.devices:
        d.use = (d.type == backend)
    sc.cycles.device = 'GPU'
    t0 = time.time()
    bpy.ops.render.render(write_still=True)
    results.append((backend, time.time() - t0))

print("\n===================== BENCHMARK =====================")
for name, secs in results:
    print(f"  {name:8s} {secs:6.2f} s")
print("======================================================")
