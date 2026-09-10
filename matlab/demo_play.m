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
%   WHAT THIS DEMO DOES NOT DO - AND THE NAMED NEXT STEP
%   =====================================================================
%   THE ROAD USERS HANDED TO THE PLANNER ARE GROUND TRUTH. builtinTracks below
%   writes exact poses: no sensor noise, no dropout, no bearing blind spot, no
%   tracker. The planner's DECISIONS are real; what it is deciding ABOUT is
%   given to it. sc.plannerView states this on screen, in the model panel, so
%   it is disclosed to an audience rather than only to whoever thinks to ask.
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
%   NEXT STEP, NAMED SO NOBODY HAS TO REDISCOVER IT: sc.senseRig / sc.senseStep
%   (Chat 4, 7 Sep) sense from the EGO'S OWN pose each step, which is exactly
%   the property this needs and the property the old batch path lacked. Wiring
%   them in here in place of builtinTracks is what would make this demo
%   genuinely perception-driven. It was deliberately NOT done on the night of
%   the internal round: it introduces noise, dropout and the blind spot into a
%   run that currently completes cleanly, hours before presenting, with no
%   time to find out what that does to the cow pass. Upside a truer demo,
%   downside no demo. That trade changes completely with a day to test it.
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
    opts.PlanEvery  (1,1) double  = 1
    opts.TEnd       (1,1) double  = NaN      % s, override the route's own length
    opts.Interactive(1,1) logical = true
    opts.Snap       (1,1) string  = ""       % write a frame here and exit
    opts.Cow        (1,1) string  = "blocking" % "blocking" | "verge" | "none"
end

here = fileparts(mfilename('fullpath'));
addpath(here);
assert(~isempty(which('sih.planner.planContingency')), ...
    'sih.planner is not on the path - the +sih repo is not where planSeat expects it');

DT = 0.05;                                    % s, the seat's own step (20 Hz)

% ================================================================= the route
D = loadRoute(route, opts.Cow);
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
cacheFile = fullfile(here, 'renders', sprintf('demo_%s.mat', tag));
if opts.Live
    LOG = [];                                  % computed inside the draw loop
elseif ~opts.Recompute && isfile(cacheFile)
    L = load(cacheFile);
    [LOG, why] = useCache(L, D, DT);
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

% ================================================================= play it
R = play(D, LOG, DT, opts);
end

% =========================================================================
%                             ROUTE LOADING
% =========================================================================
function D = loadRoute(route, cowMode)
%LOADROUTE  Chat 3 delivers sc.demo1Route / sc.demo2Route. Until they land this
%   falls back to a route built here, so this file is never blocked waiting.
%   DELIBERATELY LIBERAL about what it accepts back: a struct with .W/.Hazards,
%   or a bare hazard array, both work, so the two chats cannot deadlock over the
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
    % Chat 3's sc.demo1Route / sc.demo2Route return exactly this: the hazards
    % only. The road, the cow and the traffic still come from the built-in
    % route - but the title must say so honestly rather than keep calling
    % itself a stand-in when the real hazards are in fact loaded.
    D = builtinRoute(route, cowMode);  D.Hazards = got;
    D.Title = sprintf('SIH26037  %s - hazards from %sRoute, road from sc.s1world', ...
                      upper(route), route);
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
D.Tracks = builtinTracks(W, D.CS, cowMode, ceil(D.TEnd/0.05), 0.05);
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
% {ClassID, s0, lateral, extent, speed along the route (- = oncoming), extra yaw}
% The cow's extra yaw is pi/2 - BROADSIDE, which is what makes her LENGTH the
% thing crossing the road, and that is the assumption sc.s1geom's whole gap
% arithmetic is built on. Getting it wrong would silently halve her footprint.
spec = { 10, CS,  cowE, [G.CowLateral 0.55 1.35],   0, cowYaw ; ...
          1, 260, -2.0, [4.20 1.75 1.50],       -11.0, 0 ; ...
          5, 610, -1.9, [1.90 0.75 1.30],        -9.0, 0 };
