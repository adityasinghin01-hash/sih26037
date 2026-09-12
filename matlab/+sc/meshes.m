function [m, dim] = meshes(what)
%MESHES  Actor meshes as extendedObjectMesh, built to REAL dimensions and ASSERTED.
%
%   These are not decoration. An actor's Mesh is what the lidar and radar generators
%   see and what the renderer draws, so the silhouette must be right even though the
%   surface detail need not be. Every dimension traces to REF-04 or a scenario script.
%
%   "less, but properly built": a zebu is a barrel, a hump, a dewlap, a neck, a head,
%   four legs and a tail. That reads as a cow from any angle a camera will take.
%
%   EVERY MESH ASSERTS ITS OWN BOUNDING BOX before returning. The first version of this
%   file was measured and was wrong on six of eight meshes - the zebu came out 0.72 m
%   wide against a 0.85 m specification and 1.71 m tall against 1.43 m, because horns
%   and a hump were added without re-measuring. Hence the assertion.
%
%   Frame: +x FORWARD, +y LEFT, +z UP, origin at the GROUND CONTACT POINT, which is
%   the convention drivingScenario actors use.
%
%   [m, dim] = sc.meshes("zebu")   ->  dim is the asserted [L W H] in metres.

arguments
    what (1,1) string
end

TOL = 0.005;        % 5 mm - tighter than any camera or sensor can resolve here

switch what
% =====================================================================================
case "zebu"
    % Bos indicus. REBUILT 4 Sep - THE FIRST VERSION WAS 2.20 x 0.85 x 1.43 AND THE
    % WIDTH WAS OUT OF SPECIFICATION, which mattered because THE COW'S WIDTH IS THE
    % GAP ARITHMETIC. REF-04 s2 gives body width **57-71 cm**; 85 cm is 140 mm above
    % the top of that range, and SPEC.md cited REF-04 for it. The assertion below
    % passed the whole time because it was checking the mesh against the wrong number.
    %
    % These are S1-CATTLE-CROSSING.md's own figures - "body 205 cm long, 64 cm wide,
    % withers 128 cm, height with hump 146 cm" - and every one sits inside REF-04's
    % range. With a 0.64 m cow the WRITTEN gap arithmetic closes to 30 mm; with the
    % 0.85 m one it could not (see s10 of REF-17).
    %
    % NOTE, and it is S1's own inconsistency, not ours: 128 withers + "hump 15 cm"
    % is 143, but S1 also states "height with hump 146 cm". 146 is taken, making the
    % hump 18 cm - still inside REF-04's 10-20 cm - because the overall silhouette is
    % what the sight model and the render depend on, and the taller reading is the
    % conservative one for occlusion.
    dim = [2.05 0.64 1.46];
    % A BLENDER-AUTHORED ZEBU IF ONE IS PRESENT, the primitive otherwise. The asset is
    % a CC-BY base cow (see assets/ATTRIBUTION.md - it must be credited) with the hump
    % and dewlap added, because REF-04 s2 is blunt: "Not a Holstein - the hump and the
    % dewlap are the silhouette." It is scaled to the same asserted box, so every
    % assertion below still gates it and the S1 gap arithmetic cannot move.
    af = fullfile(sc.refRoot(),"matlab","assets","zebu.stl");
    if isfile(af)
        TR = stlread(af);
        m = extendedObjectMesh(TR.Points, TR.ConnectivityList);
        break_out = true;
    else
        break_out = false;
    end
    if ~break_out
    WITHERS = 1.28;  BARREL_H = 0.62;  B = WITHERS - BARREL_H;   % belly underside 0.66
    m =        box([ 0.00  0.00  B+BARREL_H/2], [1.34 0.64 BARREL_H]);   % barrel -> width 0.64
    m = join(m, box([ 0.24  0.00  1.46-0.09   ], [0.56 0.40 0.18]));     % HUMP -> exactly 1.46
    m = join(m, box([ 0.70  0.00  B+0.48      ], [0.38 0.30 0.40]));     % neck
    m = join(m, box([ 0.82  0.00  B+0.54      ], [0.42 0.24 0.26]));     % head -> nose +1.03
    m = join(m, box([ 0.88  0.00  B+0.42      ], [0.26 0.16 0.15]));     % muzzle, inside the head
    m = join(m, box([ 0.76  0.00  B+0.16      ], [0.28 0.14 0.30]));     % dewlap - 2nd tell
    for hy = [-0.10 0.10]                                                % horns, kept low
        m = join(m, box([0.84 hy B+0.66], [0.08 0.08 0.13]));   % top 1.385, under the hump
    end
    for lx = [0.46 -0.48]                                                % four legs
        for ly = [0.20 -0.20]
            m = join(m, box([lx ly B/2], [0.14 0.14 B]));       % width extent 0.27 < 0.32
        end
    end
    m = join(m, box([-0.945 0.00  B+0.32], [0.15 0.08 0.42]));           % tail -> tail -1.02
    end

