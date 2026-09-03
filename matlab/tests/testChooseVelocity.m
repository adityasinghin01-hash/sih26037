function tests = testChooseVelocity
%TESTCHOOSEVELOCITY  Unit tests for D2, role -> EgoCommand.
%
%   RUN IT:   results = runtests('matlab/tests/testChooseVelocity.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink. That is the point of
%   the A/B split: this whole file runs in well under a second.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
tc.TestData.SAFE       = uint8(0);
tc.TestData.GIVE_WAY   = uint8(1);
tc.TestData.STAND_ON   = uint8(2);
tc.TestData.HEAD_ON    = uint8(3);
tc.TestData.OVERTAKING = uint8(4);
end

% ---------------------------------------------------------------- fixtures

function vo = iVo(h)
% Only .h is read by chooseVelocity, but build the whole struct so the test
% exercises the same shape velocityObstacle actually returns.
vo = struct('d',20,'beta',0.1,'lambda',0.1+h,'h',h, ...
            'colliding',h<0,'tcpa',2,'dcpa',5,'bearing',0);
end

function ego = iEgo(speed_mps)
ego = struct('Position',[0 0 0],'Velocity',[speed_mps 0 0],'Yaw',0);
end

% ---------------------------------------------------------------- the roles

function testStandOnFlatDoesExactlyNothing(tc)
% THE HARD ONE: doing nothing is the action, and it is the safety argument.
cmd = sih.planner.chooseVelocity(tc.TestData.STAND_ON, iVo(0.5), iEgo(5));
verifyEqual(tc, cmd.Accel, 0, 'AbsTol', 1e-12, 'STAND_ON on the flat must emit zero accel');
verifyEqual(tc, cmd.SteerAngle, 0, 'AbsTol', 1e-12, 'STAND_ON must not steer');
end

function testStandOnGradientHoldsSpeed(tc)
% On a gradient, holding speed needs a NON-zero acceleration. Settled by Aditya.
grade = deg2rad(6);
cmd = sih.planner.chooseVelocity(tc.TestData.STAND_ON, iVo(0.5), iEgo(5), ...
                                 'gradient_rad', grade);
verifyEqual(tc, cmd.Accel, 9.81*sin(grade), 'AbsTol', 1e-9);
verifyGreaterThan(tc, cmd.Accel, 0, 'uphill must need positive accel to hold speed');
end

function testGiveWayIsOneSubstantialMoveNotANudge(tc)
% COLREGs Rule 8 forbids a series of small alterations. M10 catches a wobble.
cmd = sih.planner.chooseVelocity(tc.TestData.GIVE_WAY, iVo(0.5), iEgo(8));
verifyLessThanOrEqual(tc, cmd.Accel, -1.0, 'GIVE_WAY must be a substantial deceleration');
end

function testGiveWayDoesNotSteer(tc)
% Lateral avoidance is a D6 candidate path, not a per-agent reflex here.
cmd = sih.planner.chooseVelocity(tc.TestData.GIVE_WAY, iVo(0.5), iEgo(8));
verifyEqual(tc, cmd.SteerAngle, 0, 'AbsTol', 1e-12);
end

function testHeadOnSteersLeftByDefault(tc)
% Frame is x forward, y left. POSITIVE STEER IS LEFT. Both vehicles pick the
% same side so the manoeuvre is predictable (Rule 14).
cmd = sih.planner.chooseVelocity(tc.TestData.HEAD_ON, iVo(0.5), iEgo(8));
verifyGreaterThan(tc, cmd.SteerAngle, 0, 'default HEAD_ON side must be LEFT (positive)');
end

function testHeadOnSideIsConfigurable(tc)
cmd = sih.planner.chooseVelocity(tc.TestData.HEAD_ON, iVo(0.5), iEgo(8), ...
                                 'headOnSteer_rad', -0.2);
verifyEqual(tc, cmd.SteerAngle, -0.2, 'AbsTol', 1e-12);
end

function testOvertakingNeverAccelerates(tc)
% Rule 13: the overtaking vehicle keeps clear until past and clear.
cmd = sih.planner.chooseVelocity(tc.TestData.OVERTAKING, iVo(0.5), iEgo(8));
verifyLessThanOrEqual(tc, cmd.Accel, 0);
end

function testSafeEmitsNoConstraint(tc)
cmd = sih.planner.chooseVelocity(tc.TestData.SAFE, iVo(1.2), iEgo(8));
verifyEqual(tc, cmd.Accel, 0, 'AbsTol', 1e-12);
verifyEqual(tc, cmd.SteerAngle, 0, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- the barrier

function testNegativeBarrierForcesEmergency(tc)
% h < 0 overrides every role. The barrier can veto anything above it.
cmd = sih.planner.chooseVelocity(tc.TestData.STAND_ON, iVo(-0.3), iEgo(8));
verifyEqual(tc, cmd.Mode, uint8(2), 'h < 0 must force EMERGENCY mode');
verifyEqual(tc, cmd.Accel, -6, 'AbsTol', 1e-12, 'EMERGENCY must brake at the limit');
end

function testSafeRoleStillEmergencyWhenBarrierViolated(tc)
% Even a SAFE role does not outrank the barrier.
cmd = sih.planner.chooseVelocity(tc.TestData.SAFE, iVo(-0.01), iEgo(8));
verifyEqual(tc, cmd.Mode, uint8(2));
end

function testNormalModeIsUnstructured(tc)
cmd = sih.planner.chooseVelocity(tc.TestData.GIVE_WAY, iVo(0.5), iEgo(8));
verifyEqual(tc, cmd.Mode, uint8(1));
end

% ---------------------------------------------------------------- S4 limits

function testAccelIsAlwaysClamped(tc)
% S4 fixes Accel to [-6 +3]. The planner must never emit outside it.
cmd = sih.planner.chooseVelocity(tc.TestData.GIVE_WAY, iVo(0.5), iEgo(8), ...
                                 'giveWayAccel_mps2', -50);
verifyEqual(tc, cmd.Accel, -6, 'AbsTol', 1e-12);
end

function testSteerIsAlwaysClamped(tc)
% S4 fixes SteerAngle to [-0.6 +0.6].
cmd = sih.planner.chooseVelocity(tc.TestData.HEAD_ON, iVo(0.5), iEgo(8), ...
                                 'headOnSteer_rad', 5);
verifyEqual(tc, cmd.SteerAngle, 0.6, 'AbsTol', 1e-12);
end

function testSteepGradientStillClamped(tc)
cmd = sih.planner.chooseVelocity(tc.TestData.STAND_ON, iVo(0.5), iEgo(5), ...
                                 'gradient_rad', deg2rad(80));
verifyLessThanOrEqual(tc, cmd.Accel, 3);
end

% ---------------------------------------------------------------- edge cases

function testStoppedVehicleIsNotToldToBrakeMore(tc)
% You cannot give way with speed you do not have.
cmd = sih.planner.chooseVelocity(tc.TestData.GIVE_WAY, iVo(0.5), iEgo(0));
verifyEqual(tc, cmd.Accel, 0, 'AbsTol', 1e-12);
end

function testEveryRoleGivesANonEmptyReason(tc)
roles = [tc.TestData.SAFE tc.TestData.GIVE_WAY tc.TestData.STAND_ON ...
         tc.TestData.HEAD_ON tc.TestData.OVERTAKING];
for r = roles
    cmd = sih.planner.chooseVelocity(r, iVo(0.5), iEgo(5));
    verifyNotEmpty(tc, char(cmd.Reason), sprintf('role %d gave an empty Reason', r));
end
end

function testUnknownRoleErrors(tc)
% A role code outside S7 is a contract violation, not something to guess at.
verifyError(tc, @() sih.planner.chooseVelocity(uint8(9), iVo(0.5), iEgo(5)), ...
            'sih:planner:chooseVelocity:unknownRole');
end

function testMissingEgoFieldErrors(tc)
bad = struct('Position',[0 0 0],'Yaw',0);   % no .Velocity
verifyError(tc, @() sih.planner.chooseVelocity(uint8(2), iVo(0.5), bad), ...
            'sih:planner:chooseVelocity:missingField');
end

function testCommandHasExactlyTheFourContractFields(tc)
% D2 sets Accel, SteerAngle, Mode and Reason ONLY. Signal, Gear, Committed and
% MirrorsFolded are Stateflow's, and inventing them here would break the split.
cmd = sih.planner.chooseVelocity(tc.TestData.SAFE, iVo(0.5), iEgo(5));
verifyEqual(tc, sort(fieldnames(cmd)), sort({'Accel';'SteerAngle';'Mode';'Reason'}));
end
