function hz = demo2Route()
%DEMO2ROUTE  The static hazard list for Demo 2 - S1, THE CATTLE CROSSING, road-damage stress test.
%
%   hz = sc.demo2Route()    zero arguments, by design: this is a PRECOMPUTED, static list,
%   built once and handed straight to
%       sc.plannerView('init', struct(..., 'Hazards', hz))
%   the same way plannerView's own header already documents the Hazards field, and the same
%   zero-argument pattern sc.demo1Route uses. This file does not touch the ego, the planner,
%   or run time - it is scenery data, nothing else.
%
%   THE COW IS NOT IN HERE, ON PURPOSE - same reasoning as sc.demo1Route's header, repeated
%   because it matters: the cow is a REAL, EXISTING actor, already fully wired through
%   W.CowStation (sc.s1world, = 300.0 m) -> sc.s1actors -> sc.s1geom (the actual gap
%   arithmetic: free width 3.83 m, margin 0.965 m each side). "cow" is not one of this
%   struct's 7 allowed Type values, and it should not be. Everything below is the STATIC
%   road-surface furniture laid AROUND her - potholes, the breaker, broken-surface stretches,
%   a couple of edge failures, two real bends. Nobody should read this file and conclude the
%   cow got dropped; she was never this file's job.
%
%   DEMO 2 vs DEMO 1, WHAT ACTUALLY DIFFERS AND WHY (read sc.demo1Route first if you haven't -
%   it is the showcase this file is deliberately harder than):
%   Demo 1 paces potholes with generous clean gaps between them (its own header: "~50 m gap
%   to the one truly ISOLATED, dodge-able pothole at 141", "a long quiet stretch" before its
%   advisory sign). Demo 1's job is to show the planner handling each hazard TYPE cleanly, one
%   at a time, with recovery room. Demo 2's job is the opposite: it is the SAME real 610 m
%   road (the potholes and the breaker exist on it regardless of which demo is driving it, so
%   they appear here at the identical real stations), but this file fills every gap Demo 1
%   would have left clean with broken-surface "damage" stretches, so there is never a clear
%   line, never a calm moment to recover in, before the next thing.
%   Concretely, differing FROM Demo 1 on purpose:
%     - the 141 m pothole is Demo 1's "steer around it, no need to slow" beat. Here it sits
%       inside back-to-back damage zones on both sides (96-134 and 150-188) - there is no
%       clean stretch left around it at all.
%     - Demo 1's village edge (330-410) is a calm "slowzone" - the one deliberate recovery in
%       that file. Here the village gets a "damage" zone instead (350-410): a potholed lane
%       past the huts, not a breather.
%     - Demo 1 uses ONE sharp turn (511 m) and skips the gentler 203 m / 429 m bends "one
%       sharp-turn beat is what the pacing calls for, not three". This file uses BOTH real,
%       tighter bends (203 m and 511 m) - the two the project's own measurement flagged as
%       "genuine, not gentle" - because two capped corners with no warning is exactly the
%       kind of thing that should be harder.
%     - Demo 1 posts TWO advisory speedsigns (road start, and 21 m ahead of its turn) and a
%       calm village slowzone - three chances to see something coming. This file posts NONE.
%       That is not an oversight: S1's own spec says the real speed breaker at 268 m has "no
%       advance sign - the Indian reality", and this file extends that same reality to every
%       hazard in it. Less warning is what makes a stress test a stress test.
%     - potholes here mostly carry a real SpeedCap (Demo 1 only caps its 240/241/243
%       cluster). That is deliberate: in Demo 1 most potholes are dodge-able at speed, so a
%       cap would be make-believe; here almost none of them are (they all sit inside or hard
%       against a damage zone), so a real "you have to slow for this one too" cap is honest,
%       not decoration.
%
%   REAL VS CHOSEN, SAID PLAINLY (same discipline as sc.s1geom / sc.s10Route / sc.demo1Route):
%   REAL, MEASURED, NOT MINE TO CHANGE:
%     - the route itself: sc.localRoads([-280 450],350) -> sc.routeFrom(..., 'classes',
%       "tertiary") -> sc.path(centre,1.0) is EXACTLY what sc.s1world.m (and sc.demo1Route)
%       build. Rebuilt here, once, cheaply, purely so the asserts below catch drift.
%     - route length: 610.13 m (asserted below).
%     - the 9 pothole stations: 34, 88, 89, 141, 196, 240, 241, 243, 302 m, and the speed
%       breaker station: 268 m - literal chainages out of scenarios/S1-CATTLE-CROSSING.md
%       ("9 potholes ... at 34, 88, 89, 141, 196, 240, 241, 243, 302 m", "Speed breaker at
%       268 m"). Same nine, same one, as Demo 1 - it is the same road.
%     - pothole diameters: spec gives a RANGE for the nine as a set (0.25-0.9 m across, i.e.
%       radius 0.125-0.45 m), not a per-pothole value. This file's individual Radius values
%       are its own pick within that measured range - disclosed as chosen, not measured
%       per-pothole (Demo 1 makes the identical disclosure, and picked different individual
%       values - neither file's per-pothole size is "the" real one, because the spec never
%       gave one).
%     - "three patched with darker fresh mix": spec gives a COUNT, not which three. This file
%       treats 89, 241 and 302 as the patched ones (smaller radius, a rim already lifting) -
%       an arbitrary, disclosed pick among the nine, same as Demo 1 had to make one too.
%     - breaker geometry: IRC 99, 3.7 m long - Zone for the breaker entry below is that real
%       length, matching plannerView's own drawHazard bandDepth, not an invented one. Its
%       SpeedCap (22 km/h) is taken directly from the spec's own action timeline: "Speed
%       breaker at 268 m ... Down to 22 km/h, over, accelerate" - a real scripted number, not
%       derived or guessed.
%     - the two sharp bends used here, s~203 m (R~73 m) and s~511 m (R~63 m): genuine
%       OSM-derived curvature, RE-MEASURED below via P.curvature(), not authored. The third
%       real bend at s~429 m (R~114 m) is confirmed gentler and is not used - not because it
%       isn't real, but because it genuinely is a softer curve than the other two.
%     - village edge: spec's own "330-410 The village edge" (LEFT SIDE, metre by metre),
%       mud boundary wall then two kutcha huts.
%   CHOSEN BY THIS FILE, DISCLOSED AS SUCH (spec gives no data for any of these - there is no
%   real sign inventory, no per-pothole lateral position, no posted speed limit anywhere in
%   S1, and no authored "how long is a damage patch" figure to borrow):
%     - every Lateral (placement across the lane of each pothole / edge-failure / barrier)
%     - every "damage" zone's start station and length (Zone) - this is this file's entire
%       reason to exist: turning the real recovery gaps Demo 1 leaves clean into broken
%       road. Grounded in the spec's own general surface texture ("mid-grey dusty bitumen,
%       aggregate showing in the wheel paths ... Edges crumble into dirt over a ragged
%       100-300 mm band. No kerb"), but the exact extents are authored, not measured - the
%       spec gives that texture for the road as a whole, not metre-by-metre damage limits.
%     - the barrier and slowzone placements, and every SpeedCap that isn't the breaker's
%       22 km/h or a sharpturn's derived value (formula/reasoning given inline, at each
%       hazard, below).
%     - deliberately-left-clean gaps of 5-15 m between damage zones (see PACING below).
%
%   STATION/ZONE CONVENTION - same as sc.demo1Route (the frozen contract doesn't fix one, so
%   both files need to agree, and this is the one Demo 1 already picked): Station is the
%   LEADING EDGE of a hazard - where it first becomes relevant. Zone, when nonzero, is the
%   length of affected road measured FORWARD from Station. Point hazards (every pothole, the
%   barrier) carry Zone = 0. For Type "sharpturn", Radius carries the bend's real turn
%   radius in metres (not a pothole size) and Zone is this file's own authored estimate of
%   the driven extent of the curve - P.curvature() gives radius AT a station, not the length
%   of the tight arc, and (checked below) its near-constant-radius plateau at both real bends
%   here happens to run about 22-24 m, which is partly an artifact of the method's own 25-
%   sample smoothing window, not a clean physical curve length - so Zone=22 at both turns
%   below is a round, disclosed estimate in that same ballpark, not a claimed second
%   measurement (same discipline sc.demo1Route uses for its own sharpturn Zone).
%
%   PACING - WHY THE GAPS FALL WHERE THEY DO, AND WHY THEY ARE SMALL: this file does NOT
%   damage literally every metre of the 610 m - a perfectly continuous ragged strip start to
%   finish would read as authored padding, not a real road, and the spec's own texture
%   ("worn to about 60 %", not "destroyed") does not support that either. Instead, every gap
%   LEFT clean between hazards below is 15 m or under, deliberately too short to be a real
%   breather at any speed this ego drives at in S1 (52 km/h cruise = 14.4 m/s, so even a
%   15 m gap is one second) - a "gap" here reads as "the tarmac happens to be intact for a
%   moment", not "you can relax". The two exceptions, both disclosed:
%     - 304-350 m is left with NO hazard entry at all. This is the cow's own ground (she is
%       at 300 m; the auto-rickshaw abort/retake plays out through here per S1's action
%       timeline). Layering fabricated road damage on top of the scenario's single biggest
%       event would dilute the cow encounter, not intensify the stress test - so this file
%       deliberately leaves that stretch to her, exactly as sc.demo1Route's own header notes
%       its pothole at 302 "lands DURING the cow encounter... not this file's choice".
%     - 410-500 m and 522-610 m (~35-38 m each) are real, comparatively intact road - even a
%       stress-test run should not fabricate damage where none is textured in the spec, and
%       every OTHER real feature in this stretch (the second sharp bend and its own edge
%       failure at 500-522) is still used. One extra authored patch (445-475) keeps even this
%       calmer back half from reading as a full recovery.

