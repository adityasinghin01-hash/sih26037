function net = trainRoadSegmenter(dataRoot, outFile, opts)
%TRAINROADSEGMENTER  Train the DeepLab v3+ drivable-surface segmenter. Model 4 of 5.
%
%   net = sih.models.trainRoadSegmenter(dataRoot, outFile)
%
%   WHY IT EXISTS
%   The problem statement says road edges are unclear. On an unmarked Indian road there is no
%   painted boundary to detect, so "where can I drive" is a segmentation question, not a lane
%   question. This produces the evidence for that claim on real images.
%
%   LIKE THE SPOTTER, IT RUNS OFFLINE. The cuboid simulator emits no pixels, so this never
%   enters the driving loop. S9 DrivableSpace is filled from lidar geometry, not from this.
%   Do not wire it into the planner - see AGENTS.md section 2.
%
%   NOTE ON THE FUNCTION NAME, because this has already changed once:
%   `deeplabv3plusLayers` is REMOVED. The current function is `deeplabv3plus`, which returns a
%   dlnetwork trained with `trainnet` (not `trainNetwork`). Verified against the MathWorks
%   documentation on 1 Sep 2026.
%
%   INPUTS
%     dataRoot  string  folder with leftImg8bit/ and gtFine/ (IDD Segmentation layout)
%     outFile   string  where to save. MUST BE OUTSIDE THE REPO
%     opts.MaxEpochs     (1,1) double = 20
%     opts.MiniBatchSize (1,1) double = 4
%     opts.ImageSize     (1,2) double = [512 512]
%     opts.ValFraction   (1,1) double = 0.2
%     opts.Execution     string = "auto"
%     opts.ClassWeighting (1,1) logical = true
%           true  - weight the loss by inverse pixel frequency, so the network cannot win by
%                   calling everything background. Uses an explicit weighted cross-entropy.
%           false - the built-in "crossentropy" loss, unweighted. Set this if the weighted
%                   path errors; it is the documented path and cannot be wrong.
%
%   OUTPUT
%     net  dlnetwork

arguments
    dataRoot (1,1) string
    outFile  (1,1) string
    opts.MaxEpochs     (1,1) double {mustBePositive} = 20
    opts.MiniBatchSize (1,1) double {mustBePositive} = 4
    opts.ImageSize     (1,2) double = [512 512]
    opts.ValFraction   (1,1) double {mustBeInRange(opts.ValFraction, 0, 0.9)} = 0.2
    opts.Execution     (1,1) string {mustBeMember(opts.Execution, ["auto","gpu","cpu"])} = "auto"
    opts.ClassWeighting (1,1) logical = true
end

if exist('deeplabv3plus', 'file') ~= 2
    error('sih:models:noDeeplab', ...
        ['deeplabv3plus is not available. It needs Computer Vision Toolbox and Deep Learning\n' ...
         'Toolbox on R2024a or later.\n' ...
         'If you found `deeplabv3plusLayers` in an old example, do not use it - it has been\n' ...
         'removed. The replacement is `deeplabv3plus` + `trainnet`.']);
end
if ~isfolder(dataRoot)
    error('sih:models:noData', ...
        ['dataRoot does not exist: %s\nIDD requires a signup at ' ...
         'idd.insaan.iiit.ac.in/accounts/signup/ - a script cannot fetch it.'], dataRoot);
end

%% Three classes are enough, and fewer classes on little data beats more
% We are answering one question - where may the car put its wheels - not labelling the world.
classes = ["drivable", "obstacle", "background"];
% IDD label ids grouped onto ours. Extend rather than renumber.
%   drivable : road, parking, drivable fallback
%   obstacle : every vehicle, person, animal, wall, fence, pole
labelIDs = { [0 1 2], [4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20], [3 21 22 23 24 25] };

imgDir = fullfile(dataRoot, 'leftImg8bit');
lblDir = fullfile(dataRoot, 'gtFine');
if ~isfolder(imgDir) || ~isfolder(lblDir)
    error('sih:models:badLayout', ...
        'Expected IDD Segmentation layout under %s:\n  leftImg8bit/\n  gtFine/', dataRoot);
