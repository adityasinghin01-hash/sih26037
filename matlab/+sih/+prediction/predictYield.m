function yieldPred = predictYield(trackIDs, pAssert, isSafeGatePassed)
%PREDICTYIELD  Compute S3 YieldPrediction from assert probabilities with safety gating.
%
%   Produces an S3 YieldPrediction struct adhering to AGENTS.md Section 3:
%     .TrackIDs  [N x 1 uint32]  stable track IDs
%     .PYield    [N x 1 double]  in [0, 1], computed as 1 - P(assert)
%     .Valid     [N x 1 logical] true only when safety gate is satisfied
%
%   CRITICAL SAFETY CONTRACT (AGENTS.md Section 3, Steps 98 & 99):
%   1. PYield = 1 - P(assert) is computed exactly once at this boundary.
%   2. Because Step 98 failed the 1.00% safety bound on the untouched test
%      partition (measured 2.089% dangerous rate, 95% upper bound 2.854%),
%      the default safety gate state is FALSE.
%   3. When .Valid is false, the planner ignores .PYield completely and relies
%      exclusively on geometric velocity obstacles and safety barrier h >= 0.
%
%   INPUTS
%     trackIDs          (:, 1) uint32  track identifiers from S1 TrackList
%     pAssert           (:, 1) double  P(assert) in [0, 1] from model / Platt scaling
%     isSafeGatePassed  (1, 1) logical (optional) gate pass flag; defaults to false
%
%   OUTPUT
%     yieldPred         (1, 1) struct  S3 YieldPrediction struct:
%                         .TrackIDs [N x 1 uint32]
%                         .PYield   [N x 1 double]
%                         .Valid    [N x 1 logical]
%
%   See also sih.prediction.buildFeatureFrame, sih.planner.planContingency

arguments
    trackIDs          (:, 1) uint32
    pAssert           (:, 1) double
    isSafeGatePassed  (1, 1) logical = false
end

if numel(trackIDs) ~= numel(pAssert)
    error('sih:prediction:predictYield:dimensionMismatch', ...
        'trackIDs and pAssert must have the same number of elements.');
end

n = numel(trackIDs);
if n == 0
    yieldPred = struct(...
        'TrackIDs', uint32.empty(0, 1), ...
        'PYield',   double.empty(0, 1), ...
        'Valid',    false(0, 1));
    return;
end

% Compute PYield = 1 - P(assert) exactly once
pYield = 1.0 - pAssert;
pYield = max(0.0, min(1.0, pYield));

% When the safety gate is not passed (Step 98 outcome), Valid is false for all tracks
if ~isSafeGatePassed
    valid = false(n, 1);
else
    % Outside approved numerical bounds, invalidate individual tracks
    valid = isfinite(pYield) & (pAssert >= 0.0) & (pAssert <= 1.0);
end

yieldPred = struct(...
    'TrackIDs', uint32(trackIDs(:)), ...
    'PYield',   double(pYield(:)), ...
    'Valid',    logical(valid(:)));
end
