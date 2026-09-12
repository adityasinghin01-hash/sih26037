function out = runScenario(name, opts)
%RUNSCENARIO  Drive one scenario with the REAL planner in the loop.
%
%   The ego is genuinely planned. Every step calls, unmodified, from ~/dev/sih2026:
%       sih.planner.velocityObstacle   collision-cone geometry, per track
%       sih.planner.assignRoles        COLREGs role from geometry alone
%       sih.planner.chooseVelocity     role -> EgoCommand
%   Nothing about the ego's speed is scripted. The other actors are described in
%   backup.scenarioSpec and their honesty label is in S.Notes.
%
%   FRAME - THE ONE WAY TO GET THIS WRONG (assignRoles header)
%   Tracks and the ego pose are both in the SCENARIO (world) frame here, so the real
%   ego pose is passed. Mixing an ego-frame TrackList with a world ego pose never
%   errors and makes every role silently wrong.
%
%   THE EGO IS NEVER IN ITS OWN TRACKLIST. That defect pinned h at -pi/2 on every step
%   of every run (HANDOFF.md, Stream D). It is asserted below, not assumed.
%
%   LATERAL CONTROL IS A DOCUMENTED STAND-IN FOR D6, WHICH IS NOT BUILT
%   chooseVelocity deliberately does no lateral avoidance - going around is a candidate
%   path and belongs to the contingency planner. This backup needs the cow squeeze, so
%   backup.lateralPolicy supplies it: it MEASURES the free width either side of a
%   blocker and offsets into the wider one if the ego fits. It is not D6 and does not
%   claim to be; it is a measured gap check with a written margin.
%
%   OPTIONS
%     .Planner    "negotiating" (default) | "defensive"  - the frozen-robot stand-in
%     .Verbose    print a running trace, default true
%
%   OUTPUT out struct  .T .EgoX .EgoY .EgoYaw .EgoV .Accel .Mode .Reason .MinH
%                      .Actors  .Events  .Metrics  .Spec  .Route

arguments
    name (1,1) string {mustBeMember(name,["S1","S2"])}
    opts.Planner (1,1) string {mustBeMember(opts.Planner,["negotiating","defensive"])} = "negotiating"
    opts.Verbose (1,1) logical = true
end

backup.addSihPath();

[sc, route, ~, S] = backup.buildScenario(name);        %#ok<ASGLU>
dt   = sc.SampleTime;
N    = round(S.Duration/dt);
W    = S.CarriagewayWidth;
LANE = W/4;                       % India drives LEFT: our lane centre is +W/4 (positive = left)

