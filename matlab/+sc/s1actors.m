function A = s1actors(W, beats, opts)
%S1ACTORS  The drivingScenario and every SCRIPTED actor in S1.
%
%   THE EGO IS NOT HERE. It is integrated by the caller against sc.s1drive, because
%   a planner has to be able to react and a baked trajectory cannot. Everything in this
%   file is scripted traffic - it does what it does whatever the ego decides.
%
%   THE COW IS A MathWorks PRIMITIVE, AND THAT IS THE POINT. Her whole behaviour -
%   amble out of the clearing, cross at the peer-reviewed gait speed, stop on the
%   centreline, never move again - is one smoothTrajectory call. Nothing about it is
%   hand-rolled motion, which is what makes it a claim rather than an animation.
%
%   MEASURED HERE, NOT ASSUMED (see REF-17 s10):
%     - `smoothTrajectory(cow,[verge; stop],[1.2 0])` DOES NOT WALK AT 1.2 m/s. It
%       decelerates across the WHOLE segment: mean 0.678 m/s, only 7 % of the walk
%       within 5 % of the gait speed, and it takes 6.92 s instead of 3.53 s. The feet
%       slide for 93 % of it. Phase 1 verified the END STATE and never the profile.
%     - The cure is a waypoint at which the speed is still 1.204, so the constant-speed
%       leg is explicit. The final deceleration cannot be shorter than about 1.8 m -
%       swept, and 1.50 m and below are rejected outright with "Unable to create
%       smooth trajectory".
%
%   A.Scenario  drivingScenario     A.Cow  A.Herd  A.Auto  A.Wrong  A.Over  A.Tractor

arguments
    W struct
    beats struct
    opts.SampleTime (1,1) double = 0.05
    opts.StopTime   (1,1) double = 70
end

P = W.Path;
S = drivingScenario('SampleTime', opts.SampleTime, 'StopTime', opts.StopTime);
A.Scenario = S;

[~, zd] = sc.meshes("zebu");
GAIT = 1.68 * 43/60;                 % REF-04 s2: stride x cadence = 1.2040 m/s
DECEL = 1.85;                        % the shortest final leg smoothTrajectory accepts
VERGE = 4.90;                        % S1: "1.4 m off the carriageway" -> 3.5 + 1.4
% THE GAP ARITHMETIC LIVES IN sc.s1geom AND IS NOT REPEATED HERE.
% It used to be a hardcoded 0.65 in one file and a derivation in another, and the two
% disagreed the moment she was moved. One source, read by everything.
G = sc.s1geom(W);
STOP_E = G.CowStopE;

assert(abs(GAIT - 1.2040) < 5e-4, "sc:gait", ...
    "stride x cadence is %.4f m/s, REF-04 says 1.2040", GAIT);

% ---------------------------------------------------------------- THE COW
% Her start point inside the clearing is SOLVED, not picked: she has to reach the
% carriageway edge at the written moment, so the amble length is bisected until she
% does. Same technique as the thicket radius - author the intent, solve the number.
lo = 6.0; hi = 60.0;
for it = 1:34
    e0 = (lo+hi)/2;
    tCross = cowCrossTime(P, e0, VERGE, GAIT, DECEL, STOP_E, opts.SampleTime);
    if isnan(tCross) || tCross < beats.tCowStep, lo = e0; else, hi = e0; end
end
A.CowStartE = (lo+hi)/2;
[A.Cow, A.CowTraj] = buildCow(S, P, W.CowStation, A.CowStartE, VERGE, GAIT, DECEL, STOP_E, zd);
A.CowCrossTime = cowCrossTime(P, A.CowStartE, VERGE, GAIT, DECEL, STOP_E, opts.SampleTime);

