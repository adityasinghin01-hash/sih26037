classdef helperGridPlanningDisplayPanel < matlab.System
    % This is a helper class and may be removed or modified in a future
    % release.
    
    % This class provides the display for a single panel of the dynamic
    % grid-based planning example
    
    properties
        TrackPlotterPatch
        Resolution
    end
    
    properties
        SnapInformation
        Snapshots
    end
    
    properties
        ScenarioPlotter
        TrackPlotter
        CoveragePlotter
        PointCloudPlotter
        ViewAngles = [0 90 0];
        ViewLocation = [0 0 30];
        PanWithEgo = true;
        ReferenceEgo = false;
    end
    
    properties
        OptimalTrajectoryPlotter
        CollidingTrajectoryPlotter
        FeasibleTrajectoryPlotter
        InfeasibleTrajectoryPlotter
    end
    
    properties
        ColorOrder;
        GroundTruthColorIndex = 0;
        TrackColorIndex = 2;
        CoverageColorIndex = 2;
    end
    
    properties
        Parent
        Axes
        DarkMode = false;
    end
    
    properties
        SensorToPlot = true(6,1);
        ShowLegend = false;
    end
    
    properties
        PlotPointClouds = true;
        PlotCoverage = true;
        PlotTracks = true;
        PlotTruth = true;
        PlotRoads = true;
        PlotTrajectory = true(1,4);
    end
    
    methods
        function obj = helperGridPlanningDisplayPanel(varargin)
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, scenario, egoVehicle, lidars, ptCloud, tracker, tracks) %#ok<INUSD,INUSL>
            if obj.DarkMode
                obj.ColorOrder = darkColorOrder;
            else
                obj.ColorOrder = standardColorOrder;
            end
            
            if nargin > 5
                obj.Resolution = tracker.GridResolution;
            end
            
            if isempty(obj.Parent)
                fig = figure('Units','normalized','Position',[0 0 0.9 0.9]);
                obj.Parent = fig;
            end
            
            ax = axes(obj.Parent);
            
            if obj.DarkMode  %Dark-mode
                if isa(obj.Parent,'matlab.ui.Figure')
                    obj.Parent.Color = 0.157*[1 1 1];
                elseif isa(obj.Parent,'matlab.ui.container.Panel')
                    obj.Parent.BackgroundColor = 0.157*[1 1 1];
                    obj.Parent.ForegroundColor = [1 1 1];
                end
                ax.Color = [0 0 0];
                grid(ax,'on');
                ax.GridColor = 0.68*[1 1 1];
                ax.GridAlpha = 0.4;
                axis(ax,'equal');
                ax.XColor = [1 1 1]*0.68;
                ax.YColor = [1 1 1]*0.68;
                ax.ZColor = [1 1 1]*0.68;
            else
                if isa(obj.Parent,'matlab.ui.container.Panel')
                    obj.Parent.BackgroundColor = [1 1 1];
                end
            end
            
            obj.Axes = ax;
            if obj.PanWithEgo || obj.PlotTruth || obj.PlotRoads
                obj.ScenarioPlotter = driving.scenario.Plot('EgoActor',egoVehicle,...
                    'Parent',ax,'Meshes','on',...
                    'ViewLocation',[obj.ViewLocation(1) obj.ViewLocation(2)],...
                    'ViewHeight',obj.ViewLocation(3),...
                    'ViewRoll',obj.ViewAngles(3),...
                    'ViewPitch',obj.ViewAngles(2),...
                    'ViewYaw',obj.ViewAngles(1));
                
                if obj.GroundTruthColorIndex > 0
                    for i = 2:numel(scenario.Actors)
                        scenario.Actors(i).PlotColor = obj.ColorOrder(obj.GroundTruthColorIndex,:);
                    end
                end
                
                l  = legend(ax);
                l.AutoUpdate = 'off';
                obj.ScenarioPlotter.plotActors(scenario.Actors)
                allPatches = findall(ax,'Type','Patch');
                allTags = arrayfun(@(x)x.Tag,allPatches,'UniformOutput',false);
                actorPatches = allPatches(startsWith(allTags,'ActorPatch'));
                
                
                if obj.PlotPointClouds
                    for i = 1:numel(actorPatches)
                        actorPatches(i).FaceAlpha = 0.3;
                        actorPatches(i).EdgeAlpha = 0.1;
                    end
                end
                
                if obj.PlotRoads
                    obj.ScenarioPlotter.plotRoads(scenario.RoadTiles, roadBoundaries(scenario),scenario.RoadCenters,scenario.ShowRoadBorders);
                    roadPatches = findall(ax,'Tag','RoadTilesPatch');
                    for i = 1:numel(roadPatches)
                        if obj.DarkMode
                            roadPatches(i).FaceColor = [0.1 0.1 0.1];
                            roadPatches(i).EdgeColor = [0 0 0];
                        end
                    end
                end
            end
            
            l.AutoUpdate = 'on';
            
            tp = theaterPlot('Parent',ax);
            bep = birdsEyePlot('Parent',ax);
            
            if obj.PlotTracks
                obj.TrackPlotter = trackPlotter(tp,'DisplayName','Tracks',...
                    'Marker','none',...
                    'MarkerFaceColor',obj.ColorOrder(obj.TrackColorIndex,:),...
                    'MarkerEdgeColor',obj.ColorOrder(obj.TrackColorIndex,:),...
                    'LabelOffset',[-3 0 2]);
                sampleTrk = struct('TrackID',nan,'State',nan(7,1),'StateCovariance',eye(7));
                [pos, vel, dim, orient, dims] = parseTracks(sampleTrk);
                obj.TrackPlotter.plotTrack(pos, vel, dim, orient, dims, {'nan'});
                h = findall(ax,'Tag','tpTrackExtent');
                h.LineWidth = 2;
                obj.TrackPlotterPatch = h;
            end
            
            if obj.PlotCoverage
                cvPlotters = cell(6,1);
                
                c = obj.ColorOrder;
                idx = [1 2 3 4 2 3];
                idx(:) = obj.CoverageColorIndex;
                cvColors = c(idx,:);
                
                for i = 1:6
                    if i == 1
                        displayName = 'Lidar coverage';
                    else
                        displayName = '';
                    end
                    cvPlotters{i} = coverageAreaPlotter(bep,'FaceColor',cvColors(i,:),'EdgeColor',cvColors(i,:),....
                        'DisplayName',displayName,'FaceAlpha',0);
                end
                obj.CoveragePlotter = cvPlotters;
            end
            
            l.AutoUpdate = 'on';
            if obj.PlotPointClouds
                hold(ax,'on');
                obj.PointCloudPlotter = scatter3(ax,nan,nan,nan,'.','DisplayName','Point clouds',...
                    'SizeData',1);
            end
            
            
            if any(obj.PlotTrajectory)
                trajColors = [0 1 0;1 0 0;1 1 1;0 0 0];
                hold(ax,'on')
                if obj.PlotTrajectory(1)
                    obj.OptimalTrajectoryPlotter = plot(nan,nan,'-.','LineWidth',2,'Color',trajColors(1,:));
                end
                if obj.PlotTrajectory(2)
                    obj.CollidingTrajectoryPlotter = plot(nan,nan,'-.','LineWidth',1,'Color',trajColors(2,:));
                end
                if obj.PlotTrajectory(3)
                    obj.FeasibleTrajectoryPlotter = plot(nan,nan,'-.','LineWidth',1,'Color',trajColors(3,:));
                end
                if obj.PlotTrajectory(4)
                    obj.InfeasibleTrajectoryPlotter = plot(nan,nan,'-.','LineWidth',1,'Color',trajColors(4,:));
                end
            end
            
            l = legend(ax);
            l.TextColor = 1 - ax.Color;
            l.Location = 'best';
            colormap(ax,'parula');
            
            if ~obj.ShowLegend
                l.delete;
            end
        end
        
        function stepImpl(obj, scenario, egoVehicle, lidars, ptCloud, tracker, tracks, trajectories)
            if obj.PlotTruth
                obj.ScenarioPlotter.plotActors(scenario.Actors);
            elseif ~isempty(obj.ScenarioPlotter)
                obj.ScenarioPlotter.plotActors(driving.scenario.Actor.empty(0,1));
            end
            
            if obj.PlotCoverage
                updateCoveragePlotters(obj, lidars, egoVehicle);
            end
            
            if obj.PlotTracks
                % Update track display
                pos = parseSensorModel(obj,lidars{1},egoVehicle);
                if obj.ReferenceEgo
                    tracks = transformToEgo(tracks,egoVehicle);
                end
                [pos, vel, dim, orient, ids] = parseTracks(tracks,0);
                obj.TrackPlotter.plotTrack(pos,vel,dim,orient,ids);
            end
            
            if obj.PlotPointClouds
                % Plot point cloud. Assuming each ptCloud is reported in the
                % sensor's coordinate frame
                updatePointCloudPlotter(obj, lidars(obj.SensorToPlot), egoVehicle, ptCloud(obj.SensorToPlot));
            end
            
            if any(obj.PlotTrajectory)
                updateTrajectories(obj, trajectories, egoVehicle)
            end
        end
        
        function updatePointCloudPlotter(obj, lidars, egoVehicle, ptClouds)
            xyz = zeros(3,0);
            for i = 1:numel(lidars)
                thisPtCloud = ptClouds{i};
                loc = reshape(thisPtCloud.Location,[],3);
                [pos, orient] = parseSensorModel(obj, lidars{i}, egoVehicle);
                loc = rotatepoint(orient,loc)' + pos;
                xyz = [xyz loc];
            end
            set(obj.PointCloudPlotter,'XData',xyz(1,:),'YData',xyz(2,:),'ZData',xyz(3,:),'CData',xyz(3,:));
        end
        
        function updateTrajectories(obj, trajectories, egoVehicle)
            if obj.ReferenceEgo
                trajectories = globalToLocalTrajectory(trajectories, getGlobalState(egoVehicle));
            end
            isFeasible = vertcat(trajectories.IsFeasible);
            isColliding = vertcat(trajectories.IsColliding);
            isOptimal = vertcat(trajectories.IsOptimal);
            optimalTrajectory = trajectories(isOptimal);
            collidingTrajectories = trajectories(isColliding);
            infeasibleTrajectories = trajectories(~isFeasible);
            feasibleTrajectories = trajectories(isFeasible & ~isColliding & ~isOptimal);
            if obj.PlotTrajectory(1)
                updateTrajectoryPlotter(obj, obj.OptimalTrajectoryPlotter,optimalTrajectory);
            end
            if obj.PlotTrajectory(2)
                updateTrajectoryPlotter(obj, obj.CollidingTrajectoryPlotter,collidingTrajectories);
            end
            if obj.PlotTrajectory(3)
                updateTrajectoryPlotter(obj, obj.FeasibleTrajectoryPlotter,feasibleTrajectories);
            end
            if obj.PlotTrajectory(4)
                updateTrajectoryPlotter(obj, obj.InfeasibleTrajectoryPlotter,infeasibleTrajectories);
            end
        end
        
        function updateTrajectoryPlotter(obj, plotter, trajs)
            x = zeros(0,1);
            y = zeros(0,1);
            for i = 1:numel(trajs)
                x = [x;trajs(i).Trajectory(:,1);nan];
                y = [y;trajs(i).Trajectory(:,2);nan];
            end
            plotter.XData = x;
            plotter.YData = y;
        end
        
        function updateCoveragePlotters(obj, lidars, egoVehicle)
            cvPlotters = obj.CoveragePlotter;
            for i = 1:numel(cvPlotters)
                [pos, orient, fov, maxRange] = parseSensorModel(obj, lidars{i}, egoVehicle);
                ypr = eulerd(orient,'ZYX','frame');
                cvPlotters{i}.plotCoverageArea(pos(1:2)',5,ypr(1),diff(fov));
            end
        end
        
        function tf = isPublishing(~)
            tf = false;
            try
                s = numel(dbstack);
                tf = s > 6;
            catch
            end
        end
        
        function [pos, orient, fov, maxRange] = parseSensorModel(obj, lidar, ego)
            if ~obj.ReferenceEgo
                position = ego.Position;
                orientation = quaternion([ego.Yaw ego.Pitch ego.Roll],'eulerd','ZYX','frame');
                scene2plat = rotmat(orientation,'frame');
            else
                position = zeros(1,3);
                orientation = quaternion.ones(1);
                scene2plat = eye(3);
            end
            
            pos = position(:) + scene2plat'*[lidar.SensorLocation(:);lidar.Height];
            
            plat2sens = quaternion([lidar.Yaw lidar.Pitch lidar.Roll],'eulerd','ZYX','frame');
            orient = plat2sens*orientation;
            
            fov = lidar.AzimuthLimits;
            
            maxRange = lidar.MaxRange;
        end
    end
end

function [pos, vel, dim, orient,ids] = parseTracks(tracks, h)
dim = struct('Length',1,'Width',1,'Height',1,'OriginOffset',[0 0 0]);
orient = quaternion.ones(numel(tracks),1);

if nargin == 1
    h = 0;
end

if isempty(tracks)
    pos = zeros(0,3);
    vel = zeros(0,3);
    dim = repmat(dim,0,1);
    orient = quaternion.empty(0,1);
    ids = string.empty(0,1);
    return;
end

state = horzcat(tracks.State);
pos = [state([1 3],:);zeros(1,numel(tracks))];
vel = [state([2 4],:);zeros(1,numel(tracks))];
pos = pos';
vel = vel';
for i = 1:numel(tracks)
    pos(i,3) = h;
    dim(i).Length = state(6,i);
    dim(i).Width = state(7,i);
    dim(i).Height = 0;
    dim(i).OriginOffset = [0 0 0];
    orient(i) = quaternion([state(5,i) 0 0],'eulerd','ZYX','frame');
end
ids = strcat("T",string([tracks.TrackID]));
end

function colorOrder = darkColorOrder
colorOrder = [1.0000    1.0000    0.0667
    0.0745    0.6235    1.0000
    1.0000    0.4118    0.1608
    0.3922    0.8314    0.0745
    0.7176    0.2745    1.0000
    0.0588    1.0000    1.0000
    1.0000    0.0745    0.6510];

colorOrder(8,:) = [1 1 1];
colorOrder(9,:) = [0 0 0];
colorOrder(10,:) = 0.7*[1 1 1];
end

function colorOrder = standardColorOrder
colorOrder = lines(7);
colorOrder(8,:) = [0 0 0];
colorOrder(9,:) = [1 1 1];
colorOrder(10,:) = 0.3*[1 1 1];
end


function tracksEgo = transformToEgo(tracks, ego)
tracksEgo = tracks;
for i = 1:numel(tracks)
    posGlobal = [tracks(i).State([1 3]);0];
    velGlobal = [tracks(i).State([2 4]);0];
    speedGlobal = norm(velGlobal);
    yawGlobal = tracks(i).State(5);
    posEgo = ego.Position';
    yawEgo = ego.Yaw;
    q = quaternion([yawEgo 0 0],'eulerd','ZYX','frame');
    posWrtEgo = rotateframe(q,(posGlobal - posEgo)');
    yawWrtEgo = yawGlobal - yawEgo;
    tracksEgo(i).State([1 3]) = posWrtEgo(1:2);
    tracksEgo(i).State([2 4]) = speedGlobal*[cosd(yawWrtEgo) sind(yawWrtEgo)];% Only direction is transformed
    tracksEgo(i).State(5) = yawWrtEgo;
end
end

function state = getGlobalState(egoVehicle)
state = zeros(1,6);
state(1:2) = egoVehicle.Position(1:2);
state(3) = deg2rad(egoVehicle.Yaw);
state(5) = sqrt(sum(egoVehicle.Velocity(1:2).^2));
if state(5) > 0
    state(4) = egoVehicle.AngularVelocity(3)/state(5);
else
    state(4) = 0;
end
state(6) = egoVehicle.Acceleration(1);
end

function gridTrajectory = globalToLocalTrajectory(trajectory, currentEgoState)
states = concatenateTrajectories(trajectory);
statesLocal = globalToLocalStates(states, currentEgoState);
gridTrajectory = trajectory;
for i = 1:numel(gridTrajectory)
    gridTrajectory(i).Trajectory = statesLocal(:,:,i);
end
end

function states = concatenateTrajectories(trajectories)
length = arrayfun(@(x)size(x.Trajectory,1),trajectories);
maxLength = max(length);
states = nan(maxLength,6,numel(trajectories));
for i = 1:numel(trajectories)
    states(1:length(i),:,i) = trajectories(i).Trajectory;
end
end

function statesMap = globalToLocalStates(states, currentEgoState)
xEgo = currentEgoState(1);
yEgo = currentEgoState(2);
yawEgo = currentEgoState(3);
REgo = [cos(yawEgo) sin(yawEgo);-sin(yawEgo) cos(yawEgo)];
x = states(:,1,:);
y = states(:,2,:);
dx = x - xEgo;
dy = y - yEgo;
xEgo = dx*REgo(1,1) + dy*REgo(1,2);
yEgo = dx*REgo(2,1) + dy*REgo(2,2);
xyEgo = cat(2,xEgo,yEgo);
thetaEgo = states(:,3,:) - yawEgo;
statesMap = [xyEgo thetaEgo];
end



