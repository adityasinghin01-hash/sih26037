%% CHECK 4 — import OUR ACTUAL exported model into MATLAB
% Run this AFTER:   python3 python/export/to_onnx.py --model <checkpoint.pt>
%
% WHAT CHANGED, 1 Sep 2026, and why it matters
% This check used to build a TOY LSTM (nn.LSTM + nn.Linear only) and import that. A toy
% importing tells you nothing about the real one: our model also carries LayerNorm,
% normalisation buffers baked in as constants, and a Slice + Flatten instead of an integer
% index. Those are exactly the parts that fail. It now imports the real exported files.
%
% It also used to sweep opsets 13, 11 and 9. Torch >= 2.9 SILENTLY UPCONVERTS all three to
% opset 18, so the old sweep wrote three files that were all the same opset and reported three
% different numbers. Stream D is blocked on this number. Sending them a wrong one costs a day.
%
% Put the .onnx files next to this script, or run this from the repo root.

diary('check04_output.txt'); diary on;
fprintf('\n===== CHECK 4 : ONNX -> MATLAB =====\n');
fprintf('Date run : %s\nRelease  : %s\n\n', string(datetime("now")), version('-release'));

if exist('importNetworkFromONNX', 'file') ~= 2 && exist('importONNXNetwork', 'file') ~= 2
    fprintf(['NEITHER importer is available.\n' ...
             'Install the free add-on: Home -> Add-Ons -> Get Add-Ons ->\n' ...
             '  "Deep Learning Toolbox Converter for ONNX Model Format"\n' ...
             'The product installer does NOT include it.\n']);
    diary off; return
end

here = fileparts(mfilename('fullpath'));
roots = {pwd, here, fullfile(here, '..', 'python', 'export')};
files = [];
for r = 1:numel(roots)
    files = [files; dir(fullfile(roots{r}, 'yield_*_opset*.onnx'))]; %#ok<AGROW>
end
if isempty(files)
    fprintf(['No yield_*_opset*.onnx found in:\n']);
    for r = 1:numel(roots); fprintf('  %s\n', roots{r}); end
    fprintf(['\nExport them first:\n' ...
             '  python3 python/export/to_onnx.py --model <checkpoint.pt>\n' ...
             'That writes opsets 17, 18 and 20 only. If you see opset 9, 11 or 13 files,\n' ...
             'they are from the old script and every one of them is really opset 18.\n']);
    diary off; return
end

working = strings(0, 1);
for k = 1:numel(files)
    f = fullfile(files(k).folder, files(k).name);
    fprintf('--- %s ---\n', files(k).name);
    isGNN = contains(files(k).name, 'gnn');
    try
        if exist('importNetworkFromONNX', 'file') == 2
            net = importNetworkFromONNX(f);
            fprintf('  [OK] importNetworkFromONNX succeeded.\n');
        else
            net = importONNXNetwork(f, 'GenerateCustomLayers', true);
            fprintf('  [OK] importONNXNetwork succeeded (older API).\n');
        end

        % THE QUESTION THAT ACTUALLY MATTERS. Unsupported operators do not throw - they
        % arrive as a custom layer with a PLACEHOLDER function a human has to write. An
        % import that "succeeded" but left placeholders is not usable.
        cls = arrayfun(@(L) string(class(L)), net.Layers);
        ph = cls(contains(cls, "PlaceholderLayer", 'IgnoreCase', true));
        fprintf('  Layers: %d\n', numel(net.Layers));
        if ~isempty(ph)
            fprintf('  [PLACEHOLDERS] %d layer(s) need hand-written code:\n', numel(ph));
            for i = 1:numel(ph); fprintf('     %s\n', ph(i)); end
            fprintf('  >>> NOT USABLE AS-IS. Report these names. <<<\n\n');
            continue
        end
        fprintf('  No placeholder layers - every operator was converted.\n');

        % Forward pass with the CONTRACT shapes, not invented ones.
        %   model 1: sequence [1, 20, 31]          -> yield_logits [1, 2]
        %   model 2: sequence [1, A, 20, 31] + adjacency [1, A, A] -> [1, A, 2]
        if isGNN
            A = 16;                                    % MAX_AGENTS, fixed at export
            seq = dlarray(randn(1, A, 20, 31, 'single'));
            adj = dlarray(zeros(1, A, A, 'single'));
            y = predict(net, seq, adj);
        else
            seq = dlarray(randn(20, 31, 'single'), 'TC');
            y = predict(net, seq);
        end
        fprintf('  Forward pass OK. Output size: %s\n', mat2str(size(extractdata(y))));
        fprintf('  >>> %s WORKS. <<<\n\n', files(k).name);
        working(end+1, 1) = string(files(k).name); %#ok<AGROW>

    catch ME
        fprintf('  [FAILED] %s\n  %s\n\n', ME.identifier, ME.message);
    end
end

fprintf('=====================================================\n');
if isempty(working)
    fprintf('NOTHING IMPORTED. Send this whole output - every line.\n');
else
    fprintf('Imported cleanly:\n');
    for i = 1:numel(working); fprintf('  %s\n', working(i)); end
    fprintf(['\nSEND THE OPSET NUMBER FROM THE FILENAME TO STREAM D NOW.\n' ...
             'It is the one thing blocking them. If several work, prefer the HIGHEST your\n' ...
             'release supports - R2024b tops out at 18, R2025a+ at 20 - because the GNN''s\n' ...
             'GELU only becomes a natively supported operator at opset 20.\n']);
end
diary off;
