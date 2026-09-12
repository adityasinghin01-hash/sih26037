function st = s1render(S, W, opts)
%S1RENDER  Draw the STATIC world of S1 - road, markings, forest, corridor,
%          clearing, undergrowth and the authored thicket.
%
%   Static means: everything that does not move. The cow, the herd, the auto, the
%   motorcycle and the tractor are Phase 3 and are drawn by the action script on top
%   of this. Splitting them is what lets the world be looked at and fixed on its own.
%
%   WHAT IS REAL HERE AND WHAT IS BACKDROP - stated so nothing is over-claimed:
%     REAL, measured, and what the planner sees
%       - the centreline (map/matlab_roads.csv, offset removed)
%       - the 7.000 m carriageway and the 1.200 m earthen shoulders
%       - the marking geometry (edge line 150 mm set 150 mm in; centre 3 m + 6 m gap)
%       - every occluder position and radius, which is what decides the reveal
%     BACKDROP, massed but not measured
%       - trunk/crown proportions, leaf colour, ground relief, haze, the far treeline
%
%   PERFORMANCE. 900 trees as 900 patches is 1,800 graphics objects and the render
%   crawls. Trunks and crowns are INSTANCED into one patch each (sc.scene/instances),
%   and everything beyond opts.Radius is culled. Measured cost is printed by the
%   caller; see matlab/s1_world_shots.m.
%
%   st = sc.s1render(S, W)  returns counts and the seconds spent.

arguments
    S  sc.scene
    W  struct
    opts.Focus  (1,2) double = [NaN NaN]    % build around this world point
    opts.Radius (1,1) double = 190          % cull beyond this, m
    % HAZE CONVERGES ON THE SKY, because airlight IS the sky. This was [0.74 0.78 0.80]
    % = RGB 189/199/204 while sc.scene's measured horizon is 137/160/173 - so distant
    % trees were being mixed toward something 38 % BRIGHTER THAN THE SKY BEHIND THEM
    % and the far stand rendered as milky pale balloons floating in front of a darker
    % sky. REF-13 s5 measures the real behaviour: a ridge at 2 km sits at brightness
    % 100.7 and the far range at 15 km at 161.9, always converging up TOWARD the sky
    % and never past it. This is sc.scene's own SkyHorizon value.
    opts.Haze   (1,3) double = [0.539 0.628 0.677]
    opts.Sky    (1,1) logical = true
    opts.Probe  (1,1) logical = false       % draw a zebu at the emergence point
    opts.Detail (1,1) double  = 48          % m: authored neem inside this, primitive beyond
end

t0 = tic;
P = W.Path;
if any(isnan(opts.Focus)), opts.Focus = P.at(P.Len/2, 0); end
F   = opts.Focus;
Rad = opts.Radius;
HZ  = opts.Haze;

% ------------------------------------------------------------------ the palette
% Afternoon, 25 Sep 15:30 IST, sun 33.11 deg / 246.87 deg (S0 s2). Dry-season forest:
% olive and khaki, NOT the saturated green a default MATLAB palette reaches for.
% REF-13 s7, MEASURED: plains vegetation is RGB 92.3/116.1/95.0 and 20 points LESS
% saturated than alpine - "Najibabad is plains: build ~31 %, not 51 %. A saturated
% alpine green in our world would read as wrong immediately." Every green below was
% 51 % alpine and is now built around the measured plains value.
% MEASURED AT THE PIXEL, NOT AT THE ALBEDO - and that distinction was the bug.
% REF-13 measured PHOTOGRAPHS: plains vegetation reads 92.3/116.1/95.0 at 31 % sat.
% Those numbers were entered here as MATERIAL colours and then darkened again
% (CROWN = PLAINS*0.72), so the canopy RENDERED at 68.9/83.4/79.1, sat 17.4 % -
% 30 % too dark and 44 % under-saturated against the thing it was copied from.
% A reference measured off pixels has to be met at OUR pixels. Measured with
% tools/measure.py and corrected until it lands.
% TWO KINDS OF COLOUR LIVE HERE AND CONFUSING THEM WAS THE WHOLE BUG.
%   S.flat()      draws with FaceLighting 'none' -> the number IS the pixel.
%   S.instances() and S.mesh() are lit -> MEASURED on this scene, the pixel comes out
%                 at about 0.64 of the number, because the ambient/diffuse split means
%                 most faces of a crown are not facing the sun.
% REF-13 measured PHOTOGRAPHS, so all of its numbers are PIXELS. They were entered
% here as material colours and then darkened again, and the canopy rendered at
% 62.5/88.7/54.5 against the 92.3/116.1/95.0 it was copied from. Anything ending _PX
% below is a pixel target; anything lit is that target divided back out.
PLAINS_PX = [0.362 0.455 0.373];   % REF-13 s7, plains vegetation, AS A PIXEL
LIT       = 0.636;                 % measured: rendered pixel / albedo, this scene
PLAINS    = PLAINS_PX / LIT;       % the same green, as something to LIGHT

