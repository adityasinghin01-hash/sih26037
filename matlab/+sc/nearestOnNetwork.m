function [pieceIdx, splitT, projXY, dist] = nearestOnNetwork(R, xy)
%NEARESTONNETWORK  Nearest point ANYWHERE on the road network - mid-piece
%   included - to a given world XY. sc.routeFrom can only ever attach a
%   route at a piece's own two endpoints, so when the real nearest point is
%   mid-piece (measured: S5's and S1's own scenario anchors both sit on the
%   SAME real "service" piece, 158 m and 53 m from its nearest endpoint) it
%   simply cannot be reached. This is the projection sc.routeBetween uses
%   to manufacture a real endpoint there before handing off to
%   sc.routeFrom unchanged.
%
%   OUTPUTS
%     pieceIdx  index into R of the closest piece (0 if R is empty)
%     splitT    fractional index along R(pieceIdx).Centers: floor(splitT)
%               is the segment's start row, frac(splitT) the position
%               along it - sc.splitPieceAt consumes this directly
%     projXY    1x2 double, the projected point itself
%     dist      m, distance from xy to projXY

bestD = inf; pieceIdx = 0; splitT = 0; projXY = xy;
for i = 1:numel(R)
    P = R(i).Centers;
    for j = 1:size(P,1)-1
        a = P(j,:); b = P(j+1,:);
        ab = b - a; L2 = sum(ab.^2);
        tt = 0;
        if L2 > eps
            tt = max(0, min(1, dot(xy - a, ab) / L2));
        end
        q = a + tt * ab;
        d = norm(xy - q);
        if d < bestD
            bestD = d; pieceIdx = i; projXY = q; splitT = j + tt;
        end
    end
end
dist = bestD;
end
