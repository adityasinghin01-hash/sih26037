%% CHECK 0 + 1 — Environment and licence
% Run this first. Copy the ENTIRE output back, including any errors.
% Nothing else can start until this passes.

diary('check01_output.txt'); diary on;
fprintf('\n===== CHECK 0+1 : ENVIRONMENT =====\n');
fprintf('Date run : %s\n', datestr(now));
fprintf('Computer : %s\n', computer);

%% --- CHECK 1 : exact release ---------------------------------------
fprintf('\n--- MATLAB VERSION ---\n');
disp(version)
fprintf('Release  : %s\n', version('-release'));

%% --- CHECK 0 : the seven products we must have ---------------------
needed = { ...
    'MATLAB',                      'MATLAB'; ...
    'Simulink',                    'Simulink'; ...
    'Automated Driving Toolbox',   'driving'; ...
    'Computer Vision Toolbox',     'vision'; ...
    'Image Processing Toolbox',    'images'; ...
    'Deep Learning Toolbox',       'nnet'; ...
    'Stateflow',                   'stateflow'};

fprintf('\n--- REQUIRED PRODUCTS ---\n');
allOK = true;
for k = 1:size(needed,1)
    name = needed{k,1};
    hasIt = ~isempty(ver(needed{k,2}));
    if hasIt
        v = ver(needed{k,2});
        fprintf('  [ OK ]   %-28s  v%s\n', name, v(1).Version);
    else
        fprintf('  [ MISSING ] %-28s  <-- BLOCKER\n', name);
        allOK = false;
    end
end

%% --- Nice to have, not blockers ------------------------------------
fprintf('\n--- OPTIONAL ---\n');
optional = {'Navigation Toolbox','nav'; 'Lidar Toolbox','lidar'; ...
            'Parallel Computing Toolbox','parallel'; 'Simulink 3D Animation','sl3d'};
for k = 1:size(optional,1)
    if ~isempty(ver(optional{k,2}))
        fprintf('  [ OK ]      %s\n', optional{k,1});
    else
        fprintf('  [ absent ]  %s\n', optional{k,1});
    end
end

%% --- ONNX support package ------------------------------------------
fprintf('\n--- ONNX IMPORT ---\n');
if exist('importNetworkFromONNX','file')
    fprintf('  [ OK ]      importNetworkFromONNX is available\n');
elseif exist('importONNXNetwork','file')
    fprintf('  [ OLD ]     only importONNXNetwork found (pre-R2023b style)\n');
else
    fprintf('  [ MISSING ] no ONNX import. Install "Deep Learning Toolbox Converter for ONNX Model Format"\n');
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
