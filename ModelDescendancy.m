classdef (Sealed) ModelDescendancy 
    methods (Static)
        function T = addDescendants(T, rowName, descendantBranch, descendantRowIds)
            arguments
                T table
                rowName (1,1) {mustBeText}
                descendantBranch (1,:) {mustBeText}
                descendantRowIds cell
            end

            dictOfDescendants = T{rowName,'children'}{1};
            if isempty(dictOfDescendants)
                dictOfDescendants = dictionary();
            end

            if isKey(dictOfDescendants, descendantBranch)
                existingIds = dictOfDescendants(descendantBranch);
                if iscell(existingIds)
                    existingIds = existingIds{1};
                    if iscell(existingIds)
                        existingIds = cell2mat(existingIds);
                    end
                end
                if iscell(descendantRowIds)
                    descendantRowIds = cell2mat(descendantRowIds);
                end
                updatedIds = unique([existingIds, descendantRowIds]);
                dictOfDescendants(descendantBranch) = {updatedIds};
            else
                if iscell(descendantRowIds)
                    descendantRowIds = cell2mat(descendantRowIds);
                end
                dictOfDescendants(descendantBranch) = {descendantRowIds};
            end

            T{rowName,'children'} = {dictOfDescendants};
        end



        function T = removeDescendants(T, rowName, descendantBranch, descendantRowIds)
            arguments
                T table
                rowName (1,1) {mustBeText}
                descendantBranch (1,:) {mustBeText}
                descendantRowIds cell
            end

            dictOfDescendants = T{rowName,'children'}{1};
            if isKey(dictOfDescendants, descendantBranch)
                existingIds = dictOfDescendants(descendantBranch);
                if iscell(existingIds)
                    existingIds = existingIds{1};
                    if iscell(existingIds)
                        existingIds = cell2mat(existingIds);
                    end
                end
                if iscell(descendantRowIds)
                    descendantRowIds = cell2mat(descendantRowIds);
                end
                updatedIds = setdiff(existingIds, descendantRowIds);
                dictOfDescendants(descendantBranch) = {updatedIds};
                T{rowName,'children'} = {dictOfDescendants};
            end
        end



        function descendantIds = getDescendantIds(T, rowName, descendantBranch)
            arguments
                T table
                rowName (1,1) {mustBeText}
                descendantBranch (1,:) {mustBeText}
            end

            dictOfDescendants = T{rowName,'children'}{1};
            if isKey(dictOfDescendants, descendantBranch)
                descendantIds = dictOfDescendants(descendantBranch);
                while iscell(descendantIds)
                    if ~isempty(descendantIds) && iscell(descendantIds{1})
                        descendantIds = descendantIds{1};
                    else
                        descendantIds = cell2mat(descendantIds);
                    end
                end
            else
                descendantIds = [];
            end
        end
    end
end