% ---------------------------------------------------------------- THE HERD
% Three more cattle standing in the clearing, so it reads as a herd crossing rather
% than one animal placed on a road. They never move; they are scenery with dimensions.
A.Herd = [];
herd = [W.CowStation-9, 15.5, -0.7;  W.CowStation+6, 21.0, 2.4;  W.CowStation+13, 13.0, 1.1];
for k = 1:size(herd,1)
    xy = P.at(herd(k,1), herd(k,2));
    a = actor(S, 'ClassID', 5, 'Length', zd(1), 'Width', zd(2), 'Height', zd(3));
    a.Position = [xy 0];
    a.Yaw = rad2deg(herd(k,3));
    A.Herd = [A.Herd a];                                                %#ok<AGROW>
end

% ---------------------------------------------------------------- ONCOMING TRAFFIC
% Each one is placed so that it is at a named station at a named TIME. Nothing is
% eyeballed: the start offset is speed x time, backwards from where it has to be.
[~, ad] = sc.meshes("auto");
A.Auto = oncoming(S, P, ad, -1.70, 30/3.6, W.CowStation, beats.tAutoPass, opts.StopTime, 6);

[~, md] = sc.meshes("motorcycle");
% THE WRONG-SIDE MOTORCYCLE - on OUR side of the road, then back across at the last
% moment. The single most Indian behaviour there is, and a genuine planning problem.
A.Wrong = wrongSide(S, P, md, beats.sWrongSide, beats.tWrongSide, 42/3.6, opts.StopTime);

% the overtaking motorcycle: passes us on the right at a 0.9 m lateral GAP, which is
% a 2.20 m centre separation once both half-widths are taken off. Derived, not typed.
[~, cd] = sc.meshes("car");
sep = cd(2)/2 + 0.90 + md(2)/2;
A.OvertakeE = 1.75 - sep;
A.Over = following(S, P, md, A.OvertakeE, 62/3.6, beats.sOvertake, beats.tOvertake, opts.StopTime);

% the tractor-trolley, oncoming, cane overhanging. Two actors, one behind the other.
[~, td] = sc.meshes("tractor");  [~, ld] = sc.meshes("trolley");
A.Tractor = oncoming(S, P, td, -1.95, 15/3.6, beats.sTractor, beats.tTractor, opts.StopTime, 5);
A.Trolley = oncoming(S, P, ld, -1.95, 15/3.6, beats.sTractor + (td(1)/2 + ld(1)/2 + 0.5), ...
                     beats.tTractor, opts.StopTime, 5);

% ---------------------------------------------------------------- what it all means
% zd(1), NOT zd(2). Broadside her lateral extent is her LENGTH. Using the width here
% would compute the gap for an animal standing in a pose she is no longer in - the
% exact class of error REF-17 s10c caught the first time round, in the other direction.
A.CowLateral = G.CowLateral;
A.PassE     = G.PassE;
A.FreeWidth = G.FreeWidth;
A.Geom      = G;
A.Margin = (A.FreeWidth - cd(2)) / 2;
A.CowStopE = STOP_E;  A.Gait = GAIT;  A.Names = ["cow" "auto" "wrong" "over" "tractor"];

fprintf(['[S1 actors] cow ambles from e=%+.1f m, crosses the edge at t=%.1f s ' ...
         '(written %.1f) | free %.2f m | margin %.3f m | pass at e=%+.3f m\n'], ...
        A.CowStartE, A.CowCrossTime, beats.tCowStep, A.FreeWidth, A.Margin, A.PassE);
end

% =======================================================================================
function [a, wp] = buildCow(S, P, sCow, e0, verge, gait, decel, stopE, zd)
%BUILDCOW  Amble out of the clearing, then cross at EXACTLY the gait speed, then stop.
wp = [P.at(sCow, e0)        0
      P.at(sCow, verge+2.0) 0
      P.at(sCow, verge)     0
      P.at(sCow, stopE+decel) 0
      P.at(sCow, stopE)     0];
sp = [0.50 0.50 gait gait 0];        % [.....amble.....][..gait..][stop]
a = actor(S, 'ClassID', 5, 'Length', zd(1), 'Width', zd(2), 'Height', zd(3));
smoothTrajectory(a, wp, sp);
end

