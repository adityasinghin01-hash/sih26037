%S2_PLANNER_RUN  The real sih.planner in the S2 (the chowk) seat, against the
%   frozen scripted S2 traffic. Phase 4 of the 1-5 integration.
%
%   Same shape as s1_planner_run.m: run()s s2_action_run.m for the frozen world
%   and recorded actor poses, builds the referencePathFrenet + per-step
%   world-frame TrackLists, drives sc.s2drivePlanner in the seat, measures the
%   same numbers s2_action_run measures, saves renders/s2_planner.mat.
%
%   sc.s2drive (scripted, senses ctx.YieldDrop) is NOT touched and is what ships.

here = fileparts(mfilename('fullpath'));  addpath(here);
assert(~isempty(which('sih.planner.planContingency')), 'sih.planner not on the path');

if ~exist('VIEW','var'),       VIEW = false;      end
if ~exist('PLAN_EVERY','var'), PLAN_EVERY = 1;    end
if ~exist('INLOOP','var'),     INLOOP = true;     end     % Phase 8b: sense from the ego's
                                                           % ACTUAL pose each step - see
                                                           % sc.senseRig for the measured defect
                                                           % the precomputed batch has.
if ~exist('SENSED','var'),     SENSED = true;     end     % Phase 5: noisy sensing+tracking,
                                                           % not sc.buildTrackList's exact
                                                           % positions. SENSED=false reverts
                                                           % to the old exact-position TL for
                                                           % an A/B comparison.

% ---- Phase-3/4 tuning dials -------------------------------------------------------
TUNE = struct( ...
    'TermSpeeds',   [0 2 4 6 7.3], ...     % S2 runs slow: 26 km/h approach, 22 ring
    'LatOffsets',   [-3.0 -2.6 -1.6 -0.8 0 0.9 1.75], ...
    'Horizon',      4.0, ...
    'TimeRes',      0.1, ...
    'Inflation',    0.0, ...
    'EgoWidth',     1.8, ...
    'EgoLength',    4.7, ...
    'Wheelbase',    2.7, ...
    'LookaheadT',   0.7, ...
    'MinLookahead', 2.0, ...
    'DMin',         2.5, ...
    'ELo',         -3.4, ...
    'EHi',          2.5, ...
    'RelevanceRange',   55, ...
    'RelevanceOffRoad',  7);

run(fullfile(here,'s2_action_run.m'));   % W P DT T_END ctx0 A poses tS who DIMS av vEarly V0

fprintf('\n================ S2 PLANNER RUN (adapter, Phase 4) ================\n');

[~, carD] = sc.meshes("car");
Wp = W;  if ~isfield(Wp,'Width'), Wp.Width = W.ArmW; end       % adapterS9 wants .Width
RefPath = referencePathFrenet(W.EgoRoute.P);
kappaV  = W.EgoRoute.curvature();
if SENSED && INLOOP
    TL = poses;                      % sensed live inside the loop from the real ego pose
    fprintf('SENSING IN-LOOP from the ego''s own pose (%d steps of raw poses)\n', numel(poses));
elseif SENSED
    [TL, sensDiag] = sc.buildTrackListSensed(poses, who, DIMS, L, P);
    fprintf('built %d SENSED per-step TrackLists (simulated lidar/radar/ring + tracker)\n', numel(TL));
    fprintf('  mean detections/frame %.2f, mean tracks/frame %.2f\n', ...
            sensDiag.nDetPerFrame, sensDiag.nTrackPerFrame);
else
    nS = numel(poses);
    TL = cell(1, nS);
    for i = 1:nS
        TL{i} = sc.buildTrackList(poses{i}, who, DIMS);
    end
    fprintf('built %d EXACT-POSITION per-step TrackLists (%d..%d road users)\n', ...
            nS, min(cellfun(@numel,TL)), max(cellfun(@numel,TL)));
end
nS = numel(TL);   % SENSED truncates to min(poses,egoLog) - keeps every later index
                  % (e.g. the collision-separation loop below) inside TL either way

LP = integrateS2(Wp, W.EgoRoute, ctx0, TL, kappaV, DT, T_END, V0, RefPath, PLAN_EVERY, VIEW, TUNE, ...
                 poses, who, A, av, vEarly, SENSED && INLOOP, DIMS);

% ---- measure the same S2 numbers ------------------------------------------------
P = W.EgoRoute;  minSep = inf; worst=''; tW=NaN;
for i = 1:min(numel(LP.t), nS)
    pp = poses{i};
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        nm = who(pp(q).ActorID);  dq = DIMS.(nm);
        [sq, eq] = P.inverse(pp(q).Position(1:2));
        [~, hq]  = P.at(sq, 0);
        th = deg2rad(pp(q).Yaw) - hq;
        aL = abs(dq(1)*cos(th)) + abs(dq(2)*sin(th));
        aW = abs(dq(1)*sin(th)) + abs(dq(2)*cos(th));
        gapS = abs(sq - LP.s(i)) - (aL + carD(1))/2;
        gapE = abs(eq - LP.e(i)) - (aW + carD(2))/2;
        sep  = max(gapS, gapE);
        if sep < minSep, minSep = sep; worst = nm; tW = LP.t(i); end
    end
