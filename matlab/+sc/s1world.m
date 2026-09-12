function W = s1world(opts)
%S1WORLD  The static world of S1 - THE FOREST CATTLE CROSSING.
%
%   Road: the REAL Najibabad tertiary centreline from map/matlab_roads.csv, with the
%   measured (+35.0, -100.0) offset removed so it lands in the same frame as everything
%   else. 7.0 m carriageway (S0 s4), 1.2 m earthen shoulders, no kerb.
%
%   Setting: forest to both shoulders, with a CLEARED CORRIDOR and one clearing on the
%   left where the cattle emerge.
%
%   WHY FOREST IS AN UPGRADE, NOT A SIMPLIFICATION
%   The written script needs the cow to become visible at ~42 m, and used kans grass and
%   a fodder stack to hide it. The TREELINE plus the road's own curvature does that job
%   by GEOMETRY instead. The reveal is computed by ray-marching the sight line
%   (sc.path/sightDistance), so it is a real constraint the planner meets, not a timer.
%
%   Returns W with:
%     .Path      sc.path      the route, 1 m stations, station/lateral frame
%     .Width     double       carriageway, m
%     .Trees     Nx5          [x y trunkR crownR height]
%     .Occluders Nx3          [x y radius] - what actually blocks a sight line
%     .CowStation, .RevealDistance, .Clearing

arguments
    % 6.0, not 9.5. REF-06 s4, with open ground: "Verge grass runs 2-3 m and then the
    % TREE MASS STARTS - no transition, no mulch ring, no bed." A 9.5 m corridor leaves
    % a 6 m verge, which is a mown park edge, not a forest road - and it was why the
    % measured canopy cover was 24 % against S1's written 38 %. 6.0 m puts the first
    % trunk 2.5 m beyond the 3.5 m carriageway edge, which is the written verge.
    opts.CorridorHalf (1,1) double = 6.0     % no trunk closer than this to the centreline
    opts.NTrees       (1,1) double = 2200
    opts.Seed         (1,1) double = 26037
    opts.Reveal       (1,1) double = 42.0    % written S1: "visible at 42 m"
end

% ---------------------------------------------------------------- the real road
R = sc.localRoads([-280 450], 350);
centre = sc.routeFrom(R, [-496.1 654.1], [-12.8 300.2], 'classes', "tertiary");
W.Path  = sc.path(centre, 1.0);
W.Width = 7.0;                      % tertiary, S0 s4. ASSERTED against the table below.
W.Shoulder = 1.2;                   % S1: "Earthen shoulders 1.2 m"

% NOTHING SOLID MAY STAND ON THE DRIVABLE CARRIAGEWAY, AND NOTHING DID CHECK.
% S2 has enforced this since a render showed 46 fence posts and 315 grass tufts
% standing on a road the planner drives (REF-17 s15a) - it has `onAnyRoad` in seven
% places. S1 NEVER RECEIVED THE SAME RULE. Measured: 6 masses on the tarmac, and the
% ego drove straight through them, which is exactly what Aditya saw in the film.
% Overhang onto the SHOULDER is deliberately still allowed: S1 says the kans grass
% grows "right up to the tarmac and overhanging it", and that is true of a real verge.
% What may not happen is a solid mass inside the 7.0 m the vehicle drives on.
ROAD_CLEAR = W.Width/2 + 0.15;      % 3.65 m - carriageway edge plus a 150 mm margin
% sc.s1render draws each understorey lobe at offset 0.55r + radius 0.92r, AND THEN
% LUMPS THE MESH, which pushes the surface out by a further WALL_LUMP/2 = 27.5 %:
%     0.55 + 0.92 x 1.275 = 1.723
% so the CLAIM has to be divided by that or the DRAWING lands on the road while the
% claim looks clean. This is the drawn-vs-claimed split that has caught this project
% three times now (REF-17 s18, s19e) - and a fourth: 1.47 was written here first,
% because I costed the offset and the radius and FORGOT THE LUMP, and s1render's
% independent assert caught it on the very next render. That assert is the only
% reason this number is right, so it stays.
UND_DRAW = 1.73;
W.RoadClear = ROAD_CLEAR;  W.UndDraw = UND_DRAW;

w = R(find([R.Class]=="tertiary",1)).Width;
assert(abs(w - W.Width) < 1e-3, "sc:s1width", ...
    "the map says the tertiary is %.3f m, this world builds %.3f m", w, W.Width);

% ---------------------------------------------------------------- the clearing
% Where the cattle come from. Left side, written S1: the herd emerges from a field gap.
W.CowStation = 300.0;                       % written: the cow steps out at 300 m
% THE HOLE IN THE FOREST IS NOT A RECTANGLE. It was punched out of the tree
% distribution as an axis-aligned box in (station, offset), and from the corridor
% camera that is exactly what it looked like: a pale quadrilateral with straight sides
% laid on the forest floor. s1render can draw as wavy an edge as it likes inside a
% rectangular hole and the RECTANGLE still reads, because the trees are what draw it.
% So the hole itself wanders - the same two-harmonic wobble the drawn edge uses, which
% is what keeps the two agreeing - and clearingHas() is the single test both use.
W.Clearing   = struct('S',[W.CowStation-16, W.CowStation+22], 'E',[10 46]);
W.ClearingIn = @(s,e) clearingHas(W.Clearing, s, e);

