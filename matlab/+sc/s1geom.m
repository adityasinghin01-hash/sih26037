function g = s1geom(W)
%S1GEOM  THE S1 GAP ARITHMETIC, IN ONE PLACE.
%
%   WHY THIS FILE EXISTS: the same five numbers were being computed twice - once as a
%   hardcoded `ctx0.cowStopE = 0.65` in `s1_action_run`, and once derived inside
%   `sc.s1actors`. The moment the cow was changed to stop BROADSIDE the two disagreed,
%   and one run printed "free 3.12 m, margin 0.613 m" and "free 3.83 m, margin
%   0.965 m" three lines apart in the same log. The driver was being handed a gap the
%   road did not have. Two sources for one number is the bug; this is the fix.
%
%   THE ARITHMETIC, AND WHAT IS FREE AND WHAT IS FORCED
%   Free width is what the ego actually drives through, so it is the thing held fixed
%   at the written value and everything else is solved backwards from it:
%
%       free = (stopE - lateral/2) + carriageway/2      ->  stopE = free + lat/2 - CW/2
%
%   SHE STOPS BROADSIDE, so `lateral` is her LENGTH (2.05 m), not her width (0.64 m).
%   smoothTrajectory yaws an actor along its direction of travel and she travels
%   ACROSS the carriageway, so broadside is simply where she ends up - no rotation is
%   authored, and none is needed. Presenting her length costs 1.41 m of road, so she
%   stops 1.41 m sooner and the gap is identical.
%
%   WHAT THIS CHANGES AGAINST THE WRITTEN SCRIPT, said plainly:
%     free width 3.830 m   vs written 3.80   - UNCHANGED by the switch
%     margin     0.965 m   vs written 0.95   - UNCHANGED by the switch
%     occupied band 1.12-3.17 m from the left edge, vs a written 2.5-3.2 m.
%   Only the band moves, and it moves because the written band is 0.70 m wide - that
%   is a 0.64 m animal seen end-on, i.e. the written arithmetic quietly assumed a cow
%   standing ALONG the road. A cow that has just walked across it is standing across
%   it. Her nose ends 0.33 m short of the centreline, which is still "walks out to the
%   middle of the road and stops".

arguments
    W struct
end

[~, zd] = sc.meshes("zebu");
[~, cd] = sc.meshes("car");

g.CowLateral = zd(1);              % BROADSIDE: her length is what crosses the road
g.CowWidth   = zd(2);
g.EgoWidth   = cd(2);              % 1.90 m, mirrors included
g.Carriageway = W.Width;

g.FreeTarget = 3.830;              % m - the number the whole S1 result rests on
g.CowStopE   = g.FreeTarget + g.CowLateral/2 - g.Carriageway/2;
g.FreeWidth  = (g.CowStopE - g.CowLateral/2) + g.Carriageway/2;
g.PassE      = ((g.CowStopE - g.CowLateral/2) + (-g.Carriageway/2)) / 2;
g.Margin     = (g.FreeWidth - g.EgoWidth) / 2;

% where she actually sits, measured from the LEFT edge, which is how S1 states it
g.BandFromLeft = [g.Carriageway/2 - (g.CowStopE + g.CowLateral/2), ...
                  g.Carriageway/2 - (g.CowStopE - g.CowLateral/2)];

assert(abs(g.FreeWidth - g.FreeTarget) < 1e-9, "sc:s1geomFree", ...
    "free width solved to %.4f m against a target of %.4f", g.FreeWidth, g.FreeTarget);
assert(g.Margin >= 0.90, "sc:s1geomMargin", ...
    ['margin is %.3f m each side; SPEC requires at least 0.90 m. A broadside cow ' ...
     'costs %.2f m of road over a parallel one, so if this fires she is standing ' ...
     'too far into the carriageway.'], g.Margin, g.CowLateral - g.CowWidth);
end
