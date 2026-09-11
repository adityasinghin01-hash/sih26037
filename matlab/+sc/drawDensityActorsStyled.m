function drawDensityActorsStyled(ax, A, Sty)
%DRAWDENSITYACTORSSTYLED  One frame of sc.activeDensityActorsAt's output,
%   in the demo's locked style. Part of Phase 4 of the checkpoint-demo
%   build (11 Sep 2026) - "the scenario turns on" means these tracks
%   start appearing as the ego enters a checkpoint's own span.
%
%   Grouped by KIND, not the full S5 ClassID list (AGENTS.md s5) - a judge
%   watching a live demo reads "a person", "an animal", "a vehicle" at a
%   glance; 10 visually distinct icons for 10 classes is detail nobody
%   asked for at this stage. The real ClassID is still what's stored and
%   fed anywhere else that needs it - this function only draws.

for k = 1:numel(A)
    a = A(k);
    xy = a.XY; ext = a.Extent; yaw = a.YawRad;
    switch a.ClassID
        case 8   % pedestrian
            plot(ax, xy(1), xy(2), 'o', 'MarkerSize', 5, 'MarkerFaceColor', Sty.PersonColor, 'MarkerEdgeColor','none');
        case 10  % cow
            drawBox(ax, xy, yaw, ext, Sty.CowColor);
        case {0, 11}  % goat, dog - small ground animals
            drawBox(ax, xy, yaw, ext, Sty.AnimalColor);
        otherwise  % everything wheeled: bolero/auto/moto/bicycle/cart/tractor/trolley
            drawBox(ax, xy, yaw, ext, Sty.VehicleColor);
    end
end
end

function drawBox(ax, xy, yaw, ext, color)
L = ext(1)/2; Wd = ext(2)/2;
al = [cos(yaw) sin(yaw)]; ac = [-sin(yaw) cos(yaw)];
corners = xy + al.*[-L L L -L]' + ac.*[-Wd -Wd Wd Wd]';
patch(ax, corners(:,1), corners(:,2), color, 'EdgeColor', color*0.6, 'LineWidth', 0.8);
end
