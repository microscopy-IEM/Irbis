classdef (Sealed) ModelDescendancy 
    methods (Static)
        function T = addDescendants(T, rowName, descendantBranch, descendantRowIds)
            arguments
                T table
                rowName (1,1) {mustBeText}
                descendantBranch (1,:) {mustBeText}
                descendantRowIds
            end

            dictOfDescendants = T{rowName,'children'}{1};
            if isempty(dictOfDescendants)
                dictOfDescendants = dictionary();
            end

            if isConfigured(dictOfDescendants) && isKey(dictOfDescendants, descendantBranch)
                % using isKey on a non-configured dictionary throws an error
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
                descendantRowIds
            end

            dictOfDescendants = T{rowName,'children'}{1};
            if isempty(dictOfDescendants) || ~isConfigured(dictOfDescendants)   % isConfigured checks if the dictionary has any entries
                % the object does not have any descendants yet - just leave the table unchanged
                return
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



        function ancestorIds = getAncestorIds(T, rowName, ancestorBranch)
            arguments
                T table
                rowName (1,1) {mustBeText}
                ancestorBranch (1,:) {mustBeText}
            end

            dictOfAncestors = T{rowName,'parent'}{1};
            if isKey(dictOfAncestors, ancestorBranch)
                ancestorIds = dictOfAncestors(ancestorBranch);
                while iscell(ancestorIds)
                    if ~isempty(ancestorIds) && iscell(ancestorIds{1})
                        ancestorIds = ancestorIds{1};
                    else
                        ancestorIds = cell2mat(ancestorIds);
                    end
                end
            else
                ancestorIds = [];
            end
        end
    end
end