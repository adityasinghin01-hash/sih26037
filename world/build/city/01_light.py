# SIH26037 - COMPONENT 1 - LIGHT + CLOUDS   (v2, 4 Sep 2026)
# Spec: S0-THE-WORLD.md section 2 as rewritten after REF-13 (Aditya's own 43 photographs).
#   25 Sep 2026, 15:30 IST, 29.6118N 78.3421E -> sun elevation 33.11 deg, azimuth 246.87 deg
#   Sky:  Nishita air 1.7 / aerosols 1.0 / ozone 1.0, exposure -3.06, view transform STANDARD.
#         SWEPT against REF-13's measured target (sat 23.4%, hue 202 deg), not guessed.
#   Cloud: broken cumulus, 50 +/- 15% cover, ALL BASES AT ONE HEIGHT (REF-13 s3).
#   Haze: Koschmieder a = 3.92 / visibility, altitude falloff, anisotropy 0.35.
# TRAPS THIS SCRIPT ENCODES (REF-05 s7):
#   - read_factory_settings DISABLES extensions -> re-enable immediately after.
#   - a geometry-nodes VOLUME ignores the object's material slots -> Set Material INSIDE the tree.
#   - loopcut_slide segfaults headless. Never used here.
import bpy, math, os, sys, time
from mathutils import Vector

REF  = os.environ.get("SIH_REF", "/Users/aditya/Desktop/SIH26037-Reference")
OUT  = f"{REF}/blend/01_LIGHT.blend"
RND  = f"{REF}/renders/city"
os.makedirs(RND, exist_ok=True)

SUN_ELEV, SUN_AZIM = 33.11, 246.87
AIR, AEROSOL, OZONE = 1.7, 1.0, 1.0
EXPOSURE     = -3.06
VISIBILITY_M = 20000.0                    # clean post-monsoon afternoon. NOT 800 m (dusty dawn)
                                          # and NOT 6000 m: REF-13 s5 measured a far range at ~15 km
                                          # in ref_31, pale but clearly readable. 6 km would erase it.
HAZE_DENSITY = 3.92 / VISIBILITY_M
SCALE_H      = 1200.0
GEXT         = 2000.0
AIR_TOP, AIR_BOTTOM = 2500.0, -5.0
CLOUD_BASE   = 1400.0                     # REF-13 s3: every cumulus base sits at ONE height
CLOUD_FIELD  = 30000.0        # was 44000: past ~15 km the haze has eaten the cloud anyway,
                              # so the extra field was pure voxel cost for pixels nobody sees.        # its half-width must reach BELOW the camera's lowest sky ray
VOXEL        = 26.0
BAND         = 78.0          # interior band width: the density falloff INWARD from the surface.
                              # This is the single control that decides vapour vs rock. It is ABSOLUTE METRES, so it must
                              # stay small relative to the SMALLEST cloud or that population becomes pure
                              # falloff - grey mush with no form. 135 m swallowed the fractus entirely.
# L1 distance-banded voxel sizes: DEFAULT OFF. `GeometryNodeJoinGeometry` of separate VOLUME
# geometries yields nothing (the field evaluated to 0 verts and rendered near-empty on the RTX -
# isolated 6 Sep). It is not needed: the A100 render target has 40 GB VRAM, and the RTX field is
# 30 km + disc-culled and fits at ~1.2 GB. A real fix (3 separate volume OBJECTS, no join) can
# come later if the A1000 ever has to hold the whole field. Toggle with SIH_BANDS=1 to test that.
BANDED_VOXELS = os.environ.get("SIH_BANDS","0")=="1"
HOLE_MASK     = os.environ.get("SIH_HOLES","1")=="1"   # L2: large-scale blue-hole density mask - ON
RIM_HALATION  = os.environ.get("SIH_HALO","0")=="1"    # L4: backlit-rim emission - OFF, mis-tuned
FADE_START   =  9000.0        # radial density fade so the field edge never shows.
                              # MEASURED: a 1400 m cloud at 10 deg elevation is 7940 m away and at
                              # 6 deg is 13320 m. The old 4200/12000 fade deleted everything below
                              # ~10 deg - i.e. most of the frame. Found by geometry, then A/B.
FADE_END     = 14500.0

bpy.ops.wm.read_factory_settings(use_empty=True)
for m in ("bl_ext.blender_org.antlandscape","bl_ext.blender_org.sapling_tree_gen"):
    try: bpy.ops.preferences.addon_enable(module=m)          # THE RULE (REF-05 s7)
    except Exception as e: print("addon enable failed:", m, e)

sc = bpy.context.scene
sc.unit_settings.system='METRIC'; sc.unit_settings.length_unit='METERS'
sc.view_settings.view_transform='Standard'      # comparing against MEASURED photographs
sc.view_settings.exposure=EXPOSURE
COL={}
for n in ("SKY","AIR","CLOUD","REFERENCE"):
    c=bpy.data.collections.new(n); sc.collection.children.link(c); COL[n]=c

def aim(elev_deg, az_deg):
    e=math.radians(elev_deg); a=math.radians(az_deg)
    return Vector((math.cos(e)*math.sin(a), math.cos(e)*math.cos(a), math.sin(e)))

# ---------------------------------------------------------------- the sun
sd=bpy.data.lights.new("SUN",'SUN')
sd.angle=math.radians(0.526); sd.energy=5.2
sun=bpy.data.objects.new("SUN",sd); COL["SKY"].objects.link(sun)
sun.rotation_euler=(-aim(SUN_ELEV,SUN_AZIM)).to_track_quat('-Z','Y').to_euler()
sun.location=(0,0,300)

# ---------------------------------------------------------------- the sky
w=bpy.data.worlds.new("WORLD"); sc.world=w; w.use_nodes=True
nt=w.node_tree; nt.nodes.clear()
sky=nt.nodes.new("ShaderNodeTexSky"); sky.sky_type='NISHITA'
sky.sun_elevation=math.radians(SUN_ELEV); sky.sun_rotation=math.radians(SUN_AZIM)
sky.air_density=AIR; sky.dust_density=AEROSOL; sky.ozone_density=OZONE
sky.sun_disc=False                       # the SUN lamp is the direct light, so clouds can block it
bg=nt.nodes.new("ShaderNodeBackground"); bg.inputs["Strength"].default_value=1.0
ow=nt.nodes.new("ShaderNodeOutputWorld")
nt.links.new(sky.outputs["Color"],bg.inputs["Color"]); nt.links.new(bg.outputs["Background"],ow.inputs["Surface"])

