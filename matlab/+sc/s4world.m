function W = s4world()
%S4WORLD  THE HIGHWAY - the interchange, for the 5-scenario density
%   initiative (11 Sep 2026). Nothing existed for S4 before this - zero
%   planner risk, this is a static-world+density-only build, same discipline
%   as sc.s1world/sc.s3world's own additions this session.
%
%   REAL VS CHOSEN, SAID PLAINLY:
%   REAL, measured off sc.localRoads([130 -800], 235) - S4-THE-HIGHWAY.md's
%   own centre and radius:
%     - the ego's own carriageway: chained from the real trunk/trunk_link
%       pieces, (128.0,-1003.2) to (42.0,-699.7), classes ["trunk"
%       "trunk_link"] - a REAL, CONNECTED 411.7 m path. The written script
%       implies a longer drive (71 s of action) but does not state a route
%       length the way S1's cow-station or S3's chainage table do, so there
%       is no written number this could disagree with - 411.7 m is simply
%       what chaining the real trunk network here actually measures.
%     - 25 real OSM pieces total inside the 235 m circle, 2821.8 m - close
%       to S4's own "2848 m in 16 pieces" (OSM's own clipping/classification
%       splits some of the written 16 into more fragments; the real total
%       is the closer match, kept rather than forced to 16)
%   CHOSEN, DISCLOSED, AND SCOPED DOWN FROM THE FULL WRITTEN FURNITURE LIST:
%     - this is a flat TOP-DOWN 2D schematic (sc.plannerView's own "the
%       plain one is the truth"). A flyover and an at-grade road look
%       IDENTICAL in plan view - there is no elevation channel to draw a
%       deck, a pier or a vertical clearance into, so none of that is
%       modelled as geometry. It is real and it matters for the eventual
%       3D city; it is invisible to this view by construction, not omitted
%       by oversight.
%     - the median is drawn as one representative strip (reusing the same
%       band primitive W.Drains already draws for S1/S3's drains) on ONE
%       side of the ego's own carriageway. The OPPOSITE carriageway is not
%       modelled as a separate driven road - the ego never drives it, and
%       a second full parallel road is a bigger build than this pass scopes
%     - gantry signs, cautionary signs, km stones, hoardings, the W-beam
%       crash barrier and median planting (all named in S4-THE-HIGHWAY.md)
%       are NOT built as distinct geometry this pass - disclosed as
%       omitted, the same call already made for S1's litter/dung/puddles:
%       real, written, and not load-bearing for a density/placement check

R = sc.localRoads([130 -800], 235);
centre = sc.routeFrom(R, [128.0 -1003.2], [42.0 -699.7], 'classes', ["trunk" "trunk_link"]);
P = sc.path(centre, 1.0);
assert(P.Len > 300, "sc:s4worldLen", "S4 route measured only %.1f m", P.Len);

W.Path  = P;
W.Width = 7.0;              % one carriageway, 2x3.5m (IRC:86)

% ---------------------------------------------------------------- the median
W.Drains = struct('S0',0,'S1',P.Len,'Lateral', W.Width/2 + 2.5, 'Width',5.0, ...
    'Label',"raised median, 5.0m (opposite carriageway not modelled)");

% ---------------------------------------------------------------- buildings, 41
% S4's own roll call: 18 single-storey commercial (service roads), 9 two-storey
% (shop+rooms), 2 three-storey, 5 tin sheds, 1 toll-plaza office shell, 1 police
% check post, 4 outlying houses, 1 mobile tower. All chosen to the OUTER side
% (away from the median), matching "along the service roads" - the median side
% is the opposite carriageway, nothing is built there.
NEARSET = 6.0;    % highway shoulder is wider than S1's rural one - deep frontage aprons
mk = @(typ,s,side,w,d,st,lbl) struct('Type',string(typ),'Station',double(s), ...
    'Lateral', -side*(NEARSET+w/2), 'Width',double(w),'Depth',double(d), ...
    'Storeys',double(st),'Label',string(lbl));
rng(26037);
W.Buildings = struct('Type',{},'Station',{},'Lateral',{},'Width',{},'Depth',{}, ...
    'Storeys',{},'Label',{});
% PHASE A FIX, 11 Sep 2026: every group below originally used side=1 (or -1)
% UNCONDITIONALLY for every member - 36 of 41 buildings landed on one side of the road,
% crammed enough that 9 pairs actually overlapped, caught by sc.checkFurnitureOverlaps.
% This is the same class of bug s1world/s3world hit, one level worse (no alternation at
% all, not just insufficient spacing). Fixed at the actual cause - alternating sides -
% not just papered over by the resolver below, though that still runs as a safety net.
ss = linspace(P.Len*0.05, P.Len*0.95, 27);              % 18 commercial + 9 two-storey = 27
for i = 1:27
    side = 2*mod(i,2) - 1;
    if i <= 18
        W.Buildings(end+1) = mk("house1", ss(i), side, 4.5+3.0*rand, 8.0, 1, ""); %#ok<AGROW>
    else
        W.Buildings(end+1) = mk("house2", ss(i), side, 5.0+2.5*rand, 7.0, 2, ""); %#ok<AGROW>
    end
end
ss2 = linspace(P.Len*0.10, P.Len*0.90, 2);
for i = 1:2
    W.Buildings(end+1) = mk("house3", ss2(i), 2*mod(i,2)-1, 6.0, 7.5, 3, ""); %#ok<AGROW>
end
ss3 = linspace(P.Len*0.15, P.Len*0.85, 5);
for i = 1:5
    W.Buildings(end+1) = mk("shed", ss3(i), 2*mod(i,2)-1, 3.2, 5.0, 1, ""); %#ok<AGROW>
end
W.Buildings(end+1) = mk("shop", P.Len*0.35, -1, 8.0, 6.0, 1, "toll-plaza style office shell");
W.Buildings(end+1) = mk("wall", P.Len*0.55, -1, 3.0, 3.0, 0, "police check post, barrier + sandbags");
ssOut = linspace(P.Len*0.20, P.Len*0.80, 4);
for i = 1:4
    W.Buildings(end+1) = mk("house1", ssOut(i), 2*mod(i,2)-1, 6.0, 6.0, 1, "outlying, in haze"); %#ok<AGROW>
end
W.Buildings(end+1) = mk("shed", P.Len*0.65, -1, 4.0, 4.0, 0, "mobile tower base, 40m lattice");
assert(numel(W.Buildings) == 41, "sc:s4buildingCount", ...
    "%d buildings built, S4's own spec states 41", numel(W.Buildings));
W.Buildings = sc.resolveFurnitureOverlaps(W.Buildings);
nOnRoad = 0;
for k = 1:numel(W.Buildings)
    if abs(W.Buildings(k).Lateral) - W.Buildings(k).Width/2 < W.Width/2 + 1.0
        nOnRoad = nOnRoad + 1;
    end
end
assert(nOnRoad == 0, "sc:s4buildingOnRoad", "%d buildings sit too close to the carriageway", nOnRoad);

[nOverlap, overlapWorst] = sc.checkFurnitureOverlaps(W.Buildings, []);
assert(nOverlap == 0, "sc:s4furnitureOverlap", "%d furniture overlaps - worst: %s", ...
    nOverlap, overlapWorst);

% ---------------------------------------------------------------- signs, Phase B fix pass
% "SIGNAGE AND FURNITURE - the thing that makes a highway read as a highway" - S4's own
% words, and none of it existed before this pass. CHOSEN/DISCLOSED: the written spec gives
% chainages (gantry at 120, cantilever sign at 380) against ITS OWN chainage reference,
% which this file's real 411.7m route has no established correspondence to (unlike S1/S3,
% which both anchor to a real, measured station via the cow/junction/squeeze). Used here
% as direct real-route stations - close enough for a schematic, disclosed as approximate
% rather than claimed exact. The three cautionary signs have no written station at all
% ("merge ahead, lane narrows, pedestrian crossing" - descriptive only), placed near where
% this file's own density layer (sc.s4density) already put the matching moving traffic.
W.Signs = struct('Type',{},'Station',{},'Lateral',{},'Label',{});
W.Signs(end+1) = struct('Type',"gantry",'Station',120,'Lateral',0, ...
    'Label',"overhead gantry, destinations in Devanagari+English");
W.Signs(end+1) = struct('Type',"hoarding",'Station',380,'Lateral',NEARSET+3, ...
    'Label',"cantilever direction sign");
W.Signs(end+1) = struct('Type',"cautionary",'Station',P.Len*0.08,'Lateral',NEARSET, ...
    'Label',"merge ahead");
W.Signs(end+1) = struct('Type',"cautionary",'Station',P.Len*0.38,'Lateral',NEARSET, ...
    'Label',"lane narrows");
W.Signs(end+1) = struct('Type',"cautionary",'Station',P.Len*0.63,'Lateral',NEARSET, ...
    'Label',"pedestrian crossing");
kmS = linspace(P.Len*0.2, P.Len*0.8, 3);
for i = 1:3
    W.Signs(end+1) = struct('Type',"kmstone",'Station',kmS(i),'Lateral',-(NEARSET+1), ...
        'Label',""); %#ok<AGROW>
end
hdS = linspace(P.Len*0.10, P.Len*0.90, 5);
for i = 1:5
    side = 2*mod(i,2) - 1;
    W.Signs(end+1) = struct('Type',"hoarding",'Station',hdS(i),'Lateral',side*(NEARSET+5), ...
        'Label',""); %#ok<AGROW>
end
% NOT built this pass, disclosed rather than silently skipped: the W-beam crash barrier
% along the bridge approaches/median openings. The median band already occupies that
% visual space; a genuinely separate barrier object is a smaller remaining gap.

% ---------------------------------------------------------------- vegetation, Phase E
% "Median planting: gulmohar and amaltas alternating, 11 trees at ~36m" - 411.7/36 = 11.4,
% so the real number and the real spacing agree with each other, not forced. Planted on
% the median band itself. "Eucalyptus double row on the outer shoulder, 6m spacing, 22m
% tall" - a real, bounded number, built in full (both rows, real spacing), not thinned for
% convenience - this is what "vegetation, not a token instance" from the original ask
% actually looks like where the spec gives a real count to build to.
medS = 0:36:P.Len;
W.Trees = struct('Station',{},'Lateral',{},'CrownR',{},'Species',{});
for s = medS
    W.Trees(end+1) = struct('Station',s,'Lateral',W.Width/2+2.5,'CrownR',3.5, ...
        'Species',"gulmohar_amaltas"); %#ok<AGROW>
end
eucS = 0:6:P.Len;
for s = eucS
    W.Trees(end+1) = struct('Station',s,'Lateral', NEARSET+8.0,'CrownR',2.2, ...
        'Species',"eucalyptus"); %#ok<AGROW>
    W.Trees(end+1) = struct('Station',s,'Lateral',-(NEARSET+8.0),'CrownR',2.2, ...
        'Species',"eucalyptus"); %#ok<AGROW>
end

fprintf('[S4 world] route %.1f m (real trunk chain) | %d buildings (spec 41) | %d signs | %d trees (%d median @ 36m, %d eucalyptus @ 6m double row)\n', ...
        W.Path.Len, numel(W.Buildings), numel(W.Signs), numel(W.Trees), numel(medS), 2*numel(eucS));
end
