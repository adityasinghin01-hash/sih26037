function [cmd, st] = s1defensive(st, ctx)
%S1DEFENSIVE  THE DEFENSIVE STAND-IN. *** OURS, NOT MathWorks'. ***
%
%   REF-17 s8, decided by Aditya: the film leads with MathWorks' shipped planner
%   FAILING (referencePathFrenet, 0 of 120 candidates at t = 19.7 s, and it cannot run
%   on Najibabad at all), and then shows this beside us so the frozen-robot problem is
%   SEEN rather than described.
%
%   IT MUST BE CAPTIONED AS OURS IN THE FRAME. PRD s8 warns that a tuned opponent is a
%   rigged fight, and the defence against that charge is the caption, not our good
%   intentions. It is deliberately NOT tuned to lose: it is the textbook defensive rule
%   and nothing more - keep your lane, and stop for anything blocking it.
%
%   THE RULE, in full:
%       "Never leave your lane. If the lane ahead is blocked, decelerate to a stop and
%        wait for it to clear."
%   That is a correct, safe, entirely reasonable policy. On a road with a cow standing
%   in it, it waits forever, because a cow never clears. THAT is the frozen-robot
%   problem, and it is structural - not a tuning failure we engineered.

if isempty(fieldnames(st)), st = struct('State',"CRUISE", 'Note',"lane-keeping", 'T0',0); end

LANE_E = 1.75;  CRUISE_V = 52/3.6;  DECEL = 2.5;
cmd.e = LANE_E;                          % it never leaves its lane. That is the whole rule.

% is anything blocking OUR LANE - not the carriageway, the lane
blocked = false;  d = inf;
if isfield(ctx,'Obs')
    for i = 1:numel(ctx.Obs)
        r = ctx.Obs(i).s - ctx.s;
        if r < 0 || r > 70, continue; end
        if ctx.Obs(i).e + ctx.Obs(i).halfW > 0 && ctx.Obs(i).e - ctx.Obs(i).halfW < 3.5
            blocked = true;  d = min(d, r);
        end
    end
end

if blocked
    % TRAP, and the SECOND time this exact one has bitten: clamping the stop distance
    % at a floor leaves a non-zero speed commanded forever, so the car never actually
    % stops. sc.s1drive had the identical bug in SLOWING. Command a real zero.
    stopAt = d - 4.0;                                 % hold 4 m off it
    if stopAt <= 0.3
        cmd.v = 0;
    else
        cmd.v = min(CRUISE_V, sqrt(2*DECEL*stopAt));
    end
    if ctx.v < 0.3
        st.State = "STOPPED";
        st.Note  = sprintf("lane blocked at %.0f m - waiting", d);
    else
        st.State = "SLOWING";  st.Note = sprintf("obstacle %.0f m", d);
    end
else
    cmd.v = CRUISE_V;  st.State = "CRUISE";  st.Note = "lane-keeping";
end
cmd.State = st.State;  cmd.Note = st.Note;
end
