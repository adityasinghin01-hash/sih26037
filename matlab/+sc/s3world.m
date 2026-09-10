function W = s3world()
%S3WORLD  THE GALLI - the real road, for the 2D live demo only.
%
%   Deliberately leaner than sc.s1world: this demo needs a path the planner
%   can drive and a width the corridor math can narrow, not tree counts or a
%   reveal-distance mechanic - S3 has no forest and no sight-line hero shot.
%   "Less, but properly built" (matlab/DEMO-README.md's own standard).
%
%   REAL VS CHOSEN, SAID PLAINLY - same discipline sc.s1geom and the demoNRoute
%   files use.
%
%   REAL, MEASURED, NOT MINE TO CHANGE:
%     - centre (-155,-476), radius per world/scenarios/S3-THE-GALLI.md
%     - the road itself: sc.localRoads([-155 -476], 320) -> sc.routeFrom(...,
%       'classes',"residential") from (8.3,-362.9) to (-144.9,-709.0), 4 real
%       OSM pieces (lengths 199.4/44.6/56.8/81.3 m)
%     - four of the spec's seven side lanes reproduce almost exactly from the
%       same OSM export: 105.6 m @ 17 deg (spec: 106 @ 17), 277.1 m @ 154 deg
%       (spec: 278 @ 154), 105.3 m @ 313 deg (spec: 105 @ 313), 64.6 m @ 133
%       deg (spec: 65 @ 133) - none of those side lanes are used by this demo,
%       they are recorded here only as the evidence that this is the right
%       real location, not a stand-in
%
%   CHOSEN BY THIS FILE, DISCLOSED AS SUCH:
%     - route length: this real path measures 382.2 m. The spec states 416 m.
%       Checked twice, against two different real candidate endpoints (a
%       shorter one snapping to 382.2 m, a longer one reaching 488.4 m, 17%
%       OVER) - 382.2 m is the closer real match, not a compromise, and nothing
%       closer to 416 m exists as one connected real path in this map export.
%       Aditya's call, 10 Sep 2026: use the real 382.2 m rather than keep
%       searching. The spec's own chainage table (0-90 normal, ... 300-416
%       widens) is kept at its written stations; the practical effect is that
%       the final "lane widens, approaches the main road" stretch is
%       foreshortened to 300-382 m, not 300-416 m. Nothing before 300 m moves.
%     - width: 4.5 m base (spec: "tagged residential, 4.5 m where it is open").
%       The narrowing sequence (buildings stepping forward, the buttress, the
%       squeeze, the drain) is NOT a property of this road object - it is
%       authored as corridor-narrowing hazards, the exact mechanism
%       demo2Route.m already uses for its own shoulder-crumbling entries, so
%       demo_play.m's core loop needs no new concept to drive here.

R = sc.localRoads([-155 -476], 320);
centre = sc.routeFrom(R, [8.3 -362.9], [-144.9 -709.0], 'classes', "residential");
P = sc.path(centre, 1.0);
assert(abs(P.Len - 382.2) < 1.0, "sc:s3worldLen", ...
    ['S3 route length has drifted to %.2f m (expected ~382.2 m) - every station ' ...
     'number in demo3Route.m is keyed to this measured length.'], P.Len);

W.Path  = P;
W.Width = 4.5;             % m, S3-THE-GALLI.md: "tagged residential, 4.5 m where it is open"

% =======================================================================================
% BUILDINGS AND INFRASTRUCTURE - added 11 Sep 2026, the 5-scenario density initiative.
% Zero planner risk (W.Path/W.Width untouched) - static-world furniture for
% sc.plannerView only. This function stays "leaner than s1world" in spirit: no forest,
% no reveal mechanic, so this section is the one addition, kept in the same file rather
% than spawning a second one, because S3 has nothing else to keep it apart from.
%
% THE STATION REMAP THIS WHOLE SECTION RUNS ON. demo3Route.m's own header already
% establishes it: stations <= 300 m are real (1:1 with the written spec), stations
% > 300 m are foreshortened by (382.2-300)/(416-300) = 0.7086, because the real route
% is 382.2 m against the written 416 m and nothing before 300 m moves. Reused here
% verbatim rather than re-derived, so a building and a hazard can never disagree about
% where "340 m" actually is.
remap = @(sw) sw + (sw>300).*(sw-300).*(0.70862 - 1);

% THE PER-BAND CLEAR WIDTH IS THE SPEC'S OWN TABLE, taken directly rather than reverse-
% engineered from demo_play's corridorFrom mechanism (which narrows the DRIVABLE
% corridor from hazard entries, a different and lossier path back to the same number).
% "No setback" (S3-THE-GALLI.md, verbatim) means the building wall more or less IS the
% edge of the clear width at each station - so a building's near edge is placed at that
% half-width plus a small 0.15 m gap, not a yard the way S1's rural roadside got one.
bands = [ ...
    0   90  4.5   16 "house2" ; ...   % "two-storey, continuous frontage" both sides
    90  150 3.6   11 "house3" ; ...   % "three-storey... canyon-like"
    150 205 3.2    3 "wall"   ; ...   % blank compound walls (+ the empty-plot GAP, s3density)
    205 246 2.4    4 "house1" ; ...   % stepping forward, the buttress, the squeeze
    246 300 3.0    5 "house1" ; ...   % "lower houses, a courtyard door standing open"
    300 416 3.8   10 "house2" ];      % widens toward the main road (foreshortened by remap)
