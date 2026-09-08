function cmap = buildCostmap(occupancy, cellSize_m, mapOrigin_m)
%BUILDCOSTMAP  Wrap a known 0/1 occupancy grid in a real vehicleCostmap
%   (AGENTS.md section 3, S9: ".Costmap wraps MathWorks' shipped object - do
%   NOT invent a new one").
%
%   THE PITFALL THIS EXISTS TO AVOID, FOUND BY TESTING NOT BY READING DOCS:
%   `checkFree` does NOT report raw occupancy by default. `vehicleCostmap`'s
%   default `CollisionChecker.InflationRadius` is derived from a default
%   `VehicleDimensions` object (measured here: 2.5164 m) - so a point 3.0 m
%   from a road edge at |y|=3.5 m reads "occupied" under DEFAULT settings, a
%   full 2 m before the real boundary. Zeroing `InflationRadius` makes
%   `checkFree` match the input grid to within one cell (verified: free up to
%   the true boundary, occupied one cell beyond, at 0.1 m resolution). This
%   function does that zeroing so no caller has to rediscover it.
%
%   `EdgeDistance`/`EdgeSide` in sih.scenario.drivableSpace do NOT read this
%   costmap - they come from exact path geometry, which is precise for a known
%   corridor where a discretized grid could only ever approximate it. This
%   costmap exists to (a) satisfy the AGENTS.md contract field for real, and
%   (b) let a test cross-validate the exact geometry against an independent
%   representation (matlab/tests/testDrivableSpace.m does this).
%
%   INPUTS
%     occupancy    double/logical matrix, 0 = free, nonzero = occupied. Row 1
%                  is the Y closest to mapOrigin_m(2) (vehicleCostmap's own
%                  convention - not transposed or flipped here)
%     cellSize_m   (1,1) double, metres per cell
%     mapOrigin_m  1x2 double, the (x,y) of the grid's own local (0,0) corner
%
%   OUTPUT
%     cmap  vehicleCostmap, InflationRadius forced to 0

arguments
    occupancy double
    cellSize_m (1,1) double {mustBePositive}
    mapOrigin_m (1,2) double
end

cmap = vehicleCostmap(double(occupancy > 0), 'CellSize', cellSize_m, ...
                      'MapLocation', mapOrigin_m);
cmap.CollisionChecker.InflationRadius = 0;
end
