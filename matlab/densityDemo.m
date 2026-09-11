function densityDemo(scenario, opts)
%DENSITYDEMO  ONE command, start to end: watch a full-density scenario in
%   sc.plannerView, from station 0 to the route's own end.
%
%   densityDemo("s1")   or "s3" / "s4" / "s5"
%
%   *** THE EGO IS SCRIPTED, NOT THE REAL PLANNER. *** It drives at a
%   constant speed down the centreline. This is the 5-scenario density
%   initiative's own world + background actors (buildings, poles, signs,
%   trees, people, animals, vehicles) - it does NOT call sc.planSeat, does
%   NOT negotiate anything, and is NOT what demo_play.m runs. Connecting
%   this world to the real planner is Phase 3 of that initiative and has
%   not been built. Said here so nobody mistakes a straight drive-through
%   for a planning result.
%
%   opts.Speed  m/s, constant cruise (default 12)
%   opts.FPS    playback rate (default 20)
%
%   Same keys as every other viewer in this repo: SPACE pause/resume,
%   -> or N step one frame, Q quit.

arguments
    scenario (1,1) string = "s1"
    opts.Speed (1,1) double = 12
    opts.FPS   (1,1) double = 20
end

scenario = lower(scenario);
assert(ismember(scenario, ["s1" "s3" "s4" "s5"]), "densityDemo:badScenario", ...
    'scenario must be "s1", "s3", "s4" or "s5" - S2 is not part of this build (see AGENTS.md/HANDOFF.md: it is Antara''s live fix this week, untouched by this initiative).');

here = fileparts(mfilename('fullpath'));
addpath(here);

W = feval(sprintf('sc.%sworld', scenario));
[spec, ~] = feval(sprintf('sc.%sdensity', scenario));
fprintf('[densityDemo] %s: %.1f m route, %d density actors, scripted at %.0f m/s\n', ...
        upper(scenario), W.Path.Len, size(spec,1), opts.Speed);

sc.plannerView('init', struct('P',W.Path,'W',W, ...
    'Title', sprintf('%s - FULL DENSITY, SCRIPTED DRIVE (not the real planner)', upper(scenario)), ...
    'ViewSpan', 70, 'Interactive', true));

DT = 1/opts.FPS;
TEnd = W.Path.Len / opts.Speed;
nSteps = ceil(TEnd/DT);
cmd = struct('State',"CRUISE",'Note',"scripted constant-speed drive - not sc.planSeat", ...
    'Accel',0,'SteerAngle',0,'Mode',uint8(0),'Reason',"");

for i = 1:nSteps
    t = (i-1)*DT;
    s = min(W.Path.Len - 1, opts.Speed*t);
    [ego, hdg] = W.Path.at(s, 0);

    A = sc.activeDensityActorsAt(spec, W.Path, t);
    trk = struct('TrackID',{},'ClassID',{},'Position',{},'Velocity',{}, ...
        'Extent',{},'Yaw',{},'Existence',{},'Age',{},'SensorMask',{});
    for k = 1:numel(A)
        trk(end+1) = struct('TrackID',uint32(A(k).Row),'ClassID',uint8(A(k).ClassID), ...
            'Position',[A(k).XY 0],'Velocity',A(k).Vel,'Extent',A(k).Extent, ...
            'Yaw',A(k).YawRad,'Existence',1,'Age',uint32(1),'SensorMask',uint8(1)); %#ok<AGROW>
    end

    ctl = sc.plannerView('step', struct('t',t,'s',s,'e',0,'v',opts.Speed, ...
        'ego',ego,'yaw',hdg,'tracks',trk,'cmd',cmd));
    if ctl.Quit, break; end
end
sc.plannerView('close', struct());
fprintf('[densityDemo] done - %.0f m covered\n', s);
end