rng(26037);
W.Buildings = struct('Type',{},'Station',{},'Lateral',{},'Width',{},'Depth',{}, ...
    'Storeys',{},'Label',{});
storeyOf = dictionary(["hut" "house1" "house2" "house3" "wall" "shop" "shed"], ...
                      [1 1 2 3 0 1 1]);
for b = 1:size(bands,1)
    s0 = str2double(bands(b,1));  s1 = str2double(bands(b,2));
    halfW = str2double(bands(b,3));  n = round(str2double(bands(b,4)));
    typ = bands(b,5);
    ss = linspace(s0 + (s1-s0)*0.06, s1 - (s1-s0)*0.06, n);
    for i = 1:n
        side = 2*mod(i,2) - 1;                    % alternate left/right
        frontW = 3.0 + 3.5*rand;                   % S0 s5: "width 2.9-9.5 m" - kept modest
        depth  = 5.0 + 2.0*rand;
        near   = halfW + 0.15;
        W.Buildings(end+1) = struct('Type',typ,'Station',remap(ss(i)), ...
            'Lateral', side*(near + frontW/2), 'Width',frontW, 'Depth',depth, ...
            'Storeys', storeyOf(typ), 'Label',""); %#ok<AGROW>
    end
end
% the two tin sheds and the kirana shop - named, not scattered, both in the
% widened 300-416 band (foreshortened, remapped)
W.Buildings(end+1) = struct('Type',"shed",'Station',remap(320),'Lateral', 1.5+2.0+0.15, ...
    'Width',3.2,'Depth',5.0,'Storeys',1,'Label',"");
W.Buildings(end+1) = struct('Type',"shed",'Station',remap(400),'Lateral',-(1.9+1.6+0.15), ...
    'Width',3.2,'Depth',5.0,'Storeys',1,'Label',"");
W.Buildings(end+1) = struct('Type',"shop",'Station',remap(405),'Lateral', (1.9+1.5+0.15), ...
    'Width',2.9,'Depth',4.0,'Storeys',1,'Label',"kirana shop, shutter half up");
% the remaining 2 of the spec's "5 compound walls only" (3 already placed in band C)
W.Buildings(end+1) = struct('Type',"wall",'Station',remap(340),'Lateral',-(1.9+1.6+0.15), ...
    'Width',3.2,'Depth',3.0,'Storeys',0,'Label',"");
W.Buildings(end+1) = struct('Type',"wall",'Station',remap(360),'Lateral', (1.9+1.5+0.15), ...
    'Width',3.2,'Depth',3.0,'Storeys',0,'Label',"");
assert(numel(W.Buildings) == 54, "sc:s3buildingCount", ...
    "%d buildings built, S3's own spec states 54", numel(W.Buildings));
nOnRoadB = 0;
for k = 1:numel(W.Buildings)
    if abs(W.Buildings(k).Lateral) - W.Buildings(k).Width/2 < 0.90
        nOnRoadB = nOnRoadB + 1;   % 0.90 m: below even the squeeze's own folded margin
    end
end
assert(nOnRoadB == 0, "sc:s3buildingOnRoad", ...
    "%d buildings leave less than 0.90 m of clear width at their own station", nOnRoadB);

% ---------------------------------------------------------------- infrastructure
% "An open drain the whole length, right side" - S3's own words, and W.Drains already
% draws exactly this shape (a parallel band, not S1's culvert-marker point). Right side
% is the SIGNED convention this codebase uses throughout (positive = left).
W.Drains = struct('S0',0,'S1',W.Path.Len,'Lateral',-2.5,'Width',0.38, ...
    'Label',"open drain, 380mm, the whole length");
% "9-14 parallel wire runs... service drops to every house" - drawn as ONE representative
% pole/wire run rather than 9-14 literal lines: a flat top-down schematic cannot show sag,
% height or which of 14 runs is which voltage, so drawing all of them adds clutter without
% adding information this layer can actually convey. Disclosed as a simplification, not a
% missed count - the spec's own number is about what is OVERHEAD, and this view is plan-only.
poleS = 20:40:360;
W.Poles = struct('Station',{},'Lateral',{},'Run',{},'Label',{});
for s = poleS
    W.Poles(end+1) = struct('Station',s,'Lateral',2.6,'Run',1, ...
        'Label',"overhead wire bundle (9-14 real runs, drawn as one)"); %#ok<AGROW>
end
% the transformer "on two poles" at 118 m, right side - a real, specifically located item
W.Poles(end+1) = struct('Station',118,'Lateral',-2.6,'Run',2,'Label',"transformer, two poles");

fprintf('[S3 world] route %.1f m | %d buildings (spec 54) | drain the whole length | %d poles in %d run(s)\n', ...
        W.Path.Len, numel(W.Buildings), numel(W.Poles), numel(unique([W.Poles.Run])));
end
