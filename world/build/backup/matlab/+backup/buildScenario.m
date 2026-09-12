function [sc, route, R, S] = buildScenario(name, opts)
%BUILDSCENARIO  One scenario circle of the real Najibabad map as a drivingScenario.
%
%   Roads come from map/matlab_roads.csv - MATLAB'S OWN EXPORT - at the S0 section 4
%   widths, so the road the planner drives and the road Blender renders are the same
%   numbers by construction. Verified 4 Sep 2026: median 1.05 m over 1,625 points.
%
%   WHY NOT roadNetwork(...,'OpenStreetMap') FOR THE SCENARIO ITSELF
%   The importer carries no per-class carriageway width, and width is what the whole
%   planning argument rests on: S1's decision is 7.0 m carriageway minus a cow occupying
%   2.5-3.2 m minus a 1.9 m ego = 0.95 m each side. That number has to be OURS and
%   asserted. The importer IS still run, in backup.proveImport, as the provenance check.
%
%   OUTPUT
%     sc     drivingScenario with the roads laid, SampleTime set
%     route  Nx2 double  the ego centreline, m
%     R      struct array from backup.localRoads
%     S      the scenarioSpec

arguments
    name (1,1) string {mustBeMember(name,["S1","S2"])}
    opts.SampleTime (1,1) double = 0.05
end

S = backup.scenarioSpec(name);
R = backup.localRoads(S.Centre, S.RouteRadius);

sc = drivingScenario('SampleTime', opts.SampleTime, 'StopTime', S.Duration);

% ---- lay every road piece at its real width ----
nBuilt = 0;
for k = 1:numel(R)
    c = R(k).Centers;
    c = dedupe(c);
    if size(c,1) < 2, continue; end
    try
        road(sc, [c, zeros(size(c,1),1)], R(k).Width);
        nBuilt = nBuilt + 1;
    catch ME
        % a road MATLAB rejects (too tight a bend for its width) is reported, not hidden
        fprintf('  [road %d %s w=%.1f L=%.0f] REJECTED: %s\n', ...
                k, R(k).Class, R(k).Width, R(k).Length, ME.message);
    end
end
assert(nBuilt > 0, "backup:noRoadBuilt", "every road piece was rejected");

% ---- the ego route ----
route = backup.routeFrom(R, S.RouteStart, S.RouteEnd, 'classes', S.RouteClasses);
route = resamplePath(route, 1.0);          % 1 m stations, so chainage is exact

% ---- ASSERTIONS (Rule 3: every script asserts its dimensions and fails loudly) ----
W = dictionary("trunk",14.0,"trunk_link",7.0,"primary",10.5,"secondary",7.0, ...
               "tertiary",7.0,"unclassified",5.5,"residential",4.5, ...
               "living_street",3.2,"service",3.0,"track",3.0,"path",1.5);
for k = 1:numel(R)
    if isKey(W, R(k).Class)
        assert(abs(R(k).Width - W(R(k).Class)) < 1e-3, "backup:badWidth", ...
            "piece %d class %s built at %.3f m, table says %.3f m", ...
            k, R(k).Class, R(k).Width, W(R(k).Class));
    end
end
L = sum(vecnorm(diff(route),2,2));
assert(L > 150, "backup:shortRoute", "ego route only %.0f m", L);
assert(all(isfinite(route(:))), "backup:nanRoute", "route contains NaN or Inf");

fprintf('[%s] %d road pieces built (%d rejected), route %.0f m over %d stations\n', ...
        name, nBuilt, numel(R)-nBuilt, L, size(route,1));
end

% ---------------------------------------------------------------------------------------
function c = dedupe(c)
d = [1; vecnorm(diff(c),2,2)];
c = c(d > 1e-6, :);
end

function q = resamplePath(p, step)
%RESAMPLEPATH  Even stations along a polyline, so chainage means metres.
s = [0; cumsum(vecnorm(diff(p),2,2))];
[s, iu] = unique(s, 'stable');
p = p(iu,:);
sq = (0:step:s(end))';
if sq(end) < s(end), sq(end+1) = s(end); end
q = [interp1(s, p(:,1), sq), interp1(s, p(:,2), sq)];
end
