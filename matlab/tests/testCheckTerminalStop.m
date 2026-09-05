function tests = testCheckTerminalStop
%TESTCHECKTERMINALSTOP  Unit tests for the check that turns trunk (a) into (b).
%
%   RUN IT:   results = runtests('matlab/tests/testCheckTerminalStop.m'); disp(results)
%   Needs the Navigation Toolbox for dynamicCapsuleList, but no Simulink. Every
%   candidate and future here is hand-built.
%
%   Tested against hand-constructed candidates and futures; not yet validated
%   against World data.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function c = iCand(v, n, dt)
% A straight candidate along +x at a constant speed.
t = (0:n-1)' * dt;
c = struct('LateralOffset_m', 0, 'TerminalSpeed_mps', v, 'Horizon_s', (n-1)*dt, ...
           'Times', t, 'States', [v*t, zeros(n,1), zeros(n,1)]);
end

function f = iFuture(x0, y0, vx, n, dt, label)
% A road user driving along +x from (x0,y0).
t = (0:n-1)' * dt;
f = struct('TrackID', uint32(7), 'Label', string(label), 'Probability', 0.5, ...
           'Valid', true, 'Times', t, ...
           'States', [x0 + vx*t, repmat(y0,n,1), zeros(n,1)], ...
           'Speeds', repmat(vx,n,1), 'Extent', [4.5 1.8 1.5]);
end

function f = iParkedFuture(x0, y0)
% Something standing still, far off the candidate's line unless stated.
f = iFuture(x0, y0, 0, 41, 0.1, "ASSERT");
end

% ---------------------------------------------------------------- the geometry

function testAnEmptyRoadLetsUsStop(tc)
r = sih.planner.checkTerminalStop(iCand(5,41,0.1), iParkedFuture(500, 50), 20);
verifyTrue(tc, r.Safe);
end

function testTheStopDistanceIsTheTextbookOne(tc)
% v^2 / 2a, solved rather than integrated, so a stop is a stop.
v = 8; a = 4;
r = sih.planner.checkTerminalStop(iCand(v,41,0.1), iParkedFuture(500,50), 20, ...
                                  aBrake_mps2 = a);
verifyEqual(tc, r.StopSpeed_mps,  v,           'AbsTol', 1e-9);
verifyEqual(tc, r.StopDistance_m, v^2/(2*a),   'AbsTol', 1e-9);
verifyEqual(tc, r.StopDuration_s, v/a,         'AbsTol', 1e-9);
end

function testHarderBrakingStopsShorter(tc)
soft = sih.planner.checkTerminalStop(iCand(8,41,0.1), iParkedFuture(500,50), 20, aBrake_mps2 = 2);
hard = sih.planner.checkTerminalStop(iCand(8,41,0.1), iParkedFuture(500,50), 20, aBrake_mps2 = 8);
verifyLessThan(tc, hard.StopDistance_m, soft.StopDistance_m);
end

function testTheStopStartsWhereTheCandidateIs(tc)
c = iCand(5,41,0.1);
r = sih.planner.checkTerminalStop(c, iParkedFuture(500,50), 20);
verifyEqual(tc, r.StopStates(1,1:2), c.States(20,1:2), 'AbsTol', 1e-12);
verifyEqual(tc, r.StopTimes(1),      c.Times(20),      'AbsTol', 1e-12);
end

function testTheStopNeverGoesBackwards(tc)
% Braking past zero would drive the car in reverse. The distance must be
% monotonic and must flatten, not turn round.
r = sih.planner.checkTerminalStop(iCand(6,41,0.1), iParkedFuture(500,50), 30, ...
                                  dwellAfterStop_s = 2);
x = r.StopStates(:,1);
verifyGreaterThanOrEqual(tc, min(diff(x)), -1e-12);
verifyEqual(tc, x(end) - x(1), r.StopDistance_m, 'AbsTol', 1e-9);
end

function testAStandingCarStillGetsARealIntervalChecked(tc)
% Zero speed means zero stopping distance, but standing still is not the same as
% not being checked - something can still drive into a stopped car.
c = iCand(0, 41, 0.1);
r = sih.planner.checkTerminalStop(c, iParkedFuture(500,50), 10);
verifyEqual(tc, r.StopDistance_m, 0);
verifyGreaterThanOrEqual(tc, numel(r.StopTimes), 2);
end

% ---------------------------------------------------------------- the point of it

