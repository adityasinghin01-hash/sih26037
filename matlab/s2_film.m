%S2_FILM  PHASE 6 - the S2 film. MP4, chase camera, live HUD.
here = fileparts(mfilename('fullpath')); addpath(here);
run(fullfile(here,'s2_action_run.m'));

% MEMORY BUDGET. This is an 8 GB machine and the world got much heavier when the
% Blender-authored assets went in - an authored neem is 1,604 triangles against the
% primitive's ~117. The first attempt at a film after that was KILLED BY THE SYSTEM
% partway through, leaving a truncated MP4. Two things fixed it, and neither costs
% anything a chase camera can see:
%   - a smaller detail radius, so fewer authored trees are resident per rebuild
%   - a larger refocus distance, so the world is rebuilt less often
% The stills still render at full detail; it is only the 1,486-frame loop that cannot
% afford it.
clear OBS                               %#ok<CLEAR>  the per-step obstacle lists
%   NOT `poses` - the film reads it every frame. Clearing it was my own error and
%   it killed the run at line 49 with 'Unrecognized function or variable'.


% SPEED PASS, 6 Sep - FPS only. s1_film.m's matching Radius/Detail tightening caused
% a one-frame rendering glitch at a world-rebuild boundary and was reverted there -
% not applied here either, for the same reason. FPS alone changes frame count, not
% culling geometry, so it carries none of that risk.
FPS = 18;  outMp4 = fullfile(here,'renders','S2_the_chowk.mp4');
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

% REF-17 s8. The middle line names the stand-in as OURS. And S2's baseline failure is
% STRUCTURAL: an unsignalled gyratory has no Cartesian reference path to give, so
% MathWorks' planner cannot start. That is not a tuning result.
CMP = { 'MathWorks referencePathFrenet', 'CANNOT START  -  a gyratory supplies no reference path', [1.00 0.45 0.30]
        'DEFENSIVE STAND-IN (ours, not MathWorks)', 'STOPPED at the give-way line  -  nobody ever yields to it', [0.95 0.35 0.30]
        'OURS', '', [0.35 0.95 0.55] };
RT = W.EgoRoute.P(1:4:end, :);

nF = floor(L.t(end)*FPS);
S = sc.scene('Width', 1280, 'Height', 720);
S.startFilm(outMp4, FPS);
lastS = -inf; actH = gobjects(0); t0 = tic;
for q = 1:nF
    t = (q-1)/FPS;
    i  = max(1, min(numel(L.t), round(t/DT)+1));
    is = max(1, min(numel(poses), round(t/DT)+1));
    [exy, ehd] = P.at(L.s(i), L.e(i));
    if abs(L.s(i) - lastS) > 70
        S.clearScene();
        sc.s2render(S, W, 'Radius', 105, 'Detail', 28, 'HazeFrom', exy, 'HazeMax', 0.68);
        lastS = L.s(i); actH = gobjects(0);
    else
        delete(actH(isgraphics(actH))); actH = gobjects(0);
    end
    pp = poses{is};
    for r = 1:numel(pp)
        if ~isKey(who, pp(r).ActorID), continue; end
        nA = who(pp(r).ActorID);
        if isfield(PERFACE, nA), cc = PERFACE.(nA); else, cc = COL.(nA); end
        actH = [actH S.mesh(MESH.(nA), [pp(r).Position(1:2), deg2rad(pp(r).Yaw)], cc)]; %#ok<AGROW>
    end
    actH = [actH S.mesh(MESH.car, [exy, ehd], CCOL)]; %#ok<AGROW>
    % Ahead was 13 and the ego's bottom edge landed exactly on the HUD strip - the
    % bumper, the rear wheels and half the number plate sat behind the instrument
    % panel. Verified on s2hud_hud_commit before changing it, not assumed from S1.
    S.chase([exy ehd], 'Back', 12, 'Up', 5.6, 'Ahead', 10, 'Fov', 34);

    yd = 3.6*max(0, max(av(1:max(1,round(numel(av)*0.3)))) - av(is));
    cmp = CMP;  cmp{3,2} = sprintf('%s  -  %s', L.State(i), L.Note(i));
    sc.hud(S, struct('State', L.State(i), 'Note', L.Note(i), 'Speed', L.v(i), ...
        'Gap', yd, 'ChartRef', 1.5, ...
        'ChartTitle', 'measured lift of the circulating auto (km/h)  -  yield read above 1.5', ...
        'T', L.t(1:i), 'Hs', 3.6*max(0, max(av(1:max(1,round(numel(av)*0.3)))) - av(1:min(i,numel(av)))), ...
        'Route', RT, 'Pos', exy, 'Title', 'S2 - the chowk, an unsignalled gyratory', ...
        'Compare', {cmp}));
    S.grab();
    if q == 24
        fprintf('  24 frames in %.1f s -> ETA %.1f min for %d\n', toc(t0), toc(t0)/24*nF/60, nF);
    elseif mod(q,240)==0
        fprintf('  %4d/%d  t=%5.1f s  %.0f%%  (%.1f min)\n', q, nF, t, 100*q/nF, toc(t0)/60);
    end
end
S.endFilm(); S.close();
d = dir(outMp4);
fprintf('\n--- THE S2 FILM ---\n  %d frames at %d fps = %.1f s, %.1f MB, %.1f min\n', ...
        nF, FPS, nF/FPS, d.bytes/1e6, toc(t0)/60);
assert(d.bytes > 5e5, "sc:s2film", "the MP4 is only %d bytes", d.bytes);
