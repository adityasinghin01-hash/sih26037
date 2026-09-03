function tests = testFindSharedTrunk
%TESTFINDSHAREDTRUNK  Unit tests for D6 piece 4, how far we commit.
%
%   RUN IT:   results = runtests('matlab/tests/testFindSharedTrunk.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink. The candidates here
%   are hand-built, so this file tests the choosing rule and nothing else.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function c = iCand(offset_m, speed_mps, n, dt)
% A straight candidate along +x at a constant speed, n steps of dt.
t = (0:n-1)' * dt;
c = struct('LateralOffset_m', offset_m, ...
           'TerminalSpeed_mps', speed_mps, ...
           'Horizon_s', (n-1)*dt, ...
           'Times', t, ...
           'States',[speed_mps*t, repmat(offset_m,n,1), zeros(n,1)]);
end

% ---------------------------------------------------------------- the ranking

function testLongestSafeStretchWins(tc)
c = [iCand(0, 5, 41, 0.1); iCand(3, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, [10; 30]);
verifyEqual(tc, trunk.CandidateIndex, 2);
verifyEqual(tc, trunk.Steps, 30);
end

function testSafetyBeatsProgress(tc)
% The fast one covers far more ground but is safe for less of it. Safety first.
c = [iCand(0, 20, 41, 0.1); iCand(0, 2, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, [10; 40]);
verifyEqual(tc, trunk.CandidateIndex, 2);
end

function testOnATieTheOneThatCoversMoreGroundWins(tc)
% Same safe length, so the trunk that actually moves is the better probe.
c = [iCand(0, 2, 41, 0.1); iCand(0, 9, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, [30; 30]);
verifyEqual(tc, trunk.CandidateIndex, 2);
verifyGreaterThan(tc, trunk.Progress_m, 20);
end

function testOnAFullTieTheStraighterPathWins(tc)
% Identical speed and safe length, so do not swerve for nothing (Rule 8).
c = [iCand(3, 5, 41, 0.1); iCand(0, 5, 41, 0.1); iCand(-1.5, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, [30; 30; 30]);
verifyEqual(tc, trunk.CandidateIndex, 2);
verifyEqual(tc, trunk.LateralOffset_m, 0);
end

function testAnExactTieIsResolvedDeterministically(tc)
% Two runs of the same input must give the same answer, every time.
c = [iCand(2, 5, 41, 0.1); iCand(-2, 5, 41, 0.1)];
t1 = sih.planner.findSharedTrunk(c, [30; 30]);
t2 = sih.planner.findSharedTrunk(c, [30; 30]);
verifyEqual(tc, t1.CandidateIndex, t2.CandidateIndex);
verifyEqual(tc, t1.CandidateIndex, 1);
end

% ---------------------------------------------------------------- the trunk

function testTheTrunkIsTheLeadingPartOfTheWinningPath(tc)
c = [iCand(0, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, 25);
verifySize(tc, trunk.States, [25 3]);
verifyEqual(tc, trunk.States, c(1).States(1:25,:));
verifyEqual(tc, trunk.Times,  c(1).Times(1:25));
end

function testTimeAndProgressMatchTheCommittedPart(tc)
c = [iCand(0, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, 25);
verifyEqual(tc, trunk.Time, 2.4, 'AbsTol', 1e-12);          % 24 steps of 0.1 s
verifyEqual(tc, trunk.Progress_m, 5*2.4, 'AbsTol', 1e-9);   % 5 m/s for 2.4 s
end

function testAPrefixLongerThanThePathIsClamped(tc)
c = [iCand(0, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, 999);
verifyEqual(tc, trunk.Steps, 41);
verifySize(tc, trunk.States, [41 3]);
end

function testTheRuleUsedIsNamedInTheOutput(tc)
% Two readings of "trunk" are live. A log that does not say which one produced a
% number is not evidence.
c = [iCand(0, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, 25);
verifyTrue(tc, contains(trunk.Rule, "reading A"));
verifyTrue(tc, strlength(trunk.Reason) > 0);
end

% ---------------------------------------------------------------- blocked

function testAShortTrunkCountsAsBlocked(tc)
c = [iCand(0, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, 3, minTrunkTime_s=0.5);   % 0.2 s only
verifyTrue(tc, trunk.Blocked);
verifyTrue(tc, isnan(trunk.CandidateIndex));
verifyEqual(tc, trunk.Steps, 0);
end

function testALowerMinimumLetsTheSameTrunkThrough(tc)
c = [iCand(0, 5, 41, 0.1)];
trunk = sih.planner.findSharedTrunk(c, 3, minTrunkTime_s=0.1);
verifyFalse(tc, trunk.Blocked);
verifyEqual(tc, trunk.Steps, 3);
end

function testNoCandidatesAtAllIsBlockedNotAnError(tc)
proto = iCand(0, 5, 41, 0.1);
empty = proto([]);
trunk = sih.planner.findSharedTrunk(empty(:), zeros(0,1));
verifyTrue(tc, trunk.Blocked);
verifySize(tc, trunk.States, [0 3]);
end

% ---------------------------------------------------------------- guards

function testMismatchedSizesError(tc)
c = [iCand(0, 5, 41, 0.1); iCand(3, 5, 41, 0.1)];
verifyError(tc, @() sih.planner.findSharedTrunk(c, 30), ...
            'sih:planner:findSharedTrunk:sizeMismatch');
end
