function out = extract_metrics()
%EXTRACT_METRICS  M6 (replanning latency) and M7 (path smoothness) from sih_planner.slx.
%
%   Stream E. Runs the model step-by-step to measure real wall-clock time per
%   re-decision (M6), and logs the ego's own position/velocity to compute path
%   smoothness (M7) per the PRD definition: integral of squared lateral jerk
%   plus peak lateral acceleration.
%
%   M6 and M7 need only the ego's own trajectory, so they do not depend on
%   whether a second vehicle is wired into the barrier computation yet.
%   M1 (time-to-enter) is NOT computed here - see the note this prints at the
%   end for why.
%
%   Nothing is saved to the model. Signal logging is enabled at runtime only.

cd(fileparts(mfilename('fullpath')));
cd('..');
addpath('matlab');

mdl = 'sih_planner';
load_system(['simulink/' mdl '.slx']);
cleanupObj = onCleanup(@() close_system(mdl, 0));

% ---------------------------------------------------------- runtime-only logging
egoBlock = find_system(mdl, 'Name', 'MATLAB Function');   % the bicycle model
ph = get_param(egoBlock{1}, 'PortHandles');
for i = 1:numel(ph.Outport)
    set_param(ph.Outport(i), 'DataLogging', 'on', 'DataLoggingName', sprintf('ego_out%d', i), ...
        'DataLoggingNameMode', 'Custom');
end

% ---------------------------------------------------------- M6: step-by-step timing
set_param(mdl, 'SimulationCommand', 'start');
set_param(mdl, 'SimulationCommand', 'pause');
stepTimes_s = [];
while strcmp(get_param(mdl, 'SimulationStatus'), 'paused')
    t0 = tic;
    set_param(mdl, 'SimulationCommand', 'step');
    stepTimes_s(end+1) = toc(t0);   %#ok<AGROW>
end
set_param(mdl, 'SimulationCommand', 'stop');

% ---------------------------------------------------------- M7: path smoothness
% Re-run cleanly with sim() to get logged data through logsout, since stepping
% the block diagram above is for timing only and does not reliably populate it.
set_param(mdl, 'SignalLogging', 'on', 'SignalLoggingName', 'logsout');
simOut2 = sim(mdl);
logsout = simOut2.get('logsout');

fprintf('logsout signals found: %d\n', logsout.numElements);
for i = 1:logsout.numElements
    el = logsout.getElement(i);
    fprintf('  [%d] %s : size %s\n', i, el.Name, mat2str(size(el.Values.Data)));
end

% ---------------------------------------------------------- M6: report, with two known artifacts named and excluded
t_ms = stepTimes_s * 1000;
clean = t_ms(2:end-1);   % step 1: first-eval/compile cost. Last step: sim teardown. Named, not hidden.

out = struct();
out.stepTimes_s_raw   = stepTimes_s;
out.M6_raw_mean_ms    = mean(t_ms);
out.M6_raw_max_ms     = max(t_ms);
out.M6_clean_median_ms = median(clean);
out.M6_clean_mean_ms   = mean(clean);
out.M6_clean_p95_ms    = prctile(clean, 95);
out.M6_clean_max_ms    = max(clean);
out.nSteps             = numel(stepTimes_s);

fprintf('\n=== M6: replanning latency (wall-clock per Simulink step, this Mac) ===\n');
fprintf('n steps                    : %d\n', out.nSteps);
fprintf('RAW mean / max (all steps) : %.3f / %.3f ms\n', out.M6_raw_mean_ms, out.M6_raw_max_ms);
fprintf('step 1 (first-eval cost)   : %.3f ms - excluded from "clean" below\n', t_ms(1));
fprintf('last step (sim teardown)   : %.3f ms - excluded from "clean" below\n', t_ms(end));
fprintf('CLEAN median               : %.4f ms\n', out.M6_clean_median_ms);
fprintf('CLEAN mean                 : %.4f ms\n', out.M6_clean_mean_ms);
fprintf('CLEAN p95                  : %.4f ms\n', out.M6_clean_p95_ms);
fprintf('CLEAN max                  : %.4f ms\n', out.M6_clean_max_ms);
fprintf('NOTE: wall-clock MATLAB/OS step time on this Mac. NOT a hardware latency claim (E9 cancelled).\n');

% ---------------------------------------------------------- M7: path smoothness
pos = squeeze(logsout.getElement('ego_out1').Values.Data);   % 3 x N: x,y,z
tSig = logsout.getElement('ego_out1').Values.Time;
lat = pos(2,:);   % y = lateral, ego frame convention (x fwd, y left)

dt = diff(tSig);
if any(abs(dt - dt(1)) > 1e-6)
    fprintf('WARNING: logged samples are not evenly spaced - jerk estimate is approximate.\n');
end
dt_mean = mean(dt);

latVel   = diff(lat) ./ dt';
latAccel = diff(latVel) ./ dt(1:end-1)';
latJerk  = diff(latAccel) ./ dt(1:end-2)';

out.M7_peakLatAccel_mps2   = max(abs(latAccel));
out.M7_intSquaredJerk      = trapz(tSig(1:numel(latJerk)), latJerk.^2);
out.M7_nSamples            = numel(tSig);
out.M7_sampleInterval_s    = dt_mean;

fprintf('\n=== M7: path smoothness ===\n');
fprintf('samples used               : %d, at %.3f s intervals\n', out.M7_nSamples, out.M7_sampleInterval_s);
fprintf('peak lateral accel         : %.4f m/s^2\n', out.M7_peakLatAccel_mps2);
fprintf('integral of squared jerk   : %.6f (m/s^3)^2 . s\n', out.M7_intSquaredJerk);
fprintf('WARNING: only %d samples over 10s (~10 Hz) - jerk is a second derivative of a\n', out.M7_nSamples);
fprintf('  coarsely-sampled signal, so this number is approximate, not precision-grade.\n');
fprintf('NOTE: measured on EgoVehicleGoesStraight.mat - no real encounter in this run.\n');
fprintf('  This describes how smoothly the CURRENT stub control law drives, not a negotiation.\n');
end
