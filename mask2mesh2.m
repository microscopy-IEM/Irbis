
close all

% clear all;
load finalMap.mat


% 2D case
% finalMap = max(finalMap,[],3);
% padSize = 1;
% finalMap = padarray(finalMap,[padSize,padSize,padSize],0,'both');  


LL = mask;

CC = bwconncomp(LL)

CC.PixelIdxList{1};

s = regionprops(LL,'centroid',"FilledImage")

nRegs = size(s,1);

figure

allMeshes = cell(1,nRegs);

for ids = 1:nRegs
    s(ids)
    
    s(ids).FilledImage;
    v0 = s(ids).FilledImage;
    
    padSize = 2;
    v = padarray(v0,[padSize,padSize,padSize],0,'both');  
    
    v = imresize3(v,2,'method','linear');
    
    v = imgaussfilt3(double(v),1);
    
    isoThres = 0.1;
    % isosurface(v,isoThres);
    
    [~,verts] = extractIsosurface(v,isoThres);
    
    
    
    normals = isonormals(v,verts);
    verts = verts + 2.*s(ids).Centroid;
    
    ptCloud = pointCloud(verts);
    
    ptCloud.Normal = normals;
    
    % mesh = surfaceMesh(vertices,faces)
    
    % figure
    % pcshow(ptCloud)
    
    ptVertices = py.numpy.array(ptCloud.Location);
    ptNormals = py.numpy.array(ptCloud.Normal);

    mesh_data{1} = struct('vertices', ptVertices, ...
                            'vertexNormals', ptNormals);
    [~, meshCell, ~] = reconstruct_mesh_python(depth,mesh_data,1,1);
    
    % [n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(8,ptVertices,ptNormals,1,1);
    
    % verticesDict = dictionary(vertices);
    % facesDict = dictionary(faces);
    % vertexNormalsDict = dictionary(vertex_normals);
    % faceNormalsDict = dictionary(face_normals);
    % 
    % regionID = 1;
    % 
    % vertices = double(verticesDict(py.int(regionID)));
    % faces = double(facesDict(py.int(regionID)))+1;
    % vertexNormals = double(vertexNormalsDict(py.int(regionID)));
    % faceNormals = double(faceNormalsDict(py.int(regionID)));
    
    % mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);

    mesh = meshCell{1};
    
    allMeshes{ids} = mesh;
    % surfaceMeshShow(mesh)

  

end

% surfaceMeshShow(mesh)
c = 'm'
figure
ax1 = axes;
for ids = 1:nRegs
        
    mesh = allMeshes{ids};
        p = patch(ax1,'Faces',mesh.Faces,'Vertices',mesh.Vertices,'FaceColor',c);
        p.LineStyle = 'none';
        p.FaceAlpha = 0.6;
        hold on

end

axis equal

l1 = light(ax1)