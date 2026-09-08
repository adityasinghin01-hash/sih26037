function C = zebuColours(m)
%ZEBUCOLOURS  Per-face colours for the zebu, from geometry alone.
%
%   MATLAB CANNOT TEXTURE. There is no hair, no hide, no photographic detail available
%   in this renderer at all, and no amount of asset shopping changes that - a
%   photoreal Sketchfab cow arrives as an untextured mould because its realism lives
%   in maps this renderer cannot read.
%
%   What IS available is per-face colour, and the markings that actually read at demo
%   distance are few: REF-04 says "Light fawn, paler underside, darker muzzle", and to
%   that a cow adds black hooves and pale horns. Those four are placed off the mesh's
%   own geometry, so they follow the animal without any UVs.

v = m.Vertices;  f = m.Faces;
c = (v(f(:,1),:) + v(f(:,2),:) + v(f(:,3),:)) / 3;      % face centres
H = max(v(:,3));  L = max(v(:,1));

FAWN  = [0.60 0.52 0.40];
PALE  = [0.79 0.73 0.63];      % REF-04: "paler underside"
DARK  = [0.13 0.11 0.10];      % hooves and muzzle
HORN  = [0.74 0.70 0.60];

C = repmat(FAWN, size(f,1), 1);

% paler toward the belly, blended so there is no hard line
t = max(0, min(1, (0.62*H - c(:,3)) / (0.42*H)));
C = C .* (1-t) + PALE .* t;

hoof   = c(:,3) < 0.085*H;                                   % black feet
muzzle = c(:,1) > 0.86*L & c(:,3) > 0.55*H & c(:,3) < 0.82*H; % dark nose
% x > 0.62*L, not 0.40*L: the poll is at 0.72 L but the HUMP is at 0.42 L, and the
% looser test painted the top of the hump horn-pale - a hard grey patch on her back.
horn   = c(:,3) > 0.88*H & c(:,1) > 0.62*L & abs(c(:,2)) > 0.045;
C(hoof,:)   = repmat(DARK, sum(hoof), 1);
C(muzzle,:) = repmat(DARK.*1.6, sum(muzzle), 1);
C(horn,:)   = repmat(HORN, sum(horn), 1);
end
