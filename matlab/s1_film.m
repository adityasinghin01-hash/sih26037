%S1_FILM  PHASE 4 - the S1 film. MP4, chase camera, live HUD.
%
%   THE WORLD IS NOT REDRAWN EVERY FRAME. It is static; only the camera and the actors
%   move. Redrawing 1,400 instanced trees 1,488 times is what would make this an hour
%   instead of minutes, so the world is rebuilt only when the ego has travelled far
%   enough to need a new cull window, and between rebuilds only the actor patches are
%   deleted and redrawn.

here = fileparts(mfilename('fullpath')); addpath(here);
run(fullfile(here,'s1_result_run.m'));

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


% SPEED PASS, 6 Sep - Aditya asked to render as fast as possible on the Mac rather
% than move to the lab (MATLAB here is CPU/OpenGL, the lab GPU would not help
% anyway). FIRST ATTEMPT tightened RAD 85->70 and DET 28->20 alongside the FPS cut -
% REVERTED. It introduced a ONE-FRAME glitch at t~60s (a huge indistinct green
% blob filling the frame, gone one frame either side) that is NOT present in the
% original 85/28 render - almost certainly a camera/geometry clash right at a
% world-rebuild boundary, made reachable by the smaller cull radius. Not root-caused
% under deadline pressure; reverted rather than shipped with an unexplained glitch
% in a judged demo. FPS alone (24->18) is the safe lever - it changes frame COUNT,
% not culling or rebuild geometry, so it cannot introduce this class of bug.
FPS = 18;  RAD = 85;  REFOCUS = 70;  DET = 28;
outMp4 = fullfile(here,'renders','S1_cattle_crossing.mp4');

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
CMP = { 'MathWorks referencePathFrenet', 'FAILS TO START  -  0/120 candidates at t=19.7 s', [1.00 0.45 0.30]
        'DEFENSIVE STAND-IN (ours, not MathWorks)', '', [0.95 0.35 0.30]
        'OURS', '', [0.35 0.95 0.55] };
RT = W.Path.P(1:8:end, :);
iStopD = find(D.State=="STOPPED", 1);

nF = floor(log1.t(end)*FPS);
S = sc.scene('Width', 1280, 'Height', 720);
S.startFilm(outMp4, FPS);
focusS = -inf;  actH = gobjects(0);  t0 = tic;
% WALKING LEGS - see sc.zebuWalkLegs. ZCOL is per-face for the BODY mesh's own
% face count and cannot be reused here; the leg mesh needs its own single
% colour, matched to sc.zebuColours' own FAWN (its module-level constant, not
% importable, so restated - REF-04: "Light fawn, paler underside").
LEGCOL = [0.60 0.52 0.40];  cowPrevXY = [];  cowDist = 0;

