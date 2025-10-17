classdef (Sealed) PlanesChannelControls
    properties (Constant)
        % Define properties for the class here
        yspacer = 25;
        yoffset = 56;   % offset for panel title 
        pad = 8;
    end

    methods (Static)
        function add(panel, gridLayout, chNum, chName, chColor, chColormap, contextMenu, callbacks, styles)
            % function interactively adds new set of control components for new channel
            % disp(['adding ctrls for ch' num2str(chNum)] )

            % Get or create the internal grid layout for the panel
            internalGrid = PlanesChannelControls.getOrCreateInternalGrid(panel);
            
            % get number of already existing channel ctrl sets
            chCtrlComponents = findobj(internalGrid.Children,'Type','uicheckbox');
            numOfExistingChannelControls = size(chCtrlComponents,1);                     
            
            yspacer = PlanesChannelControls.yspacer;
            yoffset = PlanesChannelControls.yoffset;
            pad = PlanesChannelControls.pad;

            % limit number of channel to 8
            if numOfExistingChannelControls >= 8  
                disp('Max number of channel exceeded')
                return
            end

            % Add a new row to the internal grid layout
            currentRows = length(internalGrid.RowHeight);
            internalGrid.RowHeight{end+1} = yspacer;
            
            % Update the panel size in the main grid layout
            newPanelHeight = yoffset + (currentRows + 1) * yspacer + pad;
            gridLayout.RowHeight{2} = newPanelHeight;

            % Create GUI components for channel and add them to the new row
            % State channel selection button
            channelButton = uibutton(internalGrid,'state');
            channelButton.Tag = ['ch' num2str(chNum)];
            channelButton.Text  =  chName;           
            channelButton.Layout.Row = currentRows + 1;
            channelButton.Layout.Column = 1;
            channelButton.UserData = chNum;
            channelButton.ContextMenu = contextMenu;
            channelButton.ValueChangedFcn = @(~, ~) callbacks.active(channelButton.UserData);
            % channeButton.UserData returns the current channel number
            % used instead of just chNum because it is updated when channels are removed, while chNum is fixed
            channelButton.Value = 0;
            channelButton.BackgroundColor = [0.96 0.96 0.96];

            % Channel color selection button
            colSelectionButton = uibutton(internalGrid);
            colSelectionButton.Tag = ['ch' num2str(chNum)];
            colSelectionButton.Layout.Row = currentRows + 1;
            colSelectionButton.Layout.Column = 2;
            colSelectionButton.Text  = '';
            colSelectionButton.BackgroundColor = chColor;
            colSelectionButton.ButtonPushedFcn = @(~, ~) callbacks.color(channelButton.UserData, colSelectionButton);

            % Dropdown for map selection
            mapSelection = uidropdown(internalGrid);
            mapSelection.Tag = ['ch' num2str(chNum)];
            mapSelection.Layout.Row = currentRows + 1;
            mapSelection.Layout.Column = 3;
            mapSelection.Items = {'gray','turbo','parula','jet','cool','hot','nebula','summer'};
            mapSelection.Value = chColormap;
            mapSelection.ValueChangedFcn = @(~, ~) callbacks.colormap(channelButton.UserData, mapSelection.Value);

           
            % Assign styles (colormap icons) to drobdown items
            for i = 1:size(mapSelection.Items,2)

                mapName = mapSelection.Items{i};
                tempStyle = styles.(mapName);
                addStyle(mapSelection,tempStyle,"item",i);

            end

            % Check box for channel activation
            chCheckBox = uicheckbox(internalGrid);
            chCheckBox.Tag = ['ch' num2str(chNum)];
            chCheckBox.Layout.Row = currentRows + 1;
            chCheckBox.Layout.Column = 4;
            chCheckBox.Text = '';
            chCheckBox.Value = 1;
            chCheckBox.ValueChangedFcn = @(~, ~) callbacks.shown(channelButton.UserData, chCheckBox.Value);
        end



        function remove(panel, gridLayout, chNum)
            % Remove controls for a given channel and renumber the rest

            % Access class constants directly
            yspacer = PlanesChannelControls.yspacer;
            yoffset = PlanesChannelControls.yoffset;
            pad = PlanesChannelControls.pad;

            % Get the internal grid layout
            internalGrid = PlanesChannelControls.getOrCreateInternalGrid(panel);

            % 1) delete selected channel group
            tagToRemove = ['ch' num2str(chNum)];
            delete(findobj(internalGrid.Children, 'Tag', tagToRemove));

            % 2) find remaining channel state buttons (authoritative source)
            stateBtns = findobj(internalGrid.Children, 'Type','uistatebutton');
            if isempty(stateBtns)
                % No channels left, remove all rows from internal grid
                internalGrid.RowHeight = {};
                % Update panel size
                gridLayout.RowHeight{2} = yoffset + pad;
                return
            end

            % Collect old numbers and sort by grid row (ascending)
            [~, order] = sort(arrayfun(@(b)b.Layout.Row, stateBtns), 'ascend');
            stateBtns = stateBtns(order);

            % 3) renumber and reposition channels
            nCh = numel(stateBtns);
            
            % Update internal grid layout to have correct number of rows
            internalGrid.RowHeight = repmat({yspacer}, 1, nCh);
            
            % Update the panel size in the main grid layout
            newPanelHeight = yoffset + nCh * yspacer + pad;
            gridLayout.RowHeight{2} = newPanelHeight;

            for newIdx = 1:nCh
                % get all controls with the old tag
                oldTag = stateBtns(newIdx).Tag; % e.g. 'ch5'
                oldGroup = findobj(internalGrid.Children, 'Tag', oldTag);

                % assign new tag and row position
                newTag = ['ch' num2str(newIdx)];
                for comp = reshape(oldGroup,1,[])
                    comp.Tag = newTag;
                    comp.Layout.Row = newIdx;
                    if isa(comp,'matlab.ui.control.StateButton')
                        comp.UserData = newIdx; % keep UserData consistent
                    end
                end
            end
        end
        
        function internalGrid = getOrCreateInternalGrid(panel)
            % Get or create the internal grid layout within the panel
            
            % Check if internal grid already exists
            existingGrid = findobj(panel.Children, 'Type', 'uigridlayout');
            
            if ~isempty(existingGrid)
                internalGrid = existingGrid(1);
            else
                % Create new internal grid layout
                internalGrid = uigridlayout(panel);
                internalGrid.ColumnWidth = {'1x', 26, '1x', 25}; % Adjust widths as needed
                internalGrid.RowHeight = {}; % Start with no rows
                internalGrid.Padding = [10, 10, 10, 10]; % Add some padding
                internalGrid.RowSpacing = 8; % Space between rows
                internalGrid.ColumnSpacing = 10; % Space between columns
            end
        end
    end
end