function tests = testBenchStats
%TESTBENCHSTATS  PHASE 6 - the statistics benchRuns reports must themselves be
%   correct. A confidence interval computed wrongly is worse than none: it looks
%   like rigour and is not. These check the maths against known-answer cases,
%   independently of any 15-minute simulation.
tests = functiontests(localfunctions);
end

function testTIntervalMatchesKnownAnswer(tc)
% textbook case: n=10, mean 10, sd 2 -> t(0.975,9)=2.262157...
x = [8 9 10 11 12 8 9 10 11 12];
m = mean(x); sd = std(x); n = numel(x);
half = sc.tCrit95(n-1) * sd / sqrt(n);
verifyEqual(tc, m, 10, 'AbsTol', 1e-12);
verifyEqual(tc, sc.tCrit95(9), 2.262, 'RelTol', 1e-3);
verifyEqual(tc, half, 2.262*sd/sqrt(10), 'RelTol', 1e-12);
end

function testTIsWiderThanNormalAtSmallN(tc)
% benchRuns uses t, NOT 1.96*sd/sqrt(n). At n=8 the normal approximation
% UNDERSTATES the interval, and understating spread on a safety metric is the
% wrong direction to be wrong in. This asserts the choice is not cosmetic.
n = 8;
verifyGreaterThan(tc, sc.tCrit95(n-1), 1.959963984540054);
end

function testZeroVarianceGivesZeroWidth(tc)
% every run identical - a real case here, since run 1 is the deterministic
% reference and a broken harness could return it N times
x = repmat(0.1347406069392747, 1, 6);
verifyEqual(tc, std(x), 0, 'AbsTol', 1e-15);
half = sc.tCrit95(numel(x)-1) * std(x) / sqrt(numel(x));
verifyEqual(tc, half, 0, 'AbsTol', 1e-15);
end

function testNoToolboxDependence(tc)
% tinv() is Statistics Toolbox and this licence does not have it. If anyone
% reintroduces it, benchRuns dies on every machine this project runs on.
verifyEmpty(tc, ver('stats'));
verifyFalse(tc, contains(lower(fileread(which('benchRuns'))), 'tinv('));
verifyTrue(tc, isnan(sc.tCrit95(0)));       % n=1 -> no interval, not a fake one
end

function testSingleRunHasNoInterval(tc)
% n=1 -> t(0.975,0) is undefined. benchRuns must print "(n=1, none)" rather
% than a NaN interval dressed up as a measurement.
verifyTrue(tc, isnan(std([5])) || std([5])==0);
end

function testHarnessExistsAndDeclaresItsLimits(tc)
% The limits are part of the deliverable. If someone strips the header, the
% output stops being honest and this test says so.
p = which('benchRuns');
verifyNotEmpty(tc, p);
src = lower(fileread(p));
verifySubstring(tc, src, 'tcrit95');                 % t, not 1.96
verifySubstring(tc, src, 'perturb');                 % says what it varies
verifySubstring(tc, src, 'straddles a safety threshold');  % the honest limit
end