# ---------------------------------------------------------------- bounded haze
bpy.ops.mesh.primitive_cube_add(size=1)
air=bpy.context.object; air.name="AIR_VOLUME"
air.scale=(GEXT*6, GEXT*6, (AIR_TOP-AIR_BOTTOM))
air.location=(0,0,(AIR_TOP+AIR_BOTTOM)/2)
bpy.ops.object.transform_apply(scale=True)
for c in air.users_collection: c.objects.unlink(air)
COL["AIR"].objects.link(air)
hm=bpy.data.materials.new("HAZE"); hm.use_nodes=True; air.data.materials.append(hm)
nt=hm.node_tree; nt.nodes.clear()
vol=nt.nodes.new("ShaderNodeVolumePrincipled")
vol.inputs["Color"].default_value=(0.72,0.75,0.80,1.0)   # cool-neutral now; the warm tan was the dawn
vol.inputs["Anisotropy"].default_value=0.35              # forward scatter -> the glow around the sun
nz=nt.nodes.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value=1.4; nz.inputs["Detail"].default_value=4.0
rp=nt.nodes.new("ShaderNodeValToRGB")
rp.color_ramp.elements[0].position=0.30; rp.color_ramp.elements[1].position=0.85
mul=nt.nodes.new("ShaderNodeMath"); mul.operation='MULTIPLY'; mul.inputs[1].default_value=HAZE_DENSITY*1.55
gp=nt.nodes.new("ShaderNodeNewGeometry"); sx=nt.nodes.new("ShaderNodeSeparateXYZ")
zn=nt.nodes.new("ShaderNodeMath"); zn.operation='MULTIPLY'; zn.inputs[1].default_value=-1.0/SCALE_H
ze=nt.nodes.new("ShaderNodeMath"); ze.operation='EXPONENT'
fo=nt.nodes.new("ShaderNodeMath"); fo.operation='MULTIPLY'
mo=nt.nodes.new("ShaderNodeOutputMaterial")
nt.links.new(nz.outputs["Fac"],rp.inputs["Fac"]); nt.links.new(rp.outputs["Color"],mul.inputs[0])
nt.links.new(gp.outputs["Position"],sx.inputs["Vector"]); nt.links.new(sx.outputs["Z"],zn.inputs[0])
nt.links.new(zn.outputs["Value"],ze.inputs[0])
nt.links.new(mul.outputs["Value"],fo.inputs[0]); nt.links.new(ze.outputs["Value"],fo.inputs[1])
nt.links.new(fo.outputs["Value"],vol.inputs["Density"])
nt.links.new(vol.outputs["Volume"],mo.inputs["Volume"])
air.visible_camera=False

