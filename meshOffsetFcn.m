% Function perform offsetting of mesh both inward and outward with defined
% step and returns offset volume profile

function offsetVolumeProfile = meshOffsetFcn(Mesh) 

% clc;close all;

% Mesh

offsetStepIn = -0.01;

% offsetStepOut = 0.025;
offsetStepOut = 0.03;
totalOffsetOut = 0.5;

queryOffsets = -0.3:0.025:totalOffsetOut;

% nSteps = round(totalOffsetOut/offsetStepOut)*5;

doPlot = 1;

currentMesh = surfaceMesh(Mesh.Vertices,Mesh.Faces);

initMeshisIntersecting = isSelfIntersecting(currentMesh);
initMeshisWaterTight = isWatertight(currentMesh);

if initMeshisIntersecting || ~initMeshisWaterTight

    return

end

initMeshVol = compute_mesh_volume(currentMesh.Vertices, currentMesh.Faces);

disp(['init isIntersectiing = ' num2str(initMeshisIntersecting)])
disp(['init isWaterTight = ' num2str(initMeshisWaterTight)])


if doPlot
    figure(1)
    ax = axes; 
    axis equal
    hold on
    col = 'r';
    p = patch(ax,'Faces',currentMesh.Faces,'Vertices',currentMesh.Vertices,'Tag','zone1','FaceColor',col);
    p.FaceAlpha = 1;
    
    p.EdgeColor = col;
    p.FaceColor = col;
    p.LineWidth = 0.5;
    p.LineStyle = 'none';
    
    light(ax)
    view(142.5,30);
    ax.Clipping = 'off';

end

origVerts = currentMesh.Vertices;

% meshVolOut = nan(1,nSteps);
% medianDistOut = nan(1,nSteps);

subdivide(currentMesh,"midpoint-split",1)

%% Outward offset
offsetCount = 0;
nSteps = 0;
i = 0;

% subdivide(currentMesh,"midpoint-split",1)

while offsetCount < totalOffsetOut

    i = i+1;
    nSteps = nSteps+1;

    if nSteps > 100
        break
    end

    if i == 5
        
        % subdivide(currentMesh,"midpoint-split",1)

    end

    disp(num2str(i))

    % currentMesh = smoothSurfaceMesh(currentMesh,1,Method="Laplacian",ScaleFactor=0.99);
    currentMesh = smoothSurfaceMesh(currentMesh,1,Method="Average");
           
    computeNormals(currentMesh)
    
    newVerts = currentMesh.Vertices + currentMesh.VertexNormals.*offsetStepOut;

    tempMesh = surfaceMesh(newVerts,currentMesh.Faces);
                
    isIntersecting = isSelfIntersecting(tempMesh);
    isWaterTight = isWatertight(tempMesh);    

  
    if isIntersecting || ~isWaterTight

         disp(['isIntersectiing = ' num2str(isIntersecting)])
         disp(['isWaterTight = ' num2str(isWaterTight)])
         disp(num2str(i))

         break

    end

    [D,I] = pdist2(origVerts,newVerts,'euclidean','Smallest',1);
  
    medianDistOut(i) = median(D);
    meshVolOut(i) = compute_mesh_volume(tempMesh.Vertices, tempMesh.Faces);

    currentMesh = tempMesh;
    
    % disp(['Median distance = ' num2str(medianDist(i))])

    if doPlot

        p = patch(ax,'Faces',tempMesh.Faces,'Vertices',tempMesh.Vertices,'Tag','zone1','FaceColor','b');
        p.FaceAlpha = 0.05;
        p.LineStyle = 'none';

    end

    offsetCount = medianDistOut(i);

        
end


%% Inward offset

currentMesh = surfaceMesh(Mesh.Vertices,Mesh.Faces);
voxSize = abs(offsetStepIn*2.1);

if doPlot
    figure(2)
    ax = axes; 
    axis equal
    hold on
    col = 'r';
    p = patch(ax,'Faces',currentMesh.Faces,'Vertices',currentMesh.Vertices,'Tag','zone1','FaceColor',col);
    p.FaceAlpha = 0.2;
    
    p.EdgeColor = col;
    p.FaceColor = col;
    p.LineWidth = 0.5;
    p.LineStyle = 'none';
    
    light(ax)
    view(142.5,30);
    ax.Clipping = 'off';

end

medianDistIn = [];
meshVolIn = [];

for i = 1:30

    voxSize = voxSize*1.1;

    % disp(num2str(i))
   
    currentMesh = smoothSurfaceMesh(currentMesh,1,Method="Laplacian",ScaleFactor=0.99);

    simplify(currentMesh,SimplificationMethod="vertex-clustering",VoxelSize=voxSize,MergeMethod="Average");

    if currentMesh.NumVertices < 10
        break
    end

    removeDefects(currentMesh,"duplicate-vertices")
    
    computeNormals(currentMesh)

    verts = currentMesh.Vertices;
    center = vertexCenter(currentMesh);
    vertNormals = currentMesh.VertexNormals;

    newVerts = verts + vertNormals.*offsetStepIn;

    tempMesh = surfaceMesh(newVerts,currentMesh.Faces);
 
    [D,I] = pdist2(origVerts,newVerts,'euclidean','Smallest',1);
    

    isIntersecting = isSelfIntersecting(tempMesh);
    % disp(['isIntersectiing = ' num2str(isIntersecting)])
    isWaterTight = isWatertight(tempMesh);
    % disp(['isWaterTight = ' num2str(isWaterTight)])
 
    if isIntersecting

         break

    end

    medianDistIn(i) = -median(D);
    meshVolIn(i) = compute_mesh_volume(tempMesh.Vertices, tempMesh.Faces);

    % disp(['Mean distance = ' num2str(meanDist)])
    % disp(['Median distance = ' num2str(medianDistIn(i))])

    
    if doPlot

        col = 'b';
        p = patch(ax,'Faces',tempMesh.Faces,'Vertices',tempMesh.Vertices,'Tag','zone1','FaceColor','b');
        p.FaceAlpha = 0.1;
        p.LineStyle = 'none';

    end

    currentMesh = tempMesh;
    
end

% meshVolIn = sort(meshVolIn)

meshVolIn = meshVolIn(end:-1:1);
medianDistIn = medianDistIn(end:-1:1);

Dist = [medianDistIn 0 medianDistOut];
Vol = [meshVolIn initMeshVol meshVolOut];

if doPlot
    figure
    plot(Dist ,Vol)
end


offsetVolumeProfile = interp1(Dist,Vol,queryOffsets);

if doPlot
    figure
    scatter(queryOffsets,offsetVolumeProfile)
end