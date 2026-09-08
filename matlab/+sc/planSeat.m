function [cmd, st] = planSeat(st, ctx)
%PLANSEAT  The real sih.planner in a +sc driver seat, via the adapter. Shared by
%   sc.s1drivePlanner and sc.s2drivePlanner - scenario-agnostic: everything
%   scenario-specific arrives in ctx (the route, the world, the tracks, the dials).
%
%   SAME [cmd,st] CONTRACT AS sc.s1drive. cmd.v is a TARGET speed, cmd.e a
%   TARGET lateral (+ is LEFT, route/Frenet frame), cmd.State / cmd.Note for the
%   HUD. The integration loop, A_LON/D_LON and sc.lateralStep are unchanged -
%   this replaces the body of the seat and nothing else.
%
%   sc.s1drive (the scripted placeholder) is NOT touched and remains the
%   fallback. Never ship a planner-driven run that measures worse than it.
%
%   EACH STEP
%     1. pack the ego in world coordinates
%     2. S3 = Valid:false for every track  (Models 1&2 gated off - level 4)
%     3. planContingency (trunk mode "B", the D6 terminal-stop reading)
%     4. followTrunk -> EgoCommand
%     5. EgoCommand -> the seat:  cmd.v = trunk's asked-for speed (capped by
%        speedLimit);  cmd.e = the trunk's lateral offset a look-ahead ahead
%        (SteerAngle is NOT passed through - the seat integrates cmd.e via
%        sc.lateralStep).
%
%   ctx MUST carry, on top of the seat scalars .s .e .v .t:
%       .W .Path .RefPath .Tracks .EgoXY .EgoYaw .Kappa .CruiseV
%   ctx MAY carry these Phase-3 tuning dials (defaults in getf below):
%       .TermSpeeds .LatOffsets .Horizon .TimeRes .Inflation .EgoWidth
%       .EgoLength .Wheelbase .LookaheadT .MinLookahead .DMin

if isempty(fieldnames(st))
    st = struct('State',"CRUISE",'Note',"planner: open road",'EscMem',struct(), ...
                'TrackMem',containers.Map('KeyType','double','ValueType','any'), ...
                'HighWaterS',NaN,'LastAdvanceT',NaN);
end
if ~isfield(st,'EscMem'),   st.EscMem = struct(); end
if ~isfield(st,'TrackMem'), st.TrackMem = containers.Map('KeyType','double','ValueType','any'); end
if ~isfield(st,'HighWaterS'),   st.HighWaterS = NaN;   end
if ~isfield(st,'LastAdvanceT'), st.LastAdvanceT = NaN; end
if ~isfield(st,'Neg'),          st.Neg = iNegInit();   end

% ---- Phase-3 dials (safe defaults; the runner overrides) ---------------------
termSpeeds  = getf(ctx,'TermSpeeds',  [0 4 8 12 14.4]);   % INCLUDE the cruise speed
latOffsets  = getf(ctx,'LatOffsets',  [-2.5 -1.585 -0.75 0 0.9 1.75 2.6]);
horizon     = getf(ctx,'Horizon',     4.0);
timeRes     = getf(ctx,'TimeRes',     0.1);
inflation   = getf(ctx,'Inflation',   0.0);
egoWidth    = getf(ctx,'EgoWidth',    1.8);
egoLength   = getf(ctx,'EgoLength',   4.7);
wheelbase   = getf(ctx,'Wheelbase',   2.7);
lookaheadT  = getf(ctx,'LookaheadT',  0.6);
minLook     = getf(ctx,'MinLookahead',2.0);
dMin        = getf(ctx,'DMin',        2.5);

% trajectoryGeneratorFrenet.connect has a singularity at initial speed EXACTLY
% zero (measured: throws at v=0.00, clean at every v >= 0.2). A stopped car still
% needs a plan - deciding whether to creep forward is the probe. So the speed
% handed to the planner is floored; real motion is still governed by cmd.v
% through the seat's accel limits, so this does not make a stopped car move.
vPlan = max(ctx.v, 0.3);
ego = struct('Position',[ctx.EgoXY 0], ...
             'Velocity',vPlan*[cos(ctx.EgoYaw) sin(ctx.EgoYaw) 0], ...
             'Yaw',ctx.EgoYaw);

% ---- Phase 8: bridge a track that just dropped out of the list ---------------
% sih26037-phase5-sensing found a real, measured collision mechanism: simulated
% sensor dropout removes a genuinely-still-there hazard from ctx.Tracks, and
% this seat used to treat "not in this frame's list" as "not there" - which is
% how a noisy pipeline turned the already-known frozen-but-safe structural gap
% into an actual collision (S1 -0.622 m at 27 km/h, S2 -0.877 m to the wrong-
% way rider). TRACED, not assumed: the actual mechanism is NOT a brief
% probabilistic miss - it is a genuine sensor BEARING blind spot. As the ego
% draws level with a roadside hazard mid-pass, the bearing swings toward
% +-90 deg and leaves both forward sensors' cones while still 7-12 m away
% (sih.scenario.sensorSuite's ring range was widened for the same reason, but
% cannot cover every case alone). That blind spot lasts as long as the pass
% itself - S1's own written timeline is COMMIT at t=42.7 to CLEAR at t=47.0,
% ~4.3 s - so the grace window is 6 s, not the 1 s first tried (verified too
% short: the measured gap ran 3+ s and the collision still happened). A
% STATIC hazard (this one) dead-reckons with zero error regardless of window
% length, since extrapolation error only grows with the ghost's OWN velocity -
% confirmed sih.planner never reads Existence for anything but logging
% (grep across +sih/+planner: only NegotiatingStrategy.m, the separate
% Simulink track, touches it), so decaying it here changes no safety math.
% st.TrackMem is a containers.Map handle, mutated in place; threading it
% through st is only so a fresh run starts clean.
tr = iTrackHysteresis(ctx.Tracks, st.TrackMem, ctx.t, getf(ctx,'TrackGrace_s',6.0));

% ---- relevance filter -------------------------------------------------------
% The full TrackList carries the 3 static herd cows sat 13-21 m OFF the road and
% vehicles 100-240 m away. Rolling every one forward and capsule-checking 35
% candidates against it is both slow and a source of spurious prefix cuts (a cow
% 15 m onto the verge should not shorten an in-lane trunk). Keep a track only if
% it is near the road AND within a sensible range along it - or very close.
trS = zeros(1,0);  trE = zeros(1,0);  trHalfE = zeros(1,0);
if ~isempty(tr) && isfield(ctx,'Path')
    relRange   = getf(ctx,'RelevanceRange',   65);
    relOffRoad = getf(ctx,'RelevanceOffRoad',  6);
    keep = false(1, numel(tr));
    aS = zeros(1,numel(tr));  aE = zeros(1,numel(tr));  aH = zeros(1,numel(tr));
    for k = 1:numel(tr)
        [ts, te] = ctx.Path.inverse(tr(k).Position(1:2));
        dAlong   = ts - ctx.s;
        keep(k)  = (hypot(dAlong, te) < 15) || ...
                   (dAlong > -20 && dAlong < relRange && abs(te) < relOffRoad);
        % The track's LATERAL half-extent in the route frame - its body turned
        % into the frame the seat steers in, the same arithmetic both *_planner_run
        % scripts already use to measure separation (aW = |L sin th| + |W cos th|).
        % A broadside cow is 2.05 m across the road, not 0.64 m, and that
        % difference IS the gap arithmetic (SPEC.md says so in capitals).
        [~, hq] = ctx.Path.at(ts, 0);
        th = double(tr(k).Yaw) - hq;
        aS(k) = ts;  aE(k) = te;
        aH(k) = 0.5*(abs(tr(k).Extent(1)*sin(th)) + abs(tr(k).Extent(2)*cos(th)));
    end
    tr = tr(keep);  trS = aS(keep);  trE = aE(keep);  trHalfE = aH(keep);
