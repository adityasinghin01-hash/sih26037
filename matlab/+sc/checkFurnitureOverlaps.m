function [n, worst] = checkFurnitureOverlaps(B, Poles)
%CHECKFURNITUREOVERLAPS  Do any two building footprints overlap each other,
%   or does any building sit on top of a pole? Added 11 Sep 2026 (Phase A of
%   the density-initiative fix pass) - the road-clearance asserts already in
%   sc.s1world/s3world/s4world/s5world only ever checked buildings against
%   the DRIVABLE CARRIAGEWAY. Nothing checked buildings against each other.
%
%   APPROXIMATION, DISCLOSED: each footprint is an axis-aligned box in
%   (station, lateral) - [Station-Depth/2,Station+Depth/2] x
%   [Lateral-Width/2,Lateral+Width/2]. On a curved road that is not a true
%   world-frame rectangle, the same simplification every footprint in this
%   session was already placed with. It is wrong only across a station span
%   wide enough for the road's own curvature to matter, and no building here
%   is deeper than ~9 m - roads in this box do not turn meaningfully over
%   9 m. Poles are treated as points (their own real footprint is a few cm).
%
%   B      W.Buildings struct array (.Station .Lateral .Width .Depth)
%   Poles  W.Poles struct array (.Station .Lateral), or [] if the scenario
%          has none
%   n      total overlap count (building-building + building-pole)
%   worst  one human-readable line describing the worst offender found

n = 0;  worst = "";
nb = numel(B);
for i = 1:nb
    for j = i+1:nb
        if sign(B(i).Lateral) ~= sign(B(j).Lateral), continue; end
        si0 = B(i).Station - B(i).Depth/2;  si1 = B(i).Station + B(i).Depth/2;
        sj0 = B(j).Station - B(j).Depth/2;  sj1 = B(j).Station + B(j).Depth/2;
        if si1 <= sj0 || sj1 <= si0, continue; end
        li0 = abs(B(i).Lateral) - B(i).Width/2;  li1 = abs(B(i).Lateral) + B(i).Width/2;
        lj0 = abs(B(j).Lateral) - B(j).Width/2;  lj1 = abs(B(j).Lateral) + B(j).Width/2;
        if li1 <= lj0 || lj1 <= li0, continue; end
        n = n + 1;
        worst = sprintf("building %d (%s @ s=%.1f,e=%.2f) overlaps building %d (%s @ s=%.1f,e=%.2f)", ...
            i, B(i).Type, B(i).Station, B(i).Lateral, j, B(j).Type, B(j).Station, B(j).Lateral);
    end
end

if nargin >= 2 && ~isempty(Poles)
    for i = 1:nb
        si0 = B(i).Station - B(i).Depth/2;  si1 = B(i).Station + B(i).Depth/2;
        li0 = abs(B(i).Lateral) - B(i).Width/2;  li1 = abs(B(i).Lateral) + B(i).Width/2;
        for p = 1:numel(Poles)
            if sign(Poles(p).Lateral) ~= sign(B(i).Lateral), continue; end
            if Poles(p).Station < si0 || Poles(p).Station > si1, continue; end
            if abs(Poles(p).Lateral) < li0 || abs(Poles(p).Lateral) > li1, continue; end
            n = n + 1;
            worst = sprintf("pole at s=%.1f,e=%.2f sits inside building %d (%s @ s=%.1f)", ...
                Poles(p).Station, Poles(p).Lateral, i, B(i).Type, B(i).Station);
        end
    end
end
end