TR = cell(1, n);
for i = 1:n
    t  = (i-1)*DT;
    Ti = emptyTrackList();
    for k = 1:size(spec,1)
        if ~isfinite(spec{k,3}), continue; end       % Cow="none"
        u = spec{k,2} + spec{k,5}*t;
        if u < 2 || u > P.Len - 2, continue; end     % gone past, or not here yet
        [xy, hdg] = P.at(u, spec{k,3});
        yaw = hdg + spec{k,6};  vel = [0 0 0];
        if spec{k,5} < 0
            yaw = hdg + pi;
            vel = spec{k,5}*[cos(hdg) sin(hdg) 0];   % world-frame, as S1 asks
        end
        Ti(end+1) = struct('TrackID',uint32(900+k),'ClassID',uint8(spec{k,1}), ...
            'Position',[xy 0],'Velocity',vel,'Extent',spec{k,4}, ...
            'Yaw', yaw, 'Existence',1,'Age',uint32(30),'SensorMask',uint8(1)); %#ok<AGROW>
    end
    TR{i} = Ti;
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
TUNE = struct( ...
    'TermSpeeds',   [0 4 8 11 14.4], ...
    'LatOffsets',   [-2.5 -1.585 -0.9 0 0.9 1.75 2.6], ...
    'Horizon',      4.0, 'TimeRes', 0.1, 'Inflation', 0.0, ...
    'EgoWidth',     1.8, 'EgoLength', 4.7, 'Wheelbase', 2.7, ...
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
st = struct();  s = D.SStart;  e = 1.75;  ev = 0;
lastCmd = struct('v',v,'e',e);
tRun = tic;  nFail = 0;  reachedEnd = false;
fprintf('running the real planner over %d steps (this is the slow part - it is\n', n);
fprintf('cached afterwards so the demo itself never waits for it)\n');
for i = 1:n
    t = (i-1)*DT;
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));
    ctx = struct('s',s,'e',e,'v',v,'t',t, ...
        'W',W,'Path',P,'RefPath',RefPath,'Tracks',tracksAt(D,i), ...
        'EgoXY',xy,'EgoYaw',hdg,'Kappa',kappaV(ki),'CruiseV',D.CruiseV);
    fn = fieldnames(TUNE);
    for f = 1:numel(fn), ctx.(fn{f}) = TUNE.(fn{f}); end

    % ---- TIER 2: hazards narrow the corridor the planner may use ----------
    % planSeat reads ctx.ELo/ctx.EHi as supported overrides of its lateral
    % clamp, so a barrier standing in part of the carriageway genuinely takes
    % that band away from the real planner rather than being drawn on top of it.
    [eLoH, eHiH] = corridorFrom(D.Hazards, s, W, TUNE.EgoWidth);
    if isfinite(eLoH), ctx.ELo = eLoH; end
    if isfinite(eHiH), ctx.EHi = eHiH; end

    if mod(i-1, planEvery) == 0
        [cmd, st] = sc.planSeat(st, ctx);
        lastCmd = cmd;
        if isfield(cmd,'PlanFailed') && strlength(cmd.PlanFailed) > 0, nFail = nFail + 1; end
    else
        cmd = lastCmd;  cmd.State = st.State;  cmd.Note = st.Note;
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
fprintf('planner run done in %.1f s (%d plan failures)\n', toc(tRun), nFail);
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
        'Creeping','VCap'};
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
skip = {'Stamp','ReachedEnd','PlannerFP'};
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

