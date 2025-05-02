% Helper mock class
classdef MockApp < handle
    properties
        MockGridLayout
    end
    
    events
        modalityChangedByUser
        branchChangedByUser
    end
    
    methods
        function obj = MockApp()
            % Create a dummy figure and grid layout for testing
            f = uifigure('Visible', 'off');  % avoid GUI popping up during test
            obj.MockGridLayout = uigridlayout(f, [10, 10]); % size adjusted to fit the requirements
        end

        function modality = getActiveModality(~)
            modality = '';
        end
        
        function branch = getActiveBranch(~)
            branch = '';
        end

        function layout = getTableComponentGridLayout(obj)
            layout = obj.MockGridLayout;
        end

        function layout = getFilteringMenuGridLayout(obj)
            layout = obj.MockGridLayout;
        end
    end
end