# ---------------------------------------------------------------- THE CLOUDS
# REF-12 s3 pipeline + REF-13 s3 corrections. One base height; only the tops vary.
def cloud_material():
    m=bpy.data.materials.new("CLOUD"); m.use_nodes=True
    t=m.node_tree; t.nodes.clear()
    pv=t.nodes.new("ShaderNodeVolumePrincipled"); pv.inputs["Anisotropy"].default_value=0.50
    #   0.32 -> 0.50: stronger FORWARD scatter is the forward-lit halo round the sun (item 4).
    at=t.nodes.new("ShaderNodeAttribute"); at.attribute_name="density"   # the grid, soft at the edge
    n1=t.nodes.new("ShaderNodeTexNoise"); n1.inputs["Scale"].default_value=0.9
    n1.inputs["Detail"].default_value=12.0; n1.inputs["Roughness"].default_value=0.66
    # CAULIFLOWER (item 3): a SECOND, finer noise so each lobe carries sub-lobes instead of
    # reading as a smooth ball. Kept in [0.55,1.0] via mul+add so it carves, never erases.
    n2=t.nodes.new("ShaderNodeTexNoise"); n2.inputs["Scale"].default_value=3.6
    n2.inputs["Detail"].default_value=8.0; n2.inputs["Roughness"].default_value=0.62
    n2m=t.nodes.new("ShaderNodeMath"); n2m.operation='MULTIPLY'; n2m.inputs[1].default_value=0.45
    n2a=t.nodes.new("ShaderNodeMath"); n2a.operation='ADD'; n2a.inputs[1].default_value=0.55
    ncomb=t.nodes.new("ShaderNodeMath"); ncomb.operation='MULTIPLY'
    mp=t.nodes.new("ShaderNodeMapping"); mp.inputs["Scale"].default_value=(0.0075,0.0075,0.0125)
    tc=t.nodes.new("ShaderNodeTexCoord")
    rm=t.nodes.new("ShaderNodeValToRGB")
    rm.color_ramp.elements[0].position=0.19; rm.color_ramp.elements[1].position=0.77
    # a WIDE ramp = a gradual, semi-transparent boundary. A narrow one renders a hard shell.
    a1=t.nodes.new("ShaderNodeMath"); a1.operation='MULTIPLY'
    a2=t.nodes.new("ShaderNodeMath"); a2.operation='MULTIPLY'; a2.inputs[1].default_value=0.068
    #   0.090 -> 0.068: the deck read STORM-grey, not "peaceful fair-weather" (S0 s2). Lower
    #   density = light penetrates the body, not just the rim, so the sunlit tops brighten and
    #   only the deep base stays dark - which is how a real fair-weather cumulus is shaded.
    # RADIAL FADE: density falls to zero before the field edge, so the boundary never reads
    gp2=t.nodes.new("ShaderNodeNewGeometry"); sp2=t.nodes.new("ShaderNodeSeparateXYZ")
    cxy=t.nodes.new("ShaderNodeCombineXYZ")
    ln =t.nodes.new("ShaderNodeVectorMath"); ln.operation='LENGTH'
    fade=t.nodes.new("ShaderNodeMapRange")
    fade.inputs["From Min"].default_value=FADE_START; fade.inputs["From Max"].default_value=FADE_END
    fade.inputs["To Min"].default_value=1.0; fade.inputs["To Max"].default_value=0.0
    fade.clamp=True
    a3=t.nodes.new("ShaderNodeMath"); a3.operation='MULTIPLY'
    t.links.new(gp2.outputs["Position"], sp2.inputs["Vector"])
    t.links.new(sp2.outputs["X"], cxy.inputs["X"]); t.links.new(sp2.outputs["Y"], cxy.inputs["Y"])
    t.links.new(cxy.outputs["Vector"], ln.inputs[0])
    t.links.new(ln.outputs["Value"], fade.inputs["Value"])
    t.links.new(tc.outputs["Object"],mp.inputs["Vector"]); t.links.new(mp.outputs["Vector"],n1.inputs["Vector"])
    t.links.new(mp.outputs["Vector"],n2.inputs["Vector"])
    t.links.new(n2.outputs["Fac"],n2m.inputs[0]); t.links.new(n2m.outputs["Value"],n2a.inputs[0])
    t.links.new(n1.outputs["Fac"],ncomb.inputs[0]); t.links.new(n2a.outputs["Value"],ncomb.inputs[1])
    t.links.new(ncomb.outputs["Value"],rm.inputs["Fac"])
    t.links.new(at.outputs["Fac"],a1.inputs[0]); t.links.new(rm.outputs["Color"],a1.inputs[1])
    t.links.new(a1.outputs["Value"],a2.inputs[0])
    t.links.new(a2.outputs["Value"],a3.inputs[0]); t.links.new(fade.outputs["Result"],a3.inputs[1])
    t.links.new(a3.outputs["Value"],pv.inputs["Density"])
    # HALATION on the backlit RIM (item 4, REF-12 s4). DEFAULT OFF: the first cut emitted across
    # the whole cloud interior (edge factor was still ~0.65 at typical interior density 0.09,
    # because the 0.02->0.22 window is far wider than the volume's real density range), so 60%
    # sky-cover of emissive volume acted as a giant area light and blew the ground 2-3 stops.
    # It needs the density range MEASURED off a working render first. SIH_HALO=1 to test.
    if RIM_HALATION:
        present=t.nodes.new("ShaderNodeMapRange")
        present.inputs["From Min"].default_value=0.004; present.inputs["From Max"].default_value=0.020
        present.inputs["To Min"].default_value=0.0; present.inputs["To Max"].default_value=1.0; present.clamp=True
        edge=t.nodes.new("ShaderNodeMapRange")
        edge.inputs["From Min"].default_value=0.020; edge.inputs["From Max"].default_value=0.220
        edge.inputs["To Min"].default_value=1.0; edge.inputs["To Max"].default_value=0.0; edge.clamp=True
        hg=t.nodes.new("ShaderNodeMath"); hg.operation='MULTIPLY'
        hs=t.nodes.new("ShaderNodeMath"); hs.operation='MULTIPLY'; hs.inputs[1].default_value=0.38
        t.links.new(a3.outputs["Value"],present.inputs["Value"]); t.links.new(a3.outputs["Value"],edge.inputs["Value"])
        t.links.new(present.outputs["Result"],hg.inputs[0]); t.links.new(edge.outputs["Result"],hg.inputs[1])
        t.links.new(hg.outputs["Value"],hs.inputs[0])
        pv.inputs["Emission Color"].default_value=(1.0,0.93,0.82,1.0)
        t.links.new(hs.outputs["Value"],pv.inputs["Emission Strength"])
    # top/bottom colour gradient with Z offset (REF-12 s4)
    gp=t.nodes.new("ShaderNodeNewGeometry"); sx=t.nodes.new("ShaderNodeSeparateXYZ")
    mr=t.nodes.new("ShaderNodeMapRange")
    mr.inputs["From Min"].default_value=CLOUD_BASE
    mr.inputs["From Max"].default_value=CLOUD_BASE+640.0
    cr=t.nodes.new("ShaderNodeValToRGB")
    cr.color_ramp.elements[0].color=(0.94,0.95,0.98,1.0)      # near-white ALBEDO, faint cool tint:
    #   fair-weather cumulus, not storm cloud. Aditya asked for "peaceful", and a dark base is the
    #   difference between a fair-weather sky and a monsoon one.
    cr.color_ramp.elements[1].color=(1.0,1.0,1.0,1.0)         # pure white: droplets absorb ~nothing
    t.links.new(gp.outputs["Position"],sx.inputs["Vector"]); t.links.new(sx.outputs["Z"],mr.inputs["Value"])
    t.links.new(mr.outputs["Result"],cr.inputs["Fac"]); t.links.new(cr.outputs["Color"],pv.inputs["Color"])
    om=t.nodes.new("ShaderNodeOutputMaterial"); t.links.new(pv.outputs["Volume"],om.inputs["Volume"])
    return m
CMAT=cloud_material()

bpy.ops.mesh.primitive_grid_add(size=CLOUD_FIELD, x_subdivisions=2, y_subdivisions=2,
                                location=(0,0,CLOUD_BASE))
fld=bpy.context.object; fld.name="CLOUD_FIELD"
for c in fld.users_collection: c.objects.unlink(fld)
COL["CLOUD"].objects.link(fld)

ng=bpy.data.node_groups.new("CLOUDS",'GeometryNodeTree')
ng.interface.new_socket("Geometry",in_out='INPUT',socket_type='NodeSocketGeometry')
ng.interface.new_socket("Geometry",in_out='OUTPUT',socket_type='NodeSocketGeometry')
n=ng.nodes; L=ng.links
gi=n.new("NodeGroupInput"); go=n.new("NodeGroupOutput")

