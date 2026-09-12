%S2_WORLD_SHOTS  PHASE 5 - build the chowk and render it from four viewpoints.
here = fileparts(mfilename('fullpath')); addpath(here);
outDir = fullfile(here,'renders'); if ~isfolder(outDir), mkdir(outDir); end

fprintf('\n================ S2 WORLD, PHASE 5 ================\n');
W = sc.s2world();
C = W.Centre;

fprintf('\n--- WHAT IS REAL AND WHAT IS OURS ---\n');
fprintf('  REAL: node (%.1f, %.1f), written (340.1, -579.9) -> %.1f m\n', ...
        C(1), C(2), hypot(C(1)-340.1, C(2)+579.9));
fprintf('  REAL: arm bearings %.0f %.0f %.0f %.0f deg, all within 1 deg of the map\n', W.Bearing);
fprintf('  OURS: the island. There is NO island in the OSM data - the gyratory is\n');
fprintf('        built to IRC 65:2017, not traced. Never claim it as the map.\n');
fprintf('  IRC:  island %.0f + 2 x carriageway %.0f = inscribed %.0f m, weave %.0f m (min 30)\n', ...
        W.IslandDia, W.Circ, W.Inscribed, W.Weave);
fprintf('  ego enters on arm %s and exits on arm %s\n', ...
        W.Arm(W.EntryArm).Name, W.Arm(W.ExitArm).Name);

shots = { 'approach', 'the give-way line on arm D - nobody yields'
          'circulating','on the ring, no lane markings at all'
          'island',    'the island, plinth and statue'
          'over',      'the whole gyratory from above' };

S = sc.scene('Hud', false, 'Width', 1400, 'Height', 800);
for k = 1:size(shots,1)
    nm = shots{k,1};
    S.clearScene(); t0 = tic;
    % the haze origin is the CAMERA's ground position, per shot
    switch nm
        case 'approach',    hf = W.Arm(4).Path.at(34,0);  hm = 0.70;
        case 'circulating', hf = W.RingPath.at(W.RingPath.Len*0.35,0); hm = 0.70;
        case 'island',      hf = [C(1)+26 C(2)-20];       hm = 0.55;
        case 'over',        hf = C;                        hm = 0.18;
    end
    st = sc.s2render(S, W, 'Radius', 150, 'Detail', 70, 'HazeFrom', hf, 'HazeMax', hm);
    P = W.Arm(4).Path;
    switch nm
        case 'approach'
            e = P.at(34, 1.75);  tg = P.at(0, 0);
            S.look([e 1.35], [tg 1.0], 34);
        case 'circulating'
            R = W.RingPath;  e = R.at(R.Len*0.35, 0);  tg = R.at(R.Len*0.75, 0);
            S.look([e 1.35], [tg 1.2], 40);
        case 'island'
            S.look([C(1)+26 C(2)-20 6.5], [C(1) C(2) 3.0], 26);
        case 'over'
            S.look([C(1)+52 C(2)-52 78], [C 0], 34);
    end
    f = fullfile(outDir, "s2_" + nm + ".png");  S.save(f);
    fprintf('  %-12s %5.1f s | %d arms, %d giveway, %d splitters, %d posts, %d grass, %d trees | %s\n', ...
            nm, toc(t0), st.Arms, st.GiveWay, st.Splitters, st.Posts, st.Grass, st.Trees, shots{k,2});
    assert(isfile(f), "sc:noRender", "%s not written", f);
end
S.close();
fprintf('\nwrote %d S2 stills\n==================================================\n\n', size(shots,1));
