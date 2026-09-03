function tests = testNegotiatingStrategy
%TESTNEGOTIATINGSTRATEGY  Regression tests for the OpenTrafficLab subclass (D3 scaffold).
%
%   RUN IT:   results = runtests('matlab/tests/testNegotiatingStrategy.m'); disp(results)
%
%   THESE TESTS NEED OPENTRAFFICLAB, WHICH IS NOT IN THIS REPOSITORY.
%   It is third-party and gitignored on purpose. Without it every test here reports as
%   INCOMPLETE (skipped), never as failed - a missing optional dependency is not a broken
%   repository. To enable them:
%       git clone https://github.com/mathworks/OpenTrafficLab.git
%
%   WHAT THIS FILE EXISTS TO STOP COMING BACK
%   Five defects, all of which were silent or fatal, all found on 4 September 2026:
%     1. the class would not load at all - two overrides widened the superclass access
%     2. determineDrivingMode returned a uint8 where the base class switches on a char,
%        so carFollowing() errored on the very first step
%     3. updateUDStates appended to Data.Time, which addData also appends to, so the
%        safety log had two time entries per step and could not be plotted
%     4. the ego was in its own TrackList, pinning h at -pi/2 on every step of every run
%     5. the drivingScenario ClassID (0-6) was written into the S5 ClassID field (0-15)
%
%   See also SIH.PLANNER.NEGOTIATINGSTRATEGY

tests = functiontests(localfunctions);
end

% ------------------------------------------------------------------ fixture

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
repoRoot = fullfile(here, '..', '..');
addpath(fullfile(repoRoot, 'matlab'));

tc.TestData.Ready  = false;
tc.TestData.Reason = "";

otl = fullfile(repoRoot, 'OpenTrafficLab');
if ~isfolder(otl)
    tc.TestData.Reason = "OpenTrafficLab is not cloned - see the header of this file";
    return
end
addpath(genpath(otl));

if isempty(which('createTJunctionScenario'))
    tc.TestData.Reason = "OpenTrafficLab is present but createTJunctionScenario is not on the path";
    return
end

try
    tc.TestData = iRunScenario(tc.TestData);
    tc.TestData.Ready = true;
catch ME
    % Never let a setup failure masquerade as a planner bug. Report it in full.
    tc.TestData.Reason = string(sprintf('%s: %s', ME.identifier, ME.message));
end
end

function d = iRunScenario(d)
%IRUNSCENARIO  One short T-junction run with the central controller REMOVED.
%   No trafficControl.TrafficLight is created. That deletion is the whole point of D3:
%   an Indian junction has no referee, so each vehicle decides from geometry alone.

s   = createTJunctionScenario();
net = createTJunctionNetwork(s);
s.StopTime   = 20;
s.SampleTime = 0.05;

fnc  = @(varargin) sih.planner.NegotiatingStrategy(varargin{:}, 'CarFollowingModel', 'Gipps');
% Dense enough that vehicles actually share a segment and see each other -
% otherwise every TrackList is empty and the tests below skip without testing.
cars = createVehiclesForTJunction(s, net, [900 900 900], [40 60], fnc);

% R2026a: DrivingStrategy's constructor sets IsVisible false, and R2026a returns a NaN pose
% for an invisible actor. drivingScenario.setUpSensorSimulation then rejects the whole
% actor set with ssf:sensorsim:invalidActorsAddedToSensorSim before step one. Making them
% visible up front is a HARNESS fix, not a planner fix - see plan/OPENTRAFFICLAB-R2026a.md.
for c = cars
    c.IsVisible = true;
end

d.Steps = 0;
while advance(s)
    d.Steps = d.Steps + 1;
end

d.Cars     = cars;
d.Scenario = s;
end

function iNeedScenario(tc)
assumeTrue(tc, tc.TestData.Ready, ...
    "skipped - " + tc.TestData.Reason);
end

% ------------------------------------------------------- defect 1: it must load

function testClassLoadsAndOverridesKeepSuperclassAccess(tc)
% MATLAB refuses to load a subclass that changes an override's Access. The superclass
% declares both UDStates hooks inside methods (Access = protected), so ours must be too.
%   MATLAB:class:methodOverrideAccess
if isempty(which('DrivingStrategy'))
    assumeFail(tc, "OpenTrafficLab is not on the path");
end
mc = meta.class.fromName('sih.planner.NegotiatingStrategy');
verifyNotEmpty(tc, mc, 'the class did not resolve at all');

for name = ["initializeUDStates", "updateUDStates"]
    m = findobj(mc.MethodList, 'Name', char(name));
    verifyNotEmpty(tc, m, sprintf('%s is missing', name));
    verifyEqual(tc, string(m(1).Access), "protected", ...
        sprintf('%s must stay protected to match DrivingStrategy', name));
end
end

function testReferencePointExistsForR2026a(tc)
% driving.scenario.Vehicle reads MotionStrategy.ReferencePoint unconditionally in R2026a.
% Without it, advance() dies with MATLAB:noSuchMethodOrField before the first step.
if isempty(which('DrivingStrategy'))
    assumeFail(tc, "OpenTrafficLab is not on the path");
end
mc = meta.class.fromName('sih.planner.NegotiatingStrategy');
p  = findobj(mc.PropertyList, 'Name', 'ReferencePoint');
verifyNotEmpty(tc, p, ...
    'ReferencePoint is required by R2026a - see plan/OPENTRAFFICLAB-R2026a.md');
end

