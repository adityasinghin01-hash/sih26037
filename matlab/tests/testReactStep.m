function tests = testReactStep
%TESTREACTSTEP  Phase 8. The critical test is the FIRST one: disabled must be
%   byte-identical, because every measured number in this project was taken
%   against scripted actors.
tests = functiontests(localfunctions);
end

function A = actor(cid, xy, vel)
A = struct('Row',1,'ClassID',uint8(cid),'XY',xy,'Vel',[vel 0],'Extent',[2 1 1],'YawRad',0);
end
function e = egoAt(xy), e = struct('XY',xy); end
function c = on(), c = struct('Enabled',true); end

function testDisabledIsByteIdentical(tc)
A = [actor(8,[0 0],[5 0]), actor(5,[10 0],[8 0])];
B = sc.reactStep(A, egoAt([12 0]), 0.05);          % no cfg at all
verifyEqual(tc, B, A);
B2 = sc.reactStep(A, egoAt([12 0]), 0.05, struct('Enabled',false));
verifyEqual(tc, B2, A);
end

function testPedestrianYields(tc)
A = actor(8, [0 0], [2 0]);
B = sc.reactStep(A, egoAt([3 0]), 0.05, on());
verifyLessThan(tc, norm(B.Vel(1:2)), norm(A.Vel(1:2)));
end

function testCowIgnores(tc)
% S1's entire premise. A cow that yields deletes the scenario.
A = actor(10, [0 0], [1 0]);
B = sc.reactStep(A, egoAt([2 0]), 0.05, on());
verifyEqual(tc, B.Vel, A.Vel);
end

function testDogIgnores(tc)
A = actor(11, [0 0], [1 0]);
verifyEqual(tc, sc.reactStep(A, egoAt([2 0]), 0.05, on()).Vel, A.Vel);
end

function testBusAsserts(tc)
% mass wins - a bus does not slow for a car
A = actor(3, [0 0], [8 0]);
verifyEqual(tc, sc.reactStep(A, egoAt([10 0]), 0.05, on()).Vel, A.Vel);
end

function testNoReactionWhenEgoIsBehind(tc)
A = actor(8, [0 0], [2 0]);
verifyEqual(tc, sc.reactStep(A, egoAt([-5 0]), 0.05, on()).Vel, A.Vel);
end

function testNoReactionWhenEgoIsFarOffTheLine(tc)
A = actor(8, [0 0], [2 0]);
verifyEqual(tc, sc.reactStep(A, egoAt([3 9]), 0.05, on()).Vel, A.Vel);
end

function testNeverReversesOrExceedsAuthority(tc)
A = actor(8, [0 0], [0.2 0]);
B = sc.reactStep(A, egoAt([0.25 0]), 0.05, on());
verifyGreaterThanOrEqual(tc, norm(B.Vel(1:2)), 0);      % never negative
verifyLessThanOrEqual(tc, abs(norm(B.Vel(1:2))-0.2), 1.2*0.05 + 1e-9);
end

function testReactionIsLogged(tc)
A = actor(8, [0 0], [2 0]);
[~, lg] = sc.reactStep(A, egoAt([3 0]), 0.05, on());
verifyNotEmpty(tc, lg.Reacted);
verifyNotEmpty(tc, lg.Reason);
verifyLessThan(tc, lg.DeltaV(1), 0);
end

function testDirectionIsPreserved(tc)
% authority covers SPEED only - never heading, never lateral
A = actor(8, [0 0], [2 0]);
B = sc.reactStep(A, egoAt([3 0]), 0.05, on());
d0 = A.Vel(1:2)/norm(A.Vel(1:2));  d1 = B.Vel(1:2)/max(norm(B.Vel(1:2)),eps);
verifyEqual(tc, d1, d0, 'AbsTol', 1e-12);
verifyEqual(tc, B.XY, A.XY);
end
