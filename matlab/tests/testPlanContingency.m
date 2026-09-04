function tests = testPlanContingency
%TESTPLANCONTINGENCY  Unit tests for D6 piece 5, one whole planning cycle.
%
%   RUN IT:   results = runtests('matlab/tests/testPlanContingency.m'); disp(results)
%   Needs Navigation Toolbox. No Simulink - which is the point of the A/B split.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
tc.TestData.refPath = referencePathFrenet([0 0; 25 0; 50 0; 100 0]);
tc.TestData.ego     = struct('Position',[0 0 0],'Velocity',[8 0 0],'Yaw',0);
end

% ---------------------------------------------------------------- fixtures

function t = iTrack(id, pos, vel, yaw)
t = struct('TrackID', uint32(id), 'ClassID', uint8(1), ...
           'Position',[pos 0], 'Velocity',[vel 0], ...
           'Extent',  [4.5 1.8 1.5], 'Yaw', yaw, ...
           'Existence',0.9, 'Age', uint32(30), 'SensorMask', uint8(3));
end

function t = iNoTracks()
proto = iTrack(1, [0 0], [0 0], 0);
t = proto([]);
end

function y = iYield(ids, p, valid)
y = struct('TrackIDs', uint32(ids(:)), 'PYield', p(:), 'Valid', logical(valid(:)));
end

function y = iNoYield()
y = iYield([], [], []);
end

% ---------------------------------------------------------------- empty world

function testAnEmptyTrackListDoesNotErrorAndCommitsTheWholePlan(tc)
% S1 guarantee 3: the track list may be empty and consumers must not error.
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iNoTracks(), iNoYield(), lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyEqual(tc, out.NumTracks, 0);
verifyEmpty(tc, out.Futures);
verifyFalse(tc, out.Blocked);
verifyEqual(tc, out.Trunk.Steps, 41);
end

function testAnEmptyWorldStillProducesAFanOfCandidates(tc)
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iNoTracks(), iNoYield());
verifyGreaterThan(tc, numel(out.Candidates), 1);
end

% ---------------------------------------------------------------- shape

function testTwoFuturesPerRoadUser(tc)
tracks = [iTrack(1,[40 0],[0 0],0); iTrack(2,[30 -30],[0 8],pi/2)];
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          tracks, iYield([1 2],[0.6 0.4],[true true]), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyEqual(tc, out.NumTracks, 2);
verifyNumElements(tc, out.Futures, 4);
verifyEqual(tc, [out.Futures.Label], ["YIELD" "ASSERT" "YIELD" "ASSERT"]);
end

function testSafeStepsIsCandidatesByFutures(tc)
tracks = iTrack(1,[40 0],[0 0],0);
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          tracks, iYield(1, 0.6, true), ...
          lateralOffsets_m=[0 3], terminalSpeeds_mps=8);
verifySize(tc, out.SafeSteps, [numel(out.Candidates) numel(out.Futures)]);
end

% ---------------------------------------------------------- the worst future wins

function testTheWorstFutureSetsEachCandidatesLength(tc)
tracks = [iTrack(1,[30 -30],[0 8],pi/2); iTrack(2,[60 0],[0 0],0)];
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          tracks, iYield([1 2],[0.6 0.5],[true true]), ...
          lateralOffsets_m=[0 3], terminalSpeeds_mps=[3 8]);
verifyEqual(tc, out.WorstPrefixSteps, min(out.SafeSteps,[],2));
end

function testTheBindingFutureIsNamedWhenSomethingBinds(tc)
tracks = iTrack(1,[20 0],[0 0],0);
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          tracks, iYield(1, 0.6, true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyFalse(tc, isnan(out.BindingFuture(1)));
verifyLessThan(tc, out.WorstPrefixSteps(1), numel(out.Candidates(1).Times));
end

function testNothingBindsOnAClearRoad(tc)
tracks = iTrack(1,[40 60],[0 0],0);           % parked far off to one side
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          tracks, iYield(1, 0.6, true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyTrue(tc, isnan(out.BindingFuture(1)));
end

% ---------------------------------------------------------------- the trunk

function testAParkedCarAheadShortensTheTrunk(tc)
clear1 = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
             iNoTracks(), iNoYield(), lateralOffsets_m=0, terminalSpeeds_mps=8);
blocked = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
             iTrack(1,[20 0],[0 0],0), iYield(1,0.6,true), ...
             lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyLessThan(tc, blocked.Trunk.Steps, clear1.Trunk.Steps);
end

function testTheTrunkNeverExceedsWhatIsSafe(tc)
tracks = [iTrack(1,[30 -30],[0 8],pi/2); iTrack(2,[45 1],[0 0],0)];
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          tracks, iYield([1 2],[0.6 0.5],[true false]));
k = out.Trunk.CandidateIndex;
verifyLessThanOrEqual(tc, out.Trunk.Steps, out.WorstPrefixSteps(k));
end

function testSomethingRightInFrontLeavesUsBlocked(tc)
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(1,[5 0],[0 0],0), iYield(1,0.6,true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8, minTrunkTime_s=0.5);
verifyTrue(tc, out.Blocked);
verifyEqual(tc, out.Blocked, out.Trunk.Blocked);
end

% ---------------------------------------------------------- the yield prediction

