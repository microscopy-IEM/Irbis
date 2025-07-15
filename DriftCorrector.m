classdef (Sealed) DriftCorrector
    methods (Static, Access = public)

        function drift = computeDriftVector(status, currentDrift, manualDriftAdjustment)
            driftAdjustedManually = ~isequal(manualDriftAdjustment, 0);
            if driftAdjustedManually      % user supplied override
                drift = manualDriftAdjustment - currentDrift;
                if ~status            % correction switched OFF -> nothing else to do
                    drift = [0 0 0];  % no translation required when disabled
                end
            else                              % normal forward / revert toggle
                if status == 1
                    sign = 1;
                else
                    sign = -1;
                end
                drift = sign .* currentDrift;
            end
        end

        function T = applyDriftToTable(T, parametersToCorrect, drift)
            % Vectorised table update – returns modified table copy.
            hasParam = ismember(parametersToCorrect, T.Properties.VariableNames);
            existinParamIdx = find(hasParam);

            for k = existinParamIdx
                parameter = parametersToCorrect{k};
                
                columnToAdjust = T.(parameter);
                if iscell(columnToAdjust)                     % heterogeneous (objects in cells)
                    columnToAdjust = cellfun(@(obj) translateObject(obj, drift), columnToAdjust, ...
                                'UniformOutput', false);
                    
                elseif isnumeric(columnToAdjust)              % numeric array per row
                    % assume n×3 coords; keep shape, add drift to each row
                    columnToAdjust = columnToAdjust + reshape(drift,1,[]);
                    
                else                               % unsupported – leave untouched
                    warning('Parameter ''%s'' not updated (unsupported type).', parameter);
                end
                T.(parameter) = columnToAdjust;
            end
        end

    end


    methods (Static, Access = private)

        function element = translateObject(element, drift)
            % Polymorphic translation of a single object or empty.
            if isempty(element) % nothing to do
                return
            end          

            switch class(element)
                case 'double'                      % n×3 numeric vertices
                    element(:,1:3) = element(:,1:3) + drift;
                    
                case 'pointCloud'
                    element = pctransform(element, rigidtform3d([0 0 0], drift));
                    
                otherwise
                    if ismethod(element, 'translate')   % primarily for Mesh objects
                        translate(element, drift);
                    else
                        warning('Unhandled object class: %s – left unchanged.', class(element));
                    end
            end
        end

    end
end