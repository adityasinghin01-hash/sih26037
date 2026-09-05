function [cmd, info] = followTrunk(trunk, egoState, opts)
%FOLLOWTRUNK  The committed trunk in, one EgoCommand out.
%
%   The bridge between D6 and D2. sih.planner.planContingency decides WHICH PATH
%   the car commits to; sih.planner.chooseVelocity turns a single agent's role
%   into a command. Nothing turned a committed path into a command, so this does.
%
%   WHY THIS IS A SEPARATE FUNCTION AND NOT PART OF EITHER
%   chooseVelocity answers "what does this one road user oblige me to do". This
%   answers "how do I drive the path I already chose". They are different
%   questions with different inputs, and merging them would hide which one
%   produced a given command in the log. WHICH of the two the car obeys in a
%   given cycle is a mode decision, and mode decisions are Person B's Stateflow
%   chart - this function does not arbitrate and must not start.
%
%   HOW THE STEERING IS WORKED OUT - PURE PURSUIT
%   Find the point on the committed path nearest the car, walk forward along the
%   path a look-ahead distance, and steer at that point. Look-ahead grows with
%   speed, because a fast car must aim further ahead or it saws at the wheel.
%
%   The nearest point is searched for rather than assumed to be the start,
%   because the trunk is replanned at 10 Hz while the controller underneath may
%   run faster (ReadThis.md section 5, "three speeds"). Between two plans the car
%   has moved along the trunk, and pretending it has not would steer it at a
%   point it has already passed.
%
%   HOW THE ACCELERATION IS WORKED OUT
%   The trunk carries its own clock, so the speed it asks for is simply how far
%   apart its points are divided by how far apart their times are. The speed
%   taken is the one at the LOOK-AHEAD point, not the one here, so the car eases
%   off before a slow stretch instead of arriving at it too fast.
%
%   .TerminalSpeed_mps IS DELIBERATELY NOT USED. That is the speed the whole
%   candidate ends at, and the trunk is only the committed FRONT of it, so the
%   trunk almost never reaches it. Using it would make the car chase a speed the
%   committed path never asked for.
%
%   WHEN THERE IS NO TRUNK
%   No committed path means nothing safe to move along, so this decelerates to a
%   stop and says so. It does NOT creep, sound the horn, declare blocked or hand
%   over - that ladder is D9, and burying it here would hide a decision the
%   project has to be able to point at.
%
%   INPUTS
%     trunk    (1,1) struct  from sih.planner.findSharedTrunk. Reads .States
%                            (Kx3, [x y theta]), .Times (Kx1, s), .Blocked
%     egoState (1,1) struct  .Position (1x3, m), .Velocity (1x3, m/s), .Yaw (rad)
%     opts.wheelbase_m        front axle to rear axle,         default 2.8
%     opts.lookaheadTime_s    look-ahead grows by this x speed, default 0.6
%     opts.minLookahead_m     floor on look-ahead,             default 2.0
%     opts.settleTime_s       how long to take reaching the
%                             asked-for speed,                 default 0.5
%     opts.blockedDecel_mps2  used when there is no trunk,      default -2.5
%     opts.stoppedSpeed_mps   below this we are stopped,        default 0.1
%     opts.accelLimits        [min max] m/s^2,                  default [-6 3]
%     opts.steerLimits        [min max] rad,                    default [-0.6 0.6]
%
%   TODO(unverified): opts.wheelbase_m defaults to 2.8 m, which is an ordinary
%   figure for a 4.7 m car and matches the body length already assumed in
%   checkTrajectorySafety. NOTHING IN THIS REPOSITORY STATES THE REAL ONE.
%   Person B has the vehicle model and should pass the real number through opts.
%
%   OUTPUT  cmd struct  EgoCommand (AGENTS.md section 3, S4)
%     .Accel       m/s^2, always inside opts.accelLimits
%     .SteerAngle  rad,   always inside opts.steerLimits. POSITIVE IS LEFT
%     .Mode        planner mode (S8): 1 UNSTRUCTURED
%     .Reason      string, why this command was chosen
%
%   OUTPUT  info struct  for D5's log and for tests. Decides nothing
%     .Blocked            logical, true when there was no trunk to follow
%     .NearestIndex       double, the trunk step the car is beside. NaN if none
%     .LookaheadIndex     double, the trunk step being steered at. NaN if none
%     .LookaheadPoint     1x2 double, that step's [x y]. NaN NaN if none
%     .LookaheadDist_m    double, straight-line distance to it. NaN if none
%     .CrossTrack_m       double, how far LEFT of the car that point sits
%     .TargetSpeed_mps    double, the speed the trunk asks for there. NaN if none
%     .CurrentSpeed_mps   double
%
%   Signal, Gear, Committed and MirrorsFolded are NOT set here, exactly as in
%   chooseVelocity. They are state machine decisions and belong to Person B.
%
%   Mode is never EMERGENCY here. S8 defines EMERGENCY as h < 0, and h belongs to
%   the barrier and to chooseVelocity. A blocked trunk is not a barrier breach.
%
%   FRAME: x forward, y left, z up. Positive SteerAngle is LEFT, and so is a
%   positive .CrossTrack_m.
%
%   See also SIH.PLANNER.FINDSHAREDTRUNK, SIH.PLANNER.PLANCONTINGENCY,
%            SIH.PLANNER.CHOOSEVELOCITY

arguments
    trunk    (1,1) struct
    egoState (1,1) struct
    opts.wheelbase_m       (1,1) double {mustBePositive} = 2.8
    opts.lookaheadTime_s   (1,1) double {mustBeNonnegative} = 0.6
    opts.minLookahead_m    (1,1) double {mustBePositive} = 2.0
    opts.settleTime_s      (1,1) double {mustBePositive} = 0.5
    opts.blockedDecel_mps2 (1,1) double {mustBeFinite} = -2.5
    opts.stoppedSpeed_mps  (1,1) double {mustBeNonnegative} = 0.1
    opts.accelLimits       (1,2) double = [-6 3]
    opts.steerLimits       (1,2) double = [-0.6 0.6]
