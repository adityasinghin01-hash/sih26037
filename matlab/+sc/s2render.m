function st = s2render(S, W, opts)
%S2RENDER  Draw the static world of S2 - THE CHOWK.
%
%   Four elements and it reads as an Indian chowk: the kerbed island, the stepped plinth
%   and statue, grass verges, post-and-rail fencing. SPEC.md's scope call - NO BUILDINGS.
%   "Less, but properly built": everything the planner measures against is real, and the
%   surroundings are massed.
%
%   THE CIRCULATING CARRIAGEWAY CARRIES NO LANE MARKINGS AND THAT IS DELIBERATE. It is
%   the fact S2 turns on: there is no reference line to follow, which is exactly what
%   MathWorks' shipped planner requires and cannot synthesise.

arguments
    S sc.scene
    W struct
    opts.Radius (1,1) double = 150
    opts.Detail (1,1) double = 60
    % HAZE IS MEASURED FROM THE CAMERA, NOT FROM THE SCENE CENTRE. Defaulting it to the
    % chowk centre meant that in an overhead shot 78 m up, every metre of ground in frame
    % sat beyond HazeStart, so the whole world washed to 70 % sky colour and the render
    % came back a flat blue-green blur with a roundabout floating in it.
    opts.HazeFrom (1,2) double = [NaN NaN]
    opts.HazeMax  (1,1) double = 0.70
    opts.Sky    (1,1) logical = true
    opts.Actors (1,1) logical = false
end

t0 = tic;
C = W.Centre;  HZ = [0.74 0.78 0.80];
HF = opts.HazeFrom;  if any(isnan(HF)), HF = C; end

% REF-13 s7: plains vegetation, measured, ~31 % saturation - not the 51 % alpine green.
PLAINS   = [0.362 0.455 0.373];
% THE SAME TWO HUES AS S1, AND THE SAME NUMBERS - not a second, cruder formula. REF-06
% s6: greens are YELLOW-green in sun and BLUE-green in shade, "two different hues, not
% one lit twice". Scaling one triple by a brightness factor cannot change its
% saturation, so each crown sits somewhere on the line between these two instead.
CROWN_SUN   = [0.600 0.775 0.470];
CROWN_SHADE = [0.505 0.660 0.680];
CROWN_MID   = (CROWN_SUN + CROWN_SHADE)/2;
CROWN_TIP   = [0.680 0.840 0.560];
GRASS    = PLAINS .* 0.95;
DIRT     = [0.53 0.46 0.34];
TARMAC   = [0.295 0.295 0.305];
TARMAC2  = [0.315 0.312 0.318];      % the ring is resurfaced separately from the arms
PAINT    = [0.86 0.84 0.77];
KERB_W   = [0.84 0.82 0.76];
KERB_B   = [0.16 0.15 0.15];
PLINTH   = [0.72 0.69 0.62];
STATUE   = [0.60 0.56 0.50];
RAIL     = [0.52 0.50 0.46];
GZ = -0.30;

Z_GRASS = -0.105;  Z_ROAD = 0.030;  Z_PAINT = 0.036;
Z_ISLE  = 0.150;   Z_KERB = 0.152;

% ---------------------------------------------------------------- sky and ground
if opts.Sky
    S.skydome(C, 900);
    % THE FAR GROUND WAS A PALE PLATE AND THE HORIZON A FLAT STRIP, and together they
    % read as a hazy sea behind the trees. Two causes: the far annulus was tinted
    % toward DIRT while the near ground is GRASS, so the two met in a visible tonal
    % step; and the horizon band was PALER than the treeline in front of it, which
    % inverts REF-13 s5 - haze converges distance UP toward the sky, but a wooded
    % horizon is still darker than the sky it sits against, never lighter than the
    % wood in front of it. Far ground now runs off the grass, and the horizon band is
    % darker and taller so it reads as distant trees rather than as water.
    S.farGround(C, opts.Radius + 40, 860, mix(GRASS.*0.92, HZ, 0.66));
    S.horizon(C, 430, mix(CROWN_SHADE.*0.80, HZ, 0.52), 22);
end
S.ground(C(1)+[-opts.Radius-40 opts.Radius+40], C(2)+[-opts.Radius-40 opts.Radius+40], ...
         GRASS, 'Step', 5, 'Relief', 0.09, 'Hollow', GRASS.*0.58, ...
         'Haze', HZ, 'HazeFrom', HF, 'HazeStart', 40, 'HazeFull', opts.Radius+40, ...
         'HazeMax', opts.HazeMax);

% ---------------------------------------------------------------- the four arms
nArm = 0;
for k = 1:4
    P = W.Arm(k).Path;
    % THE VERGE, TEXTURED - Phase 5's ground half. Same mechanism and the same
    % measured target as S1's shoulder (sc.groundTexture, CoV 0.0861 off
    % matlab/ground_contrast_probe.m); a different seed per arm so the four verges
    % do not repeat one visible grain pattern round the chowk.
    [GXv,GYv] = bandG(P, 0, P.Len, -(W.ArmW/2 + 1.6), (W.ArmW/2 + 1.6), 2.5, 8);
    Mvrg = sc.groundTexture(W.ArmW/2 + 1.6, P.Len, 'Seed', 31 + k);
    S.carpet(GXv, GYv, Z_ROAD - 0.02, uint8(255*min(1, reshape(DIRT,1,1,3) .* Mvrg)));
    % THE ARM'S CARRIAGEWAY, TEXTURED. See sc.roadTexture and REF-17 s22: the image is
    % a MULTIPLIER on TARMAC, so the measured grey cannot move, and its amplitude is
    % solved to the coefficient of variation measured off 59 of Aditya's dashcam frames.
    [GX,GY] = bandG(P, 0, P.Len, -W.ArmW/2, W.ArmW/2, 2.5, 7);
    Marm = sc.roadTexture(W.ArmW/2, P.Len);
    S.carpet(GX, GY, Z_ROAD, uint8(255*min(1, reshape(TARMAC,1,1,3) .* Marm)));
    % edge lines only. The ARMS are marked; the RING is not.
    for sgn = [-1 1]
        [X,Y] = band(P, 0, P.Len, sgn*(W.ArmW/2-0.30), sgn*(W.ArmW/2-0.15));
        S.flat(X, Y, Z_PAINT, PAINT, 0.6);
    end
    nArm = nArm + 1;