% THE LOD CROWN-WIDTH FIX REF-17 s17d ASKED FOR, DONE PROPERLY THIS TIME. The near LOD
% (the Blender-authored neem) draws its crown at TREE.CrownR*2 across; the far-LOD
% primitive below used to draw its own at cr = (0.34-0.52)*h - MEASURED 2.04x wider,
% invisible under haze, plain in the overhead corridor shot. Tying cr to the authored
% asset's own proportion fixes that - but it roughly HALVES cr, and canopy cover is a
% disc-AREA quantity, so a village-end density boost (below) is now genuinely load-
% bearing, not decorative: measured, the OLD build's "village exceeds open" cover
% margin (44.90% vs 38.01%, both at the OLD crown size) came from village density
% being only 3.7% higher than open (3.71 vs 3.58 trees/m) - i.e. it was never an
% engineered rise toward S1's written 55%, it was luck in one random realisation, and
% halving cr was enough to flip it (sc:s1coverDir fired at 34.9% vs 38.0%). Both
% asserts are on the RIGHT side of the risk: catching a 2.04x LOD mismatch and an
% un-engineered "rises toward the village" claim in the same afternoon.
TREE_CR = sc.treeAsset().CrownR;
VILLAGE_START = W.Path.Len*0.78;    % SAME boundary as the lop zone and OPEN_END below -
                                     % one number, used at the point of scatter as well
                                     % as at the point of measurement, so density and
                                     % cover cannot silently disagree about where
                                     % "the village end" starts.

% ---------------------------------------------------------------- the forest
rng(opts.Seed);
T = zeros(0,9);   % [x y trunkR crownR height e understoreyR formCode bearing]
                  % columns 10-12 are added below: crown offset x, y, and clearance height
