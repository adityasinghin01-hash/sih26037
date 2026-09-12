function route2 = roundRouteCorners(route, seamIdx, winM)
%ROUNDROUTECORNERS  Chaikin corner-cutting, applied ONLY in a local window
%   around each named seam index - not the whole route.
%
%   FOUND 6 Sep, from a real, measured defect: sc.s2world's egp route used
%   to be a raw concatenation of the entry arm's points, the ring's points,
%   and the exit arm's points (`route = [inb; ring; out]`). An arm points
%   RADIALLY toward the gyratory centre; the ring at that same point is
%   TANGENT to the circle - perpendicular to the radius. Concatenating the
%   two point lists therefore puts a real ~80 deg direction change at one
%   seam by construction, not something sc.lateralStep's rate-limiting can
%   fix (that smooths lateral OFFSET within one path's own parametrisation;
%   this is a corner in the path's OWN geometry). Measured off the logged
%   heading: flat for 1.6 s, then ~77 deg of turn in well under half a
%   second, peaking at 352 deg/s in one 0.05 s step - exactly the "straight
%   then a 90 deg snap" a viewer would see.
%
%   Chaikin corner-cutting (not an exact tangent-arc matching S2's own
%   written R1~12m/R2~18m) is a deliberate choice: this is a MOTION-QUALITY
%   fix, not a measured arithmetic claim anything in this project asserts
%   against, so the simpler, more robust technique is the right one here.
%
%   route    Nx2 raw route points, ~1 m apart (sc.path's own station spacing)
%   seamIdx  indices INTO route (in increasing order) to round the corner at
%   winM     how many points either side of each seam to smooth (~metres,
%            since points are ~1 m apart) - SCALAR (same for every seam) or
%            a vector matching seamIdx one-for-one. Size this to the seam's
%            OWN measured angle, not one number for every corner - S2's two
%            seams measure 41 deg and 82 deg and needed different windows
%            to round out to comparable smoothness, and the windows must
%            stay small enough not to overlap the gap between seams.

% PROCESSED IN REVERSE (highest index first) - a POINT-COUNT OFFSET chain
% between sequential edits was tried first and was WRONG: Chaikin cutting
% can shorten OR lengthen the point count unpredictably (it resamples to
% the smoothed arc's own new length, which is normally shorter than the
% original two straight legs, but not always by a computable amount ahead
% of time), so an earlier edit's offset applied to a later seam's index
% landed the window short of the real corner - found by looking at the
% actual points: the ring side smoothed beautifully, then reverted to raw,
% un-smoothed straight-arm points one point later. Processing highest-index-
% first means every edit only touches indices AFTER itself, which nothing
% earlier depends on, so no offset bookkeeping is needed at all.
route2 = route;
if isscalar(winM), winM = repmat(winM, size(seamIdx)); end
[seamIdx, ord] = sort(seamIdx, 'descend');
winM = winM(ord);
for k = 1:numel(seamIdx)
    si = seamIdx(k);
    halfWin = round(winM(k));
    lo = max(2, si - halfWin);
    hi = min(size(route2,1) - 1, si + halfWin);
    seg = route2(lo:hi, :);
    for it = 1:7                              % 7 Chaikin passes - MEASURED needed,
        n = size(seg,1);                      % not guessed: this route's two seams
        if n < 3, break; end                  % measure 41 deg and 82 deg respectively
                                               % (dot-product test either side of each,
                                               % matlab/diag scratch), and 4 passes over
                                               % a 24-28 m window rounded the smaller one
                                               % but left the sharper one visibly kinked
        Q1 = 0.75*seg(1:end-1,:) + 0.25*seg(2:end,:);
        Q2 = 0.25*seg(1:end-1,:) + 0.75*seg(2:end,:);
        newSeg = zeros(2*(n-1), 2);
        newSeg(1:2:end,:) = Q1;
        newSeg(2:2:end,:) = Q2;
        seg = [seg(1,:); newSeg; seg(end,:)];
    end
    % RE-RESAMPLE TO ~1 POINT PER METRE so sc.path's own station spacing
    % stays consistent through the smoothed window, same convention as
    % everywhere else this project builds a path.
    segLen = [0; cumsum(vecnorm(diff(seg),2,2))];
    [segLen, iu] = unique(segLen, 'stable');  seg = seg(iu,:);
    nOut = max(2, round(segLen(end)));
    segR = interp1(segLen, seg, linspace(0, segLen(end), nOut)', 'linear');

    route2 = [route2(1:lo-1,:); segR; route2(hi+1:end,:)];
end
end
