%S1_REVEAL_PROBE  Two questions the S1 result rests on, answered with numbers.
%
%   Q1  The solved reveal tests the sight line to ONE POINT, the cow's origin. At the
%       solved distance that line only GRAZES the thicket, so the animal is still behind
%       it in the render - the model says "visible" and the picture says "hidden".
%       How far apart are point-visibility and silhouette-visibility?
%
%   Q2  SPEC.md says the reveal is done by "the forest edge and the road's own
%       curvature", i.e. that it is computed rather than authored. Is that true anywhere
%       on this route? Where are the bends, and what reveal does the treeline alone give?

here = fileparts(mfilename('fullpath')); addpath(here);
W = sc.s1world();
P = W.Path;  CS = W.CowStation;  CE = W.CowEmergeE;

TRUNKS = [W.Trees(:,1) W.Trees(:,2) W.Trees(:,3)];
SCRUB  = W.Scrub(1:end-1, 1:3);            % everything EXCEPT the authored thicket
NAT    = [TRUNKS; SCRUB];                  % the "natural" forest, nothing authored
ALL    = W.Occluders;

% the cow's silhouette across the road: 2.20 m of body, sampled at 5 points
EXT = linspace(-1.10, 1.10, 5);
NEED = 3;                                  % 3 of 5 clear = enough to classify it

fprintf('\n=========== Q1 - POINT vs SILHOUETTE ===========\n');
fprintf('  %-7s %-9s %-11s %s\n','gap','centre','silhouette','points clear');
for gap = [60 50 46 44 42 40 36 32 28 24 20 16]
    c = P.visible(CS-gap, 1.75, CS, CE, ALL);
    k = 0;
    for e = EXT, k = k + P.visible(CS-gap, 1.75, CS, CE+e, ALL); end
    fprintf('  %4.0f m  %-9s %-11s %d/5\n', gap, string(c), string(k>=NEED), k);
end

fprintf('\n=========== Q2 - WHERE ARE THE BENDS? ===========\n');
kap = P.curvature(25);
[~, pk] = maxk(kap, 1);
fprintf('  route %.0f m | peak curvature %.5f rad/m at station %.0f m (radius %.0f m)\n', ...
        P.Len, kap(pk), (pk-1)*P.Step, 1/max(kap(pk),1e-9));
fprintf('  stations with radius under 150 m: ');
tight = find(kap > 1/150) - 1;
if isempty(tight), fprintf('none\n'); else
    fprintf('%.0f-%.0f m\n', min(tight), max(tight)); end

fprintf('\n=========== Q2 - NATURAL REVEAL, NOTHING AUTHORED ===========\n');
fprintf('  cow at station -> reveal from trunks + scrub alone (silhouette, %d of 5)\n', NEED);
fprintf('  %-9s %-10s %-10s %s\n','station','centre','silhouette','road radius');
best = []; 
for cs = 60:20:P.Len-60
    dC = 0; dS = 0;
    for gap = 4:2:150
        s = cs - gap; if s < 0, break; end
        if P.visible(s, 1.75, cs, CE, NAT), dC = gap; else, break; end
    end
    for gap = 4:2:150
        s = cs - gap; if s < 0, break; end
        k = 0;
        for e = EXT, k = k + P.visible(s, 1.75, cs, CE+e, NAT); end
        if k >= NEED, dS = gap; else, break; end
    end
    i = min(numel(kap), max(1, round(cs/P.Step)+1));
    r = 1/max(kap(i), 1e-9);
    if dS > 0 && dS < 150
        fprintf('  %6.0f m  %6.0f m   %6.0f m     %8.0f m\n', cs, dC, dS, min(r,9999));
        best(end+1,:) = [cs dC dS r];                                  %#ok<SAGROW>
    end
end
if isempty(best)
    fprintf('  NO STATION on this route gets a bounded natural reveal - the forest as\n');
    fprintf('  placed never blocks this sight line, so an authored occluder is required.\n');
else
    inRange = best(best(:,3) >= 30 & best(:,3) <= 60, :);
    fprintf('\n  stations whose NATURAL silhouette reveal lands in 30-60 m: %d\n', size(inRange,1));
    if ~isempty(inRange)
        fprintf('  e.g. station %.0f m -> %.0f m natural reveal (road radius %.0f m)\n', ...
                inRange(1,1), inRange(1,3), min(inRange(1,4),9999));
    end
end
fprintf('\n');
