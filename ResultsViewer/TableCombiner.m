classdef TableCombiner
    methods (Static)
        function combinedTable = combineAcrossTimepoints(cellList, currentIndex)
            if istable(cellList)
                combinedTable = cellList;
                disp('Only one time point provided.');
                return;
            end

            combinedTable = table();
            [allColumns, allClasses, conflicts] = TableCombiner.analyzeColumns(cellList);
            [allColumns, allClasses] = TableCombiner.removeConflicts(allColumns, allClasses, conflicts);
            timePoints = TableCombiner.resolveTimePoints(cellList, currentIndex);

            for idx = 1:numel(cellList)
                T = cellList{idx};
                if istable(T) && ~isempty(T)
                    T = TableCombiner.dropConflictingColumns(T, conflicts);
                    T = TableCombiner.addMissingColumns(T, allColumns, allClasses);
                    T = TableCombiner.addRowIdentifiers(T, idx);    % BE CAREFUL HERE
                    % using idx is not as informative, but it might happen that the same table corresponds to multiple timepoints
                        % while the idx is unique
                    T = TableCombiner.addTimeAndCellIndex(T, timePoints(idx), idx);

                    try
                        if ~isempty(combinedTable)
                            T = T(:, combinedTable.Properties.VariableNames);
                        end
                        combinedTable = [combinedTable; T];
                    catch ME
                        disp(['Error combining table at index ' num2str(idx) ': ' ME.message]);
                        combinedTable = [];
                        return;
                    end
                end
            end
        end

        function combinedTable = mergeCombinedTables(cellList)  % here, I already expect existence of timePoints in the table
            combinedTable = table();
            [allColumns, allClasses, conflicts] = TableCombiner.analyzeColumns(cellList);
            [allColumns, allClasses] = TableCombiner.removeConflicts(allColumns, allClasses, conflicts);
            
            usedFileIds = [];

            for idx = 1:numel(cellList)
                T = cellList{idx};

                if ~istable(T) || isempty(T)
                    continue;
                end

                T = TableCombiner.dropConflictingColumns(T, conflicts);
                T = TableCombiner.addMissingColumns(T, allColumns, allClasses);
                [T, usedFileIds] = TableCombiner.assignUniqueFileId(T, idx, usedFileIds);
                T = TableCombiner.makeRowIdentifiersUnique(T, idx);

                try
                    if ~isempty(combinedTable)
                        T = T(:, combinedTable.Properties.VariableNames);
                    end
                    combinedTable = [combinedTable; T];
                catch ME
                    disp(['Error merging table at index ' num2str(idx) ': ' ME.message]);
                    combinedTable = [];
                    return;
                end
            end
        end
    end

    methods (Static, Access = private)
        function [names, classes, conflicts] = analyzeColumns(cellList)
            names = {};
            classes = {};

            for i = 1:numel(cellList)
                T = cellList{i};
                if istable(T)
                    names = [names, T.Properties.VariableNames];
                    classes = [classes, varfun(@class, T, 'OutputFormat', 'cell')];
                end
            end

            [names, ia] = unique(names, 'stable');
            classes = classes(ia);

            conflicts = {};
            for i = 1:length(names)
                name = names{i};
                indices = find(strcmp(names, name));
                if numel(indices) > 1
                    types = unique(classes(indices));
                    if numel(types) > 1
                        conflicts{end+1} = name;
                        warning('Conflicting data types for column "%s". It will be excluded.', name);
                    end
                end
            end
        end

        function [names, classes] = removeConflicts(names, classes, conflicts)
            for col = conflicts
                idx = strcmp(names, col{1});
                names(idx) = [];
                classes(idx) = [];
            end
        end

        function T = dropConflictingColumns(T, conflicts)
            for col = conflicts
                if ismember(col{1}, T.Properties.VariableNames)
                    T(:, col{1}) = [];
                end
            end
        end

        function T = addMissingColumns(T, allCols, allClasses)
            missing = setdiff(allCols, T.Properties.VariableNames);
            for col = missing
                idx = strcmp(allCols, col);
                T.(col{1}) = TableCombiner.defaultValue(allClasses{idx}, height(T));
            end
        end

        function timePoints = resolveTimePoints(cellList, currentIndex)
            n = numel(cellList);
            timePoints = nan(1, n);
            for i = 1:n
            timePoint = find(currentIndex == i, 1);     % it might be possible that one table corresponds to more time points - we do not count with that
            if ~isempty(timePoint)
                timePoints(i) = timePoint;
            end
            end
        end

        function T = addRowIdentifiers(T, idx)
            if ~isempty(T.Properties.RowNames)
                T.id = categorical(T.Properties.RowNames);  % CAREFUL, CHANGE 250421 - before, this was a cell
                T.Properties.RowNames = strcat(T.Properties.RowNames, '_', num2str(idx));
            end
        end

        function T = addTimeAndCellIndex(T, tp, cellIdx)
            if ~ismember('timePoint', T.Properties.VariableNames)
                T.timePoint = repmat(tp, height(T), 1);
            end
            T.timePoint = categorical(T.timePoint); % this is because atm, the ResultsViewer expects this
            % reorder the timepoints in ascending order
            % this is needed to prevent weird order of timepoints in pivoted tables
            if all(cellfun(@(x) ~isnan(str2double(x)), categories(T.timePoint)))
                % TO OPTIMIZE - the condition counts with categories being strings
                numericCategories = sort(str2double(categories(T.timePoint)));
                T.timePoint = reordercats(T.timePoint, string(numericCategories));
            end

            if ~ismember('cellIndex', T.Properties.VariableNames)
                T.cellIndex = repmat(cellIdx, height(T), 1);
            end
            T.cellIndex = categorical(T.cellIndex);

            if ismember('groupId', T.Properties.VariableNames)
                T.groupId = categorical(T.groupId);
            end
        end

        function val = defaultValue(className, nRows)
            switch className
                case 'double',     val = NaN(nRows, 1);
                case 'categorical',val = repmat(categorical(missing), nRows, 1);
                case 'logical',    val = false(nRows, 1);
                case 'datetime',   val = NaT(nRows, 1);
                case 'cell',       val = cell(nRows, 1);
                case 'string',     val = strings(nRows, 1);
                otherwise,         error('Unhandled data type: %s', className);
            end
        end

        function [T, usedFileIds] = assignUniqueFileId(T, idx, usedFileIds) 
            % Ensures T.fileId exists and that all fileIds are globally unique.
            % For any reused or invalid fileId, assigns a new numeric categorical value.

            % Create default fileId if missing
            if ~ismember('fileId', T.Properties.VariableNames)
                warning('Table at index %d is missing fileId column. Assigning default.', idx);
                newId = TableCombiner.getNextAvailableId(usedFileIds);
                T.fileId = categorical(repmat(newId, height(T), 1));
                usedFileIds(end+1) = newId;
                return;
            end

            % Normalize to categorical
            if ~iscategorical(T.fileId)
                T.fileId = categorical(T.fileId);
            end

            % Go through each unique fileId in the table
            originalIds = categories(T.fileId);
            idAssignments = configureDictionary("double", "double");
            for i = 1:numel(originalIds)
                origStr = string(originalIds{i});
                origNum = str2double(origStr);

                % Determine if this fileId needs to be replaced
                needsReplace = isnan(origNum) || ismember(origNum, usedFileIds);
                if needsReplace
                    newId = TableCombiner.getNextAvailableId(usedFileIds);
                    idAssignments(origNum) = newId;
                    usedFileIds(end+1) = newId;
                else
                    usedFileIds(end+1) = origNum;
                end
            end

            if isempty(keys(idAssignments))
                return
            end

            sortedKeys = sort(keys(idAssignments), 'descend'); % descending to avoid replacing a newly assigned id in the same pass
            % NOTE: we assume that the new ids will always be higher than the original ones
            for i = 1:numel(sortedKeys)
                originalFileId = sortedKeys(i);
                % Replace all rows with this fileId
                matchIdx = ismember(double(T.fileId), originalFileId);
                newFileId = idAssignments(originalFileId);
                T.fileId(matchIdx) = categorical(repmat(newFileId, sum(matchIdx), 1));
            end

            % FIXED: this script fails if the lowest fileId is replaced with another that is already in the table 
            %   For example, if we replace 1 with 2 but that one is already in the table, we keep replacing more and more
            % needsReplace = isnan(origNum) || ismember(origNum, usedFileIds);
            % if needsReplace
            %     newId = TableCombiner.getNextAvailableId(usedFileIds);

            %     % Replace all rows with this fileId
            %     matchIdx = T.fileId == origStr;
            %     T.fileId(matchIdx) = categorical(repmat(newId, sum(matchIdx), 1));

            %     usedFileIds(end+1) = newId;
            % else
            %     usedFileIds(end+1) = origNum;
            % end

            % % TO OPTIMIZE - this does not work properly if there are more fileIds in the not first file
            % % fileId should be a categorical variable, with values corresponding to unique numbers from 1 onwards
            % if ~ismember('fileId', T.Properties.VariableNames)
            %     warning('Table at index %d is missing fileId column. Assigning default.', idx);
            %     T.fileId = categorical(repmat(idx, height(T), 1));
            % end

            % originalId = unique(T.fileId);
            % newId = originalId;
            % iterator = 1;

            % while any(ismember(string(newId), string(usedFileIds)))
            %     newId = iterator;
            %     iterator = iterator + 1;
            % end

            % if ~isequal(string(newId), string(originalId))
            %     T.fileId(:) = categorical(newId);
            % end
            % usedFileIds(end+1) = newId; % my original idea was to have it as strings, but unique does not work on strings
            %     % Idea with strings (abandoned):
            %         % I am storing strings even though I expect fileId to be numeric category
            %         % this is a precaution in case someone decides to use some other value for fileId - converting to string should be safer 
        end

        function nextId = getNextAvailableId(usedIds)
            nextId = 1;
            while ismember(nextId, usedIds)
                nextId = nextId + 1;
            end
        end

        function T = makeRowIdentifiersUnique(T, idx)
            if isempty(T.Properties.RowNames)
                warning('Table at index %d is missing RowNames. Generating new ones.', idx);
                T.Properties.RowNames = strcat(string(1:height(T))', "_1");
            end

            rowNames = T.Properties.RowNames;
            splitNames = split(rowNames, "_");  % This is to clean up already combined tables from the fileId part
            if size(splitNames, 2) > 2
                rowNames = join(splitNames(:, 1:2), "_");
            end

            fileIds = string(T.fileId);

            newRowNames = strcat(rowNames, "_", fileIds);
            T.Properties.RowNames = newRowNames;
        end
    end
end
