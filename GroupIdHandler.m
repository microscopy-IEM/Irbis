classdef GroupIdHandler
    % Helper class for handling groupIds
    % Many of the functions make the code more flexible if we decide to change groupId type or similar things

    methods (Static)
        function groupIds = getFromObjectIds(T, objectIds)
            arguments
                T   table
                objectIds double
            end
            
            % returns valid groupIds as a list of the same type as the entry (should be categorical)

            rowNums = ismember(T.Properties.RowNames(:), num2str(objectIds(:)));
            groupIds = T{rowNums, 'groupId'};
            % adding conversion assuming groupIds are categorical values:
            groupNums = str2double(string(groupIds));
            groupIds = groupIds(groupNums ~= 0);
        end



        function rowNums = getRowNumsFromGroupIds(T, groupIds)
            % returns row numbers of the table T that correspond to the provided groupIds
            rowNums = find(ismember(T.groupId, groupIds));
        end



        function objectIds = getObjectIdsFromGroupIds(T, groupIds)
            % returns objectIds (double, from row names) of the table T that correspond to the provided groupIds
            rowNums = GroupIdHandler.getRowNumsFromGroupIds(T, groupIds);
            objectIds = str2double(T.Properties.RowNames{rowNums});
        end



        function groupId = correctType(groupId)
            % Corrects the type of groupId if needed (converts numeric to categorical)
            if isnumeric(groupId)
                groupId = categorical(string(groupId));
            end
        end



        function untrackedGroupId = getUntracked()
            % returns the default groupId value that means that the object is not connected in time
            % defined as a function so that we don't have to rewrite it everywhere if we for example decide to switch from 0 to 'undefined'

            untrackedGroupId = categorical(string(0));
            % untrackedGroupId = 0;
        end



        function isTracked = isTracked(groupId)
            % checks whether groupId corresponds to a lineage or is untracked
            % currently, groupId > 0 means tracked, groupId == 0 is the default untracked value (or the string can be <missing> if the categorical values are defaulted to <undefined>)
            % defined as a function so that we don't have to replace the check everywhere if we change handling/class of groupId

            isTracked = ~(isequal(string(groupId), string(0)) || ismissing(string(groupId)));
        end



        function newGroupId = getNext(groupIds)
            %GETNEXT Returns next groupId (max + 1) for categorical input
            
            % Remove undefined values or zeros, as they represent untracked objects and should not be considered when determining the next groupId
            if isnumeric(groupIds)
                groupIds = groupIds(groupIds ~= 0);
            else
                groupIds = groupIds(~isundefined(groupIds) & string(groupIds) ~= "0" & ~ismissing(string(groupIds)));
            end
            
            if isempty(groupIds)
                newGroupId = categorical("1");
                return;
            end
            
            % Convert categorical to numeric values
            numericVals = str2double(string(groupIds));
            
            % Validate conversion
            if any(isnan(numericVals))
                error('groupIds must contain only numeric values stored as categories.');
            end
            
            % Compute next ID
            nextVal = max(numericVals) + 1;
            
            % Return as the same type as the input groupIds
            if isnumeric(groupIds)
                newGroupId = nextVal;
            else
                newGroupId = categorical(string(nextVal));
            end
        end



        function groupIds = collectFromArray(cellArray)
            % Collects groupIds from an array of tables that have a groupId column, ignoring empty entries
            tmp = cellfun(@(T) T.groupId, ...
                cellArray(~cellfun(@isempty, cellArray)), ...
                'UniformOutput', false);

            groupIds = unique(vertcat(tmp{:}));
        end


        function trackedGroupIds = collectTrackedFromArray(cellArray)
            % Collects only tracked groupIds from an array of tables that have a groupId column, ignoring empty entries
            groupIds = GroupIdHandler.collectFromArray(cellArray);

            if isnumeric(groupIds)
                trackedGroupIds = groupIds(groupIds ~= 0);
            else
                trackedGroupIds = groupIds(string(groupIds) ~= "0" & ~ismissing(string(groupIds)));
            end
        end
    end
end