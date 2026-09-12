function hud(S, d)
%HUD  The instrument strip: state, live numbers, the safety barrier, a locator.
%
%   THIS IS WHAT MAKES THE DEMO READ AS A PLANNER RATHER THAN AN ANIMATION.
%   A pretty render of a car going round a cow tells a judge nothing about the
%   algorithm. The same render with the gap MEASURED on the road and h = lambda - beta
%   plotted underneath tells them everything. Every number here comes from the run,
%   never from the written script.
%
%   d fields (all optional except State):
%     .State   string   PROBE | ABORT | COMMIT | CRUISE | STOPPED | EMERGENCY
%     .Note    string   one line of why
%     .Speed   double   m/s          .Gap     double  m free width
%     .Margin  double   m each side  .H       double  barrier value
%     .T       vector   time so far  .Hs      vector  barrier history
%     .Title   string   scenario label for the locator panel

arguments
    S sc.scene
    d struct
end

f = S.Fig;
delete(S.HudAx(isgraphics(S.HudAx))); S.HudAx = gobjects(0);

BG   = [0.13 0.14 0.17];
DIM  = [0.55 0.60 0.68];
BRIG = [0.92 0.94 0.97];
COL = struct('PROBE',[1 0.78 0.15], 'ABORT',[1 0.45 0.30], 'COMMIT',[0.35 0.95 0.55], ...
             'CRUISE',[0.55 0.80 1.0], 'STOPPED',[0.95 0.35 0.30], 'EMERGENCY',[1 0.25 0.25]);
st = char(d.State);
if isfield(COL, st), sc_ = COL.(st); else, sc_ = BRIG; end

% ---------------- opaque backing ----------------
% TWO TRAPS, both found by looking at a render:
%  1. `axis off` makes an axes background TRANSPARENT, so 'Color' alone does nothing.
%  2. The 3-D axes runs with Clipping off (so the sky is not sliced), which lets the
%     scene draw straight over the HUD strip.
% Both are cured by painting one opaque strip first, in its own axes, on top of the 3-D.
ab = axes(f,'Position',[0 0 1 S.HudFrac],'Color',BG,'XLim',[0 1],'YLim',[0 1]);
axis(ab,'off');
patch(ab,'XData',[0 1 1 0],'YData',[0 0 1 1],'FaceColor',BG,'EdgeColor','none');
patch(ab,'XData',[0 1 1 0],'YData',[0.985 0.985 1 1],'FaceColor',[0.22 0.24 0.29], ...
      'EdgeColor','none');                                   % a hairline above the strip

% ---------------- state ----------------
a1 = axes(f,'Position',[0.008 0.015 0.255 0.235],'Color',BG); axis(a1,'off');
panel(a1,[0.16 0.17 0.21]);
text(a1,0.04,0.84,'STATE','Color',DIM,'FontSize',10,'FontWeight','bold','Units','normalized');
text(a1,0.04,0.48,st,'Color',sc_,'FontSize',28,'FontWeight','bold','Units','normalized');
if isfield(d,'Note') && strlength(d.Note)>0
    text(a1,0.04,0.13,d.Note,'Color',[0.72 0.76 0.82],'FontSize',9,'Units','normalized', ...
         'Interpreter','none');
end

% ---------------- numbers ----------------
a2 = axes(f,'Position',[0.272 0.015 0.205 0.235],'Color',BG); axis(a2,'off');
panel(a2,[0.16 0.17 0.21]);
rows = {};
if isfield(d,'Speed'),  rows(end+1,:) = {'speed',    sprintf('%.1f km/h', 3.6*d.Speed)}; end
if isfield(d,'Gap')  && isfinite(d.Gap),    rows(end+1,:) = {'gap free', sprintf('%.2f m', d.Gap)}; end
if isfield(d,'Margin')&& isfinite(d.Margin),rows(end+1,:) = {'margin',   sprintf('%.2f m', d.Margin)}; end
% THE CHARTED QUANTITY IS NAMED BY THE CALLER. The Phase 1 HUD hardcoded
% "h = lambda - beta", the planner's safety barrier. The PLACEHOLDER DRIVER DOES NOT
% COMPUTE ONE, and putting a number under that label would be inventing a result.
% What the backup can honestly show is the clearance it MEASURED. When Stream D's
% planner takes the seat it passes its real h here and the label changes with it.
if isfield(d,'H')
    lbl = 'h = \lambda-\beta';
    if isfield(d,'HLabel'), lbl = d.HLabel; end
    if isfinite(d.H), rows(end+1,:) = {lbl, sprintf('%+.3f', d.H)};
    else,             rows(end+1,:) = {lbl, 'undefined'};   % NaN is not "safe"
    end