guard = 0;
while size(T,1) < opts.NTrees && guard < opts.NTrees*40
    guard = guard + 1;
    s = rand*W.Path.Len;
    % The corridor edge WANDERS. A constant CorridorHalf puts every nearest trunk on one
    % dead-straight line and the treeline reads as a fence; the wave is upward-only so
    % the cleared-corridor assertion below still holds exactly.
    ch = opts.CorridorHalf + 4.0*(0.5 + 0.5*sin(s/29.0 + 1.7*sign(randn)));
    % THE FOREST HAS TO BE A FOREST FROM EVERY ANGLE. The first version put the stand
    % in a 36 m band and left bare ground to the horizon beyond it. From the driver's
    % seat that is invisible - the near trees cover it - but from the clearing camera
    % the wood plainly ended 45 m out and the world behind it was empty. rand^1.6
    % keeps the density high at the roadside and tails it out to about 105 m.
    e  = (ch + 95*rand^1.6) * sign(randn);
    % the clearing is a hole in the forest, and it is the reason the herd is there
    if clearingHas(W.Clearing, s, e)
        continue
    end
    % CLUMPING - REF-11 s5, and it is the item REF-17 s13 left outstanding.
    % "Feed a Noise Texture into DENSITY and into SCALE... the noise texture allows you
    % to form these really organic and realistic clumps of plants, just like in real
    % life." The scatter here was a uniform spray: rand in station, rand^1.6 in offset,
    % which gives an even wash with no clumps and no real holes. REF-04 s6 says the
    % same thing from the other direction - crowded and empty AT THE SAME TIME, and
    % "uniform spread is the tell".
    % The noise is a sum of three incommensurate sines in (s,e), so it has no grid and
    % no period a viewer can find, and it is DETERMINISTIC in position - the same field
    % then drives scale below, which is what makes a clump read as a thicket of big
    % trees rather than as more small ones.
    nz = 0.5 + 0.5*( 0.55*sin(s/23.0 + e/31.0) ...
                   + 0.30*sin(s/9.7  - e/13.3 + 2.1) ...
                   + 0.15*sin(s/4.3  + e/5.9  - 1.2) );
    % S1 TREES SAYS COVER "RISES TOWARD THE VILLAGE END", AND NOTHING BEFORE THIS
    % ENGINEERED THAT - it fell out of the lopping zone and whatever the clumping
    % noise happened to do in one random realisation (REF-17 s17d, honest about it:
    % "not solved for... checked for direction and reported"). MEASURED: under the
    % OLD crown size the village's density edge over the open stretch was only 3.7 %
    % (3.71 vs 3.58 trees/m) - enough for a 6.9-point cover gap by luck, not enough
    % once the LOD fix below roughly halves every crown's area. Ramped, not a step at
    % VILLAGE_START, so the treeline does not visibly thicken at a wall.
    villageBoost = 0;
    if s > VILLAGE_START
        villageBoost = 0.55 * (s - VILLAGE_START) / (W.Path.Len - VILLAGE_START);
    end
    if rand > 0.22 + 1.15*nz^2 + villageBoost, continue; end   % NOISE INTO DENSITY
    xy = W.Path.at(s, e);
    % NOISE INTO SCALE, the second half of REF-11 s5. A clump of trees is not just more
    % trees - the ones in it are bigger, because that is where the ground favoured them.
    sc_ = 0.78 + 0.44*nz;
    h  = (9 + rand*7) * sc_;                % 9-16 m, sal/teak scale, clumped
    tr = (0.16 + rand*0.14) * sc_;          % trunk radius
    % CROWN RADIUS WAS ABOUT HALF WHAT THE REFERENCES SAY, and it is why the far
    % stand rendered as a field of pale torpedoes. It was 1.8-3.4 m of RADIUS, i.e.
    % 3.6-6.8 m of crown across a 9-16 m tree. REF-04 s7 and REF-06 s2 both give neem
    % a crown of 15-20 m on old free-standing specimens, and REF-04 s7's interlock
    % rule needs crowns to MERGE below 10 m spacing - which a 3.6 m crown cannot do at
    % any spacing this forest uses. Tied to height instead, at 0.34-0.52 h, so a 12 m
    % tree carries an 8-12 m crown and the stand can actually close over itself.
    % TIED TO THE AUTHORED TREE'S OWN PROPORTION - the two LODs now agree on what a
    % crown is, so the swap between them is invisible instead of a step from small
    % detailed trees to big blobs. +-15 % kept for the same reason the old range had
    % spread at all: identical crowns read as a plantation, not a forest.
    cr = TREE_CR * h * (0.85 + 0.30*rand);
    % UNDERSTOREY - and it exists because the crowns provably do NOT close the stand.
    % s1render draws a far crown as a SPHERE scaled [cr cr 0.45h] centred at 0.58h, so
    % REF-17 s13's "they now start at 0.13h" is true of the sphere's POLE, which has
    % zero radius. MEASURED at the driver's eye (1.35 m): a 16 m tree contributes
    % 0.00 m of crown, a 12.5 m tree 0.17-0.32 m - less than its own trunk. The stand
    % therefore rendered as a plantation of poles with daylight behind it, which is
    % exactly what REF-06 s3 forbids: "from about 1 m up it is a solid dark wall - you
    % do not see through it and you do not see individual trunks."
    % It is the SAME error as BUG 1 (occluders drawn as domes), in a second place.
    %
    % REF-06 s4 is also the rule for WHERE it goes: "under a dense crown the ground
    % layer dies", and trunks stay visible on isolated trees. So the first rank at the
    % lit corridor edge keeps its bare trunks and the closed wall starts behind it.
    % 22 m WAS FAR TOO CONSERVATIVE AND IT LEFT A 16 m COLONNADE. The corridor edge
    % is at 6.0 m, so trees from 6 to 22 m carried bare trunks and nothing under
    % them - and that band is the whole of what the driver looks into. Rendered, the
    % left stand was a plantation of poles with a pale void behind it, which is the
    % exact defect this block exists to fix, one rank further out.
    %
    % The justification for 22 was REF-06 s4, "under a dense crown the ground layer
    % dies... trunks stay visible on isolated trees" - but OURS ARE NOT ISOLATED.
    % Measured spacing is 2.23 m median, 99 % below 10 m (REF-17 s17c), and REF-06 s3
    % is explicit about what that looks like: "a treeline is closed at the bottom -
    % from about 1 m up it is a solid dark wall, you do not see through it and YOU DO
    % NOT SEE INDIVIDUAL TRUNKS. Trunks are only visible on isolated trees."
    %
    % WHAT ACTUALLY CONSTRAINS THIS IS THE SIGHT LINE, AND IT IS NOT SYMMETRIC.
    % The line to the cow runs from the driver's eye at e = +1.75 m to her at
    % e = +4.60 m - entirely at POSITIVE e, the left. So:
    %   RIGHT (e < 0): provable from the SIGN that no mass there can cross the line,
    %     exactly the argument sc.s1render already uses for the kans grass. Filled
    %     from the corridor edge.
    %   LEFT  (e > 0): kept clear of the line by distance, with the margin sc.s1render
    %     asserts - it needs min(e) > max(radius) + 6.0, and radius tops out near
    %     3.4 m, so 10.5 m carries the proof with room to spare.
    % Either way the mass goes into W.Occluders at its real radius, so nothing is
    % drawn that the solver does not know about (REF-17 s7a).
    % AND THE WALL RADIUS IS CAPPED, which is what makes 10.5 m provable. Left at
    % cr*(0.62-0.96) it reached 8.9 m - crowns run to about 9.3 m radius (REF-04 s7,
    % 15-20 m across) - so a mass at e = 10.5 reached e = 1.6 and sat straight on the
    % sight line. sc.s1render's assert caught exactly that and it was right to.
    % Pushing the distance back out to 15 m would have restored the colonnade to buy
    % the proof; capping the radius keeps the proof AND closes the stand. It is also
    % the truer shape - the shaded mass under a tree is not as wide as its crown.
    UR_MAX = 3.2;                           % needs min(left e) > UR_MAX + 6.0 = 9.2
    ur = 0;
    if e < -(opts.CorridorHalf + 0.4) || e > 10.5
        ur = max(0, min([UR_MAX, cr*(0.62 + 0.34*rand), (abs(e)-ROAD_CLEAR)/UND_DRAW]));
    end
    % e is stored SIGNED (which side of the road) and the local road bearing is
    % stored with it. Both are needed per tree by the renderer to point a constraint
    % form along the row, and querying the path for them inside the draw loop would
    % cost two path lookups per tree PER FRAME of a film. Computed once, here.
    [~, bear] = W.Path.at(s, 0);
    T(end+1,:) = [xy(1) xy(2) tr cr h e ur 0 bear];   %#ok<AGROW>
