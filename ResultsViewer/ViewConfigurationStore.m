classdef ViewConfigurationStore < handle
    properties
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
        function promptViewsImport(obj)
            [filename, pathname] = uigetfile({'*.mat', 'MAT-files (*.mat)'}, 'Import stored views from');
            if ~isempty(filename) || isequal(filename, 0)
                fullPath = fullfile(pathname, filename);
                obj.importViewsFromFile(fullPath);
            end
        end


        function importViewsFromFile(obj, filename)
            loadedData = load(filename);
            if isfield(loadedData, 'viewsStruct')
                viewsStruct = loadedData.viewsStruct;
                obj.importViewsFromStruct(viewsStruct);
            else
                error('Invalid file format. Expected a structure named "viewsStruct".');
            end
        end


        function importViewsFromStruct(obj, viewsStruct)
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