function [eLo, eHi] = corridorFrom(H, s, W, egoW)
%CORRIDORFROM  A hazard standing IN the carriageway takes that lateral band
%   away. Returns NaN when no hazard narrows anything, so the caller leaves
%   planSeat's own Phase-6 bounds alone rather than re-deriving them here.
%   Only ever NARROWS - a hazard can never widen the road.
hw   = W.Width/2;
eLo0 = -(hw - 0.95);  eHi0 = (hw - 0.95) + 0.35;    % planSeat's own defaults
eLo  = eLo0;  eHi = eHi0;  touched = false;
for k = 1:numel(H)
    if ~ismember(string(H(k).Type), ["barrier","damage"]), continue; end
    [lo, hi] = stretch(H(k));
    if s < lo - 12 || s > hi, continue; end          % 12 m of approach to plan in
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
        eHi = min(eHi, blockLo);  touched = true;
    elseif blockLo <= eLo0 + 0.05                    % it eats the RIGHT edge
        eLo = max(eLo, blockHi);  touched = true;
    else                                             % mid-carriageway: keep the
        if (eHi0 - blockHi) >= (blockLo - eLo0)      % wider of the two sides
            eLo = max(eLo, blockHi);
        else
            eHi = min(eHi, blockLo);
        end
        touched = true;
    end
end
if ~touched || eHi - eLo < 2.2                       % never squeeze below a car's
    eLo = NaN;  eHi = NaN;                           % width - that is not a corridor,
end                                                  % it is a wall, and planSeat's
end                                                  % own bounds are the honest fallback

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
    'Interactive',opts.Interactive,'EnableInjection',opts.Interactive));

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
% Draw frame 1 BEFORE starting the clock. Building the figure, the road, and
% fourteen labelled hazards is a genuine one-off cost (measured at ~14 s the
% first time MATLAB touches these graphics paths) and charging it to the
% playback clock would make the car appear to sprint to catch up.
sc.plannerView('step', frameOf(LOG, 1));
tClock = tic;  pausedFor = 0;  quit = false;  drawn = 1;
for i = 2:n
    ctl = sc.plannerView('step', frameOf(LOG, i));
    ft(i) = ctl.LastFrame_ms;
    if ctl.Quit, quit = true; break; end
    if ctl.InjectPending
        [hs, he, accepted, why] = sc.clickToRoad(D.W.Path, D.W, ctl.InjectXY, LOG.s(i));
        if accepted
            liveHz = hz("barrier", hs, he, "LIVE OBSTACLE - judge click", 0.45, NaN, 0);
            D.Hazards(end+1) = liveHz;
            sc.plannerView('addHazard', struct('Hazard',liveHz));
            sc.plannerView('status', struct('Text',sprintf( ...
                'LIVE OBSTACLE PLACED AT s=%.1f m, e=%+.1f m', hs, he)));
        else
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
end
elapsed = toc(tClock);
ft = ft(1:max(drawn,1));  lag = lag(1:max(drawn,1));
y = sort(ft(isfinite(ft)));
R = struct('Frames',drawn,'Elapsed_s',elapsed,'Quit',quit, ...
           'MeanFrame_ms',mean(ft,'omitnan'), ...
           'MedianFrame_ms',median(ft,'omitnan'), ...
           'P95Frame_ms',pick(y,0.95), 'MaxFrame_ms',max(ft), ...
           'OverBudget',sum(ft > 1000*DT), 'MaxLag_s',max(abs(lag),[],'omitnan'));
fprintf('\n--- PLAYBACK ---\n');
qtxt = 'ran to the end'; if quit, qtxt = 'quit early'; end
fprintf('  %d frames in %.1f s wall clock (%s)\n', drawn, elapsed, qtxt);
fprintf('  frame work: mean %.2f ms  median %.2f  p95 %.2f  max %.2f\n', ...
        R.MeanFrame_ms, R.MedianFrame_ms, R.P95Frame_ms, R.MaxFrame_ms);
fprintf('  frames over the %.0f ms budget: %d (%.2f%%)\n', 1000*DT, R.OverBudget, ...
        100*R.OverBudget/max(drawn,1));
fprintf('  worst drift from the real clock: %.3f s\n', R.MaxLag_s);
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

function [LOG, why] = useCache(L, D, DT)
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
h = sprintf('%.3f|%.3f|%d|%.3f|', D.W.Path.Len, D.W.Width, ...
            numel(D.Hazards), D.SStart);
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
