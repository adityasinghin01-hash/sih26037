function out = runExperiment(opts)
%RUNEXPERIMENT  Run one scenario, log the safety barrier, write a results folder.
%
%   Stream E, task E2. This is the thing that turns "we ran it once and it looked fine"
%   into a result somebody else can reproduce. AGENTS.md section 3: A NUMBER WITHOUT ITS
%   CONFIG IS NOT A RESULT - so config.json is written every time, without exception.
%
%   PRODUCES, per AGENTS.md section 3 "File formats":
%     results/<run>/trajectories.csv   t,actor_id,class_id,x,y,z,yaw   SI units, header row
%     results/<run>/metrics.json       keys M1-M10
%     results/<run>/config.json        a copy of exactly what was fed in
%
%   CONSUMES: nothing from another stream. It drives sih.planner.NegotiatingStrategy over
%   OpenTrafficLab's T-junction with the central controller REMOVED, which is D3's whole
%   point - an Indian junction has no referee, so each vehicle decides from geometry.
%
%   NAME-VALUE INPUTS
%     runName     string   folder under results/. Default: a UTC timestamp
%     stopTime_s  double   simulated seconds                      default 20
%     sampleTime_s double  scenario step                          default 0.05
%     rate        1x3 double  vehicles/hour per entry             default [900 900 900]
%     turnRatio   1x2 double  percent                             default [40 60]
%     carFollowing string  OpenTrafficLab car-following model     default "Gipps"
%
%   RETURNS a struct with .RunDir, .Steps, .MinBarrier, .BarrierViolations.
%
%   REQUIRES OpenTrafficLab on the path. It is third-party and gitignored - see
%   plan/ReadThis.md section 3. Without it this errors early and says so.
%
%   M1-M10 ARE NOT COMPUTED HERE. Their definitions live in the PRD (a PDF), and
%   plan/E-evidence.md E3 says implement them EXACTLY as written. Inventing them would be
%   worse than leaving them out, so every M key is written as the literal string
%   "TODO(unverified)" and the numbers this run really produced go in a separate
%   "measured" block that says how each was obtained.

arguments
    opts.runName      (1,1) string  = ""
    opts.stopTime_s   (1,1) double {mustBePositive} = 20
    opts.sampleTime_s (1,1) double {mustBePositive} = 0.05
    opts.rate         (1,3) double {mustBePositive} = [900 900 900]
    opts.turnRatio    (1,2) double = [40 60]
    opts.carFollowing (1,1) string  = "Gipps"
end

if isempty(which('createTJunctionScenario'))
    error('sih:runExperiment:noOpenTrafficLab', ...
        ['OpenTrafficLab is not on the path. It is third-party and gitignored:\n' ...
         '    git clone https://github.com/mathworks/OpenTrafficLab.git\n' ...
         '    addpath(genpath(''OpenTrafficLab''))\n' ...
         'See plan/ReadThis.md section 3.']);
end

repoRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));   % .../matlab/+sih -> repo
if opts.runName == ""
    opts.runName = string(datetime('now','TimeZone','UTC','Format','yyyyMMdd-HHmmss'));
end
runDir = fullfile(repoRoot, 'results', char(opts.runName));
if ~isfolder(runDir), mkdir(runDir); end

% ---------------------------------------------------------------- build and run
s   = createTJunctionScenario();
net = createTJunctionNetwork(s);
s.StopTime   = opts.stopTime_s;
s.SampleTime = opts.sampleTime_s;

fnc  = @(varargin) sih.planner.NegotiatingStrategy(varargin{:}, ...
            'CarFollowingModel', char(opts.carFollowing));
cars = createVehiclesForTJunction(s, net, opts.rate, opts.turnRatio, fnc);

% R2026a returns a NaN pose for an invisible actor and setUpSensorSimulation then rejects
% the whole actor set. Harness fix, not a planner fix - plan/OPENTRAFFICLAB-R2026a.md.
for c = cars
    c.IsVisible = true;
end

steps = 0; t0 = tic;
while advance(s)
    steps = steps + 1;
end
wall_s = toc(t0);

% ---------------------------------------------------------------- harvest the logs
rows = zeros(0,7);      % t, actor_id, class_id, x, y, z, yaw
allH = [];
nLogged = 0;
for k = 1:numel(cars)
    d = cars(k).MotionStrategy.Data;
    if isempty(d) || ~isfield(d,'Time') || isempty(d.Time), continue; end
    nLogged = nLogged + 1;
    t   = d.Time(:);
    pos = d.Position;
    if size(pos,2) < 3, pos(:,end+1:3) = 0; end     %#ok<AGROW>
    yaw = d.Yaw(:);
    n   = min([numel(t), size(pos,1), numel(yaw)]);
    aid = double(cars(k).ActorID) * ones(n,1);
    % S5 ClassID is NOT available: the perception stub reports 0 (unknown) until Stream B
    % supplies the real S5 ClassID keyed by ActorID. Writing drivingScenario's own 0-6
    % numbering here would silently mislabel a bicycle as a bus - that was defect 5.
    cid = zeros(n,1);
    rows = [rows; t(1:n), aid, cid, pos(1:n,1:3), yaw(1:n)];   %#ok<AGROW>

    if isfield(d,'UDStates') && ~isempty(d.UDStates)
        h = d.UDStates(:);
        allH = [allH; h(~isnan(h))];                            %#ok<AGROW>
    end
