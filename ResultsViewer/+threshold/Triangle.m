classdef Triangle
    % Triangle threshold computation

    methods (Static, Access = public)

        function threshold = compute(data, varargin)

            if isequal(nargin, 2)
                numBins = varargin{1};
                [counts, edges] = histcounts(data, numBins);
            else
                [counts, edges] = histcounts(data);
                numBins = numel(counts);
            end

            % Compute histogram
            binCenters = edges(1:end-1) + diff(edges)/2;

            % Find peak of histogram
            [peakValue, peakIdx] = max(counts);

            % Determine which tail is longer (left or right of the peak)
            leftLength = peakIdx - 1;
            rightLength = numBins - peakIdx;

            % Tail direction
            if rightLength > leftLength
                % Right-skewed: line from peak to right end
                x1 = peakIdx;
                y1 = peakValue;
                x2 = numBins;
                y2 = counts(end);
                idxRange = peakIdx:numBins;
            else
                % Left-skewed: line from peak to left end
                x1 = peakIdx;
                y1 = peakValue;
                x2 = 1;
                y2 = counts(1);
                idxRange = 1:peakIdx;
            end

            % Normalize coordinates for distance computation
            x = idxRange;
            y = counts(idxRange);

            % Line vector
            dx = x2 - x1;
            dy = y2 - y1;

            % Perpendicular distance from each point to the line
            distances = abs(dy * (x - x1) - dx * (y - y1)) / sqrt(dx^2 + dy^2);

            % Find bin with maximum distance
            [~, maxDistIdx] = max(distances);
            thresholdBin = idxRange(maxDistIdx);
            threshold = binCenters(thresholdBin);
        end
    end
end