classdef ViewConfigurationStore < handle
    properties (Access = private)
        storedViews = {}    % Cell array of viewConfiguration objects
    end
    
    methods
        function obj = ViewConfigurationStore()
            obj.storedViews = {};
        end


        function addView(obj, viewConfiguration)
            obj.storedViews{end+1} = viewConfiguration;
        end


        function deleteView(obj, name)
            idx = obj.getIndexByName(name);
            if idx > 0
                obj.storedViews(idx) = [];
            end
        end


        %% Export to file with structures
        function promptViewsExport(obj)
            [filename, pathname] = uiputfile({'*.mat', 'MAT-files (*.mat)'}, 'Export stored views as');
            if ~isempty(filename) || isequal(filename, 0)
                fullPath = fullfile(pathname, filename);
                obj.exportViewsAsStructInMat(fullPath);
            end
        end



        function promptSelectedViewExport(obj, viewName)
            [filename, pathname, formatIdx] = uiputfile({'*.mat'; '*.json'}, 'Export stored views as', [userpath '\' char(viewName)]);
            if isequal(formatIdx, 0) % user canceled the dialog
                return
            end 

            fullPath = fullfile(pathname, filename);
            selectedView = obj.getViewByName(viewName);
            viewConfig = selectedView.getConfiguration();

            if isequal(formatIdx, 1) % user selected .mat format
                save(fullPath, 'viewConfig', 'viewName');
            elseif isequal(formatIdx, 2) % user selected .json format
                obj.exportViewAsJson(fullPath, viewName, viewConfig);
            end
        end



        function exportViewAsJson(~, filePath, viewName, viewConfig)
            viewStruct = struct('viewName', viewName, 'viewConfig', viewConfig);
            jsonStr = jsonencode(viewStruct);
            fid = fopen(filePath, 'w');
            if fid == -1
                error('Cannot open file for writing: %s', filePath);
            end
            fwrite(fid, jsonStr, 'char');
            fclose(fid);
        end
        


        function exportViewsAsStructInMat(obj, filePath)
            viewsStruct = obj.convertStoredViewsToStruct();
            save(filePath, 'viewsStruct');
        end



        function viewsStruct = convertStoredViewsToStruct(obj)
            viewsStruct = struct();
            for i = 1:length(obj.storedViews)
                viewName = obj.storedViews{i}.getViewName();
                viewsStruct.(viewName) = obj.storedViews{i}.getConfiguration();
            end
        end


        %% Import from file with structures
        function newViewNames = promptViewsImport(obj)
            [filename, pathname] = uigetfile({'*.mat'; '*.json'}, 'Import stored views from');
            if ~isempty(filename) || isequal(filename, 0)
                fullPath = fullfile(pathname, filename);
                newViewNames = obj.importViewsFromFile(fullPath);
            end
        end


        function newViewNames = importViewsFromFile(obj, filename)
            newViewNames = {};
            if endsWith(filename, '.json')
                    newViewNames = obj.importViewsFromJson(filename);
                else
                loadedData = load(filename);
                if isfield(loadedData, 'viewsStruct')
                    viewsStruct = loadedData.viewsStruct;
                    newViewNames = obj.importViewsFromStruct(viewsStruct);
                elseif isfield(loadedData, 'viewConfig') && isfield(loadedData, 'viewName')
                    viewName = loadedData.viewName;
                    viewConfig = loadedData.viewConfig;
                    newView = ViewConfiguration(viewName, viewConfig);
                    obj.addView(newView);
                    newViewNames{end + 1} = viewName;
                else
                    error('Invalid file format. Expected a structure named "viewsStruct".');
                end
            end
        end



        function newViewNames = importViewsFromJson(obj, filename)
            newViewNames = {};
            rawData = fileread(filename);
            jsonData = jsondecode(rawData);

            if isfield(jsonData, 'viewName') && isfield(jsonData, 'viewConfig')
                newView = ViewConfiguration(jsonData.viewName, jsonData.viewConfig);
                obj.addView(newView);
                newViewNames{end + 1} = jsonData.viewName;
            else
                error('Invalid JSON format. Expected fields "viewName" and "viewConfig".');
            end
        end



        function viewNames = importViewsFromStruct(obj, viewsStruct)
            viewNames = fieldnames(viewsStruct);
            for i = 1:length(viewNames)
                viewName = viewNames{i};
                configuration = viewsStruct.(viewName);
                newView = ViewConfiguration(viewName, configuration);
                obj.addView(newView);
            end
        end


        %% Getters 
        function viewNamesList = getViewNamesList(obj)
            viewNamesList = cell(1, length(obj.storedViews));
            for i = 1:length(obj.storedViews)
                viewNamesList{i} = obj.storedViews{i}.getViewName();
            end
        end


        function viewConfiguration = getViewByName(obj, name)
            idx = obj.getIndexByName(name);
            if idx > 0
                viewConfiguration = obj.storedViews{idx};
            else
                viewConfiguration = [];
            end
        end

        
        function index = getIndexByName(obj, name)
            index = -1;
            for i = 1:length(obj.storedViews)
                if strcmp(obj.storedViews{i}.getViewName(), name)
                    index = i;
                    break;
                end
            end
        end
    end
end