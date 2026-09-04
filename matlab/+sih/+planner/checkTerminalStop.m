function result = checkTerminalStop(candidate, future, startIndex, opts)
%CHECKTERMINALSTOP  Could we still brake to a stop from here, under this future?
%
%   Task D6, the step that turns reading (a) into reading (b).
%
%   WHAT THE RULING ASKS FOR
%   plan/D6-TRUNK-RULING.md: "The trunk must end in a state from which the ego
%   can brake to a full stop inside the space that is free under both futures."
%
%   Reading (a) - the longest collision-free prefix - is not enough on its own. A
%   stretch can be clear along every metre of itself and still END somewhere that
%   every continuation collides. Combine that with D9 setting Committed and the
%   planner may commit, irrevocably, to a trajectory that has already lost. The
%   ruling calls that "the crash, and we would have built it deliberately."
%
%   WHY THIS IS ONE CHECK AND NOT A SECOND ROUND OF PLANNING
%   Braking to a stop is ONE KNOWN CONTROL ACTION, so the continuation does not
%   have to be searched for - it can be written down. That is the whole reason
%   (b) is cheap. A full second generation round from the end of the trunk would
%   buy a LESS CONSERVATIVE (b) with the SAME guarantee, and the ruling is
%   explicit that it is a later optimisation. If a future session finds itself
%   designing a second generation pass, it has misread the ruling.
%
%   WHAT THE GUARANTEE ACTUALLY IS
%   Recursive feasibility with respect to the stop fallback: at every committed
%   step the car can either carry on with the plan or execute the stop, and the
%   stop is known-safe under both futures. That is forward invariance, which is
%   what a barrier function guarantees and what this project claims when it calls
%   h = lambda - beta a safety proof. Reading (a) does not support that claim.
%
%   THE STOP IS STRAIGHT, AND THAT IS DELIBERATE
%   It brakes along the heading the candidate already has. Steering while braking
%   would be a second decision inside the fallback, and a fallback with decisions
%   in it is not a fallback. Straight-line braking is also the most conservative
%   readable choice: it is what the car can certainly do.
%
%   INPUTS
%     candidate  (1,1) struct  one element from sih.planner.generateCandidates.
%                              Reads .Times and .States (Nx3, [x y theta])
%     future     (1,1) struct  one element from sih.planner.predictAgentFutures
%     startIndex (1,1) double  the step to brake from - the end of the prefix
%                              being tested
%     opts.aBrake_mps2      braking used for the fallback,   default 4.0
%     opts.dwellAfterStop_s how long to keep checking after
%                           the car has stopped,             default 0.0
%     opts.egoLength_m      passed to checkTrajectorySafety, default 4.7
%     opts.egoWidth_m       passed to checkTrajectorySafety, default 1.8
%     opts.inflation_m      passed to checkTrajectorySafety, default 0.0
%
%   opts.dwellAfterStop_s DEFAULTS TO ZERO AND THAT IS A READING, NOT AN
%   OVERSIGHT. The ruling asks that the car can "brake to a full stop inside the
%   space that is free" - it says nothing about how long it must then survive
%   standing there. A stopped car can still be driven into, so a stricter reading
%   keeps checking after the wheels stop. That reading is available by setting
%   this above zero. It is not the default because the default must be the thing
%   the ruling actually says.
%
%   OUTPUT  result struct
%     .Safe             logical, true when the whole stop is collision-free
%     .StartIndex       double, echoed back
%     .StopSpeed_mps    double, the speed being shed
%     .StopDistance_m   double, how far the car travels while stopping
%     .StopDuration_s   double, how long that takes
%     .StopTimes        Kx1 double, the fallback's own clock
%     .StopStates       Kx3 double, [x y theta] along the fallback
%     .FirstUnsafeTime  double, s, NaN when the stop is clear
%     .Label            string, whose future this was checked against
%     .TrackID          uint32
%
%   TIME BASE: the stop begins at candidate.Times(startIndex) and runs on the
%   candidate's own step. Where the fallback outlives the prediction,
%   checkTrajectorySafety holds the future's last pose, because a road user whose
%   prediction ran out has not disappeared.
%
%   Tested against hand-constructed candidates and futures; not yet validated
%   against World data.
%
%   See also SIH.PLANNER.CHECKTRAJECTORYSAFETY, SIH.PLANNER.PLANCONTINGENCY,
%            SIH.PLANNER.FINDSHAREDTRUNK

