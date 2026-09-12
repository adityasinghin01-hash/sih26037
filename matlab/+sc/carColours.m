function C = carColours(m, body)
%CARCOLOURS  Per-face colours for the ego hatchback, ONE COLOUR PER PART.
%
%   THE EGO IS THE HERO OF EVERY FRAME AND IT WAS A FEATURELESS WHITE SLAB.
%   MATLAB cannot texture a patch - no image, no UVs, no alpha, ever (REF-17 s12a).
%   The only detail available is geometry plus one colour per face, so the car is built
%   in Blender as 11 separate parts and each part is coloured for what it is.
%   THE PART LIST IS THE TEXTURE. sc.carAsset holds the parts and the face->part index.
%
%   WHAT THIS REPLACES, AND WHY IT HAD TO GO.
%   The previous version recovered the parts by GUESSING GEOMETRIC REGIONS off the
%   mesh - glass was "z above 0.72, inboard of |y| = 0.82, x below 0.90"; a tyre was
%   "below 0.62 and within 0.42 m of an axle"; a mirror was "|y| > 0.80 between z 0.90
%   and 1.14". Those bands were exactly right for the eight-cuboid primitive they were
%   written against, because there the regions WERE the parts. Against the authored
%   car they are not: the glass band also contains the door skin and the door handles,
%   the tyre band contains the wheel arches and the sills, and the mirror band contains
%   the roof rails. The parts are known exactly - they are separate files - so nothing
%   needs inferring, and a part index cannot drift when the model changes shape.
%
%   THE ONE THING STILL DONE BY GEOMETRY, AND IT IS NOT A PART: a shallow top-to-bottom
%   shade across the shell. A flank painted one flat value reads as cardboard, and
%   REF-06 s3's rule - dark and closed at the base, lighter at the top - is about how
%   light falls on a vertical surface, not about which panel it is. It is applied to
%   the shell alone, so it can never be mistaken for a part boundary.

arguments
    m
    body (1,3) double = [0.62 0.66 0.72]     % a muted steel blue, not white
end

A = sc.carAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:carColourFaces", ...
    ['sc.carAsset holds %d faces and the mesh passed in has %d. These must be the ' ...
     'same mesh in the same part order, or every colour lands on the wrong triangle.'], ...
    size(A.F,1), size(m.Faces,1));

id = A.Id;

% ---- THE PALETTE, one entry per part ---------------------------------------------
% Chosen for what actually reads at demo distance against a road measured at
% 88.8/93.3/90.0 (REF-17 s19h, off 12 of Aditya's own dashcam frames of this road
% class), not for what is technically present on a car.
P = zeros(numel(A.Names), 3);
P(id.shell,  :) = body;
P(id.glass,  :) = [0.13 0.15 0.18];   % dark glass - the strongest single "car" cue
P(id.tyres,  :) = [0.085 0.085 0.095];
P(id.rims,   :) = [0.62 0.63 0.65];   % bright against the tyre: what makes a WHEEL
P(id.bumpers,:) = body * 0.62;        % bumper bars and sills - the dark band along the
                                      % bottom that stops the body reading as a doorstop
P(id.grille, :) = [0.10 0.10 0.11];   % grille and air dam
P(id.lights, :) = [0.80 0.78 0.70];   % headlamp lens, warm off-white
P(id.tails,  :) = [0.58 0.11 0.09];   % RED, and it is its own part on purpose: a red
                                      % lens at the back is a "this is a car" cue that
                                      % one shared lamp colour would have thrown away
P(id.mirrors,:) = [0.20 0.21 0.23];   % black caps, as on a base-trim hatchback. These
                                      % are the 200 mm that makes the ego 1.90 m wide,
                                      % so they are worth being able to SEE in a frame
                                      % whose whole subject is clearance
P(id.plate,  :) = [0.80 0.80 0.76];   % white plate - cheap, and it reads at 40 m
P(id.trim,   :) = [0.17 0.18 0.20];   % pillars, roof rails, wipers, door handles

C = P(A.Part, :);

% ---- the shell's vertical shade ---------------------------------------------------
v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;      % face centres
sh = A.Part == id.shell;
t  = max(0, min(1, (c(sh,3) - 0.22) / 1.28));           % 0 at the sill, 1 at the roof
C(sh,:) = C(sh,:) .* (0.86 + 0.24*t);

C = min(1, max(0, C));
end
