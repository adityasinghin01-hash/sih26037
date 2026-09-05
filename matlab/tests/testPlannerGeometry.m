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

% ---------------------------------------------------------------- the frame contract
%
% AGENTS.md S1 defines TrackList Position in the EGO frame (x fwd, y left).
% assignRoles computes r = trkPos - egoPos and bearing - egoYaw, so it needs the tracks
% and the ego pose in the SAME frame. The two tests below pin that down, because every
% test above happens to use egoPos = [0 0] and egoYaw = 0, where the world frame and the
% ego frame coincide - so none of them can catch the mistake.
%
% THE TRAP: when Stream B delivers a real S1 TrackList (ego frame), the caller must pass
% egoPos = [0 0] and egoYaw = 0. Passing the real world ego pose instead is the obvious
% thing to do and it silently corrupts every bearing and therefore every role.

function [pW, pE] = iSameEncounterBothFrames()
% One encounter, written twice: once in world coordinates, once in the ego frame.
egoPos = [100 50];  egoYaw = pi/4;  egoSpeed = 5;
R      = @(a) [cos(a) -sin(a); sin(a) cos(a)];

egoVelW = (R(egoYaw)  * [egoSpeed; 0])';        % ego heading 45 deg, 5 m/s
relPos  = [15 -15];                              % 15 m ahead, 15 m to STARBOARD, ego frame
relVel  = [0 5];                                 % crossing left across our bow, ego frame

trkPosW = egoPos  + (R(egoYaw) * relPos')';
trkVelW =           (R(egoYaw) * relVel')';

pW = struct('egoPos', egoPos,  'egoVel', egoVelW,        'egoYaw', egoYaw, ...
            'trkPos', trkPosW, 'trkVel', trkVelW);
pE = struct('egoPos', [0 0],   'egoVel', [egoSpeed 0],   'egoYaw', 0, ...
            'trkPos', relPos,  'trkVel', relVel);
end

function testWorldFrameAndEgoFrameGiveTheSameRole(tc)
% The same physical encounter must produce the same role in either frame, PROVIDED the
% ego pose is expressed in that same frame.
[pW, pE] = iSameEncounterBothFrames();

tW = iTrack(1, pW.trkPos, pW.trkVel);
tE = iTrack(1, pE.trkPos, pE.trkVel);

rW = sih.planner.assignRoles(pW.egoPos, pW.egoVel, pW.egoYaw, tW);
rE = sih.planner.assignRoles(pE.egoPos, pE.egoVel, pE.egoYaw, tE);

verifyEqual(tc, rE.Role, rW.Role, 'the same encounter must give the same role in either frame');
verifyEqual(tc, rE.Role, uint8(1), 'this encounter is a starboard crossing: GIVE_WAY');
verifyEqual(tc, rE.Beta,   rW.Beta,   'AbsTol', 1e-9);
verifyEqual(tc, rE.Lambda, rW.Lambda, 'AbsTol', 1e-9);
verifyEqual(tc, rE.TCPA,   rW.TCPA,   'AbsTol', 1e-9);
end

function testEgoFrameTracksWithAWorldEgoPoseAreWrong(tc)
% The failure mode this contract exists to prevent, stated as a test: feeding an
% EGO-FRAME TrackList together with the WORLD ego pose does not error - it silently
% returns a different answer. If this ever starts matching, the frame handling changed
% and every role in the project needs re-checking.
[pW, pE] = iSameEncounterBothFrames();

good = sih.planner.assignRoles(pE.egoPos, pE.egoVel, pE.egoYaw, iTrack(1, pE.trkPos, pE.trkVel));
bad  = sih.planner.assignRoles(pW.egoPos, pW.egoVel, pW.egoYaw, iTrack(1, pE.trkPos, pE.trkVel));

verifyNotEqual(tc, bad.Role, good.Role, ...
    ['mixing an ego-frame TrackList with a world ego pose must NOT silently agree - ' ...
     'if it does, this test is no longer protecting anything']);
end

% ------------------------------------------- assignRoles' second output, added 4 Sep 2026

function testAssignRolesAlsoReturnsTheGeometryItUsedToThrowAway(tc)
% It always built a full velocityObstacle result per agent and kept three fields of
% it. Now it hands the rest back, so sih.planner.arbitrate can pick an agent without
% ever being shown a position - and therefore without a frame to get wrong.
tracks = [iTrack(1, [20 0], [-8 0]); iTrack(2, [10 10], [0 -5])];
[roles, vos] = sih.planner.assignRoles([0 0], [8 0], 0, tracks);

verifyNumElements(tc, vos, 2);
verifyEqual(tc, [roles.Beta],   [vos.beta],   'AbsTol', 1e-12);
verifyEqual(tc, [roles.Lambda], [vos.lambda], 'AbsTol', 1e-12);
verifyEqual(tc, [roles.TCPA],   [vos.tcpa],   'AbsTol', 1e-12);
end

function testTheSecondOutputIsTheSameThingVelocityObstacleReturns(tc)
% Not a lookalike. chooseVelocity reads .h off it, so it has to BE one.
tracks = iTrack(1, [20 0], [-8 0]);
[~, vos] = sih.planner.assignRoles([0 0], [8 0], 0, tracks);
direct = sih.planner.velocityObstacle([0 0], [8 0], [20 0], [-8 0], 2.5);

verifyEqual(tc, fieldnames(vos), fieldnames(direct));
verifyEqual(tc, vos.h, direct.h, 'AbsTol', 1e-12);
end

function testAnEmptyTrackListStillGivesTwoUsableOutputs(tc)
% S1 guarantee 3. Both outputs must come back empty rather than missing, or a caller
% that always asks for two errors on an empty road.
proto = iTrack(1, [20 0], [-8 0]);
[roles, vos] = sih.planner.assignRoles([0 0], [8 0], 0, proto([]));
verifyEmpty(tc, roles);
verifyEmpty(tc, vos);
end

function testAskingForOneOutputStillWorks(tc)
% Backward compatibility, stated as a test: every existing caller asks for one thing.
tracks = iTrack(1, [20 0], [-8 0]);
roles  = sih.planner.assignRoles([0 0], [8 0], 0, tracks);
verifyEqual(tc, roles.TrackID, uint32(1));
end
