function T = combineTablesVertically(T1, T2)
    % An alternative to vertcat that handles tables with different variable names
    % Missing values will be empty

    % Find all variables
    allVars = union(T1.Properties.VariableNames, T2.Properties.VariableNames);
    % Get types for each variable in allVars from T1 and T2
    allTypes = cell(size(allVars));
    for i = 1:length(allVars)
        varName = allVars{i};
        if ismember(varName, T1.Properties.VariableNames)
            idx = strcmp(T1.Properties.VariableNames, varName);
            allTypes{i} = T1.Properties.VariableTypes{idx};
        elseif ismember(varName, T2.Properties.VariableNames)
            idx = strcmp(T2.Properties.VariableNames, varName);
            allTypes{i} = T2.Properties.VariableTypes{idx};
        end
    end

    newT1 = table('Size', [height(T1), length(allVars)], ...
                  'VariableTypes', allTypes, ...
                  'VariableNames', allVars);

    newT1(:, T1.Properties.VariableNames) = T1;

    newT2 = table('Size', [height(T2), length(allVars)], ...
                  'VariableTypes', allTypes, ...
                  'VariableNames', allVars);
    newT2(:, T2.Properties.VariableNames) = T2;

    % Concatenate vertically
    T = [newT1; newT2];
end