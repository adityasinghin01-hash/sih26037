function drawForest(ax, W, Sty, opts)
%DRAWFOREST  S1's real tree forest (W.Trees), in the demo's locked style.
%   Part of Phase 2 of the checkpoint-demo build (11 Sep 2026) - the
%   viewer previously had no way to draw W.Trees at all (a different,
%   older numeric-matrix format than W.TreeScatter, which
%   sc.plannerView's drawWorldFurniture already handles).
%
%   ONE vectorised scatter call for all trees, not a per-tree patch loop -
%   measured necessary at 2200 trees; a loop of individual patch() calls
%   is the slow path in MATLAB, scatter() is not.
%
%   Crowns are drawn at their REAL drawn position - trunk XY plus the
%   lean offset (W.Trees columns 10-11, offx/offy) s1world.m already
%   computes for the canopy-cover claim - not at the trunk, which would
%   silently discard the lean and under-represent the roadside canopy.
%
%   opts.Centre / opts.Radius (both optional): windows to a local area by
%   simple XY distance - no sc.path lookups, so this is cheap to call
%   from an animation loop that already knows the ego's world position,
%   not just a static render. Omit both to draw every tree.

arguments
    ax
    W struct
    Sty struct
    opts.Centre (1,2) double = [NaN NaN]
    opts.Radius (1,1) double = Inf
end

if isempty(W.Trees), return; end
T = W.Trees;
cx = T(:,1) + T(:,10);   % drawn crown centre, not the trunk
cy = T(:,2) + T(:,11);
cr = T(:,4);

if all(isfinite(opts.Centre)) && isfinite(opts.Radius)
    keep = hypot(cx - opts.Centre(1), cy - opts.Centre(2)) <= opts.Radius;
    cx = cx(keep); cy = cy(keep); cr = cr(keep);
end
if isempty(cx), return; end

% scatter's marker size is in POINTS^2 (area), not data units - crownR is metres of
% radius, so this needs a data-to-points conversion. Derived from opts.Radius when
% given (the caller's own intended view width) rather than the axes' CURRENT xlim -
% reading xlim only works once the axes already reflects its final view, and this is
% meant to be called as content is being built up, before that's necessarily true.
% Falls back to xlim for an unwindowed (whole-map) call, where there is no Radius.
pos = get(ax,'Position'); fig = ancestor(ax,'figure');
figPx = get(fig,'Position');
if isfinite(opts.Radius)
    dataWidth = 2*opts.Radius;
else
    xl = xlim(ax); dataWidth = max(xl(2)-xl(1), eps);
end
pxPerUnit = (figPx(3)*pos(3)) / dataWidth;
ptPerUnit = pxPerUnit * 72/96;   % MATLAB points, not screen pixels
sz = max(4, (cr .* ptPerUnit).^2);

scatter(ax, cx, cy, sz, 'filled', ...
    'MarkerFaceColor', Sty.ForestFill, 'MarkerFaceAlpha', Sty.ForestAlpha, ...
    'MarkerEdgeColor', 'none');
end
