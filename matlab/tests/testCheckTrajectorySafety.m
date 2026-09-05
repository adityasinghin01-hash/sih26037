function tests = testCheckTrajectorySafety
%TESTCHECKTRAJECTORYSAFETY  Unit tests for D6 piece 3, one path vs one future.
%
%   RUN IT:   results = runtests('matlab/tests/testCheckTrajectorySafety.m'); disp(results)
%   Needs Navigation Toolbox (dynamicCapsuleList). No Simulink.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function c = iStraightCandidate(speed_mps, horizon_s, dt)
% Ego runs straight along +x at a constant speed from the origin.
t = (0:dt:horizon_s)';
c = struct('LateralOffset_m',0,'TerminalSpeed_mps',speed_mps,'Horizon_s',horizon_s, ...
           'Times', t, ...
           'States',[speed_mps*t, zeros(numel(t),1), zeros(numel(t),1)]);
end

function t = iTrack(pos, vel, yaw)
t = struct('TrackID', uint32(11), ...
           'ClassID', uint8(1), ...
           'Position',[pos 0], ...
           'Velocity',[vel 0], ...
           'Extent',  [4.5 1.8 1.5], ...
           'Yaw',     yaw, ...
           'Existence',0.9, ...
           'Age',     uint32(30), ...
           'SensorMask', uint8(3));
end

% ---------------------------------------------------------------- clear road

function testEmptyRoadIsSafeAllTheWay(tc)
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([30 50], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(2));
verifyTrue(tc, r.AllSafe);
verifyTrue(tc, all(r.Safe));
verifyTrue(tc, isnan(r.FirstUnsafeIndex));
verifyTrue(tc, isnan(r.FirstUnsafeTime));
verifyEqual(tc, r.SafePrefixSteps, numel(cand.Times));
end

function testOneResultPerTimestep(tc)
% Pins the shape this whole function is built on. Verified by running, 4 Sep 2026.
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([30 50], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(2));
verifyEqual(tc, numel(r.Safe),  numel(cand.Times));
verifyEqual(tc, numel(r.Times), numel(cand.Times));
end

% ---------------------------------------------------------------- blocked road

function testParkedCarOnThePathIsCaught(tc)
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([20 0], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(2));
verifyFalse(tc, r.AllSafe);
verifyFalse(tc, isnan(r.FirstUnsafeIndex));
verifyLessThan(tc, r.SafePrefixSteps, numel(cand.Times));
end

function testTheHitHappensAboutWhenTheGeometrySaysItShould(tc)
% Ego at 8 m/s, parked car centred at x = 20. The bodies touch a little before
% the centres would meet at 2.5 s, so the first unsafe moment must be under that
% and not wildly early.
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([20 0], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(2));
verifyLessThan(tc,    r.FirstUnsafeTime, 2.5);
verifyGreaterThan(tc, r.FirstUnsafeTime, 1.0);
end

function testThePrefixIsTheUnbrokenRunBeforeTheFirstHit(tc)
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([20 0], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(2));
k = r.SafePrefixSteps;
verifyTrue(tc, all(r.Safe(1:k)));
verifyFalse(tc, r.Safe(k+1));
verifyEqual(tc, r.FirstUnsafeIndex, k+1);
end

function testPrefixTimeMatchesPrefixSteps(tc)
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([20 0], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(2));
verifyEqual(tc, r.SafePrefixTime, r.Times(r.SafePrefixSteps) - r.Times(1), 'AbsTol', 1e-12);
end

% ------------------------------------------------- the two futures differ

function testYieldingCarIsSafeWhereAssertingCarIsNot(tc)
% A crossing: ego runs +x at 8 m/s; the other vehicle runs +y at 8 m/s from
% (30,-30), so if it presses on the two meet near (30,0) at about t = 3.75 s.
% If it brakes at -2 m/s^2 it covers only 16 m in the horizon and never arrives.
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([30 -30], [0 8], pi/2), 0.5, true);
rYield  = sih.planner.checkTrajectorySafety(cand, f(1));
rAssert = sih.planner.checkTrajectorySafety(cand, f(2));
verifyTrue(tc,  rYield.AllSafe,  'the yielding future should be clear');
verifyFalse(tc, rAssert.AllSafe, 'the asserting future should collide');
verifyGreaterThan(tc, rYield.SafePrefixSteps, rAssert.SafePrefixSteps);
end

