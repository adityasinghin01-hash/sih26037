function out = escapeMemory(memory, egoState, space, opts)
%ESCAPEMEMORY  Remember where you could turn around, so you never have to wonder.
%
%   Task D9, part 1. plan/D-planner.md: "S10 carries breadcrumbs of every point wide
%   enough to turn around in. When blocked you do not ask 'can I turn here', you
%   already know where the last place was."
%
%   That sentence is the whole design. Asking "can I turn around here?" at the moment
%   the road is blocked is asking it in the one place the answer is no. So the
%   question is asked continuously, while the answer is still yes, and the answer is
%   kept. Call this every step; it drops a breadcrumb whenever the car is standing
%   somewhere it could turn round in one sweep.
%
%   IT DOES NOT DECIDE WHETHER A U-TURN FITS - PLANTURN DOES
%   sih.planner.planTurn already works out how many forward/reverse sweeps a U-turn
%   needs at a given road width, and returns 1 when the road is wide enough. So this
%   file ASKS it rather than writing that geometry out a second time. If the
%   turning-circle sum is ever corrected, both the turn planner and the escape memory
%   are corrected at once, because there is only one of it.
%
%   A BREADCRUMB IS ONLY DROPPED FOR A ONE-SWEEP TURN
%   Not a three-point turn, not "possible with shuffling". An escape point exists to
%   be used when something has gone wrong, and a manoeuvre that needs five sweeps in
%   a blocked galli with a queue behind is not an escape. The bar is deliberately
%   higher than "physically possible".
%
%   THE NOSE-TO-NOSE RULE IS A QUERY ON THIS MEMORY, NOT A SEPARATE IDEA
%   plan/D-planner.md D9: "two cars meet in a galli, someone must reverse. Whoever is
%   nearer a passing place reverses." Our distance to a passing place is exactly
%   .NearestDistance_m, which this function already knows. Give it the other car's
%   distance in opts.otherEscapeDistance_m and it answers. The rule is geometric and
%   legible on purpose - there is no negotiation, no radio and nothing to agree.
%
%   A TIE GOES TO THE CAR THAT IS NOT US. If both are equidistant, somebody must move
%   and both cars run this same rule, so a symmetric answer would deadlock twice over.
%   Yielding on the tie costs one reverse and can never gridlock.
%
%   WHERE THE ROAD WIDTH COMES FROM, AND THE ONE THING UNSETTLED ABOUT IT
%   Aditya ruled on 5 September 2026 that S9 does NOT gain a width field: section 3
%   is frozen, adding a field costs six people, and the width is to be DERIVED from
%   the edge distances instead. That ruling is followed - nothing here asks for a new
%   field.
%
%   The derivation he gave is left edge plus right edge. This file cannot do that,
%   because it can only see ONE edge: sih.planner.roadBarrier, the other S9 consumer,
%   documents S9 as carrying a single .EdgeDistance (signed, + inside) with a single
%   .EdgeSide saying which side it is. One distance and one side give the distance to
%   the NEAREST edge, not both. So the width is taken as twice that, which is exact
%   for a centred car and an UNDERESTIMATE otherwise - the safe direction, because it
%   drops fewer breadcrumbs and never phantom ones.
%
%   Aditya checked AGENTS.md section 3 on 5 September 2026 and corrected himself:
%   .EdgeDistance and .EdgeSide are both SCALAR - one distance to the nearest edge
%   and one side - exactly as roadBarrier.m documents. Left-plus-right was never
%   available. Section 3 does not change for this, two days out, so the doubling
%   above STANDS for the demo, and .LocalWidth_m keeps reporting what was assumed.
%
%   THE REAL WIDTH IS ALREADY REACHABLE, AND IT IS NOT EdgeDistance
%   S9 also carries a vehicleCostmap, and Aditya verified by running on R2026a that
%   checkFree(costmap, [x y]) works. Stepping laterally from the ego until checkFree
%   goes false on each side gives a true local width with no contract change and no
%   centred assumption at all.
%   TODO(unverified): DO NOT BUILD THAT BEFORE THE 7th. matlab/+sih/+perception/ is
%   empty, so there is no S9 to query, and the doubling is already safe in the
%   conservative direction. It is the post-7th fix and it is recorded here so it is
%   not rediscovered from scratch.
%
%   AN INVALID S9 RECORDS NOTHING, AND THAT IS NOT THE SAME AS A NARROW ROAD
%   With S9 invalid there is no measured edge, so no breadcrumb is dropped and
%   .Reason says why. A remembered escape point that was never really there is worse
%   than no memory at all, because the car would drive to it while blocked.
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
%
%   INPUTS
%     memory    struct  the memory so far. Pass sih.planner.escapeMemory's own output
%                       back in, or an empty struct on the first step. Reads .Points,
%                       .Widths_m and .Times when present
%     egoState  (1,1) struct  .Position (1x3), .Yaw (rad)
%     space     (1,1) struct  S9 DrivableSpace. Reads .EdgeDistance and .Valid
%     opts.time_s                 the clock, stamped onto a breadcrumb,   default NaN
%     opts.minSpacing_m           do not record two breadcrumbs closer
%                                 together than this,                     default 5.0
%     opts.maxPoints              keep at most this many, oldest dropped, default 200
%     opts.otherEscapeDistance_m  the other car's distance to ITS nearest
%                                 passing place, for the nose-to-nose
%                                 rule. NaN means no deadlock to settle,  default NaN
%     opts.roadWidth_m            width used when S9 is valid but carries
%                                 no usable edge,                         default 7.0
%
%   TODO(unverified): minSpacing and maxPoints are DESIGN CHOICES, not measured
%   figures, and by Aditya's ruling of 5 September 2026 both must be written into
%   config.json before any of this is demonstrated, and neither may ever be described
%   as measured. NEITHER IS RECORDED THERE YET: sih.runExperiment writes a config.json
%   on every run, but it captures the scenario only - stop time, sample time, traffic
%   rate, turn ratio, MATLAB version, git commit - and no planner design number.
%   runExperiment.m is not Person A's file, so they are listed for its owner.
%
%   OUTPUT  out, a struct. FEED IT BACK IN NEXT STEP.
%     .Points            Nx2 double, the breadcrumbs, world frame
%     .Widths_m          Nx1 double, the width assumed at each one
%     .Times             Nx1 double, when each was recorded
%     .Count             double, how many are held
%     .Recorded          logical, this call dropped a breadcrumb
%     .LocalWidth_m      double, the width assumed here, NaN when S9 was invalid
%     .OneSweepHere      logical, a U-turn fits here in one sweep
%     .HasEscape         logical, there is a breadcrumb BEHIND the car
%     .NearestIndex      double, which one. NaN when there is none
%     .NearestPoint      1x2 double, where it is. [NaN NaN] when there is none
%     .NearestDistance_m double, how far back. NaN when there is none
%     .WeReverse         logical, the nose-to-nose answer. FALSE WHEN UNDECIDED -
%                        read .DeadlockDecided before believing it
%     .DeadlockDecided   logical, a nose-to-nose comparison was actually made
%     .Reason            string, one line, for D5's log

