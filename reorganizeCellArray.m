function combinedMatrix = reorganizeCellArray(cellArray)
    % Determine the number of rows and maximum number of columns
    numRows = size(cellArray{1}, 1);
    maxCols = max(cellfun(@(x) size(x, 2), cellArray));
    
    % Initialize a 3D matrix with NaNs
    combinedMatrix = nan(numRows, maxCols, numel(cellArray));

    % Fill the 3D matrix with padded matrices
    for i = 1:numel(cellArray)
        currentMatrix = cellArray{i};
        numRows = size(currentMatrix, 1);
        numCols = size(currentMatrix, 2);
        
        % Place the current matrix into the 3D matrix with padding
        combinedMatrix(1:numRows, 1:numCols, i) = currentMatrix;
    end
end