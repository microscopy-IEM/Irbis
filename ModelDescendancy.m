classdef (Sealed) ModelDescendancy 
    methods (Static)
        function T = replaceRelatives(T, affectedIds, typeOfRelative, relativeBranch, idsToReplace, newIds)
            arguments
                T table
                affectedIds
                typeOfRelative {mustBeMember(typeOfRelative, {'parent', 'children'})}
                relativeBranch (1,:) {mustBeText}
                idsToReplace
                newIds
            end

            for i = 1:numel(affectedIds)
                rowName = num2str(affectedIds{1}(i));
                dictOfRelatives = T{rowName,typeOfRelative}{1};
                if isempty(dictOfRelatives) || ~isConfigured(dictOfRelatives) || ~isKey(dictOfRelatives, relativeBranch)
                    return
                end
                if iscell(newIds)
                    newIds = cell2mat(newIds);
                end
                existingIds = dictOfRelatives(relativeBranch);
                if iscell(existingIds)
                    existingIds = existingIds{1};
                    if iscell(existingIds)
                        existingIds = cell2mat(existingIds);
                    end
                end
                if iscell(idsToReplace)
                    idsToReplace = cell2mat(idsToReplace);
                end
                updatedIds = unique([setdiff(existingIds, idsToReplace), newIds]);
                dictOfRelatives(relativeBranch) = {updatedIds};
                T{rowName, typeOfRelative} = {dictOfRelatives};
            end
        end



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



        function relativesExist = doHaveRelatives(relativesColumn)
            % Check if any of the items have any relatives (parents or children)
                % Relatives type is defined in what is passed in
            % Input is a T.parent or T.children column from a table

            % Output is a logical true/false array
            relativesExist = cellfun(@(x) ~isempty(x) && isConfigured(x), relativesColumn);
        end


        
        function relativesDict = getUniqueRelatives(relativesColumn)
            relativesDict = configureDictionary('char', 'cell');

            relativesExist = ModelDescendancy.doHaveRelatives(relativesColumn);
            relativesCells = relativesColumn(relativesExist);

            for itemIdx = 1:length(relativesCells)
                relativesEntry = relativesCells{itemIdx};
                relativesKeys = keys(relativesEntry);
                for branchIdx = 1:length(relativesKeys)
                    key = relativesKeys{branchIdx};
                    value = relativesEntry(key);
                    if iscell(value)
                        value = value{1};
                        if iscell(value)
                            value = cell2mat(value);
                        end
                    end
                    if isKey(relativesDict, key)
                        existingValues = relativesDict(key);
                        if iscell(existingValues)
                            existingValues = existingValues{1};
                            if iscell(existingValues)
                                existingValues = cell2mat(existingValues);
                            end
                        end
                        updatedValues = unique([existingValues, value]);
                        relativesDict(key) = {updatedValues};
                    else
                        if iscell(value)
                            value = cell2mat(value);
                        end
                        relativesDict(key) = {value};
                    end
                end
            end
        end
    end
end