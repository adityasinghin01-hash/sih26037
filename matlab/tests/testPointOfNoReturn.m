function tests = testPointOfNoReturn
%TESTPOINTOFNORETURN  Unit tests for D9 part 2: after this, stop re-deciding.
%
%   RUN IT:   results = runtests('matlab/tests/testPointOfNoReturn.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function t = iSafeStop()
t = struct('Safe', true,  'StopDistance_m', 3, 'FirstUnsafeTime', NaN);
end

function t = iUnsafeStop()
t = struct('Safe', false, 'StopDistance_m', 3, 'FirstUnsafeTime', 1.2);
end

function t = iNeverChecked()
t = struct();                          % no .Safe field at all
end

% ---------------------------------------------------------------- the sum

function testTheHalfwayPointOnAStandingStart(tc)
% Stopped, so no braking distance. The two ways out are equal at the middle.
out = sih.planner.pointOfNoReturn(10, 0, 0, iSafeStop());
verifyEqual(tc, out.Distance_m, 5, 'AbsTol', 1e-12);
verifyFalse(tc, out.Passed);
end

function testSpeedMOVESThePointEARLIER(tc)
% The faster the car, the further stopping carries it in, and the sooner backing
% out stops being the cheaper way out. This is the whole behaviour of the sum.
slow = sih.planner.pointOfNoReturn(20, 0, 2,  iSafeStop()).Distance_m;
fast = sih.planner.pointOfNoReturn(20, 0, 10, iSafeStop()).Distance_m;
verifyLessThan(tc, fast, slow);
end

function testTheTwoWaysOutAreEqualExactlyAtThePoint(tc)
% The definition, checked directly rather than through the closed form.
L = 30; v = 6;
s = sih.planner.pointOfNoReturn(L, 0, v, iSafeStop()).Distance_m;
at = sih.planner.pointOfNoReturn(L, s, v, iSafeStop());
verifyEqual(tc, at.ForwardDistance_m, at.BackwardDistance_m, 'AbsTol', 1e-9);
end

function testTheStoppingDistanceIsTheOrdinaryOne(tc)
out = sih.planner.pointOfNoReturn(50, 0, 8, iSafeStop());
verifyEqual(tc, out.StoppingDistance_m, 8^2/(2*4.0), 'AbsTol', 1e-12);
end

function testAWiderExposurePushesThePointLater(tc)
narrow = sih.planner.pointOfNoReturn(10, 0, 5, iSafeStop()).Distance_m;
wide   = sih.planner.pointOfNoReturn(40, 0, 5, iSafeStop()).Distance_m;
verifyGreaterThan(tc, wide, narrow);
end

% ---------------------------------------------------------------- before and after

function testBeforeThePointTheCarMayStillAbort(tc)
out = sih.planner.pointOfNoReturn(30, 2, 4, iSafeStop());
verifyFalse(tc, out.Passed);
verifyFalse(tc, out.MayCommit);
verifySubstring(tc, char(out.Reason), 'may still abort');
end

function testAfterThePointTheAnswerIsStopReDeciding(tc)
% The dithering the plan names. Once past, the caller commits and holds.
out = sih.planner.pointOfNoReturn(30, 25, 4, iSafeStop());
verifyTrue(tc, out.Passed);
verifyTrue(tc, out.MayCommit);
verifySubstring(tc, char(out.Reason), 'STOP RE-DECIDING');
end

function testTheBoundaryItselfCounTSAsPassed(tc)
% At exactly s* the two costs are equal, so continuing is never worse. Committing
% on the boundary keeps the answer from flapping as the geometry jitters at 10 Hz.
s = sih.planner.pointOfNoReturn(30, 0, 4, iSafeStop()).Distance_m;
verifyTrue(tc, sih.planner.pointOfNoReturn(30, s, 4, iSafeStop()).Passed);
end

% ---------------------------------------------------------------- committed on arrival

function testEnteringTooFastMeansThereWasNeverAChoice(tc)
% Stopping needs more room than the whole exposure, so s* is negative. This is the
% case that kills, and it must be visible rather than clamped to zero.
out = sih.planner.pointOfNoReturn(5, 0, 15, iSafeStop());
verifyLessThan(tc, out.Distance_m, 0);
verifyTrue(tc, out.PassedBeforeEntry);
verifyTrue(tc, out.Passed);
verifySubstring(tc, char(out.Reason), 'never a choice');
end

function testThePointIsNotClampedAtZero(tc)
% A clamp here would report "you were free to abort at the entry line" about a car
% that never was, which is precisely the plausible wrong number this project fears.
out = sih.planner.pointOfNoReturn(4, 0, 20, iSafeStop());
verifyLessThan(tc, out.Distance_m, 0);
verifyNotEqual(tc, out.Distance_m, 0);
end

function testAnOrdinaryEntryIsNotFlaggedAsCommittedOnArrival(tc)
out = sih.planner.pointOfNoReturn(40, 0, 4, iSafeStop());
verifyFalse(tc, out.PassedBeforeEntry);
end

% ---------------------------------------------------------------- the terminal gate

function testAnUnsafeTerminalStopForbidsTheLatchEvenPastThePoint(tc)
% plan/D6-TRUNK-RULING.md: Committed stays false until the terminal braking check
% has landed. Geometry alone is not enough.
out = sih.planner.pointOfNoReturn(30, 25, 4, iUnsafeStop());
verifyTrue(tc, out.Passed);                 % the geometry still says so
verifyFalse(tc, out.MayCommit);             % but the latch stays shut
verifySubstring(tc, char(out.Reason), 'not safe');
end

function testANeverCheckedStopIsTreatedExACTLYLikeAnUnsafeOne(tc)
% An unverified stop must never read as a safe one. Forgetting to check is the
% likelier mistake than checking and getting false.
out = sih.planner.pointOfNoReturn(30, 25, 4, iNeverChecked());
verifyFalse(tc, out.TerminalChecked);
verifyFalse(tc, out.MayCommit);
verifySubstring(tc, char(out.Reason), 'never checked');
end

function testASafeStopBeforeThePointStillDoesNotPermitTheLatch(tc)
% Both conditions, not either. A safe stop is not a reason to commit early.
out = sih.planner.pointOfNoReturn(30, 1, 4, iSafeStop());
verifyFalse(tc, out.MayCommit);
end

function testThisFunctionNeverSetsCommittedItself(tc)
% Committed is Person B's, held in the chart. This may only permit.
out = sih.planner.pointOfNoReturn(30, 25, 4, iSafeStop());
verifyFalse(tc, isfield(out, 'Committed'));
verifyTrue(tc,  isfield(out, 'MayCommit'));
end

% ---------------------------------------------------------------- the invalid path

function testNoExposureIsNotAnError(tc)
out = sih.planner.pointOfNoReturn(0, 0, 5, iSafeStop());
verifyFalse(tc, out.Valid);
verifyFalse(tc, out.MayCommit);
verifyFalse(tc, out.Passed);
verifySubstring(tc, char(out.Reason), 'no exposed stretch');
end

function testANaNExposureIsSurvivable(tc)
out = sih.planner.pointOfNoReturn(NaN, 0, 5, iSafeStop());
verifyFalse(tc, out.Valid);
verifyFalse(tc, out.MayCommit);
end

function testANegativeSpeedIsRefusedRatherThanSquared(tc)
% v^2 hides the sign, so a bad input would sail straight through the sum.
out = sih.planner.pointOfNoReturn(30, 0, -5, iSafeStop());
verifyFalse(tc, out.Valid);
verifySubstring(tc, char(out.Reason), 'not a usable number');
end

function testAValidCaseSaysSo(tc)
verifyTrue(tc, sih.planner.pointOfNoReturn(30, 0, 5, iSafeStop()).Valid);
end

% ---------------------------------------------------------------- fits the rest of D

function testItBrakesAsHardAsSpeedLimitDoesAndNoHarder(tc)
% Both size a controlled stop, not an emergency one. If the two ever disagree the
% car would be told it could stop in a distance the speed law does not believe.
out = sih.planner.pointOfNoReturn(50, 0, 10, iSafeStop());
verifyEqual(tc, out.StoppingDistance_m, 10^2/(2*4.0), 'AbsTol', 1e-12);
end

function testItAcceptsWhatCheckTerminalStopActuallyReturns(tc)
% Hand-built fixtures have hidden a real bug on this project before. Drive the
% genuine checkTerminalStop output through the gate.
t  = (0:0.1:3).';
S  = [8*t, zeros(numel(t),1), zeros(numel(t),1)];
cand = struct('Times', t, 'States', S);
fut  = struct('Times', t, 'States', [200+0*t, 50+0*t, 0*t], ...
              'Extent', [4.5 1.8 1.5], 'Label', "stopped", 'Probability', 1, ...
              'Valid', true, 'TrackID', uint32(7));

term = sih.planner.checkTerminalStop(cand, fut, 1);
out  = sih.planner.pointOfNoReturn(30, 25, 4, term);

verifyTrue(tc, out.TerminalChecked);
verifyEqual(tc, out.MayCommit, out.Passed && term.Safe);
end
