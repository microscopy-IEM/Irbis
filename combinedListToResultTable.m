function [resultTable,timePoints] = combinedListToResultTable(combinedList, attributes)

    % Convert the categorical time points back to numerical values
    numericalTimePoints = double(combinedList.timePoint);
    uniqueTimePoints = unique(numericalTimePoints);
    nTimePoints = numel(uniqueTimePoints);
    timePoints = uniqueTimePoints';
    
    % Initialize labels with the first column as 'groupId'
    labels = cell(1, 1 + nTimePoints * numel(attributes));
    labels{1} = 'groupId';
    
    % Check if the query attributes actually exist in the spine list
    attrNames = combinedList.Properties.VariableNames;
    existingAttributes = attributes(ismember(attributes, attrNames));
    
    if numel(existingAttributes) ~= numel(attributes)
        warndlg('Warning: some of the query attributes do not exist in the spine list!');
    end
    
    % Generate labels for the result table
    labelIndex = 2;
    for attr = existingAttributes
        for tp = uniqueTimePoints'
            labels{labelIndex} = [char(attr) '_' num2str(tp)];
            labelIndex = labelIndex + 1;
        end
    end
    
    % Detect all unique group IDs (excluding zero)
    uniqueIds = unique(combinedList.groupId);
    uniqueIds(uniqueIds == 0) = [];
    
    % Initialize the result table with NaNs and set column names
    resultTable = array2table(nan(numel(uniqueIds), numel(labels)), 'VariableNames', labels);
    resultTable.groupId = uniqueIds;
    
    % Fill the result table with data
    for i = 1:numel(uniqueIds)
        groupId = uniqueIds(i);
        groupData = combinedList(combinedList.groupId == groupId, :);
    
        for attr = existingAttributes
            for tp = uniqueTimePoints'
                % Find the relevant data for the current time point and attribute
                value = groupData{groupData.timePoint == tp, char(attr)};
                if ~isempty(value)
                    resultTable{i, [char(attr) '_' num2str(tp)]} = value(1);
                end
            end
        end
    end

end
