function cmd = chooseVelocity(role, vo, egoState, opts)
%CHOOSEVELOCITY  Turn one COLREGs role into one EgoCommand.
%
%   Task D2. One role in, one command out. No state is kept between calls - the
%   caller re-decides every step, and Person B's Stateflow chart owns everything
%   that has to be remembered.
%
%   WHY EACH ROLE ACTS AS IT DOES
%   GIVE_WAY is ONE early, substantial deceleration. COLREGs Rule 8 forbids "a
%   series of small alterations of course and/or speed": the other driver has to
%   SEE the decision, and a car that nudges is a car that has not answered the
%   question. Metric M10 catches the wobble if we get this wrong.
%   STAND_ON emits the acceleration needed to HOLD speed - zero on the flat,
%   non-zero on a gradient. Doing nothing is the action, and it is the hard one
%   to write because it feels like a missing branch. It is the safety argument.
%
%   WHY THERE IS NO LATERAL AVOIDANCE HERE
%   Only HEAD_ON steers, because picking a side is intrinsic to Rule 14. Every
%   other kind of going-around is a lateral CANDIDATE PATH and belongs to D6,
%   which can check it against both futures. Steering per-agent per-step here
%   would dither, and dithering mid-junction is what causes the accident.
%
%   INPUTS
%     role      (1,1) uint8   role code (S7): 0 SAFE, 1 GIVE_WAY, 2 STAND_ON,
%                             3 HEAD_ON, 4 OVERTAKING
%     vo        (1,1) struct  output of sih.planner.velocityObstacle. Only .h is
%                             read: h = lambda - beta, the safety margin
%     egoState  (1,1) struct  .Position (m), .Velocity (m/s), .Yaw (rad)
%     opts.giveWayAccel_mps2    one substantial deceleration,    default -2.5
%     opts.headOnAccel_mps2     ease off while altering course,  default -1.5
%     opts.headOnSteer_rad      POSITIVE IS LEFT,                default  0.15
%     opts.overtakeAccel_mps2   keep clear until past and clear, default -1.0
%     opts.emergencyAccel_mps2  when h < 0,                      default -6.0
%     opts.gradient_rad         road gradient, + is uphill,      default  0.0
%     opts.stoppedSpeed_mps     below this we are stopped,       default  0.1
%     opts.accelLimits          [min max] m/s^2,                 default [-6 3]
%     opts.steerLimits          [min max] rad,                   default [-0.6 0.6]
%
%   OUTPUT  cmd struct  EgoCommand (AGENTS.md section 3, S4)
%     .Accel       m/s^2, always inside opts.accelLimits
%     .SteerAngle  rad,   always inside opts.steerLimits. POSITIVE IS LEFT
%     .Mode        planner mode (S8): 1 UNSTRUCTURED, 2 EMERGENCY
%     .Reason      string, why this command was chosen
%
%   Signal, Gear, Committed and MirrorsFolded are NOT set here. They are state
%   machine decisions and belong to Person B's Stateflow chart.
%
%   FRAME: x forward, y left, z up. Positive SteerAngle is LEFT.
%
%   TODO(unverified): .Reason is a string scalar. AGENTS.md section 3 defines S4
%   and has not been read here. If S4 fixes Reason as a char array or a numeric
%   code, this is a one-line change in iPack. Check with Aditya.
%
%   See also SIH.PLANNER.VELOCITYOBSTACLE, SIH.PLANNER.ASSIGNROLES

arguments
    role     (1,1) uint8
    vo       (1,1) struct
    egoState (1,1) struct
    opts.giveWayAccel_mps2   (1,1) double {mustBeFinite} = -2.5
    opts.headOnAccel_mps2    (1,1) double {mustBeFinite} = -1.5
    opts.headOnSteer_rad     (1,1) double {mustBeFinite} =  0.15
    opts.overtakeAccel_mps2  (1,1) double {mustBeFinite} = -1.0
    opts.emergencyAccel_mps2 (1,1) double {mustBeFinite} = -6.0
    opts.gradient_rad        (1,1) double {mustBeFinite} =  0.0
    opts.stoppedSpeed_mps    (1,1) double {mustBeNonnegative} = 0.1
    opts.accelLimits         (1,2) double = [-6 3]
    opts.steerLimits         (1,2) double = [-0.6 0.6]
end

SAFE=uint8(0); GIVE_WAY=uint8(1); STAND_ON=uint8(2); HEAD_ON=uint8(3); OVERTAKING=uint8(4);
UNSTRUCTURED = uint8(1);
EMERGENCY    = uint8(2);
G_MPS2 = 9.81;

iRequireFields(vo,       {'h'},                            'vo');
iRequireFields(egoState, {'Position','Velocity','Yaw'},    'egoState');

speed_mps = norm(egoState.Velocity(1:2));

% The barrier vetoes everything above it. Checked first, deliberately.
if vo.h < 0
    cmd = iPack(opts.emergencyAccel_mps2, 0, EMERGENCY, ...
                "h < 0: safety barrier violated, maximum braking");
    cmd = iClamp(cmd, opts);
    return
end

% Below the stopped threshold there is no speed left to give away.
stopped = speed_mps < opts.stoppedSpeed_mps;

switch role
    case SAFE
        cmd = iPack(0, 0, UNSTRUCTURED, ...
                    "SAFE: no constraint from this agent");

    case STAND_ON
        % Zero on the flat, non-zero on a gradient. Holding speed IS the action.
        cmd = iPack(G_MPS2 * sin(opts.gradient_rad), 0, UNSTRUCTURED, ...
                    "STAND_ON: hold course and speed (Rule 17)");

    case GIVE_WAY
        cmd = iPack(iZeroIfStopped(opts.giveWayAccel_mps2, stopped), 0, UNSTRUCTURED, ...
                    "GIVE_WAY: one early substantial deceleration (Rule 15/16)");

    case HEAD_ON
        % Both vehicles alter to the SAME side, so the choice is predictable.
        cmd = iPack(iZeroIfStopped(opts.headOnAccel_mps2, stopped), opts.headOnSteer_rad, ...
                    UNSTRUCTURED, "HEAD_ON: both alter to the same side (Rule 14)");

    case OVERTAKING
        cmd = iPack(iZeroIfStopped(opts.overtakeAccel_mps2, stopped), 0, UNSTRUCTURED, ...
                    "OVERTAKING: keep clear until past and clear (Rule 13)");

    otherwise
        error('sih:planner:chooseVelocity:unknownRole', ...
              'Unknown role code %d. Valid S7 role codes are 0 to 4.', role);
end

cmd = iClamp(cmd, opts);
end

% ------------------------------------------------------------------ helpers

function cmd = iPack(accel, steer, mode, reason)
cmd = struct('Accel', accel, 'SteerAngle', steer, 'Mode', mode, 'Reason', reason);
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

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:chooseVelocity:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
