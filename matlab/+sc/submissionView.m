function out = submissionView(action,d)
%SUBMISSIONVIEW Polished three-panel presentation for recorded SIH planner runs.
%
%   Presentation only: this function never changes planner, tracker, or
%   vehicle state. Offline camera footage is independent of the recorded
%   MATLAB replay and is labelled as such. Detection boxes are displayed only
%   when loaded from a genuine offline detector cache.

persistent S
out = emptyControl();

switch action
case 'init'
    S = initialise(d);
case 'step'
    if isempty(S) || ~isgraphics(S.fig)
        out.Quit = true;
        return
    end
    started = tic;
    S = updateFrame(S,d);
    S.frames = S.frames+1;
    S.lastFrame_ms = toc(started)*1000;
    out = controls(S);
case {'addHazard','status','queueInjection'}
    if ~isempty(S) && isgraphics(S.fig), out = controls(S); end
case 'snap'
    if ~isempty(S) && isgraphics(S.fig)
        exportgraphics(S.fig,d.file,'Resolution',120,'BackgroundColor',S.fig.Color);
    end
case 'close'
    if ~isempty(S) && isfield(S,'fig') && isgraphics(S.fig)
        set(S.fig,'CloseRequestFcn','closereq','KeyPressFcn',[]);
        delete(S.fig);
    end
    S = [];
    drawnow;
otherwise
    error('sc:submissionView:UnknownAction','Unknown action "%s".',action);
end
end

function S = initialise(d)
S = struct();
S.P = d.P;
S.W = d.W;
S.headless = batchStartupOptionUsed;
S.interactive = getf(d,'Interactive',true);
S.frames = 0;
S.lastFrame_ms = NaN;

C.bg = [0.018 0.038 0.050];
C.panel = [0.030 0.055 0.066];
C.panel2 = [0.045 0.073 0.086];
C.edge = [0.16 0.24 0.28];
C.ink = [0.86 0.89 0.91];
C.muted = [0.63 0.69 0.72];
C.green = [0.33 0.93 0.55];
C.amber = [1.00 0.72 0.15];
C.red = [1.00 0.28 0.25];
C.blue = [0.20 0.62 0.96];
S.C = C;

S.fig = figure('Name','SIH26037 - Perception to Decision','Color',C.bg, ...
    'Position',[20 35 1600 900],'NumberTitle','off','MenuBar','none', ...
    'ToolBar','none','InvertHardcopy','off');
if S.headless, set(S.fig,'Visible','off'); end

annotation(S.fig,'textbox',[0.012 0.946 0.68 0.046], ...
    'String','SIH26037  —  PERCEPTION TO DECISION','EdgeColor','none', ...
    'Color',C.ink,'FontName','Arial','FontSize',20,'FontWeight','bold', ...
    'VerticalAlignment','middle');
scenario = scenarioLabel(string(getf(d,'Title',"")));
annotation(S.fig,'textbox',[0.67 0.950 0.315 0.038], ...
    'String',char(scenario),'EdgeColor','none','Color',[0.70 0.76 0.79], ...
    'FontName','Arial','FontSize',10,'HorizontalAlignment','right', ...
    'VerticalAlignment','middle');
annotation(S.fig,'line',[0.008 0.992],[0.942 0.942],'Color',C.edge);

cameraPanel = [0.007 0.185 0.515 0.746];
trackPanel = [0.527 0.185 0.198 0.746];
planPanel = [0.730 0.185 0.263 0.746];
panelFrame(S.fig,cameraPanel,C);
panelFrame(S.fig,trackPanel,C);
panelFrame(S.fig,planPanel,C);
panelTitle(S.fig,[0.013 0.895 0.503 0.031],'FRONT CAMERA · OFFLINE REAL-WORLD FOOTAGE');
panelTitle(S.fig,[0.533 0.895 0.186 0.031],'BIRD''S-EYE TRACKED-AGENT VIEW');
panelTitle(S.fig,[0.736 0.895 0.251 0.031],'PLANNER DECISION VIEW');