function testAPrefixThatIsClearButCannotStopIsCaught(tc)
% This is the whole reason reading (b) exists. The candidate is clear along its
% whole length up to step 20, but something is parked just past where braking
% from there would put us.
c = iCand(8, 41, 0.1);
stopEndsAt = c.States(20,1) + 8^2/(2*4);
blocker = iParkedFuture(stopEndsAt, 0);
r = sih.planner.checkTerminalStop(c, blocker, 20);
verifyFalse(tc, r.Safe);
verifyTrue(tc, isfinite(r.FirstUnsafeTime));
end

function testStoppingEarlierCanBeSafeWhereStoppingLaterIsNot(tc)
% And this is why the search walks BACK rather than giving up: a shorter prefix
% can still have a clear stop when a longer one does not.
c = iCand(8, 41, 0.1);
blocker = iParkedFuture(c.States(20,1) + 8^2/(2*4), 0);
late  = sih.planner.checkTerminalStop(c, blocker, 20);
early = sih.planner.checkTerminalStop(c, blocker, 2);
verifyFalse(tc, late.Safe);
verifyTrue(tc, early.Safe);
end

function testSlowerMeansAShorterStopAndSoMoreRoom(tc)
% Same blocker, same start step. The slow candidate stops before reaching it.
blockAt = 40;
fast = sih.planner.checkTerminalStop(iCand(12,41,0.1), iParkedFuture(blockAt,0), 20);
slow = sih.planner.checkTerminalStop(iCand(1, 41,0.1), iParkedFuture(blockAt,0), 20);
verifyLessThan(tc, slow.StopDistance_m, fast.StopDistance_m);
verifyTrue(tc, slow.Safe);
end

function testDwellCanTurnASafeStopIntoAnUnsafeOne(tc)
% Stopping IS clear; standing there while a car drives through is not. The
% stricter reading is available, and it is not the default.
c = iCand(2, 41, 0.1);
% Something arriving later at where the stop ends.
stopEndsAt = c.States(10,1) + 2^2/(2*4);
comer = iFuture(stopEndsAt + 25, 0, -5, 41, 0.1, "ASSERT");
brief = sih.planner.checkTerminalStop(c, comer, 10, dwellAfterStop_s = 0);
long_ = sih.planner.checkTerminalStop(c, comer, 10, dwellAfterStop_s = 6);
verifyTrue(tc, brief.Safe);
verifyFalse(tc, long_.Safe);
end

% ---------------------------------------------------------------- bookkeeping

function testItSaysWhoseFutureItChecked(tc)
r = sih.planner.checkTerminalStop(iCand(5,41,0.1), iParkedFuture(500,50), 20);
verifyEqual(tc, r.TrackID, uint32(7));
verifyEqual(tc, r.Label, "ASSERT");
verifyEqual(tc, r.StartIndex, 20);
end

function testAClearStopHasNoFirstUnsafeTime(tc)
r = sih.planner.checkTerminalStop(iCand(5,41,0.1), iParkedFuture(500,50), 20);
verifyTrue(tc, isnan(r.FirstUnsafeTime));
end

% ---------------------------------------------------------------- bad input

function testStartingPastTheEndErrors(tc)
verifyError(tc, @() sih.planner.checkTerminalStop(iCand(5,41,0.1), iParkedFuture(500,50), 99), ...
            'sih:planner:checkTerminalStop:startBeyondEnd');
end

function testASinglePointCandidateErrors(tc)
c = iCand(5, 41, 0.1);
c.Times = c.Times(1); c.States = c.States(1,:);
verifyError(tc, @() sih.planner.checkTerminalStop(c, iParkedFuture(500,50), 1), ...
            'sih:planner:checkTerminalStop:candidateTooShort');
end

function testMismatchedLengthsError(tc)
c = iCand(5, 41, 0.1);
c.Times = c.Times(1:end-1);
verifyError(tc, @() sih.planner.checkTerminalStop(c, iParkedFuture(500,50), 5), ...
            'sih:planner:checkTerminalStop:sizeMismatch');
end

function testMissingFieldErrors(tc)
c = rmfield(iCand(5,41,0.1), 'States');
verifyError(tc, @() sih.planner.checkTerminalStop(c, iParkedFuture(500,50), 5), ...
            'sih:planner:checkTerminalStop:missingField');
end

function testSameInputGivesSameAnswer(tc)
a = sih.planner.checkTerminalStop(iCand(5,41,0.1), iParkedFuture(500,50), 20);
b = sih.planner.checkTerminalStop(iCand(5,41,0.1), iParkedFuture(500,50), 20);
verifyEqual(tc, a, b);
end
