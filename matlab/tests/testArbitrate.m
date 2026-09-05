function tests = testArbitrate
%TESTARBITRATE  Unit tests for multi-agent arbitration: many road users, one command.
%
%   RUN IT:   results = runtests('matlab/tests/testArbitrate.m'); disp(results)
%   Needs no toolboxes beyond base MATLAB, and no Simulink. Most roles here are
%   hand-built so the CHOOSING rule is tested and nothing else; the last section
%   drives the real sih.planner.assignRoles so the two are known to fit together.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- fixtures

function r = iRole(id, roleCode, lambda, beta)
% One Role (S4). h = lambda - beta, so pick the two to place h where you want it.
r = struct('TrackID', uint32(id), 'Role', uint8(roleCode), ...
           'Beta', beta, 'Lambda', lambda, 'TCPA', 1.0);
end

function r = iNoRoles()
proto = iRole(0,0,0,0);
r = proto([]);
end

function t = iTrack(id, pos, vel, yaw)
t = struct('TrackID', uint32(id), 'ClassID', uint8(1), ...
           'Position', [pos 0], 'Velocity', [vel 0], 'Extent', [4.5 1.8 1.5], ...
           'Yaw', yaw, 'Existence', 1.0, 'Age', uint32(10), 'SensorMask', uint8(1));
end

% ---------------------------------------------------------------- the choosing rule

function testTheSmallestBarrierWins(tc)
% h = lambda - beta. Agent 2 has h = 0.1, the others 0.9 and 0.5, so agent 2 is the
% most dangerous and is the one chooseVelocity must be asked about.
roles = [iRole(1, 2, 1.0, 0.1); iRole(2, 1, 0.4, 0.3); iRole(3, 3, 0.7, 0.2)];
[winner, k, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, k, 2);
verifyEqual(tc, winner, uint8(1));            % agent 2's role code, GIVE_WAY
verifyEqual(tc, info.TrackID, uint32(2));
verifyEqual(tc, info.H, 0.1, 'AbsTol', 1e-12);
verifyEqual(tc, info.NumConsidered, 3);
end

function testANegativeBarrierBeatsEveryPositiveOne(tc)
% h < 0 is a barrier violation - S8 calls it EMERGENCY. It must never lose to an
% agent that is merely close.
roles = [iRole(1, 2, 0.30, 0.29); iRole(2, 3, 0.20, 0.50)];
[~, k, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, k, 2);
verifyLessThan(tc, info.H, 0);
end

function testTheWinnerIsNotJustTheNearestOrTheFirst(tc)
% The first agent in the list is the safe one. Choosing by list order would pick it.
roles = [iRole(7, 0, 1.5, 0.1); iRole(8, 1, 0.2, 0.15)];
[winner, k] = sih.planner.arbitrate(roles);
verifyEqual(tc, k, 2);
verifyEqual(tc, winner, uint8(1));
end

function testOneAgentIsChosenWithoutFuss(tc)
roles = iRole(4, 3, 0.6, 0.2);
[winner, k, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, k, 1);
verifyEqual(tc, winner, uint8(3));
verifyEqual(tc, info.NumConsidered, 1);
end

% ---------------------------------------------------------------- ties

function testATieGoesToTheLowestTrackIDNotTheListOrder(tc)
% Two symmetric cars at a crossroads give exactly equal h. This is the ordinary
% case, not a freak one. The higher ID is deliberately placed FIRST, so a function
% that just took min()'s index would fail here.
roles = [iRole(9, 1, 0.5, 0.2); iRole(3, 2, 0.5, 0.2)];
[winner, k, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, k, 2);
verifyEqual(tc, info.TrackID, uint32(3));
verifyEqual(tc, winner, uint8(2));
end

function testTheSameSceneInADIFFERENTORDERGivesTheSameAnswer(tc)
% Repeatability is the whole reason the tie-break exists. Perception decides list
% order; we must not. Same two agents, both orders, same TrackID chosen.
a = [iRole(9, 1, 0.5, 0.2); iRole(3, 2, 0.5, 0.2)];
b = [iRole(3, 2, 0.5, 0.2); iRole(9, 1, 0.5, 0.2)];
[~, ~, infoA] = sih.planner.arbitrate(a);
[~, ~, infoB] = sih.planner.arbitrate(b);
verifyEqual(tc, infoA.TrackID, infoB.TrackID);
end

function testATieSaysSoInItsReason(tc)
roles = [iRole(9, 1, 0.5, 0.2); iRole(3, 2, 0.5, 0.2)];
[~, ~, info] = sih.planner.arbitrate(roles);
verifySubstring(tc, char(info.Reason), 'tied');
end

% ---------------------------------------------------------------- the empty road

function testAnEmptyRoadIsNotAnError(tc)
% AGENTS.md section 3, S1 guarantee 3: the TrackList may be empty and consumers
% must not error.
[winner, k, info] = sih.planner.arbitrate(iNoRoles());
verifyEqual(tc, winner, uint8(0));            % SAFE
verifyEmpty(tc, k);
verifyTrue(tc, isnan(info.H));
verifyEqual(tc, info.NumConsidered, 0);
end

function testAnEmptyRoadGivesNoWinnerToIndexWith(tc)
% The caller is told to check isempty(k) before taking vos(k). Pin that k really is
% empty, because a 0 or a 1 here would silently hand chooseVelocity the wrong agent.
[~, k] = sih.planner.arbitrate(iNoRoles());
verifyTrue(tc, isempty(k));
end

