%RUN_CATTLE_DEMO Launch the MATLAB submission presentation for S1 cattle.
% This replays the recovered planner cache and independently loops the
% supplied offline Indian-road footage. The footage is not planner input.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot,'matlab')));
cameraVideo = fullfile(repoRoot,'submission','assets','footage', ...
    'drive_10 - Trim.mp4');
demo_play("demo1",SubmissionView=true,CameraVideo=string(cameraVideo), ...
    WriteResults=false,Interactive=true);
