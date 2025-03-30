        function spineSeparation(app,~,~)

            meshLibraryToUse = (app.meshLibrarySwitch.Value); % 1 corresponds to pymeshlab (default), 2 to trimesh
            % disp(class(meshLibraryToUse))
            % disp(meshLibraryToUse)

            % reset key release function
            app.IrbisMainFig.WindowKeyReleaseFcn = app.appData.windowKeyReleaseCallback;

            % disp(app.appData.objectsForSeparation)

            % branch definition: 
            child1Branch = 'spines';
            child2Branch = 'dendrite';

            parent1Branch = 'shaft';
            parent2Branch = 'fullVolume';            

            % setup and scene preparation: 
            set(app.InstructionsPanel,'Visible','off');

            % connectivity in time - groupId determination:
            currentTimePoint = app.TimePointSlider.Value;
            modelIdParent1 = app.timeline.currentIndex.model.(parent1Branch)(currentTimePoint);
            List = app.model.(parent1Branch).List{modelIdParent1};

            for objectId = app.appData.objectsForSeparation

            % objectId = app.appData.selectedObjectId;
            groupId = List{num2str(objectId),'groupId'};

            initialTimePoint = 1;
            % single time points or all time points
            if app.(['AlltimepointsCheckBox_' child1Branch]).Value
                timePoints = initialTimePoint:app.timeline.nTimePoints;
                if isequal(groupId,0)
                    % the object is not connected in time
                    timePoints = currentTimePoint;
                    message = 'The object is not registered in time. Separation is performed only for the first time point.';
                    uialert(app.IrbisMainFig,message,'Warning','Icon','warning')  

                else
                    for i=timePoints
                        modelIdParent1 = app.timeline.currentIndex.model.(parent1Branch)(currentTimePoint);
                        if ~ismember(groupId,app.model.(parent1Branch).List{modelIdParent1}.groupId)
                            interruptedTP = i;
                            timePoints = initialTimePoint:(interruptedTP-1);
                            message = ['The chain with the same groupId is interrupted at time point ' num2str(interruptedTP) '. Separation is performed only for the previous time points. ' ...
                                'If you want to change this, register the objects manually.'];
                            uialert(app.IrbisMainFig,message,'Warning','Icon','warning')                        
                            break
                        end
                    end
                end
            else
                timePoints = currentTimePoint;
            end

            for currentTimePoint = timePoints

                % lists: 

                modelIdChild1 = app.timeline.currentIndex.model.(child1Branch)(currentTimePoint);
                if modelIdChild1
                    child1List = app.model.(child1Branch).List{modelIdChild1};
                    if isempty(child1List)
                        child1List = getBaseStruct('table','model',0,{'spines'});
                    end
                else
                    modelIdChild1 = max(app.timeline.currentIndex.model.(child1Branch)) + 1;
                    child1List = getBaseStruct('table','model',0,{'spines'});
                    app.timeline.currentIndex.model.(child1Branch)(currentTimePoint) = modelIdChild1;
                end
                % child1List
                modelIdChild2 = app.timeline.currentIndex.model.(child2Branch)(currentTimePoint);
                if modelIdChild2
                    child2List = app.model.(child2Branch).List{modelIdChild2};
                else 
                    modelIdChild2 = max(app.timeline.currentIndex.model.(child2Branch)) + 1;
                    child2List = getBaseStruct('table','model',0);
                    app.timeline.currentIndex.model.(child2Branch)(currentTimePoint) = modelIdChild2;
                end

                modelIdParent1 = app.timeline.currentIndex.model.(parent1Branch)(currentTimePoint);
                modelIdParent2 = app.timeline.currentIndex.model.(parent2Branch)(currentTimePoint);
                parent1List = app.model.(parent1Branch).List{modelIdParent1};
                parent2List = app.model.(parent2Branch).List{modelIdParent2};

                child1List_rowNum = 1;
                child1List_rowId = 1;
                child2List_rowNum = 1;
                child2List_rowId = 1;

                
                if ~isequal(groupId,0)
                    parent1RowNum = find(parent1List{:,'groupId'} == groupId);
                else
                    % disp('groupId is 0')
                    % disp(cell2mat(parent1List.Properties.RowNames))
                    % disp((double(objectId)))
                    parent1RowNum = find(str2double(parent1List.Properties.RowNames) == objectId);
                    % disp(double(str2double(parent1List.Properties.RowNames)) == double(objectId))
                end

                % disp(parent1RowNum)
                parent1RowName = parent1List.Properties.RowNames{parent1RowNum};
                parent1ObjectId = str2double(parent1RowName);

                % TO OPTIMIZE - add possibility to select more parents
                if ~isempty(child1List)
                    valuesToDelete = (strcmp(child1List{:,'name'},['S' parent1RowName]));
                    child1List(valuesToDelete,:) = [];
                    if ~isempty(child1List)
                        child1List_lenght = size(child1List,1);
                        child1List_maxRowId = max(str2double(child1List.Properties.RowNames));
                        child1List_rowNum = child1List_lenght + 1;
                        child1List_rowId = child1List_maxRowId + 1;
                    end
                end
                if ~isempty(child2List)
                    valuesToDelete = (strcmp(child2List{:,'name'},['S' parent1RowName]));
                    child2List(valuesToDelete,:) = [];
                    if ~isempty(child2List)
                        child2List_lenght = size(child2List,1);
                        child2List_maxRowId = max(str2double(child2List.Properties.RowNames));
                        child2List_rowNum = child2List_lenght + 1;
                        child2List_rowId = child2List_maxRowId + 1;
                    end                        
                end
                % Create waiting bar
                wb = uiprogressdlg(app.IrbisMainFig,'Title',['Separating spines for time point ' num2str(currentTimePoint)],'Message','Generating...','Cancelable','off');
                nSteps = 5;
                wb.Value = 1/nSteps;
                wb.Message = sprintf('Starting separation...');

                %% Saving meshes
                wb.Value = 1/nSteps;
                wb.Message = sprintf('Saving 3D model to temp file...');                

                % FAMILY STRUCTURE CHANGE 
                    % now, parent1 is child of parent2, not the other way as before 

                parent1ParentCell = parent1List{parent1RowNum,'parent'};
                parent2ObjectId = cell2mat(parent1ParentCell{1}(parent2Branch));
                parent2RowName = num2str(parent2ObjectId);

                currentFullMeshCell = parent2List{parent2RowName,'Mesh'};
                currentFullMesh = currentFullMeshCell{1};
                % disp('fullVolume watertight')
                % disp(isWatertight(currentFullMesh))

                % Initialize mesh_data cell array
                mesh_data = cell(1, 2);

                mesh_data{1} = struct('vertices', currentFullMesh.Vertices, ...
                                        'faces', currentFullMesh.Faces - 1); % Zero-index for Python
                
                % Conditionally add vertexNormals if not empty
                if ~isempty(currentFullMesh.VertexNormals)
                    mesh_data{1}.vertexNormals = currentFullMesh.VertexNormals;
                end
                
                % Conditionally add faceNormals if not empty
                if ~isempty(currentFullMesh.FaceNormals)
                    mesh_data{1}.faceNormals = currentFullMesh.FaceNormals;
                end

                % % writeSurfaceMesh(currentFullMesh,[app.appData.tempSubfolderPath '\' 'temp_meshParent1.ply']);
                % verticesBig = py.numpy.array(currentFullMesh.Vertices);
                % facesBig = py.numpy.array(currentFullMesh.Faces-1);
                % vertexNormalsBig = py.numpy.array(currentFullMesh.VertexNormals);
                % faceNormalsBig = py.numpy.array(currentFullMesh.FaceNormals);
                
               
                currentDendriticShaftMeshCell = parent1List{parent1RowName,'Mesh'};
                currentDendriticShaftMesh = currentDendriticShaftMeshCell{1};
                % disp('shaft watertight')
                % disp(isWatertight(currentDendriticShaftMesh))

                if isempty(currentDendriticShaftMesh)
                    uialert(app.IrbisMainFig,'The shaft mesh is not yet generated.','Warning')
                    break
                end

                mesh_data{2} = struct('vertices', currentDendriticShaftMesh.Vertices, ...
                                        'faces', currentDendriticShaftMesh.Faces - 1); % Zero-index for Python
                
                % Conditionally add vertexNormals if not empty
                if ~isempty(currentDendriticShaftMesh.VertexNormals)
                    mesh_data{2}.vertexNormals = currentDendriticShaftMesh.VertexNormals;
                end
                
                % Conditionally add faceNormals if not empty
                if ~isempty(currentDendriticShaftMesh.FaceNormals)
                    mesh_data{2}.faceNormals = currentDendriticShaftMesh.FaceNormals;
                end
               
                % verticesSmall = py.numpy.array(currentDendriticShaftMesh.Vertices);
                % facesSmall = py.numpy.array(currentDendriticShaftMesh.Faces-1);
                % vertexNormalsSmall = py.numpy.array(currentDendriticShaftMesh.VertexNormals);
                % faceNormalsSmall = py.numpy.array(currentDendriticShaftMesh.FaceNormals);
                % writeSurfaceMesh(currentDendriticShaftMesh,[app.appData.tempSubfolderPath '\' 'temp_meshParent2.ply']);

                %% Separating spines
                wb.Value = 2/nSteps;
                wb.Message = sprintf('Separating spines...');                   

                [~, meshes, basePoints] = mesh_subtract_and_separate_and_save_plane_python(mesh_data, meshLibraryToUse);
                % [n_objects,vertices,faces,vertex_normals,face_normals,base_points] = mesh_subtract_and_separate_and_save_plane_python( ...
                %     verticesBig,facesBig,vertexNormalsBig,faceNormalsBig,verticesSmall,facesSmall,vertexNormalsSmall,faceNormalsSmall);
                % nReg = int8(n_objects);
                % 
                % disp('nReg')
                % disp(nReg)

                % verticesDict = dictionary(vertices);
                % facesDict = dictionary(faces);
                % vertexNormalsDict = dictionary(vertex_normals);
                % faceNormalsDict = dictionary(face_normals);
                % disp('base points')
                % disp(class(base_points))
                % disp(size(base_points))
                % basePoints = double(base_points);
      
                traj = cell2mat(parent1List{parent1RowName,'CentreLine'});

                %% Saving spines
                wb.Value = 4/nSteps;
                wb.Message = sprintf('Saving spines...');  

                child1Ids = {};
                minPoints = 20;

                % Get all vertices, faces, vertexNormals, and faceNormals in one go
                % verticesCell = cellfun(@(id) double(verticesDict(py.int(id))), num2cell(1:nReg), 'UniformOutput', false);
                % facesCell = cellfun(@(id) double(facesDict(py.int(id))) + 1, num2cell(1:nReg), 'UniformOutput', false);
                % vertexNormalsCell = cellfun(@(id) double(vertexNormalsDict(py.int(id))), num2cell(1:nReg), 'UniformOutput', false);
                % faceNormalsCell = cellfun(@(id) double(faceNormalsDict(py.int(id))), num2cell(1:nReg), 'UniformOutput', false);

                % Create surface meshes
                % meshes = cellfun(@(v, f, vn, fn) surfaceMesh(v, f, "VertexNormals", vn, "FaceNormals", fn), ...
                %     verticesCell, facesCell, vertexNormalsCell, faceNormalsCell, 'UniformOutput', false);
                
                % Extract points
                pointsCell = cellfun(@(m) m.Vertices, meshes, 'UniformOutput', false);

                % Filter out regions with insufficient points
                validIndices = cellfun(@(pts) size(pts, 1) > minPoints, pointsCell);

                % Apply the validIndices filter to all relevant variables
                validMeshes = meshes(validIndices)';
                validPointsCell = pointsCell(validIndices)';
                validBasePoints = basePoints(validIndices, :);

                % Precompute vectors and norms for valid regions
                vecB = validBasePoints(:,1:3);
                [pointIdx, ~] = knnsearch(traj, vecB);
                vecA = traj(pointIdx, :);
                vecNorms = sqrt(sum((vecA - vecB).^2, 2));
                vec = (vecA - vecB) ./ vecNorms;

                % Prepare the table entries
                numValidRegions = sum(validIndices);

                % generate table with default rows for the new data
                T = getBaseStruct('table','model',numValidRegions,{'spines'});
                
                T.Points = validPointsCell;
                T.Mesh = validMeshes;
                T.name = repmat(['S' parent1RowName], numValidRegions, 1);
                T.parent = repmat({dictionary([string(parent1Branch) string(parent2Branch)],[{parent1ObjectId} {parent2ObjectId}])}, numValidRegions, 1);
                T.positionShift = repmat({[0 0 0]}, numValidRegions, 1);
                T.cuttingPlaneCentre = basePoints(validIndices,1:3);
                T.cuttingPlaneNormal = vec;
                T.color = mat2cell(rand(numValidRegions,3), ones(numValidRegions, 1), 3);


                % Generate row names for the specified range
                rowNames = arrayfun(@num2str, child1List_rowId:child1List_rowId + numValidRegions - 1, 'UniformOutput', false);
                T.Properties.RowNames = rowNames;

                child1Ids = {child1List_rowId:child1List_rowId + numValidRegions - 1};

                app.model.(child1Branch).List{modelIdChild1} = vertcat(child1List,T);

                % for regionID = 1:nReg
                % 
                %     vertices = double(verticesDict(py.int(regionID)));
                %     faces = double(facesDict(py.int(regionID)))+1;
                %     vertexNormals = double(vertexNormalsDict(py.int(regionID)));
                %     faceNormals = double(faceNormalsDict(py.int(regionID)));
                % 
                %     Mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);
                %     % nameReg = ['temp_subtract_' num2str(regionID) '.ply'];
                %     % Mesh = readSurfaceMesh([app.appData.tempSubfolderPath '\' nameReg]);
                % 
                %     Points = Mesh.Vertices;
                % 
                %     if size(Points,1) > minPoints
                %         % TO OPTIMIZE - instead of for cycle, first remove the ones with too little points and then assign the remaining to the table
                %         vecB = [basePoints(regionID,1),basePoints(regionID,2),basePoints(regionID,3)];
                %         [pointIdx,~] = knnsearch(traj,vecB);
                %         vecA = traj(pointIdx,:);
                %         vec = (vecA - vecB)/norm(vecA - vecB);
                % 
                %         % add row to spine table
                %         child1List(child1List_rowNum,1:11) = {0,Points,{Mesh},['S' parent1RowName],0,0,{},{},0,0,{[0,0,0]}};
                %         child1List(child1List_rowNum,'parent') = {dictionary([string(parent1Branch) string(parent2Branch)],[{parent1ObjectId} {parent2ObjectId}])};
                %         % saving info about cutting plane into the main List table
                %         child1List(child1List_rowNum,'cuttingPlaneCentre') = {basePoints(regionID,1:3)};
                %         child1List(child1List_rowNum,'cuttingPlaneNormal') = {vec};
                %         child1List.Properties.RowNames{child1List_rowNum} = num2str(child1List_rowId);
                % 
                %         child1Ids{end + 1} = child1List_rowId;
                % 
                %         child1List_rowNum = child1List_rowNum+1; 
                %         child1List_rowId = child1List_rowId+1; 
                %     end
                % end
                % app.model.(child1Branch).List{modelIdChild1} = child1List;

                %% Separating dendrite center from the spines
                wb.Value = 4/nSteps;
                wb.Message = sprintf('Separating dendrite center from the spines...');  

                [~, meshes] = mesh_intersect_and_separate_python(mesh_data, meshLibraryToUse);
                % [n_objects,vertices,faces,vertex_normals,face_normals] = mesh_intersect_and_separate_python( ...
                %     verticesBig,facesBig,vertexNormalsBig,faceNormalsBig,verticesSmall,facesSmall,vertexNormalsSmall,faceNormalsSmall);
                % nReg = int8(n_objects);

                % verticesDict = dictionary(vertices);
                % facesDict = dictionary(faces);
                % vertexNormalsDict = dictionary(vertex_normals);
                % faceNormalsDict = dictionary(face_normals);

                % disp(['Dendrite separation in Python: ' num2str(toc)])
                minPoints = 20;

                % Extract points
                pointsCell = cellfun(@(m) m.Vertices, meshes, 'UniformOutput', false);

                % Filter out regions with insufficient points
                validIndices = cellfun(@(pts) size(pts, 1) > minPoints, pointsCell);

                % Apply the validIndices filter to all relevant variables
                validMeshes = meshes(validIndices)';
                validPointsCell = pointsCell(validIndices)';

                % Prepare the table entries
                numValidRegions = sum(validIndices);

                % generate table with default rows for the new data
                T = getBaseStruct('table','model',numValidRegions);
                
                T.Points = validPointsCell;
                T.Mesh = validMeshes;
                T.name = repmat(['S' parent1RowName], numValidRegions, 1);
                T.parent = repmat({dictionary([string(parent1Branch) string(parent2Branch)],[{parent1ObjectId} {parent2ObjectId}])}, numValidRegions, 1);
                T.positionShift = repmat({[0 0 0]}, numValidRegions, 1);
                T.color = mat2cell(rand(numValidRegions,3), ones(numValidRegions, 1), 3);

                child2Ids = {child2List_rowId:child2List_rowId + numValidRegions - 1};

                % Generate row names for the specified range
                rowNames = arrayfun(@num2str, child2List_rowId:child2List_rowId + numValidRegions - 1, 'UniformOutput', false);
                T.Properties.RowNames = rowNames;

                % disp(child2List)
                % disp(T)
                app.model.(child2Branch).List{modelIdChild2} = vertcat(child2List,T);

                % child2Ids = {};
                % for regionID = 1:nReg
                %     % nameReg = ['temp_intersect_' num2str(regionID) '.ply'];
                %     % Mesh = readSurfaceMesh([app.appData.tempSubfolderPath '\' nameReg]);
                %     vertices = double(verticesDict(py.int(regionID)));
                %     faces = double(facesDict(py.int(regionID)))+1;
                %     vertexNormals = double(vertexNormalsDict(py.int(regionID)));
                %     faceNormals = double(faceNormalsDict(py.int(regionID)));
                % 
                %     Mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);
                %     Points = Mesh.Vertices;
                % 
                %     if size(Points,1) > minPoints
                % 
                % 
                %         % add row to table
                %         child2List(child2List_rowNum,1:11) = {0,Points,{Mesh},['S' parent1RowName],0,0,{},{},0,0,{[0,0,0]}};
                %         child2List(child2List_rowNum,'parent') = {dictionary([string(parent1Branch) string(parent2Branch)],[{parent1ObjectId} {parent2ObjectId}])};
                %         child2List.Properties.RowNames{child2List_rowNum} = num2str(child2List_rowId);
                % 
                %         child2Ids{end + 1} = child2List_rowId;
                % 
                %         child2List_rowNum = child2List_rowNum+1; 
                %         child2List_rowId = child2List_rowId+1; 
                %     end
                % end
                % app.model.(child2Branch).List{modelIdChild2} = child2List;

                parent1Dict = app.model.(parent1Branch).List{modelIdParent1}{parent1RowNum,'children'}{1};
                parent2Dict = app.model.(parent2Branch).List{modelIdParent2}{num2str(parent2ObjectId),'children'}{1};

                if isempty(parent1Dict)
                    parent1Dict = dictionary();
                end
                if isempty(parent2Dict)
                    parent2Dict = dictionary();
                end

                parent1Dict{child1Branch} = child1Ids;
                parent2Dict{child1Branch} = child1Ids;

                parent1Dict{child2Branch} = child2Ids;
                parent2Dict{child2Branch} = child2Ids;

                app.model.(parent1Branch).List{modelIdParent1}{parent1RowNum,'children'}{1} = parent1Dict;
                app.model.(parent2Branch).List{modelIdParent2}{num2str(parent2ObjectId),'children'}{1} = parent2Dict;

                % if app.(['AlltimepointsCheckBox_' child1Branch]).Value
                %     evt.Source.Tag = child1Branch;
                %     evt.NewValue = 0.5;     % TO OPTIMIZE - this should be taken from the component, not hard-set
                %     app.objectListComponentrunTimeRegistration(evt);
                % end

            end

            end

            % Activate default model plot preference
            app.model.(child1Branch).Show = 1;
            app.model.(child2Branch).Show = 1;
            app.model.(parent1Branch).Show = 0; % not needed to show afte spines and dendrite creation
            app.model.(parent2Branch).Show = 0; % not needed to show

            app.calculateFeatures(child1Branch,timePoints);
            app.calculateFeatures(child2Branch,timePoints);
            
            app.loadParametersToComponents(child1Branch);
            app.updateHistogramAndListBoxes(child1Branch);
            
            app.plotObjects(child1Branch);
            app.plotObjects(child2Branch);
            app.ModelCheckBoxValueChanged
            
            app.model.selectableBranches = {child1Branch, child2Branch};
            app.objectSelectabilityChanged;

            % Expand second step sections
            app.showSecondStepSections(child1Branch);
            app.timepointsPresentLabel.Text = processDoubleArraysWithPaths(app.timeline.currentIndex, '', 'capture');

        end