%% CHECK 7 — Can the cuboid environment represent a drop-off (khai)?
% Decides whether the ghat-road scenario is buildable at all, and whether a
% negative obstacle is detectable by lidar in simulation.
%
% Ten minutes. Run it and paste the whole output plus the figures.

diary('check07_output.txt'); diary on;
fprintf('\n===== CHECK 7 : NEGATIVE OBSTACLE / DRIVABLE CORRIDOR =====\n');
fprintf('Release : %s\n\n', version('-release'));

try
    %% Q1 — does a road carry elevation, and is there anything beside it?
    s = drivingScenario('SampleTime', 0.1);
    % A climbing road: x, y, z. Narrow, like a ghat section.
    cx = (0:10:200).';
    cz = (0:10:200).' * 0.06;              % ~6% gradient
    road(s, [cx, zeros(size(cx)), cz], ...
         'Lanes', lanespec(1, 'Width', 4, 'Marking', laneMarking('Unmarked')));
    fprintf('[1] Road with elevation created. RoadCenters z range: %.2f to %.2f m\n', ...
            min(cz), max(cz));

    rb = roadBoundaries(s);
    fprintf('[2] roadBoundaries returned %d boundary set(s).\n', numel(rb));
    if ~isempty(rb)
        b = rb{1};
        fprintf('    first set: %d points, z range %.2f to %.2f\n', ...
                size(b,1), min(b(:,3)), max(b(:,3)));
    end
    fprintf('    >> QUESTION: is the road a SURFACE with an edge, or just a centreline+width?\n');

    %% Q2 — does lidar return anything from the road, and nothing beside it?
    ego = vehicle(s, 'ClassID', 1, 'Position', [10 0 0.6]);
    lidar = lidarPointCloudGenerator('HasRoadsInputPort', true, ...
                                     'ActorProfiles', actorProfiles(s));
    fprintf('\n[3] lidarPointCloudGenerator created. HasRoadsInputPort = %d\n', ...
            lidar.HasRoadsInputPort);
    fprintf('    >> THE DECIDING QUESTION: with HasRoadsInputPort true, do we get\n');
    fprintf('       ground returns ON the road and NO returns beside it?\n');
    fprintf('       If yes, a drop-off is detectable as ABSENCE and the ghat scenario works.\n');
    fprintf('       If the road produces no returns at all, the cuboid world has no ground,\n');
    fprintf('       and the drop-off must be modelled another way (see NEXT below).\n');

    advance(s);
    tgts = targetPoses(ego);   % returns ONE output, not two
    rdmesh = roadMesh(ego);
    ptCloud = lidar(tgts, rdmesh, s.SimulationTime);
    n = size(ptCloud.Location, 1) * size(ptCloud.Location, 2);
    fprintf('\n[4] Point cloud returned: %d points\n', n);
    if n > 0
        L = reshape(ptCloud.Location, [], 3);
        L = L(all(isfinite(L), 2), :);
        fprintf('    finite points: %d\n', size(L,1));
        fprintf('    x %.1f..%.1f   y %.1f..%.1f   z %.1f..%.1f\n', ...
                min(L(:,1)), max(L(:,1)), min(L(:,2)), max(L(:,2)), min(L(:,3)), max(L(:,3)));
        fprintf('    >> If |y| stops near the 4 m road width, the road edge IS visible.\n');
        figure; pcshow(ptCloud); title('Check 7 — lidar over a 4 m road'); drawnow;
    else
        fprintf('    NO POINTS. Road surfaces may not generate returns in this release.\n');
    end

    %% Q3 — does vehicleCostmap give us the corridor for free?
    cm = vehicleCostmap(50, 50, 0.5);
    fprintf('\n[5] vehicleCostmap created: %s\n', class(cm));
    fprintf('    CollisionChecker: %s\n', class(cm.CollisionChecker));
    fprintf('    >> Can we mark everything outside roadBoundaries as occupied?\n');
    fprintf('       If yes, the corridor barrier h_road wraps a SHIPPED object — no new struct.\n');

catch ME
    fprintf('\n***** ERROR *****\n%s\n%s\n', ME.identifier, ME.message);
    for k = 1:numel(ME.stack)
        fprintf('  at %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end

fprintf('\n===== NEXT =====\n');
fprintf('If the cuboid world has NO ground beside the road, the fallbacks are:\n');
fprintf('  a) mark off-road as occupied in vehicleCostmap — corridor works, lidar demo does not\n');
fprintf('  b) place thin static actors along the drop edge as a stand-in wall\n');
fprintf('  c) do the ghat scenario in an Unreal scene instead, where terrain is real\n');
fprintf('Report which of these is needed. Do not summarise the error.\n');
diary off;
