# utils_py_script.py

import numpy as np

def to_numpy_array(data, dtype):
    """Ensure data is a NumPy array, converting memoryview if needed."""
    if isinstance(data, memoryview):
        return np.array(data, dtype=dtype)
    return np.asarray(data, dtype=dtype)