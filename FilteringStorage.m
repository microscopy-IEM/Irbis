classdef FilteringStorage < GroupingStorageBaseClass
    properties (Dependent)
        Filters
    end

    methods
        function value = get.Filters(obj)
            value = obj.Groupings;
        end

        function addRangeFilter(obj, columnName, range)
            conditions = struct();
            groupConditions = dictionary();
            operatorValueDict = dictionary(...
                'greaterThan', range(1), ...
                'lessThan', range(2));
            groupConditions(columnName) = {operatorValueDict};
            conditions.('group1') = struct('name', true, 'conditions', groupConditions);
            active = true;
            filterObj = Filtering(columnName,conditions,active);
            obj.Groupings{end+1} = filterObj;
        end

        function addCategoricalFilter(obj, columnName, categories)
            groupConditions = dictionary();
            groupConditions(columnName) = {categories};
            conditions.('group1') = struct('name', true, 'conditions', groupConditions);
            active = true;
            filterObj = Filtering(columnName,conditions,active);
            obj.Groupings{end+1} = filterObj;
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
                        % Create operatorValueDict with 'greaterThan' and 'lessThan' for range filter
                        operatorValueDict = dictionary(...
                            'greaterThan', newCondition(1), ...
                            'lessThan', newCondition(2));
                        
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
            end
        end

        function organizedConditions = getConditions(obj, columnName)
            filter = obj.returnGrouping(columnName);
            conditions = filter.Conditions.('group1').conditions(columnName);
            conditions = conditions{1};
            if iscell(conditions)
                organizedConditions = conditions;
            else
                organizedConditions = [conditions('greaterThan'),conditions('lessThan')];
            end
        end

        % moved here from the base function, as the Active property will be defined only for filters
        function filterArray = updateAllFilterTables(obj, listArray, filterArray, timePoints)
            % Method to update all filter tables for all Groupings
            for i = 1:numel(obj.Groupings)
                cm = obj.Groupings{i};
                    if cm.Active
                        filterArray = cm.updateFilterTable(listArray, filterArray, timePoints);
                    elseif isempty(cm.Active)
                        cm.Active = true;
                        filterArray = cm.updateFilterTable(listArray, filterArray, timePoints);
                    end
            end
        end

        function activateFilter(obj, name)
            idx = obj.findGroupingIndexByName(name);
            filter = obj.Groupings{idx};
            filter.Active = true;
        end

        function inactivateFilter(obj, name)
            idx = obj.findGroupingIndexByName(name);
            filter = obj.Groupings{idx};
            filter.Active = false;
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
    end
end