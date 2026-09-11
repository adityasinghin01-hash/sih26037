function out = plannerView(action, d)
%PLANNERVIEW  A live, top-down MATLAB view of the planner in the seat.
%
%   THIS IS THE THING YOU WATCH INSTEAD OF A RENDERED VIDEO. Plain geometry -
%   "the plain one is the truth" (pipeline-rules). Run demo_play.m, or a
%   *_planner_run.m with VIEW=true, from a MATLAB session with a display (NOT
%   -batch, which has none) and this opens a window that follows the ego and
%   shows, every step:
%     - the road centreline and carriageway edges
%     - every hazard, drawn to type and LABELLED on screen
%     - the ego (oriented rectangle, real car L/W) and every road user, by class
%     - the fan of candidate paths (thin grey) and the committed trunk (green)
%     - the look-ahead point the steering is aimed at
%     - a numbers panel: t, s, v, target v, target e, state, h = lambda-beta
%     - a MODEL STATUS panel: the 4 perception models + the planner, live
%     - a rolling strip of v and h against t
%
%   =====================================================================
%   PERFORMANCE - MEASURED 7 SEPTEMBER 2026, NOT ASSUMED
%   =====================================================================
%   The first version of this file deleted and re-plotted every dynamic object
%   every frame, and cla'd the strip axes. Benchmarked against a faithful mimic
%   of this exact workload (1200 frames, real figure, real road polylines):
%
%       delete + replot   mean 224 ms/frame  =   4.5 fps,  65% of frames over
%                         a 50 ms budget, worst single frame 19.3 SECONDS,
%                         and +86 MB of RSS in 1200 frames (it leaks)
%       set() reuse       mean 4.6 ms/frame  = 219 fps,  0.75% over budget,
%                         NO drift over 6000 frames, NO memory growth
%
%   So the old pattern could not have held up a five-minute live demo, and this
%   file is written to the second pattern throughout:
%     * every static thing (road, hazards, labels) is drawn ONCE at init
%     * every dynamic thing is a PREALLOCATED object updated with set()
%     * the whole candidate fan is ONE line object, NaN-separated between paths
%     * every road user is ONE patch, via Faces/Vertices/FaceVertexCData
%     * the strip chart is a fixed-length shifting buffer, never cla'd
%   Nothing here may go back to delete-and-replot without re-running that
%   benchmark. It is the difference between a demo and a slideshow.
%
%   =====================================================================
%   THE HAZARD CONTRACT - FROZEN 7 SEPTEMBER 2026
%   =====================================================================
%     struct('Type',    "pothole"|"breaker"|"barrier"|"damage"|
%                       "speedsign"|"slowzone"|"sharpturn", ...
%            'Station', double, ... % m along the route
%            'Lateral', double, ... % m, POSITIVE IS LEFT
%            'Label',   string, ... % ALWAYS renders on screen, beside it
%            'Radius',  double, ... % m, optional
%            'SpeedCap',double, ... % m/s this hazard imposes, NaN = none
%            'Zone',    double)     % m of affected stretch, 0 = point hazard
%   Every field is honoured here; SpeedCap and Zone are the view's job only to
%   DRAW (the band, and the cap in the panel) - demo_play.m is what makes the
%   car obey them.
%
%   Colours are SOURCED, not invented: potholes dark/muddy and the speed
%   breaker's black-and-white bands both come straight from
%   scenarios/S1-CATTLE-CROSSING.md ("painted in black-and-white bands"); the
%   barrier's black-and-yellow is the ordinary real-world hazard-marker
%   convention, since this project's own scenarios never specify one; the
%   speed-limit and warning signs follow IRC 67 / the Vienna convention shapes
%   India actually uses (white disc + red rim; white triangle + red rim).
%
%   =====================================================================
%   USAGE
%   =====================================================================
%     sc.plannerView('init', struct('P',path,'W',world, ...
%                        'CS',cowStation, ...        % optional
%                        'Hazards',hazardStruct, ... % optional
%                        'Title',"Demo 1 - ...", ... % optional
%                        'ViewSpan',90, ...          % optional, m half-span
%                        'Interactive',true))        % optional, keys on/off
%     ctl = sc.plannerView('step', struct('t',..,'s',..,'e',..,'v',.., ...
%                        'ego',[x y],'yaw',..,'tracks',trackStruct,'cmd',cmd, ...
%                        'Models',modelStatusArray, ...  % optional
%                        'HazardNote',"...", ...        % optional
%                        'Chapter',"..."))              % optional
%     sc.plannerView('snap', struct('file','/abs/path.png'))
%     sc.plannerView('close')
%
%   'step' BLOCKS while paused, and returns a control struct:
%       .Paused  .Quit  .Frames (frames drawn)  .LastFrame_ms
%   so a runner can honour a quit without knowing anything about the keyboard.
%
%   KEYS (live, in the figure window)
%       SPACE            pause / resume   - this is how you narrate
%       RIGHT ARROW / N  advance exactly one frame while paused
%       Q / ESC          quit the run cleanly
%   There is deliberately NO slow-motion: a crawling car looks broken. The sim
%   runs at its natural speed and you stop it where you want to talk.
%
%   HEADLESS BEHAVIOUR, stated exactly as implemented. With no display
%   (`-batch`), 'init' still builds the figure Visible='off' and 'step' still
%   updates every object - because that is what 'snap' needs in order to write
%   a correct frame with exportgraphics. What headless SKIPS is the two things
%   that only make sense with a person watching: the drawnow, and the
%   pause/step/quit wait. So a headless step is cheap and never blocks.
%   (The original file's header promised 'init'/'step' would no-op entirely
%   when headless. That was inherited into this rewrite and was NOT true of
%   it - `S.headless` was computed and never read, so a `-batch` run drew
%   every playback frame at 20 Hz for nobody. Found when a `matlab -batch
%   demo_play(...)` run turned up on this machine. Note the detection: this
%   used feature('ShowFigureWindows') at first, which MEASURED TRUE under
%   -batch and so detected nothing - graphics genuinely work there, the
%   windows just never reach a person. batchStartupOptionUsed is the flag
%   that means what is wanted. demo_play now skips the playback leg outright
%   under -batch when no Snap= was asked for.)

persistent S
out = struct('Paused',false,'Quit',false,'Frames',0,'LastFrame_ms',NaN);

