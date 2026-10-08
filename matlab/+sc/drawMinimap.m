function drawMinimap(axMini, P, egoXY, egoS, radius, Sty, actorsXY)
%DRAWMINIMAP  A circular local-view inset, GTA-minimap style - the car
%   fixed at centre, north marked, the real road for `radius` metres
%   either side of it. Part of Phase 6 of the checkpoint-demo build
%   (11 Sep 2026).
%
%   TAKES AN EXISTING AXES, does not create one. The first version of this
%   file created a fresh inset axes every call - harmless in a one-figure-
%   per-frame batch render, a real leak in a long-running interactive
%   window (sc.checkpointDemo), where every frame would stack another
%   orphaned axes on top of the last. The caller creates axMini ONCE and
%   passes it back in every frame; this only clears and redraws into it.
%
%   INPUTS
%     axMini        the inset's own axes (already positioned by the caller)
%     P             the sc.path currently being driven (the merged route)
%     egoXY, egoS   the ego's real world position and its station on P
%     radius        m, half-width of the minimap's own view
%     Sty           sc.demoStyle()
%     actorsXY      Nx2 double, optional - nearby density-actor positions,
%                   drawn as small blips (position only - the minimap is a
%                   locator, not a second full render)

if nargin < 7, actorsXY = zeros(0,2); end

cla(axMini);
hold(axMini,'on'); axis(axMini,'equal'); axis(axMini,'off');

sWindow = -radius:2:radius;
pts = zeros(numel(sWindow),2);
for i = 1:numel(sWindow)
    pts(i,:) = P.at(egoS+sWindow(i), 0) - egoXY;
end
plot(axMini, pts(:,1), pts(:,2), '-', 'Color', Sty.RoadFill, 'LineWidth', 4);

if ~isempty(actorsXY)
    rel = actorsXY - egoXY;
    keep = hypot(rel(:,1), rel(:,2)) <= radius;
    plot(axMini, rel(keep,1), rel(keep,2), '.', 'MarkerSize', 12, 'Color', Sty.VehicleColor);
end

plot(axMini, 0, 0, '^', 'MarkerSize', 9, 'MarkerFaceColor', Sty.EgoFill, 'MarkerEdgeColor','w', 'LineWidth',1);

th = linspace(0,2*pi,120);
circ = radius*[cos(th)' sin(th)'];
plot(axMini, circ(:,1), circ(:,2), '-', 'Color', Sty.MinimapRing, 'LineWidth', 3);
text(axMini, 0, radius*1.14, 'N', 'Color', Sty.MinimapRing, 'FontWeight','bold', ...
     'HorizontalAlignment','center', 'FontSize', 9);

xlim(axMini, radius*1.3*[-1 1]); ylim(axMini, radius*1.3*[-1 1]);
set(axMini, 'Color', 'none');
end