function t = cowCrossTime(P, e0, verge, gait, decel, stopE, dt)
%COWCROSSTIME  When does she cross the carriageway edge? Run it and find out.
try
    S = drivingScenario('SampleTime', dt, 'StopTime', 120);
    [~, zd] = sc.meshes("zebu");
    a = buildCow(S, P, 300, e0, verge, gait, decel, stopE, zd);
    t = NaN;
    while advance(S)
        [~, e] = P.inverse(a.Position(1:2));
        if e <= 3.50, t = S.SimulationTime; return; end
    end
catch
    t = NaN;
end
end

% ---------------------------------------------------------------------------------------
function a = oncoming(S, P, dim, e, v, sAt, tAt, T, cls)
%ONCOMING  Travels against us, and is at station sAt at time tAt. Placed by arithmetic.
s0 = min(P.Len, sAt + v*tAt);
s1 = max(0,     sAt - v*(T - tAt));
a  = mkActor(S, dim, cls);
smoothTrajectory(a, sampleAlong(P, s0, s1, e), v*ones(1, numWp(s0, s1)));
end

function a = following(S, P, dim, e, v, sAt, tAt, T)
%FOLLOWING  Travels with us and overtakes; at station sAt at time tAt.
s0 = max(0,     sAt - v*tAt);
s1 = min(P.Len, sAt + v*(T - tAt));
a  = mkActor(S, dim, 3);
smoothTrajectory(a, sampleAlong(P, s0, s1, e), v*ones(1, numWp(s0, s1)));
end

function a = wrongSide(S, P, dim, sAt, tAt, v, T)
SWING = 14;                              % metres over which it returns to its own side
%WRONGSIDE  Oncoming ON OUR SIDE, drifting back across only at the last moment.
s0 = min(P.Len, sAt + v*tAt);
s1 = max(0,     sAt - v*(T - tAt));
ss = linspace(s0, s1, max(10, round(abs(s0-s1)/12)));
% IT SWINGS BACK RELATIVE TO THE MEETING POINT, not to a fraction of its own path.
% Keyed to the fraction it swung at frac > 0.86 of a 70 s trajectory - long after it
% had passed us - so at the meeting instant it was still at e = +2.20 and OVERLAPPED
% the ego by 0.65 m. A collision that no assertion was looking for.
d  = ss - sAt;                       % metres still to run before it reaches us
ee = 2.20 + (-1.80 - 2.20) * max(0, min(1, (SWING - d)/SWING));
wp = zeros(numel(ss),3);
for i = 1:numel(ss), wp(i,1:2) = P.at(ss(i), ee(i)); end
a = mkActor(S, dim, 3);
smoothTrajectory(a, wp, v*ones(1, numel(ss)));
end

function a = mkActor(S, dim, cls)
% TRAP: actor() REJECTS the vehicle class IDs. `actor(S,'ClassID',1,...)` warns
% "Class ID 1 is not supported for an actor" and quietly builds a vehicle instead.
% actor() takes 3 Bicycle, 4 Pedestrian, 5 Jersey Barrier, 6 Guardrail - and nothing
% else. Every wheeled thing here therefore goes through vehicle().
if cls >= 3 && cls <= 6
    a = actor(S, 'ClassID', cls, 'Length', dim(1), 'Width', dim(2), 'Height', dim(3));
else
    a = vehicle(S, 'ClassID', cls, 'Length', dim(1), 'Width', dim(2), 'Height', dim(3));
end
end

function n = numWp(s0, s1)
n = max(4, round(abs(s0-s1)/18));
end

function wp = sampleAlong(P, s0, s1, e)
%SAMPLEALONG  Waypoints down the REAL centreline at a fixed lateral offset, so a
%   vehicle going round the bend goes round it rather than cutting the chord.
ss = linspace(s0, s1, numWp(s0, s1));
wp = zeros(numel(ss), 3);
for i = 1:numel(ss), wp(i,1:2) = P.at(ss(i), e); end
end
