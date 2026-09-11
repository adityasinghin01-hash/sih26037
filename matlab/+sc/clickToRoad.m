function [station, lateral, ok, reason] = clickToRoad(P, W, xy, egoStation)
%CLICKTOROAD  Validate a map click and express it in the route Frenet frame.
%
%   [s,e,ok,reason] = sc.clickToRoad(P,W,xy,egoS) uses the route's own
%   inverse transform. A live obstacle must be on the carriageway and far
%   enough ahead of the current ego pose for a new plan to react to it.

arguments
    P
    W
    xy (1,2) double
    egoStation (1,1) double
end

station = NaN;
lateral = NaN;
ok = false;
reason = "click rejected";

if any(~isfinite(xy))
    reason = "click has no finite map position";
    return
end

[station, lateral] = P.inverse(xy);
if ~isfinite(station) || ~isfinite(lateral)
    reason = "click could not be projected onto the route";
    return
end
if station <= egoStation + 6
    reason = "click at least 6 m ahead of the car";
    return
end
if station >= P.Len - 2
    reason = "click before the final 2 m of the route";
    return
end

halfWidth = W.Width/2;
try
    halfWidth = sc.s9Width(W, station);
catch
    % A minimal world used by a unit check may only expose Width. The live
    % demo worlds expose the richer station-varying width through s9Width.
end
if abs(lateral) > halfWidth
    reason = "click inside the carriageway";
    return
end

ok = true;
reason = "accepted";
end
