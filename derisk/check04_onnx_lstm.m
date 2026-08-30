%% CHECK 4, PART B — import the ONNX LSTM into MATLAB
% Run check04_onnx_lstm.py FIRST, then run this.

diary('check04_output.txt'); diary on;
fprintf('\n===== CHECK 4 : ONNX -> MATLAB LSTM =====\n');
fprintf('Date run : %s\nRelease  : %s\n\n', datestr(now), version('-release'));

files = dir('toy_lstm_opset*.onnx');
if isempty(files)
    fprintf('No .onnx files here. Run check04_onnx_lstm.py first.\n'); diary off; return
end

for k = 1:numel(files)
    f = files(k).name;
    fprintf('--- Trying %s ---\n', f);
    try
        if exist('importNetworkFromONNX','file')
            net = importNetworkFromONNX(f);
            fprintf('  [OK] importNetworkFromONNX succeeded.\n');
        else
            net = importONNXNetwork(f, 'GenerateCustomLayers', true);
            fprintf('  [OK] importONNXNetwork succeeded (older API).\n');
        end
        fprintf('  Layers: %d\n', numel(net.Layers));
        for L = 1:numel(net.Layers)
            fprintf('     %2d. %-22s %s\n', L, class(net.Layers(L)), net.Layers(L).Name);
        end
        x = dlarray(randn(20,8,'single'), 'TC');
        y = predict(net, x);
        fprintf('  Forward pass OK. Output size: %s\n', mat2str(size(extractdata(y))));
        fprintf('  >>> %s WORKS. Use this opset. <<<\n\n', f);
    catch ME
        fprintf('  [FAILED] %s\n  %s\n\n', ME.identifier, ME.message);
    end
end
fprintf('===== Send this whole output back. =====\n');
diary off;
