% Helper mock class
classdef MockApp < handle
    
    events
        modalityChangedByUser
        branchChangedByUser
    end
    
    methods
        function modality = getActiveModality(~)
            modality = '';
        end
        
        function branch = getActiveBranch(~)
            branch = '';
        end
    end
end