function testAValidPredictionIsCarriedThroughAsAWeight(tc)
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(1,[40 0],[0 0],0), iYield(1, 0.75, true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyEqual(tc, out.Futures(1).Probability, 0.75, 'AbsTol', 1e-12);
verifyEqual(tc, out.Futures(2).Probability, 0.25, 'AbsTol', 1e-12);
end

function testAnInvalidPredictionGivesNaNNotAHalf(tc)
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(1,[40 0],[0 0],0), iYield(1, 0.75, false), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyTrue(tc, isnan(out.Futures(1).Probability));
verifyTrue(tc, isnan(out.Futures(2).Probability));
end

function testATrackMissingFromThePredictionIsTreatedAsInvalid(tc)
% Track 9 is not in S3 at all. It must still get both futures, planned against
% just as hard, and must never be given a made-up probability.
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(9,[40 0],[0 0],0), iYield(1, 0.75, true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyNumElements(tc, out.Futures, 2);
verifyTrue(tc, isnan(out.Futures(1).Probability));
verifyFalse(tc, out.Futures(1).Valid);
end

function testAnUnpredictedTrackIsStillPlannedAgainst(tc)
% The weight is missing, the danger is not. Safety must not depend on S3.
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(9,[20 0],[0 0],0), iNoYield(), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyLessThan(tc, out.WorstPrefixSteps(1), numel(out.Candidates(1).Times));
end

% ---------------------------------------------------------------- guards

function testMissingYieldFieldErrors(tc)
bad = rmfield(iYield(1, 0.5, true), 'Valid');
verifyError(tc, @() sih.planner.planContingency(tc.TestData.ego, ...
            tc.TestData.refPath, iTrack(1,[40 0],[0 0],0), bad), ...
            'sih:planner:planContingency:missingField');
end

% ------------------------------------------------- reading (b), the terminal stop

function testModeAIsTheDefaultAndSaysSo(tc)
% Nobody should have to guess which reading produced a trunk. Person B's chart
% reads .TrunkMode to know whether Committed is allowed to go true.
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iNoTracks(), iNoYield(), lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyEqual(tc, out.TrunkMode, "A");
verifyEqual(tc, out.Trunk.Rule, "LONGEST_CLEAR_PREFIX (reading A)");
end

function testModeBNamesItselfDifferently(tc)
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(1,[60 0],[0 0],0), iYield(1,0.5,true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8, trunkMode="B");
verifyEqual(tc, out.TrunkMode, "B");
verifyEqual(tc, out.Trunk.Rule, "STOP_FEASIBLE_PREFIX (reading B)");
end

function testModeACostsNoTerminalChecks(tc)
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iTrack(1,[60 0],[0 0],0), iYield(1,0.5,true), ...
          lateralOffsets_m=0, terminalSpeeds_mps=8);
verifyEqual(tc, out.StopChecks, 0);
verifyEqual(tc, out.TerminalPrefixSteps, out.WorstPrefixSteps);
end

function testModeBNeverCommitsMoreThanModeA(tc)
% (b) is (a) plus an extra requirement, so it can only ever cut the prefix back.
% If it were ever longer, the extra requirement would not be a requirement.
tracks = iTrack(1,[45 0],[0 0],0);
yield  = iYield(1,0.5,true);
a = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, tracks, yield, ...
        lateralOffsets_m=[-3 0 3], terminalSpeeds_mps=[0 4 8]);
b = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, tracks, yield, ...
        lateralOffsets_m=[-3 0 3], terminalSpeeds_mps=[0 4 8], trunkMode="B");
verifyLessThanOrEqual(tc, b.TerminalPrefixSteps, a.WorstPrefixSteps);
verifyLessThanOrEqual(tc, b.Trunk.Steps, a.Trunk.Steps);
end

function testModeBActuallyCutsBackWhenStoppingIsBlocked(tc)
% A car parked squarely ahead, placed in the window that separates the two
% readings. The ego does 8 m/s for 4 s, so the candidate ends near x = 32 and is
% clear the whole way - reading (a) commits all 41 steps. Braking from 8 m/s at
% 4 m/s^2 takes another 8 m, which puts the stop at x = 40, right on top of it.
% So reading (b) MUST cut back. Move the car much further out and there is
% nothing to catch; much nearer and (a) is cut too and the test proves nothing.
tracks = iTrack(1,[42 0],[0 0],0);
yield  = iYield(1,0.5,true);
a = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, tracks, yield, ...
        lateralOffsets_m=0, terminalSpeeds_mps=8);
b = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, tracks, yield, ...
        lateralOffsets_m=0, terminalSpeeds_mps=8, trunkMode="B");
verifyLessThan(tc, b.TerminalPrefixSteps(1), a.WorstPrefixSteps(1));
verifyGreaterThan(tc, b.StopChecks, 0);
end

function testModeBCostsOneCheckPerFutureWhenTheEndAlreadyWorks(tc)
% The ruling says (b) is one extra check per candidate. On an open road the very
% end of the (a) prefix already stops cleanly, so the walk-back never runs.
tracks = iTrack(1,[30 -60],[0 0],pi/2);          % well off to the side
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, tracks, ...
          iYield(1,0.5,true), lateralOffsets_m=0, terminalSpeeds_mps=8, trunkMode="B");
verifyEqual(tc, out.StopChecks, numel(out.Candidates) * numel(out.Futures));
end

function testModeBWithNoRoadUsersChangesNothing(tc)
% With nothing to hit, there is nothing a stop could be blocked by, so (b) must
% agree with (a) exactly rather than being conservative for its own sake.
out = sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
          iNoTracks(), iNoYield(), lateralOffsets_m=0, terminalSpeeds_mps=8, trunkMode="B");
verifyEqual(tc, out.TerminalPrefixSteps, out.WorstPrefixSteps);
verifyEqual(tc, out.Trunk.Steps, 41);
end

function testAnUnknownTrunkModeIsRefused(tc)
verifyError(tc, @() sih.planner.planContingency(tc.TestData.ego, tc.TestData.refPath, ...
                    iNoTracks(), iNoYield(), trunkMode="C"), ...
            'MATLAB:validators:mustBeMember');
end
