function s9 = drivableSpace(halfWidth_m, e, edgeSide, visibleRange_m, opts)
%DRIVABLESPACE  Assemble a real AGENTS.md section 3 S9 DrivableSpace struct
%   from already-known corridor geometry.
%
%   NOT A SENSED S9. Both S1 and S2 are fully authored worlds - the boundary
%   is known exactly, not perceived with any uncertainty. This is Phase 6's
%   "real S9" in the sense that AGENTS.md meant "stop faking it with a fixed
%   conservative corridor": EdgeDistance/EdgeSide are now derived from actual
%   per-station geometry instead of a constant, and VisibleRange is a real
%   sight-line result where one exists (S1) rather than a flat default
%   everywhere. It is still not lidar-segmented ground - that would need
%   +perception work this project has not scoped for S9.
%
%   Verified against the scenario specs (scenarios/S1-CATTLE-CROSSING.md,
%   S2-THE-CHOWK.md), not assumed: NEITHER scenario has a khai (drop-off).
%   S1's shoulder is earthen, crumbling into dirt but never falling away; S2
%   is kerbed everywhere (island kerb, splitter island kerbs). So EdgeSide is
%   correctly WALL (1) on both, never DROP (2) - the caller still passes it
%   explicitly rather than this function assuming it, in case a future
%   scenario needs otherwise.
%
%   INPUTS
%     halfWidth_m      the corridor's half-width AT THE CALLER'S CURRENT
%                      STATION, m. This is NOT constant on S2: the ring
%                      (IRC 65:2017, verified against the spec: inscribed
%                      circle 40 m -> island 24 m -> circulatory carriageway
%                      8 m) is 1 m wider than the 7 m arms. The caller (see
%                      +sc/s9Width.m) picks the right one per station - this
%                      function never guesses it.
%     e                ego's current lateral offset, m (+ left), Frenet frame
%     edgeSide         uint8, 0 unknown / 1 wall / 2 drop (AGENTS.md S9) -
%                      classified by the caller from the scenario spec
%     visibleRange_m   furthest confidently-observed ground ahead, m - the
%                      caller supplies this (a real ray-cast for S1 via
%                      sc.path.sightDistance against W.Occluders; a disclosed
%                      constant for S2, which has no occluder map yet - see
%                      +sc/s9VisibleRange.m for which and why)
%   opts (all optional - omit to get Costmap = [], same as the Phase 2 stand-in)
%     opts.Occupancy, opts.CellSize_m, opts.MapOrigin_m - if ALL THREE are
%       given, builds a real vehicleCostmap (sih.scenario.buildCostmap) over
%       that grid. See buildCostmap's own header for the InflationRadius trap
%       this avoids.
%
%   OUTPUT  s9  struct, AGENTS.md S9 shape:
%     .Costmap       vehicleCostmap or [] (opts not given)
%     .EdgeDistance  double, m, signed, + inside = halfWidth_m - abs(e)
%     .EdgeSide      uint8, passed through unchanged
%     .VisibleRange  double, m, passed through unchanged
%     .Valid         logical, always true - nothing here is uncertain, both
%                    worlds are fully authored, so there is no "S9 failed"
%                    case to report. A future genuinely-sensed S9 would be
%                    the one that can turn this false.

arguments
    halfWidth_m (1,1) double {mustBePositive}
    e (1,1) double {mustBeFinite}
    edgeSide (1,1) uint8 {mustBeMember(edgeSide, [0 1 2])}
    visibleRange_m (1,1) double {mustBeNonnegative}
    opts.Occupancy double = []
    opts.CellSize_m (1,1) double = 0.2
    opts.MapOrigin_m (1,2) double = [0 0]
end

cmap = [];
if ~isempty(opts.Occupancy)
    cmap = sih.scenario.buildCostmap(opts.Occupancy, opts.CellSize_m, opts.MapOrigin_m);
end

s9 = struct( ...
    'Costmap',      cmap, ...
    'EdgeDistance', halfWidth_m - abs(e), ...
    'EdgeSide',     edgeSide, ...
    'VisibleRange', visibleRange_m, ...
    'Valid',        true);
end
