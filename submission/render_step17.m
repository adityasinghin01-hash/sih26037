%RENDER_STEP17 Export one verified sparse-S3 frame through the MATLAB submission view.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, 'matlab')));
outputFile = fullfile(repoRoot, 'submission', 'step17_galli_shell.png');
demo_play("demo3", SubmissionView=true, Snap=string(outputFile), SnapState="PROBE", ...
    Dense=false, WriteResults=false, Interactive=false);
