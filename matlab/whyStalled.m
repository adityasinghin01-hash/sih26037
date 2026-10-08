function whyStalled(runDir, stallS)
%WHYSTALLED  What binds the planner at the station where it stops forever?
%
%   whyStalled('results/<run>', 81.4)
%
%   S3 dense stops dead at s=81.4 m of a 382.2 m route and never moves again -
%   150 s at the identical station, cycling ABORT/COMMIT. S2 does the same at
%   s~116-121 m of 244 m. The claim ledger calls S2's mechanism "a D9 WAIT-rung
%   repeatedly finding, then losing, a viable pass". Two scenarios showing one
%   pathology makes it a property of the PLANNER, not of a scenario.
%
%   This answers the only question worth asking before touching anything: WHAT
%   is in the way at that station. It does not fix, tune, or widen anything.
%
%   DO NOT "FIX" A STALL BY RAISING THE STEP BUDGET, LOOSENING THE CORRIDOR, OR
%   DELETING ACTORS UNTIL IT MOVES. The stall is the finding. Removing whatever
%   causes it without naming it first converts a real result into a demo that
%   happens to work, which is the opposite of what this project is for.

arguments
    runDir (1,1) string
    stallS (1,1) double = 81.4
end

here = fileparts(mfilename('fullpath'));  addpath(here);
T = readtable(fullfile(runDir,'trajectories.csv'));
ego = T(T.actor_id == 0, :);
W = sc.s3world();

% where in the log does the ego stop advancing?
egoS = zeros(height(ego),1);
for q = 1:height(ego)
    egoS(q) = W.Path.inverse([ego.x(q) ego.y(q)]);
end
moved = [1; abs(diff(egoS))];
firstStuck = find(egoS > stallS - 1 & moved < 1e-3, 1);
if isempty(firstStuck), firstStuck = find(egoS >= stallS, 1); end
fprintf('\n=============== WHY IT STOPPED ===============\n');
fprintf('  ego reaches s = %.2f m at t = %.2f s (sample %d)\n', ...
        egoS(firstStuck), ego.t(firstStuck), firstStuck);
fprintf('  and is still at s = %.2f m at t = %.2f s\n', ...
        egoS(end), ego.t(end));

% every actor present at that instant, ranked by how much it blocks
tStuck = ego.t(firstStuck);
others = T(abs(T.t - tStuck) < 1e-6 & T.actor_id ~= 0, :);
fprintf('\n  %d other actors present at t = %.2f s\n', height(others), tStuck);
fprintf('  %-10s %10s %10s %10s\n','actor_id','s (m)','e (m)','ds ahead');
rows = [];
for k = 1:height(others)
    [as, ae] = W.Path.inverse([others.x(k) others.y(k)]);
    rows(end+1,:) = [others.actor_id(k), as, ae, as - egoS(firstStuck)]; %#ok<AGROW>
end
rows = rows(rows(:,4) > -5 & rows(:,4) < 60, :);       % only what is ahead
rows = sortrows(rows, 4);
for k = 1:min(12, size(rows,1))
    fprintf('  %-10d %10.2f %10.2f %10.2f\n', rows(k,1), rows(k,2), rows(k,3), rows(k,4));
end
if isempty(rows)
    fprintf('  NOTHING within 60 m ahead - the block is NOT another actor.\n');
    fprintf('  Look at the corridor bounds (ctx.ELo/ctx.EHi) and sc.s3geom instead.\n');
end
fprintf('==============================================\n\n');
end
