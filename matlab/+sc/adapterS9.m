function s9 = adapterS9(W, e, opts)
%ADAPTERS9  A fixed, conservative DrivableSpace (AGENTS.md s3, S9) for the +sc
%   world.
%
%   PHASE 2 STAND-IN. There is no khai in S1 or S2, so EdgeSide is always 1
%   (wall/rising) and the corridor is just the carriageway. The real
%   costmap-derived S9 (vehicleCostmap + drop-off detection) is Phase 6.
%
%   Consumed only by sih.planner.speedLimit and sih.planner.roadBarrier for the
%   speed cap and the h_road readout. planContingency does not take S9.
%
%   INPUTS
%     W    the world struct from sc.s1world / sc.s2world (reads .Width)
%     e    current lateral offset of the ego, m (+ is LEFT)
%     opts.VisibleRange   furthest confidently-observed ground, m, default 60
%
%   OUTPUT  s9 struct with the S9 fields.

arguments
    W struct
    e (1,1) double
    opts.VisibleRange (1,1) double = 60
end

hw = W.Width/2;
s9 = struct( ...
    'Costmap',      [], ...
    'EdgeDistance', hw - abs(e), ...     % + inside; distance to the nearer edge
    'EdgeSide',     uint8(1), ...        % wall/rising - never a drop in S1/S2
    'VisibleRange', opts.VisibleRange, ...
    'Valid',        true);
end
