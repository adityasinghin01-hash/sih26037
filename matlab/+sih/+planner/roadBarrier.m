function out = roadBarrier(space, speed_mps, opts)
%ROADBARRIER  The second barrier: how much room is left beside the car.
%
%   Task D8. h_road = EdgeDistance - dMin >= 0, exactly the form AGENTS.md
%   section 3 S9 fixes, and the same shape as h_agent = lambda - beta.
%
%   WHY A SECOND BARRIER AND NOT A MODE
%   A khai - a drop at the edge of a hill road - returns NO lidar points at all.
%   Nothing comes back, so it can never appear in S1 as an object. It is not a
%   thing to avoid; it is the ABSENCE of ground. That is why it arrives through
%   S9 as geometry and gets its own barrier.
%
%   Both barriers hold at once and NOTHING SWITCHES BETWEEN THEM. On a 3 m ghat
%   road h_road binds; at an open junction h_agent binds. The geometry decides,
%   and a mode switch would be a second mechanism for something that already
%   falls out of the first.
%
%   THE THREE THINGS THAT SET dMin
%
%   1. THE BODY. EdgeDistance is measured to the vehicle reference point, so
%      half the body must come out of the margin before any clearance is counted.
%      The footprint is the REAL body INCLUDING MIRRORS, and it shrinks when
%      Person B's chart sets MirrorsFolded - folding is a real action worth
%      about 20 cm and D-planner.md lists it as one.
%
%   2. CONSEQUENCE, NOT PROBABILITY. The clearance is LARGER on a drop than on a
%      wall. Scraping a wall dents a panel; going over the edge is fatal. The two
%      are not equally likely and that is not the point - the margin is weighted
%      by what happens if it is crossed. An UNKNOWN side is treated as a drop,
%      because the cheap mistake is to leave too much room.
%
%   3. SPEED. Centimetres will do at 2 km/h; about 1.5 m is wanted at 40 km/h.
%      Those two figures are the ones D-planner.md D8 and AGENTS.md S9 state, so
%      they are the two ANCHORS of a straight line here rather than a slope
%      invented to fit them. Change the anchors, not the slope.
%
%   THE SWEPT PATH, NOT THE CENTRELINE
%   Corners sweep wider than the middle of the car in a turn, so a curvature
%   makes the effective half-width grow. At zero curvature the extra term is
%   exactly zero, so a straight road is unaffected.
%
%   WHEN S9 IS NOT VALID
%   S9 says: Valid false means the planner falls back to a fixed conservative
%   corridor. So the measured EdgeDistance is DISCARDED - not trusted, not
%   halved - and replaced by opts.fallbackCorridor_m, with the side treated as
%   unknown, which in turn is treated as a drop. .UsedFallback records that this
%   happened so no log is ever ambiguous about which number was real.
%
%   INPUTS
%     space     (1,1) struct  S9 DrivableSpace. Reads .EdgeDistance (m, signed,
%                             + inside), .EdgeSide (0 unknown, 1 wall/rising,
%                             2 drop/falling), .Valid
%     speed_mps (1,1) double  current speed, m/s
%     opts.egoWidth_m           body width without mirrors,     default 1.8
%     opts.mirrorWidth_m        added by EACH mirror,           default 0.20
%     opts.mirrorsFolded        S4 .MirrorsFolded, from B,      default false
%     opts.egoLength_m          body length, for the sweep,     default 4.7
%     opts.curvature_1pm        path curvature, 1/m, sign
%                               ignored - a turn either way
%                               sweeps wider,                   default 0
%     opts.anchorLowSpeed_mps   the "2 km/h" anchor,            default 2/3.6
%     opts.anchorLowClear_m     "centimetres" there,            default 0.10
%     opts.anchorHighSpeed_mps  the "40 km/h" anchor,           default 40/3.6
%     opts.anchorHighClear_m    "~1.5 m" there,                 default 1.50
%     opts.dropFactor           drop clearance / wall clearance, default 2.0
%     opts.fallbackCorridor_m   used when S9 .Valid is false,   default 1.50
%
%   TODO(unverified): every default above is a DESIGN CHOICE traceable to
%   D-planner.md D8 and AGENTS.md S9, not a measured figure. The two clearance
%   anchors are the numbers those documents state. dropFactor = 2.0 is not stated
%   anywhere - it encodes "a drop is worse than a wall" and nothing has measured
%   how much worse. Nothing here has been checked against World data.
%
%   OUTPUT  out struct
%     .h_road           double, m. The barrier. >= 0 is safe
%     .Violated         logical, true when h_road < 0
%     .dMin_m           double, m, what was subtracted in total
%     .HalfFootprint_m  double, m, the body half-width actually used
%     .SweepExtra_m     double, m, the part of that owed to turning
%     .Clearance_m      double, m, the free room demanded beyond the body
%     .EdgeDistance_m   double, m, the distance actually used
%     .EdgeSide         uint8, the side actually used
%     .UsedFallback     logical, true when S9 was invalid and the corridor stood in
%     .Reason           string, in words
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
%
%   See also SIH.PLANNER.SPEEDLIMIT, SIH.PLANNER.VELOCITYOBSTACLE