switch action
% --------------------------------------------------------------------- init
case 'init'
    S = struct();
    S.P = d.P;  S.W = d.W;
    S.CS = getf(d,'CS',NaN);
    % 60 m half-span = 120 m of road across the frame. Chat 3's hazards sit
    % 30-80 m apart, so two to four are in shot at once - the "wider view"
    % requirement - while a 4.7 m car is still a car and not a dot. 95 m was
    % tried and the ego was too small to read.
    S.span = getf(d,'ViewSpan',60);          % m, half-span of the follow camera
    S.interactive = getf(d,'Interactive',true);
    S.sensed = getf(d,'Sensed',false);       % demo_play's Sensed= - see the ground-truth
                                              % notice below, which reads this
    % See demo_play's own note: feature('ShowFigureWindows') is TRUE under
    % `matlab -batch` on this machine, so it cannot detect "nobody is
    % watching". batchStartupOptionUsed is true for exactly that case.
    S.headless = batchStartupOptionUsed;
    S.nFrames = 0;  S.lastMs = NaN;
    S.hz = getf(d,'Hazards',struct([]));

    try
        S.fig = figure('Name','SIH26037 - the planner in the seat','Color','w', ...
                       'Position',[40 40 1580 900],'NumberTitle','off', ...
                       'MenuBar','none','ToolBar','none');
    catch
        S.fig = figure('Name','planner in the seat','Color','w','Visible','off');
    end

    % ---- layout ---------------------------------------------------------
    S.axMap   = axes('Parent',S.fig,'Position',[0.035 0.30 0.615 0.60], ...
                     'Color',[0.985 0.985 0.982],'XColor',[.55 .55 .55],'YColor',[.55 .55 .55]);
    hold(S.axMap,'on');
    S.axStrip = axes('Parent',S.fig,'Position',[0.035 0.055 0.615 0.175], ...
                     'Color','w','XColor',[.4 .4 .4],'YColor',[.4 .4 .4]);
    hold(S.axStrip,'on');
    S.axInfo  = axes('Parent',S.fig,'Position',[0.675 0.44 0.31 0.51],'Color','w');
    hold(S.axInfo,'on');
    % HOLD FIRST, 'axis off' LAST. Found by looking at a real exported frame:
    % this panel came out as a solid BLACK BOX with 0..1 tick labels, because
    % plot() into an axes that is not held RESETS that axes - Visible, Color
    % and all - so the 'axis off' issued at construction was undone by the
    % first marker drawn into it. Holding first stops the reset; the explicit
    % white Color stops it inheriting anything; 'axis off' goes at the end of
    % init, after every child exists.
    S.axMdl   = axes('Parent',S.fig,'Position',[0.675 0.035 0.31 0.345],'Color','w');
    hold(S.axMdl,'on');
    xlim(S.axMdl,[0 1]); ylim(S.axMdl,[0 1]);
    axis(S.axMap,'equal');  grid(S.axMap,'on');
    S.axMap.GridAlpha = 0.12;
    xlabel(S.axMap,'x (m)'); ylabel(S.axMap,'y (m)');

    ttl = getf(d,'Title',"top-down - ego (blue), road users by class, candidates (grey), committed trunk (green)");
    S.hTitle = title(S.axMap, char(ttl), 'FontWeight','normal','FontSize',11,'Color',[.15 .15 .15]);

    % ---- STATIC: road ---------------------------------------------------
    C = S.P.P;  hw = S.W.Width/2;
    nrm = [-sin(S.P.Hdg), cos(S.P.Hdg)];
    Lm = C + hw.*nrm;  Rm = C - hw.*nrm;
    % the carriageway itself, so the road reads as a road and not three lines
    road = [Lm; flipud(Rm)];
    patch(S.axMap, road(:,1), road(:,2), [0.90 0.90 0.895], ...
          'EdgeColor','none','FaceAlpha',1);
    plot(S.axMap, Lm(:,1), Lm(:,2), '-',  'Color',[.35 .35 .35], 'LineWidth',1.2);
    plot(S.axMap, Rm(:,1), Rm(:,2), '-',  'Color',[.35 .35 .35], 'LineWidth',1.2);
    plot(S.axMap, C(:,1),  C(:,2),  '--', 'Color',[.98 .98 .98], 'LineWidth',1.0);

    % the cow, when a scenario has one
    if isfinite(S.CS)
        cowXY = S.P.at(S.CS, 0);
        plot(S.axMap, cowXY(1), cowXY(2), 'p', 'MarkerSize',15, ...
             'MarkerFaceColor',[.9 .5 .1],'MarkerEdgeColor','k');
    end

    % ---- STATIC: every hazard, drawn once, LABELLED ----------------------
    nBefore = numel(S.axMap.Children);
    for k = 1:numel(S.hz)
        drawHazard(S.axMap, S.P, S.hz(k), k);
    end
    % One sweep, rather than an easily-forgotten 'Clipping' on each of the
    % dozen patch/plot/text calls inside drawHazard.
    kids = S.axMap.Children;
    for k = 1:(numel(kids) - nBefore)
        try set(kids(k), 'Clipping', 'on'); catch, end %#ok<CTCH>
    end

    % ---- STATIC: world furniture, drawn once, from S.W's OWN fields -------
    % Added 11 Sep 2026 for the 5-scenario density initiative. Every field is
    % OPTIONAL: a scenario's world struct (sc.s1world and its future
    % siblings) may or may not carry Buildings/Poles/Drains/SideRoads, and
    % this draws whichever are present and silently skips the rest - the same
    % "absent field, no error" discipline the hazard/track fields already
    % have. plannerView does not know or care which scenario S.W came from.
    drawWorldFurniture(S.axMap, S.P, S.W);

    % ---- DYNAMIC: preallocated, updated with set(), never deleted --------
    % the whole candidate fan in ONE line object, NaN-separated
    S.hCand  = plot(S.axMap, NaN, NaN, '-', 'Color',[.72 .72 .78], 'LineWidth',0.5);
    % TONED DOWN, per the 6 Sep requirement: was 2.5 pt at [0 .6 .2] and it
    % dominated the frame. Kept - it is the whole point - just quieter.
    S.hTrunk = plot(S.axMap, NaN, NaN, '-', 'Color',[.36 .74 .46], 'LineWidth',1.4);
    S.hLook  = plot(S.axMap, NaN, NaN, 'o', 'MarkerSize',6, ...
                    'MarkerEdgeColor',[.30 .62 .38],'LineWidth',1.2);
    % every road user in ONE patch (Faces/Vertices/flat CData)
    % ROAD USERS ARE OUTLINED HEAVILY AND DRAWN OPAQUE, deliberately. A cow is
    % 2.05 x 0.55 m; in a 120 m-wide view that is a couple of dozen pixels of
    % mid-brown, and at the climax of demo1 she sits 2.05 m from the pothole at
    % 302 m - a dark disc with a bright orange rim that pulls the eye straight
    % off her. The thing the car is negotiating must never be the hardest thing
    % on the map to find, so the outline is 1.6 not 0.6 and the fill is solid.
    S.hTrk   = patch(S.axMap,'Faces',zeros(0,4),'Vertices',zeros(0,2), ...
                     'FaceVertexCData',zeros(0,3),'FaceColor','flat', ...
                     'EdgeColor',[.05 .05 .05],'FaceAlpha',1.0,'LineWidth',1.6);
    S.hEgo   = patch(S.axMap, nan(1,4), nan(1,4), [.10 .32 .90], ...
                     'EdgeColor',[.05 .1 .3],'LineWidth',1.2);
    S.hHead  = plot(S.axMap, NaN, NaN, '-', 'Color',[.05 .1 .3], 'LineWidth',1.4);

    % ---- DYNAMIC: strip, fixed shifting buffers, never cla'd -------------
    S.NB = 600;                              % 30 s of history at 20 Hz
    S.tB = nan(1,S.NB); S.vB = nan(1,S.NB); S.hB = nan(1,S.NB); S.capB = nan(1,S.NB);
    yyaxis(S.axStrip,'left');
    S.hV   = plot(S.axStrip, S.tB, S.vB,   '-', 'Color',[.10 .32 .90], 'LineWidth',1.3);
    S.hCap = plot(S.axStrip, S.tB, S.capB, '-', 'Color',[.85 .45 .05], 'LineWidth',1.0);
    ylabel(S.axStrip,'v (m/s)'); S.axStrip.YAxis(1).Color = [.10 .32 .90];
    % A FIXED 0-16 m/s axis. Left to autoscale, a stretch of CONSTANT speed
    % collapses the range to nothing and the trace pins itself to the top of
    % an axis labelled 3.5 .. 5 - which is what a held speed cap looks like,
    % and it is exactly the moment you most want to see the line sitting flat
    % on its cap. 16 m/s covers the 52 km/h route cruise with headroom.
    ylim(S.axStrip, [0 16]);  S.axStrip.YLimMode = 'manual';
    yyaxis(S.axStrip,'right');
    S.hH   = plot(S.axStrip, S.tB, S.hB, '-', 'Color',[.85 .20 .20], 'LineWidth',1.0);
    yline(S.axStrip, 0, ':', 'Color',[.4 .4 .4]);
    ylabel(S.axStrip,'h = \lambda-\beta'); S.axStrip.YAxis(2).Color = [.85 .20 .20];
    xlabel(S.axStrip,'t (s)');
    legend(S.axStrip, [S.hV S.hCap], {'v actual','v cap'}, 'Location','northwest', ...
           'Box','off','FontSize',8, 'AutoUpdate','off');

    % ---- numbers panel ---------------------------------------------------
    S.txt = text(S.axInfo, 0, 1, '', 'VerticalAlignment','top', ...
                 'FontName','Menlo','FontSize',10.5,'Color',[.1 .1 .1],'Interpreter','none');

    % ---- MODEL STATUS panel ---------------------------------------------
    % 4 model rows + a planner row. Chat 2 delivers sc.modelStatus returning
    % struct('Model',string,'Status',string,'Detail',string) arrays; until it
    % lands this shows an honestly-labelled stub. It is NEVER faked as real
    % model output - a stub says stub.
    S.hasModelStatus = ~isempty(which('sc.modelStatus'));
    % sc.modelStatus does a nearest-analysed-frame lookup and the panel's text
    % goes through textwrap; both are cheap ONCE and not cheap 20 times a
    % second. They are recomputed only when the ego has actually moved a metre
    % or the text has actually changed - a model line does not become stale
    % inside one metre of road, and a string that has not changed does not need
    % re-wrapping to say the same thing.
    S.mdlS = -inf;  S.mdlCache = [];
    S.wrapKey = "";  S.wrapVal = '';
    S.wrapKey2 = ""; S.wrapVal2 = '';
    text(S.axMdl, 0.0, 0.995, 'MODEL STATUS', 'VerticalAlignment','top', ...
         'FontName','Menlo','FontSize',10,'FontWeight','bold','Color',[.25 .25 .25]);
    % WHAT THE CAR IS ACTUALLY GIVEN, SAID ON SCREEN RATHER THAN ON REQUEST.
    % demo_play hands the planner ground-truth poses: no sensor noise, no
    % dropout, no bearing blind spot. The model rows below already say
    % perception is not driving this run, but nothing said the ROAD USERS are
    % handed over exactly rather than detected - and an audience that is not
    % told will reasonably assume the car saw the cow. That would be a false
    % impression the demo created, which is not the same as a claim anyone
    % made, and is just as much this project's problem. It is stated flatly
    % and NOT softened: anything hedged enough to be read as sensing defeats
    % the point of writing it. The second line is what lets the answer to
    % "so it cannot see?" be a real one - the perception work exists and is
    % tested, it is simply not in this loop.
    % Sensed=true (demo_play) swaps this notice: the road users are now run
    % through sc.senseRig/senseStep - simulated lidar/radar/near-field-ring and
    % a real trackerGNN - not handed over exactly. Said just as flatly as the
    % ground-truth line above: real noise, real missed detections and the real
    % bearing blind spot now apply, on purpose, and are not hidden either.
    if S.sensed
        gtMsg = 'ROAD USERS: SENSED, NOT GROUND TRUTH\nlidar+radar+ring -> trackerGNN -\nreal noise, dropout, blind spot apply';
        gtColor = [.10 .30 .50];
    else
        gtMsg = 'ROAD USERS: GROUND TRUTH, NOT DETECTED\nperception is real and tested separately -\nit is not in this loop';
        gtColor = [.62 .32 .05];
    end
    text(S.axMdl, 0.0, 0.905, sprintf(gtMsg), ...
         'VerticalAlignment','top', 'FontName','Menlo','FontSize',8.5, ...
         'Color',gtColor, 'Interpreter','none');
    S.NM = 6;                                  % 4 models + planner + slack
    S.mdlDot  = gobjects(1,S.NM);
    S.mdlName = gobjects(1,S.NM);
    S.mdlStat = gobjects(1,S.NM);
    S.mdlDet  = gobjects(1,S.NM);
    y0 = 0.735;  dy = 0.142;      % lowered to clear the ground-truth notice above
    for k = 1:S.NM
        yk = y0 - (k-1)*dy;
        S.mdlDot(k)  = plot(S.axMdl, 0.022, yk, 'o', 'MarkerSize',9, ...
                            'MarkerFaceColor',[.7 .7 .7],'MarkerEdgeColor',[.3 .3 .3]);
        S.mdlName(k) = text(S.axMdl, 0.065, yk, '', 'VerticalAlignment','middle', ...
                            'FontName','Menlo','FontSize',10,'FontWeight','bold','Interpreter','none');
        S.mdlStat(k) = text(S.axMdl, 0.065, yk-0.045, '', 'VerticalAlignment','middle', ...
                            'FontName','Menlo','FontSize',9.5,'Color',[.35 .35 .35],'Interpreter','none');
        S.mdlDet(k)  = text(S.axMdl, 0.065, yk-0.086, '', 'VerticalAlignment','middle', ...
                            'FontName','Menlo','FontSize',9,'Color',[.5 .5 .5],'Interpreter','none');
    end

    axis(S.axInfo,'off');  axis(S.axMdl,'off');    % see the note at axMdl above

    % ---- keyboard control ------------------------------------------------
    % State lives in the FIGURE's appdata, not in this persistent struct: the
    % KeyPressFcn callback fires from MATLAB's event loop, where it cannot see
    % or safely mutate a persistent in a function that is mid-call.
    setappdata(S.fig, 'ctl', struct('Paused',false,'StepOnce',false,'Quit',false));
    if S.interactive
        set(S.fig, 'KeyPressFcn', @onKey, 'CloseRequestFcn', @onClose);
    end
    S.hHint = annotation(S.fig, 'textbox', [0.035 0.955 0.615 0.04], ...
        'String', 'SPACE pause/resume     ->  or  N   step one frame     Q quit', ...
        'FontName','Menlo','FontSize',10,'Color',[.35 .35 .35], ...
        'EdgeColor','none','VerticalAlignment','middle');
    S.hBanner = annotation(S.fig, 'textbox', [0.30 0.60 0.30 0.08], ...
        'String','PAUSED','FontName','Menlo','FontSize',26,'FontWeight','bold', ...
        'Color',[.85 .25 .1],'BackgroundColor',[1 1 1],'FaceAlpha',0.82, ...
        'EdgeColor',[.85 .25 .1],'LineWidth',1.5, ...
        'HorizontalAlignment','center','VerticalAlignment','middle','Visible','off');

    out.Paused = false;

