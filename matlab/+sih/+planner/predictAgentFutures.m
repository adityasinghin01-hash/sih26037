function futures = predictAgentFutures(track, pYield, valid, opts)
%PREDICTAGENTFUTURES  One track in, two futures out: it yields, or it asserts.
%
%   Task D6, piece 1 of 5. Branch/contingency MPC models exactly two modes, and
%   that is precisely what Stream C's predictor outputs, so there is no third
%   future here and there must not be one.
%
%   WHY TWO AND ONLY TWO
%   A yield future and an assert future bracket the behaviour. Anything the other
%   road user actually does lies between them, so a plan safe under both is safe
%   in fact. Adding a "maybe" future would add cost without adding coverage.
%
%   WHY THE PROBABILITY IS NaN WHEN THE PREDICTION IS INVALID
%   AGENTS.md section 3, S3: "When Valid is false the planner uses the geometric
%   role alone - never 0.5." A made-up probability is worse than none, because
%   whatever reads it will trust it. So this returns NaN, which cannot be summed,
%   averaged or compared by accident. Safety never depends on it: the trunk must
%   hold under BOTH futures regardless of how they are weighted. The weight only
%   ranks candidates, it never permits one.
%
%   INPUTS
%     track   (1,1) struct  one element of S1 TrackList. Reads .TrackID,
%                           .Position (1x3, m), .Velocity (1x3, m/s), .Yaw (rad),
%                           .Extent (1x3, m)
%     pYield  (1,1) double  S3 PYield for this track, in [0,1]. Ignored if ~valid
%     valid   (1,1) logical S3 Valid for this track
%     opts.horizon_s          how far ahead to roll,          default 4.0
%     opts.timeResolution_s   step,                           default 0.1
%     opts.yieldDecel_mps2    yield braking, negative,        default -2.0
%     opts.assertAccel_mps2   assert acceleration,            default  0.0
%     opts.assertMaxSpeed_mps ceiling on the assert future,   default 25.0
%     opts.movingSpeed_mps    above this, heading comes from  default 0.1
%                             the velocity vector; below it, from .Yaw
%
%   OUTPUT  futures  1x2 struct array, element 1 YIELD, element 2 ASSERT
%     .TrackID      uint32
%     .Label        string, "YIELD" or "ASSERT"
%     .Probability  double. pYield / 1-pYield, or NaN when ~valid
%     .Valid        logical, copied from the input
%     .Times        Nx1 double, s, starting at 0
%     .States       Nx3 double, [x y theta] at each time - what the capsule
%                   collision checker wants
%     .Speeds       Nx1 double, m/s
%     .Extent       1x3 double, copied from the track so piece 3 can size it
%
%   HEADING MODEL: constant. The agent keeps its current direction of travel and
%   only its speed changes. A turning model would need a turn rate we do not have
%   from S1, and inventing one would put a number in the plan that nothing
%   measured. Revisit if S1 ever carries a yaw rate.
%
%   FRAME: x forward, y left, z up, same as S1.
%
%   See also SIH.PLANNER.VELOCITYOBSTACLE, SIH.PLANNER.GENERATECANDIDATES

arguments
    track  (1,1) struct
    pYield (1,1) double
    valid  (1,1) logical
    opts.horizon_s          (1,1) double {mustBePositive} = 4.0
    opts.timeResolution_s   (1,1) double {mustBePositive} = 0.1
    opts.yieldDecel_mps2    (1,1) double {mustBeFinite}   = -2.0
    opts.assertAccel_mps2   (1,1) double {mustBeFinite}   =  0.0
    opts.assertMaxSpeed_mps (1,1) double {mustBePositive} = 25.0
    opts.movingSpeed_mps    (1,1) double {mustBeNonnegative} = 0.1
end

iRequireFields(track, {'TrackID','Position','Velocity','Yaw','Extent'}, 'track');

if valid && (pYield < 0 || pYield > 1)
    error('sih:planner:predictAgentFutures:badPYield', ...
          'pYield must be in [0,1] when valid is true. Got %g.', pYield);
end

t  = (0:opts.timeResolution_s:opts.horizon_s)';
p0 = track.Position(1:2);
v0 = norm(track.Velocity(1:2));

% Direction of travel. Below movingSpeed_mps the velocity vector is noise, so
% the body heading is the only thing left to trust.
if v0 >= opts.movingSpeed_mps
    theta = atan2(track.Velocity(2), track.Velocity(1));
else
    theta = track.Yaw;
end
unit = [cos(theta) sin(theta)];

% YIELD: brake at a constant rate, never reverse.
[sY, vY] = iRamp(v0, opts.yieldDecel_mps2,  t, 0, opts.assertMaxSpeed_mps);
% ASSERT: hold speed by default, or press on, capped.
[sA, vA] = iRamp(v0, opts.assertAccel_mps2, t, 0, opts.assertMaxSpeed_mps);

if valid
    pY = pYield;
    pA = 1 - pYield;
else
    pY = NaN;
    pA = NaN;
end

futures = [ iFuture(track, "YIELD",  pY, valid, t, p0, unit, theta, sY, vY), ...
            iFuture(track, "ASSERT", pA, valid, t, p0, unit, theta, sA, vA) ];
end

% ------------------------------------------------------------------ helpers

function f = iFuture(track, label, prob, valid, t, p0, unit, theta, s, v)
n = numel(t);
f = struct( ...
    'TrackID',     uint32(track.TrackID), ...
    'Label',       label, ...
    'Probability', prob, ...
    'Valid',       valid, ...
    'Times',       t, ...
    'States',      [p0 + s .* unit, repmat(theta, n, 1)], ...
    'Speeds',      v, ...
    'Extent',      track.Extent(:)');
end

function [s, v] = iRamp(v0, a, t, vMin, vMax)
%IRAMP  Distance and speed under constant acceleration, with the speed held
%       inside [vMin vMax]. Solved exactly rather than integrated numerically,
%       so a stop is a stop and not a stop plus half a step of drift.
v = min(max(v0 + a .* t, vMin), vMax);
s = zeros(size(t));

if a == 0
    s = v0 .* t;
    return
end

% Time at which the ramp meets whichever limit it is heading for.
if a < 0
    tLim = (vMin - v0) / a;
else
    tLim = (vMax - v0) / a;
end
tLim = max(tLim, 0);

before = t <= tLim;
s(before) = v0 .* t(before) + 0.5 * a .* t(before).^2;

sLim  = v0 * tLim + 0.5 * a * tLim^2;
vLim  = v0 + a * tLim;
after = ~before;
s(after) = sLim + vLim .* (t(after) - tLim);
end

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:predictAgentFutures:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
