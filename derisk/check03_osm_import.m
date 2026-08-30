%% CHECK 3 — Import a REAL Indian junction from OpenStreetMap
% This is Team TwinX's headline move, free and built in.
% BEFORE RUNNING: download an .osm file (see derisk/HOW-TO-RUN.md step 3)
% and put it in this folder as meerut.osm

diary('check03_output.txt'); diary on;
fprintf('\n===== CHECK 3 : OPENSTREETMAP IMPORT =====\n');
fprintf('Date run : %s\nRelease  : %s\n\n', datestr(now), version('-release'));

osmFile = 'meerut.osm';

try
    if ~isfile(osmFile)
        error('derisk:noOSM', ['Cannot find %s in %s\n' ...
              'Download it first — see HOW-TO-RUN.md step 3.'], osmFile, pwd);
    end
    d = dir(osmFile);
    fprintf('[1] Found %s (%.1f KB)\n', osmFile, d.bytes/1024);

    fprintf('[2] Importing into a drivingScenario...\n');
    scenario = drivingScenario;
    roadNetwork(scenario, 'OpenStreetMap', osmFile);
    fprintf('    OK — import returned without error.\n');

    rn = roadNames(scenario);
    fprintf('[3] Roads imported : %d\n', numel(rn));
    for k = 1:min(numel(rn), 15)
        fprintf('      %2d. %s\n', k, rn{k});
    end
    if numel(rn) > 15, fprintf('      ... and %d more\n', numel(rn)-15); end

    fprintf('[4] Plotting...\n');
    fig = figure('Visible','on');
    plot(scenario); title('Real road geometry imported from OpenStreetMap');
    saveas(fig, 'check03_osm_map.png');

    fprintf('\n===== VERDICT =====\n');
    if numel(rn) > 0
        fprintf('  PASS. %d real roads imported with zero manual work.\n', numel(rn));
        fprintf('  This is TwinX''s move, and it cost us nothing.\n');
    else
        fprintf('  PARTIAL. Import ran but produced no roads. Try a denser junction area.\n');
    end
    fprintf('Figure saved: check03_osm_map.png  <-- send this image\n');

catch ME
    fprintf('\n***** ERROR *****\nIdentifier : %s\nMessage    : %s\n', ME.identifier, ME.message);
    for k = 1:numel(ME.stack)
        fprintf('  at %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
    fprintf('***** SEND THIS ENTIRE BLOCK BACK *****\n');
end
diary off;
