%RUN_GALLI_DEMO Launch the MATLAB submission presentation for sparse S3.
% Dense S3 is intentionally disabled because it is a recorded known failure.
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot,'matlab')));
demo_play("demo3",SubmissionView=true,Dense=false, ...
    WriteResults=false,Interactive=true);
