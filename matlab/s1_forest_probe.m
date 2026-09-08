%S1_FOREST_PROBE  MEASURE the stand against REF-04 s7 and REF-06 s1.
%
%   REF-17 s13 lists three things read out of the reference documents and never
%   applied, and two of them are claims about numbers nobody has measured on OUR
%   forest: REF-04 s7's "8-10 m spacing both sides, ~62 % measured cover, with real
%   holes in it", and REF-06 s1's hard rule that "no more than 1 in 6 trees may be the
%   round free-standing form". This measures both before anything is tuned, because a
%   target you have never measured against is not a target.
%
%   THE TWO DOCUMENTS DISAGREE ABOUT COVER AND BOTH ARE QUOTED HERE.
%   REF-04 s7 gives ~62 %, which is its build target for an interlocking AVENUE.
%   S1-CATTLE-CROSSING.md, which is the written specification for THIS road, gives
%   "canopy cover over the carriageway: 38 % in the open, rising to 55 % at the village
%   end", and it says that number was "measured by ray-casting, not estimated".
%   Rule 1 makes the scenario script the specification, so 38 % is the one we own and
%   62 % is reported beside it rather than silently dropped.
%
%   Run:  matlab -batch "run('.../matlab/s1_forest_probe.m')"

here = fileparts(mfilename('fullpath'));
addpath(here);
fprintf('\n================ S1 FOREST, MEASURED ================\n');
W = sc.s1world();
P = W.Path;  T = W.Trees;  n = size(T,1);

% ---------------------------------------------------------------- spacing
% Nearest neighbour, per tree. REF-04 s7: crowns interact at 10-15 m, MERGE below 10 m,
% read as separate trees over 15 m. Build target 8-10 m.
D = zeros(n,1);
for i = 1:n
    dd = hypot(T(:,1)-T(i,1), T(:,2)-T(i,2));  dd(i) = inf;
    D(i) = min(dd);
end
% WHICH TARGET GOVERNS, AND IT IS NOT THE OBVIOUS ONE.
% REF-04 s7's "8-10 m spacing both sides" is a build target for an interlocking
% roadside AVENUE - trees planted in a row whose crowns meet over the carriageway.
% SPEC.md builds S1 as "forest to both shoulders", and a forest is legitimately
% denser than an avenue. So 8-10 m is reported as context, and the number that
% actually governs this scenario is S1's own canopy COVER, which is what the
% section below checks and what s1world solves its lean against.
fprintf('\n--- NEAREST-NEIGHBOUR SPACING (REF-04 s7 avenue target 8-10 m) ---\n');
fprintf('  n = %d | median %.2f m | mean %.2f m | p10 %.2f | p90 %.2f | max %.2f\n', ...
        n, median(D), mean(D), prctile(D,10), prctile(D,90), max(D));
% MATLAB needs BRACKETS round a continued string inside a call - 'a' ... 'b' on two
% lines is a syntax error, ['a' ... 'b'] is not. Written but never run, which is how
% it survived; the rest of this file uses the bracketed form correctly.
fprintf(['  below 10 m (crowns MERGE): %.0f %% | 10-15 m (interacting): %.0f %% | ' ...
         'over 15 m (separate): %.0f %%\n'], ...
        100*mean(D<10), 100*mean(D>=10 & D<=15), 100*mean(D>15));

% first rank only - the trees that actually line the road
eAll = zeros(n,1);
for i = 1:n, [~, eAll(i)] = P.inverse(T(i,1:2)); end
front = abs(eAll) < 16;
fprintf('  front rank (|e| < 16 m, %d trees): median spacing %.2f m\n', ...
        sum(front), median(D(front)));

