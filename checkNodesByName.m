function checkNodesByName(tree, nodeNames)
    checkedNodes = [];
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
            disp('Node with name "%s" not found.', nodeName);
        end
    end
    tree.CheckedNodes = checkedNodes;
end