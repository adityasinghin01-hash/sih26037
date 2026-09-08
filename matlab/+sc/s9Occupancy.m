function [occ, cellSize_m, mapOrigin_m] = s9Occupancy(W, s0, opts)
%S9OCCUPANCY  A local occupancy grid for sih.scenario.buildCostmap, Phase 6.
%
%   BUILT IN THE FRENET (s,e) FRAME, NOT WORLD xy. The costmap's own
%   coordinates only have to be consistent between construction and query -
%   nothing requires world xy. Working in (s,e) sidesteps rasterizing a
%   curved corridor (S2's ring) in true world coordinates, while still using
%   the REAL per-station width (sc.s9Width - so S2's 8 m ring vs 7 m arms are
%   both represented correctly, not one constant standing in for both).
%   Column = station (s), row = lateral offset (e). Free where
%   abs(e) <= sc.s9Width(W,s), occupied beyond it.
%
%   THIS IS NOT CONSUMED BY THE PLANNER. sih.planner.roadBarrier and
%   speedLimit read .EdgeDistance/.EdgeSide/.VisibleRange directly (exact
%   Frenet arithmetic, no discretization error) - never .Costmap. This grid
%   exists to satisfy AGENTS.md's ".Costmap wraps MathWorks' own object" and
%   to let a test cross-validate the exact arithmetic against an independent
%   representation (matlab/tests/testDrivableSpace.m in the TEAM repo does
%   this pattern already for a plain corridor; this is the +sc-specific,
%   per-station-width version of the same idea).
%
%   INPUTS
%     W    the world struct (sc.s1world / sc.s2world)
%     s0   the window's centre station, m
%   opts.WindowLen_m   how far the grid extends each way along s, default 20
%   opts.CellSize_m    m per cell,                              default 0.2
%   opts.MaxHalfWidth_m  grid half-extent in e, must exceed every
%                        sc.s9Width in the window,               default 6
%
%   OUTPUTS
%     occ          double matrix, 0 free / 1 occupied, ready for
%                  sih.scenario.buildCostmap
%     cellSize_m   passed straight through, for the same call
%     mapOrigin_m  [s0-WindowLen_m, -MaxHalfWidth_m] - the grid's local (0,0)
%                  corner, IN THE SAME (s,e) FRAME - query points must be
%                  given as (s,e), not world (x,y)

arguments
    W struct
    s0 (1,1) double
    opts.WindowLen_m (1,1) double = 20
    opts.CellSize_m (1,1) double = 0.2
    opts.MaxHalfWidth_m (1,1) double = 6
end

cellSize_m = opts.CellSize_m;
sLo = s0 - opts.WindowLen_m;
sHi = s0 + opts.WindowLen_m;
nCols = round((sHi - sLo) / cellSize_m);
nRows = round((2*opts.MaxHalfWidth_m) / cellSize_m);

sv = linspace(sLo, sHi, nCols);
ev = linspace(-opts.MaxHalfWidth_m, opts.MaxHalfWidth_m, nRows);

occ = zeros(nRows, nCols);
for c = 1:nCols
    hw = sc.s9Width(W, max(0, sv(c)));
    occ(abs(ev) > hw, c) = 1;
end

mapOrigin_m = [sLo, -opts.MaxHalfWidth_m];
end