EGO_LEN = 3.99; EGO_WID = 1.70; EGO_MIRRORS = 1.90;   % Indian hatchback; mirrors add 20 cm
% dMin is "the sum of radii + margin" (velocityObstacle's own docstring), NOT a fixed
% 2.5 m. It is sized here so the WRITTEN S1 pass is not itself flagged as a violation:
% ego half-width 0.95 m + cow half-width 0.43 m + the written 0.95 m gap = 2.33 m centre
% to centre. A dMin of 2.5 would make the manoeuvre the script specifies impossible.
DMIN    = 2.00;
VMAX    = S.EgoSpeed0;

% station/lateral state
s  = 0;  v = S.EgoSpeed0;  e = LANE;
sLen = pathLength(route);

% logs
T=nan(N,1); EX=T; EY=T; EYaw=T; EV=T; EA=T; EMode=T; EMinH=T; ELat=T;
EReason = strings(N,1);
actorLog = struct('Name',{},'ClassID',{},'T',{},'X',{},'Y',{},'Yaw',{});
for k=1:numel(S.Actors)
    actorLog(k) = struct('Name',S.Actors(k).Name,'ClassID',S.Actors(k).ClassID, ...
                         'T',nan(N,1),'X',nan(N,1),'Y',nan(N,1),'Yaw',nan(N,1));
end
events = strings(0,1);
committed = false;  probeStarted = false;  minClearance = inf;

for i = 1:N
    t = (i-1)*dt;

    % ---------------- ego pose from station + lateral offset ----------------
    [p0, tang] = atStation(route, s);
    nrm  = [-tang(2), tang(1)];              % left normal
    egoP = p0 + e*nrm;
    egoYaw = atan2(tang(2), tang(1));
    egoV = v*[cos(egoYaw), sin(egoYaw)];

    % ---------------- the other actors at this instant ----------------
    A = backup.actorPoses(S, route, t, struct('EgoStation',s,'Committed',committed));

    % ---------------- S1 TrackList, world frame, EGO EXCLUDED ----------------
    tracks = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
                    'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});
    for k = 1:numel(A)
        if ~A(k).Active, continue; end
        tracks(end+1) = struct( ...
            'TrackID',uint32(k), 'ClassID',S.Actors(k).ClassID, ...
            'Position',[A(k).P, 0], 'Velocity',[A(k).V, 0], ...
            'Extent',S.Actors(k).Extent, 'Yaw',A(k).Yaw, ...
            'Existence',1.0, 'Age',uint32(i), 'SensorMask',uint8(3)); %#ok<AGROW>
    end
    % the ego is never a track. A self-track sits at d=0 and pins h at -pi/2.
    assert(all(vecnorm(reshape([tracks.Position],3,[])' - [egoP 0], 2, 2) > 1e-6), ...
        "backup:egoInTracks", "the ego appeared in its own TrackList at t=%.2f", t);

    % ---------------- the planner ----------------
    if opts.Planner == "negotiating"
        [accel, mode, reason, minH] = negotiate(egoP, egoV, egoYaw, tracks, DMIN, v, VMAX);
    else
        [accel, mode, reason, minH] = defensive(egoP, egoYaw, tracks, v, W);
    end

    % ---------------- lateral: the D6 stand-in ----------------
    [eTarget, clr, latNote] = backup.lateralPolicy(egoP, egoYaw, tracks, W, LANE, ...
                                                   EGO_MIRRORS, e);
    if isfinite(clr), minClearance = min(minClearance, clr); end
    e = e + max(-1.6*dt, min(1.6*dt, eTarget - e));      % 1.6 m/s lateral rate limit

    % ---------------- probe / commit bookkeeping (S6 candidate action) ----------------
    if reason.contains("probe") && ~probeStarted
        probeStarted = true;
        events(end+1) = sprintf("t=%5.1f  PROBE begins - %s", t, latNote); %#ok<AGROW>
    end
    if ~committed && abs(e - LANE) > 0.8 && v > 1.0
        committed = true;
        events(end+1) = sprintf("t=%5.1f  COMMIT - offset %.2f m, clearance %.2f m", t, e, clr); %#ok<AGROW>
    elseif committed && v < 0.4
        committed = false;
        events(end+1) = sprintf("t=%5.1f  ABORT - stopped, gap closed", t); %#ok<AGROW>
    end

    % ---------------- integrate ----------------
    v = max(0, min(VMAX, v + accel*dt));
    s = min(sLen, s + v*dt);

    % ---------------- log ----------------
    T(i)=t; EX(i)=egoP(1); EY(i)=egoP(2); EYaw(i)=egoYaw; EV(i)=v;
    EA(i)=accel; EMode(i)=mode; EReason(i)=reason; EMinH(i)=minH; ELat(i)=e;
    for k=1:numel(A)
        actorLog(k).T(i)=t;
        if A(k).Active
            actorLog(k).X(i)=A(k).P(1); actorLog(k).Y(i)=A(k).P(2); actorLog(k).Yaw(i)=A(k).Yaw;
        end
    end

    if s >= sLen - 0.5
        T=T(1:i); EX=EX(1:i); EY=EY(1:i); EYaw=EYaw(1:i); EV=EV(1:i);
        EA=EA(1:i); EMode=EMode(1:i); EReason=EReason(1:i); EMinH=EMinH(1:i); ELat=ELat(1:i);
        for k=1:numel(actorLog)
            actorLog(k).T=actorLog(k).T(1:i); actorLog(k).X=actorLog(k).X(1:i);
            actorLog(k).Y=actorLog(k).Y(1:i); actorLog(k).Yaw=actorLog(k).Yaw(1:i);
        end
        events(end+1) = sprintf("t=%5.1f  ROUTE COMPLETE at %.0f m", t, s); %#ok<AGROW>
        break
    end
end

% ---------------- assertions ----------------
assert(all(isfinite(EX)) && all(isfinite(EY)), "backup:nanPose", "ego pose went non-finite");
assert(all(EV >= -1e-9), "backup:negSpeed", "ego speed went negative");

out = struct('Name',name,'Planner',opts.Planner,'T',T,'EgoX',EX,'EgoY',EY,'EgoYaw',EYaw, ...
             'EgoV',EV,'Accel',EA,'Mode',EMode,'Reason',EReason,'MinH',EMinH,'Lat',ELat, ...
             'Actors',actorLog,'Events',events,'Spec',S,'Route',route, ...
             'MinClearance',minClearance,'SampleTime',dt);
out.Metrics = backup.metrics(out, EGO_WID, EGO_LEN);

if opts.Verbose
    fprintf('\n---- %s / %s ----\n', name, opts.Planner);
    for k=1:numel(events), fprintf('  %s\n', events(k)); end
    m = out.Metrics;
    fprintf('  distance %.0f m in %.1f s | mean %.1f km/h | min h %.3f rad | min clearance %.2f m\n', ...
            m.M1_distance_m, m.M2_duration_s, m.M3_meanSpeed_kmh, m.M5_minBarrier_rad, m.M6_minClearance_m);
    fprintf('  stopped for %.1f s (%.0f%% of the run) | completed: %s\n', ...
            m.M7_stoppedTime_s, 100*m.M7_stoppedTime_s/max(m.M2_duration_s,eps), string(m.M9_completed));
end
end

% =======================================================================================
function [accel, mode, reason, minH] = negotiate(egoP, egoV, egoYaw, tracks, dmin, v, vmax)
%NEGOTIATE  The real planner: role from geometry, command from the role, plus cruise.
%
%   WHY THERE IS A CRUISE TERM HERE AND NOT IN chooseVelocity
%   chooseVelocity is stateless by design - "one role in, one command out. No state is
%   kept between calls." For role SAFE it therefore returns Accel = 0, which means HOLD,
%   not RESUME. A vehicle driven by chooseVelocity alone can only ever decelerate: every
%   brake is permanent. Keeping to a target speed is a longitudinal-control job that the
%   Stateflow chart owns in the real system (HANDOFF.md, Person B). This supplies the
%   minimum stand-in so the backup car can drive, and it does nothing else.
CRUISE_KP = 0.55;  ACC_MAX = 1.6;

minH = NaN; mode = 1;
cruise = max(-2.0, min(ACC_MAX, CRUISE_KP*(vmax - v)));

if isempty(tracks)
    accel = cruise; reason = "clear road - cruise to target speed"; return
end
roles = sih.planner.assignRoles(egoP, egoV, egoYaw, tracks, 'dMin_m', dmin);

% the governing agent is the one with the smallest barrier h = lambda - beta
hs = arrayfun(@(r) r.Lambda - r.Beta, roles);
hs(~isfinite(hs)) = inf;
[minH, j] = min(hs);
if ~isfinite(minH), minH = NaN; end

vo = sih.planner.velocityObstacle(egoP, egoV, tracks(j).Position(1:2), ...
                                  tracks(j).Velocity(1:2), dmin);
egoState = struct('Position',egoP,'Velocity',egoV,'Yaw',egoYaw);
cmd = sih.planner.chooseVelocity(roles(j).Role, vo, egoState);

accel  = cmd.Accel;
mode   = double(cmd.Mode);
reason = string(cmd.Reason);

SAFE = uint8(0);
if roles(j).Role == SAFE && cmd.Mode ~= 2
    % nothing constrains us: resume. This is the branch chooseVelocity cannot own.
    accel  = cruise;
    reason = "no constraint - cruise to target speed";
end

% A STATIONARY BLOCKER IS NOT A REASON TO STOP FOREVER - it is a reason to PROBE.
% This is the whole S1 result and it is exactly where a defensive planner freezes.
if norm(tracks(j).Velocity(1:2)) < 0.15 && vo.d < 26 && vo.d > 2.5 && v < 1.2
    accel  = 0.45;                       % creep at ~0.5 m/s: read the response
    mode   = 1;
    reason = "probe - stationary blocker, creeping to read the response";
end
end

% =======================================================================================
function [accel, mode, reason, minH] = defensive(egoP, egoYaw, tracks, v, W)
%DEFENSIVE  The frozen-robot stand-in: stop if ANY agent's footprint is in the corridor.
%   This is what a purely defensive planner does and it is NOT MathWorks' planner.
%   MathWorks' own baseline was run and fails at 19.7 s in its own scenario
%   (plan/BASELINE-R2026a.md); it cannot be put on this road, so this stand-in exists
%   to produce the contrast HONESTLY LABELLED. See BACKUP-PLAN.md.
minH = NaN; mode = 1; reason = "clear"; accel = 1.0;
fwd = [cos(egoYaw), sin(egoYaw)]; lft = [-sin(egoYaw), cos(egoYaw)];
for k = 1:numel(tracks)
    r  = tracks(k).Position(1:2) - egoP;
    ax = dot(r, fwd); ay = dot(r, lft);
    if ax > 0 && ax < 28 && abs(ay) < W/2          % anything inside the corridor ahead
        accel  = -6.0*min(1, 12/max(ax,1));
        mode   = 2;
        reason = "defensive - obstacle in corridor, stop and wait";
        if v < 0.2
            accel = 0; reason = "defensive - STOPPED, waiting for the road to clear";
        end
        return
    end
end
end

% =======================================================================================
function L = pathLength(p),  L = sum(vecnorm(diff(p),2,2));  end

function [p, tang] = atStation(route, s)
%ATSTATION  Position and unit tangent at arclength s. Route is resampled at 1 m.
n = size(route,1);
i = max(1, min(n-1, floor(s)+1));
f = max(0, min(1, s - (i-1)));
p = route(i,:)*(1-f) + route(i+1,:)*f;
d = route(min(n,i+1),:) - route(max(1,i),:);
if norm(d) < 1e-9, d = [1 0]; end
tang = d/norm(d);
end
