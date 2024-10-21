% script for testing the speed of using for loop vs cellfun
% results: almost no difference, cellfun is tiny bit faster, but it is in % 

% Number of rows
numRows = 1000;
arrayLength = 100000;

% Simulate the selected column (numerical data stored as cells with vectors)
% selectedColumnData = arrayfun(@(x) randi(10000, [1, randi([3, 10])]), (1:numRows)', 'UniformOutput', false);
selectedColumnData = arrayfun(@(x) rand([1, randi([arrayLength/2, arrayLength])]), (1:numRows)', 'UniformOutput', false);

% Simulate the categorical data column as a vector and convert to categorical
categoricalData = categorical(randi([1, 5], numRows, 1));  % Random integers converted to categorical

% Combine them into a table
appUITableData = table(selectedColumnData, categoricalData, 'VariableNames', {'DataColumn', 'CategoryColumn'});

% Simulate selected column number and categorical column number
selectedColumnsNums = 1;  % Column index for the data
categoricalColumnNum = 2;   % Column index for the categorical variable

tic
test_with_for_loop(appUITableData,selectedColumnsNums,categoricalColumnNum)
disp(['With for loop: ' num2str(toc)])

tic
test_with_for_loop(appUITableData,selectedColumnsNums,categoricalColumnNum)
disp(['Without for loop: ' num2str(toc)])


function test_with_for_loop(appUITableData, selectedColumnsNums, categoricalColumnNum)
    % Extract categorical data (column is categorical)
    categoricalData = appUITableData{:, categoricalColumnNum};  % Extract categorical column

    % Extract and expand the numerical data from the selected column
    allData = [];
    allCategories = [];

    for i = 1:height(appUITableData)
        % Extract the data for the current row (vector inside a cell)
        rowData = appUITableData{i, selectedColumnsNums(end)}{1};

        % Repeat the categorical value for each element in the rowData vector
        repeatedCategory = repmat(categoricalData(i), size(rowData));

        % Concatenate the data and categories
        allData = [allData; rowData(:)];
        allCategories = [allCategories; repeatedCategory(:)];
    end

    % Optionally: return or process the data (e.g., plotting)
end

function test_without_for_loop(appUITableData, selectedColumnsNums, categoricalColumnNum)
    % Extract categorical data (column is categorical)
    categoricalData = appUITableData{:, categoricalColumnNum};  % Extract categorical column

    % Extract numerical data from the selected column (vectors inside cells)
    selectedColumnData = appUITableData{:, selectedColumnsNums(end)};

    % Vectorize the extraction of numeric data
    allData = cell2mat(vertcat(selectedColumnData{:}));

    % Repeat categorical values for each element in the corresponding row's vector
    categoryLengths = cellfun(@numel, selectedColumnData);  % Get the length of each vector
    allCategories = repelem(categoricalData, categoryLengths);

    % Optionally: return or process the data (e.g., plotting)
end