for k = 1:nF
    t = (k-1)/FPS;
    i  = max(1, min(numel(log1.t), round(t/DT)+1));
    is = max(1, min(numel(poses),  round(t/DT)+1));
    [exy, ehd] = P.at(log1.s(i), log1.e(i));

    if log1.s(i) - focusS > REFOCUS
        S.clearScene();
        sc.s1render(S, W, 'Focus', P.at(log1.s(i)+30, 0), 'Radius', RAD, ...
                    'Detail', DET, 'Probe', false);
        focusS = log1.s(i);  actH = gobjects(0);
    else
        delete(actH(isgraphics(actH)));  actH = gobjects(0);
    end

    pp = poses{is};
    for q = 1:numel(pp)
        if ~isKey(who, pp(q).ActorID), continue; end
        nm = who(pp(q).ActorID);
        if strcmp(nm,'cow'), cc = ZCOL; else, cc = COL.(nm); end
        actH = [actH S.mesh(MESH.(nm), [pp(q).Position(1:2), deg2rad(pp(q).Yaw)], cc)]; %#ok<AGROW>
        % WALKING LEGS, THE ONE ACTUAL WALKING COW ONLY - not every actor
        % named 'cow'. s1_action_run.m gives the three static HERD members
        % the SAME 'cow' label (who(h.ActorID)='cow' for h in A.Herd), which
        % is correct for drawing/dims but wrong for this: keying leg motion
        % off the shared NAME made cowDist accumulate the distance BETWEEN
        % unrelated actors as q iterated across frames - one bad render
        % showed ~97 m/s, caught before it reached the real film. A.Cow's
        % own ActorID is the one true identity check.
        if pp(q).ActorID == A.Cow.ActorID
            cowXY = pp(q).Position(1:2);  cowYaw = deg2rad(pp(q).Yaw);
            % distTraveled advances only while she actually
            % moves - the moment she stops, frame-to-frame delta is ~0 and
            % the legs freeze wherever they are, which is the honest
            % simplification this carries: no eased return to a neutral
            % standing pose, just a mid-stride hold. Far better than a
            % moving body on static legs, which is the defect this exists
            % to fix - not a claim of a fully finished walk cycle.
            if ~isempty(cowPrevXY)
                cowDist = cowDist + hypot(cowXY(1)-cowPrevXY(1), cowXY(2)-cowPrevXY(2));
            end
            cowPrevXY = cowXY;
            [Vl, Fl] = sc.zebuWalkLegs(cowXY, cowYaw, cowDist);
            actH = [actH S.mesh(struct('Vertices',Vl,'Faces',Fl), [0 0 0], LEGCOL)]; %#ok<AGROW>
        end
    end
    actH = [actH S.mesh(MESH.car, [exy, ehd], CCOL)]; %#ok<AGROW>
    % 'Ahead' WAS 13 AND IT PUT THE EGO'S BOTTOM EDGE EXACTLY ON THE HUD STRIP.
    % Measured off the render: the ego sits 13.7 deg below the view axis at Ahead 13,
    % against a 16.5 deg half-frame, i.e. 83 % of the way to the bottom - so the
    % bumper, both rear wheels and half the number plate were behind the instrument
    % panel for every still AND for the whole 62-second film. A shorter look-ahead
    % steepens the view axis and pitches the subject up the frame; at 10 it clears.
    S.chase([exy ehd], 'Back', 12, 'Up', 5.6, 'Ahead', 10, 'Fov', 33);

    jd = max(1, find(D.t <= t, 1, 'last'));
    cmp = CMP;
    if isempty(iStopD) || jd < iStopD
        cmp{2,2} = sprintf('%s  -  %.0f m from her', D.State(jd), max(0, CS - D.s(jd)));
    else
        cmp{2,2} = sprintf('STOPPED  -  %.0f m short of her, %.1f s and counting', ...
                           CS - D.s(jd), t - D.t(iStopD));
    end
    cmp{3,2} = sprintf('%s  -  %s', log1.State(i), log1.Note(i));

    sc.hud(S, struct('State', log1.State(i), 'Note', log1.Note(i), 'Speed', log1.v(i), ...
        'Gap', G.Free(i), 'Margin', G.Margin(i), 'ChartRef', 0.90, ...
        'ChartTitle', 'measured clearance each side (m)   -   required 0.90', ...
        'T', log1.t(1:i), 'Hs', G.Margin(1:i), 'Route', RT, 'Pos', exy, ...
        'Title', 'S1 - forest cattle crossing', 'Compare', {cmp}));
    S.grab();

    if k == 24
        fprintf('  first 24 frames in %.1f s -> ETA %.1f min for %d frames\n', ...
                toc(t0), toc(t0)/24*nF/60, nF);
    elseif mod(k, 240) == 0
        fprintf('  %4d/%d  t=%5.1f s  %.0f%%  (%.1f min elapsed)\n', ...
                k, nF, t, 100*k/nF, toc(t0)/60);
    end
end
S.endFilm(); S.close();

d = dir(outMp4);
fprintf('\n--- THE FILM ---\n');
fprintf('  %s\n  %d frames at %d fps = %.1f s, %.1f MB, built in %.1f min\n', ...
        outMp4, nF, FPS, nF/FPS, d.bytes/1e6, toc(t0)/60);
assert(d.bytes > 5e5, "sc:filmTooSmall", "the MP4 is only %d bytes", d.bytes);