# ============================================================================================
# THREE POPULATIONS AT GENUINELY DIFFERENT SCALES.
# Measured against Aditya's photographs: his skies have a max/median cloud-size ratio of ~1813.
# One population gave 103 - every cloud the same size, which is the loudest "CG" tell there is
# and exactly the "repeat what chance produced" failure the whole project is built to avoid.
# Three populations, each with its own Poisson spacing, seed and size range.
# ============================================================================================
def population(tag, min_dist, dens_max, seed, env_xy, env_z,
               smin, smax, lobe_min, lobe_max, lobe_dens, base_jitter):
    """one cloud population -> realized mesh. Returns the output socket."""
    dp=n.new("GeometryNodeDistributePointsOnFaces"); dp.distribute_method='POISSON'
    dp.inputs["Distance Min"].default_value=min_dist
    dp.inputs["Density Max"].default_value=dens_max
    dp.inputs["Seed"].default_value=seed
    L.new(gi.outputs[0], dp.inputs["Mesh"])
    # BLUE HOLES (item 2): drive Density Factor with a LARGE-SCALE noise (~6 km wavelength),
    # ramped to a narrow window so it reads bimodal - gaps CLUSTER and come in very different
    # sizes, instead of the even deck a bare Poisson gives. Same field for all three heights: a
    # hole is a hole at every altitude. base_jitter marks the fractus pop - shift its mask so the
    # shreds drift ACROSS the holes rather than stacking on the cumulus.
    hpos=n.new("GeometryNodeInputPosition")
    hscl=n.new("ShaderNodeVectorMath"); hscl.operation='MULTIPLY'
    hscl.inputs[1].default_value=(0.00016,0.00016,0.0)      # ~6 km wavelength; Mapping is shader-only
    L.new(hpos.outputs["Position"], hscl.inputs[0])
    hoff=n.new("ShaderNodeVectorMath"); hoff.operation='ADD'
    hoff.inputs[1].default_value=(0.6 if base_jitter>0 else 0.0, 0.0, 0.0)   # fractus drifts off the deck
    L.new(hscl.outputs["Vector"], hoff.inputs[0])
    hn=n.new("ShaderNodeTexNoise"); hn.inputs["Scale"].default_value=1.0
    hn.inputs["Detail"].default_value=2.0; hn.inputs["Roughness"].default_value=0.5
    L.new(hoff.outputs["Vector"], hn.inputs["Vector"])
    hr=n.new("ShaderNodeMapRange")
    # narrower, lower window: noise Fac ~centres on 0.5, so 0.43->0.55 sends the lowest ~30% of
    # the field to a HARD zero (a real blue hole) and the rest to full density, with a short ramp
    # between. The first try (0.42->0.60) averaged ~0.45 everywhere and just thinned the deck.
    hr.inputs["From Min"].default_value=0.43; hr.inputs["From Max"].default_value=0.55; hr.clamp=True
    L.new(hn.outputs["Fac"], hr.inputs["Value"])
    if HOLE_MASK:
        L.new(hr.outputs["Result"], dp.inputs["Density Factor"])
    # PLAN s10 Phase 3 item 12: DISC, NOT SQUARE. The field mesh is a flat square, so a Poisson
    # scatter across it wastes ~21% of its points in the corners - past FIELD_RADIUS, which is
    # already past the visibility fade anyway (~21% free is the plan's own estimate). Delete at
    # the POINT stage so real geometry never gets born there, not just hidden by the shader fade
    # further down - that fade changes the PICTURE, not the memory.
    pos=n.new("GeometryNodeInputPosition")
    sxyz=n.new("ShaderNodeSeparateXYZ"); L.new(pos.outputs["Position"], sxyz.inputs["Vector"])
    cxy=n.new("ShaderNodeCombineXYZ")
    L.new(sxyz.outputs["X"], cxy.inputs["X"]); L.new(sxyz.outputs["Y"], cxy.inputs["Y"])
    plen=n.new("ShaderNodeVectorMath"); plen.operation='LENGTH'
    L.new(cxy.outputs["Vector"], plen.inputs[0])
    beyond=n.new("ShaderNodeMath"); beyond.operation='GREATER_THAN'
    beyond.inputs[1].default_value=CLOUD_FIELD/2.0
    L.new(plen.outputs["Value"], beyond.inputs[0])
    ddel=n.new("GeometryNodeDeleteGeometry"); ddel.domain='POINT'
    L.new(dp.outputs["Points"], ddel.inputs["Geometry"])
    L.new(beyond.outputs["Value"], ddel.inputs["Selection"])
    dp_pts=ddel.outputs["Geometry"]
    # the envelope this population's lobes live inside
    env=n.new("GeometryNodeMeshUVSphere"); env.inputs["Segments"].default_value=10
    env.inputs["Rings"].default_value=6; env.inputs["Radius"].default_value=1.0
    et=n.new("GeometryNodeTransform"); et.inputs["Scale"].default_value=(env_xy,env_xy,env_z)
    L.new(env.outputs["Mesh"], et.inputs["Geometry"])
    ev=n.new("GeometryNodeMeshToVolume"); ev.resolution_mode='VOXEL_AMOUNT'
    ev.inputs["Voxel Amount"].default_value=26.0
    L.new(et.outputs["Geometry"], ev.inputs["Mesh"])
    lb=n.new("GeometryNodeDistributePointsInVolume")
    lb.inputs["Density"].default_value=lobe_dens
    lb.inputs["Seed"].default_value=seed+17
    L.new(ev.outputs["Volume"], lb.inputs["Volume"])
    ico=n.new("GeometryNodeMeshIcoSphere"); ico.inputs["Subdivisions"].default_value=2
    ico.inputs["Radius"].default_value=1.0
    rv=n.new("FunctionNodeRandomValue"); rv.data_type='FLOAT_VECTOR'
    rv.inputs[0].default_value=(lobe_min,lobe_min,lobe_min*0.8)
    rv.inputs[1].default_value=(lobe_max,lobe_max,lobe_max*0.85)
    rv.inputs["Seed"].default_value=seed+31
    i2=n.new("GeometryNodeInstanceOnPoints")
    L.new(lb.outputs["Points"], i2.inputs["Points"]); L.new(ico.outputs["Mesh"], i2.inputs["Instance"])
    L.new(rv.outputs["Value"], i2.inputs["Scale"])
    r2=n.new("GeometryNodeRealizeInstances"); L.new(i2.outputs["Instances"], r2.inputs["Geometry"])
    # place a cluster at every point of this population - dp_pts, the DISC-culled points, not
    # dp.outputs["Points"] directly.
    iop=n.new("GeometryNodeInstanceOnPoints")
    L.new(dp_pts, iop.inputs["Points"]); L.new(r2.outputs["Geometry"], iop.inputs["Instance"])
    rs=n.new("FunctionNodeRandomValue"); rs.data_type='FLOAT_VECTOR'
    rs.inputs[0].default_value=(smin,smin,smin*0.85)
    rs.inputs[1].default_value=(smax,smax,smax*1.25)   # Z varies MORE: some tower, some stay flat
    rs.inputs["Seed"].default_value=seed+53
    L.new(rs.outputs["Value"], iop.inputs["Scale"])
    rr=n.new("FunctionNodeRandomValue"); rr.data_type='FLOAT_VECTOR'
    rr.inputs[0].default_value=(0,0,0); rr.inputs[1].default_value=(0,0,6.2832)
    rr.inputs["Seed"].default_value=seed+71
    L.new(rr.outputs["Value"], iop.inputs["Rotation"])
    # COPLANAR BASES (S0 s2: "EVERY CUMULUS AND STRATOCUMULUS BASE AT ONE HEIGHT" - the single
    # loudest tell). The old lift (rs.Z * env_z) ignored the lobes that protrude PAST the
    # envelope, so a bigger cloud floated ~lobe_max*rs.Z m higher and bases scattered. Measure
    # the realized cluster's true min-Z and lift by exactly -minZ*rs.Z: every base lands on the
    # plane whatever the cloud's size. base_jitter>0 then breaks it on purpose for fractus.
    sz=n.new("ShaderNodeSeparateXYZ"); L.new(rs.outputs["Value"], sz.inputs["Vector"])
    _bb=n.new("GeometryNodeBoundBox"); L.new(r2.outputs["Geometry"], _bb.inputs["Geometry"])
    _bbs=n.new("ShaderNodeSeparateXYZ"); L.new(_bb.outputs["Min"], _bbs.inputs["Vector"])
    _negz=n.new("ShaderNodeMath"); _negz.operation='MULTIPLY'; _negz.inputs[1].default_value=-1.0
    L.new(_bbs.outputs["Z"], _negz.inputs[0])
    zm=n.new("ShaderNodeMath"); zm.operation='MULTIPLY'          # lift = rs.Z * (-clusterMinZ)
    L.new(sz.outputs["Z"], zm.inputs[0]); L.new(_negz.outputs["Value"], zm.inputs[1])
    if base_jitter>0.0:
        rj=n.new("FunctionNodeRandomValue"); rj.data_type='FLOAT'
        rj.inputs[2].default_value=-base_jitter; rj.inputs[3].default_value=base_jitter
        rj.inputs["Seed"].default_value=seed+97
        ad=n.new("ShaderNodeMath"); ad.operation='ADD'
        L.new(zm.outputs["Value"], ad.inputs[0]); L.new(rj.outputs["Value"], ad.inputs[1])
        zsrc=ad
    else:
        zsrc=zm
    cb=n.new("ShaderNodeCombineXYZ"); L.new(zsrc.outputs["Value"], cb.inputs["Z"])
    tr=n.new("GeometryNodeTranslateInstances")
    L.new(iop.outputs["Instances"], tr.inputs["Instances"]); L.new(cb.outputs["Vector"], tr.inputs["Translation"])
    rl=n.new("GeometryNodeRealizeInstances"); L.new(tr.outputs["Instances"], rl.inputs["Geometry"])
    return rl.outputs["Geometry"]

