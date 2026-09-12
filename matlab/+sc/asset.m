function [V, F, dim] = asset(name, opts)
%ASSET  Load a Blender-authored mesh from matlab/assets/<name>.stl.
%
%   REF-17 s2 recorded that this path works - stlwrite -> stlread ->
%   extendedObjectMesh round-trips, 178 faces in, 178 out - and then declined to use
%   it, because DOWNLOADED models carry licence conditions this project cannot verify.
%   That objection does not apply to assets we author ourselves, which is what these
%   are: built in Blender to REF-06's numbers and exported.
%
%   The mesh is normalised on load: base at z = 0, and the TRUNK centred on x = y = 0,
%   so a tree can be planted at a station like any primitive. Optionally scaled to a
%   target height, which is how one authored tree becomes a stand of varied ones.

arguments
    name (1,1) string
    opts.Height (1,1) double = NaN      % scale uniformly to this overall height
    opts.Dir    (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

f = fullfile(opts.Dir, name + ".stl");
assert(isfile(f), "sc:noAsset", "missing asset %s", f);
TR = stlread(f);
V = TR.Points;  F = TR.ConnectivityList;
assert(size(F,2)==3, "sc:assetFaces", "%s is not triangulated", name);

V(:,3) = V(:,3) - min(V(:,3));                       % base on the ground
lo = min(V(:,1:2));  hi = max(V(:,1:2));
V(:,1:2) = V(:,1:2) - (lo+hi)/2;                     % centre the footprint

if ~isnan(opts.Height)
    h = max(V(:,3));
    assert(h > 1e-6, "sc:assetFlat", "%s has no height", name);
    V = V * (opts.Height / h);
end
dim = [max(V(:,1))-min(V(:,1)), max(V(:,2))-min(V(:,2)), max(V(:,3))-min(V(:,3))];
end