FLOOR    = [0.37 0.35 0.26];    % leaf litter and dust, ridges
HUMUS    = [0.21 0.20 0.15];    % REF-04 s10: near-black humus in the hollows
CLEARING = PLAINS_PX .* 1.02;   % grazed doob - drawn FLAT, so this is a pixel
SHOULDER = [0.53 0.46 0.34];    % earthen shoulder, no kerb
% MEASURED off Aditya's own dashcam: 12 hand-picked daylight open-road frames of the
% single-carriageway rural class S1 actually builds (drive_02/03/09/11 - the same clips
% S1 cites for its kans verges). Median RGB 88.8/93.3/90.0, brightness 91.8, and
% R-B = -1.2, i.e. NEUTRAL. We rendered 75/75/78: 18 % too dark and faintly BLUE.
% REF-06 s6 says "light warm grey, never black". His own footage supports "never
% black" and NOT "warm" for this road class - only the wide highway frames
% (08_t44/67/89) measure warm. Brightness taken from the measurement, hue left neutral.
% Drawn by S.flat, so this is the pixel and needs no division.
TARMAC   = [0.360 0.360 0.360];
PAINT    = [0.86 0.84 0.77];
TRUNK    = [0.44 0.39 0.32];    % bark, not charcoal - it rendered at 46/40/33
% TWO HUES, NOT ONE LIT TWICE. REF-06 s6: greens are "YELLOW-green in sun and
% BLUE-green in shade - two different hues, not one lit twice", and REF-13 s7 measures
% the same thing inside a single square metre: "bright yellow-green new blades, deep
% blue-green clumps, dark olive broadleaf weeds". Our per-instance variation was a
% BRIGHTNESS multiplier, and scaling an RGB triple uniformly cannot change its
% saturation at all - which is why the canopy's per-pixel saturation tracked the
% albedo's exactly instead of rising above it the way a real canopy's does. Each
% crown now sits somewhere on the line between these two.
CROWN_SUN   = [0.600 0.775 0.470] / 1.0;
% GREEN-DOMINANT, NOT CYAN-DOMINANT. This was [0.505 0.660 0.680], where BLUE
% outranks green - which is a cyan, not a leaf. REF-06 s6 says the shade hue is
% "blue-GREEN", and a blue-green leaf is still a green: G on top, B second. The
% swap keeps the saturation (25.7 %) and moves the CROWN mean by under 3.5/255,
% so the REF-13 pixel target this file is pinned to is unaffected.
CROWN_SHADE = [0.505 0.700 0.690] / 1.0;
% B RAISED AFTER MEASURING THE SWAP. Green-dominant was right, but taking B down to
% 0.660 left the rendered canopy at 90.6/116.1/82.9 against REF-13 s7's
% 92.3/116.1/95.0 - R and G within 1.7, B 12 short, i.e. the canopy had gone
% yellow-green. B goes back up with G kept on top, which is what "blue-green" means.
CROWN    = (CROWN_SUN + CROWN_SHADE)/2;         % the mean is the REF-13 target / LIT
CROWNTIP = [0.680 0.840 0.560];
% MEASURED OFF THE RENDER, AND IT WAS THE WRONG WAY ROUND. At 0.92 the near scrub
% came back at brightness 123.2 against the canopy above it at 114.2 - the verge
% undergrowth was the BRIGHTEST vegetation in the frame. REF-06 s3 is quoted twice
% in this file for the opposite rule ("dark and closed at the base, lighter at the
% top"), and UNDER was already pulled to 0.44 for exactly this reason; the near
% scrub simply never got the same correction. It sits between the two now: darker
% than the crowns it stands under, lighter than the far wall behind it, which is
% what a lit verge actually does.
BUSH     = CROWN .* 0.58;
THICKET  = CROWN .* 0.74;
% REF-06 s3 twice over: "a treeline is CLOSED at the bottom" AND "dark and closed at
% the base, lighter at the top". At 0.62 the wall rendered as pale sage and read as
% more crowns floating at ground level rather than as the shaded mass under them.
UNDER    = CROWN .* 0.44;

GZ = -0.30;                     % vegetation is PLANTED here, below the ground surface,
                                % or every trunk and bush floats on a visible gap

% ------------------------------------------------------------------ road constants
CW      = W.Width;              % 7.000 m carriageway
SHW     = W.Shoulder;           % 1.200 m earthen shoulder
EDGE_W  = 0.150;                % S1: "edge lines 150 mm"
EDGE_IN = 0.150;                % S1: "set 150 mm in"
CTR_W   = 0.100;                % S1: "100 mm (open country)"
DASH    = 3.0; GAP = 6.0;       % S1: "3 m mark + 6 m gap"
WORN    = 0.60;                 % S1: "both worn to about 60 %"

assert(abs(CW - 7.000) < 1e-3, "sc:s1rWidth", ...
    "carriageway is %.3f m, S0 s4 says 7.000 m", CW);
assert(abs(SHW - 1.200) < 1e-3, "sc:s1rShoulder", ...
    "shoulder is %.3f m, S1 says 1.200 m", SHW);
eOut = CW/2 - EDGE_IN;                      % 3.350 - outer edge of the edge line
eIn  = eOut - EDGE_W;                       % 3.200 - inner edge
assert(abs((CW/2 - eOut) - EDGE_IN) < 1e-9 && abs((eOut - eIn) - EDGE_W) < 1e-9, ...
    "sc:s1rMarking", "edge line geometry does not close");

% z stacking. Ground is based at -0.25 with +-0.126 of relief, so its highest point is
% -0.124 m. Everything below is above that, in the order it must paint.
Z_CLEAR = -0.110;  Z_SHLD = 0.005;  Z_ROAD = 0.030;  Z_PAINT = 0.036;

% ------------------------------------------------------------------ sky and distance
if opts.Sky
    S.skydome(F, 900);
    S.farGround(F, Rad + 40, 860, mix(FLOOR, HZ, 0.72));   % annulus, never underneath
    S.horizon(F,  430, mix(CROWN*0.95, HZ, 0.62), 17);
end

S.ground(F(1)+[-Rad-40 Rad+40], F(2)+[-Rad-40 Rad+40], FLOOR, ...
         'Step', 7, 'Relief', 0.07, 'Hollow', HUMUS, 'Haze', HZ, 'HazeFrom', F, ...
         'HazeStart', 35, 'HazeFull', Rad+40, 'HazeMax', 0.72);

% THE FOREST FLOOR, FINE STRUCTURE - Phase 5's third and last ground piece, after
% the shoulder and (in sc.s2render) the verge/island. The coarse ground() above is
% Step 7 m over the whole visible extent - a per-vertex texture at that spacing
% would be sampled once every 7 m and could not show fine litter/duff grain at all.
% This is a SECOND, FINER patch of the identical relief surface (same Base/Relief/
% Hollow/Haze - it is not a different surface, just resampled denser), restricted
% to where a camera is ever close enough to see fine ground detail (opts.Detail,
% the same radius the near tree LOD already uses - fine texture 150 m away is both
% invisible and wasted). Base nudged +3 mm so it does not z-fight the coarse
% surface underneath it where the two overlap - the same trick this file's own
% road-edge crumble uses against the paint (Z_ROAD + 2 mm against Z_PAINT).
if opts.Detail > 0
    DR = opts.Detail + 10;
    S.ground(F(1)+[-DR DR], F(2)+[-DR DR], FLOOR, ...
             'Step', 1.4, 'Relief', 0.07, 'Base', -0.25+0.003, 'Hollow', HUMUS, ...
             'Haze', HZ, 'HazeFrom', F, 'HazeStart', 35, 'HazeFull', Rad+40, ...
             'HazeMax', 0.72, 'TextureFn', @sc.floorTexture);
end

% ------------------------------------------------------------------ the clearing
% The hole in the forest. It is the REASON the herd is standing there, and it is the
% same rectangle s1world punched out of the tree distribution - not a second guess.
% Drawn with a WAVY edge inset inside the rectangle s1world punched out of the forest,
% not as the rectangle itself: a hard-edged bright rectangle in the middle of a wood
% reads as a green rug laid on the floor, which is what the first render looked like.
% Insetting rather than overflowing leaves a fringe of leaf litter under the tree line.
% AND IT IS DRAWN IN THREE BANDS, NOT ONE. S.flat() has lighting off, so one polygon
% is one poster colour, and a single pale-green shape on a darker floor read from the
% corridor camera as a rug laid on the ground - a hard tonal step with a hard edge.
% REF-04 s10's rule for a floor boundary is the one being broken: "the boundary is a
% noise-masked gradient, never a line." Three nested wavy rings, each with its own
% wobble and its own colour, put two soft steps where there was one hard one, and the
% outermost sits nearly on the litter colour so the wood does not simply stop.
% AND IT IS DRAWN FROM THE SAME EDGE THE TREES WERE PLACED AGAINST. s1world's
% clearingHas() defines one wandering hole; drawing a different curve inside it left
% a rim of bare litter that did not match the wood. Three nested bands, each inset a
% little further, so the boundary is a GRADIENT and not a line (REF-04 s10) - and the
% outermost sits nearly on the litter colour, so the clearing fades into the floor
% instead of ending at a step.
cl = W.Clearing;
ss  = linspace(cl.S(1), cl.S(2), 60)';
for ring = 1:3
    g   = (ring-1)/2;                              % 0 innermost .. 1 outermost
    A = zeros(0,2); B = zeros(0,2);
    for i = 1:numel(ss)
        si = ss(i);
        near = cl.E(1) + 1.5*sin(si/7.1) + 0.9*sin(si/3.3 + 2.0);
        far  = cl.E(2) - 2.6*sin(si/9.7 + 1.1) - 1.4*sin(si/4.1);
        t    = min(1, min(si - cl.S(1), cl.S(2) - si) / 7.0);
        mid  = (near + far)/2;  half = (far - near)/2 * t;
        half = half - (1 - g)*2.6;                 % inner rings are inset
        if half <= 0.4, continue; end
        A(end+1,:) = P.at(si, mid - half);         %#ok<AGROW>
        B(end+1,:) = P.at(si, mid + half);         %#ok<AGROW>
    end
    if size(A,1) < 3, continue; end
    % ring 1 is the innermost and is the grazed doob; ring 3 is the outer rim and
    % is most of the way to leaf litter, so the wood does not end at a tonal step.
    col = mix(CLEARING, FLOOR, 0.62*g);
    S.flat([A(:,1); flipud(B(:,1))], [A(:,2); flipud(B(:,2))], ...
           Z_CLEAR - 0.004*ring, col);
end

% ------------------------------------------------------------------ the road
[sA, sB] = stationWindow(P, F, Rad + 50);

% THE SHOULDER, TEXTURED - the ground half of Phase 5. S1 "THE ROAD" names it
% directly: "Bare pale-tan dirt... dusty, wheel-scarred where vehicles pull off."
% sc.groundTexture is the same MULTIPLIER mechanism as sc.roadTexture, solved to a
% target measured off Aditya's own dashcam frames (matlab/ground_contrast_probe.m:
% 0.0861, genuinely higher than the road's 0.0561 - loose ground carries more local
% structure than engineered tarmac). Drawn over the FULL band including where the
% carriageway will paint over it, exactly as the flat version was - the road carpet
% below still occludes the middle, so no new geometry trap is introduced.
[GXs,GYs] = bandGrid(P, sA, sB, -(CW/2+SHW), (CW/2+SHW), 2.5, 8);
Mshld = sc.groundTexture(CW/2+SHW, sB - sA, 'Ruts', 0.6);
S.carpet(GXs, GYs, Z_SHLD, uint8(255*min(1, reshape(SHOULDER,1,1,3) .* Mshld)));
% THE CARRIAGEWAY, AS A TEXTURED SURFACE RATHER THAN ONE FLAT PATCH.
% It was one `patch` in one colour and it fills most of every frame. What replaces it
% is the same band drawn as a grid carrying an image: wheel paths where "aggregate
% shows" (S1 "THE ROAD"), the dust strips between them, longitudinal streaking, the oil
% line down each lane centre, and the three patches of darker fresh mix S1 counts.
% The image is a MULTIPLIER on TARMAC, so the measured grey (REF-17 s19h) cannot move.
%
% AND THE HONEST NUMBER: this is a SMALLER win than REF-17 s19j claims. That note calls
% the road "flat paper" at contrast 7.4 and "the largest available win" - but 7.4 was
% never compared to anything. Measured off 59 of Aditya's own 64 dashcam frames, at
% matched pixels-per-metre and with markings and vehicles rejected, the REAL road of
% this class runs at local contrast 6.1 (p25 4.6, p75 8.5). Ours was 5.4. The gap is
% about one level, not a chasm. What the flat patch genuinely lacked was not contrast
% but STRUCTURE - it had no wheel paths, no streaks and no patches at all - and that is
% what this buys. See REF-17 s22.
[GX,GY] = bandGrid(P, sA, sB, -CW/2, CW/2, 2.5, 7);
Mtex = sc.roadTexture(CW/2, sB - sA);
S.carpet(GX, GY, Z_ROAD, uint8(255*min(1, reshape(TARMAC,1,1,3) .* Mtex)));

