function A = treeAsset(opts)
%TREEASSET  The Blender-authored neem, branches and foliage in ONE shared frame.
%
%   TRAP this exists to prevent: loading the two parts and scaling each to the same
%   target height INDEPENDENTLY destroys their proportions - the foliage is naturally
%   taller than the woody structure (10.51 m against 9.35 m), so normalising both to
%   11 m shrinks the crown relative to the branches. They must share one scale factor,
%   derived from the height of the two together.
%
%   Returned unit-height, so the renderer scales each planted tree by its own h.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

[Vb, Fb] = rawAsset("neem_branches", opts.Dir);
[Vf, Ff] = rawAsset("neem_foliage",  opts.Dir);

H = max([Vb(:,3); Vf(:,3)]);                 % the whole tree, both parts together
assert(H > 1, "sc:treeAssetFlat", "the neem asset is only %.2f m tall", H);
A.Vb = Vb / H;  A.Fb = Fb;
A.Vf = Vf / H;  A.Ff = Ff;
A.Tris = size(Fb,1) + size(Ff,1);
A.CrownFrac = min(A.Vf(:,3));                % where the foliage starts, as a fraction
% THE CROWN'S RADIUS AS A FRACTION OF THE TREE'S HEIGHT, MEASURED OFF THE ASSET.
% Everything the renderers scale is scaled by HEIGHT, because the mesh is returned
% unit-height - so a caller that wants a crown RADIUS has to convert, and sc.s2render
% did not: it used the height scale directly as a lathe radius and drew understorey
% masses 3-4x wider than the crowns above them. One of them engulfed the approach
% camera and filled 55 % of the frame with black. Derived here, once, so no caller
% has to retype 0.418 and no caller can confuse the two quantities again.
% (REF-17 s17d wants exactly this number for the S1 LOD mismatch as well.)
A.CrownR = max(hypot(A.Vf(:,1), A.Vf(:,2)));
assert(A.CrownR > 0.05 && A.CrownR < 1.0, "sc:treeAssetCrownR", ...
    "crown radius fraction measured %.3f, which is not a plausible tree", A.CrownR);
end

function [V, F] = rawAsset(name, dir_)
f = fullfile(dir_, name + ".stl");
assert(isfile(f), "sc:noAsset", "missing asset %s", f);
TR = stlread(f);
V = TR.Points;  F = TR.ConnectivityList;
% base at z = 0 and the footprint centred, but the two parts must be shifted by the
% SAME amounts or they come apart - both were exported about the tree-base origin,
% so only the common floor is removed here and nothing is re-centred per part.
V(:,3) = V(:,3) - 0;
end
