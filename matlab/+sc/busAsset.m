function A = busAsset(opts)
%BUSASSET  The Blender-authored UPSRTC bus: 14 parts, ONE mesh, a PART INDEX per face.
%
%   Built by blend/vehicles/bus.py; loaded and part-indexed by sc.partAsset.
%
%   WHAT IT REPLACED, and why it was the worst actor in either scenario: the primitive
%   bus is eight cuboids - a body, a roof slab and six wheel stubs - drawn in ONE flat
%   colour. In the S2 chowk it is the largest object in frame after the island, and it
%   rendered as a solid yellow box on legs. Nothing on it read: no window band, no
%   two-tone, no wheels, no door.
%
%   NO MIRRORS. A real bus has large ones, but sc.meshes asserts 2.60 m over the body
%   (REF-04 s1) and mirrors would break it. Recorded rather than silently widened,
%   because S2's clearances are measured off that box.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("bus", ["shell" "skirt" "band" "glass" "tyres" "rims" "bumpers" ...
                         "grille" "lights" "tails" "plate" "dest" "door" "trim"], ...
                 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
