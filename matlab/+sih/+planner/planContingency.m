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
%   TWO READINGS OF THE TRUNK, AND opts.trunkMode PICKS ONE
%   Mode "B" IS THE DEFAULT, from 4 September 2026. It commits to the longest
%   prefix that is collision-free under every future AND that ENDS somewhere a
%   braking-to-stop is clear under every future. That is what
%   plan/D6-TRUNK-RULING.md rules the trunk actually is.
%   Mode "A" is the weaker reading - collision-free along the prefix and nothing
%   said about where it leaves us. It is kept so the two can be compared and so
%   the cost of (b) can be measured, but it must now be ASKED FOR explicitly.
%   It was the default while (b) was being built; it is not any more.
%
%   THE HARD RULE THAT COMES WITH MODE "A"
%   While trunkMode is "A", Committed MUST STAY FALSE. A prefix can be clear
%   along every metre of itself and still end in a state where every continuation
%   collides, so committing irrevocably to an (a)-trunk is committing to a
%   trajectory that has already lost. Nothing in this file sets Committed - it is
%   Person B's Stateflow chart that does - so this is a note for the chart, and
%   .TrunkMode is reported in the output precisely so the chart can obey it
%   rather than assume.
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
%     opts.trunkMode           "A" or "B", DEFAULT "B" - see the two readings above
%     opts.aBrake_mps2         the braking used by the mode "B" stop check, default 4.0
%     opts.dwellAfterStop_s    how long the stop must stay clear, default 0.0
%
%   OUTPUT  out struct
%     .Trunk             the committed plan, from findSharedTrunk. Read .Blocked
%     .Candidates        Nx1 the whole fan, kept so D5 can log what was rejected
%     .Futures           Mx1 every future of every road user, 2 per track
%     .SafeSteps         NxM double, safe leading steps per candidate per future
%     .WorstPrefixSteps  Nx1 double, the minimum of each row - reading (a)
%     .TerminalPrefixSteps Nx1 double, reading (b): the same, cut back to where a
%                        braking-to-stop is still clear. Equals .WorstPrefixSteps
%                        exactly in mode "A", so the two can be compared
%     .TrunkMode         string, "A" or "B" - WHICH READING PRODUCED THIS.
%                        Person B's chart must read it: Committed stays false
%                        while it says "A"
%     .StopChecks        double, how many terminal checks mode "B" actually cost.
%                        0 in mode "A"
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
    opts.trunkMode          (1,1) string {mustBeMember(opts.trunkMode,["A","B"])} = "B"
    opts.aBrake_mps2        (1,1) double {mustBePositive} = 4.0
    opts.dwellAfterStop_s   (1,1) double {mustBeNonnegative} = 0.0
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

% ---- 3b. can we still stop from the end of that prefix? ----------------------
% This is the whole difference between reading (a) and reading (b). Under (a) a
% prefix only has to be clear ALONG itself; under (b) it must also END somewhere
% a braking-to-stop is clear under every future. Skipped entirely in mode "A",
% so the (a) path costs exactly what it did before.
terminal   = worst;
stopChecks = 0;
if opts.trunkMode == "B" && nF > 0
    for k = 1:nC
        terminal(k) = 0;
        % Walk back from the (a) prefix and take the FIRST length whose stop is
        % clear - which is therefore the longest one that is. In the ordinary
        % case the very end already works and this costs one check per future.
        for p = worst(k):-1:1
            [ok, used] = iStopIsSafe(candidates(k), futures, p, opts);
            stopChecks = stopChecks + used;
            if ok
                terminal(k) = p;
                break
            end
        end
    end
end

% ---- 4. how far we commit ----------------------------------------------------
if opts.trunkMode == "B"
    rule = "STOP_FEASIBLE_PREFIX (reading B)";
else
    rule = "LONGEST_CLEAR_PREFIX (reading A)";
end

trunk = sih.planner.findSharedTrunk(candidates(:), terminal, ...
            minTrunkTime_s = opts.minTrunkTime_s, ...
            rule           = rule);

out = struct( ...
    'Trunk',            trunk, ...
    'Candidates',       candidates(:), ...
    'Futures',          futures, ...
    'SafeSteps',        safeSteps, ...
    'WorstPrefixSteps', worst, ...
    'TerminalPrefixSteps', terminal, ...
    'TrunkMode',        opts.trunkMode, ...
    'StopChecks',       stopChecks, ...
    'BindingFuture',    binding, ...
    'NumTracks',        nT, ...
    'Blocked',          trunk.Blocked);
end

% ------------------------------------------------------------------ helpers

function [ok, used] = iStopIsSafe(candidate, futures, p, opts)
%ISTOPISSAFE  Is braking to a stop from step p clear under EVERY future?
%   Stops at the first future that says no, so a hopeless prefix costs one check
%   rather than all of them. `used` reports how many were actually run.
ok   = true;
used = 0;
for j = 1:numel(futures)
    used = used + 1;
    r = sih.planner.checkTerminalStop(candidate, futures(j), p, ...
            aBrake_mps2      = opts.aBrake_mps2, ...
            dwellAfterStop_s = opts.dwellAfterStop_s, ...
            egoLength_m      = opts.egoLength_m, ...
            egoWidth_m       = opts.egoWidth_m, ...
            inflation_m      = opts.inflation_m);
    if ~r.Safe
        ok = false;
        return
    end
end
end

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
