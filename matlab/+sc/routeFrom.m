function [path_m, pieces] = routeFrom(R, startXY, endXY, opts)
%ROUTEFROM  Chain road pieces into one continuous ego route, nearest-end first.
%
%   The ego needs ONE ordered centreline to follow. The road pieces come out of
%   localRoads in CSV order and each may run either way round, so they are chained
%   by endpoint proximity and flipped as needed.
%
%   MEASURE, DO NOT GUESS: the joins are asserted to close within opts.joinTol_m.
%   A route that silently teleports 40 m at a join produces a planner trace that
%   looks fine and is meaningless.
%
%   INPUTS
%     R        struct array from sc.localRoads
%     startXY  1x2 double  where the route begins, m
%     endXY    1x2 double  where it should end,   m
%     opts.joinTol_m   max gap allowed at a join, default 30 m
%     opts.classes     restrict to these OSM classes, default all
%
%   OUTPUT
%     path_m   Nx2 double  ordered centreline, m
%     pieces   1xK double  indices into R, in the order used

arguments
    R struct
    startXY (1,2) double
    endXY   (1,2) double
    opts.joinTol_m (1,1) double = 30.0
    opts.classes   string = strings(0,1)
end

if ~isempty(opts.classes)
    keep = ismember([R.Class], opts.classes);
    assert(any(keep), "sc:noSuchClass", "no pieces of class %s", strjoin(opts.classes,", "));
    idxMap = find(keep);
    R = R(keep);
else
    idxMap = 1:numel(R);
end

used   = false(1,numel(R));
path_m = zeros(0,2);
pieces = [];
cur    = startXY;

while true
    % ---- choose the next piece by JOIN + HEADING CONTINUITY + GOAL, not by join alone ----
    % At a six-arm node several pieces join at distance 0, so nearest-end alone picks
    % arbitrarily and the ego can leave on the wrong arm or U-turn. Driving through a
    % junction means holding your heading unless the route says otherwise, so heading
    % change is scored, and the goal breaks the remaining tie.
    if isempty(path_m)
        curHdg = atan2(endXY(2)-cur(2), endXY(1)-cur(1));   % aim at the goal to start
    else
        tail   = path_m(max(1,end-4),:);
        curHdg = atan2(cur(2)-tail(2), cur(1)-tail(1));
    end

    bestScore = inf; bestK = 0; bestFlip = false;
    for k = 1:numel(R)
        if used(k), continue; end
        p = R(k).Centers;
        for flip = [false true]
            q = p; if flip, q = flipud(q); end
            dJoin = norm(q(1,:) - cur);
            if dJoin > opts.joinTol_m, continue; end
            nxt   = q(min(size(q,1),5),:);
            hdg   = atan2(nxt(2)-q(1,2), nxt(1)-q(1,1));
            dHdg  = abs(wrapToPi(hdg - curHdg));
            dGoal = norm(q(end,:) - endXY);
            score = dJoin + 40*dHdg + 0.15*dGoal;
            if score < bestScore
                bestScore = score; bestK = k; bestFlip = flip;
            end
        end
    end
    if bestK == 0, break; end

    p = R(bestK).Centers;
    if bestFlip, p = flipud(p); end

    if isempty(path_m)
        path_m = p;
    else
        gap = norm(p(1,:) - path_m(end,:));
        assert(gap <= opts.joinTol_m, "sc:openJoin", ...
            "route join of %.1f m exceeds tolerance %.1f m", gap, opts.joinTol_m);
        path_m = [path_m; p(2:end,:)];   %#ok<AGROW>  drop the duplicated shared node
    end
    used(bestK) = true;
    pieces(end+1) = idxMap(bestK);       %#ok<AGROW>
    cur = path_m(end,:);

    if norm(cur - endXY) < opts.joinTol_m, break; end
end

assert(size(path_m,1) >= 2, "sc:emptyRoute", "route chained no pieces");

% ---- assertions: the route must be monotone-ish and closed ----
d = vecnorm(diff(path_m),2,2);
assert(all(d > 0), "sc:dupPoint", "route contains a zero-length step");
% NOTE: a legitimate road piece carries points up to ~90 m apart (the CSV is sparse),
% so point spacing is NOT a join gap and must not be asserted against joinTol_m.
% The joins themselves are asserted above, one at a time, as they are made.
end
