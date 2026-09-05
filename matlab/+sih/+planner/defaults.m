function d = defaults()
%DEFAULTS  Every planner design number in one struct, readable from outside.
%
%   Aditya's ruling of 5 September 2026. AGENTS.md section 3's rule is that a number
%   without its config is not a result, and sih.runExperiment writes a config.json on
%   every run - but that file captures the SCENARIO only: stop time, sample time,
%   traffic rate, turn ratio, car-following model, MATLAB version, git commit,
%   plannerInLoop. Not one planner design number is in it, so not one of these numbers
%   is reproducible from a run directory today.
%
%   This function is the planner half of the fix, and it is the half that is Person
%   A's. sih.runExperiment calls it and writes the struct into config.json under a
%   "planner" key; that is Aditya's, and it lands at integration, not now. Nothing
%   here writes a file.
%
%   IT IS NOT A SECOND SOURCE OF TRUTH, AND MUST NOT BECOME ONE
%   Every value below is the default already written in a function's own arguments
%   block. This makes them READABLE without calling fifteen functions; it does not
%   make them authoritative. If the two ever disagree, THE FUNCTION IS RIGHT and this
%   file is stale. testDefaults.m pins the ones that matter by calling each function
%   with no options and again with these values, and failing if the results differ.
%
%   Nothing in the planner calls this. Passing d.turnUturnAngle_rad back into
%   sih.planner.planTurn is legal and is what the tests do, but the functions'
%   own defaults are what runs, so wiring this in would create the second source of
%   truth it exists to avoid.
%
%   THE THREE KINDS OF NUMBER, AND WHY THEY ARE LISTED SEPARATELY
%   Aditya's standing rule is that a chosen number must never be described as
%   measured. So they are not mixed:
%
%     .Measured  came from the world and can be cited. Only ONE qualifies today.
%     .Contract  fixed by AGENTS.md section 3 S4. Not ours to choose.
%     .Chosen    a design choice, traceable to a planning document, MEASURED BY
%                NOBODY. Everything else, and by far the longest list.
%
%   Every field name appears in exactly one of the three, and testDefaults.m fails if
%   a number is ever added without being classified. That is deliberate: the easy
%   mistake is to add a number and quietly leave it unlabelled, which is how a chosen
%   figure ends up in a report reading as a measurement.
%
%   UNITS ARE IN THE FIELD NAMES because a bare number in a config file is where a
%   degree becomes a radian silently.
%
%   Tested against hand-constructed S9/S10; not yet validated against World data.
%
%   OUTPUT  d, a struct of every design number, plus .Measured, .Contract and .Chosen
%           listing which field is which kind.
%
%   See also SIH.PLANNER.PLANTURN, SIH.PLANNER.SPEEDLIMIT, SIH.PLANNER.ROADBARRIER

% ---- the car -----------------------------------------------------------------------
% One car. followTrunk steers it, roadBarrier fits it through gaps and planTurn turns
% it, so these must never differ between the three.
d.vehicleWheelbase_m   = 2.8;
d.vehicleWidth_m       = 1.8;
d.vehicleLength_m      = 4.7;
d.vehicleMirrorWidth_m = 0.20;
d.vehicleMaxSteer_rad  = 0.6;

% ---- limits fixed by the contract ---------------------------------------------------
d.limitAccel_mps2 = [-6 3];
d.limitSteer_rad  = [-0.6 0.6];

% ---- roles, D2 ----------------------------------------------------------------------
d.roleDMin_m            = 2.5;
d.roleMaxRange_m        = 50;
d.cmdGiveWayAccel_mps2  = -2.5;
d.cmdHeadOnAccel_mps2   = -1.5;
d.cmdHeadOnSteer_rad    =  0.15;    % POSITIVE IS LEFT - RRR 1989 reg. 2, keep left
d.cmdOvertakeAccel_mps2 = -1.0;
d.cmdEmergencyAccel_mps2 = -6.0;    % the S4 floor itself
d.cmdStoppedSpeed_mps   = 0.1;

% ---- the road barrier, D8 -----------------------------------------------------------
d.barrierAnchorLowSpeed_mps  = 2/3.6;
d.barrierAnchorLowClear_m    = 0.10;
d.barrierAnchorHighSpeed_mps = 40/3.6;
d.barrierAnchorHighClear_m   = 1.50;
d.barrierDropFactor          = 2.0;
d.barrierFallbackCorridor_m  = 1.50;

% ---- the speed law, D7/D8 -----------------------------------------------------------
d.speedALat_mps2        = 3.0;
d.speedABrake_mps2      = 4.0;
d.speedTReact_s         = 0.5;
d.speedVRoute_mps       = 50/3.6;
d.speedFallbackVisible_m = 10.0;

% ---- turning, D10 -------------------------------------------------------------------
d.turnRoadWidth_m     = 7.0;        % MEASURED - see .Measured below
d.turnCutMinAngle_rad = 0.35;
d.turnUturnAngle_rad  = 2.36;
d.turnStreamWidth_m   = 3.5;
d.turnRefugeMargin_m  = 1.0;

% ---- reversibility, D9 --------------------------------------------------------------
d.escapeMinSpacing_m  = 5.0;
d.escapeMaxPoints     = 200;
d.commitABrake_mps2   = 4.0;        % must match speedABrake_mps2 - one braking model
d.commitMarginFactor  = 1.0;

% ---- the contingency planner, D6 ----------------------------------------------------
d.contingencyHorizon_s          = 4.0;
d.contingencyTimeResolution_s   = 0.1;
d.contingencyLateralOffsets_m   = [-3 -1.5 0 1.5 3];
d.contingencyTerminalSpeeds_mps = [0 2 5 8];
d.contingencyYieldDecel_mps2    = -2.0;
d.contingencyAssertAccel_mps2   =  0.0;
d.contingencyAssertMaxSpeed_mps = 25.0;
d.contingencyMovingSpeed_mps    = 0.1;
d.contingencyMinTrunkTime_s     = 0.5;
d.contingencyTrunkMode          = "B";   % ruled, plan/D6-TRUNK-RULING.md
d.trunkLookaheadTime_s          = 0.6;
d.trunkMinLookahead_m           = 2.0;
d.trunkSettleTime_s             = 0.5;
d.trunkBlockedDecel_mps2        = -2.5;

% ---- which kind is each -------------------------------------------------------------

% MEASURED. Exactly one, and it can be cited: world/scenarios/S0-THE-WORLD.md
% section 4's carriageway table gives tertiary = 7.0 m. Never call anything else
% measured without a citation of that shape.
d.Measured = "turnRoadWidth_m";

% CONTRACT. AGENTS.md section 3 S4 fixes these. Not ours to choose, and changing one
% is a contract change that costs six people.
d.Contract = ["limitAccel_mps2", "limitSteer_rad", "cmdEmergencyAccel_mps2", ...
              "vehicleMaxSteer_rad"];

% CHOSEN. Traceable to a planning document, measured by nobody. Everything else.
d.Chosen = setdiff(string(fieldnames(d)).', ...
                   [d.Measured, d.Contract, "Measured", "Contract", "Chosen"], ...
                   'stable');
end
