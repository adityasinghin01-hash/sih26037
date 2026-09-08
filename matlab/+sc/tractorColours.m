function C = tractorColours(m, body)
%TRACTORCOLOURS  Per-face colours for the open-ROPS tractor, ONE COLOUR PER PART.
%
%   WHAT ACTUALLY READS ON AN INDIAN TRACTOR, in order:
%     1. THE WHEEL-SIZE CONTRAST - the big rear tyres are given a darker, matte tone
%        than anything else on the machine, because tread and dust are what a real
%        rear tractor tyre looks like at any distance.
%     2. THE BODY COLOUR carried onto the mudguards - almost always painted to match,
%        unlike a car's black plastic arches.
%     3. THE OPEN ROPS FRAME AND SEAT - unpainted steel posts, a worn seat, because
%        there is no cab to hide either behind.

arguments
    m
    body (1,3) double = [0.62 0.18 0.14]     % the old flat tractor colour - red-oxide,
                                             % the commonest Indian tractor paint
end

A = sc.tractorAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:tractorColourFaces", ...
    ['sc.tractorAsset holds %d faces and the mesh passed in has %d. These must be ' ...
     'the same mesh in the same part order, or every colour lands on the wrong ' ...
     'triangle.'], size(A.F,1), size(m.Faces,1));

id = A.Id;
P = zeros(numel(A.Names), 3);
P(id.chassis,    :) = body;
P(id.rops_posts, :) = [0.42 0.43 0.45];   % unpainted steel
P(id.canopy,     :) = [0.68 0.66 0.60];   % a pale fabric/tin sun canopy, not body colour
P(id.seat,       :) = [0.20 0.17 0.15];   % worn dark upholstery
P(id.tyres,      :) = [0.075 0.075 0.085];
P(id.rims,       :) = [0.55 0.24 0.16];   % painted rims, common on Indian tractors
P(id.mudguards,  :) = body;
P(id.grille,     :) = [0.11 0.11 0.12];
P(id.lights,     :) = [0.80 0.78 0.70];
P(id.exhaust,    :) = [0.50 0.50 0.52];   % the vertical stack, dulled chrome
P(id.trim,       :) = [0.30 0.30 0.32];   % steering column, drawbar, steps
P(id.plate,      :) = [0.80 0.80 0.76];

C = P(A.Part, :);

% The chassis's vertical shade, as on every other actor in the kit.
v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;
ch = A.Part == id.chassis;
t  = max(0, min(1, (c(ch,3) - 0.75) / 0.70));
C(ch,:) = C(ch,:) .* (0.86 + 0.24*t);

C = min(1, max(0, C));
end
