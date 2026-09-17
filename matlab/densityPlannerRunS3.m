function info = densityPlannerRunS3(opts)
%DENSITYPLANNERRUNS3  Run the real planner in S3's full-density galli.
%
%   densityPlannerRunS3()
%
%   Builds sc.s3world/sc.s3density, adds demo_play.m's three actorSpecS3
%   negotiation actors, calls sc.planSeat every 0.05 s, and integrates the
%   returned target speed/lateral offset with demo_play.m's S3 limits. The
%   measured squeeze is represented by demo_play.m's ramped corridor and
%   MirrorsFolded mechanism. Evidence is written through
%   sih.metrics.writeDemoResults to results/<run>/.
%
%   opts.PlanEvery  plan every N steps, holding the command between - demo_play's
%                   own shipped setting is 3 (read from its config.json). This
%                   runner was re-planning at every 0.05 s step (20 Hz), which the
%                   real demo never does; that is 3x the planner calls for a
%                   fidelity nothing claims, and it is why S3 blew a 50-minute
%                   timebox twice. PlanEvery=1 reproduces the earlier behaviour.
%
%   This is deliberately separate from densityPlannerRun.m. S1 records its
%   negotiation traffic through s1_action_run.m; S3 generates lateral actor
%   motion in closed form and additionally changes the initial state, cruise,
%   ego width, corridor floor/lead-in, integration limits and completion rule.
%   Sharing the loop before both runners can be executed together would put the
%   already-measured S1 path at unnecessary regression risk.

arguments
    opts.PlanEvery (1,1) double = 3
    opts.Reactive  (1,1) logical = false  % PHASE 8 - agents respond to the ego
    opts.GateCfg   struct = struct()      % PHASE 5 - ML gate config; empty = closed
    opts.Quiet     (1,1) logical = false
end

here = fileparts(mfilename('fullpath'));
addpath(here);
assert(~isempty(which('sih.planner.planContingency')), ...
    'sih.planner is not on the path - the +sih repo is not where densityPlannerRunS3 expects it');

W = sc.s3world();
[densitySpec, densityTags] = sc.s3density();
negSpec = iActorSpecS3();
P = W.Path;
HZ = sc.demo3Route();
G = sc.s3geom();

% Exact S3 route values from demo_play.m's builtinRouteS3. MinCorridor is
% centreline slack, not raw free width: it must reject the 0.05 m mirrors-out
% slack and accept the 0.25 m folded slack.
S_START = 5;
CRUISE_V = 14/3.6;
MIN_CORRIDOR = 0.10;
CORRIDOR_LEAD_IN = 100;
E_START = 0.9;
fullSlack = G.FreeWidth_m - G.EgoWidthMirrors_m;
foldedSlack = G.FreeWidth_m - G.EgoWidthFolded_m;
assert(fullSlack < MIN_CORRIDOR && foldedSlack >= MIN_CORRIDOR, ...
    'densityPlannerRunS3:badSqueezeFloor', ...
    'MinCorridor %.3f must reject %.3f m unfolded slack and accept %.3f m folded slack.', ...
    MIN_CORRIDOR, fullSlack, foldedSlack);

% Exact planner tuning from demo_play.m's runPlanner, with S3's authoritative
% mirrors-out width from sc.s3geom rather than the S1/S2 default.
RefPath = referencePathFrenet(P.P);
kappaV = P.curvature();
TUNE = struct( ...
    'TermSpeeds',   [0 4 8 11 14.4], ...
    'LatOffsets',   [-2.5 -1.585 -0.9 0 0.9 1.75 2.6], ...
    'Horizon',      4.0, ...
    'TimeRes',      0.1, ...
    'Inflation',    0.0, ...
    'EgoWidth',     G.EgoWidthMirrors_m, ...
    'EgoLength',    4.7, ...
    'Wheelbase',    2.7, ...
    'LookaheadT',   0.6, ...
    'MinLookahead', 2.0, ...
    'DMin',         2.5);

