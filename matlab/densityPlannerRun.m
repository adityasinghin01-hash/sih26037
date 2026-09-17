function info = densityPlannerRun(scenario, opts)
%DENSITYPLANNERRUN  Run the real planner in S1's full-density world.
%
%   densityPlannerRun("s1")
%
%   Builds sc.s1world/sc.s1density, converts every active density actor to
%   the frozen S1 TrackList contract, calls sc.planSeat every 0.05 s, and
%   integrates the returned target speed/lateral offset with the same limits
%   and sc.lateralStep call as s1_planner_run.m. Evidence is written through
%   sih.metrics.writeDemoResults to results/<run>/.

arguments
    scenario (1,1) string = "s1"
    opts.Seed   (1,1) double = 0      % 0 = the deterministic reference run
    opts.StartS (1,1) double = 25     % perturbed by the harness for repeated runs
    opts.StartE (1,1) double = 1.75
    opts.StartV (1,1) double = 52/3.6
    opts.Quiet  (1,1) logical = false
    opts.PlanEvery (1,1) double = 3
    opts.Reactive  (1,1) logical = false  % PHASE 8 - agents respond to the ego
    opts.GateCfg   struct = struct()      % PHASE 5 - ML gate config; empty = closed   % match demo_play's own shipped setting
end

scenario = lower(scenario);
assert(scenario == "s1", "densityPlannerRun:badScenario", ...
    'Phase 1 supports only "s1"; S3/S4/S5 are later jobs.');

here = fileparts(mfilename('fullpath'));
addpath(here);
assert(~isempty(which('sih.planner.planContingency')), ...
    'sih.planner is not on the path - the +sih repo is not where densityPlannerRun expects it');

W = sc.s1world();
[spec, tags] = sc.s1density();
P = W.Path;

% PHASE 1a - the density layer is BACKGROUND, measured: 50 of its 51 actors sit off
% the 3.5 m half-carriageway. On its own the planner has nothing to negotiate and
% simply cruises (first run: 51.6 km/h mean, 0 s stopped, h=NaN on all 817 steps).
% So load the REAL negotiation set too - the cow, the herd, the auto, the wrong-way
% rider, the overtaker, the tractor - and drive against the UNION of both.
% The recording must outlast the drive. estimateDuration gives the capped route's
% budget; ask s1_action_run for that much traffic plus a margin.
negSeconds = sc.estimateDuration(sc.demo1Route(), 25, W.Path.Len, 52/3.6, "blocking");
[negPoses, negWho, negDIMS] = iLoadNegotiationActors(here, negSeconds);
fprintf('[phase1a] traffic recorded for %.0f s (%d frames)\n', negSeconds, numel(negPoses));

