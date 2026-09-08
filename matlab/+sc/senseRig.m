function rig = senseRig(opts)
%SENSERIG  A live sensing+tracking rig for IN-LOOP use, sensed from wherever the
%   ego ACTUALLY is.
%
%   WHY THIS EXISTS - a measured harness defect, not a preference.
%   sc.buildTrackListSensed precomputes the whole run's TrackLists BEFORE the
%   drive, using the SCRIPTED placeholder's recorded trajectory as the sensor
%   mount. Its own header discloses this and calls it "a reasonable, disclosed
%   approximation ... whose own trajectory the scripted one was authored to sit
%   close to". Once the planner behaves differently from the placeholder, they
%   are not close, and the approximation stops being reasonable:
%
%     S1  the two diverge by up to +89 m; the TrackList is EMPTY from t=44.0 to
%         t=59.5 and the ego accelerates through an empty world into the cow
%         (the recorded -0.623 m "collision" measures this, not the planner).
%     S2  divergence up to +66 m; the parked wrong-way rider leaves the list at
%         t=14.50 and the ego hits at t=25.95 an obstacle sitting 18.7 m
%         DIRECTLY AHEAD of it - which it would have seen from where it was.
%
%   Both "collisions" are the planner being scored on a world sensed from
%   somewhere it is not. Nothing in sc.planSeat can fix that; the fix is to
%   sense from the ego's own pose, each step, which is what this does.
%
%   NOTHING NEW IS SIMULATED. sih.perception.simulateSensors and trackObjects
%   are already per-step calls - buildTrackListSensed only batches them. This
%   holds the same suite/tracker/RandStream across steps and lets the caller
%   supply the real ego pose. Same seed, same sensor model, same tracker.
%
%   USE
%       rig = sc.senseRig();                       % once, before the drive loop
%       TL  = sc.senseStep(rig, poses{i}, who, DIMS, egoPose, t);   % each step
%
%   The tracker is a System object and the RandStream is a handle, so rig
%   carries live state and MUST NOT be copied between runs - build a fresh one
%   per run, which is what keeps a run reproducible.

arguments
    opts.Seed (1,1) double = 20260906          % same default as buildTrackListSensed
    opts.TrackerCfg (1,1) struct = struct()
end

addpath(fileparts(fileparts(mfilename('fullpath'))));  % matlab/, sibling of +sc
assert(~isempty(which('sih.scenario.groundTruthTrack')), ...
    'sih.scenario is not on the path - the +sih repo is not where sc.senseRig expects it');

rig = struct( ...
    'Stream',  RandStream('mt19937ar', 'Seed', opts.Seed), ...
    'Suite',   sih.scenario.sensorSuite(), ...
    'Tracker', sih.perception.newTracker(opts.TrackerCfg));
end
