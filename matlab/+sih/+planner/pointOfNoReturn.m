function out = pointOfNoReturn(exposure_m, progress_m, speed_mps, terminal, opts)
%POINTOFNORETURN  The moment after which aborting is worse than continuing.
%
%   Task D9, part 2. plan/D-planner.md: "compute the moment after which aborting is
%   worse than continuing. Before it, abort freely. After it, STOP RE-DECIDING. A
%   10 Hz planner will dither halfway across a cut unless you forbid it, and
%   dithering in the middle is what causes the crash."
%
%   THE SUM, AND WHY IT IS THIS ONE
%   A cut is an exposed stretch of length L. Standing at progress s along it, there
%   are two ways out and only two:
%
%       forward   L - s                          drive out of the far side
%       backward  s + v^2 / (2*aBrake)           stop, then reverse back out
%
%   The backward cost carries the braking distance because a car cannot start
%   reversing until it has stopped, and every metre spent stopping is a metre further
%   in. Set the two equal and the crossing point is
%
%       s* = ( L - v^2/(2*aBrake) ) / 2
%
%   Past s*, going on clears the exposure sooner than backing out does, so aborting
%   is the more dangerous choice even though it feels like the cautious one. That is
%   the whole of it: no threshold anybody picked, no tuning constant, just the two
%   distances compared.
%
%   THE SUM CAN COME OUT NEGATIVE, AND THAT IS THE MOST IMPORTANT CASE
%   Enter fast enough and v^2/(2*aBrake) exceeds L, so s* is negative: the point of
%   no return is BEHIND the entry line and the car was committed before it started.
%   This is not a degenerate case to clamp away - it is exactly the situation that
%   kills, and .PassedBeforeEntry reports it so a log can show the car never had a
%   choice. Clamping s* to zero would hide it.
%
%   IT DOES NOT SET Committed, AND IT MAY NOT
%   Committed is Person B's, held in the Stateflow chart. This returns .MayCommit,
%   which is Person A's geometry saying the latch is ALLOWED - never that it is set.
%
%   AND .MayCommit IS GATED ON THE TERMINAL STOP, BY RULING
%   plan/D6-TRUNK-RULING.md: Committed stays false until the terminal braking check
%   has landed. So this takes sih.planner.checkTerminalStop's result and refuses to
%   permit the latch unless that check ran and came back safe. A car may not commit
%   to a manoeuvre it has not proved it can stop out of. An unverified stop is
%   treated exactly like an unsafe one - .MayCommit false, and .Reason says which.
%
%   BEFORE THE POINT, ABORT FREELY. AFTER IT, STOP RE-DECIDING.
%   .Passed is the answer to "may I still change my mind". The planner runs at 10 Hz
%   and the geometry it sees jitters; re-deciding on every frame in the middle of a
%   cut is the dithering the plan names. Once .Passed is true the caller commits and
%   holds, and the 50-100 Hz barrier underneath is what still stops the car if
%   something really does go wrong. Committing is not the same as stopping looking.
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
%
%   INPUTS
%     exposure_m  (1,1) double  L, the length of the exposed stretch - the cut, the
%                               merge, the width of the stream being crossed
%     progress_m  (1,1) double  s, how far into it the car already is. 0 at entry
%     speed_mps   (1,1) double  current speed
%     terminal    (1,1) struct  sih.planner.checkTerminalStop's result. Reads .Safe.
%                               PASS THE REAL ONE - see the ruling above
%     opts.aBrake_mps2          braking used to size the stop,    default 4.0
%     opts.marginFactor         push the point later by this much
%                               when unsure. 1.0 is the honest
%                               geometry,                         default 1.0
%
%   TODO(unverified): aBrake defaults to 4.0 m/s^2, matching sih.planner.speedLimit
%   so the two cannot disagree about how hard this car brakes. It is deliberately
%   gentler than S4's -6 m/s^2 floor, because this sizes a controlled stop and not an
%   emergency one. It and marginFactor are DESIGN CHOICES, and by Aditya's ruling of
%   5 September 2026 both must be written into config.json before any of this is
%   demonstrated, and neither may ever be described as measured. config.json does not
%   exist in the repository yet.
%
%   OUTPUT  out, a struct
%     .Distance_m          double, s*, where the point of no return sits. MAY BE
%                          NEGATIVE - see above
%     .Passed              logical, the car is at or past it
%     .PassedBeforeEntry   logical, s* was negative: committed on arrival
%     .ForwardDistance_m   double, L - s, the cost of going on
%     .BackwardDistance_m  double, s + stopping, the cost of backing out
%     .StoppingDistance_m  double, v^2/(2*aBrake)
%     .MayCommit           logical, Person A's geometry permits Person B to latch
%                          Committed. NEVER sets it
%     .TerminalChecked     logical, a terminal stop result was supplied at all
%     .Valid               logical, the inputs made a usable answer
%     .Reason              string, one line, for D5's log