% --------------------------------------------------------------------- step
case 'step'
    if isempty(S), return; end
    if ~isfield(S,'fig') || ~isgraphics(S.fig), out.Quit = true; S = []; return; end
    tFrame = tic;
    cmd = d.cmd;

    % ---- candidate fan: ONE set() on ONE line ---------------------------
    % demo_play flattens the ~35 candidates into one NaN-separated polyline at
    % cache time, so the common path here is two set()s and no loop at all.
    % The loop below is the LIVE path (a runner handing over a raw cmd) - kept
    % because s1_planner_run.m VIEW=true still goes that way.
    if isfield(cmd,'CandX')
        set(S.hCand, 'XData', cmd.CandX, 'YData', cmd.CandY);
    elseif isfield(cmd,'Candidates') && ~isempty(cmd.Candidates)
        nC = numel(cmd.Candidates);
        cx = cell(1,nC); cy = cell(1,nC);
        for k = 1:nC
            g = cmd.Candidates{k};
            if isempty(g), cx{k} = NaN; cy{k} = NaN; continue; end
            cx{k} = [g(:,1); NaN];  cy{k} = [g(:,2); NaN];
        end
        set(S.hCand, 'XData', vertcat(cx{:}), 'YData', vertcat(cy{:}));
    else
        set(S.hCand, 'XData', NaN, 'YData', NaN);
    end

    % ---- committed trunk -------------------------------------------------
    if isfield(cmd,'Trunk') && ~isempty(cmd.Trunk)
        set(S.hTrunk, 'XData', cmd.Trunk(:,1), 'YData', cmd.Trunk(:,2));
    else
        set(S.hTrunk, 'XData', NaN, 'YData', NaN);
    end
    if isfield(cmd,'Look') && all(isfinite(cmd.Look))
        set(S.hLook, 'XData', cmd.Look(1), 'YData', cmd.Look(2));
    else
        set(S.hLook, 'XData', NaN, 'YData', NaN);
    end

    % ---- road users: ONE patch, Faces/Vertices/flat CData ---------------
    nT = numel(d.tracks);
    if nT > 0
        V = zeros(4*nT, 2);  F = zeros(nT, 4);  Cd = zeros(nT, 3);
        for k = 1:nT
            tk = d.tracks(k);
            V(4*k-3:4*k, :) = boxCorners(tk.Position(1:2), tk.Yaw, tk.Extent(1), tk.Extent(2));
            F(k, :) = (4*k-3):(4*k);
            Cd(k, :) = classColour(tk.ClassID);
        end
        set(S.hTrk, 'Faces',F, 'Vertices',V, 'FaceVertexCData',Cd);
    else
        set(S.hTrk, 'Faces',zeros(0,4), 'Vertices',zeros(0,2), 'FaceVertexCData',zeros(0,3));
    end

    % ---- ego -------------------------------------------------------------
    ec = boxCorners(d.ego, d.yaw, 4.7, 1.9);
    set(S.hEgo, 'XData', ec(:,1), 'YData', ec(:,2));
    hv = d.ego(:).' + [cos(d.yaw) sin(d.yaw)]*3.4;
    set(S.hHead, 'XData',[d.ego(1) hv(1)], 'YData',[d.ego(2) hv(2)]);

    % ---- follow camera, WIDE: several hazards in frame at once ----------
    c = d.ego(:).' + [cos(d.yaw) sin(d.yaw)]*(0.35*S.span);
    set(S.axMap, 'XLim', c(1) + [-S.span S.span], ...
                 'YLim', c(2) + [-S.span S.span]);

    % ---- strip: shift the buffers, never cla ----------------------------
    h = NaN; if isfield(cmd,'H'), h = cmd.H; end
    cap = NaN; if isfield(cmd,'VCap'), cap = cmd.VCap; end
    S.tB = [S.tB(2:end) d.t];  S.vB = [S.vB(2:end) d.v];
    S.hB = [S.hB(2:end) h];    S.capB = [S.capB(2:end) cap];
    set(S.hV,  'XData',S.tB,'YData',S.vB);
    set(S.hCap,'XData',S.tB,'YData',S.capB);
    set(S.hH,  'XData',S.tB,'YData',S.hB);
    set(S.axStrip, 'XLim', [max(0, d.t-28) d.t+1.5]);

    % ---- numbers ---------------------------------------------------------
    blk = ''; if isfield(cmd,'Blocked') && cmd.Blocked, blk = '  [BLOCKED]'; end
    tm  = ''; if isfield(cmd,'TrunkMode'), tm = char(cmd.TrunkMode); end
    cowLine = '';
    if isfinite(S.CS), cowLine = sprintf('   (cow %5.1f)', S.CS); end
    hzLine = getf(d,'HazardNote',"");
    chap   = getf(d,'Chapter',"");
    capTxt = '-';
    if isfinite(cap), capTxt = sprintf('%6.2f m/s', cap); end
    % WHERE is the short head of the label - the same clause the map shows, so
    % the eye can match panel to picture. HAZARD carries the full sentence.
    % They used to print the same paragraph twice, which cost six lines and
    % said nothing extra.
    if string(chap) ~= S.wrapKey
        S.wrapKey = string(chap);
        S.wrapVal = wrapNote(char(labelHead(chap, 32)), 34, 2);
    end
    chapW = S.wrapVal;
    if string(hzLine) ~= S.wrapKey2
        S.wrapKey2 = string(hzLine);  S.wrapVal2 = wrapNote(char(hzLine), 34, 5);
    end
    hzW = S.wrapVal2;
    set(S.txt,'String',sprintf([ ...
        'WHERE\n%s\n\n' ...
        'STATE   %s%s\n\n' ...
        't        %6.2f s\n' ...
        's        %6.1f m%s\n' ...
        'v        %6.2f m/s  (%4.1f km/h)\n' ...
        'target v %6.2f m/s\n' ...
        'target e %+6.2f m\n' ...
        'v cap    %s\n' ...
        'h        %+6.3f     (%s)\n' ...
        'trunkMode %s\n' ...
        'road users %d\n' ...
        'candidates %d\n\n' ...
        'HAZARD\n%s\n\n' ...
        'WHY\n%s'], ...
        chapW, char(cmd.State), blk, d.t, d.s, cowLine, d.v, 3.6*d.v, ...
        getf(cmd,'v',NaN), getf(cmd,'e',NaN), capTxt, h, hlabel(cmd), tm, ...
        numel(d.tracks), numCand(cmd), hzW, wrapNote(noteOf(cmd),34,3)));

    % ---- model status panel ---------------------------------------------
    M = getf(d,'Models',[]);
    if isempty(M) && ~isempty(S.mdlCache) && abs(d.s - S.mdlS) < 1.0
        M = S.mdlCache;                       % same metre of road, same answer
    end
    if isempty(M)
        if S.hasModelStatus
            try
                % Chat 2's sc.modelStatus is keyed to the ego's STATION, not to
                % this frame's struct - it looks up the nearest frame the
                % offline detectors were actually run on. Passing d here throws.
                M = sc.modelStatus(d.s);
            catch me
                M = stubModels(sprintf('sc.modelStatus errored: %s', me.message));
            end
        else
            M = stubModels('');
        end
    end
    S.mdlCache = M;  S.mdlS = d.s;
    M = [M(:).', plannerRow(cmd, d)];
    for k = 1:S.NM
        % Guard every handle. A demo must not die on stage because one panel
        % object went stale - and one WILL, whenever this file is edited while
        % a run is live: MATLAB reloads the function and clears its persistent
        % S, leaving handles from an init that no longer exists. That is how
        % this was found (mid-run edit, "Invalid or deleted object" at the
        % model panel), and the guard is worth keeping regardless of cause.
        if ~isgraphics(S.mdlDot(k)), continue; end
        if k <= numel(M)
            set(S.mdlDot(k),  'XData',0.022, ...
                              'MarkerFaceColor', statusColour(M(k).Status));
            set(S.mdlName(k), 'String', char(M(k).Model));
            set(S.mdlStat(k), 'String', char(clampStr(M(k).Status, 34)));
            % 46 chars is what fits this panel at 9 pt - measured off a real
            % exported frame, where Model 3's "[placeholder - see
            % modelStatus.m header]" ran off the right-hand edge of the figure.
            %
            % IT WRAPS RATHER THAN TRUNCATES, and the difference matters. These
            % Details carry the honest caveats - "(close-up cow photo, not a
            % road view)" is exactly what stops Model 4's 1% reading at the cow
            % looking like a malfunction - and truncation was cutting them at
            % the point the explanation began, leaving "1% drivable (close-up
            % cow photo, not a road..." on screen. A caveat that is cut off
            % mid-clause is worse than no caveat: it advertises that something
            % is being explained and then withholds it.
            set(S.mdlDet(k),  'String', wrapStr(M(k).Detail, 46, 2));
        else
            set(S.mdlName(k),'String',''); set(S.mdlStat(k),'String','');
            set(S.mdlDet(k),'String','');  set(S.mdlDot(k),'XData',NaN);
        end
    end

    if ~S.headless
        drawnow('limitrate');
    end
    S.nFrames = S.nFrames + 1;
    S.lastMs  = toc(tFrame)*1000;
    if S.headless
        % No display means no keyboard, so there is nobody to un-pause it.
        % Blocking here would hang a -batch run forever.
        out.Frames = S.nFrames;  out.LastFrame_ms = S.lastMs;
        return
    end

    % ---- PAUSE / STEP / QUIT --------------------------------------------
    % Blocking here, rather than in every runner, is deliberate: pause works
    % for demo_play.m and for s1_planner_run.m VIEW=true alike, and no runner
    % has to know a key was pressed.
    % THE ORDER HERE MATTERS AND WAS GOT WRONG ONCE. The frame is ALREADY
    % drawn by the time we reach this point, so arriving with StepOnce set
    % means "that was the frame you asked for": consume it and stay paused.
    % A first version cleared the flag BEFORE the wait loop, so the loop then
    % saw Paused && ~StepOnce and blocked forever - N deadlocked the demo.
    % Found by driving the real control path in a test, not by reading it.
    ctl = getappdata(S.fig, 'ctl');
    if ctl.StepOnce
        ctl.StepOnce = false;  ctl.Paused = true;
        setappdata(S.fig, 'ctl', ctl);
    else
        while ctl.Paused && ~ctl.Quit
            set(S.hBanner,'Visible','on');
            drawnow;                   % full drawnow: limitrate can drop the
            pause(0.03);               % banner and swallow the keypress
            if ~isgraphics(S.fig), out.Quit = true; S = []; return; end
            ctl = getappdata(S.fig, 'ctl');
            if ctl.StepOnce            % released by a key press mid-wait: let
                break                  % the runner draw exactly one more frame
            end
        end
    end
    set(S.hBanner,'Visible', onoff(ctl.Paused));

    out.Paused = ctl.Paused;  out.Quit = ctl.Quit;
    out.Frames = S.nFrames;  out.LastFrame_ms = S.lastMs;