end

% ---------------------------------------------------------------- circulating carriageway
th = linspace(0, 2*pi, 129)';
ringOut = C + W.Rout*[cos(th) sin(th)];
ringIn  = C + W.Rin *[cos(th) sin(th)];
% THE CIRCULATING CARRIAGEWAY, TEXTURED - and an annulus is already a grid, so it
% needs no helper: rows are RADIUS (across) and columns are THETA (along), which is the
% order `texturemap` maps onto the parametric domain.
% ONE LANE, DELIBERATELY. S2 turns on the fact that the ring carries NO markings, so
% there are not two lanes to wear two pairs of wheel paths into - there is a single
% circulating stream and one broad worn band. Passing Lanes 2 would draw a lane
% structure onto the one surface in the scenario whose whole point is that it has none.
nR = 7;
rr = linspace(W.Rin, W.Rout, nR)';
GXr = C(1) + rr*cos(th');   GYr = C(2) + rr*sin(th');
Mring = sc.roadTexture((W.Rout-W.Rin)/2, pi*(W.Rout+W.Rin), 'Lanes', 1, 'Seed', 23);
S.carpet(GXr, GYr, Z_ROAD, uint8(255*min(1, reshape(TARMAC2,1,1,3) .* Mring)));

% ---------------------------------------------------------------- give-way lines
% S2: "double line, 200 mm wide, 300 mm apart" at each entry. These ARE marked - it is
% only the circulating carriageway that carries nothing.
nGw = 0;
for k = 1:4
    P = W.Arm(k).Path;
    for j = 0:1
        s0 = 1.2 + j*(W.GiveWay.Width + W.GiveWay.Gap);
        [X,Y] = band(P, s0, s0 + W.GiveWay.Width, -W.ArmW/2, W.ArmW/2);
        S.flat(X, Y, Z_PAINT, PAINT, 0.75);
        nGw = nGw + 1;
    end
end

% ---------------------------------------------------------------- the island
% The island top is the SOIL the grass stands in, so it has to be darker than the
% blades - lighter, and every tuft reads as a dead twig lying on a lawn.
% TEXTURED, same mechanism as the verges - S2 s0 says "unmown grass" on the island,
% so it carries the same fine ground structure rather than one flat poster colour.
nRi = 7;  rri = linspace(0, W.Rin, nRi)';  thi = linspace(0, 2*pi, 129);
GXi = C(1) + rri*cos(thi);  GYi = C(2) + rri*sin(thi);
Misl = sc.groundTexture(max(W.Rin,1), pi*max(W.Rin,1), 'Seed', 41);
S.carpet(GXi, GYi, Z_ISLE, uint8(255*min(1, reshape(GRASS.*0.78,1,1,3) .* Misl)));
% kerb ring, painted in black-and-white 500 mm bands (S2). Built as alternating arcs so
% the bands are real geometry, chipped by the colour jitter rather than by a texture.
nB = round(2*pi*W.Rin / 0.5);
for b = 1:nB
    a0 = (b-1)/nB*2*pi;  a1 = b/nB*2*pi;
    aa = linspace(a0, a1, 3)';
    o = C + (W.Rin+0.18)*[cos(aa) sin(aa)];
    i = C + (W.Rin-0.02)*[cos(aa) sin(aa)];
    if mod(b,2)==0, col = KERB_W .* (0.88+0.2*rand01(b)); else, col = KERB_B .* (0.8+0.5*rand01(b)); end
    S.flat([o(:,1); flipud(i(:,1))], [o(:,2); flipud(i(:,2))], Z_KERB, min(1,col));
end

% raised planted circle, then the stepped plinth
S.flat(C(1)+W.Plinth.RaisedR*cos(th), C(2)+W.Plinth.RaisedR*sin(th), ...
       Z_ISLE + W.Plinth.RaisedH, GRASS.*0.70);
for s = 1:W.Plinth.Steps
    f = 1 - (s-1)/W.Plinth.Steps*0.45;
    w = W.Plinth.W * f;
    hz = Z_ISLE + W.Plinth.RaisedH + (s-1)*W.Plinth.H/W.Plinth.Steps;
    S.box3([C(1) C(2)], [w w W.Plinth.H/W.Plinth.Steps], hz, 0, PLINTH .* (0.94+0.04*s));
end
% the statue - person-scale, which is what a real small-town chowk has
topZ = Z_ISLE + W.Plinth.RaisedH + W.Plinth.H;
% S2: "a person-scale statue... which is what a real small-town chowk has." The first
% version was a box and a thinner box on top - it read as a pole on a wedding cake.
% Legs, torso, one raised arm, head: a standing figure at any distance a camera sees it.
% AND FOUR STACKED BOXES IS STILL A SCARECROW. The previous note was right that a
% box on a box "read as a pole on a wedding cake" and added limbs - but every part was
% still a CUBOID, so the figure came out as a robot: square shoulders, a cube for a
% head, one rectangular arm. A statue is the thing the camera is pointed at on this
% island, and a rectangular silhouette is the one shape a human body never has.
%
% Built from round stock instead - a lathe for the body, spheres for head and
% shoulders, tapered prisms for the limbs - and with the two features that actually
% carry "Indian chowk statue" at 20 m: the figure stands in a DHOTI, so the lower body
% is a smooth cone rather than two legs, and ONE ARM IS RAISED, which is the
% silhouette Gandhi, Ambedkar and Bose all share on small-town plinths.
% MATLAB has no textures, so silhouette is the entire budget - spend it on shape.
H = W.Statue.H;  YAW = 0.4;
[sphV, sphF] = ballMesh2(9);
% the dhoti: a cone from the ankles out to the hips, which is the real garment shape
[dhV, dhF] = latheMesh2([0.17 0.19 0.21 0.20 0.16], [0 0.10 0.26 0.40 0.50], 14);
S.instances(dhV, dhF, [C(1) C(2) topZ 1 1 H*0.52/0.50], STATUE.*0.94, ...
            'Ambient', 0.44);
