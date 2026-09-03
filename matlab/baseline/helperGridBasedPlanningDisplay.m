classdef helperGridBasedPlanningDisplay < matlab.System
    % This is a helper class and may be removed or modified in a future
    % release. This class implements the display for the motion planning in
    % urban environments using grid-based approaches. 
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties
        Figure
        FrontView
        GridView
        PredictionView
    end
    
    properties
        Record = false;
    end
    
    properties
        FigureSnapshots
        SnapshotTimes = 4.6;
    end
    
    properties (Access = protected)
        pFrames = {};
        DownsampleFactor = 2;
    end
    
    methods
        function obj = helperGridBasedPlanningDisplay(obj, varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods
        function snapnow(obj)
            if isPublishing(obj)
                panels = findall(obj.Figure,'Type','uipanel');
                f = copy(panels);
                obj.FigureSnapshots{end+1} = f;
            end
        end
        
        function fOut = showSnaps(obj, panelIdx, idx)
            fOut = [];
            if isPublishing(obj)
                if nargin == 1
                    idx = 1:numel(obj.FigureSnapshots);
                end

                fOut = gobjects(numel(idx),1);

                for i = 1:numel(idx)
                    f = figure('Units','normalized','Position',[0 0 0.8 0.8]);
                    copy(obj.FigureSnapshots{idx(i)}(panelIdx),f);
                    panel = findall(f,'Type','uipanel');
                    panel.Position = [0 0 1 1];
                    ax = findall(panel,'Type','Axes');
                    for k = 1:numel(ax)
                        ax(k).XTickLabelMode = 'auto';
                        ax(k).YTickLabelMode = 'auto';
                    end
                    uistack(panel,'top');
                    fOut(i) = f;
                end
            end
        end
        
        function writeAnimation(obj, fName, delay)
            if nargin == 2
                delay = 0;
            end
            obj.DownsampleFactor = 2;
            if obj.Record
                frames = obj.pFrames;
                imSize = size(frames{1}.cdata);
                im = zeros(imSize(1),imSize(2),1,floor(numel(frames)/obj.DownsampleFactor),'uint8');
                map = [];
                count = 1;
                for i = 1:obj.DownsampleFactor:numel(frames)
                    if isempty(map)
                        [im(:,:,1,count),map] = rgb2ind(frames{i}.cdata,256,'nodither');
                    else
                        im(:,:,1,count) = rgb2ind(frames{i}.cdata,map,'nodither');
                    end
                    count = count + 1;
                end
                imwrite(im,map,[fName,'.gif'],'DelayTime',delay,'LoopCount',inf);
            end
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, varargin)
            obj.Figure = figure('Units','normalized','Position',[0 0 1 0.8]);
            obj.Figure.Units = 'pixels';
            obj.Figure.Position(3) = 3/2*obj.Figure.Position(4);
            obj.Figure.Units = 'normalized';
            
            if isPublishing(obj)
                obj.Figure.Visible = 'off';
            end
            
            obj.FrontView = createFrontView(obj,obj.Figure);
            
            tracker = varargin{5};
            obj.GridView = createGridView(obj,obj.Figure);
            setup(obj.GridView,varargin{1:end-1});
            showDynamicMap(tracker, 'Parent', obj.GridView.Axes,'InvertColors',true);
            view(obj.GridView.Axes,-90,90);
            obj.GridView.Axes.OuterPosition = [0 0 1 1];
            obj.PredictionView = createPredictionView(obj,obj.Figure);
        end
        
        function stepImpl(obj, varargin)
            obj.FrontView(varargin{1:end-1});
            obj.GridView(varargin{1:end-1});
            tracker = varargin{5};
            validator = varargin{end};
            showDynamicMap(tracker, 'Parent', obj.GridView.Axes,'InvertColors',true);
            trajectories = varargin{end-1};
            optimalTraj = trajectories([trajectories.IsOptimal]);
            scenario = varargin{1};
            ego = scenario.Actors(1);
            showPredictions(validator,[1;7;15;20],ego,optimalTraj,obj.PredictionView);
            takeSnapshots(obj, varargin{1});
            if obj.Record
                obj.pFrames{end+1} = getframe(obj.Figure);
            end
        end
        
        function frontView = createFrontView(~, fig)
            p1 = uipanel(fig,'Units','normalized','Position',[0 1/2 1/2 1/2],...
                'Title','Ground truth - Front View');
            
            frontView = helperGridPlanningDisplayPanel('Parent',p1,...
                'ViewLocation',[-30.75 0 20],...,...[0 0 75]
                'ViewAngles',[0 20 0],...[0 90 0],...
                'PlotCoverage',false,...
                'PlotPointClouds',false,...
                'PlotTrajectory',[true false false false],...% Only optimal
                'PlotTracks',false,...
                'ShowLegend',false);
        end
        
        function gridView = createGridView(~,fig)
            p4 = uipanel(fig,'Units','normalized','Position',[1/2 1/2 1/2 1/2],...
                'Title','Dynamic Map Estimate');
            
            gridView = helperGridPlanningDisplayPanel('Parent',p4,...
                'ViewLocation',[0 0 160],...
                'ViewAngles',[0 90 0],...
                'PlotTruth',false,...
                'PlotRoads',false,...
                'PlotCoverage',false,...
                'DarkMode',true,...
                'PanWithEgo',false,...
                'PlotPointClouds',false,...
                'PlotCoverage',false,...
                'PlotTrajectory',[true false false false],...% Only optimal
                'PlotTracks',false,...
                'ReferenceEgo',true);
        end
        
        function predictionView = createPredictionView(~,fig)
            predictionView = uipanel(fig,'Units','normalized','Position',[0 0 1 1/2],...
                'Title','Predicted Cost Maps',...
                'BackgroundColor',0.157*[1 1 1],...
                'ForegroundColor',[1 1 1]);
        end
        
        function takeSnapshots(obj, scenario)
            time = scenario.SimulationTime;
            if any(abs(time - obj.SnapshotTimes) < 1e-3)
                snapnow(obj);
            end
        end
        
        function tf = isPublishing(~)
            tf = false;
            try
                s = numel(dbstack);
                tf = s > 5;
            catch
            end
        end
    end
end