% --------------------------------------------------------------------- snap
case 'snap'
    if isempty(S) || ~isgraphics(S.fig), return; end
    try
        exportgraphics(S.fig, d.file, 'Resolution', 120);
    catch me
        warning('plannerView:snap','could not write %s: %s', d.file, me.message);
    end

% --------------------------------------------------------------------- close
case 'close'
    % delete + drawnow, not just close, so the figure's graphics resources are
    % actually reclaimed before the next scenario builds its own. (This was
    % added believing it fixed a second-scenario slowdown; a later run showed
    % the slow scenario can be the FIRST one, so the real variable is machine
    % load, not ordering - see demo_play's header. Releasing the figure
    % promptly is still the right thing to do.)
    if ~isempty(S) && isfield(S,'fig') && isgraphics(S.fig)
        set(S.fig,'CloseRequestFcn','closereq','KeyPressFcn',[]);
        delete(S.fig);
    end
    S = [];
    drawnow;
end
end

% =========================================================================
%                              KEYBOARD
% =========================================================================
function onKey(fig, ev)
ctl = getappdata(fig, 'ctl');
switch lower(ev.Key)
    case 'space'
        ctl.Paused = ~ctl.Paused;
    case {'rightarrow','n'}
        ctl.Paused = true;  ctl.StepOnce = true;
    case {'q','escape'}
        ctl.Quit = true;  ctl.Paused = false;
end
setappdata(fig, 'ctl', ctl);
end

function onClose(fig, ~)
% Closing the window is a quit, not a crash. The runner sees Quit on its next
% step and stops cleanly; the figure goes now so the click feels responsive.
ctl = getappdata(fig, 'ctl');  ctl.Quit = true;  ctl.Paused = false;
setappdata(fig, 'ctl', ctl);
delete(fig);
end

