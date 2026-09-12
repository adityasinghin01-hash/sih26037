%VEH_LOOK  LOOK AT ONE VEHICLE ALONE, FAST, so its detailing can be iterated.
%
%   WHY THIS EXISTS. The only loop that has ever made anything visual good in this
%   project is render -> LOOK -> fix -> render (REF-17 s7, s19). For the WORLD that
%   costs 4-9 minutes, which is why `s1_look.m` exists; for an ACTOR it should cost
%   seconds, and there was nothing - the car was being judged inside a full HUD still
%   that spends its whole budget on 2,200 trees the car is not.
%
%   IT ALSO ANSWERS THE QUESTION A STILL CANNOT: WHICH PART AM I LOOKING AT.
%   Run with PARTS and every part gets its own hue plus a printed legend. MATLAB has
%   no textures, so a defect and a deliberate part look identical, and this has
%   already paid for itself in both directions: it proved the car's rims drew NO
%   pixels at all (no rim hue anywhere in the frame), and it stopped a fix that was
%   not needed when two "stray" dark strips turned out to be the roof rail, the
%   B-pillar trim and the side glass standing proud of the cabin. REF-17 s19f spent a
%   whole pass on an understorey mass that was a height scale used as a radius, and it
%   was found by colouring things, not by reasoning about them.
%
%   Run:  matlab -batch "run('.../matlab/veh_look.m')"                    % the car
%         matlab -batch "VEH='bus'; run('.../matlab/veh_look.m')"
%         matlab -batch "VEH='bus'; PARTS=true; run('.../matlab/veh_look.m')"

here = fileparts(mfilename('fullpath'));  addpath(here);
outDir = fullfile(here,'renders');
if ~exist('PARTS','var'), PARTS = false; end
if ~exist('VEH','var'),   VEH   = "car"; end
VEH = string(VEH);

switch VEH
    case "car",        A = sc.carAsset();      col = @sc.carColours;
    case "bus",        A = sc.busAsset();      col = @sc.busColours;
    case "auto",       A = sc.autoAsset();     col = @sc.autoColours;
    case "motorcycle", A = sc.motoAsset();     col = @sc.motoColours;
    case "tractor",    A = sc.tractorAsset();  col = @sc.tractorColours;
    case "trolley",    A = sc.trolleyAsset();  col = @sc.trolleyColours;
    case "tataace",    A = sc.aceAsset();      col = @sc.aceColours;
    otherwise
        error("sc:noVehLook", 'no part-built asset for "%s".', VEH);
end
[m, dim] = sc.meshes(VEH);

if PARTS
    % A distinct hue per part. Deliberately garish - this image is a diagnostic and is
    % never shown to anybody; the moment it looks tasteful it stops being readable.
    hue = hsv(numel(A.Names));
    C = hue(A.Part, :);
    fprintf('\n%s PART LEGEND (hue, faces)\n', upper(VEH));
    for k = 1:numel(A.Names)
        fprintf('  %-9s  RGB %.2f %.2f %.2f   %5d faces\n', ...
            A.Names(k), hue(k,:), sum(A.Part==k));
    end
    tag = 'parts';
else
    C = col(m);
    tag = 'look';
end

% THE THREE VIEWS THAT DECIDE A VEHICLE, and the first is not optional: the chase
% camera sits behind and above the ego for the whole of both films, so the REAR
% three-quarter is the view the judges actually spend 110 seconds looking at.
% Distances scale off the vehicle's own length, so a 10.8 m bus frames like a 3.99 m
% hatchback instead of falling out of the picture.
k = dim(1) / 3.99;
VIEWS = { 'rear',  [-7.6  -1.9  3.9]*k, [0 0 0.72*k], 34
          'front', [ 7.2   3.1  2.6]*k, [0 0 0.72*k], 32
          'side',  [-0.4  -7.4  1.7]*k, [0 0 0.72*k], 34 };

t0 = tic;
for v = 1:size(VIEWS,1)
    S = sc.scene('Hud', false, 'Width', 1100, 'Height', 760);
    % a plain ground, so nothing but the vehicle is being judged. REF-17 s14: when a
    % render looks wrong, strip it to one element rather than tuning the element you
    % suspect.
    g = 30*k;
    S.flat([-g g g -g], [-g -g g g], 0, [0.345 0.352 0.348]);
    S.mesh(m, [0 0 0], C);
    S.look(VIEWS{v,2}, VIEWS{v,3}, VIEWS{v,4});
    p = fullfile(outDir, sprintf('%s_%s_%s.png', VEH, tag, VIEWS{v,1}));
    S.save(p);  S.close();
    fprintf('  wrote %s\n', p);
end
fprintf('[veh_look] %s %s, 3 views, %.1f s\n', VEH, tag, toc(t0));
