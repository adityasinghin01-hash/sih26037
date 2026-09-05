function tests = testEscapeMemory
%TESTESCAPEMEMORY  Unit tests for D9 part 1: remember where you could turn around.
%
%   RUN IT:   results = runtests('matlab/tests/testEscapeMemory.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink. S9 structs are
%   hand-built, which plan/D6-TRUNK-RULING.md rules is the way to build D8-D10 while
%   the World does not exist.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function s = iSpace(edgeDistance, valid)
% S9 DrivableSpace. EdgeDistance is to the NEAREST edge, so the width is twice it.
s = struct('EdgeDistance', edgeDistance, 'EdgeSide', uint8(0), ...
           'VisibleRange', 50, 'Valid', valid);
end

function e = iEgo(x, y, yaw)
e = struct('Position', [x y 0], 'Velocity', [3 0 0], 'Yaw', yaw);
end

function m = iEmpty()
m = struct();
end

% A road wide enough to turn round in one sweep needs 2*Rmin + body = about 10 m,
% so an EdgeDistance of 6 gives 12 m and is comfortably wide; 2 gives 4 m and is not.
function s = iWide(),   s = iSpace(6, true);  end
function s = iNarrow(), s = iSpace(2, true);  end

% ---------------------------------------------------------------- dropping breadcrumbs

function testAWideSpotIsRemembered(tc)
out = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iWide());
verifyTrue(tc, out.OneSweepHere);
verifyTrue(tc, out.Recorded);
verifyEqual(tc, out.Count, 1);
verifyEqual(tc, out.Points, [0 0]);
end

function testANarrowGalliIsNotRemembered(tc)
out = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iNarrow());
verifyFalse(tc, out.OneSweepHere);
verifyFalse(tc, out.Recorded);
verifyEqual(tc, out.Count, 0);
end

function testTheBarIsONESWEEPNotMerelyPossible(tc)
% A three-point turn in a blocked galli with a queue behind is not an escape. The
% width just under the one-sweep threshold must be refused, not recorded as "tight".
here  = sih.planner.planTurn(struct('GoalHeading',pi,'Valid',true), iEgo(0,0,0));
just  = here.RequiredWidth_m;                       % exactly enough
under = just - 1;

verifyTrue(tc,  sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iSpace(just/2,  true)).Recorded);
verifyFalse(tc, sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iSpace(under/2, true)).Recorded);
end

function testTheMemoryIsCarriedForwardWhenFedBackIn(tc)
m = sih.planner.escapeMemory(iEmpty(),  iEgo(0,0,0),  iWide());
m = sih.planner.escapeMemory(m,         iEgo(20,0,0), iWide());
verifyEqual(tc, m.Count, 2);
verifyEqual(tc, m.Points, [0 0; 20 0]);
end

function testTwoBreadcrumbsTooCloseTogetherBecomeOne(tc)
% At 10 Hz an unspaced memory is hundreds of points a metre apart all saying the
% same thing, and the list is walked every step.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iWide());
m = sih.planner.escapeMemory(m,        iEgo(1,0,0), iWide());     % 1 m on
verifyEqual(tc, m.Count, 1);
verifySubstring(tc, char(m.Reason), 'could turn here');
end

function testTheMemoryNeverGrowsWithoutBound(tc)
m = iEmpty();
for k = 1:8
    m = sih.planner.escapeMemory(m, iEgo(20*k,0,0), iWide(), maxPoints = 3);
end
verifyEqual(tc, m.Count, 3);
verifyEqual(tc, m.Points(end,:), [160 0]);          % newest kept
verifyEqual(tc, m.Points(1,:),   [120 0]);          % oldest dropped
end

% ---------------------------------------------------------------- an unmeasured road

function testAnInvalidS9RecordsNothingAndSaysWhy(tc)
% A remembered escape that was never really there is worse than no memory, because
% the car drives to it while blocked.
out = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iSpace(6, false));
verifyFalse(tc, out.Recorded);
verifyFalse(tc, out.OneSweepHere);
verifyTrue(tc, isnan(out.LocalWidth_m));
verifySubstring(tc, char(out.Reason), 'never measured');
end

function testAnInvalidS9DoesNotDestroyWhatWasAlreadyRemembered(tc)
% Losing sight of the edge is not the same as the escape points ceasing to exist.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0),  iWide());
m = sih.planner.escapeMemory(m,        iEgo(20,0,0), iSpace(6, false));
verifyEqual(tc, m.Count, 1);
end

% ---------------------------------------------------------------- looking back

