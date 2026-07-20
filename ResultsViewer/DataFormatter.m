classdef DataFormatter < handle
    % processes data for plotting, takes them from the selection in shown tables

    % the output should always be a structure with the following fields:
    %   - xData: the x data for the plot    array, size: n x 1 x l (n - number of rows, l - width of the table/cell size)
    %   - yData: the y data for the plot    array, size: n x 1 x l (n - number of rows, l - width of the table/cell size)
    %   - groupData: the group data for the plot (if applicable)    array, size: n x 1 (n - number of rows)
    %   - xLabel: the x label for the plot    string
    %   - yLabel: the y label for the plot    string
    %   - groupLabel: the group label for the plot (if applicable)    string

    properties (Access = private)
        plotManagerHandle
        tableProcessorHandles
        useGrouping
        useIndividual
        useJitter = false;
        requiredParametersNum
        tableTypes

        listener
        plotSpecificListener
        processTimer
        pendingSource = []

        lastProcessedData = [] % stored processed data, to be used when redoing the plot
            % not enough - we might need to get more info
            % can be used when the plotType changes

        storedLastSource = [];
    end

    properties (Constant)
        X_COLUMN_NUM = 1
        Y_COLUMN_NUM = 2
        PROCESS_DEBOUNCE_DELAY_SECONDS = 0.05
    end

    methods
        function obj = DataFormatter(plotManagerHandle, tableProcessorHandles, useGrouping, useIndividual, useJitter, requiredParametersNum, tableTypes)

            obj.plotManagerHandle = plotManagerHandle;
            obj.tableProcessorHandles = tableProcessorHandles;
            obj.useGrouping = useGrouping;
            obj.useIndividual = useIndividual;
            obj.useJitter = useJitter;
            obj.requiredParametersNum = requiredParametersNum;
            obj.tableTypes = tableTypes;

            % Listened table events are debounced because synchronized tables can emit several valid events for one logical change.
            if iscell(obj.tableProcessorHandles)
                obj.listener = cell(1, numel(obj.tableProcessorHandles));
                obj.plotSpecificListener = cell(1, numel(obj.tableProcessorHandles));
                for i = 1:numel(obj.tableProcessorHandles)
                    obj.listener{i} = addlistener(obj.tableProcessorHandles{i}, 'tableSelectionChanged', @(src, ~) obj.requestProcessData(src));
                    obj.plotSpecificListener{i} = addlistener(obj.tableProcessorHandles{i}, 'plotUpdateRequired', @(src, ~) obj.requestProcessData(src));
                end
            else
                obj.listener = addlistener(obj.tableProcessorHandles, 'tableSelectionChanged', @(src, ~) obj.requestProcessData(src));
                obj.plotSpecificListener = addlistener(obj.tableProcessorHandles, 'plotUpdateRequired', @(src, ~) obj.requestProcessData(src));
            end
        end



        function turnGroupingUseOn(obj)
            obj.useGrouping = true;
            obj.processData([]);
        end



        function turnGroupingUseOff(obj)
            obj.useGrouping = false;
            obj.processData([]);
        end



        function turnIndividualUseOn(obj)
            obj.useIndividual = true;
            obj.processData([]);
        end


        
        function turnIndividualUseOff(obj)
            obj.useIndividual = false;
            obj.processData([]);
        end



        function setRequiredParametersNum(obj, num)
            obj.requiredParametersNum = num;
            obj.processData([]);
        end



        function turnJitterOn(obj)
            % currently applied in TwoVariablesPlot, and nowhere else? 
            if ~isempty(obj.lastProcessedData)
                obj.lastProcessedData.useJitter = true;
                obj.plotManagerHandle.plotData(obj.lastProcessedData);
            end
        end



        function turnJitterOff(obj)
            if ~isempty(obj.lastProcessedData)
                obj.lastProcessedData.useJitter = false;
                obj.plotManagerHandle.plotData(obj.lastProcessedData);
            end
        end



        function delete(obj)
            % Destructor for DataFormatter class
            obj.deleteProcessTimer();

            if iscell(obj.listener)
                for i = 1:numel(obj.listener)
                    if isvalid(obj.listener{i})
                        delete(obj.listener{i})
                    end
                end
            else
                if isvalid(obj.listener)
                    delete(obj.listener);
                end
            end

            if iscell(obj.plotSpecificListener)
                for i = 1:numel(obj.plotSpecificListener)
                    if isvalid(obj.plotSpecificListener{i})
                        delete(obj.plotSpecificListener{i})
                    end
                end
            else
                if isvalid(obj.plotSpecificListener)
                    delete(obj.plotSpecificListener);
                end
            end
        end  
        
        
        
        function requestProcessData(obj, src)
            % Schedule formatting after a short event burst so synchronized tables can both report their changes before plotting.
            obj.pendingSource = src;
            obj.ensureProcessTimer();

            if strcmp(obj.processTimer.Running, 'on')
                stop(obj.processTimer);
            end

            start(obj.processTimer);
        end



        function runPendingProcessData(obj)
            % Run one formatting pass for the latest event source after the debounce window has settled.
            src = obj.pendingSource;
            obj.pendingSource = [];
            obj.processData(src);
        end



        function ensureProcessTimer(obj)
            % Create the debounce timer lazily because formatters are replaced whenever the plot setup changes.
            if ~isempty(obj.processTimer) && isvalid(obj.processTimer)
                return
            end

            obj.processTimer = timer('ExecutionMode', 'singleShot', 'StartDelay', obj.PROCESS_DEBOUNCE_DELAY_SECONDS, 'TimerFcn', @(~, ~) obj.runPendingProcessData());
        end



        function deleteProcessTimer(obj)
            % Stop and delete the debounce timer so a delayed callback cannot run after the formatter is replaced.
            if isempty(obj.processTimer)
                return
            end

            if isvalid(obj.processTimer)
                if strcmp(obj.processTimer.Running, 'on')
                    stop(obj.processTimer);
                end

                delete(obj.processTimer);
            end

            obj.processTimer = [];
        end



        function processData(obj, src)
            if isempty(src)
                if isempty(obj.storedLastSource)
                    % disp('DataFormatter:processData:NoSource');
                    return
                end
                src = obj.storedLastSource; % use the last source if none is provided
            end
            obj.storedLastSource = src; % store the last source for later use

            % disp('DataFormatter:processData');
            srcIdx = obj.getHandleIndex(src);
            otherIdx = obj.getOtherHandleIndex(srcIdx);
        
            dataStruct = obj.extractData(srcIdx);

            % check if there are no data in cellArray or cellArray contains no rows
            % 260414: this is happening when selecting objects and triggering row selection in RV - the first step is deselection which makes the data to be plotted empty
            % it might not be sufficient to look just at the last cell, but this is what we use at first
            if isempty(dataStruct.cellArray) || isequal(size(dataStruct.cellArray{end}, 1), 0)
                obj.handleInsufficientParameters();
                return
            end
            
            % If another source exists, integrate or validate additional data
            if ~isempty(otherIdx)
                otherDataStruct = obj.extractData(otherIdx);
                dataStruct = obj.integrateData(dataStruct, otherDataStruct);
            end

            % assignin("base", "dataStruct", dataStruct);

            % Validate parameters and categorization
            if obj.useGrouping
                isGroupingPossible = obj.validateWithGrouping(dataStruct);
                if isGroupingPossible
                    obj.processWithGrouping(dataStruct);
                else
                    % If not valid with categorization, try without
                    valid = obj.validateWithoutGrouping(dataStruct);
                    if valid
                        % warning('Categorization disabled due to insufficient parameters.');
                        obj.processWithoutGrouping(dataStruct);
                    else
                        obj.handleInsufficientParameters();
                    end
                end
            else
                valid = obj.validateWithoutGrouping(dataStruct);
                if valid
                    obj.processWithoutGrouping(dataStruct);
                else
                    obj.handleInsufficientParameters();
                end
            end
        end



        function idx = getHandleIndex(obj, src)
            idx = find(cellfun(@(x) isequal(x, src), obj.tableProcessorHandles), 1);
            if isempty(idx)
                error('Invalid handle provided.');
            end
        end


        
        function otherIdx = getOtherHandleIndex(obj, currentIdx)
            otherIdx = setdiff(1:numel(obj.tableProcessorHandles), currentIdx);
            if isempty(otherIdx)
                otherIdx = [];
            end
        end



        function dataStruct = extractData(obj, idx)
            handle = obj.tableProcessorHandles{idx};
            sourceType = obj.tableTypes{idx};

            % if we combine summarized and pivoted, we need to get only selected rows from the summarized table
            % TO OPTIMIZE - this part is too specific
            if isequal(numel(obj.tableProcessorHandles), 2) && ismember('Pivoted', obj.tableTypes)
                useSelectedRowsInSummarized = true;
            else
                useSelectedRowsInSummarized = false;
            end

            if isequal(sourceType, 'Pivoted')
                if obj.useIndividual
                    [subtable, ~] = handle.getSelected();
                else
                    [subtable, ~] = handle.getSelectedRows();
                end
        
                dataStruct.rowNum = height(subtable);
                dataStruct.isCategorical = false;
                dataStruct.sourceType = sourceType;
                [dataStruct.cellArray, dataStruct.columnNames, dataStruct.columnNum] = obj.convertPivotedTable(subtable);

                % assignin("base", "dataStruct1", dataStruct);
            else
                if obj.useIndividual || useSelectedRowsInSummarized     % TO OPTIMIZE - this is too specific
                    [subtable, isCategorical] = handle.getSelected();
                else
                    [subtable, isCategorical] = handle.getSelectedColumns();
                end
        
                dataStruct.rowNum = height(subtable);
                dataStruct.isCategorical = isCategorical;
                dataStruct.sourceType = sourceType;

                [dataStruct.cellArray, dataStruct.columnNames, dataStruct.columnNum] = obj.convertStandardTable(subtable);
                % assignin("base", "dataStruct2", dataStruct);
            end
        end



        function [arrayCell, columnNames, columnNum] = convertPivotedTable(~, subtable)
            tableArray = table2array(subtable);
            
            % TO OPTIMIZE: this is a problem with the transformed columns with more descriptive column names
            % the plot function has an issue with the array dim
            columnNamesAsDouble = str2double(subtable.Properties.VariableNames);
            if all(~isnan(columnNamesAsDouble))
                columnNamesMatrix = repmat(columnNamesAsDouble, size(tableArray,1), 1);
                columnNum = {2};
            else
                % columnNamesMatrix = [];
                % columnNum = {1};

                % this is a temporary fix:
                columnNamesMatrix = repmat(1:width(subtable), size(tableArray,1), 1);
                columnNum = {2};
            end
        
            permutedTableMatrix = permute(tableArray, [1, 3, 2]);
            if ~isempty(columnNamesMatrix)
                permutedColumnNamesMatrix = permute(columnNamesMatrix, [1, 3, 2]);
                permutedTableMatrix = cat(2, permutedColumnNamesMatrix, permutedTableMatrix);
            end
        
            arrayCell = {permutedTableMatrix};

            if isfield(subtable.Properties.UserData, 'groupedDataParameter') && isfield(subtable.Properties.UserData, 'columnParameter')
                columnNames = {subtable.Properties.UserData.columnParameter, subtable.Properties.UserData.groupedDataParameter};
            else
                columnNames = {'rows'};
            end
        end



        function [arrayCell, columnNames, columnNum] = convertStandardTable(obj, subtable)
            arrayCell = cell(1, width(subtable));
            columnNames = cell(1, width(subtable));
            columnNum = cell(1, width(subtable));
            for columnId = 1:width(subtable)
                columnNames{columnId} = subtable.Properties.VariableNames{columnId};
                if iscell(subtable{:, columnId})
                    dataArray = obj.reorganizeCellArray(subtable{:, columnId});
                    arrayCell{columnId} = dataArray;
                    columnNum{columnId} = size(dataArray, 2);
                else
                    arrayCell{columnId} = subtable{:, columnId};
                    columnNum{columnId} = size(subtable{:, columnId}, 2);
                end
            end
        end



        function integratedData = integrateData(~, primaryData, secondaryData)
            if isempty(primaryData) || isequal(primaryData.rowNum, 0)
                integratedData = secondaryData;
            elseif isempty(secondaryData) || isequal(secondaryData.rowNum, 0)
                integratedData = primaryData;
            else
                % TO OPTIMIZE - if one table has only one row selected, it could be repeated
                if ~isequal(primaryData.rowNum, secondaryData.rowNum)
                    warning('Row numbers do not match between sources.');
                    integratedData = primaryData;
                    return
                end

                % we access it from the end -> 'secondaryData needs to go second
                integratedData.cellArray = [secondaryData.cellArray, primaryData.cellArray];
                integratedData.columnNames = [secondaryData.columnNames, primaryData.columnNames];
                integratedData.columnNum = [secondaryData.columnNum, primaryData.columnNum];
                integratedData.rowNum = primaryData.rowNum;
                integratedData.isCategorical = [secondaryData.isCategorical, primaryData.isCategorical];
            end
        end

        % function preprocessData2(obj, src)
        %     % take all the data from the last selected, use the other table only if some data is missing
        %     % other option - process everything

        %     if numel(obj.tableProcessorHandles) > 1
        %         lastHandleId = cellfun(@(x) isequal(x, src), obj.tableProcessorHandles);
        %         if isempty(lastHandleId)
        %             error('DataFormatter:InvalidHandle', 'The provided handle is not valid.');
        %         end
        %         otherHandle = obj.tableProcessorHandles(~lastHandleId);
        %         otherHandleId = cellfun(@(x) isequal(x, otherHandle), obj.tableProcessorHandles);

        %         lastHandleType = obj.tableTypes{lastHandleId};
        %         otherHandleType = obj.tableTypes{otherHandleId};

        %         if isequal(lastHandleType, 'Pivoted')
        %             if obj.useIndividual
        %                 [subtable, isCategorical] = src.getSelected();
        %             else
        %                 [subtable, isCategorical] = src.getSelectedColumns();
        %             end
        %             % now, I need to convert this to a matrix
        %             tableArray = table2array(subtable);

        %             % try to convert column names to another matrix
        %             columnNamesAsDouble = double(string(subtable.Properties.VariableNames));
        %             if all(~isnan(columnNamesAsDouble))
        %                 columnNamesAsDouble = reshape(columnNamesAsDouble, [1, size(subtable.Properties.VariableNames)]);
        %                 columnNamesMatrix = repmat(columnNamesAsDouble, size(tableArray, 1), 1);
        %             else
        %                 columnNamesMatrix = [];
        %             end

        %             permutedTableMatrix = permute(tableArray, [1, 3, 2]);
        %             if ~isempty(columnNamesMatrix)
        %                 permutedColumnNamesMatrix = permute(columnNamesMatrix, [1, 3, 2]);
        %                 permutedTableMatrix = cat(2, permutedTableMatrix, permutedColumnNamesMatrix);
        %             end 
        %         end
        %     end
        % 
        % end



        function isValid = validateWithGrouping(obj, dataStruct)
            % at least one categorical
            % enough for categorical + required rest
            % this can be increased by having cell columns with more than 1 column

            % TODO: instead of requiring categorical, we could just use colorcoding 
            availableColumnNum = sum([dataStruct.columnNum{:}]);
            hasEnoughColumns = availableColumnNum >= (obj.requiredParametersNum + 1); % +1 for the group column
            % disp(dataStruct.isCategorical)
            % disp(class(dataStruct.isCategorical))
            % disp('was here')
            hasCategorical = any(dataStruct.isCategorical);

            isValid = hasEnoughColumns && hasCategorical;
        end



        function isValid = validateWithoutGrouping(obj, dataStruct)
            % enough for required parameters
            isValid = sum([dataStruct.columnNum{:}]) >= obj.requiredParametersNum;
        end



        function processWithGrouping(obj, dataStruct)
            data = struct('xData', [], 'yData', [], 'groupData', [], 'xLabel', '', 'yLabel', '', 'groupLabel', '');

            groupColumnIdx = find(dataStruct.isCategorical, 1, 'last'); % problem - this takes the categorical from pivoted, which I did not want
            data.groupData = dataStruct.cellArray{groupColumnIdx};
            data.groupLabel = dataStruct.columnNames{groupColumnIdx};

            dataStruct.cellArray(groupColumnIdx) = [];
            dataStruct.columnNames(groupColumnIdx) = [];
            dataStruct.columnNum(groupColumnIdx) = [];
            dataStruct.isCategorical(groupColumnIdx) = [];

            nColumnsLast = dataStruct.columnNum{end};

            if isequal(nColumnsLast, 1)
                data.xData = dataStruct.cellArray{end};
                data.xLabel = dataStruct.columnNames{end};

                if numel(dataStruct.columnNum) > 1
                    nColumnsSecondLast = dataStruct.columnNum{end-1};
                    if isequal(nColumnsSecondLast, 1)
                        data.yData = dataStruct.cellArray{end-1};
                        data.yLabel = dataStruct.columnNames{end-1};
                    else
                        data.yData = dataStruct.cellArray{end-1}(:, 1, :);
                        data.yLabel = dataStruct.columnNames{end-1};
                    end
                end
            else
                assert(obj.X_COLUMN_NUM <= dataStruct.columnNum{end}, ...
                    'X_COLUMN_NUM exceeds the available columns in the current cell.');
                assert(obj.Y_COLUMN_NUM <= dataStruct.columnNum{end}, ...
                    'Y_COLUMN_NUM exceeds the available columns in the current cell.');
                data.xData = dataStruct.cellArray{end}(:, obj.X_COLUMN_NUM, :);
                data.yData = dataStruct.cellArray{end}(:, obj.Y_COLUMN_NUM, :);

                if numel(dataStruct.columnNames) > 1
                    data.xLabel = dataStruct.columnNames{end - 1};
                    data.yLabel = dataStruct.columnNames{end};
                else
                    data.xLabel = sprintf('%s_%d', dataStruct.columnNames{end}, obj.X_COLUMN_NUM);
                    data.yLabel = sprintf('%s_%d', dataStruct.columnNames{end}, obj.Y_COLUMN_NUM);
                end
            end

            data.useJitter = obj.useJitter;
            obj.lastProcessedData = data; 
            obj.plotManagerHandle.plotData(data);
        end



        function processWithoutGrouping(obj, dataStruct)
            data = struct('xData', [], 'yData', [], 'groupData', [], 'xLabel', '', 'yLabel', '', 'groupLabel', '');

            nColumnsLast = dataStruct.columnNum{end};

            if isequal(nColumnsLast, 1)
                data.xData = dataStruct.cellArray{end};
                data.xLabel = dataStruct.columnNames{end};

                if numel(dataStruct.columnNum) > 1
                    nColumnsSecondLast = dataStruct.columnNum{end-1};
                    if isequal(nColumnsSecondLast, 1)
                        data.yData = dataStruct.cellArray{end-1};
                        data.yLabel = dataStruct.columnNames{end-1};
                    else
                        data.yData = dataStruct.cellArray{end-1}(:, 1, :);
                        data.yLabel = dataStruct.columnNames{end-1};
                    end
                end
            else
                assert(obj.X_COLUMN_NUM <= dataStruct.columnNum{end}, ...
                    'X_COLUMN_NUM exceeds the available columns in the current cell.');
                assert(obj.Y_COLUMN_NUM <= dataStruct.columnNum{end}, ...
                    'Y_COLUMN_NUM exceeds the available columns in the current cell.');
                data.xData = dataStruct.cellArray{end}(:, obj.X_COLUMN_NUM, :);
                data.yData = dataStruct.cellArray{end}(:, obj.Y_COLUMN_NUM, :);

                if numel(dataStruct.columnNames) > 1
                    data.xLabel = dataStruct.columnNames{end - 1};
                    data.yLabel = dataStruct.columnNames{end};
                else
                    data.xLabel = sprintf('%s_%d', dataStruct.columnNames{end}, obj.X_COLUMN_NUM);
                    data.yLabel = sprintf('%s_%d', dataStruct.columnNames{end}, obj.Y_COLUMN_NUM);
                end
            end

            data.useJitter = obj.useJitter;
            obj.lastProcessedData = data;
            obj.plotManagerHandle.plotData(data);
        end



        function handleInsufficientParameters(obj)
            % disp('handling insufficient parameters')
            obj.lastProcessedData = [];
            obj.plotManagerHandle.cleanPlot();
            % Handle the case when there are not enough parameters for plotting
            % warning('Insufficient parameters for plotting. Please select more data.');
            % obj.plotManagerHandle.resetPlot(struct('xData', [], 'yData', [], 'groupData', [], 'xLabel', '', 'yLabel', '', 'groupLabel', ''));
        end



        % scenario: 
        % everything empty
        % we have enough tables
            % we do have categorical if needed
            % we do not have categorical
        % we do not have enough tables
            % we have enough but not for categorical
            % we do not have enough tables


        % function processNewData(obj, src)    % TO FIX - not working as expected - gives categories even when not asked for it

        %     data = struct('xData', [], 'yData', [], 'groupData', [], 'xLabel', '', 'yLabel', '', 'groupLabel', '');
        %     xData = [];
        %     yData = [];

        %     if obj.useIndividual
        %         [subtable, isCategorical] = src.getSelected();
        %     else
        %         [subtable, isCategorical] = src.getSelectedColumns();
        %     end

        %     if isempty(subtable)
        %         % empty the plot
        %         obj.plotManagerHandle.resetPlot(data);
        %         return
        %     elseif isequal(width(subtable), 1)
        %         xData = subtable{:, end};
        %         data.xLabel = subtable.Properties.VariableNames{end};

        %     elseif isequal(width(subtable), 2)

        %         if width(subtable) <= obj.requiredParametersNum
        %             xData = subtable{:, end};
        %             data.xLabel = subtable.Properties.VariableNames{end};
        %             yData = subtable{:, end-1};
        %             data.yLabel = subtable.Properties.VariableNames{end-1};
        %         else
        %             idx = find(isCategorical, 1, 'last');
        %             if ~isempty(idx)
        %                 data.groupData = subtable{:, idx};
        %                 data.groupLabel = subtable.Properties.VariableNames{idx};
        %                 remainingTable = subtable(:, setdiff(1:width(subtable), idx));
        %                 xData = remainingTable{:, end};
        %                 data.xLabel = remainingTable.Properties.VariableNames{end};
                        
        %             else
        %                 xData = subtable{:, end};
        %                 data.xLabel = subtable.Properties.VariableNames{end};
        %                 yData = subtable{:, end-1};
        %                 data.yLabel = subtable.Properties.VariableNames{end-1};
        %             end
        %         end

        %     else
        %         idx = find(isCategorical, 1, 'last');
        %         if ~isempty(idx)
        %             data.groupData = subtable{:, idx};
        %             data.groupLabel = subtable.Properties.VariableNames{idx};
        %             remainingTable = subtable(:, setdiff(1:width(subtable), idx));
        %             xData = remainingTable{:, end};
        %             data.xLabel = remainingTable.Properties.VariableNames{end};
        %             yData = remainingTable{:, end-1};
        %             data.yLabel = remainingTable.Properties.VariableNames{end-1};
        %         else
        %             xData = subtable{:, end};
        %             data.xLabel = subtable.Properties.VariableNames{end};
        %             yData = subtable{:, end-1};
        %             data.yLabel = subtable.Properties.VariableNames{end-1};
        %         end
        %     end


        %     % check if xData/yData corresponds to cell
        %     isYDataUsed = true;
        %     if iscell(xData) && isnumeric(xData{1})

        %         dataArray = reorganizeCellArray(obj, xData);
        %         data.xData = dataArray(:, obj.X_COLUMN_NUM, :);
        %         originalLabel = data.xLabel;
        %         data.xLabel = sprintf('%s_%d', data.xLabel, obj.X_COLUMN_NUM);

        %         arraySize = size(dataArray);

        %         if arraySize(2) > 2
        %             isYDataUsed = false;
        %             data.yData = dataArray(:, obj.Y_COLUMN_NUM, :);
        %             data.yLabel = sprintf('%s_%d', originalLabel, obj.Y_COLUMN_NUM);
        %         else 
        %             isYDataUsed = true;
        %         end
        %     else
        %         data.xData = xData;
        %     end

        %     if isYDataUsed && ~isempty(yData)
        %         if iscell(yData) && isnumeric(yData{1})
        %             dataArray = reorganizeCellArray(obj, yData);
        %             data.yData = dataArray(:, obj.X_COLUMN_NUM, :);
        %             data.yLabel = sprintf('%s_%d', data.yLabel, obj.X_COLUMN_NUM); % Added yLabel formatting
                    
        %         else
        %             data.yData = yData;
        %         end
        %     end

        %     obj.plotManagerHandle.plotData(data);

        % end


        function combinedMatrix = reorganizeCellArray(~, cellArray)
            % Determine the number of rows and maximum number of columns

            % Find the longest array in terms of columns
            % [~, longestIdx] = max(cellfun(@(x) size(x, 2), cellArray));
            % numRows = size(cellArray{longestIdx}, 1);
            % maxCols = size(cellArray{longestIdx}, 2);

            numRows = max(cellfun(@(x) size(x, 1), cellArray));
            maxCols = max(cellfun(@(x) size(x, 2), cellArray));

            % assignin("base", "cellArray", cellArray);
            
            % Initialize a 3D matrix with NaNs
            combinedMatrix = nan(numRows, maxCols, numel(cellArray));
        
            % Fill the 3D matrix with padded matrices
            for i = 1:numel(cellArray)
                currentMatrix = cellArray{i};
                numRows = size(currentMatrix, 1);
                numCols = size(currentMatrix, 2);
                
                % Place the current matrix into the 3D matrix with padding
                combinedMatrix(1:numRows, 1:numCols, i) = currentMatrix;
            end

            combinedMatrix = permute(combinedMatrix, [3 2 1]);
        end
    end
end
