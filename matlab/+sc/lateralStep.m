function [e, ev] = lateralStep(e, ev, cmdE, v, DT, opts)
%LATERALSTEP  One step of ACCELERATION-LIMITED lateral motion toward a target
%   position - shared by sc.s1_action_run and sc.s2_action_run, replacing the
%   flat rate-limiter both used to have. The old model let a car's sideways
%   position start moving at its full rate the instant a new target appeared
%   and stop dead the instant it arrived - a velocity DISCONTINUITY at both
%   ends, which is what read as a robotic snap-into-a-slide rather than a car
%   steering. This eases in and eases out instead.
%
%   THE STEERING-IMPLIED RATE CAP IS UNCHANGED - a car cannot slide sideways,
%   so how fast it can change lateral position is still set by how fast it is
%   going: tand(CrabDeg)*v, the same physics the old model used. What is NEW
%   is that the lateral VELOCITY itself is now acceleration-limited toward
%   that cap using v^2 = 2*a*d, the same idiom sc.s1drive/sc.s2drive already
%   use for braking to a stop - so the target speed itself tapers as the
%   remaining distance shrinks (ease-out), and ramping ev toward that target
%   at a bounded rate (rather than snapping to it) gives the ease-IN, which
%   sqrt(2*a*d) alone does not: for any distance more than a few cm it is
%   already saturated at the rate cap, so without also rate-limiting ev the
%   manoeuvre would still start at full speed.
%
%   opts.AccelLat, 0.35 m/s^2, is a CHOICE, not a measurement, the same status
%   as this project's other lateral constants (rLat=0.75, CrabDeg=12) - picked
%   to visibly smooth the motion without materially lengthening either film's
%   pacing (measured: about 20% longer for S1's 3.33 m pass manoeuvre, ~1.4 s
%   on a 62 s film). Render and look before trusting the number further - REF-
%   17's own rule, restated here because this is the first project file to
%   change WHICH PHYSICS MODEL a written distance depends on, not just a
%   colour or a shape.

arguments
    e    (1,1) double
    ev   (1,1) double
    cmdE (1,1) double
    v    (1,1) double
    DT   (1,1) double
    opts.RateCap  (1,1) double = 0.75
    opts.CrabDeg  (1,1) double = 12
    opts.AccelLat (1,1) double = 0.35
end

de = cmdE - e;
vMax = min(opts.RateCap, tand(opts.CrabDeg) * v);
evTarget = sign(de) * min(vMax, sqrt(2*opts.AccelLat*abs(de)));
ev = ev + max(-opts.AccelLat*DT, min(opts.AccelLat*DT, evTarget - ev));
e  = e + ev*DT;

% SNAP ONLY WHEN ONE STEP CAN ACTUALLY CLOSE THE GAP, not before. Without this
% the S-curve's own tail asymptotes toward cmdE and mathematically never quite
% arrives, which would leave every "PASS/COMMIT holds at e=+X.XXX" claim
% elsewhere in this project forever a few mm short of its written target.
if abs(cmdE - e) < max(abs(ev)*DT, 1e-3)
    e = cmdE; ev = 0;
end
end
