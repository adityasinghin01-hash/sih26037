%S1_ACTION_RUN  PHASE 3 - the S1 action. Actors, placeholder driver, and the log.
%
%   TWO PASSES, and the split is the architecture:
%     1. Integrate the PLACEHOLDER DRIVER alone. It senses nothing, so its timeline is
%        deterministic and does not depend on the traffic. That gives the beat times.
%     2. Build the scripted actors so they ARRIVE ON THOSE BEATS, then step the
%        drivingScenario alongside the ego and log every pose.
%
%   The ego is integrated here rather than given a trajectory, because a planner has to
%   be able to react and a baked trajectory cannot. sc.s1drive is the SEAT.

here = fileparts(mfilename('fullpath')); addpath(here);
fprintf('\n================ S1 ACTION, PHASE 3 ================\n');
W = sc.s1world();
P = W.Path;  CS = W.CowStation;

DT = 0.05;  T_END = 62.0;                     % S1: "THE ACTION - 62 seconds"
[~, zd] = sc.meshes("zebu");  [~, cd] = sc.meshes("car");

% the geometry the driver is handed. DERIVED from the meshes, never typed.
ctx0.cowStation = CS;
% ONE SOURCE FOR THE GAP ARITHMETIC: sc.s1geom. This block used to hardcode
% cowStopE = 0.65 while sc.s1actors derived it, and when she was moved to stop
% BROADSIDE the two disagreed by 0.7 m - the log printed "free 3.12 m, margin 0.613"
% and "free 3.83 m, margin 0.965" three lines apart, and the DRIVER was being handed
% the wrong one. PASS 1 needs this before any actor exists, which is exactly why the
% arithmetic cannot live inside the actor builder.
G = sc.s1geom(W);
ctx0.cowStopE   = G.CowStopE;
ctx0.cowLateral = G.CowLateral;
ctx0.freeWidth  = G.FreeWidth;
ctx0.passE      = G.PassE;
ctx0.margin     = G.Margin;
ctx0.reveal     = CS - W.RevealDistance;
% Beat STATIONS are ours - this route is 610 m of real map, not the written 410 m -
% but they are chosen so the first beat lands on the written TIME: 162 m at 52 km/h
% is t = 11.2 s exactly, which is S1's "oncoming motorcycle on OUR side".
% THE EGO DOES NOT START AT ZERO, and that is forced, not stylistic. An OVERTAKING
% vehicle is faster than us, so to draw level at a given station it must have started
% BEHIND our start - and with the ego at chainage 0 there is no road behind it. Its
% start clamped to 0, which put it alongside the ego at t = 0.65 s instead of the
% written 6.4 s. The collision check found it. 25 m of run-up fixes it, and sSlow
% moves with it so the first beat still lands on the written 11.2 s.
ctx0.sStart = 25;
ctx0.sSlow = 187;  ctx0.sWrongSide = 185;  ctx0.sTractor = 235;  ctx0.sOvertake = 92;

% HOW FAR SHORT OF HER THE EGO MUST STOP, so that it can finish crossing into the
% gap BEFORE it draws level. Derived from the lateral distance, the pass speed and the
% crab-angle limit - all three of which are set elsewhere - plus the two half-lengths
% and a margin. Hand-picking this number failed twice; see sc.s1drive.
PASS_V = 8/3.6;  LANE_E = 1.75;
latNeed = abs(ctx0.passE - LANE_E);
% RE-DERIVED BY SIMULATING THE ACTUAL LATERAL MODEL (sc.lateralStep), not a
% closed-form estimate of it. The old formula (latNeed / (tand(CRAB)*PASS_V))
% was exact for the OLD flat-rate motion; sc.lateralStep's ease-in/ease-out
% covers the same distance more slowly (lower average rate than its own
% peak), so reusing that formula under the new model would understate the
% run-up needed - the identical class of error "hand-picking this number
% failed twice" already warns about, just arriving from the model changing
% under it instead of from a bad guess.
[eSim, evSim, tSim] = deal(LANE_E, 0, 0);
while abs(eSim - ctx0.passE) > 1e-3 && tSim < 60
    [eSim, evSim] = sc.lateralStep(eSim, evSim, ctx0.passE, PASS_V, DT);
    tSim = tSim + DT;
end
ctx0.commitRunUp = PASS_V*tSim + zd(1)/2 + cd(1)/2 + 3.0;
fprintf('geometry: free %.2f m | ego %.2f m | margin %.3f m each side | pass at e=%+.3f m\n', ...
        ctx0.freeWidth, cd(2), ctx0.margin, ctx0.passE);
