function A = trolleyAsset(opts)
%TROLLEYASSET  The Blender-authored cane trolley: 8 parts, ONE mesh, a PART INDEX per
%   face.
%
%   Built by blend/vehicles/trolley.py; loaded and part-indexed by sc.partAsset.
%
%   WHAT IT REPLACED: the primitive trolley is a bed box, a load box and a hitch box
%   on two wheel boxes, all one flat colour - a smooth loaf shape with no overhang.
%   S1 names the overhang explicitly: "oncoming tractor-trolley with cane overhanging
%   its sides." Placed WITH "tractor" as a two-actor pair.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("trolley", ["bed" "rails" "load" "tyres" "rims" "mudguards" ...
                             "hitch" "trim"], 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
