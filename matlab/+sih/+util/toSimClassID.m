function [simID, simName] = toSimClassID(classID)
%TOSIMCLASSID  Map our S5 ClassID onto the one drivingScenario understands.
%
%   AGENTS.md section 3, S5 names this function and says NEVER HARDCODE EITHER numbering.
%   This is that function.
%
%   THE COLLISION IS REAL AND IT IS DANGEROUS
%   drivingScenario reserves ClassID 0-6 for its own meanings, and they do not match ours:
%
%       sim: 0 unknown  1 Car  2 Truck  3 Bicycle  4 Pedestrian  5 Jersey Barrier  6 Guardrail
%       S5 : 0 unknown  1 car  2 truck  3 BUS      4 AUTO-RICKSHAW  5 MOTORBIKE  6 SCOOTER
%
%   So an auto-rickshaw written straight into a scenario becomes a PEDESTRIAN, and a motorbike
%   becomes a JERSEY BARRIER. Nothing errors. The sensors return the wrong mesh, the tracker
%   reports the wrong class, and the planner reads feature 12-27 as something it is not.
%   Verified against mathworks.com 1 Sep 2026.
%
%   THE MAP IS LOSSY - THIS MATTERS
%   Sixteen of ours fold into seven of theirs, so you CANNOT recover an S5 ClassID from a
%   scenario. Carry ours alongside, keyed by ActorID. Every scenario builder in
%   sih.scenario returns that map; use it rather than inverting this function.
%
%   [simID, simName] = sih.util.toSimClassID(10)     % cow -> 4, "Pedestrian"
%
%   INPUT
%     classID  numeric  one or more S5 ClassIDs, 0-15
%   OUTPUT
%     simID    uint8    the drivingScenario ClassID, same size as the input
%     simName  string   its name, for printing and for sanity-checking a scene
%
%   See also sih.util.classNames

arguments
    classID (1,:) {mustBeNumeric, mustBeNonnegative, mustBeInteger}
end

if any(classID > 15)
    error('sih:util:badClassID', ...
        ['ClassID %d is outside S5, which defines 0-15. If you need a new class it must be ' ...
         'APPENDED to S5 in AGENTS.md section 3, by a human, with everyone told.'], ...
        max(classID));
end

%              S5:  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
%                   |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
TABLE = uint8([     0, 1, 2, 2, 1, 3, 3, 1, 4, 3, 4, 4, 3, 1, 2, 5]);
%
%   Each choice, and why:
%     0  unknown        -> 0  unknown
%     1  car            -> 1  Car
%     2  truck          -> 2  Truck
%     3  bus            -> 2  Truck          nearest large vehicle; sim has no bus
%     4  auto-rickshaw  -> 1  Car            a small enclosed vehicle. NOT 4 - that is Pedestrian
%     5  motorbike      -> 3  Bicycle        a two-wheeler. NOT 5 - that is a Jersey Barrier
%     6  scooter        -> 3  Bicycle
%     7  van            -> 1  Car
%     8  pedestrian     -> 4  Pedestrian
%     9  bicycle        -> 3  Bicycle
%    10  cow            -> 4  Pedestrian     no animal class exists. Pedestrian is the closest
%                                            vulnerable non-vehicle mover, and it matches our
%                                            metric M4, which scores animals at the pedestrian
%                                            weight of 1.00. Supply a real cow MESH anyway -
%                                            this only sets the default when none is given
%    11  dog            -> 4  Pedestrian
%    12  pushcart       -> 3  Bicycle        human-powered and slow
%    13  animal cart    -> 1  Car            roughly a car's footprint
%    14  tractor        -> 2  Truck
%    15  static obstacle-> 5  Jersey Barrier

NAMES = ["Unknown", "Car", "Truck", "Bicycle", "Pedestrian", "Jersey Barrier", "Guardrail"];

simID = TABLE(classID + 1);
simName = NAMES(double(simID) + 1);
end
