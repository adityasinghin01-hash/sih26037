%% CHECK 5 — Does OpenTrafficLab run unmodified?
% BEFORE RUNNING, in a terminal:
%   cd ~/dev/sih2026
%   git clone https://github.com/mathworks/OpenTrafficLab.git
% Then set the path below and run this.

diary('check05_output.txt'); diary on;
fprintf('\n===== CHECK 5 : OPENTRAFFICLAB =====\n');
fprintf('Date run : %s\nRelease  : %s\n\n', datestr(now), version('-release'));

repoPath = fullfile('..','OpenTrafficLab');   % adjust if you cloned elsewhere

try
    if ~isfolder(repoPath)
        error('derisk:noRepo','Cannot find %s — clone it first.', repoPath);
    end
    addpath(genpath(repoPath));
    fprintf('[1] Added to path: %s\n', repoPath);

    fprintf('[2] Key classes we plan to subclass:\n');
    for c = {'DrivingStrategy','TrafficController','Vehicle','Intersection'}
        fprintf('    %-20s %s\n', c{1}, ternary(exist(c{1},'class')==8 || exist(c{1},'file')==2, 'FOUND', 'not found'));
    end

    fprintf('[3] Example scripts in the repo:\n');
    ex = [dir(fullfile(repoPath,'**','*Example*.m')); dir(fullfile(repoPath,'**','*example*.m'))];
    if isempty(ex)
        ex = dir(fullfile(repoPath,'*.m'));
    end
    for k = 1:min(numel(ex),20)
        fprintf('    %s\n', fullfile(ex(k).folder, ex(k).name));
    end
    fprintf('\n===== NEXT =====\n');
    fprintf('Open ONE example above and run it UNMODIFIED.\n');
    fprintf('Send back: did it run? any figure? the full error if not.\n');

catch ME
    fprintf('\n***** ERROR *****\n%s\n%s\n', ME.identifier, ME.message);
    for k = 1:numel(ME.stack)
        fprintf('  at %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end
diary off;

function out = ternary(c,a,b)
    if c, out = a; else, out = b; end
end
