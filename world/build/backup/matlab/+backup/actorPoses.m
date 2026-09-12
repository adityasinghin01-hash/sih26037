function A = actorPoses(S, route, t, ctx)
%ACTORPOSES  Where every non-ego actor is at time t, and how it is moving.
%
%   Four behaviours (backup.scenarioSpec):
%     static    fixed pose, never moves
%     scripted  constant speed along the route corridor at a fixed lateral offset
%     blocker   THE COW. Walks from LateralFrom to LateralTo, then STOPS FOREVER.
%               It never reacts to the ego. That is the point of S1 and it is a
%               constant, not a model.
%     reactive  gap acceptance. Lifts off once the ego has committed, otherwise holds
%               course and speed. This is the agent whose response the ego READS.
%
%   Positions are world frame, m. Velocity is m/s.

A = struct('P',{},'V',{},'Yaw',{},'Active',{});
for k = 1:numel(S.Actors)
    a = S.Actors(k);
    switch a.Behaviour
    case "static"
        [p, yaw] = place(route, a.StationAlong, a.Lateral);
        A(k) = mk(p, [0 0], yaw + a.Yaw, true);

    case "scripted"
        if t < a.TStart, A(k) = mk([1e6 1e6],[0 0],0,false); continue; end
        [p, yaw, v] = travel(route, a, t);
        A(k) = mk(p, v, yaw, true);

    case "blocker"
        % walks out, then stops. Never moves again, whatever the ego does.
        if t < a.TStart
            [p, yaw] = place(route, a.StationAlong, a.LateralFrom);
            A(k) = mk(p, [0 0], yaw + pi/2, true);
        else
            span = abs(a.LateralTo - a.LateralFrom);
            tw   = span / max(a.Speed, 1e-6);            % how long the walk takes
            f    = min(1, (t - a.TStart)/tw);
            lat  = a.LateralFrom + f*(a.LateralTo - a.LateralFrom);
            [p, yaw] = place(route, a.StationAlong, lat);
            if f < 1
                [p2,~] = place(route, a.StationAlong, lat + 0.01*sign(a.LateralTo-a.LateralFrom));
                vv = (p2 - p); vv = vv/max(norm(vv),1e-9) * a.Speed;
            else
                vv = [0 0];                               % STOPPED. Standing. Not negotiating.
            end
            A(k) = mk(p, vv, yaw + pi/2, true);
        end

    case "reactive"
        if t < a.TStart, A(k) = mk([1e6 1e6],[0 0],0,false); continue; end
        % gap acceptance: once the ego has committed into the gap, this agent eases
        % off; otherwise it holds. The written S2 reads a 1.8 km/h drop as the yield.
        sp = a.Speed;
        if ctx.Committed, sp = a.Speed * 0.78; end        % ~1.8 km/h off 24 km/h
        b = a; b.Speed = sp;
        [p, yaw, v] = travel(route, b, t);
        A(k) = mk(p, v, yaw, true);
    end
end
end

% ---------------------------------------------------------------------------------------
function A = mk(p,v,yaw,act), A = struct('P',p,'V',v,'Yaw',yaw,'Active',act); end

function [p, yaw] = place(route, station, lateral)
[p0, tang] = at(route, station);
nrm = [-tang(2), tang(1)];
p   = p0 + lateral*nrm;
yaw = atan2(tang(2), tang(1));
end

function [p, yaw, v] = travel(route, a, t)
%TRAVEL  Constant-speed motion along the route corridor.
%   Oncoming actors run DOWN-station (toward the ego); others run up-station.
dir = 1; if a.Oncoming, dir = -1; end
st  = a.StationAlong + dir * a.Speed * (t - a.TStart);
[p, yaw] = place(route, st, a.Lateral);
if a.Oncoming, yaw = yaw + pi; end
v = a.Speed * [cos(yaw), sin(yaw)];
end

function [p, tang] = at(route, s)
n = size(route,1);
s = max(0, min(n-1, s));
i = max(1, min(n-1, floor(s)+1));
f = max(0, min(1, s - (i-1)));
p = route(i,:)*(1-f) + route(i+1,:)*f;
d = route(min(n,i+1),:) - route(max(1,i),:);
if norm(d) < 1e-9, d = [1 0]; end
tang = d/norm(d);
end
