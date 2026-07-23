classdef DataFormatter < handle
    % processes data for plotting, takes them from the selection in shown tables

    % the output should always be a structure with the following fields:
    %   - xData: the x data for the plot    array, size: n x 1 x l (n - number of rows, l - width of the table/cell size)
    %   - yData: the y data for the plot    array, size: n x 1 x l (n - number of rows, l - width of the table/cell size)
    %   - groupData: the group data for the plot (if applicable)    array, size: n x 1 (n - number of rows)
    %   - colorData: the colorcoding data for the plot (if applicable)    array, size depends on colorScope
    %   - xLabel: the x label for the plot    string
    %   - yLabel: the y label for the plot    string
    %   - groupLabel: the group label for the plot (if applicable)    string
    %   - colorLabel: the colorcoding label for the plot (if applicable)    string

    properties (Access = private)
        plotManagerHandle
        tableProcessorHandles
        useGrouping
        useIndividual
        useJitter = false;
        requiredParametersNum
        tableTypes
        plotType = ""

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
        function obj = DataFormatter(plotManagerHandle, tableProcessorHandles, useGrouping, useIndividual, useJitter, requiredParametersNum, tableTypes, plotType)
            if nargin < 8
                plotType = "";
            end

            obj.plotManagerHandle = plotManagerHandle;
            obj.tableProcessorHandles = tableProcessorHandles;
            obj.useGrouping = useGrouping;
            obj.useIndividual = useIndividual;
            obj.useJitter = useJitter;
            obj.requiredParametersNum = requiredParametersNum;
            obj.tableTypes = tableTypes;
            obj.plotType = string(plotType);

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



        function setPlotType(obj, plotType)
            % Plot type affects optional role selection.
            % For example, it decides whether a numeric extra column can become continuous color data.
            % It is kept separate from requiredParametersNum because several plot types need the same number of required parameters but support different roles.
            obj.plotType = string(plotType);
        end



        function turnJitterOn(obj)
            % currently applied in TwoVariablesPlot, and nowhere else? 
            obj.useJitter = true;
            if ~isempty(obj.lastProcessedData)
                obj.lastProcessedData.useJitter = true;
                obj.plotManagerHandle.plotData(obj.lastProcessedData);
            end
        end



        function turnJitterOff(obj)
            obj.useJitter = false;
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
            if obj.shouldReplacePendingSource(src)
                obj.pendingSource = src;
            end

            obj.ensureProcessTimer();

            if strcmp(obj.processTimer.Running, 'on')
                stop(obj.processTimer);
            end

            start(obj.processTimer);
        end



        function tf = shouldReplacePendingSource(obj, src)
            if isempty(obj.pendingSource)
                tf = true;
                return
            end

            pendingIdx = obj.getHandleIndex(obj.pendingSource);
            srcIdx = obj.getHandleIndex(src);

            pendingType = obj.tableTypes{pendingIdx};
            srcType = obj.tableTypes{srcIdx};

            if isequal(srcType, 'Pivoted') && ~isequal(pendingType, 'Pivoted')
                tf = true;
            elseif isequal(pendingType, 'Pivoted') && ~isequal(srcType, 'Pivoted')
                tf = false;
            else
                tf = true;
            end
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
                dataStruct.rowNames = obj.getTableRowNames(subtable);

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
                dataStruct.rowNames = obj.getTableRowNames(subtable);
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
                columnNames = {{subtable.Properties.UserData.columnParameter, subtable.Properties.UserData.groupedDataParameter}};
            else
                columnNames = {{'column', 'value'}};
            end
        end



        function [arrayCell, columnNames, columnNum] = convertStandardTable(obj, subtable)
            arrayCell = cell(1, width(subtable));
            columnNames = cell(1, width(subtable));
            columnNum = cell(1, width(subtable));
            for columnId = 1:width(subtable)
                baseName = subtable.Properties.VariableNames{columnId};
                if iscell(subtable{:, columnId})
                    dataArray = obj.reorganizeCellArray(subtable{:, columnId});
                    arrayCell{columnId} = dataArray;
                    columnNum{columnId} = size(dataArray, 2);
                else
                    arrayCell{columnId} = subtable{:, columnId};
                    columnNum{columnId} = size(subtable{:, columnId}, 2);
                end
                columnNames{columnId} = obj.makeBlockColumnLabels(baseName, columnNum{columnId});
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
                integratedData.rowNames = primaryData.rowNames;
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
            % Grouping is now treated as a color role, not only as a categorical-only mode.
            % A categorical block is still preferred because all existing grouped plots understand categorical groups.
            % Numeric color data is only accepted for plot types that explicitly know how to draw a continuous color channel.
            colorColumnIdx = obj.chooseColorBlock(dataStruct);
            isValid = ~isempty(colorColumnIdx);
        end



        function isValid = validateWithoutGrouping(obj, dataStruct)
            % enough for required parameters
            isValid = sum([dataStruct.columnNum{:}]) >= obj.requiredParametersNum;
        end



        function processWithGrouping(obj, dataStruct)
            data = obj.createEmptyPlotData();
            data.rowNames = dataStruct.rowNames;

            colorColumnIdx = obj.chooseColorBlock(dataStruct);
            if isempty(colorColumnIdx)
                obj.handleInsufficientParameters();
                return
            end

            data.colorData = dataStruct.cellArray{colorColumnIdx};
            colorLabels = obj.getBlockLabels(dataStruct, colorColumnIdx);
            data.colorLabel = colorLabels{1};
            data.colorType = obj.classifyColorData(data.colorData);
            data.colorScope = obj.getColorScope();

            if data.colorType == "categorical"
                % Keep the legacy group fields populated for existing plotters.
                % New plotters can read colorData/colorType.
                % Older grouped plotters continue to work with groupData/groupLabel unchanged.
                data.groupData = data.colorData;
                data.groupLabel = data.colorLabel;
            end

            dataStruct.cellArray(colorColumnIdx) = [];
            dataStruct.columnNames(colorColumnIdx) = [];
            dataStruct.columnNum(colorColumnIdx) = [];
            dataStruct.isCategorical(colorColumnIdx) = [];

            data = obj.addXYDataAndLabels(data, dataStruct);

            data.useJitter = obj.useJitter;
            obj.lastProcessedData = data; 
            obj.plotManagerHandle.plotData(data);
        end



        function processWithoutGrouping(obj, dataStruct)
            data = obj.createEmptyPlotData();
            data.rowNames = dataStruct.rowNames;

            data = obj.addXYDataAndLabels(data, dataStruct);

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


        function data = addXYDataAndLabels(obj, data, dataStruct)
            % x/y labels must be read from the same data block as x/y data.
            % Pivoted tables are represented as one data block with two internal
            % columns, while standard tables are usually one block per table
            % column. Keeping labels block-local prevents a grouping column from
            % shifting the label indices of a pivoted x/y pair.
            nColumnsLast = dataStruct.columnNum{end};
            lastLabels = obj.getBlockLabels(dataStruct, numel(dataStruct.columnNum));

            if isequal(nColumnsLast, 1)
                data.xData = dataStruct.cellArray{end};
                data.xLabel = lastLabels{1};

                if numel(dataStruct.columnNum) > 1
                    nColumnsSecondLast = dataStruct.columnNum{end-1};
                    secondLastLabels = obj.getBlockLabels(dataStruct, numel(dataStruct.columnNum) - 1);
                    if isequal(nColumnsSecondLast, 1)
                        data.yData = dataStruct.cellArray{end-1};
                        data.yLabel = secondLastLabels{1};
                    else
                        data.yData = dataStruct.cellArray{end-1}(:, 1, :);
                        data.yLabel = secondLastLabels{1};
                    end
                end
            else
                assert(obj.X_COLUMN_NUM <= dataStruct.columnNum{end}, ...
                    'X_COLUMN_NUM exceeds the available columns in the current cell.');
                assert(obj.Y_COLUMN_NUM <= dataStruct.columnNum{end}, ...
                    'Y_COLUMN_NUM exceeds the available columns in the current cell.');
                data.xData = dataStruct.cellArray{end}(:, obj.X_COLUMN_NUM, :);
                data.yData = dataStruct.cellArray{end}(:, obj.Y_COLUMN_NUM, :);
                data.xLabel = lastLabels{obj.X_COLUMN_NUM};
                data.yLabel = lastLabels{obj.Y_COLUMN_NUM};
            end
        end



        function data = createEmptyPlotData(~)
            % The formatter has one canonical output shape.
            % Keeping the optional color fields present even when they are empty means plotters can check capabilities without guarding every field access.
            data = struct( ...
                'xData', [], ...
                'yData', [], ...
                'groupData', [], ...
                'colorData', [], ...
                'xLabel', '', ...
                'yLabel', '', ...
                'groupLabel', '', ...
                'colorLabel', '', ...
                'colorType', "none", ...
                'colorScope', "none", ...
                'rowNames', strings(0, 1));
        end



        function rowNames = getTableRowNames(~, subtable)
            % Row names are lightweight plot metadata for datatips and future selection links.
            % If a table has no row names, fall back to displayed row numbers so the datatip remains informative.
            if isempty(subtable.Properties.RowNames)
                rowNames = string((1:height(subtable))');
            else
                rowNames = string(subtable.Properties.RowNames(:));
            end
        end



        function colorColumnIdx = chooseColorBlock(obj, dataStruct)
            % Select one optional block for colorcoding while leaving enough data behind for the actual plot parameters.
            % This prevents a categorical x-axis from being stolen as grouping when the user selected only the two columns needed for a two-variable plot.
            colorColumnIdx = [];

            if isempty(dataStruct.cellArray)
                return
            end

            candidateIdx = find(cellfun(@(columnCount) isequal(columnCount, 1), dataStruct.columnNum));
            candidateIdx = candidateIdx(arrayfun(@(idx) obj.hasEnoughColumnsAfterRemoving(dataStruct, idx), candidateIdx));

            categoricalCandidates = candidateIdx(dataStruct.isCategorical(candidateIdx));
            if ~isempty(categoricalCandidates)
                colorColumnIdx = categoricalCandidates(end);
                return
            end

            if ~obj.supportsNumericColorcoding()
                return
            end

            numericCandidates = candidateIdx(arrayfun(@(idx) obj.isNumericColorCandidate(dataStruct.cellArray{idx}), candidateIdx));
            if ~isempty(numericCandidates)
                colorColumnIdx = numericCandidates(end);
            end
        end



        function tf = hasEnoughColumnsAfterRemoving(obj, dataStruct, removedIdx)
            remainingColumnNum = dataStruct.columnNum;
            remainingColumnNum(removedIdx) = [];

            if isempty(remainingColumnNum)
                tf = false;
                return
            end

            tf = sum([remainingColumnNum{:}]) >= obj.requiredParametersNum;
        end



        function tf = supportsNumericColorcoding(obj)
            % Continuous color needs plot-specific rendering support.
            % Other plots deliberately remain categorical-only so a random numeric column does not change the meaning of histograms, ratios, or averaged lines.
            tf = ismember(obj.plotType, ["two variables", "line: individual"]);
        end



        function tf = isNumericColorCandidate(~, data)
            tf = isnumeric(data) || islogical(data);
        end



        function colorType = classifyColorData(~, colorData)
            if iscategorical(colorData)
                colorType = "categorical";
            elseif isnumeric(colorData) || islogical(colorData)
                colorType = "numeric";
            else
                colorType = "none";
            end
        end



        function colorScope = getColorScope(obj)
            % Scope tells plotters how to interpret colorData.
            % Scatter plots use one color value per point; individual line plots use one color value per line; categorical legacy plots use colorData as a grouping key.
            switch obj.plotType
                case "two variables"
                    colorScope = "point";
                case "line: individual"
                    colorScope = "line";
                otherwise
                    colorScope = "group";
            end
        end



        function labels = getBlockLabels(obj, dataStruct, blockIdx)
            % Return labels for the internal columns of one data block.
            % Older saved/debug data may still contain a flat label, so normalize
            % defensively to keep formatter behavior stable while the internal
            % representation is block-aligned.
            labels = dataStruct.columnNames{blockIdx};
            labels = obj.normalizeBlockLabels(labels);

            expectedNum = dataStruct.columnNum{blockIdx};
            if numel(labels) < expectedNum
                baseName = labels{1};
                labels = obj.makeBlockColumnLabels(baseName, expectedNum);
            end
        end



        function labels = normalizeBlockLabels(~, labels)
            if isstring(labels)
                labels = cellstr(labels);
            elseif ischar(labels)
                labels = {labels};
            elseif ~iscell(labels)
                labels = {char(string(labels))};
            end
        end



        function labels = makeBlockColumnLabels(~, baseName, columnCount)
            % Create one label per internal column of a data block. Single-column
            % standard table fields keep their original name; multi-column fields
            % get stable suffixes so each internal dimension can be labelled.
            baseName = char(string(baseName));
            if columnCount <= 1
                labels = {baseName};
                return
            end

            labels = arrayfun( ...
                @(columnId) sprintf('%s_%d', baseName, columnId), ...
                1:columnCount, ...
                'UniformOutput', false);
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
