function tests = testPlanTurn
%TESTPLANTURN  Unit tests for D10: one turn planner, four rows, only the binding changes.
%
%   RUN IT:   results = runtests('matlab/tests/testPlanTurn.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink. Routes here are
%   hand-built S10 structs, which is what plan/D6-TRUNK-RULING.md rules is the way
%   to build D8-D10 while the World does not exist.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function r = iRoute(goalHeading)
r = struct('GoalHeading', goalHeading, 'GoalPoint', [10 0 0], ...
           'BlockedEdges', [], 'EscapePoints', [], 'Valid', true);
end

function e = iEgo(yaw)
e = struct('Position', [0 0 0], 'Velocity', [5 0 0], 'Yaw', yaw);
end

% ---------------------------------------------------------------- the type is derived

function testStraightAheadIsNotATurn(tc)
out = sih.planner.planTurn(iRoute(0), iEgo(0));
verifyEqual(tc, out.Type, "NORMAL");
verifyEqual(tc, out.Binds, "nothing");
verifyEqual(tc, out.Curvature_1pm, 0);
verifyFalse(tc, out.NeedsReverse);
end

function testATinyHeadingChangeIsStillNotATurn(tc)
% Lane keeping wobble must not be promoted into a manoeuvre.
out = sih.planner.planTurn(iRoute(0.1), iEgo(0));
verifyEqual(tc, out.Type, "NORMAL");
verifyEqual(tc, out.Curvature_1pm, 0);
end

function testARightTurnIsACutBecauseItCrossesTheOncomingStream(tc)
% RRR 1989 reg. 2 keeps traffic left, so the RIGHT turn is the exposed one.
% x forward, y left, so a right turn is a NEGATIVE heading change.
out = sih.planner.planTurn(iRoute(-pi/2), iEgo(0));
verifyEqual(tc, out.Type, "CUT");
verifyEqual(tc, out.Binds, "refuge");
end

function testALeftTurnOfTheSameSizeIsNotACut(tc)
% The whole point of the reg. 2 reasoning. Same magnitude, opposite sign, and the
% left turn crosses nobody. If this ever matches the test above, a keep-right
% convention has been imported and the car will be turning across traffic.
out = sih.planner.planTurn(iRoute(+pi/2), iEgo(0));
verifyEqual(tc, out.Type, "NORMAL");
verifyEqual(tc, out.Binds, "nothing");
verifyNotEqual(tc, out.Type, "CUT");
end

function testAboutFaceIsAUTurn(tc)
out = sih.planner.planTurn(iRoute(pi), iEgo(0));
verifyEqual(tc, out.Type, "UTURN");
verifyEqual(tc, out.Binds, "radius");
end

function testTheTypeComesFromTHEDIFFERENCENotTheGoalAlone(tc)
% Derived from GoalHeading minus yaw. A car already pointing at the goal is not
% turning, however large the goal heading is.
out = sih.planner.planTurn(iRoute(pi), iEgo(pi));
verifyEqual(tc, out.Type, "NORMAL");
verifyEqual(tc, out.HeadingChange_rad, 0, 'AbsTol', 1e-12);
end

function testTheAngleWrapsTheShortWayRound(tc)
% Goal 179 deg, car at -179 deg. The difference is 2 deg, not 358.
out = sih.planner.planTurn(iRoute(deg2rad(179)), iEgo(deg2rad(-179)));
verifyEqual(tc, abs(out.HeadingChange_rad), deg2rad(2), 'AbsTol', 1e-9);
verifyEqual(tc, out.Type, "NORMAL");
end

% ---------------------------------------------------------------- the multi-point sum

function testAWideRoadTurnsInOneSweepAndNeedsNoReverse(tc)
% Required width is 2*Rmin + body. Rmin = 2.8/tan(0.6) = 4.09 m, so about 10 m.
out = sih.planner.planTurn(iRoute(pi), iEgo(0), roadWidth_m = 14);
verifyEqual(tc, out.NumSegments, 1);
verifyFalse(tc, out.NeedsReverse);
end

function testANarrowGalliForcesAMultiPointTurnAndSaysSo(tc)
% The row plan/D-planner.md marks "needs Gear = -1". This is where Person B is told.
out = sih.planner.planTurn(iRoute(pi), iEgo(0), roadWidth_m = 5);
verifyGreaterThan(tc, out.NumSegments, 1);
verifyTrue(tc, out.NeedsReverse);
verifySubstring(tc, char(out.Reason), 'REVERSE REQUIRED');
end

function testNarrowerRoadsNeverNeedFewerSweeps(tc)
% Monotonic, because a sum that is not would be plainly wrong and easy to miss.
prev = 0;
for w = [14 10 8 6 5 4.5]
    n = sih.planner.planTurn(iRoute(pi), iEgo(0), roadWidth_m = w).NumSegments;
    verifyGreaterThanOrEqual(tc, n, prev);
    prev = n;
end
end

function testTheOneSweepBoundaryIsExactlyTheRequiredWidth(tc)
% acos(1 - 2R/R) = acos(-1) = pi, so the textbook "wide enough" case falls out of
% the sum instead of being tested for separately. Pin the boundary.
out = sih.planner.planTurn(iRoute(pi), iEgo(0));
w   = out.RequiredWidth_m;
verifyEqual(tc, sih.planner.planTurn(iRoute(pi), iEgo(0), roadWidth_m = w).NumSegments, 1);
verifyGreaterThan(tc, ...
    sih.planner.planTurn(iRoute(pi), iEgo(0), roadWidth_m = w - 0.5).NumSegments, 1);
end

function testARoadNarrowerThanTheCarIsImpossibleNotOptimistic(tc)
% Inf, not a large finite number. A finite answer here would read as "hard but
% doable" and the car would try it.
out = sih.planner.planTurn(iRoute(pi), iEgo(0), roadWidth_m = 1.5);
verifyEqual(tc, out.NumSegments, Inf);
verifyTrue(tc, out.NeedsReverse);
verifySubstring(tc, char(out.Reason), 'impossible');
end

% ---------------------------------------------------------------- the refuge point

function testACutGetsARefugePointAndAStraightRunDoesNot(tc)
cut = sih.planner.planTurn(iRoute(-pi/2), iEgo(0));
str = sih.planner.planTurn(iRoute(0),     iEgo(0));
verifyTrue(tc, all(isfinite(cut.RefugePoint)));
verifyTrue(tc, all(isnan(str.RefugePoint)));
end

function testTheRefugeIsPastTheStreamJustCrossed(tc)
% Far enough that the tail is clear: stream width + half the body + margin.
opts = struct('streamWidth_m', 3.5, 'refugeMargin_m', 1.0, 'egoLength_m', 4.7);
want = opts.streamWidth_m + opts.egoLength_m/2 + opts.refugeMargin_m;
out  = sih.planner.planTurn(iRoute(-pi/2), iEgo(0));
verifyEqual(tc, norm(out.RefugePoint - [0 0]), want, 'AbsTol', 1e-9);
end

function testTheRefugeLiesInTheDirECTIONTheCarIsGoingTo(tc)
% Along the GOAL heading, not the current one. A refuge behind the car is useless.
out = sih.planner.planTurn(iRoute(-pi/2), iEgo(0));
verifyLessThan(tc, out.RefugePoint(2), 0);            % goal is -90 deg: to the right
verifyEqual(tc, out.RefugePoint(1), 0, 'AbsTol', 1e-9);
end

% -------------------------------------------------- the roundabout row, dropped by ruling

function testThereIsNoRoundaboutTypeAtAll(tc)
% Aditya, 5 Sep 2026: drop the row, S10 gains no field. A "roundabout" field would
% BE the classification D10 forbids. Nothing behavioural is lost - give way to the
% right already falls out of assignRoles. No angle may ever produce this type.
for a = [-pi -pi/2 -0.4 0 0.4 pi/2 pi]
    verifyNotEqual(tc, sih.planner.planTurn(iRoute(a), iEgo(0)).Type, "ROUNDABOUT");
end
end

function testThereIsNoWayToAskForARoundaboutEither(tc)
% The option is gone, not defaulted to false. If it comes back, so does the
% classification, so the door is pinned shut rather than left ajar.
verifyError(tc, @() sih.planner.planTurn(iRoute(0.2), iEgo(0), isRoundabout = true), ...
            'MATLAB:TooManyInputs');   % MATLAB's own name for an unknown option
end

function testEveryTypeThisCanReturnIsOneOfThree(tc)
% The whole reachable set, so a fourth type cannot appear unnoticed.
seen = strings(0);
for a = [-pi -2 -pi/2 -0.4 -0.1 0 0.1 0.4 pi/2 2 pi]
    seen(end+1) = sih.planner.planTurn(iRoute(a), iEgo(0)).Type; %#ok<AGROW>
end
verifyEmpty(tc, setdiff(unique(seen), ["NORMAL" "CUT" "UTURN"]));
end

% ---------------------------------------------------- the sharp-at-speed row

function testWithoutS9TheGripRowIsNotEvaluatedAtAll(tc)
% NaN means "not evaluated", never "grip does not bind". A false here would be a
% claim nobody computed - exactly the plausible-wrong-number this project fears.
out = sih.planner.planTurn(iRoute(pi/2 - 0.1), iEgo(0));
verifyTrue(tc, isnan(out.GripLimit_mps));
verifyFalse(tc, out.GripBinds);
verifyNotEqual(tc, out.Binds, "grip");
end

function testAFastCarThroughATightBendIsHeldByGrip(tc)
% The fourth row of plan/D-planner.md D10. 20 m/s round the car's own tightest
% circle is far past sqrt(3*4.09) = 3.50 m/s, so grip is what binds.
space = struct('VisibleRange', 100, 'Valid', true);
ego   = struct('Position',[0 0 0], 'Velocity',[20 0 0], 'Yaw',0);
out   = sih.planner.planTurn(iRoute(-pi/2), ego, space = space);
verifyTrue(tc, out.GripBinds);
verifyEqual(tc, out.Binds, "grip");
verifySubstring(tc, char(out.Reason), 'grip');
end

function testACrawlingCarThroughTheSameBendIsNot(tc)
% Same geometry, slower car. If this also said grip, the row would be reporting the
% corner rather than the speed, and "sharp AT SPEED" is the whole name of it.
space = struct('VisibleRange', 100, 'Valid', true);
ego   = struct('Position',[0 0 0], 'Velocity',[1 0 0], 'Yaw',0);
out   = sih.planner.planTurn(iRoute(-pi/2), ego, space = space);
verifyFalse(tc, out.GripBinds);
verifyEqual(tc, out.Binds, "refuge");
end

function testTheGripNumberIsSpeedLimitsOwnAndNotASecondCopy(tc)
% The reuse rule: one law, one place. If this ever drifts, sqrt(aLat*R) has been
% written out twice and the two will disagree under some option nobody tried.
space = struct('VisibleRange', 100, 'Valid', true);
ego   = struct('Position',[0 0 0], 'Velocity',[20 0 0], 'Yaw',0);
out   = sih.planner.planTurn(iRoute(pi), ego, space = space);
cap   = sih.planner.speedLimit(space, 20, curvature_1pm = out.Curvature_1pm);
verifyEqual(tc, out.GripLimit_mps, cap.CurveTerm_mps, 'AbsTol', 1e-12);
end

function testGripDoesNotThrowAwayTheGeometryItOverrode(tc)
% .Binds says grip, but the U-turn still needs the same sweeps and the same gear.
% Person B reads NeedsReverse, and it must not vanish because the car was fast.
space = struct('VisibleRange', 100, 'Valid', true);
ego   = struct('Position',[0 0 0], 'Velocity',[20 0 0], 'Yaw',0);
out   = sih.planner.planTurn(iRoute(pi), ego, roadWidth_m = 5, space = space);
verifyEqual(tc, out.Binds, "grip");
verifyEqual(tc, out.Type,  "UTURN");
verifyTrue(tc, out.NeedsReverse);
verifyGreaterThan(tc, out.NumSegments, 1);
end

function testAStraightRoadAtSpeedIsNotHeldByGrip(tc)
% Curvature 0 gives an infinite grip term, so the sight or route term must win.
space = struct('VisibleRange', 100, 'Valid', true);
ego   = struct('Position',[0 0 0], 'Velocity',[20 0 0], 'Yaw',0);
out   = sih.planner.planTurn(iRoute(0), ego, space = space);
verifyFalse(tc, out.GripBinds);
verifyEqual(tc, out.Binds, "nothing");
end

% ---------------------------------------------------------------- the invalid path

function testAnInvalidRouteDrivesStraightInsteadOfErroring(tc)
r = iRoute(pi); r.Valid = false;
out = sih.planner.planTurn(r, iEgo(0));
verifyEqual(tc, out.Type, "NORMAL");
verifyFalse(tc, out.Valid);
verifyFalse(tc, out.NeedsReverse);
verifySubstring(tc, char(out.Reason), 'invalid');
end

function testARouteWithNoGoalHeadingAtAllIsSurvivable(tc)
% S10 does not exist yet, so a caller handing over a half-built struct is the
% ordinary case for now, not a freak one.
out = sih.planner.planTurn(struct('GoalPoint', [1 2 0]), iEgo(0));
verifyFalse(tc, out.Valid);
verifyEqual(tc, out.Type, "NORMAL");
end

function testANaNGoalHeadingIsInvalidNotATurn(tc)
out = sih.planner.planTurn(iRoute(NaN), iEgo(0));
verifyFalse(tc, out.Valid);
verifyEqual(tc, out.Curvature_1pm, 0);
end

function testAValidRouteSaysSo(tc)
verifyTrue(tc, sih.planner.planTurn(iRoute(pi), iEgo(0)).Valid);
end

% ---------------------------------------------------------------- guards and fit

function testAMissingEgoFieldIsRefusedByName(tc)
verifyError(tc, @() sih.planner.planTurn(iRoute(0), struct('Position',[0 0 0])), ...
            'sih:planner:planTurn:missingField');
end

function testTheTurningCircleMatchesTheCarTheRestOfThePlannerSteers(tc)
% wheelbase 2.8 (followTrunk) and steer limit 0.6 (chooseVelocity, fixed by S4).
% If these ever drift, three files disagree about what car this is.
out = sih.planner.planTurn(iRoute(pi), iEgo(0));
verifyEqual(tc, out.MinRadius_m, 2.8/tan(0.6), 'AbsTol', 1e-12);
end

function testTheCurvatureIsWhatSpeedLimitWants(tc)
% The sharp-turn row binds on grip, and grip already lives in speedLimit's first
% term. This function hands the curvature over rather than owning a second copy.
turn  = sih.planner.planTurn(iRoute(pi), iEgo(0));
space = struct('VisibleRange', 50, 'Valid', true);
cap   = sih.planner.speedLimit(space, 5, curvature_1pm = turn.Curvature_1pm);
verifyEqual(tc, cap.Radius_m,      turn.MinRadius_m,          'AbsTol', 1e-9);
verifyEqual(tc, cap.CurveTerm_mps, sqrt(3.0*turn.MinRadius_m), 'AbsTol', 1e-9);
end
