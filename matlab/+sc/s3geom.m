function g = s3geom()
%S3GEOM  THE SQUEEZE ARITHMETIC, IN ONE PLACE - same discipline as sc.s1geom.
%
%   world/scenarios/S3-THE-GALLI.md, t=22.6: "Free width measured: 1.95 m.
%   Ego is 1.70 m wide, 1.90 m with mirrors. Margin: 25 mm each side [unfolded].
%   ... Fold the mirrors - 1.70 m, margin 125 mm each side."
%
%   This file does not invent those numbers - it recomputes the two margins
%   from the free width and the two ego widths, and asserts they match the
%   spec's own stated 25 mm / 125 mm, so a future change to either number is
%   caught here rather than discovered live.
%
%   g.FreeWidth_m       the squeeze's clear width (spec: scooter 0.72 m into
%                       the road + a 0.35 m drain lip leave 1.95 m clear)
%   g.EgoWidthMirrors_m 1.90 m, mirrors out
%   g.EgoWidthFolded_m  1.70 m, mirrors folded (S4 MirrorsFolded's ~200 mm)
%   g.MarginMirrors_m   each side, mirrors out
%   g.MarginFolded_m    each side, mirrors folded

g.FreeWidth_m       = 1.95;
g.EgoWidthMirrors_m = 1.90;
g.EgoWidthFolded_m  = 1.70;
g.MarginMirrors_m   = (g.FreeWidth_m - g.EgoWidthMirrors_m) / 2;
g.MarginFolded_m    = (g.FreeWidth_m - g.EgoWidthFolded_m)  / 2;

assert(abs(g.MarginMirrors_m - 0.025) < 1e-9, "sc:s3geomMirrors", ...
    "margin with mirrors out is %.4f m, spec says 25 mm each side", g.MarginMirrors_m);
assert(abs(g.MarginFolded_m - 0.125) < 1e-9, "sc:s3geomFolded", ...
    "margin with mirrors folded is %.4f m, spec says 125 mm each side", g.MarginFolded_m);
end
