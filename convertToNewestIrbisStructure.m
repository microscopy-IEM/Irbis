function newIrbisStruct = convertToNewestIrbisStructure(irbisStruct,currentVersion,fileVersion)
% back-compatibility script

% how to deal with things that should be defined and are not? 

% timePointPresent (points_edited.irbis)

% app.results.fileName to info

%% planes

            % back-compatibility
            if isfield(planes,'channel_names') && ~isfield(planes,'channelNames')
                disp('there are channel_names but not channelNames')
                planes.channelNames = planes.channel_names;
            end
            % /back-compatibility


%% tracks
% delete if there is only timePointPresent

            % back-compatibility
            if iscell(tracksToLoad) % the old structure
                if ~isempty(tracksToLoad)
                    disp('old tracks structure')
                    % Get the number of time points
                    numTimePoints = numel(tracksToLoad);
                    
                    % List all variables (assuming all time points have the same structure)
                    fieldNames = fieldnames(tracksToLoad{1});
                    
                    % Initialize the new structure to hold variables across time points
                    for i = 1:numel(fieldNames)
                        app.tracks.(fieldNames{i}) = cell(1, numTimePoints);
                    end
                    
                    % Fill the new structure with the reorganized data
                    for t = 1:numTimePoints
                        for i = 1:numel(fieldNames)
                            variableName = fieldNames{i};
                            app.tracks.(variableName){t} = tracksToLoad{t}.(variableName);
                        end
                    end
                end
                % /back-compatibility

            else
                % back-compatibility
                if ~isfield(tracksToLoad,'tracksList')
                    return
                end
                % /back-compatibility

            end   

            % back-compatibility
            if isfield(app.tracks,'filterRanges')
                % convert the old filter storage to the new version
                if ~isempty(app.tracks.filterRanges)
                    columnNames = fieldnames(app.tracks.filterRanges);
                    storedFilterNames = app.tracks.storedFilters.returnGroupingNames;
                    for i = 1:numel(columnNames)
                        columnName = columnNames{i};
                        range = app.tracks.filterRanges.(columnName);

                        if ismember(columnName,storedFilterNames)
                            app.tracks.storedFilters.deleteGrouping(columnName);
                        end
                        app.tracks.storedFilters.addRangeFilter(columnName,range);
                    end
                end
                app.tracks = rmfield(app.tracks,'filterRanges');
            end

            if isfield(app.tracks,'groupThresholds')
                app.createCategorizationsFromThresholds;
            end
            % /back-compatibility
end