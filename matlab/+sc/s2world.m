function W = s2world(opts)
%S2WORLD  The static world of S2 - THE CHOWK, an unsignalled gyratory.
%
%   WHAT IS REAL HERE AND WHAT IS OURS - stated first, because S2's honesty depends on it.
%     REAL, measured off map/matlab_roads.csv and re-verified in REF-17 s5:
%       - the node at (341.6, -578.6), measured against the written (340.1, -579.9): 1.9 m
%       - the FOUR arm bearings 46 / 62 / 232 / 237 deg, every one within 1 deg of the map
%       - that they sit in TWO NEAR-PARALLEL PAIRS - two arms leaving north-east, two
%         returning south-west. That is not a crossroads; it is a gyratory, and the
%         written S2 script reaches the same conclusion independently.
%     OURS, authored, and it must never be presented as the map:
%       - THE ISLAND. There is no island in the OSM data. The gyratory geometry below is
%         built to IRC 65:2017, not traced.
%       - the plinth, statue, railing, splitter islands, kerb bands and give-way lines.
%
%   IRC 65:2017 Table 6.2 - THE THREE NUMBERS GO TOGETHER AND ARE ASSERTED AS A SET:
%     inscribed circle diameter 40 m -> central island 24 m -> circulatory carriageway 8 m.
%   Design speed 30 km/h. Weaving length minimum 30 m at that speed.
%   NO LANE MARKINGS ON THE CIRCULATING CARRIAGEWAY. That is the fact S2 turns on: the
%   ego picks its own line, and MathWorks' planner cannot start without waypoints.

arguments
    opts.Centre  (1,2) double = [341.6, -578.6]     % MEASURED, REF-17 s5
    opts.Bearing (1,4) double = [46 62 232 237]     % MEASURED, within 1 deg
    opts.ArmLen  (1,1) double = 95
end

% ---------------------------------------------------------------- IRC 65:2017 Table 6.2
W.Inscribed  = 40.0;                     % inscribed circle diameter
W.IslandDia  = 24.0;                     % central island
W.Circ       = 8.0;                      % circulatory carriageway
assert(abs(W.IslandDia + 2*W.Circ - W.Inscribed) < 1e-9, "sc:s2irc", ...
    ['IRC 65:2017 Table 6.2 pairs these three: island %.1f + 2 x carriageway %.1f must ' ...
     'equal the inscribed circle %.1f'], W.IslandDia, W.Circ, W.Inscribed);
W.Rin  = W.IslandDia/2;                  % 12 m - island kerb face
W.Rout = W.Inscribed/2;                  % 20 m - outer edge of the circulating carriageway
W.DesignSpeed = 30/3.6;
W.Centre  = opts.Centre;
W.Bearing = opts.Bearing;
W.ArmW    = 7.0;                         % tertiary, S0 s4
W.ArmLen  = opts.ArmLen;
W.KerbH   = 0.15;                        % splitter and island kerbs, 150 mm
W.GiveWay = struct('Width', 0.200, 'Gap', 0.300);   % double line, 200 mm wide, 300 apart
W.NoLaneMarkings = true;                 % THE FACT THE SCENARIO TURNS ON

% ---------------------------------------------------------------- the arms
% Each arm runs OUTWARD from the inscribed circle on its measured bearing. Stored as a
% centreline so sc.path can carry the ego down it exactly like S1's tertiary.
W.Arm = struct('Bearing',{},'Dir',{},'Centre',{},'Path',{},'Name',{});
names = ["A-north-east" "B-east" "C-south-west" "D-west"];
for k = 1:4
    b = opts.Bearing(k);
    d = [sind(b), cosd(b)];                      % compass bearing -> unit vector
    p0 = opts.Centre + d*W.Rout;
    p1 = opts.Centre + d*(W.Rout + W.ArmLen);
    cl = [linspace(p0(1),p1(1),40)', linspace(p0(2),p1(2),40)'];
    W.Arm(k) = struct('Bearing',b, 'Dir',d, 'Centre',opts.Centre, ...
                      'Path',sc.path(cl,1.0), 'Name',names(k));
end

% THE PAIRS ARE THE POINT. Assert the structure the map actually has, so nobody later
% "fixes" it into a tidy 90-degree crossroads and quietly discards the real bearings.
sep_ne = abs(opts.Bearing(1) - opts.Bearing(2));
sep_sw = abs(opts.Bearing(3) - opts.Bearing(4));
assert(sep_ne < 25 && sep_sw < 25, "sc:s2pairs", ...
    ['the two arm pairs measure %.0f deg and %.0f deg apart - S2 is a gyratory of ' ...
     'near-parallel pairs, not a crossroads'], sep_ne, sep_sw);

