function [cmd, st] = s1drivePlanner(st, ctx)
%S1DRIVEPLANNER  The real sih.planner in the S1 (cattle-crossing) seat.
%
%   Thin wrapper over sc.planSeat - the S1 runner (s1_planner_run.m) builds every
%   scenario-specific field into ctx. sc.s1drive (the scripted placeholder) is
%   NOT touched and remains what ships; this is the honest side view of the real
%   planner (see sih26037-s1-planner-fork: option B, 6 Sep 2026).
[cmd, st] = sc.planSeat(st, ctx);
end
