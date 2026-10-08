function [decision, reason] = gateYield(track, pYield, cfg)
%GATEYIELD  PHASE 5 - decide, per track, whether the ML yield prediction may be
%   used, or whether the planner falls back to geometric right-of-way.
%
%   [d, why] = sih.prediction.gateYield(track, pYield, cfg)
%       d   = "USE" | "FALLBACK"
%       why = a short string saying exactly which rule decided it
%
%   ===================================================================
%   THIS GATE IS CLOSED BY DEFAULT, AND THAT IS THE CORRECT BEHAVIOUR.
%   ===================================================================
%   The predictor's measured dangerous-error rate is 2.089%, 95% CI
%   [1.315%, 2.854%], on a 233-clip / 694,864-sample test set opened once
%   (11 Sep 2026, round2_final_handoff.md). The project's PRE-REGISTERED bar is
%   <= 1.00%. The CI upper bound is 2.854%, so the model does not clear its own
%   bar and the honest system-level answer is: it does not drive anything.
%
%   A per-track gate could in principle open for a SUBSET where the error rate is
%   demonstrably <= 1% - very confident predictions on well-observed vehicles, say.
%   **No such subset has been validated.** Establishing one needs held-out analysis
%   nobody has run. So `cfg.Band` has NO default: absent it, every track returns
%   FALLBACK and the planner behaves EXACTLY as it does today, bit-identical.
%
%   Inventing a band here - "0.9 is probably confident enough" - would be exactly
%   the failure this project's rules exist to prevent. Codex was asked to build
%   this and refused for the same reason, which was right.
%
%   WHEN A BAND IS EARNED, it plugs in here and nothing else changes:
%       cfg.Band = [lo hi]   % PYield in [0,lo] or [hi,1] is trusted
%       cfg.BandEvidence     % REQUIRED: what measurement established it
%
%   WHAT TO SAY OUT LOUD, whatever this returns:
%       "The predictor is advisory. It gated ON for N of M tracks. Motion still
%        rests on the physical barrier, not on the model."
%   Never let a gate that opens become "our ML drives the car."

arguments
    track  struct
    pYield double
    cfg    struct = struct()
end

decision = "FALLBACK";

% --- rule 1: no validated band means the gate cannot open. Ever. ---
if ~isfield(cfg,'Band') || isempty(cfg.Band)
    reason = "no validated confidence band configured (model is 2.089% vs a <=1% bar)";
    return
end
if ~isfield(cfg,'BandEvidence') || strlength(string(cfg.BandEvidence)) == 0
    reason = "a band was set with no evidence recorded - refusing to honour it";
    return
end

% --- rule 2: the inputs must be real numbers ---
if ~isscalar(pYield) || ~isfinite(pYield) || pYield < 0 || pYield > 1
    reason = "PYield is not a finite probability";
    return
end
if ~isfield(track,'Position') || any(~isfinite(track.Position(:)))
    reason = "track position is not finite";
    return
end
if ~isfield(track,'Velocity') || any(~isfinite(track.Velocity(:)))
    reason = "track velocity is not finite";
    return
end

% --- rule 3: enough history. The model consumes a 20-step window (S2 contract). ---
minAge = 20;
if isfield(cfg,'MinAge'), minAge = cfg.MinAge; end
if ~isfield(track,'Age') || double(track.Age) < minAge
    reason = sprintf("only %d frames of history, needs %d", ...
                     double(getfielddef(track,'Age',0)), minAge);
    return
end

% --- rule 4: the class must be one that negotiates at all ---
% A cow does not yield - that is this project's entire S1 premise, and asking a
% yield model about one is a category error, not a low-confidence reading.
negotiating = [2 3 4 5 6];                       % vehicles/riders; NOT animal classes
if isfield(cfg,'NegotiatingClasses'), negotiating = cfg.NegotiatingClasses; end
if ~isfield(track,'ClassID') || ~ismember(double(track.ClassID), negotiating)
    reason = sprintf("class %d does not negotiate (a cow does not yield)", ...
                     double(getfielddef(track,'ClassID',-1)));
    return
end

% --- rule 5: the prediction must be outside the uncertain band ---
lo = cfg.Band(1); hi = cfg.Band(2);
if pYield > lo && pYield < hi
    reason = sprintf("PYield %.3f is inside the uncertain band [%.3f %.3f]", pYield, lo, hi);
    return
end

decision = "USE";
reason   = sprintf("PYield %.3f outside [%.3f %.3f]; %d frames; class %d", ...
                   pYield, lo, hi, double(track.Age), double(track.ClassID));
end

function v = getfielddef(s, f, d)
if isfield(s,f), v = s.(f); else, v = d; end
end