% =========================================================================
%                              HAZARDS
% =========================================================================
function drawWorldFurniture(ax, P, W)
%DRAWWORLDFURNITURE  The static world layer beyond the road itself -
%   buildings, pole/wire runs, drains, and any side roads the world struct
%   carries. Every field is OPTIONAL and this function does not judge
%   whether the counts/positions are real or chosen - that disclosure lives
%   in whichever sc.<scenario>world.m built the struct, per this project's
%   "real vs chosen, said plainly" rule. This just draws what it is given.
%
%   Deliberately NOT one label per object, unlike drawHazard. A hazard is
%   sparse (a handful per scenario) and the planner-relevant point of each
%   one is unique, so every one earns a caption. A building count runs to
%   dozens-to-hundreds (S2 alone is 96) and most of them are visually
%   interchangeable brick houses - labelling all of them would bury the
%   map in text boxes nobody can read. So buildings are colour-coded by
%   Type (a legend, not per-object text) and only the ones carrying a
%   non-empty .Label (a shop, a shrine, a named landmark) get an on-map
%   caption, the same visual weight a hazard label gets.

% ---- buildings ------------------------------------------------------
if isfield(W,'Buildings') && ~isempty(W.Buildings)
    B = W.Buildings;
    nB = numel(B);
    V = zeros(4*nB,2);  F = zeros(nB,4);  Cd = zeros(nB,3);
    for k = 1:nB
        b = B(k);
        [alongDir, acrossDir] = frame(P, b.Station);
        c = P.at(b.Station, b.Lateral);
        d_ = fieldOr(b,'Depth', 6.0);
        w_ = fieldOr(b,'Width', 6.0);
        corners = c + alongDir.*[-d_/2 d_/2 d_/2 -d_/2]' + acrossDir.*[-w_/2 -w_/2 w_/2 w_/2]';
        V(4*k-3:4*k,:) = corners;
        F(k,:) = (4*k-3):(4*k);
        Cd(k,:) = buildingColour(fieldOr(b,'Type',"house"));
    end
    patch(ax, 'Faces',F, 'Vertices',V, 'FaceVertexCData',Cd, 'FaceColor','flat', ...
          'EdgeColor',[.35 .32 .28], 'LineWidth',0.6, 'FaceAlpha',0.92, 'Clipping','on');
    for k = 1:nB
        b = B(k);
        lbl = string(fieldOr(b,'Label',""));
        if strlength(lbl) == 0, continue; end
        c = P.at(b.Station, b.Lateral);
        text(ax, c(1), c(2), char(labelHead(lbl,26)), ...
             'HorizontalAlignment','center','VerticalAlignment','middle', ...
             'FontName','Helvetica','FontSize',8,'FontWeight','bold','Color',[.15 .12 .05], ...
             'BackgroundColor',[1 1 .92],'EdgeColor',[.6 .5 .3],'Margin',1.5, ...
             'Interpreter','none','Clipping','on');
    end

    % ---- rooftop detail: water tanks, dishes, balconies, rebar ---------
    % Added 11 Sep 2026, Phase D of the density-initiative fix pass. THE ONLY facade
    % elements a straight-down 2D view can honestly show - a window or a door is on a
    % VERTICAL wall and has no plan-view signature at all, so this deliberately does not
    % try to fake one. A water tank and a dish sit ON the roof (visible from above); a
    % balcony genuinely projects past the wall line (a real plan-view footprint change);
    % rebar tied off at a roof corner reads as a small mark at that corner. Every field
    % below is OPTIONAL (fieldOr default false/0) so a building with none of them (most
    % of S4/S5's, which carry no per-building spec detail to honour) draws exactly as
    % before this pass - purely additive.
    for k = 1:nB
        b = B(k);
        [alongDir, acrossDir] = frame(P, b.Station);
        c = P.at(b.Station, b.Lateral);
        w_ = fieldOr(b,'Width',6.0);  d_ = fieldOr(b,'Depth',6.0);
        side = sign(b.Lateral); if side == 0, side = 1; end
        if fieldOr(b,'Tank',false)
            tp = c + alongDir*(d_*0.28) - acrossDir*side*(w_*0.28);
            patch(ax, tp(1)+0.5*[-1 1 1 -1], tp(2)+0.5*[-1 -1 1 1], [.10 .10 .12], ...
                  'EdgeColor',[.05 .05 .05], 'LineWidth',0.5, 'Clipping','on');
        end
        if fieldOr(b,'Dish',false)
            dp = c - alongDir*(d_*0.30) - acrossDir*side*(w_*0.20);
            th = linspace(0,2*pi,14);
            patch(ax, dp(1)+0.35*cos(th), dp(2)+0.35*sin(th), [.75 .75 .78], ...
                  'EdgeColor',[.4 .4 .4], 'LineWidth',0.4, 'Clipping','on');
        end
        if fieldOr(b,'Balcony',false)
            % projects PAST the road-facing wall - a real footprint change, drawn as a
            % thin extra rectangle beyond the building's own near edge.
            bp0 = c - acrossDir*side*(w_/2);
            bp1 = bp0 - acrossDir*side*0.9;
            corners = [bp0 + alongDir*d_*0.25; bp1 + alongDir*d_*0.25; ...
                       bp1 - alongDir*d_*0.25; bp0 - alongDir*d_*0.25];
            patch(ax, corners(:,1), corners(:,2), [.68 .66 .60], ...
                  'EdgeColor',[.4 .38 .32], 'LineWidth',0.4, 'Clipping','on');
        end
        if fieldOr(b,'Rebar',false)
            rp = c + alongDir*(d_*0.35) + acrossDir*side*(w_*0.35);
            plot(ax, rp(1)+[-.3 .3], rp(2)+[-.3 .3], '-', 'Color',[.55 .25 .15], ...
                 'LineWidth',1.2, 'Clipping','on');
            plot(ax, rp(1)+[-.3 .3], rp(2)+[.3 -.3], '-', 'Color',[.55 .25 .15], ...
                 'LineWidth',1.2, 'Clipping','on');
        end
    end
end

% ---- pole/wire runs ---------------------------------------------------
if isfield(W,'Poles') && ~isempty(W.Poles)
    Pl = W.Poles;
    runs = unique([Pl.Run]);
    for r = runs
        idxR = find([Pl.Run] == r);
        [~, ord] = sort([Pl(idxR).Station]);
        idxR = idxR(ord);
        xy = zeros(numel(idxR),2);
        for i = 1:numel(idxR)
            xy(i,:) = P.at(Pl(idxR(i)).Station, Pl(idxR(i)).Lateral);
        end
        plot(ax, xy(:,1), xy(:,2), '-', 'Color',[.45 .40 .35], 'LineWidth',0.7, 'Clipping','on');
        plot(ax, xy(:,1), xy(:,2), 'o', 'MarkerSize',3, 'MarkerFaceColor',[.3 .27 .22], ...
             'MarkerEdgeColor','none', 'Clipping','on');
    end
    if isfield(Pl,'Label') && strlength(string(Pl(1).Label)) > 0
        c0 = P.at(Pl(1).Station, Pl(1).Lateral);
        text(ax, c0(1), c0(2)+3.0, char(labelHead(string(Pl(1).Label),26)), ...
             'FontName','Helvetica','FontSize',7.5,'Color',[.35 .3 .25], ...
             'BackgroundColor',[1 1 1],'Margin',1.0,'Interpreter','none','Clipping','on');
    end
end

% ---- drains -------------------------------------------------------------
if isfield(W,'Drains') && ~isempty(W.Drains)
    for k = 1:numel(W.Drains)
        dr = W.Drains(k);
        ns = max(2, ceil((dr.S1 - dr.S0)/4));
        ss = linspace(dr.S0, dr.S1, ns);
        wd = fieldOr(dr,'Width', 0.4);
        LL = zeros(ns,2); RR = zeros(ns,2);
        for i = 1:ns
            LL(i,:) = P.at(ss(i), dr.Lateral + wd/2);
            RR(i,:) = P.at(ss(i), dr.Lateral - wd/2);
        end
        band = [LL; flipud(RR)];
        patch(ax, band(:,1), band(:,2), [.32 .30 .22], 'EdgeColor','none', ...
              'FaceAlpha',0.75, 'Clipping','on');
        lbl = string(fieldOr(dr,'Label',""));
        if strlength(lbl) > 0
            mid = P.at((dr.S0+dr.S1)/2, dr.Lateral);
            text(ax, mid(1), mid(2), char(labelHead(lbl,26)), ...
                 'FontName','Helvetica','FontSize',7.5,'Color',[.25 .22 .16], ...
                 'BackgroundColor',[1 1 1],'Margin',1.0,'Interpreter','none','Clipping','on');
        end
    end
end

% ---- side roads (context only - not drivable by the ego) ---------------
if isfield(W,'SideRoads') && ~isempty(W.SideRoads)
    for k = 1:numel(W.SideRoads)
        sr = W.SideRoads(k);
        plot(ax, sr.XY(:,1), sr.XY(:,2), '-', 'Color',[.7 .7 .68], 'LineWidth',3.0, ...
             'Clipping','on');
        lbl = string(fieldOr(sr,'Name',""));
        if strlength(lbl) > 0
            text(ax, sr.XY(end,1), sr.XY(end,2), char(labelHead(lbl,26)), ...
                 'FontName','Helvetica','FontSize',8,'Color',[.3 .3 .3], ...
                 'BackgroundColor',[1 1 1],'Margin',1.0,'Interpreter','none','Clipping','on');
        end
    end
end

% ---- service drops (a short stub from a building to its wire run) -------
% Added with sc.s3world's own W.ServiceDrops (Phase C, 11 Sep 2026 fix pass) - each entry
% is a single point in (Station, Lateral0->Lateral1), not a run along the path, so it is
% drawn directly rather than through sc.path.at() at two different stations.
if isfield(W,'ServiceDrops') && ~isempty(W.ServiceDrops)
    for k = 1:numel(W.ServiceDrops)
        d = W.ServiceDrops(k);
        p0 = P.at(d.S0, d.Lateral0);  p1 = P.at(d.S1, d.Lateral1);
        plot(ax, [p0(1) p1(1)], [p0(2) p1(2)], '-', 'Color',[.55 .50 .40], ...
             'LineWidth',0.5, 'Clipping','on');
    end
end

% ---- trees ----------------------------------------------------------------
% Added 11 Sep 2026, Phase E of the density-initiative fix pass, for S4's median/shoulder
% planting and S5's climb-side forest scatter - a DIFFERENT, lighter mechanism from
% sc.s1world's own 2200-tree forest (a big numeric matrix, rendered by the older
% sc.s1render 3D chase-cam system, not this one). Disclosed rather than unified: S1's
% forest carries canopy-cover solving, clumping noise and a reveal-distance mechanic none
% of the new vegetation needs or claims - this is a plain scatter of crowns, drawn as
% filled circles, nothing more.
if isfield(W,'TreeScatter') && ~isempty(W.TreeScatter)
    Tr = W.TreeScatter;
    nT = numel(Tr);
    th = linspace(0, 2*pi, 10);
    V = zeros(nT*10, 2);  F = zeros(nT,10);  Cd = zeros(nT,3);
    for k = 1:nT
        c = P.at(Tr(k).Station, Tr(k).Lateral);
        r = fieldOr(Tr(k),'CrownR',1.5);
        V((k-1)*10+1:k*10,:) = [c(1)+r*cos(th); c(2)+r*sin(th)]';
        F(k,:) = (k-1)*10+1 : k*10;
        Cd(k,:) = treeColour(fieldOr(Tr(k),'Species',"generic"));
    end
    patch(ax, 'Faces',F, 'Vertices',V, 'FaceVertexCData',Cd, 'FaceColor','flat', ...
          'EdgeColor','none', 'FaceAlpha',0.85, 'Clipping','on');