end
n  = numel(tr);
if n > 0
    yp = struct('TrackIDs',uint32([tr.TrackID].'), ...
                'PYield',  zeros(n,1), ...
                'Valid',   false(n,1));
else
    yp = struct('TrackIDs',uint32([]),'PYield',[],'Valid',logical([]));
end

% ---- the physical corridor, hoisted here so both the Phase 8 sanity check and
% the existing post-followTrunk clamp read the SAME bounds. Phase 6: uses the
% real per-station half-width (sc.s9Width - S2's ring is 8 m, its arms 7 m) in
% place of the old hardcoded ctx.W.Width, a no-op on S1 and a genuine widening
% on S2's ring.
hw  = sc.s9Width(ctx.W, ctx.s);
eLo = getf(ctx,'ELo', -(hw - 0.95));            % ~ -2.55 m on an S1 arm
eHi = getf(ctx,'EHi',  (hw - 0.95) + 0.35);      % ~ +2.90 m (onto the shoulder)
maxSaneSpeed = getf(ctx,'MaxSaneSpeed_mps', 1.5*max(termSpeeds));

planFailed = "";
try
    out = sih.planner.planContingency(ego, ctx.RefPath, tr, yp, ...
              trunkMode          = "B", ...
              lateralOffsets_m   = latOffsets, ...
              terminalSpeeds_mps = termSpeeds, ...
              horizon_s          = horizon, ...
              timeResolution_s   = timeRes, ...
              egoLength_m        = egoLength, ...
              egoWidth_m         = egoWidth, ...
              inflation_m        = inflation);
catch me
    % Deliberation failed this cycle. Safe response = a blocked trunk: brake.
    % The barrier layer carries safety, not this cycle's plan. Logged, not hidden.
    planFailed = string(me.message);
    out = struct('Trunk', struct('CandidateIndex',NaN,'States',zeros(0,3),'Times',zeros(0,1),'Blocked',true), ...
                 'Candidates', struct('Global',{}), 'TrunkMode', "B", 'Blocked', true);
end

% ---- Phase 8, piece 2: candidate-sanity reject -------------------------------
% sih26037-s1-planner-fork: a lateral candidate's frenet2global can overshoot
% off the road on a curve, read as "safe" (nothing off-road to hit), and get
% ranked ahead of a genuinely safe in-road candidate BECAUSE leaving the road
% dodges the traffic that would otherwise block it (measured: "aiming -4.65 m
% off the road, asking 49.5 m/s"). This checks the candidate findSharedTrunk
% ACTUALLY picked (out.Trunk.CandidateIndex) against its own REALIZED Frenet/
% Global output (not its nominal ask) and, if it fails, re-ranks ONLY among the
% already-generated, already-safety-checked candidates for the longest-
% progress one that stays sane. It does not re-derive safety or candidate
% generation - only adds a sanity filter on top of what planContingency already
% computed.
[out.Trunk, sanityOverridden] = iPickSaneTrunk(out, eLo, eHi, maxSaneSpeed);
if sanityOverridden && out.Trunk.Blocked
    out.Blocked = true;
end

% ---- don't just stand there (the D9 un-freeze ladder, rungs 1 and 2) --------
% findSharedTrunk ranks "longest safe stretch" first, and a STOPPED car has a
% trivially long safe stretch - so once blocked it commits to standing still,
% forever. That is the frozen-robot failure this whole project exists to beat.
% D9 (creep -> wait -> horn -> go around -> handover) lives in Person B's chart,
% which is not built. So the seat carries the first two rungs itself.
usedTrunk = out.Trunk;  creeping = false;
if ~out.Trunk.Blocked && ~isempty(out.Trunk.States) && trunkProgress(out.Trunk) < 0.6
    % RUNG 1: creep. A probe FORWARD from roughly where we are - not a lane
    % change. Restricted to candidates whose offset is close to the ego's
    % current line.
    mv = iPickMovingSafe(out, getf(ctx,'CreepMinSteps',16), ctx.e, getf(ctx,'CreepLaneBand',1.4));
    if ~isnan(mv.k)
        usedTrunk = mv.trunk;  creeping = true;
    end
end
% ---- stuck-progress clock, not a consecutive-flag counter -------------------
% FOUND NECESSARY BY RUNNING, not designed in advance: a first version counted
% CONSECUTIVE steps with creeping==true and never fired, because near a real
% obstacle the seat THRASHES - COMMIT, EMERGENCY, PROBE, COMMIT again, every
% 0.05-0.1 s - while making near-zero net progress. That thrashing IS the
% frozen-robot symptom, but it resets a consecutive counter almost every step.
% This tracks real forward progress instead: st.HighWaterS only advances when
% the ego actually gets meaningfully further along the route, and the "stuck"
% clock is how long it's been since that last happened - immune to which
% per-step label fired in between.
if isnan(st.HighWaterS) || ctx.s > st.HighWaterS + 0.5
    st.HighWaterS   = ctx.s;
    st.LastAdvanceT = ctx.t;
end
stuckFor = ctx.t - st.LastAdvanceT;

% ---- D9 RUNG 1.5 (WAIT) AND THE COMMITMENT (PASS) ---------------------------
% MEASURED 7 Sep 2026, and it corrects the Phase 8 account. Dumping the whole
% fan at every stuck tick (out.TerminalPrefixSteps / out.BindingFuture, per
% candidate) shows the seat is NOT short of a safe go-around. At the S1 freeze
% (t=37.25, ego stopped at s=286.06, the cow the ONLY track, 13.9 m ahead):
%
%     off     vT   worst  term  sane  prog   binder
%   -2.50   11.0   41.0  41.0    1  22.85   -        fully safe, 22.85 m
%   -1.58    8.0   41.0  41.0    1  16.71   -        the scripted pass line
%   +0.00    0.0   41.0  41.0    1   0.60   -    <-- out.Trunk.CandidateIndex
%
% A completely unbound 22.85 m pass exists under EVERY future, and
% findSharedTrunk commits to standing still - its documented tie-break is
% longest-safe-stretch first (a stopped car ties at the full horizon), then
% SMALLEST SIDEWAYS OFFSET, and straightness beats the pass. Rung 1 cannot help
% (it needs trunkProgress < 0.6 and the stand-still trunk's progress is exactly
% 0.60). Rung 2 finds the pass, uses it for ONE 0.05 s tick, resets the stuck
% clock, and the ordinary route reverts to standing still for the next 2 s -
% measured 17 times in a row under exact sensing, 0.0045 m of progress each.
%
% So the missing piece is a COMMITMENT that outlives one tick, and a WAIT that
% decides whether one is worth taking yet. Both live here.
stuckAfter_s = getf(ctx,'GoAroundAfterStuck_s', 2.0);
gaMinSteps   = getf(ctx,'GoAroundMinSteps', 25);
negCfg = struct( ...
    'StuckAfter_s',     stuckAfter_s, ...
    'GoAroundMinSteps', gaMinSteps, ...
    'WaitTimeout_s',    getf(ctx,'WaitTimeout_s',   10.0), ...
    'WaitCooldown_s',   getf(ctx,'WaitCooldown_s',   4.0), ...
    'PassMinSteps',     getf(ctx,'PassMinSteps',     max(8, round(gaMinSteps/2))), ...
    'PassBand_m',       getf(ctx,'PassBand_m',       0.35), ...
    'PassHold_s',       getf(ctx,'PassHold_s',      12.0), ...
    'PassDistance_m',   getf(ctx,'PassDistance_m',   4*egoLength), ...
    'MinProgress_m',    getf(ctx,'PassMinProgress_m', 2*egoLength), ...
    'MinClearance_m',   getf(ctx,'MinPassClearance_m', 0.5), ...
    'HalfWidth_m',      hw, ...
    'EgoWidth_m',       egoWidth, ...
    'ELo', eLo, 'EHi', eHi, 'MaxSpeed', maxSaneSpeed);
[st.Neg, neg] = iNegotiate(st.Neg, out, ctx, stuckFor, negCfg, trS, trE, trHalfE);

wentAround = false;  holding = false;  negNote = "";
if neg.Mode == "PASS"
    usedTrunk = neg.Trunk;  creeping = false;  wentAround = true;  negNote = neg.Note;
    if neg.Committed
        st.HighWaterS = ctx.s;  st.LastAdvanceT = ctx.t;
    end
elseif neg.Mode == "WAIT"
    holding = true;  creeping = false;  negNote = neg.Note;
elseif stuckFor >= stuckAfter_s && isfield(out,'TerminalPrefixSteps')
    % THE FLOOR - the fallback when the ladder has nothing to say, most often
    % during the cooldown after a WAIT has timed out.
    %
    % THIS USED TO CALL iPickGoAround, WHICH RANKS BY RAW PROGRESS AND HAS NO
    % CLEARANCE FLOOR, on the reasoning "the floor can never be worse than what
    % the seat did before". MEASURED, that reasoning was wrong: on S2-sensed it
    % committed to offset +1.75 whose clearance to the road users ahead was
    % -0.29 m, while +-2.60 was available at +0.50 m. It is the same defect the
    % floor in iPickPassLine exists to prevent, still live on the fallback path.
    % "Never worse than before" does not hold once the ladder changes WHEN and
    % WHERE the ego arrives at a decision - the fallback is reached in a
    % different state than the old code ever reached it in. So the fallback now
    % applies the same clearance rule as the commit; if nothing acceptable
    % exists it simply does not commit, and the ordinary blocked-trunk braking
    % carries the cycle, which is the safe answer.
    ga = iPickPassLine(out, ctx, negCfg, trS, trE, trHalfE);
    if ~isnan(ga.k)
        usedTrunk = ga.trunk;  creeping = false;
        st.HighWaterS = ctx.s;  st.LastAdvanceT = ctx.t;  wentAround = true;
        negNote = "stuck " + sprintf('%.1f', stuckFor) + " s with no real progress - committed to a go-around (D9 rung 2)";
    end
end

[fc, info] = sih.planner.followTrunk(usedTrunk, ego, ...
          wheelbase_m     = wheelbase, ...
          lookaheadTime_s = lookaheadT, ...
          minLookahead_m  = minLook);
if creeping
    creepCap = getf(ctx,'CreepCap', 1.2);
    if isfinite(info.TargetSpeed_mps)
        info.TargetSpeed_mps = max(0.5, min(info.TargetSpeed_mps, creepCap));
    else
        info.TargetSpeed_mps = 0.6;
    end
end

% ---- EgoCommand -> the seat -------------------------------------------------
tv = info.TargetSpeed_mps;
if ~isfinite(tv), tv = 0; end
if holding, tv = 0; end          % D9 rung 1.5: hold position, do not inch closer

% Phase 6: real per-station S9 by default (sc.adapterS9Real). ctx.RealS9=false
% reverts to the Phase 2 fixed-conservative stand-in (sc.adapterS9) for an A/B.
if getf(ctx, 'RealS9', true)
    s9 = sc.adapterS9Real(ctx.W, ctx.s, ctx.e);
else
    s9 = sc.adapterS9(ctx.W, ctx.e);
end
sl = sih.planner.speedLimit(s9, ctx.v, ...
          vRoute_mps    = ctx.CruiseV, ...
          curvature_1pm = ctx.Kappa);
cmd.v = max(0, min(tv, sl.v_max_mps));

% ---- do not ARRIVE before you have MOVED OVER --------------------------------
% sc.lateralStep caps the lateral rate at tand(CrabDeg)*v - a car cannot slide
% sideways - so a lateral move of dE needs at least dE/tand(12) = 4.7*dE metres
% of forward travel, plus the ease-in. Committing to e=-2.50 from 14 m short and
% then accelerating to 3.5 m/s spends that 14 m before the crab can deliver
% 2.5 m, which is exactly how the 0.030 m graze happened. So while the committed
% line is not yet established, the pass is driven slowly. S1's own specification
% says a 0.95 m-clearance pass is driven at 8 km/h, which is where 2.2 m/s comes
% from; it is a disclosed constant, it only ever SLOWS the car, and it lifts the
% moment the line is reached.
if neg.Mode == "PASS" && isfinite(st.Neg.PassE) && ...
        abs(ctx.e - st.Neg.PassE) > getf(ctx,'PassEstablished_m', 0.35)
    cmd.v = min(cmd.v, getf(ctx,'PassEstablishCap_mps', 2.2));
end

% ---- Phase 7: S10 route, wired for real for the first time --------------------
% sih.planner.planTurn and escapeMemory already existed, tested, and consume S10 -
% nothing in this seat ever called either. That gap, not a missing S10 struct, was
% the actual hole: sc.s10Route below is the new real provider; both calls are new.
% OBSERVABILITY ONLY - neither changes cmd.v/cmd.e. The seat's own driving decision
% stays planContingency->followTrunk, unchanged; Phase 8 (D9 rungs 2+, option A) is
% where turn/escape awareness would start to change what the seat actually does.
s10  = sc.s10Route(ctx.W, ctx.Path, ctx.s, ctx.e, ctx.EgoYaw);
turn = sih.planner.planTurn(s10, ego, space = s9, roadWidth_m = 2*sc.s9Width(ctx.W, ctx.s));
st.EscMem = sih.planner.escapeMemory(st.EscMem, ego, s9, time_s = ctx.t);

if all(isfinite(info.LookaheadPoint))
    [~, eLA] = ctx.Path.inverse(info.LookaheadPoint);
    % frenet2global of an aggressive lateral candidate on a curved stretch can
    % overshoot far past the fan's nominal offset (seen: a "safe" trunk aiming
    % +8.7 m off the road at 46 m/s, picked precisely BECAUSE leaving the road
    % dodges all traffic). Clamp the target line to the physical carriageway +
    % the earthen shoulder on our side. This is a seat limit, not a planner edit.
    % eLo/eHi are computed once, earlier (Phase 6/8) - the SAME bounds the new
    % candidate-sanity check uses, so the two can never disagree about the edge.
    cmd.e = min(eHi, max(eLo, eLA));
else
    cmd.e = ctx.e;                      % nothing to follow - hold the line
end
if holding, cmd.e = ctx.e; end          % waiting is a HOLD, not a lateral probe

% ---- EXECUTE the committed manoeuvre, do not merely aim at the start of it ---
% MEASURED: with the commitment working (the ego moved 286.0 -> 296.5 m in 3.7 s,
% where before it never moved at all), it STILL only reached e=-0.590 of the
% e=-2.50 it had committed to, and grazed the cow by 0.030 m. The cause is here,
% not in the ladder: cmd.e is taken from the LOOK-AHEAD point, 2-6 m ahead, where
% the chosen candidate has barely begun its lateral move - so the seat commands
% "slightly over" every tick and never the line it committed to. sc.s1drive does
% the opposite and says so plainly: its COMMIT case sets cmd.e = ctx.passE
% outright. A committed manoeuvre has to be steered to, and iPickHoldLine
% re-validates that line against the fresh fan every single cycle, so this
% commands nothing the planner has not just re-endorsed.
if neg.Mode == "PASS" && isfinite(st.Neg.PassE)
    cmd.e = min(eHi, max(eLo, st.Neg.PassE));
end

% ---- HUD ------------------------------------------------------------------------
[h, hTcpa] = localBarrier(ego, tr, dMin, egoLength, ctx.Path, ctx.e);
if strlength(planFailed) > 0
    lbl = "STOPPED";
    st.Note = "planner: deliberation failed - braking (" + planFailed + ")";
elseif holding
    % ABORT is sc.hud's own label for exactly this manoeuvre, and the scripted
    % sc.s1drive's own word for it (ABORT_FOR = 6.1 s, "oncoming auto - holding").
    lbl = "ABORT";
    st.Note = negNote;
elseif wentAround
    lbl = "COMMIT";
    st.Note = negNote;
elseif creeping
    lbl = "PROBE";
    st.Note = "blocked - creeping along the safest moving path (D9 rung 1)";
elseif h < 0 && hTcpa <= getf(ctx,'EmergencyTCPA_s', 4.0)
    % EMERGENCY REQUIRES IMMINENCE, NOT JUST A NEGATIVE h. MEASURED before this
    % gate existed: h was negative on 385 of the 387 steps where it was defined
    % - 99.5% - and the label followed it, so the demo sat in EMERGENCY for
    % 21.6% of a run in which the car never came closer than +0.468 m to
    % anything. It fired with the nearest object 64 m away, because
    % h = lambda - beta answers "on present velocities would these paths ever
    % intersect", which is true of any stationary object in your lane at any
    % distance. That is a correct velocity-obstacle reading and a useless
    % alarm; an alarm that is on a fifth of the time teaches a judge to ignore
    % it. The gate is the planner's own contingency horizon (4 s), so
    % "EMERGENCY" now means what a viewer assumes it means: a conflict inside
    % the window the planner is actually planning over.
    % h ITSELF IS UNCHANGED and still logged every step exactly as AGENTS.md S4
    % defines it - this gates the WORD, never the evidence.
    lbl = "EMERGENCY";
    st.Note = string(fc.Reason);
elseif out.Blocked
    lbl = "STOPPED";
    st.Note = string(fc.Reason);
elseif tv < ctx.v - 0.4
    lbl = "PROBE";
    st.Note = string(fc.Reason);
else
    lbl = "COMMIT";
    st.Note = string(fc.Reason);
end
% ---- LABEL HYSTERESIS, display only -----------------------------------------
% MEASURED, and it is why this exists: with the imminence gate above in place
% the raw label changed 78 times in a 75 s run and 92% of its runs lasted under
% a quarter of a second - median ONE 0.05 s step. That is a strobe, not a
% readout; nobody can read it and a judge cannot be pointed at it. (The gate is
% still right: it cut EMERGENCY from 21.6% of the run to 1.2%. It exposed the
% flicker rather than caused it - the old label was only steady because h was
% negative almost always, so it sat on EMERGENCY and never moved.)
%
% ESCALATION IS INSTANT, DE-ESCALATION WAITS. A more severe label displays on
% the very step it occurs; a less severe one must wait out a minimum dwell.
% So this can only ever hold a warning on screen LONGER than the raw signal,
% never delay one - the safe direction, and it means the label cannot be
% accused of hiding anything.
% cmd.v / cmd.e are untouched by any of this: the car drives on the raw
% decision, this only governs the WORD shown.
rawLbl = lbl;                 % what this step ACTUALLY decided, before holding
sev = @(L) find([L=="COMMIT", L=="PROBE", L=="STOPPED", L=="EMERGENCY"], 1, 'last');
dwell = getf(ctx,'LabelDwell_s', 0.6);
if ~isfield(st,'LblShown') || strlength(string(st.LblShown)) == 0
    st.LblShown = lbl;  st.LblSince = ctx.t;
elseif sev(lbl) > sev(st.LblShown)
    st.LblShown = lbl;  st.LblSince = ctx.t;              % escalate at once
elseif lbl ~= st.LblShown && (ctx.t - st.LblSince) >= dwell
    st.LblShown = lbl;  st.LblSince = ctx.t;              % de-escalate, held
end
lbl = st.LblShown;
cmd.RawState = rawLbl;        % the un-held label, kept so nothing is lost

st.State  = lbl;
cmd.State = lbl;
cmd.Note  = st.Note;
cmd.PlanFailed = planFailed;

% ---- pass-through for sc.plannerView / the log (decides nothing) --------------
cmd.H          = h;
cmd.HLabel     = "planner";
cmd.Trunk      = usedTrunk.States;
cmd.Candidates = {out.Candidates.Global};
cmd.Look       = info.LookaheadPoint;
cmd.Blocked    = usedTrunk.Blocked;
cmd.Creeping   = creeping;
cmd.TrunkMode  = out.TrunkMode;

% ---- Phase 8 pass-through (decides nothing beyond the override already
% folded into out.Trunk/usedTrunk above - these are for the log/HUD only) -----
cmd.WentAround        = wentAround;
cmd.SanityOverridden  = sanityOverridden;
cmd.StuckFor_s        = stuckFor;

% ---- D9 rung 1.5 pass-through (decides nothing - see iNegotiate) ------------
cmd.Waiting        = holding;
cmd.NegPhase       = st.Neg.Phase;
cmd.NegConflictID  = st.Neg.ConflictID;
cmd.NegPassE       = st.Neg.PassE;

% ---- Phase 7 pass-through (decides nothing - see the call site above) --------
cmd.TurnType     = turn.Type;
cmd.TurnBinds    = turn.Binds;
cmd.RefugePoint  = turn.RefugePoint;
cmd.NeedsReverse = turn.NeedsReverse;
cmd.EscapeCount  = st.EscMem.Count;
cmd.HasEscape    = st.EscMem.HasEscape;
cmd.NearestEscape = st.EscMem.NearestPoint;
end

% -----------------------------------------------------------------------------
function v = getf(s, f, dflt)
if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dflt; end
end

function p = trunkProgress(trunk)
S = trunk.States;
if size(S,1) < 2, p = 0; else, p = sum(vecnorm(diff(S(:,1:2)),2,2)); end
end

function mv = iPickMovingSafe(out, minKeepSteps, curE, laneBand)
%IPICKMOVINGSAFE  Among candidates that (a) stay within laneBand of the ego's
%   current line and (b) are safe for at least minKeepSteps under every future,
%   take the one that covers the MOST ground. This is a probe forward from where
%   we are, not a swerve. Returns .k (NaN if none) and a truncated .trunk.
mv = struct('k',NaN,'trunk',[]);
term = out.TerminalPrefixSteps(:);
cand = out.Candidates;
bestProg = 0.6;  bestK = NaN;         % require > 0.6 m of real progress
for k = 1:numel(cand)
    if abs(cand(k).LateralOffset_m - curE) > laneBand, continue; end
    p = min(round(term(k)), numel(cand(k).Times));
    if p < minKeepSteps, continue; end
    S = cand(k).States(1:p,:);
    prog = sum(vecnorm(diff(S(:,1:2)),2,2));
    if prog > bestProg
        bestProg = prog;  bestK = k;
    end
end
if isnan(bestK), return; end
p = min(round(term(bestK)), numel(cand(bestK).Times));
mv.k = bestK;
mv.trunk = struct('States', cand(bestK).States(1:p,:), ...
                  'Times',  cand(bestK).Times(1:p), ...
                  'Blocked', false);
end

function tr2 = iTrackHysteresis(tr, mem, t, graceT)
%ITRACKHYSTERESIS  Phase 8, piece 3. Bridge a track that just dropped out of
%   the list for up to graceT seconds, dead-reckoning it forward from its own
%   last known position/velocity - see the call site's own header for why this
%   exists. mem is a containers.Map (TrackID -> struct('Track',...,'LastSeenT',
%   ...)), a HANDLE mutated in place here; the caller (sc.planSeat) threads it
%   via st.TrackMem only so a fresh run starts with an empty one.
%
%   A ghost's Existence decays linearly across the grace window (its last real
%   value down to a floor of 0.2), so anything reading Existence can still
%   tell a dead-reckoned ghost from a freshly confirmed track - never silently
%   indistinguishable from a real detection.
%
%   Entries older than 3*graceT are dropped from mem outright (not just from
%   this frame's ghosts) so the map does not grow for the length of the run.

for k = 1:numel(tr)
    id = double(tr(k).TrackID);
    mem(id) = struct('Track', tr(k), 'LastSeenT', t);
end

seen = containers.Map('KeyType','double','ValueType','logical');
for k = 1:numel(tr), seen(double(tr(k).TrackID)) = true; end

% The exact S1 TrackList shape (AGENTS.md section 3) - built explicitly rather
% than via tr([]) so this never depends on tr already being non-empty.
ghosts = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
                'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});
allIDs = keys(mem);
for i = 1:numel(allIDs)
    id  = allIDs{i};
    rec = mem(id);
    dt  = t - rec.LastSeenT;

    if dt > 3*graceT
        remove(mem, id);
        continue
    end
    if isKey(seen, id) || dt <= 0 || dt > graceT
        continue                 % still seen this frame, or outside the grace window
    end

    g = rec.Track;
    g.Position   = g.Position + g.Velocity*dt;
    g.Existence  = max(0.2, double(g.Existence) * (1 - dt/graceT));
    g.Age        = g.Age + uint32(round(dt*20));    % a rough age bump, cosmetic only
    ghosts(end+1) = g;                              %#ok<AGROW>
end

tr2 = [tr(:); ghosts(:)];
if ~isempty(tr2)
    [~, ord] = sort([tr2.TrackID]);
    tr2 = tr2(ord);
end
end

function tf = iSaneCandidate(c, p, eLo, eHi, maxSpeed)
%ISANECANDIDATE  Phase 8, piece 2's shared filter. A candidate is SANE if its
%   own REALIZED trajectory (c.Frenet column 4 = L, c.Global column 5 = speed
%   - generateCandidates's own frenet2global output, not the nominal ask)
%   stays on the physical corridor and never asks for an absurd speed, over
%   its own safe prefix p. The pathology this exists to catch is exactly a
%   candidate whose nominal LateralOffset_m looks reasonable but whose
%   realized path overshoots (sih26037-s1-planner-fork: "aiming -4.65 m off
%   the road, asking 49.5 m/s").
tf = true;
if p < 1, return; end
L = c.Frenet(1:p,4);
if any(L < eLo | L > eHi), tf = false; return; end
spd = c.Global(1:p,5);
if any(spd > maxSpeed), tf = false; end
end

function [trunk, overridden] = iPickSaneTrunk(out, eLo, eHi, maxSpeed)
%IPICKSANETRUNK  Phase 8, piece 2. Check the candidate findSharedTrunk
%   actually picked; if it fails iSaneCandidate, re-rank ONLY among the
%   already-generated, already-safety-checked candidates (out.Candidates,
%   out.TerminalPrefixSteps) for the longest-progress one that stays sane.
%   Never re-derives safety or generates new candidates - purely a filter on
%   top of what planContingency already computed.
trunk = out.Trunk;  overridden = false;
if isnan(trunk.CandidateIndex)
    return                       % already "no trunk" - nothing to override
end
p0 = size(trunk.States, 1);
if iSaneCandidate(out.Candidates(trunk.CandidateIndex), p0, eLo, eHi, maxSpeed)
    return                       % already sane - the common case, untouched
end

overridden = true;
term = out.TerminalPrefixSteps(:);
cand = out.Candidates;
bestProg = -Inf;  bestK = NaN;
for k = 1:numel(cand)
    p = min(round(term(k)), numel(cand(k).Times));
    if p < 1 || ~iSaneCandidate(cand(k), p, eLo, eHi, maxSpeed), continue; end
    S = cand(k).States(1:p,1:2);
    prog = 0;
    if size(S,1) >= 2, prog = sum(vecnorm(diff(S),2,2)); end
    if prog > bestProg, bestProg = prog;  bestK = k; end
end
if isnan(bestK)
    trunk = struct('CandidateIndex',NaN, 'States',zeros(0,3), 'Times',zeros(0,1), 'Blocked',true);
    return
end
p = min(round(term(bestK)), numel(cand(bestK).Times));
trunk = struct('CandidateIndex',bestK, 'States',cand(bestK).States(1:p,:), ...
               'Times',cand(bestK).Times(1:p), 'Blocked', false);
end

% iPickGoAround REMOVED 7 Sep 2026. It ranked candidates by RAW PROGRESS with no
% clearance floor, which is what committed S2-sensed to offset +1.75 at -0.29 m
% clearance while +-2.60 sat available at +0.50 m. Every caller now uses
% iPickPassLine, which applies the same max-min-clearance rule with a floor.
% Kept in the history, not in the file: an unused ranking function that disagrees
% with the one actually in force is exactly how the two drift apart again.
function [h, tcpa] = localBarrier(ego, tr, dMin, egoLength, P, egoE)
%LOCALBARRIER  min(lambda - beta) over the tracks that are AHEAD of the ego AND
%   roughly in the ego's own path, for the HUD only. Two skips:
%   - a vehicle closing from BEHIND also lowers h (h is relative geometry) but
%     braking for it is not our job (plan/PLANNER-IN-LOOP-FINDING: 46% of
%     violations came from behind), so tracks > one body-length behind are out;
%   - an oncoming vehicle two lanes over is not our barrier either, so tracks
%     more than ~2.3 m off the ego's line are out. h is meant to say "am I about
%     to hit something in front of me", not "is anyone near".
h = NaN;  tcpa = Inf;
fwd = [cos(ego.Yaw) sin(ego.Yaw)];
for k = 1:numel(tr)
    rel   = tr(k).Position(1:2) - ego.Position(1:2);
    ahead = rel(1)*fwd(1) + rel(2)*fwd(2);
    if ahead < -egoLength, continue; end
    [~, te] = P.inverse(tr(k).Position(1:2));
    if abs(te - egoE) > 2.3, continue; end
    try
        vo = sih.planner.velocityObstacle( ...
                ego.Position(1:2), ego.Velocity(1:2), ...
                tr(k).Position(1:2), tr(k).Velocity(1:2), dMin);
        hk = vo.lambda - vo.beta;
        if isnan(h) || hk < h
            h = hk;
            % The BINDING track's time to closest approach, carried out so the
            % HUD can tell "a collision is imminent" from "something is in my
            % lane a long way off". h itself is untouched - it is the contract's
            % safety evidence (AGENTS.md S4) and is still logged exactly as the
            % formula defines it.
            if isfield(vo,'tcpa'), tcpa = vo.tcpa; else, tcpa = Inf; end
        end
    catch
        % HUD only - never let it break the drive
    end
end
end

function N = iNegInit()
%INEGINIT  D9 rung 1.5's state, threaded through st.Neg exactly like st.TrackMem
%   and st.EscMem already are. Phase is the position on the ladder: "NONE"
%   (nothing in hand), "WAIT" (holding for a NAMED track), "PASS" (committed to
%   a go-around and driving it out).
N = struct('Phase',"NONE", 'ConflictID',NaN, 'WaitStartT',NaN, ...
           'CooldownUntilT',-Inf, 'PassE',NaN, 'PassStartT',NaN, ...
           'PassStartS',NaN, 'Reason',"");
end

function c = iBindingConflict(out, eLo, eHi, maxSpeed, minKeepSteps)
%IBINDINGCONFLICT  WHICH ONE ROAD USER is holding up the go-around?
%
%   Reads out.BindingFuture, which sih.planner.planContingency ALREADY computes
%   per candidate as "the index into out.Futures of the future that limited this
%   candidate". Nothing here re-derives safety, re-generates candidates or
%   computes its own collision geometry - it only counts what the planner
%   already decided.
%
%   A candidate only votes if it is a pass we would ACTUALLY be willing to
%   drive: sane over its WHOLE length, not merely over the prefix that survived.
%   Otherwise the seat could sit waiting on a vehicle that is blocking nothing
%   but a candidate the sanity filter would have thrown away anyway.
%   Candidates cut by mode "B"'s terminal-stop check rather than by a road user
%   carry BindingFuture = NaN and are skipped: there is no vehicle to wait for.
%
%   RETURNS .ID = NaN when no single road user is responsible - which is itself
%   the useful answer. At the S1 freeze it returns NaN, because a fully safe
%   22.85 m pass is available and unbound; that is the seat's signal to GO, not
%   to wait. A WAIT rung that could not say "there is nothing to wait for" would
%   just be a slower way to freeze.
c = struct('ID',NaN, 'Votes',0, 'Prog',0);
term = out.TerminalPrefixSteps(:);
bind = out.BindingFuture(:);
cand = out.Candidates;
ids = [];  progs = [];
for k = 1:numel(cand)
    full = numel(cand(k).Times);
    p    = min(round(term(k)), full);
    if p >= minKeepSteps, continue; end       % not blocked - it clears the bar
    if isnan(bind(k)),    continue; end       % cut by the stop check, not a vehicle
    if ~iSaneCandidate(cand(k), full, eLo, eHi, maxSpeed), continue; end
    S = cand(k).States(1:full,1:2);
    ids(end+1)   = double(out.Futures(bind(k)).TrackID);   %#ok<AGROW>
    progs(end+1) = sum(vecnorm(diff(S),2,2));              %#ok<AGROW>
end
if isempty(ids), return; end
u = unique(ids);
bestVotes = -1;  bestProg = -1;  bestID = NaN;
for i = 1:numel(u)
    m  = (ids == u(i));
    v  = sum(m);
    pg = max(progs(m));
    if v > bestVotes || (v == bestVotes && pg > bestProg)
        bestVotes = v;  bestProg = pg;  bestID = u(i);
    end
end
c.ID = bestID;  c.Votes = bestVotes;  c.Prog = bestProg;
end

function tf = iTrackConsidered(out, id)
%ITRACKCONSIDERED  Was this TrackID actually planned against this cycle?
%
%   THE GUARD THAT MAKES A WAIT A WAIT AND NOT A COINCIDENCE. Without it the fan
%   "opens" the moment the conflicting vehicle drops out of the sensor's list,
%   and the seat commits into a hazard it has simply stopped seeing. That is not
%   hypothetical: it is the measured mechanism behind the S1 -0.623 m collision
%   (the whole TrackList goes empty from t=44.0 and the seat accelerates through
%   a cow that is still standing there), and sih26037-phase5-sensing measured the
%   same class of failure before that. iTrackHysteresis bridges a dropout for
%   TrackGrace_s, so inside that window the track is still in out.Futures and
%   this can be satisfied honestly; past it the track is genuinely unknown, and
%   the right answer is to keep waiting until the timeout, never to guess.
tf = false;
if isnan(id) || ~isfield(out,'Futures'), return; end
for j = 1:numel(out.Futures)
    if double(out.Futures(j).TrackID) == id, tf = true; return; end
end
end

function mv = iPickHoldLine(out, targetE, band, eLo, eHi, maxSpeed, minKeepSteps, ...
                           minClear, halfW, roadHalfW, bE, bH)
%IPICKHOLDLINE  Mid-pass: re-pick the committed LINE against this cycle's fresh
%   fan. A committed manoeuvre is held as a lateral OFFSET, never as a frozen
%   trajectory - the seat has no independent barrier layer underneath it, so
%   every cycle must still be able to say no, and does: if nothing within `band`
%   of the committed line is still sane and still safe for minKeepSteps, this
%   returns .k = NaN and the caller abandons the commitment.
%
%   AND IT KEEPS REQUIRING THE CLEARANCE THE COMMITMENT WAS TAKEN ON. Measured,
%   and this was a real regression: without it S2-sensed went from -0.625 m
%   (baseline) to -1.123 m. The commit test refused a line closer than
%   MinPassClearance_m to a road user, but the HOLD test then only asked for
%   safety over minKeepSteps (1.2 s) - so on S2's tight ring, with a fast
%   oncoming rider, the seat kept driving a line it would never have committed
%   to in the first place. Applying one rule at commit and a weaker one while
%   holding is how a committed manoeuvre turns into a collision; the same rule
%   now governs both, and when it fails the line is abandoned.
%
%   Among the candidates that ARE in the band it takes the most ground covered.
%   That ranking is load-bearing, not cosmetic: every offset column in the fan
%   carries a terminal-speed-0 candidate whose progress is ~0.6 m and which is
%   trivially safe, so a "nearest offset wins" rule would re-select standing
%   still on the very next tick and re-create the freeze this rung exists to
%   break.
mv = struct('k',NaN,'trunk',[]);
term = out.TerminalPrefixSteps(:);
cand = out.Candidates;
bestProg = -Inf;  bestK = NaN;
for k = 1:numel(cand)
    if abs(cand(k).LateralOffset_m - targetE) > band, continue; end
    p = min(round(term(k)), numel(cand(k).Times));
    if p < minKeepSteps || ~iSaneCandidate(cand(k), p, eLo, eHi, maxSpeed), continue; end
    if iLineClearance(cand(k).LateralOffset_m, halfW, roadHalfW, bE, bH) < minClear
        continue
    end
    S = cand(k).States(1:p,1:2);
    prog = 0;
    if size(S,1) >= 2, prog = sum(vecnorm(diff(S),2,2)); end
    if prog > bestProg, bestProg = prog;  bestK = k; end
end
if isnan(bestK), return; end
p = min(round(term(bestK)), numel(cand(bestK).Times));
mv.k = bestK;
mv.trunk = struct('CandidateIndex',bestK, 'States',cand(bestK).States(1:p,:), ...
                  'Times',cand(bestK).Times(1:p), 'Blocked',false);
end

function cl = iLineClearance(o, halfW, roadHalfW, bE, bH)
%ILINECLEARANCE  Lateral room a line at offset `o` leaves: to the nearer
%   carriageway edge, and to every road user we have to get past. ONE definition,
%   used by both the commit test (iPickPassLine) and the hold test
%   (iPickHoldLine), so the two can never disagree about what "clear" means.
cl = roadHalfW - abs(o) - halfW;
for j = 1:numel(bE)
    if o < bE(j)
        cl = min(cl, (bE(j) - bH(j)) - (o + halfW));
    else
        cl = min(cl, (o - halfW) - (bE(j) + bH(j)));
    end
end
end

function [N, act] = iNegotiate(N, out, ctx, stuckFor, cfg, trS, trE, trHalfE)
%INEGOTIATE  D9 rung 1.5 - the WAIT rung, and the commitment that follows it.
%
%   THE LADDER
%     NONE -> PASS   stuck, and a real go-around exists right now: commit to it
%     NONE -> WAIT   stuck, none exists, and ONE named road user is why
%     WAIT -> PASS   that road user is still tracked, still planned against, and
%                    no longer binding the fan
%     WAIT -> NONE   WaitTimeout_s elapsed, plus a cooldown, so the pre-existing
%                    rung 2 resumes and the floor is never worse than before
%     PASS -> NONE   driven out, held too long, or the line stopped being safe
%
%   WHAT DECIDES "CLEARED", AND WHY IT IS NOT A HAND-ROLLED PROJECTION.
%   out.TerminalPrefixSteps already encodes "safe under BOTH of this track's
%   futures across the whole horizon" - that IS the projection, computed by the
%   frozen planner. So the commit test is simply: a real go-around exists again,
%   AND the road user we have been waiting on is still being planned against
%   (iTrackConsidered). Re-deriving a closing-speed estimate here would be a
%   second, worse answer to a question planContingency has already answered.
%
%   THE TIMEOUT IS NOT A SAFETY VALVE, IT IS THE POINT. A cow never clears. S1's
%   whole thesis is the frozen-robot failure, and a WAIT rung with no timeout is
%   a machine for producing it.
act = struct('Mode',"NONE", 'Trunk',[], 'Note',"", 'Committed',false);

% On a planContingency failure the caller's catch builds an `out` with no fan at
% all. Nothing can be decided from it; hold whatever phase we were in and let
% the ordinary blocked-trunk braking carry the cycle.
if ~isfield(out,'TerminalPrefixSteps') || ~isfield(out,'BindingFuture')
    return
end

switch N.Phase
case "PASS"
    if (ctx.s - N.PassStartS) >= cfg.PassDistance_m
        N.Phase = "NONE";  N.Reason = "pass driven out";
        return
    end
    if (ctx.t - N.PassStartT) >= cfg.PassHold_s
        N.Phase = "NONE";  N.CooldownUntilT = ctx.t + cfg.WaitCooldown_s;
        N.Reason = "pass held too long without completing";
        return
    end
    aheadH = (trS > ctx.s - 2) & (abs(trE) < cfg.HalfWidth_m + 1.0);
    hold = iPickHoldLine(out, N.PassE, cfg.PassBand_m, cfg.ELo, cfg.EHi, ...
                         cfg.MaxSpeed, cfg.PassMinSteps, cfg.MinClearance_m, ...
                         cfg.EgoWidth_m/2, cfg.HalfWidth_m, trE(aheadH), trHalfE(aheadH));
    if isnan(hold.k)
        N.Phase = "NONE";  N.CooldownUntilT = ctx.t + cfg.WaitCooldown_s;
        N.Reason = "committed line no longer safe - abandoned";
        return
    end
    act.Mode = "PASS";  act.Trunk = hold.trunk;
    act.Note = sprintf("driving out the committed go-around at e=%+.2f m (%.1f of %.1f m)", ...
                       N.PassE, ctx.s - N.PassStartS, cfg.PassDistance_m);

case "WAIT"
    waited = ctx.t - N.WaitStartT;
    g = iPickPassLine(out, ctx, cfg, trS, trE, trHalfE);
    considered = iTrackConsidered(out, N.ConflictID);
    if ~isnan(g.k) && (isnan(N.ConflictID) || considered)
        N.Phase = "PASS";  N.PassE = out.Candidates(g.k).LateralOffset_m;
        N.PassStartT = ctx.t;  N.PassStartS = ctx.s;
        act.Mode = "PASS";  act.Trunk = g.trunk;  act.Committed = true;
        act.Note = sprintf("track %d cleared after %.1f s - committing the go-around at e=%+.2f m", ...
                           N.ConflictID, waited, N.PassE);
        return
    end
    if waited >= cfg.WaitTimeout_s
        N.Phase = "NONE";  N.CooldownUntilT = ctx.t + cfg.WaitCooldown_s;
        N.Reason = sprintf("waited %.1f s for track %d and it never cleared", waited, N.ConflictID);
        return                              % the pre-existing rung 2 takes over
    end
    c = iBindingConflict(out, cfg.ELo, cfg.EHi, cfg.MaxSpeed, cfg.GoAroundMinSteps);
    if ~isnan(c.ID), N.ConflictID = c.ID; end   % name a SECOND arrival honestly
    act.Mode = "WAIT";
    if ~isnan(g.k) && ~considered
        act.Note = sprintf("holding: a gap opened but track %d is no longer tracked - not committing on a dropout (%.1f/%.1f s)", ...
                           N.ConflictID, waited, cfg.WaitTimeout_s);
    else
        act.Note = sprintf("holding for track %d to clear (%.1f/%.1f s)", ...
                           N.ConflictID, waited, cfg.WaitTimeout_s);
    end

otherwise   % NONE
    if stuckFor < cfg.StuckAfter_s || ctx.t < N.CooldownUntilT
        return
    end
    g = iPickPassLine(out, ctx, cfg, trS, trE, trHalfE);
    if ~isnan(g.k)
        N.Phase = "PASS";  N.PassE = out.Candidates(g.k).LateralOffset_m;
        N.PassStartT = ctx.t;  N.PassStartS = ctx.s;
        act.Mode = "PASS";  act.Trunk = g.trunk;  act.Committed = true;
        act.Note = sprintf("stuck %.1f s - committing to a go-around at e=%+.2f m (clearance %.2f m)", ...
                           stuckFor, N.PassE, g.clear);
        return
    end
    c = iBindingConflict(out, cfg.ELo, cfg.EHi, cfg.MaxSpeed, cfg.GoAroundMinSteps);
    N.Phase = "WAIT";  N.ConflictID = c.ID;  N.WaitStartT = ctx.t;
    act.Mode = "WAIT";
    if isnan(c.ID)
        % No ONE road user is responsible, but there is still no line worth
        % committing to - most often because the only lines with room are on the
        % far side of oncoming traffic. Holding is still the right answer; the
        % commit test below then rests on the clearance alone, since there is no
        % named track to guard on.
        act.Note = sprintf("stuck %.1f s - no pass line with acceptable clearance, holding", stuckFor);
    else
        act.Note = sprintf("stuck %.1f s - every sane pass is blocked by track %d, holding", ...
                           stuckFor, c.ID);
    end
end
end

function mv = iPickPassLine(out, ctx, cfg, trS, trE, trHalfE)
%IPICKPASSLINE  WHICH line do we commit to? Ranked by the CLEARANCE it achieves.
%
%   iPickGoAround ranks by raw progress, which is right for a one-tick override
%   and wrong for a line we are going to hold and steer to. Measured: it picks
%   the outermost candidate the fan offers (e=-2.50), which clears the cow by
%   1.94 m and the carriageway edge by 0.10 m - so the number that gets reported,
%   min(gapToCow, gapToEdge), is 0.10 m. The placeholder achieves 0.965 m EACH
%   SIDE, and it does that by passing down the middle of the free gap.
%
%   So the objective here is exactly that: MAXIMISE THE MINIMUM LATERAL
%   CLEARANCE, to the blocking road users on one side and to the carriageway
%   edges on the other. It is the same arithmetic sc.s1geom already does for the
%   scripted driver (free width 3.83 m, ego 1.90 m, margin 0.965 m each side),
%   and on S1 it lands on e=-1.585 - the scripted pass line - from first
%   principles rather than by being told:
%
%       offset   clear of the cow   clear of the edge    min
%       -0.90         0.335              1.70           0.335
%       -1.585        1.02               1.015          1.015   <- chosen
%       -2.50         1.935              0.10           0.10
%
%   THIS IS A PREFERENCE, NOT A SAFETY CHECK. Every candidate it ranks has
%   already been certified by planContingency as safe under every future of every
%   track, and by iSaneCandidate as staying on the road. Nothing here can permit
%   a candidate; it only chooses among ones already permitted. Safety is still
%   the frozen planner's answer.
%
%   MinProgress_m keeps a stand-still candidate out of the running: every offset
%   column in the fan carries a terminal-speed-0 trajectory that is trivially
%   safe and goes nowhere, and those are what the freeze is MADE of. Two vehicle
%   lengths inside the horizon is the floor for calling something a pass.
mv = struct('k',NaN, 'trunk',[], 'clear',NaN);
term = out.TerminalPrefixSteps(:);
cand = out.Candidates;
halfW = cfg.EgoWidth_m/2;

% the road users we actually have to get past: ahead of us, and on the road
ahead = (trS > ctx.s - 2) & (abs(trE) < cfg.HalfWidth_m + 1.0);
bS = trE(ahead);  bH = trHalfE(ahead);

bestClear = -Inf;  bestProg = -Inf;  bestK = NaN;
for k = 1:numel(cand)
    p = min(round(term(k)), numel(cand(k).Times));
    if p < cfg.GoAroundMinSteps, continue; end
    if ~iSaneCandidate(cand(k), p, cfg.ELo, cfg.EHi, cfg.MaxSpeed), continue; end
    S = cand(k).States(1:p,1:2);
    prog = 0;
    if size(S,1) >= 2, prog = sum(vecnorm(diff(S),2,2)); end
    if prog < cfg.MinProgress_m, continue; end

    o  = cand(k).LateralOffset_m;
    cl = iLineClearance(o, halfW, cfg.HalfWidth_m, bS, bH);
    % A FLOOR, NOT JUST A RANKING. Measured, and it was a real defect in the
    % first version of this function: at the S1 freeze it committed to
    % "e=-0.90 m (clearance -0.73 m)" - a NEGATIVE clearance, i.e. a guaranteed
    % overlap - because -0.73 was simply the largest number on offer while the
    % oncoming auto-rickshaw occupied e = [-2.37, -1.07]. It clipped the auto by
    % 0.095 m. Taking the best available is not the same as taking an acceptable
    % one, and when nothing acceptable exists the answer is to WAIT, which is
    % exactly what returning empty here makes the ladder do. Five seconds later,
    % with the auto gone, the same function finds e=-1.58 at +1.02 m.
    % 0.5 m is deliberately BELOW the placeholder's own 0.965 m margin, so this
    % floor cannot be what makes the number: it only refuses a pass that would
    % put the ego within half a metre of another road user.
    if cl < cfg.MinClearance_m, continue; end
    if cl > bestClear || (abs(cl - bestClear) < 1e-9 && prog > bestProg)
        bestClear = cl;  bestProg = prog;  bestK = k;
    end
end
if isnan(bestK), return; end
p = min(round(term(bestK)), numel(cand(bestK).Times));
mv.k = bestK;  mv.clear = bestClear;
mv.trunk = struct('CandidateIndex',bestK, 'States',cand(bestK).States(1:p,:), ...
                  'Times',cand(bestK).Times(1:p), 'Blocked',false);
end