arguments
    space     (1,1) struct
    speed_mps (1,1) double {mustBeNonnegative}
    opts.egoWidth_m          (1,1) double {mustBePositive} = 1.8
    opts.mirrorWidth_m       (1,1) double {mustBeNonnegative} = 0.20
    opts.mirrorsFolded       (1,1) logical = false
    opts.egoLength_m         (1,1) double {mustBePositive} = 4.7
    opts.curvature_1pm       (1,1) double {mustBeFinite} = 0
    opts.anchorLowSpeed_mps  (1,1) double {mustBeNonnegative} = 2/3.6
    opts.anchorLowClear_m    (1,1) double {mustBeNonnegative} = 0.10
    opts.anchorHighSpeed_mps (1,1) double {mustBePositive} = 40/3.6
    opts.anchorHighClear_m   (1,1) double {mustBeNonnegative} = 1.50
    opts.dropFactor          (1,1) double {mustBePositive} = 2.0
    opts.fallbackCorridor_m  (1,1) double {mustBeFinite} = 1.50
end

UNKNOWN = uint8(0); WALL = uint8(1); DROP = uint8(2);

iRequireFields(space, {'EdgeDistance','EdgeSide','Valid'}, 'space');

if opts.anchorHighSpeed_mps <= opts.anchorLowSpeed_mps
    error('sih:planner:roadBarrier:badAnchors', ...
          ['The high-speed anchor (%g m/s) must be above the low-speed one (%g m/s), ' ...
           'or the clearance line cannot be drawn.'], ...
          opts.anchorHighSpeed_mps, opts.anchorLowSpeed_mps);
end

% ---- which numbers we are actually allowed to use ----------------------------
usedFallback = ~logical(space.Valid);
if usedFallback
    edge = opts.fallbackCorridor_m;
    side = UNKNOWN;
else
    edge = double(space.EdgeDistance);
    side = uint8(space.EdgeSide);
end

% ---- the body ----------------------------------------------------------------
mirrors = opts.mirrorWidth_m;
if opts.mirrorsFolded
    mirrors = 0;
end
halfBody = opts.egoWidth_m/2 + mirrors;

% Corners sweep wider than the middle. Zero curvature gives exactly zero extra.
sweepExtra = iSweepExtra(halfBody, opts.egoLength_m, opts.curvature_1pm);
halfFootprint = halfBody + sweepExtra;

% ---- the clearance beyond the body -------------------------------------------
% A straight line through the two anchors the documents state, then scaled by
% consequence. Never negative, however the anchors are set.
slope = (opts.anchorHighClear_m - opts.anchorLowClear_m) / ...
        (opts.anchorHighSpeed_mps - opts.anchorLowSpeed_mps);
base  = opts.anchorLowClear_m - slope * opts.anchorLowSpeed_mps;
wallClearance = max(0, base + slope * speed_mps);

switch side
    case WALL
        clearance = wallClearance;
        sideWord  = "wall";
    case DROP
        clearance = opts.dropFactor * wallClearance;
        sideWord  = "drop";
    case UNKNOWN
        % Unknown is treated as a drop. The cheap mistake is too much room.
        clearance = opts.dropFactor * wallClearance;
        sideWord  = "unknown side, treated as a drop";
    otherwise
        error('sih:planner:roadBarrier:unknownEdgeSide', ...
              'Unknown EdgeSide code %d. S9 defines 0 unknown, 1 wall, 2 drop.', side);
end

dMin  = halfFootprint + clearance;
hRoad = edge - dMin;

if usedFallback
    why = sprintf( ...
        'S9 invalid: measured edge discarded, %.2f m corridor assumed, %s. h_road = %.3f m', ...
        opts.fallbackCorridor_m, sideWord, hRoad);
elseif hRoad < 0
    why = sprintf( ...
        'h_road = %.3f m: inside the margin on a %s at %.1f m/s (need %.2f m, have %.2f m)', ...
        hRoad, sideWord, speed_mps, dMin, edge);
else
    why = sprintf( ...
        'h_road = %.3f m clear of a %s at %.1f m/s (need %.2f m, have %.2f m)', ...
        hRoad, sideWord, speed_mps, dMin, edge);
end

out = struct( ...
    'h_road',          hRoad, ...
    'Violated',        hRoad < 0, ...
    'dMin_m',          dMin, ...
    'HalfFootprint_m', halfFootprint, ...
    'SweepExtra_m',    sweepExtra, ...
    'Clearance_m',     clearance, ...
    'EdgeDistance_m',  edge, ...
    'EdgeSide',        side, ...
    'UsedFallback',    usedFallback, ...
    'Reason',          string(why));
end

% ------------------------------------------------------------------ helpers

function extra = iSweepExtra(halfBody, len, kappa)
%ISWEEPEXTRA  How much wider than its own half-width a turning body sweeps.
%   The outer front corner sits further from the turn centre than the side of
%   the car does. Straight ahead the two coincide, so this is exactly zero.
if kappa == 0
    extra = 0;
    return
end
R     = 1 / abs(kappa);
outer = R + halfBody;
extra = hypot(outer, len/2) - outer;
end

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:roadBarrier:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
