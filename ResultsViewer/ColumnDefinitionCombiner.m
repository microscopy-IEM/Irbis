classdef ColumnDefinitionCombiner
    methods (Static)
        function [definitionList, namesToRecalculate] = combineStorage(storageArray)
            % Combine multiple FilteringStorage instances into one
            definitionList = {};
            existingNames = {};
            namesToRecalculate = {};

            for i = 1:numel(storageArray)
                currentStorage = storageArray{i};
                
                if ~isa(currentStorage, 'CategorizationStorage')
                    continue
                end

                names = currentStorage.returnCategorizationNames();
                for j = 1:numel(names)
                    name = names{j};
                    if ~ismember(name, existingNames)
                        existingNames{end+1} = name;
                        correspondingObject = currentStorage.returnCategorization(name);
                        definitionList{end+1} = correspondingObject;
                    else
                        % do the comparison
                        idx = find(strcmp(existingNames, name), 1);
                        existingObject = definitionList{idx};
                        definitionsAreSame = ColumnDefinitionCombiner.compareColumnDefinitions(existingObject, correspondingObject);
                        if ~definitionsAreSame
                            namesToRecalculate{end+1} = name;
                        end
                    end
                end
            end
        end

        function areEqual = compareColumnDefinitions(firstDefinition, secondDefinition)

            definitionType = firstDefinition.getDefinitionType();
            if ~isequal(definitionType, secondDefinition.getDefinitionType())
                areEqual = false;
                return
            end

            switch definitionType
                case 'categorization'
                    conds1 = firstDefinition.getConditions();
                    conds2 = secondDefinition.getConditions();
                    areEqual = ColumnDefinitionCombiner.conditionsAreEqual(conds1, conds2);
                case {'formula', 'merged'}  % the formula is a text we compare
                    areEqual = isequal(firstDefinition.getFormula(), secondDefinition.getFormula());
                    % TO OPTIMIZE - different texts can be the same formula, we do not take that into account - too difficult to check
                case 'manual'
                    areEqual = true;
                    % this is the user's responsibility, there is not much we can check
            end


        end


        function tf = conditionsAreEqual(conds1, conds2)
            % Return true if two Conditions structs are equal in terms of their rules
        
            if ~isequal(numel(fieldnames(conds1)), numel(fieldnames(conds2)))
                tf = false;
                return;
            end
        
            % Convert to standardized cell arrays for comparison
            normalized1 = ColumnDefinitionCombiner.normalizeConditions(conds1);
            normalized2 = ColumnDefinitionCombiner.normalizeConditions(conds2);
        
            tf = isequal(normalized1, normalized2);
        end
        

        function normConds = normalizeConditions(conds)
            % Convert conditions into a sorted, comparable structure
            fields = fieldnames(conds);
            normConds = cell(numel(fields), 1);
        
            for i = 1:numel(fields)
                groupConditions = conds.(fields{i}).conditions;
                condFields = sort(keys(groupConditions));
                normGroup = struct();
        
                for j = 1:numel(condFields)
                    condField = condFields{j};
                    value = groupConditions(condField);
        
                    if isa(value{1}, 'dictionary')
                        dict = value{1};
                        dictKeys = sort(keys(dict));
                        dictStruct = struct();
                        for k = 1:numel(dictKeys)
                            key = dictKeys{k};
                            dictStruct.(key) = dict(key);
                        end
                        normGroup.(condField) = dictStruct;
                    else
                        vals = sort(value{1});
                        normGroup.(condField) = vals;
                    end
                end
        
                % Convert to JSON string for consistent sorting and comparison
                normConds{i} = jsonencode(normGroup);
            end
        
            normConds = sort(normConds);  % sort JSON-encoded condition strings
        end
        
    end
end
