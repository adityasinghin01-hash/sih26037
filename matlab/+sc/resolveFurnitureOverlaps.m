function B = resolveFurnitureOverlaps(B, minGap)
%RESOLVEFURNITUREOVERLAPS  Nudge building STATIONS forward, in station
%   order, until no two buildings on the same side of the road overlap.
%   Added 11 Sep 2026 (Phase A fix pass) after sc.checkFurnitureOverlaps
%   caught real collisions in both sc.s1world (hand-picked stations placed
%   three buildings on top of each other) and sc.s3world (named additions
%   landed inside the procedural scatter's own footprint, unaware of it).
%
%   Both were symptoms of the same thing: a station picked in isolation,
%   never checked against its neighbours. Rather than hand-resolve every
%   conflict this pattern can produce, one general sweep: process buildings
%   in station order, and whenever a later one's near edge would land closer
%   than minGap to an earlier one ON THE SAME SIDE with overlapping lateral
%   extent, push the later one forward just enough to clear it. Deterministic
%   (sorted, single forward pass), a no-op when nothing overlaps, and safe to
%   call unconditionally before the overlap assert that follows it.
%
%   B       W.Buildings struct array (.Station .Lateral .Width .Depth)
%   minGap  m, minimum clear gap once resolved (default 0.5 m)

if nargin < 2, minGap = 0.5; end
[~, ord] = sort([B.Station]);
for oi = 2:numel(ord)
    i = ord(oi);
    for oj = 1:oi-1
        j = ord(oj);
        if sign(B(i).Lateral) ~= sign(B(j).Lateral), continue; end
        li0 = abs(B(i).Lateral) - B(i).Width/2;  li1 = abs(B(i).Lateral) + B(i).Width/2;
        lj0 = abs(B(j).Lateral) - B(j).Width/2;  lj1 = abs(B(j).Lateral) + B(j).Width/2;
        if li1 <= lj0 || lj1 <= li0, continue; end   % different lateral bands, never conflict
        si0 = B(i).Station - B(i).Depth/2;
        sj1 = B(j).Station + B(j).Depth/2;
        if si0 < sj1 + minGap
            shift = (sj1 + minGap) - si0;
            B(i).Station = B(i).Station + shift;
        end
    end
end
end
