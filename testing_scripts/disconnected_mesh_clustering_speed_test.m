profile on

% [faceClusterIdx,clusterNumFaces,~] = clusterConnectedFaces(fullMesh);                   
% nReg = length(clusterNumFaces);

% original approach
tic
for objIdx = 1:nReg
    
    idx = 1:size(verts,1);
    firstFaces = faces(faceClusterIdx==objIdx,:);
    idx(unique(firstFaces))=[];
    singleObjMesh = surfaceMesh(verts,firstFaces);
    removeVertices(singleObjMesh,idx)
end
toc
% 44s for mesh with 3 mil vertices


% new approach
tic
for objIdx = 1:nReg
    used = false(size(verts,1), 1);
    firstFaces = faces(faceClusterIdx==objIdx,:);
    used(firstFaces(:)) = true;                 % mark vertices referenced by any face

    oldToNew = zeros(size(verts,1), 1);
    oldToNew(used) = 1:nnz(used);      % mapping: old index -> compact new index

    V2 = verts(used, :);                   % compacted vertices
    F2 = reshape(oldToNew(firstFaces(:)), size(firstFaces));   % remap faces (same shape as F)

    newMesh = surfaceMesh(V2, F2);
end
toc
% 1 s for mesh with 3 mil vertices

profile off
profile viewer