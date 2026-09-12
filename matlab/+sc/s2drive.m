function [cmd, st] = s2drive(st, ctx)
%S2DRIVE  *** A PLACEHOLDER DRIVER. IT MAKES NO PLANNING CLAIM WHATSOEVER. ***
%
%   The same seat as sc.s1drive, and the same warning applies: Stream D's planner
%   replaces the body of this function and nothing else.
%
%   ONE DIFFERENCE FROM S1, AND IT IS THE WHOLE POINT OF S2. The cow never reacted, so
%   S1's driver could follow stations blindly. Here the circulating auto DOES react, and
%   the demo turns on reading that. So this placeholder does read ONE real quantity from
%   the world - `ctx.YieldDrop`, the measured speed change of the binding agent - and
%   commits only when it exceeds a threshold. Everything else is still scripted by
%   station and time-in-state. Say that plainly: it senses one number, not a scene.
%
%   S2 written beats: give-way at t=5.2 (nobody yields) -> probe 6.0 -> auto drops
%   1.8 km/h at 8.3, read as a yield -> commit -> ring at 10.1 -> exit 24.8.

if isempty(fieldnames(st))
    st = struct('State',"APPROACH", 'Note',"arm D, 26 km/h", 'T0',0, 'Nosed',0);
end

APPROACH_V = 26/3.6;      % S2 t=0
PROBE_V    = 0.4;         % S2 t=6.0: "noses forward 1.1 m at 0.4 m/s"
NOSE_M     = 1.1;
RING_V     = 22/3.6;
EXIT_V     = 18/3.6;      % S2 t=24.8: "Speed 18"
YIELD_KMH  = 1.5;         % the auto drops 1.8 km/h; read anything over 1.5

LANE_E = 1.75;            % arm lane centre. India drives on the LEFT: ours is positive.
RING_E = ctx.ringE;       % 1.4 m off the island kerb (S2 t=10.1), computed by the caller

prev = st.State;
switch st.State
case "APPROACH"
    cmd.v = APPROACH_V;  cmd.e = LANE_E;  st.Note = "arm D, 26 km/h";
    if ctx.s >= ctx.sGiveWay - 12, st.State = "GIVEWAY"; st.T0 = ctx.t; end

case "GIVEWAY"
    % brake to the line and hold. Nobody yields yet.
    d = ctx.sGiveWay - ctx.s;
    if d <= 0.4, cmd.v = 0; else, cmd.v = min(APPROACH_V, sqrt(2*2.5*d)); end
    cmd.e = LANE_E;  st.Note = "give-way line - nobody yields";
    if ctx.v < 0.4 && ctx.t - st.T0 > 0.8, st.State = "PROBE"; st.T0 = ctx.t; end

case "PROBE"
    % creep out 1.1 m and watch whether the circulating auto lifts off
    cmd.v = PROBE_V;  cmd.e = LANE_E;
    st.Nosed = st.Nosed + PROBE_V*ctx.dt;
    st.Note = sprintf("probing - nosed %.2f m", min(st.Nosed, NOSE_M));
    if st.Nosed >= NOSE_M, cmd.v = 0; end
    if ctx.YieldDrop >= YIELD_KMH
        st.State = "COMMIT";  st.T0 = ctx.t;
        st.Note = sprintf("auto lifted %.1f km/h - read as yield", ctx.YieldDrop);
    end

case "COMMIT"
    cmd.v = RING_V;  cmd.e = RING_E;
    st.Note = sprintf("committed on a %.1f km/h lift", ctx.YieldDrop);
    if ctx.s >= ctx.sRingIn, st.State = "CIRCULATE"; end

case "CIRCULATE"
    % NO LANE MARKINGS HERE. The ego picks its own line, 1.4 m off the island kerb.
    cmd.v = RING_V;  cmd.e = RING_E;
    st.Note = "no lane markings - own line, 1.4 m off the kerb";
    % S2 t=14.6: a motorcycle comes the wrong way round the island. HOLD THE LINE.
    % "Backing off now is more dangerous than continuing."
    if ctx.WrongWayRange < 30 && ctx.WrongWayRange > 0
        st.State = "HOLD";  st.T0 = ctx.t;
    elseif ctx.s >= ctx.sRingOut
        st.State = "EXIT";
    end

case "HOLD"
    cmd.v = RING_V*0.85;  cmd.e = RING_E;
    st.Note = sprintf("wrong-way rider %.0f m - holding line", ctx.WrongWayRange);
    if ctx.WrongWayRange <= 0 || ctx.WrongWayRange > 34
        st.State = "CIRCULATE";
    end

case "EXIT"
    cmd.v = EXIT_V;  cmd.e = LANE_E;  st.Note = "exiting onto arm A";
end

st.Changed = ~strcmp(prev, st.State);
if st.Changed
    [cmd, st] = sc.s2drive(setfield(st,'Changed',false), ctx);   %#ok<SFLD>
    st.Changed = true;  return
end
cmd.State = st.State;  cmd.Note = st.Note;
end
