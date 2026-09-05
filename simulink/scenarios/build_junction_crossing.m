%BUILD_JUNCTION_CROSSING  Two-vehicle crossing scenario for sih_planner.slx.
%
%   Leaves a drivingScenario named `scenario` in the caller's workspace.
%   sih_planner.slx's Scenario Reader is set to ScenarioSource = "From workspace"
%   and reads it by that name, so a fresh clone needs NO .mat file - the model's
%   PreLoadFcn runs this script. Nothing is saved: a raw drivingScenario written
%   to a .mat is NOT a format the Scenario Reader block accepts (it wants a
%   Driving Scenario Designer session), and derived files stay out of git anyway.
%
%   Verified headless on R2026a, 6 Sep 2026: the block loads this object in
%   "From workspace" mode and its Actors output carries the crossing vehicle;
%   loading the old saved-object .mat failed with
%   "not a supported driving scenario file".
%
%   Ego ActorID is 1, matching the Scenario Reader 'EgoVehicleActorID'.
%   The ego drives straight; a second car crosses its path from the side, timed
%   to arrive within about half a second of the ego. Closest approach ~1.56 m at
%   t~3.9 s - a genuine "who goes first" conflict, not a straight drive with no
%   agent in it (EgoVehicleGoesStraight.mat, the previous scenario, has no second
%   actor at all).

scenario = drivingScenario('SampleTime', 0.02, 'StopTime', 10);

road(scenario, [0 0 0; 80 0 0], 7);
road(scenario, [40 -30 0; 40 30 0], 7);

ego = vehicle(scenario, 'ClassID', 1, 'Position', [0 0 0], 'Yaw', 0);
smoothTrajectory(ego, [0 0 0; 80 0 0], [10 10]);

other = vehicle(scenario, 'ClassID', 1, 'Position', [40 -30 0], 'Yaw', 90);
smoothTrajectory(other, [40 -30 0; 40 30 0], [8 8]);

restart(scenario);   % hand it to the Scenario Reader at t = 0