end

imds = imageDatastore(imgDir, IncludeSubfolders=true, FileExtensions=[".png" ".jpg"]);
pxds = pixelLabelDatastore(lblDir, classes, labelIDs, IncludeSubfolders=true, ...
                           FileExtensions=".png");
n = numel(imds.Files);
fprintf('Images: %d   Labels: %d\n', n, numel(pxds.Files));
if n == 0
    error('sih:models:emptyData', 'No images under %s', imgDir);
end
if numel(pxds.Files) ~= n
    warning('sih:models:countMismatch', ...
        ['%d images but %d label maps. They must correspond one to one, so the extras will ' ...
         'pair wrongly. Check the folder layout before trusting any number below.'], ...
        n, numel(pxds.Files));
end

rng(0);
idx = randperm(n);
nVal = max(1, round(opts.ValFraction * n));
valIdx = idx(1:nVal); trainIdx = idx(nVal+1:end);
fprintf('Split: %d train, %d validation\n', numel(trainIdx), numel(valIdx));

dsTrain = combine(subset(imds, trainIdx), subset(pxds, trainIdx));
dsVal   = combine(subset(imds, valIdx),   subset(pxds, valIdx));

%% Train
net = deeplabv3plus([opts.ImageSize 3], numel(classes), "resnet50");

% Class weighting. Background and road dominate the pixel count; without weighting the
% network learns "everything is road", which is the segmentation twin of a yield model that
% always answers no.
tbl = countEachLabel(pxds);
w = median(tbl.PixelCount) ./ tbl.PixelCount;
fprintf('Pixel counts per class:\n'); disp(tbl);
fprintf('Class weights (rarer class gets more): %s\n', mat2str(round(w', 3)));

if opts.ClassWeighting
    % Written out rather than passed to crossentropy's `weights` argument. That argument is
    % positional, but a weight vector that is not the same size as Y also needs a
    % WeightsFormat string to say how its dimensions map onto SSCB - and getting that wrong
    % fails at the first iteration with an unhelpful message. This form has no ambiguity.
    % Y is post-softmax probabilities in [H W C B]; class weights apply along dimension 3.
    wc = reshape(single(w), 1, 1, []);
    lossFcn = @(Y, T) mean(-sum(wc .* T .* log(Y + single(1e-8)), 3), 'all');
else
    lossFcn = "crossentropy";      % the documented built-in. Always correct, never weighted.
end

options = trainingOptions("adam", ...
    MaxEpochs            = opts.MaxEpochs, ...
    MiniBatchSize        = opts.MiniBatchSize, ...
    InitialLearnRate     = 1e-3, ...
    ValidationData       = dsVal, ...
    ExecutionEnvironment = opts.Execution, ...
    Shuffle              = "every-epoch", ...
    Verbose              = true, ...
    Plots                = "none");

fprintf('\nTraining DeepLab v3+ ...\n');
net = trainnet(dsTrain, net, lossFcn, options);

%% Report per class, not overall accuracy
fprintf('\nEvaluating ...\n');
pxdsPred = semanticseg(subset(imds, valIdx), net, Classes=classes, WriteLocation=tempdir);
metrics = evaluateSemanticSegmentation(pxdsPred, subset(pxds, valIdx));

fprintf('\nIoU per class:\n');
disp(metrics.ClassMetrics);
fprintf('Global accuracy %.4f   mean IoU %.4f\n', ...
        metrics.DataSetMetrics.GlobalAccuracy, metrics.DataSetMetrics.MeanIoU);
fprintf(['Read the DRIVABLE IoU, not the global accuracy. Background is most of every image,\n' ...
         'so global accuracy stays high even when the road class is wrong.\n']);

save(outFile, 'net', 'classes', 'metrics', '-v7.3');
fprintf('\nSaved %s\n', outFile);
end
