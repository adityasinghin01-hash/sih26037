function W = s3world()
%S3WORLD  THE GALLI - the real road, for the 2D live demo only.
%
%   Deliberately leaner than sc.s1world: this demo needs a path the planner
%   can drive and a width the corridor math can narrow, not tree counts or a
%   reveal-distance mechanic - S3 has no forest and no sight-line hero shot.
%   "Less, but properly built" (matlab/DEMO-README.md's own standard).
%
%   REAL VS CHOSEN, SAID PLAINLY - same discipline sc.s1geom and the demoNRoute
%   files use.
%
%   REAL, MEASURED, NOT MINE TO CHANGE:
%     - centre (-155,-476), radius per world/scenarios/S3-THE-GALLI.md
%     - the road itself: sc.localRoads([-155 -476], 320) -> sc.routeFrom(...,
%       'classes',"residential") from (8.3,-362.9) to (-144.9,-709.0), 4 real
%       OSM pieces (lengths 199.4/44.6/56.8/81.3 m)
%     - four of the spec's seven side lanes reproduce almost exactly from the
%       same OSM export: 105.6 m @ 17 deg (spec: 106 @ 17), 277.1 m @ 154 deg
%       (spec: 278 @ 154), 105.3 m @ 313 deg (spec: 105 @ 313), 64.6 m @ 133
%       deg (spec: 65 @ 133) - none of those side lanes are used by this demo,
%       they are recorded here only as the evidence that this is the right
%       real location, not a stand-in
%
%   CHOSEN BY THIS FILE, DISCLOSED AS SUCH:
%     - route length: this real path measures 382.2 m. The spec states 416 m.
%       Checked twice, against two different real candidate endpoints (a
%       shorter one snapping to 382.2 m, a longer one reaching 488.4 m, 17%
%       OVER) - 382.2 m is the closer real match, not a compromise, and nothing
%       closer to 416 m exists as one connected real path in this map export.
%       Aditya's call, 10 Sep 2026: use the real 382.2 m rather than keep
%       searching. The spec's own chainage table (0-90 normal, ... 300-416
%       widens) is kept at its written stations; the practical effect is that
%       the final "lane widens, approaches the main road" stretch is
%       foreshortened to 300-382 m, not 300-416 m. Nothing before 300 m moves.
%     - width: 4.5 m base (spec: "tagged residential, 4.5 m where it is open").
%       The narrowing sequence (buildings stepping forward, the buttress, the
%       squeeze, the drain) is NOT a property of this road object - it is
%       authored as corridor-narrowing hazards, the exact mechanism
%       demo2Route.m already uses for its own shoulder-crumbling entries, so
%       demo_play.m's core loop needs no new concept to drive here.

R = sc.localRoads([-155 -476], 320);
centre = sc.routeFrom(R, [8.3 -362.9], [-144.9 -709.0], 'classes', "residential");
P = sc.path(centre, 1.0);
assert(abs(P.Len - 382.2) < 1.0, "sc:s3worldLen", ...
    ['S3 route length has drifted to %.2f m (expected ~382.2 m) - every station ' ...
     'number in demo3Route.m is keyed to this measured length.'], P.Len);

W.Path  = P;
W.Width = 4.5;             % m, S3-THE-GALLI.md: "tagged residential, 4.5 m where it is open"
end
