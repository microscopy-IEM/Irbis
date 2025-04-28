classdef StatisticalColumnDefinition < ColumnDefinitionInterface
    properties
        % columnName  % - taken from the superclass
        groupingParameter 
        dataParameter   % Column to calculate statistics on (e.g., 'intensity', 'area', etc.)
        columnParameter     % Column to do the first aggregation on (most likely 'timepoint')
        innerAggregationFunction    % Used only when columnParameter is used (first group for each timepoint, then aggregate over timepoints using outerAggregationFunction)
        outerAggregationFunction    % Used in all cases
    end

    methods
        function obj = StatisticalColumnDefinition()
        end

        % Configuration
        function defineRules(obj)
        % Opens a dialog to define parameters for column creation
        % Stores creation rules internally to the object
            
            % Define the prompts and default values
            prompts = {'Column Name:', ...
                  'Data Parameter:', ...
                  'Column Parameter:', ...
                  'First Aggregation Function (mean/median/std/var/min/max/sum):', ...
                  'Second Aggregation Function (mean/median/std/var/min/max/sum):'};
            
            defaults = {'', '', '', 'mean', 'mean'};
            dlgtitle = 'Statistical Column Parameters';
            
            % Show input dialog
            answer = inputdlg(prompts, dlgtitle, [1 50], defaults);
            
            % If user didn't cancel, store the values
            if ~isempty(answer)
                obj.columnName = answer{1};
                obj.dataParameter = answer{2};
                obj.columnParameter = answer{3};
                obj.innerAggregationFunction = answer{4};
                obj.outerAggregationFunction = answer{5};
            end
        end

        function replaceRules(obj, newRules)
        end

        function defineRulesProgrammatically(obj, groupingParameter, dataParameter, outerAggregationFunction, columnParameter, innerAggregationFunction)
        % Programmatically define parameters for column creation
        % Stores creation rules internally to the object

            if nargin == 4
                obj.groupingParameter = groupingParameter;
                obj.dataParameter = dataParameter;
                obj.outerAggregationFunction = outerAggregationFunction;
                obj.columnName = sprintf('%s_%s', obj.dataParameter, obj.outerAggregationFunction);
                obj.innerAggregationFunction = '';
                obj.columnParameter = '';
            elseif nargin == 6
                obj.groupingParameter = groupingParameter;
                obj.dataParameter = dataParameter;
                obj.outerAggregationFunction = outerAggregationFunction;
                obj.columnParameter = columnParameter;
                obj.innerAggregationFunction = innerAggregationFunction;
                obj.columnName = sprintf('%s_%s_over_%s_%s', obj.dataParameter, obj.outerAggregationFunction, obj.columnParameter, obj.innerAggregationFunction);
            else
                error('Invalid number of arguments.');
            end
        end

        function columnName = getColumnName(obj)
            % Returns the name of the column
            columnName = obj.columnName;
        end

        function columnName = getDataParameter(obj)
            % Returns the name of the data parameter
            columnName = obj.dataParameter;
        end

        function columnNames = getRequiredColumnNames(obj)
            % Returns the names of the columns required for calculation
            if isempty(obj.columnParameter)
                columnNames = {obj.groupingParameter, obj.dataParameter};
            else
                % If columnParameter is defined, include it in the required columns
                columnNames = {obj.groupingParameter, obj.dataParameter, obj.columnParameter};
            end
        end
               
        function renameColumn(obj, newName)
            % Rename with a new name
            % Args: newName - string of desired column name
        end

        % Column Operations        
        function data = generateColumn(obj, inputData)
            if isempty(obj.innerAggregationFunction)
                % If no inner aggregation function is defined, use the outer aggregation function directly
                data = obj.applySimpleAggregation(inputData);
            else
                % If inner aggregation function is defined, first apply it and then the outer aggregation function
                data = obj.applyInnerAndOuterAggregation(inputData);
            end
        end

        function data = applySimpleAggregation(obj, inputData)

            aggregationFunction = str2func(obj.outerAggregationFunction);
            % inputData
            % aggregationFunction
            summaryTable = groupsummary(inputData, obj.groupingParameter, aggregationFunction, obj.dataParameter);
            data = summaryTable{:, 3};  % first column contains category names, second group counts
        end

        function data = applyInnerAndOuterAggregation(obj, inputData)
            % Apply inner aggregation first
            pivotedTable = pivotTable(inputData, obj.columnParameter, obj.groupingParameter, obj.dataParameter, obj.innerAggregationFunction, {}, {});
            data = computePivotTableStatistics(obj, pivotedTable, obj.outerAggregationFunction);
        end

        function data = computePivotTableStatistics(~, inputData, aggregationFunction)
            % Calculates summary statistics for rows in input table.
            % Input: table (combinedTable from results viewer) with groupId per line
            % Output: table with summary statistics for each row
            % The table needs to contain only the uniform column, not the column with the group names!
    
            % Convert table to array for efficient computation
            dataArray = table2array(inputData);
        
            % Basic statistics (vectorized)
            if isequal(aggregationFunction, 'slope') || isequal(aggregationFunction, 'RSquared')
                summaryTable = array2table(zeros(size(inputData, 1), 2), ...
                    'VariableNames', {'Slope', 'RSquared'}, ...
                    'RowNames', inputData.Properties.RowNames);

                % Slope and R^2 calculations (row-wise)
                x = 1:size(dataArray, 2); % Independent variable
                for i = 1:size(dataArray, 1)
                    rowData = dataArray(i, :);
            
                    % Skip empty rows
                    if all(isnan(rowData))
                        continue;
                    end
            
                    validIdx = ~isnan(rowData);
                    if sum(validIdx) > 1
                        % Fit linear model
                        p = polyfit(x(validIdx), rowData(validIdx), 1);
                        summaryTable.Slope(i) = p(1);
            
                        % Compute R^2
                        yFit = polyval(p, x(validIdx));
                        SSres = sum((rowData(validIdx) - yFit).^2);
                        SStot = sum((rowData(validIdx) - mean(rowData(validIdx))).^2);
                        summaryTable.RSquared(i) = 1 - (SSres / SStot);
                    else
                        summaryTable.Slope(i) = NaN;
                        summaryTable.RSquared(i) = NaN;
                    end

                    if isequal(aggregationFunction, 'slope')
                        data = summaryTable.Slope;
                    elseif isequal(aggregationFunction, 'RSquared')
                        data = summaryTable.RSquared;
                    end
                end
            elseif isequal(aggregationFunction, 'observationCount')
                data = sum(~isnan(dataArray), 2);
            elseif ismember(char(aggregationFunction), {'var', 'std'})
                aggregationFunction = str2func(aggregationFunction);
                data = aggregationFunction(dataArray, 0, 2, 'omitnan');
            elseif ismember(char(aggregationFunction), {'min', 'max'})
                aggregationFunction = str2func(aggregationFunction);
                data = aggregationFunction(dataArray, [], 2, 'omitnan');
            else
                aggregationFunction = str2func(aggregationFunction);
                data = aggregationFunction(dataArray, 2, 'omitnan');
            end
    
        end

        % Validation
        function isValid = validateRulesApplicabilityOnData(obj, inputData)
        % Validates if the rules can be applied to the input data
        % Args: inputData - source data for rules validation
        % Returns: logical indicating validity
        end
    end
end