end

% ---- signs - gantry / cautionary / km-stone / hoarding -------------------
% Added 11 Sep 2026, Phase B of the density-initiative fix pass. Nothing drew these
% before, at all - S4-THE-HIGHWAY.md's own "signage and furniture is the thing that makes
% a highway read as a highway" line named a real gap. Shapes and colours are the SAME
% IRC 67 / Vienna-convention sourcing drawHazard's own "sharpturn"/"speedsign" cases
% already use for S1/S3's hazards - this is the identical real-world convention, just for
% CONTEXT signs rather than hazards the planner's speed cap logic reads.
if isfield(W,'Signs') && ~isempty(W.Signs)
    for k = 1:numel(W.Signs)
        drawSign(ax, P, W.Signs(k));
    end
end
end

function drawSign(ax, P, sg)
c = P.at(sg.Station, sg.Lateral);
switch string(sg.Type)
case "gantry"
    % IRC: a wide green overhead panel spanning the carriageway. Drawn here as a green
    % band across the road at its station - the deck itself is 5.5m up, invisible to a
    % top-down view (the same "no elevation channel" call sc.s4world's own header makes
    % for flyover decks), so this marks WHERE it crosses, not what it looks like from below.
    [~, acrossDir] = frame(P, sg.Station);
    hw = 8.0;
    p0 = c - acrossDir*hw;  p1 = c + acrossDir*hw;
    plot(ax, [p0(1) p1(1)], [p0(2) p1(2)], '-', 'Color',[.05 .45 .15], 'LineWidth',5.0, ...
         'Clipping','on');
case "cautionary"
    % IRC 67: white equilateral triangle, red border - IDENTICAL shape to drawHazard's
    % own "sharpturn" case, reused verbatim rather than redrawn differently.
    r = 2.0;
    th = [pi/2, pi/2+2*pi/3, pi/2+4*pi/3];
    patch(ax, c(1)+r*cos(th), c(2)+r*sin(th), [1 1 1], ...
          'EdgeColor',[.80 .08 .10], 'LineWidth',2.6, 'Clipping','on');
case "kmstone"
    % IRC 8: 600x300x100mm, green top for a national highway.
    r = 0.8;
    patch(ax, c(1)+r*[-1 1 1 -1], c(2)+r*[-.5 -.5 .5 .5], [.90 .88 .80], ...
          'EdgeColor',[.05 .45 .15], 'LineWidth',2.0, 'Clipping','on');
case "hoarding"
    % a unipole billboard - grey board, dark post mark. Drawn axis-aligned rather than
    % rotated to the road heading - a small map icon, not a measured footprint.
    r = [3.0 1.4];
    patch(ax, c(1)+r(1)*[-1 1 1 -1], c(2)+r(2)*[-1 -1 1 1], [.75 .75 .75], ...
          'EdgeColor',[.3 .3 .3], 'LineWidth',1.2, 'Clipping','on');
otherwise
    plot(ax, c(1), c(2), 's', 'MarkerSize',8, 'Color',[.5 .5 .5], 'Clipping','on');
end
lbl = string(fieldOr(sg,'Label',""));
if strlength(lbl) > 0
    [~, acrossDir] = frame(P, sg.Station);
    anchor = c + acrossDir*7.0;
    text(ax, anchor(1), anchor(2), char(labelHead(lbl,28)), ...
         'HorizontalAlignment','center','VerticalAlignment','middle', ...
         'FontName','Helvetica','FontSize',8,'Color',[.15 .15 .15], ...
         'BackgroundColor',[1 1 1],'EdgeColor',[.6 .6 .6],'Margin',1.5, ...
         'Interpreter','none','Clipping','on');
end
end

function c = treeColour(species)
%TREECOLOUR  Map-symbol colours, same footing as buildingColour's own -
%   not photographed, a legibility convention distinguishing species groups.
switch string(species)
case "gulmohar_amaltas", c = [.42 .58 .28];   % median flowering trees, a warmer green
case "eucalyptus",       c = [.38 .50 .42];   % cooler grey-green, pale peeling bark canopy
case "sal",               c = [.30 .42 .22];   % denser forest green
otherwise,                c = [.35 .48 .28];
end
end

