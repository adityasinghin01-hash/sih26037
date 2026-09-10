function [spec, tags] = s1density()
%S1DENSITY  S1's density layer: the 21 people, the animals beyond the cow, and
%   the standing vehicles S1-CATTLE-CROSSING.md itemises but nothing in this
%   repo builds yet (sc.s1actors owns the cow/herd/oncoming-traffic negotiation
%   set - untouched, not duplicated here). Part of the 5-scenario density
%   initiative (11 Sep 2026); zero planner risk - this never feeds sc.planSeat.
%
%   [spec, tags] = sc.s1density()  no arguments: a precomputed static list,
%   same shape as demo_play.m's own actorSpec/actorSpecS3 (which this format
%   is deliberately copied from, not reinvented) - {ClassID, s0, lateral0,
%   Extent[L W H], along-route speed (- = oncoming), extra yaw rad, [optional
%   lateral target, [t1 t2]]}. Feed it to sc.activeDensityActorsAt(spec,P,t)
%   to get per-frame tracks for sc.plannerView, exactly the way
%   demo_play.m's activeActorsAt already works for the scenarios it drives -
%   see that function's own header for why this file keeps a private copy
%   rather than calling into demo_play.m (a local function there, not
%   exported, and not a file this initiative is touching).
%
%   REAL VS CHOSEN, SAID PLAINLY (same discipline as every other file here):
%   REAL, from S1-CATTLE-CROSSING.md, NOT MINE TO CHANGE:
%     - all 8 people clusters and their counts (2+1+4+1+2+3+5+3 = 21) and
%       their written station ranges (cane cutters 30-42m, paddy harvesters
%       176-255m, the dairy yard at 340m, the junction cluster, children at
%       360m, "nobody in the open field stretch between 60 and 170m")
%     - the animal counts: 2 loose zebu bulls, 4 buffalo, 6 goats, 5 dogs,
%       plus the dairy yard's own tethered "3 tethered (2 standing, 1
%       lying) + 1 calf"
%     - the standing vehicles: 4 motorcycles at the junction shop, 1 bicycle
%       against the wall, 1 bullock cart (bed 1.83x0.91m - the spec's own
%       measurement, not estimated) parked at 305m, 1 tractor+trolley loaded
%       with sheaves in the paddy field
%     - the moving cyclist and the moving Bolero pickup, both named in
%       VEHICLES as real elements this scenario is missing
%   CHOSEN, DISCLOSED, NOT SOURCED:
%     - the exact metre/lateral offset of each person/animal WITHIN its
%       written cluster/range - the spec gives the cluster, not individual
%       coordinates
%     - goat dimensions (no source anywhere in this repo; a generic small
%       quadruped estimate, ~0.9x0.35x0.65m) and bicycle dimensions (no
%       sc.meshes preset exists for one; ~1.7x0.5x1.7m including rider)
%     - the Bolero pickup reuses sc.meshes("tataace")'s dimensions - both
%       are small Indian pickup-class vehicles; visually distinct in
%       reality, dimensionally close enough for a flat 2D box
%     - S5's frozen ClassID enum (AGENTS.md s3) has no "buffalo", "bull" or
%       "goat" class. Bulls and buffalo are mapped to 10 (cow) - genuinely
%       the same sub-family, not a stretch. Goats get 0 (unknown) rather
%       than being forced into "dog" or "cow", because neither is honestly
%       closer - disclosed rather than silently misclassified
%     - motion: only the cyclist (spec: "moving away") and the tractor+
%       trolley pairing use the along-route speed column; every static
%       cluster (cane cutters, paddy harvesters, the dairy yard, the
%       junction, the goats, the tethered/loose cattle) is placed once and
%       does not move - matching how the herd (sc.s1actors' A.Herd) is
%       already built, and this file's own STATION/LATERAL choices already
%       state which stretch each belongs to
%
%   NOT built here, disclosed as omitted rather than silently dropped: the
%   ~45 birds and the 8 cattle egrets (decorative, do not read as distinct
%   marks in a flat top-down 2D schematic - see the 5-scenario density plan)
%   and the one child "on a cycle too big for him" (kept as a plain
%   pedestrian entry - the cycle detail is a visual-only elaboration this
%   initiative's 2D layer has no use for).

ADULT = [0.50 0.50 1.65];   CHILD = [0.40 0.40 1.20];
GOAT  = [0.90 0.35 0.65];   DOG   = [0.60 0.25 0.45];
BULLOCK_CART = [1.83 0.91 0.90];               % S1's own measurement
BICYCLE = [1.70 0.50 1.70];
[~, cowDim]    = sc.meshes("zebu");            % reused for bulls/buffalo, disclosed above
[~, motoDim]   = sc.meshes("motorcycle");
[~, tractDim]  = sc.meshes("tractor");
[~, trolDim]   = sc.meshes("trolley");
[~, aceDim]    = sc.meshes("tataace");         % reused for the Bolero, disclosed above

spec = { ...
% ---- PEOPLE, 21 -------------------------------------------------------
8,  34, +4.3, ADULT, 0, pi/2, [], [] ; ...      % cane cutter 1 (30-42m, left)
8,  38, +4.6, ADULT, 0, pi/2, [], [] ; ...      % cane cutter 2
8,  55, +4.5, ADULT, 0, 0,    [], [] ; ...      % carrying cane bundle, walking the verge
8, 190, +4.5, ADULT, 0, pi/2, [], [] ; ...      % paddy harvester 1 (176-255m, left)
8, 205, +4.8, ADULT, 0, pi/2, [], [] ; ...      % paddy harvester 2
8, 220, +4.5, ADULT, 0, pi/2, [], [] ; ...      % paddy harvester 3
8, 240, +5.0, ADULT, 0, pi/2, [], [] ; ...      % paddy harvester 4, stacking
8, 278, +4.3, ADULT, 0, 0,    [], [] ; ...      % woman walking, left verge 280m
8, 282, +4.6, ADULT, 0, 0,    [], [] ; ...      % woman walking, left verge 280m
8, 338, -4.5, ADULT, 0, pi/2, [], [] ; ...      % dairy yard, right 340m - milking
8, 340, -4.8, ADULT, 0, pi/2, [], [] ; ...      % dairy yard - loading
8, 342, -4.3, ADULT, 0, pi/2, [], [] ; ...      % dairy yard - loading
8, 383, +3.9, ADULT, 0, pi/2, [], [] ; ...      % junction cluster - waiting for shared auto
8, 384, +4.2, ADULT, 0, pi/2, [], [] ; ...      % junction cluster - waiting for shared auto
8, 385, +4.5, ADULT, 0, pi/2, [], [] ; ...      % junction cluster - at the shop
8, 388, -3.9, ADULT, 0, pi/2, [], [] ; ...      % junction cluster - talking
8, 389, -4.2, ADULT, 0, pi/2, [], [] ; ...      % junction cluster - talking
8, 358, +4.3, CHILD, 0, pi/2, [], [] ; ...      % children, left 360m
8, 360, +4.6, CHILD, 0, pi/2, [], [] ; ...      % children (one "on a cycle too big for him")
8, 362, +4.9, CHILD, 0, pi/2, [], [] ; ...      % children
9, 130, -4.0, BICYCLE, 2.8, 0, [], [] ; ...     % the cyclist, moving away (spec: PEOPLE+VEHICLES)
% ---- ANIMALS beyond the cow/herd ---------------------------------------
10, 220, -5.0, cowDim, 0, pi/2, [], [] ; ...    % loose zebu bull 1 (stubble, 210-268m)
10, 245, -5.5, cowDim, 0, pi/2, [], [] ; ...    % loose zebu bull 2
10, 317, -4.3, cowDim, 0, pi/2, [], [] ; ...    % buffalo, driven along the right verge, 320m
10, 319, -4.6, cowDim, 0, pi/2, [], [] ; ...    % buffalo
10, 321, -4.9, cowDim, 0, pi/2, [], [] ; ...    % buffalo
10, 323, -4.4, cowDim, 0, pi/2, [], [] ; ...    % buffalo
0,  160, -5.0, GOAT, 0, pi/2, [], [] ; ...      % goat 1 (kans grass, 150-200m, right)
0,  165, -5.3, GOAT, 0, pi/2, [], [] ; ...      % goat 2
0,  172, -4.8, GOAT, 0, pi/2, [], [] ; ...      % goat 3
0,  180, -5.5, GOAT, 0, pi/2, [], [] ; ...      % goat 4
0,  188, -5.0, GOAT, 0, pi/2, [], [] ; ...      % goat 5
0,  195, -5.3, GOAT, 0, pi/2, [], [] ; ...      % goat 6
11, 100, +4.2, DOG, 0, 0, [], [] ; ...          % dog trotting the verge
11, 386, +4.5, DOG, 0, pi/2, [], [] ; ...       % dog asleep at the shop
11, 386, +4.8, DOG, 0, pi/2, [], [] ; ...       % dog asleep at the shop
11, 390, +5.0, DOG, 0, pi/2, [], [] ; ...       % dog nursing under the charpai
11, 450, -4.5, DOG, 0, 0, [], [] ; ...          % dog trotting the verge
10, 336, -5.0, cowDim, 0, pi/2, [], [] ; ...    % dairy yard: tethered, standing
10, 338, -5.3, cowDim, 0, pi/2, [], [] ; ...    % dairy yard: tethered, lying
10, 340, -5.6, cowDim, 0, pi/2, [], [] ; ...    % dairy yard: tethered, standing
10, 339, -5.0, [1.1 0.4 0.9], 0, pi/2, [], [] ; ... % dairy yard: the calf
% ---- STANDING VEHICLES, and the two missing moving ones ----------------
5, 384, +4.0, motoDim, 0, pi/2, [], [] ; ...    % standing motorcycle 1 (junction shop)
5, 384, +4.3, motoDim, 0, pi/2, [], [] ; ...    % standing motorcycle 2
5, 384, +4.6, motoDim, 0, pi/2, [], [] ; ...    % standing motorcycle 3
5, 384, +4.9, motoDim, 0, pi/2, [], [] ; ...    % standing motorcycle 4
9,  387, +5.2, BICYCLE, 0, pi/2, [], [] ; ...   % bicycle against the wall
13, 305, -4.5, BULLOCK_CART, 0, pi/2, [], [] ; ...  % parked bullock cart, shafts down
14, 210, +8.0, tractDim, 0, 0, [], [] ; ...     % standing tractor in the paddy field
15, 213, +8.5, trolDim, 0, 0, [], [] ; ...      % its loaded trolley (static obstacle - no
                                                 % dedicated "trolley" S5 class; disclosed)
1,  92, -3.0, aceDim, -12/3.6, 0, [], [] ...    % the Bolero pickup, oncoming (spec names it,
                                                 % nothing else places it - clear stretch
                                                 % chosen, away from the cow/traffic beats)
};

tags = strings(size(spec,1),1);
names = ["person","goat","dog","cow","moto","bicycle","cart","tractor","trolley","bolero"];
for k = 1:size(spec,1)
    switch spec{k,1}
        case 8,  tags(k) = "person";
        case 0,  tags(k) = "goat";
        case 11, tags(k) = "dog";
        case 10, tags(k) = "cow";
        case 5,  tags(k) = "moto";
        case 9,  tags(k) = "bicycle";
        case 13, tags(k) = "cart";
        case 14, tags(k) = "tractor";
        case 15, tags(k) = "trolley";
        case 1,  tags(k) = "bolero";
        otherwise, tags(k) = "other";
    end
end

% S1's own PEOPLE count (21) includes "1 on a bicycle" - that rider is built
% as the ClassID=9 cyclist row above (real dimensions/kinematics need the
% bicycle class, not pedestrian), so the total is pedestrians PLUS that one
% row, not pedestrians alone. The bicycle PARKED at the junction is a
% different, separate item from VEHICLES and does not count here.
nPedestrian = sum([spec{:,1}] == 8);
nCyclistPeople = 1;
assert(nPedestrian + nCyclistPeople == 21, "sc:s1densityPeople", ...
    "%d pedestrians + %d cyclist = %d people built, S1's own spec states 21", ...
    nPedestrian, nCyclistPeople, nPedestrian + nCyclistPeople);

% NOTHING MAY SIT ON THE DRIVABLE CARRIAGEWAY - the same rule s1world.m's own
% sc:s1vegOnRoad assert enforces for the forest. Checked against each row's
% OWN static lateral (spec{:,3}), which is the near-fixed value for every
% entry except the cyclist and the Bolero - both pass THROUGH the carriageway
% by design (a cyclist and an oncoming pickup are real road users), so they
% are excluded from this static-clearance check, not silently passed.
ROAD_HALF = 3.5;   % S1's own 7.0 m carriageway (sc.s1world W.Width/2)
nOnRoad = 0;  worst = "";
for k = 1:size(spec,1)
    if spec{k,1} == 9 && spec{k,5} ~= 0, continue; end   % the moving cyclist
    if spec{k,1} == 1 && spec{k,5} ~= 0, continue; end   % the Bolero
    ext = spec{k,4};
    nearEdge = abs(spec{k,3}) - ext(2)/2;
    if nearEdge < ROAD_HALF
        nOnRoad = nOnRoad + 1;
        worst = sprintf("row %d (%s) at lateral %.2f m, width %.2f m -> near edge %.2f m", ...
            k, tagsFor(spec{k,1}), spec{k,3}, ext(2), nearEdge);
    end
end
assert(nOnRoad == 0, "sc:s1densityOnRoad", ...
    "%d density actors intrude on the %.1f m carriageway - worst: %s", nOnRoad, 2*ROAD_HALF, worst);
end

function s = tagsFor(id)
switch id
    case 8,  s = "person"; case 0,  s = "goat"; case 11, s = "dog"; case 10, s = "cow";
    case 5,  s = "moto";   case 9,  s = "bicycle"; case 13, s = "cart";
    case 14, s = "tractor"; case 15, s = "trolley"; case 1, s = "bolero";
    otherwise, s = "other";
end
end
