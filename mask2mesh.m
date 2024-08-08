
close all

% clear all;
% load finalMap.mat

LL = finalMap;

CC = bwconncomp(LL)

CC.PixelIdxList{1};

s = regionprops(LL,'centroid',"BoundingBox","PixelList","FilledImage")

ids = 5;
s(ids)

s(ids).FilledImage
v0 = s(ids).FilledImage;

padSize = 2;
v = padarray(v0,[padSize,padSize,padSize],0,'both');  

v = imresize3(v,2,'method','linear');

v = imgaussfilt3(double(v),1);

isoThres = 0.1;
isosurface(v,isoThres)

[~,verts] = extractIsosurface(v,isoThres);



normals = isonormals(v,verts);
verts = verts + s(ids).Centroid;

ptCloud = pointCloud(verts);

ptCloud.Normal = normals;

% mesh = surfaceMesh(vertices,faces)

figure
pcshow(ptCloud)

ptVertices = py.numpy.array(ptCloud.Location);
ptNormals = py.numpy.array(ptCloud.Normal);

[n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(8,ptVertices,ptNormals,1,1);

verticesDict = dictionary(vertices);
facesDict = dictionary(faces);
vertexNormalsDict = dictionary(vertex_normals);
faceNormalsDict = dictionary(face_normals);

regionID = 1

vertices = double(verticesDict(py.int(regionID)));
faces = double(facesDict(py.int(regionID)))+1;
vertexNormals = double(vertexNormalsDict(py.int(regionID)));
faceNormals = double(faceNormalsDict(py.int(regionID)));

mesh = surfaceMesh(vertices,faces,"VertexNormals",vertexNormals,"FaceNormals",faceNormals);

surfaceMeshShow(mesh)