function A = aceAsset(opts)
%ACEASSET  The Blender-authored Tata Ace: 12 parts, ONE mesh, a PART INDEX per face.
%
%   Built by blend/vehicles/tataace.py; loaded and part-indexed by sc.partAsset.
%
%   WHAT IT REPLACED: the primitive is a chassis box, a cab box and a load box on
%   four wheel boxes, all one flat colour, tailgate permanently shut because there is
%   no tailgate at all. S2 names this actor's state explicitly - "loading, tailgate
%   down" - and the parked Ace's job is to narrow the exit lane, so its footprint is
%   what S2's clearance arithmetic is measured against.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("ace", ["cab" "glass" "mirrors" "bed" "rails" "tailgate" "tyres" ...
                         "rims" "mudguards" "grille" "lights" "plate"], 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
