function [A, log] = reactStep(A, ego, dt, cfg)
%REACTSTEP  PHASE 8 - let a scripted actor respond to the ego, instead of
%   replaying a recording regardless of what the car does.
%
%   [A, log] = sc.reactStep(A, ego, dt)            % cfg.Enabled defaults FALSE
%
%   ===================================================================
%   OFF BY DEFAULT. cfg.Enabled = false returns A UNTOUCHED, byte for byte.
%   ===================================================================
%   Every number this project has measured was taken against scripted actors.
%   If this function could alter them silently, every one of those numbers would
%   become unreproducible. The acceptance test for this file is therefore NOT
%   "does it look reactive" but "does disabling it reproduce the old result
%   exactly". testReactStep.m asserts that directly.
%
%   WHAT IT MAY DO, AND WHAT IT MAY NEVER DO
%   It may change ONE thing: an actor's speed ALONG ITS OWN EXISTING PATH, within
%   a physically sane acceleration limit. It may not move an actor laterally, turn
%   it, teleport it, reverse it, or create or delete one. A reaction model that can
%   do anything can hide any planner failure, and then the benchmark measures our
%   imagination rather than our planner.
%
%   IT MUST NEVER REACT TO RESCUE THE EGO. This is the rule that keeps the result
%   honest, and it is easy to violate by accident. The trigger below is the
%   AGENT'S OWN SITUATION - "is something occupying the space I am moving into" -
%   computed from relative geometry alone. It never reads the planner's state, its
%   candidate set, whether a plan failed, or whether a collision is imminent. An
%   agent that swerves precisely when our planner would have hit it is an
%   invisible home-field advantage, and sih26037-end-goal-locked forbids exactly
%   that: "no home-field advantage baked into scenarios or metrics".
%
%   PER-AGENT NEGOTIABILITY IS THE POINT, not a detail. This project's whole
%   novelty claim is that Indian road users are not interchangeable: a cow ignores
%   you, a pedestrian reacts, a bus asserts. ClassIDs are AGENTS.md section 3 S5,
%   via sih.scenario.classIDByName.
%     cow 10, dog 11        -> IGNORE. An animal does not negotiate with traffic.
%                              This is S1's entire premise; making the cow yield
%                              would delete the scenario's reason to exist.
%     pedestrian 8          -> YIELD, strongly. Highest deceleration authority.
%     motorbike 5, auto 4   -> YIELD, mildly. They thread gaps; they slow, briefly.
%     car 1, van 7          -> YIELD, mildly.
%     bus 3, truck/tractor  -> ASSERT. Mass wins on an Indian road. They do NOT
%       14, cart 13            slow for a car; they hold speed. Encoded as zero
%                              yield authority, NOT as acceleration - an actor
%                              that speeds up at the ego would be manufacturing a
%                              hazard the scenario never specified.
%
%   Reactions are LOGGED per actor per step. An unlogged reaction is
%   indistinguishable from a scripted one, and the first question a judge asks
%   about reactive traffic is "how do you know it reacted?"

arguments
    A   struct
    ego struct
    dt  (1,1) double
    cfg struct = struct()
end

log = struct('Reacted',{{}},'DeltaV',[],'Reason',{{}});
if ~isfield(cfg,'Enabled') || ~cfg.Enabled
    return                      % untouched - the bit-identical path
end

% Yield authority in m/s^2, by ClassID. Absent = not reactive.
auth = containers.Map('KeyType','double','ValueType','double');
auth(8)  = 1.2;    % pedestrian - can stop quickly, and does
auth(5)  = 0.8;    % motorbike
auth(4)  = 0.6;    % auto-rickshaw
auth(1)  = 0.6;    % car
auth(7)  = 0.5;    % van
auth(3)  = 0.0;    % bus      - asserts
auth(14) = 0.0;    % tractor  - asserts
auth(13) = 0.0;    % cart     - asserts
if isfield(cfg,'Authority'), auth = cfg.Authority; end

lookahead = 2.5;                                   % s, the agent's own horizon
if isfield(cfg,'Lookahead'), lookahead = cfg.Lookahead; end

for k = 1:numel(A)
    cid = double(A(k).ClassID);
    if ~isKey(auth, cid) || auth(cid) <= 0
        continue                                    % ignores, or asserts
    end
    v = norm(A(k).Vel(1:2));
    if v < 0.05, continue; end                      % already stopped

    dir = A(k).Vel(1:2) / v;                        % its OWN direction of travel
    rel = ego.XY(:).' - A(k).XY(:).';
    ahead = dot(rel, dir);                          % ego's distance along that line
    lateral = abs(rel(1)*dir(2) - rel(2)*dir(1));   % ego's offset from that line

    % The agent's own situation: is something sitting in the lane I am moving
    % into, within my own lookahead? No planner state is read here.
    reach = v * lookahead;
    if ahead <= 0 || ahead > reach || lateral > 2.0
        continue
    end

    % Slow proportionally to how far into the lookahead the obstruction is.
    urgency = 1 - (ahead / max(reach, eps));        % 0 far, 1 right in front
    dv = -auth(cid) * urgency * dt;
    vNew = max(0, v + dv);
    A(k).Vel(1:2) = dir * vNew;

    log.Reacted{end+1} = A(k).Row;                                      %#ok<AGROW>
    log.DeltaV(end+1)  = vNew - v;                                      %#ok<AGROW>
    log.Reason{end+1}  = sprintf('class %d yielding: ego %.1f m ahead, %.1f m off line', ...
                                 cid, ahead, lateral);                  %#ok<AGROW>
end
end
