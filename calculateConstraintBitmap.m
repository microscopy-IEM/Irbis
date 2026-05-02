function constraintBitmap = calculateConstraintBitmap(restrictedAreas, zstack, xlim, ylim, drift)
    % constrain tracking

    if isempty(restrictedAreas)
        constraintBitmap = [];
    else

        % make a constraint map
        xVector = linspace(xlim(1),xlim(2),size(zstack,2));
        yVector = linspace(ylim(1),ylim(2),size(zstack,1));

        [xGrid,yGrid] = meshgrid(xVector,yVector);

        inROI = zeros(size(xGrid));
        for roiNum = 1:length(restrictedAreas)
            roi = restrictedAreas(roiNum);
            inROI = inROI + inpolygon(xGrid,yGrid,roi.Position(:,1)-drift(1),roi.Position(:,2)-drift(2));
        end

        inROI = double(inROI);
        inROI(inROI > 0) = -Inf;
        inROI(inROI == 0) = Inf;

        constraintBitmap = repmat(inROI,[1,1,size(zstack,3)]);
    end
end