function tests = testDefaults
%TESTDEFAULTS  Unit tests for sih.planner.defaults - the design numbers, in one place.
%
%   RUN IT:   results = runtests('matlab/tests/testDefaults.m'); disp(results)
%
%   The point of this file is DRIFT. defaults.m restates values that already live in
%   fifteen arguments blocks, so the only real risk it carries is that one of them
%   changes and the other does not. Most of what is below is that check, done by
%   calling each function twice - once with no options, once with these values - and
%   failing if the two answers differ.
tests = functiontests(localfunctions);
end

function setupOnce(tc) %#ok<INUSD>
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'..'));          % puts matlab/ on the path so +sih resolves
end

% ---------------------------------------------------------------- classification

function testEveryNumberIsClassifiedAsExactlyOneKind(tc)
% The easy mistake is adding a number and quietly leaving it unlabelled, which is how
% a chosen figure ends up in a report reading as a measurement. This fails when that
% happens, and names the offender.
d      = sih.planner.defaults();
names  = setdiff(string(fieldnames(d)).', ["Measured" "Contract" "Chosen"], 'stable');
listed = [d.Measured, d.Contract, d.Chosen];

missing = setdiff(names, listed);
verifyEmpty(tc, missing, ...
    "unclassified design number(s): " + strjoin(missing, ", "));

verifyEqual(tc, numel(listed), numel(unique(listed)), ...
    'a field is listed under more than one kind');
verifyEqual(tc, sort(listed), sort(names));
end

function testExactlyOneNumberIsCalledMeasured(tc)
% world/scenarios/S0-THE-WORLD.md section 4 gives tertiary = 7.0 m. Nothing else in
% the planner has a citation of that shape, and nothing else may claim one.
d = sih.planner.defaults();
verifyEqual(tc, d.Measured, "turnRoadWidth_m");
verifyEqual(tc, d.turnRoadWidth_m, 7.0);
end

function testTheContractNumbersAreTheOnesS4Fixes(tc)
d = sih.planner.defaults();
verifyEqual(tc, sort(d.Contract), sort(["limitAccel_mps2", "limitSteer_rad", ...
                                        "cmdEmergencyAccel_mps2", "vehicleMaxSteer_rad"]));
verifyEqual(tc, d.limitAccel_mps2, [-6 3]);
verifyEqual(tc, d.limitSteer_rad,  [-0.6 0.6]);
end

function testMostOfThemAreCHOSENAndThatIsTheHonestAnswer(tc)
% If this list ever gets short, somebody has started calling choices measurements.
d = sih.planner.defaults();
verifyGreaterThan(tc, numel(d.Chosen), 20);
end

% ------------------------------------------------- the numbers match the functions

function testPlanTurnAgreesWithWhatIsWrittenHere(tc)
d     = sih.planner.defaults();
route = struct('GoalHeading', pi, 'Valid', true);
ego   = struct('Position',[0 0 0], 'Velocity',[5 0 0], 'Yaw',0);

bare = sih.planner.planTurn(route, ego);
same = sih.planner.planTurn(route, ego, ...
          roadWidth_m     = d.turnRoadWidth_m, ...
          wheelbase_m     = d.vehicleWheelbase_m, ...
          maxSteer_rad    = d.vehicleMaxSteer_rad, ...
          egoWidth_m      = d.vehicleWidth_m, ...
          egoLength_m     = d.vehicleLength_m, ...
          cutMinAngle_rad = d.turnCutMinAngle_rad, ...
          uturnAngle_rad  = d.turnUturnAngle_rad, ...
          streamWidth_m   = d.turnStreamWidth_m, ...
          refugeMargin_m  = d.turnRefugeMargin_m);

verifyEqual(tc, same.NumSegments,     bare.NumSegments);
verifyEqual(tc, same.MinRadius_m,     bare.MinRadius_m,     'AbsTol', 1e-12);
verifyEqual(tc, same.RequiredWidth_m, bare.RequiredWidth_m, 'AbsTol', 1e-12);
end

function testSpeedLimitAgreesWithWhatIsWrittenHere(tc)
d     = sih.planner.defaults();
space = struct('VisibleRange', 40, 'Valid', true);

bare = sih.planner.speedLimit(space, 8, curvature_1pm = 0.05);
same = sih.planner.speedLimit(space, 8, curvature_1pm = 0.05, ...
          aLat_mps2         = d.speedALat_mps2, ...
          aBrake_mps2       = d.speedABrake_mps2, ...
          tReact_s          = d.speedTReact_s, ...
          vRoute_mps        = d.speedVRoute_mps, ...
          fallbackVisible_m = d.speedFallbackVisible_m);

verifyEqual(tc, same.v_max_mps, bare.v_max_mps, 'AbsTol', 1e-12);
verifyEqual(tc, same.Binding,   bare.Binding);
end

function testRoadBarrierAgreesWithWhatIsWrittenHere(tc)
d     = sih.planner.defaults();
space = struct('EdgeDistance', 1.2, 'EdgeSide', uint8(2), 'Valid', true);

bare = sih.planner.roadBarrier(space, 6);
same = sih.planner.roadBarrier(space, 6, ...
          egoWidth_m          = d.vehicleWidth_m, ...
          mirrorWidth_m       = d.vehicleMirrorWidth_m, ...
          egoLength_m         = d.vehicleLength_m, ...
          anchorLowSpeed_mps  = d.barrierAnchorLowSpeed_mps, ...
          anchorLowClear_m    = d.barrierAnchorLowClear_m, ...
          anchorHighSpeed_mps = d.barrierAnchorHighSpeed_mps, ...
          anchorHighClear_m   = d.barrierAnchorHighClear_m, ...
          dropFactor          = d.barrierDropFactor, ...
          fallbackCorridor_m  = d.barrierFallbackCorridor_m);

verifyEqual(tc, same.h_road, bare.h_road, 'AbsTol', 1e-12);
end

function testChooseVelocityAgreesWithWhatIsWrittenHere(tc)
d   = sih.planner.defaults();
vo  = struct('d',12,'beta',0.3,'lambda',0.5,'h',0.2,'colliding',true, ...
             'tcpa',1.5,'dcpa',2.0,'bearing',0.4);
ego = struct('Position',[0 0 0], 'Velocity',[6 0 0], 'Yaw',0);

bare = sih.planner.chooseVelocity(uint8(1), vo, ego);
same = sih.planner.chooseVelocity(uint8(1), vo, ego, ...
          giveWayAccel_mps2   = d.cmdGiveWayAccel_mps2, ...
          headOnAccel_mps2    = d.cmdHeadOnAccel_mps2, ...
          headOnSteer_rad     = d.cmdHeadOnSteer_rad, ...
          overtakeAccel_mps2  = d.cmdOvertakeAccel_mps2, ...
          emergencyAccel_mps2 = d.cmdEmergencyAccel_mps2, ...
          stoppedSpeed_mps    = d.cmdStoppedSpeed_mps, ...
          accelLimits         = d.limitAccel_mps2, ...
          steerLimits         = d.limitSteer_rad);

verifyEqual(tc, same.Accel,      bare.Accel,      'AbsTol', 1e-12);
verifyEqual(tc, same.SteerAngle, bare.SteerAngle, 'AbsTol', 1e-12);
end

function testPointOfNoReturnAgreesWithWhatIsWrittenHere(tc)
d    = sih.planner.defaults();
term = struct('Safe', true);

bare = sih.planner.pointOfNoReturn(30, 5, 8, term);
same = sih.planner.pointOfNoReturn(30, 5, 8, term, ...
          aBrake_mps2 = d.commitABrake_mps2, marginFactor = d.commitMarginFactor);

verifyEqual(tc, same.Distance_m, bare.Distance_m, 'AbsTol', 1e-12);
end

function testEscapeMemoryAgreesWithWhatIsWrittenHere(tc)
d     = sih.planner.defaults();
ego   = struct('Position',[0 0 0], 'Velocity',[3 0 0], 'Yaw',0);
space = struct('EdgeDistance', 6, 'EdgeSide', uint8(0), 'Valid', true);

bare = sih.planner.escapeMemory(struct(), ego, space);
same = sih.planner.escapeMemory(struct(), ego, space, ...
          minSpacing_m = d.escapeMinSpacing_m, maxPoints = d.escapeMaxPoints, ...
          roadWidth_m  = d.turnRoadWidth_m);

verifyEqual(tc, same.Recorded,     bare.Recorded);
verifyEqual(tc, same.LocalWidth_m, bare.LocalWidth_m, 'AbsTol', 1e-12);
end

% ---------------------------------------------------------------- one car, one brake

function testTheWholePlannerAgreesWhatCarThisIs(tc)
% followTrunk steers it, roadBarrier fits it through gaps, planTurn turns it,
% checkTrajectorySafety sweeps its body. Four files, one car.
d = sih.planner.defaults();
verifyEqual(tc, d.vehicleWheelbase_m, 2.8);
verifyEqual(tc, d.vehicleWidth_m,     1.8);
verifyEqual(tc, d.vehicleLength_m,    4.7);
end

function testTheCommitBrakeIsTheSameBrakeAsTheSpeedLaw(tc)
% pointOfNoReturn sizes the stop that decides commitment; speedLimit sizes the stop
% that decides speed. If they disagree the car is told it can stop in a distance the
% speed law does not believe.
d = sih.planner.defaults();
verifyEqual(tc, d.commitABrake_mps2, d.speedABrake_mps2);
end

function testTheEmergencyAccelIsTheContractFloorItself(tc)
d = sih.planner.defaults();
verifyEqual(tc, d.cmdEmergencyAccel_mps2, d.limitAccel_mps2(1));
end

% ---------------------------------------------------------------- shape

function testUnitsAreInTheNames(tc)
% A bare number in a config file is where a degree becomes a radian silently. Every
% numeric field must carry a unit suffix, or be one of the few genuinely unitless
% ones named here.
d        = sih.planner.defaults();
unitless = ["escapeMaxPoints" "barrierDropFactor" "commitMarginFactor" ...
            "contingencyTrunkMode" "Measured" "Contract" "Chosen"];
names    = setdiff(string(fieldnames(d)).', unitless, 'stable');

bad = names(~endsWith(names, ["_m" "_s" "_rad" "_mps" "_mps2" "_1pm" "_m2"]));
verifyEmpty(tc, bad, "field(s) with no unit in the name: " + strjoin(bad, ", "));
end

function testItWritesNothingAndAsksForNothing(tc)
% It is a table of numbers. If it ever grows an input or a side effect, it has
% started being a second source of truth instead of a readable copy of one.
verifyEqual(tc, nargin('sih.planner.defaults'), 0);
verifyTrue(tc, isstruct(sih.planner.defaults()));
end