arguments
    memory   struct
    egoState (1,1) struct
    space    (1,1) struct
    opts.time_s                (1,1) double                          = NaN
    opts.minSpacing_m          (1,1) double {mustBePositive}         = 5.0
    opts.maxPoints             (1,1) double {mustBePositive}         = 200
    opts.otherEscapeDistance_m (1,1) double                          = NaN
    opts.roadWidth_m           (1,1) double {mustBePositive}         = 7.0
end

iRequireFields(egoState, {'Position','Yaw'}, 'egoState');
iRequireFields(space,    {'Valid'},          'space');

pos = egoState.Position(1:2);
pos = pos(:).';

% ---- carry the memory forward ------------------------------------------------------
% An empty struct is the ordinary first step, not an error.
pts    = iFieldOr(memory, 'Points',   zeros(0,2));
widths = iFieldOr(memory, 'Widths_m', zeros(0,1));
times  = iFieldOr(memory, 'Times',    zeros(0,1));

out = struct('Points', pts, 'Widths_m', widths, 'Times', times, ...
             'Count', size(pts,1), 'Recorded', false, 'LocalWidth_m', NaN, ...
             'OneSweepHere', false, 'HasEscape', false, 'NearestIndex', NaN, ...
             'NearestPoint', [NaN NaN], 'NearestDistance_m', NaN, ...
             'WeReverse', false, 'DeadlockDecided', false, 'Reason', "");

% ---- is HERE somewhere we could turn around? ---------------------------------------

if ~logical(space.Valid)
    out.Reason = "S9 invalid - no breadcrumb dropped, the road was never measured";