end
W.Trees = T;

% ---------------------------------------------------------------- crown form
% REF-06 s1 IS THE GOVERNING RULE AND IT WAS NEVER APPLIED: "A tree's shape is not
% random variation on a template. It is a RECORD OF WHAT HAPPENED TO IT... Model the
% CAUSE, and the variation comes out for free and reads as true." With a hard ceiling:
% "no more than 1 in 6 trees may be the round free-standing form." Every tree in this
% forest was the round free-standing form - 100 % against a ceiling of 16.7 %.
%
% THE CAUSE IS ASSIGNED BY WHAT IS ACTUALLY NEXT TO THE TREE, not drawn from a hat,
% which is the whole point of REF-06 s5's "apply them by what is actually next to each
% tree". Two of the eight causes have NO AGENT anywhere in S1's forest and are
% therefore deliberately absent rather than sprinkled in:
%   - WIRE CUT needs an electricity run. S1's forest stretch carries none; the wires
%     are at the village end, which SPEC's "DELIBERATELY NOT BUILT" list excludes.
%   - WALL SQUEEZE needs a building within a crown's width. There are no buildings.
% Inventing either would be decoration pretending to be causation, which is the exact
% failure REF-06 s0 corrected.
FORM_FREE=1; FORM_ROADCUT=2; FORM_CROWD=3; FORM_LOP=4; FORM_VINE=5; FORM_DEAD=6;
nT = size(T,1);
NN = zeros(nT,1);
for i = 1:nT
    dd = hypot(T(:,1)-T(i,1), T(:,2)-T(i,2));  dd(i) = inf;
    NN(i) = min(dd);
end
form = repmat(FORM_CROWD, nT, 1);                 % a forest tree is a crowded tree
eT = abs(T(:,6));
% cause 2, ROAD-SIDE CLEARANCE: only the rank that actually stands at the carriageway
form(eT < opts.CorridorHalf + 3.5) = FORM_ROADCUT;
% cause 5, FODDER LOPPING: "people cut fodder NEAR SETTLEMENTS" (S1 TREES). The village
% end of this route is the high-station end, so lopping is clustered there and nowhere
% else - a lopped tree in the middle of a wood would be a lie about who lopped it.
sT = zeros(nT,1);
for i = 1:nT, sT(i) = W.Path.inverse(T(i,1:2)); end
lopZone = sT > VILLAGE_START & eT < 30;
form(lopZone & rand(nT,1) < 0.30) = FORM_LOP;
% cause 6, VINE SMOTHERING: REF-06 s5 makes it MANDATORY - "at least two per scenario.
% Nothing else looks so local." Damp and shaded, so: deep in the stand, in the clumps.
form(eT > 30 & rand(nT,1) < 0.035) = FORM_VINE;
% cause 7, DEATH/DAMAGE: S1 names one - "One dead and leafless at 190 m" - and a real
% stand carries a few more standing dead.
form(rand(nT,1) < 0.022) = FORM_DEAD;
% cause 8, FREE-STANDING, THE CAPPED ONE. Only a tree with no neighbour inside 15 m has
% actually been free to grow round (REF-04 s7: over 15 m they read as separate trees),
% and even those are capped at 1 in 6 by taking the most isolated first.
cand = find(NN > 15 & form ~= FORM_DEAD & form ~= FORM_VINE);
[~, ord] = sort(NN(cand), 'descend');
cand = cand(ord);
cap  = floor(nT/6);
form(cand(1:min(cap, numel(cand)))) = FORM_FREE;
T(:,8) = form;

