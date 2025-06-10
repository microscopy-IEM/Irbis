function checkNodesByName(tree, nodeNames)
    checkedNodes = [];
    if isempty(nodeNames)
        return
    end
    if ~iscell(nodeNames)
        warning('Input nodeNames should be a cell array of strings.');  % Added if there is some problem with filter settings
        return
    end
    for i = 1:length(nodeNames)
        % Find the node with the specific name
        nodeName = nodeNames{i};
        node = findobj(tree.Children, 'Text', nodeName);
        % get(node)
        
        % Check if the node is found and check the box
        if ~isempty(node)
            checkedNodes = [checkedNodes,node];
        else
            % warning('Node with name "%s" not found.', nodeName);
            % fprintf('Node with name "%s" not found.', nodeName);
        end
        % nodeName
    end
    % checkedNodes
    tree.CheckedNodes = checkedNodes;
end