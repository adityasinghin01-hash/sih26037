function s10 = s10Route(W, P, s, e, egoYaw, opts)
%S10ROUTE  A real AGENTS.md section 3 S10 Route struct. Phase 7.
%
%   GoalHeading/GoalPoint are a COARSE, route-scale goal - deliberately NOT
%   the same lookahead followTrunk already steers with (0.6-0.7 s, a few
%   metres). sih.planner.planTurn derives turn TYPE from the heading change
%   between here and the goal, and a turn is a tens-of-metres-scale feature
%   (S2's arm-to-ring transition is the concrete example this project has -
%   the entry arm points radially at the gyratory centre, the ring is
%   tangent, so the two meet at a genuine ~80 deg corner "by construction",
%   already found and partly fixed for rendering in sc.roundRouteCorners).
%   opts.LookAhead_m is chosen at roughly half the IRC weaving-length minimum
%   the S2 spec itself states (30 m) - a real, disclosed, turn-detection
%   scale, not an arbitrary number.
%
%   BlockedEdges stays honestly EMPTY. Neither S1 nor S2 currently scripts an
%   impassable edge - reporting one would be inventing a scenario that is not
%   there. EscapePoints is likewise NOT filled in here: sih.planner.escapeMemory
%   already IS the mechanism that fills it, as a running memory built up over
%   the drive (see sc.planSeat, which now threads its state through
%   st.EscMem) - a static route function cannot know in advance where the
%   ego will have been.
%
%   INPUTS
%     W       the world struct
%     P       the route (sc.path-style .at(s,e) -> [xy, heading])
%     s, e    ego's current station/lateral offset
%     egoYaw  ego's current heading, rad, world frame
%   opts.LookAhead_m  (1,1) double, default 15 (see header)
%
%   OUTPUT  s10 struct, AGENTS.md S10 shape (plus .Valid, which planTurn
%           tolerates "when present" but AGENTS.md does not require):
%     .GoalHeading   double, rad, WORLD frame - the route's own heading
%                    LookAhead_m ahead, along its centreline
%     .GoalPoint     1x2, m, EGO FRAME - the same lookahead point, rotated
%                    into the ego's own forward/left axes
%     .BlockedEdges  uint32([]), always - see header
%     .EscapePoints  zeros(0,3), always - see header
%     .Valid         true - both worlds are fully known, nothing here is
%                    uncertain

arguments
    W struct
    P
    s (1,1) double
    e (1,1) double
    egoYaw (1,1) double
    opts.LookAhead_m (1,1) double = 15
end

lookS = min(s + opts.LookAhead_m, P.Len);
[goalXY, goalHdg] = P.at(lookS, 0);
[egoXY, ~] = P.at(s, e);

rel = goalXY - egoXY;
fwd = [cos(egoYaw) sin(egoYaw)];
lft = [-sin(egoYaw) cos(egoYaw)];
goalPointEgoFrame = [rel*fwd.', rel*lft.'];

s10 = struct( ...
    'GoalHeading',  goalHdg, ...
    'GoalPoint',    goalPointEgoFrame, ...
    'BlockedEdges', uint32([]), ...
    'EscapePoints', zeros(0,3), ...
    'Valid',        true);
end