% torso: narrow at the waist, wide at the shoulders
[tsV, tsF] = latheMesh2([0.15 0.17 0.20 0.21 0.18 0.09], ...
                        [0    0.08 0.20 0.30 0.36 0.40], 14);
S.instances(tsV, tsF, [C(1) C(2) topZ+H*0.50 1 1 H*0.34/0.40], STATUE, ...
            'Ambient', 0.44);
% shoulders and head
S.instances(sphV, sphF, [C(1) C(2) topZ+H*0.82 0.20 0.15 0.075], STATUE.*0.98, ...
            'Ambient', 0.44);
S.instances(sphV, sphF, [C(1) C(2) topZ+H*0.90 0.095 0.088 0.105], STATUE.*1.06, ...
            'Ambient', 0.46);
% the raised arm, and a second arm down at the side
[arV, arF] = latheMesh2([0.050 0.045 0.038 0.030], [0 0.35 0.72 1.0], 8);
aOff = 0.20;
S.instances(arV, arF, ...
    [C(1)+aOff*cos(YAW+1.5), C(2)+aOff*sin(YAW+1.5), topZ+H*0.72, 1, 1, H*0.30], ...
    STATUE.*0.99, 'Ambient', 0.44);
% A NEGATIVE Z SCALE MIRRORS THE MESH, which reverses every face's winding and
% points its normal inward - the arm would have shaded black. The hanging arm gets
% its own profile, thick at the shoulder and thin at the hand, and a POSITIVE scale
% with its base at the wrist.
[adV, adF] = latheMesh2([0.030 0.038 0.045 0.050], [0 0.28 0.65 1.0], 8);
S.instances(adV, adF, ...
    [C(1)-aOff*cos(YAW+1.5), C(2)-aOff*sin(YAW+1.5), topZ+H*0.46, 1, 1, H*0.34], ...
    STATUE.*0.95, 'Ambient', 0.44);

% the railing round the monument, and the four floodlight posts (unlit)
% A RAILING, NOT A RING OF STAKES. 22 posts of 0.09 m at 0.85 m tall crowded into a
% palisade round the plinth. Thinner, fewer, and with an actual top rail between them.
nR = 14;
railZ = Z_ISLE + W.Plinth.RaisedH;
for r = 1:nR
    a  = (r-1)/nR*2*pi;  a2 = r/nR*2*pi;
    S.box3([C(1)+W.RailR*cos(a), C(2)+W.RailR*sin(a)], [0.055 0.055 0.62], railZ, a, RAIL);
    p1 = [C(1)+W.RailR*cos(a),  C(2)+W.RailR*sin(a)];
    p2 = [C(1)+W.RailR*cos(a2), C(2)+W.RailR*sin(a2)];
    S.box3((p1+p2)/2, [norm(p2-p1) 0.035 0.045], railZ + 0.55, ...
           atan2(p2(2)-p1(2), p2(1)-p1(1)), RAIL.*1.05);
end
for a = (0:3)/4*2*pi + 0.4
    S.box3([C(1)+(W.RailR-0.9)*cos(a), C(2)+(W.RailR-0.9)*sin(a)], [0.14 0.14 1.5], Z_ISLE + W.Plinth.RaisedH, a, ...
          RAIL.*0.9);
end

% TWO SHRUBS, AND S2 COUNTS THEM. "Around it inside the island: unmown grass, TWO
% SHRUBS, a hoarding frame, litter blown against the kerb, and a municipal signboard."
% They were simply absent. Two is the written number, so two is what is drawn - a
% counted detail is a specification, not a suggestion, and "some shrubs" would be the
% start of the uniform-scatter failure REF-04 s6 warns about.
% Built as overlapping lobes rather than one ball: a shrub is a clump of growth, and
% the single-sphere version of this in S1 was the "field of pale torpedoes" defect.
% AND FOUR SMOOTH SPHERES INSIDE ONE RADIUS IS STILL ONE SPHERE. The lobes were
% offset by only 0.34 of the shrub radius with radii of 0.44-0.74, so they overlapped
% almost completely and the near shrub rendered as a single smooth balloon 3.9 m
% across - the most artificial object left in the island shot, and the same "field of
% pale torpedoes" failure the comment above says it was built to avoid. Lumping the
% unit sphere costs nothing (same vertex and face count, the move already used for the
% S1 crowns and the backdrop wall) and the lobes are thrown wider so the clump has a
% silhouette instead of an outline.
[shV, shF] = ballMesh2(8);
shV = lumpAll(shV, 0.42);
shrubAt = [C + [-7.4  3.1], 1.55; C + [ 6.2 -6.6], 1.95];
for i = 1:size(shrubAt,1)
    b = shrubAt(i,3);
    Tsh = zeros(0,6); Csh = zeros(0,3);
    for q = 1:4
        aa = 2*pi*hash2(i*7+q, i*3);  dd = b*0.62*hash2(i*11+q, i*5);
        rq = b*(0.38 + 0.26*hash2(i*13+q, i*2));
        Tsh(end+1,:) = [shrubAt(i,1)+dd*cos(aa), shrubAt(i,2)+dd*sin(aa), ...
                        Z_ISLE + rq*0.55, rq, rq*0.92, rq*0.86];        %#ok<AGROW>
        Csh(end+1,:) = CROWN_SHADE .* (0.72 + 0.30*hash2(i*17+q, i));   %#ok<AGROW>
    end
    S.instances(shV, shF, Tsh, Csh, 'Ambient', 0.42, 'Tip', CROWN_TIP.*0.92);
