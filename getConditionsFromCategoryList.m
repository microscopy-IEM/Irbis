function conditions = getConditionsFromCategoryList(categories)
    % disp('in fcn')
    % disp(categories)
    % Initialize the conditions structure
    conditions = struct();
    
    % Loop over each category name and build the conditions structure
    for i = 1:length(categories)
        % Create the group field name
        groupFieldName = sprintf('group%d', i);
        
        % Assign a struct with 'name' and 'conditions' fields to the group
        % !!! struct('name', categories{i}, 'conditions', {})   % having this produces an empty structure because of the {}
        conditions.(groupFieldName) = struct('name', categories{i}, 'conditions', {{}});
        % disp(['run ' num2str(i)])
        % disp(conditions)
    end

    % disp(conditions)
end