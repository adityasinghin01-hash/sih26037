function detector = trainLidarDetector(dsTrain, outFile, opts)
%TRAINLIDARDETECTOR  Train the PointPillars 3-D detector. Model 5 of 5.
%
%   detector = sih.models.trainLidarDetector(dsTrain, outFile)
%
%   WHY THIS ONE IS DIFFERENT FROM MODELS 3 AND 4
%   The spotter and the segmenter read pixels, so they can never enter the driving loop. This
%   one reads a POINT CLOUD, and the cuboid simulator produces real point clouds through
%   lidarPointCloudGenerator. So this is the only learned perception model that could run
%   in the loop. It is still not on the critical path - S1 tracks come from the shipped
%   trackers - but it is the one with a route in.
%
%   NOTHING IS IMPORTED. MATLAB ships PointPillars natively (pointPillarsObjectDetector,
%   trainPointPillarsObjectDetector, Lidar Toolbox), so the ONNX problem that rules out an
%   imported YOLO does not arise here at all.
%
%   INPUTS
%     dsTrain  datastore  read() must return a 3-column cell/table row:
%                           1  pointCloud object
%                           2  M-by-9 boxes [x y z length width height roll pitch yaw]
%                           3  categorical labels
%                         Build it with lidarObjectDetectorTrainingData from labelled ground
%                         truth. The box format is NINE columns, not four - a 2-D box table
%                         will fail here with an unhelpful message.
%     outFile  string     where to save. MUST BE OUTSIDE THE REPO
%     opts.PointCloudRange (1,6) double = [0 69.12 -39.68 39.68 -5 5]   % x y z limits, m
%     opts.VoxelSize       (1,2) double = [0.16 0.16]
%     opts.MaxEpochs       (1,1) double = 60
%     opts.MiniBatchSize   (1,1) double = 2
%     opts.Execution       string = "auto"
%
%   OUTPUT
%     detector  pointPillarsObjectDetector

arguments
    dsTrain
    outFile (1,1) string
    opts.PointCloudRange (1,6) double = [0 69.12 -39.68 39.68 -5 5]
    opts.VoxelSize       (1,2) double = [0.16 0.16]
    opts.MaxEpochs       (1,1) double {mustBePositive} = 60
    opts.MiniBatchSize   (1,1) double {mustBePositive} = 2
    opts.Execution       (1,1) string {mustBeMember(opts.Execution, ["auto","gpu","cpu"])} = "auto"
end

if exist('trainPointPillarsObjectDetector', 'file') ~= 2
    error('sih:models:noLidarToolbox', ...
        ['trainPointPillarsObjectDetector is not available. It needs the Lidar Toolbox and\n' ...
         'Deep Learning Toolbox. Both are on licence 41087767.']);
end

% Fail early and clearly on the box format, which is the mistake people actually make.
sample = preview(dsTrain);
if istable(sample); sample = table2cell(sample); end
if size(sample, 2) < 3
    error('sih:models:badDatastore', ...
        ['dsTrain must return three columns: pointCloud, M-by-9 boxes, labels. Got %d.\n' ...
         'Build it with lidarObjectDetectorTrainingData.'], size(sample, 2));
end
bx = sample{1, 2};
if ~isempty(bx) && size(bx, 2) ~= 9
    error('sih:models:bad3DBoxes', ...
        ['Boxes have %d columns; PointPillars needs 9:\n' ...
         '  [x y z length width height roll pitch yaw]\n' ...
         'A 4-column box table is a 2-D image box and will not work here.'], size(bx, 2));
end

[names, ~] = sih.util.classNames("lidar");
fprintf('Classes (%d, S5 order): %s\n', numel(names), strjoin(names, ', '));
fprintf('Point cloud range: %s m\n', mat2str(opts.PointCloudRange));

detector = pointPillarsObjectDetector(opts.PointCloudRange, cellstr(names), ...
                                      "VoxelSize", opts.VoxelSize);

options = trainingOptions("adam", ...
    MaxEpochs            = opts.MaxEpochs, ...
    MiniBatchSize        = opts.MiniBatchSize, ...
    InitialLearnRate     = 2e-4, ...
    ExecutionEnvironment = opts.Execution, ...
    Shuffle              = "every-epoch", ...
    Verbose              = true, ...
    Plots                = "none");

fprintf('\nTraining PointPillars. This wants a GPU more than anything else in the project.\n');
[detector, info] = trainPointPillarsObjectDetector(dsTrain, detector, options);

save(outFile, 'detector', 'names', 'info', '-v7.3');
fprintf('\nSaved %s\n', outFile);
fprintf(['Next, and this is the part worth doing: run the SAME detector on a point cloud from\n' ...
         'lidarPointCloudGenerator in our own scenario. If it detects there too, the simulated\n' ...
         'lidar is realistic enough to trust. If it does not, that is a finding about the\n' ...
         'simulator, and a more interesting one than the detector''s own score.\n']);
end
