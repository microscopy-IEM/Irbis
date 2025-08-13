classdef (Sealed) TrajectorySimplifier

    methods (Static)
        function coarseningFactor = calculateFactor(pixelWidth)

            % calculating arbitrary zoom level that will prevent unnecessary redrawing of trajectories with the same resolution
            % if the pixelWidth is small, it makes sense not to coarsen, but to plot only the selected area
            % if the pixel width is large, it makes sense to coarsen the plot, but we can plot everything and not redraw it every time

            if pixelWidth < 0.08
                coarseningFactor = 0;
            elseif pixelWidth < 0.25
                coarseningFactor = 0.25;
            else
                coarseningFactor = 0.5;
            end
        end


        function factors = getAvailableFactors()
            % Define a set of available coarsening factors
            factors = [0.25, 0.5];
        end


        function out = coarsenAndSquish(data, step)
        %   data : T-by-N-by-D numeric (NaNs allowed)
        %   step : scalar step size for the snapping grid
        %
        %   Behavior:
        %     - Snap values to nearest multiple of `step` (NaNs remain NaN).
        %     - A position is kept (keep==true) iff it is non-NaN and its value
        %       differs from the previous *non-NaN* value in the same column/slice,
        %       or there is no previous non-NaN value (i.e., start).
        %     - Only starts are kept (no “ends”); kept values are packed to the top
        %       of each [N,D] column; the rest is filled with NaN.

            % ---- 1) snap to uniform grid
            dataSnapped = step .* round(data ./ step);   % NaNs stay NaN
            [T, N, D]   = size(dataSnapped);

            % ---- 2) detect STARTS across NaN gaps
            valid = ~isnan(dataSnapped);

            % index grids
            [tIdx, cIdx, dIdx] = ndgrid(1:T, 1:N, 1:D);

            % For each position, find the index of the last non-NaN AT OR BEFORE it
            maskedT          = tIdx .* valid;           % 0 where NaN
            prevAtOrBefore   = cummax(maskedT, 1);      % (T x N x D)
            % We want the strictly previous non-NaN -> shift down by 1 row
            prevIdx          = cat(1, zeros(1,N,D,'like',prevAtOrBefore), prevAtOrBefore(1:end-1,:,:));

            % Gather the previous value (NaN if none)
            prevVal = NaN(T, N, D);
            hasPrev = prevIdx > 0;
            linPrev = sub2ind([T, N, D], prevIdx(hasPrev), cIdx(hasPrev), dIdx(hasPrev));
            prevVal(hasPrev) = dataSnapped(linPrev);

            % A start = non-NaN AND (no previous non-NaN OR value changes vs previous non-NaN)
            isStart = valid & ( (prevIdx == 0) | (dataSnapped ~= prevVal) );

            keep = isStart(:, :, 1) | isStart(:, :, 2) | isStart(:, :, 3); 
            keep = repmat(keep, [1, 1, D]);  % keep same for all dimensions
            
            % ---- 3) pack kept values upward, pad to longest
            nkeep = sum(keep, 1);                    % 1 x N x D
            R     = max(nkeep, [], 'all');           % height of the longest packed column
            out   = NaN(R, N, D);

            pos = cumsum(keep, 1);                   % destination row index per kept value
            pos(~keep) = 0;

            linDest = sub2ind([R, N, D], pos(keep), cIdx(keep), dIdx(keep));
            out(linDest) = dataSnapped(keep);
        end
    end
end