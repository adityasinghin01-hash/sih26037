function [V, F] = zebuWalkLegs(cowXY, cowYaw, distTraveled, opts)
%ZEBUWALKLEGS  All four zebu legs, posed for one walk-cycle frame.
%
%   THE ZEBU ASSET (matlab/assets/zebu.stl) IS A SINGLE RIGID DOWNLOADED MESH,
%   AND STAYS ONE - this does NOT cut or rig it. Cutting an unfamiliar organic
%   mesh's legs off, blind, with no way to preview the result before it ships,
%   is exactly the class of mistake this project's own burial traps warn
%   about. Instead, one new leg part (blend/vehicles/zebu_leg.py) is drawn
%   OVER each of her four real leg positions, built slightly LARGER than
%   whatever the original static leg's silhouette is - "step outward", the
%   same fix that solved the car's wheel/rim/hub occlusion - so the new,
%   moving leg simply wins the pixel and the original underneath is never
%   seen, without needing to be removed.
%
%   THE FOUR ATTACHMENT POINTS ARE MEASURED OFF THE ACTUAL MESH, not guessed:
%   all four legs meet the torso at the SAME height, z = 0.657 m in the
%   model's own 1.46 m frame. Front pair centred near local x = +0.234, rear
%   pair near x = -0.713 (the model's own local +x IS front - confirmed by
%   cross-referencing sc.zebuColours' own muzzle test, which is written to
%   fire only at high +x). Lateral half-spacing ~0.135 m, averaged from the
%   measured 0.132-0.138 m split between the front and rear pairs.
%
%   sc.scene's mesh()/instances() CANNOT do this rotation - Yaw there is
%   Z-axis only, and a leg swings fore-aft, which is a rotation about the
%   LOCAL Y AXIS at the hip. So this function does the full pose maths
%   itself - swing about the hip, then the SAME rotate-and-translate by the
%   cow's own world pose that sc.scene/mesh applies internally - and returns
%   already-WORLD-SPACE vertices, meant to be drawn via
%   S.mesh(struct('Vertices',V,'Faces',F), [0 0 0], col) - pose [0 0 0] is a
%   no-op transform, since the transform already happened here.
%
%   distTraveled DRIVES THE GAIT, NOT THE CLOCK. Cumulative arc length since
%   she started walking - the caller sums frame-to-frame position deltas -
%   naturally stops advancing the instant she stops moving, so the legs
%   freeze wherever they are rather than needing her exact stop time known in
%   advance. A mid-stride freeze reads far better than a moving body on
%   static legs, which is the defect this exists to fix.

arguments
    cowXY (1,2) double
    cowYaw (1,1) double
    distTraveled (1,1) double
    opts.StrideLen (1,1) double = 1.68     % REF-04 s2, matches the verified gait
    opts.SwingAmp  (1,1) double = 0.44     % rad, ~25 deg each way - visible, not a strut
    opts.LegLen    (1,1) double = 0.657    % measured hip height, matlab/assets/zebu.stl
    opts.HipY      (1,1) double = 0.135    % measured lateral half-spacing
    opts.HipXFront (1,1) double = 0.234    % measured front pair local x
    opts.HipXRear  (1,1) double = -0.713   % measured rear pair local x
end

persistent LEG0
if isempty(LEG0)
    f = fullfile(sc.refRoot(), "matlab", "assets", "zebu_leg.stl");
    TR = stlread(f);
    LEG0.V = TR.Points;  LEG0.F = TR.ConnectivityList;
end

phase = 2*pi * distTraveled / opts.StrideLen;
% DIAGONAL PAIRS, ANTIPHASE - the standard quadruped walk sequence: front-
% left+rear-right swing one way while front-right+rear-left swing the other.
hips = [ opts.HipXFront -opts.HipY opts.LegLen  phase        % front-left
         opts.HipXFront  opts.HipY opts.LegLen  phase+pi     % front-right
         opts.HipXRear  -opts.HipY opts.LegLen  phase+pi     % rear-left  (diagonal w/ FL... )
         opts.HipXRear   opts.HipY opts.LegLen  phase   ];   % rear-right (paired with FL)
% (front-left, rear-right) share `phase`; (front-right, rear-left) share `phase+pi` -
% that IS the diagonal pairing, just read off the table above by matching angle.

nv = size(LEG0.V,1); nf = size(LEG0.F,1);
V = zeros(4*nv, 3);  F = zeros(4*nf, 3);
R = [cos(cowYaw) -sin(cowYaw); sin(cowYaw) cos(cowYaw)];
for k = 1:4
    hipLocal = hips(k,1:3);  swing = opts.SwingAmp * sin(hips(k,4));
    Vk = LEG0.V;
    Vk(:,3) = Vk(:,3) - 1;                  % pivot (was local z=1) to the origin
    Vk(:,3) = Vk(:,3) * opts.LegLen;        % scale height to the real leg length
    ca = cos(swing); sa = sin(swing);       % swing about the LOCAL Y axis (fore-aft)
    Vx = Vk(:,1)*ca + Vk(:,3)*sa;
    Vz = -Vk(:,1)*sa + Vk(:,3)*ca;
    Vk = [Vx, Vk(:,2), Vz];
    Vk = Vk + hipLocal;                     % seat the hip at its real attachment point
    p  = (R * Vk(:,1:2)')';                 % same rotate-then-translate sc.scene/mesh
    Vk = [p(:,1)+cowXY(1), p(:,2)+cowXY(2), Vk(:,3)];   % uses for [x y yaw] pose
    V((k-1)*nv+1:k*nv, :) = Vk;
    F((k-1)*nf+1:k*nf, :) = LEG0.F + (k-1)*nv;
end
end
