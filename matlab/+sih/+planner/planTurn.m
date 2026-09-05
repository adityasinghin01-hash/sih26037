function out = planTurn(route, egoState, opts)
%PLANTURN  One turn planner, not five. Only which constraint binds changes.
%
%   Task D10. plan/D-planner.md states the rule this file is built on:
%
%       | turn        | binds                    | needs                        |
%       | Normal      | nothing                  | -                            |
%       | Roundabout  | conflict - it's a merge  | existing probe-commit        |  DROPPED
%       | U-turn      | minimum turning radius   | multi-point turn, Gear = -1  |
%       | Side cut    | crossing while exposed   | refuge points                |
%       | Sharp       | lateral grip             | the sqrt(aLat*R) term in D8  |
%
%   Four rows, one function. Writing four planners would mean four places for the
%   same geometry to drift apart, and the row that binds is a consequence of the
%   numbers, not a mode anybody selects.
%
%   THE TYPE IS DERIVED, NEVER CLASSIFIED
%   D-planner.md D10: "Turn type is DERIVED from S10.GoalHeading, never classified.
%   No sign detection." So everything here comes out of one angle - the difference
%   between where the car points now and where the route wants it to point. There is
%   no learned classifier, no sign reader, and nothing to mislabel.
%
%   WHY A RIGHT TURN IS A CUT AND A LEFT TURN IS NOT
%   The same reason plan/D6-TRUNK-RULING.md gives for HEAD_ON steering left: the
%   Rules of the Road Regulations, 1989, reg. 2 keeps traffic to the LEFT. So a left
%   turn peels off the near side and crosses nothing, while a right turn crosses the
%   oncoming stream and then the one it is joining - exposed in the middle for the
%   whole manoeuvre. That exposure is what a refuge point exists for. Importing a
%   keep-right convention here would mark the harmless turn as the dangerous one.
%   The frame is x forward, y left, z up, so a POSITIVE heading change is LEFT.
%
%   THE SHARP ROW IS ASKED FOR, NOT RECOMPUTED
%   The sharp-at-speed row binds on lateral grip, and sqrt(aLat*R) already exists as
%   the first term of sih.planner.speedLimit. So this file never writes that term out
%   again: hand it opts.space and it CALLS speedLimit and reads which term won.
%
%       t = sih.planner.planTurn(route, egoState, space = space);
%       if t.GripBinds, ... % .Binds is "grip", .GripLimit_mps is the cap
%
%   Two copies of one law is how they drift apart, and this one is logged as safety
%   evidence, so there must be exactly one place it comes from.
%
%   Grip is a SPEED question and the geometry rows are not, so it is settled last and
%   can take the binding off them: at 15 m/s a gentle bend is held by grip long
%   before its radius or its refuge matters. The geometry is not discarded when that
%   happens - .Type, .NeedsReverse and .RefugePoint all still say what they said.
%
%   WITHOUT opts.space THE ROW IS NOT EVALUATED
%   speedLimit needs S9 DrivableSpace, which this function is not otherwise given.
%   With no space, .GripBinds stays false and .GripLimit_mps stays NaN, and that
%   means NOT EVALUATED - never "grip does not bind". A caller that wants the fourth
%   row must pass S9.
%
%   WHAT THIS FUNCTION DOES NOT DO, ON PURPOSE
%
%   It does not set the gear either. .NeedsReverse says a multi-point turn is
%   unavoidable; Gear is a Stateflow decision and belongs to Person B, exactly as
%   Signal, Committed and MirrorsFolded do. This function is where she learns that
%   reverse is required, and it is the only place that answer comes from.
%
%   THE ROUNDABOUT ROW IS DROPPED, BY RULING
%   A roundabout is a merge, and a merge is not visible in a heading change - a car
%   entering one may be aiming almost straight ahead. AGENTS.md S10 Route carries
%   GoalHeading, GoalPoint, BlockedEdges and EscapePoints, and none of them says
%   "roundabout", so it cannot be derived from S10 as written.
%
%   Aditya ruled on 5 September 2026: DROP THE ROW, S10 does not gain a field. Three
%   reasons. AGENTS.md section 3 is frozen. A "roundabout" field would BE the
%   classification D10 forbids, so adding one would break the rule it was meant to
%   serve. And nothing behavioural is lost: give-way-to-the-right falls out of
%   sih.planner.assignRoles geometrically, and the backup demo already runs a real
%   gyratory with no such field.
%
%   So there is no roundabout type and no way to ask for one. Reopen this only by
%   naming a specific behaviour that geometry cannot produce.
%
%   THE MULTI-POINT SUM
%   A car of turning radius R that has y metres of clear lateral room can swing its
%   heading through acos(1 - y/R) in one sweep before it runs out of road. A U-turn
%   needs pi, so it needs ceil(pi / that) sweeps, alternating forward and reverse.
%   The formula lands on the textbook answer at both ends: with y = 2R it gives
%   acos(-1) = pi, one sweep, which is the ordinary "the road is wide enough" case;
%   with almost no room it grows without bound. No separate is-it-wide-enough test
%   is needed, because the sum already contains it.
%
%   AN EMPTY OR INVALID ROUTE IS NOT AN ERROR
%   S9 and S10 do not exist yet and the yield predictor fails its own gate about one
%   time in five, so an invalid input is the likely path, not the rare one. An
%   invalid route returns a NORMAL turn with .Valid false and every number NaN. The
%   caller drives straight, which is what a car with no route should do.
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
%
%   INPUTS
%     route     (1,1) struct  S10 Route. Reads .GoalHeading (rad, world frame) and,
%                             when present, .Valid. MAY be marked invalid.
%     egoState  (1,1) struct  .Position (1x3), .Velocity (1x3), .Yaw (rad)
%     opts.roadWidth_m        clear width for the manoeuvre,   default 7.0 MEASURED
%     opts.wheelbase_m        front axle to rear axle,         default 2.8
%     opts.maxSteer_rad       steering limit, S4,              default 0.6
%     opts.egoWidth_m         body width without mirrors,      default 1.8
%     opts.egoLength_m        body length,                     default 4.7
%     opts.cutMinAngle_rad    below this a turn is NORMAL,     default 0.35 (20 deg)
%     opts.uturnAngle_rad     at or above this it is a U-turn, default 2.36 (135 deg)
%     opts.streamWidth_m      one traffic stream's width,      default 3.5
%     opts.refugeMargin_m     clear of the stream just crossed,default 1.0
%     opts.space              S9 DrivableSpace. WITHOUT IT the grip row is
%                             not evaluated at all,             default none
%
%   WHICH OF THESE NUMBERS ARE MEASURED, AND WHICH ARE CHOSEN
%   The distinction is the whole point, so it is written out rather than assumed.
%
%   roadWidth_m is MEASURED, per Aditya's ruling of 5 September 2026: it is S0
%   section 4 and the backup demo asserts it to 1 mm. It must never be described as
%   a design choice.
%   TODO(unverified): the citation cannot be checked from this repository - there is
%   no S0 file in plan/ and the figure 7.0 appears nowhere outside this file. The
%   ruling is followed on Aditya's word; ask him to land S0 so the number has a
%   source here rather than in a message.
%
%   TODO(unverified): cutMinAngle, uturnAngle, streamWidth and refugeMargin are
%   DESIGN CHOICES traceable to plan/D-planner.md D10, not measured figures. By the
%   same ruling every one of them must be written into config.json before any of it
%   is demonstrated, and none may ever be called measured or sourced.
%   TODO(unverified): config.json does not exist anywhere in the repository yet.
%
%   wheelbase and egoWidth/egoLength match sih.planner.followTrunk and
%   sih.planner.roadBarrier so the three cannot disagree about the same car;
%   maxSteer matches chooseVelocity's steerLimits, which S4 fixes.
%
%   OUTPUT  out, a struct
%     .Type              string  "NORMAL" "UTURN" "CUT". Never "ROUNDABOUT"
%     .Binds             string  "nothing" "radius" "refuge" "grip"
%     .HeadingChange_rad double  goal heading minus current yaw, wrapped to +/-pi.
%                                POSITIVE IS LEFT
%     .MinRadius_m       double  the car's own tightest circle, wheelbase/tan(steer)
%     .Curvature_1pm     double  1/radius, to hand to sih.planner.speedLimit.
%                                0 for a NORMAL turn
%     .NeedsReverse      logical true when one sweep cannot do it - Person B's Gear
%     .NumSegments       double  forward/reverse sweeps needed. 1 means one sweep.
%                                Inf when the road is narrower than the car
%     .RequiredWidth_m   double  width a single-sweep U-turn would need
%     .RefugePoint       (1,2)   where to pause mid-cut, [NaN NaN] when not a cut
%     .GripLimit_mps     double  sqrt(aLat*R) as speedLimit computes it. NaN when
%                                no opts.space was given - not evaluated
%     .GripBinds         logical grip is the tightest constraint right now
%     .Valid             logical false when the route could not be used
%     .Reason            string  one line, for D5's log

