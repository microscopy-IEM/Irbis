classdef SummarizedTableStorageClass < handle
    properties
        summarizedTableObjects
    end

    methods
        function obj = SummarizedTableStorageClass()
            obj.summarizedTableObjects = {};
        end


        function addSummarizedTable(obj, summarizedTable)
            idx = obj.findSummarizedTableIndexByName(summarizedTable.rowParameterName);
            if idx > 0
                disp(['Summarized table of parameter "' summarizedTable.rowParameterName '" already exists. Replaced.']);
                obj.summarizedTableObjects{idx} = summarizedTable;
            else
                obj.summarizedTableObjects{end+1} = summarizedTable;
            end
        end


        function deleteSummarizedTable(obj, name)
            idx = obj.findSummarizedTableIndexByName(name);
            if idx > 0
                obj.summarizedTableObjects(idx) = [];
            end
        end


        function idx = findSummarizedTableIndexByName(obj, name)
            idx = -1;
            for i = 1:numel(obj.summarizedTableObjects)
                if strcmp(obj.summarizedTableObjects{i}.rowParameterName, name)
                    idx = i;
                    return;
                end
            end
        end
    end

end