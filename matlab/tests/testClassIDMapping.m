function tests = testClassIDMapping
%TESTCLASSIDMAPPING  Guard the S5 -> drivingScenario ClassID map.
%
%   runtests('matlab/tests/testClassIDMapping')
%
%   AGENTS.md section 3 S5 says NEVER RENUMBER and never hardcode either numbering. The
%   collision between the two schemes is silent: an auto-rickshaw written straight into a
%   scenario becomes a PEDESTRIAN and a motorbike becomes a JERSEY BARRIER, with no error.
%   These tests exist so that can never happen unnoticed.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
% <repo>/matlab/tests -> <repo>, then add <repo>/matlab so the +sih package resolves.
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, 'matlab'));
tc.TestData = struct();
end

function testTheDangerousOnes(tc)
% The three that motivate the whole function. If any of these regress, actors in every
% scenario silently become the wrong kind of object.
tc.verifyEqual(sih.util.toSimClassID(4), uint8(1), ...
    'auto-rickshaw (S5 4) must NOT stay 4 - sim 4 is Pedestrian');
tc.verifyEqual(sih.util.toSimClassID(5), uint8(3), ...
    'motorbike (S5 5) must NOT stay 5 - sim 5 is a Jersey Barrier');
tc.verifyEqual(sih.util.toSimClassID(8), uint8(4), ...
    'pedestrian (S5 8) must map to sim 4');
end

function testEveryS5ValueMaps(tc)
for cid = 0:15
    [simID, simName] = sih.util.toSimClassID(cid);
    tc.verifyClass(simID, 'uint8');
    tc.verifyLessThanOrEqual(simID, uint8(6), ...
        sprintf('S5 %d mapped to %d - drivingScenario only reserves 0-6', cid, simID));
    tc.verifyNotEmpty(char(simName));
end
end

function testVectorInputKeepsShape(tc)
in = [0 1 4 5 10 15];
out = sih.util.toSimClassID(in);
tc.verifyEqual(size(out), size(in));
tc.verifyEqual(out, uint8([0 1 1 3 4 5]));
end

function testOutOfRangeErrors(tc)
% 16 is not in S5. It must fail loudly rather than silently becoming something.
tc.verifyError(@() sih.util.toSimClassID(16), 'sih:util:badClassID');
end

function testCowScoresAtPedestrianWeight(tc)
% M4 scores animals at CARLA's pedestrian weight of 1.00, so the cow mapping to Pedestrian
% is deliberate and consistent with the metric. If someone changes it to Unknown, the
% metric and the scenario stop agreeing.
tc.verifyEqual(sih.util.toSimClassID(10), uint8(4), 'cow must map to Pedestrian - see M4');
end

function testClassNamesMatchesS5Order(tc)
[names, ids] = sih.util.classNames();
tc.verifyEqual(numel(names), 16);
tc.verifyEqual(ids, uint8(0:15));
tc.verifyEqual(names(5), "auto-rickshaw", 'S5 ClassID 4 is auto-rickshaw');
tc.verifyEqual(names(11), "cow", 'S5 ClassID 10 is cow');
end
