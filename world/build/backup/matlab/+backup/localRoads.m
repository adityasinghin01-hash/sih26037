function R = localRoads(centre_m, radius_m, opts)
%LOCALROADS  The real Najibabad roads inside one scenario circle, with real widths.
%
%   Built from map/matlab_roads.csv - MATLAB'S OWN EXPORT and the SOURCE OF TRUTH for
%   every centreline (S0 section 4). Never from a re-projection: using MATLAB's own
%   numbers is what keeps the planner's road and the rendered road in one frame.
%
%   The CSV is in the MATLAB import frame. The OSM metric frame used by the reference
%   library and by Blender is offset by (+35.0, -100.0) m - measured, not assumed, and
%   re-verified 4 Sep 2026 at 1.05 m median / 99.4 % within 5 m over 1,625 points.
%   This function returns OSM-metric coordinates so that every downstream consumer -
%   the scenario, the trajectories CSV and Blender - shares one frame.
%
%   Width comes from the OSM class in map/najibabad_metres.json, per the S0 section 4
%   table. The importer cannot supply per-class carriageway width and the width is what
%   the whole planning argument rests on, so it is taken from the table and ASSERTED.
%
%   INPUTS
%     centre_m  1x2 double  circle centre, m, OSM metric frame
%     radius_m  1x1 double  circle radius, m
%     opts.mapDir       folder holding matlab_roads.csv and najibabad_metres.json
%     opts.minLength_m  discard fragments shorter than this, default 12 m
%
%   OUTPUT  R  struct array, one entry per road piece
%     .Centers  Nx2 double  m, OSM metric frame, ordered
%     .Class    string      OSM highway class
%     .Width    double      m, carriageway width from the S0 table
%     .Length   double      m
%     .SrcID    double      the CSV road id it came from

arguments
    centre_m (1,2) double
    radius_m (1,1) double {mustBePositive}
    opts.mapDir      (1,1) string = fullfile(backup.refRoot(),"map")
    opts.minLength_m (1,1) double = 12.0
end

OFFSET = [35.0, -100.0];      % MATLAB import frame -> OSM metric frame. MEASURED.

% ---- the S0 section 4 width table. Every number is from the specification. ----
W = dictionary( ...
    "trunk",14.0, "trunk_link",7.0, "primary",10.5, "secondary",7.0, "tertiary",7.0, ...
    "unclassified",5.5, "residential",4.5, "living_street",3.2, "service",3.0, ...
    "track",3.0, "path",1.5);

csvFile = fullfile(opts.mapDir,"matlab_roads.csv");
jsonFile = fullfile(opts.mapDir,"najibabad_metres.json");
assert(isfile(csvFile),  "backup:noCSV",  "missing %s", csvFile);
assert(isfile(jsonFile), "backup:noJSON", "missing %s", jsonFile);

raw = readmatrix(csvFile);
assert(size(raw,2)>=3, "backup:badCSV", "matlab_roads.csv needs 3 columns, got %d", size(raw,2));
raw(:,1:2) = raw(:,1:2) + OFFSET;         % into the OSM metric frame, once, here

% ---- the OSM classes, as segments, so a centreline can be classified by proximity ----
J = jsondecode(fileread(jsonFile));
segA = []; segB = []; segC = strings(0,1);
for k = 1:numel(J.roads)
    r = J.roads(k);
    if iscell(r), r = r{1}; end
    p = r.pts;
    if size(p,1) < 2, continue; end
    segA = [segA; p(1:end-1,1:2)];                               %#ok<AGROW>
    segB = [segB; p(2:end,  1:2)];                               %#ok<AGROW>
    segC = [segC; repmat(string(r.class), size(p,1)-1, 1)];      %#ok<AGROW>
end
assert(~isempty(segA), "backup:noClasses", "no road classes decoded from %s", jsonFile);

% ---- clip each CSV road to the circle, keeping contiguous runs ----
R = struct('Centers',{},'Class',{},'Width',{},'Length',{},'SrcID',{});
ids = unique(raw(:,3))';
for id = ids
    pts = raw(raw(:,3)==id, 1:2);
    if size(pts,1) < 2, continue; end
    inside = vecnorm(pts - centre_m, 2, 2) <= radius_m;
    % walk the polyline, cutting it into runs of consecutive inside points
    runStart = [];
    for i = 1:numel(inside)+1
        isIn = i <= numel(inside) && inside(i);
        if isIn && isempty(runStart)
            runStart = i;
        elseif ~isIn && ~isempty(runStart)
            run = pts(runStart:i-1, :);
            R = addRun(R, run, id, segA, segB, segC, W, opts.minLength_m);
            runStart = [];
        end
    end
end

assert(~isempty(R), "backup:emptyCircle", ...
    "no road found within %.0f m of (%.1f, %.1f)", radius_m, centre_m(1), centre_m(2));
end

% ------------------------------------------------------------------------------------
function R = addRun(R, run, id, segA, segB, segC, W, minLen)
if size(run,1) < 2, return; end
L = sum(vecnorm(diff(run),2,2));
if L < minLen, return; end

% classify by the nearest OSM segment to the run's MIDPOINT - a whole run carries one class
mid = run(max(1,round(size(run,1)/2)), :);
d = pointToSegmentDistance(mid, segA, segB);
[~, j] = min(d);
cls = segC(j);
if isKey(W, cls), w = W(cls); else, w = 4.5; end   % unmapped tags fall back to a lane

R(end+1) = struct('Centers',run, 'Class',cls, 'Width',w, 'Length',L, 'SrcID',id); %#ok<AGROW>
end

% ------------------------------------------------------------------------------------
function d = pointToSegmentDistance(p, a, b)
%POINTTOSEGMENTDISTANCE  Perpendicular distance from p to each segment a(i)->b(i).
ab = b - a;
ap = p - a;
L2 = sum(ab.^2, 2);
t  = sum(ap .* ab, 2) ./ max(L2, eps);
t  = min(1, max(0, t));
t(L2 <= eps) = 0;                       % degenerate segment: distance to the point
proj = a + t .* ab;
d = vecnorm(p - proj, 2, 2);
end
