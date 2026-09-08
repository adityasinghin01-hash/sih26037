function s9 = adapterS9Real(W, s, e, opts)
%ADAPTERS9REAL  The real, per-station AGENTS.md section 3 S9 DrivableSpace.
%   Phase 6 - replaces sc.adapterS9's fixed conservative corridor.
%
%   Three real fixes over the Phase 2 stand-in, each found by reading the
%   scenario specs or by testing, not assumed:
%     1. EdgeDistance now uses the CORRECT per-station half-width
%        (sc.s9Width) - the old code used W.ArmW/W.Width everywhere, which
%        was 1 m too narrow on S2's ring (8 m, not 7 m - IRC 65:2017,
%        verified against scenarios/S2-THE-CHOWK.md). Understating room was
%        the safe direction, but it was still wrong.
%     2. VisibleRange is now real and station-varying on S1 (sc.s9VisibleRange,
%        a genuine forward ray-cast against W.Occluders), not a flat 60 m
%        copied to every step. S2 still uses a disclosed constant (no
%        occluder map exists for it yet) - see s9VisibleRange's own header.
%     3. .Costmap is now a real vehicleCostmap (sih.scenario.buildCostmap)
%        over a local window, not [] - satisfying the AGENTS.md contract
%        literally, not just its two numeric fields.
%
%   EdgeSide stays 1 (wall/rising) on both scenarios - verified against both
%   scenario specs, NEITHER has a khai: S1's shoulder crumbles into dirt but
%   never falls away, S2 is kerbed everywhere (island kerb, splitter island
%   kerbs). Not assumed - checked.
%
%   sc.adapterS9 (the Phase 2 stand-in) is UNTOUCHED and still importable for
%   an A/B comparison if one is ever wanted - this is a new function, not an
%   edit to that one, so nothing that already called it changes behaviour
%   without a call-site change.
%
%   INPUTS
%     W  the world struct (sc.s1world / sc.s2world, or S2's Wp with .Width
%        added - s9Width/s9VisibleRange only read the fields they need)
%     s  current station, m (NEW - the Phase 2 stand-in never took this,
%        which is exactly why it could not know S1 vs S2, arm vs ring)
%     e  current lateral offset, m (+ left)
%   opts.BuildCostmap  logical, default true - set false to skip building the
%                      vehicleCostmap (cheaper; .Costmap comes back [])
%
%   OUTPUT  s9 struct, AGENTS.md S9 shape (via sih.scenario.drivableSpace)

arguments
    W struct
    s (1,1) double
    e (1,1) double
    opts.BuildCostmap (1,1) logical = true
end

addpath(fileparts(fileparts(mfilename('fullpath'))));  % matlab/, sibling of +sc

hw = sc.s9Width(W, s);
vr = sc.s9VisibleRange(W, s, e);

if opts.BuildCostmap
    [occ, cellSize, mapOrigin] = sc.s9Occupancy(W, s);
    s9 = sih.scenario.drivableSpace(hw, e, uint8(1), vr, ...
            'Occupancy', occ, 'CellSize_m', cellSize, 'MapOrigin_m', mapOrigin);
else
    s9 = sih.scenario.drivableSpace(hw, e, uint8(1), vr);
end
end
