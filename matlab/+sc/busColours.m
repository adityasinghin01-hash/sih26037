function C = busColours(m, upper)
%BUSCOLOURS  Per-face colours for the UPSRTC bus, ONE COLOUR PER PART.
%
%   THE BUS WAS A SOLID YELLOW BOX ON SIX LEG-STUBS, and after the island it is the
%   largest object in the S2 frame. MATLAB cannot texture a patch, so the only detail
%   available is geometry plus one colour per face; the bus is therefore built in
%   Blender as 14 parts and each is coloured for what it is. THE PART LIST IS THE
%   TEXTURE. sc.busAsset holds the parts and the face->part index.
%
%   WHAT ACTUALLY READS ON A BUS AT DISTANCE, in order, and all four are parts:
%     1. THE WINDOW BAND - a long row of dark glass divided by pillars. Nothing else
%        says "bus" so immediately, and the primitive had none of it.
%     2. THE TWO-TONE - an Indian state bus is banded horizontally, never one colour.
%        Here it is GEOMETRY (skirt, waist rail, upper) rather than a colour rule, so
%        it survives any change to the palette.
%     3. The wheels, which are what say "vehicle" rather than "shed".
%     4. The destination board and the entrance.

arguments
    m
    upper (1,3) double = [0.72 0.71 0.66]    % warm off-white, not white: the car body
                                             % at 0.62-0.72 already measures 183/255 in
                                             % the S1 frame, and this is a bigger panel
end

A = sc.busAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:busColourFaces", ...
    ['sc.busAsset holds %d faces and the mesh passed in has %d. These must be the ' ...
     'same mesh in the same part order, or every colour lands on the wrong triangle.'], ...
    size(A.F,1), size(m.Faces,1));

id = A.Id;
P = zeros(numel(A.Names), 3);
P(id.shell,  :) = upper;
P(id.skirt,  :) = [0.14 0.26 0.45];   % the deep blue lower half
P(id.band,   :) = [0.55 0.18 0.15];   % the waist stripe. REF-13 s8: the saturated
                                      % things in a frame are placed deliberately, and
                                      % on a state bus this stripe is one of them
P(id.glass,  :) = [0.13 0.15 0.18];
P(id.tyres,  :) = [0.085 0.085 0.095];
P(id.rims,   :) = [0.52 0.52 0.53];   % plain steel, dustier than a car's
P(id.bumpers,:) = [0.30 0.31 0.33];
P(id.grille, :) = [0.11 0.11 0.12];
P(id.lights, :) = [0.80 0.78 0.70];
P(id.tails,  :) = [0.58 0.11 0.09];
P(id.plate,  :) = [0.80 0.80 0.76];
P(id.dest,   :) = [0.86 0.84 0.74];   % brighter than the body, so it reads as a SIGN
P(id.door,   :) = [0.14 0.16 0.19];   % a dark opening. There are no booleans here, so
                                      % the entrance is a proud dark panel - a recess
                                      % cut into an opaque shell is simply invisible
P(id.trim,   :) = [0.26 0.27 0.29];   % window pillars and the roof carrier

C = P(A.Part, :);

% The shell's vertical shade, as on the car: REF-06 s3's rule that a lit vertical
% surface is darker at the base is about light, not about which panel it is, so it is
% applied to the shell alone and can never be mistaken for a part boundary.
v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;
sh = A.Part == id.shell;
t  = max(0, min(1, (c(sh,3) - 0.52) / 2.52));
C(sh,:) = C(sh,:) .* (0.88 + 0.20*t);

C = min(1, max(0, C));
end
