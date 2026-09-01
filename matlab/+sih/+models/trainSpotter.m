function detector = trainSpotter(dataRoot, outFile, opts)
%TRAINSPOTTER  Train the YOLOX road-user detector. Model 3 of 5.
%
%   detector = sih.models.trainSpotter(dataRoot, outFile)
%
%   WHAT THIS IS AND IS NOT
%   This runs OFFLINE and never enters the driving loop. The cuboid simulator emits an object
%   list, not pixels, so there is nothing for a detector to read at the moment the car drives.
%   Its job is to produce real per-class numbers on real Indian images - specifically cow,
%   auto-rickshaw and pushcart - which closes a stated gap in the problem statement.
%
%   WHY YOLOX AND NOT YOLOv4 OR RTMDet
%   RTMDet is inference-only in MATLAB and cannot be trained on new classes. An imported ONNX
%   YOLO does not work either: NMS is unsupported and dynamic shapes fail. YOLOX is trainable
%   natively here, which removes the import problem entirely. See AGENTS.md section 2.
%
%   INPUTS
%     dataRoot  string  folder holding IDD Detection: JPEGImages/ and Annotations/
%     outFile   string  where to save the trained detector. MUST BE OUTSIDE THE REPO
%     opts.MaxEpochs      (1,1) double = 30
%     opts.MiniBatchSize  (1,1) double = 8
%     opts.InputSize      (1,3) double = [640 640 3]
%     opts.ValFraction    (1,1) double = 0.2
%     opts.Execution      string = "auto"    "auto" | "gpu" | "cpu"
%
%   OUTPUT
%     detector  yoloxObjectDetector
%
%   Classes come from sih.util.classNames("detector") so the ordering matches S5. Do not pass
%   your own list - a detector with its own class order produces a feature vector the planner
%   misreads without any error.

arguments
    dataRoot (1,1) string
    outFile  (1,1) string
    opts.MaxEpochs     (1,1) double {mustBePositive} = 30
    opts.MiniBatchSize (1,1) double {mustBePositive} = 8
    opts.InputSize     (1,3) double = [640 640 3]
    opts.ValFraction   (1,1) double {mustBeInRange(opts.ValFraction, 0, 0.9)} = 0.2
    opts.Execution     (1,1) string {mustBeMember(opts.Execution, ["auto","gpu","cpu"])} = "auto"
end

%% Preflight - fail with an instruction, never with a missing-function error
% Check for the FUNCTIONS we call, not for toolbox names. `ver` takes a directory name
% ('vision'), not a product name, so a name-based check warns on a correct install and stays
% quiet on a broken one - worse than no check.
if exist('yoloxObjectDetector', 'file') ~= 2
    error('sih:models:noCVT', ...
        'yoloxObjectDetector not found. Computer Vision Toolbox is not installed.');
end
if exist('trainingOptions', 'file') ~= 2
    error('sih:models:noDLT', ...
        'trainingOptions not found. Deep Learning Toolbox is not installed.');
end
if exist('trainYOLOXObjectDetector', 'file') ~= 2
    error('sih:models:missingAddOn', ...
        ['trainYOLOXObjectDetector is not available.\n' ...
         'YOLOX training needs the "Automated Visual Inspection Library for Computer Vision\n' ...
         'Toolbox", which is a separate free add-on and is NOT installed by the product\n' ...
         'installer. Get it from:  Home -> Add-Ons -> Get Add-Ons -> search that name.\n' ...
         'This catches people out because the detector object exists without it; only\n' ...
         'training is missing.']);
end
if ~isfolder(dataRoot)
    error('sih:models:noData', 'dataRoot does not exist: %s', dataRoot);
end
iWarnIfInsideRepo(outFile);

%% Data
imgDir = fullfile(dataRoot, 'JPEGImages');
annDir = fullfile(dataRoot, 'Annotations');
if ~isfolder(imgDir) || ~isfolder(annDir)
    error('sih:models:badLayout', ...
        ['Expected IDD Detection layout under %s:\n  JPEGImages/\n  Annotations/\n' ...
         'IDD requires a signup at idd.insaan.iiit.ac.in/accounts/signup/ - it cannot be\n' ...
         'downloaded by a script.'], dataRoot);
end

[names, ~] = sih.util.classNames("detector");
fprintf('Classes (%d, S5 order): %s\n', numel(names), strjoin(names, ', '));

[imds, blds] = sih.models.readDetectionData(imgDir, annDir, names);
n = numel(imds.Files);
fprintf('Images found: %d\n', n);
if n == 0
    error('sih:models:emptyData', 'No images read from %s', imgDir);
end

rng(0);                                     % a split you can reproduce
idx = randperm(n);
nVal = max(1, round(opts.ValFraction * n));
valIdx = idx(1:nVal);
trainIdx = idx(nVal+1:end);
fprintf('Split: %d train, %d validation\n', numel(trainIdx), numel(valIdx));

dsTrain = combine(subset(imds, trainIdx), subset(blds, trainIdx));
dsVal   = combine(subset(imds, valIdx),   subset(blds, valIdx));

%% Train
detector = yoloxObjectDetector("small-coco", names, InputSize=opts.InputSize);

options = trainingOptions("adam", ...
    MaxEpochs            = opts.MaxEpochs, ...
    MiniBatchSize        = opts.MiniBatchSize, ...
    InitialLearnRate     = 1e-3, ...
    ValidationData       = dsVal, ...
    ExecutionEnvironment = opts.Execution, ...
    ResetInputNormalization = false, ...
    Verbose              = true, ...
    Plots                = "none");

fprintf('\nTraining YOLOX. This is the one model here that genuinely wants a GPU.\n');
detector = trainYOLOXObjectDetector(dsTrain, detector, options);

%% Report PER CLASS - the whole point of this model
fprintf('\nEvaluating on the held-out split ...\n');
results = detect(detector, subset(imds, valIdx), MiniBatchSize=opts.MiniBatchSize);
metrics = evaluateObjectDetection(results, subset(blds, valIdx));

fprintf('\nAverage precision per class (AGENTS.md requires cow, auto-rickshaw, pushcart):\n');
ap = metrics.ClassMetrics.AP;
for k = 1:numel(names)
    v = ap(k);
    if iscell(v); v = v{1}; end
    fprintf('  %-18s AP %.4f\n', names(k), mean(v, 'omitnan'));
end
fprintf('  overall mAP %.4f\n', mean(metrics.DatasetMetrics.mAP, 'omitnan'));

save(outFile, 'detector', 'names', 'metrics', '-v7.3');
fprintf('\nSaved %s\n', outFile);
fprintf('Report the three named classes, not the mAP alone. A high mAP driven by cars while\n');
fprintf('the cow class is empty is exactly the result this model exists to rule out.\n');
end


function iWarnIfInsideRepo(outFile)
here = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
if startsWith(string(fullfile(outFile)), string(here))
    warning('sih:models:inRepo', ...
        ['%s is inside the repository. AGENTS.md section 6 forbids committing model files ' ...
         'and .gitignore blocks .mat - write it somewhere else.'], outFile);
end
end
