function n_objects = reconstruct_mesh_python(depth,input_name,path,varargin)

    if nargin == 3
        fractionToKeep = 0.8;
        minVertexNum = 20;
        output_name = 'temp_mesh.ply';
        separate = 1;
    elseif nargin == 5
        fractionToKeep = 0.8;
        minVertexNum = 20;
        separate = varargin{1};
        output_name = varargin{2};
    else
        separate = 0;
        fractionToKeep = varargin{1};
        minVertexNum = varargin{2};
        output_name = varargin{3};
    end

    pathAdapted = strrep(path,'\','/');
    % n_objects = pyrunfile('reconstruct_mesh_py_script.py','n_objects',d=depth,input_name=input_name,output_name=output_name,path=pathAdapted,f=fractionToKeep,nVer=minVertexNum,separate=separate);
    n_objects = pyrunfile('reconstruct_mesh_py_script_vocal.py','n_objects',d=depth,input_name=input_name,output_name=output_name,path=pathAdapted,f=fractionToKeep,nVer=minVertexNum,separate=separate);

end