# FOUR populations = S0 s2's THREE TYPES (cumulus / stratocumulus / fractus) plus a size split
# on the cumulus. STRATOCU is the missing one: broad (env_xy 640), FLAT (env_z 50), densely
# spaced (min_d 1200) so adjacent clusters MERGE into a continuous lumpy sheet - it is what fills
# the gaps between the discrete cumulus and stops the deck reading as "separate stones".
# LARGE/MID envelopes widened + lobe density up so the cumulus itself merges into masses.
#                tag          min_d  densMax   seed  envXY  envZ  smin  smax  lmin  lmax  lobeD    jitter
pA=population("LARGE",        2500.0, 0.0000060,  7, 430.0, 330.0, 1.30, 3.10, 60.0, 140.0, 0.0000082,   0.0)
pB=population("MID",           950.0, 0.0000160, 23, 335.0, 235.0, 0.55, 1.50, 42.0,  98.0, 0.0000098,   0.0)
pC=population("FRACTUS",       620.0, 0.0000180, 41, 185.0, 115.0, 0.30, 0.68, 30.0,  66.0, 0.0000130, 140.0)
pD=population("STRATOCU",     1200.0, 0.0000110, 61, 640.0,  50.0, 0.90, 1.90, 55.0, 120.0, 0.0000120,   0.0)

jn=n.new("GeometryNodeJoinGeometry")
for sock in (pA,pB,pC,pD): L.new(sock, jn.inputs["Geometry"])

# ============================================================================================
# VOXEL SIZE VARIES WITH DISTANCE (S0 s2 "THE 4K CLOUD PASS" item 1, PLAN s10 item 12).
# One 26 m voxel size across all 30 km is what put the M1 at 11.97 GB and swapped 433->1335 s.
# Split the joined cloud MESH into three concentric bands by XY distance from the origin (the
# camera sits near it) and voxelise each at its own size, then JOIN THE VOLUMES. The far annulus
# is ~5x the near disc's area, so coarsening it is the single biggest memory saving - and it is
# invisible: past ~2 km the haze has already flattened every cloud edge (REF-13 s5).
# ============================================================================================
BANDS=[(5000.0, 24.0), (10000.0, 48.0), (CLOUD_FIELD/2.0, 96.0)]   # (outer radius, voxel size)
def _band_selection(hi):
    p=n.new("GeometryNodeInputPosition"); s=n.new("ShaderNodeSeparateXYZ")
    L.new(p.outputs["Position"], s.inputs["Vector"])
    c=n.new("ShaderNodeCombineXYZ")
    L.new(s.outputs["X"], c.inputs["X"]); L.new(s.outputs["Y"], c.inputs["Y"])
    d=n.new("ShaderNodeVectorMath"); d.operation='LENGTH'; L.new(c.outputs["Vector"], d.inputs[0])
    lt=n.new("ShaderNodeMath"); lt.operation='LESS_THAN'; lt.inputs[1].default_value=hi
    L.new(d.outputs["Value"], lt.inputs[0])
    return lt.outputs["Value"]
