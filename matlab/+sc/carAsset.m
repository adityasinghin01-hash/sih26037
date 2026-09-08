function A = carAsset(opts)
%CARASSET  The Blender-authored hatchback: 11 parts, ONE mesh, a PART INDEX per face.
%
%   Built by blend/vehicles/car.py; loaded and part-indexed by sc.partAsset, which
%   carries the reasoning and the integrity assertions. This file exists to own ONE
%   thing: the part ORDER, which is the contract every per-face colour depends on.
%
%   What it replaced: sc.carColours used to recover the parts by GUESSING GEOMETRIC
%   REGIONS off the mesh - "glass is above z = 0.72 and inboard of |y| = 0.82", "a
%   tyre is below 0.62 within 0.42 m of an axle". Those bands were exactly right for
%   the eight-cuboid primitive they were written against, because there the regions
%   WERE the parts. On a lofted shell with wheel arches they are not: the glass band
%   also holds the door skin and the handles, the tyre band holds the arches and the
%   sills. The parts are separate files, so nothing has to be inferred, and a part
%   index cannot drift when the model changes shape.

arguments
    opts.Dir (1,1) string = fullfile(sc.refRoot(),"matlab","assets")
end

persistent CACHE CACHEDIR
if ~isempty(CACHE) && CACHEDIR == opts.Dir
    A = CACHE;  return
end

% THE ORDER IS THE CONTRACT. Do not reorder without regenerating every per-face colour.
A = sc.partAsset("car", ["shell" "glass" "tyres" "rims" "bumpers" "grille" ...
                         "lights" "tails" "mirrors" "plate" "trim"], 'Dir', opts.Dir);

CACHE = A;  CACHEDIR = opts.Dir;
end
