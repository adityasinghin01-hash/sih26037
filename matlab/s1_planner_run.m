%S1_PLANNER_RUN  The real sih.planner in the S1 seat, run against the frozen
%   scripted S1 traffic (the same recorded poses sc.s1defensive is judged on, so
%   the comparison to the placeholder is exact, not approximate).
%
%   Phase 2 gate: this runs end to end, the planner drives, nothing errors, and
%   sc.plannerView animates it live in MATLAB (set VIEW=true in a desktop
%   session). The clearance numbers are NOT expected to pass yet - that is
%   Phase 3, and it is gated: the planner must match or beat sc.s1drive
%   (cow clearance 0.965 m each side, past her at 8 km/h, no contact).

here = fileparts(mfilename('fullpath'));  addpath(here);
assert(~isempty(which('sih.planner.planContingency')), ...
    'sih.planner is not on the path - the +sih repo is not where s1drivePlanner expects it');

if ~exist('VIEW','var'),      VIEW = false;      end     % live figure (desktop only)
if ~exist('PLAN_EVERY','var'), PLAN_EVERY = 1;   end     % decimate the planner if slow
if ~exist('INLOOP','var'),    INLOOP = true;     end     % Phase 8b: sense from the ego's
                                                          % ACTUAL pose each step. false =
                                                          % the old precomputed batch, which
                                                          % mounts the sensors on the SCRIPTED
                                                          % driver's trajectory (see sc.senseRig
                                                          % for the measured defect that causes).
if ~exist('SENSED','var'),    SENSED = true;     end     % Phase 5: noisy sensing+tracking,
                                                          % not sc.buildTrackList's exact
                                                          % positions. SENSED=false reverts
                                                          % to the old exact-position TL for
                                                          % an A/B comparison.

% ---- Phase 3 tuning dials (one place) ------------------------------------------
% TermSpeeds MUST reach the cruise speed or every candidate commands a slowdown.
TUNE = struct( ...
    'TermSpeeds',   [0 4 8 11 14.4], ...   % m/s - includes 52 km/h cruise
    'LatOffsets',   [-2.5 -1.585 -0.9 0 0.9 1.75 2.6], ...  % samples lane + pass line
    'Horizon',      4.0, ...
    'TimeRes',      0.1, ...
    'Inflation',    0.0, ...
    'EgoWidth',     1.8, ...
    'EgoLength',    4.7, ...
    'Wheelbase',    2.7, ...
    'LookaheadT',   0.6, ...
    'MinLookahead', 2.0, ...
    'DMin',         2.5);

run(fullfile(here,'s1_action_run.m'));   % W P CS DT T_END A_LON D_LON R_LAT ctx0 who DIMS poses log1

fprintf('\n================ S1 PLANNER RUN (adapter, Phase 2) ================\n');

[~, zd] = sc.meshes("zebu");
[~, cd] = sc.meshes("car");
RefPath = referencePathFrenet(W.Path.P);
kappaV  = W.Path.curvature();

if SENSED && INLOOP
    TL = poses;                      % sensed live inside the loop from the real ego pose
    fprintf('SENSING IN-LOOP from the ego''s own pose (%d steps of raw poses)\n', numel(poses));
elseif SENSED
    [TL, sensDiag] = sc.buildTrackListSensed(poses, who, DIMS, log1, P);
    fprintf('built %d SENSED per-step TrackLists (simulated lidar/radar/ring + tracker)\n', numel(TL));
    fprintf('  mean detections/frame %.2f, mean tracks/frame %.2f\n', ...
            sensDiag.nDetPerFrame, sensDiag.nTrackPerFrame);
else
    nS = numel(poses);
    TL = cell(1, nS);
    for i = 1:nS
        TL{i} = sc.buildTrackList(poses{i}, who, DIMS);
    end
    fprintf('built %d EXACT-POSITION per-step TrackLists (%d..%d road users each)\n', ...
            nS, min(cellfun(@numel,TL)), max(cellfun(@numel,TL)));
end
nS = numel(TL);   % SENSED truncates to min(poses,egoLog) - this keeps every later
                  % index (e.g. the collision-separation loop below) inside TL either way

% ---------------------------------------------------------------- drive it
LP = integratePlanner(W, W.Path, ctx0, TL, kappaV, DT, T_END, ...
                      A_LON, D_LON, R_LAT, RefPath, PLAN_EVERY, VIEW, TUNE, ...
                      SENSED && INLOOP, who, DIMS);

% ---------------------------------------------------------------- measure the bar
alongside = abs(LP.s - CS) < zd(1)/2 + cd(1)/2;
cmp = struct('planner',NaN,'placeholder',0.965);
if any(alongside)
    egoLeft  = LP.e(alongside) + cd(2)/2;                       % flank toward the cow
    gapToCow = (ctx0.cowStopE - ctx0.cowLateral/2) - max(egoLeft);
    gapToEdg = min(LP.e(alongside)) - cd(2)/2 - (-W.Width/2);
    vPast    = 3.6*max(LP.v(alongside));
    fprintf('\n--- ALONGSIDE THE COW ---\n');
    fprintf('  ego lateral while alongside: %+.3f .. %+.3f m\n', min(LP.e(alongside)), max(LP.e(alongside)));
    fprintf('  gap to the cow   %+.3f m   (placeholder 0.965)\n', gapToCow);
    fprintf('  gap to the edge  %+.3f m   (placeholder 0.965)\n', gapToEdg);
    fprintf('  speed past her   %.2f km/h (placeholder 8.00)\n', vPast);
    cmp.planner = min(gapToCow, gapToEdg);
else
    fprintf('\n--- the ego never drew level with the cow (s reached %.0f m of %.0f) ---\n', ...
            LP.s(end), W.Path.Len);
end

