# VIEWPORT DISPLAY COLOURS - so the world is READABLE in Blender's SOLID mode.
#   blender --background --python build/city/viewport_colors.py -- <file.blend>
#
# THE BUG THIS FIXES, found 11 Sep 2026 when Aditya opened the world in Blender and said he
# could not tell the river from the rails from a house from a building:
# `gui_open.py` opens the viewport in SOLID shading with `color_type='MATERIAL'`. In that mode
# Blender does NOT evaluate shader nodes - it reads ONE property per material,
# `material.diffuse_color` ("Viewport Display > Color" in the UI). Every material in this project
# was built with `use_nodes=True` and a Principled BSDF Base Color, and NONE of them ever set
# `diffuse_color`, so all 72 sat at Blender's default 0.8 grey. The whole world rendered
# correctly in Cycles (which is the only way it had ever been checked) and was uniformly,
# indistinguishably grey in the mode he was actually looking at it in.
# LESSON, same family as audit.py's own "a false OK is worse than a missing check": verify in
# the mode the human will actually USE, not only the one the build script happens to render.
import bpy, sys, os
a = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
BLEND = a[0] if a else None
if BLEND is None:
    print("usage: blender -b --python build/city/viewport_colors.py -- <file.blend>"); sys.exit(1)
bpy.ops.wm.open_mainfile(filepath=BLEND)

# The 13 materials whose Base Color is a procedural node network, so there is no single colour to
# read back. Each value here is the REAL dominant colour that network produces - taken from the
# base/darkest layer the shader itself mixes from, not invented, so SOLID mode is an honest
# preview of the render rather than a different-looking scene.
OVERRIDE = {
    # roads: 03h_roadmaterials.py's own asphalt base (0.052,0.050,0.048) before markings
    "ASPHALT_MARKED_14.00":   (0.052, 0.050, 0.048),
    "ASPHALT_MARKED_7.00":    (0.052, 0.050, 0.048),
    "ASPHALT_MARKED_7.00_S1": (0.052, 0.050, 0.048),
    "ASPHALT_MARKED_5.50":    (0.052, 0.050, 0.048),
    "ASPHALT_MARKED_4.50":    (0.052, 0.050, 0.048),
    "ASPHALT_MARKED_3.20":    (0.052, 0.050, 0.048),
    "BRIDGE_DECK":            (0.115, 0.112, 0.107),   # concrete deck, paler than asphalt
    "GYRATORY_KERB":          (0.520, 0.510, 0.490),   # pale kerb stone
    "BUILDING_WALL":          (0.760, 0.700, 0.580),   # the wall ramp's own mid whitewash/ochre
    "RAIL_SLEEPER":           (0.180, 0.130, 0.090),   # creosoted sleeper + ballast, dark brown
    # the hill shader mixes earth WITH rock per-pixel, so it genuinely sits between farmland
    # brown and ROCK's grey - pulling it toward grey is the faithful value, not a fudge, and it
    # is also what separates the hill from the plain at a glance (they were 0.095 apart before).
    "HILL":                   (0.300, 0.285, 0.265),
    "ROCK":                   (0.300, 0.295, 0.285),
    "SOIL":                   (0.390, 0.330, 0.245),   # the plain's farmland base
}

n_auto = n_over = n_skip = 0
for m in bpy.data.materials:
    if m.name in OVERRIDE:
        m.diffuse_color = (*OVERRIDE[m.name], 1.0)
        n_over += 1
        continue
    if not m.use_nodes:
        n_skip += 1
        continue
    b = m.node_tree.nodes.get("Principled BSDF")
    if b is None or b.inputs["Base Color"].is_linked:
        n_skip += 1
        continue
    c = b.inputs["Base Color"].default_value
    m.diffuse_color = (c[0], c[1], c[2], 1.0)
    n_auto += 1

print(f"viewport colours set: {n_auto} auto-derived from Base Color, {n_over} from the "
      f"procedural override table, {n_skip} skipped")

print("\n================= VIEWPORT COLOURS : ASSERTIONS =================")
fails = []
def flag(name, cond):
    print(f"  {'OK  ' if cond else 'FAIL'} {name}")
    if not cond: fails.append(name)

DEFAULT = (0.8, 0.8, 0.8, 1.0)
still_grey = [m.name for m in bpy.data.materials
              if tuple(round(v, 3) for v in m.diffuse_color) == DEFAULT]
flag(f"no material left at Blender's default grey ({len(still_grey)} left"
     + (f": {still_grey[:5]}" if still_grey else "") + ")", not still_grey)

# the point of the whole exercise: the big categories must be TELLABLE APART at a glance.
def dc(name):
    m = bpy.data.materials.get(name)
    return tuple(round(v, 3) for v in m.diffuse_color)[:3] if m else None
def dist(a, b):
    return None if (a is None or b is None) else sum(abs(x - y) for x, y in zip(a, b))
CATEGORY_PAIRS = [
    ("road vs building wall", "ASPHALT_MARKED_7.00", "BUILDING_WALL"),
    ("road vs bridge deck",   "ASPHALT_MARKED_7.00", "BRIDGE_DECK"),
    ("building vs kutcha hut","BUILDING_WALL",       "KUTCHA_mud_plaster"),
    ("rail vs road",          "RAIL_SLEEPER",        "ASPHALT_MARKED_7.00"),
    ("hill vs soil",          "HILL",                "SOIL"),
]
for label, a_, b_ in CATEGORY_PAIRS:
    d = dist(dc(a_), dc(b_))
    flag(f"{label}: colour separation {d if d is None else round(d,3)} (want >0.10)",
         d is not None and d > 0.10)

print("  " + ("ALL ASSERTIONS PASSED" if not fails else f"ASSERTIONS FAILED: {fails}"))
print("=" * 66)
bpy.ops.wm.save_mainfile(filepath=BLEND)
print(f"saved: {BLEND}")
if fails: sys.exit(1)