% ---------------------------------------------------------------- crown displacement
% TWO REF STATEMENTS PULL OPPOSITE WAYS AND BOTH ARE TRUE - THEY ARE ABOUT DIFFERENT
% HEIGHTS, AND RECONCILING THEM IS WHAT DELIVERS THE WRITTEN CANOPY COVER.
%   REF-06 s1 cause 2: "Road-side clearance: vertical plane where the crown stops at
%     the carriageway edge. Crown is a HALF-TREE."
%   REF-06 s4:         "Crowns are flattened on the building face and PUSHED OUT OVER
%     THE ROAD", and REF-04 s7: canopy interlock is "the dappled light on the road".
% A roadside tree is cut vertically at the carriageway edge BELOW vehicle clearance -
% buses and loaded trolleys prune it - and leans OUT over the carriageway ABOVE that
% height, where nothing touches it and the light is. Model the cause and the shape
% follows, which is REF-06 s0's whole instruction.
%
% The offset lives HERE, not in the renderer. It was in sc.s1render alone, so the world
% did not know where its own crowns were: measured cover came out 0.7 % against the
% written 38 % because the measurement used trunk positions. That is the same
% drawn-versus-modelled split that hid the confetti canopy and the widened thicket.
CLEAR_H = 4.5;                        % vehicle clearance: a loaded trolley is 4.3 m
offx = zeros(nT,1);  offy = zeros(nT,1);
lean = zeros(nT,1);
isRoad = form == FORM_ROADCUT;
% lean TOWARD the corridor - phototropism, REF-06 s2: "directional lateral expansion on
% the open side", and the corridor is the only open side a forest tree here has.
% THE LEAN MAGNITUDE IS SOLVED, NOT CHOSEN - the same method as the thicket radius.
% REF-06 says a roadside crown leans toward the light and that its centre of mass is
% displaced off the trunk, but gives NO METRES for either. The sourced number is on the
% other side: S1 TREES specifies "38 % in the open, rising to 55 % at the village end",
% measured by ray-casting. So the lean is bisected until the measured open-country cover
% equals the written 38 %.
%
% TWO DOCUMENTS DISAGREE AND S1 WINS. REF-04 s7's general build target is "~62 %
% measured cover"; S1's own script says 38 %. Rule 1 - the scenario scripts ARE the
% specification - so the scenario-specific number governs its own scenario. Recorded
% because 62 % is reachable here and looks defensible until you check which document
% is talking about this road.
sg = sign(T(:,6));  sg(sg==0) = 1;
nrmx = cos(T(:,9) + pi/2);  nrmy = sin(T(:,9) + pi/2);
isRoad = form == FORM_ROADCUT;
OPEN_END = VILLAGE_START;             % SAME boundary the scatter loop's density boost
                                       % used - one source, see the lop zone too
    function c = coverFor(k, sA, sB)
        lk = zeros(nT,1);  lk(isRoad) = T(isRoad,4) .* k;
        qx = T(:,1) - sg.*nrmx.*lk;  qy = T(:,2) - sg.*nrmy.*lk;
        hit = 0; tot = 0;
        for ss = sA:2:sB
            for lat = -3.5:0.5:3.5
                xy = W.Path.at(ss, lat);  tot = tot + 1;
                if any(hypot(qx-xy(1), qy-xy(2)) < T(:,4)), hit = hit + 1; end
            end
        end
        c = 100*hit/max(tot,1);
    end
% CEILING RAISED FROM 1.2, MEASURED NEEDED: fitted to the OLD crown radius, and
% halving cr (TREE_CR fix above) means hitting the same 38 % needs proportionally
% more lean. 1.2 clipped the bisection at 33.6 %; 2.6 was enough - see [[matlab
% memory]] for the full before/after, this number is not a round guess.
lo = 0.0; hi = 2.6;
for it = 1:18
    mid = (lo+hi)/2;
    if coverFor(mid, 0, OPEN_END) < 38, lo = mid; else, hi = mid; end
end
LEAN_K = (lo+hi)/2;
lean = zeros(nT,1);  lean(isRoad) = T(isRoad,4) .* LEAN_K;
offx = -sg .* nrmx .* lean;           % minus: toward the centreline, not away
offy = -sg .* nrmy .* lean;
T(:,10) = offx;  T(:,11) = offy;  T(:,12) = CLEAR_H;
W.Trees = T;
W.ClearanceH = CLEAR_H;  W.LeanK = LEAN_K;
W.CoverOpen    = coverFor(LEAN_K, 0, OPEN_END);
W.CoverVillage = coverFor(LEAN_K, OPEN_END, W.Path.Len);

% ---------------------------------------------------------------- canopy cover
% S1 TREES: "Canopy cover over the carriageway: 38 % in the open, rising to 55 % at the
% village end. MEASURED BY RAY-CASTING, NOT ESTIMATED." So it is measured here the same
% way, against the crowns where they actually sit.
cx = T(:,1) + offx;  cy = T(:,2) + offy;
nHit = 0; nTot = 0;
for ss = 0:2:W.Path.Len
    for lat = -3.5:0.5:3.5
        xy = W.Path.at(ss, lat);  nTot = nTot + 1;
        if any(hypot(cx - xy(1), cy - xy(2)) < T(:,4)), nHit = nHit + 1; end
    end
end
W.CanopyCover = 100*nHit/nTot;
assert(abs(W.CoverOpen - 38) <= 2.0, "sc:s1cover", ...
    'open-country canopy cover solved to %.1f %%, S1 TREES specifies 38 %%', W.CoverOpen);
% The village end must be DENSER than the open, which is the direction S1 states
% (38 rising to 55). It is not solved for - it falls out of the lopping zone and the
% clumping - so it is checked for direction and reported, not asserted to a value.
assert(W.CoverVillage > W.CoverOpen, "sc:s1coverDir", ...
    ['cover at the village end is %.1f %% against %.1f %% in the open; S1 says it ' ...
     'RISES toward the village'], W.CoverVillage, W.CoverOpen);
