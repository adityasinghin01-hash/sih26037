function [cmd, st] = s2drivePlanner(st, ctx)
%S2DRIVEPLANNER  The real sih.planner in the S2 (the chowk) seat.
%
%   Thin wrapper over sc.planSeat - the S2 runner (s2_planner_run.m) builds every
%   scenario-specific field into ctx (the ego route round the gyratory, the world,
%   the world-frame TrackList, the tuning dials). sc.s2drive (the scripted
%   placeholder, which senses one number - ctx.YieldDrop) is NOT touched.
%
%   S2 is a tighter-curve scenario than S1, so watch generateCandidates /
%   frenet2global overshoot on the ring - the ELo/EHi clamp in sc.planSeat is
%   the guard, and the S2 runner should pass ELo/EHi sized to the ring corridor.
[cmd, st] = sc.planSeat(st, ctx);
end