function testLabelAndTrackIDAreCarriedThrough(tc)
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([30 50], [0 0], 0), 0.5, true);
r    = sih.planner.checkTrajectorySafety(cand, f(1));
verifyEqual(tc, r.Label,   "YIELD");
verifyEqual(tc, r.TrackID, uint32(11));
end

% ---------------------------------------------------------------- margins

function testInflatingTheBodiesNeverMakesThingsLookSafer(tc)
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([30 -30], [0 8], pi/2), 0.5, true);
tight = sih.planner.checkTrajectorySafety(cand, f(2));
loose = sih.planner.checkTrajectorySafety(cand, f(2), inflation_m=1.0);
verifyLessThanOrEqual(tc, loose.SafePrefixSteps, tight.SafePrefixSteps);
end

function testAWiderBodyCanTurnAClearPathIntoABlockedOne(tc)
% Other vehicle sitting one lane over. A normal car squeezes past; add two
% metres of margin all round and it does not.
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([20 2.6], [0 0], 0), 0.5, true);
narrow = sih.planner.checkTrajectorySafety(cand, f(2));
wide   = sih.planner.checkTrajectorySafety(cand, f(2), inflation_m=2.0);
verifyTrue(tc,  narrow.AllSafe);
verifyFalse(tc, wide.AllSafe);
end

% ---------------------------------------------------------------- clocks

function testAShorterFutureHoldsItsLastPoseInsteadOfVanishing(tc)
% The future runs out after 1 s but the parked car has not gone anywhere, so the
% ego must still be told it hits it later than that.
cand = iStraightCandidate(8, 4, 0.1);
f    = sih.planner.predictAgentFutures(iTrack([20 0], [0 0], 0), 0.5, true, horizon_s=1);
verifyEqual(tc, numel(f(2).Times), 11);
r = sih.planner.checkTrajectorySafety(cand, f(2));
verifyFalse(tc, r.AllSafe);
verifyGreaterThan(tc, r.FirstUnsafeTime, 1.0);
end

% ---------------------------------------------------------------- integration

function testItAcceptsARealCandidateFromTheGenerator(tc)
refPath = referencePathFrenet([0 0; 25 0; 50 0; 100 0]);
ego     = struct('Position',[0 0 0],'Velocity',[8 0 0],'Yaw',0);
cands   = sih.planner.generateCandidates(ego, refPath, ...
              lateralOffsets_m=[0 3], terminalSpeeds_mps=8);
f       = sih.planner.predictAgentFutures(iTrack([25 0], [0 0], 0), 0.5, true);
straightOn = cands(arrayfun(@(x) x.LateralOffset_m == 0, cands));
goAround   = cands(arrayfun(@(x) x.LateralOffset_m == 3, cands));
rStraight = sih.planner.checkTrajectorySafety(straightOn(1), f(2));
rAround   = sih.planner.checkTrajectorySafety(goAround(1),   f(2));
verifyFalse(tc, rStraight.AllSafe, 'driving straight into a parked car should not be safe');
verifyTrue(tc,  rAround.AllSafe,   'pulling 3 m left should clear it');
end

% ---------------------------------------------------------------- guards

function testMissingCandidateFieldErrors(tc)
cand = rmfield(iStraightCandidate(8, 4, 0.1), 'States');
f    = sih.planner.predictAgentFutures(iTrack([30 50], [0 0], 0), 0.5, true);
verifyError(tc, @() sih.planner.checkTrajectorySafety(cand, f(2)), ...
            'sih:planner:checkTrajectorySafety:missingField');
end

function testEmptyCandidateErrors(tc)
cand = iStraightCandidate(8, 4, 0.1);
cand.Times  = [];
cand.States = zeros(0,3);
f = sih.planner.predictAgentFutures(iTrack([30 50], [0 0], 0), 0.5, true);
verifyError(tc, @() sih.planner.checkTrajectorySafety(cand, f(2)), ...
            'sih:planner:checkTrajectorySafety:emptyCandidate');
end
