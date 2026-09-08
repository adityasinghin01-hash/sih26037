function A = s2actors(W, beats, opts)
%S2ACTORS  The drivingScenario and every scripted actor in S2 - THE CHOWK.
%
%   THE DIFFERENCE FROM S1, AND IT IS THE RESULT. S1's cow never reacts: that is the
%   frozen-robot problem. Here the circulating auto DOES react - the written script says
%   its "speed drops 1.8 km/h" and that lift-off IS the yield the ego reads. So S2 tests
%   negotiation with an agent that negotiates back, which S1 cannot.
%
%   The yield is built with smoothTrajectory, not hand-rolled: a waypoint on the ring
%   where the speed steps down. It is then MEASURED back off the recorded poses, so the
%   number the driver reads is the number the actor actually did.

arguments
    W struct
    beats struct
    opts.SampleTime (1,1) double = 0.05
    opts.StopTime   (1,1) double = 56
end

S = drivingScenario('SampleTime', opts.SampleTime, 'StopTime', opts.StopTime);
A.Scenario = S;
C = W.Centre;  Rmid = (W.Rin + W.Rout)/2;

[~, autoD]  = sc.meshes("auto");
[~, motoD]  = sc.meshes("motorcycle");
[~, busD]   = sc.meshes("bus");
[~, aceD]   = sc.meshes("tataace");
[~, zebuD]  = sc.meshes("zebu");

% ---------------------------------------------------------------- the circulating auto
% EVERY CIRCULATING ACTOR IS PLACED BY WHEN IT PASSES THE EGO'S ENTRY, NOT BY A START
% ANGLE. Hand-picking angles put the auto's lift-off BEFORE the ego ever reached the
% give-way line - so the driver read a yield it had not asked for and the PROBE state
% never executed at all - and it put the bus exactly where the ego committed, a 1.76 m
% overlap. Both were found by the beat table and the separation assert, not by eye.
A.YieldDrop_kmh = 1.8;                       % S2 t=8.3, the written number
vHi = 24/3.6;  vLo = vHi - A.YieldDrop_kmh/3.6;
aEntry = atan2d(W.Arm(W.EntryArm).Dir(2), W.Arm(W.EntryArm).Dir(1));

% the auto: it must still be SHORT of our entry while we probe, and lift off there.
[wp, sp, kRamp] = ringPath(C, Rmid, aEntry, beats.tAutoLift, vHi, 300, 56);
sp(kRamp:kRamp+5) = linspace(vHi, vLo, 6);   % a ramp, not a step - see the Jerk note
sp(kRamp+6:end)   = vLo;                     % held: it does not speed back up
A.Auto = vehicle(S, 'ClassID', 1, 'Length', autoD(1), 'Width', autoD(2), 'Height', autoD(3));
% JERK HAD TO BE RAISED, AND THE NUMBER WAS SWEPT, NOT GUESSED. At default jerk
% smoothTrajectory rejects ANY speed change on a densely sampled arc: a flat speed
% always builds; a ramp fails at 46 and 20 waypoints and only builds at 12, where the
% chord error is 0.31 m on a 16 m radius and the ring visibly becomes a polygon.
% Sweeping jerk at full resolution: 3 and 4 fail, 5 is the threshold, and 5 holds the
% chord error at 0.019 m. A throttle lift-off is a brisk event, so 5 m/s^3 is honest.
smoothTrajectory(A.Auto, wp, sp, 'Jerk', 5);
A.AutoVHi = vHi;  A.AutoVLo = vLo;

% ---------------------------------------------------------------- the wrong-way rider
% S2 t=14.6: "A motorcycle comes the wrong way round the island, head on, at 18 km/h."
% It circulates in the OPPOSITE sense to everything else, which is the whole point.
vW = 18/3.6;
thW = aEntry - beats.tWrongMeet*vW/Rmid*180/pi + linspace(0, 210, 34);
wpW = C + (Rmid + 1.3)*[cosd(thW)', sind(thW)'];  wpW(:,3) = 0;
% TRAP, CAUGHT BY THE PHASE 8 HONESTY PASS - s1actors.m's mkActor already knows
% vehicle() REJECTS ClassID 3 ("Class ID 3 is not supported for a vehicle") and
% silently falls back to a generic actor; this file called vehicle() directly for
% the wrong-way rider and had been doing so, warning on every run, since 5 Sep -
% never loud enough to notice until this run's console output was read in full.
% actor() is what ClassID 3 (Bicycle - the class used for every two-wheeler here,
% S1 and S2 both) actually needs.
A.Wrong = actor(S, 'ClassID', 3, 'Length', motoD(1), 'Width', motoD(2), 'Height', motoD(3));
smoothTrajectory(A.Wrong, wpW, vW*ones(1, size(wpW,1)));

