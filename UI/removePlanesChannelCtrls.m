function removePlanesChannelCtrls(panel, gridLayout, chNum)
% Remove controls for a given channel and renumber the rest

    yspacer = 28;
    yoffset = 56;
    pad = 8;

    % 1) delete selected channel group
    tagToRemove = ['ch' num2str(chNum)];
    delete(findobj(panel.Children, 'Tag', tagToRemove));

    % 2) find remaining channel state buttons (authoritative source)
    stateBtns = findobj(panel.Children, ...
                        'Type','uibutton', 'Style','state');
    if isempty(stateBtns)
        return  % no channels left
    end

    % Collect old numbers and sort by ascending position (y descending)
    % -> ensures consistent top-to-bottom ordering
    [~, order] = sort(arrayfun(@(b)b.Position(2), stateBtns), 'descend');
    stateBtns = stateBtns(order);

    % 3) renumber and reposition channels
    nCh = numel(stateBtns);
    panelHeight = yoffset + nCh*yspacer + pad;
    gridLayout.RowHeight{2} = panelHeight;

    for newIdx = 1:nCh
        ypos = panelHeight - (newIdx-1)*yspacer - yoffset;

        % get all controls with the old tag
        oldTag = stateBtns(newIdx).Tag; % e.g. 'ch5'
        oldGroup = findobj(panel.Children, 'Tag', oldTag);

        % assign new tag and position
        newTag = ['ch' num2str(newIdx)];
        for comp = reshape(oldGroup,1,[])
            comp.Tag = newTag;
            p = comp.Position;
            p(2) = ypos;
            comp.Position = p;
            if isa(comp,'matlab.ui.control.StateButton')
                comp.UserData = newIdx; % keep UserData consistent
            end
        end
    end
end