% ---------------------------------------------------------------- unusable geometry

function testAgentsWithNaNBarriersNeverWinByAccident(tc)
% MATLAB's min() ignores NaN. Pin that, because the opposite behaviour would make
% an agent we know nothing about outrank one we can actually see.
roles = [iRole(1, 1, NaN, NaN); iRole(2, 2, 0.9, 0.1)];
[~, k, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, k, 2);
verifyEqual(tc, info.TrackID, uint32(2));
end

function testAllNaNIsNoWinnerAndSaysWhy(tc)
% Knowing nothing about everybody is NOT the same as the road being clear, so this
% must be distinguishable in the log from the empty-road case.
roles = [iRole(1, 1, NaN, NaN); iRole(2, 2, NaN, NaN)];
[winner, k, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, winner, uint8(0));
verifyEmpty(tc, k);
verifyEqual(tc, info.NumConsidered, 2);       % 2, not 0 - that is the difference
verifySubstring(tc, char(info.Reason), 'NaN');
end

% ------------------------------------------- telling the two no-winner cases apart

function testAnEmptyRoadAndAnUnKNOWABLERoadAreDistinguishableWithoutStrings(tc)
% Both return winner = SAFE, and they mean opposite things. Person B wires a chart
% transition, not a string parser, so the difference has to be readable as numbers.
empty   = iNoRoles();
unknown = [iRole(1, 1, NaN, NaN); iRole(2, 2, NaN, NaN)];

[~, ~, e] = sih.planner.arbitrate(empty);
[~, ~, u] = sih.planner.arbitrate(unknown);

verifyEqual(tc, e.NumConsidered, 0);
verifyEqual(tc, u.NumConsidered, 2);          % agents WERE there
verifyEqual(tc, e.NumUsable, 0);
verifyEqual(tc, u.NumUsable, 0);
verifyFalse(tc, e.AllUnknown);                % nobody there is not "unknown"
verifyTrue(tc,  u.AllUnknown);
end

function testWinnerAloneCannotTellThemApartWhichIsWHYTheFlagsExist(tc)
% Pin the hazard itself. If this ever stops being true the header is out of date.
[w1, k1] = sih.planner.arbitrate(iNoRoles());
[w2, k2] = sih.planner.arbitrate([iRole(1,1,NaN,NaN); iRole(2,2,NaN,NaN)]);
verifyEqual(tc, w1, w2);                      % identical - that is the problem
verifyEmpty(tc, k1);
verifyEmpty(tc, k2);
end

function testNumUsableCountsOnlyTheAgentsWeCanActuallyMeasure(tc)
roles = [iRole(1, 1, NaN, NaN); iRole(2, 2, 0.9, 0.1); iRole(3, 1, 0.5, 0.2)];
[~, ~, info] = sih.planner.arbitrate(roles);
verifyEqual(tc, info.NumConsidered, 3);
verifyEqual(tc, info.NumUsable, 2);
verifyFalse(tc, info.AllUnknown);
end

function testAllUnknownIsFalseWheneverAnyoneIsMeasurable(tc)
roles = [iRole(1, 1, NaN, NaN); iRole(2, 2, 0.9, 0.1)];
[~, ~, info] = sih.planner.arbitrate(roles);
verifyFalse(tc, info.AllUnknown);
end

% ---------------------------------------------------------------- guards

function testAMissingFieldIsRefusedByName(tc)
bad = rmfield(iRole(1, 1, 0.5, 0.2), 'Lambda');
verifyError(tc, @() sih.planner.arbitrate(bad), ...
            'sih:planner:arbitrate:missingField');
end

% ---------------------------------------------------------------- fits the real chain

function testItAcceptsWhatAssignRolesActuallyReturns(tc)
% The fixtures above are hand-built, and hand-built fixtures have hidden a real bug
% on this project before. Drive the genuine assignRoles output through it.
tracks = [iTrack(5, [20  0], [-8 0], pi); ...
          iTrack(6, [30 25], [ 0 0], 0)];
[roles, vos] = sih.planner.assignRoles([0 0], [8 0], 0, tracks);
[winner, k, info] = sih.planner.arbitrate(roles);
verifyNotEmpty(tc, k);
verifyEqual(tc, winner, uint8(roles(k).Role));
verifyEqual(tc, info.TrackID, roles(k).TrackID);
verifyEqual(tc, info.H, vos(k).h, 'AbsTol', 1e-12);   % the vo agrees with the role
end

function testTheWholeChainReachesAnEgoCommand(tc)
% The point of the function: many road users in, ONE command out. If this breaks,
% the three pieces no longer fit and Person B's chart cannot call them.
tracks = [iTrack(5, [20  0], [-8 0], pi); ...
          iTrack(6, [30 25], [ 0 0], 0)];
ego    = struct('Position',[0 0 0], 'Velocity',[8 0 0], 'Yaw',0);
[roles, vos] = sih.planner.assignRoles([0 0], [8 0], 0, tracks);
[winner, k]  = sih.planner.arbitrate(roles);
cmd = sih.planner.chooseVelocity(winner, vos(k), ego);
verifyTrue(tc, isstruct(cmd));
verifyTrue(tc, isfield(cmd,'Accel') && isfield(cmd,'SteerAngle'));
verifyTrue(tc, isstring(cmd.Reason));
end