end
rows = sortrows(rows, [1 2]);

minH   = NaN; nViol = NaN;
if ~isempty(allH)
    minH  = min(allH);
    nViol = nnz(allH < 0);
end

% ---------------------------------------------------------------- trajectories.csv
csv = fullfile(runDir,'trajectories.csv');
fid = fopen(csv,'w');
fprintf(fid,'t,actor_id,class_id,x,y,z,yaw\n');
fprintf(fid,'%.4f,%d,%d,%.6f,%.6f,%.6f,%.6f\n', rows');
fclose(fid);

% ---------------------------------------------------------------- config.json
v = ver('MATLAB');
cfg = struct( ...
    'runName',            opts.runName, ...
    'utc',                string(datetime('now','TimeZone','UTC','Format','yyyy-MM-dd HH:mm:ss')), ...
    'scenario',           "OpenTrafficLab createTJunctionScenario, TrafficController REMOVED", ...
    'stopTime_s',         opts.stopTime_s, ...
    'sampleTime_s',       opts.sampleTime_s, ...
    'rate_veh_per_hour',  opts.rate, ...
    'turnRatio_pct',      opts.turnRatio, ...
    'carFollowingModel',  opts.carFollowing, ...
    'planner',            "sih.planner.NegotiatingStrategy", ...
    'matlabVersion',      string(version), ...
    'matlabRelease',      string(v.Release), ...
    'platform',           string(computer), ...
    'gitCommit',          iGitCommit(repoRoot), ...
    'gitDirty',           iGitDirty(repoRoot), ...
    'baselineComparable', false, ...
    'plannerInLoop',      false, ...
    'notes',              ["PLANNER IS NOT IN THE LOOP. NegotiatingStrategy OBSERVES and logs h; it does not steer. The vehicles are driven by the base class's Gipps car-following model, and sih.planner.chooseVelocity is never called - see the TODO at NegotiatingStrategy.m line 105. So h here is a MEASUREMENT of a simulation our planner is watching, not evidence that our planner keeps h positive.", ...
                           "S5 ClassID unavailable - perception stub reports 0 (unknown); class_id is 0 for every row", ...
                           "NOT comparable to matlab/baseline/ - that runs a different scenario and does not complete (plan/BASELINE-R2026a.md)"]);
iWriteJson(fullfile(runDir,'config.json'), cfg);

% ---------------------------------------------------------------- metrics.json
todo = "TODO(unverified)";
metrics = struct('M1',todo,'M2',todo,'M3',todo,'M4',todo,'M5',todo, ...
                 'M6',todo,'M7',todo,'M8',todo,'M9',todo,'M10',todo);
metrics.metricsNote = "M1-M10 are defined in the PRD (PDF), which this code has never seen. plan/E-evidence.md E3 says implement them EXACTLY as written, so they are left unset rather than invented.";
metrics.measured = struct( ...
    'steps',                    steps, ...
    'simulatedDuration_s',      opts.stopTime_s, ...
    'wallClock_s',              wall_s, ...
    'actorsTotal',              numel(cars), ...
    'actorsWithLogs',           nLogged, ...
    'barrierSamples',           numel(allH), ...
    'minBarrier_h',             minH, ...
    'barrierViolations_hLT0',   nViol, ...
    'trajectoryRows',           size(rows,1));
metrics.measuredNote = "h = lambda - beta, logged every step through the base class UDStates mechanism, across EVERY agent. minBarrier_h is the smallest over all agents and all steps; barrierViolations_hLT0 counts samples below zero; NaN samples (no agent in range) are excluded. READ config.plannerInLoop BEFORE QUOTING ANY OF THIS: while it is false these numbers describe traffic our planner is only watching, and a negative h is a collision-course reading, not a crash and not a planner failure.";
iWriteJson(fullfile(runDir,'metrics.json'), metrics);

out = struct('RunDir',string(runDir),'Steps',steps,'MinBarrier',minH, ...
             'BarrierViolations',nViol,'BarrierSamples',numel(allH));

fprintf('run written : %s\n', runDir);
fprintf('  steps                 : %d\n', steps);
fprintf('  barrier samples       : %d\n', numel(allH));
fprintf('  min h                 : %.6f\n', minH);
fprintf('  h < 0 count           : %d\n', nViol);
fprintf('  trajectory rows       : %d\n', size(rows,1));
end

% ------------------------------------------------------------------ helpers
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
