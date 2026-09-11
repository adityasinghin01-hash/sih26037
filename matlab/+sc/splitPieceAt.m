function [Ra, Rb] = splitPieceAt(piece, splitT)
%SPLITPIECEAT  Cut one sc.localRoads piece into two at a point along its own
%   centreline, so the cut point becomes a real endpoint sc.routeFrom can
%   attach to. splitT comes from sc.nearestOnNetwork: floor(splitT) is the
%   segment's start row in piece.Centers, frac(splitT) the position along it.
%
%   Class/Width/SrcID are copied to both halves - it is still the same real
%   road, just cut in two. Length is recomputed for each half.

P = piece.Centers;
j = floor(splitT);
j = max(1, min(size(P,1)-1, j));
tt = splitT - j;
a = P(j,:); b = P(j+1,:);
mid = a + tt * (b - a);

Pa = [P(1:j,:); mid];
Pb = [mid; P(j+1:end,:)];

Ra = piece;  Ra.Centers = Pa;  Ra.Length = sum(vecnorm(diff(Pa),2,2));
Rb = piece;  Rb.Centers = Pb;  Rb.Length = sum(vecnorm(diff(Pb),2,2));
end
