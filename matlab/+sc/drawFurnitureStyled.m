function drawFurnitureStyled(ax, W, P, Sty)
%DRAWFURNITURESTYLED  Buildings, poles, signs, drains, service drops, side
%   roads and roadside tree scatter, in the demo's locked style. Part of
%   Phase 3 of the checkpoint-demo build (11 Sep 2026) - the styled
%   counterpart to sc.plannerView's own drawWorldFurniture, kept as
%   separate new code for the same reason every other Phase 1-3 file is
%   separate: sc.plannerView.m is shared with the live team's demo_play.m
%   and is not touched by this initiative.
%
%   Every field is optional, same convention as the file it parallels -
%   this draws whatever W actually carries and does not judge whether the
%   counts are real or chosen (that disclosure lives in the world file).

if isfield(W,'Buildings') && ~isempty(W.Buildings)
    for b = W.Buildings
        [~, hdg] = P.at(b.Station, 0);
        c = P.at(b.Station, b.Lateral);
        al = [cos(hdg) sin(hdg)]; ac = [-sin(hdg) cos(hdg)];
        d_ = fieldOrD(b,'Depth',6.0)/2; w_ = fieldOrD(b,'Width',6.0)/2;
        corners = c + al.*[-d_ d_ d_ -d_]' + ac.*[-w_ -w_ w_ w_]';
        patch(ax, corners(:,1), corners(:,2), Sty.BuildingFill, 'EdgeColor', Sty.BuildingEdge, 'LineWidth', 1.0);
    end
end

if isfield(W,'TreeScatter') && ~isempty(W.TreeScatter)
    n = numel(W.TreeScatter);
    cx = zeros(n,1); cy = zeros(n,1); cr = zeros(n,1);
    for i = 1:n
        t = W.TreeScatter(i);
        xy = P.at(t.Station, t.Lateral);
        cx(i) = xy(1); cy(i) = xy(2); cr(i) = t.CrownR;
    end
    scatter(ax, cx, cy, max(4,(cr*8)).^2, 'filled', ...
        'MarkerFaceColor', Sty.TreeDotFill, 'MarkerFaceAlpha', Sty.ForestAlpha, 'MarkerEdgeColor','none');
end

if isfield(W,'Poles') && ~isempty(W.Poles)
    for p = W.Poles
        xy = P.at(p.Station, p.Lateral);
        plot(ax, xy(1), xy(2), 'o', 'MarkerSize', 3.5, 'MarkerFaceColor', Sty.PoleColor, 'MarkerEdgeColor','none');
    end
end

if isfield(W,'Signs') && ~isempty(W.Signs)
    for sg = W.Signs
        xy = P.at(sg.Station, sg.Lateral);
        plot(ax, xy(1), xy(2), '^', 'MarkerSize', 6, 'MarkerFaceColor', Sty.SignColor, 'MarkerEdgeColor','none');
    end
end

if isfield(W,'Drains') && ~isempty(W.Drains)
    for d = W.Drains
        a = P.at(d.S0, d.Lateral); b = P.at(d.S1, d.Lateral);
        plot(ax, [a(1) b(1)], [a(2) b(2)], '-', 'Color', Sty.DrainColor, 'LineWidth', 2.5);
    end
end

if isfield(W,'ServiceDrops') && ~isempty(W.ServiceDrops)
    for s = W.ServiceDrops
        a = P.at(s.S0, s.Lateral0); b = P.at(s.S1, s.Lateral1);
        plot(ax, [a(1) b(1)], [a(2) b(2)], '-', 'Color', Sty.ServiceColor, 'LineWidth', 0.8);
    end
end

if isfield(W,'SideRoads') && ~isempty(W.SideRoads)
    for r = W.SideRoads
        plot(ax, r.XY(:,1), r.XY(:,2), '-', 'Color', Sty.SideRoadColor, 'LineWidth', 2.0);
    end
end
end

function v = fieldOrD(s, f, dflt)
if isfield(s,f) && ~isempty(s.(f)), v = s.(f); else, v = dflt; end
end