fprintf('lateral move %.2f m, eased, takes %.2f s -> stop %.1f m short of her\n', ...
        latNeed, tSim, ctx0.commitRunUp);

% ---------------------------------------------------------------- PASS 1: the driver
A_LON = 1.8; D_LON = 3.2; R_LAT = 0.75;       % accel, decel, lateral rate limits
[log1, beatsRaw] = integrate(P, ctx0, DT, T_END, A_LON, D_LON, R_LAT);
fprintf('ego starts at station %.0f m\n', ctx0.sStart);

fprintf('\n--- PASS 1: the placeholder driver alone (it senses nothing) ---\n');
fprintf('  %-10s %8s %8s   %s\n', 'state', 't (s)', 'station', 'written S1');
written = struct('CRUISE',0, 'SLOW',11.2, 'CRUISE2',26.1, 'SIGHTED',29.0, ...
                 'SLOWING',30.7, 'PROBE',32.8, 'ABORT',36.6, 'COMMIT',42.7, 'CLEAR',47.0);
fn = fieldnames(beatsRaw);
for k = 1:numel(fn)
    b = beatsRaw.(fn{k});
    if isfield(written, fn{k})
        fprintf('  %-10s %8.2f %8.1f   %.1f  (%+.1f s)\n', fn{k}, b.t, b.s, ...
                written.(fn{k}), b.t - written.(fn{k}));
    else
        fprintf('  %-10s %8.2f %8.1f\n', fn{k}, b.t, b.s);
    end
end

% ---------------------------------------------------------------- PASS 2: the traffic
beats.tCowStep   = beatsRaw.SLOWING.t;        % she steps out as we start braking
beats.tAutoPass  = beatsRaw.COMMIT.t - 0.8;   % the auto clears just before we commit
% It has to MEET us. Placing it at a fixed station put it at 185 m while the ego was
% already at 194 m, so they had crossed before the shot: the frame showed empty road.
% An oncoming vehicle's station is therefore the EGO'S station at the meeting time.
beats.tWrongSide = beatsRaw.SLOW.t + 3.4;
beats.sWrongSide = interpS(log1, beats.tWrongSide);
beats.tTractor   = interpT(log1, ctx0.sTractor);  beats.sTractor = ctx0.sTractor;
beats.tOvertake  = interpT(log1, ctx0.sOvertake); beats.sOvertake = ctx0.sOvertake;

fprintf('\n--- PASS 2: the scripted traffic, placed to arrive on those beats ---\n');
A = sc.s1actors(W, beats, 'SampleTime', DT, 'StopTime', T_END + 8);

% the actors must agree with the geometry PASS 1 was driven on, or the driver planned
% through a gap the render does not draw
assert(abs(A.FreeWidth - ctx0.freeWidth) < 1e-9 && ...
       abs(A.CowStopE  - ctx0.cowStopE)  < 1e-9, "sc:geomSplit", ...
    'the actors and the driver disagree about the gap: %.4f vs %.4f m', ...
    A.FreeWidth, ctx0.freeWidth);

% THERE IS NO LONGER A TURN, AND REMOVING IT MADE THE SCENARIO MORE HONEST.
% She used to be rotated PARALLEL to the road over 2 s after stopping, purely so the
% written 0.70 m occupied band would close. That rotation was authored and labelled as
% authored - but it is not what a cow does, and it is not what the frame needs: an
% animal standing ALONG the lane does not read as blocking it. smoothTrajectory yaws
% an actor along its direction of travel, so having crossed the road she is already
% broadside; the fix is to let her stay that way and stop her 1.41 m sooner, which
% leaves the identical 3.83 m gap (see sc.s1actors). One authored behaviour removed.
who = containers.Map('KeyType','double','ValueType','char');
who(A.Cow.ActorID)='cow'; who(A.Auto.ActorID)='auto';
who(A.Wrong.ActorID)='moto_wrong'; who(A.Over.ActorID)='moto_over';
who(A.Tractor.ActorID)='tractor'; who(A.Trolley.ActorID)='trolley';
for h = A.Herd, who(h.ActorID)='cow'; end
DIMS = struct('cow',zd, 'auto',dimOf("auto"), 'moto_wrong',dimOf("motorcycle"), ...
              'moto_over',dimOf("motorcycle"), 'tractor',dimOf("tractor"), ...
              'trolley',dimOf("trolley"));
