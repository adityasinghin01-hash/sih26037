function tests = testGateYield
%TESTGATEYIELD  The gate must be CLOSED unless every condition is positively met.
tests = functiontests(localfunctions);
end

function t = trk(varargin)
t = struct('Position',[10 0 0],'Velocity',[5 0 0],'Age',uint32(50),'ClassID',uint8(3));
for k = 1:2:numel(varargin), t.(varargin{k}) = varargin{k+1}; end
end
function c = cfg()
c = struct('Band',[0.1 0.9],'BandEvidence',"held-out validation, hypothetical");
end

function testClosedByDefault(tc)
[d, why] = sih.prediction.gateYield(trk(), 0.99, struct());
verifyEqual(tc, d, "FALLBACK");
verifySubstring(tc, char(why), 'no validated confidence band');
end
function testBandWithoutEvidenceIsRefused(tc)
c = struct('Band',[0.1 0.9]);
verifyEqual(tc, sih.prediction.gateYield(trk(), 0.99, c), "FALLBACK");
end
function testOpensWhenEverythingIsMet(tc)
verifyEqual(tc, sih.prediction.gateYield(trk(), 0.99, cfg()), "USE");
verifyEqual(tc, sih.prediction.gateYield(trk(), 0.01, cfg()), "USE");
end
function testUncertainBandFallsBack(tc)
verifyEqual(tc, sih.prediction.gateYield(trk(), 0.50, cfg()), "FALLBACK");
end
function testShortHistoryFallsBack(tc)
verifyEqual(tc, sih.prediction.gateYield(trk('Age',uint32(5)), 0.99, cfg()), "FALLBACK");
end
function testNonNegotiatingClassFallsBack(tc)
% a cow does not yield - asking the model is a category error
verifyEqual(tc, sih.prediction.gateYield(trk('ClassID',uint8(10)), 0.99, cfg()), "FALLBACK");
end
function testNonFiniteInputsFallBack(tc)
verifyEqual(tc, sih.prediction.gateYield(trk(), NaN, cfg()), "FALLBACK");
verifyEqual(tc, sih.prediction.gateYield(trk('Position',[NaN 0 0]), 0.99, cfg()), "FALLBACK");
verifyEqual(tc, sih.prediction.gateYield(trk('Velocity',[Inf 0 0]), 0.99, cfg()), "FALLBACK");
end
function testProbabilityOutOfRangeFallsBack(tc)
verifyEqual(tc, sih.prediction.gateYield(trk(), 1.5, cfg()), "FALLBACK");
verifyEqual(tc, sih.prediction.gateYield(trk(), -0.1, cfg()), "FALLBACK");
end
