%S2_ACTION_RUN  PHASE 6 - the S2 action and result. The negotiation, and map/ego_S2.csv.
%
%   THE S2 RESULT, AND IT IS THE COMPLEMENT OF S1:
%     S1 - an agent that never reacts. A defensive planner waits forever. Frozen robot.
%     S2 - an agent that DOES react. The probe is answered, and the answer is a number:
%          the circulating auto lifts 1.8 km/h, which is read as a yield and committed on.
%   Both are needed. Either alone is half the argument.

here = fileparts(mfilename('fullpath')); addpath(here);
fprintf('\n================ S2 ACTION + RESULT, PHASE 6 ================\n');
W = sc.s2world();
P = W.EgoRoute;  C = W.Centre;
DT = 0.05;  T_END = 48.0;                    % S2: "THE ACTION - 48 seconds"
[~, carD] = sc.meshes("car");

Rmid = (W.Rin + W.Rout)/2;
% SIGN VERIFIED BY MEASUREMENT, NOT BY DERIVATION. Positive e is LEFT of travel, and
% going clockwise round the island that is OUTWARD - so +2.60 put the ego at radius
% 18.59 m, hard against the outer edge, where the wrong-way rider passes. It grazed by
% 7 mm and the separation assert caught it. Negative is inward: -2.60 measures 13.39 m,
% which is the written "1.4 m off the island kerb".
ctx0.ringE     = -((Rmid - W.Rin) - 1.4);    % S2 t=10.1: 1.4 m off the island kerb
ctx0.sGiveWay  = W.SGiveWay;
ctx0.sRingIn   = W.SRingIn;
ctx0.sRingOut  = W.SRingOut;
ctx0.dt        = DT;
xyChk = W.RingPath.at(W.RingPath.Len*0.5, ctx0.ringE);
rChk  = hypot(xyChk(1)-C(1), xyChk(2)-C(2));
assert(abs((rChk - W.Rin) - 1.4) < 0.05, "sc:s2ringLine", ...
    "the ring line sits %.2f m off the kerb, the script says 1.4 m", rChk - W.Rin);
fprintf('route %.0f m | give-way at %.0f m | ring %.0f-%.0f m | ring line e=%+.2f m\n', ...
        P.Len, ctx0.sGiveWay, ctx0.sRingIn, ctx0.sRingOut, ctx0.ringE);

% the actors' start angles, chosen so each meets us on its written beat
% THE EGO DOES NOT START AT THE FAR END OF THE ARM. The written script has it at the
% give-way line at t=5.2 s, and at 26 km/h that is 37.6 m of approach - not the 94 m the
% arm provides. Starting at the end put every beat 6 s late.
V0 = 26/3.6;
ctx0.sStart = max(0, ctx0.sGiveWay - V0*5.2);
beats = struct('tBusPass', 3.4, 'tAutoLift', 7.0, 'tWrongMeet', 15.5, 'aceStation', 46);
fprintf('ego starts at %.1f m so it reaches the give-way line at t=5.2 s\n', ctx0.sStart);
A = sc.s2actors(W, beats, 'SampleTime', DT, 'StopTime', T_END + 6);

% ---------------------------------------------------------------- record the actors
S = A.Scenario;  poses = {};  tS = [];  k = 0;
while advance(S)
    k = k + 1;  tS(k) = S.SimulationTime;  poses{k} = actorPoses(S);        %#ok<SAGROW>
end
fprintf('scenario stepped %d times to t=%.2f s\n', k, tS(end));

who = containers.Map('KeyType','double','ValueType','char');
who(A.Auto.ActorID)='auto'; who(A.Wrong.ActorID)='wrong'; who(A.Bus.ActorID)='bus';
who(A.Ace.ActorID)='ace';
for c = A.Cows, who(c.ActorID)='cow'; end
DIMS = struct('auto',dimOf("auto"), 'wrong',dimOf("motorcycle"), 'bus',dimOf("bus"), ...
              'ace',dimOf("tataace"), 'cow',dimOf("zebu"));

% ---------------------------------------------------------------- THE YIELD, MEASURED
% Read the auto's speed back off the recorded poses. The driver must act on what the
% actor DID, not on the number the script asked for.
av = zeros(1,k);
for i = 1:k
    p = poses{i}([poses{i}.ActorID] == A.Auto.ActorID);
    av(i) = norm(p.Velocity(1:2));
end
vEarly = max(av(1:round(k*0.3)));
vLate  = min(av(av > 0.5));
fprintf('\n--- THE YIELD, MEASURED OFF THE RECORDED POSES ---\n');
fprintf('  auto ran at %.2f km/h and lifted to %.2f km/h -> drop %.2f km/h (written 1.8)\n', ...
        3.6*vEarly, 3.6*vLate, 3.6*(vEarly - vLate));
assert(abs(3.6*(vEarly-vLate) - A.YieldDrop_kmh) < 0.25, "sc:s2yield", ...
    "the auto's measured lift is %.2f km/h, the script says %.2f", ...
    3.6*(vEarly-vLate), A.YieldDrop_kmh);