% Camera -----------------------------------------------------------------
S.axCamera = axes('Parent',S.fig,'Position',[0.013 0.230 0.503 0.655], ...
    'Color',[0.01 0.02 0.025],'XColor','none','YColor','none');
hold(S.axCamera,'on');
S.cameraVideo = [];
S.det = [];
S.maxDet = 24;
videoFile = string(getf(d,'CameraVideo',""));
if isfile(videoFile)
    S.cameraVideo = VideoReader(char(videoFile));
    first = readFrame(S.cameraVideo);
    S.cameraLastTime = 0;
    first = cropToAspect(first,1.36);
    S.cameraImage = image(S.axCamera,first);
    set(S.axCamera,'YDir','reverse','XLim',[1 size(first,2)],'YLim',[1 size(first,1)]);
    cacheFile = string(regexprep(char(videoFile),'(?i)\.mp4$','_yolox.mat'));
    if isfile(cacheFile), S.det = load(cacheFile); end
else
    S.cameraImage = gobjects(0);
    axis(S.axCamera,[0 1 0 1]);
    text(S.axCamera,0.5,0.5,'FOOTAGE SOURCE NOT CONNECTED', ...
        'Color',C.ink,'HorizontalAlignment','center','FontWeight','bold');
end
axis(S.axCamera,'off');
S.detBox = gobjects(S.maxDet,1);
S.detText = gobjects(S.maxDet,1);
for k = 1:S.maxDet
    S.detBox(k) = rectangle(S.axCamera,'Position',[1 1 1 1], ...
        'EdgeColor',C.green,'LineWidth',1.5,'Visible','off');
    S.detText(k) = text(S.axCamera,1,1,'','Color',[0.02 0.04 0.05], ...
        'BackgroundColor',C.green,'FontName','Arial','FontSize',7.5, ...
        'FontWeight','bold','VerticalAlignment','bottom','Clipping','on', ...
        'Visible','off','Interpreter','none');
end
annotation(S.fig,'textbox',[0.013 0.195 0.503 0.029], ...
    'String','YOLOX: GENUINE OFFLINE DETECTIONS  ·  NOT CLOSED-LOOP CONTROL', ...
    'Color',[0.70 0.82 0.84],'BackgroundColor',[0.020 0.041 0.051], ...
    'EdgeColor',C.edge,'FontName','Arial','FontSize',8,'FontWeight','bold', ...
    'HorizontalAlignment','center','VerticalAlignment','middle');

% Ego-local maps ---------------------------------------------------------
S.axTrack = mapAxes(S.fig,[0.534 0.205 0.184 0.680],[-10 10],[-12 52],C);
S.axPlan = mapAxes(S.fig,[0.742 0.515 0.239 0.370],[-13 13],[-7 45],C);
S.trackMap = initialiseMap(S.axTrack,S.P,S.W,C,true);
S.planMap = initialiseMap(S.axPlan,S.P,S.W,C,false);

