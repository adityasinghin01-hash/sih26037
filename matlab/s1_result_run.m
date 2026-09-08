%S1_RESULT_RUN  PHASE 4 - the S1 RESULT. Live gap arithmetic, the defensive stand-in
%               beside us, and map/ego_S1.csv.
%
%   The traffic is SCRIPTED - it does not react to the ego - so both drivers can be run
%   against the same recorded actor poses and the comparison is exact rather than
%   approximate. Said plainly, because it is the reason the side-by-side is fair.

here = fileparts(mfilename('fullpath')); addpath(here);
run(fullfile(here,'s1_action_run.m'));      % W, A, poses, tS, log1, ctx0, who, DIMS, DT

fprintf('\n================ S1 RESULT, PHASE 4 ================\n');

% ---------------------------------------------------------------- obstacles per step
% Every scripted actor, in path coordinates, with its own yaw and its own ASSERTED
% mesh dimensions. This is what both drivers and the gap arithmetic read.
nS = numel(poses);
OBS = cell(1, nS);
for i = 1:nS
    pp = poses{i};  o = struct('s',{},'e',{},'yaw',{},'dim',{},'halfW',{},'name',{});
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        nm = who(pp(q).ActorID);  dq = DIMS.(nm);
        [sq, eq] = P.inverse(pp(q).Position(1:2));
        [~, hq]  = P.at(sq, 0);
        th = deg2rad(pp(q).Yaw) - hq;
        o(end+1) = struct('s',sq, 'e',eq, 'yaw',deg2rad(pp(q).Yaw), 'dim',dq, ...
            'halfW',(abs(dq(1)*sin(th))+abs(dq(2)*cos(th)))/2, 'name',nm);   %#ok<SAGROW>
    end
    OBS{i} = o;
end

% ---------------------------------------------------------------- OUR live gap
fprintf('\n--- THE GAP, MEASURED EVERY STEP FROM REAL POSES ---\n');
n = numel(log1.t);
G = struct('Free',nan(1,n), 'Margin',nan(1,n), 'PassE',nan(1,n), ...
           'Range',nan(1,n), 'Fits',false(1,n), 'Bind',strings(1,n));
for i = 1:n
    o = OBS{min(i,nS)};
    g = sc.s1gap(W, log1.s(i), log1.e(i), o, cd);
    G.Free(i)=g.Free; G.Margin(i)=g.Margin; G.PassE(i)=g.PassE;
    G.Range(i)=g.Range; G.Fits(i)=g.Fits;
    if g.Binding>0, G.Bind(i)=o(g.Binding).name; end
end
iCow = find(G.Bind=="cow", 1);
fprintf('  first sees the cow as the binding obstacle at t=%.2f s, %.0f m ahead\n', ...
        log1.t(iCow), G.Range(iCow));
fprintf('  it measures free %.2f m, margin %.3f m -> FITS = %s\n', ...
        G.Free(iCow), G.Margin(iCow), string(G.Fits(iCow)));
[~, iAlong] = min(abs(log1.s - CS));
fprintf('  level with her at t=%.2f s: free %.2f m, margin %.3f m\n', ...
        log1.t(iAlong), G.Free(iAlong), G.Margin(iAlong));
cowGap = G.Free(G.Bind=="cow");
fprintf('  free width while she is binding: %.3f-%.3f m\n', min(cowGap), max(cowGap));

% THE MINIMUM IS NOT A FAILURE, AND ASSERTING ON IT WAS THE WRONG QUESTION. The gap
% NOTE, 5 Sep: the old 0.588 m dip is GONE. It happened while she rotated from
% broadside to parallel, and that rotation no longer exists - she stops broadside and
% stays there, so the narrowest margin at any instant is the pass margin itself.
% does occupy more of the road, and the measurement is right to say so. The ego is 18 m
% away and stopped at that moment. What has to hold is the clearance from the instant
% the planner COMMITS onwards, because that is the width it actually drives through.
iCommit = find(log1.State=="COMMIT", 1);
mCommit = G.Margin(iCommit:end);  mCommit = mCommit(~isnan(mCommit));
fprintf('  narrowest at any time: %.3f m margin, at t=%.2f s with the ego %.0f m back\n', ...
        min(G.Margin(G.Bind=="cow")), ...
        log1.t(find(G.Margin==min(G.Margin(G.Bind=="cow")),1)), ...
        CS - log1.s(find(G.Margin==min(G.Margin(G.Bind=="cow")),1)));
fprintf('  from COMMIT (t=%.2f s) onwards: margin %.3f-%.3f m\n', ...
        log1.t(iCommit), min(mCommit), max(mCommit));
assert(min(mCommit) >= 0.90 - 1e-9, "sc:gapFail", ...
    "after committing, the measured margin drops to %.3f m", min(mCommit));

