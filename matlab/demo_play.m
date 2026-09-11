function R = demo_play(route, opts)
%DEMO_PLAY  The live SIH26037 demo: the REAL planner driving a real route, in a
%   real MATLAB window, at natural speed, with pause-to-narrate.
%
%   demo_play                      % Demo 1, natural speed
%   demo_play("demo2")             % Demo 2 - the broken-carriageway stress test
%   demo_play("demo1", Recompute=true)   % re-run the planner, ignore the cache
%   demo_play("demo1", Cow="blocking")   % reproduce the known cow freeze
%   demo_play("demo1", Live=true)        % plan and draw in the same loop
%
%   CLOSE OTHER HEAVY PROCESSES BEFORE PRESENTING. Across six full runs the
%   MEDIAN frame cost was rock steady at 3.1-7.4 ms; what moves is the TAIL.
%   p95 measured anywhere from 10 ms to 241 ms depending on what else the
%   machine was doing, and playback landed between 4% and 36% slower than real
%   time - on the same code, on both scenarios, in both orders. An early guess
%   that this was "the second scenario in a session" was WRONG and is recorded
%   here so nobody acts on it: a later run had demo1 slow FIRST and demo2 fast
%   second. It is machine load, not scenario order. Nothing here needs a
%   restart; it needs the other MATLAB sessions and renders shut down.
%
%   KEYS, live in the window:   SPACE pause/resume   -> or N step one frame   Q quit
%
%   =====================================================================
%   WHY IT COMPUTES FIRST AND PLAYS AFTER (measured, not assumed)
%   =====================================================================
%   Two things were benchmarked on 7 September 2026 before a line of this was
%   written, because the whole demo rests on them:
%
%     1. CAN A LIVE FIGURE ANIMATE FOR FIVE CONTINUOUS MINUTES?  Yes - but only
%        if every graphics object is REUSED via set(). Measured over 6000 frames
%        paced at 20 Hz (a full 5 minutes): 4.6 ms of work per frame, 219 fps
%        sustainable, no frame-time drift, no memory growth. The delete-and-
%        replot pattern the view used before measured 224 ms/frame - 4.5 fps -
%        with a worst frame of 19.3 s and +86 MB in 1200 frames. sc.plannerView
%        was rewritten to the first pattern; its header carries the numbers.
%
%     2. CAN THE PLANNER ITSELF RUN AT 20 Hz?  No. sc.planSeat calls
%        planContingency (35 candidates, capsule-checked) and sc.adapterS9Real,
%        whose sight term ray-marches against this world's ~2200 occluders every
%        single step. That is nowhere near a 50 ms budget.
%
%   Those two facts together decide the architecture. Running the planner inside
%   the draw loop would give a car that crawls at the planner's rate, which is
%   exactly the "crawling car looks broken" failure this demo must not have. So:
%   the planner runs ONCE, ahead of time, and the result is cached; the demo then
%   plays that recording back at the true DT with a real clock. The maths is the
%   real planner's - nothing is faked or scripted - it just is not being computed
%   in the same second it is watched. Live=true runs both in one loop if you ever
%   want to prove that on demand; it is slow, and that is the point of not
%   shipping it as the default.
%
%   =====================================================================
%   WHAT MAKES THE CAR OBEY A HAZARD  (tier 2)
%   =====================================================================
%   Each hazard carries a SpeedCap and a Zone (the frozen contract - see
%   sc.plannerView's header). This applies them in the SEAT, alongside - never
%   inside - sih.planner.speedLimit:
%
%       cmd.v  =  min( trunk's ask,  speedLimit(S9),  hazard cap )
%
%   which is the same "tightest term wins" arbitration speedLimit itself uses.
%   It is applied OUT HERE ON PURPOSE. speedLimit.m's own header states its law
%   has exactly three terms, that a fourth "would put a number in the plan that
%   no document asks for", and says to raise it rather than assume it. So the
%   tested law is left untouched and the hazard term sits visibly beside it, in
%   the demo seat, where the panel can name which hazard is binding.
%
%   The cap is applied from a BRAKING LEAD-IN ahead of the hazard, not at its
%   edge - (v^2 - cap^2)/(2*aComfort) - so the car slows down BEFORE the speed
%   breaker and recovers after it, which is what makes it read as driving rather
%   than as a number changing.
%
%   A barrier or a broken stretch does something different and stronger: it
%   NARROWS THE CORRIDOR. planSeat already reads ctx.ELo / ctx.EHi as overrides
%   for the lateral bounds it clamps to (they exist for Phase 6/8), so a hazard
%   occupying part of the carriageway takes that band away and the real planner
%   plans around what is left. No file of anyone else's is edited to do it.
%   A LIVE barrier is the one special case: changing a scalar bound after the
%   ego is already inside the blocked band invalidates its present pose. The
%   live adapter therefore removes blocked terminal offsets, adds the
%   max-clearance line to the real candidate fan, and holds that candidate as
%   a commitment while planContingency continues to solve each planning cycle.
%
%   =====================================================================
%   TIER 3, TESTED AND ANSWERED: POTHOLES ARE SLOW-THROUGH, NOT DODGED
%   =====================================================================
%   The open question was whether the real planner would cleanly dodge ONE
%   isolated pothole with no other traffic around - the cow failure having been
%   blamed on simultaneous oncoming traffic, which is absent here. It was
%   actually tried, on sc.demo1Route's own isolated pothole (s = 141 m,
%   e = +1.6 m, 0.8 m across, presented to the planner as a static track, which
%   is sih.planner's only channel for "something is there"):
%
%       ego lateral while alongside   +0.26 .. +0.45 m   (from a +1.75 m line)
%       speed while alongside          1.54 .. 5.74 m/s  (cruise is 14.44)
%
%   So it DOES steer - a real 1.5 m lateral shift, ending at +0.29 m against a
%   hole spanning +1.20..+2.00 m, which clears by about a centimetre. But it
%   pays for it by braking from 52 km/h to 5.5 km/h, and it sits in EMERGENCY
%   the whole way in. A 0.8 m hole is not a reason to nearly stop, and a
%   one-centimetre margin is not a clean dodge. The pre-decided fallback stands:
%   POTHOLES ARE PRESENTED AS SLOW-THROUGH ONLY. They are not injected as
%   tracks; they impose their SpeedCap and nothing else, which is what the code
%   below already does. This paragraph is the record of the test, so nobody
%   spends the night on it again.
%
%   =====================================================================
%   GROUND TRUTH BY DEFAULT - REAL SENSING IS Sensed=true, NOT YET THE DEFAULT
%   =====================================================================
%   BY DEFAULT THE ROAD USERS HANDED TO THE PLANNER ARE GROUND TRUTH.
%   builtinTracks below writes exact poses: no sensor noise, no dropout, no
%   bearing blind spot, no tracker. The planner's DECISIONS are real; what it
%   is deciding ABOUT is given to it. sc.plannerView states this on screen, in
%   the model panel, so it is disclosed to an audience rather than only to
%   whoever thinks to ask.
%
%   Worth recording, because the defect was severe enough elsewhere that this
%   will be doubted later: THIS FILE NEVER TOUCHES sc.buildTrackListSensed.
%   The 7 Sep sensing-harness defect - sensors mounted on the SCRIPTED
%   driver's trajectory, so a diverged planner was scored against a world
%   sensed from where it was not, up to 66 m away, with the S2 track list
%   empty for 11 s - produced S1's -0.623 and S2's -1.123 and never touched
%   any demo1/demo2 figure. Those numbers came through builtinTracks, which
%   that path does not reach. Verified by grep, not assumed.
%
%   Sensed=true WIRES IN sc.senseRig / sc.senseStep (Chat 4, 7 Sep) instead -
%   simulated lidar/radar/near-field-ring + a real trackerGNN, sensing from
%   the EGO'S OWN pose each step inside this loop (builtinPoses supplies the
%   same raw ground truth builtinTracks does, just not yet packaged as a
%   TrackList). It introduces real noise, real dropout and the real bearing
%   blind spot - Phase 5/D9's own finding was that this can turn a structural
%   "frozen but safe" freeze into "makes progress but occasionally misses a
%   hazard and collides", in both S1 and S2's own harnesses, for a genuine,
%   disclosed reason (a track intermittently dropping out mid-maneuver), not a
%   bug. This demo's own traffic/route differ from those harnesses, so its own
%   Sensed=true numbers have to be measured here, not assumed from there.
%   Still false by default: the ground-truth run is the one rehearsed and
%   known-good ahead of presenting; Sensed=true is the honest upgrade path,
%   run and disclosed deliberately, not silently swapped in.
%
%   =====================================================================
%   OWNERSHIP
%   =====================================================================
%   This file and sc.plannerView are Chat 1's. sc.demo1Route / sc.demo2Route are
%   Chat 3's and sc.modelStatus is Chat 2's - all three are called IF PRESENT and
%   fall back cleanly if not, so this never blocks on them and never has to be
%   edited when they land.

arguments
    route (1,1) string = "demo1"
    opts.Live       (1,1) logical = false    % plan inside the draw loop (slow)
    opts.Recompute  (1,1) logical = false    % ignore any cache
    opts.Speed      (1,1) double  = 1.0      % 1.0 = natural speed. NOT slow-motion.
    opts.ViewSpan   (1,1) double  = 60       % m, half-span of the follow camera
    % Anjali profile, this branch: 84.7 ms average, ~130 ms slow region.
    % 3 means 6.67 Hz and leaves measured headroom; 2 (10 Hz) is aggressive.
    opts.PlanEvery  (1,1) double  = 3
    opts.TEnd       (1,1) double  = NaN      % s, override the route's own length
    opts.Sensed     (1,1) logical = false    % sense the traffic via sc.senseRig/senseStep
                                              % (lidar+radar+ring, trackerGNN) instead of
                                              % handing the planner exact ground truth
    opts.Interactive(1,1) logical = true
    opts.Snap       (1,1) string  = ""       % write a frame here and exit
    opts.Cow        (1,1) string  = "blocking" % "blocking" | "verge" | "none"
    opts.InjectStep (1,1) double  = NaN      % automated rehearsal/test hook; UI uses clicks
    opts.InjectXY   (1,2) double  = [NaN NaN]
    opts.WriteResults(1,1) logical = true    % write results/<run>/{trajectories.csv,
                                              % metrics.json, config.json} - AGENTS.md
                                              % section 3. Skipped under Live=true, where
                                              % LOG is never a single reproducible record.
end

here = fileparts(mfilename('fullpath'));
addpath(here);
assert(isfinite(opts.PlanEvery) && opts.PlanEvery >= 1 && opts.PlanEvery == round(opts.PlanEvery), ...
    'demo_play:PlanEvery','PlanEvery must be a positive integer');
assert(~isempty(which('sih.planner.planContingency')), ...
    'sih.planner is not on the path - the +sih repo is not where planSeat expects it');

DT = 0.05;                                    % s, the seat's own step (20 Hz)

% ================================================================= the route
D = loadRoute(route, opts.Cow);
D.Sensed = opts.Sensed;              % must be set before the cache tag/stamp below -
                                      % it changes what the planner sees every step, so a
                                      % Sensed run must never load or overwrite an exact-
                                      % ground-truth cache (or the reverse) - see routeStamp.
if isfinite(opts.TEnd), D.TEnd = opts.TEnd; end
fprintf('\n================ %s ================\n', D.Title);
fprintf('route  %.0f m,  %d hazards,  %.0f s of driving\n', ...
        D.W.Path.Len, numel(D.Hazards), D.TEnd);

% ================================================================= the run
% The cow mode is in the FILENAME, not just the stamp. Both modes are real
% runs somebody may want back; keyed on route alone they overwrite each other,
% and the stamp check would then silently trigger a three-minute recompute the
% next time - which is exactly the wrong thing to discover at 5am.
tag = route;
if opts.Cow ~= "verge", tag = route + "-cow" + opts.Cow; end
if opts.Sensed, tag = tag + "-sensed"; end
cacheFile = fullfile(here, 'renders', sprintf('demo_%s.mat', tag));
if opts.Live
    LOG = [];                                  % computed inside the draw loop
elseif ~opts.Recompute && isfile(cacheFile)
    L = load(cacheFile);
    [LOG, why] = useCache(L, D, DT, opts.PlanEvery);
    if isempty(LOG)
        fprintf('%s - recomputing\n', why);
        LOG = runPlanner(D, DT, opts.PlanEvery);
        LOG.Stamp = routeStamp(D);
        saveCache(cacheFile, LOG);
    else
        fprintf('%s\n', why);
    end
else
    LOG = runPlanner(D, DT, opts.PlanEvery);
    LOG.Stamp = routeStamp(D);
    saveCache(cacheFile, LOG);
end

% ================================================================= the evidence
% "A number without its config is not a result" - AGENTS.md section 3. Written
% for every run that has a real LOG, cache hit or not - a cached run is still a
% real, reproducible result, not merely a demo convenience.
if opts.WriteResults && ~opts.Live
    runName = tag + "_" + string(datetime('now','TimeZone','UTC','Format','yyyyMMdd-HHmmss'));
    sih.metrics.writeDemoResults(runName, D, LOG, opts);
end

% ================================================================= play it
R = play(D, LOG, DT, opts);
end

% =========================================================================
%                             ROUTE LOADING
% =========================================================================
function D = loadRoute(route, cowMode)
%LOADROUTE  Chat 3 delivers sc.demo1Route / sc.demo2Route; sc.demo3Route is
%   this file's own (10 Sep). Falls back to a route built here if a Route
%   function is ever absent or errors, so this file is never blocked waiting.
%   DELIBERATELY LIBERAL about what it accepts back: a struct with .W/.Hazards,
%   or a bare hazard array, both work, so no two chats can deadlock over the
%   exact shape of a return value.
fn = "sc." + route + "Route";
if ~isempty(which(char(fn)))
    fprintf('using %s\n', fn);
    try
        got = feval(char(fn));
        D = normaliseRoute(got, route, cowMode);
        return
    catch me
        warning('demo_play:route', '%s errored (%s) - falling back to the built-in route', fn, me.message);
    end
end
fprintf('%s not on the path yet - using the built-in temporary %s route\n', fn, route);
D = builtinRoute(route, cowMode);
end

function D = normaliseRoute(got, route, cowMode)
if isstruct(got) && isfield(got,'W') && isfield(got,'Hazards')
    D = got;
elseif isstruct(got) && isfield(got,'Type')          % a bare hazard array
    % sc.demo1Route / sc.demo2Route / sc.demo3Route all return exactly this:
    % the hazards only. The road and the traffic still come from the built-in
    % route - but the title must say so honestly rather than keep calling
    % itself a stand-in when the real hazards are in fact loaded.
    if route == "demo3"
        D = builtinRouteS3();  D.Hazards = got;
        D.Title = 'SIH26037  DEMO3 - hazards from demo3Route, road from sc.s3world';
    else
        D = builtinRoute(route, cowMode);  D.Hazards = got;
        D.Title = sprintf('SIH26037  %s - hazards from %sRoute, road from sc.s1world', ...
                          upper(route), route);
    end
else
    error('demo_play:badRoute','%s returned something this cannot read', route);
end
D = fill(D, 'Title',  sprintf('SIH26037  %s', upper(route)));
D = fill(D, 'CS',     NaN);
D = fill(D, 'SStart', 20);
D = fill(D, 'TEnd',   90);
D = fill(D, 'Tracks', {});
D = fill(D, 'CruiseV', 52/3.6);
D.Hazards = fillHazards(D.Hazards);
end

function D = builtinRoute(route, cowMode)
%BUILTINROUTE  A TEMPORARY Demo 1, so this file is never blocked on Chat 3.
%   Real road (the Najibabad tertiary centreline sc.s1world already loads), real
%   cow station, and a dense hazard sequence to the frozen contract. Chat 3's
%   sc.demo1Route replaces it the moment it exists - nothing here has to change.
W = sc.s1world();
D.W  = W;
D.CS = W.CowStation;
D.SStart  = 20;
D.CruiseV = 52/3.6;                     % 52 km/h, the route cruise everywhere else uses

if route == "demo2"
    D.Title   = 'SIH26037  DEMO 2 - BROKEN CARRIAGEWAY (temporary stand-in)';
    D.Hazards = [ ...
      hz("speedsign", 70,  4.6, "speed limit 40",              1.6, 40/3.6, 0) ...
      hz("damage",   140,  1.2, "broken carriageway",          3.0, 22/3.6, 26) ...
      hz("damage",   168, -1.4, "broken carriageway",          2.6, NaN,    0) ...
      hz("pothole",  215,  1.5, "pothole",                     1.6, NaN,    0) ...
      hz("barrier",  250,  2.9, "barricade - lane out",        NaN, 18/3.6, 20) ...
      hz("sharpturn",320,  4.8, "sharp bend",                  1.9, 30/3.6, 34) ...
      hz("damage",   400,  0.0, "edge collapse",               3.2, 20/3.6, 24) ...
      hz("slowzone", 470,  4.6, "village - slow zone",         1.0, 25/3.6, 60) ...
      ];
else
    D.Title   = 'SIH26037  DEMO 1 - POTHOLES, BREAKER, COW (temporary stand-in)';
    D.Hazards = [ ...
      hz("speedsign", 60,  4.6, "speed limit 50",              1.6, 50/3.6, 0) ...
      hz("pothole",  120,  1.4, "isolated pothole - dodgeable",1.8, NaN,    0) ...
      hz("breaker",  180,  0.0, "speed breaker",               NaN, 20/3.6, 0) ...
      hz("pothole",  238, -0.8, "pothole cluster",             1.7, 25/3.6, 18) ...
      hz("pothole",  246,  1.3, "pothole cluster",             1.5, NaN,    0) ...
      hz("pothole",  253, -1.6, "pothole cluster",             1.9, NaN,    0) ...
      hz("sharpturn",300,  4.8, "sharp bend ahead",            1.9, 30/3.6, 30) ...
      hz("slowzone", 360,  4.6, "school - slow zone",          1.0, 25/3.6, 55) ...
      hz("barrier",  440,  2.9, "roadworks barricade",         NaN, 20/3.6, 16) ...
      hz("breaker",  500,  0.0, "speed breaker",               NaN, 20/3.6, 0) ...
      ];
end
D.Hazards = fillHazards(D.Hazards);

% HOW LONG TO DRIVE FOR - DERIVED FROM THE ROUTE'S OWN CAPS, NOT GUESSED.
% This has now been got wrong twice, in the same way both times, so it is
% worth stating why it is computed rather than typed:
%   1. The original formula assumed a steady 0.62 * cruise average. With a
%      BLOCKING cow the D9 WAIT rung holds the ego near zero around 286 m, so
%      64 s ended demo1 at 440 m and silently dropped its last two hazards -
%      the run looked complete and was not. That was patched with TEnd = 88.
%   2. Adding vDamage to demo2Route's nine centreline damage entries (7 Sep)
%      slowed the whole route again, and 88 s promptly became too short for
%      exactly the same reason: demo2 reached 489.6 m and silently dropped
%      three more hazards, the sharpest bend on the road among them.
% A hardcoded duration goes stale every time a speed cap changes. So the
% traverse time is INTEGRATED over the route at each station's own binding
% cap. The margin covers accel/decel transitions and any waiting; overshooting
% costs nothing, because runPlanner stops itself the moment it runs out of
% road and truncates the log to what it actually drove.
D.TEnd = estimateDuration(D.Hazards, D.SStart, W.Path.Len, D.CruiseV, cowMode);
nSteps = ceil(D.TEnd/0.05);
D.Tracks = builtinTracks(W, D.CS, cowMode, nSteps, 0.05);
% D.Poses/D.Who/D.DIMS: the SAME three actors, raw (unsensed) - built off the
% identical per-step kinematics as D.Tracks above (see actorSpec/activeActorsAt),
% so the two can never silently disagree about where anything is. Built
% unconditionally, whether or not this run ever uses Sensed=true - it is cheap
% closed-form kinematics, no sensing happens here.
[D.Poses, D.Who, D.DIMS] = builtinPoses(W, D.CS, cowMode, nSteps, 0.05);
end

function h = hz(type, station, lateral, label, radius, cap, zone)
h = struct('Type',string(type),'Station',station,'Lateral',lateral, ...
           'Label',string(label),'Radius',radius,'SpeedCap',cap,'Zone',zone);
end

function H = fillHazards(H)
%FILLHAZARDS  Every field of the frozen contract present on every element, so
%   nothing downstream has to guess whether a field exists.
for k = 1:numel(H)
    if ~isfield(H,'Lateral')  || isempty(H(k).Lateral),  H(k).Lateral  = 0;      end
    if ~isfield(H,'Label')    || strlength(string(H(k).Label))==0
        H(k).Label = string(H(k).Type);
    end
    if ~isfield(H,'Radius')   || isempty(H(k).Radius),   H(k).Radius   = NaN;    end
    if ~isfield(H,'SpeedCap') || isempty(H(k).SpeedCap), H(k).SpeedCap = NaN;    end
    if ~isfield(H,'Zone')     || isempty(H(k).Zone),     H(k).Zone     = 0;      end
end
end

function TR = builtinTracks(W, CS, cowMode, n, DT)
%BUILTINTRACKS  A handful of road users so the road is not empty.
%
%   THE ONCOMING VEHICLES ACTUALLY MOVE, and that was forced by measurement,
%   not taste. A first pass parked them - a car standing at CS+118 m in the
%   OPPOSITE lane at e = -2.0 m, nowhere near the ego's +1.75 m line. Run, the
%   ego drove the whole village slow zone correctly and then FROZE at 413.6 m,
%   4 m short of it, at 0.00 m/s for the last 25 s. planSeat's own barrier
%   (DMin = 2.5 m) does not care which lane a stationary obstacle is in, and
%   nothing in the world was ever going to move out of the way. A parked car
%   in the oncoming lane is not a scenario, it is a wall. Oncoming traffic
%   that oncomes gets approached, passed and left behind, which is both more
%   honest and the thing that does not deadlock.
%
%   Chat 3's routes supply hazards only; if one later supplies scripted
%   traffic, that replaces this whole function.
P = W.Path;
% MEASURED, NOT ASSUMED, TWICE.
%   (1) A first pass parked the auto-rickshaw at CS-130 m in OUR lane at
%       +1.8 m. Running it, the seat sat in EMERGENCY from 159 m onward -
%       correct behaviour (a stationary vehicle in your lane IS an emergency)
%       and a useless demo, because the panel then reads EMERGENCY through the
%       whole pothole section and the hazards stop being the story.
%   (2) The cow's lateral was invented as +0.9 m. sc.s1geom already DERIVES
%       where she stops, from the actual zebu mesh, and asserts the pass margin
%       it leaves is at least 0.90 m. Inventing a second number for something
%       the repo already solves is exactly the bug s1_action_run.m's own header
%       records ("the two disagreed by 0.7 m and the DRIVER was handed the
%       wrong one"). So it is read from sc.s1geom, and she is BROADSIDE -
%       yaw + pi/2 - because that is what makes her length the thing crossing
%       the road, which is the assumption s1geom's arithmetic is built on.
% Chat 3's routes supply hazards only; if one later supplies scripted traffic,
% that replaces this block wholesale.
%   (3) WHERE THE COW STANDS - AND THIS NOTE HAS BEEN OVERTAKEN BY EVENTS,
%       WHICH IS THE POINT OF WRITING THE MEASUREMENT DOWN RATHER THAN THE
%       CONCLUSION.
%       BEFORE Chat 4's D9 WAIT rung merged (commit d5ebdd6): with her
%       BROADSIDE on sc.s1geom's derived stopping line, the planner drove the
%       first eight hazards correctly and then FROZE at 286.1 m - 14 m short
%       of her - at 0.00 m/s for the rest of the run, never reaching the
%       village, the advisory sign or the bend. Reproduced exactly, twice.
%       That was the known go-around failure sih26037-s1-planner-fork
%       diagnosed. It is why the default below is "verge".
%       AFTER that merge: RE-MEASURED off the integrator's own blocking-cow
%       run - 1494 steps, final s = 604.8 m of 610, only 1.8 s spent below
%       0.1 m/s (a real, brief near-stop while passing her, not a freeze).
%       CHAT 4 FIXED IT. The reason for defaulting to "verge" no longer
%       holds, and the default is left alone here only because that is a
%       demo-content decision for the hub chat, not this file's to take:
%       Cow="blocking" is now the better scenario AND it works. Flip it if
%       you want the real S1 encounter on screen.
spec = actorSpec(W, CS, cowMode);
TR = cell(1, n);
for i = 1:n
    t = (i-1)*DT;
    A = activeActorsAt(spec, P, t);
    Ti = emptyTrackList();
    for a = 1:numel(A)
        Ti(end+1) = struct('TrackID',uint32(900+A(a).Row),'ClassID',uint8(A(a).ClassID), ...
            'Position',[A(a).XY 0],'Velocity',A(a).Vel,'Extent',A(a).Extent, ...
            'Yaw',A(a).YawRad,'Existence',1,'Age',uint32(30),'SensorMask',uint8(1)); %#ok<AGROW>
    end
    TR{i} = Ti;
end
end

function spec = actorSpec(W, CS, cowMode)
%ACTORSPEC  The three demo actors (cow/oncoming car/motorcycle) as the
%   {ClassID, s0, lateral, extent, speed along the route (- = oncoming), extra
%   yaw} rows builtinTracks always used - pulled out here so builtinTracks
%   (exact ground truth) and builtinPoses (raw poses for sc.senseStep) read
%   the identical geometry and can never silently disagree about the world.
G = sc.s1geom(W);
switch cowMode
case "blocking"
    cowE = G.CowStopE;   cowYaw = pi/2;    % broadside, in the carriageway
case "none"
    cowE = NaN;          cowYaw = 0;
otherwise
    % On the verge: her NEAR flank sits just outside the carriageway edge, so
    % she is genuinely off the road rather than nudged a little sideways.
    cowE = -(W.Width/2 + G.CowLateral/2 + 0.35);   cowYaw = pi/2;
end
% The cow's extra yaw is pi/2 - BROADSIDE, which is what makes her LENGTH the
% thing crossing the road, and that is the assumption sc.s1geom's whole gap
% arithmetic is built on. Getting it wrong would silently halve her footprint.
spec = { 10, CS,  cowE, [G.CowLateral 0.55 1.35],   0, cowYaw ; ...
          1, 260, -2.0, [4.20 1.75 1.50],       -11.0, 0 ; ...
          5, 610, -1.9, [1.90 0.75 1.30],        -9.0, 0 };
end

function A = activeActorsAt(spec, P, t)
%ACTIVEACTORSAT  Which of actorSpec's rows exist at time t, and where - the
%   exact per-step kinematics both builtinTracks and builtinPoses need. A
%   plain closed-form function of t and spec; nothing here senses anything.
%
%   Columns 7/8 are OPTIONAL and back-compatible: every 6-column spec (S1,
%   S2, S3's own motorcycle) behaves exactly as before - untouched, verified
%   by construction, not just by inspection. If present, spec{k,7} is a
%   lateral TARGET and spec{k,8} is a [t1 t2] time window: the actor's
%   lateral position linearly interpolates from spec{k,3} at t<=t1 to
%   spec{k,7} at t>=t2. This is a SECOND, independent kind of motion from
%   spec{k,5}'s along-route speed, not a replacement for it - S3's child
%   (crosses the road, does not travel along it) and its dog (steps aside,
%   does not travel along it) both need lateral motion with zero along-route
%   speed, which the six-column model had no way to express at all.
A = struct('Row',{},'ClassID',{},'XY',{},'YawRad',{},'Vel',{},'Extent',{});
for k = 1:size(spec,1)
    if ~isfinite(spec{k,3}), continue; end       % Cow="none"
    u = spec{k,2} + spec{k,5}*t;
    if u < 2 || u > P.Len - 2, continue; end     % gone past, or not here yet
    lat = spec{k,3};  latRate = 0;
    if size(spec,2) >= 8 && ~isempty(spec{k,7}) && ~isempty(spec{k,8})
        tw = spec{k,8};  dLat = spec{k,7} - spec{k,3};
        frac = max(0, min(1, (t - tw(1)) / (tw(2) - tw(1))));
        lat = spec{k,3} + dLat*frac;
        if t > tw(1) && t < tw(2), latRate = dLat / (tw(2) - tw(1)); end
    end
    [xy, hdg] = P.at(u, lat);
    yaw = hdg + spec{k,6};  vel = [0 0 0];
    if spec{k,5} < 0
        yaw = hdg + pi;
        vel = spec{k,5}*[cos(hdg) sin(hdg) 0];   % world-frame, as S1 asks
    end
    if latRate ~= 0
        vel = vel + latRate*[-sin(hdg) cos(hdg) 0];   % world-frame, lateral component
    end
    A(end+1) = struct('Row',k,'ClassID',spec{k,1},'XY',xy,'YawRad',yaw, ...
        'Vel',vel,'Extent',spec{k,4}); %#ok<AGROW>
end
end

function [PR, who, DIMS] = builtinPoses(W, CS, cowMode, n, DT)
%BUILTINPOSES  The SAME three actors as builtinTracks, raw - actorPoses(S)-
%   shaped poses for sc.senseStep, not a pre-built S1 TrackList. Nothing here
%   is sensed; this is ground truth, packaged the way sih.scenario.
%   groundTruthTrack/sc.senseStep expect it - the same poses/who/DIMS shape
%   s1_action_run.m already builds off a real actorPoses(S), just built here
%   in closed form since this demo's traffic never used a drivingScenario.
%
%   THE ONE UNIT TRAP: traffic Yaw goes out in DEGREES - groundTruthTrack does
%   its own deg2rad, matching what actorPoses(S) really returns. The ego pose
%   passed separately to sc.senseStep stays in RADIANS (senseStep's own
%   contract). These are NOT interchangeable, and getting it backwards is
%   silent, not an error - the sensed track just carries the wrong heading.
P = W.Path;
spec = actorSpec(W, CS, cowMode);

tags = {'cow','car','moto_wrong'};           % row order matches actorSpec exactly
assert(numel(tags) == size(spec,1), ...
    'demo_play:builtinPosesTagMismatch', ...
    'actorSpec has %d rows but builtinPoses only names %d tags - keep them in step.', ...
    size(spec,1), numel(tags));
who = containers.Map('KeyType','double','ValueType','char');
DIMS = struct();
for k = 1:size(spec,1)
    who(900+k) = tags{k};
    DIMS.(tags{k}) = spec{k,4};
end

PR = cell(1, n);
for i = 1:n
    t = (i-1)*DT;
    A = activeActorsAt(spec, P, t);
    Pi = struct('ActorID',{},'Position',{},'Velocity',{},'Yaw',{});
    for a = 1:numel(A)
        Pi(end+1) = struct('ActorID',900+A(a).Row,'Position',[A(a).XY 0], ...
            'Velocity',A(a).Vel,'Yaw',rad2deg(A(a).YawRad)); %#ok<AGROW>
    end
    PR{i} = Pi;
end
end

% =========================================================================
%                    DEMO 3 - THE GALLI, ITS OWN WORLD AND ACTORS
% =========================================================================
function D = builtinRouteS3()
%BUILTINROUTES3  Demo 3's own route builder - sc.s3world instead of s1world,
%   the oncoming motorcycle instead of the cow/car/moto trio. No dedicated
%   fallback content is needed the way demo1/demo2's builtinRoute has, since
%   sc.demo3Route already exists (this is the loadRoute error-fallback path,
%   only reached if that file is ever missing or errors).
W = sc.s3world();
D.W = W;
D.SStart  = 5;
D.CruiseV = 14/3.6;             % 14 km/h - S3-THE-GALLI.md's own t=0 speed
D.Title   = 'SIH26037  DEMO 3 - THE GALLI (temporary stand-in)';
D.MinCorridor = 0.10;            % this is centreline SLACK, not free width -
                                 % the squeeze's real slack is 0.05 m unfolded
                                 % (1.95 free width - 1.90 m ego) and 0.25 m
                                 % folded (1.95 - 1.70) - 0.10 sits between
                                 % them so unfolded correctly rejects (forcing
                                 % the fold check) and folded correctly passes
D.CorridorLeadIn = 100;          % demo1/demo2's 12 m default made the ego try
                                 % to complete a large lateral move with too
                                 % little road left, and it froze - measured,
                                 % not assumed (see corridorFrom's own header).
                                 % 100 m starts the drift at s~132, well clear
                                 % of the motorcycle encounter (~s=93-100) and
                                 % of the child/dog encounter (clears ~s=127),
                                 % so none of the three interact. TRIED 130 m
                                 % during the misdiagnosis chased in the
                                 % LatOffsets comment below - made things
                                 % WORSE (froze 3.7 m earlier, since the ramp
                                 % then started at s=102, before the child/dog
                                 % encounter even finished) - reverted once the
                                 % real cause turned out to be elsewhere.
D.EgoWidth = 1.90;               % sc.s3geom: mirrors-out baseline. Folding
                                 % (runPlanner's lastCmd.MirrorsFolded check)
                                 % subtracts the same 0.20 m every route uses,
                                 % landing exactly on s3geom's real 1.70 m.
D.EgoStartE = 0.9;               % S1/S2's 1.75 m lane position is outside
                                 % this road's own narrower default corridor
                                 % (measured: [-1.30, 1.65] here vs [-2.55,
                                 % 2.90] on S1's 7.0 m road) - 0.9 is already
                                 % one of runPlanner's own LatOffsets samples,
                                 % comfortably inside. (Tried -0.9 instead, to
                                 % pre-position for the squeeze - that broke
                                 % the motorcycle fix, which was tuned against
                                 % +0.9, and introduced a SECOND freeze of its
                                 % own at s=140. See sc.demo3Route's header for
                                 % why the three lead-up segments no longer
                                 % narrow the corridor at all.)
% NO D.LatOffsets HERE - TRIED AND REVERTED, DISCLOSED RATHER THAN QUIETLY
% DROPPED. S1/S2's 7-value fan [-2.5 -1.585 -0.9 0 0.9 1.75 2.6] was sized
% for their 7.0 m road, where +-0.9 clears +sc/planSeat's own road-edge check
% (roadHalfW - |o| - egoW/2 >= MinClearance_m) with room to spare. On S3's
% 4.5 m road that same check gives 2.25-0.9-0.95 = 0.40 m at o=+-0.9 - BELOW
% the negotiation layer's 0.5 m floor regardless of any actor, traced by
% temporarily instrumenting +sc/planSeat's own iPickPassLine (reverted after,
% not a change to that file) and reading candidate-by-candidate clearances
% directly. That looked, at the time, like the reason the dog (still at -1.0
% then) could never get a real PASS, so a finer route-specific LatOffsets
% grid was added here to give the fan something inside S3's true safe band.
% It DID let that dog placement resolve - but running the full route with it
% in showed the extra candidates ALSO changed which offset the ego settles
% on well before the squeeze (most likely around the motorcycle encounter,
% s~93-100), leaving a small persistent ~0.18-0.2 m residual that never
% fully returns to e=0 - and that residual, not the dog, is what re-broke
% the squeeze approach (identical "blocked ladder is D9" freeze at s=223.6,
% present with EITHER dog placement, absent with neither). Confirmed by A/B:
% removing the finer grid while keeping the dog at -1.65 (below) restores a
% clean run past s=223.6 and into the squeeze; the finer grid was solving a
% problem that the dog fix's own real solution (make o=0 sufficient - see
% actorSpecS3's own header) had already made unnecessary, while quietly
% introducing a worse one elsewhere. Left out on purpose - the working fix
% for the dog/child conflict is entirely in actorSpecS3.m, not here.
D.Hazards = fillHazards(sc.demo3Route());

D.TEnd = estimateDuration(D.Hazards, D.SStart, W.Path.Len, D.CruiseV, "none");
nSteps = ceil(D.TEnd/0.05);
D.Tracks = builtinTracksS3(W, nSteps, 0.05);
[D.Poses, D.Who, D.DIMS] = builtinPosesS3(W, nSteps, 0.05);
end

function spec = actorSpecS3()
%ACTORSPECS3  S3's three live actors. {ClassID, s0, lateral0, extent, speed
%   (- = oncoming), extra yaw, [lateralTarget, [t1 t2]]} - the last two are
%   optional (see activeActorsAt) and only the child/dog use them.
%
%   ROW 1 - THE ONCOMING MOTORCYCLE, ~150 m (S3-THE-GALLI.md: "no room for
%   both, so somebody reverses").
%   LATERAL AND SPEED, MEASURED AGAINST THE REAL FOOTPRINTS, NOT GUESSED
%   TWICE OVER LIKE THE FIRST PASS WAS. Ego 1.90 m wide (sc.s3geom), moto
%   0.75 m wide: combined half-widths need 1.325 m of separation before they
%   ever have to negotiate anything. The first version placed the ego's own
%   start (0.9) and the moto (-0.3) only 1.2 m apart - LESS than what their
%   bodies need even standing still, so it was never a negotiation, it was a
%   guaranteed graze, measured as a real -0.372 m collision at t=20.2 s.
%   -1.0 STILL collided (-0.299 m, measured) - the ego moves toward the
%   moto's side during its own stop-and-resume maneuver, so "far enough at
%   the ego's start" is not the same as "far enough for wherever the seat's
%   own candidate search actually puts it mid-maneuver." Moved to -1.5 (2.4 m
%   from the ego's start, clear of every in-bounds LatOffset candidate the
%   seat can pick on this road, not just the default one) and kept the 2.5
%   m/s closing speed - real negotiation timing comes from the corridor
%   still only being 3.2-3.6 m here, not from shaving the lateral margin
%   to the minimum that survives a straight-line check. Verified +0.204 m
%   full-route with the moto alone; +0.175 m once the child and dog (below)
%   were added, still safely positive - both are ALWAYS-PRESENT tracked
%   actors from t=0 (their stations are static, speed 0, so they exist in
%   the world for the whole run, not just from their own window), which
%   makes them simultaneously "ahead" during the moto encounter too and
%   nudges the negotiated line slightly. Disclosed, not chased further: a
%   real, small, still-safe side effect of three actors sharing one road,
%   not a defect in any one of them.
%
%   ROW 2 - THE CHILD, crossing (S3-THE-GALLI.md t=8.2: "a child runs across").
%   Station 110 m is CHOSEN - the spec times this off the WRITTEN action
%   script's own clock, which this run does not share (real hazard caps and
%   negotiation change when the ego actually gets anywhere), so there is no
%   real station to recover; 110 m sits inside the open, unconstrained
%   90-150 m stretch, clear of both the motorcycle (~s=93) and the squeeze
%   (232). Crosses the FULL carriageway, verge to verge (+2.2 to -2.2),
%   over a 3 s window (t=20-23 s) - also chosen, since ground truth does not
%   need to land exactly under wherever the ego happens to be; the point is
%   that the actor is real and the planner reacts to whatever it actually
%   sees, not that the two clocks are synchronised.
%
%   ROW 3 - THE DOG (S3-THE-GALLI.md: "asleep exactly in the squeeze - it
%   moves"). NOT placed at the squeeze's own station (232-246) - TWO REAL
%   BUGS FOUND HERE, BOTH BY RUNNING THE FULL ROUTE, NEITHER ASSUMED:
%
%   BUG 1 - inside the squeeze, there is no safe "aside". The squeeze's
%   1.95 m free width decomposes exactly into drain [-1.725,-0.975] +
%   passable lane [-0.975,+0.975] + scooter [+0.975,+2.775] (sc.demo3Route),
%   nothing left over for a second body at any lateral offset - stepping
%   aside to +1.0 still overlapped the passable lane against the ego's own
%   half-width, and the ego is forced by corridorFrom's ramp to within
%   centimetres of e=0 well before it reaches the squeeze. Froze the planner
%   permanently at s=225 m ("holding for track 903 to clear").
%
%   BUG 2 - moving the dog to 250 m (just past the squeeze, where the
%   corridor is back to full width) did NOT fix it, and this is the more
%   interesting of the two: sc.planSeat's own negotiation layer (iPickPassLine
%   / iPickHoldLine, +sc/planSeat.m - Antara/Anjali's file, not edited here)
%   filters "the road users we have to get past" with `trS > ctx.s - 2` and
%   NO UPPER BOUND - any tracked actor still ahead of the ego, no matter how
%   far, is treated as something the CURRENT candidate fan must clear. With
%   the ego stuck deep in the squeeze (e forced near 0) and the dog 13+ m
%   ahead at e=+1.0, iLineClearance's own arithmetic - (1.0-0.15) - (0+0.95)
%   = -0.10 m - is negative for every offset the squeeze allows, so no
%   candidate ever clears, the WAIT never resolves, and rung 2's stuck-timer
%   reset just repeats the same WAIT forever. A real, disclosed limitation of
%   an already-built, already-correct-elsewhere piece of the negotiation
%   layer - not something to patch from this file, or from a track outside
%   the one that owns it.
%
%   THE FIX (part 1): station 125 - inside the open 90-150 m stretch,
%   comfortably before the ramp even starts narrowing (corridorFrom's
%   lead-in begins at 232-100=132 m). By the time the ego's own s passes
%   127 m the dog is more than 2 m behind it and drops out of "ahead"
%   entirely, long before the corridor gets tight - the squeeze transit
%   already proven to work (0 plan failures, full route) sees no third
%   actor in it at all. Still steps aside over the same t=50-55 s window.
%
%   BUG 3 - station 125 alone still froze it, because station 125 sits close
%   enough to the child's own 110 that BOTH are "ahead" (unbounded lookahead,
%   same as bug 2) for the whole approach, and their settled positions
%   pointed in OPPOSITE directions: the child settles at -2.2 (clears only
%   for a candidate offset o >= -0.50), the dog stepping to +1.0 clears only
%   for o <= -0.60 (iLineClearance's own arithmetic: (1.0-0.15)-(o+0.95) >=
%   0.5). Those two requirements do not overlap for ANY o - a genuinely
%   empty feasible set, true regardless of station separation as long as
%   both are "ahead" together. FIRST FIX TRIED: step the dog to -1.0 instead
%   of +1.0 - the same side as the child. Looked right by hand (child +1.90 m
%   clear, dog +0.80 m clear at o=+0.9) but that arithmetic left out the
%   THIRD term iLineClearance always checks - clearance to the physical road
%   edge, roadHalfW-|o|-egoW/2 = 2.25-0.9-0.95 = 0.40 m, itself below the
%   0.5 m floor. Chased at the time by adding a finer route-specific
%   LatOffsets grid in builtinRouteS3 - since reverted, see its own header:
%   the grid itself turned out to move the real problem, not solve it.
%
%   BUG 4 - the -1.0 fix (with that finer grid in place) let the ego find a
%   real pass (o~0.6-0.9), but RETURNING to e=0 afterwards is the frozen
%   planner's own findSharedTrunk tie-break, not a distance-proportional
%   decay - measured still ~0.18 m off-centre 8 m before the squeeze,
%   outside even the FOLDED tolerance (+-0.125 m, sc.s3geom), which hit the
%   identical D9 freeze the corridor ramp was built to prevent, just from a
%   smaller residual instead of a full lane change. Tried compensating with
%   a longer corridorFrom leadIn (130 m) - made it WORSE, for the reason in
%   runPlanner's own header. Tried removing the finer grid instead - the
%   SAME ~0.18 m residual was still there with the dog at -1.0, proving the
%   grid was never the fix for this part either, only a distraction that
%   also broke something else further up the route (builtinRouteS3's header
%   has the full account of what that was and why it's gone).
%
%   THE ACTUAL FIX: stop needing an avoidance offset at all. -1.65 is far
%   enough that o=0 ITSELF already clears the dog (iLineClearance(0, 0.95,
%   -1.65, 0.15) = +0.55 m) as well as the child (+1.00 m) - both checked
%   AGAINST THE ROAD-EDGE TERM TOO this time, not just the per-actor one. The
%   ego never has to leave e=0 for either actor, so there is no residual left
%   to bleed off before the squeeze, and the original 7-value LatOffsets fan
%   (S1/S2's, unmodified) is all this route ever actually needed. CHOSEN,
%   disclosed: -1.65 sits past the default corridor's own eLo (-1.30 m),
%   closer to the wall than a modest "step aside" - still a real tracked
%   actor the frozen planner evaluates and would react to if it were any
%   closer, just not one that forces a detour this time.
spec = { ...
    5,  150, -1.5,  [1.90 0.75 1.30], -2.5, 0, [], [] ; ...
    8,  110,  2.2,  [0.50 0.50 1.40],  0,   0, -2.2, [20 23] ; ...
    11, 125,  0.0,  [0.50 0.30 0.40],  0,   0, -1.65, [50 55] ...
};
end

function TR = builtinTracksS3(W, n, DT)
%BUILTINTRACKSS3  Exact ground truth for S3's one actor - same construction
%   as builtinTracks, just off actorSpecS3 instead of actorSpec.
P = W.Path;
spec = actorSpecS3();
TR = cell(1, n);
for i = 1:n
    t = (i-1)*DT;
    A = activeActorsAt(spec, P, t);
    Ti = emptyTrackList();
    for a = 1:numel(A)
        Ti(end+1) = struct('TrackID',uint32(900+A(a).Row),'ClassID',uint8(A(a).ClassID), ...
            'Position',[A(a).XY 0],'Velocity',A(a).Vel,'Extent',A(a).Extent, ...
            'Yaw',A(a).YawRad,'Existence',1,'Age',uint32(30),'SensorMask',uint8(1)); %#ok<AGROW>
    end
    TR{i} = Ti;
end
end

function [PR, who, DIMS] = builtinPosesS3(W, n, DT)
%BUILTINPOSESS3  Same three actors, raw - see builtinPoses's own header on
%   the one unit trap (traffic Yaw in degrees, ego Yaw in radians). Row order
%   matches actorSpecS3 exactly: 1 motorcycle, 2 child, 3 dog.
P = W.Path;
spec = actorSpecS3();
tags = {'moto_wrong', 'child', 'dog'};
assert(numel(tags) == size(spec,1), ...
    'demo_play:builtinPosesS3TagMismatch', ...
    'actorSpecS3 has %d rows but builtinPosesS3 only names %d tags - keep them in step.', ...
    size(spec,1), numel(tags));
who = containers.Map('KeyType','double','ValueType','char');
DIMS = struct();
for k = 1:size(spec,1)
    who(900+k) = tags{k};
    DIMS.(tags{k}) = spec{k,4};
end
PR = cell(1, n);
for i = 1:n
    t = (i-1)*DT;
    A = activeActorsAt(spec, P, t);
    Pi = struct('ActorID',{},'Position',{},'Velocity',{},'Yaw',{});
    for a = 1:numel(A)
        Pi(end+1) = struct('ActorID',900+A(a).Row,'Position',[A(a).XY 0], ...
            'Velocity',A(a).Vel,'Yaw',rad2deg(A(a).YawRad)); %#ok<AGROW>
    end
    PR{i} = Pi;
end
end

% =========================================================================
%                       THE PLANNER RUN (computed once)
% =========================================================================
function LOG = runPlanner(D, DT, planEvery)
%RUNPLANNER  The real sc.planSeat, stepped over the route, logged. No graphics.
W = D.W;  P = W.Path;
RefPath = referencePathFrenet(P.P);
kappaV  = P.curvature();
egoWidth0 = 1.8;
if isfield(D, 'EgoWidth'), egoWidth0 = D.EgoWidth; end
TUNE = struct( ...
    'TermSpeeds',   [0 4 8 11 14.4], ...
    'LatOffsets',   [-2.5 -1.585 -0.9 0 0.9 1.75 2.6], ...
    'Horizon',      4.0, 'TimeRes', 0.1, 'Inflation', 0.0, ...
    'EgoWidth',     egoWidth0, 'EgoLength', 4.7, 'Wheelbase', 2.7, ...
    'LookaheadT',   0.6, 'MinLookahead', 2.0, 'DMin', 2.5);
A_LON = 1.5;  D_LON = 3.0;  R_LAT = 0.9;      % the same seat limits every runner uses

n = round(D.TEnd/DT);
LOG = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
             'x',zeros(1,n),'y',zeros(1,n),'yaw',zeros(1,n), ...
             'cmd',{cell(1,n)},'tracks',{cell(1,n)}, ...
             'cap',nan(1,n),'capWhy',strings(1,n),'chapter',strings(1,n));
% DO NOT START FASTER THAN THE FIRST HAZARD CAN BE BRAKED FOR. MEASURED on
% demo2: its first capped pothole sits at 32 m, 12 m past the s = 20 m start
% line, with a cap of 6.94 m/s. Starting at the 14.44 m/s route cruise, the
% ego needs ~50 m to shed that speed and physically cannot - it went through
% at 11.59 m/s and the run reported its very first hazard as disobeyed. That
% is not the cap logic failing; it is being asked for something no car could
% do. A driver joining a road does not arrive at 52 km/h into a hazard they
% can already see, so the opening speed is derived from what is ahead, using
% the SAME comfortable deceleration the lead-in is sized with.
v = startSpeed(D.Hazards, D.SStart, D.CruiseV);
if v < D.CruiseV - 0.05
    fprintf('opening speed held to %.2f m/s (cruise %.2f) - a capped hazard sits too close to the start line\n', ...
            v, D.CruiseV);
end
% e0 = 1.75 is S1/S2's own lane-position convention on their 7.0 m road -
% comfortably inside that road's own default corridor ([-2.55, 2.90]). It is
% NOT a universal constant: on S3's narrower 4.5 m road the default corridor
% is only [-1.30, 1.65], so 1.75 starts the ego already outside it, and the
% planner correctly reports no safe trunk from step 1 - found by running
% demo3, not assumed. Route-specific, defaulting to 1.75 so S1/S2 are
% byte-identical to before.
e0 = 1.75;
if isfield(D, 'EgoStartE'), e0 = D.EgoStartE; end
st = struct();  s = D.SStart;  e = e0;  ev = 0;
lastCmd = struct('v',v,'e',e);
tRun = tic;  nFail = 0;  reachedEnd = false;
fprintf('running the real planner over %d steps (this is the slow part - it is\n', n);
fprintf('cached afterwards so the demo itself never waits for it)\n');
% sc.senseRig carries live tracker/RandStream state (Chat 4, 7 Sep - see its own
% header) - build ONE per run, reused every step, never copied. D.Sensed is set
% unconditionally in demo_play before this is ever called.
rig = [];
if D.Sensed
    rig = sc.senseRig();
    fprintf('SENSING IN-LOOP from the ego''s own pose each step (sc.senseRig/senseStep)\n');
end
for i = 1:n
    t = (i-1)*DT;
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));
    % ---- the one place ground truth vs sensed diverges -------------------
    % D.Tracks/tracksAt is exact ground truth, precomputed before this loop
    % ever runs (traffic position is a pure function of t, nothing to sense
    % against yet). D.Poses is the SAME raw ground truth, packaged for
    % sc.senseStep instead - which needs the ego's REAL pose (xy/hdg, just
    % computed above), not a fictitious one. That is the whole reason sensing
    % happens HERE, inside the loop, and not folded into D.Tracks up front.
    if D.Sensed
        tracksNow = sc.senseStep(rig, D.Poses{min(i,numel(D.Poses))}, D.Who, D.DIMS, ...
            struct('Position',[xy 0],'Yaw',hdg), t);
    else
        tracksNow = tracksAt(D,i);
    end
    ctx = struct('s',s,'e',e,'v',v,'t',t, ...
        'W',W,'Path',P,'RefPath',RefPath,'Tracks',tracksNow, ...
        'EgoXY',xy,'EgoYaw',hdg,'Kappa',kappaV(ki),'CruiseV',D.CruiseV);
    fn = fieldnames(TUNE);
    for f = 1:numel(fn), ctx.(fn{f}) = TUNE.(fn{f}); end
    [ctx.LatOffsets, livePassE] = liveSafeOffsets( ...
        D.Hazards, s, W, TUNE.EgoWidth, ctx.LatOffsets);

    % ---- TIER 2: hazards narrow the corridor the planner may use ----------
    % planSeat reads ctx.ELo/ctx.EHi as supported overrides of its lateral
    % clamp, so a barrier standing in part of the carriageway genuinely takes
    % that band away from the real planner rather than being drawn on top of it.
    %
    % MIRRORSFOLDED IS DECIDED HERE, NOT READ FROM THE PLANNER - checked by
    % grep, not assumed: chooseVelocity.m, followTrunk.m, planTurn.m and
    % roadBarrier.m all say explicitly that Signal/Gear/Committed/MirrorsFolded
    % are "not set here" - that decision was always meant to live in the
    % Simulink/Stateflow chart. demo_play never runs through Stateflow at all
    % (sc.planSeat is called directly), so nothing else in this pipeline was
    % ever going to fold the mirrors. Decided the same way a driver would: try
    % the full-width corridor first, fold only if that's rejected or too tight
    % AND folding actually opens up a real corridor. 0.20 m is AGENTS.md S4's
    % own figure ("folding narrows the ego footprint ~20 cm").
    % minCorridorNow is deliberately NOT compared against ego width anywhere
    % below - eHi-eLo, once a hazard has touched it, is already centerline
    % SLACK (corridorFrom's blockLo/blockHi bake egoW/2 in on each side), not
    % raw free width. Comparing slack against a whole ego-width-sized number
    % again was the original bug: it made the fold-acceptance check
    % impossible to satisfy (a 0.25 m folded slack can never be >= 1.72 m).
    % minCorridorNow is just "how little slack is still drivable" - 0.10 m
    % sits between the squeeze's real unfolded slack (0.05 m - correctly
    % rejects) and its real folded slack (0.25 m - correctly accepts).
    minCorridorNow = 2.2;
    if isfield(D, 'MinCorridor'), minCorridorNow = D.MinCorridor; end
    leadInNow = 12;
    if isfield(D, 'CorridorLeadIn'), leadInNow = D.CorridorLeadIn; end
    fullEgoWidth   = TUNE.EgoWidth;
    foldedEgoWidth = TUNE.EgoWidth - 0.20;
    [eLoH, eHiH] = corridorFrom(D.Hazards, s, W, fullEgoWidth, minCorridorNow, leadInNow);
    mirrorsFoldedNow = false;
    if isnan(eLoH)
        [eLoTry, eHiTry] = corridorFrom(D.Hazards, s, W, foldedEgoWidth, minCorridorNow, leadInNow);
        if ~isnan(eLoTry)
            mirrorsFoldedNow = true;
            eLoH = eLoTry;  eHiH = eHiTry;
        end
    end
    if isfinite(eLoH), ctx.ELo = eLoH; end
    if isfinite(eHiH), ctx.EHi = eHiH; end

    if mod(i-1, planEvery) == 0
        [cmd, st] = sc.planSeat(st, ctx);
        cmd.MirrorsFolded = mirrorsFoldedNow;
        lastCmd = cmd;
        if isfield(cmd,'PlanFailed') && strlength(cmd.PlanFailed) > 0, nFail = nFail + 1; end
    else
        cmd = lastCmd;  cmd.State = st.State;  cmd.Note = st.Note;
        cmd.MirrorsFolded = mirrorsFoldedNow;   % cheap, computed every step
                                                 % regardless of planEvery
    end
    if isfinite(livePassE)
        % This is one of the planner's terminal candidates. Hold it through
        % the manoeuvre instead of following only the first few metres of the
        % same receding-horizon lateral transition on every new cycle.
        cmd.e = livePassE;
    end

    % ---- TIER 2: the hazard speed cap, beside speedLimit, never inside it --
    [cap, why] = hazardCap(D.Hazards, s, v, D.CruiseV);
    cmd.VCap = min(cmd.v, cap);
    cmd.v    = min(cmd.v, cap);
    LOG.cap(i) = cap;  LOG.capWhy(i) = why;
    LOG.chapter(i) = chapterFor(D.Hazards, s, ctx.Tracks, D.W.Path, s);

    dv = cmd.v - v;
    v  = max(0, v + max(-D_LON*DT, min(A_LON*DT, dv)));
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', R_LAT);
    s  = min(P.Len, s + v*DT);

    LOG.t(i)=t; LOG.s(i)=s; LOG.e(i)=e; LOG.v(i)=v;
    LOG.x(i)=xy(1); LOG.y(i)=xy(2); LOG.yaw(i)=hdg;
    LOG.cmd{i} = slimCmd(cmd);
    LOG.tracks{i} = ctx.Tracks;
    if mod(i, 100) == 0
        fprintf('  step %4d/%d  t=%5.1f s  s=%6.1f m  v=%5.2f m/s  %-9s  (%.0f s elapsed)\n', ...
                i, n, t, s, v, cmd.State, toc(tRun));
    end
    if s >= P.Len - 6
        fprintf('  reached the end of the route at step %d\n', i);
        LOG = truncate(LOG, i);  reachedEnd = true;  break
    end
end
LOG.ReachedEnd = reachedEnd;
LOG.PlannerFP  = plannerFingerprint();
LOG.PlanEvery  = planEvery;
fprintf('planner run done in %.1f s (%d plan failures)\n', toc(tRun), nFail);
end

function TAIL = runPlannerTail(D, DT, planEvery, prior, keep)
%RUNPLANNERTAIL  Re-plan only the unplayed portion after a live obstruction.
%   The physical state at KEEP is preserved exactly. Deliberation state is
%   deliberately fresh: the click creates a new planning episode, while the
%   current tracks, road, speed and lateral motion remain the real ones.
W = D.W;  P = W.Path;
RefPath = referencePathFrenet(P.P);
kappaV  = P.curvature();
TUNE = struct( ...
    'TermSpeeds',   [0 4 8 11 14.4], ...
    'LatOffsets',   [-2.5 -1.585 -0.9 0 0.9 1.75 2.6], ...
    'Horizon',      4.0, 'TimeRes', 0.1, 'Inflation', 0.0, ...
    'EgoWidth',     1.8, 'EgoLength', 4.7, 'Wheelbase', 2.7, ...
    'LookaheadT',   0.6, 'MinLookahead', 2.0, 'DMin', 2.5);
A_LON = 1.5;  D_LON = 3.0;  R_LAT = 0.9;

nTotal = round(D.TEnd/DT);
n = max(0, nTotal - keep);
TAIL = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
              'x',zeros(1,n),'y',zeros(1,n),'yaw',zeros(1,n), ...
              'cmd',{cell(1,n)},'tracks',{cell(1,n)}, ...
              'cap',nan(1,n),'capWhy',strings(1,n),'chapter',strings(1,n));
