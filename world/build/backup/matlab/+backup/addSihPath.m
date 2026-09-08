function addSihPath()
%ADDSIHPATH  Put the real sih.planner package on the path, unmodified.
%   The backup calls Stream D's planner as-is. Nothing is forked or copied, so a fix
%   there is a fix here. The repo is found relative to the user's home, and its absence
%   is reported loudly rather than silently falling back to a stub.
persistent done
if ~isempty(done), return; end
repo = fullfile(char(java.lang.System.getProperty('user.home')), 'dev', 'sih2026', 'matlab');
assert(isfolder(repo), "backup:noRepo", ...
    ['Cannot find the sih2026 MATLAB folder at %s\n' ...
     'The backup calls sih.planner.* from the team repo and does not vendor a copy.'], repo);
addpath(repo);
assert(exist('sih.planner.assignRoles','file')==2 || ~isempty(which('sih.planner.assignRoles')), ...
    "backup:noPlanner", "sih.planner.assignRoles not found after adding %s", repo);
done = true;
end
