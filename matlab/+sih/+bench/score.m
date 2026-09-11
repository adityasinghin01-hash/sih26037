function S = score(M)
%SCORE  A NAVSIM-style PDMS score from sih.metrics.computeM1toM10's own
%   output. Phase 1 of the planner/ML side-build ("Bring Your Own Planner"),
%   11 Sep 2026.
%
%   REAL, CITED STRUCTURE, NOT INVENTED HERE: NAVSIM's own Predictive Driver
%   Model Score is safety terms as MULTIPLICATIVE GATES - any one real
%   violation zeroes the whole score, because safety cannot be averaged away
%   by good comfort elsewhere - times quality terms as a WEIGHTED AVERAGE on
%   top. This project already computes every number the gates and the
%   quality terms below read (M1-M10, BarrierViolations_Imminent); this
%   function formalizes what's already measured. It adds no new safety math.
%
%   SAFETY GATES (each 0 or 1; the product is 0 if ANY of them is 0)
%     NoCollision       M6_minClearance_m > 0        never actually overlapped
%                                                     any scripted actor
%     Completed         M9_completed                 reached the end of the
%                                                     route, not stuck/frozen
%     NoImminentBarrier BarrierViolations_Imminent==0 the planner's own h<0-
%                                                     AND-within-4s-horizon
%                                                     gate never fired
%
%   QUALITY TERMS (each clamped to [0,1], combined as a weighted average -
%   ONLY MEANINGFUL WHEN EVERY GATE ABOVE PASSED; a zero-gated run still gets
%   a quality number here so the report can say HOW CLOSE it came, but the
%   final PDMS is 0 regardless)
%     Progress    M1_distance_m / RouteLength_m, capped at 1 - did it
%                 actually cover the road, not just survive on it
%     Comfort     1 - |M8_maxDecel_mps2| / aRefBrake_mps2 - softer braking
%                 scores higher. aRefBrake_mps2 = 3.0, the seat's OWN D_LON
%                 hard-braking limit (demo_play.m's runPlanner: "the same
%                 seat limits every runner uses") - not a new number, the
%                 existing ceiling every driver here is already held to
%     Efficiency  1 - M7_stoppedTime_s / M2_duration_s - the fraction of the
%                 run NOT spent stopped
%
%   WEIGHTS ARE HAND-PICKED AND DISCLOSED AS SUCH: Progress 0.5, Comfort 0.3,
%   Efficiency 0.2. No dataset exists to fit these against - same disclosure
%   this project already gives its other hand-set constants (S1's Grandin
%   flight-zone figures, S2's RSS constants). Do not present this weighting
%   as tuned or validated; it is a reasonable, stated choice, nothing more.
%
%   INPUT   M  struct, sih.metrics.computeM1toM10's own output
%   OUTPUT  S  struct
%     .PDMS               double in [0,1], the final score
%     .Gates              struct of the three 0/1 safety terms
%     .GatesPassed        logical, true iff every gate above is 1
%     .Quality            struct of the three [0,1] quality terms
%     .QualityWeighted    double in [0,1], the weighted average alone
%     .Reason             string, plain-English account of the result

aRefBrake_mps2 = 3.0;

gates = struct( ...
    'NoCollision',       double(M.M6_minClearance_m > 0), ...
    'Completed',         double(logical(M.M9_completed)), ...
    'NoImminentBarrier', double(M.BarrierViolations_Imminent == 0));

gatesPassed = gates.NoCollision && gates.Completed && gates.NoImminentBarrier;
gateProduct = gates.NoCollision * gates.Completed * gates.NoImminentBarrier;

progress   = max(0, min(1, M.M1_distance_m / M.RouteLength_m));
comfort    = max(0, min(1, 1 - abs(M.M8_maxDecel_mps2) / aRefBrake_mps2));
efficiency = max(0, min(1, 1 - M.M7_stoppedTime_s / max(M.M2_duration_s, eps)));

quality = struct('Progress', progress, 'Comfort', comfort, 'Efficiency', efficiency);
qualityWeighted = 0.5*progress + 0.3*comfort + 0.2*efficiency;

PDMS = gateProduct * qualityWeighted;

if gatesPassed
    reason = sprintf( ...
        "all safety gates passed - PDMS %.3f from progress %.2f, comfort %.2f, efficiency %.2f", ...
        PDMS, progress, comfort, efficiency);
else
    failed = {};
    if ~gates.NoCollision,       failed{end+1} = "touched an actor (M6 <= 0)"; end
    if ~gates.Completed,         failed{end+1} = "never reached the end of the route"; end
    if ~gates.NoImminentBarrier, failed{end+1} = "the planner's own imminent-emergency gate fired"; end
    reason = sprintf("PDMS is 0 - a safety gate failed: %s. Quality alone would have been %.3f.", ...
        strjoin(failed, "; "), qualityWeighted);
end

S = struct('PDMS', PDMS, 'Gates', gates, 'GatesPassed', gatesPassed, ...
           'Quality', quality, 'QualityWeighted', qualityWeighted, 'Reason', string(reason));
end
