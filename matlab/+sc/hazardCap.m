function [cap, why] = hazardCap(H, s, v, vRef)
%HAZARDCAP  The tightest hazard-imposed speed cap in force at station s.
%
%   A DISCLOSED DUPLICATE of demo_play.m's own private hazardCap/stretch pair,
%   lifted verbatim on 16 Sep 2026 so densityPlannerRun can apply the same road
%   constraints without editing demo_play.m (which is shared with the live demo).
%   Same precedent as sc.activeDensityActorsAt, which duplicates demo_play's
%   private activeActorsAt for exactly this reason.
%
%   IF demo_play's COPY EVER CHANGES, THIS MUST CHANGE WITH IT. Two copies of a
%   speed law that disagree is worse than one copy in the wrong place.
%
%   Applied from a braking LEAD-IN ahead of the hazard, not at its edge, so the
%   car slows BEFORE the pothole and recovers after - which is what makes it read
%   as driving rather than as a number changing.
%
%   vRef IS THE ROUTE CRUISE SPEED, NOT THE CURRENT ONE, and that is not a detail.
%   Sized from v the term is self-referential: the cap slows the car, the slower
%   car needs a shorter lead-in, the lead-in releases the cap, the car speeds up,
%   the cap returns - a visible 20 Hz sawtooth that reads as a broken controller.
%   demo_play's header records that this was seen in a real exported frame.

aComfort = 1.6;
cap = Inf;  why = "";
if nargin < 4 || ~isfinite(vRef), vRef = v; end
for k = 1:numel(H)
    c = H(k).SpeedCap;
    if ~isfinite(c), continue; end
    [lo, hi] = iStretch(H(k));
    lead = 0;
    if vRef > c, lead = (vRef^2 - c^2) / (2*aComfort); end
    if s >= lo - lead && s <= hi
        if c < cap
            cap = c;
            if s < lo
                why = string(H(k).Label) + sprintf(" in %.0f m", lo - s);
            else
                why = string(H(k).Label) + " - in it now";
            end
        end
    end
end
if ~isfinite(cap), why = "clear"; end
end

function [lo, hi] = iStretch(h)
%ISTRETCH  Where a hazard actually applies. Zone runs FORWARD from Station - the
%   same convention sc.plannerView draws the band with, so the picture and the
%   behaviour can never disagree. A point hazard (Zone == 0) applies over its own
%   footprint with a 2 m floor, so a 0.4 m pothole is not skipped between two
%   20 Hz samples at 14 m/s.
r = 2.0;
if isfinite(h.Radius), r = max(2.0, h.Radius); end
if h.Zone > 0
    lo = h.Station;  hi = h.Station + h.Zone;
else
    lo = h.Station - r;  hi = h.Station + r;
end
end