end

% the municipal signboard - S2 lists it, and one upright rectangle at the island edge
% is the cheapest thing in the scene that says "this is a town, and it has a name".
sgA = 2.35;
sgP = C + (W.Rin - 2.6)*[cos(sgA) sin(sgA)];
sgN = [cos(sgA + pi/2), sin(sgA + pi/2)];      % across the board, not along it
for dx = [-0.62 0.62]
    S.box3(sgP + dx*sgN, [0.09 0.09 1.35], Z_ISLE, sgA, RAIL.*0.86);
end
S.box3(sgP, [1.55 0.08 0.62], Z_ISLE + 1.20, sgA + pi/2, [0.30 0.42 0.30]);

% ---------------------------------------------------------------- splitter islands
nSp = 0;
for k = 1:4
    P = W.Arm(k).Path;  sp = W.Splitter;
    ss = linspace(2.0, 2.0 + sp.Len, 14)';
    wq = sp.WNose + (sp.WTail - sp.WNose) * (ss - ss(1))/(ss(end)-ss(1));
    L = zeros(numel(ss),2); R = zeros(numel(ss),2);
    for i = 1:numel(ss)
        L(i,:) = P.at(ss(i),  wq(i)/2);
        R(i,:) = P.at(ss(i), -wq(i)/2);
    end
    S.flat([L(:,1); flipud(R(:,1))], [L(:,2); flipud(R(:,2))], Z_KERB, KERB_W.*0.94);
    S.flat([L(:,1); flipud(R(:,1))], [L(:,2); flipud(R(:,2))], Z_KERB+0.002, GRASS.*0.9, 0.55);
    nSp = nSp + 1;
end

% ---------------------------------------------------------------- verges and fencing
% S2/SPEC: post-and-rail fence separating grass from tarmac. "Massed, not detailed"
% is the spec's OWN call here, not an oversight - at ~114 posts around the gyratory,
% a heavily detailed fence would work against both that written intent and render
% speed. What changed, 6 Sep: Blender-authored geometry (octagonal chamfered post,
% rounded-edge rail - blend/vehicles/fence.py) instead of sc.box3's flat cuboids, 72
% triangles total, batched into ONE instanced patch per part exactly like every other
% repeated prop on this road (grass, scrub) rather than one graphics object per post -
% both a real shape upgrade and, unlike the old per-call box3 loop, no added cost.
persistent FENCE_POST FENCE_RAIL
if isempty(FENCE_POST)
    try
        [fpv, fpf] = rawSTL2("fence_post"); FENCE_POST = struct('V',fpv,'F',fpf);
        [frv, frf] = rawSTL2("fence_rail"); FENCE_RAIL = struct('V',frv,'F',frf);
    catch
        FENCE_POST = struct('V',[]); FENCE_RAIL = struct('V',[]);
    end
end
nPost = 0;
Tpost = zeros(0,6); Trail = zeros(0,6); railYaw = zeros(0,1);
for k = 1:4
    P = W.Arm(k).Path;
    for sgn = [-1 1]
        for s = 6:4.5:P.Len
            xy = P.at(s, sgn*(W.ArmW/2 + 2.2));
            if hypot(xy(1)-C(1), xy(2)-C(2)) > opts.Radius, continue; end
            % THE ARMS ARE 5 AND 16 DEGREES APART, SO A VERGE CAN LAND ON THE NEXT
            % ARM'S TARMAC. The first version put fence posts - solid obstacles - on a
            % carriageway the planner drives. Found by looking at the approach shot.
            % Nothing may be planted where any arm, or the ring, is drivable.
            if onAnyRoad(W, xy, C), continue; end
            Tpost(end+1,:) = [xy(1) xy(2) GZ 1 1 1];                    %#ok<AGROW>
            nPost = nPost + 1;
            % POST-AND-RAIL. The first version drew only posts, so the fence read as
            % sticks pushed into the verge at random. Two rails between consecutive
            % posts is what makes it a fence.
            if s + 4.5 <= P.Len
                xy2 = P.at(s + 4.5, sgn*(W.ArmW/2 + 2.2));
                if onAnyRoad(W, xy2, C), continue; end
                mid = (xy + xy2)/2;
                spanLen = hypot(xy2(1)-xy(1), xy2(2)-xy(2));
                ang = atan2(xy2(2)-xy(2), xy2(1)-xy(1));
                for rz = [0.42 0.82]
                    % rail is UNIT LENGTH along x with its real cross-section already
                    % baked in, so sx=spanLen stretches it and sy=sz=1 keeps the
                    % 0.05 x 0.09 m section exact - same scaling contract every other
                    % instanced prop in this file uses.
                    Trail(end+1,:) = [mid(1) mid(2) GZ+rz spanLen 1 1];  %#ok<AGROW>
                    railYaw(end+1,1) = ang;                              %#ok<AGROW>
                end
            end
        end
    end
end
if ~isempty(FENCE_POST.V) && ~isempty(Tpost)
    S.instances(FENCE_POST.V, FENCE_POST.F, Tpost, ...
        repmat([0.46 0.40 0.31], size(Tpost,1), 1), 'Ambient', 0.40, 'Smooth', false);
