classdef SummarizedTableClass < handle

    properties
        rowParameterName    % string/char - name of the categorical parameter that forms rows
        summarizedTable     % table - table with summarized data, can contain statistics column or categorizations
        groupCategories     % CategorizationStorage object - object containing defition of categorizations present in the table
        groupFilters        % FilteringStorage object - object containing filters applied based on groups based on the summarized table
    end

    methods
        function obj = SummarizedTableClass(rowParameterName, summarizedTable, groupCategories, groupFilters)
            % Constructor for SummarizedTableClass
            obj.rowParameterName = rowParameterName;
            obj.summarizedTable = summarizedTable;
            if ~isempty(groupCategories) && isa(groupCategories, 'CategorizationStorage')
                obj.groupCategories = groupCategories;
            else
                obj.groupCategories = CategorizationStorage();
            end
            if ~isempty(groupFilters) && isa(groupFilters, 'FilteringStorage')
                obj.groupFilters = groupFilters;
            else
                obj.groupFilters = FilteringStorage();
            end
        end

        function extendTable(obj, newTable)
            % Extends the summarized table with new columns (input as table)

            % Raise an error if the tables do not have the same number of rows
            assert(height(obj.summarizedTable) == height(newTable), 'Tables must have the same number of columns');
            obj.summarizedTable = horzcat(obj.summarizedTable, newTable);
        end

        function addCategorization(obj, categorization)
            % Adds a categorization to the groupCategories object and to the table
            obj.groupCategories.addCategorization(categorization);

            % Update the summarized table with the new categorization
            obj.summarizedTable = categorization.updateTable(obj.summarizedTable, {});
        end
    end

end