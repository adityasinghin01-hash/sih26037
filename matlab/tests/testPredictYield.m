function tests = testPredictYield
%TESTPREDICTYIELD  Unit tests for sih.prediction.predictYield (Step 99).
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
root = fileparts(fileparts(here));
addpath(fullfile(root, 'matlab'));
end

function testEmptyInput(tc)
y = sih.prediction.predictYield(uint32.empty(0, 1), double.empty(0, 1));
tc.verifyTrue(isfield(y, 'TrackIDs'));
tc.verifyTrue(isfield(y, 'PYield'));
tc.verifyTrue(isfield(y, 'Valid'));
tc.verifyEqual(numel(y.TrackIDs), 0);
tc.verifyEqual(numel(y.PYield), 0);
tc.verifyEqual(numel(y.Valid), 0);
end

function testPYieldComputation(tc)
ids = uint32([101; 102; 103]);
pAssert = [0.1; 0.8; 0.0];
y = sih.prediction.predictYield(ids, pAssert, true);
tc.verifyEqual(y.TrackIDs, ids);
tc.verifyEqual(y.PYield, [0.9; 0.2; 1.0], 'AbsTol', 1e-6);
tc.verifyEqual(y.Valid, [true; true; true]);
end

function testStep98FailsafeDefault(tc)
% Because Step 98 failed the 1% bound, default must always be Valid = false
ids = uint32([1; 2]);
pAssert = [0.01; 0.5];
y = sih.prediction.predictYield(ids, pAssert);
tc.verifyEqual(y.Valid, [false; false]);
end

function testDimensionMismatchErrors(tc)
tc.verifyError(@() sih.prediction.predictYield(uint32([1; 2]), [0.5]), ...
    'sih:prediction:predictYield:dimensionMismatch');
end
