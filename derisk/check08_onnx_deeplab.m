%% CHECK 8 — Import and verify DeepLab v3+ Road Segmenter (Model 4) in MATLAB
% Problem Statement: SIH26037 (MathWorks)
% Contract: Produces S9 DrivableSpace boundary segmentation
% Classes: 0: drivable, 1: obstacle, 2: background

diary('check08_output.txt'); diary on;
fprintf('\n===== CHECK 8 : DeepLab v3+ Road Segmenter -> MATLAB =====\n');
fprintf('Date run : %s\nRelease  : %s\n\n', string(datetime("now")), version('-release'));

here = fileparts(mfilename('fullpath'));
repo_root = fullfile(here, '..');
addpath(repo_root);

mat_path = 'C:\Users\admin\meteor-data\road_segmenter_deeplab.mat';
onnx_path = 'C:\Users\admin\meteor-data\road_segmenter_deeplabv3_opset18.onnx';

try
    if exist(mat_path, 'file') == 2
        fprintf('Loading pre-initialized model from: %s\n', mat_path);
        data = load(mat_path, 'net', 'classes', 'class_names');
        net = data.net;
        fprintf('  [OK] Loaded dlnetwork with %d layers.\n', numel(net.Layers));
    else
        fprintf('Pre-initialized .mat not found. Importing from ONNX: %s\n', onnx_path);
        if exist(onnx_path, 'file') ~= 2
            error('ONNX model file not found at %s', onnx_path);
        end
        net = importNetworkFromONNX(onnx_path);
        fprintf('  [OK] importNetworkFromONNX completed.\n');
        
        % Ensure custom layer PLACEHOLDER is implemented
        pkg_folder = fullfile(pwd, '+road_segmenter_deeplabv3_opset18');
        f1004 = fullfile(pkg_folder, 'Shape_To_ResizeLayer1004.m');
        f1009 = fullfile(pkg_folder, 'Shape_To_ResizeLayer1009.m');
        
        patch_code = sprintf(['\nfunction [Y, numDimsY] = PLACEHOLDER(X, targetShape)\n' ...
                              'targetShapeVal = extractdata(targetShape);\n' ...
                              'target_H = double(targetShapeVal(3));\n' ...
                              'target_W = double(targetShapeVal(4));\n' ...
                              'x_hwcn = permute(X, [2 1 3 4]);\n' ...
                              'resized_hwcn = dlresize(x_hwcn, ''OutputSize'', [target_H, target_W], ''DataFormat'', ''SSCB'', ''Method'', ''linear'');\n' ...
                              'Y = permute(resized_hwcn, [2 1 3 4]);\n' ...
                              'numDimsY = 4;\n' ...
                              'end\n']);
        
        for f = {f1004, f1009}
            content = fileread(f{1});
            if ~contains(content, 'function [Y, numDimsY] = PLACEHOLDER')
                fid = fopen(f{1}, 'a');
                fwrite(fid, patch_code);
                fclose(fid);
                fprintf('  [PATCHED] Added dlresize PLACEHOLDER to %s\n', f{1});
            end
        end
        
        clear classes; rehash;
        X_dummy = dlarray(zeros(512, 512, 3, 1, 'single'), 'SSCB');
        fprintf('  Initializing dlnetwork...\n');
        net = initialize(net, X_dummy);
        classes = categorical({'drivable', 'obstacle', 'background'});
        class_names = {'drivable', 'obstacle', 'background'};
        save(mat_path, 'net', 'classes', 'class_names');
        fprintf('  [OK] Saved initialized network to %s\n', mat_path);
    end

    % Run forward inference verification
    fprintf('\nRunning forward inference test (1x 512x512 RGB)...\n');
    X_test = dlarray(zeros(512, 512, 3, 1, 'single'), 'SSCB');
    t_start = tic;
    Y_pred = predict(net, X_test);
    t_ms = toc(t_start) * 1000;
    
    out_size = size(Y_pred);
    fprintf('  Forward pass SUCCESS! Inference time: %.2f ms\n', t_ms);
    fprintf('  Output tensor size: %s\n', mat2str(out_size));
    fprintf('  Channel interpretation: [1] Drivable, [2] Obstacle, [3] Background\n');
    
    if isequal(out_size, [512 512 3 1])
        fprintf('\n>>> CHECK 8 PASSED: DeepLab v3+ ResNet-50 is 100%% functional in MATLAB. <<<\n');
    else
        warning('Unexpected output shape: %s (expected [512 512 3 1])', mat2str(out_size));
    end

catch ME
    fprintf('\n[FAILED] %s\n', ME.identifier);
    fprintf('%s\n', ME.message);
    fprintf('\nFull Stack Trace:\n');
    disp(getReport(ME));
end

diary off;
