%BUILD_YOLOX_CACHE Run genuine offline YOLOX on the selected camera clip.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
videoFile = fullfile(repoRoot,'submission','assets','footage','drive_10 - Trim.mp4');
outputFile = fullfile(repoRoot,'submission','assets','footage','drive_10 - Trim_yolox.mat');

video = VideoReader(videoFile);
sampleTimes = 0:0.5:max(0,video.Duration-1/video.FrameRate); % 2 Hz offline analysis
detector = yoloxObjectDetector('small-coco');
bboxes = cell(numel(sampleTimes),1);
scores = cell(numel(sampleTimes),1);
labels = cell(numel(sampleTimes),1);
for i = 1:numel(sampleTimes)
    video.CurrentTime = sampleTimes(i);
    frame = readFrame(video);
    [bboxes{i},scores{i},rawLabels] = detect(detector,frame,'Threshold',0.35);
    labels{i} = string(rawLabels);
    fprintf('%2d/%2d  t=%5.2f s  detections=%d\n', ...
        i,numel(sampleTimes),sampleTimes(i),size(bboxes{i},1));
end
sourceVideo = string(videoFile);
detectorName = "MATLAB yoloxObjectDetector small-coco";
threshold = 0.35;
save(outputFile,'sampleTimes','bboxes','scores','labels','sourceVideo', ...
    'detectorName','threshold');
fprintf('wrote %s\n',outputFile);
