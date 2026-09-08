function S = scenarioSpec(name)
%SCENARIOSPEC  The written scenario, as data. Nothing here is invented.
%
%   Every number traces to scenarios/S1-CATTLE-CROSSING.md or S2-THE-CHOWK.md,
%   which were written BEFORE anything was built (Rule 1). Where the map disagrees
%   with the script the MAP WINS and the disagreement is recorded in .Notes.
%
%   OUTPUT S struct
%     .Name          "S1" | "S2"
%     .Centre        1x2 double  scenario circle centre, m, OSM metric frame
%     .Radius        double      m
%     .RouteRadius   double      m - roads are built out to here so the ego has a run-up
%     .RouteStart/.RouteEnd  1x2 double  m
%     .RouteClasses  string      classes the ego route may use
%     .EgoSpeed0     double      m/s at t = 0
%     .Duration      double      s
%     .Actors        struct array - see below
%     .Notes         string array - the honest disagreements with the written script
%
%   ACTOR FIELDS
%     .Name, .ClassID (S5), .Extent [L W H] m, .Behaviour
%       "static"    parked / standing. .Pose [x y yaw]
%       "scripted"  follows .Waypoints [x y] at .Speed m/s, entering at .TStart
%       "blocker"   the cow: walks .Waypoints then STOPS FOREVER. Never reacts.
%       "reactive"  gap acceptance: lifts off if the ego has committed, else holds.
%
%   LATERAL SIGN CONVENTION - GET THIS WRONG AND EVERY ENCOUNTER INVERTS
%   .Lateral is metres from the route centreline, POSITIVE IS LEFT of the ego's
%   direction of travel (matching chooseVelocity's "positive is left" frame).
%   INDIA DRIVES ON THE LEFT, so:
%     our own lane      -> POSITIVE  (+W/4; +1.75 m on a 7.0 m carriageway)
%     oncoming traffic  -> NEGATIVE  (it passes on our right, RRR 1989 reg. 2)
%     a vehicle on OUR side coming at us -> POSITIVE, and that is the wrong-side case

arguments
    name (1,1) string {mustBeMember(name,["S1","S2"])}
end

switch name
% =====================================================================================
case "S1"
% S1 - THE CATTLE CROSSING.  scenarios/S1-CATTLE-CROSSING.md
% Verified against the map 4 Sep 2026: the written junction (-252.8,+373.3) measures
% (-251.8,+370.5) - 2.9 m. The through tertiary measures 208.2 m at 132.9 deg against
% the written "209 m running 133 deg".
S.Name        = "S1";
S.Centre      = [-280, 450];
S.Radius      = 205;
S.RouteRadius = 350;                    % the written action needs ~410 m of run
S.RouteStart  = [-496.1, 654.1];        % NW end of the tertiary at r=350, MEASURED
S.RouteEnd    = [ -12.8, 300.2];        % SE end, measured
S.RouteClasses= "tertiary";
S.EgoSpeed0   = 52/3.6;                 % written: 52 km/h
S.Duration    = 62;                     % written: 62 seconds
S.CarriagewayWidth = 7.0;               % tertiary, S0 section 4

% ---- THE COW.  written: visible at 42 m, steps out, reaches the centreline, STOPS ----
% "Cow steps onto the carriageway... reaches the centreline (2.6 m at 1.2 m/s) and STOPS.
%  Stands. Head turns away. It is not negotiating. It does not care that we are there."
% zebu: withers 128 cm (REF-04). Extent from the written gap arithmetic: it occupies
% 2.5-3.2 m measured from the left edge of a 7.0 m carriageway.
S.Actors(1) = actor("COW", 10, [2.20 0.85 1.43], "blocker", ...
    'Waypoints', [], 'Speed', 1.2, 'TStart', 29.0, ...
    'StationAlong', 300.0, 'LateralFrom', 4.6, 'LateralTo', 0.65);
% The written gap arithmetic REPRODUCES from these numbers, which is why they are these
% numbers: the cow occupies 2.5-3.2 m in from the left edge of a 7.0 m carriageway, so it
% spans +0.30 to +1.00 m and free width to its RIGHT is 0.30-(-3.50) = 3.80 m. Written:
% "free width right = 3.8 m, ego 1.7 m (1.9 m with mirrors), margin 0.95 m each side."''

% ---- the oncoming auto-rickshaw that forces the ABORT.  written t=36.6, 55 m ----
% REACTIVE: it is the agent whose response the ego reads. Bajaj RE: 2.63 x 1.30 x 1.70 m
S.Actors(2) = actor("AUTO_ONCOMING", 4, [2.63 1.30 1.70], "reactive", ...
    'Speed', 30/3.6, 'TStart', 22.0, 'StationAlong', 470.0, 'Lateral', -2.2, 'Oncoming', true);

% ---- the motorcycle on OUR side of the road.  written t=11.2 ----
S.Actors(3) = actor("MC_WRONGSIDE", 5, [1.90 0.70 1.30], "scripted", ...
    'Speed', 34/3.6, 'TStart', 4.0, 'StationAlong', 300.0, 'Lateral', 1.6, 'Oncoming', true);

% ---- the tractor-trolley, oncoming, cane overhanging.  written t=19.8 ----
S.Actors(4) = actor("TRACTOR", 14, [5.60 2.30 2.60], "scripted", ...
    'Speed', 18/3.6, 'TStart', 12.0, 'StationAlong', 380.0, 'Lateral', -2.0, 'Oncoming', true);

% ---- standing things, from the written script ----
S.Actors(5) = actor("BULLOCKCART", 13, [3.10 1.60 1.70], "static", ...
    'StationAlong', 250.0, 'Lateral', -5.2, 'Yaw', 0.0);   % written: right verge
S.Actors(6) = actor("MC_PARKED", 5, [1.90 0.70 1.30], "static", ...
    'StationAlong', 352.0, 'Lateral', 5.0, 'Yaw', 0.3);

S.Notes = [ ...
  "The written script places 9 potholes, a speed breaker at 268 m and a culvert at 158 m."; ...
  "Those are SURFACE features. They are built in Blender (T2) and are not modelled as"; ...
  "MATLAB actors, so the ego does not slow for the breaker in this backup run."; ...
  "Ambient actors 3-6 are on scripted paths. Only the COW (never reacts) and the"; ...
  "AUTO_ONCOMING (gap acceptance) participate in the negotiation."];

% =====================================================================================
case "S2"
% S2 - THE CHOWK.  scenarios/S2-THE-CHOWK.md
% MEASURED DISAGREEMENT, and the map wins: the script infers a GYRATORY with a circulating
% island. The OSM data contains no ring and no island - it is ONE node at (341.6,-578.6)
% where SIX road-ends meet: four tertiary arms in two opposing pairs, plus NH534 crossing.
% All four written arm bearings match to under a degree (46/62/232/237 vs 45.8/62.1/232.3/236.7).
% So this builds a six-arm UNSIGNALLED JUNCTION with the trunk crossing. The planning
% problem is identical - no signal, no markings, negotiate or wait forever.
S.Name        = "S2";
S.Centre      = [340, -580];
S.Radius      = 165;
S.RouteRadius = 260;
S.RouteStart  = [135.2, -674.8];        % SW arm, measured
S.RouteEnd    = [447.7, -475.5];        % NE arm, measured
S.RouteClasses= "tertiary";
S.EgoSpeed0   = 26/3.6;                 % written: approaches at 26 km/h
S.Duration    = 48;                     % written: 48 seconds
S.CarriagewayWidth = 7.0;

% ---- the auto whose lift-off IS the yield the ego reads.  written t=8.3 ----
% "The auto's speed drops 1.8 km/h. Read as a yield. Commit into the gap."
S.Actors(1) = actor("AUTO_CIRCULATING", 4, [2.63 1.30 1.70], "reactive", ...
    'Speed', 24/3.6, 'TStart', 2.0, 'StationAlong', 300.0, 'Lateral', -2.4, 'Oncoming', true);

% ---- the motorcycle coming the WRONG WAY round.  written t=14.6, 18 km/h, head on ----
S.Actors(2) = actor("MC_WRONGWAY", 5, [1.90 0.70 1.30], "scripted", ...
    'Speed', 18/3.6, 'TStart', 8.0, 'StationAlong', 320.0, 'Lateral', 1.8, 'Oncoming', true);

% ---- the bus in the circulating stream.  written t=5.2 "a bus, all circulating" ----
S.Actors(3) = actor("BUS", 3, [10.80 2.60 3.10], "scripted", ...
    'Speed', 22/3.6, 'TStart', 0.5, 'StationAlong', 360.0, 'Lateral', -2.6, 'Oncoming', true);

% ---- two cows lying down.  written t=19.0 "Two cows lying on the island" ----
% No island exists, so they sit on the splitter ground beside the node, which is where
% cattle actually lie at a chowk. Static, and they never move.
S.Actors(4) = actor("COW_LYING_A", 10, [2.20 0.85 0.95], "static", ...
    'StationAlong', 232.0, 'Lateral', 7.4, 'Yaw', 0.9);
S.Actors(5) = actor("COW_LYING_B", 10, [2.20 0.85 0.95], "static", ...
    'StationAlong', 238.0, 'Lateral', 8.6, 'Yaw', 1.4);

% ---- the parked Tata Ace that narrows the exit to 2.9 m.  written t=37.5 ----
S.Actors(6) = actor("TATA_ACE", 2, [3.80 1.50 1.85], "static", ...
    'StationAlong', 330.0, 'Lateral', 4.1, 'Yaw', 0.05);

% ---- the cycle-rickshaw pulling out without looking.  written t=31.0 ----
S.Actors(7) = actor("RICKSHAW", 9, [2.40 1.10 1.60], "scripted", ...
    'Speed', 8/3.6, 'TStart', 24.0, 'StationAlong', 318.0, 'Lateral', 3.4, 'Oncoming', false);

S.Notes = [ ...
  "THE MAP OVERRULES THE SCRIPT: there is no gyratory island in the OSM data. Six road-"; ...
  "ends meet at one point (341.6,-578.6). Built as a six-arm unsignalled junction with"; ...
  "NH534 crossing. All four written arm bearings match to under one degree."; ...
  "The two cows therefore lie on the splitter ground, not on an island."; ...
  "Only AUTO_CIRCULATING negotiates. The bus, the wrong-way motorcycle and the rickshaw"; ...
  "are scripted traffic."];
end

S.Actors = S.Actors(:)';
end

% ---------------------------------------------------------------------------------------
function a = actor(name, classID, extent, behaviour, varargin)
p = inputParser;
p.addParameter('Waypoints', []);
p.addParameter('Speed', 0);
p.addParameter('TStart', 0);
p.addParameter('StationAlong', 0);      % metres along the ego route where it lives
p.addParameter('Lateral', 0);           % m from route centreline, + is LEFT of travel
p.addParameter('LateralFrom', 0);
p.addParameter('LateralTo', 0);
p.addParameter('Yaw', 0);
p.addParameter('Oncoming', false);
p.parse(varargin{:});
a = p.Results;
a.Name      = string(name);
a.ClassID   = uint8(classID);
a.Extent    = extent;
a.Behaviour = string(behaviour);
end
