function [TL, diagOut] = buildTrackListSensed(poses, who, DIMS, egoLog, P, opts)
%BUILDTRACKLISTSENSED  Phase 5 - poses/who/DIMS -> a NOISY S1 TrackList, via
%   simulated lidar+radar+near-field-ring sensing and a trackerGNN
%   (sih.scenario / sih.perception, the TEAM repo ~/dev/sih2026), instead of
%   sc.buildTrackList's exact-position passthrough.
%
%   DROP-IN REPLACEMENT for the batch precompute both *_planner_run.m scripts
%   already do:
%       for i = 1:nS, TL{i} = sc.buildTrackList(poses{i}, who, DIMS); end
%   becomes
%       TL = sc.buildTrackListSensed(poses, who, DIMS, log1, P);
%   sc.planSeat is NOT touched - it only ever reads ctx.Tracks, a cell already
%   built before the drive loop starts, and cannot tell the two apart. That is
%   the whole point of the frozen S1 TrackList contract.
%
%   WHY egoLog AND P ARE NEEDED, AND THE ONE ASSUMPTION THIS MAKES: sensing is
%   ego-relative (range/FOV/noise all depend on where the sensor mount is),
%   but TL is built as a batch BEFORE the live planner-in-seat run exists -
%   there is no real ego trajectory yet to be relative to. This uses the
%   SCRIPTED placeholder's own recorded trajectory (log1 from s1_action_run.m,
%   or L from s2_action_run.m: .t .s .e, converted to world xy+yaw via P.at)
%   as the sensor-mount reference. This is EXACT for the shipping
%   configuration (both scenarios ship on the scripted driver, option B - see
%   sih26037-s1-planner-fork) and a reasonable, disclosed approximation for
%   the planner-in-seat secondary view, whose own trajectory the scripted one
%   was authored to sit close to.
%
%   TL IS TRUNCATED TO min(numel(poses), numel(egoLog.t)). The traffic
%   scenario is deliberately run longer than the scripted driver's own PASS-1
%   log (S1: StopTime = T_END+8 vs log1's T_END), so poses can outrun egoLog.
%   Past egoLog's own end there is no real ego pose to sense relative to, and
%   the live driving loop (integratePlanner) never reaches those indices
%   anyway - it clamps to numel(TL), which this truncation only makes tighter
%   and does not otherwise change.
%
%   INPUTS
%     poses   cell array, poses{i} = actorPoses(S) snapshot, i = 1..nS
%     who     containers.Map ActorID -> tag (same as sc.buildTrackList)
%     DIMS    struct tag -> [L W H]                (same as sc.buildTrackList)
%     egoLog  struct .t .s .e - the scripted driver's own recorded trajectory,
%             SAME DT as poses
%     P       the route: needs .at(s,e) -> [xy, heading]
%   opts (name-value, all optional)
%     Seed        (1,1) double = 20260906  - one seed, the whole run reproduces
%     TrackerCfg  (1,1) struct  = struct() - forwarded to sih.perception.newTracker
%
%   OUTPUT
%     TL       cell array, 1 x min(numel(poses),numel(egoLog.t)), each an S1
%              TrackList (may be empty)
%     diagOut  struct .nDetPerFrame .nTrackPerFrame .nBuilt - for the report,
%              not read by anything downstream

arguments
    poses (1,:) cell
    who
    DIMS (1,1) struct
    egoLog (1,1) struct
    P
    opts.Seed (1,1) double = 20260906
    opts.TrackerCfg (1,1) struct = struct()
end

addpath(fileparts(fileparts(mfilename('fullpath'))));  % matlab/, sibling of +sc
assert(~isempty(which('sih.scenario.groundTruthTrack')), ...
    'sih.scenario is not on the path - the +sih repo is not where buildTrackListSensed expects it');

rs      = RandStream('mt19937ar', 'Seed', opts.Seed);
suite   = sih.scenario.sensorSuite();
tracker = sih.perception.newTracker(opts.TrackerCfg);

nBuild = min(numel(poses), numel(egoLog.t));
TL   = cell(1, nBuild);
nDet = zeros(1, nBuild);
nTrk = zeros(1, nBuild);

for i = 1:nBuild
    gt = sih.scenario.groundTruthTrack(poses{i}, who, DIMS);

    [xy, hdg] = P.at(egoLog.s(i), egoLog.e(i));
    egoPose = struct('Position',[xy 0], 'Yaw', hdg);

    dets  = sih.perception.simulateSensors(gt, egoPose, suite, egoLog.t(i), rs);
    TL{i} = sih.perception.trackObjects(dets, tracker, egoLog.t(i));

    nDet(i) = numel(dets);
    nTrk(i) = numel(TL{i});
end

diagOut = struct('nDetPerFrame', mean(nDet), 'nTrackPerFrame', mean(nTrk), 'nBuilt', nBuild);
end
