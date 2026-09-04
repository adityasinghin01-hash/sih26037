function tests = testSpeedLimit
%TESTSPEEDLIMIT  Unit tests for the three-term speed cap.
%
%   RUN IT:   results = runtests('matlab/tests/testSpeedLimit.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB and no Simulink.
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function s = iSpace(visible_m, valid)
s = struct('VisibleRange', visible_m, 'Valid', logical(valid));
end

% ---------------------------------------------------------------- the curve term

function testAStraightRoadPutsNoLateralDemandOnTheTyres(tc)
% Inf, not a large finite number nothing produced.
r = sih.planner.speedLimit(iSpace(100, true), 5, curvature_1pm = 0);
verifyEqual(tc, r.CurveTerm_mps, Inf);
verifyEqual(tc, r.Radius_m, Inf);
end

function testTheCurveTermIsExactlySqrtALatR(tc)
R = 20;
r = sih.planner.speedLimit(iSpace(500, true), 1, curvature_1pm = 1/R, aLat_mps2 = 3);
verifyEqual(tc, r.CurveTerm_mps, sqrt(3*R), 'AbsTol', 1e-12);
verifyEqual(tc, r.Radius_m, R, 'AbsTol', 1e-12);
end

function testATighterCurveCapsHarder(tc)
wide  = sih.planner.speedLimit(iSpace(500, true), 1, curvature_1pm = 1/50);
tight = sih.planner.speedLimit(iSpace(500, true), 1, curvature_1pm = 1/5);
verifyLessThan(tc, tight.CurveTerm_mps, wide.CurveTerm_mps);
end

function testLeftAndRightCurvesCapTheSame(tc)
l = sih.planner.speedLimit(iSpace(500, true), 1, curvature_1pm =  1/10);
r = sih.planner.speedLimit(iSpace(500, true), 1, curvature_1pm = -1/10);
verifyEqual(tc, l.v_max_mps, r.v_max_mps, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- the sight term

function testTheSightTermIsExactlyTheStoppingDistanceLaw(tc)
vis = 40; v = 6; tReact = 0.5; aBrake = 4;
r = sih.planner.speedLimit(iSpace(vis, true), v, ...
        tReact_s = tReact, aBrake_mps2 = aBrake, vRoute_mps = 100);
room = vis - v*tReact;
verifyEqual(tc, r.BrakingRoom_m, room, 'AbsTol', 1e-12);
verifyEqual(tc, r.SightTerm_mps, sqrt(2*aBrake*room), 'AbsTol', 1e-12);
end

function testFogSlowsTheCarWithNoWeatherMode(tc)
% Fog shrinks VisibleRange, the sight term shrinks, the car slows. That is the
% whole mechanism, and a rain branch would be a second one for the same effect.
clear_  = sih.planner.speedLimit(iSpace(120, true), 10, vRoute_mps = 100);
foggy   = sih.planner.speedLimit(iSpace(12,  true), 10, vRoute_mps = 100);
verifyLessThan(tc, foggy.v_max_mps, clear_.v_max_mps);
verifyEqual(tc, foggy.Binding, "SIGHT");
end

function testNoBrakingRoomMeansStop(tc)
% Sight shorter than the distance covered while reacting: the honest cap is 0.
r = sih.planner.speedLimit(iSpace(2, true), 20, tReact_s = 0.5, vRoute_mps = 100);
verifyEqual(tc, r.v_max_mps, 0);
verifyEqual(tc, r.Binding, "SIGHT");
verifyGreaterThan(tc, r.SightShortfall_m, 0);
end

function testTheAnswerIsNeverComplex(tc)
% sqrt of a negative would return a complex number and poison everything
% downstream silently. This project's failure mode is a wrong number, not a crash.
r = sih.planner.speedLimit(iSpace(1, true), 30, vRoute_mps = 100);
verifyTrue(tc, isreal(r.v_max_mps));
verifyTrue(tc, isreal(r.SightTerm_mps));
end

function testShortfallIsZeroWhenThereIsRoom(tc)
r = sih.planner.speedLimit(iSpace(100, true), 5);
verifyEqual(tc, r.SightShortfall_m, 0);
end

% ---------------------------------------------------------------- the route term

function testTheRouteCanBeTheTightestOfTheThree(tc)
r = sih.planner.speedLimit(iSpace(500, true), 2, curvature_1pm = 0, vRoute_mps = 8);
verifyEqual(tc, r.v_max_mps, 8);
verifyEqual(tc, r.Binding, "ROUTE");
end

% ---------------------------------------------------------------- the minimum

function testTheCapIsExactlyTheSmallestOfTheThreeTerms(tc)
r = sih.planner.speedLimit(iSpace(30, true), 8, curvature_1pm = 1/15, vRoute_mps = 11);
verifyEqual(tc, r.v_max_mps, ...
            min([r.CurveTerm_mps, r.SightTerm_mps, r.RouteTerm_mps]), 'AbsTol', 1e-12);
end

function testBindingNamesTheTermThatActuallyWon(tc)
r = sih.planner.speedLimit(iSpace(30, true), 8, curvature_1pm = 1/15, vRoute_mps = 11);
byName = struct('CURVE', r.CurveTerm_mps, 'SIGHT', r.SightTerm_mps, 'ROUTE', r.RouteTerm_mps);
verifyEqual(tc, byName.(r.Binding), r.v_max_mps, 'AbsTol', 1e-12);
end

function testOnAHairpinTheCurveAndSightTermsCanBindTogether(tc)
% D-planner.md says both bind at once on a hairpin. Taking a minimum IS the
% arbitration, so there is nothing to switch between.
r = sih.planner.speedLimit(iSpace(15, true), 5, curvature_1pm = 1/6, vRoute_mps = 100);
verifyLessThan(tc, r.CurveTerm_mps, 100);
verifyLessThan(tc, r.SightTerm_mps, 100);
verifyTrue(tc, ismember(r.Binding, ["CURVE" "SIGHT"]));
end

function testTheCapIsNeverNegative(tc)
r = sih.planner.speedLimit(iSpace(0, true), 25);
verifyGreaterThanOrEqual(tc, r.v_max_mps, 0);
end

% ---------------------------------------------------------------- invalid S9

function testInvalidSpaceUsesTheFallbackSight(tc)
r = sih.planner.speedLimit(iSpace(999, false), 5, fallbackVisible_m = 10, vRoute_mps = 100);
verifyTrue(tc, r.UsedFallback);
verifyEqual(tc, r.BrakingRoom_m, 10 - 5*0.5, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- bad input

function testMissingFieldErrors(tc)
s = rmfield(iSpace(50, true), 'VisibleRange');
verifyError(tc, @() sih.planner.speedLimit(s, 5), ...
            'sih:planner:speedLimit:missingField');
end

function testNegativeSpeedIsRefused(tc)
verifyError(tc, @() sih.planner.speedLimit(iSpace(50, true), -1), ...
            'MATLAB:validators:mustBeNonnegative');
end

% ---------------------------------------------------------------- housekeeping

function testReasonIsAString(tc)
r = sih.planner.speedLimit(iSpace(50, true), 5);
verifyClass(tc, r.Reason, 'string');
end

function testSameInputGivesSameAnswer(tc)
a = sih.planner.speedLimit(iSpace(33, true), 7, curvature_1pm = 1/9);
b = sih.planner.speedLimit(iSpace(33, true), 7, curvature_1pm = 1/9);
verifyEqual(tc, a, b);
end
