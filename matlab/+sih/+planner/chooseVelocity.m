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
%   Only HEAD_ON steers, because picking a side is intrinsic to the head-on rule.
%   Every other kind of going-around is a lateral CANDIDATE PATH and belongs to D6,
%   which can check it against both futures. Steering per-agent per-step here
%   would dither, and dithering mid-junction is what causes the accident.
%
%   WHICH SIDE, AND WHY IT IS NOT THE MARITIME SIDE  (settled 4 September 2026)
%   COLREGs buys us LEGIBILITY, and legibility means matching what the other driver
%   already expects. On two of our roles the maritime rule and the Indian rule agree,
%   and on one they are opposites:
%
%     CROSSING - they AGREE, which is why assignRoles can use the maritime sectors.
%       COLREGs Rule 15 gives way to the vessel on your starboard. Rules of the Road
%       Regulations, 1989, reg. 9: on entering an unregulated intersection a driver
%       shall "give way to all traffic approaching the intersection on his right hand."
%       Starboard is the right hand. Same answer.
%
%     HEAD-ON - they are OPPOSITE, and India wins.
%       COLREGs Rule 14 alters to STARBOARD so vessels pass port to port. That is a
%       keep-right convention. India keeps left: reg. 2 says a driver shall drive
%       "as close to the left side of the road as may be expedient and shall allow all
%       traffic which is proceeding in the opposite direction to pass on his right hand
%       side." Oncoming traffic passes on our RIGHT, so we move LEFT.
%
%   Importing the maritime direction literally here would steer into oncoming traffic.
%   opts.headOnSteer_rad is therefore POSITIVE (left) by default, and it is derived from
%   a citable regulation rather than chosen. Flip the sign only for a right-hand-traffic
%   country, and say so in the run config if you ever do.
%
%   INPUTS
%     role      (1,1) uint8   role code (S7): 0 SAFE, 1 GIVE_WAY, 2 STAND_ON,
%                             3 HEAD_ON, 4 OVERTAKING
%     vo        (1,1) struct  output of sih.planner.velocityObstacle. Only .h is
%                             read: h = lambda - beta, the safety margin
%     egoState  (1,1) struct  .Position (m), .Velocity (m/s), .Yaw (rad)
%     opts.giveWayAccel_mps2    one substantial deceleration,    default -2.5
%     opts.headOnAccel_mps2     ease off while altering course,  default -1.5
%     opts.headOnSteer_rad      POSITIVE IS LEFT (India),        default  0.15
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
%   .Reason IS A STRING, AND THAT MATCHES THE CONTRACT  (checked 4 September 2026)
%   AGENTS.md section 3, S4 declares `.Reason string`, so a MATLAB string scalar is
%   correct and no change is needed here.
%   ONE CONSEQUENCE FOR PERSON B: Simulink and Stateflow handle the string type poorly
%   inside buses, and Embedded Coder restricts it further - which E9 needs for the PIL
%   latency numbers. If the chart cannot carry .Reason as a string, that is a CONTRACT
%   question for Aditya, not a silent change here. Section 3 is frozen.
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
        % Maritime Rule 15 and RRR 1989 reg. 9 agree here: give way to the right.
        cmd = iPack(iZeroIfStopped(opts.giveWayAccel_mps2, stopped), 0, UNSTRUCTURED, ...
                    "GIVE_WAY: one early substantial deceleration (Rule 15/16; RRR reg. 9)");

    case HEAD_ON
        % Both vehicles alter to their own LEFT, so the choice is predictable and it is
        % what the other driver already expects. Rules of the Road Regulations, 1989,
        % reg. 2 - oncoming traffic passes on our right. NOT COLREGs Rule 14, which
        % alters to starboard and would steer us into the oncoming stream. See header.
        cmd = iPack(iZeroIfStopped(opts.headOnAccel_mps2, stopped), opts.headOnSteer_rad, ...
                    UNSTRUCTURED, "HEAD_ON: both alter left, oncoming passes right (RRR 1989 reg. 2)");

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
