function R = gridSweep(nSteps)
%GRIDSWEEP  PHASE 9 - what does a cheaper planner actually cost in driving quality?
%
%   R = gridSweep(150)
%
%   Live planning needs 100 ms/step for 10 Hz. Measured: 735.8 ms. We are 7.4x off.
%
%   PRUNING ALREADY FAILED, and that result drove this design. Removing 27 of 60
%   tracks per step changed the runtime by 0.6% - noise - because the cost is NOT
%   set by how many obstacles exist. checkTrajectorySafety runs 1,023 times per
%   step = 35 candidates x ~29 horizon samples. The CANDIDATE GRID is the
%   multiplier: TermSpeeds (5) x LatOffsets (7) = 35, each sampled at TimeRes 0.1 s
%   over a 4.0 s horizon.
%
%   SO THIS IS THE ONLY LEVER LEFT - AND UNLIKE PRUNING IT IS NOT FREE.
%   Fewer candidates is a coarser search. The car may plan worse: less clearance,
%   more stopping, or a route it cannot finish. A faster planner that drives worse
%   is not a win, it is a different planner. This measures BOTH sides so the
%   trade can be decided on numbers instead of hope.
%
%   WHAT IS DELIBERATELY NOT DONE HERE: no attempt to pick a "best" grid. This
%   reports the curve. Choosing a point on it changes what the planner IS and that
%   is Aditya's call, not a script's.

arguments
    nSteps (1,1) double = 150
end

here = fileparts(mfilename('fullpath'));  addpath(here);
W = sc.s1world(); [spec, ~] = sc.s1density(); P = W.Path;
RefPath = referencePathFrenet(W.Path.P);
kappaV  = W.Path.curvature();
HZ = sc.demo1Route();

% the grids to try, coarsest last. Row 1 is the SHIPPED grid - the reference.
grids = { ...
  struct('name',"35 shipped", 'T',[0 4 8 11 14.4],    'L',[-2.5 -1.585 -0.9 0 0.9 1.75 2.6]), ...
  struct('name',"20",         'T',[0 4 8 14.4],       'L',[-2.5 -1.585 0 0.9 2.6]), ...
  struct('name',"15",         'T',[0 8 14.4],         'L',[-2.5 -1.585 0 0.9 2.6]), ...
  struct('name',"9",          'T',[0 8 14.4],         'L',[-1.585 0 1.75]), ...
  struct('name',"6",          'T',[0 14.4],           'L',[-1.585 0 1.75])};

fprintf('\n=========== PHASE 9: CANDIDATE GRID SWEEP (%d steps each) ===========\n', nSteps);
fprintf('%-12s %8s %10s %10s %12s %10s\n','grid','nCand','median ms','mean ms','10Hz ok?','min sep m');
R = struct('name',{},'nCand',{},'medMs',{},'meanMs',{},'minSep',{});

for g = 1:numel(grids)
    G = grids{g};
    TUNE = struct('TermSpeeds',G.T,'LatOffsets',G.L,'Horizon',4.0,'TimeRes',0.1, ...
        'Inflation',0.0,'EgoWidth',1.8,'EgoLength',4.7,'Wheelbase',2.7, ...
        'LookaheadT',0.6,'MinLookahead',2.0,'DMin',2.5);
    s = 25; e = 1.75; ev = 0; v = 52/3.6; DT = 0.05;
    st = struct(); tms = zeros(1,nSteps); minSep = inf;
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
        f = fieldnames(TUNE); for q=1:numel(f), ctx.(f{q}) = TUNE.(f{q}); end
        tic; [cmd, st] = sc.planSeat(st, ctx); tms(i) = toc;
        cap = sc.hazardCap(HZ, s, v, 52/3.6);
        if isfinite(cap) && cap < cmd.v, cmd.v = cap; end
        dv = cmd.v - v; v = max(0, v + max(-3.2*DT, min(1.8*DT, dv)));
        [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT, 'RateCap', 0.75);
        s = min(P.Len, s + v*DT);
        for k = 1:numel(trk)
            d = norm(trk(k).Position(1:2) - xy) - 3.0;
            if d < minSep, minSep = d; end
        end
    end
    nC = numel(G.T)*numel(G.L);
    med = 1000*median(tms); mn = 1000*mean(tms);
    fprintf('%-12s %8d %10.1f %10.1f %12s %10.3f\n', G.name, nC, med, mn, ...
            string(med < 100), minSep);
    R(end+1) = struct('name',G.name,'nCand',nC,'medMs',med,'meanMs',mn,'minSep',minSep); %#ok<AGROW>
end
fprintf('\n  10 Hz needs median < 100 ms. Read the SPEED and the CLEARANCE together:\n');
fprintf('  a grid that hits the budget but drives worse has not solved anything.\n');
fprintf('===================================================================\n\n');
end
