function [spec, tags] = s3density()
%S3DENSITY  S3's density layer: the 23 written people (16 placeable on the
%   ground plane - see below), the animals beyond the one already-built
%   squeeze dog, and the standing/moving vehicles S3-THE-GALLI.md names that
%   nothing in this repo builds yet. Part of the 5-scenario density
%   initiative (11 Sep 2026); zero planner risk - never feeds sc.planSeat.
%   Same shape and the same sc.activeDensityActorsAt(spec,P,t) consumer as
%   sc.s1density - see that file's header for the format.
%
%   WHAT THIS FILE DELIBERATELY DOES NOT DUPLICATE: the oncoming motorcycle
%   (150m), the crossing child (110m) and the dog asleep in the squeeze
%   (125m) already exist, real and tested, in demo_play.m's actorSpecS3 -
%   that is the live-planner story and this initiative does not touch it.
%   This file is the everything-else layer, same split as S1's
%   sc.s1density vs sc.s1actors.
%
%   REAL VS CHOSEN:
%   REAL, from S3-THE-GALLI.md:
%     - all people/animal/vehicle counts and their written locations
%       (hand pump at the squeeze, children at 270m, the man on the charpai
%       at 190m, the buffalo/cattle shed and the milking at 380m, the two
%       at the kirana shop at 400m, the cycle-rickshaw at 95m, the
%       transformer's own poles at 118m - built in sc.s3world, not here)
%     - stations > 300 m go through the SAME remap sc.s3world uses (real
%       382.2 m route vs the written 416 m), so a person at written "380m"
%       and the building next to them land at the same real station
%   CHOSEN, DISCLOSED:
%     - exact per-person offset within a named spot; the two sweeping
%       women's own stations (spec gives only "60m apart", not where)
%     - 7 of the 23 people are explicitly "glimpsed through open doorways
%       and on balconies - not on the street at all" (S3's own words) and
%       are NOT placed - a plan-view ground layer has no honest way to put
%       a person on a first-floor balcony. 16 are placed; 7 disclosed as
%       intentionally absent, not lost
%     - cat and cycle-rickshaw/handcart dimensions are unsourced estimates
%       (S5's frozen ClassID enum has no cat class either - mapped to 0,
%       unknown, same reasoning sc.s1density applies to goats)
%     - the hand pump (spec: "beside" the squeeze's scooter) is the one
%       density item placed inside 228-250m - OFF the drivable width, the
%       same way a building's footprint sits off it, checked below with
%       the squeeze's own real half-width. demo3Route.m's OWN "no pocket
%       fits" finding is about the PLANNER's candidate fan negotiating a
%       second TRACKED, avoidance-needing body there - this layer never
%       feeds sc.planSeat, so a wall-flush static person is a different
%       question and is not the thing that finding ruled out

remap = @(sw) sw + (sw>300).*(sw-300).*(0.70862 - 1);

ADULT = [0.50 0.50 1.65];  CHILD = [0.40 0.40 1.20];
GOAT  = [0.90 0.35 0.65];  KID   = [0.55 0.25 0.40];
DOG   = [0.60 0.25 0.45];  CAT   = [0.45 0.15 0.30];
RICKSHAW = [2.20 0.90 1.90];  HANDCART = [1.80 0.90 1.00];
[~, cowDim]  = sc.meshes("zebu");        % reused for the buffalo, disclosed in sc.s1density
[~, motoDim] = sc.meshes("motorcycle");
[~, autoDim] = sc.meshes("auto");
BICYCLE = [1.70 0.50 1.70];

spec = { ...
% ---- PEOPLE, 16 of 23 placeable (7 on balconies/through doorways, disclosed above) ---
8,  239, +1.55, ADULT, 0, pi/2, [], [] ; ...    % hand pump, at the squeeze - pumping
8,  241, +1.55, ADULT, 0, pi/2, [], [] ; ...    % hand pump - waiting with a vessel
8,  242, +1.55, ADULT, 0, pi/2, [], [] ; ...    % hand pump - waiting with a vessel
8,   80, +1.9,  ADULT, 0, pi/2, [], [] ; ...    % sweeping her doorstep (60m apart, chosen)
8,  140, -1.9,  ADULT, 0, pi/2, [], [] ; ...    % sweeping her doorstep
8,  269, +2.0,  CHILD, 0, pi/2, [], [] ; ...    % children playing, 270m, tight knot
8,  270, +2.2,  CHILD, 0, pi/2, [], [] ; ...
8,  270, +1.9,  CHILD, 0, pi/2, [], [] ; ...
8,  271, +2.1,  CHILD, 0, pi/2, [], [] ; ...
8,  190, -1.9,  ADULT, 0, pi/2, [], [] ; ...    % on the charpai with tea, 190m
8,  328.3,+2.3, ADULT, 1.2, 0,  [], [] ; ...    % 2 walking away (remap(340)) - Phase F:
8,  328.3,+2.6, ADULT, 1.2, 0,  [], [] ; ...    % given real motion. Lateral bumped to 2.3/
                                                 % 2.6 (was 1.9/2.2) because giving a row
                                                 % nonzero speed makes it skip the auto-
                                                 % lateral-correction below (real road
                                                 % users, not furniture) - these two now
                                                 % have to clear the band by their own
                                                 % authored number, same as the cyclist/
                                                 % auto-rickshaw already did
8,  112, -1.9,  ADULT, 0, pi/2, [], [] ; ...    % washing a motorcycle, 110m (offset off child@110)
8,  356.7,-2.3, ADULT, 0, pi/2, [], [] ; ...    % milking the buffalo, right 380m (remap(380))
8,  370.9,+2.3, ADULT, 0, pi/2, [], [] ; ...    % at the kirana shop, 400m (remap(400))
8,  370.9,+2.6, ADULT, 0, pi/2, [], [] ; ...    % at the kirana shop
% ---- ANIMALS beyond the already-built squeeze dog ----------------------
10, 356.7,-2.0,  cowDim, 0, pi/2, [], [] ; ...  % the buffalo, cattle shed, 380m (remap)
0,  175, +1.8, GOAT, 0, pi/2, [], [] ; ...      % goat tethered in the empty plot (150-205m)
0,  175, +2.0, KID,  0, pi/2, [], [] ; ...      % its kid
11, 371, +2.0, DOG, 0, pi/2, [], [] ; ...       % 2 at the kirana shop
11, 372, +2.3, DOG, 0, pi/2, [], [] ; ...
11, 268, -2.0, DOG, 0, 0,    [], [] ; ...       % following a child (near the 270m children)
0,  200, -1.7, CAT, 0, pi/2, [], [] ; ...       % 2 cats on a wall (150-205 band)
0,  202, -1.7, CAT, 0, pi/2, [], [] ; ...
10, 300, +1.9,  cowDim, 0, pi/2, [], [] ; ...   % cow standing in a doorway, 300m
% ---- STANDING VEHICLES --------------------------------------------------
5,   20, -1.9, motoDim, 0, pi/2, [], [] ; ...   % 7 motorcycles against walls
5,   45, +1.9, motoDim, 0, pi/2, [], [] ; ...
5,   70, -1.9, motoDim, 0, pi/2, [], [] ; ...
5,  160, +2.0, motoDim, 0, pi/2, [], [] ; ...
5,  260, -1.6, motoDim, 0, pi/2, [], [] ; ...
5,  328.3,-2.3, motoDim, 0, pi/2, [], [] ; ...  % (remap(340))
5,  356.7,+2.3, motoDim, 0, pi/2, [], [] ; ...  % (remap(380))
9,   85, +1.9, BICYCLE, 0, pi/2, [], [] ; ...   % 3 bicycles
9,  140, +1.9, BICYCLE, 0, pi/2, [], [] ; ...
9,  310, -2.4, BICYCLE, 0, pi/2, [], [] ; ...
12,  95, -1.9, RICKSHAW, 0, pi/2, [], [] ; ...  % cycle-rickshaw parked, 95m (real)
12, 335.7,-2.4, HANDCART, 0, pi/2, [], [] ; ...  % handcart on end (remap(350), chosen)
% ---- MOVING VEHICLES named in VEHICLES but not built ---------------------
9,   50, +1.6, BICYCLE, 2.5, 0, [], [] ; ...    % the cyclist
4,   10, -1.5, autoDim, 1.5, 0, [], [] ...      % the auto-rickshaw entering behind us
};

% LATERAL MAGNITUDE IS SOLVED, NOT HAND-PICKED - the same lesson sc.s1density's
% own junction-cluster bug already taught: eyeballing a handful of offsets
% against SEVEN different per-band clear widths (2.25 down to 0.975 m) got
% 23 of them wrong the first pass, caught by the assert below, not by eye.
% So every STATIC row's magnitude is now DERIVED from the real band half-width
% at its own station, keeping only the SIDE (the sign already authored above,
% which is the real "left or right" content) as chosen. Moving rows (the
% cyclist, the auto-rickshaw) keep their authored lateral - they are real road
% users passing through, not furniture sitting beside the road.
bandsS  = [0 90 150 205 232 246 300 416];
bandsHW = [2.25 1.80 1.60 1.20 0.975 1.50 1.90];
for k = 1:size(spec,1)
    if spec{k,5} ~= 0, continue; end
    sReal = spec{k,2};
    sw = sReal;  if sReal > 300, sw = 300 + (sReal-300)/0.70862; end
    bi = find(sw >= bandsS(1:end-1) & sw < bandsS(2:end), 1);
    if isempty(bi), bi = numel(bandsHW); end
    side = sign(spec{k,3});  if side == 0, side = 1; end
    ext = spec{k,4};
    spec{k,3} = side * (bandsHW(bi) + 0.15 + ext(2)/2);
end

tags = strings(size(spec,1),1);
for k = 1:size(spec,1)
    tags(k) = tagFor(spec{k,1});
end

nPedestrian = sum([spec{:,1}] == 8);
assert(nPedestrian == 16, "sc:s3densityPeople", ...
    "%d pedestrians built; S3 states 23, of which 7 are on balconies/through " + ...
    "doorways and disclosed as not placed (see header) - 16 is the expected ground count", ...
    nPedestrian);

% VERIFY THE SOLVE, do not just trust it - same discipline as everywhere else
% in this codebase: the arithmetic above is asserted, not merely executed.
nOnRoad = 0;  worst = "";
for k = 1:size(spec,1)
    if spec{k,5} ~= 0, continue; end
    sReal = spec{k,2};
    sw = sReal;  if sReal > 300, sw = 300 + (sReal-300)/0.70862; end
    bi = find(sw >= bandsS(1:end-1) & sw < bandsS(2:end), 1);
    if isempty(bi), bi = numel(bandsHW); end
    ext = spec{k,4};
    nearEdge = abs(spec{k,3}) - ext(2)/2;
    if nearEdge < bandsHW(bi) + 0.10 - 1e-9
        nOnRoad = nOnRoad + 1;
        worst = sprintf("row %d (%s) at s=%.1f lateral %.2f -> near edge %.2f, band needs %.2f", ...
            k, tags(k), sReal, spec{k,3}, nearEdge, bandsHW(bi)+0.10);
    end
end
assert(nOnRoad == 0, "sc:s3densityOnRoad", "%d placement problems - worst: %s", nOnRoad, worst);
end

function s = tagFor(id)
switch id
    case 8,  s = "person"; case 0,  s = "small_animal"; case 11, s = "dog"; case 10, s = "cow";
    case 5,  s = "moto";   case 9,  s = "bicycle"; case 12, s = "pushcart"; case 4, s = "auto";
    otherwise, s = "other";
end
end
