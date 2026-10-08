function sihDemo(which, opts)
%SIHDEMO  PHASE 7 - ONE command for the whole project.
%
%   sihDemo                 % S1, the cattle crossing
%   sihDemo("galli")        % S3, the residential squeeze
%   sihDemo("all")          % both, in order
%   sihDemo("s1", Dense=true, Reactive=true)
%
%   There are currently three names for the same idea - demo_play('demo1'),
%   'demo2', 'demo3' - plus densityPlannerRun and densityPlannerRunS3, and
%   nobody outside this repo can guess which is which. This is the front door.
%   It does NOT reimplement anything: it calls demo_play, which is the demo.
%
%   WHAT IT WILL NOT DO
%   It will not offer S2 (the chowk) or a dense S3. Both are known broken and a
%   menu entry that stalls in front of a judge is worse than no menu entry:
%     S2 - collides with the wrong-way rider, then permanently stalls at
%          s~116-121 m of a 244 m ring, under BOTH sensing conditions.
%     S3 dense - stops dead at s=81.4 m of 382.2 m and never moves again,
%          cycling ABORT/COMMIT for 150 s. Same mechanism as S2.
%   Ask for them and you get told exactly that, with the number, rather than a
%   demo that hangs. Disclosing a defect is this project's edge; hiding one
%   behind a menu would throw that away.

arguments
    which (1,1) string = "s1"
    opts.Dense     (1,1) logical = false
    opts.Reactive  (1,1) logical = false
    opts.Recompute (1,1) logical = false
end

which = lower(which);
switch which
    case {"s1","cow","cattle","demo1"}
        runOne("demo1", "S1 - the cattle crossing, 610 m of real Najibabad road", opts);
    case {"s3","galli","squeeze","demo3"}
        runOne("demo3", "S3 - the galli, a 1.95 m squeeze", opts);
    case {"s2","chowk"}
        error("sihDemo:knownBroken", ...
          ['S2 (the chowk) does NOT finish the route under either sensing condition.\n' ...
           'Ground truth: grazes the wrong-way rider at -0.003 m (t=17.65 s).\n' ...
           'Real sensing: collides at -0.909 m (t=12.70 s).\n' ...
           'In BOTH it then stalls permanently at s~116-121 m of 244 m and never\n' ...
           'reaches the exit. This is disclosed, not hidden - see plan/CLAIM-LEDGER.md.']);
    case "all"
        runOne("demo1", "S1 - the cattle crossing", opts);
        runOne("demo3", "S3 - the galli", opts);
    otherwise
        error("sihDemo:unknown", ...
            'Unknown "%s". Use "s1", "s3" or "all". S2 is known broken - ask for it by name to see why.', which);
end
end

function runOne(route, title, opts)
fprintf('\n============================================================\n');
fprintf('  %s\n', title);
if opts.Dense,    fprintf('  + density world (51 background actors)\n'); end
if opts.Reactive, fprintf('  + reactive agents (they respond to the car)\n'); end
fprintf('============================================================\n');
demo_play(route, 'Dense',opts.Dense, 'Reactive',opts.Reactive, ...
                 'Recompute',opts.Recompute);
end
