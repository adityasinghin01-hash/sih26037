function [spec, tags] = s4density()
%S4DENSITY  S4's density layer: the 44 people and the real vehicles/animals
%   S4-THE-HIGHWAY.md names. Part of the 5-scenario density initiative
%   (11 Sep 2026); zero planner risk - never feeds sc.planSeat. Same shape
%   and the same sc.activeDensityActorsAt(spec,P,t) consumer as
%   sc.s1density/sc.s3density.
%
%   REAL VS CHOSEN:
%   REAL: the 8 people-cluster counts and their own composition (9+6+5+4+
%   7+5+3+5 = 44, matching S4's own PEOPLE total exactly), and the standing/
%   moving vehicle roll call.
%   A REAL DISCREPANCY IN THE SPEC, DISCLOSED RATHER THAN FORCED QUIET:
%   S4-THE-HIGHWAY.md's own VEHICLES section header says "63", but its own
%   itemised list (9 trucks+2 tankers+4 cars+6 motorcycles+2 autos+1
%   tractor-trolley+1 broken-down truck standing, plus 2 merging+3 lane-
%   ending+1 U-turning truck+4 overtaking cars+6 motorcycles+1 bus+2
%   overloaded trucks+1 tractor-trolley moving) sums to 45, not 63. Built to
%   the 45 that is actually itemised - the same call this project's own
%   S0 s4 road table made when its 47.3 km audit line and its 42.1 km
%   measured figure disagreed ("42.1 km is the measured figure and wins").
%   CHOSEN, DISCLOSED: S4-THE-HIGHWAY.md gives clusters ("at the dhaba",
%   "at the fuel pump", "at the tyre repair") without station numbers the
%   way S1 gave the cow or S3 gave its chainage table - every station below
%   is chosen, spread along the real 411.7 m route sc.s4world measures, not
%   sourced. Pig/goat/generic-animal dimensions are unsourced estimates,
%   same disclosure as sc.s1density/sc.s3density's own goats.

[~, truckDim] = sc.meshes("bus");        % no dedicated truck preset - bus is the
                                          % closest already-built large-rigid-body
                                          % dims in sc.meshes; disclosed, not a claim
[~, carDim]   = sc.meshes("car");
[~, motoDim]  = sc.meshes("motorcycle");
[~, autoDim]  = sc.meshes("auto");
[~, tractDim] = sc.meshes("tractor");
[~, aceDim]   = sc.meshes("tataace");    % the tanker reuses this - both rigid, mid-size
ADULT = [0.50 0.50 1.65];
DOG   = [0.60 0.25 0.45];
PIG   = [1.00 0.40 0.55];
COW   = [2.05 0.64 1.46];

L = 411.7;             % sc.s4world's own measured route length
NEAR = 7.0;             % clear of the 7.0m carriageway + 1.5m paved shoulder, flat and
                         % generous - a highway frontage sits well back, unlike S3's galli

spec = cell(0,8);
% ---- PEOPLE, 44 (8 clusters, exactly matching S4's own total) -----------
spec = addCluster(spec, 8, L*0.20, NEAR, 9, ADULT, "dhaba");        % 4 charpai+2 eating+1
                                                                      % cooking+2 washing
spec = addCluster(spec, 8, L*0.35, NEAR, 6, ADULT, "fuel pump");    % 2 attendants+4 waiting
spec = addCluster(spec, 8, L*0.45, -NEAR, 5, ADULT, "truck drivers");
spec = addCluster(spec, 8, L*0.55, NEAR, 4, ADULT, "tyre repair");
spec = addCluster(spec, 8, L*0.65, 0,     7, ADULT, "crossing at grade");  % at-grade, 0
                                                                             % lateral: they
                                                                             % ARE crossing
spec = addCluster(spec, 8, L*0.72, NEAR, 5, ADULT, "bus stop, unmarked");
spec = addCluster(spec, 8, L*0.55,-NEAR-3, 3, ADULT, "police post");
spec = addCluster(spec, 8, L*0.85, -NEAR-15, 5, ADULT, "distant, in haze");

% ---- ANIMALS: 5 cattle (median), 6 dogs (dhaba), 3 pigs (drain) ---------
spec = addCluster(spec, 10, L*0.50, +(7.0/2+2.5), 5, COW, "cattle grazing the median");
spec = addCluster(spec, 11, L*0.20, NEAR+2, 6, DOG, "dogs at the dhaba");
spec = addCluster(spec, 0,  L*0.55, -NEAR-2, 3, PIG, "pigs in the drain (service road)");

% ---- STANDING VEHICLES, 25 -----------------------------------------------
spec = addCluster(spec, 2, L*0.20, NEAR+1.0, 5, truckDim, "trucks, dhaba+pump");
spec = addCluster(spec, 2, L*0.35, NEAR+1.0, 4, truckDim, "trucks, dhaba+pump");
spec = addCluster(spec, 2, L*0.35, NEAR+3.0, 2, aceDim,   "tankers");
spec = addCluster(spec, 1, L*0.45, -NEAR,    4, carDim,   "parked cars");
spec = addCluster(spec, 5, L*0.55, NEAR,     6, motoDim,  "parked motorcycles");
spec = addCluster(spec, 4, L*0.45, -NEAR-2,  2, autoDim,  "auto-rickshaws");
spec = addCluster(spec, 14,L*0.65, -NEAR,    1, tractDim, "standing tractor-trolley");
spec = addCluster(spec, 2, L*0.30, NEAR+1.0, 1, truckDim, "broken-down truck + warning stones");

% ---- MOVING VEHICLES, 20 (real road users - excluded from clearance check) ---
spec(end+1,:) = {1, L*0.10, -1.6, carDim,  10, 0, [], []};   % merging off the slip road
spec(end+1,:) = {1, L*0.12, -1.9, carDim,  11, 0, [], []};
spec(end+1,:) = {2, L*0.40, +1.8, truckDim, 9, 0, [], []};   % lane that ends, forced across
spec(end+1,:) = {1, L*0.42, +1.5, carDim,  12, 0, [], []};
spec(end+1,:) = {1, L*0.44, +1.5, carDim,  13, 0, [], []};
spec(end+1,:) = {2, L*0.48, -1.5, truckDim,-8, 0, [], []};   % the U-turning truck (oncoming)
spec(end+1,:) = {1, L*0.60, +2.0, carDim,  14, 0, [], []};   % overtaking cars
spec(end+1,:) = {1, L*0.62, +2.0, carDim,  15, 0, [], []};
spec(end+1,:) = {1, L*0.64, +2.0, carDim,  14, 0, [], []};
spec(end+1,:) = {1, L*0.66, +2.0, carDim,  13, 0, [], []};
spec(end+1,:) = {5, L*0.30, +1.4, motoDim, 8, 0, [], []};    % 6 motorcycles
spec(end+1,:) = {5, L*0.32, +1.7, motoDim, 8, 0, [], []};
spec(end+1,:) = {5, L*0.34, -1.7, motoDim,-6, 0, [], []};    % one on the shoulder, wrong way
spec(end+1,:) = {5, L*0.50, +1.4, motoDim, 9, 0, [], []};
spec(end+1,:) = {5, L*0.52, +1.7, motoDim, 9, 0, [], []};
spec(end+1,:) = {5, L*0.54, +1.4, motoDim, 8, 0, [], []};
spec(end+1,:) = {3, L*0.20, +1.9, truckDim,11, 0, [], []};   % UPSRTC bus
spec(end+1,:) = {2, L*0.70, +1.6, truckDim, 9, 0, [], []};   % overloaded trucks, slow
spec(end+1,:) = {2, L*0.74, +1.6, truckDim, 9, 0, [], []};
spec(end+1,:) = {14,L*0.80, +1.5, tractDim, 5, 0, [], []};   % tractor-trolley on the NH

tags = strings(size(spec,1),1);
for k = 1:size(spec,1), tags(k) = tagFor(spec{k,1}); end

nPedestrian = sum([spec{:,1}] == 8);
assert(nPedestrian == 44, "sc:s4densityPeople", ...
    "%d pedestrians built, S4's own spec states 44", nPedestrian);
nVeh = sum(ismember([spec{:,1}], [1 2 3 4 5 14]));
assert(nVeh == 45, "sc:s4densityVehicles", ...
    "%d vehicles built; S4's own header says 63 but its itemised list sums to 45 " + ...
    "(disclosed in this file's header) - 45 is the built-to target", nVeh);

nOnRoad = 0;  worst = "";
for k = 1:size(spec,1)
    if spec{k,5} ~= 0, continue; end
    ext = spec{k,4};
    nearEdge = abs(spec{k,3}) - ext(2)/2;
    if abs(spec{k,3}) > 1e-6 && nearEdge < 3.5 + 1.5   % carriageway half + paved shoulder
        nOnRoad = nOnRoad + 1;
        worst = sprintf("row %d (%s) near edge %.2f m", k, tags(k), nearEdge);
    end
end
assert(nOnRoad == 0, "sc:s4densityOnRoad", "%d placements too close - worst: %s", nOnRoad, worst);
end

function spec = addCluster(spec, classID, s0, lat0, n, ext, label) %#ok<INUSD>
%ADDCLUSTER  n static actors scattered +-8m in STATION only around s0, all
%   at the SAME lat0 - the cluster IS the located, real thing; the scatter
%   inside it is chosen, same as every other cluster in this initiative.
%   Lateral is deliberately NOT jittered: lat0 is already solved to clear
%   the carriageway with a fixed extent, and jittering it independently of
%   the extent it was solved against is exactly the class of bug
%   sc.s3density's own header already found and fixed the hard way.
rs = RandStream('twister','Seed', mod(round(s0*13 + lat0*7 + 1), 2^31));
for i = 1:n
    s = s0 + 8*(rand(rs)-0.5)*2;
    spec(end+1,:) = {classID, s, lat0, ext, 0, pi/2, [], []}; %#ok<AGROW>
end
end

function s = tagFor(id)
switch id
    case 8,  s = "person"; case 0,  s = "small_animal"; case 11, s = "dog"; case 10, s = "cow";
    case 5,  s = "moto";   case 1,  s = "car"; case 2, s = "truck"; case 3, s = "bus";
    case 4,  s = "auto";   case 14, s = "tractor";
    otherwise, s = "other";
end
end
