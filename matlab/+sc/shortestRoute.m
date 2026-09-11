function [path_m, pieces, R2] = shortestRoute(R, startXY, endXY, opts)
%SHORTESTROUTE  A TRUE shortest-path route between two points on the real
%   road network, weighted by real segment length.
%
%   sc.routeFrom chains pieces by a greedy nearest-join + heading-continuity
%   + goal-distance SCORE, one step at a time - built for, and good at, a
%   scenario's own short local route. MEASURED wiring the 5-scenario
%   connectors (11 Sep 2026): over a longer, junction-rich stretch it can
%   wander badly - the S1<->S3 connector (663 m straight-line) came back at
%   4802 m (7.24x) unrestricted and still 1789-1875 m (2.7-2.8x) restricted
%   to plausible through-classes, because the greedy search locally prefers
%   continuing straight over ever backtracking onto the real shortest path.
%   This function does not patch that heuristic - it replaces it with
%   Dijkstra over the real piece graph, so the route it returns is
%   provably the shortest real one, not merely a plausible-looking one.
%
%   Same snap-in-first approach as sc.routeBetween (sc.snapPointIntoNetwork,
%   itself sc.nearestOnNetwork + sc.splitPieceAt): neither startXY nor
%   endXY need already be a piece's own endpoint. Drop-in-shaped output -
%   [path_m, pieces, R2] as sc.routeBetween, except `pieces` here may
%   legitimately traverse a piece in either direction (a real route through
%   a junction lattice has no reason to prefer one), which sc.routeFrom's
%   own output never needed to express.
%
%   INPUTS as sc.routeBetween. opts.nodeTol_m (default 2.0 m) merges piece
%   endpoints that are the same real junction into one graph node - real
%   OSM-derived junctions from one export coincide far tighter than that
%   (this codebase's own cross-frame agreement figures run ~1 m; the same
%   export against itself is far closer), so this is a safety margin, not
%   the thing doing the real work.
%
%   Neither sc.routeFrom nor any of its existing callers (every scenario's
%   own world builder) are touched by this file.

arguments
    R struct
    startXY (1,2) double
    endXY   (1,2) double
    opts.classes   string = strings(0,1)
    opts.minFrag_m (1,1) double = 0.5
    opts.nodeTol_m (1,1) double = 2.0
end

if ~isempty(opts.classes)
    keep = ismember([R.Class], opts.classes);
    assert(any(keep), "sc:noSuchClass", "no pieces of class %s", strjoin(opts.classes,", "));
    R = R(keep);
end

R2 = sc.snapPointIntoNetwork(R,  startXY, opts.minFrag_m);
R2 = sc.snapPointIntoNetwork(R2, endXY,   opts.minFrag_m);
nPieces = numel(R2);
assert(nPieces > 0, "sc:emptyNetwork", "no road pieces to route over");

% ---- one node per real junction: every piece endpoint, coincident ones merged ----
ends = zeros(2*nPieces, 2);
for i = 1:nPieces
    ends(2*i-1,:) = R2(i).Centers(1,:);
    ends(2*i,  :) = R2(i).Centers(end,:);
end
nodeXY = zeros(0,2);
nodeOf = zeros(2*nPieces,1);
for i = 1:size(ends,1)
    if isempty(nodeXY)
        nodeXY(1,:) = ends(i,:);  nodeOf(i) = 1;  continue
    end
    d = vecnorm(nodeXY - ends(i,:), 2, 2);
    [dm, j] = min(d);
    if dm <= opts.nodeTol_m
        nodeOf(i) = j;
    else
        nodeXY(end+1,:) = ends(i,:);   %#ok<AGROW>
        nodeOf(i) = size(nodeXY,1);
    end
end
nNode = size(nodeXY,1);

[~, startNode] = min(vecnorm(nodeXY - startXY, 2, 2));
[~, endNode]   = min(vecnorm(nodeXY - endXY,   2, 2));
assert(norm(nodeXY(startNode,:) - startXY) <= opts.nodeTol_m + opts.minFrag_m, ...
    "sc:startNotSnapped", "startXY did not land on a real graph node after snapping");
assert(norm(nodeXY(endNode,:) - endXY) <= opts.nodeTol_m + opts.minFrag_m, ...
    "sc:endNotSnapped", "endXY did not land on a real graph node after snapping");

% ---- adjacency: for each node, the pieces that touch it and which way ----
adj = cell(nNode,1);
for i = 1:nPieces
    a = nodeOf(2*i-1);  b = nodeOf(2*i);
    adj{a}(end+1,:) = [b, i, 0];   % traverse piece i FORWARD, as stored
    adj{b}(end+1,:) = [a, i, 1];   % traverse piece i FLIPPED
end

% ---- Dijkstra, weighted by each piece's own real Length ----
dist = inf(nNode,1);      dist(startNode) = 0;
prevNode  = zeros(nNode,1);
prevPiece = zeros(nNode,1);
prevFlip  = false(nNode,1);
visited   = false(nNode,1);

for iter = 1:nNode
    u = 0;  best = inf;
    for v = 1:nNode
        if ~visited(v) && dist(v) < best, best = dist(v);  u = v;  end
    end
    if u == 0 || u == endNode, break; end
    visited(u) = true;
    rows = adj{u};
    for r = 1:size(rows,1)
        v = rows(r,1);  pIdx = rows(r,2);  flip = rows(r,3);
        w = R2(pIdx).Length;
        if dist(u) + w < dist(v)
            dist(v) = dist(u) + w;
            prevNode(v) = u;  prevPiece(v) = pIdx;  prevFlip(v) = flip;
        end
    end
end
assert(isfinite(dist(endNode)), "sc:noRoute", ...
    "no path exists between the two points on this network (%d nodes, %d pieces)", nNode, nPieces);

% ---- reconstruct the piece sequence, start to end ----
seq = [];  flips = [];
v = endNode;
while v ~= startNode
    seq   = [prevPiece(v), seq];    %#ok<AGROW>
    flips = [prevFlip(v),  flips];  %#ok<AGROW>
    v = prevNode(v);
end

path_m = zeros(0,2);
for k = 1:numel(seq)
    p = R2(seq(k)).Centers;
    if flips(k), p = flipud(p); end
    if isempty(path_m)
        path_m = p;
    else
        path_m = [path_m; p(2:end,:)];   %#ok<AGROW>
    end
end
pieces = seq;

d = vecnorm(diff(path_m),2,2);
assert(all(d > 0), "sc:dupPoint", "route contains a zero-length step");
end