[~, hdgRoad] = P.at(CS, 0);
S = A.Scenario;  k = 0;  poses = {};  tS = [];  tStop = NaN;
while advance(S)
    k = k + 1;  tS(k) = S.SimulationTime;
    if isnan(tStop) && norm(A.Cow.Velocity(1:2)) < 1e-4, tStop = tS(k); end
    poses{k} = actorPoses(S);                                           %#ok<SAGROW>
end
% MEASURED, not designed: how far off broadside does smoothTrajectory actually leave
% her? She walks along a constant station varying only her offset, so her heading
% should be exactly across the road, and the gap arithmetic below assumes it.
% EITHER NOSE SENSE IS BROADSIDE. What the gap arithmetic needs is that her LENGTH
% lies across the road; which end the head is at does not change one millimetre of it.
% The first version tested against +90 only and fired at "-180.00 deg off square" -
% she was exactly broadside, facing the other way.
offBroad = min(abs(wrapTo180(A.Cow.Yaw - (rad2deg(hdgRoad) + 90))), ...
               abs(wrapTo180(A.Cow.Yaw - (rad2deg(hdgRoad) - 90))));
fprintf('  cow stops at t = %.2f s and STAYS BROADSIDE (%.2f deg off square to the road)\n', ...
        tStop, offBroad);
assert(abs(offBroad) < 3.0, "sc:cowNotBroadside", ...
    ['she ends %.1f deg off square to the road; the gap arithmetic assumes she ' ...
     'presents her length across it'], offBroad);
fprintf('  scenario stepped %d times, ended at t = %.2f s of a %.0f s StopTime\n', ...
        k, tS(end), T_END+8);
if tS(end) < T_END + 8 - 2*DT
    fprintf('  ** advance() STOPPED EARLY - every trajectory had finished. **\n');
else
    fprintf('  ran the full StopTime, because every moving actor was given a\n');
    fprintf('  trajectory that spans it. That is deliberate: advance() DOES return\n');
    fprintf('  false the moment the last trajectory ends (measured separately - a\n');
    fprintf('  3-waypoint cow alone ended a 14 s scenario at 5.02 s), so a 62 s film\n');
    fprintf('  must either run on its own clock or keep one trajectory alive.\n');
end

% ---------------------------------------------------------------- the hero claim
cowE = zeros(1,k); cowV = zeros(1,k);
for i = 1:k
    p = poses{i}([poses{i}.ActorID] == A.Cow.ActorID);
    [~, cowE(i)] = P.inverse(p.Position(1:2));
    cowV(i) = norm(p.Velocity(1:2));
end
iCross = find(cowE <= W.Width/2, 1);
iStop  = find(cowV < 1e-4 & (1:k) > iCross, 1);
assert(~isempty(iStop), "sc:cowNeverStops", "the cow never came to rest");
% The GAIT LEG is the constant-speed part - verge to the start of the deceleration.
% That is the leg the stride x cadence claim is about; the last 1.85 m is a
% jerk-limited stop and nothing pretends otherwise.
% DERIVED, NOT TYPED. This was a hardcoded 2.50 m, which happened to be the start of
% the deceleration only while she stopped at e = 0.65. She stops at 1.355 now, so
% 2.50 m fell INSIDE the braking leg and the gait claim was being scored against a
% window that included the brake - it read 78 % where the constant-speed leg is
% actually clean. The window is now the deceleration start, wherever that is.
gaitStart = ctx0.cowStopE + 1.85;          % DECEL in sc.s1actors
gaitLeg = cowV(cowE > gaitStart & cowE < 4.90);
whole   = cowV(cowE > ctx0.cowStopE + 0.01 & cowE < 4.90);
fprintf('\n--- THE HERO: does the cow walk at the gait speed and then never move? ---\n');
fprintf('  crosses the carriageway edge at t = %.2f s\n', tS(iCross));
fprintf('  GAIT LEG (verge -> %.2f m): %.4f-%.4f m/s, %.0f%% within 0.5%% of %.4f\n', ...
        gaitStart, ...
        min(gaitLeg), max(gaitLeg), ...
        100*mean(abs(gaitLeg - A.Gait) < 0.005*A.Gait), A.Gait);
fprintf('  whole crossing incl. the 1.85 m stop: %.4f-%.4f m/s, %.0f%% at gait\n', ...
        min(whole), max(whole), 100*mean(abs(whole - A.Gait) < 0.005*A.Gait));