s = prior.s(keep);  e = prior.e(keep);  v = prior.v(keep);
ev = 0;
if keep > 1, ev = (prior.e(keep) - prior.e(keep-1))/DT; end
st = struct();  lastCmd = struct('v',v,'e',e);
tRun = tic;  nFail = 0;  reachedEnd = false;
fprintf('LIVE local re-plan: keeping %d frames, solving at 20/%d = %.2f Hz\n', ...
        keep, planEvery, 20/planEvery);
for j = 1:n
    i = keep + j;
    t = (i-1)*DT;
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));
    ctx = struct('s',s,'e',e,'v',v,'t',t, ...
        'W',W,'Path',P,'RefPath',RefPath,'Tracks',tracksAt(D,i), ...
        'EgoXY',xy,'EgoYaw',hdg,'Kappa',kappaV(ki),'CruiseV',D.CruiseV);
    fn = fieldnames(TUNE);
    for f = 1:numel(fn), ctx.(fn{f}) = TUNE.(fn{f}); end
    [ctx.LatOffsets, livePassE] = liveSafeOffsets( ...
        D.Hazards, s, W, TUNE.EgoWidth, ctx.LatOffsets);
    [eLoH, eHiH] = corridorFrom(D.Hazards, s, W, TUNE.EgoWidth);
    if isfinite(eLoH), ctx.ELo = eLoH; end
    if isfinite(eHiH), ctx.EHi = eHiH; end

    if j == 1 || mod(i-1, planEvery) == 0
        [cmd, st] = sc.planSeat(st, ctx);
        lastCmd = cmd;
        if isfield(cmd,'PlanFailed') && strlength(cmd.PlanFailed) > 0, nFail = nFail + 1; end
    else
        cmd = lastCmd;  cmd.State = st.State;  cmd.Note = st.Note;
    end
    if isfinite(livePassE), cmd.e = livePassE; end
    [cap, why] = hazardCap(D.Hazards, s, v, D.CruiseV);
    cmd.VCap = min(cmd.v, cap);
    cmd.v    = min(cmd.v, cap);
    TAIL.cap(j) = cap;  TAIL.capWhy(j) = why;
    TAIL.chapter(j) = chapterFor(D.Hazards, s, ctx.Tracks, D.W.Path, s);

    dv = cmd.v - v;
    v  = max(0, v + max(-D_LON*DT, min(A_LON*DT, dv)));
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', R_LAT);
    s  = min(P.Len, s + v*DT);
    TAIL.t(j)=t; TAIL.s(j)=s; TAIL.e(j)=e; TAIL.v(j)=v;
    TAIL.x(j)=xy(1); TAIL.y(j)=xy(2); TAIL.yaw(j)=hdg;
    TAIL.cmd{j}=slimCmd(cmd); TAIL.tracks{j}=ctx.Tracks;
    if s >= P.Len - 6
        TAIL = truncate(TAIL, j);  reachedEnd = true;  break
    end
