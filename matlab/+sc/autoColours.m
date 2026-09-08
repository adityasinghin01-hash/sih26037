function C = autoColours(m)
%AUTOCOLOURS  Per-face colours for the Bajaj RE auto-rickshaw, ONE COLOUR PER PART.
%
%   THE STANDARD UP LIVERY: a green body under a yellow canopy. Unlike the bus, this
%   is not a geometry step - the canopy and the chassis are separate loft families
%   already, so the two-tone is just which part gets which colour.
%
%   WHAT ACTUALLY READS ON AN AUTO, in order, and all four are parts or colour choices:
%     1. The OPEN CABIN - dark seat upholstery visible under the canopy, because there
%        are no side panels to hide it behind.
%     2. The single front wheel, same treatment as the rear pair so it reads as one
%        consistent wheel design rather than a mismatched spare.
%     3. The mudguards, painted body colour (as real autos are, unlike a car's body).
%     4. The single round headlamp and the yellow number plates - Indian commercial
%        vehicles carry yellow plates with black text, not white ones.

arguments
    m
end

A = sc.autoAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:autoColourFaces", ...
    ['sc.autoAsset holds %d faces and the mesh passed in has %d. These must be the ' ...
     'same mesh in the same part order, or every colour lands on the wrong triangle.'], ...
    size(A.F,1), size(m.Faces,1));

id = A.Id;
BODY = [0.14 0.42 0.30];      % the dark green lower body, matched to the flat colour
                              % this actor used before (s1_action_shots.m COL.auto)
P = zeros(numel(A.Names), 3);
P(id.chassis,  :) = BODY;
P(id.canopy,   :) = [0.82 0.71 0.14];   % the yellow canopy
P(id.pillars,  :) = [0.10 0.10 0.11];   % black frame
P(id.glass,    :) = [0.14 0.16 0.19];
P(id.seats,    :) = [0.22 0.18 0.15];   % dark upholstery, visible with no side panels
P(id.tyres,    :) = [0.085 0.085 0.095];
P(id.rims,     :) = [0.55 0.55 0.56];
P(id.mudguards,:) = BODY;               % body colour, as a real auto's are
P(id.grille,   :) = [0.11 0.11 0.12];
P(id.lights,   :) = [0.80 0.78 0.70];
P(id.tails,    :) = [0.58 0.11 0.09];
P(id.plate,    :) = [0.80 0.66 0.10];   % YELLOW commercial plate, not white
P(id.trim,     :) = [0.12 0.12 0.13];   % handlebar, console, roof rails, exhaust

C = P(A.Part, :);

% The chassis's vertical shade, as on the car and bus.
v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;
ch = A.Part == id.chassis;
t  = max(0, min(1, (c(ch,3) - 0.05) / 0.60));
C(ch,:) = C(ch,:) .* (0.86 + 0.24*t);

C = min(1, max(0, C));
end
