f = '/Users/aditya/Desktop/SIH26037-Reference/map/najibabad.osm';
out = '/Users/aditya/Desktop/SIH26037-Reference/map/matlab_roads.csv';
fprintf('MATLAB %s\n', version);
s = drivingScenario;
try
    roadNetwork(s, 'OpenStreetMap', f);
    fprintf('IMPORT OK\n');
catch ME
    fprintf('IMPORT FAILED: %s\n', ME.message); return;
end
p = properties(s);
fprintf('scenario properties: %s\n', strjoin(p', ', '));
n = 0; allpts = [];
try
    rs = s.RoadSegments;
    n = numel(rs);
    fprintf('RoadSegments: %d\n', n);
    for k = 1:n
        c = rs(k).RoadCenters;
        allpts = [allpts; c(:,1:2), repmat(k,size(c,1),1)]; %#ok<AGROW>
    end
catch ME
    fprintf('RoadSegments unavailable: %s\n', ME.message);
end
if isempty(allpts)
    try
        rp = roadprops(s); n = height(rp);
        fprintf('roadprops rows: %d\n', n);
        for k = 1:n
            c = rp.RoadCenters{k};
            allpts = [allpts; c(:,1:2), repmat(k,size(c,1),1)]; %#ok<AGROW>
        end
    catch ME2
        fprintf('roadprops failed: %s\n', ME2.message);
    end
end
if isempty(allpts)
    fprintf('NO ROAD GEOMETRY EXTRACTED\n'); return;
end
writematrix(allpts, out);
L = 0;
for k = unique(allpts(:,3))'
    c = allpts(allpts(:,3)==k, 1:2);
    L = L + sum(vecnorm(diff(c),2,2));
end
fprintf('roads=%d  points=%d\n', n, size(allpts,1));
fprintf('x range %.1f .. %.1f   y range %.1f .. %.1f\n', ...
    min(allpts(:,1)), max(allpts(:,1)), min(allpts(:,2)), max(allpts(:,2)));
fprintf('total centreline length = %.1f m\n', L);
fprintf('WROTE %s\n', out);
