function T = combineTablesVertically(T1, T2)
    % An alternative to vertcat that handles tables with different variable names
    % Missing values will be empty

    % Find all variables
    allVars = union(T1.Properties.VariableNames, T2.Properties.VariableNames, 'stable');
    % Get types for each variable in allVars from T1 and T2
    allTypes = cell(size(allVars));
    for i = 1:length(allVars)
        varName = allVars{i};
        if ismember(varName, T1.Properties.VariableNames)
            idx = strcmp(T1.Properties.VariableNames, varName);
            allTypes{i} = T1.Properties.VariableTypes{idx};
            disp(['Variable: ', varName, ', Type: ', allTypes{i}]);
            if ismember(varName, T2.Properties.VariableNames)
                idx2 = strcmp(T2.Properties.VariableNames, varName);
                type2 = T2.Properties.VariableTypes{idx2};
                if ~strcmp(allTypes{i}, type2)
                    error(['Type mismatch for variable ', varName, ': ', allTypes{i}, ' vs ', type2]);
                end
            end
        elseif ismember(varName, T2.Properties.VariableNames)
            idx = strcmp(T2.Properties.VariableNames, varName);
            allTypes{i} = T2.Properties.VariableTypes{idx};
        end
    end

    % Add missing columns to T1 with proper types
    T1 = addMissingColumns(T1, allVars, allTypes);
    T2 = addMissingColumns(T2, allVars, allTypes);

    % Concatenate vertically
    T = [T1; T2];
end



function T = addMissingColumns(T, allVars, allTypes)
    missingVars = setdiff(allVars, T.Properties.VariableNames);
    for i = 1:length(missingVars)
        varName = missingVars{i};
        idx = strcmp(allVars, varName);
        varType = allTypes{idx};
        
        % Create empty values of the right type
        if strcmp(varType, 'cell')
            T.(varName) = cell(height(T), 1);
        elseif strcmp(varType, 'double')
            T.(varName) = nan(height(T), 1);
        elseif strcmp(varType, 'string') || strcmp(varType, 'char')
            T.(varName) = strings(height(T), 1);
        elseif strcmp(varType, 'logical')
            T.(varName) = false(height(T), 1);
        elseif strcmp(varType, 'categorical')
            T.(varName) = categorical(NaN(height(T), 1));
        elseif strcmp(varType, 'table')
            T.(varName) = cell(height(T), 1);
        elseif strcmp(varType, 'datetime')
            T.(varName) = NaT(height(T), 1);
        else
            T.(varName) = repmat({[]}, height(T), 1);
        end
    end
end