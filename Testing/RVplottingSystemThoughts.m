% column to plot on x
% for two variables: column to plot on y
% column to plot as categorical 

% column to plot on x - usually the last selected
    % for 

% categorical 


% or categorical the last one? 

% if use categorical
    % check if the last column is categorical
        % if yes, use it and use the previous one to plot
        % if not, find the last categorical one and use the last one to plot

shownData = app.UITable.Data;

selectedColumnsNums = unique(app.UITable.Selection(:,2),'stable');
selectedData = app.UITable.Data(:,selectedColumnsNums);


            isCat = varfun(@iscategorical, selectedData, 'OutputFormat', 'uniform');
            isNum = varfun(@isnumeric, selectedData, 'OutputFormat', 'uniform');
            isCell = varfun(@iscell, selectedData, 'OutputFormat', 'uniform');

            categoricalColumns = selectedData(:,isCat);
            numericalColumns = selectedData(:,isNum);
            cellColumns = selectedData(:,isCell);

% EXITS: 
    % selection is empty
    % there are no rows