end
for k = 1:size(rows,1)
    y = 0.86 - (k-1)*0.235;
    text(a2,0.05,y,rows{k,1},'Color',DIM,'FontSize',9,'Units','normalized');
    text(a2,0.60,y,rows{k,2},'Color',BRIG,'FontSize',12,'FontWeight','bold','Units','normalized');
end

% ---------------- barrier chart ----------------
a3 = axes(f,'Position',[0.492 0.048 0.315 0.196],'Color',BG);
if isfield(d,'T') && numel(d.T)>1
    ref = 0;  if isfield(d,'ChartRef'), ref = d.ChartRef; end
    plot(a3,d.T,d.Hs,'-','Color',[0.35 0.85 1.0],'LineWidth',1.6); hold(a3,'on');
    yline(a3,ref,'-','Color',[0.95 0.35 0.30],'LineWidth',1.1);
    xlim(a3,[0 max(8,max(d.T))]);
    lo = min([ref-0.25, min(d.Hs,[],'omitnan')-0.1]);
    hi = max([ref+0.7,  max(d.Hs,[],'omitnan')+0.1]);
    if all(isfinite([lo hi])) && hi>lo, ylim(a3,[lo hi]); end
end
set(a3,'XColor',[0.45 0.5 0.58],'YColor',[0.45 0.5 0.58],'FontSize',8,'Box','off','Color',BG);
ct = 'safety barrier   h = \lambda - \beta';
if isfield(d,'ChartTitle'), ct = d.ChartTitle; end
title(a3, ct, 'Color',[0.72 0.76 0.82], 'FontSize',9,'FontWeight','normal');

% ---------------- locator ----------------
a4 = axes(f,'Position',[0.822 0.030 0.170 0.215],'Color',BG); axis(a4,'off');
panel(a4,[0.16 0.17 0.21]);
if isfield(d,'Route') && ~isempty(d.Route)
    R=d.Route;
    plot(a4,R(:,1),R(:,2),'-','Color',[0.45 0.50 0.58],'LineWidth',1.8); hold(a4,'on');
    if isfield(d,'Pos')
        plot(a4,d.Pos(1),d.Pos(2),'o','MarkerFaceColor',[1 0.78 0.15], ...
             'MarkerEdgeColor','none','MarkerSize',7);
    end
    axis(a4,'equal');
end
axis(a4,'off');
if isfield(d,'Title')
    text(a4,0.5,-0.04,d.Title,'Color',[0.62 0.66 0.72],'FontSize',8, ...
         'Units','normalized','HorizontalAlignment','center');
end

% ---------------- the comparison caption ----------------
% REF-17 s8. Three lines, and the MIDDLE one names the stand-in as OURS. PRD s8 warns
% that a tuned opponent is a rigged fight, and the caption is the defence against that
% charge - not our good intentions. Never let it read as MathWorks' planner.
if isfield(d,'Compare') && ~isempty(d.Compare)
    a5 = axes(f,'Position',[0.008 0.255 0.984 0.055],'Color',BG); axis(a5,'off');
    set(a5,'XLim',[0 1],'YLim',[0 1]);
    patch(a5,'XData',[0 1 1 0],'YData',[0 0 1 1],'FaceColor',[0.10 0.11 0.14], ...
          'EdgeColor','none');
    cc = d.Compare;
    for r = 1:size(cc,1)
        text(a5, 0.012, 0.80-(r-1)*0.33, cc{r,1}, 'Color',[0.62 0.66 0.72], ...
             'FontSize',9,'Units','normalized','Interpreter','none');
        text(a5, 0.235, 0.80-(r-1)*0.33, cc{r,2}, 'Color',cc{r,3}, ...
             'FontSize',9,'FontWeight','bold','Units','normalized','Interpreter','none');
    end
    S.HudAx = [ab a1 a2 a3 a4 a5];
else
    S.HudAx = [ab a1 a2 a3 a4];
end

end

% ---------------------------------------------------------------------------------------
function panel(ax, col)
%PANEL  An opaque card behind a HUD group. `axis off` alone leaves it see-through.
set(ax,'XLim',[0 1],'YLim',[0 1]);
patch(ax,'XData',[0 1 1 0],'YData',[0 0 1 1],'FaceColor',col,'EdgeColor','none');
end
