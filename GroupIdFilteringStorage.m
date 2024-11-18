classdef GroupIdFilteringStorage < FilteringStorage
    methods 
        function filteredGroupings = getFiltersByVariable(obj, variableValue)
            % Get GroupIdFiltering objects with a specific FilteredVariable value
            filteredGroupings = obj.Groupings(cellfun(@(f) isequal(f.FilteredVariable, variableValue), obj.Groupings));
        end

        function addRangeFilter(obj, columnName, range, filteredVariable)
            % Call the parent method to create the filter object
            addRangeFilter@FilteringStorage(obj, columnName, range);

            % Adjust the last added object to set the FilteredVariable
            if isa(obj.Groupings{end}, 'Filtering')
                % Replace the Filtering object with a GroupIdFiltering object
                lastFilter = obj.Groupings{end};
                obj.Groupings{end} = GroupIdFiltering(lastFilter.Name, ...
                                                      lastFilter.Conditions, ...
                                                      lastFilter.Active, ...
                                                      filteredVariable);
            else
                error('Last added object is not of type Filtering.');
            end
        end

        function addCategoricalFilter(obj, columnName, categories, filteredVariable)
            % Call the parent method to create the filter object
            addCategoricalFilter@FilteringStorage(obj, columnName, categories);

            % Adjust the last added object to set the FilteredVariable
            if isa(obj.Groupings{end}, 'Filtering')
                % Replace the Filtering object with a GroupIdFiltering object
                lastFilter = obj.Groupings{end};
                obj.Groupings{end} = GroupIdFiltering(lastFilter.Name, ...
                                                      lastFilter.Conditions, ...
                                                      lastFilter.Active, ...
                                                      filteredVariable);
            else
                error('Last added object is not of type Filtering.');
            end
        end

        function names = returnGroupingNamesForVariable(obj, filteredVariable)
            filteredGroupings = obj.getFiltersByVariable(filteredVariable);
            names = cell(1, numel(filteredGroupings));
            for i = 1:numel(filteredGroupings)
                cm = filteredGroupings{i};
                names{i} = char(cm.Name);
            end
        end
    end
end