% ------------------------------------------------------------------ potholes
% S1 "THE ROAD": 9 potholes at named stations, 0.25-0.9 m diameter, 30-90 mm
% deep, "three patched with darker fresh mix".
%
% TWO THINGS TRIED AND ABANDONED BEFORE THIS ONE, BOTH FOUND BY LOOKING:
%   1. Perturbing the road's own grid - rejected before building anything:
%      `texturemap` stretches the road image evenly across however many grid
%      COLUMNS exist, regardless of their real spacing, so densifying the
%      shared grid near a pothole would stretch/distort the surrounding
%      texture exactly where detail was being added.
%   2. A real 3D bowl mesh (a lathe, unit radius 1 at the rim tapering to a
%      depression at the centre), layered as its own instanced object. Built,
%      and it rendered as a THIN RING OUTLINE with a hollow interior - proven
%      by mapping the actual dark pixels, which formed a ring, not a filled
%      shape. Cause: the flat road carpet is ONE CONTINUOUS SURFACE with no
%      hole cut into it, so it simply occludes the bowl's interior from the
%      camera - only the rim, right at the boundary, pokes past it. Cutting
%      an actual hole in the shared grid re-opens problem 1's exact risk.
%
% WHAT'S HERE INSTEAD: a flat, unlit, RADIAL COLOUR GRADIENT - nested discs,
% darkest at the centre, blending out to the exact road colour at the rim, so
% there is no hard edge to occlude or fight. The same idiom this file already
% uses for the clearing's own soft boundary (three nested rings blending
% FLOOR into CLEARING) - proven, and it sidesteps the winding-direction
% question entirely, since an unlit flat colour does not depend on which way
% a face points. At 30-90 mm deep and this viewing distance a real pothole
% mostly IS a colour/shadow cue, not a dramatic silhouette - this is a closer
% match to how one actually reads from a moving car than a literal bowl was.
%
% PATCHED = STATIONS 240/241/243, NOT A RANDOM PICK. S1's own text calls these
% three out as one cluster ("9 potholes clustered, not spaced... 240, 241,
% 243") - a maintenance crew patches adjacent holes in one pass, so patching
% exactly that trio is the reading the spec's own structure supports, not an
% arbitrary choice among nine.
PH_S       = [34 88 89 141 196 240 241 243 302];
PH_PATCHED = ismember(PH_S, [240 241 243]);
[pfV, pfF] = discMesh(12, 0, 1);   % plain flat disc - reused from the shadow stencil
for pk = 1:numel(PH_S)
    sk = PH_S(pk);
    if sk < sA - 5 || sk > sB + 5, continue; end            % cull off-window
    diam = 0.25 + 0.65*rand01(sk*3.1);                      % S1: 0.25-0.9 m
    ek   = (rand01(sk*5.7) - 0.5) * 3.6;                    % clustered, not on one line
    if abs(ek) > CW/2 - 0.4, ek = sign(ek)*(CW/2-0.4); end  % stay inside the carriageway
    xy = P.at(sk, ek);
    if PH_PATCHED(pk)
        FRESH = mix(TARMAC, [0.42 0.40 0.36], 0.55);        % darker fresh mix, S1's words
        Tp = [xy(1) xy(2) Z_ROAD+0.003 diam/2 diam/2 1];
        S.instances(pfV, pfF, Tp, FRESH, 'Lighting','none');
    else
        % CONTRAST RAISED, 6 SEP - checked from the REAL chase camera (not the
        % steep diagnostic angle used to verify the mechanism), the tree
        % shadows already on this road are large, soft and far higher-
        % contrast than the first version of this gradient, and the two
        % competed for the same visual space - a small subtle pothole read as
        % just more shadow. Darker centre (0.35->0.20 base factor) and a
        % tighter core (falloff exponent 1.3->2.2, so more of the radius
        % stays near full darkness before blending out) makes a pothole read
        % as a compact, hard anomaly rather than a soft sprawl - the opposite
        % character from a tree shadow, which is what lets the eye tell them
        % apart instead of one more shape in the same family.
        deep    = 0.030 + 0.060*rand01(sk*7.9);             % S1: 30-90 mm, sets DARKNESS
        darkest = TARMAC .* (0.20 - 0.12*min(1, deep/0.09));% deeper -> darker centre
        for ring = 1:4
            g   = (ring-1)/3;                     % 0 centre (smallest,darkest) .. 1 rim
            rr  = (diam/2) * (0.25 + 0.75*g);
            col = mix(darkest, TARMAC, g^2.2);      % g=1 blends fully into the road - no hard edge
            zk  = Z_ROAD + 0.002 + 0.001*(4-ring);  % smallest ring drawn ON TOP, all clear of Z_ROAD
            Tp  = [xy(1) xy(2) zk rr rr 1];
            S.instances(pfV, pfF, Tp, col, 'Lighting','none');
        end
    end
end

% THE EDGE CRUMBLES, AND S1 SAYS SO IN METRES. "THE ROAD": "Edges crumble into dirt
% over a RAGGED 100-300 mm band. No kerb." The carriageway was a clean mathematical
% band, so tarmac met shoulder along a dead-straight line for 610 m - the one edge in
% the frame a real road never has. Drawn UNDER the paint (Z_ROAD + 2 mm against
% Z_PAINT at 36 mm), so the edge line still reads over the top of it, which is what a
% worn rural edge actually looks like.
for sgn = [-1 1]
    ssr = unique([sA:0.8:sB, sB]);
    Ai = zeros(numel(ssr),2);  Bo = zeros(numel(ssr),2);
    for ir = 1:numel(ssr)
        wr = 0.10 + 0.20*rand01(ssr(ir)*3.7 + (sgn+1)*11.3);   % S1: 100-300 mm
        Ai(ir,:) = P.at(ssr(ir), sgn*(CW/2 - wr));
        Bo(ir,:) = P.at(ssr(ir), sgn*(CW/2));
    end
    S.flat([Ai(:,1); flipud(Bo(:,1))], [Ai(:,2); flipud(Bo(:,2))], ...
           Z_ROAD + 0.002, mix(TARMAC, SHOULDER, 0.58));
end

for sgn = [-1 1]                                        % the two edge lines
    [X,Y] = bandPoly(P, sA, sB, sgn*eIn, sgn*eOut);
    S.flat(X, Y, Z_PAINT, PAINT, WORN);
end
nd = 0;
for s0 = ceil(sA/(DASH+GAP))*(DASH+GAP) : (DASH+GAP) : sB-DASH   % the centre line
    [X,Y] = bandPoly(P, s0, s0+DASH, -CTR_W/2, CTR_W/2);
    S.flat(X, Y, Z_PAINT, PAINT, WORN);  nd = nd + 1;
end

% ------------------------------------------------------------------ the forest
[trV, trF] = prismMesh(7);                  % unit trunk: radius 1, z 0..1
[crV, crF] = ballMesh(8, false, 0.34);      % unit crown: LUMPY, see ballMesh
% Unit bush: FULL RADIUS 1 from z = 0 to z = 1, then a shallow cap to z = 1.22.
% Not a dome. A dome is only at full radius at its BASE, so a 2 m dome is half a metre
% tall where a sight line actually crosses it - which is exactly how the cow ended up
% plainly visible at 60 m while the model called it blocked.
[buV, buF] = latheMesh([0 1.00 1.00 0.98 0.92 0.80 0.62 0.36 0], ...
                       [0 0    1.00 1.10 1.21 1.32 1.42 1.50 1.55], 11);
% AND LUMP IT ABOVE THE FULL-RADIUS SECTION ONLY. The lathe is a cylinder with a cap,
% so every bush and every occluder rendered as a machined drum with a flat top - a
% hundred of them along the verge is the most artificial thing in the frame after a
% smooth crown. The shape BELOW hFull is left exactly alone, because that is the part
% the 2-D sight model claims (REF-17 s7a): pulling it in would draw an occluder
% smaller than it claims to be, which is BUG 1 all over again. Only the cap moves.
buV = lumpAbove(buV, 1.00, 0.30);
% A SECOND UNIT MASS FOR THE UNDERSTOREY WALL, LUMPED OVER ITS WHOLE HEIGHT.
% The scrub above must keep its cylinder below hFull because the 2-D sight model
% claims that silhouette (REF-17 s7a). THE WALL IS UNDER NO SUCH CLAIM: it stands
% at |e| >= 6.4 m on the right, where the sight line to the cow cannot reach it by
% SIGN, and at |e| >= 10.5 m on the left, where it cannot reach by distance - both
% argued and asserted where the wall is drawn. Sharing the scrub's pinned mesh with
% it was never required by anything; it just meant the wall inherited a constraint
% that does not apply to it, and rendered as a row of smooth-sided tanks. Lumping
% the full height is what a dense mass of undergrowth actually looks like, and it
% costs nothing - same vertex and face count, one mesh.
WALL_LUMP = 0.55;                  % +-27.5 % on the radius, at every height
[bwV, bwF] = latheMesh([0 1.00 1.00 0.98 0.92 0.80 0.62 0.36 0], ...
                       [0 0    1.00 1.10 1.21 1.32 1.42 1.50 1.55], 11);
bwV = lumpAbove(bwV, 0.02, WALL_LUMP);

% LOD. The Blender-authored neem is 1,112 triangles; the primitive is about 117. At
% 2,200 trees the authored one alone is 2.4 M triangles and MATLAB will not draw it,
% so the authored mesh is used for the trees near enough to read as trees and the
% primitive carries the mass behind them. opts.Detail is where the swap happens.
persistent TREE
if isempty(TREE) && opts.Detail > 0
    try TREE = sc.treeAsset(); catch, TREE = struct('Tris',0); end
end

T = W.Trees;
d = hypot(T(:,1)-F(1), T(:,2)-F(2));
T = T(d <= Rad, :);  d = d(d <= Rad);
near = false(size(d));
if ~isempty(TREE) && isfield(TREE,'Vb') && opts.Detail > 0
    near = d <= opts.Detail;
    Tn = T(near,:);  dn = d(near);
    if ~isempty(Tn)
        hn  = Tn(:,5);
        sxy = hn .* (0.88 + 0.24*hash2(Tn(:,1), Tn(:,2)));
        Ta  = [Tn(:,1), Tn(:,2), GZ*ones(size(hn)), sxy, sxy, hn];
        fn  = hazeFactor(dn, 35, Rad, 0.74);
        S.instances(TREE.Vb, TREE.Fb, Ta, ...
            mixN(TRUNK .* (0.80 + 0.40*hash2(Tn(:,1), Tn(:,2))), HZ, fn), 'Ambient', 0.38);
        % REF-06 s6: greens are YELLOW-green in sun and BLUE-green in shade - two hues,
        % not one lit twice. Base dark and blue-ish, tip lighter and yellower.
        tHueN = hash2(Tn(:,1)*1.7, Tn(:,2)*0.9);
        baseN = CROWN_SUN.*(1 - tHueN*0.9) + CROWN_SHADE.*(tHueN*0.9);
        % THE AUTHORED TREE'S FOLIAGE LEANS; ITS TRUNK DOES NOT. The branches are a
        % separate mesh from the canopy, so the world's crown offset (columns 10-11)
        % applies to the foliage only - which is exactly the real thing: the trunk
        % stands where it stands and the crown reaches out over the road above vehicle
        % clearance. Drawing both at the trunk position was why the near trees carried
        % no canopy over the carriageway while the far ones did.
        Tf = Ta;
        if size(Tn,2) >= 11
            Tf(:,1) = Tf(:,1) + Tn(:,10);
            Tf(:,2) = Tf(:,2) + Tn(:,11);
        end
        S.instances(TREE.Vf, TREE.Ff, Tf, ...
            mixN(baseN .* (0.88 + 0.24*hash2(Tn(:,2), Tn(:,1))), HZ, fn), ...
            'Ambient', 0.44, 'Tip', mix(CROWNTIP, HZ, 0.10));
    end
end
% SHADOWS COME FROM ALL THE TREES, NOT THE LEFTOVERS. Splitting the list for LOD and
% then casting shadows from what remained silently removed every shadow inside the
% detail radius - exactly the ones that fall on the road in front of the camera. The
% dapple vanished from the carriageway and nothing failed.
Tall = T;
T = T(~near, :);  d = d(~near);
n = size(T,1);
if n > 0
    h = T(:,5);  tr = T(:,3);  cr = T(:,4);
    v = hash2(T(:,1), T(:,2));                          % deterministic per-tree variation
    f = hazeFactor(d, 35, Rad, 0.74);

    Ttr = [T(:,1) T(:,2) GZ*ones(n,1) tr tr (h - GZ)];
    % +-20 % of one brown made a picket fence of identical poles. Bark varies far
    % more than that between trees, so the spread stays wide.
    % BUT THE PALE SKEW WAS TOO FAR AND IT WAS SKEWING THE WRONG THING. The top of
    % the old 0.62-1.48 range put a trunk at albedo 0.65/0.58/0.47, which rendered
    % as pale mauve tubing. The justification was REF-06 s4's whitewashed band -
    % and that is a BAND AT THE BASE of some trees near settlement, not a whole
    % trunk lightened end to end, so the observation was real and the implementation
    % of it was not. The spread is kept and the pale end pulled back; the whitewash
    % is left unbuilt rather than faked by making every trunk paler.
    Ctr = mixN(TRUNK .* (0.55 + 0.68*v.^0.8), HZ, f);
    S.instances(trV, trF, Ttr, Ctr, 'Ambient', 0.38);

    zc  = GZ + 0.70*h;                                  % crown centre height
    % REF-06 s3 / REF-13 s7: "a treeline is CLOSED at the bottom - from about 1 m up it
    % is a solid dark wall, you do not see through it and you do not see individual
    % trunks." The far crowns ran 0.38h to 1.02h, so daylight showed under the whole
    % stand and the mass read as a plantation of poles. They now start at 0.13h - and
    % see the understorey block below for why that alone was not enough.
    % Crown from 0.32 h to 1.00 h, which is REF-06 s2's "branches at 2-5 m into a
    % broad round or oval crown" for a 12 m tree. It used to run 0.13 h to 1.03 h in
    % an attempt to close the treeline from below - which a SPHERE cannot do, because
    % its bottom is a point (measured: 0.00 m of radius at eye height on a 16 m tree).
    % The understorey does that job properly now, so the crown can be the shape the
    % reference actually describes.
    zcFar = GZ + 0.66*h;

    % ---------------------------------------------------------- REF-06 s1, THE FORMS
    % "A tree's shape is not random variation on a template. It is a RECORD OF WHAT
    % HAPPENED TO IT... Model the CAUSE, and the variation comes out for free."
    % s1world assigns the cause from what is actually next to each tree; this draws it.
    % Each cause is three numbers - a horizontal scale pair, a vertical scale and a
    % centre height - plus a bearing to point the long axis along, which is what
    % sc.scene/instances' Yaw was added for.
    form = ones(n,1);  if size(T,2) >= 8, form = T(:,8); end
    % Both of these are precomputed in s1world. Querying the path per tree HERE would
    % be two lookups x ~1,300 trees x every frame of a 1,488-frame film.
    yaw = zeros(n,1);  if size(T,2) >= 9, yaw = T(:,9); end
    ax = cr;  ay = cr;  az = 0.34*h;  zc2 = zcFar;
    isRoad  = form == 2;  isCrowd = form == 3;
    isLop   = form == 4;  isVine  = form == 5;  isDead = form == 6;
    % cause 2, ROAD-SIDE CLEARANCE: "vertical plane where the crown stops at the
    % carriageway edge. Crown is a HALF-TREE." Narrow across the road, offset away.
    ax(isRoad) = cr(isRoad)*0.58;
    % cause 4, NEIGHBOUR CROWDING: "elongates along the row, narrows across it".
    ax(isCrowd) = cr(isCrowd)*0.66;  ay(isCrowd) = cr(isCrowd)*1.34;
    % cause 5, FODDER LOPPING: "branches cut back to stubs; regrowth is a DENSE BROOM
    % of thin shoots from a thick stub" - a small tight crown high on a bare trunk.
    ax(isLop) = cr(isLop)*0.52;  ay(isLop) = cr(isLop)*0.52;
    az(isLop) = 0.17*h(isLop);   zc2(isLop) = GZ + 0.86*h(isLop);
    % cause 6, VINE SMOTHERING: "bulbous, melted, drooping silhouette with no readable
    % branch structure". Wide, and hanging far lower down the trunk than a crown does.
    ax(isVine) = cr(isVine)*1.18;  ay(isVine) = cr(isVine)*1.10;
    az(isVine) = 0.52*h(isVine);   zc2(isVine) = GZ + 0.50*h(isVine);
    % cause 7, DEATH: "bare fan of pale limbs". No crown at all - the trunk stands.
    ax(isDead) = 0;  ay(isDead) = 0;  az(isDead) = 0;

    % THE CROWN OFFSET COMES FROM THE WORLD, IT IS NOT RECOMPUTED HERE. This block used
    % to push road-cut crowns AWAY from the carriageway, on REF-06 s1 cause 2 alone
    % ("the crown stops at the carriageway edge"). REF-06 s4 says the opposite -
    % "crowns are PUSHED OUT OVER THE ROAD" - and both are true at different heights:
    % cut vertically below vehicle clearance, leaning out above it. sc.s1world now
    % resolves that, SOLVES the lean against S1's written 38 % cover, and stores it in
    % columns 10-11. Recomputing it here is how the world came to disagree with its own
    % picture: measured cover was 0.7 % because the world only knew about trunks.
    offx = zeros(n,1); offy = zeros(n,1);
    if size(T,2) >= 11
        offx = T(:,10);  offy = T(:,11);
    end
    Tcr = [T(:,1)+offx, T(:,2)+offy, zc2, ax, ay, az];
    % REF-13 s5: haze collapses LOCAL CONTRAST as well as saturation, 43 to 21. So the
    % per-tree colour VARIATION is compressed with distance too, not just the hue.
    varF = 1 - 0.75*f;
    % HUE varies per tree, then brightness on top of it. A brightness-only spread
    % leaves every crown the same hue, which is what made the canopy read as one
    % poster colour lit unevenly. Haze then compresses the SPREAD as well as the
    % colour, which is REF-13 s5's second law: local contrast collapses 43 -> 21.
    tHue = hash2(T(:,1)*1.7, T(:,2)*0.9);
    base = CROWN_SUN.*(1 - tHue.*varF*0.9) + CROWN_SHADE.*(tHue.*varF*0.9);
    Ccr  = mixN(base .* (1 - 0.24*varF + 0.48*varF.*hash2(T(:,2), T(:,1))), HZ, f);
    live = ~isDead;
    % SPIN, and it is load-bearing now that the crown mesh has a fixed lump pattern.
    % yaw() is the local ROAD bearing, which is nearly the same for every tree in a
    % stretch - so using it alone would line every lump up along the row and the
    % repetition would read instantly. A per-tree spin on top scatters them.
    spin = yaw + 2*pi*hash2(T(:,2)*4.1, T(:,1)*2.7);
    S.instances(crV, crF, Tcr(live,:), Ccr(live,:), 'Ambient', 0.44, ...
                'Tip', mix(CROWNTIP, HZ, 0.30), 'Yaw', spin(live), 'Grain', 0.13);
    % a dead trunk is PALE, not green - REF-06 s1 cause 7, "a bare fan of pale limbs"
    if any(isDead)
        S.instances(trV, trF, Ttr(isDead,:), ...
                    mixN(repmat([0.44 0.41 0.35], sum(isDead), 1), HZ, f(isDead)), ...
                    'Ambient', 0.46);
    end
end

% ------------------------------------------------------------------ the understorey wall
% REF-06 s3: "A treeline is CLOSED at the bottom. From ~1 m up it is a solid dark wall -
% you do not see through it and you do not see individual trunks."
% MEASURED, and this is why the block exists: a far crown is a SPHERE, so at the
% driver's eye (1.35 m) it has a radius of 0.00 m on a 16 m tree and 0.17-0.32 m on a
% 12.5 m one - less than the trunk it hangs on. Starting the sphere at 0.13h closes
% nothing, because a sphere's bottom is a POINT. The stand rendered as poles on a pale
% void and the world behind the wood was plainly visible from the clearing camera.
% Drawn as a LATHE - full radius over its whole height - for the same reason the
% occluders are (REF-17 s7a BUG 1): a mass that has to block a horizontal line has to
% be at full radius where that line crosses it.
% s1world puts every one of these in W.Occluders at this radius, so nothing is drawn
% that the solver does not know about.
if ~isempty(Tall) && size(Tall,2) >= 7
    Un = Tall(Tall(:,7) > 0, :);
    if ~isempty(Un)
        % THE SHAPE HERE IS FREE, AND THIS IS WHY - it is not the s7a rule being
        % bent. Every understorey mass stands at |e| > 22 m while the sight line to
        % the cow runs from the driver's eye at e = +1.75 m to her at e = +4.60 m and
        % never leaves that band. The closest any of them can come to that line is
        % 22 - 4.6 = 17.4 m against a maximum radius of about 3.4 m, so NO drawn shape
        % here can cross it, whatever shape it is. That is provable from the numbers
        % rather than measured, exactly as the kans-grass side argument is, and it is
        % ASSERTED below. They are still carried in W.Occluders, which only ever makes
        % the reveal more conservative.
        % THE PROOF IS NOT SYMMETRIC, SO NEITHER IS THE ASSERT. The sight line to the
        % cow runs from the driver's eye at e = +1.75 m to her at e = +4.60 m, so it
        % lives entirely at POSITIVE e. Mass on the right side is therefore harmless
        % whatever its radius - provable from the SIGN, which is the same argument
        % this file already makes for the kans grass - and only the left side has to
        % clear the line by distance. Asserting one combined min() over both sides
        % would fail on right-side mass that cannot possibly matter, and the honest
        % fix is to state the two arguments separately rather than to loosen one
        % threshold until it passes (REF-17 s11b).
        eL = Un(Un(:,6) > 0, :);                    % left of the centreline only
        assert(all(Un(Un(:,6) <= 0, 6) <= 0), "sc:s1rUnderSign", ...
            "right-side understorey is not all at e <= 0, so the sign argument fails");
        if ~isempty(eL)
            assert(min(eL(:,6)) - 5.0 > max(eL(:,7)) + 1.0, "sc:s1rUnderReach", ...
                ['nearest LEFT understorey is %.1f m off the centreline with radius ' ...
                 'up to %.1f m, so it can reach the sight line at e <= 5 m'], ...
                min(eL(:,6)), max(eL(:,7)));
        end
        % CULLED HARDER THAN THE CANOPY, and deliberately. A crown at 180 m is on the
        % skyline and has to be there; the wall under it is behind 150 m of nearer
        % trunks and cannot be seen at all. Drawing it anyway cost three lathes per
        % tree over the full 200 m radius - about 4,900 of them - and the render time
        % per still went from 27 s to over 200 s for geometry nothing looks at.
        % 95 m WAS TOO TIGHT AND THE CLEARING SHOT SHOWED IT: that camera looks
        % ACROSS the clearing at trees 100-140 m away, which had no wall under them,
        % and the pale far ground was plainly visible through their trunks again -
        % the exact defect the understorey exists to fix, reintroduced by my own
        % culling. The reach now covers what a camera can actually see through, and
        % the cost is paid back by dropping to ONE lobe beyond the near band, where
        % the silhouette is all that survives anyway.
        UNDER_NEAR  = 90;
        UNDER_REACH = 175;
        dU0 = hypot(Un(:,1)-F(1), Un(:,2)-F(2));
        Un  = Un(dU0 <= UNDER_REACH, :);
        if isempty(Un), Un = zeros(0,9); end
        du2 = hypot(Un(:,1)-F(1), Un(:,2)-F(2));
        ru  = Un(:,7);
        fu  = hazeFactor(du2, 35, Rad, 0.74);
        % IT HAS TO BE A WALL, NOT A ROW OF OIL DRUMS. One lathe per tree rendered as
        % exactly that from the clearing camera: separate near-black cylinders with
        % flat tops and hard rims, standing apart with the pale far ground showing
        % between them. REF-06 s3 asks for the opposite - "a solid dark wall... you do
        % not see through it" - and s3 again for the tone: "dark and closed at the
        % base, LIGHTER AT THE TOP", which one flat dark colour cannot say.
        % Three overlapping lobes per tree at different heights and offsets, blended
        % from UNDER at the base toward the crown colour at the top.
        nearU = du2 <= UNDER_NEAR;
        Tuw = zeros(0,6); Cuw = zeros(0,3);
        Euw = zeros(0,1); EuwSide = zeros(0,1);   % worst-case drawn reach, and side
        for j = 1:2
            if j == 2
                Un2 = Un(nearU,:);  ru2 = ru(nearU);  fu2 = fu(nearU);
            else
                Un2 = Un;           ru2 = ru;         fu2 = fu;
            end
            if isempty(Un2), continue; end
            % THE SAME ASPECT BUG AS THE SCRUB, ONE LAYER FURTHER OUT, AND CAPPING
            % the wall radius in sc.s1world is what exposed it. At hFullMin + 0.15 the
            % shortest lobes stood 2.9 m tall against 6.9 m wide - 2.4:1 - and the
            % wall rendered as a row of smooth-sided tanks with flat circular tops
            % marching down the verge. The lathe is a cylinder, so anything wider than
            % it is tall is a drum however it is coloured; the floor on the height is
            % what stops it, and it is raised here rather than by shrinking the radius
            % again, because the wall has to stay wide enough to overlap its
            % neighbours at 2.23 m spacing and actually close the stand.
            hj  = W.HFullMin + 0.90 + 2.20*hash2(Un2(:,2)*(3*j), Un2(:,1)*j);
            rj  = ru2 .* (0.62 + 0.30*hash2(Un2(:,1)*(j+2), Un2(:,2)));
            ang = 2*pi*hash2(Un2(:,1)*(j+9), Un2(:,2)*(j+4));
            dj  = ru2 .* 0.55 .* hash2(Un2(:,2)*(j+6), Un2(:,1)*(j+1));
            Tuw = [Tuw; Un2(:,1)+dj.*cos(ang), Un2(:,2)+dj.*sin(ang), ...
                   GZ*ones(size(ru2)), rj, rj, hj - GZ];                     %#ok<AGROW>
            Cuw = [Cuw; mixN(UNDER .* (0.80 + 0.40*hash2(Un2(:,1)*j, Un2(:,2)*5)), ...
                             HZ, fu2)];                                      %#ok<AGROW>
            % rj is the lobe radius BEFORE the wall mesh's own lump, which pushes
            % the surface out by up to WALL_LUMP/2. The reach has to be measured on
            % what is drawn, not on what is scaled - that is the whole point of it.
            Euw     = [Euw;     abs(Un2(:,6)) - (dj + rj*(1 + WALL_LUMP/2))];  %#ok<AGROW>
            EuwSide = [EuwSide; Un2(:,6)];                                   %#ok<AGROW>
        end
        assert(all(Tuw(:,6) >= W.HFullMin - GZ), "sc:s1rUnderShort", ...
            "understorey drawn below the %.2f m sight line", W.HFullMin);
        % AND THE REACH IS MEASURED OFF WHAT IS ACTUALLY DRAWN, not off the radius the
        % world CLAIMS plus a guessed margin. The lobes sit at offset dj with their own
        % radius rj, so a wall mass reaches ru*(0.55 + 0.92) = 1.47 x its claimed
        % radius - and the sight-line assert above was comparing against ru + 1.0. On
        % the old 22 m threshold that gap was covered by distance and nothing showed;
        % after the stand was closed at 10.5 m it cleared the cow's line by 0.68 m, by
        % luck rather than by anything checked. This is the same lesson as REF-17 s7a
        % BUG 2 and s18: a check that measures a different quantity from the one that
        % matters will pass while the geometry is wrong. Left side only - the right is
        % safe by sign, argued above.
        % Computed off the tree's STORED signed e (column 6) and the lobe's own offset
        % and radius, so it costs no path lookups - inverting the path per lobe would
        % be thousands of searches on every frame of a film. The offset direction is
        % arbitrary, so e - (dj + rj) is the worst case: the lobe thrown straight at
        % the road. Conservative by construction, which is the right side to err on.
        % THE ROAD, ON BOTH SIDES AND ON THE DRAWN GEOMETRY. s1world caps the claimed
        % radius by (|e| - 3.65)/1.47; this checks the number that number was meant to
        % produce, so if either the cap or the lobe arithmetic drifts, the render fails
        % instead of quietly paving the carriageway again.
        assert(min(Euw) >= W.Width/2, "sc:s1rUnderOnRoad", ...
            ['a drawn understorey mass reaches e = %.2f m, inside the %.1f m ' ...
             'carriageway - the ego drives through it'], min(Euw), W.Width);
        onLeft = Euw > -inf & EuwSide > 0;
        if any(onLeft)
            assert(min(Euw(onLeft)) > 5.0, "sc:s1rUnderDrawnReach", ...
                ['a drawn understorey mass reaches e = %.2f m at worst case, inside ' ...
                 'the 5.0 m the sight line to the cow needs (she is at e = %.2f m)'], ...
                min(Euw(onLeft)), W.CowEmergeE);
        end
        S.instances(bwV, bwF, Tuw, Cuw, 'Ambient', 0.36, ...
                    'Tip', mix(CROWN.*0.86, HZ, 0.12), 'Grain', 0.15);
    end
end

% ------------------------------------------------------------------ tree shadows
% At 15:30 with the sun 33.11 deg up, a 12 m tree throws 18 m of shadow, and on a
% forest road those bars across the carriageway are the most recognisable thing in the
% frame. MATLAB casts no shadows, so the crowns are projected along the real solar
% vector. A sphere's shadow under a directional light is an ELLIPSE elongated along the
% sun's bearing by 1/sin(elevation) = 1.83 here, so the stencil is built pre-rotated to
% that bearing once and then only scaled - which is what lets all of them ride in one
% instanced patch.
%
% ROAD ONLY, deliberately. A shadow drawn flat at z = 0.045 sits 0.30 m above the
% forest floor and would float; on the road it lands on a surface that really is flat.
if ~isempty(Tall)
    nAll = size(Tall,1);
    hAll = Tall(:,5);  crAll = Tall(:,4);  zcAll = GZ + 0.70*hAll;
    dirv = -[S.SunVec(1) S.SunVec(2)] / max(S.SunVec(3), 0.15);
    % the shadow falls from where the CROWN is, not from the trunk - so the leaned
    % crowns are what dapple the carriageway, which is the whole point of the lean.
    ox = zeros(nAll,1); oy = zeros(nAll,1);
    if size(Tall,2) >= 11, ox = Tall(:,10); oy = Tall(:,11); end
    px = Tall(:,1) + ox + dirv(1)*zcAll;   py = Tall(:,2) + oy + dirv(2)*zcAll;
    onRoad = false(nAll,1);
    for i = 1:nAll
        [~, ee] = P.inverse([px(i) py(i)]);
        onRoad(i) = abs(ee) < CW/2 - 0.4;     % centre well inside the carriageway
    end
    if any(onRoad)
        bear = atan2(-S.SunVec(2), -S.SunVec(1));
        stretch = 1/max(sind(S.SunElAz(1)), 0.2);
        [shV, shF] = discMesh(18, bear, stretch);
        m = sum(onRoad);
        % 0.62 of the crown radius, not all of it: crowns overlap, so a full-radius
        % ellipse per crown lays down far more shade than the canopy really casts, and
        % a 6 m ellipse spills off the tarmac onto the verge, where a flat shadow
        % floats 0.30 m above the ground and reads as a stain rather than a shadow.
        rs = 0.62 * crAll(onRoad);
        Tsh = [px(onRoad), py(onRoad), 0.045*ones(m,1), rs, rs, ones(m,1)];
        % FLAT: a shadow stencil interpolated at its rim bleeds into a soft blob
        S.instances(shV, shF, Tsh, repmat([0.10 0.11 0.10], m, 1), ...
                    'Lighting','none', 'Alpha', 0.26, 'Smooth', false);
    end
end

% ------------------------------------------------------------------ undergrowth
% The scrub, NOT the trunks, is what blocks a sight line at 1.75 m eye height - a line
% down a cleared corridor stays inside the corridor and never reaches a trunk. Measured
% before it was built: with trees alone the reveal was 160 m, i.e. no occlusion at all.
assert(isequal(W.Scrub(end,:), W.Thicket), "sc:s1rThicket", ...
    "the last scrub row is supposed to BE the authored thicket");
% THE PICTURE MUST SATISFY THE MODEL. Every occluder is drawn at full radius up to its
% column 4, so column 4 has to clear the sight line the 2-D model claims it cuts.
[~, zdim] = sc.meshes("zebu");           % derived, never retyped - see sc.s1world
SIGHT_MAX = zdim(3) + 0.15;             % zebu top + margin; the line never exceeds it
nShort = sum(W.Scrub(:,4) < SIGHT_MAX);
assert(nShort == 0, "sc:s1rShortOccluder", ...
    "%d occluders are drawn shorter than the %.2f m sight line they claim to block", ...
    nShort, SIGHT_MAX);
U  = W.Scrub(1:end-1, :);
du = hypot(U(:,1)-F(1), U(:,2)-F(2));
U  = U(du <= Rad, :);  du = du(du <= Rad);
if ~isempty(U)
    r = U(:,3);  hf = U(:,4);
    % The z-scale is hf - GZ, NOT hf: the bush is planted at GZ, and this is what puts
    % the top of its full-radius section at exactly z = hf, which is what is asserted.
    Tu = [U(:,1), U(:,2), GZ*ones(size(r)), r, r, hf - GZ];
    fu = hazeFactor(du, 35, Rad, 0.74);
    Cu = mixN(BUSH .* (0.76 + 0.46*hash2(U(:,1), U(:,2))), HZ, fu);
    S.instances(buV, buF, Tu, Cu, 'Ambient', 0.42, 'Grain', 0.16);

    % EVERY OCCLUDER RENDERED AS A MACHINED DRUM - flat top, dead-vertical side, one
    % colour - and a hundred of them lining the verge is the most artificial thing in
    % the frame. The two obvious cures are both forbidden: an inward wobble draws the
    % occluder SMALLER than it claims (BUG 1, the domes), and an outward one draws
    % silhouette the solver knows nothing about (BUG 2, the bushes). So the shape below
    % hFull is left exactly alone and the silhouette is broken ABOVE it, where the
    % model makes no claim at all - the same move the thicket already uses, applied to
    % all of the scrub, with the reach asserted for the same reason.
    % FIVE LOBES, NOT THREE, AND THEY NOW REACH MUCH FURTHER ABOVE hFull. With the
    % radius capped in sc.s1world the pinned cylinder is about 1.6-2.1 m of a 2.7-3.4 m
    % clump, so roughly a third of the height is free - and that third is the ONLY
    % place a silhouette can be broken. Three short lobes spent it on a crumpled cap
    % sitting on a drum; five taller ones that overlap read as one bushy mass with an
    % irregular top, which is what REF-06 s3 measures ("the top edge still reads as
    % separate lumps - never a smooth hedge silhouette").
    k = 5;  aa = (0:k-1)'/k*2*pi;
    Tl = zeros(0,6);  Cl = zeros(0,3);  maxReach = 0;
    for j = 1:k
        ang = aa(j) + 2*pi*hash2(U(:,1)*(j+1), U(:,2));
        % HEIGHT AND WIDTH BOTH READ OFF THE RENDER. At 1.05-1.67 x hFull these came
        % out as CYPRESS SPIRES - the lobe z-scale is multiplied AGAIN by the lathe's
        % own 1.55, so 1.67 x hFull put lobe tops at 5.3 m on a 3.4 m clump, and at
        % 0.34-0.64 x r they were narrow enough to read as conifers on an Indian
        % verge. Overcorrected from drums straight past bushes. Now they clear the
        % main mass by about a metre and are wide enough to merge with it.
        rr  = r .* (0.46 + 0.34*hash2(U(:,2)*(j+3), U(:,1)));
        off = (r - rr) .* (0.55 + 0.35*hash2(U(:,1)*(j+7), U(:,2)*2));
        maxReach = max(maxReach, max(off + rr - r));
        Tl = [Tl; U(:,1)+off.*cos(ang), U(:,2)+off.*sin(ang), ...
              GZ*ones(size(r)), rr, rr, (hf.*(1.00+0.30*hash2(U(:,2),U(:,1)*(j+2)))-GZ)]; %#ok<AGROW>
        Cl = [Cl; mixN(BUSH .* (0.60 + 0.66*hash2(U(:,1)*(j+5), U(:,2))), HZ, fu)];       %#ok<AGROW>
    end
    % A SKIRT, AND IT IS FREE. Every clump met the ground along a hard circular rim -
    % a machined foot, which is the same tell as the machined top and nothing had been
    % spent on it. These sit INSIDE the claimed radius exactly as the lobes do, so the
    % occlusion model is untouched and the same assert covers them; they are short, so
    % they only ever break the line where the clump meets the litter.
    for j = 1:3
        ang = 2*pi*hash2(U(:,1)*(j+13), U(:,2)*(j+2));
        rr  = r .* (0.26 + 0.24*hash2(U(:,2)*(j+11), U(:,1)*3));
        off = (r - rr) .* (0.70 + 0.28*hash2(U(:,1)*(j+17), U(:,2)*5));
        maxReach = max(maxReach, max(off + rr - r));
        Tl = [Tl; U(:,1)+off.*cos(ang), U(:,2)+off.*sin(ang), ...
              GZ*ones(size(r)), rr, rr, (hf.*(0.30+0.22*hash2(U(:,1),U(:,2)*(j+4)))-GZ)]; %#ok<AGROW>
        Cl = [Cl; mixN(BUSH .* (0.48 + 0.40*hash2(U(:,2)*(j+8), U(:,1))), HZ, fu)];       %#ok<AGROW>
    end
    assert(maxReach <= 1e-9, "sc:s1rScrubWidens", ...
        ['scrub lobes reach %.3f m OUTSIDE the claimed radius - the render would ' ...
         'occlude more than the solver believes'], maxReach);
    S.instances(buV, buF, Tl, Cl, 'Ambient', 0.42, 'Grain', 0.16);
end

% ------------------------------------------------------------------ grass
% Blender-authored, and placed under a rule that makes the Phase 2 occlusion bug
% impossible rather than merely unlikely:
%   - TUFTS are 0.52 m. The sight line to the cow never drops below 1.63 m, so a tuft
%     cannot occlude anything no matter where it goes. They are scattered freely.
%   - KANS is 3.03 m and absolutely could occlude. It is therefore placed ONLY at
%     NEGATIVE e - the right-hand verge - while the sight line to the cow runs from
%     e = +1.75 to e = +4.90, entirely on the left. Right-side kans cannot cross it.
%     That is provable from the sign, not from a measurement, and it is asserted.
persistent GRASS KANS DOOB
if isempty(GRASS) && opts.Detail > 0
    try
        [gv, gf] = rawSTL("grass_tuft");   GRASS = struct('V',gv,'F',gf);
        [kv, kf] = rawSTL("kans_clump");   KANS  = struct('V',kv,'F',kf);
        [dv, df] = rawSTL("doob_patch");   DOOB  = struct('V',dv,'F',df);
    catch
        GRASS = struct('V',[]); KANS = struct('V',[]); DOOB = struct('V',[]);
    end
end
if ~isempty(GRASS) && ~isempty(GRASS.V) && opts.Detail > 0
    [gA, gB] = stationWindow(P, F, opts.Detail);
    Tg = zeros(0,6);
    for sg = gA:1.8:gB
        for q = 1:6
            e = (CW/2 + 0.15 + rand01(sg*7+q)*3.6) * sgnOf(q);
            xy = P.at(sg + rand01(sg+q*3)*1.5, e);
            if hypot(xy(1)-F(1), xy(2)-F(2)) > opts.Detail, continue; end
            sc_ = 0.7 + 0.7*rand01(sg*2+q);
            Tg(end+1,:) = [xy(1) xy(2) GZ sc_ sc_ sc_];                 %#ok<AGROW>
        end
    end
    if ~isempty(Tg)
        % REF-13 s7: "Grass is never one colour - bright yellow-green new blades, deep
        % blue-green clumps, dark olive broadleaf weeds, pale straw dead matter at the
        % base." The colour has to vary WITHIN a layer, not only between layers, so the
        % per-tuft spread here is deliberately wide.
        cg = mixN(PLAINS .* (0.62 + 0.76*hash2(Tg(:,1), Tg(:,2))), HZ, ...
                  hazeFactor(hypot(Tg(:,1)-F(1), Tg(:,2)-F(2)), 25, opts.Detail, 0.5));
        S.instances(GRASS.V, GRASS.F, Tg, cg, 'Ambient', 0.46, ...
                    'Tip', mix(PLAINS.*1.30, HZ, 0.10));   % REF-11 s3, root to tip
    end

    % REF-11 s2: EACH LAYER GETS ITS OWN SCATTER. doob (REF-04 s8: 0.05-0.15 m) is the
    % mat that stops the verge reading as bare dirt with spikes stuck in it, so it is
    % laid dense and close in. At 0.14 m it cannot occlude anything.
    Td = zeros(0,6);
    for sd = gA:0.9:gB
        for q = 1:8
            e = (CW/2 + 0.05 + rand01(sd*13+q*5)*3.9) * sgnOf(q);
            xy = P.at(sd + rand01(sd*4+q)*0.8, e);
            if hypot(xy(1)-F(1), xy(2)-F(2)) > opts.Detail*0.65, continue; end
            sd_ = 0.8 + 0.6*rand01(sd+q*9);
            Td(end+1,:) = [xy(1) xy(2) GZ sd_ sd_ sd_];                 %#ok<AGROW>
        end
    end
    if ~isempty(Td)
        cd_ = mixN(PLAINS .* (0.58 + 0.70*hash2(Td(:,1), Td(:,2))), HZ, ...
                   hazeFactor(hypot(Td(:,1)-F(1), Td(:,2)-F(2)), 20, opts.Detail, 0.45));
        S.instances(DOOB.V, DOOB.F, Td, cd_, 'Ambient', 0.48, ...
                    'Tip', mix(PLAINS.*1.22, HZ, 0.08));
    end

    % kans, right verge only
    Tk = zeros(0,6);
    for sk = gA:6.5:gB
        if rand01(sk*11) > 0.55, continue; end
        e = -(CW/2 + 1.4 + rand01(sk*5)*2.2);            % NEGATIVE - the right verge
        assert(e < 0, "sc:kansSide", "kans placed at e=%+.2f, the sight-line side", e);
        xy = P.at(sk, e);
        if hypot(xy(1)-F(1), xy(2)-F(2)) > opts.Detail, continue; end
        sc_ = 0.75 + 0.45*rand01(sk*3);
        Tk(end+1,:) = [xy(1) xy(2) GZ sc_ sc_ sc_];                     %#ok<AGROW>
    end
    if ~isempty(Tk)
        ck = mixN(repmat([0.58 0.57 0.41], size(Tk,1), 1) .* ...
                  (0.85 + 0.3*hash2(Tk(:,2), Tk(:,1))), HZ, 0.10*ones(size(Tk,1),1));
        S.instances(KANS.V, KANS.F, Tk, ck, 'Ambient', 0.52, ...
                    'Tip', [0.86 0.85 0.78]);   % REF-04 s8: feathery WHITE plumes
    end
end

% ------------------------------------------------------------------ the thicket
% The one authored occluder, its radius SOLVED by bisection in sc.s1world until the
% ray-marched reveal matches the written 42 m. Drawn as a CLUSTER, not one ball, so
% what the camera sees is the same shape the solver was given: a mass of that radius.
th = W.Thicket;  reach = 0;
if hypot(th(1)-F(1), th(2)-F(2)) <= Rad + 30
    % ONE MASS AT THE FULL CLAIMED RADIUS. The first version drew a ring of nine small
    % domes summing to roughly the right area, and the sight line went between them.
    % What the solver asserts is a solid circle of radius th(3) up to height th(4), so
    % that is what is drawn. The six smaller bushes only break the silhouette and
    % nothing in the model depends on them.
    Tt = [th(1), th(2), GZ, th(3), th(3), th(4) - GZ];
    S.instances(buV, buF, Tt, mixN(THICKET, HZ, 0.05), 'Ambient', 0.40);

    % DECORATION MUST LIVE INSIDE THE CLAIMED CIRCLE. The first version pushed these
    % six out to th(3) + 0.45*rr, which put drawn foliage 5.96 m from the centre against
    % a modelled 3.48 m - 2.48 m of silhouette the solver knew nothing about - and the
    % cow stayed hidden all the way down to 24 m while the model called it visible from
    % 44 m. They are now seated inside the circle and made TALLER than the core instead,
    % so they break the skyline rather than the plan outline. The assertion is the point:
    % nothing decorative may widen an occluder.
    k = 6;  a = (0:k-1)'/k*2*pi + 0.4;  rr = th(3)*(0.24 + 0.16*hash2(a, a*2));
    off = [cos(a) sin(a)] .* ((th(3) - rr) * 0.85);
    reach = max(vecnorm(off, 2, 2) + rr);
    assert(reach <= th(3) + 1e-9, "sc:s1rDecorWidens", ...
        ['thicket decoration reaches %.2f m from centre against a modelled %.2f m - ' ...
         'the render would occlude more than the solver believes'], reach, th(3));
    Tf = [th(1)+off(:,1), th(2)+off(:,2), GZ*ones(k,1), rr, rr, (th(4)*1.22-GZ)*ones(k,1)];
    Cf = mixN(THICKET .* (0.88 + 0.24*hash2(a*3, a)), HZ, 0.05*ones(k,1));
    S.instances(buV, buF, Tf, Cf, 'Ambient', 0.40);
end

% ------------------------------------------------------------------ sight-line probe
% Optional. Puts the zebu mesh at the emergence point so the reveal can be CHECKED BY
% EYE against the number the solver returned. It makes no motion claim - Phase 3 owns
% the walk - it is here so the occlusion can be seen rather than believed.
if opts.Probe
    [xy, hdg] = P.at(W.CowStation, W.CowEmergeE);
    % THE SAME ANIMAL THE FILM SHOWS. This drew her in one flat colour while
    % s1_film and s1_hud_check used sc.zebuColours, so the stills that exist to prove
    % the reveal showed a plaster mould and the film showed a cow - two different
    % animals in one deliverable. Per-face is all MATLAB has (there are no textures),
    % and it is what puts the fawn body, the paler underside, the dark muzzle and the
    % black hooves REF-04 s2 describes on the mesh.
    cow = sc.meshes("zebu");
    S.mesh(cow, [xy, hdg - pi/2], sc.zebuColours(cow));
end

S.limits(F(1)+[-Rad Rad], F(2)+[-Rad Rad], [-6 70]);

st = struct('Trees', n, 'TreesDetailed', sum(near), 'Scrub', size(U,1), 'Dashes', nd, ...
            'ThicketR', th(3), 'DecorReach', reach, ...
            'RoadFrom', sA, 'RoadTo', sB, 'Seconds', toc(t0));
end

% =======================================================================================
function [X, Y] = bandPoly(P, sA, sB, e0, e1)
%BANDPOLY  The polygon of a lateral band [e0,e1] between stations sA and sB.
%   Sampled along the real centreline at 1 m, so a band round a bend is a band round
%   that bend and not a chord across it.
ss = unique([sA:1.0:sB, sB]);
L = zeros(numel(ss),2); R = zeros(numel(ss),2);
for i = 1:numel(ss)
    L(i,:) = P.at(ss(i), e1);
    R(i,:) = P.at(ss(i), e0);
end
X = [L(:,1); flipud(R(:,1))];
Y = [L(:,2); flipud(R(:,2))];
assert(all(isfinite([X;Y])), "sc:bandNaN", "band polygon contains NaN");
end

% ---------------------------------------------------------------------------------------
function [X, Y] = bandGrid(P, sA, sB, e0, e1, dsAlong, nAcross)
%BANDGRID  The same band as bandPoly, but as a GRID so it can carry a texture.
%   Rows are ACROSS the road and columns ALONG it, which is the order sc.roadTexture
%   returns and the order `texturemap` maps onto the parametric domain. Columns are
%   evenly spaced in STATION, so the texture's along-road coordinate is arc length and
%   the grain does not stretch round a bend.
ss = unique([sA:dsAlong:sB, sB]);
ee = linspace(e0, e1, nAcross);
X = zeros(nAcross, numel(ss));  Y = X;
for i = 1:numel(ss)
    for j = 1:nAcross
        q = P.at(ss(i), ee(j));
        X(j,i) = q(1);  Y(j,i) = q(2);
    end
end
assert(all(isfinite([X(:); Y(:)])), "sc:bandGridNaN", "band grid contains NaN");
end

% ---------------------------------------------------------------------------------------
function [sA, sB] = stationWindow(P, F, reach)
%STATIONWINDOW  The run of stations whose road is inside `reach` of F.
d  = vecnorm(P.P - F, 2, 2);
ix = find(d <= reach);
if isempty(ix), [~,ix] = min(d); end
sA = max(0,      (min(ix)-1)*P.Step - 12);
sB = min(P.Len,  (max(ix)-1)*P.Step + 12);
end

% ---------------------------------------------------------------------------------------
function [V, F] = prismMesh(n, rTop)
%PRISMMESH  Unit n-sided prism, radius 1 at z = 0 tapering to rTop at z = 1.
%
%   IT HAD NO TAPER, AND A TRUNK WITHOUT TAPER IS A PIPE. Read straight off the
%   render: every trunk in the left stand was a constant-diameter tube from the
%   litter to the canopy, and a stand of them read as scaffolding. REF-06 s2 gives
%   the sourced rule - daughter cross-section sums to the mother's, so a two-way
%   split takes each child to 1/sqrt(2) = 0.707 of the parent diameter - and the
%   Blender-authored neem in matlab/assets already uses exactly that via ratioPower.
%   The primitive LOD standing behind it did not, so the two LODs disagreed about
%   what a trunk is. One split's worth of taper over the drawn length is the
%   conservative reading of the same number and it is what is used here.
if nargin < 2, rTop = 0.707; end
th = (0:n-1)'/n*2*pi;
V  = [cos(th) sin(th) zeros(n,1); rTop*cos(th) rTop*sin(th) ones(n,1)];
F  = zeros(0,3);
for i = 1:n
    j = mod(i,n)+1;
    F = [F; i j j+n; i j+n i+n];                            %#ok<AGROW>
end
F = [F; repmat(n+1,n-2,1), (n+2:2*n-1)', (n+3:2*n)'];       % top cap fan
end

% ---------------------------------------------------------------------------------------
function [V, F] = ballMesh(n, flatBottom, lumps)
%BALLMESH  Unit sphere as triangles; flatBottom clamps it into a dome sitting on z = 0.
%
%   LUMPS IS WHY THE CANOPY STOPPED BEING A FIELD OF TORPEDOES, AND IT IS FREE.
%   A crown drawn as a smooth ellipsoid is the single most artificial shape in the
%   frame - REF-06 s3 measured the real thing off Aditya's footage: crowns "merge into
%   one continuous green mass, BUT THE TOP EDGE STILL READS AS SEPARATE LUMPS. Never a
%   smooth hedge silhouette."
%   The obvious fix - two or three offset spheres per tree - triples the geometry on a
%   1,300-tree stand and the film already costs 0.567 s a frame. Perturbing the unit
%   sphere's RADIUS instead costs nothing at all: same vertex count, same face count,
%   one mesh, and the lumps come out in the silhouette where they are wanted.
%   The perturbation is a hash of the vertex DIRECTION, so it is identical every run,
%   and sc.scene/instances' Yaw then spins each copy to a different bearing - which is
%   what stops 1,300 crowns sharing one recognisable bump pattern.
if nargin < 3, lumps = 0; end
[sx, sy, sz] = sphere(n);
if flatBottom, sz = max(sz, 0); end
fv = surf2patch(sx, sy, sz, 'triangles');
V = fv.vertices; F = fv.faces;
if lumps > 0
    d = V ./ max(vecnorm(V, 2, 2), 1e-9);
    g = mod(sin(d(:,1)*12.9898 + d(:,2)*78.233 + d(:,3)*37.719)*43758.5453, 1);
    g = g + 0.5*mod(sin(d(:,1)*31.7 - d(:,2)*17.3 + d(:,3)*53.1)*24634.6345, 1);
    V = V .* (1 + lumps*(g/1.5 - 0.5));
end
end

% ---------------------------------------------------------------------------------------
function [V, F] = rawSTL(name)
%RAWSTL  A Blender-authored asset, base on the ground, footprint centred.
f = fullfile(sc.refRoot(), "matlab", "assets", name + ".stl");
assert(isfile(f), "sc:noAsset", "missing asset %s", f);
TR = stlread(f);
V = TR.Points;  F = TR.ConnectivityList;
V(:,3) = V(:,3) - min(V(:,3));
V(:,1:2) = V(:,1:2) - (min(V(:,1:2)) + max(V(:,1:2)))/2;
end

function v = rand01(k)
v = mod(sin(k*12.9898)*43758.5453, 1);
end

function s = sgnOf(q)
s = 1; if mod(q,2)==0, s = -1; end
end

% ---------------------------------------------------------------------------------------
function [V, F] = discMesh(n, bear, stretch)
%DISCMESH  A flat unit disc, pre-stretched along `bear` - the shadow stencil.
%   Pre-rotating the stencil is what avoids needing per-instance rotation: every
%   shadow in the scene shares one sun, so they differ only in size.
th = (0:n-1)/n*2*pi;
Rz = [cos(bear) -sin(bear); sin(bear) cos(bear)];
p  = (Rz * ([stretch 0; 0 1] * [cos(th); sin(th)]))';
V  = [0 0 0; p, zeros(n,1)];
F  = [ones(n,1), (2:n+1)', [(3:n+1)'; 2]];
end

% ---------------------------------------------------------------------------------------
function [V, F] = latheMesh(pr, pz, n)
%LATHEMESH  A surface of revolution from a (radius, height) profile, n sides.
%   Used instead of a sphere so that "radius r up to height h" is literally what gets
%   drawn - which is the shape the 2-D occlusion model assumes it is getting.
th = (0:n-1)/n*2*pi;
m  = numel(pr);
V  = zeros(m*n, 3);
for k = 1:m
    V((k-1)*n+1:k*n, :) = [pr(k)*cos(th)', pr(k)*sin(th)', pz(k)*ones(n,1)];
end
F = zeros(2*(m-1)*n, 3);  q = 0;
for k = 1:m-1
    for i = 1:n
        j = mod(i,n)+1;
        a = (k-1)*n+i; b = (k-1)*n+j; c = k*n+j; d = k*n+i;
        F(q+1,:) = [a b c];  F(q+2,:) = [a c d];  q = q + 2;
    end
end
end

% ---------------------------------------------------------------------------------------
function v = hash2(a, b)
%HASH2  Deterministic 0..1 from a coordinate pair.
%   NOT rand: s1world has already consumed the rng stream to place the forest, and a
%   renderer that advanced it would change the world it is drawing. Position in,
%   variation out, same every run.
v = mod(sin(a*12.9898 + b*78.233) * 43758.5453, 1);
end

function f = hazeFactor(d, d0, d1, fmax)
f = fmax * min(1, max(0, (d - d0) ./ max(1e-6, d1 - d0)));
end

function c = mix(a, b, f)
c = a*(1-f) + b*f;
end

function C = mixN(A, b, f)
%MIXN  Blend an Nx3 of colours toward one colour by a per-row fraction.
C = A .* (1-f) + b .* f;
C = min(1, max(0, C));
end

% ---------------------------------------------------------------------------------------
function V = lumpAbove(V, zKeep, amt)
%LUMPABOVE  Perturb a lathe's radius ONLY above z = zKeep.
%   Below zKeep the silhouette is a promise the occlusion model relies on, so it is
%   untouched; above it the shape is free and a flat cap is the giveaway.
r  = hypot(V(:,1), V(:,2));
hi = V(:,3) > zKeep & r > 1e-9;
if ~any(hi), return; end
d  = [V(hi,1)./r(hi), V(hi,2)./r(hi)];
g  = mod(sin(d(:,1)*29.7 + d(:,2)*61.3 + V(hi,3)*13.1)*43758.5453, 1);
k  = 1 + amt*(g - 0.5);
V(hi,1) = V(hi,1).*k;  V(hi,2) = V(hi,2).*k;
V(hi,3) = V(hi,3) .* (1 + 0.35*amt*(g - 0.5));
end