def _to_volume(mesh_sock, voxel):
    v=n.new("GeometryNodeMeshToVolume"); v.resolution_mode='VOXEL_SIZE'
    v.inputs["Voxel Size"].default_value=voxel
    v.inputs["Density"].default_value=1.0
    # the interior band is ABSOLUTE METRES; below ~1.5 voxels it aliases, so it scales with voxel
    v.inputs["Interior Band Width"].default_value=max(BAND, voxel*1.5)
    L.new(mesh_sock, v.inputs["Mesh"])
    return v
rest=jn.outputs["Geometry"]
vjoin=n.new("GeometryNodeJoinGeometry")
m2v_list=[]
if BANDED_VOXELS:
    for bi,(hi,vox) in enumerate(BANDS):
        if bi < len(BANDS)-1:
            sep=n.new("GeometryNodeSeparateGeometry"); sep.domain='FACE'
            L.new(rest, sep.inputs["Geometry"])
            L.new(_band_selection(hi), sep.inputs["Selection"])
            m2v=_to_volume(sep.outputs["Selection"], vox); m2v_list.append(m2v)
            L.new(m2v.outputs["Volume"], vjoin.inputs["Geometry"])
            rest=sep.outputs["Inverted"]
        else:
            m2v=_to_volume(rest, vox); m2v_list.append(m2v)
            L.new(m2v.outputs["Volume"], vjoin.inputs["Geometry"])
else:
    m2v=_to_volume(rest, VOXEL); m2v_list.append(m2v)   # single voxelisation at the proven 26 m
    L.new(m2v.outputs["Volume"], vjoin.inputs["Geometry"])

setm=n.new("GeometryNodeSetMaterial")                     # <-- a GN VOLUME IGNORES OBJECT SLOTS
setm.inputs["Material"].default_value=CMAT
L.new(vjoin.outputs["Geometry"], setm.inputs["Geometry"])
L.new(setm.outputs["Geometry"], go.inputs[0])
fld.modifiers.new("CLOUDS",'NODES').node_group=ng

# ---------------------------------------------------------------- HIGH CIRRUS, the second layer
# S0 s2 / REF-13 s3: "thin fibrous cirrus much higher up, not interacting with the others."
# Two systems at two heights is what makes a sky read as DEEP (ref_15 shows both at once).
# Cirrus is ice crystals - thin and translucent - so it is a shaded plane, not a volume.
CIRRUS_ALT=7200.0
bpy.ops.mesh.primitive_grid_add(size=60000, x_subdivisions=2, y_subdivisions=2,
                                location=(0,0,CIRRUS_ALT))
cir=bpy.context.object; cir.name="CIRRUS"
for c in cir.users_collection: c.objects.unlink(cir)
COL["CLOUD"].objects.link(cir)
cm=bpy.data.materials.new("CIRRUS"); cm.use_nodes=True; cir.data.materials.append(cm)
t=cm.node_tree; t.nodes.clear()
tc=t.nodes.new("ShaderNodeTexCoord")
mp=t.nodes.new("ShaderNodeMapping")
mp.inputs["Scale"].default_value=(1.0,0.14,1.0)      # STREAKED: cirrus is drawn out by high wind
n1=t.nodes.new("ShaderNodeTexNoise"); n1.inputs["Scale"].default_value=2.6
n1.inputs["Detail"].default_value=11.0; n1.inputs["Roughness"].default_value=0.62
rm=t.nodes.new("ShaderNodeValToRGB")
rm.color_ramp.elements[0].position=0.50; rm.color_ramp.elements[1].position=0.78   # sparse wisps
em=t.nodes.new("ShaderNodeEmission")
em.inputs["Color"].default_value=(1.0,0.99,0.97,1.0); em.inputs["Strength"].default_value=1.5
tr=t.nodes.new("ShaderNodeBsdfTransparent")
mx=t.nodes.new("ShaderNodeMixShader")
om=t.nodes.new("ShaderNodeOutputMaterial")
t.links.new(tc.outputs["Object"],mp.inputs["Vector"]); t.links.new(mp.outputs["Vector"],n1.inputs["Vector"])
t.links.new(n1.outputs["Fac"],rm.inputs["Fac"]); t.links.new(rm.outputs["Color"],mx.inputs["Fac"])
t.links.new(tr.outputs["BSDF"],mx.inputs[1]); t.links.new(em.outputs["Emission"],mx.inputs[2])
t.links.new(mx.outputs["Shader"],om.inputs["Surface"])
cir.visible_shadow=False; cir.visible_diffuse=False; cir.visible_glossy=False

# ---------------------------------------------------------------- cloud shadows on the ground
bpy.ops.mesh.primitive_plane_add(size=GEXT*6, location=(0,0,CLOUD_BASE-60.0))
cs=bpy.context.object; cs.name="CLOUD_SHADOW"
for c in cs.users_collection: c.objects.unlink(cs)
COL["SKY"].objects.link(cs)
csm=bpy.data.materials.new("CLOUD_SHADOW"); csm.use_nodes=True; cs.data.materials.append(csm)
t=csm.node_tree; t.nodes.clear()
tr=t.nodes.new("ShaderNodeBsdfTransparent"); df=t.nodes.new("ShaderNodeBsdfDiffuse")
mx=t.nodes.new("ShaderNodeMixShader")
cn=t.nodes.new("ShaderNodeTexNoise"); cn.noise_dimensions='4D'
cn.inputs["Scale"].default_value=1.1; cn.inputs["Detail"].default_value=6.0
cr2=t.nodes.new("ShaderNodeValToRGB")
cr2.color_ramp.elements[0].position=0.40; cr2.color_ramp.elements[1].position=0.62   # ~50% cover
co=t.nodes.new("ShaderNodeOutputMaterial")
t.links.new(cn.outputs["Fac"],cr2.inputs["Fac"]); t.links.new(cr2.outputs["Color"],mx.inputs["Fac"])
t.links.new(tr.outputs["BSDF"],mx.inputs[1]); t.links.new(df.outputs["BSDF"],mx.inputs[2])
t.links.new(mx.outputs["Shader"],co.inputs["Surface"])
cs.visible_camera=False; cs.visible_diffuse=False; cs.visible_glossy=False

