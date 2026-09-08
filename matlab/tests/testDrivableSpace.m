function tests = testDrivableSpace
%TESTDRIVABLESPACE  Phase 6 - sih.scenario.drivableSpace + buildCostmap.
%
%   RUN IT:  results = runtests('matlab/tests/testDrivableSpace.m'); disp(results)
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));
tc.TestData = struct();
end

% ---------------------------------------------------------------- drivableSpace shape

function testEdgeDistanceSignAndMagnitude(tc)
s9 = sih.scenario.drivableSpace(3.5, 0.0, uint8(1), 60);
tc.verifyEqual(s9.EdgeDistance, 3.5, 'AbsTol', 1e-12);   % centred: full half-width free
s9r = sih.scenario.drivableSpace(3.5, 2.0, uint8(1), 60);
tc.verifyEqual(s9r.EdgeDistance, 1.5, 'AbsTol', 1e-12);  % 2 m off-centre, 1.5 m left to the edge
s9l = sih.scenario.drivableSpace(3.5, -2.0, uint8(1), 60);
tc.verifyEqual(s9l.EdgeDistance, 1.5, 'AbsTol', 1e-12);  % symmetric either side
end

function testEdgeDistanceGoesNegativeOffCorridor(tc)
s9 = sih.scenario.drivableSpace(3.5, 4.5, uint8(1), 60);   % 1 m past the edge
tc.verifyEqual(s9.EdgeDistance, -1.0, 'AbsTol', 1e-12);
end

function testValidIsAlwaysTrue(tc)
s9 = sih.scenario.drivableSpace(3.5, 0, uint8(1), 60);
tc.verifyTrue(s9.Valid);
end

function testEdgeSidePassesThroughUnchanged(tc)
s9 = sih.scenario.drivableSpace(4.0, 0, uint8(2), 60);   % pretend a drop, for the plumbing test
tc.verifyEqual(s9.EdgeSide, uint8(2));
end

function testNoCostmapWhenOccupancyOmitted(tc)
s9 = sih.scenario.drivableSpace(3.5, 0, uint8(1), 60);
tc.verifyTrue(isempty(s9.Costmap));
end

function testRoadBarrierAndSpeedLimitAcceptItDirectly(tc)
% The whole point: drivableSpace's output must satisfy the FROZEN consumers
% unchanged. If this fails, the S9 shape drifted from what AGENTS.md section 3
% actually promises.
s9 = sih.scenario.drivableSpace(3.5, 0.5, uint8(1), 60);
rb = sih.planner.roadBarrier(s9, 10);
tc.verifyFalse(rb.UsedFallback);
sl = sih.planner.speedLimit(s9, 10);
tc.verifyFalse(sl.UsedFallback);
end

% ---------------------------------------------------------------- buildCostmap

function testCostmapMatchesKnownOccupancyAtCellResolution(tc)
cellSize = 0.1; roadHalf = 3.5;
yExtent = 12; xExtent = 6;
ny = round(yExtent/cellSize); nx = round(xExtent/cellSize);
yv = linspace(-yExtent/2, yExtent/2, ny);
occ = zeros(ny, nx);
occ(abs(yv) > roadHalf, :) = 1;

cmap = sih.scenario.buildCostmap(occ, cellSize, [-xExtent/2 -yExtent/2]);
tc.verifyClass(cmap, 'vehicleCostmap');
tc.verifyEqual(cmap.CollisionChecker.InflationRadius, 0);

tc.verifyTrue(checkFree(cmap, [0 3.3]));    % inside the true boundary
tc.verifyFalse(checkFree(cmap, [0 3.7]));   % outside it
end

function testDrivableSpaceBuildsRealCostmapWhenOccupancyGiven(tc)
cellSize = 0.2; roadHalf = 3.5;
yExtent = 10; xExtent = 4;
ny = round(yExtent/cellSize); nx = round(xExtent/cellSize);
yv = linspace(-yExtent/2, yExtent/2, ny);
occ = zeros(ny, nx);
occ(abs(yv) > roadHalf, :) = 1;

s9 = sih.scenario.drivableSpace(roadHalf, 0, uint8(1), 60, ...
        'Occupancy', occ, 'CellSize_m', cellSize, 'MapOrigin_m', [-xExtent/2 -yExtent/2]);
tc.verifyClass(s9.Costmap, 'vehicleCostmap');
% cross-check: the EXACT EdgeDistance and the INDEPENDENT costmap must agree
% on where the boundary is, to within one cell.
edgeY = roadHalf - abs(0);   % = 3.5, at e=0
tc.verifyTrue(checkFree(s9.Costmap, [0 edgeY - cellSize]));
tc.verifyFalse(checkFree(s9.Costmap, [0 edgeY + 2*cellSize]));
end
