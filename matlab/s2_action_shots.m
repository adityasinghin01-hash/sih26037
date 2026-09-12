%S2_ACTION_SHOTS  PHASE 6 - render the S2 beats and LOOK at them.
here = fileparts(mfilename('fullpath')); addpath(here);
run(fullfile(here,'s2_action_run.m'));
outDir = fullfile(here,'renders');

mo = sc.meshes("motorcycle");
MESH = struct('auto',sc.meshes("auto"), 'wrong',mo, 'bus',sc.meshes("bus"), ...
              'ace',sc.meshes("tataace"), 'cow',sc.meshes("zebu"), 'car',sc.meshes("car"));
COL  = struct('auto',[0.14 0.42 0.30], 'wrong',[0.72 0.16 0.12], 'bus',[0.80 0.62 0.18], ...
              'ace',[0.86 0.86 0.88], 'cow',[0.62 0.55 0.44], 'car',[0.80 0.81 0.84]);
ZCOL = sc.zebuColours(MESH.cow);
CCOL = sc.carColours(MESH.car);   % per-face: glass, wheels, sill, roof.
                                  % One flat colour made the ego a white slab.
BCOL = sc.busColours(MESH.bus);   % per-face: the window band, the two-tone skirt
                                  % and waist rail, the wheels, the entrance and the
                                  % destination board. One flat colour made the
                                  % largest object in the S2 frame a yellow box.
ACOL = sc.autoColours(MESH.auto); % per-face: the yellow canopy, the open cabin's dark
                                  % seats, the single centred front wheel, mudguards.
WCOL = sc.motoColours(MESH.wrong); % per-face: both wheels centred, an exhaust, mirrors,
                                   % and a rider - the wrong-way-round-the-island agent.
ECOL = sc.aceColours(MESH.ace);   % per-face: the dropped tailgate, the open bed rails.
% ACTORS THAT CARRY PER-FACE COLOUR. Everything else is still one flat value, which
% is what the remaining primitives deserve until they are rebuilt as parts.
PERFACE = struct('cow', ZCOL, 'bus', BCOL, 'auto', ACOL, 'wrong', WCOL, 'ace', ECOL);

shots = { 'giveway',  beatsRaw.GIVEWAY.t + 1.2, 'eye',   'at the line - nobody yields'
          'probe',    beatsRaw.PROBE.t + 1.0,   'eye',   'probing - nosed out, reading the auto'
          'commit',   beatsRaw.COMMIT.t + 0.6,  'chase', 'the auto lifted 1.8 km/h - committed'
          'wrongway', beatsRaw.HOLD.t + 1.0,    'chase', 'wrong-way rider - holding the line'
          'ring',     beatsRaw.CIRCULATE.t+3.5, 'over',  'on the ring, no lane markings' };

S = sc.scene('Hud', false, 'Width', 1400, 'Height', 800);
for q = 1:size(shots,1)
    [nm, t, cam, note] = shots{q,:};
    i  = max(1, min(numel(L.t), round(t/DT)+1));
    is = max(1, min(numel(poses), round(t/DT)+1));
    [exy, ehd] = P.at(L.s(i), L.e(i));
    S.clearScene(); t0 = tic;
    hf = exy; if strcmp(cam,'over'), hf = C; end
    hm = 0.70; if strcmp(cam,'over'), hm = 0.20; end
    sc.s2render(S, W, 'Radius', 150, 'Detail', 75, 'HazeFrom', hf, 'HazeMax', hm);
    pp = poses{is};
    for r = 1:numel(pp)
        if ~isKey(who, pp(r).ActorID), continue; end
        nA = who(pp(r).ActorID);
        if isfield(PERFACE, nA), cc = PERFACE.(nA); else, cc = COL.(nA); end
        S.mesh(MESH.(nA), [pp(r).Position(1:2), deg2rad(pp(r).Yaw)], cc);
    end
    if ~strcmp(cam,'eye'), S.mesh(MESH.car, [exy, ehd], CCOL); end
    switch cam
        case 'eye',   fwd = P.at(L.s(i)+1.2, L.e(i));  tg = P.at(L.s(i)+28, 0);
                      S.look([fwd 1.35], [tg 1.1], 36);
        case 'chase', S.chase([exy ehd], 'Back', 12, 'Up', 5.6, 'Ahead', 13, 'Fov', 34);
        case 'over',  S.look([C(1)+30 C(2)-30 40], [C 1], 32);
    end
    f = fullfile(outDir, "s2act_" + nm + ".png");  S.save(f);
    fprintf('  %-10s t=%5.2f s  %5.1f s | %s\n', nm, t, toc(t0), note);
end
S.close();
fprintf('\nwrote %d S2 action stills\n\n', size(shots,1));
