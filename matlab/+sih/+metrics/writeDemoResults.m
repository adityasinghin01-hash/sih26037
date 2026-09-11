function info = writeDemoResults(runName, D, LOG, opts)
%WRITEDEMORESULTS  demo_play.m's own run -> the frozen results/<run>/ format
%   (AGENTS.md section 3, "File formats").
%
%   info = sih.metrics.writeDemoResults(runName, D, LOG, opts)
%
%   UNLIKE sih.runExperiment (which leaves M1-M10 as the literal string
%   "TODO(unverified)" because it has never seen the PRD's own definitions),
%   THIS FILE DOES COMPUTE THEM - using the exact same formulas already
%   shipped and used in world/build/backup/matlab/+backup/metrics.m, adapted
%   to demo_play's LOG shape instead of that file's `out` struct. That reuse
%   is a real decision, made once, not a free one: it means these M1-M10
%   follow the backup's own interpretation of each metric name, not an
%   independently PRD-checked reading. Flagged here so reuse is never mistaken
%   for verification - the same discipline runExperiment.m's own header uses.
%
%   INPUTS
%     runName  (1,1) string   folder name under results/
%     D        (1,1) struct   demo_play's route struct - D.W.Path, D.Poses,
%              D.Who, D.DIMS, D.Sensed, D.Title all read here
%     LOG      (1,1) struct   demo_play's runPlanner() output
%     opts     (1,1) struct   the demo_play() opts that produced this run -
%              written verbatim to config.json: "a number without its config
%              is not a result" (AGENTS.md section 3)
%
%   OUTPUT
%     info  struct  .RunDir .M (the metrics struct actually written)

arguments
    runName (1,1) string
    D (1,1) struct
    LOG (1,1) struct
    opts (1,1) struct
end

repoRoot = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));   % +metrics -> +sih -> matlab -> repo
runDir = fullfile(repoRoot, 'results', char(runName));
if ~isfolder(runDir), mkdir(runDir); end

n  = numel(LOG.t);
DT = 0.05;
if n > 1, DT = LOG.t(2) - LOG.t(1); end

% ---------------------------------------------------------------- trajectories.csv
% World frame, SI units, one row per actor per step: the ego (actor_id 0,
% ClassID 1 - it IS a car) plus every road user from D.Poses, the same raw
% ground truth both the exact and sensed paths derive from (see
% demo_play.m's builtinPoses). Traffic yaw comes back from degrees to radians
% here - SI units means radians, and D.Poses' own Yaw is degrees on purpose
% (see builtinPoses's header on the unit trap).
rows = [LOG.t(:), zeros(n,1), ones(n,1), LOG.x(:), LOG.y(:), zeros(n,1), LOG.yaw(:)];
for i = 1:min(n, numel(D.Poses))
    Pi = D.Poses{i};
    for k = 1:numel(Pi)
        tag = string(D.Who(Pi(k).ActorID));
        cid = double(sih.scenario.classIDByName(tag));
        if isnan(cid), continue; end   % unrecognised tag - drop, matches S1 guarantee 4's spirit
        rows(end+1,:) = [LOG.t(i), double(Pi(k).ActorID), cid, ...
            Pi(k).Position(1), Pi(k).Position(2), Pi(k).Position(3), deg2rad(Pi(k).Yaw)]; %#ok<AGROW>
    end
end
rows = sortrows(rows, [1 2]);
fid = fopen(fullfile(runDir, 'trajectories.csv'), 'w');
fprintf(fid, 't,actor_id,class_id,x,y,z,yaw\n');
fprintf(fid, '%.4f,%d,%d,%.6f,%.6f,%.6f,%.6f\n', rows');
fclose(fid);

% ---------------------------------------------------------------- metrics.json
% PULLED OUT to sih.metrics.computeM1toM10.m on 11 Sep 2026 (Phase 1 of the
% planner/ML side-build) so sih.bench's benchmark harness can score OTHER
% drivers with the exact same math, not a second copy of it. Byte-identical
% formulas - see that file's own header.
M = sih.metrics.computeM1toM10(D, LOG, DT);
iWriteJson(fullfile(runDir, 'metrics.json'), M);

% ---------------------------------------------------------------- config.json
v = ver('MATLAB');
cfg = struct( ...
    'runName',        runName, ...
    'utc',            string(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm:ss')), ...
    'scenario',       string(D.Title), ...
    'sensed',         logical(D.Sensed), ...
    'demoPlayOpts',   opts, ...
    'matlabVersion',  string(version), ...
    'matlabRelease',  string(v.Release), ...
    'platform',       string(computer), ...
    'gitCommit',      iGitCommit(repoRoot), ...
    'gitDirty',       iGitDirty(repoRoot), ...
    'plannerInLoop',  true, ...
    'notes', "demo_play.m's own live 2D demo: the real sc.planSeat drives every " + ...
        "step, computed once and cached, then played back - nothing here is " + ...
        "scripted. sensed=true means lidar+radar+near-field-ring+trackerGNN fed " + ...
        "the planner; sensed=false means exact ground truth. See demo_play.m's " + ...
        "own header for both the caching architecture and the Sensed trade-off." ...
    );
iWriteJson(fullfile(runDir, 'config.json'), cfg);

info = struct('RunDir', string(runDir), 'M', M);
fprintf('results written: %s\n', runDir);
end

% =============================================================================
function c = iGitCommit(root)
[st,o] = system(sprintf('git -C "%s" rev-parse HEAD', root));
if st == 0, c = string(strtrim(o)); else, c = "unknown"; end
end

function d = iGitDirty(root)
[st,o] = system(sprintf('git -C "%s" status --porcelain', root));
d = (st ~= 0) || ~isempty(strtrim(o));
end

function iWriteJson(f, s)
fid = fopen(f,'w');
fprintf(fid,'%s', jsonencode(s,'PrettyPrint',true));
fclose(fid);
end
