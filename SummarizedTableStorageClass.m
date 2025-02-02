classdef SummarizedTableStorageClass < handle
    properties
        summarizedTableObjects
    end

    methods
        function obj = SummarizedTableStorageClass()
            obj.summarizedTableObjects = {};
        end


        function addSummarizedTableObject(obj, summarizedTable)
            % summarizedTable - SummarizedTableClass object
            idx = obj.findSummarizedTableIndexByName(summarizedTable.rowParameterName);
            if idx > 0
                disp(['Summarized table of parameter "' summarizedTable.rowParameterName '" already exists. Replaced.']);
                obj.summarizedTableObjects{idx} = summarizedTable;
            else
                obj.summarizedTableObjects{end+1} = summarizedTable;
            end
        end


        function deleteSummarizedTableObject(obj, name)
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


        function names = returnRowParameterNames(obj)
            names = cell(1, numel(obj.summarizedTableObjects));
            for i = 1:numel(obj.summarizedTableObjects)
                cm = obj.summarizedTableObjects{i};
                names{i} = char(cm.rowParameterName);
            end
        end


        function summarizedTableObject = getSummarizedTableObject(obj, name)
            idx = obj.findSummarizedTableIndexByName(name);
            if idx > 0
                summarizedTableObject = obj.summarizedTableObjects{idx};
            else
                summarizedTableObject = [];
            end
        end
    end

end