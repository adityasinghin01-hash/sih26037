function [cmd, st] = s1drive(st, ctx)
%S1DRIVE  *** A PLACEHOLDER DRIVER. IT MAKES NO PLANNING CLAIM WHATSOEVER. ***
%
%   IT DOES NOT SENSE ANYTHING. It follows the beats written in S1-CATTLE-CROSSING.md
%   by STATION and by TIME-IN-STATE. It does not look at the cow, it does not look at
%   the oncoming auto, and the reason it "aborts" is that the script says to abort at
%   that station - not that it detected anything. Say this out loud in any demo.
%
%   Aditya's instruction, 4 Sep: "build a simple one, we'll just replace it - I just
%   have to see how everything is working."
%
%   WHAT IT IS FOR is the SEAT. Stream D's planner replaces the body of this function
%   and nothing else: same inputs, same outputs, same integration loop, and the frozen
%   S1 TrackList (AGENTS.md s3) is the boundary. That boundary does not move.
%
%   ctx  .s .e .v          station, lateral (+ is LEFT), speed
%        .t                seconds since the run started
%        .reveal           station at which the cow becomes visible (from the world)
%        .cowStation .cowStopE .passE .freeWidth .margin
%   cmd  .v .e             TARGET speed and TARGET lateral - not a pose. The loop
%                          integrates them under acceleration and lateral-rate limits,
%                          so the placeholder cannot teleport the car.
%   st   .State .Note .T0  the state machine; State is one of the sc.hud labels.

if isempty(fieldnames(st)), st = struct('State',"CRUISE", 'Note',"open road", 'T0',0); end

CRUISE_V = 52/3.6;      % S1 t=0:    "Ego at chainage 0, 52 km/h"
SLOW_V   = 34/3.6;      % S1 t=11.2: "slows to 34"
BACK_V   = 38/3.6;      % S1 t=30.7 and t=47.0: "38 km/h"
CREEP_V  = 0.5;         % S1 t=32.8: "Creep at 0.5 m/s"
PASS_V   = 8/3.6;       % S1 t=42.7: "Crawls past at 8 km/h"
LANE_E   = 1.75;        % our lane centre. INDIA DRIVES ON THE LEFT: ours is POSITIVE.
SHOULDER_E = 2.85;      % S1 t=11.2: "moves left onto the shoulder"

PROBE_FOR = 2.4;        % S1: probe 32.8 -> classified 35.2
ABORT_FOR = 6.1;        % S1: abort 36.6 -> auto passes 41.9 -> commits 42.7

s = ctx.s;  prev = st.State;

switch st.State
case "CRUISE"
    cmd.v = CRUISE_V;  cmd.e = LANE_E;  st.Note = "open road, 52 km/h";
    if s >= ctx.sSlow, st.State = "SLOW"; end

case "SLOW"
    % the wrong-side motorcycle, then the tractor-trolley. Both are "edge left, slow".
    cmd.v = SLOW_V;  cmd.e = SHOULDER_E;
    st.Note = "oncoming on our side - shoulder";
    if s >= ctx.sTractor + 18
        st.State = "CRUISE2";
    end

case "CRUISE2"
    cmd.v = BACK_V;  cmd.e = LANE_E;  st.Note = "clear, 38 km/h";
    % THE COW IS REVEALED HERE. The placeholder does not see her; it reaches the
    % station at which the WORLD says she becomes visible, which sc.s1world SOLVED.
    if s >= ctx.reveal, st.State = "SIGHTED"; end

case "SIGHTED"
    cmd.v = BACK_V;  cmd.e = LANE_E;
    st.Note = sprintf("cattle ahead at %.0f m", ctx.cowStation - s);
    if s >= ctx.reveal + 2, st.State = "SLOWING"; end      % seen it; start slowing

case "SLOWING"
    % Brake to a stop about 12 m short of her, which is where the probe begins.
    % TRAP, and it cost a run: clamping d at 0.5 m leaves sqrt(2*2.6*0.5) = 1.61 m/s
    % commanded FOREVER once the stop point is reached, so the speed never falls under
    % any threshold and the machine never leaves this state. Command a real zero.
    % WHERE TO STOP IS DERIVED, NOT PICKED. Twice now a hand-picked distance has
    % failed: at 12 m the ego could not finish its lateral move before drawing level
    % and cleared the cow by 0.856 m against a required 0.90; at 18 m it could not
    % physically stop in the room it had left itself. The stop point is therefore
    % whatever the LATERAL MOVE needs - ctx.commitRunUp, computed from the pass
    % offset, the pass speed and the crab-angle limit - plus the two half-lengths.
    d = (ctx.cowStation - ctx.commitRunUp) - s;
    if d <= 0.4
        cmd.v = 0;
    else
        cmd.v = min(BACK_V, sqrt(2 * 2.5 * d));  % v^2 = 2 a d
    end
    cmd.e = LANE_E;  st.Note = "non-negotiable obstacle - stopping";
    if ctx.v < 0.5, st.State = "PROBE"; st.T0 = ctx.t; end

case "PROBE"
    % creep forward and offset right, and read the response. There is none: a cow
    % does not negotiate. THIS is the frozen-robot problem, made visible.
    cmd.v = CREEP_V;  cmd.e = LANE_E + (ctx.passE - LANE_E)*0.45;
    st.Note = "probing - no response";
    if ctx.t - st.T0 >= PROBE_FOR, st.State = "ABORT"; st.T0 = ctx.t; end

case "ABORT"
    % the gap is real and it fits, but it is in the ONCOMING lane and the auto is in
    % it. Two futures; commit only to what is safe under both.
    cmd.v = 0;  cmd.e = LANE_E + (ctx.passE - LANE_E)*0.45;
    st.Note = "oncoming auto - holding";
    if ctx.t - st.T0 >= ABORT_FOR, st.State = "COMMIT"; st.T0 = ctx.t; end

case "COMMIT"
    cmd.v = PASS_V;  cmd.e = ctx.passE;
    st.Note = sprintf("%.2f m each side", ctx.margin);
    if s >= ctx.cowStation + 6, st.State = "CLEAR"; end

case "CLEAR"
    cmd.v = BACK_V;  cmd.e = LANE_E;  st.Note = "clear";
end

st.Changed = ~strcmp(prev, st.State);

% THE NOTE HAS TO MATCH THE STATE IN THE SAME FRAME. Each case sets its note and THEN
% decides whether to transition, so on a transition step the note still described the
% state we just left - and a still captured at exactly that step (which is what
% find(State=="ABORT",1) returns) showed "ABORT / probing - no response". One frame in
% a film is invisible; in a deck it is a wrong caption. Re-evaluate once in the new
% state so the command, the state and the note are all from the same place.
if st.Changed
    [cmd, st] = sc.s1drive(setfield(st, 'Changed', false), ctx);   %#ok<SFLD>
    st.Changed = true;
    return
end
cmd.State = st.State;  cmd.Note = st.Note;
end
