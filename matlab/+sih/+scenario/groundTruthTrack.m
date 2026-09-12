function gt = groundTruthTrack(poses, who, DIMS)
%GROUNDTRUTHTRACK  One actorPoses(S) snapshot -> perfect, sensor-agnostic
%   ground truth, WORLD FRAME.
%
%   THIS IS NOT THE S1 TRACKLIST (AGENTS.md section 3). It is the input to a
%   sensor simulator (sih.perception.simulateSensors), which is what actually
%   produces S1. Ground truth carries no noise, no missed detections, and none
%   of S1's earned fields (Existence, Age, SensorMask) - those come from
%   sensing and tracking, never given for free here. It also keeps the
%   drivingScenario's own ActorID rather than a stable TrackID, because a real
%   sensor cannot see an ActorID either - re-deriving stable identity from
%   geometry alone is exactly sih.perception.trackObjects's job, and handing
%   it the ActorID here would let it cheat.
%
%   Same poses/who/DIMS shape sc.buildTrackList (matlab/+sc/ in this repo,
%   since the two-repo merge) already consumes, so this drops straight into
%   both s1_action_run.m's and s2_action_run.m's poses{i}.
%
%   INPUTS
%     poses  struct array from actorPoses(S): .ActorID .Position(1x3,m)
%            .Velocity(1x3,m/s) .Yaw(deg) ...
%     who    containers.Map  ActorID -> short scenario tag - see
%            sih.scenario.classIDByName for the full tag list
%     DIMS   struct  tag -> [L W H] in metres (asserted mesh dims)
%
%   OUTPUT
%     gt   struct array, WORLD frame. MAY BE EMPTY (no traffic this frame, or
%          every tag unrecognised - both degrade gracefully, never error).
%          Fields: .ActorID uint32  .ClassID uint8 (S5)  .Position 1x3
%                  .Velocity 1x3  .Extent 1x3  .Yaw double (rad)

gt = struct('ActorID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
            'Extent',{},'Yaw',{});

for q = 1:numel(poses)
    id = poses(q).ActorID;
    if ~isKey(who, id), continue; end
    nm = who(id);
    if ~isfield(DIMS, nm), continue; end
    cid = sih.scenario.classIDByName(nm);
    if isnan(cid), continue; end
    d = DIMS.(nm);
    gt(end+1) = struct( ...                                          %#ok<AGROW>
        'ActorID',  uint32(id), ...
        'ClassID',  uint8(cid), ...
        'Position', poses(q).Position(:).', ...
        'Velocity', poses(q).Velocity(:).', ...
        'Extent',   [d(1) d(2) d(3)], ...
        'Yaw',      deg2rad(poses(q).Yaw));
end
end