% Exact S3 step/integration limits from demo_play.m. Duration is derived from
% the caps actually in force; "none" avoids S1's blocking-cow time allowance.
DT = 0.05;
T_END = sc.estimateDuration(HZ, S_START, P.Len, CRUISE_V, "none");
A_LON = 1.5;
D_LON = 3.0;
R_LAT = 0.9;
s = S_START;
e = E_START;
ev = 0;
V_START = iStartSpeed(HZ, S_START, CRUISE_V);
v = V_START;

nMax = round(T_END/DT);
LOG = struct( ...
    't',zeros(1,nMax),'s',zeros(1,nMax),'e',zeros(1,nMax), ...
    'v',zeros(1,nMax),'x',zeros(1,nMax),'y',zeros(1,nMax), ...
    'yaw',zeros(1,nMax),'H',nan(1,nMax), ...
    'State',strings(1,nMax),'Note',strings(1,nMax), ...
    'PlanFailed',strings(1,nMax),'MirrorsFolded',false(1,nMax), ...
    'cmd',{cell(1,nMax)},'tracks',{cell(1,nMax)});
poses = cell(1,nMax);

% Package BOTH actor sets in the evidence map. Negotiation IDs retain
% demo_play.m's 901:903 range; density IDs start at 1001. Density names include
% the row number so repeated classes with different extents cannot overwrite
% each other in DIMS and silently corrupt M6.
who = containers.Map('KeyType','double','ValueType','char');
actorClassIDs = containers.Map('KeyType','double','ValueType','double');
DIMS = struct();
negTags = {'moto_wrong','child','dog'};
assert(numel(negTags) == size(negSpec,1), ...
    'densityPlannerRunS3:negotiationTagMismatch', ...
    'actorSpecS3 has %d rows but the evidence map has %d tags.', ...
    size(negSpec,1), numel(negTags));
for k = 1:size(negSpec,1)
    who(900 + k) = negTags{k};
    actorClassIDs(900 + k) = double(negSpec{k,1});
    DIMS.(negTags{k}) = negSpec{k,4};
end
for k = 1:size(densitySpec,1)
    tag = sprintf('bg_%s_%d', char(densityTags(k)), k);
    who(1000 + k) = tag;
    actorClassIDs(1000 + k) = double(densitySpec{k,1});
    DIMS.(tag) = densitySpec{k,4};
end

st = struct();
nSteps = 0;
nFail = 0;
nPlans = 0;
nReacted = 0;  nGateUse = 0;  nGateFallback = 0;
nFolded = 0;
reachedEnd = false;
fprintf('\n================ S3 DENSITY + REAL PLANNER ================\n');
fprintf('route %.1f m, %d density actors, %d negotiation actors, %d maximum steps\n', ...
    P.Len, size(densitySpec,1), size(negSpec,1), nMax);
fprintf('T_END %.0f s computed from sc.demo3Route caps; squeeze %.2f m, ego %.2f/%.2f m\n', ...
    T_END, G.FreeWidth_m, G.EgoWidthMirrors_m, G.EgoWidthFolded_m);

