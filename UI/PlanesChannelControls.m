classdef (Sealed) PlanesChannelControls
    properties (Constant)
        % Define properties for the class here
        yspacer = 28;
        yoffset = 56;   % offset for panel title 
        pad = 8;
    end

    methods (Static)
        function add(panel, gridLayout, chNum, chName, chColor, chColormap, contextMenu, callbacks)
            % function interactively adds new set of control components for new channel
            % disp(['adding ctrls for ch' num2str(chNum)] )

            % get number of already existing channel ctrl sets
            chCtrlComponents = findobj(panel.Children,'Type','uicheckbox');
            numOfExistingChannelControls = size(chCtrlComponents,1);                     
            
            yspacer = PlanesChannelControls.yspacer;
            yoffset = PlanesChannelControls.yoffset;

            % limit number of channel to 8
            if numOfExistingChannelControls >= 8  
                disp('Max number of channel exceeded')
                return
            end

            % Create channel control components
            % Channel state button
            
            % panelHeight = panel.Position(4)
            % rowh = gridLayout.RowHeight{2}
            panelHeight = gridLayout.RowHeight{2};

            ypos = panelHeight - (chNum-1)*yspacer - yoffset;

            % if the control would be outside of the panel, resize the panel
            if ypos < 0            
  
                rowh = gridLayout.RowHeight{2} + yspacer;
                gridLayout.RowHeight{2} = rowh;
                % panel.Position(4) = rowh;
                                
                % Shift existing components up if the panel size changed
                chCtrlComponents = findobj(panel.Children);
                
                for i = 1:size(chCtrlComponents,1)
                    
                    chCtrlComponents(i).Position(2) = chCtrlComponents(i).Position(2)+30;                 
                    
                end

                ypos = rowh - (chNum-1)*yspacer - yoffset;

            end

            % Create GUI components for channel
            % State channel selection button
            channelButton = uibutton(panel,'state');
            channelButton.Tag = ['ch' num2str(chNum)];
            channelButton.Text  =  chName;           
            channelButton.Position = [58,ypos,83,23];
            channelButton.UserData = chNum;
            channelButton.ContextMenu = contextMenu;
            channelButton.ValueChangedFcn = @(~, ~) callbacks.active(chNum);
            channelButton.Value = 0;
            channelButton.BackgroundColor = [0.96 0.96 0.96];

            % Channel color selection button
            colSelectionButton = uibutton(panel);
            colSelectionButton.Tag = ['ch' num2str(chNum)];
            colSelectionButton.Position = [164,ypos,26,23];
            colSelectionButton.Text  = '';
            colSelectionButton.BackgroundColor = chColor;
            colSelectionButton.ButtonPushedFcn = @(~, ~) callbacks.color(chNum, colSelectionButton);

            % Dropdown for map selection
            mapSelection = uidropdown(panel);
            mapSelection.Tag = ['ch' num2str(chNum)];
            mapSelection.Position = [202,ypos,71,22];
            mapSelection.Items = {'gray','turbo','parula','jet','cool','hot'};
            mapSelection.Value = chColormap;
            mapSelection.ValueChangedFcn = @(~, ~) callbacks.colormap(chNum, mapSelection.Value);

            % Check box for channel activation
            chCheckBox = uicheckbox(panel);
            chCheckBox.Tag = ['ch' num2str(chNum)];
            chCheckBox.Position = [288,ypos,25,22];
            chCheckBox.Text = '';
            chCheckBox.Value = 1;
            chCheckBox.ValueChangedFcn = @(~, ~) callbacks.shown(chNum, chCheckBox.Value);
        end



        function remove(panel, gridLayout, chNum)
            % Remove controls for a given channel and renumber the rest

            % Access class constants directly
            yspacer = PlanesChannelControls.yspacer;
            yoffset = PlanesChannelControls.yoffset;
            pad = PlanesChannelControls.pad;

            % 1) delete selected channel group
            tagToRemove = ['ch' num2str(chNum)];
            delete(findobj(panel.Children, 'Tag', tagToRemove));

            % 2) find remaining channel state buttons (authoritative source)

            stateBtns = findobj(panel.Children, ...
                                'Type','uistatebutton');
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
                    get(comp)
                    get(comp, 'Type')
                    comp.Tag = newTag;
                    pos = comp.Position;
                    pos(2) = ypos;
                    comp.Position = pos;
                    if isa(comp,'matlab.ui.control.StateButton')
                        comp.UserData = newIdx; % keep UserData consistent
                    end
                end
            end
        end
    end
end