arguments
    candidate  (1,1) struct
    future     (1,1) struct
    startIndex (1,1) double {mustBePositive, mustBeInteger}
    opts.aBrake_mps2      (1,1) double {mustBePositive} = 4.0
    opts.dwellAfterStop_s (1,1) double {mustBeNonnegative} = 0.0
    opts.egoLength_m      (1,1) double {mustBePositive} = 4.7
    opts.egoWidth_m       (1,1) double {mustBePositive} = 1.8
    opts.inflation_m      (1,1) double {mustBeNonnegative} = 0.0
end

iRequireFields(candidate, {'Times','States'}, 'candidate');

t = candidate.Times(:);
S = candidate.States;
n = numel(t);

if size(S,1) ~= n
    error('sih:planner:checkTerminalStop:sizeMismatch', ...
          'candidate has %d states but %d times. They must match one to one.', size(S,1), n);
end
if n < 2
    error('sih:planner:checkTerminalStop:candidateTooShort', ...
          ['candidate has %d step(s). At least two are needed, because the speed to ' ...
           'shed is measured from how far the path moves between them.'], n);
end
if startIndex > n
    error('sih:planner:checkTerminalStop:startBeyondEnd', ...
          'startIndex %d is past the candidate''s last step, %d.', startIndex, n);
end

dt = iStepOf(t);

% The speed to shed, taken from the path's own clock - the same rule
% sih.planner.followTrunk uses, so the two never disagree about how fast the
% committed path is going.
v0 = iSpeedAt(S, t, startIndex);

stopDuration = v0 / opts.aBrake_mps2;
stopDistance = v0^2 / (2 * opts.aBrake_mps2);

theta = S(startIndex,3);
p0    = S(startIndex,1:2);

% The fallback's own clock: from where the prefix ends, through the stop, and
% then however long we insist on standing still and staying clear.
tEnd  = stopDuration + opts.dwellAfterStop_s;
tRel  = (0:dt:tEnd)';
if numel(tRel) < 2
    tRel = [0; dt];        % a standing start still gets a real interval to check
end

% Distance covered while braking, held once stopped. Solved rather than
% integrated, so a stop is a stop and not a stop plus half a step of drift.
moving      = tRel < stopDuration;
travelled   = zeros(size(tRel));
travelled(moving)  = v0*tRel(moving) - 0.5*opts.aBrake_mps2*tRel(moving).^2;
travelled(~moving) = stopDistance;

unit  = [cos(theta) sin(theta)];
stopStates = [p0 + travelled .* unit, repmat(theta, numel(tRel), 1)];
stopTimes  = t(startIndex) + tRel;

stopPath = struct('Times', stopTimes, 'States', stopStates);

check = sih.planner.checkTrajectorySafety(stopPath, future, ...
            egoLength_m = opts.egoLength_m, ...
            egoWidth_m  = opts.egoWidth_m, ...
            inflation_m = opts.inflation_m);

result = struct( ...
    'Safe',            check.AllSafe, ...
    'StartIndex',      startIndex, ...
    'StopSpeed_mps',   v0, ...
    'StopDistance_m',  stopDistance, ...
    'StopDuration_s',  stopDuration, ...
    'StopTimes',       stopTimes, ...
    'StopStates',      stopStates, ...
    'FirstUnsafeTime', check.FirstUnsafeTime, ...
    'Label',           future.Label, ...
    'TrackID',         uint32(future.TrackID));
end

% ------------------------------------------------------------------ helpers

function dt = iStepOf(t)
%ISTEPOF  The candidate's own timestep. Uses the median so one odd gap in a
%         hand-built fixture cannot set the whole fallback's resolution.
d = diff(t);
d = d(d > 0);
if isempty(d)
    error('sih:planner:checkTerminalStop:zeroTimestep', ...
          'candidate.Times never advances, so the stop has no clock to run on.');
end
dt = median(d);
end

function v = iSpeedAt(S, T, j)
%ISPEEDAT  The speed the path implies at step j: how far it moved over how long.
%   The segment ARRIVING at j is used, because that is the speed the path is
%   travelling when it gets there. At the first step the leaving one stands in.
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

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:checkTerminalStop:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
