function M = floorTexture(GX, GY, opts)
%FLOORTEXTURE  A per-vertex brightness multiplier for the forest floor, evaluated
%   directly in WORLD COORDINATES rather than through an image/UV mapping - the
%   third and hardest piece of Phase 5's ground half, after the shoulder and the
%   verge/island (both of which could just swap sc.scene/flat for sc.scene/carpet,
%   exactly as the road did).
%
%   WHY THIS ONE COULD NOT COPY THE ROAD'S TRICK. The floor is drawn by
%   sc.scene/ground as a RELIEF-SHADED `surf` - REF-04 s10's "dark, near-black humus
%   in hollows... light pebbly tan on ridges" needs the undulating relief and the
%   Hollow blend, neither of which a flat sc.scene/carpet band has. A flat textured
%   carpet laid over the relief at a fixed z would poke through the relief's high
%   points or float above its low ones - sc.scene/ground's OWN header already warns
%   about exactly this failure mode for grass over the road, one level up ("relief
%   of +-0.11 m ... makes the GRASS RENDER OVER THE ROAD in patches"). So this
%   multiplies the SAME surface's per-vertex colour instead of adding a second one.
%
%   VALUE NOISE, NOT A SIN-HASH PER QUERY POINT. sc.roadTexture / sc.groundTexture
%   both had to replace a `sin(a*I+b*J)` per-texel hash after it aliased into a
%   visible chequer on a REGULAR LATTICE (REF-17 s22d) - fine at scattered tree
%   centroids, not fine evaluated at every cell of a dense grid. The fix there was
%   `rng+rand` on a coarse lattice, interpolated. This needs the same property but
%   sampled at arbitrary WORLD (x,y), not image indices, so it hashes only the
%   integer LATTICE CORNERS (deterministic, no rand stream to save/restore) and
%   interpolates smoothly between the four nearest with a quintic ease - the query
%   density can be anything, coarse or fine, without ever rendering a raw hash
%   densely enough to alias.
%
%   THE SAME MEASURED TARGET AS THE SHOULDER AND VERGE - CoV 0.0861, off
%   matlab/ground_contrast_probe.m's 209 contamination-rejected dashcam crops. Leaf
%   litter and humus are the same class of "loose ground" that probe measured, not
%   a separate guess for a third material.

arguments
    GX (:,:) double
    GY (:,:) double
    opts.Contrast (1,1) double = 0.0861     % MEASURED - matlab/ground_contrast_probe.m
    opts.Seed     (1,1) double = 53         % distinct from sc.groundTexture's 31
end

fine   = worldNoise(GX, GY, 0.45, opts.Seed)   - 0.5;   % litter/duff grain
mid    = worldNoise(GX, GY, 2.2,  opts.Seed+1) - 0.5;   % twigs, small scrapes, clumps
patchy = worldNoise(GX, GY, 7.5,  opts.Seed+2) - 0.5;   % humus/ridge patchiness - the
                                                        % scale sc.scene/ground's own
                                                        % Hollow blend does NOT reach

dev = 0.45*fine + 0.85*mid + 1.00*patchy;
dev = dev - mean(dev(:));
sdev = std(dev(:));
if sdev > 1e-9
    dev = dev * (opts.Contrast / sdev);            % SOLVED, not guessed
end

M = 1 + dev;
mm = mean(M(:));
assert(abs(mm - 1) < 2e-3, "sc:floorTexMean", ...
    "floor texture mean is %.5f, not 1 - it would move FLOOR/HUMUS, not just add grain", mm);
M = max(0.55, min(1.55, M));
end

% ---------------------------------------------------------------------------------------
function v = worldNoise(x, y, cell, seed)
%WORLDNOISE  Deterministic band-limited value noise at world coordinates - hash the
%   lattice CORNERS only, then interpolate smoothly (quintic ease) between the four
%   nearest. See the file header: this is what avoids the sin-hash aliasing trap
%   while still being sample-able at any (x,y), not just image pixel indices.
gx = x/cell;  gy = y/cell;
x0 = floor(gx);  y0 = floor(gy);
tx = gx - x0;    ty = gy - y0;
sx = tx.^3 .* (tx.*(tx*6 - 15) + 10);      % quintic ease, zero 1st/2nd derivative at 0/1
sy = ty.^3 .* (ty.*(ty*6 - 15) + 10);
h00 = corner(x0,   y0,   seed);  h10 = corner(x0+1, y0,   seed);
h01 = corner(x0,   y0+1, seed);  h11 = corner(x0+1, y0+1, seed);
v = h00.*(1-sx).*(1-sy) + h10.*sx.*(1-sy) + h01.*(1-sx).*sy + h11.*sx.*sy;
end

function h = corner(ix, iy, seed)
h = mod(sin(ix*127.1 + iy*311.7 + seed*57.31) * 43758.5453, 1);
end