% ---------------------------------------------------------------- the bus
% S2 t=5.2: "A motorcycle, then an auto, then a bus, all circulating" while nobody
% yields. So the bus passes our entry EARLY, before the auto's lift-off - it is part of
% the reason we are still waiting, not an obstacle to drive into.
% AND IT MUST LEAVE THE GYRATORY, NOT STOP ON IT. A drivingScenario actor HOLDS its
% final pose when its trajectory ends - verified in Phase 3 - so a bus given only a ring
% arc finished circulating and then PARKED on the circulating carriageway, exactly where
% the ego later drove. The separation assert caught it as a 3.33 m overlap. Its path
% therefore continues out along the exit arm and off the scene, which is what a bus does.
vB = 20/3.6;
[wpB, spB] = ringPath(C, W.Rout - 2.2, aEntry, beats.tBusPass, vB, 165, 30);
outA = W.Arm(W.ExitArm).Path;
tail = zeros(10,3);
for q = 1:10
    tail(q,1:2) = outA.at((q-1)/9 * outA.Len, -1.75);   % away down arm A, left-hand rule
end
wpB = [wpB; tail];
spB = [spB, vB*ones(1,10)];
A.Bus = vehicle(S, 'ClassID', 2, 'Length', busD(1), 'Width', busD(2), 'Height', busD(3));
smoothTrajectory(A.Bus, wpB, spB, 'Jerk', 5);

% ---------------------------------------------------------------- static actors
% S2: "2 cows lying on the traffic island itself, chewing, completely unbothered - this
% is the single most Indian detail available and it costs nothing." They are ON the
% island, so they are NOT an obstacle - and that is the contrast with S1 that makes the
% point: the same animal, off the carriageway, changes nothing.
A.Cows = [];
for k = 1:2
    a = 2.1 + (k-1)*0.9;
    r = W.Rin - 3.4 - (k-1)*1.1;
    p = C + r*[cos(a) sin(a)];
    c = actor(S, 'ClassID', 5, 'Length', zebuD(1), 'Width', zebuD(2), 'Height', zebuD(3));
    c.Position = [p, 0.15];                  % standing on the raised island
    c.Yaw = rad2deg(a) + 118;
    A.Cows = [A.Cows c];                                                    %#ok<AGROW>
end

% the parked Tata Ace on the exit arm - S2 t=37.5: "narrows the lane to 2.9 m"
% "A parked Tata Ace narrows the lane to 2.9 m." READ THE SENTENCE PROPERLY: parked
% fully on the tarmac it leaves 5.25 m of a 7.0 m carriageway, which is not 2.9 and
% cannot be. The written number is about ONE DIRECTION'S 3.5 m lane, and it needs the
% Ace to intrude 0.60 m into it - straddling the edge with 0.90 m of its 1.5 m width
% still on the verge, which is exactly how an Ace parks on an Indian road.
Pa = W.Arm(W.ExitArm).Path;
ACE_INTRUDE = 0.60;
pAce = Pa.at(beats.aceStation, -(W.ArmW/2 - ACE_INTRUDE + aceD(2)/2));
A.Ace = vehicle(S, 'ClassID', 2, 'Length', aceD(1), 'Width', aceD(2), 'Height', aceD(3));
A.Ace.Position = [pAce, 0];
[~, hA] = Pa.at(beats.aceStation, 0);
A.Ace.Yaw = rad2deg(hA);
A.AceGap = W.ArmW/2 - ACE_INTRUDE;           % what is left of the 3.5 m lane beside it

A.Names = ["auto" "wrong" "bus" "cow" "ace"];
fprintf(['[S2 actors] auto %.1f -> %.1f km/h (drop %.1f) | wrong-way rider 18 km/h | ' ...
         'bus passes our entry at t=%.1f s | 2 cows ON the island | Ace leaves %.2f m\n'], ...
        3.6*A.AutoVHi, 3.6*A.AutoVLo, A.YieldDrop_kmh, beats.tBusPass, A.AceGap);
end

% =======================================================================================
function [wp, sp, kAt] = ringPath(C, R, aAt, tAt, v, arcDeg, npts)
%RINGPATH  A circulating arc that passes bearing aAt at time tAt, travelling at v.
%   Solved, not tuned: the lead is simply v*tAt of arc placed BEFORE that bearing, so
%   the actor is wherever it has to be to arrive on the written beat.
arcLen  = deg2rad(arcDeg)*R;
leadDeg = rad2deg(v*tAt / R);
th = (aAt + leadDeg) - linspace(0, arcDeg, npts);
wp = C + R*[cosd(th)', sind(th)'];  wp(:,3) = 0;
sp = v*ones(1, npts);
kAt = max(2, min(npts-7, round(leadDeg/arcDeg*(npts-1)) + 1));
end
