function trunk = findSharedTrunk(candidates, prefixSteps, opts)
%FINDSHAREDTRUNK  Out of the whole fan, how far do we actually commit?
%
%   Task D6, piece 4 of 5. The trunk is the part of the plan the car commits to
%   this cycle. ReadThis.md section 11: "The trunk IS the probe." The car edges
%   forward along the stretch that is safe whichever way the other road users
%   behave, and that motion is itself the question being asked. There is no
%   separate signal.
%
%   WHICH READING OF "TRUNK" THIS IS
%   Reading A: the longest opening stretch that is collision-free under every
%   future. That is what this implements, and it is what plan/D-planner.md D6
%   describes - "the first piece safe under both futures".
%
%   Reading B, the standard contingency-MPC form, is stricter: commit to a
%   stretch only if a safe CONTINUATION still exists at the end of it, so the car
%   is never walked into a corner that is clean on the way in and has no way out.
%   Reading B needs a second round of generation from the end of the trunk, one
%   branch per future, which piece 2 can already do from any ego state.
%
%   ANSWERED, 4 SEP 2026: plan/D6-TRUNK-RULING.md rules READING B, and
%   sih.planner.planContingency's opts.trunkMode defaults to "B" accordingly. This
%   header said "not yet answered" for a day after the ruling landed and contradicted
%   the code two files away - corrected 5 September 2026. Reading A remains reachable
%   for comparison, and .Rule names which one produced the answer, so no log is ever
%   ambiguous.
%
%   THE TIE-BREAK, AND WHY IT IS THIS ORDER
%   Ties are the normal case, not the exception - every candidate that is safe
%   for the whole horizon ties at the top. Broken in this order:
%     1. longest safe stretch          - safety first, always
%     2. smallest sideways offset      - do not swerve unless swerving bought
%                                        something, per COLREGs Rule 8
%     3. most ground covered on it     - the trunk is the probe, so a trunk that
%                                        does not move asks no question
%     4. lowest index                  - deterministic, so two runs of the same
%                                        input give the same answer
%
%   STRAIGHTNESS IS CHECKED BEFORE PROGRESS, AND THAT ORDER MATTERS.
%   A path that curves out to one side is LONGER than a straight path reaching
%   the same distance forward, so ranking by path length rewards swerving for
%   nothing. Found on 4 Sep 2026 by drawing the output: with an identical safe
%   length and terminal speed available straight ahead, the planner picked -3 m
%   sideways purely because that arc was 0.1 m longer. Straightness only ever
%   breaks a tie - it can never beat a genuinely safer path, because safety is
%   compared first.
%
%   INPUTS
%     candidates  Nx1 struct array from sih.planner.generateCandidates
%     prefixSteps Nx1 double, per candidate, the number of leading timesteps that
%                 are safe under EVERY future. From sih.planner.planContingency,
%                 which takes the minimum across futures
%     opts.minTrunkTime_s  below this the trunk is treated as no trunk at all and
%                          .Blocked is set, default 0.5
%
%   OUTPUT  trunk struct
%     .CandidateIndex    double, which candidate won. NaN if there is no trunk
%     .Steps             double, committed timesteps
%     .Time              double, s, how long the commitment lasts
%     .Progress_m        double, ground covered along the committed part
%     .Times             Kx1 double, the committed part of the clock
%     .States            Kx3 double, [x y theta], the committed path itself
%     .LateralOffset_m   double, + is LEFT
%     .TerminalSpeed_mps double
%     .Blocked           logical, true when nothing worth committing to exists
%     .Rule              string, which reading produced this
%     .Reason            string, in words, why this trunk
%
%   WHAT THIS DOES NOT DO
%   It does not decide what to do when blocked. Creep, wait, horn, go around,
%   hand over - that ladder is D9, and putting it here would bury a decision the
%   project has to be able to point at.
%
%   See also SIH.PLANNER.PLANCONTINGENCY, SIH.PLANNER.CHECKTRAJECTORYSAFETY

arguments
    candidates  (:,1) struct
    prefixSteps (:,1) double
    opts.minTrunkTime_s (1,1) double {mustBeNonnegative} = 0.5
    opts.rule (1,1) string = "LONGEST_CLEAR_PREFIX (reading A)"
end

% This function only ever ranks the prefix lengths it is handed. WHICH reading
% produced them is decided by the caller - sih.planner.planContingency - so the
% name of the rule is carried in rather than assumed. The default is reading A
% because that is what a bare prefix length means if nobody says otherwise.
RULE = opts.rule;

n = numel(candidates);
if numel(prefixSteps) ~= n
    error('sih:planner:findSharedTrunk:sizeMismatch', ...
          'Got %d candidates but %d prefix values. They must match one to one.', ...
          n, numel(prefixSteps));
end

if n == 0
    trunk = iNoTrunk(RULE, "no candidates were generated - nothing to commit to");
    return
end

steps    = zeros(n,1);
timeOf   = zeros(n,1);
progress = zeros(n,1);
offset   = zeros(n,1);

for k = 1:n
    t = candidates(k).Times(:);
    s = candidates(k).States;
    p = max(0, min(round(prefixSteps(k)), numel(t)));

    steps(k)  = p;
    offset(k) = candidates(k).LateralOffset_m;

    if p >= 1
        timeOf(k) = t(p) - t(1);
    end
    if p >= 2
        progress(k) = sum(vecnorm(diff(s(1:p,1:2)), 2, 2));
    end
end

% Safety, then straightness, then progress, then index. See the header - the
% order of the middle two is deliberate and a swap re-introduces a real bug.
order = sortrows([-steps, abs(offset), -progress, (1:n)'], [1 2 3 4]);
best  = order(1,4);

if timeOf(best) < opts.minTrunkTime_s
    trunk = iNoTrunk(RULE, sprintf( ...
        "best trunk is only %.2f s, below the %.2f s minimum - treat as blocked (D9)", ...
        timeOf(best), opts.minTrunkTime_s));
    return
end

p = steps(best);
trunk = struct( ...
    'CandidateIndex',    best, ...
    'Steps',             p, ...
    'Time',              timeOf(best), ...
    'Progress_m',        progress(best), ...
    'Times',             candidates(best).Times(1:p), ...
    'States',            candidates(best).States(1:p,:), ...
    'LateralOffset_m',   candidates(best).LateralOffset_m, ...
    'TerminalSpeed_mps', candidates(best).TerminalSpeed_mps, ...
    'Blocked',           false, ...
    'Rule',              RULE, ...
    'Reason',            sprintf( ...
        "committed %.2f s (%.1f m) at %+0.1f m offset, safe under every future", ...
        timeOf(best), progress(best), candidates(best).LateralOffset_m));
end

% ------------------------------------------------------------------ helpers

function trunk = iNoTrunk(rule, reason)
trunk = struct( ...
    'CandidateIndex',    NaN, ...
    'Steps',             0, ...
    'Time',              0, ...
    'Progress_m',        0, ...
    'Times',             zeros(0,1), ...
    'States',            zeros(0,3), ...
    'LateralOffset_m',   NaN, ...
    'TerminalSpeed_mps', NaN, ...
    'Blocked',           true, ...
    'Rule',              rule, ...
    'Reason',            string(reason));
end
