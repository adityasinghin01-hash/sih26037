%S1_ACTION_SHOTS  PHASE 3 - render the action at its beats and LOOK at it.
%   Every defect in Phase 2 was found this way and none of them by reading code.

here = fileparts(mfilename('fullpath')); addpath(here);
outDir = fullfile(here,'renders'); if ~isfolder(outDir), mkdir(outDir); end
run(fullfile(here,'s1_action_run.m'));          % rebuilds W, A, log1, poses, beatsRaw

P = W.Path; CS = W.CowStation;
mo = sc.meshes("motorcycle");
MESH = struct('cow',sc.meshes("zebu"), 'auto',sc.meshes("auto"), ...
              'moto_wrong',mo, 'moto_over',mo, 'tractor',sc.meshes("tractor"), ...
              'trolley',sc.meshes("trolley"), 'car',sc.meshes("car"));
% The cow is PER-FACE (sc.zebuColours), as s1_film and s1_hud_check already do. A flat
% colour here made the action stills show a plaster mould while the film showed a cow -
% two different animals inside one deliverable.
COL = struct('cow',sc.zebuColours(sc.meshes("zebu")), 'auto',sc.autoColours(MESH.auto), ...
             'moto_wrong',sc.motoColours(MESH.moto_wrong), ...
             'moto_over',sc.motoColours(MESH.moto_over,[0.22 0.22 0.26]), ...
             'tractor',sc.tractorColours(MESH.tractor), ...
             'trolley',sc.trolleyColours(MESH.trolley), 'car',[0.80 0.81 0.84]);
% AND THE EGO IS PER-FACE TOO, for exactly the reason written above about the cow.
% s1_film and s1_hud_check both call sc.carColours; this file did not, so the five
% action stills would have shown a flat white wedge while the film and the HUD frames
% showed a hatchback with glass, lamps and a number plate - the deck contradicting
% itself about the vehicle the whole demo is about.
CCOL = sc.carColours(MESH.car);
% THE MOMENT OF THE PASS IS TAKEN FROM THE LOG, NOT GUESSED. COMMIT + 5.4 s was a
% guess and it was wrong: at that instant the ego was still 8.6 m short of her and
% halfway through its lateral move, so the two shots that exist to show the CLEARANCE
% showed the approach instead. This is the step at which it is actually level with her.
[~, iAlong] = min(abs(log1.s - CS));
tAlong = log1.t(iAlong);
fprintf('the ego is level with the cow at t = %.2f s (e = %+.3f m)\n', tAlong, log1.e(iAlong));

shots = { 'a_wrongside', beats.tWrongSide - 3.0,  'chase', 'oncoming motorcycle ON OUR SIDE, closing'
          'b_cowsteps',  A.CowCrossTime + 0.6,    'eye',   'the cow steps onto the carriageway'
          'c_abort',     beatsRaw.ABORT.t + 3.0,  'eye',   'ABORT - the auto is in the gap'
          'd_commit',    tAlong - 1.6,            'chase', 'COMMIT - drawing level with her'
          'e_gap',       tAlong,                  'over',  'level with her - the 0.965 m each side' };

S = sc.scene('Hud', false, 'Width', 1400, 'Height', 800);
for k = 1:size(shots,1)
    [nm, t, cam, note] = shots{k,:};
    ie = max(1, min(numel(log1.t), round(t/DT)+1));
    is = max(1, min(numel(tS),     round(t/DT)+1));
    [exy, ehd] = P.at(log1.s(ie), log1.e(ie));

    S.clearScene(); t0 = tic;
    sc.s1render(S, W, 'Focus', P.at(log1.s(ie)+25, 0), 'Radius', 130, 'Probe', false);
    pp = poses{is};
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        nmA = who(pp(q).ActorID);
        S.mesh(MESH.(nmA), [pp(q).Position(1:2), deg2rad(pp(q).Yaw)], COL.(nmA));
    end
    % THE EGO IS NOT DRAWN FOR A DRIVER'S-EYE SHOT. The camera sits at the car's own
    % origin, so drawing the body around it filled the entire frame with grey bonnet.
    % You do not see your own car from the driver's seat.
    if ~strcmp(cam,'eye'), S.mesh(MESH.car, [exy, ehd], CCOL); end

    switch cam
        case 'chase', S.chase([exy ehd], 'Back', 14, 'Up', 6.4, 'Ahead', 26, 'Fov', 33);
        case 'eye',   fwd = P.at(log1.s(ie) + 1.2, log1.e(ie));   % clear of the bonnet
                      tgt = P.at(log1.s(ie)+34, 0);
                      S.look([fwd 1.35], [tgt 1.05], 34);
        case 'over',  c = P.at(CS, 0);
                      S.look([c(1)+5 c(2)-5 21], [c 0], 30);   % low enough to read the gap
    end
    f = fullfile(outDir, "s1act_" + nm + ".png"); S.save(f);
    fprintf('  %-14s t=%5.2f s  %5.1f s  | %s\n', nm, t, toc(t0), note);
end
S.close();
fprintf('\nwrote %d action stills\n\n', size(shots,1));