% ---------------------------------------------------------------- collisions
who2 = who;  DIMS2 = DIMS;
P = W.Path;  minSep = inf;  worst = '';  tW = NaN;
for i = 1:min(numel(LP.t), nS)
    pp = poses{i};
    for q = 1:numel(pp)
        if ~isKey(who2, pp(q).ActorID), continue; end
        nm = who2(pp(q).ActorID);  dq = DIMS2.(nm);
        [sq, eq] = P.inverse(pp(q).Position(1:2));
        [~, hq]  = P.at(sq, 0);
        th = deg2rad(pp(q).Yaw) - hq;
        aL = abs(dq(1)*cos(th)) + abs(dq(2)*sin(th));
        aW = abs(dq(1)*sin(th)) + abs(dq(2)*cos(th));
        gapS = abs(sq - LP.s(i)) - (aL + cd(1))/2;
        gapE = abs(eq - LP.e(i)) - (aW + cd(2))/2;
        sep  = max(gapS, gapE);
        if sep < minSep, minSep = sep; worst = nm; tW = LP.t(i); end
    end
end
fprintf('\n--- SEPARATION FROM EVERY SCRIPTED ACTOR ---\n');
fprintf('  closest approach %.3f m to the %s at t=%.2f s   (placeholder 0.900 to moto_over)\n', ...
        minSep, worst, tW);

fprintf('\n--- STATE TIMELINE ---\n');
ch = [true, LP.State(2:end) ~= LP.State(1:end-1)];
idx = find(ch);
for k = idx
    fprintf('  %-10s t=%6.2f s  s=%6.1f m  v=%5.2f m/s  h=%+.3f  "%s"\n', ...
            LP.State(k), LP.t(k), LP.s(k), LP.v(k), LP.H(k), LP.Note(k));
end

fprintf('\n--- PHASE 2 GATE ---\n');
fprintf('  ran end to end:            %s (%d steps, s %d -> %.0f m)\n', ...
        string(LP.s(end) > ctx0.sStart), numel(LP.t), ctx0.sStart, LP.s(end));
fprintf('  no collision:              %s (min sep %.3f m)\n', string(minSep > 0), minSep);
fprintf('  planner clearance vs 0.965: %s (planner %.3f m)  <-- Phase 3 tunes this\n', ...
        string(cmp.planner >= 0.90), cmp.planner);

save(fullfile(here,'renders','s1_planner.mat'), 'LP', 'cmp', 'minSep', 'worst', 'tW');
fprintf('==================================================================\n\n');

% =======================================================================================
function LP = integratePlanner(W, P, c, TL, kappaV, DT, T, aUp, aDn, rLat, RefPath, planEvery, VIEW, TUNE, inLoop, who, DIMS)
st = struct();  s = c.sStart;  e = 1.75;  ev = 0;  v = 52/3.6;
rig = [];  if inLoop, rig = sc.senseRig(); end
n = round(T/DT);  nS = numel(TL);
LP = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
            'H',nan(1,n),'State',strings(1,n),'Note',strings(1,n));
lastCmd = struct('v',v,'e',e);
nFail = 0;  failFirst = NaN;
if VIEW, sc.plannerView('init', struct('P',P,'W',W,'CS',c.cowStation)); end
for i = 1:n
    t  = (i-1)*DT;
    ii = min(i, nS);
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));
    if inLoop
        tracksNow = sc.senseStep(rig, TL{ii}, who, DIMS, ...
                                 struct('Position',[xy 0],'Yaw',hdg), t);
    else
        tracksNow = TL{ii};
    end
    ctx = struct('s',s,'e',e,'v',v,'t',t, ...
        'W',W, 'Path',P, 'RefPath',RefPath, 'Tracks',tracksNow, ...
        'EgoXY',xy, 'EgoYaw',hdg, 'Kappa',kappaV(ki), 'CruiseV',52/3.6);
    fn = fieldnames(TUNE);
    for f = 1:numel(fn), ctx.(fn{f}) = TUNE.(fn{f}); end
    if mod(i-1, planEvery) == 0
        [cmd, st] = sc.s1drivePlanner(st, ctx);
        lastCmd = cmd;
        if isfield(cmd,'PlanFailed') && strlength(cmd.PlanFailed) > 0
            nFail = nFail + 1;
            if isnan(failFirst)
                failFirst = i;
                fprintf('  [plan FAIL] step %d  t=%.2f s  s=%.1f m  v=%.2f m/s  nTracks=%d\n     %s\n', ...
                        i, t, s, v, numel(TL{ii}), cmd.PlanFailed);
            end
        end
    else
        cmd = lastCmd;                 % hold the last plan between planner ticks
        cmd.State = st.State;  cmd.Note = st.Note;
    end
    if mod(i, 300) == 0
        fprintf('  ... step %d/%d  t=%.1f  s=%.1f m  v=%.2f m/s  state=%s\n', ...
                i, n, t, s, v, st.State);
    end
    dv = cmd.v - v;
    v  = max(0, v + max(-aDn*DT, min(aUp*DT, dv)));
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', rLat);
    s  = min(P.Len, s + v*DT);
    LP.t(i)=t; LP.s(i)=s; LP.e(i)=e; LP.v(i)=v;
    LP.State(i)=string(cmd.State); LP.Note(i)=string(cmd.Note);
    if isfield(cmd,'H'), LP.H(i)=cmd.H; end
    if VIEW
        sc.plannerView('step', struct('t',t,'s',s,'e',e,'v',v,'ego',xy,'yaw',hdg, ...
            'tracks',tracksNow,'cmd',cmd));
    end
end
if nFail > 0
    fprintf('  [plan FAIL] %d of %d planner ticks failed (first at step %d)\n', nFail, ceil(n/planEvery), failFirst);
end
end
