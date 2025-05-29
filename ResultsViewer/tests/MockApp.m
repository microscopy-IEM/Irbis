% Helper mock class
classdef MockApp < handle
    properties
        MockGridLayout
        currentModality = '';
        currentBranch = '';
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

        % these are just helper methods to get the desired output
        function setModality(obj, modalityName)
            obj.currentModality = modalityName;
        end

        function setBranch(obj, branchName)
            obj.currentBranch = branchName;
        end
    end


    methods % these simulate the methods from the actual app
        function modality = getActiveModality(obj)
            modality = obj.currentModality;
        end
        
        function branch = getActiveBranch(obj)
            branch = obj.currentBranch;
        end

        function layout = getTableComponentGridLayout(obj)
            layout = obj.MockGridLayout;
        end

        function layout = getFilteringMenuGridLayout(obj)
            layout = obj.MockGridLayout;
        end
    end
end