arguments
    route    (1,1) struct
    egoState (1,1) struct
    opts.roadWidth_m     (1,1) double {mustBePositive}    = 7.0
    opts.wheelbase_m     (1,1) double {mustBePositive}    = 2.8
    opts.maxSteer_rad    (1,1) double {mustBePositive}    = 0.6
    opts.egoWidth_m      (1,1) double {mustBePositive}    = 1.8
    opts.egoLength_m     (1,1) double {mustBePositive}    = 4.7
    opts.cutMinAngle_rad (1,1) double {mustBePositive}    = 0.35
    opts.uturnAngle_rad  (1,1) double {mustBePositive}    = 2.36
    opts.streamWidth_m   (1,1) double {mustBePositive}    = 3.5
    opts.refugeMargin_m  (1,1) double {mustBeNonnegative} = 1.0
    opts.space                 struct                     = struct.empty(0,1)
end

iRequireFields(egoState, {'Position','Yaw'}, 'egoState');

% The car's own tightest circle. Bicycle model, and the two numbers in it are the
% same ones followTrunk steers with and S4 clamps to, so the three cannot disagree
% about what car this is.
Rmin = opts.wheelbase_m / tan(opts.maxSteer_rad);

out = struct('Type', "NORMAL", 'Binds', "nothing", 'HeadingChange_rad', NaN, ...
             'MinRadius_m', Rmin, 'Curvature_1pm', 0, 'NeedsReverse', false, ...
             'NumSegments', 1, 'RequiredWidth_m', NaN, ...
             'RefugePoint', [NaN NaN], 'GripLimit_mps', NaN, 'GripBinds', false, ...
             'Valid', false, 'Reason', "");

