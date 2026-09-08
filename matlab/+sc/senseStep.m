function TL = senseStep(rig, poses, who, DIMS, egoPose, t)
%SENSESTEP  One step of live sensing from the ego's ACTUAL pose - see sc.senseRig
%   for why this exists and what it replaces.
%
%   INPUTS
%     rig      from sc.senseRig - carries the suite, the tracker and the stream
%     poses    actorPoses(S) snapshot for this step (the same thing
%              buildTrackListSensed reads out of the precomputed cell)
%     who      containers.Map ActorID -> tag
%     DIMS     struct tag -> [L W H]
%     egoPose  struct .Position (1x3) .Yaw (rad) - WHERE THE EGO ACTUALLY IS
%     t        simulation time, s
%
%   OUTPUT
%     TL       an S1 TrackList for this step. MAY BE EMPTY (S1 guarantee 3).

gt   = sih.scenario.groundTruthTrack(poses, who, DIMS);
dets = sih.perception.simulateSensors(gt, egoPose, rig.Suite, t, rig.Stream);
TL   = sih.perception.trackObjects(dets, rig.Tracker, t);
end