% PHASE 1a PART 3 - THE ROAD'S OWN CONSTRAINTS.
% Runs 1 and 2 loaded the world and the actors but NOT sc.demo1Route's 14 hazards
% (potholes, the speed breaker, the village slow zone), each carrying a SpeedCap of
% 14-29 km/h. Without them the car cruised at 52 km/h the whole way, finished the
% route 15 s earlier than demo_play does, and drove into the overtaking motorcycle
% at s=609 m - an actor whose script assumed the slower arrival. M6 = -0.800 m.
% demo_play applies  cmd.v = min(trunk's ask, speedLimit(S9), hazard cap);
% planSeat already does the first two, so the third is applied here, in the seat.
HZ = sc.demo1Route();
fprintf('[phase1a] hazards: %d from sc.demo1Route\n', numel(HZ));
fprintf('[phase1a] negotiation actors: %d recorded pose frames\n', numel(negPoses));

% Exact reference-path construction and planner tuning from s1_planner_run.m.
RefPath = referencePathFrenet(W.Path.P);
kappaV = W.Path.curvature();
TUNE = struct( ...
    'TermSpeeds',   [0 4 8 11 14.4], ...
    'LatOffsets',   [-2.5 -1.585 -0.9 0 0.9 1.75 2.6], ...
    'Horizon',      4.0, ...
    'TimeRes',      0.1, ...
    'Inflation',    0.0, ...
    'EgoWidth',     1.8, ...
    'EgoLength',    4.7, ...
    'Wheelbase',    2.7, ...
    'LookaheadT',   0.6, ...
    'MinLookahead', 2.0, ...
    'DMin',         2.5);

% Exact S1 step, duration, initial state, and integration limits supplied to
% s1_planner_run.m by s1_action_run.m.
DT = 0.05;
% T_END is COMPUTED from the caps actually in force, never hardcoded. The previous
% hardcoded 62 s (copied from the sparse config) left the capped run stranded at
% s=403.7 m of 610 with M9_completed=false.
T_END = sc.estimateDuration(HZ, 25, W.Path.Len, 52/3.6, "blocking");
A_LON = 1.8;
D_LON = 3.2;
R_LAT = 0.75;
s  = opts.StartS;
e  = opts.StartE;
ev = 0;
v  = opts.StartV;

nMax = round(T_END/DT);
LOG = struct( ...
    't',zeros(1,nMax),'s',zeros(1,nMax),'e',zeros(1,nMax), ...
    'v',zeros(1,nMax),'x',zeros(1,nMax),'y',zeros(1,nMax), ...
    'yaw',zeros(1,nMax),'H',nan(1,nMax), ...
    'State',strings(1,nMax),'Note',strings(1,nMax), ...
    'PlanFailed',strings(1,nMax), ...
    'cmd',{cell(1,nMax)},'tracks',{cell(1,nMax)});
poses = cell(1,nMax);

% Package density ground truth in the shape writeDemoResults consumes.
% PHASE 1a BUGFIX - writeDemoResults measures M6 (minimum clearance) by walking
% D.Poses. The first version of this file put ONLY the density actors in there, so
% M6 came back as the clearance to background scenery and the cow was never measured
% at all. Run 1 reported M6 = 1.092 m; that number was clearance to a parked vehicle,
% not to the animal the whole scenario is about. Both sets go in now, density offset
% by 1000 to match the TrackIDs and to keep the two ID spaces apart.
who = containers.Map('KeyType','double','ValueType','char');
DIMS = struct();
negKeys = cell2mat(keys(negWho));
for k = 1:numel(negKeys)
    who(negKeys(k)) = negWho(negKeys(k));
end
negTags = fieldnames(negDIMS);
for k = 1:numel(negTags)
    DIMS.(negTags{k}) = negDIMS.(negTags{k});
end
for k = 1:size(spec,1)
    who(1000 + k) = ['bg_' char(tags(k))];
    DIMS.(['bg_' char(tags(k))]) = spec{k,4};
end

st = struct();
nSteps = 0;
nFail = 0;
nGhostsFixed = 0;
nFrozenSteps = 0;
nPruned = 0;
nPlans = 0;
nReacted = 0;  nGateUse = 0;  nGateFallback = 0;
reachedEnd = false;
if ~opts.Quiet
fprintf('\n================ S1 DENSITY + REAL PLANNER ================\n');
end
fprintf('route %.1f m, %d density actors, %d maximum steps (T_END %.0f s, computed from the caps)\n', ...
    P.Len, size(spec,1), nMax, T_END);

for i = 1:nMax
    t = (i-1)*DT;
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));

    % --- the real traffic: cow, herd, auto, wrong-way rider, overtaker, tractor ---
    % GHOST-TRACK GUARD, added 16 Sep 2026 after a measured defect.
    % moto_over reaches the route end (s=610) at t=49.95 s and stops there, but its
    % recorded Velocity stays at 17.22 m/s - 62 km/h - for the rest of the run. Any
    % consumer of that track sees a motorcycle sprinting away while it is in fact
    % parked in the carriageway, and sih.planner.predictAgentFutures propagates it
    % forward from exactly that velocity. The ego drove past it in COMMIT at
    % 13.85 m/s without reacting, which is what believing the ghost looks like.
    % Separately: the recording is 1399 frames and the run is now 1559 steps, so
    % negIdx saturates and freezes EVERY actor for the last 160 steps.
    % An actor whose position has not moved is reported as stationary. Measured,
    % not assumed - the threshold is one millimetre per step at DT=0.05 s.
    negIdx = min(i, numel(negPoses));
    if negIdx >= numel(negPoses) && i > numel(negPoses)
        nFrozenSteps = nFrozenSteps + 1;
    end
    NPnow = negPoses{negIdx};
    if negIdx > 1
        NPprev = negPoses{negIdx-1};
        for q = 1:numel(NPnow)
            pm = find([NPprev.ActorID] == NPnow(q).ActorID, 1);
            if isempty(pm), continue; end
            moved = norm(NPnow(q).Position(1:2) - NPprev(pm).Position(1:2));
            if moved < 1e-3 && norm(NPnow(q).Velocity) > 1e-3
                NPnow(q).Velocity = [0 0 0];
                nGhostsFixed = nGhostsFixed + 1;
            end
        end
    end
    trk = sc.buildTrackList(NPnow, negWho, negDIMS);
    nNeg = numel(trk);

    % --- the background world on top, IDs offset by 1000 so they cannot collide ---
    % ---- PRUNE AT THE SOURCE, USING NUMBERS WE ALREADY HAVE -----------------
    % Measured: planContingency is 88% of runtime and checkTrajectorySafety runs
    % 1,023 times PER STEP against ~60 tracks, 50 of which are scenery 5-8 m off a
    % 3.5 m half-carriageway. Skipping them is provably free - a run pruning 39.3
    % tracks/step returned M6 = 0.1347406069392747, bit-identical to the unpruned
    % run on every one of M1-M10.
    %
    % FIRST ATTEMPT WAS SLOWER, AND THAT IS THE LESSON: it called P.inverse() per
    % track per step - 111,300 Frenet inversions, each a search along the path -
    % and cost MORE than it saved (16m35s vs 13m12s unpruned). The station and
    % lateral of every density actor are already in `spec` by construction, so the
    % test is two array lookups and no geometry at all.
    %
    % BOUNDS DERIVED, NOT TUNED: horizon 4.0 s x 14.44 m/s cruise = 57.8 m, plus
    % ego 4.7 m and the longest actor ~6 m -> 100 m each way is nearly double the
    % reachable set. Widest candidate offset 2.6 m + ego half-width 0.9 + half the
    % widest actor ~1.5 = 5.0 m -> 12 m lateral is over double.
    A = sc.activeDensityActorsAt(spec, W.Path, t);

    % PHASE 8 - let the agents respond to the ego. OFF BY DEFAULT: with
    % opts.Reactive=false sc.reactStep returns A untouched, so every number
    % measured against scripted actors stays exactly reproducible.
    if opts.Reactive
        [A, rlog] = sc.reactStep(A, struct('XY',xy), DT, struct('Enabled',true));
        nReacted = nReacted + numel(rlog.Reacted);
    end
    for k = 1:numel(A)
        % ONLY STATIC ACTORS ARE PRUNED, AND THAT IS A CORRECTNESS RULE.
        % spec{Row,2} is the actor's INITIAL station. 20 of these 51 actors move,
        % so for them that number goes stale immediately - an actor starting
        % beyond 100 m and driving toward the ego would be pruned while it closed.
        % M6 came back identical when this was pruned naively, but that is luck in
        % one run, not a guarantee, and a safety filter may not rest on luck.
        % A static actor's station and lateral are exact for all time, so pruning
        % those is correct by construction. Moving actors are never pruned: there
        % are only 20, and keeping them costs far less than being wrong once.
        if spec{A(k).Row,5} == 0 && ...
           (abs(spec{A(k).Row,3}) > 12 || abs(spec{A(k).Row,2} - s) > 100)
            nPruned = nPruned + 1;
            continue
        end
        trk(end+1) = struct('TrackID',uint32(1000 + A(k).Row),'ClassID',uint8(A(k).ClassID), ...
            'Position',[A(k).XY 0],'Velocity',A(k).Vel,'Extent',A(k).Extent, ...
            'Yaw',A(k).YawRad,'Existence',1,'Age',uint32(1),'SensorMask',uint8(1)); %#ok<AGROW>
    end

    ctx = struct('s',s,'e',e,'v',v,'t',t, ...
        'W',W,'Path',P,'RefPath',RefPath,'Tracks',trk, ...
        'EgoXY',xy,'EgoYaw',hdg,'Kappa',kappaV(ki),'CruiseV',52/3.6);
    tuneFields = fieldnames(TUNE);
    for f = 1:numel(tuneFields)
        ctx.(tuneFields{f}) = TUNE.(tuneFields{f});
    end

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

    % the road's own speed law, applied beside planSeat's - never inside it
    [hzCap, hzWhy] = sc.hazardCap(HZ, s, v, 52/3.6);
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

    % Exact integration block from s1_planner_run.m.
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
    LOG.cmd{i} = struct('H',cmd.H,'RawState',string(cmd.RawState));
    LOG.tracks{i} = trk;

    Pi = struct('ActorID',{},'Position',{},'Velocity',{},'Yaw',{});
    NP = negPoses{negIdx};
    for k = 1:numel(NP)
        Pi(end+1) = struct('ActorID',double(NP(k).ActorID),'Position',NP(k).Position, ...
            'Velocity',NP(k).Velocity,'Yaw',NP(k).Yaw); %#ok<AGROW>
    end
    for k = 1:numel(A)
        Pi(end+1) = struct('ActorID',1000 + double(A(k).Row),'Position',[A(k).XY 0], ...
            'Velocity',A(k).Vel,'Yaw',rad2deg(A(k).YawRad)); %#ok<AGROW>
    end
    poses{i} = Pi;
    nSteps = i;

    if mod(i,300) == 0 && ~opts.Quiet
        fprintf('  ... step %d/%d  t=%.1f  s=%.1f m  v=%.2f m/s  state=%s  tracks=%d\n', ...
            i, nMax, t, s, v, cmd.State, numel(trk));
        fprintf('        (%d negotiation + %d background)  cap=%s [%s]\n', ...
            nNeg, numel(trk)-nNeg, string(hzCap), hzWhy);
    end
    if s >= P.Len
        reachedEnd = true;
        break
    end