for i = 1:nMax
    t = (i-1)*DT;
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));

    % demo_play.m's live S3 actors and sc.s3density are ADDED. Both are
    % generated from the current time, so no recording can saturate and leave
    % a stopped actor advertising an old non-zero velocity (S1's ghost defect).
    negActors = iActiveActorsAt(negSpec, P, t);
    densityActors = iActiveActorsAt(densitySpec, P, t);
    trk = [iTracksFromActors(negActors, 900, uint32(30)), ...
           iTracksFromActors(densityActors, 1000, uint32(1))];
    if ~isempty(trk)
        [~, order] = sort([trk.TrackID]);
        trk = trk(order);
    end

    ctx = struct('s',s,'e',e,'v',v,'t',t, ...
        'W',W,'Path',P,'RefPath',RefPath,'Tracks',trk, ...
        'EgoXY',xy,'EgoYaw',hdg,'Kappa',kappaV(ki),'CruiseV',CRUISE_V);
    tuneFields = fieldnames(TUNE);
    for f = 1:numel(tuneFields)
        ctx.(tuneFields{f}) = TUNE.(tuneFields{f});
    end

    % Exact S3 mirror decision from demo_play.m: first try the full-width
    % footprint, then fold only when the full corridor is rejected and the
    % measured 1.70 m footprint opens a real corridor.
    [eLoH, eHiH] = iCorridorFrom( ...
        HZ, s, W, G.EgoWidthMirrors_m, MIN_CORRIDOR, CORRIDOR_LEAD_IN);
    mirrorsFoldedNow = false;
    if isnan(eLoH)
        [eLoTry, eHiTry] = iCorridorFrom( ...
            HZ, s, W, G.EgoWidthFolded_m, MIN_CORRIDOR, CORRIDOR_LEAD_IN);
        if ~isnan(eLoTry)
            mirrorsFoldedNow = true;
            eLoH = eLoTry;
            eHiH = eHiTry;
        end
    end
    if isfinite(eLoH), ctx.ELo = eLoH; end
    if isfinite(eHiH), ctx.EHi = eHiH; end
    % PLAN EVERY N STEPS, HOLD THE COMMAND BETWEEN - demo_play's own shipped
    % setting is PlanEvery=3 (read from its config.json), and these runners were
    % re-planning at every 0.05 s step, i.e. 20 Hz, which the real demo never does.
    % That is 3x the planner calls for a fidelity the shipped demo does not claim.
    % S3 could not finish inside a 50-minute timebox because of it.
    % The seat still integrates every step; only the PLAN is held, exactly as
    % demo_play holds it. This CHANGES BEHAVIOUR and is therefore reported, not
    % hidden: PlanEvery=1 reproduces the earlier numbers.
    if mod(i-1, opts.PlanEvery) == 0 || ~exist('cmd','var')
        % PHASE 5 - the ML gate runs over every track and RECORDS its decision.
        % With no validated confidence band it returns FALLBACK for all of them,
        % which is the honest state: the predictor measures 2.089% dangerous-error
        % against a <=1% bar, so it drives nothing. Wiring it in now means the demo
        % can say "gated ON for 0 of N" from a live decision rather than a caption.
        for gk = 1:numel(trk)
            gd = sih.prediction.gateYield(trk(gk), NaN, opts.GateCfg);
            if gd == "USE", nGateUse = nGateUse + 1;
            else,           nGateFallback = nGateFallback + 1; end
        end
        [cmd, st] = sc.planSeat(st, ctx);
        nPlans = nPlans + 1;
    end
    cmd.MirrorsFolded = mirrorsFoldedNow;
    nFolded = nFolded + double(mirrorsFoldedNow);

    % The road's speed law is beside planSeat's own cap, never inside it.
    [hzCap, hzWhy] = sc.hazardCap(HZ, s, v, CRUISE_V);
    if isfinite(hzCap) && hzCap < cmd.v
        cmd.v = hzCap;
    end
    if strlength(cmd.PlanFailed) > 0
        nFail = nFail + 1;
        if nFail == 1
            fprintf('  [plan FAIL] step %d  t=%.2f s  s=%.1f m  v=%.2f m/s  nTracks=%d\n     %s\n', ...
                i, t, s, v, numel(trk), cmd.PlanFailed);
        end
    end

    dv = cmd.v - v;
    v = max(0, v + max(-D_LON*DT, min(A_LON*DT, dv)));
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', R_LAT);
    s = min(P.Len, s + v*DT);

    LOG.t(i) = t;
    LOG.s(i) = s;
    LOG.e(i) = e;
    LOG.v(i) = v;
    LOG.x(i) = xy(1);
    LOG.y(i) = xy(2);
    LOG.yaw(i) = hdg;
    LOG.H(i) = cmd.H;
    LOG.State(i) = string(cmd.State);
    LOG.Note(i) = string(cmd.Note);
    LOG.PlanFailed(i) = string(cmd.PlanFailed);
    LOG.MirrorsFolded(i) = mirrorsFoldedNow;
    LOG.cmd{i} = struct('H',cmd.H,'RawState',string(cmd.RawState), ...
        'MirrorsFolded',mirrorsFoldedNow);
    LOG.tracks{i} = trk;

    Pi = [iPosesFromActors(negActors, 900), ...
          iPosesFromActors(densityActors, 1000)];
    poses{i} = Pi;
    nSteps = i;

    if mod(i,300) == 0
        fprintf('  ... step %d/%d  t=%.1f  s=%.1f m  v=%.2f m/s  state=%s  tracks=%d\n', ...
            i, nMax, t, s, v, cmd.State, numel(trk));
        fprintf('        (%d negotiation + %d density)  mirrorsFolded=%s  cap=%s [%s]\n', ...
            numel(negActors), numel(densityActors), string(mirrorsFoldedNow), ...
            string(hzCap), hzWhy);
    end

    % demo_play.m's S3 completion rule: the ego reference point reaches the
    % final 6 m of the route. Reusing it keeps M9 comparable to the live demo.
    if s >= P.Len - 6
        reachedEnd = true;
        break
    end
end

logFields = {'t','s','e','v','x','y','yaw','H','State','Note', ...
    'PlanFailed','MirrorsFolded','cmd','tracks'};
for k = 1:numel(logFields)
    LOG.(logFields{k}) = LOG.(logFields{k})(1:nSteps);
end
poses = poses(1:nSteps);
LOG.ReachedEnd = reachedEnd;

D = struct('W',W,'Poses',{poses},'Who',who,'DIMS',DIMS, ...
    'ActorClassIDs',actorClassIDs, ...
    'Sensed',false, ...
    'EgoWidth',G.EgoWidthMirrors_m, ...
    'EgoWidthFolded',G.EgoWidthFolded_m, ...
    'Title',"S3: negotiation actors + full density, real planner");
runOpts = struct( ...
    'Runner',"densityPlannerRunS3", ...
    'Scenario',"s3", ...
    'WorldFactory',"sc.s3world", ...
    'DensityFactory',"sc.s3density", ...
    'NegotiationActors',"demo_play.m actorSpecS3 arithmetic", ...
    'Hazards',"sc.demo3Route, speed caps and ramped corridor applied in the seat", ...
    'HazardSpec',{HZ}, ...
    'DensitySpec',{densitySpec}, ...
    'NegotiationSpec',{negSpec}, ...
    'Geometry',G, ...
    'ActorIDOffsets',struct('Negotiation',900,'Density',1000), ...
    'DT_s',DT, ...
    'TEnd_s',T_END, ...
    'PlanEvery',opts.PlanEvery, ...
    'Sensed',false, ...
    'CompletionThreshold_m',P.Len - 6, ...
    'InitialState',struct('s_m',S_START,'e_m',E_START,'v_mps',V_START), ...
    'IntegrationLimits',struct('Accel_mps2',A_LON,'Decel_mps2',D_LON,'LateralRate',R_LAT), ...
    'Corridor',struct('MinSlack_m',MIN_CORRIDOR,'LeadIn_m',CORRIDOR_LEAD_IN, ...
        'FreeWidth_m',G.FreeWidth_m,'EgoWidthMirrors_m',G.EgoWidthMirrors_m, ...
        'EgoWidthFolded_m',G.EgoWidthFolded_m), ...
    'PlannerTune',TUNE);
runName = "density-planner-s3_" + ...
    string(datetime('now','TimeZone','UTC','Format','yyyyMMdd-HHmmss'));
info = sih.metrics.writeDemoResults(runName, D, LOG, runOpts);

kinematicsNonFinite = nnz(~isfinite([LOG.t LOG.s LOG.e LOG.v LOG.x LOG.y LOG.yaw]));
barrierNonFinite = nnz(~isfinite(LOG.H));
fprintf('\n--- S3 DENSITY PLANNER SUMMARY ---\n');
fprintf('  total steps:                         %d\n', nSteps);
fprintf('  reached live-demo completion point:  %s\n', string(reachedEnd));
fprintf('  plan-failure count:                  %d\n', nFail);
fprintf('  planner calls (PlanEvery=%d):         %d\n', opts.PlanEvery, nPlans);
fprintf('  PHASE 8 reactive: %s, %d agent reactions\n', ...
    string(opts.Reactive), nReacted);
fprintf('  PHASE 5 ML gate:  USE %d / FALLBACK %d  (%s)\n', nGateUse, nGateFallback, ...
    "no validated band -> geometric right-of-way");
fprintf('  mirror-folded steps:                 %d\n', nFolded);
fprintf('  any NaN/Inf in t/s/e/v/x/y/yaw:     %s (%d values)\n', ...
    string(kinematicsNonFinite > 0), kinematicsNonFinite);
fprintf('  any NaN/Inf in returned barrier H:   %s (%d values)\n', ...
    string(barrierNonFinite > 0), barrierNonFinite);

metricNames = ["M1_distance_m","M2_duration_s","M3_meanSpeed_kmh", ...
    "M4_maxSpeed_kmh","M5_minBarrier_rad","M6_minClearance_m", ...
    "M7_stoppedTime_s","M8_maxDecel_mps2","M9_completed","M10_latWobble_m"];
fprintf('\n--- M1-M10 ---\n');
for k = 1:numel(metricNames)
    fprintf('  %s = %s\n', metricNames(k), jsonencode(info.M.(metricNames(k))));
end
fprintf('  evidence: %s\n', info.RunDir);
fprintf('===========================================================\n\n');
end

function spec = iActorSpecS3()
%IACTORSPECS3  Verbatim data rows from demo_play.m's actorSpecS3.
%   ClassID, route station m, lateral m, extent [L W H] m, route speed m/s,
%   extra yaw rad, optional lateral target m, optional transition [t1 t2] s.
spec = { ...
    5,  150, -1.5,  [1.90 0.75 1.30], -2.5, 0, [], [] ; ...
    8,  110,  2.2,  [0.50 0.50 1.40],  0,   0, -2.2, [20 23] ; ...
    11, 125,  0.0,  [0.50 0.30 0.40],  0,   0, -1.65, [50 55] ...
};
end

function A = iActiveActorsAt(spec, P, t)
%IACTIVEACTORSAT  Closed-form actor poses and world-frame velocities.
%   This is demo_play.m's activeActorsAt arithmetic with one local correction:
%   positive along-route speeds produce a positive world velocity as well as
%   changing position. The private source only assigns velocity for negative
%   speed, which would make S3 density's walkers/cyclist/auto move while their
%   S1 tracks claim they are stationary.
A = struct('Row',{},'ClassID',{},'XY',{},'YawRad',{},'Vel',{},'Extent',{});
for k = 1:size(spec,1)
    if ~isfinite(spec{k,3}), continue; end
    u = spec{k,2} + spec{k,5}*t;
    if u < 2 || u > P.Len - 2, continue; end
    lat = spec{k,3};
    latRate = 0;
    if size(spec,2) >= 8 && ~isempty(spec{k,7}) && ~isempty(spec{k,8})
        tw = spec{k,8};
        dLat = spec{k,7} - spec{k,3};
        frac = max(0, min(1, (t - tw(1)) / (tw(2) - tw(1))));
        lat = spec{k,3} + dLat*frac;
        if t > tw(1) && t < tw(2), latRate = dLat / (tw(2) - tw(1)); end
    end
    [xy, hdg] = P.at(u, lat);
    yaw = hdg + spec{k,6};
    vel = spec{k,5}*[cos(hdg) sin(hdg) 0];
    if spec{k,5} < 0
        yaw = hdg + pi;
    end
    if latRate ~= 0
        vel = vel + latRate*[-sin(hdg) cos(hdg) 0];
    end
    A(end+1) = struct('Row',k,'ClassID',spec{k,1},'XY',xy,'YawRad',yaw, ...
        'Vel',vel,'Extent',spec{k,4}); %#ok<AGROW>
end
end

function tracks = iTracksFromActors(A, idOffset, age)
%ITRACKSFROMACTORS  Active world actors -> frozen S1 TrackList fields.
tracks = iEmptyTrackList();
for k = 1:numel(A)
    tracks(end+1) = struct( ... %#ok<AGROW>
        'TrackID',uint32(idOffset + A(k).Row), ...
        'ClassID',uint8(A(k).ClassID), ...
        'Position',[A(k).XY 0], ...
        'Velocity',A(k).Vel, ...
        'Extent',A(k).Extent, ...
        'Yaw',A(k).YawRad, ...
        'Existence',1, ...
        'Age',age, ...
        'SensorMask',uint8(1));
end
end

function tracks = iEmptyTrackList()
%IEMPTYTRACKLIST  Empty S1 TrackList with the full frozen field set.
tracks = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
    'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});
end

function poses = iPosesFromActors(A, idOffset)
%IPOSESFROMACTORS  Active actors -> writeDemoResults ground-truth pose shape.
%   Traffic yaw is degrees because writeDemoResults converts it back to SI
%   radians, matching demo_play.m's builtinPosesS3 unit convention.
poses = struct('ActorID',{},'Position',{},'Velocity',{},'Yaw',{});
for k = 1:numel(A)
    poses(end+1) = struct( ... %#ok<AGROW>
        'ActorID',idOffset + A(k).Row, ...
        'Position',[A(k).XY 0], ...
        'Velocity',A(k).Vel, ...
        'Yaw',rad2deg(A(k).YawRad));
end
end

function v0 = iStartSpeed(H, sStart, cruise)
%ISTARTSPEED  Verbatim mechanism from demo_play.m's private startSpeed.
aComfort = 1.6;
v0 = cruise;
for k = 1:numel(H)
    c = H(k).SpeedCap;
    if ~isfinite(c), continue; end
    [lo, ~] = iStretch(H(k));
    d = lo - sStart;
    if d <= 0, continue; end
    v0 = min(v0, sqrt(c^2 + 2*aComfort*d));
end
v0 = max(v0, 0.5);
end

function [eLo, eHi] = iCorridorFrom(H, s, W, egoW, minCorridor, leadIn)
%ICORRIDORFROM  Ramped hazard corridor from demo_play.m's corridorFrom.
%   minCorridor is centreline slack. It is supplied explicitly for S3 so the
%   demo1/demo2 default 2.2 m floor is never applied to the measured squeeze.
hw = W.Width/2;
eLo0 = -(hw - 0.95);
eHi0 = (hw - 0.95) + 0.35;
eLo = eLo0;
eHi = eHi0;
touched = false;
for k = 1:numel(H)
    if ~ismember(string(H(k).Type), ["barrier","damage"]), continue; end
    if startsWith(string(H(k).Label),"LIVE OBSTACLE"), continue; end
    [lo, hi] = iStretch(H(k));
    if s < lo - leadIn || s > hi, continue; end
    progress = max(0, min(1, (s - (lo - leadIn)) / leadIn));
    onShoulder = abs(H(k).Lateral) > 2.0;
    hasWidth = isfinite(H(k).Radius) && H(k).Radius > 0;
    if ~onShoulder && ~hasWidth, continue; end
    halfW = 1.0;
    if hasWidth, halfW = H(k).Radius; end
    blockLo = H(k).Lateral - halfW - egoW/2;
    blockHi = H(k).Lateral + halfW + egoW/2;
    if blockHi >= eHi0 - 0.05
        eHi = min(eHi, eHi0 + (blockLo - eHi0)*progress);
        touched = true;
    elseif blockLo <= eLo0 + 0.05
        eLo = max(eLo, eLo0 + (blockHi - eLo0)*progress);
        touched = true;
    else
        if (eHi0 - blockHi) >= (blockLo - eLo0)
            eLo = max(eLo, eLo0 + (blockHi - eLo0)*progress);
        else
            eHi = min(eHi, eHi0 + (blockLo - eHi0)*progress);
        end
        touched = true;
    end
end
if ~touched || eHi - eLo < minCorridor
    eLo = NaN;
    eHi = NaN;
end
end

function [lo, hi] = iStretch(h)
%ISTRETCH  Verbatim station/Zone convention from demo_play.m.
r = 2.0;
if isfinite(h.Radius), r = max(2.0, h.Radius); end
if h.Zone > 0
    lo = h.Station;
    hi = h.Station + h.Zone;
else
    lo = h.Station - r;
    hi = h.Station + r;
end
end
