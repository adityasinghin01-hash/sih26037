function tracker = newTracker(cfg)
%NEWTRACKER  A fresh trackerGNN - MATLAB's own Sensor Fusion and Tracking
%   Toolbox multi-object tracker - configured for the S1 pipeline.
%
%   Construct ONE of these per run and reuse it for every frame of that run.
%   Constructing a new one mid-run restarts every track's history, which
%   defeats the point of tracking across frames. Verified installed and
%   licensed on this machine by actually constructing trackerGNN and
%   objectDetection (not by trusting license('test',...) - a wrong feature
%   string there gave a false "not licensed" reading first).
%
%   Uses initcvekf (a constant-velocity extended Kalman filter, position-only
%   measurement) as the per-track filter - not a hand-rolled alpha-beta
%   filter. Velocity is never measured directly; the filter estimates it
%   purely from the position history, which is the actual point of using a
%   Kalman filter here rather than a shortcut. TrackID assignment - stable
%   across frames, never reused (AGENTS.md S1) - is trackerGNN's own, for
%   free.
%
%   cfg (optional) struct, all fields optional:
%     .AssignmentThreshold    default 30    - trackerGNN's own default. This
%        is a NORMALIZED (Mahalanobis) gating distance, not a distance in
%        metres - do not reinterpret it as one.
%     .ConfirmationThreshold  default [2 3] - M-of-N hits to confirm a track
%     .DeletionThreshold      default [3 3] - M-of-N consecutive misses to
%        drop a track. VERIFIED empirically (see the Phase 5 build notes):
%        with these defaults a track built on 4 clean hits survives 2
%        consecutive misses (coasted) and is gone on the 3rd.
%     .MaxNumTracks           default 500   - trackerGNN's OWN default is 100,
%        and A REAL S1 RUN EXCEEDS IT: found while validating Phase 8, a full
%        62 s S1 run assigns 133 distinct TrackIDs (several actors repeatedly
%        cross radar's 150 m boundary as the ego travels 610 m, and each
%        re-entry after a deletion is a NEW track, never reusing the old ID -
%        that IS the "stable, never reused" contract working as intended, it
%        just uses more IDs than 100 over a long run). Once trackerGNN hits
%        MaxNumTracks it silently stops creating new tracks - no error, no
%        warning - which produced a real, measured consequence: a ~20 s
%        continuous stretch with ZERO tracks output, exactly overlapping an
%        S1 collision that looked at first like a brief sensor-dropout effect
%        but was actually this. 500 gives 5x headroom over the measured 133,
%        not a round number picked without evidence.

arguments
    cfg (1,1) struct = struct()
end

assignThr = getf(cfg, 'AssignmentThreshold', 30);
conf      = getf(cfg, 'ConfirmationThreshold', [2 3]);
del       = getf(cfg, 'DeletionThreshold', [3 3]);
maxTracks = getf(cfg, 'MaxNumTracks', 500);

tracker = trackerGNN( ...
    'FilterInitializationFcn', @initcvekf, ...
    'AssignmentThreshold', assignThr, ...
    'ConfirmationThreshold', conf, ...
    'DeletionThreshold', del, ...
    'MaxNumTracks', maxTracks);
end

function v = getf(s, f, d)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
