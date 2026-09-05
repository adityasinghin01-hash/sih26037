function trajectoryList = helperAssembleTrajectoryForPlotting(globalTrajectories, isFeasible, isCollisionFree, optimalIdx)
trajectoryList = globalTrajectories;
isCollisionFreeTotal = false(numel(globalTrajectories),1);
isCollisionFreeTotal(isFeasible) = isCollisionFree;

if ~isempty(optimalIdx)
    f = find(isCollisionFreeTotal);
    optimalIdxTotal = f(optimalIdx);
else
    optimalIdxTotal = zeros(0,1);
end

for i = 1:numel(trajectoryList)
    trajectoryList(i).IsFeasible = isFeasible(i);
    trajectoryList(i).IsColliding = ~isCollisionFreeTotal(i);
end

[trajectoryList.IsOptimal] = deal(false);
if ~isempty(optimalIdxTotal)
    trajectoryList(optimalIdxTotal).IsOptimal = true;
end

end