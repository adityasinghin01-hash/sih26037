%PHASE4_CLOSE_CHECK  One-off: put the tractor+trolley (S1) and the Tata Ace (S2) into
%   their real world backdrops and LOOK, since the five canonical action stills in each
%   scenario happen not to catch them in frame. Not part of the numbered pipeline.
here = fileparts(mfilename('fullpath')); addpath(here);
outDir = fullfile(here,'renders');

% S1 tractor+trolley already confirmed - skipped on this re-run to save the ~2 min
% world build. Re-enable by uncommenting if needed again.

% ---------------------------------------------------------------- S2: TATA ACE
% Arm A, 46 deg (compass, 0=N=+y, 90=E=+x), roughly where S2 says it parks.
W2 = sc.s2world();
C  = W2.Centre;
brg = deg2rad(46);
dirv = [sin(brg) cos(brg)];
pAce = C + dirv*42;
pCar = C + dirv*58;

perp = [dirv(2) -dirv(1)];   % across the arm, to frame the Ace face-on

S2 = sc.scene('Hud', false, 'Width', 1400, 'Height', 800);
sc.s2render(S2, W2, 'Radius', 150, 'Detail', 75);
S2.mesh(sc.meshes("tataace"), [pAce brg+pi/2], sc.aceColours(sc.meshes("tataace")));
S2.mesh(sc.meshes("car"), [pCar brg+pi], sc.carColours(sc.meshes("car")));
camPos = pAce + perp*9 - dirv*3;
S2.look([camPos 1.7], [pAce 1.0], 40);
S2.save(fullfile(outDir, "check_s2_tataace.png"));
S2.close();
fprintf('wrote check_s2_tataace.png\n');
