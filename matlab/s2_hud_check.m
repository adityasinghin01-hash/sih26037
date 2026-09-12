%S2_HUD_CHECK  PHASE 4's missing twin - three S2 frames with the full instrument strip.
%
%   S1 has had s1hud_* since Phase 4. S2 never got the equivalent, so the S2 HUD existed
%   ONLY inside the 48-second film: there was no still to put on a slide, and no way to
%   check the strip without paying for a whole film pass. That asymmetry is why this
%   file exists.
%
%   THE THREE BEATS ARE THE ARGUMENT, chosen to mirror S1's three:
%     giveway  - the baseline's whole story. It stops at the line, and on an unsignalled
%                gyratory nobody ever yields to it, so it never starts again.
%     probe    - ours noses out at 0.4 m/s and READS the response. S1 cannot test this,
%                because a cow has no response to read.
%     commit   - the auto's measured lift is classified as a yield and the ego goes.
%                This is the negotiation claim in a single frame.
%
%   EVERYTHING ON THE STRIP IS TAKEN FROM THE RUN, NEVER RETYPED.
%   The caption block and the chart are the SAME ones s2_film.m uses - copied here
%   deliberately rather than re-worded, because a still and a film that caption the
%   same instant differently is how a deck ends up contradicting itself.
%
%   Run:  matlab -batch "run('.../matlab/s2_hud_check.m')"

here = fileparts(mfilename('fullpath')); addpath(here);
run(fullfile(here,'s2_action_run.m'));
outDir = fullfile(here,'renders');
if ~isfolder(outDir), mkdir(outDir); end

mo   = sc.meshes("motorcycle");
MESH = struct('auto',sc.meshes("auto"), 'wrong',mo, 'bus',sc.meshes("bus"), ...
              'ace',sc.meshes("tataace"), 'cow',sc.meshes("zebu"), 'car',sc.meshes("car"));
COL  = struct('auto',[0.14 0.42 0.30], 'wrong',[0.72 0.16 0.12], 'bus',[0.80 0.62 0.18], ...
              'ace',[0.86 0.86 0.88], 'cow',[0.62 0.55 0.44], 'car',[0.80 0.81 0.84]);
ZCOL = sc.zebuColours(MESH.cow);        % per-face; a flat colour makes her a mould
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

% THE CAPTION, WORD FOR WORD FROM s2_film.m. REF-17 s8 / PRD s8: the middle line names
% the stand-in as OURS, because the defence against "you rigged the opponent" is the
% caption, not our good intentions. S2's top line is worded harder than S1's on
% purpose - here MathWorks' planner does not merely fail, it CANNOT START, since
% referencePathFrenet needs Cartesian waypoints and a gyratory supplies none.
CMP = { 'MathWorks referencePathFrenet', 'CANNOT START  -  a gyratory supplies no reference path', [1.00 0.45 0.30]
        'DEFENSIVE STAND-IN (ours, not MathWorks)', 'STOPPED at the give-way line  -  nobody ever yields to it', [0.95 0.35 0.30]
        'OURS', '', [0.35 0.95 0.55] };
RT = W.EgoRoute.P(1:4:end, :);

% the auto's baseline speed, the same window s2_film.m uses
vEarlyW = max(av(1:max(1, round(numel(av)*0.3))));

beats = { 'hud_giveway', beatsRaw.GIVEWAY.t + 1.2, 'at the give-way line - nobody yields'
          'hud_probe',   beatsRaw.PROBE.t   + 1.0, 'probing - nosed out, reading the auto'
          'hud_commit',  beatsRaw.COMMIT.t  + 0.6, 'the auto lifted - committed' };

S = sc.scene('Width', 1400, 'Height', 820);      % HUD on
for k = 1:size(beats,1)
    [nm, t, note] = beats{k,:};
    i  = max(1, min(numel(L.t),   round(t/DT)+1));
    is = max(1, min(numel(poses), round(t/DT)+1));
    [exy, ehd] = P.at(L.s(i), L.e(i));

    S.clearScene();
    sc.s2render(S, W, 'Radius', 130, 'Detail', 75, 'HazeFrom', exy, 'HazeMax', 0.60);
    pp = poses{is};
    for r = 1:numel(pp)
        if ~isKey(who, pp(r).ActorID), continue; end
        nA = who(pp(r).ActorID);
        if isfield(PERFACE, nA), cc = PERFACE.(nA); else, cc = COL.(nA); end
        S.mesh(MESH.(nA), [pp(r).Position(1:2), deg2rad(pp(r).Yaw)], cc);
    end
    S.mesh(MESH.car, [exy, ehd], CCOL);
    % Same camera compromise as s1_hud_check: the strip eats the bottom of the frame,
    % so the look-ahead is shortened to pitch the subject up out from under it.
    % Ahead was 13 and the ego's bottom edge landed exactly on the HUD strip - the
    % bumper, the rear wheels and half the number plate sat behind the instrument
    % panel. Verified on s2hud_hud_commit before changing it, not assumed from S1.
    S.chase([exy ehd], 'Back', 12, 'Up', 5.6, 'Ahead', 10, 'Fov', 33);

    % THE CHART IS THE YIELD READING, NOT A SAFETY BARRIER. sc.hud's chart is named by
    % the CALLER for exactly this reason (REF-17 s11d): the backup computes no
    % lambda-beta barrier, and putting a number under that label would be inventing a
    % result. What S2 measures is the circulating auto's speed, and the LIFT in it is
    % the whole negotiation - so that is what is plotted.
    yd  = 3.6*max(0, vEarlyW - av(is));
    yds = 3.6*max(0, vEarlyW - av(1:min(i, numel(av))));
    cmp = CMP;  cmp{3,2} = sprintf('%s  -  %s', L.State(i), L.Note(i));

    sc.hud(S, struct('State', L.State(i), 'Note', L.Note(i), 'Speed', L.v(i), ...
        'Gap', yd, 'ChartRef', 1.5, ...
        'ChartTitle', 'measured lift of the circulating auto (km/h)  -  yield read above 1.5', ...
        'T', L.t(1:min(i,numel(yds))), 'Hs', yds, ...
        'Route', RT, 'Pos', exy, 'Title', 'S2 - the chowk, an unsignalled gyratory', ...
        'Compare', {cmp}));

    f = fullfile(outDir, "s2hud_" + nm + ".png");
    S.save(f);
    fprintf('  %-12s t=%5.2f s  state %-10s  speed %4.1f km/h  auto lift %.2f km/h | %s\n', ...
            nm, L.t(i), L.State(i), L.v(i)*3.6, yd, note);
    assert(isfile(f), "sc:noRender", "%s was not written", f);
end
S.close();
fprintf('\nwrote %d S2 HUD frames to %s\n\n', size(beats,1), outDir);
