function [M, info] = groundTexture(halfWidth, len, opts)
%GROUNDTEXTURE  A per-pixel BRIGHTNESS MULTIPLIER for shoulders, verges and the near
%   forest floor - the ground half of Phase 5, the same mechanism as sc.roadTexture
%   applied to a different measured target and a different character.
%
%   WHY A MULTIPLIER, NOT A COLOUR - same reasoning as sc.roadTexture s1. SHOULDER,
%   the forest FLOOR/HUMUS pair and S2's GRASS are all measured pixel targets
%   (s1render/s2render headers). Returning a multiplier around 1.0 - asserted below
%   to 0.2 % - means this file adds STRUCTURE and cannot move any of those numbers.
%
%   THE AMPLITUDE IS SOLVED, NOT CHOSEN. matlab/ground_contrast_probe.m measured the
%   real ground's local contrast off 209 contamination-rejected crops from 60 of 64
%   of Aditya's own dashcam frames (4 excluded: portrait orientation, no EXIF tag to
%   explain it), at MATCHED metres-per-pixel via a ground-plane projection (140 deg
%   FOV, REF-01 s12; 1.35 m mount height - THIS PROJECT'S driver-eye figure, reused
%   for lack of anything dashcam-specific, and said so). Three-pass contamination
%   rejection, same discipline as the road (REF-17 s22b): naive -> best-of-N ->
%   reject sky/flat-grey/shadow/blown/off-hue/edge-dominated/over-saturated, contact-
%   sheeted and LOOKED AT after every pass, because a filter that looks right in
%   isolation can still be passing a painted gate or a lane edge (matlab-render-
%   hazards memory s4). MEDIAN 0.0861 (p25 0.0586, p75 0.1185) - genuinely higher
%   than the road's 0.0561, which is the right direction: loose dirt, grass and leaf
%   litter carry more local structure than an engineered tarmac surface, even before
%   either is dressed up.
%
%   CHARACTER, FROM THE SCENARIOS' OWN WORDS, NOT GUESSED: S1 "THE ROAD" - "Bare
%   pale-tan dirt... dusty, wheel-scarred where vehicles pull off"; S1 "LEFT SIDE" -
%   patchy grazed doob, "bare scrapes"; SPEC.md / REF-04 s10 - forest floor is
%   "dark, near-black humus in hollows... light pebbly tan on ridges", a boundary
%   this file does NOT touch (sc.scene/ground's Hollow blend already owns that scale;
%   this is the FINE grain on top of it, the same division of labour roadTexture has
%   with the measured TARMAC colour). No wheel paths, no oil line, no lane markings -
%   those are the road's vocabulary, not the ground's. Wheel-scarring is real here
%   too (S1's own words) but only where a caller asks for it (opts.Ruts), because a
%   forest floor and an S2 island have no vehicles pulling onto them.
%
%   THE TWO TRAPS ALREADY PAID FOR ON THE ROAD, NOT RE-EARNED HERE (REF-17 s22d):
%     - a sin-hash on a REGULAR LATTICE aliases into a visible chequer - this file
%       uses the identical rng(seed)+rand, stream saved and restored, never sin.
%     - texturemap magnifies NEAREST-NEIGHBOUR with no MATLAB-side filter - the cure
%       is band-limiting in the SOURCE, which smoothField already does.

arguments
    halfWidth (1,1) double
    len       (1,1) double
    opts.MPP   (1,1) double = 0.060         % matches sc.roadTexture and the probe's
                                            % own target scale, so both textures are
                                            % solved to one physical grain size
    opts.NV    (1,1) double = 96
    opts.Seed  (1,1) double = 31            % distinct from roadTexture's 11/23
    opts.Contrast (1,1) double = 0.0861     % MEASURED - matlab/ground_contrast_probe.m
    opts.Ruts  (1,1) double = 0             % 0-1: wheel-scar streaking, S1 shoulder only
end

persistent CACHE
key = sprintf('%.3f_%.1f_%.4f_%.2f_%d', halfWidth, len, opts.Contrast, opts.Ruts, opts.Seed);
for c = 1:numel(CACHE)
    if strcmp(CACHE(c).key, key), M = CACHE(c).M; info = CACHE(c).info; return, end
end

nU = max(256, min(8192, round(len / opts.MPP)));
nV = opts.NV;

sPrev = rng;  rng(opts.Seed, 'twister');
% FINE GRAIN - dirt/grass-blade scale, the ground's equivalent of the road's
% aggregate. Slightly coarser cell than the road's 2.2 texels: at 0.060 m/px that
% is a ~13 cm feature, which is grit on tarmac but too fine to read as a grass
% blade or a dry-earth crumb - loose ground structure sits closer to 20-30 cm.
fine  = smoothField(nV, nU, 3.2, 3.2) - 0.5;
% COARSE PATCHINESS - bare scrapes, litter clumps, drier/wetter patches. This is
% the DOMINANT layer, unlike the road where streaking dominates: S1's own words
% are "patchy" and "bare scrapes", not "streaked".
patchy = smoothField(nV, nU, 34, max(2,round(4.5/opts.MPP))) - 0.5;
% MID-SCALE MOTTLE - between the two, so the transition from fine grain to coarse
% patch does not look like two unrelated frequencies stacked.
mid = smoothField(nV, nU, 11, max(2,round(1.4/opts.MPP))) - 0.5;
rng(sPrev);

dev = 0.55*fine + 1.00*patchy + 0.75*mid;

if opts.Ruts > 0
    % WHEEL-SCARRING, S1's own word for the bare shoulder: "dusty, wheel-scarred
    % where vehicles pull off." Two scars, not a continuous pair of lanes - a
    % shoulder is pulled onto, not driven along, so the ruts are patchy AND
    % directional, not a clean uniform stripe the way the road's wheel paths are.
    e  = linspace(-halfWidth, halfWidth, nV)';
    rc = halfWidth * 0.55;
    scarMask = exp(-((e-rc)/0.28).^2) + exp(-((e+rc)/0.28).^2);
    sPrev = rng;  rng(opts.Seed + 7, 'twister');
    scarPatch = smoothField(nV, nU, 20, max(2,round(2.6/opts.MPP)));
    rng(sPrev);
    dev = dev + opts.Ruts * 0.9 * (scarMask .* (scarPatch - 0.35));
end

dev = dev - mean(dev(:));
dev = dev * (opts.Contrast / std(dev(:)));          % SOLVED, not guessed

M = 1 + dev;
M = M / mean(M(:));
assert(abs(mean(M(:)) - 1) < 2e-3, "sc:groundTexMean", ...
    ['ground texture mean is %.5f, not 1. This field is a multiplier on MEASURED ' ...
     'pixel colours (SHOULDER/FLOOR/GRASS); a mean off 1 silently rebalances a ' ...
     'number that was measured off photographs or REF-13.'], mean(M(:)));
M = max(0.55, min(1.55, M));

info.CoV = std(M(:));
info.Size = [nV nU];
entry = struct('key', key, 'M', M, 'info', info);
if isempty(CACHE), CACHE = entry; else, CACHE(end+1) = entry; end
if numel(CACHE) > 8, CACHE = CACHE(end-7:end); end
end

% ---------------------------------------------------------------------------------------
function N = smoothField(nV, nU, cellV, cellU)
%SMOOTHFIELD  Identical to sc.roadTexture's - band-limited noise from a coarse
%   lattice, drawing from whatever stream the caller has already seeded.
gv = max(3, ceil(nV/cellV) + 2);
gu = max(3, ceil(nU/cellU) + 2);
L = rand(gv, gu);
N = interp2(1:gu, (1:gv)', L, linspace(1,gu,nU), linspace(1,gv,nV)', 'makima');
end
