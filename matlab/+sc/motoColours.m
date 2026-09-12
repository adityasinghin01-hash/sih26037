function C = motoColours(m, body)
%MOTOCOLOURS  Per-face colours for the ridden motorcycle, ONE COLOUR PER PART.
%
%   THIS ACTOR IS RIDDEN IN EVERY APPEARANCE - the wrong-side rider and the overtaker
%   in S1, the wrong-way rider in S2 - so the rider is coloured as deliberately as the
%   machine: a dark helmet and a shirt colour, because an unpainted grey rider reads
%   as a mannequin rather than a person.
%
%   `body` lets the same geometry serve more than one instance with a different paint
%   job, as sc.carColours already does - the three roles this actor plays were
%   previously told apart only by one flat colour each, and that distinction still has
%   to survive becoming per-part.

arguments
    m
    body (1,3) double = [0.62 0.14 0.11]     % maroon-red, the old moto_wrong flat value
end

A = sc.motoAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:motoColourFaces", ...
    ['sc.motoAsset holds %d faces and the mesh passed in has %d. These must be the ' ...
     'same mesh in the same part order, or every colour lands on the wrong triangle.'], ...
    size(A.F,1), size(m.Faces,1));

id = A.Id;
P = zeros(numel(A.Names), 3);
P(id.frame,     :) = body;
P(id.seat,      :) = [0.12 0.12 0.13];   % black vinyl
P(id.tyres,     :) = [0.085 0.085 0.095];
P(id.rims,      :) = [0.58 0.58 0.60];
P(id.forks,     :) = [0.42 0.43 0.45];   % brushed metal
P(id.handlebar, :) = [0.14 0.14 0.16];
P(id.exhaust,   :) = [0.55 0.55 0.56];   % chrome-ish muffler, the loudest cue after
                                         % the rider itself
P(id.mudguards, :) = body;
P(id.lights,    :) = [0.80 0.78 0.70];
P(id.plate,     :) = [0.80 0.80 0.76];
P(id.rider,     :) = [0.30 0.30 0.55];   % a shirt colour - varied per call if a scene
                                         % ever needs the two riders visibly distinct

C = P(A.Part, :);

% The rider's helmet is its own dark note within the rider part, not a flat shirt
% colour repeated over the head - the single detail that stops the rider reading as
% a shirt-coloured block with no face.
v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;
rd = A.Part == id.rider;
topThird = c(rd,3) > (min(c(rd,3)) + 0.72*(max(c(rd,3))-min(c(rd,3))));
Crider = C(rd,:);
Crider(topThird,:) = repmat([0.10 0.10 0.11], sum(topThird), 1);
C(rd,:) = Crider;

C = min(1, max(0, C));
end
