function drawEgoCar(ax, xy, yaw, Sty)
%DRAWEGOCAR  The ego, as an actual car-shaped rectangle at its real
%   dimensions - not a triangle. A car-footprint patch plus a lighter
%   stripe across the front third so the facing direction still reads at
%   a glance, without needing a real icon yet - Aditya's own call (11 Sep
%   2026): "we'll do [the exact look] later", this just has to stop being
%   an arrow.

[~, dims] = sc.meshes("car");   % [L W H], the same real car every other
L = dims(1)/2; W = dims(2)/2;   % run in this project measures against

al = [cos(yaw) sin(yaw)]; ac = [-sin(yaw) cos(yaw)];
body = xy + al.*[-L L L -L]' + ac.*[-W -W W W]';
patch(ax, body(:,1), body(:,2), Sty.EgoFill, 'EdgeColor', Sty.EgoEdge, 'LineWidth', 1.4);

frontC = xy + al*(L*0.55);
front = frontC + al.*[-L*0.20 L*0.20 L*0.20 -L*0.20]' + ac.*[-W*0.85 -W*0.85 W*0.85 W*0.85]';
patch(ax, front(:,1), front(:,2), Sty.EgoEdge, 'EdgeColor','none');
end