end

fprintf('\n--- STATE TIMELINE ---\n');
ch = [true, LP.State(2:end) ~= LP.State(1:end-1)];
for k = find(ch)
    fprintf('  %-10s t=%6.2f s  s=%6.1f m  v=%5.2f m/s  h=%+.3f  yieldDrop=%.1f  "%s"\n', ...
            LP.State(k), LP.t(k), LP.s(k), LP.v(k), LP.H(k), LP.YD(k), LP.Note(k));
end

fprintf('\n--- PHASE 4 GATE (vs sc.s2drive: commit on the 1.8 km/h yield, min sep 0.886 m, exit the ring) ---\n');
fprintf('  ran end to end:      %s  (%d steps, s %.0f -> %.0f m of %.0f)\n', ...
        string(LP.s(end) > ctx0.sStart), numel(LP.t), ctx0.sStart, LP.s(end), P.Len);
fprintf('  reached the ring exit (s>=%.0f): %s\n', W.SRingOut, string(LP.s(end) >= W.SRingOut));
fprintf('  no collision:        %s  (min sep %.3f m to the %s at t=%.2f s)\n', ...
        string(minSep > 0), minSep, worst, tW);
committed = any(LP.State == "COMMIT");
fprintf('  committed at all:    %s\n', string(committed));

save(fullfile(here,'renders','s2_planner.mat'), 'LP', 'minSep', 'worst', 'tW');
fprintf('==================================================================\n\n');

% =======================================================================================
function LP = integrateS2(W, P, c, TL, kappaV, DT, T, V0, RefPath, planEvery, VIEW, TUNE, ...
                          poses, who, A, av, vEarly, inLoop, DIMS)
st = struct();  s = c.sStart;  e = 1.75;  ev = 0;  v = V0;
rig = [];  if inLoop, rig = sc.senseRig(); end
A_LON = 1.8;  D_LON = 3.2;
n = round(T/DT);  nS = numel(TL);
LP = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
            'H',nan(1,n),'YD',zeros(1,n),'State',strings(1,n),'Note',strings(1,n));
lastCmd = struct('v',v,'e',e);  nFail = 0;
if VIEW, sc.plannerView('init', struct('P',P,'W',W,'CS',NaN)); end
for i = 1:n
    t  = (i-1)*DT;   is = max(1, min(nS, round(t/DT)+1));
    [xy, hdg] = P.at(s, e);
    ki  = min(numel(kappaV), max(1, round(s/P.Step)+1));
    yd  = 3.6 * max(0, vEarly - av(is));
    pw  = poses{is}([poses{is}.ActorID] == A.Wrong.ActorID);
    [sw,~] = P.inverse(pw.Position(1:2));
    if inLoop
        tracksNow = sc.senseStep(rig, TL{is}, who, DIMS, ...
                                 struct('Position',[xy 0],'Yaw',hdg), t);
    else
        tracksNow = TL{is};
    end
    ctx = struct('s',s,'e',e,'v',v,'t',t, 'W',W, 'Path',P, 'RefPath',RefPath, ...
        'Tracks',tracksNow, 'EgoXY',xy, 'EgoYaw',hdg, 'Kappa',kappaV(ki), ...
        'CruiseV',26/3.6, 'YieldDrop',yd, 'WrongWayRange',sw - s);
    fn = fieldnames(TUNE); for f = 1:numel(fn), ctx.(fn{f}) = TUNE.(fn{f}); end
    if mod(i-1, planEvery) == 0
        [cmd, st] = sc.s2drivePlanner(st, ctx);
        lastCmd = cmd;
        if isfield(cmd,'PlanFailed') && strlength(cmd.PlanFailed) > 0, nFail = nFail + 1; end
    else
        cmd = lastCmd;  cmd.State = st.State;  cmd.Note = st.Note;
    end
    dv = cmd.v - v;
    v  = max(0, v + max(-D_LON*DT, min(A_LON*DT, dv)));
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT);
    s  = min(P.Len, s + v*DT);
    LP.t(i)=t; LP.s(i)=s; LP.e(i)=e; LP.v(i)=v; LP.YD(i)=yd;
    LP.State(i)=string(cmd.State); LP.Note(i)=string(cmd.Note);
    if isfield(cmd,'H'), LP.H(i)=cmd.H; end
    if mod(i,300)==0, fprintf('  ... step %d/%d t=%.1f s=%.1f v=%.2f state=%s\n', i,n,t,s,v,st.State); end
    if VIEW
        sc.plannerView('step', struct('t',t,'s',s,'e',e,'v',v,'ego',xy,'yaw',hdg, ...
            'tracks',tracksNow,'cmd',cmd));
    end
end
if nFail > 0, fprintf('  [plan FAIL] %d of %d planner ticks\n', nFail, ceil(n/planEvery)); end
end
