function tests = testPredictAgentFutures
%TESTPREDICTAGENTFUTURES  Unit tests for D6 piece 1, one track -> two futures.
%
%   RUN IT:   results = runtests('matlab/tests/testPredictAgentFutures.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function t = iTrack(speed_mps, yaw_rad)
% A car heading along its own yaw at the given speed.
t = struct('TrackID', uint32(7), ...
           'ClassID', uint8(1), ...
           'Position',[10 0 0], ...
           'Velocity',[speed_mps*cos(yaw_rad) speed_mps*sin(yaw_rad) 0], ...
           'Extent',  [4.5 1.8 1.5], ...
           'Yaw',     yaw_rad, ...
           'Existence',0.9, ...
           'Age',     uint32(30), ...
           'SensorMask', uint8(3));
end

% ---------------------------------------------------------------- shape

function testExactlyTwoFuturesInYieldAssertOrder(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.7, true);
verifyNumElements(tc, f, 2);
verifyEqual(tc, f(1).Label, "YIELD");
verifyEqual(tc, f(2).Label, "ASSERT");
end

function testStepCountMatchesHorizonAndResolution(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.5, true, ...
        horizon_s=4, timeResolution_s=0.1);
verifyEqual(tc, numel(f(1).Times), 41);
verifyEqual(tc, size(f(1).States), [41 3]);
verifyEqual(tc, f(1).Times(1),   0,   'AbsTol', 1e-12);
verifyEqual(tc, f(1).Times(end), 4,   'AbsTol', 1e-12);
end

function testTrackIDAndExtentAreCarriedThrough(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.5, true);
verifyEqual(tc, f(1).TrackID, uint32(7));
verifyEqual(tc, f(2).Extent,  [4.5 1.8 1.5]);
end

function testEveryStateIsFinite(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0.3), 0.5, true);
verifyTrue(tc, all(isfinite(f(1).States(:))));
verifyTrue(tc, all(isfinite(f(2).States(:))));
end

% ---------------------------------------------------------------- probability

function testProbabilitiesSumToOneWhenValid(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.7, true);
verifyEqual(tc, f(1).Probability, 0.7, 'AbsTol', 1e-12);
verifyEqual(tc, f(2).Probability, 0.3, 'AbsTol', 1e-12);
end

function testProbabilityIsNaNWhenInvalidNeverAHalf(tc)
% S3 rule: never 0.5 as a fallback. NaN cannot be used by accident.
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.7, false);
verifyTrue(tc, isnan(f(1).Probability));
verifyTrue(tc, isnan(f(2).Probability));
verifyFalse(tc, f(1).Valid);
end

function testBothFuturesStillExistWhenPredictionIsInvalid(tc)
% Safety must not depend on the weight, so an invalid prediction still gets
% both futures to plan against.
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.7, false);
verifyNumElements(tc, f, 2);
verifySize(tc, f(1).States, [41 3]);
end

function testOutOfRangePYieldErrorsOnlyWhenValid(tc)
verifyError(tc, @() sih.planner.predictAgentFutures(iTrack(8,0), 1.4, true), ...
            'sih:planner:predictAgentFutures:badPYield');
% Invalid means pYield is meaningless, so its value must not matter.
f = sih.planner.predictAgentFutures(iTrack(8,0), 1.4, false);
verifyTrue(tc, isnan(f(1).Probability));
end

% ---------------------------------------------------------------- the motion

function testAssertHoldsSpeedByDefault(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.5, true);
verifyEqual(tc, f(2).Speeds, repmat(8,41,1), 'AbsTol', 1e-12);
end

function testYieldEndsSlowerThanAssert(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.5, true);
verifyLessThan(tc, f(1).Speeds(end), f(2).Speeds(end));
end

function testYieldNeverReverses(tc)
% Braking to a stop must stop, not drive backwards.
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.5, true, yieldDecel_mps2=-5);
verifyGreaterThanOrEqual(tc, min(f(1).Speeds), 0);
travelled = f(1).States(:,1) - 10;             % track starts at x = 10
verifyGreaterThanOrEqual(tc, min(diff(travelled)), -1e-12);
end

function testYieldStopDistanceMatchesTheClosedForm(tc)
% v0 = 10, a = -5  ->  stops after 2 s having covered v0^2/(2|a|) = 10 m,
% and stays there for the rest of the 4 s horizon.
f = sih.planner.predictAgentFutures(iTrack(10,0), 0.5, true, yieldDecel_mps2=-5);
verifyEqual(tc, f(1).States(end,1), 20, 'AbsTol', 1e-9);
verifyEqual(tc, f(1).Speeds(end),    0, 'AbsTol', 1e-12);
end

function testAssertIsCappedAtMaxSpeed(tc)
f = sih.planner.predictAgentFutures(iTrack(8,0), 0.5, true, ...
        assertAccel_mps2=3, assertMaxSpeed_mps=10);
verifyEqual(tc, max(f(2).Speeds), 10, 'AbsTol', 1e-12);
end

function testStoppedAgentStaysPut(tc)
f = sih.planner.predictAgentFutures(iTrack(0,0), 0.5, true);
verifyEqual(tc, f(1).States(end,1:2), [10 0], 'AbsTol', 1e-12);
verifyEqual(tc, f(2).States(end,1:2), [10 0], 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- heading

function testHeadingComesFromVelocityWhenMoving(tc)
% Velocity says +y, Yaw says +x. Moving, so velocity wins.
t = iTrack(5, 0);
t.Velocity = [0 5 0];
f = sih.planner.predictAgentFutures(t, 0.5, true);
verifyEqual(tc, f(2).States(1,3), pi/2, 'AbsTol', 1e-12);
verifyGreaterThan(tc, f(2).States(end,2), 10);       % it moved in +y
end

function testHeadingComesFromYawWhenNearlyStopped(tc)
% Below movingSpeed_mps the velocity vector is noise and Yaw is all we have.
t = iTrack(0, pi/2);
t.Velocity = [0.01 -0.02 0];
f = sih.planner.predictAgentFutures(t, 0.5, true);
verifyEqual(tc, f(1).States(1,3), pi/2, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- guards

function testMissingTrackFieldErrors(tc)
t = rmfield(iTrack(8,0), 'Extent');
verifyError(tc, @() sih.planner.predictAgentFutures(t, 0.5, true), ...
            'sih:planner:predictAgentFutures:missingField');
end
