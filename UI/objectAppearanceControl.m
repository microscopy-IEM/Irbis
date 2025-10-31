classdef objectAppearanceControl < handle
    
    properties
       nControls = 0;
       maxControls = 5;
       upperPanelHeight = 80;
       x0 = 10;
       ySpacer = 40;         
       commonTag =  'mixerComponents';       
       controlsHandle = [];
       callbacks % Description
       colorMapStyles
       colorMapsNames = ["flat","gray","random","turbo","parula","jet","cool","hot","nebula","summer"]; % Description
       defaultColors = {[0.88,0.06,0.88],[0.39,0.83,0.07],[0.06,1.00,1.00],[0.72,0.27,1.00],[0.21,0.60,0.86]};
       defaultTransparency = 0.5
       mappingProperties;
       dockPanel % static panel in main Irbis app with show/hide button
       controlPanel
       plotPanel
       showButton
    end

    methods
        
        function oac = objectAppearanceControl(dockPanel,controlPanel,plotPanel,showButton)
           
            oac.dockPanel = dockPanel;
            oac.controlPanel = controlPanel;
            oac.plotPanel = plotPanel;
            oac.showButton = showButton;

            % oac.mappingProperties = {'none','volume'};

            oac.showButton.ValueChangedFcn = @(src, evt)oac.showColorControls(src, evt);

            for i = 1:size(oac.colorMapsNames,2)

                mapName = oac.colorMapsNames{i};                              
                icon = oac.makeColorMapIcon(mapName,[]);                
                oac.colorMapStyles.(mapName) = uistyle("Icon",icon,'HorizontalAlignment','center','IconAlignment','leftmargin');

            end

        end

        
        function add(oac,branch,shown,transparency,color,colormap,mapProperty)
            
            % Add input validation

            index = oac.nControls+1;                                                       
                       
            % Branch name label
            Label = uilabel(oac.plotPanel);
            Label.Text = branch;
            Label.Tag = oac.commonTag;
            Label.UserData.branch = branch;
            % Label.FontColor = col;
           

            % Selection check box
            ShownCheckBox = uicheckbox(oac.plotPanel);            
            ShownCheckBox.Text = '';  
            ShownCheckBox.Tag = oac.commonTag;  
            ShownCheckBox.Value = shown;
            ShownCheckBox.UserData.branch = branch;            
            ShownCheckBox.ValueChangedFcn = @(~, ~) oac.callbacks.changeAppearance(branch,'visibility',ShownCheckBox.Value);


            % Transparency slider
            TransparencySlider = uislider(oac.plotPanel);
            TransparencySlider.Tag = oac.commonTag;           
            TransparencySlider.Value = transparency;
            TransparencySlider.MajorTickLabels = {};
            TransparencySlider.MajorTicks = [];
            TransparencySlider.MinorTicks = [];
            TransparencySlider.Limits = [0 1];     
            TransparencySlider.UserData.branch = branch;
            TransparencySlider.UserData.feature = 'transparency';
            TransparencySlider.ValueChangedFcn = @(~, ~) oac.callbacks.changeAppearance(branch,'transparency',TransparencySlider.Value);


            % Color picking button
            ColorPickerButton = uibutton(oac.plotPanel);
            ColorPickerButton.Tag = oac.commonTag;           
            ColorPickerButton.ButtonPushedFcn = @(src,evt)oac.showColorMappingPanel(src,evt);
            ColorPickerButton.BackgroundColor = color;
            ColorPickerButton.Text = '';
            ColorPickerButton.UserData.branch = branch;
            ColorPickerButton.UserData.colorMap = colormap;
            ColorPickerButton.UserData.color = color;
            ColorPickerButton.UserData.mappingProperty = mapProperty;


            % Store control's handles           
            oac.controlsHandle.(branch).Label = Label;
            oac.controlsHandle.(branch).ShownCheckBox = ShownCheckBox;
            oac.controlsHandle.(branch).TransparencySlider = TransparencySlider;
            oac.controlsHandle.(branch).ColorPickerButton = ColorPickerButton;

            % update actual number of controls
            oac.nControls = index;    

            % re-arrange added control in space
            oac.reArrangeControls
            
        end

        
        function setVisibility(oac,branch, status)

            oac.controlsHandle.(branch).ShownCheckBox.Value = status;
            oac.callbacks.changeAppearance(branch,'visibility',status);            

        end

        function setTransparency(oac,branch, transparency)

            oac.controlsHandle.(branch).TransparencySlider.Value = transparency;
            oac.callbacks.changeAppearance(branch,'transparency',transparency);            

        end

        function setColor(oac,branch, newColor)

            callerBtn = oac.controlsHandle.(branch).ColorPickerButton;           
            currentMap = callerBtn.UserData.colorMap;

            callerBtn.BackgroundColor = newColor;
            callerBtn.UserData.color = newColor;
            

            switch currentMap
                case 'flat'

                    oac.callbacks.changeAppearance(branch,'color',newColor);
                    callerBtn.BackgroundColor = newColor;
                    callerBtn.Icon = '';

                case 'gray'

                    icon = oac.makeColorMapIcon(currentMap,newColor);
                    callerBtn.Icon = icon;
                    callerBtn.BackgroundColor = [0 0 0];

                    % oac.callbacks.changeAppearance(branch,'colorMap','gray');
                    % oac.callbacks.changeAppearance(branch,'color',newColor);
                    oac.callbacks.changeAppearance(branch,'colorMap','gray',newColor);

                otherwise

                    callerBtn.UserData.colorMap = 'flat';
                    callerBtn.Icon = '';
                    oac.callbacks.changeAppearance(branch,'color',newColor);

            end

            

            % oac.callbacks.changeAppearance(branch,'color',newColor);  

        end

        function setColorMap(oac,branch, colorMap)

       
            if ismember(colorMap,oac.colorMapsNames)                
                
                oac.controlsHandle.(branch).ColorPickerButton.UserData.colorMap = colorMap;
                

                color = [];
                callerBtn = oac.controlsHandle.(branch).ColorPickerButton;
                
                switch colorMap
                    case 'flat'
                                                
                        callerBtn.UserData.color
                        icon = '';
                        callerBtn.BackgroundColor = callerBtn.UserData.color;
    
                    case 'gray'
    
                        color = callerBtn.UserData.color;
                        icon = makeColorMapIcon(oac,'gray',color);
                        callerBtn.BackgroundColor = [0 0 0];

    
                    otherwise
    
                        callerBtn.BackgroundColor = [0 0 0];                       
                        icon = makeColorMapIcon(oac,colorMap,[0 0 0]);

                end

                callerBtn.Icon = icon; 
                
                callerBtn.UserData.colorMap = colorMap;
    
                oac.callbacks.changeAppearance(branch,'colorMap',colorMap,color); 
               
                

            end

        end

        function setMappingProperty(oac,branch, mapProperty)

            if ismember(mapProperty,oac.mappingProperties)
                oac.controlsHandle.(branch).ColorPickerButton.UserData.mappingProperty = mapProperty;
                oac.callbacks.changeAppearance(branch,'mappingProperty',mapProperty);        
            end

        end

        function setMappingPropertiesList(oac,properties)
            
            oac.mappingProperties = properties;

        end

        function adjustControlPanelPosition(oac)
                                    
            imHeight = oac.upperPanelHeight + (oac.nControls*oac.ySpacer);

            dockPos = oac.dockPanel.Position;
            imPos = oac.controlPanel.Position;
    
            oac.controlPanel.Position = [dockPos(1), dockPos(2) + dockPos(4)-imHeight - dockPos(4), imPos(3), imHeight];
           
               
        end

        function reArrangeControls(oac)
                        
            imHeight = oac.upperPanelHeight + (oac.nControls*oac.ySpacer);

            dockPos = oac.dockPanel.Position;
            imPos = oac.controlPanel.Position;
    
            oac.controlPanel.Position = [dockPos(1), dockPos(2) + dockPos(4)-imHeight - dockPos(4), imPos(3), imHeight];
            
            branchNames = fieldnames(oac.controlsHandle);

            dockPanelPos = oac.dockPanel.Position;   
            % controlPanelPos =oac.controlPanel.Position;
      
            nBranches = size(branchNames,1);
                        
            elementsH = 22;
            sliderLength = 120;

            for index = 1:nBranches

                branch = branchNames{index};   
                                                              
                % calculate common constants       
                baseY = dockPanelPos(2) - oac.upperPanelHeight - (index-1)*oac.ySpacer - elementsH-10;
                % baseX = controlPanelPos(1) + oac.x0;
                baseX = dockPanelPos(1) + oac.x0;

                % calculate control's positions
                posLabel = [baseX, baseY, 80, elementsH];
                posChBox = [baseX + 80, baseY, 22, elementsH];
                posSlider = [baseX + 110, baseY + 7, sliderLength, 3];         
                posColPicker = [baseX + 125 + sliderLength, baseY, 25, 25];

                % assign positions to ui controls
                oac.controlsHandle.(branch).Label.Position = posLabel;
                oac.controlsHandle.(branch).ShownCheckBox.Position = posChBox;
                oac.controlsHandle.(branch).TransparencySlider.Position = posSlider;
                oac.controlsHandle.(branch).ColorPickerButton.Position = posColPicker;                         
  

            end

            oac.adjustControlPanelPosition

        end


        function remove(oac,branch)
            
                    if ~isfield(oac.controlsHandle,branch)
                        return
                    end
                    
                    h = oac.controlsHandle.(branch);
                    
                    delete(h.Label)
                    delete(h.ShownCheckBox)
                    delete(h.TransparencySlider)
                    delete(h.ColorPickerButton)

                    oac.controlsHandle = rmfield(oac.controlsHandle,branch);

                    oac.nControls = oac.nControls-1;

                    oac.reArrangeControls
        end
        
            
        function showColorMappingPanel(oac,callerBtn,~)
            
            % Find existing miniPanel 
            mp = findobj(oac.plotPanel.Children,'Tag','miniPanel');
           
            % Deal with situation if the miniPanel already exists from
            % previsou events
            if ~isempty(mp)
                
                % if miniPanel exist and was crated by the calling button,
                % close the miniPanel and return
                if isequal(callerBtn,mp.UserData.callerBtn)

                     delete(mp)
                     return

                % if miniPanel already exist and was created by another
                % button, delete and continue
                else

                     delete(mp)

                end
                               
            end
             
            branch = callerBtn.UserData.branch;

            % Create temporal miniPanel with color selection and mapping controls                   
            miniPanel = uipanel(oac.plotPanel,'Tag','miniPanel');
            miniPanel.UserData.branch = branch;            
            miniPanel.UserData.callerBtn = callerBtn;  % save infromation about which button triggered the event               
            miniPanelPos = [callerBtn.Position(1)-256,callerBtn.Position(2)-51,298,50];
            miniPanel.Position = miniPanelPos;
            miniPanel.BorderType = 'none';
            
            % Color mapping property selection dropDown
            propertyDropDown = uidropdown(miniPanel);
            propertyDropDown.Items = oac.mappingProperties;
            propertyDropDown.Value = callerBtn.UserData.mappingProperty;
            propertyDropDown.Position = [10,10,100,22];
            propertyDropDown.ValueChangedFcn = @(src,evt)oac.mappingPropertyChanged(src,evt,callerBtn,miniPanel);

            % Color map selection dropdown
            colorMapDropDown = uidropdown(miniPanel);
            colorMapDropDown.Items = oac.colorMapsNames;
            colorMapDropDown.Value = callerBtn.UserData.colorMap;
            colorMapDropDown.Position = [120,10,100,22];
            colorMapDropDown.ValueChangedFcn = @(src,evt)oac.colorMapChanged(src,evt,callerBtn,miniPanel);
            
 
            % assign styles (colormap icons) to drobdown items
            for i = 1:size(oac.colorMapsNames,2)

                mapName = oac.colorMapsNames{i};
                s = oac.colorMapStyles.(mapName);
                addStyle(colorMapDropDown,s,"item",i);

            end
            
            % Colore picker control
            ColorPicker = uicolorpicker(miniPanel);
            ColorPicker.Value = callerBtn.UserData.color;
            ColorPicker.Position = [235,10,40,22];
            ColorPicker.ValueChangedFcn = @(src,evt)oac.colorChanged(src,evt,callerBtn,miniPanel);

            % small pause to prevent reaction to buttonUp event
            pause(0.5)          


        end

        % MiniPanel color function 
        function colorChanged(oac,src,~,callerBtn,miniPanel)
            
            currentMap = callerBtn.UserData.colorMap;

            branch = callerBtn.UserData.branch;

            newColor = src.Value;
            callerBtn.BackgroundColor = newColor;
            callerBtn.UserData.color = newColor;                         

            switch currentMap
                case 'flat'

                    oac.callbacks.changeAppearance(branch,'color',newColor);
                    callerBtn.BackgroundColor = newColor;
                    callerBtn.Icon = '';

                case 'gray'

                    icon = oac.makeColorMapIcon(currentMap,newColor);
                    callerBtn.Icon = icon;
                    callerBtn.BackgroundColor = [0 0 0];

                    % oac.callbacks.changeAppearance(branch,'colorMap','gray');
                    % oac.callbacks.changeAppearance(branch,'color',newColor);
                    oac.callbacks.changeAppearance(branch,'colorMap','gray',newColor);

                otherwise

                    callerBtn.UserData.colorMap = 'flat';
                    callerBtn.Icon = '';
                    oac.callbacks.changeAppearance(branch,'color',newColor);

            end
            

            delete(miniPanel)

        end

        % MiniPanel colormap function 
        function colorMapChanged(oac,colorMapDropDown,~,callerBtn,miniPanel)

            branch = callerBtn.UserData.branch;
            newMap = colorMapDropDown.Value;
            color = [];

            switch newMap
                case 'flat'
                                            
                    callerBtn.UserData.color
                    icon = '';
                    callerBtn.BackgroundColor = callerBtn.UserData.color;

                case 'gray'

                    color = callerBtn.UserData.color;
                    icon = makeColorMapIcon(oac,'gray',color);
                    callerBtn.BackgroundColor = [0 0 0];

                otherwise

                    callerBtn.BackgroundColor = [0 0 0];
                    icon =  colorMapDropDown.StyleConfigurations(colorMapDropDown.ValueIndex,:).Style.Icon;

            end

            callerBtn.Icon = icon; 
            
            callerBtn.UserData.colorMap = newMap;
            
            oac.callbacks.changeAppearance(branch,'colorMap',newMap,color);
            
            delete(miniPanel)

        end


                
        
       
        function showColorControls(oac,src,~)
           
            status = src.Value;
                        
            h = findobj(oac.plotPanel,'Tag',oac.commonTag);

            if status
                set(h,'Visible','Off')

            else
                set(h,'Visible','On')                
            end

            oac.adjustControlPanelPosition
    
        end
       
       
        
    end

    methods (Access = protected)

        % MiniPanel map property function 
        function mappingPropertyChanged(oac,mappingPropertyDropDown,~,callerBtn,miniPanel)

            branch = callerBtn.UserData.branch;
            callerBtn.UserData.mappingProperty = mappingPropertyDropDown.Value;
            oac.callbacks.changeAppearance(branch,'mappingProperty',mappingPropertyDropDown.Value);
            delete(miniPanel)

        end

        function icon = makeColorMapIcon(~,mapName,color)

            n = 32; % size in pixels

            if isempty(color)
                color = [1 1 1];
            end

            if isempty(mapName)
                mapName = 'gray';
            end


            switch mapName

                case 'random'

                        icon = imresize(rand(5,5,3),4,"nearest");

                case 'gray'

                        map = gray(n);
                        c = repmat(color,n,1);                        
                        map = map.*c;
                        map = repmat(map,[1,1,n]);          
                        icon = permute(map,[3 1 2]);


                case 'flat'

                        map = white(n);
                        map = repmat(map,[1,1,n]);          
                        icon = permute(map,[3 1 2]);

                otherwise

                        mapFcn = str2func(mapName);
                        map = mapFcn(n);
                        map = repmat(map,[1,1,n]);          
                        icon = permute(map,[3 1 2]);        
            end

        end


    end
     
end