% F: nF-by-3 faces (1-based vertex indices)
F = faces;
tic
% nF = size(F,1);

% % 1) Build all (undirected) edges of all faces: 3 edges per triangle
% E = [F(:,[1 2]);
%      F(:,[2 3]);
%      F(:,[3 1])];

% E = sort(E, 2);                 % undirected: (i,j) same as (j,i)

% % 2) For each edge, remember which face it came from
% faceOfEdge = repelem((1:nF)', 3);

% % 3) Group identical edges
% [~,~,edgeId] = unique(E, 'rows');

% % 4) Build face adjacency by connecting faces that share the same edge
% % Sort by edgeId so equal edges are consecutive
% [edgeIdSorted, order] = sort(edgeId);
% faceSorted = faceOfEdge(order);

% % Find consecutive pairs with same edgeId => those faces share an edge
% same = edgeIdSorted(1:end-1) == edgeIdSorted(2:end);
% i = faceSorted(same);
% j = faceSorted([false; same]);   % shifted by 1 to pair with next

% % (If non-manifold edges exist: >2 faces per edge, this only links neighbors
% % in the sorted list; add the "complete linking" section below if needed.)

% % 5) Make a sparse adjacency and compute connected components
% A = sparse([i; j], [j; i], true, nF, nF);
% G = graph(A);

% compId = conncomp(G);            % 1-by-nF component label per face
% % compId(k) tells you which connected part face k belongs to

% F: nF-by-3 faces (triangles), 1-based vertex indices
nF = size(F,1);

% All edges (undirected)
E = [F(:,[1 2]);
     F(:,[2 3]);
     F(:,[3 1])];
E = sort(E, 2);

% Which face each edge came from
faceOfEdge = repelem((1:nF)', 3);

% Identify identical edges
[~,~,edgeId] = unique(E, 'rows');

% Sort by edgeId so identical edges are consecutive
[edgeIdS, ord] = sort(edgeId);
faceS = faceOfEdge(ord);

% Consecutive entries with same edgeId => faces share that edge
same = edgeIdS(1:end-1) == edgeIdS(2:end);

i = faceS(find(same));          % face at position k
j = faceS(find(same) + 1);      % face at position k+1   <-- THIS is the key fix

% Build adjacency and components
A = sparse([i; j], [j; i], true, nF, nF);
compId = conncomp(graph(A));
toc