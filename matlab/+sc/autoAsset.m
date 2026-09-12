function A = autoAsset(opts)
%AUTOASSET  The Blender-authored Bajaj RE auto-rickshaw: 13 parts, ONE mesh, a PART
%   INDEX per face.
%
%   Built by blend/vehicles/auto.py; loaded and part-indexed by sc.partAsset.
%
%   WHAT IT REPLACED: the primitive auto is a lower box, a canopy box, a front cowl
%   box and three wheel boxes, all one flat colour - no open cabin, no single centred
%   front wheel, no mudguards, nothing that says "three-wheeler" rather than "van".
%   It is the S1 abort agent and one of S2's three circulating vehicles, so it is on
%   screen for a meaningful fraction of both films.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("auto", ["chassis" "canopy" "pillars" "glass" "seats" "tyres" ...
                          "rims" "mudguards" "grille" "lights" "tails" "plate" ...
                          "trim"], 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
