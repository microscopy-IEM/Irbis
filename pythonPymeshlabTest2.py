import scipy.io
import numpy as np
import os

# Change the working directory to the specified path
os.chdir(r'C:\Users\stepan.kortus\Documents\Irbis')

# Load the .mat file (make sure the .mat file is in this directory)
mat_file = scipy.io.loadmat('mesh_data.mat')

# Access the MATLAB variables and convert them to NumPy arrays
vertices_big = np.array(mat_file['verticesBigMat'])
faces_big = np.array(mat_file['facesBigMat'])
vertex_normals_big = np.array(mat_file['vertexNormalsBigMat'])
face_normals_big = np.array(mat_file['faceNormalsBigMat'])
vertices_small = np.array(mat_file['verticesSmallMat'])
faces_small = np.array(mat_file['facesSmallMat'])
vertex_normals_small = np.array(mat_file['vertexNormalsSmallMat'])
face_normals_small = np.array(mat_file['faceNormalsSmallMat'])

# Execute the external script
with open('mesh_subtract_and_separate_and_save_plane_py_script.py') as script_file:
    exec(script_file.read())
