function A = motoAsset(opts)
%MOTOASSET  The Blender-authored ridden motorcycle: 11 parts, ONE mesh, a PART INDEX
%   per face.
%
%   Built by blend/vehicles/motorcycle.py; loaded and part-indexed by sc.partAsset.
%
%   WHAT IT REPLACED: the primitive motorcycle is a frame box, a handlebar box, a seat
%   box, two wheel boxes and a rider block, all one flat colour. This actor plays
%   THREE roles - S1's wrong-side rider, S1's overtaker, and S2's wrong-way rider - so
%   it is on screen for real time in both films, always ridden.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("moto", ["frame" "seat" "tyres" "rims" "forks" "handlebar" ...
                          "exhaust" "mudguards" "lights" "plate" "rider"], ...
                 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
