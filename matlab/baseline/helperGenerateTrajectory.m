function [frenetTrajectory, globalTrajectory] = helperGenerateTrajectory(connector, refPath, currentEgoState, speedLimit, laneWidth, intersectionS, intersectionBuffer)

% Convert current global state of ego to frenet coordinate
egoFrenetState = global2frenet(refPath, currentEgoState);

if egoFrenetState(1) > (intersectionS-intersectionBuffer) && egoFrenetState(1) < intersectionS
    % Create terminal states that bring vehicle to a stop at upcoming intersections
    desiredS = intersectionS;
    ds = 0;
    dL = 0;
    dds = 0;
    
    % Calculate minimum-jerk time
    dT = minJerkTime(egoFrenetState(1),egoFrenetState(2),egoFrenetState(3),desiredS);
else
    % Sample uniformly sampled trajectories in dS and dL
    desiredS = nan;
    ds = linspace(0,speedLimit,10);
    dL = [0 laneWidth];
    dds = 0;
    
    % Planning horizon time
    dT = linspace(2,4,6);
end

% Combinatorial combination of each desired end state
[DL, DS, DDS] = meshgrid(dL,ds,dds);

% Assemble final Frenet states
nTraj = numel(DS);
finalFrenetState = zeros(nTraj,6);
finalFrenetState(:,1) = desiredS; % Compute Longutidinal automatically
finalFrenetState(:,2) = DS(:); % Desired speed along path
finalFrenetState(:,3) = DDS(:); % Desired acceleration along path
finalFrenetState(:,4) = DL(:); % Desired

% Repeat for each planning horizon end
finalFrenetState = repmat(finalFrenetState,numel(dT),1);
timeStamps = repelem(dT,nTraj);

% Connect the trajectories and obtain end state in global coordinates
[frenetTrajectory,globalTrajectory] = connect(connector,egoFrenetState,finalFrenetState,timeStamps);

end

function dT = minJerkTime(s0,ds0,dds0,sT)

assert(abs(ds0) > 0,'Requires non-zero velocity at start');

if dds0 == 0
    dTPossible = [-(5*(s0 - sT))/(2*ds0)
        -(15*(s0 - sT))/(4*ds0)];
else
    dTPossible = [(4*ds0 + 2^(1/2)*(8*ds0^2 + 15*dds0*s0 - 15*dds0*sT)^(1/2))/dds0
        (4*ds0 - 2^(1/2)*(8*ds0^2 + 15*dds0*s0 - 15*dds0*sT)^(1/2))/dds0
        -(2*(2*ds0 + (4*ds0^2 - 5*dds0*s0 + 5*dds0*sT)^(1/2)))/dds0
        -(2*(2*ds0 - (4*ds0^2 - 5*dds0*s0 + 5*dds0*sT)^(1/2)))/dds0];
end

isValid = imag(dTPossible) == 0 & real(dTPossible) > 0 & real(dTPossible) < 100;

dT = dTPossible(isValid);

end
