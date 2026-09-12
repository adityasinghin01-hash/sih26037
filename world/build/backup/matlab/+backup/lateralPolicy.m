function [eTarget, clearance, note] = lateralPolicy(egoP, egoYaw, tracks, W, lane, egoWidth, eNow)
%LATERALPOLICY  Choose a lateral offset by MEASURING the free gaps ahead.
%
%   A DOCUMENTED STAND-IN FOR D6, WHICH IS NOT BUILT.
%   sih.planner.chooseVelocity deliberately performs no lateral avoidance: going around
%   something is a candidate path and belongs to the contingency planner, which can check
%   it against both futures. The backup demo needs the S1 cow squeeze and the S1 wrong-side
%   motorcycle, so this supplies both - by MEASURING, which is the part that must be right.
%
%   METHOD
%     1. Every hazard ahead within LOOKAHEAD projects a lateral interval, widened by MARGIN.
%     2. Subtract those from the usable width to get the FREE intervals.
%     3. Keep the free intervals at least egoWidth wide - the ones the ego actually fits in.
%     4. Choose between them by a rule that depends on what the nearest hazard is doing:
%
%        STATIONARY hazard -> take the WIDEST gap.
%          This is what the written S1 does: 7.0 m carriageway, cow spanning +0.30..+1.00 m,
%          free width to its right 0.30-(-3.50) = 3.80 m against 2.50 m on its left, so the
%          car goes right. Ego 1.90 m with mirrors -> margin 0.95 m each side. The written
%          script's arithmetic reproduces exactly.
%
%        MOVING ONCOMING hazard -> go LEFT, and the shoulder is allowed.
%          Rules of the Road Regulations 1989, reg. 2: drive "as close to the left side of
%          the road as may be expedient and shall allow all traffic which is proceeding in
%          the opposite direction to pass on his right hand side." This is the same
%          derivation chooseVelocity uses for its positive (left) HEAD_ON steer, applied
%          laterally. It is why the written S1 says "Ego moves left onto the shoulder".
%
%   It does NOT plan a trajectory, look past the nearest hazard, or reason about two
%   futures. It is a measured free-space choice with a written margin.
%
%   OUTPUT
%     eTarget    target lateral offset, m, POSITIVE IS LEFT
%     clearance  the tighter side margin actually available in the chosen gap, m
%     note       one line stating what was measured

MARGIN    = 0.35;     % lateral clearance demanded on each side of a hazard
LOOKAHEAD = 30.0;     % m
SHOULDER  = 1.20;     % m of earthen shoulder, S1: "Earthen shoulders 1.2 m"

eTarget = lane; clearance = NaN; note = "lane keeping";

fwd = [cos(egoYaw), sin(egoYaw)]; lft = [-sin(egoYaw), cos(egoYaw)];

% ---- hazards ahead, with their lateral spans ----
occ = zeros(0,2); nearestAx = inf; nearestMoving = false; nearestOncoming = false;
for k = 1:numel(tracks)
    r  = tracks(k).Position(1:2) - egoP;
    ax = dot(r, fwd); ay = dot(r, lft);
    if ax <= 0 || ax > LOOKAHEAD, continue; end
    halfW = tracks(k).Extent(2)/2;
    if abs(ay) - halfW > W/2 + SHOULDER, continue; end        % genuinely off the road
    occ(end+1,:) = [ay - halfW - MARGIN, ay + halfW + MARGIN]; %#ok<AGROW>
    if ax < nearestAx
        nearestAx = ax;
        vk = tracks(k).Velocity(1:2);
        nearestMoving   = norm(vk) > 0.15;
        nearestOncoming = dot(vk, fwd) < -0.1;
    end
end
if isempty(occ), return; end

% ---- usable width. The shoulder is only available when evading someone moving at us. ----
useShoulder = nearestMoving && nearestOncoming;
lo = -W/2; hi = W/2;
if useShoulder, lo = lo - SHOULDER; hi = hi + SHOULDER; end

% ---- free intervals = usable width minus the occupied spans ----
occ = sortrows(occ);
free = zeros(0,2); cursor = lo;
for i = 1:size(occ,1)
    if occ(i,1) > cursor, free(end+1,:) = [cursor, occ(i,1)]; end %#ok<AGROW>
    cursor = max(cursor, occ(i,2));
end
if cursor < hi, free(end+1,:) = [cursor, hi]; end %#ok<AGROW>

fits = (free(:,2) - free(:,1)) >= egoWidth;
if ~any(fits)
    [wBest, j] = max(free(:,2) - free(:,1));
    eTarget   = eNow;                       % nothing fits: hold position, never squeeze
    clearance = (wBest - egoWidth)/2;
    note = sprintf("NO GAP: widest free %.2f m < ego %.2f m - holding", wBest, egoWidth);
    return
end
free = free(fits,:);
widths = free(:,2) - free(:,1);

% ---- the choice ----
if useShoulder
    [~, j] = max(free(:,1));                % leftmost gap that fits - RRR 1989 reg. 2
    why = "LEFT (RRR reg.2, oncoming passes on our right)";
else
    [~, j] = max(widths);                   % widest gap - the written S1 measurement
    why = "WIDEST";
end

centre    = mean(free(j,:));
eTarget   = max(free(j,1) + egoWidth/2, min(free(j,2) - egoWidth/2, centre));
clearance = (widths(j) - egoWidth)/2;
note = sprintf("gap %s: free %.2f m, ego %.2f m, margin %.2f m each side, offset %+.2f m", ...
               why, widths(j), egoWidth, clearance, eTarget);
end
