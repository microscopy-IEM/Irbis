function saveSortedCategories(scrollPanel, groupingFig)
    % create categories structure to store to Categorization object
    % sorts the structure so that the structure is the same no matter the order of definition

    nCategories = length(scrollPanel.UserData.CategoryPanels);
    categoryNames = cell(1, nCategories); % Preallocate cell array
    for i = 1:nCategories
        categoryNames{i} = scrollPanel.UserData.CategoryPanels{i}.Children(1).Children(1).Value;
    end

    [~, indexes] = sort(categoryNames)
    % indexes = indexes(:)
    size(indexes)

    conditions = struct();
    risingNum = 1;
    for i = indexes
        disp(i)
        categoryPanel = scrollPanel.UserData.CategoryPanels{i};
        categoryName = categoryNames{i}; % Get the category name
        conditionsDict = dictionary(string.empty, {}); % Initialize with key and value types

        % sort the column names
        nConditions = length(categoryPanel.UserData.CriteriaComponents);
        columns = cell(1, nConditions);
        operators = cell(1, nConditions);
        for j = 1:nConditions
            columns{j} = categoryPanel.UserData.CriteriaComponents{j}{1}.Value;
            operators{j} = categoryPanel.UserData.CriteriaComponents{j}{2}.Value;
        end
        [sortedColumns, columnIndexes] = sort(columns)
        operatorsSortedByColumns = operators(columnIndexes)

        % now, I also need to sort based on the operator, when the column is mentioned more times
        [~, b, c] = unique(sortedColumns, "stable")

        for elementId = 1:numel(b)
            elementCount = sum(c == elementId);
            if elementCount > 1
                % column more than once -> sort
                relevantOperators = operatorsSortedByColumns(b(elementId):b(elementId)+elementCount-1)
                [~, operatorIndexes] = sort(relevantOperators);
                relevantColumnIndexes = columnIndexes(b(elementId):b(elementId)+elementCount-1);
                columnIndexes(b(elementId):b(elementId)+elementCount-1) = relevantColumnIndexes(operatorIndexes);
            end
        end

        for j = columnIndexes
            rowComponents = categoryPanel.UserData.CriteriaComponents{j};
            % column = rowComponents{1}.Value;
            % operator = rowComponents{2}.Value;
            column = columns{j};
            operator = operators{j};

            % Check if the value field is a uitree (for categorical variables)
            if strcmp(rowComponents{3}.Type, 'uicheckboxtree')
                checkedNodes = rowComponents{3}.CheckedNodes;
                value = {checkedNodes.Text}; % Save as cell array
                conditionsDict(column) = {value};
            else
                value = rowComponents{3}.Value;
                operatorValueDict = dictionary(operator, value);
                if isKey(conditionsDict, column)
                    innerDict = conditionsDict(column);
                    innerDict = innerDict{1};
                    % innerDict
                    isConfigured(innerDict)
                    % operator
                    if isKey(innerDict, operator)
                        disp('overwriting the same condition');
                    end
                    innerDict(operator) = value;
                    conditionsDict(column) = {innerDict};
                else
                    conditionsDict(column) = {operatorValueDict};
                end
            end
        end
        categoryStruct.name = categoryName;
        categoryStruct.conditions = conditionsDict;
        conditions.(['group' num2str(risingNum)]) = categoryStruct;
        risingNum = risingNum + 1;
    end
    assignin('base', 'cats', conditions); % Save to workspace for further use
    % disp(conditions)

    uiresume(groupingFig);
    delete(groupingFig);
end 