end
TAIL.ReachedEnd = reachedEnd;
TAIL.PlannerFP = plannerFingerprint();
TAIL.PlanEvery = planEvery;
fprintf('LIVE local re-plan done in %.1f s (%d plan failures, %d new frames)\n', ...
        toc(tRun), nFail, numel(TAIL.t));
end

function LOG = spliceTail(LOG, TAIL, keep)
%SPLICETAIL  Preserve the watched prefix byte-for-byte and replace only its tail.
LOG = truncate(LOG, keep);
names = {'t','s','e','v','x','y','yaw','cmd','tracks','cap','capWhy','chapter'};
for k = 1:numel(names)
    f = names{k};
    LOG.(f) = [LOG.(f) TAIL.(f)];
end
LOG.ReachedEnd = TAIL.ReachedEnd;
LOG.PlannerFP = TAIL.PlannerFP;
LOG.PlanEvery = TAIL.PlanEvery;
end

function TR = tracksAt(D, i)
%TRACKSAT  This frame's TrackList. An EMPTY one MUST still carry the full S1
%   field set - measured, not guessed: handing sc.planSeat a bare struct([])
%   throws inside its own iTrackHysteresis ("Number of fields in structure
%   arrays being concatenated do not match") when it tries to concatenate the
%   frame's tracks with its dead-reckoned ghosts. planSeat builds ITS empty
%   prototype explicitly for exactly this reason; so does this.
if iscell(D.Tracks)
    if isempty(D.Tracks), TR = emptyTrackList(); else, TR = D.Tracks{min(i,numel(D.Tracks))}; end
else
    TR = D.Tracks;                       % one static set
end
if isempty(TR), TR = emptyTrackList(); end
end

function TR = emptyTrackList()
TR = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
            'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});
end

function c = slimCmd(cmd)
%SLIMCMD  Keep only what the view draws. The full cmd carries the whole
%   candidate fan every step; at 20 Hz over 140 s that is a several-hundred-MB
%   .mat, which is a slow load right before a demo. The fan IS kept (it is half
%   the point of watching) - just as single precision, which is well past the
%   precision of a 1600-pixel-wide axes.
keep = {'State','Note','v','e','H','HLabel','Look','Blocked','TrunkMode', ...
        'Creeping','VCap','MirrorsFolded','TurnType','TurnBinds', ...
        'RefugePoint','NeedsReverse','EscapeCount','HasEscape','NearestEscape'};
c = struct();
for k = 1:numel(keep)
    if isfield(cmd, keep{k}), c.(keep{k}) = cmd.(keep{k}); end
end
if isfield(cmd,'Trunk'), c.Trunk = single(cmd.Trunk); end
% THE CANDIDATE FAN IS FLATTENED HERE, NOT IN THE DRAW LOOP. Measured: the
% real planner returns ~35 candidates per step, and concatenating 35 arrays
% into one NaN-separated polyline every frame pushed p95 frame time to 90 ms -
% past the 50 ms budget, and playback then ran 1.35x slower than real time
% while quietly absorbing the lag. Doing it once, at cache time, moves that
% work off the demo entirely: the view just set()s two vectors.
if isfield(cmd,'Candidates')
    cc = cmd.Candidates;
    nC = numel(cc);
    c.NCand = nC;
    xs = cell(1,nC); ys = cell(1,nC);
    for k = 1:nC
        g = cc{k};
        if isempty(g), xs{k} = single(NaN); ys{k} = single(NaN); continue; end
        xs{k} = single([g(:,1); NaN]);  ys{k} = single([g(:,2); NaN]);
    end
    c.CandX = vertcat(xs{:});  c.CandY = vertcat(ys{:});
end
end

function LOG = truncate(LOG, n)
%TRUNCATE  Cut every per-step series to n samples. Scalar bookkeeping fields
%   (Stamp, ReachedEnd) are left alone - they describe the RUN, not a step,
%   and slicing them would quietly corrupt the cache's own metadata.
skip = {'Stamp','ReachedEnd','PlannerFP','PlanEvery'};
f = fieldnames(LOG);
for k = 1:numel(f)
    if ismember(f{k}, skip), continue; end
    v = LOG.(f{k});
    if (isnumeric(v) || isstring(v) || iscell(v)) && numel(v) > n, LOG.(f{k}) = v(1:n); end
end
end

% =========================================================================
%                        TIER 2 - HAZARD BEHAVIOUR
% =========================================================================
function [lo, hi] = stretch(h)
%STRETCH  Where a hazard actually applies. Zone runs FORWARD from Station - the
%   same convention sc.plannerView draws the band with, so the picture and the
%   behaviour can never disagree about where the stretch is. A point hazard
%   (Zone == 0) applies over its own footprint, with a 2 m floor so a 0.4 m
%   pothole is not skipped between two 20 Hz samples at 14 m/s.
r = 2.0;
if isfinite(h.Radius), r = max(2.0, h.Radius); end
if h.Zone > 0
    lo = h.Station;  hi = h.Station + h.Zone;
else
    lo = h.Station - r;  hi = h.Station + r;
end
end

function T = estimateDuration(H, sStart, routeLen, cruise, cowMode)
%ESTIMATEDURATION  How many seconds this route actually takes to drive, walked
%   station by station at whatever cap binds there. Self-correcting: change a
%   SpeedCap and this follows, which is the whole point.
%
%   THIS RETURNS A GENEROUS UPPER BOUND, NOT A PREDICTION, AND THE ASYMMETRY
%   IS THE WHOLE DESIGN. runPlanner stops itself the moment it runs out of
%   road and truncates the log, so overshooting costs a little precompute and
%   nothing else - while undershooting silently drops hazards off the end of
%   the demo, which is the failure this function exists to prevent, and which
%   has now happened twice.
%   A first version used a 1.35 margin as an ESTIMATE. MEASURED: it returned
%   88 s for demo2 where the route actually takes 101 s, because a station-by
%   -station walk at each cap ignores every acceleration and braking
%   transition between them, and there are 22 capped stretches on that route.
%   It dropped the same three hazards all over again. Doubling is not a
%   tuned constant - it is the acknowledgement that this walk systematically
%   underestimates and that erring long is free.
ds = 2.0;  T = 0;
for u = sStart:ds:routeLen
    v = cruise;
    for k = 1:numel(H)
        c = H(k).SpeedCap;
        if ~isfinite(c), continue; end
        [lo, hi] = stretch(H(k));
        if u >= lo && u <= hi, v = min(v, c); end
    end
    T = T + ds/max(v, 1.0);
end
T = 2.0*T;                                    % an upper bound, deliberately loose
if cowMode == "blocking", T = T + 15; end     % the WAIT rung's time at a standstill
T = min(220, max(40, T));
end

function v0 = startSpeed(H, sStart, cruise)
%STARTSPEED  The fastest opening speed from which EVERY capped hazard ahead is
%   still reachable by comfortable braking. Same aComfort as hazardCap's
%   lead-in, so the two cannot disagree about what is achievable.
aComfort = 1.6;
v0 = cruise;
for k = 1:numel(H)
    c = H(k).SpeedCap;
    if ~isfinite(c), continue; end
    [lo, ~] = stretch(H(k));
    d = lo - sStart;
    if d <= 0, continue; end            % already past it - nothing to plan for
    v0 = min(v0, sqrt(c^2 + 2*aComfort*d));
end
v0 = max(v0, 0.5);
end

function [cap, why] = hazardCap(H, s, v, vRef)
%HAZARDCAP  The tightest hazard-imposed speed cap in force at station s.
%   Applied from a braking LEAD-IN ahead of the hazard, not at its edge, so the
%   car slows down before it and recovers after - which is what makes it read as
%   driving. aComfort is a comfortable deceleration, deliberately gentler than
%   the seat's own D_LON = 3.0 emergency figure; it is a DESIGN CHOICE, like
%   speedLimit's own aBrake, not a measured number.
aComfort = 1.6;
% THE LEAD-IN IS SIZED FROM THE ROUTE CRUISE SPEED, NOT THE CURRENT ONE, AND
% THAT IS NOT A DETAIL. Sized from v, the term is self-referential: the cap
% slows the car, the slower car needs a shorter lead-in, the lead-in releases
% the cap, the car speeds up, the cap comes back. Plotted, that is a visible
% 20 Hz sawtooth on the v-cap trace - it was there in the first exported frame,
% chattering the whole way through the pothole cluster, and it reads as a
% broken controller. vRef is fixed for the route, so the braking point for a
% given hazard is one fixed station and the approach is monotone.
cap = Inf;  why = "";
if nargin < 4 || ~isfinite(vRef), vRef = v; end
for k = 1:numel(H)
    c = H(k).SpeedCap;
    if ~isfinite(c), continue; end
    [lo, hi] = stretch(H(k));
    lead = 0;
    if vRef > c, lead = (vRef^2 - c^2) / (2*aComfort); end
    if s >= lo - lead && s <= hi
        if c < cap
            cap = c;
            if s < lo
                why = string(H(k).Label) + sprintf(" in %.0f m", lo - s);
            else
                why = string(H(k).Label) + " - in it now";
            end
        end
    end
end
if ~isfinite(cap), why = "clear"; end
end

function [eLo, eHi] = corridorFrom(H, s, W, egoW, minCorridor, leadIn)
%CORRIDORFROM  A hazard standing IN the carriageway takes that lateral band
%   away. Returns NaN when no hazard narrows anything, so the caller leaves
%   planSeat's own Phase-6 bounds alone rather than re-deriving them here.
%   Only ever NARROWS - a hazard can never widen the road.
%
%   minCorridor (optional, default 2.2 m - demo1/demo2's unchanged behavior)
%   is the sanity floor below which a "corridor" is treated as a wall instead.
%   2.2 m was never a physical law, just headroom past demo1/demo2's 1.8 m
%   ego - S3's squeeze is a genuine, measured 1.95 m free width (sc.s3geom),
%   which needs its own, smaller floor to be representable at all.
%
%   leadIn (optional, default 12 m - demo1/demo2's unchanged behavior) is how
%   far ahead of a hazard its narrowing starts applying. 12 m was tuned for
%   demo1/demo2's hazards, which only ever need a small nudge off-centre.
%   MEASURED, NOT ASSUMED: asking the ego to complete a large lateral move
%   (~0.8-1.4 m) inside a 12 m window repeatedly produced a genuine freeze -
%   findSharedTrunk's own tie-break prefers the smallest lateral offset until
%   a move is forced, and 12 m is not enough distance left once it is. A
%   longer leadIn does not change WHAT the corridor is, only how early the
%   planner is given the chance to drift toward it gradually instead of late.
if nargin < 6, leadIn = 12; end
if nargin < 5, minCorridor = 2.2; end
hw   = W.Width/2;
eLo0 = -(hw - 0.95);  eHi0 = (hw - 0.95) + 0.35;    % planSeat's own defaults
eLo  = eLo0;  eHi = eHi0;  touched = false;
for k = 1:numel(H)
    if ~ismember(string(H(k).Type), ["barrier","damage"]), continue; end
    % A live barrier constrains terminal candidate lines in liveSafeOffsets.
    % ELo/EHi also applies to the candidate's current pose, so using it here
    % would invalidate every path before an ego on the blocked side can leave.
    if startsWith(string(H(k).Label),"LIVE OBSTACLE"), continue; end
    [lo, hi] = stretch(H(k));
    if s < lo - leadIn || s > hi, continue; end      % leadIn m of approach to plan in
    % RAMPED, NOT A STEP FUNCTION - progress 0 at s=lo-leadIn (no effect yet)
    % to 1 at s=lo and for the hazard's own physical extent (full effect).
    % A step function was the real bug behind a genuine freeze: with the
    % full narrowing switching on all at once, a large lateral move (~1.4 m)
    % had to be completed from a standing start in whatever the planner's own
    % Horizon actually reaches - MEASURED to fail regardless of how far back
    % leadIn started, because a longer leadIn only moved where the step was,
    % it never let the ego drift into position gradually. This does.
    progress = max(0, min(1, (s - (lo - leadIn)) / leadIn));
    % FULL-WIDTH SURFACE DAMAGE IS NOT A THING TO DODGE, AND SAYING SO HERE
    % MATTERS. Read sc.demo2Route's own labels: every damage entry on the
    % centreline describes the WHOLE carriageway - "aggregate showing through
    % in BOTH WHEEL PATHS", "runs RIGHT THROUGH the bend", "NO CLEAN LINE".
    % There is nothing to steer around; the honest response is to slow down,
    % which its SpeedCap already does. Only the entries out on the shoulder
    % (+3.40, +3.80 - "the shoulder has caved in", "no margin left to dodge
    % onto") actually remove lateral room, and those are what this narrows for.
    % Before this, a Radius of 0 - which is what demo2Route gives ALL of them -
    % was read by isfinite() as a literal zero WIDTH rather than as "not
    % specified", so a centreline entry reserved just the ego's own width and
    % was then thrown away by the minimum-corridor guard below. Right outcome,
    % two wrongs, and it would not have survived the next route.
    % AND A NOTE ON HOW THIS WAS VERIFIED, because the first attempt got it
    % backwards and someone will otherwise re-derive it at 5am: a check that
    % asked "did the ego DODGE this?" of full-width damage reported NINE
    % negative clearances and looked like a serious failure. It was the CHECK
    % that was wrong - the ego drives on the road, so of course its body spans
    % the centreline. Reading Chat 3's labels is what settled it. Had the code
    % been "fixed" to satisfy that check, mid-carriageway damage would have
    % become a dodgeable obstacle and the route undrivable. Ask each hazard
    % the question its own label implies.
    onShoulder = abs(H(k).Lateral) > 2.0;
    hasWidth   = isfinite(H(k).Radius) && H(k).Radius > 0;
    if ~onShoulder && ~hasWidth, continue; end       % surface condition, not an obstacle
    halfW = 1.0;                                     % a barricade board is ~1 m deep
    if hasWidth, halfW = H(k).Radius; end
    blockLo = H(k).Lateral - halfW - egoW/2;
    blockHi = H(k).Lateral + halfW + egoW/2;
    if blockHi >= eHi0 - 0.05                        % it eats the LEFT edge
        eHi = min(eHi, eHi0 + (blockLo - eHi0)*progress);  touched = true;
    elseif blockLo <= eLo0 + 0.05                    % it eats the RIGHT edge
        eLo = max(eLo, eLo0 + (blockHi - eLo0)*progress);  touched = true;
    else                                             % mid-carriageway: keep the
        if (eHi0 - blockHi) >= (blockLo - eLo0)      % wider of the two sides
            eLo = max(eLo, eLo0 + (blockHi - eLo0)*progress);
        else
            eHi = min(eHi, eHi0 + (blockLo - eHi0)*progress);
        end
        touched = true;
    end
end
if ~touched || eHi - eLo < minCorridor               % never squeeze below the sanity
    eLo = NaN;  eHi = NaN;                           % floor - that is not a corridor,
end                                                  % it is a wall, and planSeat's
end                                                  % own bounds are the honest fallback

function [offsets, passE] = liveSafeOffsets(H, s, W, egoW, offsets)
%LIVESAFEOFFSETS  Offer terminal lines only on a clear side of a live barrier.
%   Terminal offsets let the trajectory begin at the ego's unchanged pose and
%   move across. planContingency still generates, safety-checks, selects and
%   follows the resulting trajectory; this adapter only removes blocked goals.
eLo = -(W.Width/2 - 0.95);
eHi =  (W.Width/2 - 0.95) + 0.35;
passE = NaN;
for k = 1:numel(H)
    if ~startsWith(string(H(k).Label),"LIVE OBSTACLE"), continue; end
    [lo, hi] = stretch(H(k));
    if s < lo - 45 || s > hi, continue; end
    halfObstacle = 0.35;
    if isfinite(H(k).Radius) && H(k).Radius > 0
        halfObstacle = H(k).Radius;
    end
    clearance = 0.50;
    blockedLo = H(k).Lateral - halfObstacle - egoW/2 - clearance;
    blockedHi = H(k).Lateral + halfObstacle + egoW/2 + clearance;
    rightRoom = blockedLo - eLo;
    leftRoom  = eHi - blockedHi;
    if leftRoom >= rightRoom
        safeLo = blockedHi;  safeHi = eHi;
    else
        safeLo = eLo;        safeHi = blockedLo;
    end
    if safeHi <= safeLo
        continue                         % physically a wall: retain safe stop
    end
    keep = offsets >= safeLo & offsets <= safeHi;
    bestClearanceLine = 0.5*(safeLo + safeHi);
    offsets = unique([offsets(keep) bestClearanceLine], 'stable');
    passE = bestClearanceLine;
end
end

function c = chapterFor(H, s, tracks, P, egoS)
%CHAPTERFOR  The FULL label of whatever the ego is closest to, for the panel.
%   The map only has room for the first clause (sc.plannerView cuts it there);
%   this is where the rest of Chat 3's sentence actually gets read out. That
%   split is the whole reason nothing ends up unexplained AND nothing ends up
%   painted across the road.
%
%   ROAD USERS ARE CONSIDERED TOO, AND THAT WAS A REAL BUG. This function used
%   to search the HAZARD list only. The cow is not a hazard - she is a road
%   user, a track - so throughout the entire cow encounter (measured: every
%   station from 286 m to 310 m) the panel's WHERE field read "Pothole, ~0.7 m
%   across", naming the pothole at 302 m while the car was negotiating a cow
%   standing in the road. At the single most important moment of the demo the
%   panel talked about a pothole and never once named the animal. Road users
%   are now ranked alongside hazards and the nearer one wins.
if nargin < 3, tracks = []; end
c = "open road";
best = inf;
for k = 1:numel(H)
    [lo, hi] = stretch(H(k));
    if s >= lo - 45 && s <= hi
        d = abs(s - lo);
        if d < best, best = d; c = string(H(k).Label); end
    end
end
% road users, in the same station frame, same 45 m look-ahead
for k = 1:numel(tracks)
    try
        [ts, te] = P.inverse(tracks(k).Position(1:2));
    catch
        continue
    end
    if ts < egoS - 5 || ts > egoS + 45, continue; end     % behind us, or too far
    d = abs(ts - egoS);
    % STRICTLY GREATER, and the tie is the whole point. stretch() gives a point
    % hazard a 2 m footprint, so the pothole at 302 m starts at 300 m - exactly
    % the cow's station. Both scored d = 14.0 at s = 286, and with >= the
    % hazard won the tie and the panel said "Pothole" through the entire cow
    % encounter, which is the bug this function was changed to fix. On an exact
    % tie the living thing in the road wins, which is also just the right
    % priority.
    if d > best, continue; end
    best = d;
    nm = trackName(tracks(k).ClassID);
    if abs(te) <= 3.5
        c = nm + " in the carriageway, " + sprintf('%.0f', max(0,ts-egoS)) + " m ahead" + ...
            " - a road user, not a mapped hazard: the planner is negotiating it live.";
    else
        c = nm + " on the verge, " + sprintf('%.0f', max(0,ts-egoS)) + " m ahead" + ...
            " - clear of the carriageway, tracked but not blocking.";
    end
end
end

function n = trackName(classID)
%TRACKNAME  AGENTS.md section 3 S5 ClassID -> a word a judge reads, not a number.
switch double(classID)
    case 1,  n = "Car";
    case 2,  n = "Truck";
    case 3,  n = "Bus";
    case 4,  n = "Auto-rickshaw";
    case 5,  n = "Motorcycle";
    case 6,  n = "Scooter";
    case 7,  n = "Van";
    case 8,  n = "Pedestrian";
    case 9,  n = "Cyclist";
    case 10, n = "COW";
    case 11, n = "Dog";
    case 13, n = "Bullock cart";
    case 14, n = "Tractor";
    otherwise, n = "Road user";
end
end

% =========================================================================
%                              PLAYBACK
% =========================================================================
function R = play(D, LOG, DT, opts)
%PLAY  Draw the recorded run at the true DT against a real clock.
n = numel(LOG.t);
sc.plannerView('init', struct('P',D.W.Path,'W',D.W,'CS',D.CS, ...
    'Hazards',D.Hazards,'Title',D.Title,'ViewSpan',opts.ViewSpan, ...
    'Interactive',opts.Interactive,'EnableInjection',opts.Interactive, ...
    'Sensed',D.Sensed));

if strlength(opts.Snap) > 0                       % one frame, for a screenshot
    i = max(1, round(n/2));
    sc.plannerView('step', frameOf(LOG, i));
    sc.plannerView('snap', struct('file',char(opts.Snap)));
    sc.plannerView('close');
    R = struct('Frames',1,'Snapped',opts.Snap);
    fprintf('wrote %s\n', opts.Snap);
    return
end

% batchStartupOptionUsed, NOT feature('ShowFigureWindows'). MEASURED on this
% machine: ShowFigureWindows returns TRUE under `matlab -batch` - graphics are
% fully functional there, the windows just never reach a human - so testing it
% skips nothing and the guard silently did nothing at all the first time. Both
% -batch and -nodesktop also report usejava('desktop') false, so that cannot
% tell them apart either. batchStartupOptionUsed is true for exactly one case,
% `-batch`, which is exactly the case with nobody watching.
if batchStartupOptionUsed && strlength(opts.Snap) == 0
    % Drawing ~1700 frames at 20 Hz into a window no human will see costs
    % about 90 seconds and shows nobody anything, so the playback leg is
    % skipped. The planner run above already happened and is cached, which is
    % the only useful thing a -batch invocation can produce - so say so
    % plainly rather than appearing to play.
    fprintf(['\nNO DISPLAY (matlab -batch). The planner run is done and cached;\n' ...
             'the playback leg is skipped - there is nothing to watch and no\n' ...
             'Snap= was asked for. Re-run from a MATLAB session WITH a display\n' ...
             '(desktop, or -nodesktop) to watch it; the cache means that is fast.\n']);
    sc.plannerView('close');
    R = struct('Frames',0,'Elapsed_s',0,'Quit',false,'MeanFrame_ms',NaN, ...
               'MedianFrame_ms',NaN,'P95Frame_ms',NaN,'MaxFrame_ms',NaN, ...
               'OverBudget',0,'MaxLag_s',NaN,'Headless',true);
    return
end
fprintf('\nplaying %d steps = %.0f s of driving at %.1fx\n', n, n*DT, opts.Speed);
fprintf('SPACE pause/resume    ->  or  N  step one frame    Q quit\n\n');
dtWall = DT/opts.Speed;
ft = nan(1,n);  lag = nan(1,n);
nReplans = 0;  nRejected = 0;  lastReplanS = NaN;
lastObstacleS = NaN;  lastObstacleE = NaN;
% Draw frame 1 BEFORE starting the clock. Building the figure, the road, and
% fourteen labelled hazards is a genuine one-off cost (measured at ~14 s the
% first time MATLAB touches these graphics paths) and charging it to the
% playback clock would make the car appear to sprint to catch up.
sc.plannerView('step', frameOf(LOG, 1));
tClock = tic;  pausedFor = 0;  quit = false;  drawn = 1;
i = 2;
while i <= n
    ctl = sc.plannerView('step', frameOf(LOG, i));
    if isfinite(opts.InjectStep) && i == round(opts.InjectStep) && all(isfinite(opts.InjectXY))
        % Deterministic twin of a mouse event for regression testing and a
        % pre-scripted rehearsal fallback. The normal demo leaves this off.
        ctl.InjectPending = true;
        ctl.InjectXY = opts.InjectXY;
    end
    ft(i) = ctl.LastFrame_ms;
    if ctl.Quit, quit = true; break; end
    if ctl.InjectPending
        [hs, he, accepted, why] = sc.clickToRoad(D.W.Path, D.W, ctl.InjectXY, LOG.s(i));
        if accepted
            % A stationary obstruction needs braking lead-in as well as a safe
            % terminal line. Four m/s makes this a controlled pass; the local
            % re-solve still decides the candidate trajectory and speed below.
            liveHz = hz("barrier", hs, he, "LIVE OBSTACLE - judge click", 0.35, 4.0, 0);
            sc.plannerView('status', struct('Text',sprintf( ...
                'LIVE RE-PLAN TRIGGERED AT s=%.1f m, e=%+.1f m', hs, he)));
            nextD = D;  nextD.Hazards(end+1) = liveHz;
            try
                tail = runPlannerTail(nextD, DT, opts.PlanEvery, LOG, i);
                LOG = spliceTail(LOG, tail, i);
                D = nextD;
                n = numel(LOG.t);
                nReplans = nReplans + 1;
                lastReplanS = LOG.s(i);
                lastObstacleS = hs;  lastObstacleE = he;
                sc.plannerView('addHazard', struct('Hazard',liveHz));
                sc.plannerView('status', struct('Text',sprintf( ...
                    'LIVE RE-PLAN COMPLETE FROM s=%.1f m  (%g Hz)', LOG.s(i), 20/opts.PlanEvery)));
            catch me
                % The already-watched prefix and the original cached tail both
                % survive. A failed live feature must not destroy the demo.
                sc.plannerView('status', struct('Text', ...
                    "LIVE RE-PLAN FAILED - ORIGINAL SAFE TAIL RETAINED"));
                warning('demo_play:liveReplan','live re-plan failed: %s',me.message);
            end
        else
            nRejected = nRejected + 1;
            sc.plannerView('status', struct('Text',"OBSTACLE NOT PLACED - " + why));
        end
    end
    drawn = i;
    % Pace against a real clock, not by accumulating pauses: time spent PAUSED
    % must not be repaid by the car sprinting to catch up afterwards.
    target = pausedFor + i*dtWall;
    slack  = target - toc(tClock);
    if ctl.Paused || slack < -0.5                 % we were held, or we fell behind
        pausedFor = toc(tClock) - i*dtWall;
    elseif slack > 0
        pause(slack);
    end
    lag(i) = toc(tClock) - (pausedFor + i*dtWall);
    i = i + 1;
end
elapsed = toc(tClock);
ft = ft(1:max(drawn,1));  lag = lag(1:max(drawn,1));
y = sort(ft(isfinite(ft)));
egoEAtObstacle = NaN;
if isfinite(lastObstacleS)
    [~, iObstacle] = min(abs(LOG.s(1:drawn) - lastObstacleS));
    egoEAtObstacle = LOG.e(iObstacle);
end
lastCmd = LOG.cmd{drawn};
finalState = "";  finalNote = "";
if isfield(lastCmd,'State'), finalState = string(lastCmd.State); end
if isfield(lastCmd,'Note'),  finalNote  = string(lastCmd.Note);  end
R = struct('Frames',drawn,'Elapsed_s',elapsed,'Quit',quit, ...
           'MeanFrame_ms',mean(ft,'omitnan'), ...
           'MedianFrame_ms',median(ft,'omitnan'), ...
           'P95Frame_ms',pick(y,0.95), 'MaxFrame_ms',max(ft), ...
           'OverBudget',sum(ft > 1000*DT), 'MaxLag_s',max(abs(lag),[],'omitnan'), ...
           'LiveReplans',nReplans,'RejectedClicks',nRejected,'LastReplan_s',lastReplanS, ...
           'LiveObstacleS',lastObstacleS,'LiveObstacleE',lastObstacleE, ...
           'EgoEAtObstacle',egoEAtObstacle,'FinalS',LOG.s(drawn),'FinalE',LOG.e(drawn), ...
           'ReachedEnd',LOG.ReachedEnd,'FinalState',finalState,'FinalNote',finalNote);
fprintf('\n--- PLAYBACK ---\n');
qtxt = 'ran to the end'; if quit, qtxt = 'quit early'; end
fprintf('  %d frames in %.1f s wall clock (%s)\n', drawn, elapsed, qtxt);
fprintf('  frame work: mean %.2f ms  median %.2f  p95 %.2f  max %.2f\n', ...
        R.MeanFrame_ms, R.MedianFrame_ms, R.P95Frame_ms, R.MaxFrame_ms);
fprintf('  frames over the %.0f ms budget: %d (%.2f%%)\n', 1000*DT, R.OverBudget, ...
        100*R.OverBudget/max(drawn,1));
fprintf('  worst drift from the real clock: %.3f s\n', R.MaxLag_s);
fprintf('  live re-plans: %d  rejected clicks: %d\n', R.LiveReplans, R.RejectedClicks);
if ~quit, fprintf('  (window left open - close it or call sc.plannerView(''close''))\n'); end
end

function fp = plannerFingerprint()
%PLANNERFINGERPRINT  A cheap identity for the PLANNER CODE a cache was built
%   against. Deliberately NOT part of routeStamp - see useCache.
%
%   Files: sc.planSeat (the seat), and every .m in the +sih/+planner package
%   it delegates to. Size + mtime, not a content hash: this drives a WARNING,
%   not a decision, so a false positive costs one ignorable line and a false
%   negative needs an edit that changes neither byte count nor timestamp.
fp = '';
try
    d = dir(which('sc.planSeat'));
    if ~isempty(d), fp = sprintf('seat:%d:%.0f|', d.bytes, d.datenum*86400); end
    pkg = fileparts(which('sih.planner.planContingency'));
    if ~isempty(pkg)
        dd = dir(fullfile(pkg, '*.m'));
        for k = 1:numel(dd)
            fp = [fp sprintf('%s:%d:%.0f;', dd(k).name, dd(k).bytes, dd(k).datenum*86400)]; %#ok<AGROW>
        end
    end
catch
    fp = '';                     % never let a fingerprint failure block a demo
end
end

function [LOG, why] = useCache(L, D, DT, planEvery)
%USECACHE  Decide whether a cached run answers this request.
%
%   A cached run is REUSABLE IF it is the same route AND it covers at least as
%   much driving as is being asked for - a run of 88 s trivially contains the
%   first 64 s of itself, so it is truncated and used. This is not a
%   micro-optimisation: keyed on TEnd, `demo_play("demo1", Cow="blocking")`
%   with the default duration missed a perfectly good 88 s cache and started a
%   two-minute planner run. In front of judges. That is the whole reason the
%   demo precomputes in the first place, so the cache has to be hard to miss.
%
%   A run that REACHED THE END OF THE ROUTE is complete by definition and
%   satisfies any request, however long - there is no more road to drive.
LOG = [];
if ~isfield(L,'LOG') || ~isfield(L.LOG,'Stamp')
    why = 'cache is from an older version of this file';  return
end
C = L.LOG;
if ~strcmp(C.Stamp, routeStamp(D))
    why = 'cache is for a different route';  return
end
if ~isfield(C,'cmd') || isempty(C.cmd) || ~isfield(C.cmd{1},'TurnType') ...
        || ~isfield(C.cmd{1},'NearestEscape')
    why = 'cache predates the turn/escape HUD fields';  return
end
if ~isfield(C,'PlanEvery') || C.PlanEvery ~= planEvery
    why = sprintf('cache planner rate differs from PlanEvery=%d', planEvery);  return
end
% THE PLANNER CODE IS NOT PART OF THE STAMP, ON PURPOSE. If it were, every
% edit to planSeat.m would invalidate every cache and force a two-minute
% recompute at the worst possible moment - and planSeat is under active edit
% in another chat. So a changed planner WARNS instead of recomputing: the
% cache still plays, and whoever is driving decides whether to rebuild. The
% failure this catches is the dangerous one - a cache whose route matches
% perfectly, replaying OLD planner behaviour while looking entirely correct.
fpNow = plannerFingerprint();
if isfield(C,'PlannerFP') && ~isempty(C.PlannerFP) && ~isempty(fpNow) ...
        && ~strcmp(C.PlannerFP, fpNow)
    fprintf(2, ['\n  *** THE PLANNER CODE HAS CHANGED SINCE THIS CACHE WAS BUILT ***\n' ...
                '  This run will replay the OLD planner''s decisions. That is fine for\n' ...
                '  a rehearsal and WRONG for measuring anything. Rebuild with\n' ...
                '  Recompute=true before quoting a number off it.\n\n']);
end
haveSteps = numel(C.t);
wantSteps = round(D.TEnd/DT);
reachedEnd = isfield(C,'ReachedEnd') && C.ReachedEnd;
if haveSteps < wantSteps && ~reachedEnd
    why = sprintf('cache covers only %.0f s of the %.0f s asked for', ...
                  haveSteps*DT, D.TEnd);
    return
end
if haveSteps > wantSteps
    LOG = truncate(C, wantSteps);
    why = sprintf('using a cached %.0f s run of this route, trimmed to %.0f s', ...
                  haveSteps*DT, wantSteps*DT);
else
    LOG = C;
    why = sprintf('loaded a cached run of this exact route (%d steps)', haveSteps);
end
end

function d = frameOf(LOG, i)
d = struct('t',LOG.t(i),'s',LOG.s(i),'e',LOG.e(i),'v',LOG.v(i), ...
           'ego',[LOG.x(i) LOG.y(i)],'yaw',LOG.yaw(i), ...
           'tracks',LOG.tracks{i},'cmd',LOG.cmd{i}, ...
           'HazardNote',LOG.capWhy(i),'Chapter',LOG.chapter(i));
end

function v = pick(y, p)
if isempty(y), v = NaN; else, v = y(max(1,min(numel(y),ceil(p*numel(y))))); end
end

% =========================================================================
%                              PLUMBING
% =========================================================================
function s = fill(s, f, dflt)
if ~isfield(s,f) || isempty(s.(f)), s.(f) = dflt; end
end

function k = routeStamp(D)
%ROUTESTAMP  So a cache built for one route is never played back for another.
%   Covers the road, the hazards and the traffic - anything that changes what
%   the planner would decide.
% TEnd is DELIBERATELY NOT IN THE STAMP. It does not change what the planner
% would decide at any station - it only says how long to keep going - so
% folding it in here made a cache built for 88 s useless to a 64 s request and
% silently triggered a two-minute recompute. See useCache below.
h = sprintf('%.3f|%.3f|%d|%.3f|sensed%d|', D.W.Path.Len, D.W.Width, ...
            numel(D.Hazards), D.SStart, isfield(D,'Sensed') && D.Sensed);
for k2 = 1:numel(D.Hazards)
    z = D.Hazards(k2);
    h = [h sprintf('%s,%.2f,%.2f,%.2f,%.2f,%.2f;', z.Type, z.Station, z.Lateral, ...
                   nz(z.Radius), nz(z.SpeedCap), z.Zone)]; %#ok<AGROW>
end
% THE TRAFFIC, HASHED BY WHAT IT DOES - NOT BY HOW MANY FRAMES OF IT EXIST.
% A first version hashed numel(D.Tracks), which is a CELL ARRAY WITH ONE ENTRY
% PER TIME STEP, built as ceil(TEnd/0.05). So taking TEnd out of the stamp
% above achieved nothing: it walked straight back in through the track count,
% and a bare demo_play('demo1') still missed a good cache built at another
% TEnd. Caught by the integrator chat, twice, against a freshly rebuilt cache.
%
% What actually changes what the planner decides is WHICH actors exist, WHERE
% they start and HOW THEY MOVE - so all three are hashed off the opening frame
% and nothing about the clock is. Velocity is in here deliberately: the old
% hash took only ClassID and Position(1), so changing an oncoming vehicle's
% SPEED (or its y, on a road that runs diagonally) left the stamp identical
% and would have silently replayed a stale cache. That hole was mine and is
% closed here rather than left for someone to find during a demo.
T1 = D.Tracks; if iscell(T1), if isempty(T1), T1 = emptyTrackList(); else, T1 = T1{1}; end, end
h = [h sprintf('|n%d', numel(T1))];
for k2 = 1:numel(T1)
    h = [h sprintf('|%d@%.2f,%.2f>%.2f,%.2f', T1(k2).ClassID, ...
                   T1(k2).Position(1), T1(k2).Position(2), ...
                   T1(k2).Velocity(1), T1(k2).Velocity(2))]; %#ok<AGROW>
end
k = h;
end

function v = nz(x), if isfinite(x), v = x; else, v = -1; end, end

function saveCache(f, LOG)
d = fileparts(f);
if ~isfolder(d), mkdir(d); end
save(f, 'LOG', '-v7.3');
q = dir(f);
fprintf('cached to %s (%.0f MB)\n', f, q.bytes/1e6);
end
