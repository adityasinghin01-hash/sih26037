function drawStyledRoad(ax, P, s0, s1, halfW_m, Sty)
%DRAWSTYLEDROAD  One stretch of road (any sc.path), in the demo's locked
%   look - filled carriageway, dark edge lines, dashed centre line. Part
%   of Phase 1/2 of the checkpoint-demo build (11 Sep 2026).
%
%   halfW_m is the REAL half-width (e.g. W.Width/2) - Sty.RoadWidthMult is
%   applied here, once, so every caller passes the real number and this
%   is the only place the legibility exaggeration happens.

ss = s0:2:s1;
if numel(ss) < 2, return; end
hw = halfW_m * Sty.RoadWidthMult;
left = zeros(numel(ss),2); right = zeros(numel(ss),2);
for i = 1:numel(ss)
    left(i,:)  = P.at(ss(i),  hw);
    right(i,:) = P.at(ss(i), -hw);
end
V = [left; flipud(right)];
patch(ax, 'Faces', 1:size(V,1), 'Vertices', V, 'FaceColor', Sty.RoadFill, 'EdgeColor', 'none');
plot(ax, left(:,1),  left(:,2),  '-', 'Color', Sty.RoadEdge, 'LineWidth', Sty.RoadEdgeW);
plot(ax, right(:,1), right(:,2), '-', 'Color', Sty.RoadEdge, 'LineWidth', Sty.RoadEdgeW);

s = s0;
while s < s1
    e = min(s1, s + Sty.LaneSeg_m);
    a = P.at(s,0); b = P.at(e,0);
    plot(ax, [a(1) b(1)], [a(2) b(2)], '-', 'Color', Sty.LaneDash, 'LineWidth', Sty.LaneDashW);
    s = e + Sty.LaneGap_m;
end
end