% ------------------------------------------------- defect 2: the loop must close

function testSimulationRunsEndToEnd(tc)
% The base class switches on a CHAR mode with no otherwise branch. Returning our uint8
% S8 PlannerMode left leaderSpacing and delVel unassigned and carFollowing() errored on
% step one - so "defers to the base class so the simulation still runs" was not true.
iNeedScenario(tc);
verifyGreaterThan(tc, tc.TestData.Steps, 100, ...
    'the scenario should advance for many steps without erroring');
end

function testPlannerModeIsNeverWrittenIntoTheBaseClassMode(tc)
% obj.Mode belongs to DrivingStrategy and must stay one of its three strings.
% Our S8 mode lives in PlannerMode. Two different axes, two different fields.
iNeedScenario(tc);
valid = {'CarFollowing', 'ApproachingRedLight', 'ApproachingGreenLight'};
for c = tc.TestData.Cars
    ms = c.MotionStrategy;
    if isempty(ms.Mode), continue; end
    verifyTrue(tc, ischar(ms.Mode) || isstring(ms.Mode), ...
        'DrivingStrategy.Mode must stay a char - see the class header');
    verifyTrue(tc, ismember(char(ms.Mode), valid), ...
        sprintf('unexpected base Mode "%s"', char(ms.Mode)));
    verifyTrue(tc, isa(ms.PlannerMode, 'uint8'), 'PlannerMode is S8 and must be uint8');
end
end

% --------------------------------------- defect 3: the safety log must be plottable

function testBarrierLogHasExactlyOneEntryPerTimeStep(tc)
% h = lambda - beta is our safety evidence. It is logged through the base class's
% UDStates mechanism so addData keeps it aligned with Data.Time. Appending to Data.Time
% from updateUDStates gave it two entries per step while every other array got one -
% and addData's own guard still passed, so it failed silently.
iNeedScenario(tc);
checked = 0;
for c = tc.TestData.Cars
    ms = c.MotionStrategy;
    if isempty(ms.Data.Time), continue; end
    checked = checked + 1;
    verifyEqual(tc, size(ms.Data.UDStates, 1), numel(ms.Data.Time), ...
        sprintf(['actor %d: the barrier log and the time vector must be the same ' ...
                 'length, or h cannot be plotted against time'], c.ActorID));
end
verifyGreaterThan(tc, checked, 0, 'no actor logged any data - the run did nothing');
end

% ------------------------------------- defect 4: the ego is not one of its own tracks

function testEgoIsNeverInItsOwnTrackList(tc)
% S1 guarantee 2. getVehiclesInSegment() returns Node.Vehicles, which includes us -
% the base class's own getLeader proves it (selfIdx = find(drivers == obj)).
iNeedScenario(tc);
for c = tc.TestData.Cars
    trk = c.MotionStrategy.LastTracks;
    if isempty(trk), continue; end
    verifyFalse(tc, ismember(uint32(c.ActorID), [trk.TrackID]), ...
        sprintf('actor %d appears in its own TrackList', c.ActorID));
end
end

function testBarrierIsNeverPinnedAtTheSelfCollisionValue(tc)
% With the ego in its own list, d = 0 takes velocityObstacle's d <= dMin branch and h is
% exactly -pi/2 forever: permanent EMERGENCY, and the one number the project rests on
% wrong on 100% of steps, in the direction that reads as a safety violation.
iNeedScenario(tc);
for c = tc.TestData.Cars
    ms = c.MotionStrategy;
    if isempty(ms.Data.UDStates), continue; end
    h = ms.Data.UDStates(:);
    verifyEqual(tc, sum(abs(h + pi/2) < 1e-9), 0, ...
        sprintf('actor %d logged h = -pi/2, which means it saw itself', c.ActorID));
end
end

function testBarrierIsNaNRatherThanInfWhenNoAgentIsInRange(tc)
% NaN means "h is undefined because nothing was in range", which is honest and plots as
% a gap. Inf would claim infinite safety margin and would wreck the y-axis of E4's graph.
iNeedScenario(tc);
sawSomething = false;
for c = tc.TestData.Cars
    ms = c.MotionStrategy;
    if isempty(ms.Data.UDStates), continue; end
    h = ms.Data.UDStates(:);
    verifyEqual(tc, sum(isinf(h)), 0, 'the barrier log must never contain Inf');
    sawSomething = true;
end
verifyTrue(tc, sawSomething, 'no barrier data was logged at all');
end

% ------------------------------- defect 5: S5 numbering is not drivingScenario numbering

function testTrackClassIDIsNotTheScenarioNumbering(tc)
% sih.util.toSimClassID maps S5 (0-15) onto drivingScenario (0-6) and is LOSSY and
% ONE-WAY - sixteen of ours fold into seven of theirs. Copying a.ClassID straight across
% would silently turn a scenario Bicycle (sim 3) into an S5 bus, and a Pedestrian (sim 4)
% into an auto-rickshaw. The stub therefore reports 0 (unknown) until Stream B supplies
% the real S5 ClassID keyed by ActorID.
iNeedScenario(tc);
seen = false;
for c = tc.TestData.Cars
    trk = c.MotionStrategy.LastTracks;
    if isempty(trk), continue; end
    seen = true;
    verifyEqual(tc, unique([trk.ClassID]), uint8(0), ...
        'the stub must report ClassID 0 rather than guess an S5 class it cannot recover');
end
assumeTrue(tc, seen, "no vehicle ever saw another vehicle in this short run");
end
