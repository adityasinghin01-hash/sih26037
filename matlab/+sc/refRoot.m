function p = refRoot()
%REFROOT  The SIH26037-Reference folder, found from this file rather than hardcoded.
%   AGENTS.md section 6: never hardcode a path under /Users/ or C:\.
% this file is  <ref>/matlab/+sc/refRoot.m  - three levels down
p = string(fileparts(fileparts(fileparts(mfilename('fullpath')))));
end
