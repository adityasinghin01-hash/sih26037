function tests = testPlannerGeometry
%TESTPLANNERGEOMETRY  Unit tests for the velocity obstacle and COLREGs role assignment.
%
%   RUN IT:   results = runtests('matlab/tests/testPlannerGeometry.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB. Run this the moment MATLAB is installed -
%   it verifies the planner maths without any simulation.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
tc.TestData.dMin = 2.0;
end

% ---------------------------------------------------------------- velocity obstacle

function testHeadOnCollisionDetected(tc)
% ego at origin heading +x at 5 m/s; agent 20 m ahead coming straight at us at 5 m/s
vo = sih.planner.velocityObstacle([0 0],[5 0],[20 0],[-5 0],tc.TestData.dMin);
verifyTrue(tc, vo.colliding, 'head-on approach must be flagged as colliding');
verifyLessThan(tc, vo.h, 0, 'barrier h must be negative when colliding');
verifyGreaterThan(tc, vo.tcpa, 0, 'tCPA must be positive when closing');
verifyEqual(tc, vo.tcpa, 2.0, 'AbsTol', 1e-9);   % 20 m closing at 10 m/s
end

function testOpeningIsSafe(tc)
% agent 20 m ahead driving away faster than us
vo = sih.planner.velocityObstacle([0 0],[5 0],[20 0],[10 0],tc.TestData.dMin);
verifyFalse(tc, vo.colliding);
verifyGreaterThanOrEqual(tc, vo.h, 0, 'h must be >= 0 when safe');
verifyLessThan(tc, vo.tcpa, 0, 'tCPA must be negative when opening');
end

function testZeroRelativeVelocityStaysDefined(tc)
% THE CASE THAT BREAKS THE COLLISION-CONE FORM: both stationary relative to each other.
% An Indian junction produces this constantly. The VO form must not return NaN.
vo = sih.planner.velocityObstacle([0 0],[3 0],[15 0],[3 0],tc.TestData.dMin);
verifyFalse(tc, isnan(vo.h), 'h must stay defined at zero relative velocity');
verifyFalse(tc, vo.colliding);
verifyEqual(tc, vo.tcpa, Inf);
end

function testConeHalfAngleFormula(tc)
% beta = asin(dMin/d).  d = 10, dMin = 2  ->  beta = asin(0.2)
vo = sih.planner.velocityObstacle([0 0],[1 0],[10 0],[0 0],2.0);
verifyEqual(tc, vo.beta, asin(0.2), 'AbsTol', 1e-12);
end

function testInsideSafetyDiscIsCollision(tc)
vo = sih.planner.velocityObstacle([0 0],[1 0],[1 0],[0 0],2.0);
verifyTrue(tc, vo.colliding);
verifyLessThan(tc, vo.h, 0);
end

% ---------------------------------------------------------------- role assignment

function t = iTrack(id, pos, vel)
t = struct('TrackID',uint32(id),'ClassID',uint8(1),'Position',[pos 0], ...
           'Velocity',[vel 0],'Extent',[4 1.8 1.5],'Yaw',atan2(vel(2),vel(1)), ...
           'Existence',1.0,'Age',uint32(30));
end

function testEmptyTrackListReturnsEmpty(tc)
% S1 rule 3: consumers must handle an empty TrackList without erroring
empty = iTrack(1,[0 0],[0 0]); empty = empty([]);
roles = sih.planner.assignRoles([0 0],[5 0],0,empty);
verifyEmpty(tc, roles);
end

function testStarboardCrossingGivesWay(tc)
% Rule 15: agent crossing from our STARBOARD (negative y) -> we give way.
% Agent 15 m ahead and 15 m to starboard, moving to port across our bow.
trk = iTrack(1,[15 -15],[0 5]);
roles = sih.planner.assignRoles([0 0],[5 0],0,trk);
verifyEqual(tc, roles.Role, uint8(1), 'expected GIVE_WAY for a starboard crossing');
end

function testPortCrossingStandsOn(tc)
% Mirror image: agent on our PORT side -> we hold course and speed (Rule 17)
trk = iTrack(2,[15 15],[0 -5]);
roles = sih.planner.assignRoles([0 0],[5 0],0,trk);
verifyEqual(tc, roles.Role, uint8(2), 'expected STAND_ON for a port crossing');
end

function testHeadOnDetected(tc)
% Rule 14: reciprocal courses
trk = iTrack(3,[25 0.5],[-5 0]);
roles = sih.planner.assignRoles([0 0],[5 0],0,trk);
verifyEqual(tc, roles.Role, uint8(3), 'expected HEAD_ON');
end

function testOpeningAgentIsSafe(tc)
trk = iTrack(4,[25 0],[10 0]);
roles = sih.planner.assignRoles([0 0],[5 0],0,trk);
verifyEqual(tc, roles.Role, uint8(0), 'expected SAFE for an opening agent');
end

function testOutOfRangeIsSafe(tc)
trk = iTrack(5,[200 0],[-5 0]);
roles = sih.planner.assignRoles([0 0],[5 0],0,trk,'maxRange_m',50);
verifyEqual(tc, roles.Role, uint8(0), 'expected SAFE beyond maxRange');
end

function testRoleCountMatchesTrackCount(tc)
trks = [iTrack(1,[15 -15],[0 5]), iTrack(2,[15 15],[0 -5]), iTrack(3,[25 0.5],[-5 0])];
roles = sih.planner.assignRoles([0 0],[5 0],0,trks);
verifyNumElements(tc, roles, 3);
verifyEqual(tc, [roles.TrackID], uint32([1 2 3]));
end