% ---------------------------------------------------------------- verify against the real route
% Rebuilt exactly as sc.s1world.m (and sc.demo1Route) build it - see header. Cheap, and it
% buys a loud failure the moment the map data, or this route's own geometry, drifts out from
% under these hand-picked stations.
R = sc.localRoads([-280 450], 350);
centre = sc.routeFrom(R, [-496.1 654.1], [-12.8 300.2], 'classes', "tertiary");
P = sc.path(centre, 1.0);
assert(abs(P.Len - 610.13) < 0.05, "sc:demo2RouteLen", ...
    ['S1 route length has drifted to %.2f m (expected ~610.13 m) - every station number in ' ...
     'this file is keyed to the ORIGINAL measured route.'], P.Len);

k = P.curvature();
sBend1 = 203; sBend2 = 511;                          % real, measured peaks - see header
iB1 = max(1, min(numel(k), round(sBend1/P.Step)+1));
iB2 = max(1, min(numel(k), round(sBend2/P.Step)+1));
rBend1 = 1/k(iB1);
rBend2 = 1/k(iB2);
assert(abs(rBend1 - 72.8) < 3, "sc:demo2RouteCurv1", ...
    ['curvature at s=203 m no longer reads ~73 m radius (got %.1f m) - the "genuine bend" ' ...
     'claim behind this file''s first sharpturn hazard needs re-checking.'], rBend1);
