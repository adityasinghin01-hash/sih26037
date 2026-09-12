%BUILD_ALL  Render every deliverable for both scenarios, in dependency order.
%
%   WHY THIS EXISTS: the deliverables have an order, and getting it wrong produces a
%   deck that quietly disagrees with itself. The stills, the HUD frames and the films
%   all read the SAME run, so if the world changes under them they must all be redone
%   together - a film rendered before a colour change and a still rendered after it are
%   two different worlds presented as one. Running them by hand, one command at a time,
%   is how that happens.
%
%   ORDER, AND IT IS NOT ARBITRARY:
%     1. the two world-shot passes prove the STATIC worlds render and assert
%     2. the forest probe measures the S1 stand against its documents
%     3. the result/action runs integrate the drivers and write the CSVs
%     4. the HUD checks prove the instrument strip on stills - CHEAP, and they are the
%        last chance to catch a bad caption before paying for a film
%     5. the films, which are the expensive step and go LAST for that reason
%
%   COST, MEASURED ON THIS MACHINE (REF-17 s9b, s16d):
%     stills ~25-95 s each · S1 film ~15 min at 0.567 s/frame · S2 film ~10 min.
%     Budget about 40 minutes for a full pass. Use opts.Skip to leave the films out
%     while iterating on the look, which is the loop that actually converges.
%
%   Run:   matlab -batch "run('.../matlab/build_all.m')"
%   Look:  every PNG it writes. RENDER IT AND LOOK AT IT is the rule that found every
%          defect in this project; a green log is not evidence that a frame is right.

here = fileparts(mfilename('fullpath'));
addpath(here);

% Set SKIP_FILMS = true in the base workspace to iterate on the look without paying
% 25 minutes for two films you are about to invalidate anyway.
if ~exist('SKIP_FILMS','var'), SKIP_FILMS = false; end

steps = { 's1_world_shots',  'S1 world - 5 stills',              false
          's1_forest_probe', 'S1 forest - measured vs the refs',  false
          's2_world_shots',  'S2 chowk - stills',                 false
          's1_result_run',   'S1 numbers + map/ego_S1.csv',       false
          's1_hud_check',    'S1 HUD - 3 stills',                 false
          's2_action_run',   'S2 numbers + map/ego_S2.csv',       false
          's2_action_shots', 'S2 beats - 5 stills',               false
          's2_hud_check',    'S2 HUD - 3 stills',                 false
          's1_film',         'S1 film  (~15 min)',                true
          's2_film',         'S2 film  (~10 min)',                true };

fprintf('\n================ BUILD ALL ================\n');
if SKIP_FILMS, fprintf('  films SKIPPED (SKIP_FILMS = true)\n'); end
tAll = tic;  results = strings(0,3);

for k = 1:size(steps,1)
    [name, what, isFilm] = steps{k,:};
    if isFilm && SKIP_FILMS
        results(end+1,:) = [string(name), "skipped", "-"];                  %#ok<SAGROW>
        continue
    end
    f = fullfile(here, [name '.m']);
    if ~isfile(f)
        % A MISSING STEP IS REPORTED, NEVER SILENTLY PASSED OVER. A build script that
        % prints nothing for a file that does not exist is how a deliverable goes
        % missing from a deck without anyone noticing.
        fprintf('\n--- %-18s MISSING (%s) ---\n', name, what);
        results(end+1,:) = [string(name), "MISSING", "-"];                  %#ok<SAGROW>
        continue
    end
    fprintf('\n--- %-18s %s ---\n', name, what);
    t0 = tic;
    try
        % run in a function-scoped workspace so one step's variables cannot leak into
        % the next - s1_result_run and s2_action_run both define L, P, W and poses,
        % and a leaked P is a silently wrong render rather than an error.
        runStep(f);
        results(end+1,:) = [string(name), "ok", sprintf('%.1f s', toc(t0))]; %#ok<SAGROW>
    catch ME
        % KEEP GOING. One broken step should not hide the state of the other nine, and
        % before a deadline the useful output is "these eight are fine, this one is
        % not", never a stack trace and nothing else.
        fprintf(2, '  FAILED: %s\n', ME.message);
        results(end+1,:) = [string(name), "FAILED", ME.identifier];          %#ok<SAGROW>
    end
end

fprintf('\n================ SUMMARY ================\n');
for k = 1:size(results,1)
    fprintf('  %-18s %-8s %s\n', results(k,1), results(k,2), results(k,3));
end
nBad = sum(results(:,2) == "FAILED" | results(:,2) == "MISSING");
fprintf('  ---\n  %d step(s) need attention | total %.1f min\n', nBad, toc(tAll)/60);
fprintf('=========================================\n\n');
if nBad > 0
    fprintf(2, '  %d step(s) did not complete - see above before trusting renders/\n\n', nBad);
end

function runStep(f)
%RUNSTEP  Execute a script in its own workspace.
run(f);
end
