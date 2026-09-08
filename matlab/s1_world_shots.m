%S1_WORLD_SHOTS  Build the S1 static world and render it from five viewpoints.
%
%   PHASE 2. This exists to be LOOKED AT. The rule that produced every fix so far is
%   "render it, look at the image, fix what is wrong" - reasoning about a scene has
%   never once found what one glance at it finds.
%
%   Three of the five shots are the SAME sight line at three ranges, because the whole
%   S1 result rests on the reveal being geometric. Each one prints the occlusion verdict
%   from sc.path/visible BEFORE it is drawn, so the picture can be checked against the
%   number instead of admired.
%
%   Run:  matlab -batch "run('.../matlab/s1_world_shots.m')"

here = fileparts(mfilename('fullpath'));
addpath(here);
outDir = fullfile(here,'renders');
if ~isfolder(outDir), mkdir(outDir); end

fprintf('\n================ S1 WORLD, PHASE 2 ================\n');
tw = tic;
W  = sc.s1world();
fprintf('[build] %.2f s\n', toc(tw));

P   = W.Path;
CS  = W.CowStation;
CE  = W.CowEmergeE;
OCC = W.Occluders;

% ---------------------------------------------------------------- the sight line, stated
fprintf('\n--- SIGHT LINE TO THE COW AT STATION %.0f, e = %+.2f m ---\n', CS, CE);
fprintf('  %-8s %-9s %-9s %s\n','gap','visible','blocker r','blocker station/offset');
for gap = [90 70 60 50 46 44 42 40 30 20]
    [tf, bl] = P.visible(CS-gap, 1.75, CS, CE, OCC);
    if isempty(bl)
        fprintf('  %5.0f m  %-9s %-9s %s\n', gap, string(tf), '-', '-');
    else
        [bs, be] = P.inverse(bl(1:2));
        fprintf('  %5.0f m  %-9s %6.2f m   s=%.0f m, e=%+.1f m\n', gap, string(tf), bl(3), bs, be);
    end
end
fprintf('  solved reveal: %.0f m (specification %.0f m)\n', W.RevealDistance, W.RevealTarget);

% ---------------------------------------------------------------- HONESTY CHECK
% Do the TREES contribute anything to the reveal, or is it the undergrowth alone?
% If crowns 9-16 m up are inert at 1.75 m eye height, the occluder list should say so
% rather than carry them as decoration that looks like it is doing work.
scrubOnly = W.Scrub;
dScrub = P.revealDistance(CS, CE, scrubOnly, 200);
dAll   = P.revealDistance(CS, CE, OCC,       200);
fprintf('  reveal with scrub only: %.0f m | with trees + scrub: %.0f m -> trees contribute %.0f m\n', ...
        dScrub, dAll, dScrub - dAll);

% ---------------------------------------------------------------- the shots
shots = struct('name',{},'eyeS',{},'rad',{},'from',{},'at',{},'fov',{},'probe',{},'note',{});

for g = [60 W.RevealDistance 22]
    s0 = CS - g;
    [e0, h0] = P.at(s0, 1.75);
    tgt = P.at(s0 + 46, 1.10);
    shots(end+1) = struct('name', sprintf('s1_drive_%02.0fm', g), ...
        'eyeS', s0, 'rad', 200, 'from', [e0 1.35], 'at', [tgt 1.05], ...
        'fov', 34, 'probe', true, ...
        'note', sprintf('driver eye, %.0f m short of the cow', g));           %#ok<SAGROW>
end

cf = P.at(CS-10, -7);  ct = P.at(CS+10, 24);
shots(end+1) = struct('name','s1_clearing','eyeS',CS,'rad',210, ...
    'from',[cf 3.4],'at',[ct 1.6],'fov',42,'probe',true, ...
    'note','the clearing - the hole in the forest the herd comes out of');

% STEEP, not oblique. The first version sat 62 m up at 160 m back - about 21 degrees
% above the horizon - and 16 m crowns flanking a 9.5 m half-corridor closed over the
% road completely. A shot of a corridor has to look INTO it.
of = P.at(CS-95, -55);  ot = P.at(CS+25, 0);
shots(end+1) = struct('name','s1_corridor','eyeS',CS,'rad',300, ...
    'from',[of 145],'at',[ot 0],'fov',31,'probe',true, ...
    'note','steep oblique - the corridor, the bend and the clearing together');

fprintf('\n--- RENDERING %d SHOTS ---\n', numel(shots));
S = sc.scene('Hud', false, 'Width', 1400, 'Height', 800);
for k = 1:numel(shots)
    sh = shots(k);
    S.clearScene();
    t0 = tic;
    focus = P.at(sh.eyeS + 40, 0);
    st = sc.s1render(S, W, 'Focus', focus, 'Radius', sh.rad, 'Probe', sh.probe);
    S.look(sh.from, sh.at, sh.fov);
    f = fullfile(outDir, sh.name + ".png");
    S.save(f);
    fprintf('  %-16s %5.2f s | %4d far + %3d AUTHORED trees, %3d scrub, %3d dashes | %s\n', ...
            sh.name, toc(t0), st.Trees, st.TreesDetailed, st.Scrub, st.Dashes, sh.note);
    assert(isfile(f), "sc:noRender", "%s was not written", f);
end
S.close();

% ---------------------------------------------------------------- FILM-RATE CHECK
% The stills above go through exportgraphics at Resolution 110 - the SLOW path, and the
% only reason a shot costs 25-110 s. A FILM redraws no geometry at all: the world is
% static and only the camera moves. That is the number Phase 4 depends on, so it is
% measured here on the real S1 world rather than inherited from the Phase 1 kit, which
% had 40 buildings and no forest.
fprintf('\n--- FILM RATE, MEASURED ON THIS WORLD ---\n');
Sf  = sc.scene('Hud', false, 'Width', 1280, 'Height', 720);
stf = sc.s1render(Sf, W, 'Focus', P.at(CS-20, 0), 'Radius', 150, 'Probe', true);
nF = 48; tf = tic;
for k = 1:nF
    sk = CS - 90 + (k-1)*(70/nF);
    [ek, ~] = P.at(sk, 1.75);
    tk = P.at(sk + 30, 1.10);
    Sf.look([ek 1.35], [tk 1.05], 34);
    drawnow; getframe(Sf.Fig);
end
spf = toc(tf)/nF;
fprintf('  %d trees drawn once | %d frames | %.3f s/frame | 62 s at 24 fps = %.1f min\n', ...
        stf.Trees, nF, spf, spf*62*24/60);
Sf.close();

fprintf('\nwrote %d PNGs to %s\n', numel(shots), outDir);
fprintf('==================================================\n\n');
