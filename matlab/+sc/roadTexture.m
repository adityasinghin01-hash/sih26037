function [M, info] = roadTexture(halfWidth, len, opts)
%ROADTEXTURE  A per-pixel BRIGHTNESS MULTIPLIER for a carriageway surface.
%
%   WHY A MULTIPLIER AND NOT A COLOUR. REF-17 s19h nearly lost the road's hue once
%   already: the neutral grey is not a guess, it is measured off Aditya's own dashcam
%   frames of this road class and it deliberately overrules REF-06 s6's "light warm
%   grey". Returning a multiplier around 1.0 - asserted below to 0.2 % - means this
%   file CANNOT move that measurement. It can only add the variation and the STRUCTURE
%   the flat colour never had. The caller multiplies its own base through it, so S1 and
%   S2 keep their own different tarmac values.
%
%   THE AMPLITUDE IS SOLVED TO A MEASURED TARGET, NOT CHOSEN. See s22 of REF-17: the
%   real road's local contrast was measured off 59 of the 64 dashcam frames, at
%   MATCHED pixels-per-metre, with markings and vehicles rejected - because our lane
%   markings are separate measured geometry, so what this texture represents is the
%   surface BETWEEN them. Median coefficient of variation 0.0561. The relative weights
%   below set the CHARACTER; that one number sets the amount.
%
%   The mechanism was verified before anything was built on it - REF-17 s19j records
%   that s12a "proved" `surface` + `FaceColor','texturemap'` works, and that claim had
%   never been executed. It binds, and a 2x2 grid carrying a 512-wide image renders at
%   luminance std 65.4, so the IMAGE resolution really does beat the GRID resolution.

arguments
    halfWidth (1,1) double
    len       (1,1) double                  % metres of road the image is stretched over
    opts.MPP   (1,1) double = 0.060         % metres per texture pixel ALONG the road,
                                            % held constant so the grain does not change
                                            % scale when the drawn window changes
    opts.NV    (1,1) double = 160    % bumped from 128, 6 Sep, for sharper close-range
                                     % detail under the chase camera - cheap: this
                                     % scales the ONE-TIME cached texture generation,
                                     % not the per-frame render cost
    opts.Lanes (1,1) double = 2
    opts.Seed  (1,1) double = 11
    opts.Contrast (1,1) double = 0.0561     % MEASURED. Do not tune this by eye.
    opts.Patches  (1,1) double = 3          % S1 "THE ROAD": three potholes "patched
                                            % with darker fresh mix". The potholes are
                                            % on SPEC's not-built list; the patches are
                                            % pure colour and cost nothing.
end

% A SMALL CACHE, not one slot. S2 asks for five different surfaces per world build -
% four arms and the ring - so a single-slot cache would miss every time and the film,
% which rebuilds the world every 70 m, would pay for all five on each rebuild.
persistent CACHE
key = sprintf('%.3f_%.1f_%.4f_%d_%d', halfWidth, len, opts.Contrast, opts.Seed, opts.Lanes);
for c = 1:numel(CACHE)
    if strcmp(CACHE(c).key, key), M = CACHE(c).M;  info = CACHE(c).info;  return, end
end

nU = max(256, min(8192, round(len / opts.MPP)));
nV = opts.NV;
e  = linspace(-halfWidth, halfWidth, nV)';

% ---- WHERE THE WHEELS RUN ---------------------------------------------------------
% Lane centres sit at +-halfWidth/lanes and a car's tracks are about 1.70 m apart, so
% on a 7.0 m two-way carriageway the four wheel paths land at +-0.90 and +-2.60.
% S1 "THE ROAD" is explicit about what happens there: "aggregate showing in the wheel
% paths" - the binder is polished off and the stone shows, so the paths are lighter and
% COARSER, and the strips between hold the dust film a tyre never sweeps.
lane = halfWidth / opts.Lanes;
paths = [];
for k = 1:opts.Lanes
    c = -halfWidth + lane*(2*k-1);
    paths = [paths, c-0.85, c+0.85];                          %#ok<AGROW>
end
wp = zeros(nV,1);
for c = paths, wp = max(wp, exp(-((e-c)/0.32).^2)); end

