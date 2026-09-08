function C = trolleyColours(m)
%TROLLEYCOLOURS  Per-face colours for the cane trolley, ONE COLOUR PER PART.
%
%   THE OVERHANGING LOAD IS A DIFFERENT COLOUR FROM THE BED, deliberately - straw-pale
%   cane against a weathered wood/steel bed is what makes the overhang read as loaded
%   cargo rather than a shapeless green mass the same colour as the deck it sits on.

arguments
    m
end

A = sc.trolleyAsset();
assert(size(A.F,1) == size(m.Faces,1), "sc:trolleyColourFaces", ...
    ['sc.trolleyAsset holds %d faces and the mesh passed in has %d. These must be ' ...
     'the same mesh in the same part order, or every colour lands on the wrong ' ...
     'triangle.'], size(A.F,1), size(m.Faces,1));

id = A.Id;
P = zeros(numel(A.Names), 3);
P(id.bed,      :) = [0.32 0.26 0.20];   % weathered wood/steel deck
P(id.rails,    :) = [0.24 0.20 0.16];   % darker than the bed - a worn slatted tub
P(id.load,     :) = [0.66 0.58 0.32];   % straw-pale cut cane, distinct from the bed
P(id.tyres,    :) = [0.085 0.085 0.095];
P(id.rims,     :) = [0.52 0.52 0.53];
P(id.mudguards,:) = [0.30 0.24 0.19];
P(id.hitch,    :) = [0.32 0.32 0.34];
P(id.trim,     :) = [0.28 0.28 0.30];

C = P(A.Part, :);
C = min(1, max(0, C));
end
