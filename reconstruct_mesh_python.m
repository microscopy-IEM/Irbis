function [n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(depth,pt_vertices,pt_normals,varargin)

    % disp('in matlab function')
    if nargin == 3
        fractionToKeep = 0.8;
        minVertexNum = 20;
        % disp('3 args')
        separate = 1;
    elseif nargin == 4
        fractionToKeep = 0.8;
        minVertexNum = 20;
        separate = varargin{1};
        % disp('5 args')
    else
        separate = 1;
        fractionToKeep = varargin{1};
        minVertexNum = varargin{2};
        % disp('else args')
    end

    [n_objects,vertices,faces,vertex_normals,face_normals] = pyrunfile('reconstruct_mesh_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals"],d=depth,f=fractionToKeep,nVer=minVertexNum,separate=separate,pt_vertices=pt_vertices,pt_normals=pt_normals);

end

