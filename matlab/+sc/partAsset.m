function A = partAsset(prefix, names, opts)
%PARTASSET  Load a Blender-authored vehicle: N parts, ONE mesh, a PART INDEX per face.
%
%   MATLAB's patch cannot take a texture, a UV or an alpha - not ever (REF-17 s12a).
%   So the only detail available is GEOMETRY plus ONE COLOUR PER FACE, and the way to
%   spend that is to build each actor as separate parts and colour each for what it is.
%   THE PART LIST IS THE TEXTURE. One STL per part, because STL carries no colour.
%
%   THE ORDER OF `names` IS THE CONTRACT. The face index of every triangle - and so the
%   colour written against it - depends on it. It is defined once per vehicle, in that
%   vehicle's own asset function, and never here.
%
%   Extracted from sc.carAsset when the bus arrived. Four more actors are still to be
%   rebuilt this way, which is four more chances to write this loop slightly
%   differently; sc.s1geom is the record of what two sources for one number costs.
%
%   Frame, as exported and asserted below: +x forward, +y left, +z up, origin on the
%   ground at the centre of the vehicle - the convention every mesh in sc.meshes uses,
%   so the renderer can place it at a pose with no offset.

arguments
    prefix (1,1) string
    names  (1,:) string
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

V = zeros(0,3);  F = zeros(0,3);  part = zeros(0,1);
for k = 1:numel(names)
    f = fullfile(opts.Dir, prefix + "_" + names(k) + ".stl");
    assert(isfile(f), "sc:noPart", ...
        ['missing part %s.\n' ...
         'The parts are built by blend/vehicles/%s.py - run it headless:\n' ...
         '  /Applications/Blender.app/Contents/MacOS/Blender --background --python ' ...
         'blend/vehicles/%s.py'], f, prefix, prefix);
    TR = stlread(f);
    Vk = TR.Points;  Fk = TR.ConnectivityList;
    assert(size(Fk,2) == 3, "sc:partFaces", "%s_%s is not triangulated", prefix, names(k));
    assert(~isempty(Fk),   "sc:partEmpty",  "%s_%s has no faces", prefix, names(k));
    F    = [F; Fk + size(V,1)];                 %#ok<AGROW>  reindex onto the running V
    V    = [V; Vk];                             %#ok<AGROW>
    part = [part; repmat(k, size(Fk,1), 1)];    %#ok<AGROW>
end

A.V = V;  A.F = F;  A.Part = part;  A.Names = names;  A.Prefix = prefix;
A.Tris = size(F,1);
for k = 1:numel(names), A.Id.(names(k)) = k; end
A.Dim = [max(V(:,1))-min(V(:,1)), max(V(:,2))-min(V(:,2)), max(V(:,3))-min(V(:,3))];

% ---- WHAT THIS ASSERTS, AND WHAT IT DELIBERATELY DOES NOT -----------------------
% The SPECIFICATION dimensions are asserted in sc.meshes, which is where every actor
% answers for its size and where the S1 and S2 arithmetic read them. Repeating them
% here would be two sources for one number. What is asserted here is the asset's own
% INTEGRITY - that the parts loaded, that every face has a part, and that the mesh
% arrives in the frame the renderer assumes.
assert(numel(part) == size(F,1), "sc:partIndex", ...
    "part index has %d entries for %d faces", numel(part), size(F,1));
assert(all(isfinite(V(:)),'all'), "sc:partNaN", "%s contains NaN or Inf", prefix);
assert(abs(min(V(:,3))) <= 0.005, "sc:partGround", ...
    "%s does not sit on the ground: zmin = %+.4f m", prefix, min(V(:,3)));

% CENTRED, NOT RE-CENTRED. sc.asset silently shifts a mesh onto its own centre, which
% is right for a tree that gets planted anywhere. A vehicle is placed at a POSE, so a
% silent shift would move it off its own logged position and the frame would still
% look fine. An asymmetric export must therefore fail here instead.
ax = ["x" "y"];
for k = [1 2]
    off = (max(V(:,k)) + min(V(:,k))) / 2;
    assert(abs(off) <= 0.005, "sc:partOffCentre", ...
        ['%s is not centred on %s: centre is %+.4f m. The renderer places this mesh ' ...
         'at the actor pose with no offset, so an off-centre export moves the whole ' ...
         'vehicle off its own logged position.'], prefix, ax(k), off);
end
end