end

logFields = {'t','s','e','v','x','y','yaw','H','State','Note','PlanFailed','cmd','tracks'};
for k = 1:numel(logFields)
    LOG.(logFields{k}) = LOG.(logFields{k})(1:nSteps);
end
poses = poses(1:nSteps);
LOG.ReachedEnd = reachedEnd;

% EVIDENCE FIX: writeDemoResults drops any actor whose tag classIDByName cannot
% resolve, and it resolves none of the bg_* names - so trajectories.csv recorded
% only 10 of the 60 actors the planner actually reacted to. Anyone recomputing a
% number from that file was reconstructing a different scenario. Supply the map.
actorClassIDs = containers.Map('KeyType','double','ValueType','double');
for k = 1:size(spec,1)
    actorClassIDs(1000 + k) = double(spec{k,1});
end
D = struct('W',W,'Poses',{poses},'Who',who,'DIMS',DIMS, ...
    'ActorClassIDs',actorClassIDs, ...
    'Sensed',false, 'Title',"S1: negotiation actors + full density, real planner");
runOpts = struct( ...
    'Runner',"densityPlannerRun", ...
    'Scenario',scenario, ...
    'WorldFactory',"sc.s1world", ...
    'DensityFactory',"sc.s1density", ...
    'NegotiationActors',"sc.s1actors via s1_action_run.m", ...
    'Hazards',"sc.demo1Route, speed caps applied in the seat", ...
    'DensitySpec',{spec}, ...
    'DT_s',DT, ...
    'TEnd_s',T_END, ...
    'PlanEvery',opts.PlanEvery, ...
    'Sensed',false, ...
    'InitialState',struct('s_m',25,'e_m',1.75,'v_mps',52/3.6), ...
    'IntegrationLimits',struct('Accel_mps2',A_LON,'Decel_mps2',D_LON,'LateralRate',R_LAT), ...
    'PlannerTune',TUNE);
