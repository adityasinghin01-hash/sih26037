function out = speedLimit(space, speed_mps, opts)
%SPEEDLIMIT  One speed cap for three separate reasons.
%
%   Task D7's speed law, and the companion to D8's road barrier.
%
%       v_max = min( sqrt(aLat * R),                            hold the road
%                    sqrt(2*aBrake*(VisibleRange - v*tReact)),  stop inside sight
%                    vRoute )
%
%   WHY ONE NUMBER AND NOT THREE MODES
%   Each term is a different way of running out of road, and the tightest one
%   wins. On a hairpin the first two bind at once and no arbitration is needed,
%   because taking a minimum IS the arbitration.
%
%   THERE IS NO WEATHER MODE, AND THERE MUST NOT BE ONE
%   Fog does not need handling. It shrinks VisibleRange, the second term shrinks,
%   and the car slows down - which is exactly why a human slows in fog. A rain
%   branch would be a second mechanism for something that already falls out of
%   the first, and two mechanisms for one effect is how they drift apart.
%
%   THE SIGHT TERM CAN DEMAND A STOP, AND IT IS ALLOWED TO
%   VisibleRange - v*tReact is the ground left to brake in AFTER the distance
%   covered while reacting. If that is zero or negative there is no braking room
%   at all and the honest cap is 0 m/s. The square root is never taken of a
%   negative number here: the shortfall is reported in .SightShortfall_m instead,
%   so a log can tell "just barely stopping" from "already past it".
%
%   THE TERM IS EVALUATED AT THE CURRENT SPEED, which is what AGENTS.md S10 and
%   D-planner.md D8 both write. It is therefore a cap on what the car may do
%   next, not a fixed point solved for itself. Fine at 10 Hz, where the barrier
%   underneath runs at 50-100 Hz and can veto anything regardless.
%
%   WHAT THESE THREE TERMS DO NOT COVER - OBSERVED BY RUNNING, 5 SEPTEMBER 2026
%   None of them knows how WIDE the road is. Printing both D8 functions together
%   on a 3 m ghat road (1.5 m to each edge) gave: this law caps a hairpin of
%   R = 8 m at 4.90 m/s, and at that speed sih.planner.roadBarrier reports
%   h_road = -1.25 m beside the khai. Both numbers are correct for what each was
%   asked. The car is meant to be held back by the BARRIER in that case - the
%   50-100 Hz layer that can veto anything - not by this cap, and the two are
%   deliberately separate.
%
%   It is worth knowing that the barrier could be inverted into a fourth term:
%   the clearance grows linearly with speed, so the largest speed satisfying
%   h_road >= 0 has a closed form. That would let the cap respect road width
%   directly instead of relying on a veto. It is NOT done here, because the law
%   AGENTS.md S10 and D-planner.md D8 both state has exactly three terms, and
%   quietly adding a fourth would put a number in the plan that no document asks
%   for. Raise it with Aditya rather than assuming it.
%
%   INPUTS
%     space     (1,1) struct  S9 DrivableSpace. Reads .VisibleRange and .Valid
%     speed_mps (1,1) double  current speed, m/s, used for the reaction distance
%     opts.curvature_1pm      path curvature 1/m. 0 is straight,   default 0
%     opts.aLat_mps2          lateral grip budget,                 default 3.0
%     opts.aBrake_mps2        braking used for the sight term,     default 4.0
%     opts.tReact_s           reaction and compute latency,        default 0.5
%     opts.vRoute_mps         the route's own cap,                 default 13.89
%     opts.fallbackVisible_m  VisibleRange when S9 is invalid,     default 10.0
%
%   TODO(unverified): aLat, aBrake, tReact, vRoute and fallbackVisible are DESIGN
%   CHOICES, not measured figures, and nothing in this repository states them.
%   aBrake is deliberately gentler than S4's -6 m/s^2 floor, because the sight
%   term should size a comfortable stop rather than an emergency one. vRoute
%   defaults to 50 km/h. S10 Route carries GoalHeading, GoalPoint, BlockedEdges
%   and EscapePoints and does NOT carry a speed, so vRoute has to be passed in.
%
%   OUTPUT  out struct
%     .v_max_mps          double, the cap. Never negative
%     .Binding            string, "CURVE", "SIGHT" or "ROUTE" - which term won
%     .CurveTerm_mps      double, Inf on a straight road
%     .SightTerm_mps      double
%     .RouteTerm_mps      double
%     .Radius_m           double, Inf on a straight road
%     .BrakingRoom_m      double, VisibleRange - v*tReact. May be negative
%     .SightShortfall_m   double, how far PAST the sight limit we already are.
%                         0 unless BrakingRoom_m is negative
%     .UsedFallback       logical, true when S9 was invalid
%     .Reason             string, in words
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
%
%   See also SIH.PLANNER.ROADBARRIER, SIH.PLANNER.CHOOSEVELOCITY

