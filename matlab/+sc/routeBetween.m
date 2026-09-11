function [path_m, pieces, R2] = routeBetween(R, startXY, endXY, opts)
%ROUTEBETWEEN  Like sc.routeFrom, but the two ends need not already be a
%   piece's own endpoint.
%
%   sc.routeFrom can only ATTACH a route at a piece's pre-existing endpoint
%   - fine for a scenario's own short local build, where the endpoints were
%   hand-picked to already sit there, but it fails or wanders badly when the
%   real nearest point is mid-piece. MEASURED building the 5-scenario
%   connectors (11 Sep 2026): S5's and S1's own scenario anchors sit on the
%   SAME real "service" road, 158 m and 53 m from its nearest endpoint -
%   sc.routeFrom cannot reach either one, and forcing it onto distant real
%   endpoints elsewhere produced 4-21x circuitous "routes" that were the
%   algorithm being pushed onto the wrong real junctions, not a genuinely
%   winding road.
%
%   This snaps each end in first: sc.nearestOnNetwork finds the true
%   closest point anywhere on the network (mid-piece included),
%   sc.splitPieceAt cuts that one piece there so the point becomes a real
%   endpoint, and ONLY THEN does the unmodified sc.routeFrom run. Neither
%   sc.routeFrom nor any of its existing callers (every scenario's own
%   world builder) are touched by this file.
%
%   OUTPUTS
%     path_m  Nx2 double  ordered centreline, m (as sc.routeFrom)
%     pieces  1xK double  indices into R2 (NOT R - R2 is returned because
%             the split may have added a piece)
%     R2      the piece list actually used, R with 0-2 pieces replaced by
%             their split halves - pass this to anything that needs to
%             look up piece metadata (Class, Width) for `pieces`

arguments
    R struct
    startXY (1,2) double
    endXY   (1,2) double
    opts.joinTol_m  (1,1) double = 30.0
    opts.classes    string = strings(0,1)
    opts.minFrag_m  (1,1) double = 0.5   % a split half shorter than this is degenerate -
                                          % xy was already effectively this piece's endpoint
end

R2 = sc.snapPointIntoNetwork(R,  startXY, opts.minFrag_m);
R2 = sc.snapPointIntoNetwork(R2, endXY,   opts.minFrag_m);

[path_m, pieces] = sc.routeFrom(R2, startXY, endXY, ...
    'joinTol_m', opts.joinTol_m, 'classes', opts.classes);
end
