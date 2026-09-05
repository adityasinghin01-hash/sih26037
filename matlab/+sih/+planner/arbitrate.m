function [winner, k, info] = arbitrate(roles)
%ARBITRATE  Many road users, one command: pick the most dangerous and plan against it.
%
%   Person A's multi-agent arbitration. A junction hands us several road users at once
%   and sih.planner.chooseVelocity answers about exactly one, so something has to choose.
%   This is that something, and it is deliberately the smallest function in the planner.
%
%   HOW IT CHOOSES
%   The most dangerous agent is the one with the SMALLEST h = Lambda - Beta. That is the
%   same barrier value AGENTS.md section 3 S4 says to log every step as our safety
%   evidence, so arbitration is not a new idea with a new threshold - it is the number
%   the project already stands on, minimised.
%
%   WHY IT TAKES NO POSITIONS, AND WHY THAT IS THE POINT
%   Everything here comes out of the Role array. There is no ego pose and no TrackList,
%   so THERE IS NO FRAME TO GET WRONG. The failure this avoids is the one written up in
%   sih.planner.assignRoles's header: hand a function an ego-frame track list together
%   with a world-frame ego pose and it does not error, it silently returns the wrong
%   answer for every agent. A function that never sees a position cannot make that
%   mistake, and that is worth more than the handful of sums it saves.
%
%   The vo the winner needs comes from assignRoles's second output, which was already
%   being built and thrown away:
%
%     [roles, vos] = sih.planner.assignRoles(egoPos, egoVel, egoYaw, tracks);
%     [winner, k]  = sih.planner.arbitrate(roles);
%     cmd          = sih.planner.chooseVelocity(winner, vos(k), egoState);
%
%   WHY LOWEST TrackID BREAKS A TIE
%   Two agents can produce the same h - two symmetric cars at a crossroads is the
%   ordinary case, not a freak one. MATLAB's min() would then return whichever came
%   first in the list, and the list order is perception's business, not ours. TrackID is
%   stable across frames and never reused (S1), so choosing the lowest one makes the same
%   scene produce the same decision on every run. A demo that flickers between two equally
%   valid answers looks broken even when it is right.
%
%   WHAT AN EMPTY ROAD RETURNS
%   No agents means nobody to negotiate with, so there is no winner: k comes back EMPTY
%   and info.H is NaN. AGENTS.md S1 guarantee 3 says an empty TrackList must not cause an
%   error, and this honours it. THE CALLER MUST CHECK isempty(k) BEFORE INDEXING vos(k) -
%   there is nothing sensible to hand chooseVelocity when there is nothing there.
%
%   THIS FUNCTION IS NOT IN plan/ OR AGENTS.md
%   The multi-agent split was settled verbally by Aditya and relayed, and the interface
%   above was chosen by Person A on 4 September 2026 rather than read out of a document.
%   TODO(unverified): show Aditya this signature.
%
%   INPUT
%     roles  struct array  Role (AGENTS.md section 3 S4) as returned by
%                          sih.planner.assignRoles. Needs .TrackID, .Beta, .Lambda.
%                          MAY BE EMPTY.
%
%   OUTPUTS
%     winner  (1,1) uint8   the winning agent's role code (S7), ready for chooseVelocity.
%                           SAFE (0) when there is no winner
%     k       index         position of the winner in roles, so the caller can take
%                           vos(k). EMPTY when there is no winner
%     info    (1,1) struct  .TrackID  the winner's ID, uint32(0) when there is none
%                           .H        the winning (smallest) h, NaN when there is none
%                           .NumConsidered  how many agents were weighed
%                           .Reason   string, why this one - for D5's log

arguments
    roles struct
end

SAFE = uint8(0);

info = struct('TrackID', uint32(0), 'H', NaN, 'NumConsidered', numel(roles), ...
              'Reason', "");

if isempty(roles)
    winner = SAFE;
    k      = [];
    info.Reason = "no road users - nothing to negotiate with";
    return
end

iRequireFields(roles, {'TrackID','Beta','Lambda'});

h = [roles.Lambda] - [roles.Beta];

% min() ignores NaN, so an agent whose geometry could not be computed never wins by
% accident. All-NaN means we know nothing about anybody, which is not the same as safe.
if all(isnan(h))
    winner = SAFE;
    k      = [];
    info.Reason = "every agent's barrier is NaN - no usable geometry";
    return
end

hMin = min(h);

% Ties resolved by lowest TrackID, not by list order. See the header.
tied = find(h == hMin);
if isscalar(tied)
    k = tied;
else
    ids       = [roles(tied).TrackID];
    [~, iLow] = min(ids);
    k         = tied(iLow);
end

winner        = uint8(roles(k).Role);
info.TrackID  = roles(k).TrackID;
info.H        = hMin;

if isscalar(tied)
    info.Reason = "smallest barrier h of " + numel(roles) + " agents";
else
    info.Reason = "smallest barrier h, tied " + numel(tied) + " ways, lowest TrackID wins";
end
end

% -------------------------------------------------------------------------------------

function iRequireFields(s, names)
% Fail loudly and by name. A missing field would otherwise surface as a confusing
% error from the arithmetic three lines later.
for i = 1:numel(names)
    if ~isfield(s, names{i})
        error('sih:planner:arbitrate:missingField', ...
              'roles is missing required field ''%s''.', names{i});
    end
end
end