function testTheNearestEscapeBEHINDIsFound(tc)
m = iEmpty();
m = sih.planner.escapeMemory(m, iEgo(0,0,0),  iWide());
m = sih.planner.escapeMemory(m, iEgo(30,0,0), iWide());
m = sih.planner.escapeMemory(m, iEgo(60,0,0), iNarrow());   % now here, nothing recorded
verifyTrue(tc, m.HasEscape);
verifyEqual(tc, m.NearestPoint, [30 0]);
verifyEqual(tc, m.NearestDistance_m, 30, 'AbsTol', 1e-9);
end

function testABreadcrumbAHEADIsNotAnEscape(tc)
% Driving further forward to reach it is the manoeuvre we are trying to avoid.
m = sih.planner.escapeMemory(iEmpty(), iEgo(50,0,0), iWide());
m = sih.planner.escapeMemory(m,        iEgo(0,0,0),  iNarrow());
verifyFalse(tc, m.HasEscape);
verifyTrue(tc, isnan(m.NearestDistance_m));
end

function testBehindIsRelativeToWHERETHECARPOINTS(tc)
% Same breadcrumb, car turned round. What was behind is now ahead.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0),  iWide());
fwd = sih.planner.escapeMemory(m, iEgo(30,0,0), iNarrow());
rev = sih.planner.escapeMemory(m, iEgo(30,0,pi), iNarrow());
verifyTrue(tc,  fwd.HasEscape);
verifyFalse(tc, rev.HasEscape);
end

function testNoMemoryAtAllIsNotAnError(tc)
out = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iNarrow());
verifyFalse(tc, out.HasEscape);
verifyEqual(tc, out.Count, 0);
end

% ---------------------------------------------------------------- nose to nose

function testTheCarNEARERAPassingPlaceReverses(tc)
% plan/D-planner.md D9. Ours is 10 m back, theirs 40 m: we reverse.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0),  iWide());
m = sih.planner.escapeMemory(m, iEgo(10,0,0), iNarrow(), otherEscapeDistance_m = 40);
verifyTrue(tc, m.DeadlockDecided);
verifyTrue(tc, m.WeReverse);
verifySubstring(tc, char(m.Reason), 'we reverse');
end

function testTheCarFURTHERFromOneHolds(tc)
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0),  iWide());
m = sih.planner.escapeMemory(m, iEgo(50,0,0), iNarrow(), otherEscapeDistance_m = 5);
verifyTrue(tc, m.DeadlockDecided);
verifyFalse(tc, m.WeReverse);
verifySubstring(tc, char(m.Reason), 'they reverse');
end

function testATieDoesNotDeadlockBothCars(tc)
% Both cars run this same rule. A symmetric answer on a tie leaves two cars each
% waiting for the other, which is the deadlock the rule exists to break.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0),  iWide());
m = sih.planner.escapeMemory(m, iEgo(20,0,0), iNarrow(), otherEscapeDistance_m = 20);
verifyTrue(tc, m.WeReverse);
end

function testACarWithNowhereToGoDoesNotAgreeToReverse(tc)
% Saying "we reverse" with no escape point sends the car backwards down a galli
% with no passing place in it.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iNarrow(), otherEscapeDistance_m = 1);
verifyFalse(tc, m.HasEscape);
verifyTrue(tc, m.DeadlockDecided);
verifyFalse(tc, m.WeReverse);
end

function testNoDeadlockIsSettledUnlessOneWasAsked(tc)
% WeReverse false must not be mistaken for "they reverse" when nobody asked.
m = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iWide());
verifyFalse(tc, m.DeadlockDecided);
verifyFalse(tc, m.WeReverse);
end

% ---------------------------------------------------------------- guards and reuse

function testAMissingEgoFieldIsRefusedByName(tc)
verifyError(tc, @() sih.planner.escapeMemory(iEmpty(), struct('Position',[0 0 0]), iWide()), ...
            'sih:planner:escapeMemory:missingField');
end

function testTheWidthTestIsPlanTurnsAndNotASecondCopy(tc)
% The reuse rule: one turning-circle sum, one place. If this drifts, the escape
% memory and the turn planner will disagree about the same road.
for edge = [1.5 2.5 4 5 6 8]
    out   = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iSpace(edge, true));
    uturn = sih.planner.planTurn(struct('GoalHeading',pi,'Valid',true), iEgo(0,0,0), ...
                                 roadWidth_m = 2*edge);
    verifyEqual(tc, out.OneSweepHere, uturn.NumSegments == 1);
end
end

function testTheAssumedWidthIsReportedSoALogCanShowIt(tc)
% S9 gives a distance to one edge, not a width. The doubling is an assumption and
% it has to be visible.
out = sih.planner.escapeMemory(iEmpty(), iEgo(0,0,0), iSpace(6, true));
verifyEqual(tc, out.LocalWidth_m, 12, 'AbsTol', 1e-12);
end
