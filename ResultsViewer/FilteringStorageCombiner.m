classdef FilteringStorageCombiner
    methods (Static)
        function combinedStorage = combineStorage(storageArray)
            % Combine multiple FilteringStorage instances into one
            combinedStorage = FilteringStorage();
            existingNames = {};

            % disp('Combining FilteringStorage instances...');
            % disp(storageArray);
            for i = 1:numel(storageArray)
                currentStorage = storageArray{i};
                
                if ~isa(currentStorage, 'FilteringStorage')
                    continue
                end

                names = currentStorage.returnGroupingNames();
                for j = 1:numel(names)
                    name = names{j};
                    if ~ismember(name, existingNames)
                        existingNames{end+1} = name;
                        correspondingFilteringObject = currentStorage.returnGrouping(name);
                        combinedStorage.addGrouping(correspondingFilteringObject);
                    else
                        % skip it, as we can only have one instance of a filter
                    end
                end
            end
        end
    end
end