% =====================================================================================
case "car"
    % Indian hatchback. Body 1.70 wide; MIRRORS TAKE IT TO 1.90, and that 200 mm is a
    % planner action (D8: folding the mirrors narrows the footprint). Both asserted.
    %
    % THE BLENDER-AUTHORED CAR, replacing the eight cuboids that were here. The ego is
    % the hero of every frame in both scenarios and it was a stack of boxes: no wheel
    % arches, so only the bottom 0.22 m of a 0.62 m wheel showed and it read as a
    % hovercraft; no rounded section, so it read as a crate. 11 separately-coloured
    % parts and 2,884 triangles, and the part list is the only texture MATLAB allows.
    % Built by blend/vehicles/car.py; loaded and part-indexed by sc.carAsset.
    %
    % There is no primitive fallback and that is deliberate: a fallback that fires
    % when the assets are missing renders a box car into a demo and says nothing.
    % sc.treeAsset already hard-requires its STLs, so the repo cannot run without
    % matlab/assets/ in any case.
    dim = [3.99 1.90 1.50];
    A = sc.carAsset();
    m = extendedObjectMesh(A.V, A.F);
    carPart = A.Part;  carId = A.Id;

% =====================================================================================
case "auto"
    % Bajaj RE three-wheeler: one front wheel, two rear. The S1 abort agent and one of
    % S2's three circulating vehicles.
    %
    % THE BLENDER-AUTHORED AUTO, replacing the four-box primitive that was here: a
    % lower body, a canopy slab, a front cowl and three wheel boxes, all one flat
    % colour - no open cabin, no single centred front wheel, no mudguards. 13
    % separately-coloured parts and 1,772 triangles; the open-sided cabin with a
    % visible bench seat is the single biggest tell an auto has and the primitive had
    % none of it. Built by blend/vehicles/auto.py; loaded by sc.autoAsset.
    dim = [2.63 1.30 1.70];
    A = sc.autoAsset();
    m = extendedObjectMesh(A.V, A.F);

% =====================================================================================
case "motorcycle"
    % Ridden in every appearance: the S1 wrong-side agent, the S1 overtaker, and S2's
    % wrong-way-round-the-island rider.
    %
    % THE BLENDER-AUTHORED MOTORCYCLE, replacing the four-box primitive that was here:
    % a frame box, a handlebar box, a seat box, two wheel boxes and a rider block, all
    % one flat colour. 11 separately-coloured parts and 1,028 triangles - both wheels
    % single and centred, an exhaust, mirrors, and a rider built to the same standard
    % as the rest of the kit rather than tacked on. Built by blend/vehicles/
    % motorcycle.py; loaded by sc.motoAsset.
    dim = [1.90 0.70 1.30];
    A = sc.motoAsset();
    m = extendedObjectMesh(A.V, A.F);

% =====================================================================================
case "tractor"
    % Placed WITH "trolley" as two actors. Written S1: the pair reads 5.60 m overall.
    %
    % THE BLENDER-AUTHORED TRACTOR, replacing the three-box primitive that was here:
    % a chassis, a cab and a bonnet, all one flat colour, on four equal-ish wheel
    % boxes. 12 separately-coloured parts and 1,552 triangles - the big-rear/
    % small-front wheel contrast, the open ROPS frame rather than a glazed cab (rural
    % Indian tractors overwhelmingly have neither doors nor glass), and the vertical
    % exhaust stack on the hood, which is the single fastest "tractor" read there is.
    % Built by blend/vehicles/tractor.py; loaded by sc.tractorAsset.
    dim = [3.40 1.90 2.60];
    A = sc.tractorAsset();
    m = extendedObjectMesh(A.V, A.F);

case "trolley"
    % Placed WITH "tractor" as two actors.
    %
    % THE BLENDER-AUTHORED TROLLEY, replacing the three-box primitive that was here: a
    % bed, a smooth cane-load loaf and a hitch on two wheel boxes, all one flat colour
    % - no overhang, though S1 names it by name: "cane overhanging its sides." 8
    % separately-coloured parts and 1,064 triangles; the crosswise cane lengths that
    % poke past the side rails are the one detail the primitive owed the script and
    % never paid. Built by blend/vehicles/trolley.py; loaded by sc.trolleyAsset.
    dim = [3.20 2.00 1.70];
    A = sc.trolleyAsset();
    m = extendedObjectMesh(A.V, A.F);

