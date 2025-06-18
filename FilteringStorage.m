classdef FilteringStorage < GroupingStorageBaseClass
    properties (Dependent)
        Filters
    end

    events
        filtersChanged
    end

    methods
        function value = get.Filters(obj)
            value = obj.Groupings;
        end

        function addRangeFilter(obj, columnName, range)
            conditions = struct();
            groupConditions = dictionary();
            operatorValueDict = dictionary(...
                'equalOrGreaterThan', range(1), ...
                'equalOrLessThan', range(2));
                % 250525: updated from open to closed interval
                    % including edge values in the filter makes more sense to me, but can be discussed
            groupConditions(columnName) = {operatorValueDict};
            conditions.('group1') = struct('name', true, 'conditions', groupConditions);
            active = true;
            filterObj = Filtering(columnName,conditions,active);
            obj.Groupings{end+1} = filterObj;

            % disp(['Added range filter for column: ', columnName]);

            % Notify listeners that the filters have changed
            notify(obj, 'filtersChanged');
        end

        function addCategoricalFilter(obj, columnName, categories)
            groupConditions = dictionary();
            groupConditions(columnName) = {categories};
            conditions.('group1') = struct('name', true, 'conditions', groupConditions);
            active = true;
            filterObj = Filtering(columnName,conditions,active);
            obj.Groupings{end+1} = filterObj;

            % disp(['Added categorical filter for column: ', columnName]);

            notify(obj, 'filtersChanged');
        end

        function updateFilter(obj, columnName, newCondition)
            % Automatically determine the filter type based on the format of newCondition
            filterFound = false;
        
            % Determine the filter type based on the input type
            if iscell(newCondition) || isstring(newCondition)
                % Categorical filter if it's a cell array or string array
                filterType = 'categorical';
            elseif isnumeric(newCondition) && numel(newCondition) == 2
                % Range filter if it's a numeric array with two elements
                filterType = 'range';
            else
                error('Unsupported filter condition format.');
            end
            
            for i = 1:numel(obj.Groupings)
                filterObj = obj.Groupings{i};
                
                % Check if the filter corresponds to the specified columnName
                if isequal(filterObj.Name, columnName)
                    % Update based on the determined filter type
                    if strcmp(filterType, 'categorical')
                        % Update the conditions with new categories (categorical filter)
                        filterObj.Conditions.('group1').conditions(columnName) = {newCondition};
                    elseif strcmp(filterType, 'range')
                        % Create operatorValueDict with 'equalOrGreaterThan' and 'equalOrLessThan' for range filter
                        operatorValueDict = dictionary(...
                            'equalOrGreaterThan', newCondition(1), ...
                            'equalOrLessThan', newCondition(2));
                        
                        % Update the conditions with the new range
                        filterObj.Conditions.('group1').conditions(columnName) = {operatorValueDict};
                    end
        
                    % Mark that the filter was found and updated
                    filterFound = true;
                    break;
                end
            end
            
            % If no filter was found with the given columnName, add a new filter
            if ~filterFound
                if strcmp(filterType, 'categorical')
                    % Add new categorical filter
                    obj.addCategoricalFilter(columnName, newCondition);
                elseif strcmp(filterType, 'range')
                    % Add new range filter
                    obj.addRangeFilter(columnName, newCondition);
                end
            else
                notify(obj, 'filtersChanged');  % otherwise, it is already done in addRangeFilter or addCategoricalFilter
            end
        end

        function organizedConditions = getConditions(obj, columnName)
            filter = obj.returnGrouping(columnName);
            conditions = filter.Conditions.('group1').conditions(columnName);
            conditions = conditions{1};
            if iscell(conditions)
                organizedConditions = conditions;
            else
                if isKey(conditions, 'equalOrGreaterThan') && isKey(conditions, 'equalOrLessThan')
                    organizedConditions = [conditions('equalOrGreaterThan'), conditions('equalOrLessThan')];
                else    % legacy option - open interval instead of closed
                    organizedConditions = [conditions('greaterThan'),conditions('lessThan')];   
                end
            end
        end

        % moved here from the base function, as the Active property will be defined only for filters
        function filterArray = updateAllFilterTables(obj, listArray, filterArray, timePoints)
            % Method to update all filter tables for all Groupings
            % Filter array - cell array of tables, one for each time point
            % Each table has a column for each filter            

            for i = 1:numel(obj.Groupings)
                cm = obj.Groupings{i};
                    if cm.Active
                        filterArray = cm.updateFilterTable(listArray, filterArray, timePoints);
                    elseif isempty(cm.Active)
                        cm.Active = true;
                        filterArray = cm.updateFilterTable(listArray, filterArray, timePoints);
                    end
            end
            % NOTE: With this approach, every time a filter changes, we recalculate all filters.
            % Because we do not store the filterArray. 
            % This is probably not optimal when it comes to filtering large datasets.
        end

        function isKept = filter(obj, listArray)
            % Method to update all filter tables for all Groupings
            % Filter array - cell array of tables, one for each time point
            % Each table has a column for each filter            

            filterArray = table();

            % If the listArray is cell (table for each time point), we want to apply the filter to each table
            if iscell(listArray)
                timePoints = 1:numel(listArray);
            else
                timePoints = 1;
            end

            for i = 1:numel(obj.Groupings)
                cm = obj.Groupings{i};
                if cm.Active
                    filterArray = cm.updateFilterTable(listArray, filterArray, timePoints);
                elseif isempty(cm.Active)
                    cm.Active = true;
                    filterArray = cm.updateFilterTable(listArray, filterArray, timePoints);
                end
                
            end

            if ~isempty(filterArray) && istable(listArray)
                filterLogicalArray = all(table2array(filterArray), 2);
                isKept = filterLogicalArray;
            elseif ~isempty(filterArray) && iscell(listArray)
                % If listArray is a cell array of tables, we need to apply the filter to each table
                isKept = cell(size(listArray));
                for i = 1:numel(listArray)
                    filterLogicalArray = all(table2array(filterArray{i}), 2);
                    isKept{i} = filterLogicalArray;
                end
            else
                isKept = [];
            end
            % NOTE: With this approach, every time a filter changes, we recalculate all filters.
            % Because we do not store the filterArray. 
            % This is probably not optimal when it comes to filtering large datasets.
        end

        function activateFilter(obj, name)
            idx = obj.findGroupingIndexByName(name);
            if isequal(idx, -1)
                error(['Filter with name "', name, '" not found.']);
            end
            filter = obj.Groupings{idx};
            filter.Active = true;

            notify(obj, 'filtersChanged');
        end

        function inactivateFilter(obj, name)
            idx = obj.findGroupingIndexByName(name);
            if isequal(idx, -1)
                error(['Filter with name "', name, '" not found.']);
            end
            filter = obj.Groupings{idx};
            filter.Active = false;

            notify(obj, 'filtersChanged');
        end

        function activationStatus = getActivationStatus(obj, name)
            idx = obj.findGroupingIndexByName(name);
            filter = obj.Groupings{idx};
            activationStatus = filter.Active;
            if isempty(activationStatus)
                activationStatus = true;
                filter.Active = true;
            end
        end

        function deleteGrouping(obj, name)
            deleteGrouping@GroupingStorageBaseClass(obj, name);
            notify(obj, 'filtersChanged');
        end

        function renameFilteredColumn(obj, oldName, newName)
            idx = obj.findGroupingIndexByName(oldName);
            if idx > 0
                filter = obj.Groupings{idx};
                filter.Name = newName;

                % The column name is also propagated into the conditions structure
                % TO OPTIMIZE - rethink the structure of filters, this is unnecessarily complicated
                % Update the key in the conditions dictionary
                conditionsDict = filter.Conditions.('group1').conditions;
                if isKey(conditionsDict, oldName)
                    disp('It is a key in the conditions dictionary');
                    % Get the condition value for the old key
                    conditionValue = conditionsDict(oldName);
                    % Remove the old key-value pair
                    conditionsDict = remove(conditionsDict, oldName);
                    % Add the same value with the new key
                    conditionsDict(newName) = conditionValue;
                    filter.Conditions.('group1').conditions = conditionsDict;
                else
                    disp('It is not a key in the conditions dictionary');
                    % If the old name is not a key, we do not need to update the conditions
                    % This might happen if the filter was created without a specific condition
                end
                notify(obj, 'filtersChanged');
            else
                warning(['Filter with name "', oldName, '" not found.']);
            end
        end
    end
end