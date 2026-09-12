function tests = testPerceptionPipeline
%TESTPERCEPTIONPIPELINE  Phase 5 - sih.scenario (ground truth) + sih.perception
%   (simulated lidar/radar/near-field-ring + trackerGNN) -> the S1 TrackList.
%
%   RUN IT:  results = runtests('matlab/tests/testPerceptionPipeline.m'); disp(results)
%   Needs the Sensor Fusion and Tracking Toolbox (trackerGNN, objectDetection,
%   initcvekf) - verified installed and licensed on this machine by actually
%   constructing them, not by trusting a license('test',...) string (a wrong
%   feature name there gave a false "not licensed" reading during this build).
tests = functiontests(localfunctions);
end

function setupOnce(tc)
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
tc.TestData = struct();
end

% ---------------------------------------------------------------- classIDByName

function testKnownTagsMapToS5(tc)
tc.verifyEqual(sih.scenario.classIDByName("cow"),        uint8(10));
tc.verifyEqual(sih.scenario.classIDByName("car"),        uint8(1));
tc.verifyEqual(sih.scenario.classIDByName("dog"),        uint8(11));
tc.verifyEqual(sih.scenario.classIDByName("child"),      uint8(8));
tc.verifyEqual(sih.scenario.classIDByName("auto"),       uint8(4));
tc.verifyEqual(sih.scenario.classIDByName("moto_wrong"), uint8(5));
tc.verifyEqual(sih.scenario.classIDByName("moto_over"),  uint8(5));
tc.verifyEqual(sih.scenario.classIDByName("wrong"),      uint8(5));   % S2's own tag, same class
tc.verifyEqual(sih.scenario.classIDByName("tractor"),    uint8(14));
tc.verifyEqual(sih.scenario.classIDByName("trolley"),    uint8(13));
tc.verifyEqual(sih.scenario.classIDByName("bus"),        uint8(3));
tc.verifyEqual(sih.scenario.classIDByName("ace"),        uint8(7));
end

function testUnknownTagIsNaNNotError(tc)
tc.verifyTrue(isnan(sih.scenario.classIDByName("not_a_real_tag")));
end

% ---------------------------------------------------------------- groundTruthTrack

function [poses, who, DIMS] = iSyntheticFrame(id, pos, vel, tag)
poses = struct('ActorID',id, 'Position',pos, 'Velocity',vel, 'Yaw',0);
who = containers.Map('KeyType','double','ValueType','char');
who(id) = tag;
DIMS = struct(tag, [4 1.8 1.5]);
end

function testGroundTruthShapeAndFrame(tc)
[poses, who, DIMS] = iSyntheticFrame(7, [10 5 0], [-2 0 0], 'auto');
gt = sih.scenario.groundTruthTrack(poses, who, DIMS);
tc.verifyEqual(numel(gt), 1);
tc.verifyEqual(gt.ActorID, uint32(7));
tc.verifyEqual(gt.ClassID, uint8(4));
tc.verifyEqual(gt.Position, [10 5 0]);
tc.verifyEqual(gt.Extent, [4 1.8 1.5]);
end

function testGroundTruthEmptyIsSafe(tc)
who = containers.Map('KeyType','double','ValueType','char');
gt = sih.scenario.groundTruthTrack(struct('ActorID',{},'Position',{},'Velocity',{},'Yaw',{}), ...
                                    who, struct());
tc.verifyEqual(numel(gt), 0);
end

function testGroundTruthSkipsUnknownTagRatherThanError(tc)
[poses, who, DIMS] = iSyntheticFrame(9, [0 0 0], [0 0 0], 'a_tag_nobody_uses');
gt = sih.scenario.groundTruthTrack(poses, who, DIMS);
tc.verifyEqual(numel(gt), 0);
end

% ---------------------------------------------------------------- sensorSuite

