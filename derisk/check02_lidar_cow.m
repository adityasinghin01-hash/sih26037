%% CHECK 2 — THE CRITICAL ONE
% Unmarked road + custom cow mesh + lidar point cloud with returns OFF THE COW.
% If this fails, the in-loop perception design changes. Send back the FULL output
% and the saved figure.

diary('check02_output.txt'); diary on;
fprintf('\n===== CHECK 2 : LIDAR RETURNS OFF A CUSTOM COW MESH =====\n');
fprintf('Date run : %s\nRelease  : %s\n\n', datestr(now), version('-release'));

try
%% ---------- 1. UNMARKED ROAD ---------------------------------------
fprintf('[1] Building an UNMARKED road...\n');
scenario = drivingScenario('SampleTime', 0.1, 'StopTime', 6);

roadCenters = [0 0 0; 30 0 0; 60 0 0];
lm  = laneMarking('Unmarked');
ls  = lanespec(1, 'Width', 12, 'Marking', lm);
road(scenario, roadCenters, 'Lanes', ls);
fprintf('    OK. One 12 m lane, marking = Unmarked (no painted lines).\n');

%% ---------- 2. BUILD A COW MESH -------------------------------------
fprintf('[2] Building a custom cow mesh from explicit vertices/faces...\n');
V = []; F = [];
parts = { ...
    [ 0.00  0.00  0.95], [1.90 0.65 0.85]; ...  % body
    [ 1.15  0.00  1.15], [0.55 0.35 0.40]; ...  % head
    [ 0.65  0.22  0.38], [0.14 0.14 0.75]; ...  % leg front-left
    [ 0.65 -0.22  0.38], [0.14 0.14 0.75]; ...  % leg front-right
    [-0.65  0.22  0.38], [0.14 0.14 0.75]; ...  % leg rear-left
    [-0.65 -0.22  0.38], [0.14 0.14 0.75]};     % leg rear-right

for p = 1:size(parts,1)
    [Vp, Fp] = localBox(parts{p,1}, parts{p,2});
    F = [F; Fp + size(V,1)];   %#ok<AGROW>
    V = [V; Vp];               %#ok<AGROW>
end
fprintf('    Mesh built: %d vertices, %d triangular faces.\n', size(V,1), size(F,1));
fprintf('    Bounds  X[%.2f %.2f]  Y[%.2f %.2f]  Z[%.2f %.2f] metres\n', ...
        min(V(:,1)),max(V(:,1)),min(V(:,2)),max(V(:,2)),min(V(:,3)),max(V(:,3)));

cowMesh = extendedObjectMesh(V, F);
fprintf('    extendedObjectMesh created OK.\n');

%% ---------- 3. ADD THE COW AS AN ACTOR ------------------------------
fprintf('[3] Adding the cow to the scenario as a custom-mesh actor...\n');
cowPos = [38 1.5 0];
cow = actor(scenario, 'ClassID', 5, ...
            'Length', 1.90, 'Width', 0.65, 'Height', 1.40, ...
            'Mesh', cowMesh, 'Position', cowPos);
fprintf('    OK. Cow ActorID = %d, standing at [%.1f %.1f %.1f].\n', ...
        cow.ActorID, cowPos);

%% ---------- 4. EGO VEHICLE ------------------------------------------
fprintf('[4] Adding the ego vehicle...\n');
ego = vehicle(scenario, 'ClassID', 1, 'Mesh', driving.scenario.carMesh);
smoothTrajectory(ego, [2 0 0; 30 0 0], 8);
fprintf('    OK. Ego ActorID = %d, driving 2 m -> 30 m at 8 m/s.\n', ego.ActorID);

%% ---------- 5. LIDAR -------------------------------------------------
fprintf('[5] Configuring lidarPointCloudGenerator...\n');
lidar = lidarPointCloudGenerator( ...
    'SensorLocation',     [1.5 0], ...
    'Height',             1.6, ...
    'MaxRange',           80, ...
    'AzimuthResolution',  0.32, ...
    'ElevationResolution',0.5, ...
    'HasRoadsInputPort',  true, ...
    'ActorProfiles',      actorProfiles(scenario), ...
    'EgoVehicleActorID',  ego.ActorID);