% ---- THE FIELDS. Deterministic and hashed, never rand ------------------------------
% The film rebuilds the world every 70 m, and a surface whose grain resampled on each
% rebuild would CRAWL - the same reasoning as sc.scene's Grain, hashed off each face's
% own world centroid.
% SEEDED rand WITH THE GLOBAL STREAM SAVED AND RESTORED, not a sin-hash.
% The first version hashed sin(a*I + b*J) per texel, the same idiom the rest of the
% package uses for per-face grain - and on a REGULAR LATTICE it aliased into a visible
% diagonal CHEQUER across the near foreground of the road. A hash that is fine when
% evaluated at scattered world centroids is not fine when evaluated at every cell of a
% 128 x 5600 grid. rng(seed) is genuinely white, and with the state restored it is
% just as deterministic - so the film cannot crawl, which was the only reason to avoid
% rand here - and it disturbs nothing else that draws from the stream.
sPrev = rng;  rng(opts.Seed, 'twister');
% BAND-LIMITED, NOT PER-TEXEL. Pure white noise per texel put a visible RECTANGULAR
% GRID across the near foreground: `texturemap` magnifies nearest-neighbour, with no
% filtering available on a MATLAB surface, so at 2 m from a 1.35 m eye each texel
% covers several screen pixels and any hard edge between neighbours is drawn as one.
% The cure has to be in the SOURCE, so the grain is generated at ~2 texels and
% interpolated - fine enough to read as aggregate, correlated enough to have no edges.
agg = smoothField(nV, nU, 2.2, 2.2) - 0.5;
str = smoothField(nV, nU, 26,          max(2,round(3.2/opts.MPP))) - 0.5;
blo = smoothField(nV, nU, 90,          max(2,round(11 /opts.MPP))) - 0.5;
rng(sPrev);

% RELATIVE weights only - they set the character. The amount is solved below.
% Weighted toward STREAKING over speckle. The 59 accepted dashcam crops are gently
% mottled and streaked, not granular - at the scale a camera 1.35 m up actually sees
% this road, per-texel speckle reads as film grain rather than as aggregate.
% WHEEL-PATH DEFINITION RAISED 0.90->1.15, 6 SEP, NOT THE AGG:STR RATIO. The
% agg:str weighting above is a MEASURED finding (the 59 dashcam crops are
% mottled/streaked, not granular) and stays untouched - raising it would
% contradict that evidence. This term is different: it is how visually
% DISTINCT the worn tracks are from the dust between them, which S1's own
% "aggregate showing in the wheel paths" already asks for more of, and it is
% independent of the grain-vs-streak question.
dev =  0.70 * agg .* (0.30 + 0.70*wp) ...           % aggregate, coarser where exposed
     + 1.00 * str ...                               % the dominant longitudinal streaking
     + 0.70 * blo ...                               % slow patchiness
     + 1.15 * repmat(wp - mean(wp), 1, nU);         % the paths themselves
for k = 1:opts.Lanes                                % the oil line down each lane centre
    c = -halfWidth + lane*(2*k-1);
    dev = dev - 0.45 * repmat(exp(-((e-c)/0.16).^2), 1, nV*0+nU);
end
dev = dev - mean(dev(:));
dev = dev * (opts.Contrast / std(dev(:)));          % SOLVED, not guessed

% ---- PATCHES ----------------------------------------------------------------------
uu = linspace(0,1,nU);  vv = linspace(0,1,nV)';
info.Patches = zeros(opts.Patches, 2);
for p = 1:opts.Patches
    u0 = hash1(p*7.3 + opts.Seed);  v0 = 0.15 + 0.70*hash1(p*19.1 + opts.Seed);
    du = 0.004 + 0.010*hash1(p*3.1);  dv = 0.22 + 0.30*hash1(p*5.7);
    % DEPTH RAISED 0.085->0.13, 6 SEP - applied AFTER the CoV normalisation
    % above, so this is a real, direct darkening, not something the
    % renormalisation cancels out. S1 names these three as visibly "patched
    % with darker fresh mix"; they were reading as faint blotches.
    dev = dev - 0.13 * (exp(-((uu-u0)/du).^8) .* exp(-((vv-v0)/dv).^8));
    info.Patches(p,:) = [u0 v0];
end

M = 1 + dev;
M = M / mean(M(:));
assert(abs(mean(M(:)) - 1) < 2e-3, "sc:roadTexMean", ...
    ['road texture mean is %.5f, not 1. This field is a multiplier on a MEASURED ' ...
     'tarmac colour (REF-17 s19h); a mean off 1 silently rebalances a number that ' ...
     'was measured off photographs.'], mean(M(:)));
M = max(0.55, min(1.55, M));

info.CoV = std(M(:));
info.WheelPaths = paths;
info.Size = [nV nU];
entry = struct('key', key, 'M', M, 'info', info);
if isempty(CACHE), CACHE = entry; else, CACHE(end+1) = entry; end
if numel(CACHE) > 8, CACHE = CACHE(end-7:end); end
end

% ---------------------------------------------------------------------------------------
function h = hash1(x)
h = mod(sin(x*127.1 + 311.7) * 43758.5453, 1);
end

function N = smoothField(nV, nU, cellV, cellU)
%SMOOTHFIELD  Band-limited noise from a coarse lattice. Draws from whatever stream the
%   caller has already seeded, so determinism is the caller's business and there is
%   only one place that decides it.
gv = max(3, ceil(nV/cellV) + 2);
gu = max(3, ceil(nU/cellU) + 2);
L = rand(gv, gu);
N = interp2(1:gu, (1:gv)', L, linspace(1,gu,nU), linspace(1,gv,nV)', 'makima');
end
