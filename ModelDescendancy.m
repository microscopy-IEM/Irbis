classdef (Sealed) ModelDescendancy 
    methods (Static)
        function T = replaceRelatives(T, affectedIds, typeOfRelative, relativeBranch, idsToReplace, newIds)
            % Replace selected relative IDs for many subjects at once.
            % For each affected subject row, remove idsToReplace and add newIds
            % only within the specified branch of either 'parent' or 'children'.
            arguments
                T table
                affectedIds
                typeOfRelative {mustBeMember(typeOfRelative, {'parent', 'children'})}   % what is the relation of the relative to the subject
                relativeBranch (1,:) {mustBeText}
                idsToReplace
                newIds
            end

            if iscell(affectedIds)
                affectedIds = cell2mat(affectedIds);
            end

            for i = 1:numel(affectedIds)
                rowName = num2str(affectedIds(i));
                dictOfRelatives = T{rowName,typeOfRelative}{1};
                if isempty(dictOfRelatives) || ~isConfigured(dictOfRelatives) || ~isKey(dictOfRelatives, relativeBranch)
                    continue
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



        function T = updateRelatives(T, typeOfRelative, relativeBranch, subjectId, oldIdList, newIdList)
            % Synchronize inverse links after a subject's relatives changed.
            % Adds subjectId to newly referenced relatives and removes it from
            % relatives that are no longer referenced.
            arguments
                T
                typeOfRelative {mustBeMember(typeOfRelative, {'parent', 'children'})}   % what is the relation of the relative to the subject
                relativeBranch (1,:) {mustBeText}
                subjectId
                oldIdList cell
                newIdList cell
            end

            % Method for updating information about subject in relatives' tables

            oldIdList = oldIdList{1};
            if iscell(oldIdList)
                oldIdList = cell2mat(oldIdList);
            end

            newIdList = newIdList{1};
            if iscell(newIdList)
                newIdList = cell2mat(newIdList);
            end

            % For objects in newIdList that are not in oldIdList, add subjectId as their relative
            idsToAdd = setdiff(newIdList, oldIdList);
            for i = 1:numel(idsToAdd)
                idsToAdd(i)
                if isequal(typeOfRelative, 'parent')
                    % Ensure only one parent per branch
                    T = ModelDescendancy.replaceAncestor(T, num2str(idsToAdd(i)), relativeBranch, subjectId);
                elseif isequal(typeOfRelative, 'children')
                    T = ModelDescendancy.addRelatives(T, num2str(idsToAdd(i)), relativeBranch, subjectId, typeOfRelative);
                end    
            end

            % For objects in oldIdList that are not in newIdList, remove subjectId as their relative
            idsToRemove = setdiff(oldIdList, newIdList);
            for i = 1:numel(idsToRemove)
                idsToRemove(i)
                T = ModelDescendancy.removeRelatives(T, num2str(idsToRemove(i)), relativeBranch, subjectId, typeOfRelative);
            end
        end



        function T = replaceAncestor(T, rowName, ancestorBranch, ancestorId)
            % Set (replace) the parent for one object in one branch.
            % This enforces a single parent per branch by overwriting prior value.
            % We assume that there can only be one parent -> remove the existing one(s) and add the new one
            arguments
                T table
                rowName (1,:) {mustBeText}
                ancestorBranch (1,:) {mustBeText}
                ancestorId
            end

            dictOfRelatives = T{rowName, 'parent'}{1};
            if isempty(dictOfRelatives)
                dictOfRelatives = dictionary();
            end
            dictOfRelatives(ancestorBranch) = {ancestorId};

            T{rowName, 'parent'} = {dictOfRelatives};
        end



        function T = addRelatives(T, rowName, relativeBranch, relativeRowIds, typeOfRelative)
            % Add relative IDs to one object under one branch.
            % Works for either 'parent' or 'children' and keeps IDs unique.
            arguments
                T table
                rowName (1,:) {mustBeText}
                relativeBranch (1,:) {mustBeText}
                relativeRowIds
                typeOfRelative {mustBeMember(typeOfRelative, {'parent', 'children'})}
            end

            dictOfRelatives = T{rowName, typeOfRelative}{1};
            if isempty(dictOfRelatives)
                dictOfRelatives = dictionary();
            end

            if isConfigured(dictOfRelatives) && isKey(dictOfRelatives, relativeBranch)
                % using isKey on a non-configured dictionary throws an error
                existingIds = dictOfRelatives(relativeBranch);
                if iscell(existingIds)
                    existingIds = existingIds{1};
                    if iscell(existingIds)
                        existingIds = cell2mat(existingIds);
                    end
                end
                if iscell(relativeRowIds)
                    relativeRowIds = cell2mat(relativeRowIds);
                end
                updatedIds = unique([existingIds, relativeRowIds]);
                dictOfRelatives(relativeBranch) = {updatedIds};
            else
                if iscell(relativeRowIds)
                    relativeRowIds = cell2mat(relativeRowIds);
                end
                dictOfRelatives(relativeBranch) = {relativeRowIds};
            end

            T{rowName, typeOfRelative} = {dictOfRelatives};
        end



        function T = removeRelatives(T, rowName, relativeBranch, relativeRowIds, typeOfRelative)
            % Remove specific relative IDs from one object under one branch.
            % Leaves the table unchanged if the relationship dictionary/branch does not exist.
            arguments
                T table
                rowName (1,:) {mustBeText}
                relativeBranch (1,:) {mustBeText}
                relativeRowIds
                typeOfRelative {mustBeMember(typeOfRelative, {'parent', 'children'})}
            end

            dictOfRelatives = T{rowName, typeOfRelative}{1};
            if isempty(dictOfRelatives) || ~isConfigured(dictOfRelatives)   % isConfigured checks if the dictionary has any entries
                % the object does not have any relatives yet - just leave the table unchanged
                return
            end
            if isKey(dictOfRelatives, relativeBranch)
                existingIds = dictOfRelatives(relativeBranch);
                if iscell(existingIds)
                    existingIds = existingIds{1};
                    if iscell(existingIds)
                        existingIds = cell2mat(existingIds);
                    end
                end
                if iscell(relativeRowIds)
                    relativeRowIds = cell2mat(relativeRowIds);
                end
                updatedIds = setdiff(existingIds, relativeRowIds);
                dictOfRelatives(relativeBranch) = {updatedIds};
                T{rowName, typeOfRelative} = {dictOfRelatives};
            end
        end



        function T = addDescendants(T, rowName, descendantBranch, descendantRowIds)
            % Convenience wrapper to add child IDs in a given branch.
            % Updates the 'children' dictionary for the specified object row.
            arguments
                T table
                rowName (1,:) {mustBeText}
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
            % Convenience wrapper to remove child IDs in a given branch.
            % Updates the 'children' dictionary only when the branch exists.
            arguments
                T table
                rowName (1,:) {mustBeText}
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
            % Return child IDs for one object and branch.
            % Normalizes nested cell wrappers and returns [] when branch is missing.
            arguments
                T table
                rowName (1,:) {mustBeText}
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
            % Return parent ID(s) for one object and branch.
            % Normalizes nested cell wrappers and returns [] when branch is missing.
            arguments
                T table
                rowName (1,:) {mustBeText}
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
            % Indicate which rows contain configured relationship dictionaries.
            % Input is typically one table column: T.parent or T.children.
            % Check if any of the items have any relatives (parents or children)
                % Relatives type is defined in what is passed in
            % Input is a T.parent or T.children column from a table

            % Output is a logical true/false array
            relativesExist = cellfun(@(x) ~isempty(x) && isConfigured(x), relativesColumn);
        end


        
        function relativesDict = getUniqueRelatives(relativesColumn)
            % Aggregate all relatives across rows into one branch->IDs dictionary.
            % Merges duplicate branches and stores unique IDs per branch.
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



        function siblingIds = getSiblingIdsViaAncestor(T, rowName, ancestorBranch, ancestorT, siblingBranch)
            % Returns ids of the objects of siblingBranch that have the same parent in ancestorBranch as the object with id subjectId.
            
            arguments
                T table
                rowName (1,:) {mustBeText}
                ancestorBranch (1,:) {mustBeText}
                ancestorT table
                siblingBranch (1,:) {mustBeText}
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
                siblingIds = [];
                return
            end

            siblingIds = [];
            for i = 1:numel(ancestorIds)
                ancestorId = ancestorIds(i);
                ancestorRowName = num2str(ancestorId);
                if ismember(ancestorRowName, ancestorT.Properties.RowNames)
                    dictOfChildren = ancestorT{ancestorRowName, 'children'}{1};
                    if isKey(dictOfChildren, siblingBranch)
                        candidateSiblingIds = dictOfChildren(siblingBranch);
                        while iscell(candidateSiblingIds)
                            if ~isempty(candidateSiblingIds) && iscell(candidateSiblingIds{1})
                                candidateSiblingIds = candidateSiblingIds{1};
                            else
                                candidateSiblingIds = cell2mat(candidateSiblingIds);
                            end
                        end
                        siblingIds = [siblingIds, candidateSiblingIds];
                    end
                end
            end
        end
    end
end