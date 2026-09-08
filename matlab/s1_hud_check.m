%S1_HUD_CHECK  PHASE 4 - three frames with the full instrument strip, to be LOOKED at
%   before committing 8.5 minutes to a film.

here = fileparts(mfilename('fullpath')); addpath(here);
run(fullfile(here,'s1_result_run.m'));
outDir = fullfile(here,'renders');

MESH = struct('cow',sc.meshes("zebu"), 'auto',sc.meshes("auto"), ...
              'moto_wrong',sc.meshes("motorcycle"), 'moto_over',sc.meshes("motorcycle"), ...
              'tractor',sc.meshes("tractor"), 'trolley',sc.meshes("trolley"), ...
              'car',sc.meshes("car"));
COL = struct('cow',[0.62 0.55 0.44], 'auto',sc.autoColours(MESH.auto), ...
             'moto_wrong',sc.motoColours(MESH.moto_wrong), ...
             'moto_over',sc.motoColours(MESH.moto_over,[0.22 0.22 0.26]), ...
             'tractor',sc.tractorColours(MESH.tractor), ...
             'trolley',sc.trolleyColours(MESH.trolley), 'car',[0.80 0.81 0.84]);
ZCOL = sc.zebuColours(MESH.cow);   % per-face, computed once
CCOL = sc.carColours(MESH.car);   % per-face: glass, wheels, sill, roof.
                                  % One flat colour made the ego a white slab.

% The three-line caption. REF-17 s8: the middle line names the stand-in as OURS.
CMP = { 'MathWorks referencePathFrenet', 'FAILS TO START  -  0/120 candidates at t=19.7 s', [1.00 0.45 0.30]
        'DEFENSIVE STAND-IN (ours, not MathWorks)', '', [0.95 0.35 0.30]
        'OURS', '', [0.35 0.95 0.55] };

RT = W.Path.P(1:8:end, :);
[~, iAlong] = min(abs(log1.s - CS));
frames = [find(G.Bind=="cow",1), find(log1.State=="ABORT",1), iAlong];
names  = ["hud_measure" "hud_abort" "hud_pass"];

S = sc.scene('Width', 1400, 'Height', 820);     % HUD on
for k = 1:3
    i = frames(k);
    is = min(i, numel(poses));
    [exy, ehd] = P.at(log1.s(i), log1.e(i));
    S.clearScene();
    sc.s1render(S, W, 'Focus', P.at(log1.s(i)+22, 0), 'Radius', 120, 'Probe', false);
    pp = poses{is};
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        nm = who(pp(q).ActorID);
        % the cow carries PER-FACE colour: dark hooves, dark muzzle, pale horns,
        % paler underside. One colour per actor is what made her a mould.
        if strcmp(nm,'cow'), cc = ZCOL; else, cc = COL.(nm); end
        S.mesh(MESH.(nm), [pp(q).Position(1:2), deg2rad(pp(q).Yaw)], cc);
    end
    S.mesh(MESH.car, [exy, ehd], CCOL);
    % The HUD eats the bottom third of the frame, so the chase camera has to look
    % DOWN more than a bare chase shot would - a 26 m look-ahead put the car and the
    % cow underneath the caption strip. Less 'Ahead' pitches the subject up the frame.
    % 'Ahead' WAS 13 AND IT PUT THE EGO'S BOTTOM EDGE EXACTLY ON THE HUD STRIP.
    % Measured off the render: the ego sits 13.7 deg below the view axis at Ahead 13,
    % against a 16.5 deg half-frame, i.e. 83 % of the way to the bottom - so the
    % bumper, both rear wheels and half the number plate were behind the instrument
    % panel for every still AND for the whole 62-second film. A shorter look-ahead
    % steepens the view axis and pitches the subject up the frame; at 10 it clears.
    S.chase([exy ehd], 'Back', 12, 'Up', 5.6, 'Ahead', 10, 'Fov', 33);

    jd = find(D.t <= log1.t(i), 1, 'last');
    cmp = CMP;
    cmp{2,2} = sprintf('%s  -  %.0f m short of her, %.1f s stopped', ...
        D.State(jd), CS - D.s(jd), max(0, log1.t(i) - D.t(find(D.State=="STOPPED",1))));
    cmp{3,2} = sprintf('%s  -  %s', log1.State(i), log1.Note(i));

    d = struct('State', log1.State(i), 'Note', log1.Note(i), 'Speed', log1.v(i), ...
        'Gap', G.Free(i), 'Margin', G.Margin(i), ...
        'ChartRef', 0.90, ...
        'ChartTitle', 'measured clearance each side (m)   -   required 0.90', ...
        'T', log1.t(1:i), 'Hs', G.Margin(1:i), 'Route', RT, 'Pos', exy, ...
        'Title', 'S1 - forest cattle crossing', 'Compare', {cmp});
    sc.hud(S, d);
    f = fullfile(outDir, "s1hud_" + names(k) + ".png");
    S.save(f);
    fprintf('  %-12s t=%5.2f s  state %-9s gap %.2f m  margin %.3f m\n', ...
            names(k), log1.t(i), log1.State(i), G.Free(i), G.Margin(i));
end
S.close();
fprintf('\nwrote 3 HUD frames\n\n');
