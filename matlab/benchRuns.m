function R = benchRuns(scenario, n, opts)
%BENCHRUNS  PHASE 6 - turn a demo into a test.
%
%   R = benchRuns("s1", 12)
%
%   A single deterministic run is an anecdote. This runs the same scenario N
%   times from slightly different starting conditions and reports each metric as
%   a MEAN with a 95% CONFIDENCE INTERVAL, so a number becomes a property of the
%   scenario rather than of one lucky execution.
%
%   WHY THIS MATTERS HERE, SPECIFICALLY: the project's locked end goal is "a
%   generalized self-driving test for India" that other planners can be compared
%   against. A comparison standard whose own numbers move when you nudge the
%   start is not a standard. This is the phase that makes the benchmark claim
%   honest rather than aspirational.
%
%   WHAT IS PERTURBED, AND WHY THESE
%     StartS  +/- 2.0 m   where the car enters the scene
%     StartE  +/- 0.25 m  its lateral position in the lane
%     StartV  +/- 1.0 m/s its entry speed
%   All three are things a real vehicle would vary in and NONE of them changes
%   the scenario itself - the road, the traffic script, the hazards and the
%   density layer are untouched. Perturbing the WORLD instead would be measuring
%   a different test each time, which is the opposite of what a benchmark needs.
%
%   THE PERTURBATIONS ARE SEEDED AND RECORDED. Every run's exact start is written
%   into its own config.json by writeDemoResults, so any row here can be
%   reproduced exactly. An unreproducible confidence interval is decoration.
%
%   HONEST LIMITS - state these wherever this output is quoted:
%     - N is small. With 12 runs a 95% CI is wide and the t-distribution is
%       doing real work; this reports the t-based interval, not 1.96*sd, because
%       using the normal approximation at n=12 would understate the spread.
%     - Perturbing the start does NOT explore the space of things that could go
%       wrong. It measures sensitivity to entry conditions and nothing else.
%     - A metric whose CI straddles a safety threshold has NOT passed it.

arguments
    scenario (1,1) string = "s1"
    n (1,1) double = 12
    opts.Seed (1,1) double = 42
end

rng(opts.Seed);
dS = (rand(1,n)*2 - 1) * 2.00;      % +/- 2.00 m
dE = (rand(1,n)*2 - 1) * 0.25;      % +/- 0.25 m
dV = (rand(1,n)*2 - 1) * 1.00;      % +/- 1.00 m/s
dS(1) = 0; dE(1) = 0; dV(1) = 0;    % run 1 is ALWAYS the reference run

names = ["M1_distance_m","M2_duration_s","M3_meanSpeed_kmh","M4_maxSpeed_kmh", ...
         "M5_minBarrier_rad","M6_minClearance_m","M7_stoppedTime_s", ...
         "M8_maxDecel_mps2","M9_completed","M10_latWobble_m"];
V = nan(n, numel(names));
ok = false(1,n);  tEach = nan(1,n);

fprintf('\n=========== BENCH: %s, %d runs ===========\n', upper(scenario), n);
for i = 1:n
    t0 = tic;
    try
        info = densityPlannerRun(scenario, 'Seed',i, 'Quiet',true, ...
            'StartS',25+dS(i), 'StartE',1.75+dE(i), 'StartV',52/3.6+dV(i));
        for k = 1:numel(names)
            if isfield(info.M, names(k)), V(i,k) = double(info.M.(names(k))); end
        end
        ok(i) = info.ReachedEnd && info.PlanFailures == 0;
        tEach(i) = toc(t0);
        fprintf('  run %2d/%d  s0=%+.2f e0=%+.2f v0=%+.2f  ->  M6=%7.4f  done=%d  (%.1f s)\n', ...
                i, n, dS(i), dE(i), dV(i), V(i,6), ok(i), tEach(i));
    catch me
        fprintf('  run %2d/%d  FAILED: %s\n', i, n, me.message);
    end
end

fprintf('\n--- %d of %d runs completed the route with 0 plan failures ---\n', nnz(ok), n);
fprintf('%-22s %10s %10s %10s %22s\n','metric','mean','sd','min','95%% CI');
for k = 1:numel(names)
    x = V(~isnan(V(:,k)), k);
    if isempty(x), continue; end
    m = mean(x); sd = std(x); nn = numel(x);
    if nn > 1
        half = sc.tCrit95(nn-1) * sd / sqrt(nn);       % t, not 1.96 - n is small
                                                       % the toolbox inverse-t needs a licence we lack
        ci = sprintf('[%8.4f, %8.4f]', m-half, m+half);
    else
        ci = '   (n=1, none)';
    end
    fprintf('%-22s %10.4f %10.4f %10.4f %22s\n', names(k), m, sd, min(x), ci);
end
R = struct('names',{names},'values',V,'ok',ok,'dS',dS,'dE',dE,'dV',dV,'secs',tEach);
fprintf('  total wall: %.1f min\n', sum(tEach,'omitnan')/60);
fprintf('==============================================\n\n');
end