% ---------------------------------------------------------------- the circulating ring
% The ego's route: enter on arm D, circulate anticlockwise (India drives on the LEFT, so
% traffic passes the island with the island on its RIGHT), exit on arm A.
W.EntryArm = 4;  W.ExitArm = 1;
Rmid = (W.Rin + W.Rout)/2;
aIn  = atan2d(W.Arm(W.EntryArm).Dir(2), W.Arm(W.EntryArm).Dir(1));
aOut = atan2d(W.Arm(W.ExitArm ).Dir(2), W.Arm(W.ExitArm ).Dir(1));
sweep = mod(aIn - aOut, 360);                    % clockwise in math terms = left-hand rule
th = aIn - linspace(0, sweep, max(24, round(sweep/3)));
ring = opts.Centre + Rmid*[cosd(th)', sind(th)'];
W.RingPath = sc.path(ring, 1.0);
W.Weave = W.RingPath.Len;
assert(W.Weave >= 30, "sc:s2weave", ...
    "weaving length is %.1f m, IRC requires 30 m minimum at 30 km/h", W.Weave);

% ---------------------------------------------------------------- the ego's route
% Inbound down arm D (its path runs OUTWARD from the ring, so it is reversed), round the
% ring, then out along arm A. One continuous sc.path so the ego is driven exactly as in
% S1 - station and lateral offset - and the same placeholder-driver seat applies.
inb = flipud(W.Arm(W.EntryArm).Path.P);
out = W.Arm(W.ExitArm).Path.P;
ring = W.RingPath.P;
route = [inb; ring; out];
d = [true; vecnorm(diff(route),2,2) > 1e-6];
route = route(d,:);
% THE ARM-TO-RING SEAM IS A GENUINE CORNER, NOT A SMOOTHING ARTEFACT. An arm
% points radially toward the gyratory centre; the ring at that same point is
% tangent to the circle (perpendicular to the radius) - concatenating the two
% point lists puts a real ~80-90 deg direction change at one seam, not
% something a lateral-rate limiter (sc.lateralStep, upstream of THIS - that
% smooths offset WITHIN one path, not the path's own geometry) can fix. S2's
% own written spec already names the real turning radii for exactly this
% ("entry R1 ~12m, exit R2 ~18m") - built here as CORNER-ROUNDING (Chaikin
% cuts) on the route's raw points in a short window around each seam, rather
% than an exact tangent-arc derivation, since this is a motion-quality fix,
% not a measured arithmetic claim the film's numbers depend on.
% WINDOW SIZED PER SEAM, MEASURED NOT GUESSED. A raw dot-product angle test
% either side of each seam (before any smoothing) found the entry corner at
% 41 deg and the exit corner at 82 deg - genuinely, measurably twice as
% sharp, not the same defect at two places, so it needs roughly twice the
% window to round out to comparable smoothness. Only 49 points separate the
% two seams, so BOTH windows must fit inside that gap without overlapping -
% 15 and 30 leaves a 4-point margin between them.
seamStations = [size(inb,1), size(inb,1)+size(ring,1)];
route = sc.roundRouteCorners(route, seamStations, [15 30]);
W.EgoRoute = sc.path(route, 1.0);
W.SGiveWay = W.Arm(W.EntryArm).Path.Len - 1.2;      % station of the give-way line
W.SRingIn  = size(inb,1);                            % station where the ring begins
W.SRingOut = W.SRingIn + size(ring,1);               % station where arm A begins

% ---------------------------------------------------------------- the monument
% S2: "figure ~2.4 m on a stepped plinth 2.6 m high and 3.2 m square, on a raised
% planted circle". Working figures until Aditya measures his own footage (REF-01 s14).
W.Plinth = struct('H', 2.60, 'W', 3.20, 'Steps', 3, 'RaisedR', 6.5, 'RaisedH', 0.35);
W.Statue = struct('H', 2.40);
W.RailR  = 4.6;

% ---------------------------------------------------------------- splitter islands
% One per arm, kerbed, tapering. IRC SP-41 corner radii 12-15 m on the approaches.
W.Splitter = struct('Len', 22.0, 'WNose', 1.0, 'WTail', 3.4, 'Offset', W.Rout + 2.0);
W.CornerR  = 13.5;

fprintf(['[S2 world] route %.0f m | gyratory: island %.0f m / carriageway %.0f m / inscribed %.0f m | ' ...
         '4 arms at %.0f %.0f %.0f %.0f deg (pairs %.0f and %.0f apart) | weave %.0f m\n'], ...
        W.EgoRoute.Len, W.IslandDia, W.Circ, W.Inscribed, opts.Bearing, sep_ne, sep_sw, W.Weave);
end