end
if ~isempty(FENCE_RAIL.V) && ~isempty(Trail)
    S.instances(FENCE_RAIL.V, FENCE_RAIL.F, Trail, ...
        repmat([0.44 0.38 0.30], size(Trail,1), 1), 'Ambient', 0.40, ...
        'Yaw', railYaw, 'Smooth', false);
end

% ---------------------------------------------------------------- grass, per REF-11 s2
persistent GT DB
if isempty(GT)
    try
        [gv,gf] = rawSTL2("grass_tuft"); GT = struct('V',gv,'F',gf);
        [dv,df] = rawSTL2("doob_patch"); DB = struct('V',dv,'F',df);
    catch, GT = struct('V',[]); DB = struct('V',[]); end
end
nG = 0;
if ~isempty(GT.V)
    T = zeros(0,6);
    for k = 1:4
        P = W.Arm(k).Path;
        for s = 3:1.6:min(P.Len, opts.Detail)
            for q = 1:5
                e = (W.ArmW/2 + 0.3 + rand01(s*7+q)*4.5) * sgnOf(q);
                xy = P.at(s + rand01(s+q)*1.2, e);
                if hypot(xy(1)-C(1), xy(2)-C(2)) > opts.Detail*1.6, continue; end
                if onAnyRoad(W, xy, C), continue; end
                sc_ = 0.7 + 0.7*rand01(s*3+q);
                T(end+1,:) = [xy(1) xy(2) GZ sc_ sc_ sc_];               %#ok<AGROW>
            end
        end
    end
    % S2: "unmown grass" on the island. Tall tufts ALONE read as dead sticks on bare
    % soil - REF-11 s2's point is that a layer needs the MAT underneath it. Doob first,
    % tufts sparsely on top.
    % DENSITY AND TONE, both measured off the render. At 300 mats and 70 tufts over a
    % 452 m2 island this was one plant every 1.2 m2 - visibly bare soil between them -
    % and the tufts read as pale spikes because Tip ran to PLAINS*1.55, which clips
    % into near-white. REF-13 s7 measures the real thing: grass is FOUR greens plus a
    % dead straw layer, none of them white. Denser, and the tip pulled back so the
    % variation reads as grass rather than as blown highlights.
    % MEASURED, NOT ASSUMED: doob_patch.stl is a 0.32 x 0.24 m mat (matlab/assets),
    % and 900 of them over the island's ~414 m2 annulus is about 20 % areal coverage -
    % 80 % of the "lawn" was actually bare textured floor showing through, which is
    % why sparse tufts on top read as sticks poking out of dirt rather than grass
    % emerging from a mat. ~2600 gets coverage past 60 %, past the point individual
    % mats visually merge into a continuous ground layer.
    Ti = zeros(0,6);
    for r = 1:2600
        a  = rand01(r*5)*2*pi;
        rr = W.Plinth.RaisedR*0.55 + rand01(r*9)*(W.Rin - W.Plinth.RaisedR*0.55 - 1.0);
        sc_ = 0.85 + 0.5*rand01(r*11);
        Ti(end+1,:) = [C(1)+rr*cos(a), C(2)+rr*sin(a), Z_ISLE-0.02, sc_, sc_, sc_]; %#ok<AGROW>
    end
    if ~isempty(DB.V)
        S.instances(DB.V, DB.F, Ti, ...
            mixN(PLAINS .* (0.80 + 0.55*hash2(Ti(:,1),Ti(:,2))), HZ, 0.06*ones(size(Ti,1),1)), ...
            'Ambient', 0.54, 'Tip', mix(PLAINS.*1.22, HZ, 0.05));
    end
    % WIDTH, NOT JUST COUNT OR TONE - neither fixed the "dead twig" read (see the
    % two things already tried and abandoned above: 3x the doob coverage, and a
    % much darker Tip - visually identical results, which is the tell that colour
    % was never the cause). grass_tuft.stl is only 0.19 x 0.20 m at scale 1 - a
    % narrow blade cluster that, seen from a driving/standing height, is a handful
    % of thin marks rather than a bushy clump. Widened well past its height scale
    % so each instance reads as a SPREAD of blades, the actual silhouette a real
    % untidy tuft has, rather than a few thin uprights.
    for r = 1:380
        a = rand01(r*5)*2*pi;  rr = W.Plinth.RaisedR + 0.8 + rand01(r*9)*(W.Rin-W.Plinth.RaisedR-1.6);
        T(end+1,:) = [C(1)+rr*cos(a), C(2)+rr*sin(a), Z_ISLE-0.02, ...
                      1.8+0.9*rand01(r), 1.8+0.9*rand01(r), 0.85+0.35*rand01(r*3)]; %#ok<AGROW>
    end
    if ~isempty(T)
        % 0.74 PUT THE BOTTOM OF THE SPREAD AT 3/4 OF THE MEASURED PLAINS GREEN, and
        % against the doob mat under them the darker half of the tufts read as bare
        % dark twigs rather than as grass. The spread stays wide (REF-13 s7: colour
        % varies WITHIN a layer) but it is centred on the measurement instead of
        % sitting below it.
        cg = mixN(PLAINS .* (0.88 + 0.52*hash2(T(:,1), T(:,2))), HZ, ...
                  hazeF(hypot(T(:,1)-HF(1), T(:,2)-HF(2)), 30, opts.Radius, 0.55*opts.HazeMax/0.70));
        % TIP PULLED BACK FROM x1.26 TO x0.98, MEASURED AGAINST THE RENDER, NOT
        % GUESSED. Denser coverage (above) did not fix the "dead twigs" read - it
        % made MORE of the same problem, which is the tell that density was never
        % the actual cause. grass_tuft.stl is a thin vertical blade cluster
        % (0.19 x 0.20 x 0.52 m), so almost its whole visible silhouette sits near
        % the Tip end of the height blend - a bright x1.26 tip was therefore not
        % colouring the TOP of a mostly-base-coloured blade, it was colouring nearly
        % the WHOLE blade pale, which is what read as a dry stick rather than a
        % living tuft. Pulled to just under the base tone instead.
        S.instances(GT.V, GT.F, T, cg, 'Ambient', 0.50, 'Tip', mix(PLAINS.*0.98, HZ, 0.08));
        nG = size(T,1);
    end