% ---- the invalid path, built first because it is the likely one -------------------

if ~isfield(route, 'GoalHeading')
    out.Reason = "route has no GoalHeading - driving straight";
    return
end
if isfield(route, 'Valid') && ~route.Valid
    out.Reason = "route marked invalid - driving straight";
    return
end
if ~isscalar(route.GoalHeading) || ~isfinite(route.GoalHeading)
    out.Reason = "GoalHeading is not a usable angle - driving straight";
    return
end
if ~isfinite(egoState.Yaw)
    out.Reason = "ego yaw is not a usable angle - driving straight";
    return
end

out.Valid = true;

% ---- the one angle everything is derived from ------------------------------------

delta = iWrapToPi(route.GoalHeading - egoState.Yaw);
out.HeadingChange_rad = delta;

mag  = abs(delta);
left = delta > 0;                  % x forward, y left: positive is LEFT

% A single-sweep U-turn needs the full turning circle plus the body across it.
out.RequiredWidth_m = 2*Rmin + opts.egoWidth_m;

% ---- which row binds --------------------------------------------------------------

if mag >= opts.uturnAngle_rad
    out.Type          = "UTURN";
    out.Binds         = "radius";
    out.Curvature_1pm = 1 / Rmin;

    [n, room] = iSweepsFor(mag, Rmin, opts.roadWidth_m - opts.egoWidth_m);
    out.NumSegments  = n;
    out.NeedsReverse = n > 1;

    if ~isfinite(n)
        out.Reason = "U-turn impossible - " + iFmt(opts.roadWidth_m) + " m road is " + ...
                     "narrower than the " + iFmt(opts.egoWidth_m) + " m car";
    elseif n == 1
        out.Reason = "U-turn in one sweep - " + iFmt(room) + " m of room, " + ...
                     iFmt(out.RequiredWidth_m) + " m needed";
    else
        out.Reason = "U-turn needs " + n + " sweeps - " + iFmt(room) + " m of room, " + ...
                     iFmt(out.RequiredWidth_m) + " m needed for one. REVERSE REQUIRED";
    end

elseif mag >= opts.cutMinAngle_rad && ~left
    % Right turn across the oncoming stream. RRR 1989 reg. 2 keeps traffic left, so
    % this is the crossing that leaves the car exposed - see the header.
    out.Type          = "CUT";
    out.Binds         = "refuge";
    out.Curvature_1pm = 1 / Rmin;
    out.RefugePoint   = iRefuge(egoState.Position(1:2), route.GoalHeading, opts);
    out.Reason        = "right turn of " + iFmt(rad2deg(mag)) + " deg crosses the " + ...
                        "oncoming stream - stop at the refuge, do not block it";

