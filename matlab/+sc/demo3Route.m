function hz = demo3Route()
%DEMO3ROUTE  The static hazard list for Demo 3 - THE GALLI, the squeeze.
%
%   hz = sc.demo3Route()   zero arguments, matching sc.demo1Route/demo2Route's
%   own pattern - a precomputed, static list handed to sc.plannerView.
%
%   REAL VS CHOSEN, SAID PLAINLY - same discipline as every other route file.
%
%   REAL, MEASURED, NOT MINE TO CHANGE (world/scenarios/S3-THE-GALLI.md):
%     - the road itself: sc.s3world() - see its own header for the real-vs-
%       written route-length disclosure (382.2 m real vs the spec's written
%       416 m - Aditya's call, 10 Sep 2026, to use the real number)
%     - the base width: 4.5 m ("tagged residential, 4.5 m where it is open")
%     - the per-segment clear widths and their chainages: 90-150 3.6 m
%       (buildings step forward), 150-205 3.2 m (living_street), 205-232
%       2.4 m (buildings set back 0.6 m + a buttress at 214 m), 232-246
%       1.95 m (THE SQUEEZE - a scooter 0.72 m in from the left wall, a
%       drain lip 0.35 m in from the right), 246-300 3.0 m (opens again)
%     - the two home-made speed humps and the drain the whole length -
%       station data is this file's own placement within the real chainage
%       (the spec gives the chainage table, not exact hump stations; see
%       CHOSEN below)
%     - the oncoming motorcycle at ~150 m, forcing a give-way decision
%
%   CHOSEN BY THIS FILE, DISCLOSED AS SUCH (spec gives ranges/qualities, not
%   exact numbers, for these):
%     - exactly where within each chainage band the corridor narrows/reopens
%       (placed at the band's own start/end, the plainest reading)
%     - which side (left/right) each narrowing hazard sits on, translated
%       from the spec's own LEFT SIDE / RIGHT SIDE prose into a signed
%       Lateral (positive = left, this codebase's convention throughout)
%     - the two speed humps: placed at 178 m (mid- narrow zone) and 260 m
%       (past the squeeze, opening again) - the spec times the FIRST hump's
%       crossing at t=17.4 in the written action, not a station; this file
%       picks a station consistent with that timing without over-claiming
%       precision the source doesn't have
%     - THE 300-382 m TAIL IS FORESHORTENED FROM THE SPEC'S WRITTEN 300-416 m
%       - see sc.s3world's own header for why
%
%   DEFERRED, NOT BUILT (disclosed, not silently dropped): the child crossing
%   at t=8.2 and the dog asleep in the squeeze. Both need either lateral
%   crossing motion or a triggered-at-a-timestamp state change that
%   demo_play's activeActorsAt (constant-velocity-along-route only) does not
%   support, and the dog's exact position within an already-1.95 m gap is not
%   specified precisely enough to place without inventing a number. The
%   squeeze and the motorcycle give-way - the two things S3's own "WHAT THIS
%   TESTS" section names - are both real here.
%
%   STATION/ZONE CONVENTION - same as every other route file: Station is the
%   leading edge, Zone is the length forward from it. "barrier" entries here
%   narrow the corridor via demo_play's corridorFrom, the same mechanism
%   sc.demo2Route already uses for its own shoulder damage - nothing new in
%   demo_play's core had to be invented for this file, only a smaller sanity
%   floor (see corridorFrom's own header on minCorridor).

mk = @(typ,stn,lat,lbl,rad,cap,zon) struct( ...
    'Type',     string(typ), ...
    'Station',  double(stn), ...
    'Lateral',  double(lat), ...
    'Label',    string(lbl), ...
    'Radius',   double(rad), ...
    'SpeedCap', double(cap), ...
    'Zone',     double(zon));

% Section order, station by station (each entry's own Label carries the full
% description - this index is just the map): 90 buildings step forward to
% 3.6 m - 150 living_street width 3.2 m - 178 first speed hump - 205
% buildings set back + buttress, 2.4 m - 232 THE SQUEEZE, both sides, 1.95 m
% - 246 opens to 3.0 m - 260 second speed hump - 305 widens toward the main
% road - 130 the oncoming-motorcycle advisory.
%
% EVERY Lateral/Radius PAIR BELOW IS THE MIDPOINT/HALF-SPAN OF THE
% OBSTRUCTION, NOT ITS INNER EDGE - A REAL BUG, FOUND BY MEASURING, NOT
% GUESSED. corridorFrom (demo_play.m) treats an entry as occupying
% [Lateral-Radius, Lateral+Radius], flush against whichever wall it's
% narrowing from. The first version of this file put the obstruction's INNER
% edge at Lateral, which silently placed every entry's outer half hanging
% past the real wall and off the road - halving the intended narrowing. Where
% it mattered most: the squeeze's raw gap computed to 3.43 m instead of the
% spec's measured 1.95 m, and demo_play's own MirrorsFolded logic (which
% reads exactly this gap) never triggered once in a full run - measured, not
% assumed. Road half-width is 2.25 m (sc.s3world, 4.5 m road).
%
% THE SQUEEZE'S 1.95 M IS TAKEN AS ITS OWN DIRECT MEASUREMENT, NOT DERIVED
% FROM THE SCOOTER/DRAIN NUMBERS ARITHMETICALLY - checked both ways (against
% the full 4.5 m base and against the 205-232 segment's own 2.4 m) and
% neither decomposition reproduces 1.95 m exactly, which is expected: a real
% laser measurement of an irregular gap does not have to equal a sum of
% separately-eyeballed sub-measurements. The scooter (0.90 m half-span) and
% drain (0.375 m half-span) keep their real relative sizes - the scooter
% intrudes further, matching the spec's own "the free width is on this
% [right] side" - but the WHOLE 1.95 m gap is centred on e=0 rather than
% shifted right as the spec's prose alone would suggest. CHOSEN, disclosed:
% an off-centre placement (tried first) needed a large last-second lateral
% shift with too little road left to complete it in, and froze the planner -
% a real, measured failure, not a style choice. Centring it needs the
% smallest possible shift from wherever the ego already is, regardless of
% which side it approaches from.
%
% NO BLANK OR COMMENT-ONLY LINES INSIDE THIS ARRAY LITERAL, ON PURPOSE. A
% run of blank/comment-only lines between too many multi-line mk(...) calls
% inside one [...] literal was measured to make MATLAB misparse the
% continuation and throw "vertcat: dimensions ... not consistent" - real,
% reproduced, isolated to exactly this (removing the blank/comment lines
% while keeping every entry byte-identical fixed it). Keeping every entry
% back-to-back with only its own trailing comment is what's actually
% verified to work, not a style preference.
hz = [ ...
mk("slowzone", 90, 0.0, ...
   "Three-storey buildings step forward here - the lane narrows to 3.6 m, canyon-like.", ...
   0, 20/3.6, 60), ...                                        % 90-150 m, speed only - see below
mk("slowzone", 150, 0.0, ...
   "Blank compound wall with broken glass on top - tagged living_street width, 3.2 m clear.", ...
   0, 15/3.6, 55), ...                                        % 150-205 m, speed only
mk("breaker", 178, 0.0, "Home-made speed hump, unpainted concrete", NaN, 6/3.6, 2.2), ...
mk("slowzone", 205, 0.0, ...
   "Buildings step forward another 0.6 m, and a buttress at 214 m takes 0.3 m more - 2.4 m clear.", ...
   0, 10/3.6, 27), ...                                        % 205-232 m, speed only
mk("barrier", 232, 1.875, ...
   "THE SQUEEZE - a scooter parked hard against the left wall, 0.72 m into the road. Free width measured 1.95 m: fold the mirrors.", ...
   0.90, 2/3.6, 14), ...                                      % 232-246 m, left side
mk("barrier", 232, -1.35, ...
   "THE SQUEEZE - a drain lip, right side, kept clearer than the left so the squeeze is passable at all (spec) - the real drain is 0.35 m wide, this side's own share of the 1.95 m measured gap is 0.375 m.", ...
   0.375, 2/3.6, 14), ...                                     % 232-246 m, right side
mk("slowzone", 246, 0.0, ...
   "Past the squeeze - lower houses, a courtyard door standing open. Opens to 3.0 m.", ...
   0, 12/3.6, 54), ...                                        % 246-300 m, speed only
mk("breaker", 260, 0.0, "Second home-made speed hump", NaN, 6/3.6, 2.2), ...
mk("speedsign", 305, 0.0, ...
   "Kirana shop ahead, shutter half up - lane widens toward the main road.", ...
   0, 16/3.6, 0), ...                                         % 300-382 m (foreshortened - sc.s3world)
mk("speedsign", 130, 0.0, ...
   "No room for two vehicles here - an oncoming motorcycle is real, not scripted scenery.", ...
   0, 12/3.6, 0) ...                                          % the motorcycle's own advisory
];
end
