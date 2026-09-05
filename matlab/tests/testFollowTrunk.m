function tests = testFollowTrunk
%TESTFOLLOWTRUNK  Unit tests for the bridge from D6's committed trunk to D2's command.
%
%   RUN IT:   results = runtests('matlab/tests/testFollowTrunk.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink. Every trunk here is
%   hand-built, so this file tests the following rule and nothing else.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function tr = iTrunk(S, t)
% A trunk shaped exactly like the one findSharedTrunk hands back.
if size(S,1) >= 2
    prog = sum(vecnorm(diff(S(:,1:2)), 2, 2));
else
    prog = 0;
end
tr = struct('CandidateIndex', 1, ...
            'Steps',             size(S,1), ...
            'Time',              iSpan(t), ...
            'Progress_m',        prog, ...
            'Times',             t, ...
            'States',            S, ...
            'LateralOffset_m',   0, ...
            'TerminalSpeed_mps', 0, ...
            'Blocked',           false, ...
            'Rule',              "test fixture", ...
            'Reason',            "test fixture");
end

function s = iSpan(t)
if isempty(t)
    s = 0;
else
    s = t(end) - t(1);
end
end

function tr = iAngledTrunk(v, ang, n, dt)
% A dead straight trunk leaving the origin at angle ang, travelling at v.
t = (0:n-1)' * dt;
S = [v*t*cos(ang), v*t*sin(ang), repmat(ang, n, 1)];
tr = iTrunk(S, t);
end

function tr = iStraightTrunk(v, n, dt)
tr = iAngledTrunk(v, 0, n, dt);
end

function tr = iBlockedTrunk()
% Exactly the shape findSharedTrunk's iNoTrunk produces.
tr = iTrunk(zeros(0,3), zeros(0,1));
tr.CandidateIndex    = NaN;
tr.LateralOffset_m   = NaN;
tr.TerminalSpeed_mps = NaN;
tr.Blocked           = true;
end

function e = iEgo(x, y, yaw, speed)
e = struct('Position', [x y 0], ...
           'Velocity', speed * [cos(yaw) sin(yaw) 0], ...
           'Yaw',      yaw);
end

% ---------------------------------------------------------------- steering

function testStraightTrunkGoesStraight(tc)
% Trunk dead ahead, car already on it at the speed it asks for: do nothing.
tr = iStraightTrunk(5, 41, 0.1);
[cmd, info] = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
verifyEqual(tc, cmd.SteerAngle, 0);
verifyEqual(tc, cmd.Accel, 0, 'AbsTol', 1e-9);
verifyEqual(tc, info.CrossTrack_m, 0, 'AbsTol', 1e-12);
verifyFalse(tc, info.Blocked);
end

function testTrunkToTheLeftSteersLeft(tc)
% Positive steer is LEFT. Frame is x forward, y left.
tr  = iAngledTrunk(5, 0.2, 41, 0.1);
cmd = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
verifyGreaterThan(tc, cmd.SteerAngle, 0);
end

function testTrunkToTheRightSteersRight(tc)
tr  = iAngledTrunk(5, -0.2, 41, 0.1);
cmd = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
verifyLessThan(tc, cmd.SteerAngle, 0);
end

function testLeftAndRightAreMirrorImages(tc)
% Nothing in the rule may prefer one side. A left bias here would be a real bug.
cmdL = sih.planner.followTrunk(iAngledTrunk(5,  0.2, 41, 0.1), iEgo(0,0,0,5));
cmdR = sih.planner.followTrunk(iAngledTrunk(5, -0.2, 41, 0.1), iEgo(0,0,0,5));
verifyEqual(tc, cmdL.SteerAngle, -cmdR.SteerAngle, 'AbsTol', 1e-12);
verifyEqual(tc, cmdL.Accel,       cmdR.Accel,      'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- speed

function testSpeedsUpWhenTheTrunkAsksForMore(tc)
tr  = iStraightTrunk(4, 41, 0.1);
cmd = sih.planner.followTrunk(tr, iEgo(0,0,0,2), settleTime_s = 2);
verifyGreaterThan(tc, cmd.Accel, 0);
end

function testSlowsDownWhenTheTrunkAsksForLess(tc)
tr  = iStraightTrunk(4, 41, 0.1);
cmd = sih.planner.followTrunk(tr, iEgo(0,0,0,5), settleTime_s = 2);
verifyLessThan(tc, cmd.Accel, 0);
end

function testTerminalSpeedIsIgnored(tc)
% The trunk is only the committed FRONT of a candidate, so the candidate's
% terminal speed is a speed the committed part never reaches. The pace of the
% committed points is the only thing that may set the target.
tr = iStraightTrunk(5, 41, 0.1);
tr.TerminalSpeed_mps = 99;
[~, info] = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
verifyEqual(tc, info.TargetSpeed_mps, 5, 'AbsTol', 1e-9);
end

% ---------------------------------------------------------------- S4 limits

function testAccelIsClampedToS4Limits(tc)
% S4 fixes Accel to [-6, +3]. The planner must never emit outside them.
fast = sih.planner.followTrunk(iStraightTrunk(20, 41, 0.1), iEgo(0,0,0,0.5), settleTime_s = 0.1);
slow = sih.planner.followTrunk(iStraightTrunk(1,  41, 0.1), iEgo(0,0,0,20),  settleTime_s = 0.1);
verifyEqual(tc, fast.Accel,  3);
verifyEqual(tc, slow.Accel, -6);
end

function testSteerIsClampedToS4Limits(tc)
% A trunk leaving straight out to the left demands far more than 0.6 rad.
tr  = iAngledTrunk(5, pi/2, 41, 0.1);
cmd = sih.planner.followTrunk(tr, iEgo(0,0,0,0.5));
verifyEqual(tc, cmd.SteerAngle, 0.6);
end

% ---------------------------------------------------------------- no trunk

function testBlockedTrunkDecelerates(tc)
[cmd, info] = sih.planner.followTrunk(iBlockedTrunk(), iEgo(0,0,0,5));
verifyLessThan(tc, cmd.Accel, 0);
verifyEqual(tc, cmd.SteerAngle, 0);
verifyTrue(tc, info.Blocked);
verifyTrue(tc, contains(cmd.Reason, "blocked"));
end

function testBlockedAndAlreadyStoppedDoesNotReverse(tc)
% A standing car given a negative acceleration would roll backwards.
cmd = sih.planner.followTrunk(iBlockedTrunk(), iEgo(0,0,0,0));
verifyEqual(tc, cmd.Accel, 0);
end

function testSinglePointTrunkIsNotFollowable(tc)
% One point carries no heading and no speed, so it is no better than no trunk.
tr = iTrunk([1 2 0], 0);
[cmd, info] = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
verifyLessThan(tc, cmd.Accel, 0);
verifyEqual(tc, cmd.SteerAngle, 0);
verifyTrue(tc, info.Blocked);
end

% ---------------------------------------------------------------- the contract

function testCommandHasExactlyTheS4FieldsWeSet(tc)
% Signal, Gear, Committed and MirrorsFolded belong to Person B's chart.
cmd = sih.planner.followTrunk(iStraightTrunk(5, 41, 0.1), iEgo(0,0,0,5));
verifyEqual(tc, sort(fieldnames(cmd)), sort({'Accel';'SteerAngle';'Mode';'Reason'}));
end

function testModeIsUnstructuredAndReasonIsAString(tc)
% S8: 1 is UNSTRUCTURED. EMERGENCY is h < 0 and is not this function's business.
cmd = sih.planner.followTrunk(iStraightTrunk(5, 41, 0.1), iEgo(0,0,0,5));
verifyEqual(tc, cmd.Mode, uint8(1));
verifyClass(tc, cmd.Reason, 'string');
end

% ---------------------------------------------------------------- aiming

function testFindsWhereTheCarIsAlongTheTrunk(tc)
% The trunk is replanned at 10 Hz but this may run faster, so by now the car has
% moved along it. Aiming from the trunk's START would steer at a passed point.
tr = iStraightTrunk(5, 41, 0.1);          % 0.5 m per step, x from 0 to 20
[~, info] = sih.planner.followTrunk(tr, iEgo(10,0,0,5));
verifyEqual(tc, info.NearestIndex, 21);
verifyGreaterThan(tc, info.LookaheadIndex, 21);
end

function testShortTrunkAimsAtItsLastPoint(tc)
% A trunk shorter than the look-ahead must still give an answer, not run off it.
tr = iStraightTrunk(1, 3, 0.1);           % 0.1 m per step, 0.2 m long in all
[cmd, info] = sih.planner.followTrunk(tr, iEgo(0,0,0,1));
verifyEqual(tc, info.LookaheadIndex, 3);
verifyTrue(tc, isfinite(cmd.Accel) && isfinite(cmd.SteerAngle));
end

% ---------------------------------------------------------------- bad input

function testMissingTrunkFieldErrors(tc)
tr = iStraightTrunk(5, 41, 0.1);
tr = rmfield(tr, 'Blocked');
verifyError(tc, @() sih.planner.followTrunk(tr, iEgo(0,0,0,5)), ...
            'sih:planner:followTrunk:missingField');
end

function testMissingEgoFieldErrors(tc)
e = rmfield(iEgo(0,0,0,5), 'Yaw');
verifyError(tc, @() sih.planner.followTrunk(iStraightTrunk(5,41,0.1), e), ...
            'sih:planner:followTrunk:missingField');
end

function testNonFiniteTrunkErrors(tc)
% This project's failure mode is a plausible wrong number, not a crash. A NaN in
% the path must be loud, never quietly followed.
tr = iStraightTrunk(5, 41, 0.1);
tr.States(10,2) = NaN;
verifyError(tc, @() sih.planner.followTrunk(tr, iEgo(0,0,0,5)), ...
            'sih:planner:followTrunk:nonFiniteTrunk');
end

function testMismatchedLengthsError(tc)
tr = iStraightTrunk(5, 41, 0.1);
tr.Times = tr.Times(1:end-1);
verifyError(tc, @() sih.planner.followTrunk(tr, iEgo(0,0,0,5)), ...
            'sih:planner:followTrunk:sizeMismatch');
end

function testSameInputGivesSameAnswer(tc)
tr = iAngledTrunk(5, 0.15, 41, 0.1);
a  = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
b  = sih.planner.followTrunk(tr, iEgo(0,0,0,5));
verifyEqual(tc, a, b);
end
