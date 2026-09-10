function [spec, tags] = s5density()
%S5DENSITY  S5's density layer: the 24-macaque bridge troop plus the 9 more
%   at the temple (33 total - S5's own hero shot, "the frame Aditya named"),
%   the 19 people, and the goats/dogs/cattle. Part of the 5-scenario
%   density initiative (11 Sep 2026); zero planner risk. Same shape and the
%   same sc.activeDensityActorsAt(spec,P,t) consumer as the other three.
%
%   REAL VS CHOSEN: the counts, the composition (macaque troop: 5 adult
%   males, 10 adult females - 3 carrying infants, 9 juveniles, per S5's own
%   field-data ratio) and the general locations (on the bridge, at the
%   temple, roadworks, tea shop, byres) are S5's own words. Exact per-
%   individual offsets within each location are chosen, same discipline as
%   every other file this session. Clearance uses the SAME flat 1.875m
%   half-width sc.s5world.m's own header discloses for the whole route
%   (climb-width applied throughout, including the real 7.5m bridge) -
%   conservative on the bridge, not measured there separately.

ADULT = [0.50 0.50 1.65];
MACAQUE_A = [0.52 0.30 0.55];   % adult, on all fours
MACAQUE_J = [0.35 0.20 0.35];   % juvenile
GOAT = [0.90 0.35 0.65];
DOG  = [0.60 0.25 0.45];
COW  = [2.05 0.64 1.46];

HALF = 1.875;   % sc.s5world's own W.Width/2, applied for the whole route (disclosed there)

spec = cell(0,8);
% ---- THE MACAQUE TROOP, 24, on the bridge (real approach, station < 213.5) -----
% composition: 5 adult males + 10 adult females (3 w/ infants, carried - not modelled as
% a separate body) + 9 juveniles = 24. Spread across the bridge deck/parapet/footpath.
troopS = linspace(20, 190, 24);
for i = 1:24
    if i <= 15   % 5 males + 10 females as "adult"
        ext = MACAQUE_A;
    else
        ext = MACAQUE_J;
    end
    side = 2*mod(i,2) - 1;
    spec(end+1,:) = {0, troopS(i), side*(HALF+0.3+ext(2)/2), ext, 0, pi/2, [], []}; %#ok<AGROW>
end
% 9 more at the temple (climb end)
templeS = 213.5 + 965.7 - 5;
for i = 1:9
    side = 2*mod(i,2) - 1;
    ext = MACAQUE_A; if i > 5, ext = MACAQUE_J; end
    spec(end+1,:) = {0, templeS + 2*(i-5), side*(HALF+2.0+ext(2)/2), ext, 0, pi/2, [], []}; %#ok<AGROW>
end

% ---- GOATS, 4, on the cut face (climb, inside/cut side) ------------------
goatS = 213.5 + [150 350 550 750];
for i = 1:4
    spec(end+1,:) = {0, goatS(i), HALF+1.0+GOAT(2)/2, GOAT, 0, pi/2, [], []}; %#ok<AGROW>
end

% ---- DOGS, 2, at the roadworks (climb-relative 380-440, written 560-620) -
dogS = 213.5 + [395 410];
for i = 1:2
    spec(end+1,:) = {11, dogS(i), -(HALF+1.5+DOG(2)/2), DOG, 0, 0, [], []}; %#ok<AGROW>
end

% ---- CATTLE at two of the byres -------------------------------------------
cattleS = 213.5 + [100 800];
for i = 1:2
    spec(end+1,:) = {10, cattleS(i), HALF+1.2+COW(2)/2, COW, 0, pi/2, [], []}; %#ok<AGROW>
end

% ---- PEOPLE, 19 ------------------------------------------------------------
spec(end+1,:) = {8, 213.5+405, -(HALF+1.0+ADULT(2)/2), ADULT, 0, pi/2, [], []}; % roadworks
spec(end+1,:) = {8, 213.5+400, -(HALF+1.3+ADULT(2)/2), ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, 213.5+415, -(HALF+1.0+ADULT(2)/2), ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, 213.5+420, -(HALF+1.3+ADULT(2)/2), ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, 213.5+408, -(HALF+1.6+ADULT(2)/2), ADULT, 0, pi/2, [], []};   % 5 roadworks
spec(end+1,:) = {8, 213.5+388, HALF+0.6+ADULT(2)/2, ADULT, 0, pi/2, [], []};      % tea shop,
spec(end+1,:) = {8, 213.5+390, HALF+0.9+ADULT(2)/2, ADULT, 0, pi/2, [], []};      % 2nd bend
spec(end+1,:) = {8, 213.5+392, HALF+1.2+ADULT(2)/2, ADULT, 0, pi/2, [], []};      % 3 total
spec(end+1,:) = {8, 213.5+150, HALF+0.6+ADULT(2)/2, ADULT, 0, 0, [], []};         % fodder x2
spec(end+1,:) = {8, 213.5+600, HALF+0.6+ADULT(2)/2, ADULT, 0, 0, [], []};
spec(end+1,:) = {8, templeS,   -(HALF+0.6+ADULT(2)/2), ADULT, 0, pi/2, [], []};   % temple x4
spec(end+1,:) = {8, templeS+3, -(HALF+0.9+ADULT(2)/2), ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, templeS-3, -(HALF+0.6+ADULT(2)/2), ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, templeS-6, -(HALF+0.9+ADULT(2)/2), ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, 213.5+194, HALF+0.6+ADULT(2)/2, ADULT, 0, pi/2, [], []};      % 2 at shops
spec(end+1,:) = {8, 213.5+776, HALF+0.6+ADULT(2)/2, ADULT, 0, pi/2, [], []};
spec(end+1,:) = {8, 100, HALF+0.4+ADULT(2)/2, ADULT, 0, 0, [], []};              % bridge footpath
spec(end+1,:) = {8, 213.5+250, HALF+0.6+ADULT(2)/2, ADULT, 0, pi/2, [], []};      % grass cutting x2
spec(end+1,:) = {8, 213.5+700, HALF+0.6+ADULT(2)/2, ADULT, 0, pi/2, [], []};

tags = strings(size(spec,1),1);
for k = 1:size(spec,1), tags(k) = tagFor(spec{k,1}); end

nPedestrian = sum([spec{:,1}] == 8);
assert(nPedestrian == 19, "sc:s5densityPeople", ...
    "%d pedestrians built, S5's own spec states 19", nPedestrian);
assert(sum([spec{:,1}]==0) - 4 == 33, "sc:s5densityMacaques", ...
    "expected 33 macaques (24 bridge + 9 temple) plus 4 goats sharing ClassID 0 " + ...
    "(no monkey/goat class in S5's frozen enum) - got a different total, check the count");

nOnRoad = 0;  worst = "";
for k = 1:size(spec,1)
    ext = spec{k,4};
    nearEdge = abs(spec{k,3}) - ext(2)/2;
    if nearEdge < HALF + 0.10
        nOnRoad = nOnRoad + 1;
        worst = sprintf("row %d (%s) near edge %.2f m", k, tags(k), nearEdge);
    end
end
assert(nOnRoad == 0, "sc:s5densityOnRoad", "%d placements too close - worst: %s", nOnRoad, worst);
end

function s = tagFor(id)
switch id
    case 8, s = "person"; case 0, s = "small_animal"; case 11, s = "dog"; case 10, s = "cow";
    otherwise, s = "other";
end
end
