function profilePlanSeat(nSteps)
%PROFILEPLANSEAT  Where does the planner's time actually go?
%
%   profilePlanSeat(200)
%
%   sc.planSeat has NEVER been timed - its own source comments say so - and every
%   phase of the integration plan is paying for that. A dense S1 run now costs ~50
%   minutes, which caps the whole project at about four experiments a day, and makes
%   Phase 6 (repeated runs for confidence intervals) and Phase 9 (live at 10 Hz)
%   impossible rather than merely hard.
%
%   This runs a SHORT slice of the real dense scenario under MATLAB's profiler and
%   reports where the milliseconds go. It measures; it changes nothing.
%
%   The hypothesis to confirm or kill: sc.adapterS9Real's sight term ray-marches
%   against this world's ~2200 occluders EVERY step, and that dominates everything
%   else. If true, a spatial index over the occluders is the single highest-value
%   change available. If false, do not touch it - find the real cost first.

arguments
    nSteps (1,1) double = 200
end

here = fileparts(mfilename('fullpath'));  addpath(here);
W = sc.s1world();
[spec, tags] = sc.s1density();
P = W.Path;
RefPath = referencePathFrenet(W.Path.P);
kappaV  = W.Path.curvature();

DT = 0.05;  s = 25;  e = 1.75;  ev = 0;  v = 52/3.6;
A_LON = 1.8; D_LON = 3.2; R_LAT = 0.75;
TUNE = struct('TermSpeeds',[0 4 8 11 14.4], ...
    'LatOffsets',[-2.5 -1.585 -0.9 0 0.9 1.75 2.6], 'Horizon',4.0, 'TimeRes',0.1, ...
    'Inflation',0.0,'EgoWidth',1.8,'EgoLength',4.7,'Wheelbase',2.7, ...
    'LookaheadT',0.6,'MinLookahead',2.0,'DMin',2.5);

st = struct();
fprintf('\n=== PROFILING sc.planSeat over %d dense steps ===\n', nSteps);
stepTimes = zeros(1,nSteps);

profile off; profile('clear'); profile on;
tAll = tic;
for i = 1:nSteps
    t = (i-1)*DT;
    [xy, hdg] = P.at(s, e);
    ki = min(numel(kappaV), max(1, round(s/P.Step)+1));

    A = sc.activeDensityActorsAt(spec, W.Path, t);
    trk = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
        'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});
    for k = 1:numel(A)
        trk(end+1) = struct('TrackID',uint32(1000+A(k).Row),'ClassID',uint8(A(k).ClassID), ...
            'Position',[A(k).XY 0],'Velocity',A(k).Vel,'Extent',A(k).Extent, ...
            'Yaw',A(k).YawRad,'Existence',1,'Age',uint32(1),'SensorMask',uint8(1)); %#ok<AGROW>
    end

    ctx = struct('s',s,'e',e,'v',v,'t',t,'W',W,'Path',P,'RefPath',RefPath, ...
        'Tracks',trk,'EgoXY',xy,'EgoYaw',hdg,'Kappa',kappaV(ki),'CruiseV',52/3.6);
    f = fieldnames(TUNE);
    for q = 1:numel(f), ctx.(f{q}) = TUNE.(f{q}); end

    tStep = tic;
    [cmd, st] = sc.planSeat(st, ctx);
    stepTimes(i) = toc(tStep);

    dv = cmd.v - v;
    v  = max(0, v + max(-D_LON*DT, min(A_LON*DT, dv)));
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', R_LAT);
    s  = min(P.Len, s + v*DT);
end
wall = toc(tAll);
profile off;

fprintf('\n--- PER-STEP COST ---\n');
fprintf('  steps            %d\n', nSteps);
fprintf('  total wall       %.1f s\n', wall);
fprintf('  mean  per step   %.1f ms\n', 1000*mean(stepTimes));
fprintf('  median per step  %.1f ms\n', 1000*median(stepTimes));
fprintf('  p95   per step   %.1f ms\n', 1000*prctile(stepTimes,95));
fprintf('  max   per step   %.1f ms\n', 1000*max(stepTimes));
fprintf('  BUDGET for 10 Hz live: 100 ms/step -> %s\n', ...
    string(1000*median(stepTimes) < 100));
fprintf('  projected full 1240-step run: %.1f min\n', 1240*mean(stepTimes)/60);

p = profile('info');
[~, ord] = sort([p.FunctionTable.TotalTime], 'descend');
fprintf('\n--- TOP 18 BY TOTAL TIME ---\n');
fprintf('%-52s %9s %8s %10s\n','function','total s','calls','self s');
for k = 1:min(18, numel(ord))
    F = p.FunctionTable(ord(k));
    fprintf('%-52s %9.2f %8d %10.2f\n', F.FunctionName, F.TotalTime, F.NumCalls, ...
            F.TotalTime - sum([F.Children.TotalTime]));
end
fprintf('\nprofile saved - run profview in a desktop session for the full tree\n');
fprintf('======================================================\n\n');
end