% =====================================================================================
case "bus"
    % UPSRTC mofussil bus. REF-04 s1: ~11 m long, 2.6 m wide, 3.2 m tall.
    %
    % THE BLENDER-AUTHORED BUS, replacing the eight cuboids that were here - a body,
    % a roof slab and six wheel stubs, drawn in one flat colour. In the S2 chowk this
    % is the largest object in frame after the island and it rendered as a solid
    % yellow box on legs. 14 parts and 3,324 triangles; the window band, the two-tone
    % skirt and waist rail, the wheels, the entrance and the destination board are
    % all GEOMETRY, because the part list is the only texture MATLAB allows.
    %
    % NO MIRRORS: a real bus has large ones, but the asserted 2.60 m is over the body
    % and mirrors would break it. Said out loud rather than silently widened, because
    % S2's clearances are measured off this box.
    dim = [10.80 2.60 3.10];
    A = sc.busAsset();
    m = extendedObjectMesh(A.V, A.F);

case "tataace"
    % The parked mini-truck that narrows the S2 exit, "loading, tailgate down".
    %
    % THE BLENDER-AUTHORED TATA ACE, replacing the four-box primitive that was here:
    % a chassis/deck, a cab and a load box, all one flat colour, tailgate permanently
    % shut because there was no tailgate at all. 12 separately-coloured parts and
    % 1,492 triangles - the dropped tailgate is a SILHOUETTE change, not a colour, and
    % it is the one state S2 names by name. Built by blend/vehicles/tataace.py;
    % loaded by sc.aceAsset.
    dim = [3.80 1.50 1.85];
    A = sc.aceAsset();
    m = extendedObjectMesh(A.V, A.F);

otherwise
    error("sc:noSuchMesh", "no mesh named '%s'", what);
end

% ---- ASSERT. Fails loudly, names the mesh, and reports the miss in millimetres. ----
v = m.Vertices;
got = [max(v(:,1))-min(v(:,1)), max(v(:,2))-min(v(:,2)), max(v(:,3))-min(v(:,3))];
ax = ["length" "width" "height"];
for k = 1:3
    assert(abs(got(k)-dim(k)) <= TOL, "sc:meshDim", ...
        "%s %s is %.3f m, specification says %.3f m (out by %+.0f mm)", ...
        what, ax(k), got(k), dim(k), 1000*(got(k)-dim(k)));
end
assert(abs(min(v(:,3))) <= TOL, "sc:meshGround", ...
    "%s does not sit on the ground: zmin = %+.3f m", what, min(v(:,3)));

% ---- THE ZEBU IS CHECKED AGAINST REF-04's RANGES, NOT JUST ITS OWN TARGET. ----
% The 0.85 m width passed a dimension assertion for a whole phase because the assertion
% only ever compared the mesh to `dim`, and `dim` was the thing that was wrong. A mesh
% has to answer to the reference document as well as to itself.
if what == "zebu"
    RANGE = struct('length',[1.80 2.26], 'width',[0.57 0.71], 'height',[1.24 1.58]);
    fn = ["length" "width" "height"];
    for k = 1:3
        r = RANGE.(fn(k));
        assert(dim(k) >= r(1) && dim(k) <= r(2), "sc:meshRange", ...
            "zebu %s is %.3f m, outside REF-04 s2's documented %.2f-%.2f m", ...
            fn(k), dim(k), r(1), r(2));
    end
end

% THE CAR CARRIES A SECOND, LOAD-BEARING NUMBER: THE BODY WITHOUT MIRRORS.
% This used to select "not a mirror" as a Z-BAND - everything outside 1.02 +- 0.09 m -
% which was true of the primitive only because the primitive's mirrors were the sole
% geometry at that height. On the authored car the same band cuts through the door
% handles, the glass and the top of the cabin, so it would have measured the width of
% an arbitrary horizontal slice and called it the body. The mirrors are a PART, so
% they are excluded as one; nothing is inferred from where they happen to sit.
if what == "car"
    isMirror = carPart == carId.mirrors;
    fBody = m.Faces(~isMirror, :);
    body  = v(unique(fBody(:)), :);
    bw = max(body(:,2)) - min(body(:,2));
    assert(abs(bw-1.70) <= TOL, "sc:meshDim", ...
        ['car body width is %.3f m, specification says 1.700 m (mirrors add 200 mm ' ...
         'and folding them is a planner action worth exactly that). Out by %+.0f mm.'], ...
        bw, 1000*(bw-1.70));
    % and the mirrors must actually BE the 1.90, or the two numbers are unrelated
    fMirr = m.Faces(isMirror, :);
    mw = max(v(unique(fMirr(:)), 2)) - min(v(unique(fMirr(:)), 2));
    assert(abs(mw-1.90) <= TOL, "sc:meshDim", ...
        "car mirrors span %.3f m, but the asserted overall width is 1.900 m", mw);
end
end

% ---------------------------------------------------------------------------------------
function m = box(c, s)
%BOX  A cuboid of size s = [L W H] centred at c = [x y z].
m = translate(scale(extendedObjectMesh('cuboid'), s), c);
end
