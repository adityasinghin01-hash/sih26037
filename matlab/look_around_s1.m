%LOOK_AROUND_S1  Open S1's world in a real, interactive window.
%
%   RUN THIS FROM THE MATLAB APP ITSELF, not from a terminal - the
%   interactive rotate/zoom only works with a real display, which
%   the command-line "matlab -batch" mode does not have.
%
%   Once it opens:
%     - LEFT-CLICK AND DRAG   to orbit the camera around
%     - SCROLL / RIGHT-DRAG   to zoom in and out
%     - Just re-run this script (F5, or type look_around_s1 and press
%       Enter) any time to rebuild fresh - e.g. after Claude changes
%       something and you want to check it yourself.

here = fileparts(mfilename('fullpath'));
addpath(here);
W = sc.s1world();
P = W.Path;
CS = W.CowStation;

S = sc.scene('Visible', true, 'Hud', false);
sc.s1render(S, W, 'Focus', P.at(CS-20, 0), 'Radius', 90, 'Detail', 40);

% starting camera position - drag with the mouse to look anywhere from here
[e0, ~] = P.at(CS-60, 1.75);
tgt = P.at(CS-14, 1.0);
S.look([e0 1.5], [tgt 1.0], 40);

fprintf('S1 world is open. Drag to look around, scroll to zoom.\n');
fprintf('Re-run this script any time to rebuild fresh.\n');
