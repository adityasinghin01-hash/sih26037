function tests = testRoadBarrier
%TESTROADBARRIER  Unit tests for D8's second barrier, the ground itself.
%
%   RUN IT:   results = runtests('matlab/tests/testRoadBarrier.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB and no Simulink. Every DrivableSpace
%   here is hand-built, so this tests the margin rule and nothing else.
%
%   Tested against hand-constructed S9; not yet validated against World data.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function s = iSpace(edge_m, side, valid)
s = struct('EdgeDistance', edge_m, 'EdgeSide', uint8(side), 'Valid', logical(valid));
end

% ---------------------------------------------------------------- consequence

function testADropDemandsMoreRoomThanAWall(tc)
% Weighted by consequence, not probability: a wall dents a panel, a drop is fatal.
wall = sih.planner.roadBarrier(iSpace(3, 1, true), 5);
drop = sih.planner.roadBarrier(iSpace(3, 2, true), 5);
verifyGreaterThan(tc, drop.dMin_m, wall.dMin_m);
verifyLessThan(tc, drop.h_road, wall.h_road);
end

function testUnknownSideIsTreatedAsADrop(tc)
% The cheap mistake is leaving too much room, so unknown takes the worse case.
unknown = sih.planner.roadBarrier(iSpace(3, 0, true), 5);
drop    = sih.planner.roadBarrier(iSpace(3, 2, true), 5);
verifyEqual(tc, unknown.Clearance_m, drop.Clearance_m, 'AbsTol', 1e-12);
end

function testTheDropFactorIsExactlyWhatWasAskedFor(tc)
wall = sih.planner.roadBarrier(iSpace(3, 1, true), 5, dropFactor = 3);
drop = sih.planner.roadBarrier(iSpace(3, 2, true), 5, dropFactor = 3);
verifyEqual(tc, drop.Clearance_m, 3 * wall.Clearance_m, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- speed

function testMoreSpeedDemandsMoreRoom(tc)
slow = sih.planner.roadBarrier(iSpace(3, 1, true), 1);
fast = sih.planner.roadBarrier(iSpace(3, 1, true), 10);
verifyGreaterThan(tc, fast.Clearance_m, slow.Clearance_m);
end

function testTheClearanceLinePassesThroughBothStatedAnchors(tc)
% The documents state centimetres at 2 km/h and about 1.5 m at 40 km/h. Those
% two figures ARE the line, rather than a slope invented to fit them.
low  = sih.planner.roadBarrier(iSpace(3, 1, true), 2/3.6);
high = sih.planner.roadBarrier(iSpace(3, 1, true), 40/3.6);
verifyEqual(tc, low.Clearance_m,  0.10, 'AbsTol', 1e-12);
verifyEqual(tc, high.Clearance_m, 1.50, 'AbsTol', 1e-12);
end

function testClearanceNeverGoesNegative(tc)
% Standing still sits below the low anchor, and the line must not run under zero.
r = sih.planner.roadBarrier(iSpace(3, 1, true), 0, ...
        anchorLowClear_m = 0, anchorLowSpeed_mps = 5, anchorHighClear_m = 1, ...
        anchorHighSpeed_mps = 10);
verifyGreaterThanOrEqual(tc, r.Clearance_m, 0);
end

% ---------------------------------------------------------------- the body

function testFoldingTheMirrorsBuysExactlyTheMirrorWidth(tc)
% Folding narrows the real footprint - D-planner.md calls it a real action.
out = sih.planner.roadBarrier(iSpace(3, 1, true), 5, mirrorsFolded = false);
in  = sih.planner.roadBarrier(iSpace(3, 1, true), 5, mirrorsFolded = true);
verifyEqual(tc, in.h_road - out.h_road, 0.20, 'AbsTol', 1e-12);
end

function testAStraightRoadSweepsNothingExtra(tc)
r = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm = 0);
verifyEqual(tc, r.SweepExtra_m, 0);
end

function testTurningSweepsWiderThanTheCarIsWide(tc)
% Corners sweep wider than the middle. Check the swept path, not the centreline.
straight = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm = 0);
turning  = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm = 1/10);
verifyGreaterThan(tc, turning.SweepExtra_m, 0);
verifyLessThan(tc, turning.h_road, straight.h_road);
end