% ---------------------------------------------------------------- integrate the ego
n = round(T_END/DT);
L = struct('t',zeros(1,n),'s',zeros(1,n),'e',zeros(1,n),'v',zeros(1,n), ...
           'State',strings(1,n),'Note',strings(1,n));
st = struct();  s = ctx0.sStart;  e = 1.75;  ev = 0;  v = V0;  beatsRaw = struct();
A_LON = 1.8;  D_LON = 3.2;
for i = 1:n
    t = (i-1)*DT;
    is = max(1, min(k, round(t/DT)+1));
    ctx = ctx0;  ctx.s=s; ctx.e=e; ctx.v=v; ctx.t=t;
    % the two quantities the driver is allowed to read from the world
    j = max(1, is-1);
    ctx.YieldDrop = 3.6 * max(0, vEarly - av(is));
    pw = poses{is}([poses{is}.ActorID] == A.Wrong.ActorID);
    [sw, ~] = P.inverse(pw.Position(1:2));
    ctx.WrongWayRange = sw - s;
    [cmd, st] = sc.s2drive(st, ctx);
    % FIRST entry, not last. CIRCULATE is re-entered after HOLD, so recording every
    % entry made the beat table print HOLD as happening before CIRCULATE.
    if (st.Changed || i == 1) && ~isfield(beatsRaw, char(st.State))
        beatsRaw.(char(st.State)) = struct('t',t,'s',s);
    end
    v = max(0, v + max(-D_LON*DT, min(A_LON*DT, cmd.v - v)));
    % SMOOTH EASE IN/OUT, not a flat-rate slide - see sc.lateralStep. Same
    % physics cap (tand(12)*v) as before, now acceleration-limited on top.
    [e, ev] = sc.lateralStep(e, ev, cmd.e, v, DT);
    s = min(P.Len, s + v*DT);
    L.t(i)=t; L.s(i)=s; L.e(i)=e; L.v(i)=v; L.State(i)=st.State; L.Note(i)=st.Note;
end

fprintf('\n--- THE BEATS ---\n');
written = struct('APPROACH',0, 'GIVEWAY',5.2, 'PROBE',6.0, 'COMMIT',8.3, ...
                 'CIRCULATE',10.1, 'HOLD',14.6, 'EXIT',24.8);
fn = fieldnames(beatsRaw);
for q = 1:numel(fn)
    b = beatsRaw.(fn{q});
    if isfield(written, fn{q})
        fprintf('  %-10s %6.2f s  %6.1f m   written %.1f  (%+.1f s)\n', ...
                fn{q}, b.t, b.s, written.(fn{q}), b.t - written.(fn{q}));
    else
        fprintf('  %-10s %6.2f s  %6.1f m\n', fn{q}, b.t, b.s);
    end
end

% ---------------------------------------------------------------- separation
minSep = inf; worst=''; tW=NaN;
for i = 1:min(n,k)
    pp = poses{i};
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        nm = who(pp(q).ActorID);  dq = DIMS.(nm);
        [sq, eq] = P.inverse(pp(q).Position(1:2));
        [~, hq]  = P.at(sq, 0);
        th = deg2rad(pp(q).Yaw) - hq;
        aL = abs(dq(1)*cos(th)) + abs(dq(2)*sin(th));
        aW = abs(dq(1)*sin(th)) + abs(dq(2)*cos(th));
        sep = max(abs(sq - L.s(i)) - (aL + carD(1))/2, ...
                  abs(eq - L.e(i)) - (aW + carD(2))/2);
        if sep < minSep, minSep = sep; worst = nm; tW = L.t(i); end
    end
end
fprintf('\n--- SEPARATION ---\n  closest approach %.3f m to the %s at t=%.2f s\n', ...
        minSep, worst, tW);
assert(minSep > 0, "sc:s2collision", ...
    "the ego overlaps the %s by %.3f m at t=%.2f s", worst, -minSep, tW);
fprintf('  the parked Tata Ace leaves %.2f m of lane (written 2.9)\n', A.AceGap);

% ---------------------------------------------------------------- the CSV
X=zeros(1,n); Y=zeros(1,n); H=zeros(1,n);
for i=1:n, [xy,h]=P.at(L.s(i), L.e(i)); X(i)=xy(1); Y(i)=xy(2); H(i)=h; end
outCsv = fullfile(sc.refRoot(),'world','map','ego_S2.csv');
Tcsv = table(L.t(:), X(:), Y(:), H(:), L.v(:), ...
             'VariableNames', {'time','x','y','heading','speed'});
writetable(Tcsv, outCsv);
assert(~any(isnan([X Y H L.v])), "sc:s2csvNaN", "the CSV contains NaN");
fprintf('\n--- map/ego_S2.csv ---\n  %d rows, %.2f s, %.1f m, OSM-metric frame\n', ...
        height(Tcsv), L.t(end), L.s(end)-ctx0.sStart);
save(fullfile(here,'renders','s2_action.mat'), 'L','beatsRaw','tS','av','poses','who','DIMS');
fprintf('\n============================================================\n\n');

function d = dimOf(nm)
[~, d] = sc.meshes(nm);
end
