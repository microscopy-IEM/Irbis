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

    methods (Access = public)
        function setModalityData(obj, modalityPath, modalityData)
            if isempty(modalityPath)    % if no path is provided, set the data to the root
                obj.dataCollection = modalityData;
            else
                obj.dataCollection = setfield(obj.dataCollection, modalityPath{:}, modalityData);
            end
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
            paths = {};
            fields = fieldnames(obj.dataCollection);
            for i = 1:length(fields)
                if isstruct(obj.dataCollection.(fields{i}))
                    subfields = fieldnames(obj.dataCollection.(fields{i}));
                    for j = 1:length(subfields)
                        paths{end+1} = {fields{i}, subfields{j}};
                    end
                else
                    paths{end+1} = {fields{i}};
                end
            end
        end
        
    end
end