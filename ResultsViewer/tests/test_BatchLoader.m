classdef test_BatchLoader < matlab.unittest.TestCase

    methods (TestClassSetup)
        function setupOnce(~)
            addpath(fullfile(pwd, '..', '..'));
        end
    end

    methods (Test)
        function testConstructor(testCase)
            % Test the constructor
            loader = BatchLoader();
            testCase.verifyEmpty(loader.fileNamesAll, 'fileNamesAll should be empty after construction');
            testCase.verifyEmpty(loader.pathNamesAll, 'pathNamesAll should be empty after construction');
            testCase.verifyEmpty(loader.modalities, 'modalities should be empty after construction');
        end


        function testEmptyRunLoadFromApp(testCase)
            loader = BatchLoader();
            irbisStruct = struct();
            loader.runLoadFromApp(irbisStruct);
            testCase.verifyEmpty(loader.modalities, 'modalities should be empty, as the input stuct is empty');
        end


        function testRunLoadFromAppWithValidData(testCase)
            loader = BatchLoader();
            irbisStruct = testCase.createTestStruct();
            loader.runLoadFromApp(irbisStruct);
            testCase.verifyEqual(loader.modalities, {'model', 'tracks'}, 'modalities not set correctly');
            testCase.verifyEqual(fieldnames(loader.combinedTablesModel), {'branch1', 'branch2'}, 'model branches not loaded correctly');
            testCase.verifyTrue(istable(loader.combinedTablesTracks{1}), 'trackData1', 'tracks data is not a table');
        end


        function testStoreSingleLoadedData(testCase)
            loader = BatchLoader();
            loader.modalities = {'model', 'tracks'};
            loader.combinedTablesModel = struct('branch1', {{'data1'}});
            loader.combinedColumnDefinitionsModel = struct('branch1', 'definition1');
            loader.combinedFilteringsModel = struct('branch1', 'filter1');
            loader.combinedTablesTracks = {{'trackData1'}};
            loader.combinedColumnDefinitionsTracks = {'trackDefinition1'};
            loader.combinedFilteringsTracks = {'trackFilter1'};
            
            newDataStruct = loader.storeSingleLoadedData();
            testCase.verifyNotEmpty(newDataStruct, 'newDataStruct should not be empty after storeSingleLoadedData');
            testCase.verifyEqual(newDataStruct.model.branch1.combinedList, 'data1', 'model data not correctly stored');
            testCase.verifyEqual(newDataStruct.tracks.combinedList, {'trackData1'}, 'tracks data not correctly stored');
        end


        function testAppendLoadedData(testCase)
            % Test appendLoadedData method
            loader = BatchLoader();
            loader.modalities = {'model', 'tracks'};
            loader.combinedTablesModel = struct('branch1', {{'data1'}});
            loader.combinedColumnDefinitionsModel = struct('branch1', 'definition1');
            loader.combinedFilteringsModel = struct('branch1', 'filter1');
            loader.combinedTablesTracks = {{'trackData1'}};
            loader.combinedColumnDefinitionsTracks = {'trackDefinition1'};
            loader.combinedFilteringsTracks = {'trackFilter1'};
            
            existingDataStruct = struct('model', struct('branch1', struct('combinedList', 'existingData')));
            updatedDataStruct = loader.appendLoadedData(existingDataStruct);
            testCase.verifyNotEmpty(updatedDataStruct, 'updatedDataStruct should not be empty after appendLoadedData');
            testCase.verifyEqual(updatedDataStruct.model.branch1.combinedList, 'existingData', 'existing data not preserved after append');
        end


        function testStoreLoadedDataAddsFileIdGroupIdMergedDefinition(testCase)
            loader = BatchLoader();
            loader.modalities = {'model'};

            modelTable = table( ...
                categorical([1; 1; 2]), ...
                categorical([10; 11; 10]), ...
                [5; 6; 7], ...
                'VariableNames', {'fileId', 'groupId', 'Value'});

            loader.combinedTablesModel = struct('spines', {{modelTable}});
            loader.combinedColumnDefinitionsModel = struct('spines', {{CategorizationStorage()}});
            loader.combinedFilteringsModel = struct('spines', {{FilteringStorage()}});

            newDataStruct = loader.storeLoadedData();
            combinedList = newDataStruct.model.spines.combinedList;

            testCase.verifyTrue(ismember('fileId_groupId', combinedList.Properties.VariableNames), ...
                'Batch-loaded model tables should include the automatic merged identifier.');
            testCase.verifyEqual(string(combinedList.fileId_groupId), ["1_10"; "1_11"; "2_10"]);

            [definitionList, ~] = ColumnDefinitionCombiner.combineStorage(newDataStruct.model.spines.storedCategorizations);
            definitionNames = cellfun(@(definition) char(definition.getColumnName()), definitionList, 'UniformOutput', false);
            testCase.verifyTrue(ismember('fileId_groupId', definitionNames), ...
                'The automatic merged identifier should be registered as a user-defined column.');

            definitionIdx = find(strcmp(definitionNames, 'fileId_groupId'), 1);
            testCase.verifyEqual(definitionList{definitionIdx}.getDefinitionType(), 'merged');
        end
    end


    methods (Access = private)
        function testStruct = createTestStruct(~)
            testStruct = struct();

            % Default branch of model
            testStruct.model.branch1.combinedList = table( ...
                [1; 2; 3; 4; 5; 6; 7; 8], ... % Numerical column
                categorical({'A'; 'B'; 'A'; 'C'; 'B'; 'C'; 'A'; 'B'}), ... % Categorical column
                [10.5; 20.3; 15.8; 30.1; 25.7; 18.2; 22.9; 27.4], ... % Another numerical column
                categorical([1; 1; 2; 2; 3; 3; 1; 2]), ... % New categorical column with values 1, 2, or 3
                categorical({'first'; 'second'; 'third'; 'second'; 'first'; 'third'; 'third'; 'first'}), ... % New categorical column with time points
                'VariableNames', {'Value', 'Category', 'Score', 'timePoint', 'AnotherCategory'});
            testStruct.model.branch1.storedFilters = {FilteringStorage()};
            testStruct.model.branch1.storedCategorizations = {CategorizationStorage()};

            % Second branch of model
            testStruct.model.branch2.combinedList = table( ...
                [9; 10; 11; 12], ... % Numerical column
                categorical({'B'; 'C'; 'A'; 'C'}), ... % Categorical column
                [12.1; 19.7; 23.5; 16.8], ... % Another numerical column
                categorical([1; 2; 3; 1]), ... % timePoint categorical column with values 1, 2, 3, 1
                categorical({'first'; 'second'; 'third'; 'second'}), ... % Another categorical column
                'VariableNames', {'Value', 'Category', 'Score', 'timePoint', 'AnotherCategory'});
            % Create FilteringStorage and add example filters
            branch2FilteringStorage = FilteringStorage();
            % Add a range filter on 'Value' column (e.g., keep values between 10 and 12)
            branch2FilteringStorage.addRangeFilter('Value', [10, 12]);
            % Add a categorical filter on 'Category' column (e.g., keep only 'A' and 'C')
            branch2FilteringStorage.addCategoricalFilter('Category', {'A', 'C'});
            testStruct.model.branch2.storedFilters = {branch2FilteringStorage};
            testStruct.model.branch2.storedCategorizations = {CategorizationStorage()};

            % Tracks data
            testStruct.tracks.combinedList = table( ...
                [101; 102; 103; 104; 105; 106; 107; 108], ... % Numerical column
                categorical({'X'; 'Y'; 'X'; 'Z'; 'Y'; 'Z'; 'X'; 'Y'}), ... % Categorical column
                [55.2; 63.1; 58.7; 60.5; 62.3; 59.8; 57.6; 61.4], ... % Another numerical column
                'VariableNames', {'TrackID', 'TrackType', 'TrackScore'});
            testStruct.tracks.storedFilters = {FilteringStorage()};
            testStruct.tracks.storedCategorizations = {CategorizationStorage()};
        end
    end
end
