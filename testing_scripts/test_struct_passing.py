from dataclasses import dataclass
import numpy as np
import time

@dataclass

class ProcessingParams:
    """Parameters for the mesh-plane processing pipeline."""
    # Centerline sampling parameters
    buffer: int = 10
    spacing: int = 10
    ahead_index: int = 5
    
    # Grid parameters
    grid_size: int = 100
    min_val: float = -1.0
    max_val: float = 1.0
    
    # Outline consideration
    n_neighbors: int = 1  # Number of neighboring outlines to consider on each side
    
    # Morphological processing
    disk_radius: int = 10
    
    # Contour resampling
    n_contour_points: int = 20


def parse_matlab_struct(matlab_struct: dict) -> ProcessingParams:
    """
    Parse a MATLAB struct (accepted as dictionary) and update ProcessingParams.
    
    Parameters
    ----------
    matlab_struct : dict
        Dictionary containing struct fields and values from MATLAB.
        
    Returns
    -------
    ProcessingParams
        Updated ProcessingParams instance with values from the struct.
    """
    # Extract relevant fields from the struct dictionary
    parameters_object = ProcessingParams()  # Create an instance with default values

    for matlab_key, matlab_value in matlab_struct.items():
        print(matlab_value)
        print(type(matlab_value))

        if hasattr(parameters_object, matlab_key):
            print('Setting attribute:', matlab_key, 'to value:', matlab_value)
            setattr(parameters_object, matlab_key, matlab_value)

    return parameters_object

start = time.time()
boolTest = 'test' in locals()
end = time.time()
print(f"Execution time: {end - start:.4f} seconds")

if 'test' in locals():
    print(test)
else:
    print('No test variable found.')



result = parse_matlab_struct(struct)
print(result)



