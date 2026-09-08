function tracks = buildTrackList(poses, who, DIMS)
%BUILDTRACKLIST  One actorPoses(S) snapshot -> an S1 TrackList (AGENTS.md s3),
%   in the WORLD frame.
%
%   The +sih D6 route works in the global frame: generateCandidates builds
%   candidates from the global referencePathFrenet, predictAgentFutures rolls a
%   track forward straight from track.Position, checkTrajectorySafety compares
%   the two. So the adapter feeds tracks in world coordinates - which is exactly
%   what actorPoses(S) already gives. (Phase 0 finding C: an ego-frame TrackList
%   here makes the planner ignore everything.)
%
%   INPUTS
%     poses  struct array from actorPoses(S): .ActorID .Position(1x3,m)
%            .Velocity(1x3,m/s) .Yaw(deg) ...
%     who    containers.Map  ActorID -> short name: 'cow' 'auto' 'moto_wrong'
%            'moto_over' 'tractor' 'trolley'  (built in s1_action_run.m)
%     DIMS   struct          name -> [L W H] in metres (asserted mesh dims)
%
%   OUTPUT
%     tracks  struct array, sorted by TrackID, S1 fields. MAY BE EMPTY
%             (S1 guarantee 3 - consumers must not error).

% FOUND WHILE BUILDING PHASE 5 (realistic sensing): this map never had S2's own
% tags ('wrong','bus','ace' - s2actors.m's `who` map, distinct from S1's
% 'moto_wrong'/'moto_over'). Every S2 call to this function was silently
% DROPPING the wrong-way motorcycle, the bus and the Tata Ace from the
% planner's TrackList - `~isfield(CLS,nm)` failed for all three and the loop
% below just skipped them, no error, no warning. The planner-seat S2 run
% (sih26037-s1-planner-fork) was therefore negotiating against an incomplete
% TrackList; the separation/collision numbers were unaffected (measured
% straight off poses{i}, not off this TrackList) but the planner's OWN
% awareness of those three actors was never real. Fixed here.
CLS = struct('cow',10, 'auto',4, 'moto_wrong',5, 'moto_over',5, 'wrong',5, ...
             'tractor',14, 'trolley',13, 'bus',3, 'ace',7);   % AGENTS.md S5

tracks = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
                'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});

for q = 1:numel(poses)
    id = poses(q).ActorID;
    if ~isKey(who, id), continue; end
    nm = who(id);
    if ~isfield(DIMS, nm) || ~isfield(CLS, nm), continue; end
    d = DIMS.(nm);
    tracks(end+1) = struct( ...                                     %#ok<AGROW>
        'TrackID',    uint32(id), ...
        'ClassID',    uint8(CLS.(nm)), ...
        'Position',   poses(q).Position(:).', ...
        'Velocity',   poses(q).Velocity(:).', ...
        'Extent',     [d(1) d(2) d(3)], ...
        'Yaw',        deg2rad(poses(q).Yaw), ...
        'Existence',  1, ...
        'Age',        uint32(30), ...
        'SensorMask', uint8(1));
end

if ~isempty(tracks)
    [~, ord] = sort([tracks.TrackID]);
    tracks   = tracks(ord);
end
end