% ---------------------------------------------------------------- THE DEFENSIVE RUN
fprintf('\n--- THE DEFENSIVE STAND-IN (OURS, NOT MathWorks) ---\n');
D = integrateD(P, ctx0, OBS, DT, T_END, A_LON, D_LON, @sc.s1defensive);
% WHAT DID IT ACTUALLY DO? Print it before judging it.
sts = unique(D.State, 'stable');
fprintf('  states visited: %s\n', strjoin(cellstr(sts), ' -> '));
tAtCow = D.t(find(D.s >= CS, 1));
if isempty(tAtCow), tAtCow = NaN; end
tCowSet = tS(find(cowV < 1e-4 & (1:numel(cowV)) > find(cowE <= W.Width/2,1), 1));
if isnan(tAtCow)
    fprintf('  NEVER reaches her station. She is standing there from t=%.2f s.\n', tCowSet);
else
    fprintf('  reaches her station at t=%.2f s; she stands there from t=%.2f s\n', tAtCow, tCowSet);
end
iStop = find(D.State=="STOPPED", 1);
if isempty(iStop)
    fprintf('  it never stopped - which would break the argument. CHECK THIS.\n');
else
    fprintf('  STOPPED at t=%.2f s, station %.1f m, %.1f m short of the cow\n', ...
            D.t(iStop), D.s(iStop), CS - D.s(iStop));
    fprintf('  still stopped at the end of the run (t=%.1f s): %s\n', ...
            D.t(end), string(D.State(end)=="STOPPED"));
    fprintf('  it travelled %.1f m in %.1f s and never passed her.\n', ...
            D.s(end)-ctx0.sStart, D.t(end));
end
fprintf('  OURS  reached %.1f m and cleared her by %.3f m at %.1f km/h\n', ...
        log1.s(end)-ctx0.sStart, G.Margin(iAlong), 3.6*log1.v(iAlong));
% THE RESULT: a purely defensive rule cannot finish this road, and it is not because
% the rule is bad. "Keep your lane; stop for anything blocking it" is correct and safe.
% It is that a cow never clears, so the wait never ends. Structural, not tuned.
assert(max(D.s) < CS, "sc:defensivePassed", ...
    "the defensive stand-in reached %.1f m and got past the cow at %.1f m", max(D.s), CS);
assert(D.State(end) == "STOPPED", "sc:defensiveMoved", ...
    "the defensive stand-in is not still stopped at the end of the run");


% ---------------------------------------------------------------- THE CSV
outCsv = fullfile(sc.refRoot(),'world','map','ego_S1.csv');
hdg = zeros(1,n);  X = zeros(1,n);  Y = zeros(1,n);
for i = 1:n
    [xy, h] = P.at(log1.s(i), log1.e(i));
    X(i)=xy(1); Y(i)=xy(2); hdg(i)=h;
end
Tcsv = table(log1.t(:), X(:), Y(:), hdg(:), log1.v(:), ...
             'VariableNames', {'time','x','y','heading','speed'});
writetable(Tcsv, outCsv);
assert(isfile(outCsv), "sc:noCsv", "%s was not written", outCsv);
assert(~any(isnan([X Y hdg log1.v])), "sc:csvNaN", "the CSV contains NaN");
fprintf('\n--- map/ego_S1.csv ---\n');
fprintf('  %d rows, %.2f s, %.1f m, OSM-metric frame (the shared one)\n', ...
        height(Tcsv), log1.t(end), log1.s(end)-ctx0.sStart);
fprintf('  x %.1f..%.1f   y %.1f..%.1f   speed %.2f..%.2f m/s\n', ...
        min(X), max(X), min(Y), max(Y), min(log1.v), max(log1.v));

save(fullfile(here,'renders','s1_result.mat'), 'G', 'D', 'log1', 'beatsRaw', 'Tcsv');
fprintf('\n===================================================\n\n');

% =======================================================================================
function L = integrateD(P, c, OBS, DT, T, aUp, aDn, drv)
%INTEGRATED  The same loop as ours, with a different driver in the seat. That is the point.
st = struct();  s = c.sStart;  e = 1.75;  v = 52/3.6;  n = round(T/DT);
L = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
           'State',strings(1,n),'Note',strings(1,n));
for i = 1:n
    ctx = c;  ctx.s=s; ctx.e=e; ctx.v=v; ctx.t=(i-1)*DT;
    ctx.Obs = OBS{min(i, numel(OBS))};
    [cmd, st] = drv(st, ctx);
    v = max(0, v + max(-aDn*DT, min(aUp*DT, cmd.v - v)));
    rNow = min(0.75, tand(12)*v);
    e = e + max(-rNow*DT, min(rNow*DT, cmd.e - e));
    s = min(P.Len, s + v*DT);
    L.t(i)=(i-1)*DT; L.s(i)=s; L.e(i)=e; L.v(i)=v;
    L.State(i)=st.State; L.Note(i)=st.Note;
end
end