assert(mean(form==FORM_FREE) <= 1/6 + 1e-9, "sc:s1formRound", ...
    "%.1f %% of trees are the round free-standing form; REF-06 s1 allows 1 in 6", ...
    100*mean(form==FORM_FREE));
W.FormNames = ["free-standing (round)","road cut","neighbour crowding", ...
               "fodder lopping","vine smothering","dieback"];

% ---------------------------------------------------------------- undergrowth
% A forest road is not a clean corridor: scrub and saplings grow right to the shoulder
% edge, and THAT is what hides an animal standing on the verge. Distant trunks never
% could - a sight line down a cleared corridor stays inside it. Measured first, then
% built: with trees alone the reveal was 160 m (i.e. no occlusion at all).
%
%   AN OCCLUDER MUST BE TALL ENOUGH TO BE ONE. The sight-line model here is 2-D -
%   circles in plan - which is only truthful if every circle is a solid mass over the
%   whole height the sight line occupies. That line runs from the driver's eye at
%   1.35 m (a 1.50 m hatchback, sc.meshes "car") to the top of the zebu, so it never
%   rises above the zebu's height. Every occluder therefore carries HFULL, the height to
%   which it is at FULL radius, and HFULL >= 1.58 m is asserted below and drawn by
%   sc.s1render. Found by rendering the world and looking at it: the first version drew
%   the undergrowth as domes 0.8-1.8 m tall and the cow was plainly visible at 60 m
%   while this model called it blocked.
% DERIVED FROM THE MESH, never retyped. When the zebu was rebuilt from 1.43 m to
% 1.46 m this number had to move with it, and a hardcoded 1.58 would have gone on
% asserting a sight line 30 mm shorter than the animal that has to be hidden behind it.
[~, zdim] = sc.meshes("zebu");
HFULL_MIN = zdim(3) + 0.15;             % cow top + margin
% UNDERGROWTH CLUMPS, it does not form a hedge. The first version put a bush every
% 2.2 m with flat 72 % probability and rendered a continuous green wall to both
% shoulders for 610 m - which is not what a forest verge looks like and, worse, made
% every stretch of the road equally occluded. A slow wave along the station, different
% on each side, gives runs of dense scrub separated by real gaps.
U = zeros(0,4);                         % [x y radius hFull]
for s = 0:2.2:W.Path.Len
    for sgn = [-1 1]
        g = 0.5 + 0.35*sin(s/17.0 + 2.1*sgn) + 0.15*sin(s/6.1 - 1.1*sgn);
        if rand > max(0, 1.06*g - 0.20), continue; end
        e = sgn*(W.Shoulder + W.Width/2 + 0.3 + rand*1.9);      % 5.0-6.9 m out
        if sgn > 0 && clearingHas(W.Clearing, s, e), continue; end
        xy = W.Path.at(s, e);
        % squared, so most bushes are small and a few are large - a flat distribution
        % renders as a row of identical capsules
        %
        % AND THE RADIUS IS NOW DRAWN AGAINST THE HEIGHT, WHICH IS WHAT MADE THEM
        % SILOS. It ran to 0.55 + 1.75 = 2.30 m - a clump 4.60 m ACROSS - while the
        % full-radius section is only hFull tall, i.e. about 2.0 m. That is an
        % aspect of 2.3:1 WIDE, and the widest clumps rendered as smooth-sided
        % cylinders with a crumpled cap: read off the render, four of them in a row
        % on the right verge looking exactly like grain silos.
        %
        % It cannot be fixed in the renderer, and that is the point. The silhouette
        % BELOW hFull is the promise the 2-D sight model relies on (REF-17 s7a), so
        % it is the one part of the shape the renderer may not perturb - pulling it
        % in is BUG 1 (drawn smaller than claimed), pushing it out is BUG 2 (mass
        % the solver is blind to). A clump that is wider than it is tall is
        % therefore a machined cylinder BY CONSTRUCTION, whatever the renderer does
        % above it. The cure has to be here, in the shape that gets claimed.
        %
        % Drawn height is GZ + 1.55*(hFull - GZ) = 2.69-3.39 m (the lathe profile in
        % sc.s1render tops out at 1.55). Radius is capped so the widest clump is
        % never wider than the shortest one is tall, and that is ASSERTED below
        % rather than left to the arithmetic staying true when someone edits it.
        % the lobes drawn on a bush are asserted to stay INSIDE this radius
        % (sc:s1rScrubWidens), so capping the claim here is enough for the drawing
        rS = min(0.42 + 0.95*rand^2, abs(e) - ROAD_CLEAR);
        U(end+1,:) = [xy(1) xy(2) rS, HFULL_MIN+0.02+rand*0.45]; %#ok<AGROW>
    end
