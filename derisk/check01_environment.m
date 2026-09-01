%% CHECK 0 + 1 — Environment and licence
% Run this first. Copy the ENTIRE output back, including any errors.
% Nothing else can start until this passes.

diary('check01_output.txt'); diary on;
fprintf('\n===== CHECK 0+1 : ENVIRONMENT =====\n');
fprintf('Date run : %s\n', string(datetime("now")));   % datestr is deprecated
fprintf('Computer : %s\n', computer);

%% --- CHECK 1 : exact release ---------------------------------------
fprintf('\n--- MATLAB VERSION ---\n');
disp(version)
fprintf('Release  : %s\n', version('-release'));

%% --- CHECK 0 : the products, and WHAT EACH ONE UNLOCKS --------------
% Third column says what stops working without it, so a MISSING line is
% actionable rather than just alarming. Sensor Fusion and Navigation were
% absent from this list until 1 Sep 2026 even though the BASELINE needs both -
% which would have surfaced as a mystery failure weeks into Stream E.
needed = { ...
    'MATLAB',                            'MATLAB',    'everything'; ...
    'Simulink',                          'Simulink',  'the closed loop, Stateflow charts'; ...
    'Automated Driving Toolbox',         'driving',   'drivingScenario, roads, lidar generator'; ...
    'Computer Vision Toolbox',           'vision',    'YOLOX, DeepLab, the spotter'; ...
    'Image Processing Toolbox',          'images',    'image handling under the above'; ...
    'Deep Learning Toolbox',             'nnet',      'ONNX import, every learned model'; ...
    'Stateflow',                         'stateflow', 'the planner state machine'; ...
    'Sensor Fusion and Tracking Toolbox','fusion',    'S1 TrackList, AND THE BASELINE'; ...
    'Navigation Toolbox',                'nav',       'Frenet planner, AND THE BASELINE'};

fprintf('\n--- REQUIRED PRODUCTS ---\n');
allOK = true;
for k = 1:size(needed,1)
    name = needed{k,1};
    hasIt = ~isempty(ver(needed{k,2}));
    if hasIt
        v = ver(needed{k,2});
        fprintf('  [ OK ]      %-34s v%s\n', name, v(1).Version);
    else
        fprintf('  [ MISSING ] %-34s <-- BLOCKS: %s\n', name, needed{k,3});
        allOK = false;
    end
end

%% --- Needed only for specific jobs ---------------------------------
fprintf('\n--- NEEDED FOR SPECIFIC JOBS ---\n');
optional = {'Lidar Toolbox','lidar','PointPillars (model 5). Not needed otherwise'; ...
            'Mapping Toolbox','map','real terrain elevation for the ghat road'; ...
            'Parallel Computing Toolbox','parallel','GPU training. Slower without it, not blocked'; ...
            'Simulink 3D Animation','sl3d','the Unreal scenes. Stretch goal only'};
for k = 1:size(optional,1)
    if ~isempty(ver(optional{k,2}))
        fprintf('  [ OK ]      %-30s\n', optional{k,1});
    else
        fprintf('  [ absent ]  %-30s %s\n', optional{k,1}, optional{k,3});
    end
end

%% --- YOLOX training add-on -----------------------------------------
% This one is nasty: yoloxObjectDetector exists WITHOUT the add-on and only
% TRAINING is missing, so the failure arrives late and reads like a typo.
fprintf('\n--- YOLOX TRAINING (model 3) ---\n');
if exist('trainYOLOXObjectDetector','file') == 2
    fprintf('  [ OK ]      trainYOLOXObjectDetector is available\n');
elseif exist('yoloxObjectDetector','file') == 2
    fprintf('  [ MISSING ] the detector exists but TRAINING does not.\n');
    fprintf('              Home -> Add-Ons -> Get Add-Ons -> "Automated Visual Inspection\n');
    fprintf('              Library for Computer Vision Toolbox". Free.\n');
    fprintf('              Only blocks model 3. Everything else runs without it.\n');
else
    fprintf('  [ absent ]  no YOLOX at all - Computer Vision Toolbox is missing\n');
end

%% --- ONNX support package ------------------------------------------
fprintf('\n--- ONNX IMPORT ---\n');
if exist('importNetworkFromONNX','file')
    fprintf('  [ OK ]      importNetworkFromONNX is available\n');
elseif exist('importONNXNetwork','file')
    fprintf('  [ OLD ]     only importONNXNetwork found (pre-R2023b style)\n');
else
    fprintf('  [ MISSING ] no ONNX import.\n');
    fprintf('              Home -> Add-Ons -> Get Add-Ons -> "Deep Learning Toolbox Converter\n');
    fprintf('              for ONNX Model Format". Free, and the product installer does NOT\n');
    fprintf('              include it. check04 cannot run without it.\n');
end

%% --- Full product list, for the record ------------------------------
fprintf('\n--- FULL INSTALLED PRODUCT LIST ---\n');
ver

fprintf('\n===== VERDICT =====\n');
if allOK
    fprintf('All seven required products present. Proceed to check02_lidar_cow.m\n');
else
    fprintf('BLOCKED. Email the licence admin with the MISSING lines above.\n');
end
diary off;
fprintf('\nOutput also saved to check01_output.txt\n');
