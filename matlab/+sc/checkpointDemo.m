function checkpointDemo(opts)
%CHECKPOINTDEMO  The real, interactive checkpoint demo - a live MATLAB
%   window, not a video file. Phases 3-6 of the checkpoint-demo build
%   (11 Sep 2026), rebuilt 11 Sep evening: the first version of this file
%   rendered to a .gif for review in an Artifact, which was the wrong
%   deliverable - Aditya's own correction: "I want it to be built in
%   MATLAB only." This version opens a real figure and drives it live,
%   following the exact keyboard/appdata pattern sc.plannerView.m already
%   proves works (KeyPressFcn mutates figure appdata; the frame loop
%   blocks on that appdata between frames) - not reinvented, mirrored.
%
%   sc.checkpointDemo()                    S5->S1->S3->S2->S4, from the start
%   sc.checkpointDemo('Upto',"S1")         only build as far as S1 (faster)
%   sc.checkpointDemo('StartS',1300)       start partway in
%
%   CONTROLS, while the window has focus:
%     SPACE        pause / resume
%     -> or N      step one frame while paused
%     + / -        speed up / slow down (a live multiplier on opts.Speed)
%     1 2 3 4 5    jump to checkpoint S5 S1 S3 S2 S4 (whichever exist in
%                  this build - out-of-range keys are ignored)
%     Q / Esc      quit
%
%   WHAT TURNS ON BY ITSELF: each checkpoint's own forest/roundabout,
%   buildings and density actors, the moment the car's station enters that
%   checkpoint's own span - sc.checkpointChain already carries the real
%   station ranges, this just reads them every frame.
%
%   WHAT THIS IS NOT: the car is still a constant-speed cruise, not the
%   real planner - unchanged scope, per Aditya's own "no integration yet".

arguments
    opts.Upto      string = "S4"
    opts.StartS    (1,1) double = 0
    opts.Speed     (1,1) double = 12
    opts.ViewSpan  (1,1) double = 55
    opts.DT        (1,1) double = 0.1
    opts.Chain     struct = struct([])   % a prebuilt sc.checkpointChain, to skip the
                                          % ~8 s world rebuild when relaunching repeatedly
    opts.MaxFrames (1,1) double = Inf    % stop after N frames. Exists because a -batch
                                          % run has no keyboard: without it the end-of-route
                                          % hold below spins forever and the run must be
                                          % killed from outside (measured, twice, 11 Sep)
    opts.SnapFile  string = ""           % write the final frame here before closing
end

Sty = sc.demoStyle();
if isempty(fieldnames(opts.Chain))
    C = sc.checkpointChain('Upto', opts.Upto);
else
    C = opts.Chain;
end
P = C.Path;
names = strings(1, numel(C.Checkpoints));
for k = 1:numel(C.Checkpoints), names(k) = C.Checkpoints(k).Name; end

fig = figure('Name','SIH26037 - Checkpoint Demo','Color',Sty.Background, ...
             'Position',[60 60 1000 1040], 'NumberTitle','off', ...
             'MenuBar','none','ToolBar','none');
ax = axes('Parent',fig, 'Position',[0.03 0.03 0.94 0.90]);
hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
axMini = axes('Parent',fig, 'Position',[0.74 0.05 0.22 0.22]);

hintStr = sprintf('SPACE pause/resume   +/- speed   %s jump   Q quit', ...
                   strjoin("[" + (1:numel(names)) + "]" + names, "  "));
annotation(fig, 'textbox', [0.03 0.945 0.94 0.045], 'String', hintStr, ...
    'FontName','IBM Plex Mono','FontSize',10.5,'Color',Sty.TextColor, ...
    'EdgeColor','none','VerticalAlignment','middle');

setappdata(fig, 'ctl', struct('Paused',false,'StepOnce',false,'Quit',false, ...
                               'SpeedMult',1.0,'JumpTo',""));
set(fig, 'KeyPressFcn', @(f,e) onKey(f,e,names), 'CloseRequestFcn', @onClose);

s = opts.StartS; t = 0;
entryT = nan(1, numel(C.Checkpoints));
nFrames = 0;

