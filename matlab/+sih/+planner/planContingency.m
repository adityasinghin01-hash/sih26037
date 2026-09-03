function out = planContingency(egoState, refPath, tracks, yieldPred, opts)
%PLANCONTINGENCY  One planning cycle: fan out, imagine both futures, commit the trunk.
%
%   Task D6, piece 5 of 5. This is the function Person B's chart calls, about ten
%   times a second. Everything else in D6 is a helper it drives.
%
%   THE CYCLE, IN ORDER
%     1. sih.planner.generateCandidates    the fan of paths for us      (piece 2)
%     2. sih.planner.predictAgentFutures   two futures per road user    (piece 1)
%     3. sih.planner.checkTrajectorySafety every path against every future (piece 3)
%     4. sih.planner.findSharedTrunk       how far we actually commit   (piece 4)
%     5. throw the rest away and do it again next cycle
%
%   WHY THE WORST FUTURE WINS
%   A candidate's committable length is the MINIMUM of its safe length across
%   every future of every road user. Not the average, not the probability-weighted
%   value. Safety cannot be traded against likelihood: a stretch that is only safe
%   if the cow yields is not safe. PYield ranks and explains; it never permits.
%
%   WHY PYield IS ONLY A LABEL HERE
%   AGENTS.md section 3, S3: when Valid is false the planner uses the geometric
%   role alone, never 0.5. A track with no prediction, or an invalid one, still
%   gets both futures - it is planned against just as hard. The weight is carried
%   through for logging and for D5's evidence, and is deliberately not used to
%   decide anything in this function.
%
%   INPUTS
%     egoState  (1,1) struct  .Position (1x3, m), .Velocity (1x3, m/s), .Yaw (rad)
%     refPath   (1,1) referencePathFrenet   the route centreline (S10)
%     tracks    struct array   S1 TrackList. MAY BE EMPTY and must not error -
%                              S1 guarantee 3
%     yieldPred (1,1) struct   S3 YieldPrediction: .TrackIDs, .PYield, .Valid.
%                              A track missing from it is treated as invalid
%     opts.lateralOffsets_m    passed to piece 2, default [-3 -1.5 0 1.5 3]
%     opts.terminalSpeeds_mps  passed to piece 2, default [0 2 5 8]
%     opts.horizon_s           shared by pieces 1 and 2, default 4.0
%     opts.timeResolution_s    shared by pieces 1 and 2, default 0.1
%     opts.yieldDecel_mps2     passed to piece 1, default -2.0
%     opts.assertAccel_mps2    passed to piece 1, default  0.0
%     opts.egoLength_m         passed to piece 3, default 4.7
%     opts.egoWidth_m          passed to piece 3, default 1.8
%     opts.inflation_m         passed to piece 3, default 0.0
%     opts.minTrunkTime_s      passed to piece 4, default 0.5
%
%   OUTPUT  out struct
%     .Trunk             the committed plan, from findSharedTrunk. Read .Blocked
%     .Candidates        Nx1 the whole fan, kept so D5 can log what was rejected
%     .Futures           Mx1 every future of every road user, 2 per track
%     .SafeSteps         NxM double, safe leading steps per candidate per future
%     .WorstPrefixSteps  Nx1 double, the minimum of each row - what piece 4 reads
%     .BindingFuture     Nx1 double, which future limited each candidate. NaN if
%                        the candidate was safe under all of them
%     .NumTracks         double
%     .Blocked           logical, copied out of .Trunk for the caller's convenience
%
%   WHAT THIS DOES NOT SET
%   No Accel, no SteerAngle, no Signal, no Committed. This produces a committed
%   PATH; turning that into one EgoCommand is D2 and the Stateflow chart. Keeping
%   them apart is what lets the trunk be tested in seconds without Simulink.
%
%   TODO(performance): with 20 candidates and 3 road users this builds 120
%   dynamicCapsuleList objects per cycle. It has never been timed. Measure before
%   optimising - the barrier layer underneath runs at 50-100 Hz and can veto
%   anything, which is exactly why deliberation here is allowed to be slow.
%
%   See also SIH.PLANNER.GENERATECANDIDATES, SIH.PLANNER.PREDICTAGENTFUTURES,
%            SIH.PLANNER.CHECKTRAJECTORYSAFETY, SIH.PLANNER.FINDSHAREDTRUNK

