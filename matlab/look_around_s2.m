%LOOK_AROUND_S2  Open S2's world (the chowk gyratory) in a real, interactive
%   window. Same idea as look_around_s1.m - see that file's header.
%
%   RUN THIS FROM THE MATLAB APP ITSELF, not from a terminal.
%     - LEFT-CLICK AND DRAG   to orbit the camera around
%     - SCROLL / RIGHT-DRAG   to zoom in and out

here = fileparts(mfilename('fullpath'));
addpath(here);
W = sc.s2world();
C = W.Centre;

S = sc.scene('Visible', true, 'Hud', false);
sc.s2render(S, W, 'Radius', 100, 'Detail', 40);

S.look([C(1)-20 C(2)-90 20], [C(1) C(2) 2], 40);

fprintf('S2 world is open. Drag to look around, scroll to zoom.\n');
fprintf('Re-run this script any time to rebuild fresh.\n');
