%BUILD_JUNCTION_CROSSING  A real two-vehicle crossing scenario for sih_planner.slx.
%
%   Ego drives straight along a road. A second vehicle crosses its path from the
%   side, timed to arrive at the crossing point within about half a second of the
%   ego - a genuine "who goes first" encounter, not a straight-line drive with no
%   agent in it. Built for Stream D's Simulink model, which currently reads
%   EgoVehicleGoesStraight.mat (a MathWorks sample with no other actor at all).
%
%   Ego ActorID is 1, matching sih_planner.slx's Scenario Reader
%   'EgoVehicleActorID' parameter. Variable name is 'scenario', matching the
%   block's 'ScenarioVariableName'. Sample time and stop time match the model's
%   own solver config (0.02 s fixed step, 10 s).

scenario = drivingScenario('SampleTime', 0.02, 'StopTime', 10);

road(scenario, [0 0 0; 80 0 0], 7);
road(scenario, [40 -30 0; 40 30 0], 7);

ego = vehicle(scenario, 'ClassID', 1, 'Position', [0 0 0], 'Yaw', 0);
smoothTrajectory(ego, [0 0 0; 80 0 0], [10 10]);

other = vehicle(scenario, 'ClassID', 1, 'Position', [40 -30 0], 'Yaw', 90);
smoothTrajectory(other, [40 -30 0; 40 30 0], [8 8]);

outFile = fullfile(fileparts(mfilename('fullpath')), 'junction_crossing.mat');
save(outFile, 'scenario');
fprintf('saved: %s\n', outFile);

% ------------------------------------------------------------- sanity check
r1 = record(scenario);
p1 = vertcat(r1(1).ActorPoses(1).Position);   % won't work across steps this way; use loop
restart(scenario);
minSep = inf; tMin = NaN;
while advance(scenario)
    poses = actorPoses(scenario);
    d = norm(poses(1).Position(1:2) - poses(2).Position(1:2));
    if d < minSep
        minSep = d; tMin = scenario.SimulationTime;
    end
end
fprintf('closest approach: %.2f m at t = %.2f s\n', minSep, tMin);
fprintf('EGO ActorID = %d (must be 1)\n', ego.ActorID);