assert(abs(rBend2 - 63.4) < 3, "sc:demo2RouteCurv2", ...
    ['curvature at s=511 m no longer reads ~63 m radius (got %.1f m) - the "sharpest real ' ...
     'bend" claim behind this file''s second sharpturn hazard needs re-checking.'], rBend2);

% Both sharpturn SpeedCaps use the SAME comfort lateral-acceleration rule of thumb as
% sc.demo1Route's own sharpturn entry (aLat = 1.5 m/s^2, chosen, disclosed, not tyre-tested;
% S1's own spec gives no posted speed for either curve). Using the identical formula/constant
% Demo 1 uses for the SAME 511 m bend is deliberate - two files describing one real road
% should not derive two different "safe" speeds for the same physical corner.
aLat = 1.5;                                          % m/s^2, chosen, disclosed
vBend1 = sqrt(aLat * rBend1);                        % ~10.45 m/s, ~38 km/h
vBend2 = sqrt(aLat * rBend2);                        % ~9.75 m/s, ~35 km/h - matches demo1Route

% ---------------------------------------------------------------- the 22 km/h breaker fact
% Spec's own action script: "Speed breaker at 268 m ... Down to 22 km/h, over, accelerate."
% Converted directly, not rounded up front, same as sc.demo1Route.
vBreaker = 22/3.6;                                   % = 6.111 m/s

% ---------------------------------------------------------------- the broken-surface cap
% TODO(unverified): vDamage is a DESIGN CHOICE, not a measured figure, and
% nothing in this repository or in S1's own spec states a speed for driving on
% continuously broken tarmac. It was added 7 Sep 2026 after a verification run
% found that all eleven damage entries here carried SpeedCap = NaN, so the
% "road damage stress test" drove its own damage at 12.72-14.38 m/s - within a
% whisker of the 14.44 m/s route cruise - wherever no pothole or slow zone
% happened to overlap.
%
% WHAT MAKES 8.33 m/s (30 km/h) DEFENSIBLE IS THE ORDERING, NOT THE VALUE. It
% is anchored to this project's OWN existing numbers, not to an outside source:
%
%     potholes           4.00 - 6.94 m/s   a specific deep hole to place a wheel around
%     speed breaker      6.11 m/s
%     >>> broken surface 8.33 m/s <<<      continuous degraded tarmac
%     village slow zone  8.00 m/s (demo1)
%     bends              9.75 - 10.45 m/s
%     open road          14.44 m/s
%
% A continuous degraded surface should be slower than open road and FASTER
% than a specific hole you must avoid; that ordering is the argument. The
% precise value is chosen to sit just above demo1's own village zone. If a
% real figure for this is ever measured, it replaces this one.
vDamage = 30/3.6;                                    % = 8.333 m/s - CHOSEN, see above