arguments
    egoState  (1,1) struct
    refPath   (1,1) referencePathFrenet
    tracks          struct
    yieldPred (1,1) struct
    opts.lateralOffsets_m   (1,:) double = [-3 -1.5 0 1.5 3]
    opts.terminalSpeeds_mps (1,:) double = [0 2 5 8]
    opts.horizon_s          (1,1) double {mustBePositive} = 4.0
    opts.timeResolution_s   (1,1) double {mustBePositive} = 0.1
    opts.yieldDecel_mps2    (1,1) double {mustBeFinite} = -2.0
    opts.assertAccel_mps2   (1,1) double {mustBeFinite} =  0.0
    opts.egoLength_m        (1,1) double {mustBePositive} = 4.7
    opts.egoWidth_m         (1,1) double {mustBePositive} = 1.8
    opts.inflation_m        (1,1) double {mustBeNonnegative} = 0.0
    opts.minTrunkTime_s     (1,1) double {mustBeNonnegative} = 0.5
end

iRequireFields(yieldPred, {'TrackIDs','PYield','Valid'}, 'yieldPred');

% ---- 1. our own options ------------------------------------------------------
candidates = sih.planner.generateCandidates(egoState, refPath, ...
    lateralOffsets_m   = opts.lateralOffsets_m, ...
    terminalSpeeds_mps = opts.terminalSpeeds_mps, ...
    horizon_s          = opts.horizon_s, ...
    timeResolution_s   = opts.timeResolution_s);

nC = numel(candidates);

% ---- 2. two futures for every road user --------------------------------------
nT = numel(tracks);
futures = iEmptyFutureArray();
for k = 1:nT
    [pY, isValid] = iLookupYield(yieldPred, tracks(k).TrackID);
    f = sih.planner.predictAgentFutures(tracks(k), pY, isValid, ...
            horizon_s        = opts.horizon_s, ...
            timeResolution_s = opts.timeResolution_s, ...
            yieldDecel_mps2  = opts.yieldDecel_mps2, ...
            assertAccel_mps2 = opts.assertAccel_mps2);
    futures = [futures; f(:)];  %#ok<AGROW>  at most 2 per track
end
nF = numel(futures);

% ---- 3. every candidate against every future ---------------------------------
safeSteps = zeros(nC, nF);
for k = 1:nC
    for j = 1:nF
        r = sih.planner.checkTrajectorySafety(candidates(k), futures(j), ...
                egoLength_m = opts.egoLength_m, ...
                egoWidth_m  = opts.egoWidth_m, ...
                inflation_m = opts.inflation_m);
        safeSteps(k,j) = r.SafePrefixSteps;
    end
end

% The worst future wins. With no road users at all, every candidate is safe for
% its whole length - which is the right answer, not a special case.
worst   = zeros(nC,1);
binding = nan(nC,1);
for k = 1:nC
    full = numel(candidates(k).Times);
    if nF == 0
        worst(k) = full;
    else
        [worst(k), idx] = min(safeSteps(k,:));
        if worst(k) < full
            binding(k) = idx;
        end
    end
end

% ---- 4. how far we commit ----------------------------------------------------
trunk = sih.planner.findSharedTrunk(candidates(:), worst, ...
            minTrunkTime_s = opts.minTrunkTime_s);

out = struct( ...
    'Trunk',            trunk, ...
    'Candidates',       candidates(:), ...
    'Futures',          futures, ...
    'SafeSteps',        safeSteps, ...
    'WorstPrefixSteps', worst, ...
    'BindingFuture',    binding, ...
    'NumTracks',        nT, ...
    'Blocked',          trunk.Blocked);
end

% ------------------------------------------------------------------ helpers

function [pY, isValid] = iLookupYield(yieldPred, trackID)
%ILOOKUPYIELD  S3 for one track. Absent counts as invalid, never as a guess.
idx = find(uint32(yieldPred.TrackIDs(:)) == uint32(trackID), 1, 'first');
if isempty(idx)
    pY = NaN; isValid = false;
    return
end
isValid = logical(yieldPred.Valid(idx));
if isValid
    pY = double(yieldPred.PYield(idx));
else
    pY = NaN;
end
end

function f = iEmptyFutureArray()
proto = struct('TrackID',uint32(0),'Label',"",'Probability',NaN,'Valid',false, ...
               'Times',zeros(0,1),'States',zeros(0,3),'Speeds',zeros(0,1), ...
               'Extent',zeros(1,3));
f = proto([]);
f = f(:);
end

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:planContingency:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
