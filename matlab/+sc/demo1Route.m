function hz = demo1Route()
%DEMO1ROUTE  The static hazard list for Demo 1 - S1, THE CATTLE CROSSING.
%
%   hz = sc.demo1Route()    zero arguments, by design: this is a PRECOMPUTED,
%   static list, built once and handed straight to
%       sc.plannerView('init', struct(..., 'Hazards', hz))
%   the same way plannerView's own header already documents the Hazards field.
%   It does not touch the ego, the planner, or run time - it is scenery data.
%
%   THE COW IS NOT IN HERE, ON PURPOSE. Read this before wondering where it
%   went: the cow is a REAL, EXISTING actor, already fully wired through
%   W.CowStation (sc.s1world, = 300.0 m) -> sc.s1actors -> sc.s1geom (which
%   does the actual gap arithmetic: free width 3.83 m, margin 0.965 m each
%   side). "cow" is not one of this struct's 7 allowed Type values, and it
%   should not be - Demo 1's requirement to "include the cow" is satisfied
%   by that existing world/actor pipeline, not by this file. Everything
%   below is the STATIC road surface hazard furniture laid around her: the
%   potholes, the breaker, the signs, the village slow zone, the one sharp
%   turn worth calling out. Nobody should read this file and conclude the
%   cow got silently dropped - she didn't, she was never this file's job.
%
%   REAL VS CHOSEN, SAID PLAINLY (same discipline as sc.s1geom / sc.s10Route):
%   REAL, MEASURED, NOT MINE TO CHANGE:
%     - the route itself: sc.localRoads([-280 450],350) -> sc.routeFrom(...,
%       'classes',"tertiary") -> sc.path(centre,1.0) is EXACTLY what
%       sc.s1world.m builds. Rebuilt here (cheaply, once) purely so the two
%       asserts below can catch drift - the same "two sources for one
%       number is the bug" reasoning sc.s1geom's header gives for its own
%       arithmetic.
%     - route length: 610.13 m (asserted below).
%     - the 9 pothole stations: 34, 88, 89, 141, 196, 240, 241, 243, 302 m,
%       and the speed-breaker station: 268 m - all literal chainages out of
%       scenarios/S1-CATTLE-CROSSING.md ("9 potholes ... at 34, 88, 89, 141,
%       196, 240, 241, 243, 302 m", "Speed breaker at 268 m").
%     - pothole diameters: spec gives a RANGE (0.25-0.9 m across, i.e.
%       radius 0.125-0.45 m) for the nine as a set, not a per-pothole value.
%       The individual Radius below is this file's own pick WITHIN that
%       measured range, disclosed as chosen, not measured per-pothole.
%     - breaker geometry: IRC 99, 3.7 m long - matches plannerView's own
%       drawHazard bandDepth, so Zone here is that same real length, not an
%       invented one.
%     - the sharp bend at s=511 m: genuine OSM-derived curvature, computed
%       via P.curvature() below, NOT authored. Confirmed radius ~63.4 m,
%       the sharpest real bend on this route (the other two real bends,
%       s~203 m R~73 m and s~429 m R~114 m, are gentler and not used here -
%       one sharp-turn beat is what the pacing calls for, not three).
%     - village edge: spec's own "330-410 The village edge" (LEFT SIDE,
%       metre by metre) with huts, then a dairy yard, children at 360 m.
%   CHOSEN BY THIS FILE, DISCLOSED AS SUCH (spec gives no data for these -
%   there is no real sign inventory, no per-pothole lateral position, no
%   posted speed limit anywhere in S1):
%     - every Lateral (mid-lane placement of each pothole/sign)
%     - both speedsign placements and their posted values
%     - the slowzone and sharpturn SpeedCap values (formulas/reasoning given
%       inline, at each hazard, below)
%
%   STATION/ZONE CONVENTION (this struct's own, since the frozen contract
%   doesn't fix one): Station is the LEADING EDGE of a hazard - where it
%   first becomes relevant. Zone, when nonzero, is the length of affected
%   road measured FORWARD from Station (breaker: its own 3.7 m length;
%   slowzone: exactly the spec's 330-410 m span; sharpturn: an authored
%   estimate of the curve's driven extent - P.curvature() gives radius AT a
%   station, not the length of the tight arc, so 25 m forward of the
%   measured peak is this file's own estimate, not a second measurement).
%   Point hazards (every pothole, both signs) carry Zone = 0.
%
%   PACING (point 8 of the brief, why the stations fall where they do):
%   speed-limit sign at the start -> three scattered early potholes (34,
%   88, 89 - the last two genuinely only ~1 m apart) -> a quiet ~50 m gap
%   to the one truly ISOLATED, dodge-able pothole at 141 -> another quiet
%   gap to 196 -> the real, tight, un-dodgeable 240/241/243 cluster ->
%   straight into the unsigned speed breaker at 268 -> pothole 302, which
%   lands DURING the cow encounter (300 m) by the spec's own numbers, not
%   this file's choice -> a calm ~20 m gap -> the village slowzone (330-
%   410) -> a long quiet stretch -> an advisory sign -> the one real sharp
%   turn at 511 -> ~74 m of calm road into the (not-authored-here) junction
%   at the route's end, 610 m.

% ---------------------------------------------------------------- verify against the real route
% Rebuilt exactly as sc.s1world.m builds it - see header. This costs one
% cheap rebuild per call and buys a loud failure the moment the map data,
% or this route's geometry, ever drifts out from under these hand-picked
% stations.
R = sc.localRoads([-280 450], 350);
centre = sc.routeFrom(R, [-496.1 654.1], [-12.8 300.2], 'classes', "tertiary");
P = sc.path(centre, 1.0);
assert(abs(P.Len - 610.13) < 0.05, "sc:demo1RouteLen", ...
    ['S1 route length has drifted to %.2f m (expected ~610.13 m) - every station ' ...
     'number in this file is keyed to the ORIGINAL measured route.'], P.Len);

k = P.curvature();
sSharp = 511;                                        % real, measured peak - see header
iSharp = max(1, min(numel(k), round(sSharp/P.Step)+1));
rSharp = 1/k(iSharp);
assert(abs(rSharp - 63.4) < 3, "sc:demo1RouteCurv", ...
    ['curvature at s=511 m no longer reads ~63 m radius (got %.1f m) - the ' ...
     '"sharpest real bend" claim behind this file''s sharpturn hazard needs re-checking.'], ...
    rSharp);

% sharpturn's SpeedCap is DERIVED from the measured radius, not hardcoded -
% same "one source for one number" discipline as sc.s1geom. aLat is a
% common rural-road comfort/safety lateral-acceleration rule of thumb
% (S1's own spec gives no speed for this curve at all).
aLat = 1.5;                                          % m/s^2, chosen, disclosed
vSharp = sqrt(aLat * rSharp);                         % ~9.75 m/s, ~35 km/h

% ---------------------------------------------------------------- the 22 km/h breaker fact
% Spec's own action script: "Speed breaker at 268 m ... Down to 22 km/h,
% over, accelerate." Converted directly, not rounded up front, so the
% number in the struct matches the number a unit test would recompute.
vBreaker = 22/3.6;                                    % = 6.111 m/s

mk = @(typ,stn,lat,lbl,rad,cap,zon) struct( ...
    'Type',     string(typ), ...
    'Station',  double(stn), ...
    'Lateral',  double(lat), ...
    'Label',    string(lbl), ...
    'Radius',   double(rad), ...
    'SpeedCap', double(cap), ...
    'Zone',     double(zon));

hz = [ ...

... % ---- start-of-road speed marker (CHOSEN placement/value - no real sign in the spec) ----
mk("speedsign", 5, 0.0, ...
   "Speed limit sign, road start (placed for this demo - S1 gives no real sign here): general rural-tertiary limit, 40 km/h.", ...
   0, 40/3.6, 0), ...

... % ---- three scattered early potholes: real stations, chosen lateral/radius ----
mk("pothole", 34, 0.3, ...
   "Pothole, ~0.5 m across - first of the nine, early and isolated, plenty of clear road either side.", ...
   0.25, NaN, 0), ...

mk("pothole", 88, -0.5, ...
   "Pothole, ~0.3 m across - paired with another only 1 m ahead at 89 m (the spec's own 'clustered, not spaced').", ...
   0.15, NaN, 0), ...

mk("pothole", 89, 0.6, ...
   "Second pothole of that close pair, ~0.35 m across, 1 m past the last one - still easy to place a wheel between them.", ...
   0.175, NaN, 0), ...

... % ---- a lone pothole, off the driven line, taken at cruise ----
... % LABEL CORRECTED 7 Sep 2026. It used to read "steer around it, no need to
... % slow", which promised a lateral dodge the car does NOT perform: measured
... % off the run, it passes at +0.35..+0.45 m lateral (i.e. straight) and
... % 51.8 km/h. A label describing behaviour the demo does not show is the one
... % kind of wrong that cannot be recovered from live - a judge reads it and
... % watches the car ignore it.
... % WHY THE DODGE IS NOT BUILT, rather than simply unlabelled: it was tried.
... % Injecting the hole as a static track (sih.planner's only channel for
... % "something is there") does produce a real ~1.5 m lateral shift - but it
... % also brakes 52 -> 5.5 km/h and clears by about a centimetre, sitting in
... % EMERGENCY throughout, because a track means "obstacle" and obstacles mean
... % brake. There is no "minor surface defect, ease around it" concept in the
... % planner. Building one is real planner work, not a route-file change.
mk("pothole", 141, 1.6, ...
   "Lone pothole, ~0.8 m across, sitting off the driven line - clear road either side, so it is taken at cruise without a deviation.", ...
   0.4, NaN, 0), ...

mk("pothole", 196, -0.8, ...
   "Pothole, ~0.45 m across - another lone one, well clear of anything else, before the real cluster ahead.", ...
   0.225, NaN, 0), ...

... % ---- the tight, real, un-dodgeable cluster: 240/241/243, 1-2 m apart ----
mk("pothole", 240, -0.3, ...
   "Pothole cluster, 1 of 3 - 240/241/243 m sit only 1-2 m apart: too tight to thread through, slow and roll over all three.", ...
   0.3, 4.0, 0), ...

mk("pothole", 241, 0.4, ...
   "Pothole cluster, 2 of 3 - ~0.9 m across, the biggest of the nine, offset to the other side of its neighbours so no straight line clears all three.", ...
   0.45, 4.0, 0), ...

mk("pothole", 243, -0.2, ...
   "Pothole cluster, 3 of 3 - last of the trio, right before the speed breaker: stay slow through the exit too.", ...
   0.275, 4.0, 0), ...

... % ---- the unsigned speed breaker, real station and real IRC 99 length ----
mk("breaker", 268, 0.0, ...
   "Speed breaker, IRC 99 profile, black-and-white bands worn - NO advance warning sign, exactly as the real one is. Down to ~22 km/h over it.", ...
   0, vBreaker, 3.7), ...

... % ---- the ninth pothole - lands during the cow encounter, per the spec's own numbers ----
mk("pothole", 302, 1.0, ...
   "Pothole, ~0.7 m across - right in the middle of the cow encounter (she's at 300 m): one more thing to track while creeping past her.", ...
   0.35, NaN, 0), ...

... % ---- the village edge: real 330-410 m span, chosen SpeedCap ----
mk("slowzone", 330, 0.0, ...
   "Village edge ahead, 330-410 m: mud-walled kutcha huts, a dairy yard, children on the verge - hold to ~30 km/h through here.", ...
   0, 8.0, 80), ...

... % ---- advisory sign ahead of the real sharp turn (CHOSEN placement, posts the curve's own derived cap) ----
mk("speedsign", 490, 0.0, ...
   "Curve-ahead advisory sign (placed for this demo, 21 m out): posts the same speed the bend itself requires, ~35 km/h.", ...
   0, vSharp, 0), ...

... % ---- the one real sharp turn: measured, not authored ----
mk("sharpturn", sSharp, 0.0, ...
   sprintf(['Sharp bend, radius ~%.0f m - the sharpest real curve on this road, measured from the ' ...
            'actual route geometry, not authored. Slow for it, ~35 km/h.'], rSharp), ...
   0, vSharp, 25) ...

];
end
