classdef HelperDynamicMapValidator < matlab.System & nav.StateValidator
    % This is a helper class and may be removed or modified in a future
    % release. This class provides a validator for planning with dynamic
    % occupancy grid estimate obtained by trackerGridRFS. 
    
    % This class implements a custom nav.StateValidator object to validate
    % trajectories against predicted occupancies obtained using the
    % grid-based tracker, trackerGridRFS> 
    
    properties
        % trackerGridRFS object for predicting occupancy
        Tracker
        
        % Threshold for declaring a cell obstacle in the map at different
        % steps
        OccupiedThreshold
        
        % Maximum time horizon for validating trajectories
        MaxTimeHorizon = 2;
        
        % Time Resolution of the trajectories. Must be same as the
        % trajectoryGeneratorFrenet object used to sample trajectories.
        TimeResolution = 0.1;
        
        % Dimensions of the ego vehicle
        VehicleDimensions = vehicleDimensions(4.7,1.8);
        
        % Current state of the ego vehicle
        CurrentEgoState = zeros(1,6);
        
        % multiLayerMap storing cost maps for the future time steps
        FutureCostMaps
        
        % Current time
        CurrentTime
        
        % Valid duration of a prediction to reduce number of prediction
        % steps required from the tracker
        ValidPredictionSpan = 5;
    end
    
    properties (Access = protected)
        NumLayers
        TimeSteps
        VehicleOffset
        RectangularProfile
    end
    
    methods
        function obj = HelperDynamicMapValidator(varargin)
            obj@nav.StateValidator(stateSpaceSE2);
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj, currentEgoState, map, time) %#ok<INUSD,INUSL>
            % Setup the validator during first call to the step function
            
            % The tracker must be locked before this step
            assert(isLocked(obj.Tracker),...
                'tracker must be stepped at least once before using this object');
            
            % Time steps into the future
            obj.TimeSteps = obj.TimeResolution:obj.TimeResolution:obj.MaxTimeHorizon;
            
            % Number of cost map layers
            numCostmapLayers = numel(obj.TimeSteps);
            defaultVal = cast(0,'like',map.getOccupancy([0 0],'local'));
            
            % Define the multiLayerMap to store cost maps
            layers = cell(numCostmapLayers,1);
            tracker = obj.Tracker;
            for i = 1:numCostmapLayers
                layers{i} = mapLayer(tracker.GridLength,tracker.GridWidth,2,...
                    'Resolution',tracker.GridResolution,...
                    'GridOriginInLocal',tracker.GridOriginInLocal,...
                    'LayerName',num2str(i),...
                    'DefaultValue',defaultVal);
            end
            obj.FutureCostMaps = multiLayerMap(layers);
            
            % Set bounds of the state space
            obj.StateSpace.StateBounds = [obj.FutureCostMaps.XLocalLimits;obj.FutureCostMaps.YLocalLimits;-pi pi];
            
            % Threshold for declaring a cell dynamic decreases with time
            % due to uncertainty.
            obj.OccupiedThreshold = linspace(0.7,0.55,numCostmapLayers);
            
            % Store vehicle offset in the x direction
            L = obj.VehicleDimensions.Length;
            R = obj.VehicleDimensions.RearOverhang;
            W = obj.VehicleDimensions.Width;
            obj.VehicleOffset = L/2 - R;
            
            % Store rectangular profile for visualization
            obj.RectangularProfile = [-L/2 W/2;-L/2 -W/2;L/2 -W/2;L/2 W/2;-L/2 W/2] + [L/2 - R 0];
        end
        
        function stepImpl(obj, currentEgoState, map, time)
            % Store the current time
            obj.CurrentTime = time;
            
            % Time stamps of the future time
            timeStamps = time + obj.TimeSteps;
            
            % Set the current ego state
            obj.CurrentEgoState = currentEgoState;
            
            % Get handle of the tracker object
            tracker = obj.Tracker;
            
            % Use uncertainty free prediction in terms of process, birth
            % and death by setting properties of the tracker
            Q = tracker.ProcessNoise;
            F = tracker.FreeSpaceDiscountFactor;
            d = tracker.DeathRate;            
            tracker.ProcessNoise(:) = 0;
            tracker.FreeSpaceDiscountFactor = 1;
            tracker.DeathRate = 0;
            
            % For each time stamp, store a cost map
            for i = 1:numel(timeStamps)
                % Need new prediction with obj.ValidPredictionSpan steps
                if mod(i-1,obj.ValidPredictionSpan) == 0
                    % map is the dynamicEvidentialGridMap estimate
                    map = predictMapToTime(tracker, timeStamps(i),'WithStateAndCovariance', false);
                    
                    % Obtained cost map from dynamic map estimate
                    costMapData = mapToCostTheta(obj, map, i);
                end
                setMapData(obj.FutureCostMaps,num2str(i),costMapData);
            end
            
            % Predict map back to current time for visualization outside
            % the validator
            predictMapToTime(tracker,time,'WithStateAndCovariance',false);
            
            % Restore properties of the tracker for regular step call
            tracker.ProcessNoise = Q;
            tracker.FreeSpaceDiscountFactor = F;
            tracker.DeathRate = d;
        end
        
        function mapData = mapToCostTheta(obj, map, i)
            % This function converts the dynamic map estimate to a
            % representative cost map.
            P_occ = map.getOccupancy();
            
            % Get list of occupied cells
            isOccupied = P_occ > obj.OccupiedThreshold(i);
            
            % Circumscribed radius for inflation
            L = obj.VehicleDimensions.Length;
            W = obj.VehicleDimensions.Width;
            inscribedRadius = min(L/2,W/2);
            
            % Use bwdist for radius map calculation and closest object
            % index
            [distMap, idx] = bwdist(isOccupied);
            thetaMap = reshape(idx,map.GridSize);
            distMap = distMap/map.GridResolution;
            
            % Choose an inflation radius. Inflation happens from inscribed
            % radius fo inflation radius
            inflationRadius = 5;
            
            % Convert range to cost. 
            costValues = rangeToCostFcn(distMap, inscribedRadius, inflationRadius);
            thetaValues = thetaMap;
            mapData = cat(3,double(costValues),double(thetaValues));
        end
    end
    
    % Custom state validator methods
    methods
        function obj2 = copy(obj)
            obj2 = clone(obj);
        end
        
        function [tf, cost, tfDetailed, costDetailed] = isStateValid(obj,states)
            mapStates = globalToLocalStates(states, obj.CurrentEgoState);
            [tf, cost, tfDetailed, costDetailed] = checkCollision(obj, mapStates);
        end
        
        function [tf, cost, tfDetailed, costDetailed] = isTrajectoryValid(obj, globalTrajectories)
            states = concatenateTrajectories(globalTrajectories);
            [tf, cost, tfDetailed, costDetailed] = isStateValid(obj,states);
        end
        
        function tf = isMotionValid(obj,varargin)
            % Dummy implementation
        end
    end
    
    % Method to visualize validator's steps
    methods
        function showPredictions(obj, stepsToShow, ego, trajectories, parent)
            n = numel(stepsToShow);
            
            % Concatenate trajectories and transform them to local
            % coordinates
            states = concatenateTrajectories(trajectories);
            mapStates = globalToLocalStates(states, obj.CurrentEgoState);
            
            % Collect all trajectories x, y to plot on single line
            xTotal = zeros(0,1);
            yTotal = zeros(0,1);
            for i = 1:numel(trajectories)
                xTraj = mapStates(:,1,i);
                xTraj = xTraj(:);
                yTraj = mapStates(:,2,i);
                yTraj = yTraj(:);
                xTotal = [xTotal;xTraj;nan];
                yTotal = [yTotal;yTraj;nan];
            end
            
            % Loop through each step, create and update plots
            for i = 1:n
                % Tag of the axes
                tag = ['mapPredictionAxes',num2str(stepsToShow(i))];
                
                % Find axes, if empty, create one
                hAx = findall(parent,'Type','Axes','Tag',tag);
                if isempty(hAx)
                    hAx = axes(parent); %#ok<LAXES>
                end
                
                % Plot road boundaries
                hLaneBoundaries = findall(hAx,'Type','Line','Tag','LaneBoundaries');
                if isempty(hLaneBoundaries)
                    hLaneBoundaries = plot(nan,nan,'-','LineWidth',2,'Color',0.7*[1 1 1],'Tag','LaneBoundaries');
                end
                lb = roadBoundaries(ego);
                hLaneBoundaries.XData = lb{1}(:,1);
                hLaneBoundaries.YData = lb{1}(:,2);
                
                % Find image, if empty, create one
                hImage = findall(hAx,'Type','Image','Tag','Prediction');
                
                data = getMapData(obj.FutureCostMaps,num2str(stepsToShow(i)));
                
                if isempty(hImage)
                    % Create image if not presente
                    hold on;
                    hImage = imagesc(hAx,data(:,:,1));
                    
                    % Set the appropriate properties for visualization
                    hImage.XData = [obj.FutureCostMaps.XLocalLimits(1) + 1/obj.FutureCostMaps.Resolution obj.FutureCostMaps.XLocalLimits(2) + 1/obj.FutureCostMaps.Resolution];
                    hImage.YData = [obj.FutureCostMaps.YLocalLimits(2) + 1/obj.FutureCostMaps.Resolution obj.FutureCostMaps.YLocalLimits(1) - 1/obj.FutureCostMaps.Resolution];
                    hImage.Tag = 'Prediction';
                    view(hAx,-90,90);
                    hAx.DataAspectRatio = [1 1 1];
                    hAx.XLim = obj.FutureCostMaps.XLocalLimits;
                    hAx.YLim = obj.FutureCostMaps.YLocalLimits;
                    hAx.ZLim = [-100 100];
                    hAx.YDir = 'normal';
                    hAx.Tag = tag;
                    
                    % Plot grid on axes
                    costmaps = obj.FutureCostMaps;
                    xLim = [nan costmaps.XLocalLimits(1):20/costmaps.Resolution:costmaps.XLocalLimits(2) nan];
                    yLim = [nan costmaps.YLocalLimits(1):20/costmaps.Resolution:costmaps.YLocalLimits(2) nan];
                    [X, Y] = meshgrid(xLim,yLim);
                    x1 = X(:);
                    y1 = Y(:);
                    X = X';
                    Y = Y';
                    x2 = X(:);
                    y2 = Y(:);
                    hTraj = plot([x1;x2],[y1;y2],'-');
                    hTraj.Color = [1*ones(1,3) 0.5];
                    
                    % Thicker boundary
                    h2Box = plot(costmaps.XLocalLimits([1 2 2 1 1]), costmaps.YLocalLimits([1 1 2 2 1]));
                    h2Box.LineWidth = 2;
                    h2Box.Color = 1*ones(1,3);
                    
                    % Axes color
                    hAx.XAxis.Color = [1 1 1];
                    hAx.YAxis.Color = [1 1 1];
                    
                    % No ticks are shown
                    hAx.XTick = [];
                    hAx.YTick = [];
                    
                    % Set title as DT = x seconds
                    title(hAx,['$\Delta$T = ',num2str(obj.TimeSteps(stepsToShow(i)))],'interpreter','latex','Color',[1 1 1]);
                    
                    % Position the axes on the parent
                    hAx.Position = [0.05 + 0.9*(i-1)/n 0 0.9/n 1];
                end
                
                % Set hImage data
                hImage.CData = data(:,:,1);
                
                % Create trajectories on each plot
                h1 = findall(hAx,'Type','Line','Tag','validatorTrajectories');
                if isempty(h1)
                    h1 = plot(hAx,nan,nan,'-.','LineWidth',3,'Color',[0 1 0]);
                    h1.Tag = 'validatorTrajectories';
                end
                
                % Update trajectory plot
                h1.XData = xTotal;
                h1.YData = yTotal;
                
                % Update point on the trajectory if exists at this time
                if stepsToShow(i) <= size(mapStates,1)
                    xPoint = reshape(mapStates(stepsToShow(i),1,:),[],1);
                    yPoint = reshape(mapStates(stepsToShow(i),2,:),[],1);
                    thetaPoint = reshape(mapStates(stepsToShow(i),3,:),[],1);
                    
                    profile = zeros(0,2);
                    for profIdx = 1:numel(thetaPoint)
                        % Update the ego vehicles profile on the plot
                        R = [cos(thetaPoint(profIdx)) sin(thetaPoint(profIdx));-sin(thetaPoint(profIdx)) cos(thetaPoint(profIdx))];
                        thisP = obj.RectangularProfile*R + [xPoint(profIdx) yPoint(profIdx)];
                        profile = [profile;thisP;nan(1,2)];
                    end
                else
                    xPoint = nan;
                    yPoint = nan;
                    profile = nan(1,2);
                end
                
                hPt = findall(hAx,'Type','Line','Tag','validatorTrajectoriesPoint');
                if isempty(hPt)
                    hPt = plot(hAx,nan,nan,'.','Color',[0 1 0],'MarkerSize',20);
                    hPt.Tag = 'validatorTrajectoriesPoint';
                end
                hPt.XData = xPoint;
                hPt.YData = yPoint;
                
                hProf = findall(hAx,'Type','Line','Tag','validatorTrajectoriesEgoProfile');
                if isempty(hProf)
                    hProf = plot(hAx,nan,nan,'-','Color',[0 1 0],'LineWidth',2);
                    hProf.Tag = 'validatorTrajectoriesEgoProfile';
                end
                hProf.XData = profile(:,1);
                hProf.YData = profile(:,2);               
                
                % Move image to the bottom to show overlayed plots
                uistack(hImage,'bottom');
            end
        end
    end
    
    methods (Access = protected)
        function [tf, cost, tfDetailed, costDetailed] = checkCollision(obj, mapStates)
            % Check collision of the local states against cost maps
            
            % Allocate memory
            tfDetailed = true(numel(obj.TimeSteps),size(mapStates,3));
            costDetailed = zeros(numel(obj.TimeSteps) - 1,size(mapStates,3));
            L = obj.VehicleDimensions.Length;
            W = obj.VehicleDimensions.Width;
            inscribedRadius = min(L/2,W/2);
            circumscribedRadius = sqrt(L^2 + W^2)/2;
            
            % Go through each time step
            for i = 2:(min(size(mapStates,1),numel(obj.TimeSteps)+1))
                
                % x, y, theta with respect to grid of all trajectories
                xyTheta = reshape(mapStates(i,:,:),3,[])';
                
                % Some may be invalid as their length is shorter than
                % current time
                isValid =  all(~isnan(xyTheta),2);
                xyTheta = xyTheta(isValid,:);
                
                % Transform x, y to the center of the ego
                x = xyTheta(:,1) + cos(xyTheta(:,3))*obj.VehicleOffset;
                y = xyTheta(:,2) + sin(xyTheta(:,3))*obj.VehicleOffset;
                xyTheta(:,1:2) = [x y];
                
                % Get cost and closest object index at local positions
                costIdx = reshape(getMapData(obj.FutureCostMaps,num2str(i-1),xyTheta(:,1:2),'local'),[],2);
                
                % Cost value
                thisCost = costIdx(:,1);
                
                % In definitely colliding regions?
                isColliding = thisCost > 0.99;
                
                % Set the cost for output
                costDetailed(i - 1,isValid) = thisCost;
                
                % Convert cost to range to check if inside ambiguous
                % regions
                thisRange = costToRangeFcn(thisCost,inscribedRadius);
                
                % If yes, investigate properly for collision
                toInvestigate = thisRange > inscribedRadius & thisRange <= circumscribedRadius;
                if any(toInvestigate)
                    % grid index of closet object at this point
                    closestObjectIdx = costIdx(toInvestigate,2);
                    
                    % Local coordinate of the closest object at this point
                    [gridI, gridJ] = ind2sub(obj.FutureCostMaps.GridSize,closestObjectIdx(:));
                    xyObstacle = grid2local(obj.FutureCostMaps,[gridI gridJ]);
                    
                    % Relative position wrt ego center
                    xyEgo = xyObstacle - xyTheta(toInvestigate,1:2);
                    
                    % Angle with respect to ego at this position
                    thetaR = atan2(xyEgo(:,2),xyEgo(:,1)) - xyTheta(toInvestigate,3);
                    
                    % Calculate range of ego boundary in the relative
                    % direction
                    intersectingWithL = abs(thetaR) < atan2(W,L);
                    r1 = abs(L./(2*cos(thetaR)));
                    r2 = abs(W./(2*sin(thetaR)));
                    rBoundary = r1;
                    rBoundary(~intersectingWithL) = r2(~intersectingWithL);
                    
                    % Object colliding if range boundary is greater than
                    % obstacle range
                    isColliding(toInvestigate) = rBoundary >= thisRange(toInvestigate);
                end
                
                % Update is colliding details
                tfDetailed(i - 1,isValid) = ~isColliding;
            end
            
            % Use cost as probability of collision as merge using mutually
            % exclusive probability rules
            cost = 1 - prod(1 - costDetailed,1);
            
            % A trajectories is collision free if each point is collision
            % free.
            tf = all(tfDetailed,1);
        end
    end
end

function costValues = rangeToCostFcn(r, rMin, rMax)
% Range to representative cost value. Cost represents probability measure
% in this case. Decay is modeleted using an expontetial factor of 0.3.
costValues = zeros(size(r),'like',r);
costValues(r <= rMin) = 1;
costValues(r > rMax) = 0;
decayingRegion = r > rMin & r <= rMax;
costValues(decayingRegion) = exp(-0.3*(r(decayingRegion) - rMin));
end

function r = costToRangeFcn(cost, rMin)
% Only supported until inflation region
r = rMin - 1/0.3*log(cost);
end

% A function to convert states in global coordinates to states in local
% coordinates for projecting on the map.
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

function states = concatenateTrajectories(trajectories)
length = arrayfun(@(x)size(x.Trajectory,1),trajectories);
maxLength = max(length);
states = nan(maxLength,6,numel(trajectories));
for i = 1:numel(trajectories)
    states(1:length(i),:,i) = trajectories(i).Trajectory;
end
end


