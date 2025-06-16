classdef (Sealed) ModalityDataStore < handle
    %MODALITYDATASTORE Modality data storage
    % it is handle because I need to dynamically update the data stored in the object

    properties (Access = private)
        dataCollection = struct();
    end

    methods
        function obj = ModalityDataStore()
        end
    end

    events
        userColumnDefinitionChanged  % Event triggered when a column definition changes
    end

    methods (Access = public)
        function setModalityData(obj, modalityPath, modalityData)
            if isempty(modalityPath)    % if no path is provided, set the data to the root
                obj.dataCollection = modalityData;
            else
                obj.dataCollection = setfield(obj.dataCollection, modalityPath{:}, modalityData);
            end

            obj.addUserColumnDefinitionChangeListener(modalityPath, modalityData);
        end

        function modalityData = getModalityData(obj, modalityPath)
            if isempty(modalityPath)  % if no path is provided, get the data from the root
                modalityData = obj.dataCollection;
            else
                modalityData = getfield(obj.dataCollection, modalityPath{:});
            end
        end

        function paths = getAvailableModalityPaths(obj)
            % Returns a cell array of all available modality paths in the data collection

            % NOTE - I could preallocate paths, but that would require counting the number of fields
            %   meaning I would need to do one more for loop
            %   for about 10 fields, it is probably not worth it

            paths = {};
            fields = fieldnames(obj.dataCollection);
            for i = 1:length(fields)
                if isstruct(obj.dataCollection.(fields{i}))
                    subfields = fieldnames(obj.dataCollection.(fields{i}));
                    for j = 1:length(subfields)
                        paths{end+1} = {fields{i}, subfields{j}};
                    end
                else
                    paths{end+1} = fields(i);
                end
            end
        end


        function addUserColumnDefinitionChangeListener(obj, modalityPath, modalityData)
            % Adds a listener for user column definition changes
            % listenerFunction should be a function handle that takes an event as input
            % modalityPath specifies the starting path for traversal
            % Add listener for changes in each of the leaf nodes

            obj.traverseAndAddListener(modalityPath, modalityData);
        end


        function notifyUserColumnDefinitionChange(obj, modalityPath, ~, event)
            % Notify the user about the column definition change
            % This method is called when a column definition change occurs
            % It creates a ColumnDefinitionEvent and notifies the listeners

            if isempty(modalityPath)
                disp(['Column definition changed in the root: ', event.name, ' - ', event.typeOfChange]);
            else
                disp(['Column definition changed in ', strjoin(modalityPath, '.'), ': ', event.name, ' - ', event.typeOfChange]);
            end

            event.setModalityPath(modalityPath);  % Add the modality path to the event for context
            
            notify(obj, 'userColumnDefinitionChanged', event);
        end  
    end


    methods (Access = ?matlab.unittest.TestCase)
        function traverseAndAddListener(obj, currentPath, data)
            if isstruct(data)
                fields = fieldnames(data);
                for i = 1:length(fields)
                    obj.traverseAndAddListener([currentPath, {fields{i}}], data.(fields{i}));
                end
            else
                addlistener(data, 'userColumnDefinitionChanged', @(src, event) obj.notifyUserColumnDefinitionChange(currentPath, src, event));
            end
        end
    end
end