else
    if isfield(space, 'EdgeDistance') && isfinite(space.EdgeDistance)
        % EdgeDistance is to the NEAREST edge. Twice it is the width of a car in the
        % middle, and an underestimate otherwise - see the header.
        out.LocalWidth_m = 2 * abs(double(space.EdgeDistance));
    else
        out.LocalWidth_m = opts.roadWidth_m;
    end

    % Ask planTurn, do not re-derive. A U-turn here, at this width.
    uturn = sih.planner.planTurn( ...
                struct('GoalHeading', egoState.Yaw + pi, 'Valid', true), ...
                egoState, roadWidth_m = max(out.LocalWidth_m, eps));

    out.OneSweepHere = uturn.NumSegments == 1;

    if out.OneSweepHere && iFarEnoughFromLast(pts, pos, opts.minSpacing_m)
        out.Points   = [out.Points;   pos];
        out.Widths_m = [out.Widths_m; out.LocalWidth_m];
        out.Times    = [out.Times;    opts.time_s];
        out.Recorded = true;

        % Oldest first out. A memory that grows without bound would eventually be the
        % slowest thing in a 10 Hz loop.
        if size(out.Points,1) > opts.maxPoints
            keep = (size(out.Points,1) - opts.maxPoints + 1) : size(out.Points,1);
            out.Points   = out.Points(keep, :);
            out.Widths_m = out.Widths_m(keep);
            out.Times    = out.Times(keep);
        end
    end
    out.Count = size(out.Points,1);
end

% ---- where is the last place we could have turned around? --------------------------
% BEHIND only. A breadcrumb ahead of the car is not an escape from something that is
% blocking the road ahead - driving further forward to reach it is the manoeuvre we
% are trying to avoid.

if out.Count > 0
    heading = [cos(egoState.Yaw), sin(egoState.Yaw)];
    rel     = out.Points - pos;
    behind  = (rel * heading.') < 0;

    if any(behind)
        d          = vecnorm(rel, 2, 2);
        d(~behind) = Inf;
        [dMin, k]  = min(d);

        out.HasEscape         = true;
        out.NearestIndex      = k;
        out.NearestPoint      = out.Points(k, :);
        out.NearestDistance_m = dMin;
    end
end

% ---- the nose-to-nose rule ---------------------------------------------------------
% Whoever is nearer a passing place reverses. Both cars run this same comparison, so
% it must not be symmetric on a tie - see the header.

if isfinite(opts.otherEscapeDistance_m)
    if out.HasEscape
        out.DeadlockDecided = true;
        out.WeReverse       = out.NearestDistance_m <= opts.otherEscapeDistance_m;
    else
        % We have nowhere to reverse to. Saying "we reverse" would send the car
        % backwards down a galli with no passing place in it.
        out.DeadlockDecided = true;
        out.WeReverse       = false;
    end
end

out.Reason = iReason(out, opts);
end

% -------------------------------------------------------------------------------------

function tf = iFarEnoughFromLast(pts, pos, minSpacing)
% Breadcrumbs every step at 10 Hz would be hundreds of points a metre apart, all
% saying the same thing. One per minSpacing is enough to navigate back to.
if isempty(pts)
    tf = true;
else
    tf = norm(pts(end,:) - pos) >= minSpacing;
end
end

function v = iFieldOr(s, name, dflt)
if isfield(s, name) && ~isempty(s.(name))
    v = s.(name);
else
    v = dflt;
end
end

function r = iReason(out, opts)
if strlength(out.Reason) > 0
    r = out.Reason;                                  % S9 already explained itself
elseif out.Recorded
    r = "escape point recorded, " + out.Count + " held";
elseif out.OneSweepHere
    r = "could turn here, but within " + iFmt(opts.minSpacing_m) + " m of the last one";
else
    r = "cannot turn around here - " + iFmt(out.LocalWidth_m) + " m of width";
end

if out.DeadlockDecided
    if out.WeReverse
        r = r + ". NOSE-TO-NOSE: we reverse, nearer the passing place";
    else
        r = r + ". NOSE-TO-NOSE: they reverse, we hold";
    end
end
end

function s = iFmt(x)
s = string(sprintf('%.2f', x));
end

function iRequireFields(s, names, argName)
% Fail loudly and by name, rather than three lines later inside the arithmetic.
for i = 1:numel(names)
    if ~isfield(s, names{i})
        error('sih:planner:escapeMemory:missingField', ...
              '%s is missing required field ''%s''.', argName, names{i});
    end
end
end
