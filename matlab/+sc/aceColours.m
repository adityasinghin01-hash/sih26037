function C = aceColours(m, body)
%ACECOLOURS  Per-face colours for the Tata Ace, ONE COLOUR PER PART.
%
%   THE OPEN TAILGATE reads as a slightly darker panel than the body, the way a
%   dropped steel tailgate catches less light than the painted flank above it - a
%   small note that it is a moving part, not just a differently-angled body panel.

arguments
    m
    body (1,3) double = [0.86 0.86 0.88]     % the old flat tataace value - off-white,
                                             % the commonest Ace paint
end

A = sc.aceAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:aceColourFaces", ...
    ['sc.aceAsset holds %d faces and the mesh passed in has %d. These must be the ' ...
     'same mesh in the same part order, or every colour lands on the wrong triangle.'], ...
    size(A.F,1), size(m.Faces,1));

id = A.Id;
P = zeros(numel(A.Names), 3);
P(id.cab,      :) = body;
P(id.glass,    :) = [0.14 0.16 0.19];
P(id.mirrors,  :) = [0.20 0.21 0.23];
P(id.bed,      :) = [0.42 0.42 0.44];   % bare steel deck, not painted body colour
P(id.rails,    :) = body;
P(id.tailgate, :) = body * 0.75;        % darker - a dropped steel panel, not flat paint
P(id.tyres,    :) = [0.085 0.085 0.095];
P(id.rims,     :) = [0.55 0.55 0.56];
P(id.mudguards,:) = [0.20 0.21 0.23];
P(id.grille,   :) = [0.11 0.11 0.12];
P(id.lights,   :) = [0.80 0.78 0.70];
P(id.plate,    :) = [0.80 0.80 0.76];

C = P(A.Part, :);

v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;
ch = A.Part == id.cab;
t  = max(0, min(1, (c(ch,3) - 0.55) / 1.05));
C(ch,:) = C(ch,:) .* (0.86 + 0.24*t);

C = min(1, max(0, C));
end
