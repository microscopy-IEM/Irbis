function [n_objects,vertices,faces,vertex_normals,face_normals] = reconstruct_mesh_python(depth,input_name,path,varargin)

    % disp('in matlab function')
    if nargin == 3
        fractionToKeep = 0.8;
        minVertexNum = 20;
        output_name = 'temp_mesh.ply';
        % disp('3 args')
        separate = 1;
    elseif nargin == 5
        fractionToKeep = 0.8;
        minVertexNum = 20;
        separate = varargin{1};
        output_name = varargin{2};
        % disp('5 args')
    else
        separate = 1;
        fractionToKeep = varargin{1};
        minVertexNum = varargin{2};
        output_name = varargin{3};
        pt_vertices = varargin{4};
        pt_normals = varargin{5};
        % disp('else args')
    end

    pathAdapted = strrep(path,'\','/');
    disp(pt_vertices)
    disp(pt_normals)
    [n_objects,vertices,faces,vertex_normals,face_normals] = pyrunfile('reconstruct_mesh_py_script.py',["n_objects","vertices","faces","vertex_normals","face_normals"],d=depth,input_name=input_name,output_name=output_name,path=pathAdapted,f=fractionToKeep,nVer=minVertexNum,separate=separate,pt_vertices=pt_vertices,pt_normals=pt_normals);
    % n_objects = pyrunfile('reconstruct_mesh_py_script_vocal.py','n_objects',d=depth,input_name=input_name,output_name=output_name,path=pathAdapted,f=fractionToKeep,nVer=minVertexNum,separate=separate);

end

