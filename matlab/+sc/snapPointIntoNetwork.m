function R2 = snapPointIntoNetwork(R, xy, minFrag_m)
%SNAPPOINTINTONETWORK  Make xy a real piece endpoint if it isn't already.
%
%   ALWAYS attempts the split - does not use sc.nearestOnNetwork's own
%   distance as a "skip it" test, because that distance is xy to the
%   nearest point ANYWHERE on the network, which is ~0 for every real
%   scenario anchor by construction (they were placed on the real road) -
%   it can never tell "already at an endpoint" from "158 m mid-piece",
%   which was a real, measured bug in the first version of this logic
%   (sih26037, 11 Sep 2026: the S5->S1 connector kept failing identically
%   after the fix until this was corrected). The real "already an
%   endpoint, nothing to do" case is instead caught by the split producing
%   a degenerate (near-zero-length) half, which minFrag_m filters out.
%
%   Shared by sc.routeBetween and sc.shortestRoute so this logic exists
%   in exactly one place.

arguments
    R struct
    xy (1,2) double
    minFrag_m (1,1) double = 0.5
end

[k, t] = sc.nearestOnNetwork(R, xy);
if k == 0
    R2 = R;
    return
end
[Ra, Rb] = sc.splitPieceAt(R(k), t);
R2 = R;
keep = struct('Centers',{},'Class',{},'Width',{},'Length',{},'SrcID',{});
if Ra.Length > minFrag_m, keep(end+1) = Ra; end
if Rb.Length > minFrag_m, keep(end+1) = Rb; end
if isempty(keep)
    return   % both halves degenerate - xy was effectively already this piece's endpoint
end
R2(k) = [];
R2 = [R2, keep];
end
