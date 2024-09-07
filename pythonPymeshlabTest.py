import scipy.io
import numpy as np
import os

# Change the working directory to the specified path
os.chdir(r'C:\Users\stepan.kortus\Documents\Irbis')

# Load the .mat file (make sure the .mat file is in this directory)
mat_file = scipy.io.loadmat('mesh_data.mat')

# Check the variable names in the .mat file to confirm the data is there
print(mat_file.keys())

# Access the MATLAB variables and add the _mat suffix to differentiate them
verticesBig_mat = mat_file['verticesBigMat']
facesBig_mat = mat_file['facesBigMat']
vertexNormalsBig_mat = mat_file['vertexNormalsBigMat']
faceNormalsBig_mat = mat_file['faceNormalsBigMat']
verticesSmall_mat = mat_file['verticesSmallMat']
facesSmall_mat = mat_file['facesSmallMat']
vertexNormalsSmall_mat = mat_file['vertexNormalsSmallMat']
faceNormalsSmall_mat = mat_file['faceNormalsSmallMat']

# Convert them to NumPy arrays (removing the _mat suffix)
verticesBig = np.array(verticesBig_mat)
facesBig = np.array(facesBig_mat)
vertexNormalsBig = np.array(vertexNormalsBig_mat)
faceNormalsBig = np.array(faceNormalsBig_mat)
verticesSmall = np.array(verticesSmall_mat)
facesSmall = np.array(facesSmall_mat)
vertexNormalsSmall = np.array(vertexNormalsSmall_mat)
faceNormalsSmall = np.array(faceNormalsSmall_mat)

# # Optionally, print the data to verify
# print('verticesBig:', verticesBig)
# print('facesBig:', facesBig)
# print('vertexNormalsBig:', vertexNormalsBig)
# print('faceNormalsBig:', faceNormalsBig)
# print('verticesSmall:', verticesSmall)
# print('facesSmall:', facesSmall)
# print('vertexNormalsSmall:', vertexNormalsSmall)
# print('faceNormalsSmall:', faceNormalsSmall)