runName = "density-planner-" + scenario + "_" + ...
    string(datetime('now','TimeZone','UTC','Format','yyyyMMdd-HHmmss'));
info = sih.metrics.writeDemoResults(runName, D, LOG, runOpts);

kinematicsNonFinite = nnz(~isfinite([LOG.t LOG.s LOG.e LOG.v LOG.x LOG.y LOG.yaw]));
barrierNonFinite = nnz(~isfinite(LOG.H));
info.M = info.M;  %#ok<ASGSL> - writeDemoResults already returned M in `info`
info.Seed = opts.Seed;  info.Start = [opts.StartS opts.StartE opts.StartV];
info.Steps = nSteps;  info.ReachedEnd = reachedEnd;  info.PlanFailures = nFail;
info.Pruned = nPruned;  info.GhostsFixed = nGhostsFixed;
if opts.Quiet, return; end
fprintf('\n--- DENSITY PLANNER SUMMARY ---\n');
fprintf('  total steps:                         %d\n', nSteps);
fprintf('  reached end of route:                %s\n', string(reachedEnd));
fprintf('  plan-failure count:                  %d\n', nFail);
fprintf('  planner calls (PlanEvery=%d):         %d\n', opts.PlanEvery, nPlans);
fprintf('  PHASE 8 reactive: %s, %d agent reactions\n', ...
    string(opts.Reactive), nReacted);
fprintf('  PHASE 5 ML gate:  USE %d / FALLBACK %d  (%s)\n', nGateUse, nGateFallback, ...
    "no validated band -> geometric right-of-way");
fprintf('  tracks pruned as unreachable:        %d (%.1f per step)\n', ...
    nPruned, nPruned/max(nSteps,1));
fprintf('  ghost tracks zeroed (stopped but\n');
fprintf('    still reporting a velocity):       %d\n', nGhostsFixed);
fprintf('  steps past the end of the recording\n');
fprintf('    (every actor frozen):              %d of %d\n', nFrozenSteps, nSteps);
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

function [poses, who, DIMS] = iLoadNegotiationActors(here, seconds)
%ILOADNEGOTIATIONACTORS  Run s1_action_run.m in an ISOLATED workspace and return only
%   the three things we need. It defines W P CS DT T_END A_LON D_LON R_LAT ctx0 who
%   DIMS poses log1 - running it inline would silently clobber our own W and P.
T_END = seconds;            %#ok<NASGU> - consumed by s1_action_run.m's guarded default
run(fullfile(here,'s1_action_run.m'));
end