fprintf('  stops at t = %.2f s, e = %+.4f m (target %+.4f)\n', tS(iStop), cowE(end), ctx0.cowStopE);
fprintf('  MOVEMENT AFTER STOPPING: %.6f m over the remaining %.1f s\n', ...
        max(abs(cowE(iStop:end) - cowE(end))), tS(end)-tS(iStop));

% ---------------------------------------------------------------- COLLISIONS
% NOTHING WAS CHECKING THIS. The wrong-side motorcycle was drifting back to its own
% side at a fraction of its OWN trajectory rather than relative to the meeting, so at
% the moment it passed the ego it was still in our lane and the two footprints
% OVERLAPPED - and every other assertion passed. Separation is tested in path
% coordinates, with each actor's extents rotated by its own yaw.
minSep = inf; worst = ''; tWorst = NaN;
egoL = cd(1); egoW = cd(2);
for i = 1:min(numel(log1.t), numel(poses))
    pp = poses{i};
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        dq = DIMS.(who(pp(q).ActorID));
        [sq, eq] = P.inverse(pp(q).Position(1:2));
        [~, hq] = P.at(sq, 0);
        th = deg2rad(pp(q).Yaw) - hq;                     % yaw relative to the road
        aL = abs(dq(1)*cos(th)) + abs(dq(2)*sin(th));     % extents along/across the road
        aW = abs(dq(1)*sin(th)) + abs(dq(2)*cos(th));
        gapS = abs(sq - log1.s(i)) - (aL + egoL)/2;
        gapE = abs(eq - log1.e(i)) - (aW + egoW)/2;
        sep  = max(gapS, gapE);                           % >0 means clear on some axis
        if sep < minSep, minSep = sep; worst = who(pp(q).ActorID); tWorst = log1.t(i); end
    end
end
fprintf('\n--- SEPARATION FROM EVERY SCRIPTED ACTOR ---\n');
fprintf('  closest approach %.3f m to the %s at t = %.2f s\n', minSep, worst, tWorst);
assert(minSep > 0, "sc:collision", ...
    "the ego overlaps the %s by %.3f m at t = %.2f s", worst, -minSep, tWorst);

% ---------------------------------------------------------------- HER ACTUAL BAND
% Measured off the mesh at the pose she really ends in, projected onto the road normal.
pEnd = poses{end}([poses{end}.ActorID] == A.Cow.ActorID);
mz = sc.meshes("zebu");  yv = mz.Vertices;
th = deg2rad(pEnd.Yaw);
wx = pEnd.Position(1) + yv(:,1)*cos(th) - yv(:,2)*sin(th);
wy = pEnd.Position(2) + yv(:,1)*sin(th) + yv(:,2)*cos(th);
nrm = [-sin(hdgRoad), cos(hdgRoad)];
lat = (wx - pEnd.Position(1))*nrm(1) + (wy - pEnd.Position(2))*nrm(2) + ctx0.cowStopE;
% MEASURED AGAINST HER LENGTH NOW, NOT HER WIDTH. She stops broadside, so the
% lateral extent this must reproduce is zd(1) = 2.05 m. `yawPar` is gone with the
% authored rotation, so squareness is measured against the road normal directly.
offSq = min(abs(wrapTo180(pEnd.Yaw - (rad2deg(hdgRoad) + 90))), ...
            abs(wrapTo180(pEnd.Yaw - (rad2deg(hdgRoad) - 90))));
fprintf('\n--- HER ACTUAL FOOTPRINT, off the mesh at the pose she ends in ---\n');
fprintf('  final yaw %.1f deg vs road %.1f deg -> %.2f deg off SQUARE to the road\n', ...
        pEnd.Yaw, rad2deg(hdgRoad), offSq);
fprintf('  occupies e = %+.3f to %+.3f m  -> %.3f m of lateral extent (design %.3f)\n', ...
        min(lat), max(lat), max(lat)-min(lat), ctx0.cowLateral);
fprintf('  i.e. %.2f-%.2f m in from the left edge\n', ...
        W.Width/2 - max(lat), W.Width/2 - min(lat));
fprintf('  written S1 says 2.5-3.2 m, which is a 0.70 m band - that is the animal seen\n');
fprintf('  END-ON, i.e. the written arithmetic assumed a cow standing ALONG the road.\n');
% Her LEADING edge is the smaller e - she walks from the left verge (large e) toward
% the centreline (e = 0), so min(lat) is the nose.
fprintf('  Her nose ends %.3f m short of the centreline (e = %+.3f).\n', ...
        min(lat), min(lat));