arguments
    exposure_m (1,1) double
    progress_m (1,1) double
    speed_mps  (1,1) double
    terminal   (1,1) struct
    opts.aBrake_mps2  (1,1) double {mustBePositive} = 4.0
    opts.marginFactor (1,1) double {mustBePositive} = 1.0
end

out = struct('Distance_m', NaN, 'Passed', false, 'PassedBeforeEntry', false, ...
             'ForwardDistance_m', NaN, 'BackwardDistance_m', NaN, ...
             'StoppingDistance_m', NaN, 'MayCommit', false, ...
             'TerminalChecked', false, 'Valid', false, 'Reason', "");

% ---- the invalid path, built first because it is the likely one --------------------

if ~isfinite(exposure_m) || exposure_m <= 0
    out.Reason = "no exposed stretch to be committed to";
    return
end
if ~isfinite(progress_m) || ~isfinite(speed_mps) || speed_mps < 0
    out.Reason = "progress or speed is not a usable number";
    return
end

out.Valid = true;

% ---- the two ways out --------------------------------------------------------------

out.StoppingDistance_m = speed_mps^2 / (2 * opts.aBrake_mps2);
out.ForwardDistance_m  = exposure_m - progress_m;
out.BackwardDistance_m = progress_m + out.StoppingDistance_m;

% Not clamped. A negative answer is the case that matters - see the header.
out.Distance_m = opts.marginFactor * (exposure_m - out.StoppingDistance_m) / 2;

out.PassedBeforeEntry = out.Distance_m < 0;
out.Passed            = progress_m >= out.Distance_m;

% ---- may Person B latch Committed? -------------------------------------------------
% Two conditions. The geometry says the decision is made, AND the terminal stop was
% checked and came back safe - D6-TRUNK-RULING.md. An unverified stop is treated as
% an unsafe one, because a car may not commit to a manoeuvre it cannot stop out of.

out.TerminalChecked = isfield(terminal, 'Safe');
terminalSafe        = out.TerminalChecked && logical(terminal.Safe);
out.MayCommit       = out.Passed && terminalSafe;

% ---- say which of those it was ------------------------------------------------------

if ~out.TerminalChecked
    out.Reason = "terminal stop was never checked - the latch stays shut";
elseif ~terminalSafe
    out.Reason = "terminal stop is not safe - the latch stays shut";
elseif out.PassedBeforeEntry
    out.Reason = "committed on arrival - stopping needs " + ...
                 iFmt(out.StoppingDistance_m) + " m and the exposure is only " + ...
                 iFmt(exposure_m) + " m. There was never a choice";
elseif out.Passed
    out.Reason = "past the point of no return at " + iFmt(out.Distance_m) + ...
                 " m - going on clears in " + iFmt(out.ForwardDistance_m) + ...
                 " m, backing out in " + iFmt(out.BackwardDistance_m) + ...
                 " m. STOP RE-DECIDING";
else
    out.Reason = "may still abort - " + ...
                 iFmt(out.Distance_m - progress_m) + " m before the point of no return";
end
end

% -------------------------------------------------------------------------------------

function s = iFmt(x)
s = string(sprintf('%.2f', x));
end
