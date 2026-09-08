function p = refRoot()
%REFROOT  The SIH26037-Reference folder, found from this file rather than hardcoded.
%   AGENTS.md section 6: never hardcode a path under /Users/ or C:\.
% this file is  <ref>/build/backup/matlab/+backup/refRoot.m  - five levels down
p = string(fileparts(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))))));
end