function testSensorSuiteHasNoCameraAndDistinctBits(tc)
suite = sih.scenario.sensorSuite();
tc.verifyEqual(numel(suite), 3);
bits = double([suite.Bit]);
tc.verifyEqual(numel(unique(bits)), 3, 'each sensor must have its own SensorMask bit');
tc.verifyTrue(~any(bits == 4), 'bit2 (camera, value 4) must never appear - AGENTS.md: camera offline');
tc.verifyTrue(any(bits == 8), 'the near-field ring must use S1 bit3 (value 8)');
end

% ---------------------------------------------------------------- simulateSensors

function testOutOfRangeObjectNeverDetected(tc)
gt = struct('ActorID',uint32(1),'ClassID',uint8(1),'Position',[500 0 0], ...
            'Velocity',[0 0 0],'Extent',[4 1.8 1.5],'Yaw',0);
ego = struct('Position',[0 0 0],'Yaw',0);
suite = sih.scenario.sensorSuite();
rs = RandStream('mt19937ar','Seed',1);
dets = sih.perception.simulateSensors(gt, ego, suite, 0.0, rs);
tc.verifyEqual(numel(dets), 0, '500 m is beyond every sensor''s Range_m');
end

function testInRangeObjectIsUsuallyDetectedAcrossManyFrames(tc)
gt = struct('ActorID',uint32(1),'ClassID',uint8(10),'Position',[10 0 0], ...
            'Velocity',[0 0 0],'Extent',[1.7 0.6 1.3],'Yaw',0);
ego = struct('Position',[0 0 0],'Yaw',0);
suite = sih.scenario.sensorSuite();
rs = RandStream('mt19937ar','Seed',7);
nSeen = 0;  N = 200;
for k = 1:N
    dets = sih.perception.simulateSensors(gt, ego, suite, k*0.05, rs);
    if ~isempty(dets), nSeen = nSeen + 1; end
end
tc.verifyGreaterThan(nSeen/N, 0.9, ...
    'a cow 10 m dead ahead, well within lidar/radar/ring range, must be seen almost every frame');
end

function testDetectionNoiseIsPresentAndCovarianceIsValid(tc)
gt = struct('ActorID',uint32(1),'ClassID',uint8(1),'Position',[20 0 0], ...
            'Velocity',[0 0 0],'Extent',[4 1.8 1.5],'Yaw',0);
ego = struct('Position',[0 0 0],'Yaw',0);
suite = sih.scenario.sensorSuite();
rs = RandStream('mt19937ar','Seed',3);
xs = [];
for k = 1:50
    dets = sih.perception.simulateSensors(gt, ego, suite, k*0.05, rs);
    for d = 1:numel(dets)
        xs(end+1) = dets{d}.Measurement(1);                          %#ok<AGROW>
        tc.verifyEqual(dets{d}.MeasurementNoise, dets{d}.MeasurementNoise.', ...
            'AbsTol', 1e-12, 'MeasurementNoise must be symmetric');
        tc.verifyGreaterThanOrEqual(eig(dets{d}.MeasurementNoise), 0, ...
            'MeasurementNoise must be positive semi-definite');
    end
end
tc.verifyGreaterThan(std(xs), 0, 'measured range must actually vary frame to frame - noise-free would be a bug');
end

% ---------------------------------------------------------------- trackObjects / newTracker

function testStationaryObjectTracksCleanlyNoNaN(tc)
tracker = sih.perception.newTracker();
gt = struct('ActorID',uint32(1),'ClassID',uint8(10),'Position',[15 3 0], ...
            'Velocity',[0 0 0],'Extent',[1.7 0.6 1.3],'Yaw',0);
ego = struct('Position',[0 0 0],'Yaw',0);
suite = sih.scenario.sensorSuite();
rs = RandStream('mt19937ar','Seed',11);

