function T = estimateDuration(H, sStart, routeLen, cruise, cowMode)
%ESTIMATEDURATION  How long this route actually takes, walked station by station
%   at whatever cap binds there. Self-correcting: change a SpeedCap and this
%   follows, which is the whole point.
%
%   A DISCLOSED DUPLICATE of demo_play.m's own private estimateDuration, lifted
%   verbatim 16 Sep 2026 - same reason and same precedent as sc.hazardCap.
%   IF demo_play's COPY CHANGES, THIS MUST CHANGE WITH IT.
%
%   WHY THIS EXISTS AT ALL: densityPlannerRun hardcoded T_END = 62 s, copied from
%   the sparse S1 config. Once sc.demo1Route's speed caps were applied the car got
%   slower, 62 s stopped covering 610 m, and the run ended at s=403.7 m with
%   M9_completed=false. The constant was copied; the mechanism was not.
%
%   THIS RETURNS A GENEROUS UPPER BOUND, NOT A PREDICTION, and the asymmetry is
%   deliberate - demo_play's own header records that a 1.35 margin ESTIMATE
%   returned 88 s for a route that takes 101 s, because a station-by-station walk
%   ignores every acceleration and braking transition between caps. Doubling is
%   not a tuned constant; it is the acknowledgement that this walk systematically
%   underestimates and that erring long is free.

arguments
    H struct
    sStart (1,1) double
    routeLen (1,1) double
    cruise (1,1) double
    cowMode (1,1) string = "blocking"
end

ds = 2.0;  T = 0;
for u = sStart:ds:routeLen
    v = cruise;
    for k = 1:numel(H)
        c = H(k).SpeedCap;
        if ~isfinite(c), continue; end
        [lo, hi] = iStretch(H(k));
        if u >= lo && u <= hi, v = min(v, c); end
    end
    T = T + ds/max(v, 1.0);
end
T = 2.0*T;                                    % a deliberately loose upper bound
if cowMode == "blocking", T = T + 15; end     % the WAIT rung's time at a standstill
T = min(220, max(40, T));
end

function [lo, hi] = iStretch(h)
r = 2.0;
if isfinite(h.Radius), r = max(2.0, h.Radius); end
if h.Zone > 0
    lo = h.Station;  hi = h.Station + h.Zone;
else
    lo = h.Station - r;  hi = h.Station + r;
end
end
