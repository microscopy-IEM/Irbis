function totalLength = calculateCentrelineLength(centreline)
    % Get number of points
    numPoints = size(centreline, 1);

    % Check if we have enough points to form a line
    if numPoints < 2
        disp('Centreline must have at least 2 points to calculate length');
        return;
    end

    % Calculate differences between consecutive points
    pointDiffs = diff(centreline, 1, 1);
    
    % Calculate segment lengths (Euclidean distances)
    segmentLengths = sqrt(sum(pointDiffs.^2, 2));
    
    % Sum all segment lengths
    totalLength = sum(segmentLengths);

    % Display result
    % disp(['Centreline length: ', num2str(totalLength)]);

    % disp(['Centreline length 2: ', num2str(calculateReducedLength(centreline, 2))]);

    % disp(['Centreline length 5: ', num2str(calculateReducedLength(centreline, 5))]);

    % disp(['Centreline length 10: ', num2str(calculateReducedLength(centreline, 10))]);

    % function totalLength = calculateReducedLength(centreline, reduction_factor)
    %     % Get number of points
    %     numPoints = size(centreline, 1);

    %     % Check if we have enough points to form a line
    %     if numPoints < 2
    %         disp('Centreline must have at least 2 points to calculate length');
    %         totalLength = 0;
    %         return;
    %     end
        
    %     % Set default reduction factor if not provided
    %     if nargin < 2
    %         reduction_factor = 1; % No reduction by default
    %     end
        
    %     % Reduce number of points if reduction factor > 1
    %     if reduction_factor > 1
    %         % Ensure we keep at least first and last point
    %         if numPoints > 2
    %             indices = unique([1, round(linspace(2, numPoints-1, floor((numPoints-2)/reduction_factor))), numPoints]);
    %             centreline = centreline(indices, :);
    %             disp(['Reduced from ' num2str(numPoints) ' to ' num2str(length(indices)) ' points']);
    %         end
    %     end
        
    %     % Calculate differences between consecutive points
    %     pointDiffs = diff(centreline, 1, 1);
        
    %     % Calculate segment lengths (Euclidean distances)
    %     segmentLengths = sqrt(sum(pointDiffs.^2, 2));
        
    %     % Sum all segment lengths
    %     totalLength = sum(segmentLengths);

    %     % Display result
    %     disp(['Centreline length: ', num2str(totalLength)]);
    % end
end