function result = checkTrajectorySafety(candidate, future, opts)
%CHECKTRAJECTORYSAFETY  One candidate path against one future: safe, step by step.
%
%   Task D6, piece 3 of 5. Not "is this path safe" but "how far along this path
%   am I safe", because piece 4 needs the prefix, not the verdict. A path that is
%   safe for two seconds and then hit is not simply unsafe - the first two
%   seconds of it may be exactly what we commit to.
%
%   WHY .SafePrefixSteps IS THE POINT
%   The trunk is built out of leading safe stretches. A single true/false answer
%   throws away the information the trunk is made of, so this returns the whole
%   per-step picture and counts the unbroken run from the start.
%
%   WHY THE FOOTPRINTS ARE SLIGHTLY TOO BIG
%   Following the MathWorks Frenet example, the capsule is built with
%   Length = vehicle length and Radius = half the width, so the shape is about
%   one width longer than the real vehicle. That errs on the safe side, which is
%   the right direction to err. opts.inflation_m adds more on top for tracking
%   uncertainty.
%
%   INPUTS
%     candidate (1,1) struct  one element from sih.planner.generateCandidates.
%                             Reads .Times and .States (Nx3, [x y theta])
%     future    (1,1) struct  one element from sih.planner.predictAgentFutures.
%                             Reads .Times, .States, .Extent, .Label, .TrackID
%     opts.egoLength_m  ego body length,               default 4.7
%     opts.egoWidth_m   ego body width,                default 1.8
%     opts.inflation_m  extra margin on BOTH bodies,   default 0.0
%
%   OUTPUT  result struct
%     .TrackID          uint32, whose future this was
%     .Label            string, "YIELD" or "ASSERT"
%     .Times            Nx1, the candidate's own time base
%     .Safe             Nx1 logical, true = clear at that step
%     .AllSafe          logical, true if every step is clear
%     .FirstUnsafeIndex double, first step that is not clear, NaN if none
%     .FirstUnsafeTime  double, s, NaN if none
%     .SafePrefixSteps  double, unbroken clear steps counted from the start
%     .SafePrefixTime   double, s, how long that prefix lasts
%
%   TIME BASES
%   The candidate's clock wins. The future is interpolated onto it, and if the
%   future is shorter it holds its last pose rather than vanishing - a vehicle
%   that stopped two seconds ago is still standing there.
%
%   TODO(performance): a fresh dynamicCapsuleList is built per call, so a fan of
%   20 candidates against 2 futures builds 40 of them each cycle. Fine at the
%   scale we test at. Measure before optimising.
%
%   See also SIH.PLANNER.GENERATECANDIDATES, SIH.PLANNER.PREDICTAGENTFUTURES,
%            DYNAMICCAPSULELIST

arguments
    candidate (1,1) struct
    future    (1,1) struct
    opts.egoLength_m (1,1) double {mustBePositive} = 4.7
    opts.egoWidth_m  (1,1) double {mustBePositive} = 1.8
    opts.inflation_m (1,1) double {mustBeNonnegative} = 0.0
end

iRequireFields(candidate, {'Times','States'}, 'candidate');
iRequireFields(future,    {'Times','States','Extent','Label','TrackID'}, 'future');

t = candidate.Times(:);
n = numel(t);
if n < 1
    error('sih:planner:checkTrajectorySafety:emptyCandidate', ...
          'candidate.Times is empty - there is nothing to check.');
end

egoStates = candidate.States;
obsStates = iResampleHold(future.Times(:), future.States, t);

capList = dynamicCapsuleList;
capList.MaxNumSteps = n;        % default is 31; a 4 s plan at 0.1 s is 41 steps

egoID = 1;
[egoID, egoGeom] = egoGeometry(capList, egoID);
egoGeom.Geometry.Length = opts.egoLength_m;
egoGeom.Geometry.Radius = opts.egoWidth_m/2 + opts.inflation_m;
egoGeom.Geometry.FixedTransform(1,end) = -opts.egoLength_m/2;
updateEgoGeometry(capList, egoID, egoGeom);

obsID = 2;
obsLen = future.Extent(1);
obsWid = future.Extent(2);
[obsID, obsGeom] = obstacleGeometry(capList, obsID);
obsGeom.Geometry.Length = obsLen;
obsGeom.Geometry.Radius = obsWid/2 + opts.inflation_m;
obsGeom.Geometry.FixedTransform(1,end) = -obsLen/2;
updateObstacleGeometry(capList, obsID, obsGeom);

updateEgoPose(capList,      egoID, struct('ID', egoID, 'States', egoStates));
updateObstaclePose(capList, obsID, struct('ID', obsID, 'States', obsStates));

hit = checkCollision(capList);
hit = logical(hit(:));

% Observed by running on R2026a, 4 Sep 2026: one ego and n pose steps gives back
% n logicals, one per step. Refuse to guess if that ever changes.
if numel(hit) ~= n
    error('sih:planner:checkTrajectorySafety:unexpectedResultShape', ...
          ['checkCollision returned %d values for %d timesteps. This function ' ...
           'assumes one result per timestep. Stop and check the toolbox version.'], ...
          numel(hit), n);
end

safe = ~hit;
firstBad = find(hit, 1, 'first');
if isempty(firstBad)
    firstIdx  = NaN;
    firstTime = NaN;
    prefix    = n;
else
    firstIdx  = firstBad;
    firstTime = t(firstBad);
    prefix    = firstBad - 1;
end

if prefix >= 1
    prefixTime = t(prefix) - t(1);
else
    prefixTime = 0;
end

result = struct( ...
    'TrackID',          uint32(future.TrackID), ...
    'Label',            future.Label, ...
    'Times',            t, ...
    'Safe',             safe, ...
    'AllSafe',          all(safe), ...
    'FirstUnsafeIndex', firstIdx, ...
    'FirstUnsafeTime',  firstTime, ...
    'SafePrefixSteps',  prefix, ...
    'SafePrefixTime',   prefixTime);
end

% ------------------------------------------------------------------ helpers

function out = iResampleHold(tSrc, statesSrc, tQuery)
%IRESAMPLEHOLD  Put [x y theta] onto another clock, holding the ends.
%   Outside the source window the first or last pose is held, because an agent
%   whose prediction ran out has not disappeared - it is still where it was.
tq = min(max(tQuery, tSrc(1)), tSrc(end));

if numel(tSrc) == 1
    out = repmat(statesSrc(1,:), numel(tq), 1);
    return
end

th   = unwrap(statesSrc(:,3));           % never interpolate across a pi wrap
xy   = interp1(tSrc, statesSrc(:,1:2), tq, 'linear');
thq  = interp1(tSrc, th,               tq, 'linear');
out  = [xy, thq(:)];
end

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:checkTrajectorySafety:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
