function drawGyratory(ax, W2, Sty)
%DRAWGYRATORY  S2's real roundabout geometry, in the demo's locked style.
%   Part of Phase 2 of the checkpoint-demo build (11 Sep 2026) - the
%   viewer previously had no way to draw S2 at all (its own ring/arms/
%   monument fields are unique to it, not among sc.plannerView's generic
%   furniture types).
%
%   Draws: the 4 real arms (sc.drawStyledRoad, same look as every other
%   road), the circulating carriageway as a filled ring (the outer disc
%   drawn first, the island drawn on top - simpler than a true annulus
%   polygon and visually identical), the central island, and the
%   plinth+statue as one marker. W2 is the struct sc.s2world() returns -
%   read only, this file never touches +sc/s2world.m itself.

th = linspace(0, 2*pi, 96)';
outer = W2.Centre + W2.Rout*[cos(th) sin(th)];
patch(ax, outer(:,1), outer(:,2), Sty.RingFill, 'EdgeColor', Sty.RingEdge, 'LineWidth', Sty.RoadEdgeW);

for k = 1:numel(W2.Arm)
    sc.drawStyledRoad(ax, W2.Arm(k).Path, 0, W2.Arm(k).Path.Len, W2.ArmW/2, Sty);
end

island = W2.Centre + W2.Rin*[cos(th) sin(th)];
patch(ax, island(:,1), island(:,2), Sty.IslandFill, 'EdgeColor', Sty.RingEdge, 'LineWidth', 1.2);

% the plinth - a small square at centre, the statue a dot on top of it, real dims
pw = W2.Plinth.W/2;
sq = W2.Centre + pw*[-1 -1; 1 -1; 1 1; -1 1];
patch(ax, sq(:,1), sq(:,2), Sty.PlinthFill, 'EdgeColor', Sty.PlinthEdge, 'LineWidth', 1.2);
plot(ax, W2.Centre(1), W2.Centre(2), 'o', 'MarkerSize', 6, ...
     'MarkerFaceColor', Sty.PlinthEdge, 'MarkerEdgeColor', 'none');
end