function c = buildingColour(typ)
%BUILDINGCOLOUR  One colour per building Type tag, so the map reads as a
%   legend even with no per-object label. Not sourced from a photograph -
%   these are MAP SYMBOL colours (a legibility convention, same footing as
%   drawHazard's speed-sign red rim), disclosed as such.
switch string(typ)
case "hut",       c = [.82 .70 .50];   % mud/dung-plastered, thatch
case "house1",    c = [.80 .78 .74];   % single-storey unplastered brick
case "house2",    c = [.72 .70 .64];   % two-storey
case "house3",    c = [.60 .58 .55];   % three-storey, darkest of the three heights
case "wall",      c = [.85 .84 .80];   % a blank compound wall, not a habitable building
case "shop",      c = [.55 .62 .78];   % distinguishable from housing at a glance
case "shrine",    c = [.95 .90 .55];   % whitewashed + marigold, a warm highlight
case {"tin_shed","shed"}, c = [.60 .58 .62];
otherwise,        c = [.78 .76 .72];
end
end

function drawHazard(ax, P, hz, idx)
%DRAWHAZARD  One static road hazard plus its on-screen label, drawn once at
%   init. Real-world sourced colours - see plannerView's own header for exactly
%   where each comes from. EVERY hazard gets a label: nothing unexplained.
lat  = fieldOr(hz,'Lateral',0);
zone = fieldOr(hz,'Zone',0);
cap  = fieldOr(hz,'SpeedCap',NaN);
c    = P.at(hz.Station, lat);

% ---- the affected stretch, if this hazard has one -----------------------
% Drawn first so every glyph sits on top of it. Zone runs FORWARD from
% Station - that is the convention demo_play.m enforces the SpeedCap over,
% and the two must not disagree about where the stretch is.
if zone > 0
    hwz = 3.6;
    ns  = max(2, ceil(zone/2));
    ss  = linspace(hz.Station, hz.Station + zone, ns);
    LL = zeros(ns,2); RR = zeros(ns,2);
    for i = 1:ns
        LL(i,:) = P.at(ss(i),  hwz);
        RR(i,:) = P.at(ss(i), -hwz);
    end
    band = [LL; flipud(RR)];
    patch(ax, band(:,1), band(:,2), [1 .72 .25], 'FaceAlpha',0.22, ...
          'EdgeColor',[.9 .6 .1], 'LineStyle','--', 'LineWidth',0.9);
end

switch string(hz.Type)
case "pothole"
    % S1's own spec gives potholes as 0.25-0.9 m ACROSS (radius 0.125-0.45 m)
    % - genuinely near-invisible at a "watch the whole road" zoom. The default
    % here is a DELIBERATE, DISCLOSED size boost for legibility (~3x true
    % size), the same convention a real road map uses to draw lane markings
    % wider than true scale - not a claim about true size.
    % sc.demo1Route supplies TRUE radii (0.15-0.45 m). At a 95 m half-span
    % those are sub-pixel - a pothole drawn to true scale is a pothole nobody
    % can see. drawR applies the disclosed 3x boost with a floor; the true
    % radius is still what the LABEL quotes, so the picture is enlarged and
    % the number is not.
    r = drawR(hz, 1.8, 1.2);
    th = linspace(0, 2*pi, 24);
    % S1's own spec: "muddy, dark, no sky reflection" - a dark, slightly warm
    % fill (asphalt-shadow, not flat black), with a burnt-orange rim because a
    % dark fill THIS small is low-contrast on a pale road - a legibility
    % concession, disclosed as one.
    patch(ax, c(1)+r*cos(th), c(2)+r*sin(th), [.10 .09 .08], ...
          'EdgeColor',[.8 .4 .1], 'LineWidth',1.8);

case "breaker"
    % S1's own spec, verbatim: "painted in black-and-white bands 300 mm wide".
    % Drawn across the FULL carriageway, perpendicular to travel - a real
    % speed breaker runs across the road, never along it.
    [alongDir, acrossDir] = frame(P, hz.Station);
    hw = 3.6;  nBands = 12;  bandW = (2*hw)/nBands;  bandDepth = 3.7;
    for b = 0:nBands-1
        off = -hw + b*bandW;
        p0 = c + acrossDir*off;
        p1 = c + acrossDir*(off+bandW);
        col = [0 0 0]; if mod(b,2)==0, col = [1 1 1]; end
        quad = [p0 - alongDir*bandDepth/2; p1 - alongDir*bandDepth/2; ...
                p1 + alongDir*bandDepth/2; p0 + alongDir*bandDepth/2];
        patch(ax, quad(:,1), quad(:,2), col, 'EdgeColor',[.3 .3 .3], 'LineWidth',0.5);
    end

case "barrier"
    % A roadside marker board. Ordinary black-and-yellow hazard convention -
    % this project's own scenarios never place a real barrier, so the everyday
    % real-world convention is the honest source.
    [alongDir, acrossDir] = frame(P, hz.Station);
    L = 3.0; Wd = 1.0;    % a waist-high barricade board is about this size
    corners = c + alongDir.*[-L/2 L/2 L/2 -L/2]' + acrossDir.*[-Wd/2 -Wd/2 Wd/2 Wd/2]';
    % PLAIN yellow block, black border, no internal stripe - a chevron pattern
    % was tried first and read as solid black: LineWidth is a FIXED PIXEL
    % width, so at this board's size 3 diagonal lines covered nearly the whole
    % face however the colours were set. Simpler reads correctly at any zoom.
    patch(ax, corners(:,1), corners(:,2), [0.95 0.75 0.05], 'EdgeColor','k','LineWidth',1.5);

case "damage"
    % Broken carriageway - the Demo 2 stress test. An IRREGULAR patch, because
    % a circle reads as a pothole and a rectangle reads as a sign. The
    % irregularity is seeded from the station so the same hazard draws
    % identically every run - a demo that reshuffles its own road between takes
    % is not reproducible.
    r  = fieldOr(hz,'Radius',2.6);
    rs = RandStream('twister','Seed', mod(round(hz.Station*7), 2^31));
    n  = 14;  th = linspace(0, 2*pi, n+1); th(end) = [];
    rr = r .* (0.62 + 0.55*rand(rs, 1, n));
    px = c(1) + rr.*cos(th);  py = c(2) + rr.*sin(th);
    patch(ax, px, py, [.22 .20 .18], 'EdgeColor',[.55 .30 .10], 'LineWidth',1.6);
    % cracks radiating out - what actually distinguishes broken tarmac from a hole
    for q = 1:5
        a = 2*pi*q/5 + 0.4;
        plot(ax, c(1)+[0.2 1.35]*r*cos(a), c(2)+[0.2 1.35]*r*sin(a), ...
             '-', 'Color',[.35 .30 .26], 'LineWidth',1.1);
    end

case "speedsign"
    % IRC 67 / Vienna-convention mandatory speed limit: white disc, red rim,
    % black numeral. The numeral is NOT decorative - it is SpeedCap in km/h,
    % so the sign and the cap the car obeys can never drift apart.
    % A SIGN IS A MAP SYMBOL, not a road object: its size is chosen for
    % legibility and Radius (0 in Chat 3's routes) must not shrink it away.
    r = 1.7;
    th = linspace(0, 2*pi, 40);
    patch(ax, c(1)+r*cos(th), c(2)+r*sin(th), [1 1 1], ...
          'EdgeColor',[.80 .08 .10], 'LineWidth',3.2);
    if isfinite(cap)
        text(ax, c(1), c(2), sprintf('%d', round(cap*3.6)), ...
             'HorizontalAlignment','center','VerticalAlignment','middle', ...
             'FontSize',10,'FontWeight','bold','Color',[.1 .1 .1],'Clipping','on');
    end

case "slowzone"
    % The band above IS the hazard. A small amber marker anchors the label so
    % the text has something to point at.
    r = 1.1;                        % a marker for the band, not a real object
    th = linspace(0, 2*pi, 24);
    patch(ax, c(1)+r*cos(th), c(2)+r*sin(th), [.98 .70 .10], ...
          'EdgeColor',[.6 .4 .05], 'LineWidth',1.4);

case "sharpturn"
    % IRC 67 cautionary sign: white equilateral triangle, red rim, black glyph.
    r = 2.0;                        % map symbol, sized for legibility
    th = [pi/2, pi/2+2*pi/3, pi/2+4*pi/3];
    patch(ax, c(1)+r*cos(th), c(2)+r*sin(th), [1 1 1], ...
          'EdgeColor',[.80 .08 .10], 'LineWidth',2.6);
    % the bend glyph
    plot(ax, c(1)+[-0.35 -0.35 0.35]*r, c(2)+[-0.35 0.15 0.15]*r, ...
         '-', 'Color',[.1 .1 .1], 'LineWidth',2.0);

otherwise
    % An unknown type must still be VISIBLE and LABELLED rather than silently
    % dropped - a hazard that does not draw is a hazard nobody notices is missing.
    plot(ax, c(1), c(2), 'x', 'MarkerSize',12, 'Color',[.8 .1 .1], 'LineWidth',2);
end

% ---- THE LABEL - every hazard, always, beside the element ---------------
% Chat 3's routes carry FULL-SENTENCE labels ("Pothole cluster, 1 of 3 -
% 240/241/243 m sit only 1-2 m apart: too tight to thread through, slow and
% roll over all three."). That is the right thing to store and the wrong thing
% to paint across the road: unwrapped it spans the whole frame and hides the
% car. So the map gets the HEAD of the label - everything up to the first
% dash, colon or full stop, which is how these labels are already written -
% and demo_play hands the FULL sentence to the panel as the ego reaches it.
% Nothing goes unexplained; the explanation just has somewhere sane to sit.
lbl = string(fieldOr(hz,'Label',""));
if strlength(lbl) == 0
    lbl = string(hz.Type);      % never leave one unexplained
end
short = labelHead(lbl, 30);
if isfinite(cap)
    short = short + sprintf("  [%.0f km/h]", cap*3.6);
end
% Offset AWAY from the centreline on the hazard's own side, so a label never
% sits on top of the carriageway the ego is about to drive down. Hazards
% CLUSTER - 240/241/243 m sit 1-2 m apart, and Demo 2 packs 25 of them into
% the same road - so a single fixed offset stacks labels on top of each other.
% Two things spread them: the distance cycles through five slots by index, and
% a hazard sitting ON the centreline (lat == 0, which most signs and breakers
% are) alternates which side it labels to instead of every one going left.
[~, acrossDir] = frame(P, hz.Station);
if nargin < 4, idx = 1; end
if lat < 0
    side = -1;
elseif lat > 0
    side = 1;
else
    side = 1; if mod(idx,2) == 0, side = -1; end
end
anchor = c + acrossDir*side*(5.6 + 3.1*mod(idx-1,5));
% CLIPPING MUST BE ON. Text objects do NOT clip to the axes by default, so a
% label 300 m up the road painted itself over the figure's own title and key
% hints - visible in the first exported frame. Every hazard glyph gets the
% same treatment (clipHazard, below).
text(ax, anchor(1), anchor(2), char(short), ...
     'HorizontalAlignment','center','VerticalAlignment','middle', ...
     'FontName','Helvetica','FontSize',9,'FontWeight','bold','Color',[.12 .12 .12], ...
     'BackgroundColor',[1 1 1],'EdgeColor',[.65 .65 .65],'Margin',2.0, ...
     'Interpreter','none','Clipping','on');
plot(ax, [c(1) anchor(1)], [c(2) anchor(2)], '-', 'Color',[.6 .6 .6], ...
     'LineWidth',0.6, 'Clipping','on');
end

function t = clampStr(v, n)
t = string(v);
if strlength(t) > n, t = extractBefore(t, n-2) + "..."; end
end

function h = labelHead(lbl, maxChars)
%LABELHEAD  The first clause of a label - what goes on the map. Splits on the
%   punctuation these labels are actually written with, then hard-truncates
%   only if that first clause is still too long to paint.
s = strtrim(string(lbl));
cut = regexp(char(s), ' - |: |\. ', 'once');
if ~isempty(cut) && cut > 3, s = strtrim(extractBefore(s, cut)); end
if strlength(s) > maxChars
    s = strtrim(extractBefore(s, maxChars-1)) + "...";
end
h = s;
end

function r = drawR(hz, dflt, floorR)
%DRAWR  The radius a hazard is DRAWN at, which is not the radius it HAS.
%   S1's own spec gives potholes as 0.25-0.9 m across and sc.demo1Route now
%   supplies exactly those true figures. At the zoom needed to see several
%   hazards at once they are smaller than one pixel. This applies a DISCLOSED
%   3x boost with a legibility floor - the same convention a road map uses to
%   draw a lane marking wider than true scale. It is not a claim about size,
%   and the label still quotes the real one.
r = fieldOr(hz,'Radius',NaN);
if ~isfinite(r) || r <= 0, r = dflt; else, r = max(3*r, floorR); end
end

% =========================================================================
%                              HELPERS
% =========================================================================
function [alongDir, acrossDir] = frame(P, s)
[~, hdg] = P.at(s, 0);
alongDir  = [cos(hdg) sin(hdg)];
acrossDir = [-sin(hdg) cos(hdg)];    % + is LEFT, the project's sign convention
end

function V = boxCorners(c, yaw, L, W)
R = [cos(yaw) -sin(yaw); sin(yaw) cos(yaw)];
p = [ L/2  W/2; L/2 -W/2; -L/2 -W/2; -L/2 W/2].';
V = (R*p + c(:)).';
end

function c = classColour(id)
switch double(id)
    case 10, c = [.55 .35 .15];   % cow
    case 4,  c = [.95 .75 .1];    % auto-rickshaw
    case 5,  c = [.85 .25 .25];   % motorbike
    case 14, c = [.2 .5 .2];      % tractor
    case 13, c = [.5 .4 .25];     % animal-drawn cart / trolley
    case 3,  c = [.3 .3 .7];      % bus
    case 1,  c = [.6 .6 .6];      % car
    otherwise, c = [.4 .4 .4];
end
end

function c = statusColour(stat)
switch lower(strtrim(char(stat)))
    case {'detecting','running','ok','active','segmenting','tracking'}, c = [.20 .70 .30];
    case {'gated','idle','standby','stub'},                             c = [.72 .72 .72];
    case {'degraded','fallback','warning','low confidence'},            c = [.95 .70 .10];
    case {'failed','error','blocked','down'},                           c = [.85 .20 .15];
    otherwise,                                                          c = [.45 .55 .85];
end
end

function M = stubModels(why)
%STUBMODELS  Honest placeholder until Chat 2's sc.modelStatus lands. It says
%   "stub" in as many words - a demo panel that invents model output is worse
%   than one that admits it has none yet.
d = 'stub - sc.modelStatus not on the path yet';
if ~isempty(why), d = why; end
M = struct( ...
  'Model',  {"Models 1+2", "Model 3",  "Model 4",     "Fusion"}, ...
  'Status', {"gated",      "stub",     "stub",        "stub"}, ...
  'Detail', {"intent/traj gated off - planner runs on geometry", d, d, d});
end

function r = plannerRow(cmd, d)
%PLANNERROW  The planner's own line. This one is NEVER a stub - it is read
%   straight out of the command the seat actually produced this step.
stat = string(getf(cmd,'State',"?"));
det  = sprintf('%d candidates, %d tracks, v* %.1f m/s', ...
               numCand(cmd), numel(d.tracks), getf(cmd,'v',NaN));
if isfield(cmd,'Blocked') && cmd.Blocked, stat = stat + " / blocked"; end
r = struct('Model',"PLANNER", 'Status',stat, 'Detail',string(det));
end

function n = numCand(cmd)
n = 0;
if isfield(cmd,'NCand'), n = cmd.NCand;
elseif isfield(cmd,'Candidates'), n = numel(cmd.Candidates); end
end

function s = noteOf(cmd)
s = ''; if isfield(cmd,'Note'), s = char(cmd.Note); end
end

function v = getf(s, f, dflt)
if isstruct(s) && isfield(s,f) && ~isempty(s.(f)), v = s.(f); else, v = dflt; end
end

function v = fieldOr(s, f, dflt)
v = dflt;
if isfield(s,f) && ~isempty(s.(f)) && (~isnumeric(s.(f)) || all(isfinite(s.(f)))), v = s.(f); end
end

function s = hlabel(cmd)
s = 'lambda-beta'; if isfield(cmd,'HLabel'), s = char(cmd.HLabel); end
end

function s = wrapNote(txt, width, maxLines)
%WRAPNOTE  Wrap to WIDTH and HARD-CAP the line count. The cap is not cosmetic:
%   Chat 3's hazard labels are full sentences, and an unbounded block of them
%   grew straight down out of the numbers axes and printed over the MODEL
%   STATUS panel below it - seen in a real exported frame. A text object does
%   not know where its axes ends, so the budget has to be enforced here.
if nargin < 3, maxLines = 4; end
if isempty(txt), s = ''; return; end
L = string(textwrap({txt}, width));
if numel(L) > maxLines
    L = L(1:maxLines);
    L(end) = extractBefore(L(end), max(2, strlength(L(end))-2)) + "...";
end
s = char(join(L, newline));
end

function v = onoff(tf)
if tf, v = 'on'; else, v = 'off'; end
end

function c = wrapStr(s, maxChars, maxLines)
%WRAPSTR  Wrap to at most maxLines of maxChars, breaking on spaces, and only
%   ellipsise if it genuinely will not fit. Returns a cellstr, which a text
%   object renders as multiple lines. See the call site for why these Details
%   must not be hard-truncated.
s = strtrim(string(s));
if strlength(s) == 0, c = {''}; return; end
words = split(s, ' ');
lines = strings(0,1);  cur = "";
for i = 1:numel(words)
    trial = cur;
    if strlength(trial) == 0, trial = words(i); else, trial = trial + " " + words(i); end
    if strlength(trial) <= maxChars
        cur = trial;
    else
        lines(end+1) = cur;                                   %#ok<AGROW>
        cur = words(i);
        if numel(lines) == maxLines, break; end
    end
end
if strlength(cur) > 0 && numel(lines) < maxLines, lines(end+1) = cur; end
if numel(lines) == maxLines && strlength(cur) > 0 && lines(end) ~= cur
    last = lines(end);
    if strlength(last) > maxChars - 3, last = extractBefore(last, maxChars-2); end
    lines(end) = last + "...";
end
c = cellstr(lines);
end
