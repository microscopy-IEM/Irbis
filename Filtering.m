classdef Filtering < GroupingBaseClass   
    methods
        function obj = Filtering(name, conditions)
            obj@GroupingBaseClass(name, conditions);
        end

        function preservedConditions = getGroupConditions(obj)
            preservedConditions = getGroupConditions@GroupingBaseClass(obj,true);
        end

        function obj = updateGroupConditions(obj, groupName, newConditions)
            groups = fieldnames(obj.Conditions);
            for i = 1:numel(groups)
                if strcmp(obj.Conditions.(groups{i}).name, groupName)
                    obj.Conditions.(groups{i}).conditions = newConditions;
                    return;
                end
            end
            error('Group name %s not found', groupName);
        end

        function groups = evaluateConditions(obj, table)
            groups = false(height(table), 1);
            groups = evaluateConditions@GroupingBaseClass(obj, table, groups);
        end
    end
end