end
W.Scrub = U;
% ASPECT, ASSERTED. sc.s1render's bush lathe reaches z = 1.55*(hFull - GZ) above
% GZ = -0.30, so this is the height the widest clump is actually drawn at. If a
% later edit widens the radius or shortens hFull, this fires instead of quietly
% putting a row of drums back on the verge.
BUSH_GZ    = -0.30;                     % must track sc.s1render's GZ
BUSH_ZTOP  = 1.55;                      % must track the bush lathe's last pz
drawnH     = BUSH_GZ + BUSH_ZTOP*(U(:,4) - BUSH_GZ);
aspect     = 2*U(:,3) ./ drawnH;
assert(max(aspect) <= 1.05, "sc:s1scrubAspect", ...
    ['widest scrub clump is %.2f m across against %.2f m tall (aspect %.2f) - a ' ...
     'clump wider than it is tall renders as a smooth cylinder, because the ' ...
     'silhouette below hFull is pinned by the sight model and cannot be broken'], ...
    2*max(U(:,3)), min(drawnH), max(aspect));

% ---------------------------------------------------------------- occluders
% CROWNS ARE NOT OCCLUDERS AND ARE NOT LISTED AS ONE. A crown sits between 0.38h and
% 1.02h, i.e. 3.4-6.1 m up, and cannot intersect a sight line that never leaves 1.43 m.
% The first version listed them anyway; MEASURED, they moved the reveal by 0 m over
% 200 m of ray-marching. Carrying an occluder that does nothing makes the model look
% like it is doing work it is not. TRUNKS are kept, at trunk radius, because a trunk
% really does stand in the way - they are simply outside the 9.5 m corridor and so
% never cross this particular line.
% NOTHING MAY BE DRAWN THAT THE OCCLUDER LIST DOES NOT KNOW ABOUT (REF-17 s7a).
% The understorey is real mass at real radius, so it goes in the list at that radius
% rather than being decoration the solver is blind to - which is BUG 2 exactly.
% It cannot reach the cow's sight line (every tree sits at |e| >= 9.5 m and the line
% runs entirely inside |e| < 5 m), and the reveal is re-measured below to prove it.
und = T(T(:,7) > 0, [1 2 7]);
W.Occluders = [T(:,1), T(:,2), T(:,3); und; U(:,1:3)];

% ---------------------------------------------------------------- the reveal
% MEASURED, never chosen. The cow emerges at the LEFT VERGE, so the line that decides
% the reveal runs to +4.6 m, not to the centreline.
W.CowEmergeE = 4.6;
W.RevealTarget = opts.Reveal;                  % written S1: "visible at 42 m"

% RANDOM SCRUB ALONE CANNOT DELIVER A REPEATABLE REVEAL. Measured across 8 seeds it
% ranged 34-110 m, median 76 m - so the one seed that produced 44 m was luck, not
% design. The written script does not leave this to chance either: it names the two
% things that hide the cow, "the kans grass and the fodder stack".
% So ONE DELIBERATE THICKET is authored at the verge, and its radius is SOLVED by
% bisection until the ray-marched reveal equals the specification. The reveal is still
% computed by marching the sight line - it is measured, not asserted.
W.Scrub(W.Scrub(:,1)==inf,:) = [];
keep = true(size(U,1),1);
for i = 1:size(U,1)
    [ss, ee] = W.Path.inverse(U(i,1:2));
    if ee > 0 && ss > W.CowStation-150 && ss < W.CowStation+12, keep(i) = false; end
end
U = U(keep,:);                                  % clear the approach so the solve is clean

% 26 m WAS THE ONE PLACING IT ON THE ROAD, AND IT COULD NOT BE FIXED SIDEWAYS.
% The bisection grows the radius until the circle just touches the sight line, so
% THE INNER EDGE IS PINNED TO THE LINE, not to the thicket's own offset: swept at
% e = 6.4, 7.2 and 8.0 the radius grew by exactly the offset and the inner edge
% stayed at 2.92 m every time - 0.58 m inside the carriageway. The only free
% variable is STATION, because the line itself moves outboard as it approaches her
% (e = 2.92 m at 26 m short, 3.89 m at 11 m short).
% Swept, and 11 m is better than the position it replaces on BOTH counts:
%   26 m short -> r 3.48, reveal 44.0 m, inner edge 2.92 m  (on the road)
%   11 m short -> r 2.51, reveal 42.0 m, inner edge 3.89 m  (clear)
% It now lands on the written 42 m exactly instead of 2 m over, and S1's own script
% names a fodder stack near the cow as one of the two things that hide her, so an
% occluder 11 m short of her is what the scenario describes anyway.
TH_S = W.CowStation - 11.0;                     % thicket station, just short of the cow
TH_E = 6.4;                                     % just beyond the shoulder, on the left
% AND THE SOLVER MAY NOT BUY THE REVEAL WITH TARMAC. Capping the upper bound means a
% radius that would reach the carriageway is simply not reachable; if that makes the
% reveal unattainable the reveal assert below fires, which is the honest failure.
lo = 0.5; hi = min(9.0, TH_E - ROAD_CLEAR);
for it = 1:40                                   % bisection on the thicket radius
    mid = (lo+hi)/2;
    xy  = W.Path.at(TH_S, TH_E);
    occ = [T(:,1), T(:,2), T(:,3); und; U(:,1:3); xy(1) xy(2) mid];
    d   = W.Path.revealDistance(W.CowStation, W.CowEmergeE, occ, 200);
    if d > opts.Reveal, lo = mid; else, hi = mid; end