while isgraphics(fig)
    ctl = getappdata(fig, 'ctl');
    if ctl.Quit, break; end

    if strlength(ctl.JumpTo) > 0
        idx = find(names == ctl.JumpTo, 1);
        if ~isempty(idx)
            s = C.Checkpoints(idx).SpanStart;
            entryT(:) = NaN;
            t = 0;
        end
        ctl.JumpTo = "";
        setappdata(fig, 'ctl', ctl);
    end

    cla(ax);
    sClamped = min(P.Len-1, max(0, s));
    [egoXY, hdg] = P.at(sClamped, 0);

    curHalfW = 2.75;             % plain connector road - a disclosed generic default
    curName  = "(connector)";
    activeActorsXY = zeros(0,2);
    for k = 1:numel(C.Checkpoints)
        cp = C.Checkpoints(k);
        if sClamped < cp.SpanStart || sClamped > cp.SpanEnd, continue; end
        curName = cp.Name;
        if isnan(entryT(k)), entryT(k) = t; end
        tLocal = t - entryT(k);

        if cp.Kind == "linear"
            curHalfW = cp.W.Width/2;
            sc.drawFurnitureStyled(ax, cp.W, cp.LocalPath, Sty);
            if isfield(cp.W, 'Trees')
                sc.drawForest(ax, cp.W, Sty, 'Centre', egoXY, 'Radius', opts.ViewSpan*1.8);
            end
        else
            curHalfW = cp.W.ArmW/2;
            sc.drawGyratory(ax, cp.W, Sty);
        end

        if ~isempty(cp.DensitySpec)
            A = sc.activeDensityActorsAt(cp.DensitySpec, cp.LocalPath, tLocal);
            sc.drawDensityActorsStyled(ax, A, Sty);
            if ~isempty(A), activeActorsXY = vertcat(A.XY); end %#ok<AGROW>
        end
    end

    sc.drawStyledRoad(ax, P, sClamped-opts.ViewSpan, sClamped+opts.ViewSpan, curHalfW, Sty);
    sc.drawEgoCar(ax, egoXY, hdg, Sty);
    xlim(ax, egoXY(1) + [-opts.ViewSpan opts.ViewSpan]);
    ylim(ax, egoXY(2) + [-opts.ViewSpan opts.ViewSpan]);

    sc.drawMinimap(axMini, P, egoXY, sClamped, 45, Sty, activeActorsXY);

    atEnd = s >= P.Len-1;
    endMsg = "";
    if atEnd, endMsg = " - END OF ROUTE, jump to another checkpoint or quit"; end
    hud = sprintf('s=%.0f m   t=%.1f s   %.0f km/h   at %s%s', ...
        sClamped, t, ctl.SpeedMult*opts.Speed*3.6, curName, endMsg);
    text(ax, egoXY(1)-opts.ViewSpan*0.95, egoXY(2)+opts.ViewSpan*0.90, char(hud), ...
         'FontName','IBM Plex Mono','FontSize',10,'Color',Sty.TextColor, ...
         'BackgroundColor',Sty.TextBg,'Margin',3);

    drawnow;
    nFrames = nFrames + 1;
    if mod(nFrames, 20) == 0
        fprintf('[checkpointDemo] frame %d   s=%.0f m   t=%.1f s   at %s\n', nFrames, sClamped, t, curName);
    end

    ctl = getappdata(fig, 'ctl');
    if ctl.StepOnce
        ctl.StepOnce = false; ctl.Paused = true;
        setappdata(fig, 'ctl', ctl);
    else
        while ctl.Paused && ~ctl.Quit
            drawnow;
            pause(0.03);
            if ~isgraphics(fig), return; end
            ctl = getappdata(fig, 'ctl');
            if ctl.StepOnce, break; end
        end
    end
    if ctl.Quit || ~isgraphics(fig), break; end
    if nFrames >= opts.MaxFrames, break; end

    if ~atEnd
        s = min(P.Len-1, s + ctl.SpeedMult*opts.Speed*opts.DT);
        t = t + opts.DT;
    end
end

if isgraphics(fig)
    if strlength(opts.SnapFile) > 0
        try
            exportgraphics(fig, opts.SnapFile, 'Resolution', 140);
        catch me
            warning('sc:checkpointDemo:snap', 'could not write %s: %s', opts.SnapFile, me.message);
        end
    end
    set(fig, 'CloseRequestFcn', 'closereq', 'KeyPressFcn', []);
    delete(fig);
end
end

% =============================================================================
function onKey(fig, ev, names)
ctl = getappdata(fig, 'ctl');
switch lower(ev.Key)
    case 'space'
        ctl.Paused = ~ctl.Paused;
    case {'rightarrow','n'}
        ctl.Paused = true; ctl.StepOnce = true;
    case {'q','escape'}
        ctl.Quit = true; ctl.Paused = false;
    case {'equal','add'}          % '+' (shift+= on most layouts registers as 'equal')
        ctl.SpeedMult = min(4.0, ctl.SpeedMult * 1.3);
    case {'hyphen','subtract'}
        ctl.SpeedMult = max(0.2, ctl.SpeedMult / 1.3);
    otherwise
        idx = str2double(ev.Key);
        if isfinite(idx) && idx >= 1 && idx <= numel(names)
            ctl.JumpTo = names(idx);
        end
end
setappdata(fig, 'ctl', ctl);
end

function onClose(fig, ~)
ctl = getappdata(fig, 'ctl');
ctl.Quit = true;
setappdata(fig, 'ctl', ctl);
delete(fig);
end
