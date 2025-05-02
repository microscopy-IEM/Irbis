classdef test_BatchLoader < matlab.unittest.TestCase
    methods (Test)
        function testConstructor(testCase)
            % Test the constructor
            loader = BatchLoader();
            testCase.verifyEmpty(loader.fileNamesAll);
            testCase.verifyEmpty(loader.pathNamesAll);
            testCase.verifyEmpty(loader.modalities);
        end

        function testRunLoadFromApp(testCase)
            % Test runLoadFromApp method
            loader = BatchLoader();
            irbisStruct = struct(); % Mock input
            loader.runLoadFromApp(irbisStruct);
            testCase.verifyNotEmpty(loader.modalities);
            testCase.verifyTrue(ismember('model', loader.modalities));
            testCase.verifyTrue(ismember('tracks', loader.modalities));
        end

        function testStoreSingleLoadedData(testCase)
            % Test storeSingleLoadedData method
            loader = BatchLoader();
            loader.modalities = {'model', 'tracks'};
            loader.combinedTablesModel = struct('branch1', {{'data1'}});
            loader.combinedColumnDefinitionsModel = struct('branch1', 'definition1');
            loader.combinedFilteringsModel = struct('branch1', 'filter1');
            loader.combinedTablesTracks = {{'trackData1'}};
            loader.combinedColumnDefinitionsTracks = {'trackDefinition1'};
            loader.combinedFilteringsTracks = {'trackFilter1'};
            
            newDataStruct = loader.storeSingleLoadedData();
            testCase.verifyNotEmpty(newDataStruct);
            testCase.verifyEqual(newDataStruct.model.branch1.combinedList, 'data1');
            testCase.verifyEqual(newDataStruct.tracks.combinedList, 'trackData1');
        end

        function testRunBatchLoad(testCase)
            % Test runBatchLoad method
            loader = BatchLoader();
            loader.fileNamesAll = {'file1.irbis'};
            loader.pathNamesAll = {'/path/to/file'};
            loader.modalities = {'model', 'tracks'};
            
            % Mock methods
            loader.selectFiles = @() disp('Mock selectFiles');
            loader.selectModalities = @() disp('Mock selectModalities');
            loader.ensureParallelPool = @() disp('Mock ensureParallelPool');
            loader.processFilesInParallel = @() deal({struct()}, {struct()});
            
            loader.runBatchLoad();
            testCase.verifyNotEmpty(loader.modalities);
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
            testCase.verifyNotEmpty(updatedDataStruct);
            testCase.verifyEqual(updatedDataStruct.model.branch1.combinedList, 'existingData');
        end
    end
end