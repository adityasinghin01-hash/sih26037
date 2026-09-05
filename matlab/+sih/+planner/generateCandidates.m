function [candidates, info] = generateCandidates(egoState, refPath, opts)
%GENERATECANDIDATES  Ego state plus a reference path in, a fan of paths out.
%
%   Task D6, piece 2 of 5. Not one plan - several, so that piece 4 has something
%   to choose a committable trunk from. A planner that generates one trajectory
%   has already decided, and has nothing left to fall back on.
%
%   WHY A FAN OF SIDEWAYS OFFSETS AND SPEEDS
%   The two things a car can do at a junction are go around and slow down, so the
%   fan is the cross product of those: every sideways offset at every terminal
%   speed. Terminal speed 0 is the abort candidate and is always worth having.
%   D-planner.md D6: "when forward is blocked, bias generation toward LATERAL
%   candidates instead of giving up." That bias is expressed by the caller
%   widening opts.lateralOffsets_m, not by a special mode in here.
%
%   SIGN CONVENTION
%   Positive lateral offset is LEFT of the reference path, matching the frame
%   (x forward, y left) and matching positive SteerAngle in chooseVelocity.
%   Verified by running: offsets -3 / 0 / +3 on a path curving to +y produced
%   endpoints at y = 0.08 / 2.96 / 5.84 (4 Sep 2026).
%
%   INPUTS
%     egoState (1,1) struct  .Position (1x3, m), .Velocity (1x3, m/s), .Yaw (rad)
%     refPath  (1,1) referencePathFrenet  the route centreline (S10)
%     opts.lateralOffsets_m    sideways offsets, + is LEFT,
%                              default [-3 -1.5 0 1.5 3]
%     opts.terminalSpeeds_mps  speed to arrive at. 0 is the abort candidate,
%                              default [0 2 5 8]
%     opts.horizon_s           how far ahead to plan,        default 4.0
%     opts.timeResolution_s    step,                         default 0.1
%     opts.egoCurvature_1pm    ego path curvature,           default 0
%     opts.egoAccel_mps2       ego longitudinal accel,       default 0
%
%   OUTPUT
%     candidates  Mx1 struct array, one per surviving offset/speed pair
%       .LateralOffset_m     double, + is left
%       .TerminalSpeed_mps   double
%       .Horizon_s           double
%       .Times               Nx1 double, s, starting at 0
%       .Frenet              Nx6 double, [S dS ddS L dL ddL]
%       .Global              Nx6 double, [x y theta kappa speed accel]
%       .States              Nx3 double, [x y theta] - what the capsule
%                            collision checker in piece 3 wants
%     info  struct
%       .NumRequested  how many offset/speed pairs were asked for
%       .NumDropped    how many came back with non-finite values and were binned
%       .InitFrenet    1x6, where the ego is on the path right now
%
%   WHAT THIS DOES NOT DO, DELIBERATELY
%   No collision checking - that is piece 3. No ranking or choosing - that is
%   piece 4. No dynamic feasibility filter beyond dropping non-finite results:
%   grip and comfort limits belong with the speed limit in D8, and duplicating
%   them here would let the two copies drift apart.
%
%   TODO(performance): the trajectory generator is rebuilt on every call. At 10 Hz
%   that is wasteful. Not optimised until something measures it as a problem.
%
%   TODO(unverified): global2frenet needs a 6-column global state
%   [x y theta kappa speed accel]. Curvature and acceleration are not in
%   egoState, so they default to 0. If Person B can supply the real ones from the
%   vehicle model, pass them through opts and this gets more accurate.
%
%   See also SIH.PLANNER.PREDICTAGENTFUTURES, REFERENCEPATHFRENET,
%            TRAJECTORYGENERATORFRENET

arguments
    egoState (1,1) struct
    refPath  (1,1) referencePathFrenet
    opts.lateralOffsets_m   (1,:) double {mustBeFinite} = [-3 -1.5 0 1.5 3]
    opts.terminalSpeeds_mps (1,:) double {mustBeNonnegative} = [0 2 5 8]
    opts.horizon_s          (1,1) double {mustBePositive} = 4.0
    opts.timeResolution_s   (1,1) double {mustBePositive} = 0.1
    opts.egoCurvature_1pm   (1,1) double {mustBeFinite} = 0
    opts.egoAccel_mps2      (1,1) double {mustBeFinite} = 0
end

iRequireFields(egoState, {'Position','Velocity','Yaw'}, 'egoState');

speed = norm(egoState.Velocity(1:2));

% global2frenet wants [x y theta kappa speed accel]. Checked by running, 4 Sep 2026:
% a 3-column input errors with "Expected globalPoint to be of size Mx6".
globalState = [egoState.Position(1), egoState.Position(2), egoState.Yaw, ...
               opts.egoCurvature_1pm, speed, opts.egoAccel_mps2];

initFrenet = global2frenet(refPath, globalState);

% Every offset at every terminal speed. NaN in the S slot means "as far as you
% get in horizon_s", which is what makes this a time-bounded plan and not a
% distance-bounded one.
[offGrid, spdGrid] = meshgrid(opts.lateralOffsets_m, opts.terminalSpeeds_mps);
offsets = offGrid(:);
speeds  = spdGrid(:);
nWanted = numel(offsets);

termStates = [nan(nWanted,1), speeds, zeros(nWanted,1), ...
              offsets,        zeros(nWanted,1), zeros(nWanted,1)];

connector = trajectoryGeneratorFrenet(refPath, 'TimeResolution', opts.timeResolution_s);
[frenetTraj, globalTraj] = connect(connector, initFrenet, termStates, opts.horizon_s);

proto = struct('LateralOffset_m',0,'TerminalSpeed_mps',0,'Horizon_s',0, ...
               'Times',[],'Frenet',[],'Global',[],'States',[]);
candidates = repmat(proto, nWanted, 1);

keep = false(nWanted,1);
for k = 1:nWanted
    g = globalTraj(k).Trajectory;
    f = frenetTraj(k).Trajectory;
    if isempty(g) || ~all(isfinite(g(:))) || ~all(isfinite(f(:)))
        continue                    % the generator could not join those two states
    end
    n = size(g,1);
    candidates(k).LateralOffset_m   = offsets(k);
    candidates(k).TerminalSpeed_mps = speeds(k);
    candidates(k).Horizon_s         = opts.horizon_s;
    candidates(k).Times             = (0:n-1)' * opts.timeResolution_s;
    candidates(k).Frenet            = f;
    candidates(k).Global            = g;
    candidates(k).States            = g(:,1:3);
    keep(k) = true;
end

candidates = candidates(keep);

info = struct('NumRequested', nWanted, ...
              'NumDropped',   nWanted - numel(candidates), ...
              'InitFrenet',   initFrenet);
end

% ------------------------------------------------------------------ helpers

function iRequireFields(s, names, argName)
missing = names(~isfield(s, names));
if ~isempty(missing)
    error('sih:planner:generateCandidates:missingField', ...
          '%s is missing required field(s): %s', argName, strjoin(missing, ', '));
end
end