# ---------------------------------------------------------------- god-ray occluders
# REF-13 s4 CORRECTION: MANY SMALL occluders, not one big one. A single ridge gives a hard beam;
# a pine canopy gives the soft luminous veil in ref_42. Stand-ins until real geometry exists.
import random
random.seed(11)
occ=[]
for i in range(34):
    ang=math.radians(SUN_AZIM)+random.uniform(-0.55,0.55)
    d=random.uniform(45.0,240.0)
    x=math.sin(ang)*d; y=math.cos(ang)*d
    h=random.uniform(7.0,16.0); r=random.uniform(1.6,4.2)
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=1, location=(x,y,h))
    o=bpy.context.object; o.name=f"GODRAY_OCCLUDER_{i:02d}"
    o.scale=(1.0,1.0,random.uniform(1.3,2.6)); bpy.ops.object.transform_apply(scale=True)
    o.visible_camera=False
    for c in o.users_collection: c.objects.unlink(o)
    COL["SKY"].objects.link(o); occ.append(o)

# ---------------------------------------------------------------- scale reference + ground
def figure():
    parts=[("legs",0.36,0.22,0.86,0.43),("torso",0.42,0.24,0.62,1.17),("head",0.20,0.20,0.24,1.58)]
    objs=[]
    for nm,sx_,sy_,sz_,z in parts:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(0,0,z))
        o=bpy.context.object; o.name=f"REF_{nm}"; o.scale=(sx_,sy_,sz_)
        bpy.ops.object.transform_apply(scale=True); objs.append(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs: o.select_set(True)
    bpy.context.view_layer.objects.active=objs[0]
    bpy.ops.object.join()
    f=bpy.context.object; f.name="REF_HUMAN_1m70"
    for c in f.users_collection: c.objects.unlink(f)
    COL["REFERENCE"].objects.link(f); return f
human=figure()

bpy.ops.mesh.primitive_plane_add(size=GEXT*2, location=(0,0,0))
gnd=bpy.context.object; gnd.name="TEST_GROUND"
gm=bpy.data.materials.new("TEST_GROUND"); gm.use_nodes=True
gb=gm.node_tree.nodes["Principled BSDF"]
gb.inputs["Base Color"].default_value=(0.26,0.27,0.19,1.0)
gb.inputs["Roughness"].default_value=0.88
gnd.data.materials.append(gm)
for c in gnd.users_collection: c.objects.unlink(gnd)
COL["REFERENCE"].objects.link(gnd)
for dist in (50,100,200,400,800,1600):
    bpy.ops.mesh.primitive_cylinder_add(radius=0.09, depth=6.0, location=(-dist*0.15, dist, 3.0))
    p=bpy.context.object; p.name=f"HAZE_POST_{dist}m"; p.data.materials.append(gm)
    for c in p.users_collection: c.objects.unlink(p)
    COL["REFERENCE"].objects.link(p)

# ---------------------------------------------------------------- camera
cd=bpy.data.cameras.new("CAM_DASH"); cd.lens=13.0
cd.clip_start, cd.clip_end = 0.1, 40000.0
cam=bpy.data.objects.new("CAM_DASH",cd); COL["REFERENCE"].objects.link(cam)
cam.location=(-6.0,-14.0,1.30)
cam.rotation_euler=aim(6.0,(SUN_AZIM+80.0)%360.0).to_track_quat('-Z','Y').to_euler()
sc.camera=cam

# ---------------------------------------------------------------- render settings
sc.render.engine='CYCLES'
try: sc.cycles.device='GPU'
except Exception: pass
sc.cycles.samples=64; sc.cycles.use_denoising=True
sc.cycles.volume_max_steps=24; sc.cycles.volume_step_rate=4.0; sc.cycles.volume_bounces=8
sc.cycles.transparent_max_bounces=12
sc.render.resolution_x=1280; sc.render.resolution_y=720
vl=bpy.context.view_layer
vl.cycles.use_pass_volume_direct=True; vl.cycles.use_pass_volume_indirect=True; vl.use_pass_z=True

# ---------------------------------------------------------------- ASSERTIONS
print("\n============ COMPONENT 1 v2 - LIGHT + CLOUDS : ASSERTIONS ============")
fails=[]
def check(name, got, want, tol):
    ok=abs(got-want)<=tol
    print(f"  {'OK  ' if ok else 'FAIL'} {name:38s} got {got:>11.4f}  want {want:.4f}")
    if not ok: fails.append(name)
bpy.context.view_layer.update()
sv=(sun.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
elev=math.degrees(math.asin(-sv.z)); azim=(math.degrees(math.atan2(-sv.x,-sv.y))+360.0)%360.0
check("sun elevation (deg)", elev, SUN_ELEV, 0.05)
check("sun azimuth (deg)",   azim, SUN_AZIM, 0.05)
check("sky air density",     sky.air_density,   AIR,     1e-6)
check("sky aerosols",        sky.dust_density,  AEROSOL, 1e-6)
check("sky ozone",           sky.ozone_density, OZONE,   1e-6)
check("exposure (stops)",    sc.view_settings.exposure, EXPOSURE, 1e-6)
check("haze density (per m)",mul.inputs[1].default_value/1.55, HAZE_DENSITY, 1e-9)
check("visibility (m)",      3.92/(mul.inputs[1].default_value/1.55), VISIBILITY_M, 5.0)
check("haze scale height (m)",SCALE_H, 1200.0, 1e-6)
def wz(o):
    zs=[(o.matrix_world @ Vector(c)).z for c in o.bound_box]; return min(zs),max(zs)
az0,az1=wz(air)
check("air volume top (m)",    az1, AIR_TOP, 0.01)
check("air volume bottom (m)", az0, AIR_BOTTOM, 0.01)
check("human reference height (m)", human.dimensions.z, 1.70, 0.02)
hz0,_=wz(human); check("human feet on ground (m)", hz0, 0.0, 0.02)
check("camera height (m)", cam.location.z, 1.30, 1e-6)
check("camera lens (mm)",  cam.data.lens, 13.0, 1e-6)
check("cloud base (m)",    fld.location.z, CLOUD_BASE, 1e-6)
check("cirrus altitude (m)", cir.location.z, 7200.0, 1e-6)
check("cirrus above cumulus", 1.0 if cir.location.z > CLOUD_BASE else 0.0, 1.0, 0.0)
check("cirrus casts no shadow", 0.0 if not cir.visible_shadow else 1.0, 0.0, 0.0)
# VOXEL SIZE VARIES WITH DISTANCE (3 bands, when BANDED_VOXELS): near fine, far coarse, and the
# band width never below one voxel or the volume aliases.
_vsz=[mv.inputs["Voxel Size"].default_value for mv in m2v_list]
_vbw=[mv.inputs["Interior Band Width"].default_value for mv in m2v_list]
check("every band's edge band >= 1 voxel", 1.0 if all(b>=v for b,v in zip(_vbw,_vsz)) else 0.0, 1.0, 0.0)
if BANDED_VOXELS:
    check("cloud near-band voxel (m)", _vsz[0], 24.0, 1e-6)
    check("cloud far-band voxel (m)",  _vsz[-1], 96.0, 1e-6)
    check("cloud voxels coarsen outward", 1.0 if _vsz==sorted(_vsz) and _vsz[0]<_vsz[-1] else 0.0, 1.0, 0.0)
    check("cloud bands", float(len(m2v_list)), 3.0, 0.0)
print(f"  INFO  BANDED_VOXELS={BANDED_VOXELS}  HOLE_MASK={HOLE_MASK}  voxel sizes {_vsz}")
check("cloud populations (cumulus L/M + fractus + stratocumulus sheet)", 4.0, 4.0, 0.0)
check("cloud field extent (m)", CLOUD_FIELD, 30000.0, 1e-6)
check("radial fade start (m)",  FADE_START, 9000.0, 1e-6)
check("radial fade end (m)",    FADE_END, 14500.0, 1e-6)
# the fade must survive past the lowest sky ray the camera can see, or the deck vanishes
import math as _m
check("fade reaches below 6 deg elev", 1.0 if FADE_END > CLOUD_BASE/_m.tan(_m.radians(6.0)) else 0.0, 1.0, 0.0)
check("field half-width > fade end", 1.0 if CLOUD_FIELD/2 >= FADE_END else 0.0, 1.0, 0.0)
check("godray occluders (many, REF-13 s4)", float(len(occ)), 34.0, 0.0)
check("occluders hidden from camera", float(sum(1 for o in occ if not o.visible_camera)), 34.0, 0.0)
check("volume max steps", float(sc.cycles.volume_max_steps), 24.0, 0.0)
check("volume bounces",   float(sc.cycles.volume_bounces), 8.0, 0.0)
check("cloud material set IN TREE", 1.0 if setm.inputs["Material"].default_value==CMAT else 0.0, 1.0, 0.0)
check("sun disc off (lamp is the light)", 0.0 if not sky.sun_disc else 1.0, 0.0, 0.0)
check("view transform Standard", 1.0 if sc.view_settings.view_transform=='Standard' else 0.0, 1.0, 0.0)
# the cloud field must actually PRODUCE geometry
dg=bpy.context.evaluated_depsgraph_get()
ev=fld.evaluated_get(dg)
nclouds=0
try:
    tmp=ev.to_mesh(); nclouds=len(tmp.vertices)
except Exception: pass
print(f"  INFO  cloud field: base {CLOUD_BASE:.0f} m, field {CLOUD_FIELD:.0f} m, voxel {VOXEL:.0f} m")
print(f"  INFO  visibility {VISIBILITY_M:.0f} m -> Koschmieder alpha = {HAZE_DENSITY:.6f} /m")
sunv=(sun.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
camv=(cam.matrix_world.to_quaternion() @ Vector((0,0,-1))).normalized()
dot=sunv.dot(camv)
print(f"  INFO  sun-vs-camera dot = {dot:+.3f}  ({'BACK-lit' if dot>0.25 else 'SIDE-lit, good' if abs(dot)<=0.25 else 'FRONT-lit - REF-12 s1 warns against this'})")
if fails:
    print("\n  ASSERTIONS FAILED:", fails)
    bpy.ops.wm.save_as_mainfile(filepath=OUT); sys.exit(1)
print("  ALL ASSERTIONS PASSED")
# --- make the file OPEN CORRECTLY in the GUI. The viewport far-clip defaults to 1000 m; our
#     cloud base is 1400 m, so without this every cloud sits behind the far plane and is not drawn.
for _scr in bpy.data.screens:
    for _ar in _scr.areas:
        if _ar.type!='VIEW_3D': continue
        _sp=_ar.spaces[0]
        _sp.clip_start=0.10; _sp.clip_end=60000.0; _sp.lens=13.0
        _sp.shading.type='RENDERED'
        _sp.shading.use_scene_world_render=True; _sp.shading.use_scene_lights_render=True
        for _rg in _ar.regions:
            if _rg.type=='WINDOW' and _rg.data: _rg.data.view_perspective='CAMERA'
print("  viewport: clip 0.1-60000 m, RENDERED shading, opens in camera view")
print("=====================================================================\n")
bpy.ops.wm.save_as_mainfile(filepath=OUT)

# ---------------------------------------------------------------- the looks
LOOKS=(("c2_a_driver",  aim(  6.0,(SUN_AZIM+80.0)%360.0), 13.0, (-6.0,-14.0,1.30)),
       ("c2_b_intosun", aim( 14.0, SUN_AZIM),             13.0, (-6.0,-14.0,1.30)),
       ("c2_c_skyward", aim( 42.0,(SUN_AZIM+40.0)%360.0), 13.0, (-6.0,-14.0,1.30)),
       ("c2_d_wide",    aim(  9.0,(SUN_AZIM+110.0)%360.0),24.0, (-160.0,-330.0,55.0)))
for nm,fwd,lens,loc in LOOKS:
    cam.location=loc; cam.data.lens=lens
    cam.rotation_euler=fwd.to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=os.path.join(RND,nm)
    t0=time.time(); print("rendering",nm,flush=True)
    bpy.ops.render.render(write_still=True)
    print(f"   {nm} done in {time.time()-t0:.0f}s",flush=True)
print("DONE")
