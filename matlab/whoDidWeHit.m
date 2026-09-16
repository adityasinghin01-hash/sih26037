function whoDidWeHit(runDir)
%WHODIDWEHIT  Which actor produced M6, and when? EXACT replica of
%   writeDemoResults/minClearanceToActors - Frenet (s,e), same projection, same
%   max(gapS,gapE). An earlier world-XY approximation disagreed with the official
%   number (-1.9 vs -0.800) and was therefore worthless. This reproduces M6 exactly
%   and reports the argmin instead of just the min.

here = fileparts(mfilename('fullpath'));  addpath(here);
T = readtable(fullfile(runDir,'trajectories.csv'));
W = sc.s1world();  [spec, tags] = sc.s1density();
[negPoses, negWho, negDIMS] = iNeg(here);
egoWidth = 1.8; egoLen = 4.7;

% trajectories.csv is per-ACTOR world XY (t,actor_id,class_id,x,y,z,yaw) and has no
% s/e columns. Actor 0 is the ego. M6 works in Frenet, so recover the ego's (s,e)
% from its own logged XY through the same Path.inverse the metric itself uses.
ego = T(T.actor_id == 0, :);
nE = height(ego);
egoS = zeros(nE,1); egoE = zeros(nE,1);
for q = 1:nE
    [egoS(q), egoE(q)] = W.Path.inverse([ego.x(q) ego.y(q)]);
end
fprintf('ego samples %d, t %.2f..%.2f s, s %.1f..%.1f m\n', ...
        nE, ego.t(1), ego.t(end), min(egoS), max(egoS));

best = struct('sep',inf,'name','','t',NaN,'i',NaN,'kind','','as',NaN,'ae',NaN);
worstPer = containers.Map('KeyType','char','ValueType','double');

n = min(nE, numel(negPoses));
for i = 1:n
    % -------- negotiation actors
    NP = negPoses{i};
    for k = 1:numel(NP)
        id = double(NP(k).ActorID);
        if ~isKey(negWho,id), continue; end
        tag = negWho(id);
        if ~isfield(negDIMS,tag), continue; end
        [sep, as, ae] = iSep(W, NP(k).Position(1:2), NP(k).Yaw, negDIMS.(tag), ...
                             egoS(i), egoE(i), egoLen, egoWidth);
        worstPer(tag) = min(iGet(worstPer,tag), sep);
        if sep < best.sep
            best = struct('sep',sep,'name',tag,'t',ego.t(i),'i',i,'kind','NEGOTIATION','as',as,'ae',ae);
        end
    end
    % -------- background actors
    A = sc.activeDensityActorsAt(spec, W.Path, ego.t(i));
    for k = 1:numel(A)
        nm = ['bg_' char(tags(A(k).Row))];
        [sep, as, ae] = iSep(W, A(k).XY, rad2deg(A(k).YawRad), A(k).Extent, ...
                             egoS(i), egoE(i), egoLen, egoWidth);
        worstPer(nm) = min(iGet(worstPer,nm), sep);
        if sep < best.sep
            best = struct('sep',sep,'name',nm,'t',ego.t(i),'i',i,'kind','BACKGROUND','as',as,'ae',ae);
        end
    end
end

fprintf('\n============ WHAT PRODUCED M6 ============\n');
fprintf('  actor       %s   (%s)\n', best.name, best.kind);
fprintf('  separation  %.4f m\n', best.sep);
fprintf('  at          t = %.2f s  (sample %d of %d)\n', best.t, best.i, n);
fprintf('  ego was at  s = %.2f m   e = %.2f m\n', egoS(best.i), egoE(best.i));
fprintf('  actor at    s = %.2f m   e = %.2f m\n', best.as, best.ae);
fprintf('\n--- worst separation per actor, closest 10 ---\n');
kk = keys(worstPer); vv = cell2mat(values(worstPer));
[vs, ord] = sort(vv);
for q = 1:min(10,numel(ord))
    fprintf('  %-28s %8.3f m\n', kk{ord(q)}, vs(q));
end
fprintf('==========================================\n\n');
end

function [sep, as, ae] = iSep(W, oXY, oYawDeg, dims, egoS, egoE, egoLen, egoWidth)
[as, ae] = W.Path.inverse(oXY(1:2));
[~, hdg] = W.Path.at(as, 0);
th = deg2rad(oYawDeg) - hdg;
aL = abs(dims(1)*cos(th)) + abs(dims(2)*sin(th));
aW = abs(dims(1)*sin(th)) + abs(dims(2)*cos(th));
gapS = abs(as - egoS) - (aL + egoLen)/2;
gapE = abs(ae - egoE) - (aW + egoWidth)/2;
sep = max(gapS, gapE);
end

function v = iGet(m,k), if isKey(m,k), v = m(k); else, v = inf; end, end
function [poses, who, DIMS] = iNeg(here)
run(fullfile(here,'s1_action_run.m'));
end