S.stateBox = annotation(S.fig,'textbox',[0.742 0.424 0.239 0.072], ...
    'String','WAITING','Color',C.amber,'BackgroundColor',[0.055 0.070 0.060], ...
    'EdgeColor',C.amber,'LineWidth',1.25,'FontName','Arial','FontSize',24, ...
    'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
S.metricBox = annotation(S.fig,'textbox',[0.742 0.397 0.239 0.023], ...
    'String','RECORDED REPLAY','Color',C.muted,'EdgeColor','none', ...
    'FontName','Arial','FontSize',7.5,'HorizontalAlignment','center', ...
    'VerticalAlignment','middle');
S.reasonBox = annotation(S.fig,'textbox',[0.742 0.235 0.239 0.150], ...
    'String','WHY: recorded planner reason','Color',C.ink, ...
    'BackgroundColor',[0.030 0.053 0.066],'EdgeColor',[0.33 0.43 0.48], ...
    'LineWidth',0.9,'FontName','Arial','FontSize',10.5,'FontWeight','bold', ...
    'VerticalAlignment','middle','Interpreter','none');

% Four-block status bar, matching the intended presentation hierarchy.
strip = [0.007 0.025 0.986 0.135];
annotation(S.fig,'rectangle',strip,'Color',C.edge,'FaceColor',[0.026 0.052 0.064]);
items = {
    'PERCEPTION','OFFLINE VIDEO + YOLOX';
    'TRACKING','RECORDED SIMULATION';
    'PLANNING','CLOSED-LOOP SIMULATION';
    'SAFETY CHECK','GEOMETRIC FALLBACK ACTIVE'};
for k = 1:4
    x0 = strip(1)+strip(3)*(0.015+(k-1)*0.247);
    if k>1
        annotation(S.fig,'line',[x0-0.012 x0-0.012], ...
            [strip(2)+0.018 strip(2)+strip(4)-0.018],'Color',C.edge);
    end
    annotation(S.fig,'ellipse',[x0 strip(2)+0.038 0.036 0.060], ...
        'Color',C.green,'LineWidth',1.6,'FaceColor',[0.026 0.052 0.064]);
    annotation(S.fig,'textbox',[x0 strip(2)+0.052 0.036 0.032], ...
        'String',items{k,1}(1),'EdgeColor','none','Color',C.green, ...
        'FontName','Arial','FontSize',10,'FontWeight','bold', ...
        'HorizontalAlignment','center','VerticalAlignment','middle');
    annotation(S.fig,'textbox',[x0+0.047 strip(2)+0.067 0.185 0.030], ...
        'String',items{k,1},'EdgeColor','none','Color',C.ink, ...
        'FontName','Arial','FontSize',9,'FontWeight','bold','VerticalAlignment','middle');
    annotation(S.fig,'textbox',[x0+0.047 strip(2)+0.035 0.185 0.030], ...
        'String',items{k,2},'EdgeColor','none','Color',C.muted, ...
        'FontName','Arial','FontSize',7.8,'VerticalAlignment','middle');
    annotation(S.fig,'line',[x0+0.047 x0+0.222], ...
        [strip(2)+0.027 strip(2)+0.027],'Color',C.green,'LineWidth',2.6);
end

setappdata(S.fig,'ctl',struct('Paused',false,'StepOnce',false,'Quit',false));
if S.interactive
    set(S.fig,'KeyPressFcn',@onKey,'CloseRequestFcn',@onClose);
end
end

function S = updateFrame(S,d)
cmd = d.cmd;

% Offline footage and genuine cached YOLOX detections.
if ~isempty(S.cameraVideo) && isgraphics(S.cameraImage)
    latest = max(0,S.cameraVideo.Duration-1/max(S.cameraVideo.FrameRate,1));
    cameraTime = mod(max(0,double(d.t)),max(latest,eps));
    if cameraTime+0.10<S.cameraLastTime || abs(S.cameraVideo.CurrentTime-cameraTime)>0.30
        S.cameraVideo.CurrentTime = cameraTime;
    end
    if hasFrame(S.cameraVideo)
        raw = readFrame(S.cameraVideo);
        while hasFrame(S.cameraVideo) && S.cameraVideo.CurrentTime+1/S.cameraVideo.FrameRate<cameraTime
            raw = readFrame(S.cameraVideo);
        end
        S.cameraLastTime = cameraTime;
        [frame,xOffset] = cropToAspect(raw,1.36);
        set(S.cameraImage,'CData',frame,'XData',[1 size(frame,2)],'YData',[1 size(frame,1)]);
        set(S.axCamera,'XLim',[1 size(frame,2)],'YLim',[1 size(frame,1)]);
        if ~isempty(S.det)
            [~,idx] = min(abs(S.det.sampleTimes-cameraTime));
            boxes = S.det.bboxes{idx};
            boxes(:,1) = boxes(:,1)-xOffset;
            showDetections(S,boxes,S.det.scores{idx},S.det.labels{idx},size(frame));
        end
    end
end

S.trackMap = updateMap(S.trackMap,d,false);
S.planMap = updateMap(S.planMap,d,true);

state = upper(string(getf(cmd,'State',"UNKNOWN")));
if logical(getf(cmd,'Blocked',false)), state = state+" · BLOCKED"; end
colour = stateColour(state,S.C);
set(S.stateBox,'String',char(state),'Color',colour,'EdgeColor',colour);

h = getf(cmd,'H',NaN);
metric = string(sprintf('RECORDED REPLAY  ·  %.1f km/h',3.6*d.v));
if isfinite(h), metric = metric+string(sprintf('  ·  h %+.3f',h)); end
if isfield(cmd,'NCand'), metric = metric+string(sprintf('  ·  %d candidates',cmd.NCand)); end
set(S.metricBox,'String',char(metric));
reason = string(getf(cmd,'Note',"No recorded explanation in this frame."));
set(S.reasonBox,'String',char("WHY: "+reason));

if ~S.headless
    drawnow('limitrate');
    ctl = getappdata(S.fig,'ctl');
    while ctl.Paused && ~ctl.Quit && ~ctl.StepOnce
        drawnow;
        pause(0.03);
        if ~isgraphics(S.fig), return; end
        ctl = getappdata(S.fig,'ctl');
    end
    if ctl.StepOnce
        ctl.StepOnce = false;
        ctl.Paused = true;
        setappdata(S.fig,'ctl',ctl);
    end
end
end

function M = initialiseMap(ax,P,W,C,withMotion)
drawBackdrop(ax,C);
Cg = P.P;
hw = W.Width/2;
nrm = [-sin(P.Hdg),cos(P.Hdg)];
M.centreGlobal = Cg;
M.leftGlobal = Cg+hw.*nrm;
M.rightGlobal = Cg-hw.*nrm;
M.road = patch(ax,nan,nan,[0.16 0.19 0.20],'EdgeColor','none');
M.edgeL = plot(ax,nan,nan,'-','Color',[0.48 0.53 0.54],'LineWidth',1.0);
M.edgeR = plot(ax,nan,nan,'-','Color',[0.48 0.53 0.54],'LineWidth',1.0);
M.centre = plot(ax,nan,nan,'--','Color',[0.34 0.39 0.40],'LineWidth',0.8);
M.candidates = plot(ax,nan,nan,'-','Color',[0.48 0.55 0.58],'LineWidth',0.75);
M.trunk = plot(ax,nan,nan,'-','Color',C.green,'LineWidth',2.3);
M.look = plot(ax,nan,nan,'o','Color',C.green,'MarkerSize',5,'LineWidth',1.2);
M.objects = patch(ax,'Faces',zeros(0,4),'Vertices',zeros(0,2), ...
    'FaceVertexCData',zeros(0,3),'FaceColor','flat','EdgeColor',[.92 .96 .98], ...
    'LineWidth',1.1);
M.ego = vehiclePatch(ax,[0.90 0.93 0.95]);
M.egoRoof = vehiclePatch(ax,[0.14 0.22 0.27]);
M.withMotion = withMotion;
M.motion = quiver(ax,[],[],[],[],0,'Color',C.blue,'LineWidth',1.2, ...
    'MaxHeadSize',0.8,'AutoScale','off');
M.maxLabels = 18;
M.labels = gobjects(M.maxLabels,1);
for k = 1:M.maxLabels
    M.labels(k) = text(ax,0,0,'','Color',[0.85 0.90 0.92], ...
        'FontName','Arial','FontSize',6.5,'FontWeight','bold', ...
        'HorizontalAlignment','center','VerticalAlignment','bottom', ...
        'Visible','off','Clipping','on');
end
end

function M = updateMap(M,d,showPlanning)
left = toEgo(M.leftGlobal,d.ego,d.yaw);
right = toEgo(M.rightGlobal,d.ego,d.yaw);
centre = toEgo(M.centreGlobal,d.ego,d.yaw);
set(M.road,'XData',[left(:,1);flipud(right(:,1))], ...
    'YData',[left(:,2);flipud(right(:,2))]);
set(M.edgeL,'XData',left(:,1),'YData',left(:,2));
set(M.edgeR,'XData',right(:,1),'YData',right(:,2));
set(M.centre,'XData',centre(:,1),'YData',centre(:,2));

setLocalObjects(M.objects,d.tracks,d.ego,d.yaw);
setVehicle(M.ego,[0 0],pi/2,4.7,1.9);
setVehicle(M.egoRoof,[0 0.25],pi/2,2.2,1.35);
updateLabels(M,d.tracks,d.ego,d.yaw);

if M.withMotion
    n = numel(d.tracks);
    x=zeros(n,1); y=zeros(n,1); u=zeros(n,1); v=zeros(n,1);
    fwd=[cos(d.yaw) sin(d.yaw)]; leftDir=[-sin(d.yaw) cos(d.yaw)];
    for k=1:n
        p=toEgo(d.tracks(k).Position(1:2),d.ego,d.yaw);
        x(k)=p(1); y(k)=p(2);
        vel=d.tracks(k).Velocity(1:2);
        u(k)=dot(vel,leftDir)*2.0; v(k)=dot(vel,fwd)*2.0;
    end
    set(M.motion,'XData',x,'YData',y,'UData',u,'VData',v);
else
    set(M.motion,'XData',[],'YData',[],'UData',[],'VData',[]);
end

cmd=d.cmd;
if showPlanning
    if isfield(cmd,'CandX')
        p=toEgo([double(cmd.CandX(:)) double(cmd.CandY(:))],d.ego,d.yaw);
        set(M.candidates,'XData',p(:,1),'YData',p(:,2));
    elseif isfield(cmd,'Candidates') && ~isempty(cmd.Candidates)
        [x,y]=flattenCandidates(cmd.Candidates);
        p=toEgo([x y],d.ego,d.yaw);
        set(M.candidates,'XData',p(:,1),'YData',p(:,2));
    else
        set(M.candidates,'XData',NaN,'YData',NaN);
    end
    if isfield(cmd,'Trunk') && ~isempty(cmd.Trunk)
        p=toEgo(double(cmd.Trunk(:,1:2)),d.ego,d.yaw);
        set(M.trunk,'XData',p(:,1),'YData',p(:,2));
    else
        set(M.trunk,'XData',NaN,'YData',NaN);
    end
    if isfield(cmd,'Look') && numel(cmd.Look)>=2 && all(isfinite(cmd.Look(1:2)))
        p=toEgo(double(cmd.Look(1:2)),d.ego,d.yaw);
        set(M.look,'XData',p(1),'YData',p(2));
    else
        set(M.look,'XData',NaN,'YData',NaN);
    end
else
    set(M.candidates,'XData',NaN,'YData',NaN);
    set(M.trunk,'XData',NaN,'YData',NaN);
    set(M.look,'XData',NaN,'YData',NaN);
end
end

function showDetections(S,boxes,scores,labels,frameSize)
for k=1:S.maxDet
    set(S.detBox(k),'Visible','off');
    set(S.detText(k),'Visible','off');
end
if isempty(boxes), return; end
w=frameSize(2); h=frameSize(1);
insideW=max(0,min(boxes(:,1)+boxes(:,3),w)-max(boxes(:,1),1));
insideH=max(0,min(boxes(:,2)+boxes(:,4),h)-max(boxes(:,2),1));
keep=(insideW.*insideH)./max(boxes(:,3).*boxes(:,4),eps)>0.60;
boxes=boxes(keep,:); scores=scores(keep); labels=labels(keep);
n=min(S.maxDet,size(boxes,1));
for k=1:n
    b=boxes(k,:);
    b(1)=max(1,b(1)); b(2)=max(1,b(2));
    b(3)=min(b(3),w-b(1)); b(4)=min(b(4),h-b(2));
    colour=detectionColour(labels(k),S.C);
    set(S.detBox(k),'Position',b,'EdgeColor',colour,'Visible','on');
    label=upper(string(labels(k)))+sprintf(' %.0f%%',100*scores(k));
    textX=min(max(1,b(1)),max(1,w-92));
    set(S.detText(k),'Position',[textX max(1,b(2)-2) 0], ...
        'String',char(label),'BackgroundColor',colour,'Visible','on');
end
end

function [frame,xOffset] = cropToAspect(frame,targetAspect)
xOffset=0;
current=size(frame,2)/size(frame,1);
if current>targetAspect
    keep=max(1,round(targetAspect*size(frame,1)));
    first=max(1,floor((size(frame,2)-keep)/2)+1);
    frame=frame(:,first:first+keep-1,:);
    xOffset=first-1;
elseif current<targetAspect
    keep=max(1,round(size(frame,2)/targetAspect));
    first=max(1,floor((size(frame,1)-keep)/2)+1);
    frame=frame(first:first+keep-1,:,:);
end
end

function drawBackdrop(ax,C)
xl=xlim(ax); yl=ylim(ax);
patch(ax,[xl(1) xl(2) xl(2) xl(1)],[yl(1) yl(1) yl(2) yl(2)], ...
    [0.055 0.095 0.075],'EdgeColor','none');
rs=RandStream('twister','Seed',26037);
for side=[-1 1]
    for k=1:24
        x=side*(5+8*rand(rs)); y=yl(1)+(yl(2)-yl(1))*rand(rs);
        r=1.2+2.4*rand(rs); th=linspace(0,2*pi,12);
        col=[0.08 0.17 0.11]+0.06*rand(rs,1,3);
        patch(ax,x+r*cos(th),y+r*sin(th),min(col,[0.18 0.28 0.18]), ...
            'EdgeColor','none','FaceAlpha',0.95);
    end
end
for k=1:8
    side=2*(mod(k,2)==0)-1;
    x=side*(8.0+2.5*rand(rs)); y=yl(1)+(yl(2)-yl(1))*rand(rs);
    patch(ax,x+[-2 2 2 -2],y+[-3 -3 3 3],[0.20 0.22 0.21], ...
        'EdgeColor',[0.28 0.30 0.29],'LineWidth',0.5);
end
rectangle(ax,'Position',[xl(1) yl(1) diff(xl) diff(yl)], ...
    'EdgeColor',C.edge,'LineWidth',0.8);
end

function ax=mapAxes(parent,pos,xl,yl,C)
ax=axes('Parent',parent,'Position',pos,'Color',C.panel2,'XColor','none','YColor','none');
hold(ax,'on'); axis(ax,'equal'); xlim(ax,xl); ylim(ax,yl); ax.Clipping='on';
end

function setLocalObjects(h,tracks,ego,yaw)
n=numel(tracks);
if n==0
    set(h,'Faces',zeros(0,4),'Vertices',zeros(0,2),'FaceVertexCData',zeros(0,3));
    return
end
V=zeros(4*n,2); F=zeros(n,4); Cd=zeros(n,3);
for k=1:n
    p=toEgo(tracks(k).Position(1:2),ego,yaw);
    localYaw=double(tracks(k).Yaw)-yaw+pi/2;
    V(4*k-3:4*k,:)=boxCorners(p,localYaw,tracks(k).Extent(1),tracks(k).Extent(2));
    F(k,:)=4*k-3:4*k;
    Cd(k,:)=classColour(tracks(k).ClassID);
end
set(h,'Faces',F,'Vertices',V,'FaceVertexCData',Cd);
end

function updateLabels(M,tracks,ego,yaw)
for k=1:M.maxLabels, set(M.labels(k),'Visible','off'); end
n=min(M.maxLabels,numel(tracks));
for k=1:n
    p=toEgo(tracks(k).Position(1:2),ego,yaw);
    set(M.labels(k),'Position',[p(1) p(2)+tracks(k).Extent(1)/2+0.7 0], ...
        'String',sprintf('#%u',tracks(k).TrackID),'Visible','on');
end
end

function p=toEgo(xy,ego,yaw)
if isempty(xy), p=zeros(0,2); return; end
d=double(xy)-double(ego(:).');
left=[-sin(yaw) cos(yaw)]; fwd=[cos(yaw) sin(yaw)];
p=[d*left(:) d*fwd(:)];
end

function h=vehiclePatch(ax,colour)
h=patch(ax,nan(4,1),nan(4,1),colour,'EdgeColor',[.94 .97 .98],'LineWidth',1.2);
end

function setVehicle(h,c,yaw,L,W)
v=boxCorners(c,yaw,L,W);
set(h,'XData',v(:,1),'YData',v(:,2));
end

function V=boxCorners(c,yaw,L,W)
R=[cos(yaw) -sin(yaw);sin(yaw) cos(yaw)];
p=[L/2 W/2;L/2 -W/2;-L/2 -W/2;-L/2 W/2].';
V=(R*p+c(:)).';
end

function [x,y]=flattenCandidates(candidates)
x=[]; y=[];
for k=1:numel(candidates)
    g=candidates{k};
    if isempty(g), continue; end
    x=[x;g(:,1);NaN]; %#ok<AGROW>
    y=[y;g(:,2);NaN]; %#ok<AGROW>
end
end

function c=classColour(id)
switch double(id)
case 10, c=[0.93 0.27 0.24];
case 8,  c=[0.28 0.90 0.48];
case 4,  c=[1.00 0.72 0.12];
case 5,  c=[0.18 0.58 0.95];
case 1,  c=[0.75 0.78 0.80];
otherwise, c=[0.63 0.68 0.70];
end
end

function c=detectionColour(label,C)
s=lower(string(label));
if contains(s,"person")
    c=C.green;
elseif contains(s,"car") || contains(s,"truck") || contains(s,"bus")
    c=C.amber;
elseif contains(s,"motor") || contains(s,"bicycle")
    c=C.blue;
else
    c=[0.76 0.48 0.94];
end
end

function c=stateColour(state,C)
if contains(state,"EMERGENCY") || contains(state,"ABORT") || contains(state,"BLOCKED")
    c=C.red;
elseif contains(state,"PROBE") || contains(state,"CREEP") || contains(state,"HOLD")
    c=C.amber;
else
    c=C.green;
end
end

function panelFrame(fig,pos,C)
annotation(fig,'rectangle',pos,'Color',C.edge,'FaceColor','none');
end

function panelTitle(fig,pos,label)
annotation(fig,'textbox',pos,'String',label,'EdgeColor','none','Color',[0.77 0.82 0.84], ...
    'BackgroundColor',[0.026 0.048 0.058],'FontName','Arial','FontSize',8.5, ...
    'FontWeight','bold','VerticalAlignment','middle');
end

function label=scenarioLabel(titleText)
if contains(titleText,"DEMO3",'IgnoreCase',true) || contains(titleText,"GALLI",'IgnoreCase',true)
    label="GALLI · CONSTRAINED INDIAN ROAD · RECORDED MATLAB REPLAY";
else
    label="CATTLE CROSSING · INDIAN VILLAGE ROAD · OFFLINE/REPLAY";
end
end

function out=controls(S)
out=emptyControl(); out.Frames=S.frames; out.LastFrame_ms=S.lastFrame_ms;
if ~S.headless && isgraphics(S.fig)
    ctl=getappdata(S.fig,'ctl'); out.Paused=ctl.Paused; out.Quit=ctl.Quit;
end
end

function out=emptyControl()
out=struct('Paused',false,'Quit',false,'Frames',0,'LastFrame_ms',NaN, ...
    'InjectPending',false,'InjectXY',[NaN NaN]);
end

function onKey(fig,event)
ctl=getappdata(fig,'ctl');
switch lower(event.Key)
case 'space', ctl.Paused=~ctl.Paused;
case {'rightarrow','n'}, ctl.Paused=true; ctl.StepOnce=true;
case {'q','escape'}, ctl.Quit=true; ctl.Paused=false;
end
setappdata(fig,'ctl',ctl);
end

function onClose(fig,~)
ctl=getappdata(fig,'ctl'); ctl.Quit=true; ctl.Paused=false;
setappdata(fig,'ctl',ctl); delete(fig);
end

function v=getf(s,f,dflt)
if isstruct(s) && isfield(s,f) && ~isempty(s.(f)), v=s.(f); else, v=dflt; end
end