end

UNSTRUCTURED = uint8(1);

iRequireFields(trunk,    {'States','Times','Blocked'},  'trunk');
iRequireFields(egoState, {'Position','Velocity','Yaw'}, 'egoState');

egoPos  = egoState.Position(1:2);
egoPos  = egoPos(:)';
speed   = norm(egoState.Velocity(1:2));
stopped = speed < opts.stoppedSpeed_mps;

S = trunk.States;
T = trunk.Times(:);

if size(S,1) ~= numel(T)
    error('sih:planner:followTrunk:sizeMismatch', ...
          'trunk has %d states but %d times. They must match one to one.', ...
          size(S,1), numel(T));
end

% A path with a NaN in it is a broken input, not a situation. Say so loudly
% rather than steering at a number nothing produced.
if ~isempty(S) && (~all(isfinite(S(:))) || ~all(isfinite(T)))
    error('sih:planner:followTrunk:nonFiniteTrunk', ...
          'trunk.States or trunk.Times holds a non-finite value. Nothing can follow that.');
end

% ---- nothing to follow -------------------------------------------------------
% Fewer than two points carries no direction and no speed, so it is no more
% followable than an empty trunk.
if trunk.Blocked || size(S,1) < 2
    if trunk.Blocked
        why = "no committed trunk (blocked): decelerating to a stop. The blocked ladder is D9";
    else
        why = "trunk has fewer than two points, so it carries no heading or speed: decelerating";
    end
    cmd  = iPack(iZeroIfStopped(opts.blockedDecel_mps2, stopped), 0, UNSTRUCTURED, why);
    cmd  = iClamp(cmd, opts);
    info = iNoInfo(speed);
    return
end

% ---- where we are on the trunk, and where we are aiming ----------------------
[~, iNear] = min(vecnorm(S(:,1:2) - egoPos, 2, 2));

lookahead = max(opts.minLookahead_m, opts.lookaheadTime_s * speed);

% Walk forward along the path from the nearest point. Distance is measured ALONG
% the trunk, not straight across it, so a curving trunk is never aimed through.
seg    = vecnorm(diff(S(iNear:end,1:2)), 2, 2);
walked = cumsum([0; seg]);
jRel   = find(walked >= lookahead, 1, 'first');
if isempty(jRel)
    jRel = numel(walked);            % the trunk is shorter than the look-ahead
end
jLook  = iNear + jRel - 1;
target = S(jLook,1:2);

% ---- steering: pure pursuit --------------------------------------------------
d     = target - egoPos;
ct    = cos(egoState.Yaw);
st    = sin(egoState.Yaw);
ahead =  ct*d(1) + st*d(2);          % + is in front of the car
left  = -st*d(1) + ct*d(2);          % + is to the LEFT of the car
reach = hypot(ahead, left);

if reach < eps
    steer = 0;                       % already standing on the aim point
else
    steer = atan2(2 * opts.wheelbase_m * left, reach^2);
end

% ---- acceleration: the speed the trunk asks for at the aim point -------------
vTarget = iSpeedAt(S, T, jLook);
accel   = (vTarget - speed) / opts.settleTime_s;

cmd = iPack(accel, steer, UNSTRUCTURED, sprintf( ...
    'following the trunk: aiming %.1f m ahead, %+.2f m to the left, asking for %.1f m/s (now %.1f)', ...
    reach, left, vTarget, speed));
cmd = iClamp(cmd, opts);

info = struct( ...
    'Blocked',          false, ...
    'NearestIndex',     iNear, ...
    'LookaheadIndex',   jLook, ...
    'LookaheadPoint',   target, ...
    'LookaheadDist_m',  reach, ...
    'CrossTrack_m',     left, ...
    'TargetSpeed_mps',  vTarget, ...
    'CurrentSpeed_mps', speed);
end

% ------------------------------------------------------------------ helpers

function v = iSpeedAt(S, T, j)
%ISPEEDAT  The speed the trunk implies at step j: how far it moved over how long.
%   The segment ARRIVING at j is used, because that is the speed the path is
%   travelling when it gets there. At the very first step there is no arriving
%   segment, so the leaving one stands in.
if j <= 1
    a = 1; b = 2;
else
    a = j-1; b = j;
end
dt = T(b) - T(a);
if dt <= 0
    v = 0;
    return
end
v = norm(S(b,1:2) - S(a,1:2)) / dt;
end

function cmd = iPack(accel, steer, mode, reason)
cmd = struct('Accel', accel, 'SteerAngle', steer, 'Mode', mode, 'Reason', string(reason));
end

function cmd = iClamp(cmd, opts)
% S4 fixes these limits. The planner must never emit outside them.
cmd.Accel      = min(max(cmd.Accel,      opts.accelLimits(1)), opts.accelLimits(2));
cmd.SteerAngle = min(max(cmd.SteerAngle, opts.steerLimits(1)), opts.steerLimits(2));
end

function a = iZeroIfStopped(a, stopped)
if stopped
    a = 0;
end
end

function info = iNoInfo(speed)
info = struct( ...
    'Blocked',          true, ...
    'NearestIndex',     NaN, ...
    'LookaheadIndex',   NaN, ...
    'LookaheadPoint',   [NaN NaN], ...
    'LookaheadDist_m',  NaN, ...
    'CrossTrack_m',     NaN, ...
    'TargetSpeed_mps',  NaN, ...
    'CurrentSpeed_mps', speed);
end

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:followTrunk:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