seenIDs = [];
for k = 1:40
    t = k*0.05;
    dets = sih.perception.simulateSensors(gt, ego, suite, t, rs);
    tracks = sih.perception.trackObjects(dets, tracker, t);
    for i = 1:numel(tracks)
        tc.verifyFalse(any(~isfinite(tracks(i).Position)), 'S1 guarantee: no NaN/Inf in Position');
        tc.verifyFalse(any(~isfinite(tracks(i).Velocity)));
        tc.verifyGreaterThanOrEqual(tracks(i).Existence, 0);
        tc.verifyLessThanOrEqual(tracks(i).Existence, 1);
        tc.verifyClass(tracks(i).TrackID, 'uint32');
        tc.verifyClass(tracks(i).ClassID, 'uint8');
        tc.verifyClass(tracks(i).SensorMask, 'uint8');
        seenIDs(end+1) = double(tracks(i).TrackID);                  %#ok<AGROW>
    end
end
tc.verifyNotEmpty(seenIDs, 'a stationary in-range object over 40 frames must be tracked at least once');
tc.verifyEqual(numel(unique(seenIDs)), 1, 'one physical object must keep ONE stable TrackID throughout');
end

function testEmptyDetectionsNeverErrorsAndStaysEmptySafe(tc)
tracker = sih.perception.newTracker();
for k = 1:5
    t = k*0.05;
    tracks = sih.perception.trackObjects(cell(1,0), tracker, t);
    tc.verifyEqual(numel(tracks), 0);
end
end

function testTracksSortedByTrackID(tc)
tracker = sih.perception.newTracker();
gtA = struct('ActorID',uint32(1),'ClassID',uint8(1),'Position',[10 4 0], ...
             'Velocity',[0 0 0],'Extent',[4 1.8 1.5],'Yaw',0);
gtB = struct('ActorID',uint32(2),'ClassID',uint8(5),'Position',[12 -4 0], ...
             'Velocity',[0 0 0],'Extent',[2 0.7 1.4],'Yaw',0);
ego = struct('Position',[0 0 0],'Yaw',0);
suite = sih.scenario.sensorSuite();
rs = RandStream('mt19937ar','Seed',13);

tracks = struct('TrackID',{});
for k = 1:12                                     % run past confirmation for both
    t = k*0.05;
    dets = [sih.perception.simulateSensors(gtA, ego, suite, t, rs), ...
            sih.perception.simulateSensors(gtB, ego, suite, t, rs)];
    tracks = sih.perception.trackObjects(dets, tracker, t);
end
if numel(tracks) > 1
    ids = double([tracks.TrackID]);
    tc.verifyEqual(ids, sort(ids), 'S1 guarantee: TrackList must be sorted by TrackID');
end
end

% ---------------------------------------------------------------- end to end

function testEndToEndFromPosesToS1TrackList(tc)
who = containers.Map('KeyType','double','ValueType','char');
who(1) = 'cow';  who(2) = 'auto';
DIMS = struct('cow',[1.7 0.6 1.3], 'auto',[3.0 1.4 1.7]);
suite = sih.scenario.sensorSuite();
tracker = sih.perception.newTracker();
rs = RandStream('mt19937ar','Seed',99);

egoPose = struct('Position',[0 0 0],'Yaw',0);
for k = 1:30
    t = k*0.05;
    poses = struct('ActorID',{1,2}, ...
                    'Position',{[8 2 0], [15-0.1*k -3 0]}, ...
                    'Velocity',{[0 0 0], [-2 0 0]}, ...
                    'Yaw',{90,180});
    gt = sih.scenario.groundTruthTrack(poses, who, DIMS);
    dets = sih.perception.simulateSensors(gt, egoPose, suite, t, rs);
    tracks = sih.perception.trackObjects(dets, tracker, t);

    tc.verifyTrue(isstruct(tracks));
    for i = 1:numel(tracks)
        f = fieldnames(tracks(i));
        for name = ["TrackID","ClassID","Position","Velocity","Extent","Yaw", ...
                    "Existence","Age","SensorMask"]
            tc.verifyTrue(any(strcmp(f, name)), "S1 TrackList must carry field " + name);
        end
    end
end
end