end
thXY = W.Path.at(TH_S, TH_E);
W.Thicket = [thXY(1), thXY(2), (lo+hi)/2, 2.40];    % kans grass scale: S1 says 2.6 m
W.Scrub   = [U; W.Thicket];
W.Occluders = [T(:,1), T(:,2), T(:,3); und; W.Scrub(:,1:3)];
W.HFullMin = HFULL_MIN;

W.RevealDistance = W.Path.revealDistance(W.CowStation, W.CowEmergeE, W.Occluders, 200);
assert(abs(W.RevealDistance - opts.Reveal) <= 3.0, "sc:s1reveal", ...
    "reveal solved to %.0f m, specification says %.0f m", W.RevealDistance, opts.Reveal);

% ---------------------------------------------------------------- assertions
% THE ONE THAT KEEPS THE 2-D SIGHT MODEL HONEST. Every occluder must be a solid mass
% at full radius up to at least the height of the sight line it is claimed to block.
tooShort = sum(W.Scrub(:,4) < HFULL_MIN);
assert(tooShort == 0, "sc:s1occluderHeight", ...
    ['%d occluders are shorter than %.2f m at full radius, so the 2-D sight model ' ...
     'claims occlusion the geometry does not provide'], tooShort, HFULL_MIN);

% ---------------------------------------------------------------- the road assert
% On the CLAIMED geometry. sc.s1render asserts the DRAWN geometry separately, because
% they are different quantities and conflating them is how 6 masses ended up on a road
% while every assertion in this file passed.
nS = size(W.Scrub,1);  eScrub = zeros(nS,1);
for i = 1:nS, [~, ee] = W.Path.inverse(W.Scrub(i,1:2)); eScrub(i) = ee; end
reachS = abs(eScrub) - W.Scrub(:,3);
undT   = W.Trees(W.Trees(:,7) > 0, :);
reachU = abs(undT(:,6)) - undT(:,7)*UND_DRAW;
nOnRoad = sum(reachS < W.Width/2) + sum(reachU < W.Width/2);
assert(nOnRoad == 0, "sc:s1vegOnRoad", ...
    ['%d vegetation masses stand on the %.1f m drivable carriageway ' ...
     '(nearest: scrub %.2f m, understorey %.2f m). The ego drives through them.'], ...
    nOnRoad, W.Width, min(reachS), min(reachU));
W.RoadNearest = min([reachS; reachU]);

assert(W.Path.Len > 400, "sc:s1short", "route is only %.0f m", W.Path.Len);
d = vecnorm(W.Trees(:,1:2) - reshape(W.Path.P(1,:),1,2), 2, 2); %#ok<NASGU>
% no trunk may sit inside the corridor - checked against the real path, every tree
bad = 0;
for i = 1:size(W.Trees,1)
    [~, e] = W.Path.inverse(W.Trees(i,1:2));
    if abs(e) < opts.CorridorHalf - 0.51, bad = bad + 1; end
end
assert(bad == 0, "sc:s1corridor", ...
    "%d trees stand inside the %.1f m cleared corridor", bad, opts.CorridorHalf);
fprintf(['[S1 world] cover %.0f%% open / %.0f%% village (lean %.2f) | route %.0f m | %d trees (%d carry understorey) | %d scrub ' ...
         '(h_full %.2f-%.2f m) | thicket r=%.2f m | REVEAL %.0f m (spec %.0f) | nearest veg to centreline %.2f m (road edge %.2f)\n'], ...
        W.CoverOpen, W.CoverVillage, W.LeanK, W.Path.Len, size(W.Trees,1), sum(W.Trees(:,7) > 0), ...
        size(W.Scrub,1), min(W.Scrub(:,4)), max(W.Scrub(:,4)), ...
        W.Thicket(3), W.RevealDistance, opts.Reveal, W.RoadNearest, W.Width/2);
end

% =======================================================================================
function tf = clearingHas(cl, s, e)
%CLEARINGHAS  Is (station, offset) inside the clearing?
%   ONE definition, used by the tree scatter, by the scrub scatter and by the renderer,
%   so the hole in the forest and the grass drawn in it cannot disagree. The near and
%   far edges wander on two incommensurate harmonics; an axis-aligned box read as a
%   rectangular rug from above and no amount of wavy PAINT inside it could hide the
%   straight line the TREES were drawing.
if s <= cl.S(1) || s >= cl.S(2), tf = false; return; end
near = cl.E(1) + 1.5*sin(s/7.1) + 0.9*sin(s/3.3 + 2.0);
far  = cl.E(2) - 2.6*sin(s/9.7 + 1.1) - 1.4*sin(s/4.1);
% and taper it out at both ends, so the wood closes round it instead of stopping dead
t    = min(1, min(s - cl.S(1), cl.S(2) - s) / 7.0);
mid  = (near + far)/2;  half = (far - near)/2 * t;
tf   = e > mid - half && e < mid + half;
end