% ---------------------------------------------------------------- canopy cover
% Ray-cast straight up from a grid over the carriageway and ask whether a crown is
% overhead. A crown is an ellipsoid centred at 0.70h of radius cr, so "overhead" is
% simply horizontal distance < cr. Same test S1 says it used.
ss = 0:2:P.Len;  ee = -3.5:0.5:3.5;
hit = 0; tot = 0;
% MEASURE THE CROWNS WHERE THEY ACTUALLY SIT, NOT THE TRUNKS.
% This probe first measured cover at T(:,1:2) - the TRUNK positions - and reported
% 25.6 % against s1world's own 38 %, which I wrote up as "the world contradicts
% itself, one of them is a lie". It was neither: s1world applies a roadside LEAN
% (REF-06 s2, phototropism - "directional lateral expansion on the open side", so the
% crown's centre of mass is displaced off the trunk) and stores the displacement in
% columns 10 and 11. It then solves that lean by bisection until measured open-country
% cover equals S1's written 38 %. Measuring at the trunk ignores the entire mechanism
% and undercounts every roadside tree - which is exactly the 12-point gap.
% A probe that measures a different quantity from the thing it is checking is worse
% than no probe: it manufactures a defect and sends someone off to fix the wrong file.
if size(T,2) >= 11
    cx = T(:,1) + T(:,10);  cy = T(:,2) + T(:,11);
else
    cx = T(:,1);            cy = T(:,2);
end
for s = ss
    for e = ee
        xy = P.at(s, e);
        tot = tot + 1;
        if any(hypot(cx-xy(1), cy-xy(2)) < T(:,4)), hit = hit + 1; end
    end
end
cover = 100*hit/tot;
fprintf('\n--- CANOPY COVER OVER THE 7.0 m CARRIAGEWAY (%d samples) ---\n', tot);
fprintf('  measured %.1f %%\n', cover);
fprintf('  S1-CATTLE-CROSSING.md (the specification): 38 %% in the open  -> delta %+.1f\n', cover-38);
fprintf('  REF-04 s7 (avenue build target):           62 %%              -> delta %+.1f\n', cover-62);

% REAL HOLES IN IT - REF-04 s7 says the cover must have holes, not be an even wash.
runLen = 0; runs = [];
for s = ss
    xy = P.at(s, 0);
    over = any(hypot(cx-xy(1), cy-xy(2)) < T(:,4));
    if over, runLen = runLen + 2; else
        if runLen > 0, runs(end+1) = runLen; end %#ok<SAGROW>
        runLen = 0;
    end
end
if runLen > 0, runs(end+1) = runLen; end
gap = 0; gaps = [];
for s = ss
    xy = P.at(s, 0);
    over = any(hypot(cx-xy(1), cy-xy(2)) < T(:,4));
    if ~over, gap = gap + 2; else
        if gap > 0, gaps(end+1) = gap; end %#ok<SAGROW>
        gap = 0;
    end
end
if gap > 0, gaps(end+1) = gap; end
fprintf('  along the centreline: %d covered runs (longest %.0f m), %d open gaps (longest %.0f m)\n', ...
        numel(runs), max([runs 0]), numel(gaps), max([gaps 0]));

% ---------------------------------------------------------------- crown form
% REF-06 s1: "no more than 1 in 6 trees may be the round free-standing form."
% A tree is ROUND here if its crown is drawn circular in plan and unoffset. Column 8
% of W.Trees is the form code once s1world assigns one; before that every tree is
% round by construction, which is the finding.
if size(T,2) >= 8
    forms = T(:,8);
    % FROM THE WORLD, never retyped here. A local copy of this list silently
    % mislabels every row the moment s1world's cause set changes.
    if isfield(W,'FormNames'), names = W.FormNames;
    else, names = "form " + string(1:max(forms)); end
    fprintf('\n--- CROWN FORM (REF-06 s1: max 1 in 6 may be round free-standing) ---\n');
    for k = 1:numel(names)
        fprintf('  %-24s %5d  %5.1f %%\n', names(k), sum(forms==k), 100*mean(forms==k));
    end
    fprintf('  round free-standing: %.1f %% against a ceiling of %.1f %%  -> %s\n', ...
            100*mean(forms==1), 100/6, string(mean(forms==1) <= 1/6 + 1e-9));
    assert(mean(forms==1) <= 1/6 + 1e-9, "sc:s1formRound", ...
        "%.1f %% of trees are the round free-standing form, REF-06 s1 allows 1 in 6", ...
        100*mean(forms==1));
else
    fprintf('\n--- CROWN FORM ---\n  NO FORM CODE ASSIGNED: every tree is the round\n');
    fprintf('  free-standing form, i.e. 100 %% against REF-06 s1''s ceiling of 16.7 %%.\n');
end
fprintf('\n====================================================\n\n');
