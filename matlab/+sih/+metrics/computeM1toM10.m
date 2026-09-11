function M = computeM1toM10(D, LOG, DT)
%COMPUTEM1TOM10  Same formulas as world/build/backup/matlab/+backup/metrics.m,
%   adapted to demo_play's LOG instead of that file's `out` struct - see
%   sih.metrics.writeDemoResults's own header for why that reuse is a
%   disclosed decision, not a verified one.
%
%   PULLED OUT of writeDemoResults.m on 11 Sep 2026 (Phase 1 of the planner/
%   ML side-build, "Bring Your Own Planner" benchmark) so a SECOND caller -
%   sih.bench.runOne, which scores planners other than demo_play's own -
%   can compute the identical M1-M10 without a second, drifting copy of this
%   math. Byte-identical to the version that was inline here; nothing about
%   the formulas changed, only where they live. writeDemoResults now calls
%   this function instead of a local one - re-run the 344-test suite after
%   touching either file, exactly as before.
%
%   INPUTS
%     D    (1,1) struct  needs .Poses, .Who, .DIMS - the route's own scripted
%          traffic, same shape demo_play.m builds. .EgoWidth is optional
%     LOG  (1,1) struct  needs .x .y .v .t .cmd .e .ReachedEnd - the shape
%          demo_play.m's runPlanner (or sih.bench.runOne) produces
%     DT   (1,1) double  s, the step used for M7/M8's own derivatives
%
%   OUTPUT
%     M  struct  M1_distance_m ... M10_latWobble_m, plus RouteLength_m,
%        EgoWidth_m, EgoLength_m, BarrierViolations, BarrierViolations_Imminent

egoWidth = 1.8; egoLen = 4.7;   % TUNE.EgoWidth/EgoLength in demo_play's runPlanner
% A REAL BUG, FOUND PREPARING THIS SESSION'S CASE STUDY: egoWidth used to be
% this hardcoded default unconditionally, even though runPlanner itself reads
% D.EgoWidth when the route sets one (S3's is 1.90 m, not 1.8 - sc.s3geom).
% M6_minClearance_m below used the wrong, narrower ego for every S3 run,
% UNDERSTATING how tight its clearances really are - the unsafe direction of
% error. EgoLength has no such route override anywhere in demo_play.m (grep
% confirms every TUNE.EgoLength is the same 4.7), so it needs none here either.
if isfield(D, 'EgoWidth'), egoWidth = D.EgoWidth; end

x = LOG.x(:); y = LOG.y(:); v = LOG.v(:); t = LOG.t(:);
d = [0; cumsum(vecnorm(diff([x y]), 2, 2))];

M.M1_distance_m    = d(end);
M.M2_duration_s    = t(end) - t(1) + DT;
M.M3_meanSpeed_kmh = 3.6*mean(v);
M.M4_maxSpeed_kmh  = 3.6*max(v);

% M5: h = lambda - beta, the safety barrier. NaN (no agent was in range) is
% deliberately NOT treated as safe - min(...,'omitnan') matches the backup's
% own reasoning: NaN < 0 is false, so a NaN run of steps can never masquerade
% as a clean EMERGENCY-free stretch.
H = nan(numel(LOG.t), 1);
imminent = false(numel(LOG.t), 1);
for i = 1:numel(LOG.cmd)
    if isfield(LOG.cmd{i}, 'H'), H(i) = LOG.cmd{i}.H; end
    % RawState is +sc/planSeat's own un-held label, set the same step h is -
    % it is "EMERGENCY" exactly when h<0 AND within the planner's own 4 s
    % contingency horizon (its EmergencyTCPA_s gate), which is the precise,
    % already-built answer to "was this h<0 actually imminent" - see below.
    if isfield(LOG.cmd{i}, 'RawState'), imminent(i) = (LOG.cmd{i}.RawState == "EMERGENCY"); end
end
mh = min(H, [], 'omitnan');
if isempty(mh), mh = NaN; end
M.M5_minBarrier_rad = mh;

% M6: minimum separation to any of the three scripted actors, world frame,
% the same rectangle-projection method already used and verified in this
% session's own Sensed-vs-ground-truth comparison.
M.M6_minClearance_m = minClearanceToActors(D, LOG, egoWidth, egoLen);

M.M7_stoppedTime_s = DT*sum(v < 0.2);
accel = diff(v)/DT;
M.M8_maxDecel_mps2 = min([0; accel(:)]);
M.M9_completed     = logical(LOG.ReachedEnd);   % demo_play's own precise flag,
                                                 % not the backup's 92%-of-route
                                                 % -length heuristic - a more
                                                 % exact answer was available
M.M10_latWobble_m  = sum(abs(diff(LOG.e)));

M.RouteLength_m     = D.W.Path.Len;
M.EgoWidth_m        = egoWidth;
M.EgoLength_m       = egoLen;
M.BarrierViolations = sum(H < 0, 'omitnan');
% A REAL, DISCLOSED CAVEAT ON THE ABOVE, found preparing this session's case
% study. Raw h<0 is true of ANY stationary object anywhere ahead in the ego's
% own lane, at any distance - that is what the velocity-obstacle definition of
% h actually answers ("would these paths ever intersect at present velocity"),
% not "is this close." +sc/planSeat.m's own header documents this exact
% false-positive (measured there at 99.5% of defined steps in one run) and
% already carries the fix: EMERGENCY is only DISPLAYED when h<0 falls inside
% the planner's own 4 s contingency horizon too. BarrierViolations above is
% the raw count and on its own overstates real safety concern for exactly
% that reason - it is kept, unclipped, per this project's own rule never to
% hide a negative h. BarrierViolations_Imminent reuses the SAME gate the live
% HUD already computes (RawState=="EMERGENCY") rather than re-deriving a
% second, worse answer to a question planSeat.m already answered.
M.BarrierViolations_Imminent = sum(imminent);
end

% ------------------------------------------------------------------ helpers

function sep = minClearanceToActors(D, LOG, egoWidth, egoLen)
sep = inf;
for i = 1:min(numel(LOG.t), numel(D.Poses))
    Pi = D.Poses{i};
    for k = 1:numel(Pi)
        tag = D.Who(Pi(k).ActorID);
        if ~isfield(D.DIMS, tag), continue; end
        dims = D.DIMS.(tag);
        [s, e] = D.W.Path.inverse(Pi(k).Position(1:2));
        [~, hdg] = D.W.Path.at(s, 0);
        th = deg2rad(Pi(k).Yaw) - hdg;
        aL = abs(dims(1)*cos(th)) + abs(dims(2)*sin(th));
        aW = abs(dims(1)*sin(th)) + abs(dims(2)*cos(th));
        gapS = abs(s - LOG.s(i)) - (aL + egoLen)/2;
        gapE = abs(e - LOG.e(i)) - (aW + egoWidth)/2;
        sep = min(sep, max(gapS, gapE));
    end
end
end