end

% ---------------------------------------------------------------- backdrop treeline
% SPEC.md's scope call for S2 is "no buildings at all", and that stands. But an empty
% green plain does not read as a chowk either, and the standard allows scenery to be
% MASSED. REF-04 s7: neem is the roadside tree, young roadside specimens 8-14 m, and
% REF-04 s7 again: crowns merge below 10 m spacing, so these sit at 11-16 m and read
% as separate trees rather than a hedge. Nothing here is measured against; it is
% backdrop, and it is declared as backdrop.
persistent TREE
if isempty(TREE)
    try TREE = sc.treeAsset(); catch, TREE = struct('Tris',0); end
end
nT = 0;
if isfield(TREE,'Vb')
    % THE WALL'S SHAPE, DEFINED ONCE AND USED BY BOTH THE GUARD AND THE DRAW.
    % These were two separate literals in two places - the reach the placement
    % guard cleared and the radius the wall was actually drawn at - which is the
    % same one-number-in-two-places failure REF-17 s17c paid for with the crown
    % offset ("the offset lived only in s1render, so the world did not know where
    % its own crowns were"). If they disagree, either the stand does not close or
    % the geometry lands on a carriageway, and both have now happened here.
    % Multiples of the CROWN RADIUS (TREE.CrownR * h), never of the height scale.
    % MEASURED OFF THE ASSET: CrownR = 0.241 x height, foliage starts at 0.360.
    % So an 11 m neem has a 2.65 m crown radius and its crown begins at 3.96 m.
    % AND IT MUST BE NARROWER THAN THE CROWN IT STANDS UNDER, WHICH IS WHY 0.90-1.50
    % FAILED. At up to 1.5 crown radii the mass was WIDER than the foliage above it,
    % offset sideways by up to 0.9 more, and it stopped below where the foliage
    % starts - so it rendered as a dark boulder sitting BESIDE a lollipop tree, with
    % the trunk still bare above it, in all four shots. An understorey is not a rock
    % next to a tree; it is the shaded mass beneath its own canopy, and it has to
    % read as continuous with the foliage rather than as a separate object.
    WALL_R0 = 0.55;  WALL_R1 = 0.45;      % rj = crR * (R0 + R1*hash), <= 1 crown radius
    WALL_OFF = 0.55;                      % dd = crR * OFF * hash, stays under the crown
    % HEIGHT IS A FRACTION OF THE TREE, AND IT MUST OVERLAP THE FOLIAGE. Stopping the
    % mass at the crown base (0.36 h, measured) leaves a bright horizontal seam right
    % where the two meet, and the eye reads that seam as the top of a separate object.
    % Running it to 0.42-0.72 h pushes it well into the foliage band so the two merge
    % into one silhouette - which is REF-06 s3's "solid dark wall... you do not see
    % through it and you do not see individual trunks". It also makes every mass
    % taller than it is wide, which is what stops a lathe reading as a drum.
    WALL_H0 = 0.42;  WALL_H1 = 0.30;      % hj = h * (H0 + H1*hash)
    WALL_REACH = WALL_R0 + WALL_R1 + WALL_OFF;   % worst case, in crown radii
    T = zeros(0,6);
    for r = 1:260
        a  = rand01(r*3.1)*2*pi;
        rr = 46 + rand01(r*7.7)*(opts.Radius - 55);
        xy = [C(1)+rr*cos(a), C(2)+rr*sin(a)];
        if onAnyRoad(W, xy, C), continue; end
        h = 8 + rand01(r*5.3)*6;                      % REF-04 s7: 8-14 m roadside neem
        % THE GUARD HAS TO KNOW HOW WIDE THE THING IT IS PLANTING WILL BE.
        % It cleared the TRUNK POSITION by a flat 6.5 m and the understorey mass
        % drawn under that trunk then reached far past it - which is REF-17 s7a
        % BUG 2 exactly ("nothing may be drawn that the solver does not know
        % about"), and s15a's own rule about planting on the carriageway, both
        % defeated by checking a point instead of an extent. The reach below is
        % the same arithmetic the wall is actually drawn with.
        wallReach = TREE.CrownR * h * WALL_REACH;
        near = false;
        for k = 1:4
            [ss, e] = W.Arm(k).Path.inverse(xy);
            if ss > 0.5 && ss < W.Arm(k).Path.Len-0.5 && ...
               abs(e) < W.ArmW/2 + wallReach + 2.0
                near = true; break
            end
        end
        if near, continue; end
        T(end+1,:) = [xy(1) xy(2) GZ h*(0.9+0.2*rand01(r)) h*(0.9+0.2*rand01(r*2)) h]; %#ok<AGROW>
        % CLUMPED, NOT SPRAYED - REF-11 s5 and REF-04 s6, the same rule S1 obeys.
        % An even ring of single trees round the horizon is the "uniform spread is the
        % tell" failure; real stands are crowded and empty at the same time. A second
        % and third tree are dropped beside roughly half of these, close enough that
        % their crowns merge (REF-04 s7: below 10 m they merge).
        if rand01(r*11.3) < 0.55
            for q = 1:1+round(rand01(r*13.7))
                aa = rand01(r*17+q)*2*pi;  dd = 3.5 + rand01(r*19+q)*5.0;
                x2 = xy(1)+dd*cos(aa);  y2 = xy(2)+dd*sin(aa);
                if onAnyRoad(W, [x2 y2], C), continue; end
                h2 = h*(0.72 + 0.4*rand01(r*23+q));
                % AND THE CLUMPS NEVER HAD THE ARM GUARD AT ALL - only onAnyRoad,
                % which is a point test. A clump tree is dropped up to 8.5 m from
                % its parent, so it could land beside an arm the parent had cleared.
                wr2 = TREE.CrownR * h2 * WALL_REACH;
                skip = false;
                for k = 1:4
                    [s2_, e2_] = W.Arm(k).Path.inverse([x2 y2]);
                    if s2_ > 0.5 && s2_ < W.Arm(k).Path.Len-0.5 && ...
                       abs(e2_) < W.ArmW/2 + wr2 + 2.0
                        skip = true; break
                    end
                end
                if skip, continue; end
                T(end+1,:) = [x2 y2 GZ h2*(0.9+0.2*rand01(r*29+q)) ...
                              h2*(0.9+0.2*rand01(r*31+q)) h2];   %#ok<AGROW>
            end
        end
    end
    if ~isempty(T)
        d = hypot(T(:,1)-HF(1), T(:,2)-HF(2));
        f = hazeF(d, 40, opts.Radius, opts.HazeMax);
        S.instances(TREE.Vb, TREE.Fb, T, ...
            mixN(repmat([0.27 0.23 0.19], size(T,1), 1) .* ...
                 (0.8+0.4*hash2(T(:,1),T(:,2))), HZ, f), 'Ambient', 0.38);
        S.instances(TREE.Vf, TREE.Ff, T, ...
            mixN(CROWN_SHADE + (CROWN_SUN-CROWN_SHADE).*hash2(T(:,2),T(:,1)), HZ, f), ...
            'Ambient', 0.44, 'Tip', mix(CROWN_TIP, HZ, 0.06));
        % THE TREELINE IS CLOSED AT THE BOTTOM - REF-06 s3, and S2 had exactly the
        % defect S1 already paid for: bare trunks with pom-pom crowns on top, daylight
        % showing under the whole stand, so the backdrop read as a plantation of
        % lollipops standing on a lawn. "From about 1 m up it is a solid dark wall -
        % you do not see through it and you do not see individual trunks."
        % Nothing here is an occluder - S2's planner claims rest on the give-way line
        % and the circulating carriageway, not on sight lines through the backdrop -
        % so this is pure scenery, massed, and declared as such.
        % LUMPED OVER ITS WHOLE HEIGHT, exactly as S1's wall is. Nothing here is an
        % occluder - stated above - so no silhouette is promised to anything and a
        % smooth lathe is pure loss. Same vertex and face count.
        [uwV, uwF] = latheMesh2([1 1 0.96 0.82 0.55 0], [0 0.62 0.78 0.90 0.97 1], 9);
        uwV = lumpAll(uwV, 0.50);
        Tu = zeros(0,6);  Cu = zeros(0,3);
        for q = 1:3          % 3, not 2 - two lobes left gaps a clump could not close
            % crR IS A RADIUS. T(:,4) IS A HEIGHT SCALE. They are not the same
            % quantity and using one for the other is what put a 13 m black mass
            % on the approach camera - the asset is returned unit-HEIGHT, so a
            % tree scaled by h = 14 has a crown radius of CrownR*14, not 14.
            crR = TREE.CrownR * T(:,6);
            rj = crR .* (WALL_R0 + WALL_R1*hash2(T(:,1)*(q+1), T(:,2)));
            aa = 2*pi*hash2(T(:,1)*(q+5), T(:,2)*(q+2));
            dd = crR .* WALL_OFF .* hash2(T(:,2)*(q+3), T(:,1));
            hj = T(:,6) .* (WALL_H0 + WALL_H1*hash2(T(:,2)*(q*3), T(:,1)*q));
            Tu = [Tu; T(:,1)+dd.*cos(aa), T(:,2)+dd.*sin(aa), ...
                  GZ*ones(size(rj)), rj, rj, hj];                        %#ok<AGROW>
            Cu = [Cu; mixN(CROWN_SHADE.*0.66 .* ...
                  (0.82+0.36*hash2(T(:,1)*q, T(:,2)*5)), HZ, f)];        %#ok<AGROW>
        end
        S.instances(uwV, uwF, Tu, Cu, 'Ambient', 0.34, ...
                    'Tip', mix(CROWN_SHADE.*0.86, HZ, 0.10));

        % SHADOWS, AND S2 HAD NONE AT ALL - which is most of why it read flat next to
        % S1. MATLAB casts no shadows, so S1 projects its crowns along the real solar
        % vector; S2 never did, so 260-odd trees and a 5 m monument stood on grass with
        % nothing under them and the whole scene looked pasted together.
        % S1 restricts its shadows to the ROAD because a flat shadow on its +-0.126 m
        % forest floor would float 0.30 m. Here the ground relief is 0.09 m, so a
        % shadow laid just above it is at worst 9 cm off - invisible at these distances
        % - and the open grass is most of the frame, so it is where the shadows are
        % worth the most. Same ellipse trick: a sphere's shadow under a directional
        % light is an ellipse stretched along the sun's bearing by 1/sin(elevation).
        bear    = atan2(-S.SunVec(2), -S.SunVec(1));
        stretch = 1/max(sind(S.SunElAz(1)), 0.2);
        [sdV, sdF] = discMesh2(16, bear, stretch);
        dirv = -[S.SunVec(1) S.SunVec(2)] / max(S.SunVec(3), 0.15);
        zc   = GZ + 0.70*T(:,6);
        Tsd  = [T(:,1) + dirv(1)*zc, T(:,2) + dirv(2)*zc, ...
                (GZ + 0.10)*ones(size(zc)), 0.60*T(:,4), 0.60*T(:,4), ones(size(zc))];
        S.instances(sdV, sdF, Tsd, repmat([0.10 0.11 0.10], size(Tsd,1), 1), ...
                    'Lighting', 'none', 'Alpha', 0.22, 'Smooth', false);
        % and the monument's own shadow, thrown across the island
        zm = Z_ISLE + W.Plinth.RaisedH + W.Plinth.H + W.Statue.H*0.5;
        S.instances(sdV, sdF, ...
            [C(1) + dirv(1)*zm, C(2) + dirv(2)*zm, Z_ISLE + 0.01, 2.6, 2.6, 1], ...
            [0.10 0.11 0.10], 'Lighting', 'none', 'Alpha', 0.26, 'Smooth', false);
        nT = size(T,1);
    end
end

S.limits(C(1)+[-opts.Radius opts.Radius], C(2)+[-opts.Radius opts.Radius], [-6 60]);
st = struct('Arms', nArm, 'GiveWay', nGw, 'Splitters', nSp, 'Posts', nPost, ...
            'Grass', nG, 'Trees', nT, 'Seconds', toc(t0));
end

% =======================================================================================
function tf = onAnyRoad(W, xy, C)
%ONANYROAD  Is this point on drivable tarmac - any arm, or the circulating ring?
tf = true;
r = hypot(xy(1)-C(1), xy(2)-C(2));
if r <= W.Rout + 1.0, return; end                 % the ring and its apron
for k = 1:4
    [~, e] = W.Arm(k).Path.inverse(xy);
    [ss, ~] = W.Arm(k).Path.inverse(xy);
    if ss > 0.5 && ss < W.Arm(k).Path.Len - 0.5 && abs(e) < W.ArmW/2 + 1.0, return; end
end
tf = false;
end

function [X, Y] = bandG(P, sA, sB, e0, e1, dsAlong, nAcross)
%BANDG  The same band as band(), but as a GRID so it can carry a texture.
ss = unique([sA:dsAlong:sB, sB]);
ee = linspace(e0, e1, nAcross);
X = zeros(nAcross, numel(ss));  Y = X;
for i = 1:numel(ss)
    for j = 1:nAcross
        q = P.at(ss(i), ee(j));
        X(j,i) = q(1);  Y(j,i) = q(2);
    end
end
assert(all(isfinite([X(:); Y(:)])), "sc:bandGridNaN", "S2 band grid contains NaN");
end

function [X,Y] = band(P, sA, sB, e0, e1)
ss = unique([sA:1.0:sB, sB]);
L = zeros(numel(ss),2); R = zeros(numel(ss),2);
for i = 1:numel(ss), L(i,:) = P.at(ss(i), e1); R(i,:) = P.at(ss(i), e0); end
X = [L(:,1); flipud(R(:,1))];  Y = [L(:,2); flipud(R(:,2))];
end
function [V,F] = rawSTL2(name)
f = fullfile(sc.refRoot(),"matlab","assets",name+".stl");
assert(isfile(f), "sc:noAsset", "missing %s", f);
TR = stlread(f); V = TR.Points; F = TR.ConnectivityList;
V(:,3) = V(:,3)-min(V(:,3));
V(:,1:2) = V(:,1:2) - (min(V(:,1:2))+max(V(:,1:2)))/2;
end
function v = rand01(k), v = mod(sin(k*12.9898)*43758.5453, 1); end
function s = sgnOf(q), s = 1; if mod(q,2)==0, s = -1; end, end
function v = hash2(a,b), v = mod(sin(a*12.9898 + b*78.233)*43758.5453, 1); end
function f = hazeF(d,d0,d1,fmax), f = fmax*min(1,max(0,(d-d0)./max(1e-6,d1-d0))); end
function c = mix(a,b,f), c = a*(1-f)+b*f; end
function C = mixN(A,b,f), C = min(1,max(0,A.*(1-f)+b.*f)); end

% =======================================================================================
function [V, F] = ballMesh2(n)
%BALLMESH2  Unit sphere as triangles.
[sx, sy, sz] = sphere(n);
fv = surf2patch(sx, sy, sz, 'triangles');
V = fv.vertices; F = fv.faces;
end

function [V, F] = latheMesh2(pr, pz, n)
%LATHEMESH2  Surface of revolution from a (radius, height) profile.
%   Round stock for anything organic. A cuboid is the one shape a body never has.
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

function [V, F] = discMesh2(n, bear, stretch)
%DISCMESH2  A flat unit disc pre-stretched along `bear` - the shadow stencil.
%   Pre-rotating it is what lets every shadow ride in ONE instanced patch: they all
%   share one sun, so they differ only in size.
th = (0:n-1)/n*2*pi;
Rz = [cos(bear) -sin(bear); sin(bear) cos(bear)];
p  = (Rz * ([stretch 0; 0 1] * [cos(th); sin(th)]))';
V  = [0 0 0; p, zeros(n,1)];
F  = [ones(n,1), (2:n+1)', [(3:n+1)'; 2]];
end

% ---------------------------------------------------------------------------------------
function V = lumpAll(V, amt)
%LUMPALL  Perturb a lathe's radius at EVERY height, deterministically.
%   sc.s1render's lumpAbove keeps the bottom of a shape intact because the 2-D sight
%   model claims it. The S2 backdrop makes no such claim, so the whole height is free.
r  = hypot(V(:,1), V(:,2));
hi = r > 1e-9;
if ~any(hi), return; end
d  = [V(hi,1)./r(hi), V(hi,2)./r(hi)];
g  = mod(sin(d(:,1)*31.4 + d(:,2)*57.1 + V(hi,3)*11.7)*43758.5453, 1);
k  = 1 + amt*(g - 0.5);
V(hi,1) = V(hi,1).*k;  V(hi,2) = V(hi,2).*k;
end