elseif mag >= opts.cutMinAngle_rad
    % Left turn. It peels off the near side and crosses nobody, so nothing binds
    % except the grip the caller gets from speedLimit.
    out.Type          = "NORMAL";
    out.Binds         = "nothing";
    out.Curvature_1pm = 1 / Rmin;
    out.Reason        = "left turn of " + iFmt(rad2deg(mag)) + " deg crosses no " + ...
                        "stream - grip is the only limit";

else
    out.Type          = "NORMAL";
    out.Binds         = "nothing";
    out.Curvature_1pm = 0;
    out.Reason        = "heading change of " + iFmt(rad2deg(mag)) + " deg is not a turn";
end

% ---- the sharp-at-speed row -------------------------------------------------------
%
% D-planner.md D10's last row: "Sharp at speed | lateral grip | the sqrt(aLat*R) term
% in D8". Grip is a speed question, and the geometry rows above are not, so it is
% settled last and can take the binding off them - at 15 m/s a gentle bend is held by
% grip long before its radius or its refuge matters.
%
% THE TERM IS NOT COMPUTED HERE. sih.planner.speedLimit owns the speed law and
% already reports .Binding == "CURVE" when its first term wins, so this asks it
% rather than writing sqrt(aLat*R) out a second time. Two copies of one law is how
% they drift apart, and this one is logged as safety evidence.
%
% It needs S9 DrivableSpace, which this function is not otherwise given, so the grip
% row is evaluated only when a caller passes opts.space. Without it .GripBinds stays
% false and .GripLimit_mps stays NaN - "not evaluated", never "does not bind".

if ~isempty(opts.space)
    iRequireFields(egoState, {'Velocity'}, 'egoState');
    speed = norm(egoState.Velocity(1:2));

    cap = sih.planner.speedLimit(opts.space, speed, curvature_1pm = out.Curvature_1pm);
    out.GripLimit_mps = cap.CurveTerm_mps;

    % TWO conditions, and the second is the one the row is named after. speedLimit
    % says CURVE whenever the grip term is the smallest of its three - which is true
    % of a hairpin whether the car is doing 20 m/s or standing still. A parked car is
    % not being held back by grip. So the row binds only when the car is actually AT
    % or above the cap: "sharp AT SPEED".
    if cap.Binding == "CURVE" && speed >= cap.CurveTerm_mps
        out.GripBinds = true;
        out.Binds     = "grip";
        out.Reason    = out.Reason + " - but lateral grip binds first at " + ...
                        iFmt(cap.CurveTerm_mps) + " m/s, and the car is doing " + ...
                        iFmt(speed);
    end
end
end

% -------------------------------------------------------------------------------------

function [n, room] = iSweepsFor(totalAngle, R, room)
%ISWEEPSFOR  How many forward/reverse sweeps a turn of totalAngle needs.
%
%   room is the clear lateral space the body has, already less its own width. A car
%   on a circle of radius R that moves y sideways has turned acos(1 - y/R), so one
%   sweep buys that much heading and the turn needs ceil(total / it).
%
%   At room = 2R the sum gives acos(-1) = pi and therefore one sweep, which is the
%   textbook "wide enough to U-turn" case falling out rather than being tested for.

if room <= 0
    n = Inf;                       % the road is narrower than the car
    return
end

perSweep = acos(max(-1, 1 - room / R));

if perSweep <= 0
    n = Inf;
else
    n = ceil(totalAngle / perSweep);
end
end

function p = iRefuge(pos, goalHeading, opts)
%IREFUGE  Where to pause part-way through a right turn.
%
%   Far enough along the goal direction that the tail is clear of the stream just
%   crossed, and no further - a refuge past that point starts blocking the stream
%   being joined instead, which is the same mistake facing the other way.

d = opts.streamWidth_m + opts.egoLength_m/2 + opts.refugeMargin_m;
p = pos(:).' + d * [cos(goalHeading), sin(goalHeading)];
end

function a = iWrapToPi(a)
% Local, so this file needs no toolbox. Same helper sih.planner.assignRoles carries.
a = mod(a + pi, 2*pi) - pi;
end

function s = iFmt(x)
s = string(sprintf('%.2f', x));
end

function iRequireFields(s, names, argName)
% Fail loudly and by name, rather than three lines later inside the arithmetic.
for i = 1:numel(names)
    if ~isfield(s, names{i})
        error('sih:planner:planTurn:missingField', ...
              '%s is missing required field ''%s''.', argName, names{i});
    end
end
end
