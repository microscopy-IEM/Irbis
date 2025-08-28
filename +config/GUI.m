classdef (Sealed) GUI
    methods (Static)
        function channelColors = getChannelColors(nChannels)
            % Irbis palette
            Irbis_pink = '#ee3377';
            Irbis_blue = '#009988';
            Irbis_yellow = '#ffdd00';
            Irbis_green = '#33bbee';

            % IBM palette
            IBM_pink = '#dc267f';
            IBM_blue = '#648fff';
            IBM_orange ='#fe6100';

            % Wong pallete
            pale_violet = '#cc79a7';
            sky_blue = '#56b4e9';
            blue_green = '#009e73';
            orange = '#e69f00';
            vermillion = '#d55e00';

            % Base color set
            baseColors = {hex2rgb(Irbis_pink), hex2rgb(Irbis_blue), hex2rgb(Irbis_yellow), ...
                 hex2rgb(Irbis_green), hex2rgb(vermillion), hex2rgb(IBM_pink), ...
                 hex2rgb(IBM_blue), hex2rgb(IBM_orange), hex2rgb(pale_violet), ...
                 hex2rgb(sky_blue), hex2rgb(blue_green), hex2rgb(orange)};
            
            % Initialize the output cell array
            channelColors = cell(1, nChannels);

            if nChannels == 1
                channelColors{1} = hex2rgb("#FFFFFF");
                disp('single channel planes')
            else
            
                % Fill the output with colors, repeating the base set if necessary
                baseColorCount = length(baseColors);
                for i = 1:nChannels
                    colorIndex = mod(i-1, baseColorCount) + 1;
                    channelColors{i} = baseColors{colorIndex};
                end

            end
        end

        
        function channelColormaps = getChannelColormaps(nChannels)
            % Default colormap for all channels
            channelColormaps = cell(1, nChannels);
            for i = 1:nChannels
                channelColormaps{i} = 'gray'; % Default colormap is gray for all channels
            end
        end


        function channelNames = getChannelNames(nChannels)
            % Generate default channel names
            channelNames = cell(1, nChannels);
            for i = 1:nChannels
                channelNames{i} = ['ch' num2str(i)];
            end
        end
    end
end