assert(abs((max(lat)-min(lat)) - ctx0.cowLateral) < 0.03, "sc:cowBand", ...
    ['the cow occupies %.3f m of lateral extent, the arithmetic assumes %.3f m - ' ...
     'she is %.2f deg off square to the road'], max(lat)-min(lat), ctx0.cowLateral, offSq);

% ---------------------------------------------------------------- THE CLEARANCE
% Not the designed number - the number the ego ACTUALLY achieved, because its lateral
% motion is rate-limited and it may not have reached the pass line by the time it is
% alongside her. This is the S1 result in one line.
alongside = abs(log1.s - CS) < zd(1)/2 + cd(1)/2;
assert(any(alongside), "sc:neverAlongside", "the ego never drew level with the cow");
egoL = log1.e(alongside) + cd(2)/2;                 % ego's left flank (toward the cow)
gapToCow = (ctx0.cowStopE - ctx0.cowLateral/2) - max(egoL);
gapToEdge = min(log1.e(alongside)) - cd(2)/2 - (-W.Width/2);
fprintf('\n--- THE CLEARANCE ACHIEVED, measured off the log ---\n');
fprintf('  ego lateral while alongside: %+.3f to %+.3f m (pass line %+.3f)\n', ...
        min(log1.e(alongside)), max(log1.e(alongside)), ctx0.passE);
fprintf('  gap to the cow  %.3f m   |   gap to the right edge %.3f m\n', gapToCow, gapToEdge);
fprintf('  speed past her  %.2f km/h (written 8)\n', 3.6*max(log1.v(alongside)));
assert(gapToCow >= 0.90 && gapToEdge >= 0.90, "sc:clearance", ...
    "clearance %.3f / %.3f m - SPEC requires >= 0.90 m each side", gapToCow, gapToEdge);

assert(abs(cowE(end) - ctx0.cowStopE) < 1e-3, "sc:cowStop", ...
    "cow stopped at e = %+.4f, the gap arithmetic needs %+.4f", cowE(end), ctx0.cowStopE);
assert(max(abs(cowE(iStop:end) - cowE(end))) < 1e-6, "sc:cowMoves", "the cow moved after stopping");
assert(all(isfinite(log1.s)) && all(isfinite(log1.e)), "sc:egoNaN", "ego log has NaN");

save(fullfile(here,'renders','s1_action.mat'), 'log1', 'beatsRaw', 'beats', 'tS', 'cowE', 'cowV');
assert(exist('poses','var')==1, 'sc:noPoses', 'poses were not captured');
fprintf('\nlogged %d ego samples and %d scenario samples\n', numel(log1.t), k);
fprintf('====================================================\n\n');

% =======================================================================================
function d = dimOf(n)
[~, d] = sc.meshes(n);
end

function [L, beats] = integrate(P, c, DT, T, aUp, aDn, rLat)
%INTEGRATE  Step the ego against sc.s1drive under acceleration-limited
%   longitudinal AND lateral motion (sc.lateralStep) - a smooth ease in/out
%   lane change, not a flat-rate slide that starts and stops instantly.
st = struct();  s = c.sStart;  e = 1.75;  ev = 0;  v = 52/3.6;  n = round(T/DT);
L = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
           'State',strings(1,n),'Note',strings(1,n));
beats = struct();
for i = 1:n
    t = (i-1)*DT;
    ctx = c;  ctx.s = s;  ctx.e = e;  ctx.v = v;  ctx.t = t;
    [cmd, st] = sc.s1drive(st, ctx);
    if st.Changed || i == 1
        beats.(char(st.State)) = struct('t', t, 's', s);
    end
    dv = cmd.v - v;                              % rate-limited longitudinal
    v  = v + max(-aDn*DT, min(aUp*DT, dv));
    v  = max(0, v);
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', rLat);
    s  = min(P.Len, s + v*DT);
    L.t(i)=t; L.s(i)=s; L.e(i)=e; L.v(i)=v; L.State(i)=st.State; L.Note(i)=st.Note;
end
end

function t = interpT(L, s)
i = find(L.s >= s, 1);
if isempty(i), t = L.t(end); else, t = L.t(i); end
end

function s = interpS(L, t)
i = find(L.t >= t, 1);
if isempty(i), s = L.s(end); else, s = L.s(i); end
end