arguments
    space     (1,1) struct
    speed_mps (1,1) double {mustBeNonnegative}
    opts.curvature_1pm     (1,1) double {mustBeFinite} = 0
    opts.aLat_mps2         (1,1) double {mustBePositive} = 3.0
    opts.aBrake_mps2       (1,1) double {mustBePositive} = 4.0
    opts.tReact_s          (1,1) double {mustBeNonnegative} = 0.5
    opts.vRoute_mps        (1,1) double {mustBeNonnegative} = 50/3.6
    opts.fallbackVisible_m (1,1) double {mustBeNonnegative} = 10.0
end

iRequireFields(space, {'VisibleRange','Valid'}, 'space');

usedFallback = ~logical(space.Valid);
if usedFallback
    visible = opts.fallbackVisible_m;
else
    visible = double(space.VisibleRange);
end

% ---- 1. hold the road --------------------------------------------------------
% A straight road puts no lateral demand on the tyres at all, so the term is Inf
% rather than a large finite number nothing produced.
if opts.curvature_1pm == 0
    radius    = Inf;
    curveTerm = Inf;
else
    radius    = 1 / abs(opts.curvature_1pm);
    curveTerm = sqrt(opts.aLat_mps2 * radius);
end

% ---- 2. stop inside what can be seen -----------------------------------------
brakingRoom = visible - speed_mps * opts.tReact_s;
if brakingRoom > 0
    sightTerm = sqrt(2 * opts.aBrake_mps2 * brakingRoom);
    shortfall = 0;
else
    sightTerm = 0;
    shortfall = -brakingRoom;
end

% ---- 3. the route ------------------------------------------------------------
routeTerm = opts.vRoute_mps;

terms  = [curveTerm, sightTerm, routeTerm];
labels = ["CURVE", "SIGHT", "ROUTE"];
[vMax, which] = min(terms);
binding = labels(which);

if usedFallback
    why = sprintf( ...
        'S9 invalid: %.1f m of sight assumed. %s binds at %.2f m/s', ...
        opts.fallbackVisible_m, binding, vMax);
elseif shortfall > 0
    why = sprintf( ...
        'SIGHT binds at 0 m/s: %.1f m of sight is already %.2f m short of the %.2f m needed just to react at %.1f m/s', ...
        visible, shortfall, speed_mps * opts.tReact_s, speed_mps);
else
    why = sprintf('%s binds at %.2f m/s (curve %.2f, sight %.2f, route %.2f)', ...
                  binding, vMax, curveTerm, sightTerm, routeTerm);
end

out = struct( ...
    'v_max_mps',        vMax, ...
    'Binding',          binding, ...
    'CurveTerm_mps',    curveTerm, ...
    'SightTerm_mps',    sightTerm, ...
    'RouteTerm_mps',    routeTerm, ...
    'Radius_m',         radius, ...
    'BrakingRoom_m',    brakingRoom, ...
    'SightShortfall_m', shortfall, ...
    'UsedFallback',     usedFallback, ...
    'Reason',           string(why));
end

% ------------------------------------------------------------------ helpers

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:speedLimit:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
