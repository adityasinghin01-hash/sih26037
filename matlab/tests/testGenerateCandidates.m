function tests = testGenerateCandidates
%TESTGENERATECANDIDATES  Unit tests for D6 piece 2, ego + path -> a fan of paths.
%
%   RUN IT:   results = runtests('matlab/tests/testGenerateCandidates.m'); disp(results)
%   Needs Navigation Toolbox (referencePathFrenet, trajectoryGeneratorFrenet).
%   No Simulink.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
tc.TestData.straight = referencePathFrenet([0 0; 25 0; 50 0; 100 0]);
tc.TestData.curved   = referencePathFrenet([0 0; 20 0; 40 5; 60 5]);
end

% ---------------------------------------------------------------- fixtures

function e = iEgo(speed_mps)
e = struct('Position',[0 0 0],'Velocity',[speed_mps 0 0],'Yaw',0);
end

% ---------------------------------------------------------------- shape

function testOneOffsetOneSpeedGivesOneCandidate(tc)
[c, info] = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
                lateralOffsets_m=0, terminalSpeeds_mps=5);
verifyEqual(tc, info.NumRequested, 1);
verifyNumElements(tc, c, 1);
end

function testTheFanIsEveryOffsetAtEverySpeed(tc)
[~, info] = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
                lateralOffsets_m=[-2 0 2], terminalSpeeds_mps=[2 5]);
verifyEqual(tc, info.NumRequested, 6);
end

function testEveryReturnedCandidateIsFinite(tc)
c = sih.planner.generateCandidates(iEgo(5), tc.TestData.curved);
verifyGreaterThan(tc, numel(c), 0);
for k = 1:numel(c)
    verifyTrue(tc, all(isfinite(c(k).Global(:))), ...
        sprintf('candidate %d has a non-finite value in .Global', k));
    verifyTrue(tc, all(isfinite(c(k).Frenet(:))));
end
end

function testStatesAreXYThetaAndMatchGlobal(tc)
c = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
        lateralOffsets_m=0, terminalSpeeds_mps=5);
verifySize(tc, c(1).States, [size(c(1).Global,1) 3]);
verifyEqual(tc, c(1).States, c(1).Global(:,1:3));
end

function testTimesStartAtZeroAndReachTheHorizon(tc)
c = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
        lateralOffsets_m=0, terminalSpeeds_mps=5, horizon_s=4, timeResolution_s=0.1);
verifyEqual(tc, c(1).Times(1), 0, 'AbsTol', 1e-12);
verifyEqual(tc, c(1).Times(end), 4, 'AbsTol', 1e-9);
verifyEqual(tc, numel(c(1).Times), size(c(1).Global,1));
end

function testInitFrenetIsSixWide(tc)
[~, info] = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight);
verifySize(tc, info.InitFrenet, [1 6]);
end

function testHorizonIsRecordedOnEveryCandidate(tc)
c = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, horizon_s=3);
for k = 1:numel(c)
    verifyEqual(tc, c(k).Horizon_s, 3);
end
end

% ---------------------------------------------------------------- the geometry

function testPositiveOffsetGoesLeftNegativeGoesRight(tc)
% Straight path along +x, so left is +y. This is the sign convention the whole
% planner depends on: positive is LEFT, same as SteerAngle in chooseVelocity.
c = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
        lateralOffsets_m=[-2 0 2], terminalSpeeds_mps=5);
yEnd = arrayfun(@(x) x.States(end,2), c);
off  = arrayfun(@(x) x.LateralOffset_m, c);
verifyEqual(tc, yEnd(off==2),  2, 'AbsTol', 0.2);
verifyEqual(tc, yEnd(off==0),  0, 'AbsTol', 0.2);
verifyEqual(tc, yEnd(off==-2),-2, 'AbsTol', 0.2);
end

function testTerminalSpeedIsReached(tc)
c = sih.planner.generateCandidates(iEgo(8), tc.TestData.straight, ...
        lateralOffsets_m=0, terminalSpeeds_mps=3, horizon_s=4);
verifyEqual(tc, c(1).Global(end,5), 3, 'AbsTol', 0.1);
end

function testTheAbortCandidateEndsStopped(tc)
% Terminal speed 0 is the abort option and must actually come to rest.
c = sih.planner.generateCandidates(iEgo(8), tc.TestData.straight, ...
        lateralOffsets_m=0, terminalSpeeds_mps=0, horizon_s=4);
verifyEqual(tc, c(1).Global(end,5), 0, 'AbsTol', 0.1);
end

function testACandidateStartsWhereTheEgoIs(tc)
c = sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
        lateralOffsets_m=0, terminalSpeeds_mps=5);
verifyEqual(tc, c(1).States(1,1:2), [0 0], 'AbsTol', 0.1);
end

% ---------------------------------------------------------------- guards

function testMissingEgoFieldErrors(tc)
e = rmfield(iEgo(5), 'Yaw');
verifyError(tc, @() sih.planner.generateCandidates(e, tc.TestData.straight), ...
            'sih:planner:generateCandidates:missingField');
end

function testNegativeTerminalSpeedIsRejected(tc)
verifyError(tc, @() sih.planner.generateCandidates(iEgo(5), tc.TestData.straight, ...
            terminalSpeeds_mps=-1), 'MATLAB:validators:mustBeNonnegative');
end