% SHOULDER damage (Lateral +3.40/+3.80 below) deliberately keeps SpeedCap NaN.
% Those entries take away LATERAL ROOM - they do not degrade the surface the
% wheels are actually on - and demo_play's corridorFrom already narrows the
% drivable band for them. Capping speed there too would model one constraint
% twice and slow the car for a hazard it has already steered clear of.

mk = @(typ,stn,lat,lbl,rad,cap,zon) struct( ...
    'Type',     string(typ), ...
    'Station',  double(stn), ...
    'Lateral',  double(lat), ...
    'Label',    string(lbl), ...
    'Radius',   double(rad), ...
    'SpeedCap', double(cap), ...
    'Zone',     double(zon));

hz = [ ...

... % ================================================================ 0-88 m: first pothole, first damage stretch
mk("pothole", 34, 0.4, ...
   "Pothole, ~0.55 m across - first of the nine. Only 10 m of decent road left before the surface starts breaking up for good.", ...
   0.275, 25/3.6, 0), ...

mk("damage", 44, 0.0, ...
   "Broken surface starts here and runs 38 m - aggregate showing through in both wheel paths. No clean line before the next pair of potholes at 88/89 m.", ...
   0, vDamage, 38), ...

... % ================================================================ 88-96 m: the close pair
mk("pothole", 88, -0.6, ...
   "Pothole, ~0.70 m across, one of a close pair with the one 1 m ahead at 89 m - and the broken surface just behind gives no clean run-up to either.", ...
   0.35, 23/3.6, 0), ...

mk("pothole", 89, 0.5, ...
   "Second of the pair, ~0.30 m across, patched with darker fresh mix - the patch is already cracking at the rim.", ...
   0.15, 20/3.6, 0), ...

... % ================================================================ 96-141 m: no clean stretch left before/around the isolated pothole
mk("damage", 96, 0.0, ...
   "38 m of worn, crumbling patches straight through to the pothole at 141 m. In the calmer run this is a clear stretch - not here.", ...
   0, vDamage, 38), ...

mk("pothole", 141, 1.3, ...
   "Pothole, ~0.85 m across - the largest yet, and boxed in by broken surface on both sides, so there is no clear road either side to stay at speed on.", ...
   0.425, 20/3.6, 0), ...

... % ================================================================ 150-198 m: leading into the bend
mk("damage", 150, 0.0, ...
   "Worn, crumbling patches the rest of the way to the pothole at 196 m.", ...
   0, vDamage, 38), ...

mk("pothole", 196, -0.9, ...
   "Pothole, ~0.40 m across, right where the shoulder itself is starting to crumble away.", ...
   0.20, 20/3.6, 0), ...

... % ================================================================ 198-245 m: the real bend, broken surface under it, then the crumbling shoulder into the cluster
mk("damage", 198, 0.0, ...
   "Broken surface runs right through the bend ahead and on into the 240-243 pothole cluster - the turn gets no benefit of clean tarmac under it.", ...
   0, vDamage, 38), ...

mk("sharpturn", 203, 0.0, ...
   sprintf(['Genuine bend, radius about %.0f m - real route geometry, not authored. Comfortable cornering ' ...
            'speed here is about %.0f km/h, and (see the damage zone) the surface under the turn is ' ...
            'breaking up too.'], rBend1, vBend1*3.6), ...
   rBend1, vBend1, 22), ...

mk("barrier", 226, 3.8, ...
   "Roadside hazard marker - the shoulder has caved in here, the edge drops straight into the borrow ditch.", ...
   0, NaN, 0), ...

mk("damage", 225, 3.4, ...
   "Shoulder crumbling into dirt over a ragged band here, no kerb - with the pothole cluster right ahead, there is nowhere on the left to bail out to.", ...
   0, NaN, 20), ...

mk("slowzone", 234, 0.0, ...
   "Pothole cluster plus a crumbling edge, together - not a recovery, a mandatory crawl. There is no clean line through here, only a lower cap to survive it.", ...
   0, 4.5, 18), ...

... % ================================================================ 240-266 m: the tight, un-dodgeable cluster, then straight into the breaker
mk("pothole", 240, -0.4, ...
   "Pothole cluster, 1 of 3, ~0.90 m across - the largest of the nine. 240/241/243 sit only 1-2 m apart: too tight to thread, slow and roll over all three.", ...
   0.45, 4.0, 0), ...

mk("pothole", 241, 0.5, ...
   "Pothole cluster, 2 of 3, ~0.35 m across, patched - offset from its neighbours so no straight line clears all three.", ...
   0.175, 4.0, 0), ...

mk("pothole", 243, -0.3, ...
   "Pothole cluster, 3 of 3, ~0.60 m across - right before the breaker, and the crumbling edge from 225 m is still running here too.", ...
   0.30, 4.0, 0), ...

mk("damage", 246, 0.0, ...
   "Broken surface closes right up against the speed breaker ahead - no clean approach to it either.", ...
   0, vDamage, 20), ...

mk("breaker", 268, 0.0, ...
   "Speed breaker, IRC 99 profile, worn black-and-white bands - NO advance warning sign, exactly as the real one has none. Down to ~22 km/h over it.", ...
   0, vBreaker, 3.7), ...

... % ================================================================ 272-304 m: past the breaker, into the cow's own ground
mk("damage", 272, 0.0, ...
   "Broken surface continues past the breaker toward the cattle-crossing clearing - no smooth patch before the cow at 300 m.", ...
   0, vDamage, 32), ...

mk("pothole", 302, 1.1, ...
   "Pothole, ~0.45 m across, patched, right at the edge of the cattle-crossing clearing - one more thing to track while dealing with her.", ...
   0.225, 18/3.6, 0), ...

... % ================================================================ 304-350 m deliberately left clean - the cow's own ground, see header
... % ================================================================ 350-410 m: village edge, damage instead of Demo 1's calm slowzone
mk("damage", 350, 0.0, ...
   "Potholed lane past the huts - worn patches and crumbling edges continue well past the village edge. Unlike the calmer run's village slow zone, this run gives no clean recovery even past the houses.", ...
   0, vDamage, 60), ...

... % ================================================================ 410-522 m: the calmer back half - still not fully clean
mk("damage", 445, 0.0, ...
   "Another worn, aggregate-exposed patch - even the quieter back half of this road doesn't stay clean for long.", ...
   0, vDamage, 30), ...

mk("damage", 500, 3.4, ...
   "Shoulder crumbling right through the sharpest bend on the whole road - no margin left to dodge onto, mid-curve, with an edge like this.", ...
   0, NaN, 22), ...

mk("sharpturn", 511, 0.0, ...
   sprintf(['The sharpest genuine bend on this route, radius about %.0f m, measured from the real ' ...
            'route geometry. Comfortable cornering speed here is about %.0f km/h - and unlike the ' ...
            'calmer run, nothing warns you it is coming.'], rBend2, vBend2*3.6), ...
   rBend2, vBend2, 22), ...

... % ================================================================ 560-595 m: one last patch before the road runs out
mk("damage", 560, 0.0, ...
   "One last stretch of broken tarmac before the road runs out - same worn, aggregate-exposed surface as the rest of this road, right to the end.", ...
   0, vDamage, 35) ...

];

% ---------------------------------------------------------------- sanity checks on the shape
allTypes = ["pothole" "breaker" "barrier" "damage" "speedsign" "slowzone" "sharpturn"];
assert(all(ismember([hz.Type], allTypes)), "sc:demo2RouteType", ...
    "a hazard here uses a Type outside the frozen contract's 7 allowed values.");
assert(sum([hz.Type]=="pothole") == 9, "sc:demo2RoutePotholeCount", ...
    "S1's own spec gives exactly 9 potholes - this file no longer has 9 pothole entries.");
assert(sum([hz.Type]=="breaker") == 1, "sc:demo2RouteBreakerCount", ...
    "S1's own spec gives exactly 1 speed breaker - this file no longer has 1 breaker entry.");
ends = [hz.Station] + max([hz.Zone], 0);
assert(all(ends < P.Len), "sc:demo2RouteOOB", ...
    "a hazard (station + zone) extends past the real route length (%.2f m).", P.Len);
end
