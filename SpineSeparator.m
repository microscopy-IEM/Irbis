classdef SpineSeparator < handle
    properties (Access = private)
        app
        config
        child1Branch = 'spines'
        child2Branch = 'dendrite'
        parent1Branch = 'shaft'
        parent2Branch = 'fullVolume'
    end
    
    methods
        function obj = SpineSeparator(app)
            obj.app = app;
        end
        
        function separateSpines(obj)
            obj.setupInitialState();
            
            currentTimePoint = obj.app.TimePointSlider.Value;
            modelIdParent1 = obj.app.timeline.currentIndex.model.(obj.parent1Branch)(currentTimePoint);
            List = obj.app.model.(obj.parent1Branch).List{modelIdParent1};
            
            for objectId = obj.app.appData.objectsForSeparation
                timePoints = obj.determineTimePoints(List, objectId, currentTimePoint);
                obj.processTimePoints(timePoints, objectId);
            end
            
            obj.finalizeSpineSeparation(timePoints);
        end
    end
    
    methods (Access = private)
        function setupInitialState(obj)
            obj.app.IrbisMainFig.WindowKeyReleaseFcn = obj.app.appData.windowKeyReleaseCallback;
            set(obj.app.InstructionsPanel, 'Visible', 'off');
        end
        
        function timePoints = determineTimePoints(obj, List, objectId, currentTimePoint)
            groupId = List{num2str(objectId), 'groupId'};
            
            if obj.app.(['AlltimepointsCheckBox_' obj.child1Branch]).Value
                timePoints = obj.handleAllTimePoints(groupId, currentTimePoint);
            else
                timePoints = currentTimePoint;
            end
        end
        
        function timePoints = handleAllTimePoints(obj, groupId, currentTimePoint)
            if isequal(groupId, 0)
                timePoints = currentTimePoint;
                obj.showTimePointWarning('not registered');
                return;
            end
            
            timePoints = 1:obj.app.timeline.nTimePoints;
            for i = timePoints
                if ~obj.isGroupIdPresent(i, groupId)
                    timePoints = 1:(i-1);
                    obj.showTimePointWarning('interrupted', i);
                    break;
                end
            end
        end
        
        function processTimePoints(obj, timePoints, objectId)
            for currentTimePoint = timePoints
                wb = obj.createProgressDialog(currentTimePoint);
                try
                    [child1List, child2List, modelIds] = obj.initializeLists(currentTimePoint);
                    [parent1Info, parent2Info] = obj.getParentInfo(modelIds, objectId);
                    
                    mesh_data = obj.prepareMeshData(parent1Info, parent2Info);
                    if isempty(mesh_data), continue; end
                    
                    obj.processSpines(wb, mesh_data, parent1Info, modelIds, child1List);
                    obj.processDendrite(wb, mesh_data, parent1Info, modelIds, child2List);
                    
                    obj.updateParentRelations(parent1Info, parent2Info, modelIds);
                catch ex
                    warning('Error processing timepoint %d: %s', currentTimePoint, ex.message);
                end
                close(wb);
            end
        end
        
        function finalizeSpineSeparation(obj, timePoints)
            % Set visibility
            obj.app.model.(obj.child1Branch).Show = 1;
            obj.app.model.(obj.child2Branch).Show = 1;
            obj.app.model.(obj.parent1Branch).Show = 0;
            obj.app.model.(obj.parent2Branch).Show = 0;
            
            % Update features and UI
            obj.app.calculateFeatures(obj.child1Branch, timePoints);
            obj.app.calculateFeatures(obj.child2Branch, timePoints);
            
            obj.updateUI();
        end
        
        % ... additional helper methods would go here ...
    end
end