function testATighterTurnSweepsWider(tc)
wide  = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm = 1/20);
tight = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm = 1/5);
verifyGreaterThan(tc, tight.SweepExtra_m, wide.SweepExtra_m);
end

function testLeftAndRightTurnsSweepTheSame(tc)
% A turn either way puts a corner out. The sign carries no information here.
l = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm =  1/10);
r = sih.planner.roadBarrier(iSpace(3, 1, true), 5, curvature_1pm = -1/10);
verifyEqual(tc, l.SweepExtra_m, r.SweepExtra_m, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- the formula

function testTheFrozenFormulaHoldsExactly(tc)
% AGENTS.md S9: h_road = EdgeDistance - dMin. Nothing else may creep in.
r = sih.planner.roadBarrier(iSpace(2.5, 2, true), 7, curvature_1pm = 1/12);
verifyEqual(tc, r.h_road, r.EdgeDistance_m - r.dMin_m, 'AbsTol', 1e-12);
verifyEqual(tc, r.dMin_m, r.HalfFootprint_m + r.Clearance_m, 'AbsTol', 1e-12);
end

function testTooCloseIsReportedAsAViolation(tc)
r = sih.planner.roadBarrier(iSpace(0.2, 2, true), 10);
verifyLessThan(tc, r.h_road, 0);
verifyTrue(tc, r.Violated);
end

function testPlentyOfRoomIsNotAViolation(tc)
r = sih.planner.roadBarrier(iSpace(20, 1, true), 5);
verifyGreaterThan(tc, r.h_road, 0);
verifyFalse(tc, r.Violated);
end

% ---------------------------------------------------------------- invalid S9

function testInvalidSpaceDiscardsTheMeasuredEdgeEntirely(tc)
% S9: Valid false means fall back to a fixed conservative corridor. A measured
% number that is not trusted must not be half-trusted either.
r = sih.planner.roadBarrier(iSpace(999, 1, false), 5, fallbackCorridor_m = 1.5);
verifyTrue(tc, r.UsedFallback);
verifyEqual(tc, r.EdgeDistance_m, 1.5);
verifyEqual(tc, r.EdgeSide, uint8(0));
end

function testInvalidSpaceIsTreatedAsADrop(tc)
inval = sih.planner.roadBarrier(iSpace(999, 1, false), 5, fallbackCorridor_m = 3);
drop  = sih.planner.roadBarrier(iSpace(3,   2, true),  5);
verifyEqual(tc, inval.Clearance_m, drop.Clearance_m, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- bad input

function testUnknownEdgeSideCodeErrors(tc)
verifyError(tc, @() sih.planner.roadBarrier(iSpace(3, 7, true), 5), ...
            'sih:planner:roadBarrier:unknownEdgeSide');
end

function testMissingFieldErrors(tc)
s = rmfield(iSpace(3, 1, true), 'EdgeSide');
verifyError(tc, @() sih.planner.roadBarrier(s, 5), ...
            'sih:planner:roadBarrier:missingField');
end

function testAnchorsInTheWrongOrderError(tc)
verifyError(tc, @() sih.planner.roadBarrier(iSpace(3,1,true), 5, ...
                    anchorLowSpeed_mps = 10, anchorHighSpeed_mps = 2), ...
            'sih:planner:roadBarrier:badAnchors');
end

function testNegativeSpeedIsRefused(tc)
verifyError(tc, @() sih.planner.roadBarrier(iSpace(3,1,true), -1), ...
            'MATLAB:validators:mustBeNonnegative');
end

% ---------------------------------------------------------------- housekeeping

function testReasonIsAString(tc)
r = sih.planner.roadBarrier(iSpace(3, 1, true), 5);
verifyClass(tc, r.Reason, 'string');
end

function testSameInputGivesSameAnswer(tc)
a = sih.planner.roadBarrier(iSpace(2.2, 2, true), 6, curvature_1pm = 1/15);
b = sih.planner.roadBarrier(iSpace(2.2, 2, true), 6, curvature_1pm = 1/15);
verifyEqual(tc, a, b);
end
