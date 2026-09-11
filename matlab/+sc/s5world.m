function W = s5world()
%S5WORLD  THE MOUNTAIN ROAD - the real bridge approach plus the authored
%   hairpin climb. Part of the 5-scenario density initiative (11 Sep 2026);
%   nothing existed for S5 before this. Zero planner risk.
%
%   REAL VS CHOSEN, SAID PLAINLY - and this file has the biggest CHOSEN
%   share of any of the four, because S5's own written spec says so first:
%   "THE HILL... is the one invented thing in the world, marked as ours."
%
%   REAL, measured off sc.localRoads([-690 760], 205) - S5's own centre/radius:
%     - the approach: a real tertiary piece, 213.5 m, bearing 130.1 deg -
%       matches S5's own "tertiary road with a BRIDGE, 89 m at 132 deg"
%       closely on bearing (132 vs 130.1); this piece runs longer than just
%       the bridge span, which the written number was scoped to
%     - 4 real pieces total in the circle, 491.4 m - close to S5's own
%       "493 m of road in seven pieces" (OSM splits/classifies some
%       differently, same drift already seen in S1/S3/S4)
%   AUTHORED, EXACTLY LIKE THE HILL ITSELF IS: the climb. There is no real
%   road up an invented hill for sc.localRoads to return. S0's own hill
%   centre (-1050,900) sits roughly bearing 280 deg from where the real
%   approach ends (-766.7,848.8) - NOT a continuation of the approach's own
%   139 deg heading, so the climb genuinely forks away from the real road,
%   which is consistent with S5's "off the bridge, the climb begins."
%   Built as 5 legs / 4 hairpins (S5's own count: "Four hairpins... minimum
%   60 m between successive bends"), each leg ~194 m, total 970 m - EXACTLY
%   S5's own written 180-1150 m climb span (1150-180=970), so every station
%   in S5-THE-MOUNTAIN-ROAD.md's climb table (first hairpin ~t=24, parapet
%   gone 420-505, the washout 520-640, no-parapet 700-790, the temple at
%   1150) transfers to this path at real-approach-length + (written-180),
%   with NO remap factor needed - unlike S3, this section was never
%   measured against a shorter real substitute, it was built to the
%   written length directly, because it has no real length to fall short of.
%   Hairpins alternate +-150 deg off the main climb bearing (280 deg),
%   rounded with sc.roundRouteCorners - the same Chaikin technique S2's
%   own arm-to-ring seams use, not an exact tangent-arc match to the
%   written 14 m inner radius (a motion-quality choice, disclosed, the
%   same call roundRouteCorners' own header already makes for S2).

R = sc.localRoads([-690 760], 205);
approach = sc.routeFrom(R, [-603.6 711.6], [-766.7 848.8], 'classes', "tertiary");
P0 = sc.path(approach, 1.0);
assert(P0.Len > 150, "sc:s5approachLen", "S5 approach measured only %.1f m", P0.Len);

% ---------------------------------------------------------------- the authored climb
CLIMB_BEARING = 280;             % deg, toward the invented hill (-1050,900), measured above
HAIRPIN_OFF   = 75;              % deg either side of CLIMB_BEARING - gives a 150 deg turn
LEG_LEN       = 194;             % m - 970/5, so 4 hairpins land exactly on 970 m total
start = P0.P(end,:);
route = start;
seams = [];
dirs = [CLIMB_BEARING+HAIRPIN_OFF, CLIMB_BEARING-HAIRPIN_OFF];
for leg = 1:5
    d = dirs(mod(leg-1,2)+1);
    uv = [sind(d), cosd(d)];
    n = round(LEG_LEN);
    seg = start + (1:n)'*uv;
    route = [route; seg]; %#ok<AGROW>
    start = seg(end,:);
    if leg < 5, seams(end+1) = size(route,1); end %#ok<AGROW>
end
route = sc.roundRouteCorners(route, seams, 26);
% dedupe any near-coincident points roundRouteCorners' resampling can leave at the seams
d = [true; vecnorm(diff(route),2,2) > 1e-6];
route = route(d,:);

full = [P0.P; route];
d2 = [true; vecnorm(diff(full),2,2) > 1e-6];
full = full(d2,:);
P = sc.path(full, 1.0);

W.Path = P;
W.Width = 3.75;                   % IRC hill road, single lane (the climb - approach is 7.5m
                                   % at the bridge, but the ego's OWN drivable width for the
                                   % whole route is kept at the climb's narrower figure,
                                   % disclosed as the binding constraint for this schematic)
W.ApproachLen = P0.Len;           % real/authored boundary, for anything that needs to know
W.ClimbStart  = P0.Len;           % station 0 of the climb = written "180 m" in the spec
W.HairpinS    = P0.Len + [194 388 582 776];   % the 4 seam stations, real path coordinates

% =======================================================================================
% BUILDINGS, THE TEMPLE, AND THE NAMED HAZARDS - all on the CLIMB, none on the approach
% (S5's own text places every building "along the road" of the climb; the approach is
% fields and the river, nothing built there). Climb-relative station = real - ClimbStart,
% and because the climb was built to the WRITTEN 970 m directly (see header), climb-
% relative IS the written station minus 180 - no remap factor, unlike S3.
toReal = @(climbRel) W.ClimbStart + climbRel;

% "Hillside settlement - 22 buildings... a scatter along the road where the slope
% allows... always on the INSIDE of a bend" (tea shops) - placed near the 4 real hairpin
% seams for exactly that reason, the rest spread along the straighter stretches between.
mk = @(typ,cs,side,w,d,st,lbl) struct('Type',string(typ),'Station',toReal(cs), ...
    'Lateral', side*(2.5+w/2), 'Width',double(w),'Depth',double(d), ...
    'Storeys',double(st),'Label',string(lbl));
W.Buildings = struct('Type',{},'Station',{},'Lateral',{},'Width',{},'Depth',{}, ...
    'Storeys',{},'Label',{});
hpRel = W.HairpinS - W.ClimbStart;    % [194 388 582 776] - the bend stations, inside placement
for i = 1:5
    cs = hpRel(min(i,4)) + (i==5)*90;      % 5th tea shop near the last bend, offset along
    W.Buildings(end+1) = mk("shop", cs, 1, 3.0, 4.0, 1, ""); %#ok<AGROW>  % 5 tea shops/dhabas
end
sHouses = linspace(40, 900, 7);
for i = 1:7
    W.Buildings(end+1) = mk("house1", sHouses(i), 1, 5.0, 6.0, 1, ""); %#ok<AGROW>  % stone/mud, 7
end
sSheds = linspace(70, 860, 4);
for i = 1:4
    W.Buildings(end+1) = mk("shed", sSheds(i), 1, 3.5, 4.0, 1, ""); %#ok<AGROW>     % 4 tin sheds
end
sByre = linspace(100, 800, 3);
for i = 1:3
    W.Buildings(end+1) = mk("shed", sByre(i), 1, 3.0, 4.5, 1, "cattle byre"); %#ok<AGROW> % 3 byres
end
sHalf = [300 650];
for i = 1:2
    W.Buildings(end+1) = mk("wall", sHalf(i), 1, 4.0, 5.0, 0, "half-built, rebar showing"); %#ok<AGROW>
end
W.Buildings(end+1) = mk("house1", 500, 1, 4.0, 5.0, 1, "forest department hut");   % 1 hut
assert(numel(W.Buildings) == 22, "sc:s5buildingCount", ...
    "%d buildings built, S5's own spec states 22 (hillside settlement)", numel(W.Buildings));
W.Buildings(end+1) = struct('Type',"shrine",'Station',W.Path.Len-5,'Lateral',5.0, ...
    'Width',5.2,'Depth',5.2,'Storeys',1,'Label',"the temple, 38 steps up, at the top");
nOnRoadB = 0;
for k = 1:numel(W.Buildings)
    if abs(W.Buildings(k).Lateral) - W.Buildings(k).Width/2 < W.Width/2 + 0.3, nOnRoadB = nOnRoadB+1; end
end
assert(nOnRoadB == 0, "sc:s5buildingOnRoad", "%d buildings sit too close to the climb", nOnRoadB);

% the 5 culverts (written 265/398/542/706/941 -> climb-relative -180 each)
culvS = [265 398 542 706 941] - 180;
W.Drains = struct('S0',{},'S1',{},'Lateral',{},'Width',{},'Label',{});
for i = 1:5
    W.Drains(end+1) = struct('S0',toReal(culvS(i))-1.5,'S1',toReal(culvS(i))+1.5, ...
        'Lateral',0,'Width',1.2,'Label',"hume pipe culvert, 900mm"); %#ok<AGROW>
end
% the two missing-parapet stretches, on the OUTSIDE (drop) edge - a real, disclosed safety
% feature: "no parapet was ever built here" / "14 m of it knocked out". Drawn on the
% opposite side from the buildings (side = -1, the drop side), same band primitive.
noParapetRel = [420 505; 700 790] - 180;
for i = 1:2
    W.Drains(end+1) = struct('S0',toReal(noParapetRel(i,1)),'S1',toReal(noParapetRel(i,2)), ...
        'Lateral', -(W.Width/2+0.3), 'Width',0.6, ...
        'Label', "NO PARAPET - the drop, unprotected"); %#ok<AGROW>
end

[nOverlap, overlapWorst] = sc.checkFurnitureOverlaps(W.Buildings, []);
assert(nOverlap == 0, "sc:s5furnitureOverlap", "%d furniture overlaps - worst: %s", ...
    nOverlap, overlapWorst);

fprintf('[S5 world] approach %.1f m (real) + climb %.1f m (authored, 4 hairpins) = %.1f m total | %d buildings (spec 22+temple) | 5 culverts | 2 no-parapet stretches\n', ...
        P0.Len, P.Len - P0.Len, P.Len, numel(W.Buildings)-1);
end