fprintf('    OK. MaxRange 80 m, mounted 1.6 m high.\n');

%% ---------- 6. RUN AND COUNT ----------------------------------------
fprintf('[6] Running the simulation and counting points...\n\n');
fprintf('    %-8s %-12s %-14s %-12s\n','time','total pts','pts ON COW','ego x');
fprintf('    %s\n', repmat('-',1,50));

maxCowPts = 0; bestCloud = []; bestT = NaN; anyPoints = false;
while advance(scenario)
    actors = actorPoses(ego);
    rdMesh = roadMesh(ego);
    [ptCloud, isValid] = lidar(actors, rdMesh, scenario.SimulationTime);

    if isValid && ptCloud.Count > 0
        anyPoints = true;
        loc  = reshape(ptCloud.Location, [], 3);
        loc  = loc(all(isfinite(loc),2), :);

        egoPose = actorPoses(scenario); egoPose = egoPose([egoPose.ActorID]==ego.ActorID);
        cowRelX = cowPos(1) - egoPose.Position(1);
        cowRelY = cowPos(2) - egoPose.Position(2);

        onCow = abs(loc(:,1)-cowRelX) < 1.5 & ...
                abs(loc(:,2)-cowRelY) < 1.0 & loc(:,3) > 0.15;
        nCow  = sum(onCow);

        fprintf('    %-8.1f %-12d %-14d %-12.1f\n', ...
                scenario.SimulationTime, ptCloud.Count, nCow, egoPose.Position(1));

        if nCow > maxCowPts
            maxCowPts = nCow; bestCloud = loc; bestT = scenario.SimulationTime;
        end
    end
end

%% ---------- 7. VERDICT -----------------------------------------------
fprintf('\n===== VERDICT =====\n');
fprintf('Any lidar points at all      : %s\n', ternary(anyPoints,'YES','NO'));
fprintf('Max points landing ON THE COW: %d   (at t = %.1f s)\n', maxCowPts, bestT);

if maxCowPts >= 10
    fprintf('\n  PASS. Lidar returns come off the custom cow mesh.\n');
    fprintf('  The in-loop perception design HOLDS. Proceed to check 3.\n');
elseif anyPoints
    fprintf('\n  PARTIAL. Point cloud works but few/no returns off the cow.\n');
    fprintf('  Send this output back before changing anything.\n');
else
    fprintf('\n  FAIL. No point cloud at all. Send the full output back.\n');
end

if ~isempty(bestCloud)
    fig = figure('Visible','on');
    scatter3(bestCloud(:,1), bestCloud(:,2), bestCloud(:,3), 6, bestCloud(:,3), 'filled');
    axis equal; grid on; view(-35,20);
    xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
    title(sprintf('Lidar point cloud at t=%.1fs — %d points on cow', bestT, maxCowPts));
    saveas(fig, 'check02_pointcloud.png');
    fprintf('\nFigure saved: check02_pointcloud.png  <-- send this image too\n');
end

catch ME
    fprintf('\n***** ERROR *****\n');
    fprintf('Identifier : %s\n', ME.identifier);
    fprintf('Message    : %s\n', ME.message);
    for k = 1:numel(ME.stack)
        fprintf('  at %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    fprintf('***** SEND THIS ENTIRE BLOCK BACK, UNSUMMARISED *****\n');
end

diary off;
fprintf('\nOutput also saved to check02_output.txt\n');

%% ---------- local helpers ---------------------------------------------
function [V, F] = localBox(center, dims)
    hx = dims(1)/2; hy = dims(2)/2; hz = dims(3)/2;
    V = [-hx -hy -hz;  hx -hy -hz;  hx  hy -hz; -hx  hy -hz; ...
         -hx -hy  hz;  hx -hy  hz;  hx  hy  hz; -hx  hy  hz];
    V = V + repmat(center, 8, 1);
    F = [1 3 2; 1 4 3;  5 6 7; 5 7 8;  1 2 6; 1 6 5; ...
         2 3 7; 2 7 6;  3 4 8; 3 8 7;  4 1 5; 4 5 8];
end

function out = ternary(cond, a, b)
    if cond, out = a; else, out = b; end
end
