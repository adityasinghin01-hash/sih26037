function A = tractorAsset(opts)
%TRACTORASSET  The Blender-authored open-ROPS farm tractor: 12 parts, ONE mesh, a
%   PART INDEX per face.
%
%   Built by blend/vehicles/tractor.py; loaded and part-indexed by sc.partAsset.
%
%   WHAT IT REPLACED: the primitive tractor is a chassis box, a cab box and a bonnet
%   box on four near-identical wheel boxes, all one flat colour - no wheel-size
%   contrast, no ROPS frame, no exhaust stack. Placed WITH "trolley" as a two-actor
%   pair (SPEC.md: the pair reads 5.60 m overall).

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("tractor", ["chassis" "rops_posts" "canopy" "seat" "tyres" "rims" ...
                             "mudguards" "grille" "lights" "exhaust" "trim" "plate"], ...
                 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
