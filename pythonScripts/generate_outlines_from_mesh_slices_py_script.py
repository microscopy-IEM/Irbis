"""
Mesh-Plane Intersection Processing Module

This module provides functions for:
- Extracting points and normals from a centerline
- Computing mesh-plane intersections
- Projecting 3D outlines to 2D
- Converting outlines to binary images
- Extracting and processing contours
- Reversing projections back to 3D

Author: Iva Svecova
Date: 2026-01-09
"""

import numpy as np
import scipy.io
import scipy.ndimage as ndi
import trimesh
import skimage.draw as draw
import skimage.morphology as morph
from skimage.measure import find_contours
from scipy.interpolate import interp1d
from typing import Tuple, List, Optional
from dataclasses import dataclass
import time
import cProfile
import pstats
from io import StringIO


# =============================================================================
# Data Classes
# =============================================================================

@dataclass
class ProcessingParams:
    """Parameters for the mesh-plane processing pipeline."""
    # Centerline sampling parameters
    buffer: int = 10
    spacing: int = 20
    ahead_index: int = 5
    
    # Grid parameters
    grid_size: int = 100
    min_val: float = -1.0
    max_val: float = 1.0
    
    # Outline consideration
    n_neighbors: int = 2  # Number of neighboring outlines to consider on each side
    
    # Morphological processing
    do_morphological_processing: bool = False
    disk_radius: int = 10
    
    # Contour resampling
    n_contour_points: int = 20


@dataclass
class PointData:
    """Data for a single point along the centerline."""
    index: int
    point: np.ndarray
    normal: np.ndarray
    outline_3d: np.ndarray
    projected_outline: np.ndarray
    rotation_matrix: np.ndarray


# =============================================================================
# Rotation Matrix Functions
# =============================================================================

def rotation_z(angle: float) -> np.ndarray:
    """
    Create a rotation matrix for rotation about the Z-axis.
    
    Parameters
    ----------
    angle : float
        Rotation angle in radians.
        
    Returns
    -------
    np.ndarray
        3x3 rotation matrix.
    """
    c, s = np.cos(angle), np.sin(angle)
    return np.array([
        [c, -s, 0],
        [s,  c, 0],
        [0,  0, 1]
    ], dtype=float)


def rotation_x(angle: float) -> np.ndarray:
    """
    Create a rotation matrix for rotation about the X-axis.
    
    Parameters
    ----------
    angle : float
        Rotation angle in radians.
        
    Returns
    -------
    np.ndarray
        3x3 rotation matrix.
    """
    c, s = np.cos(angle), np.sin(angle)
    return np.array([
        [1, 0,  0],
        [0, c, -s],
        [0, s,  c]
    ], dtype=float)


def compute_alignment_rotation(normal: np.ndarray) -> np.ndarray:
    """
    Compute the rotation matrix that aligns a normal vector to the Y-axis.
    
    The rotation is composed of:
    1. Yaw about Z to bring normal into the YZ-plane
    2. Pitch about X to align with +Y
    
    Parameters
    ----------
    normal : np.ndarray
        3D normal vector to align.
        
    Returns
    -------
    np.ndarray
        3x3 rotation matrix R such that R @ normal is aligned with Y-axis.
    """
    n = np.asarray(normal, dtype=float)
    n = n / np.linalg.norm(n)
    
    # Yaw about Z to make x' = 0 (bring n into YZ-plane)
    alpha = np.arctan2(n[0], n[1])
    Rz_alpha = rotation_z(alpha)
    
    n1 = Rz_alpha @ n
    
    # Pitch about X to make z'' = 0 (rotate onto +Y)
    beta = np.arctan2(-n1[2], n1[1])
    Rx_beta = rotation_x(beta)
    
    # Combined rotation (apply Z first, then X)
    R = Rx_beta @ Rz_alpha
    return R


# =============================================================================
# Data Loading Functions
# =============================================================================

def load_centerline(mat_path: str, variable_name: str = 'centreline') -> np.ndarray:
    """
    Load centerline data from a .mat file.
    
    Parameters
    ----------
    mat_path : str
        Path to the .mat file.
    variable_name : str, optional
        Name of the variable in the .mat file containing the centerline.
        
    Returns
    -------
    np.ndarray
        Centerline as an Nx3 array of 3D points.
    """
    data = scipy.io.loadmat(mat_path)
    return data[variable_name]


def load_mesh(mesh_path: str) -> trimesh.Trimesh:
    """
    Load a mesh from a file.
    
    Parameters
    ----------
    mesh_path : str
        Path to the mesh file (e.g., .stl, .obj).
        
    Returns
    -------
    trimesh.Trimesh
        Loaded mesh object.
    """
    return trimesh.load(mesh_path, force='mesh')

def create_mesh_from_vertices_and_faces(vertices: np.ndarray, faces: np.ndarray) -> trimesh.Trimesh:
    """
    Create a trimesh mesh from vertices and faces.
    
    Parameters
    ----------
    vertices : np.ndarray
        Nx3 array of vertex coordinates.
    faces : np.ndarray
        Mx3 array of face indices (triangular faces).
        
    Returns
    -------
    trimesh.Trimesh
        The created mesh object.
    """
    return trimesh.Trimesh(vertices=vertices, faces=faces)


# =============================================================================
# Point and Normal Extraction
# =============================================================================

def extract_points_and_normals(
    centerline: np.ndarray,
    buffer: int = 10,
    spacing: int = 10,
    ahead_index: int = 5
) -> Tuple[np.ndarray, np.ndarray, List[int]]:
    """
    Extract sample points and their normals from a centerline.
    
    The normal at each point is computed as the direction from the point
    to the average position of the next `ahead_index` points.
    
    Parameters
    ----------
    centerline : np.ndarray
        Nx3 array of centerline points.
    buffer : int, optional
        Number of points to skip at the start and end of the centerline.
    spacing : int, optional
        Spacing between sampled points.
    ahead_index : int, optional
        Number of points ahead to average for normal computation.
        
    Returns
    -------
    points : np.ndarray
        Mx3 array of sampled points.
    normals : np.ndarray
        Mx3 array of normal vectors at each point.
    selected_indices : List[int]
        Indices of selected points in the original centerline.
    """
    selected_indices = list(range(buffer, len(centerline) - buffer, spacing))
    normals = []
    
    for i in selected_indices:
        ahead_points = centerline[i + 1:i + 1 + ahead_index]
        average_pos = np.mean(ahead_points, axis=0)
        normal = average_pos - centerline[i]
        normals.append(normal)
    
    normals = np.array(normals)
    points = centerline[selected_indices]
    
    return points, normals, selected_indices


# =============================================================================
# Mesh Intersection
# =============================================================================

def compute_mesh_intersections(
    mesh: trimesh.Trimesh,
    points: np.ndarray,
    normals: np.ndarray
) -> List[np.ndarray]:
    """
    Compute mesh-plane intersections for each point and normal.
    
    Parameters
    ----------
    mesh : trimesh.Trimesh
        The mesh to intersect.
    points : np.ndarray
        Mx3 array of plane origin points.
    normals : np.ndarray
        Mx3 array of plane normal vectors.
        
    Returns
    -------
    List[np.ndarray]
        List of intersection line segments for each plane.
        Each element is an Nx2x3 array of line segment endpoints.
    """
    outlines = []
    for origin, normal in zip(points, normals):
        output = trimesh.intersections.mesh_plane(
            mesh, 
            plane_origin=origin, 
            plane_normal=normal
        )
        outlines.append(output)
    return outlines


# =============================================================================
# 2D Projection
# =============================================================================

def project_outlines_to_2d(
    outlines: List[np.ndarray],
    points: np.ndarray,
    normals: np.ndarray
) -> Tuple[List[np.ndarray], List[np.ndarray]]:
    """
    Project 3D outlines to 2D by rotating the plane to be axis-aligned.
    
    Parameters
    ----------
    outlines : List[np.ndarray]
        List of 3D outline segments (Nx2x3 arrays).
    points : np.ndarray
        Mx3 array of plane origin points.
    normals : np.ndarray
        Mx3 array of plane normal vectors.
        
    Returns
    -------
    projected_outlines : List[np.ndarray]
        List of 2D projected outlines (Nx2x2 arrays).
    rotation_matrices : List[np.ndarray]
        List of rotation matrices used for each projection.
    """
    projected_outlines = []
    rotation_matrices = []
    
    for i, output in enumerate(outlines):
        R = compute_alignment_rotation(normals[i])
        rotation_matrices.append(R)
        
        ends = output[:, 1, :]
        starts = output[:, 0, :]
        origin = points[i]
        
        centered_ends = ends - origin
        centered_starts = starts - origin
        
        # Apply rotation and keep only X and Z components
        projected_ends = centered_ends @ R.T
        projected_ends = projected_ends[:, [0, 2]]
        projected_starts = centered_starts @ R.T
        projected_starts = projected_starts[:, [0, 2]]
        
        projected_output = np.stack([projected_starts, projected_ends], axis=1)
        projected_outlines.append(projected_output)
    
    return projected_outlines, rotation_matrices


# =============================================================================
# Binary Image Generation
# =============================================================================

def get_neighboring_outlines(
    projected_outlines: List[np.ndarray],
    index: int,
    n_neighbors: int = 1
) -> List[np.ndarray]:
    """
    Get outlines neighboring a given index.
    
    Parameters
    ----------
    projected_outlines : List[np.ndarray]
        List of all projected outlines.
    index : int
        Center index.
    n_neighbors : int, optional
        Number of neighbors on each side to include.
        
    Returns
    -------
    List[np.ndarray]
        List of neighboring outlines.
    """
    min_idx = max(index - n_neighbors, 0)
    max_idx = min(index + n_neighbors + 1, len(projected_outlines))
    return projected_outlines[min_idx:max_idx]


def outlines_to_binary_image(
    outlines: List[np.ndarray],
    grid_size: int = 100,
    min_val: float = -1.0,
    max_val: float = 1.0
) -> np.ndarray:
    """
    Convert projected outlines to a binary image.
    
    Parameters
    ----------
    outlines : List[np.ndarray]
        List of 2D outline segments to draw.
    grid_size : int, optional
        Size of the output grid.
    min_val : float, optional
        Minimum coordinate value.
    max_val : float, optional
        Maximum coordinate value.
        
    Returns
    -------
    np.ndarray
        Binary image with outline segments drawn.
    """
    binary_grid = np.zeros((grid_size, grid_size), dtype=np.uint8)
    scale = (grid_size - 1) / (max_val - min_val)
    
    for outline in outlines:
        starts_u = outline[:, 0, 0]
        starts_v = outline[:, 0, 1]
        ends_u = outline[:, 1, 0]
        ends_v = outline[:, 1, 1]
        
        # Filter out segments completely outside bounds
        mask_starts = (np.abs(starts_u) > 1) | (np.abs(starts_v) > 1)
        mask_ends = (np.abs(ends_u) > 1) | (np.abs(ends_v) > 1)
        mask_out = mask_starts & mask_ends
        mask_in = ~mask_out
        
        starts_i = np.clip(np.round((starts_u[mask_in] - min_val) * scale), 0, grid_size - 1).astype(np.int32)
        starts_j = np.clip(np.round((starts_v[mask_in] - min_val) * scale), 0, grid_size - 1).astype(np.int32)
        ends_i = np.clip(np.round((ends_u[mask_in] - min_val) * scale), 0, grid_size - 1).astype(np.int32)
        ends_j = np.clip(np.round((ends_v[mask_in] - min_val) * scale), 0, grid_size - 1).astype(np.int32)
        
        # Draw lines - no bounds check needed since indices are already clipped
        for idx in range(len(starts_i)):
            rr, cc = draw.line(starts_j[idx], starts_i[idx], ends_j[idx], ends_i[idx])
            binary_grid[rr, cc] = 1
    
    return binary_grid


# =============================================================================
# Binary Image Processing
# =============================================================================

def extract_center_component(
    binary_grid: np.ndarray,
    do_morphological_processing: bool = False,
    disk_radius: int = 10
) -> np.ndarray:
    """
    Extract the connected component at the center of the image.
    
    This inverts the binary grid (treating background as foreground),
    finds the component at the center, and applies morphological
    opening and closing.
    
    Parameters
    ----------
    binary_grid : np.ndarray
        Input binary image.
    do_morphological_processing : bool, optional
        Whether to apply morphological opening and closing.
    disk_radius : int, optional
        Radius of the disk structuring element for morphological operations.
        
    Returns
    -------
    np.ndarray
        Processed binary image with only the center component.
    """
    struct_elem = morph.disk(disk_radius)
    grid_size = binary_grid.shape[0]
    
    # Find connected components in the background (inverted)
    mask = (binary_grid == 0)
    labeled, num = ndi.label(mask)
    
    if num == 0:
        return np.zeros_like(binary_grid)
    
    # Get the label at the center
    center_label = labeled[grid_size // 2, grid_size // 2]
    
    # If center is on a line (label 0), find closest component
    if center_label == 0:
        centers = ndi.center_of_mass(mask, labeled, range(1, num + 1))
        grid_center = np.array([grid_size / 2, grid_size / 2])
        distances = [np.linalg.norm(np.array(c) - grid_center) for c in centers]
        center_label = np.argmin(distances) + 1
    
    # Create binary mask for the chosen component
    result = np.zeros_like(binary_grid)
    result[labeled == center_label] = 1
    
    # Apply morphological operations
    if do_morphological_processing:
        result = ndi.binary_opening(result, structure=struct_elem)
        result = ndi.binary_closing(result, structure=struct_elem)
    
    return result.astype(np.uint8)


# =============================================================================
# Contour Extraction and Resampling
# =============================================================================

def extract_contour(
    binary_grid: np.ndarray,
    n_points: int = 20
) -> Optional[np.ndarray]:
    """
    Extract and resample a contour from a binary image.
    
    Parameters
    ----------
    binary_grid : np.ndarray
        Binary image to extract contour from.
    n_points : int, optional
        Number of points to resample the contour to.
        
    Returns
    -------
    np.ndarray or None
        Resampled contour as an (n_points, 2) array, or None if no contour found.
    """
    contours = find_contours(binary_grid, level=0.5)
    
    if len(contours) == 0:
        return None
    
    # Select the largest contour
    contour = max(contours, key=len)
    
    # Resample to n_points
    if len(contour) > n_points:
        indices = np.linspace(0, len(contour) - 1, n_points).astype(int)
        contour = contour[indices]
    elif len(contour) < n_points:
        t = np.linspace(0, 1, len(contour))
        t_new = np.linspace(0, 1, n_points)
        f = interp1d(t, contour, kind='linear', axis=0)
        contour = f(t_new)
    
    return contour


def transform_contour_to_coordinates(
    contour: np.ndarray,
    grid_size: int = 100,
    min_val: float = -1.0,
    max_val: float = 1.0
) -> np.ndarray:
    """
    Transform contour from grid indices to coordinate space.
    
    Parameters
    ----------
    contour : np.ndarray
        Contour in grid indices (row, col).
    grid_size : int, optional
        Size of the grid.
    min_val : float, optional
        Minimum coordinate value.
    max_val : float, optional
        Maximum coordinate value.
        
    Returns
    -------
    np.ndarray
        Contour in coordinate space (u, v).
    """
    step = (max_val - min_val) / (grid_size - 1)
    # contour is (row, col), we want (u, v) where col->u, row->v
    transformed = np.zeros_like(contour)
    transformed[:, 0] = contour[:, 1] * step + min_val  # u from col
    transformed[:, 1] = contour[:, 0] * step + min_val  # v from row
    return transformed


# =============================================================================
# 3D Reconstruction
# =============================================================================

def reverse_projection(
    contour_2d: np.ndarray,
    rotation_matrix: np.ndarray,
    origin: np.ndarray
) -> np.ndarray:
    """
    Reverse a 2D projection back to 3D coordinates.
    
    Parameters
    ----------
    contour_2d : np.ndarray
        2D contour in (u, v) coordinates.
    rotation_matrix : np.ndarray
        The rotation matrix used for the original projection.
    origin : np.ndarray
        The origin point of the plane.
        
    Returns
    -------
    np.ndarray
        3D coordinates of the contour.
    """
    # Create 3D points with y=0 (on the rotated plane)
    projected_full = np.zeros((len(contour_2d), 3))
    projected_full[:, 0] = contour_2d[:, 0]  # x' = u
    projected_full[:, 2] = contour_2d[:, 1]  # z' = v
    projected_full[:, 1] = 0  # y' = 0
    
    # Apply inverse rotation (R is orthonormal, so R.T = R^-1)
    centered_points = projected_full @ rotation_matrix
    
    # Add back the origin
    return centered_points + origin


# =============================================================================
# Main Processing Pipeline
# =============================================================================

def process_single_point(
    index: int,
    projected_outlines: List[np.ndarray],
    points: np.ndarray,
    rotation_matrices: List[np.ndarray],
    params: ProcessingParams
) -> Optional[np.ndarray]:
    """
    Process a single point to extract its 3D contour.
    
    Parameters
    ----------
    index : int
        Index of the point to process.
    projected_outlines : List[np.ndarray]
        List of all projected outlines.
    points : np.ndarray
        Array of all points.
    rotation_matrices : List[np.ndarray]
        List of all rotation matrices.
    params : ProcessingParams
        Processing parameters.
        
    Returns
    -------
    np.ndarray or None
        3D contour, or None if processing failed.
    """
    # Get neighboring outlines
    neighboring = get_neighboring_outlines(
        projected_outlines, index, params.n_neighbors
    )
    
    # Convert to binary image
    binary_grid = outlines_to_binary_image(
        neighboring,
        grid_size=params.grid_size,
        min_val=params.min_val,
        max_val=params.max_val
    )
    
    # Extract center component
    processed = extract_center_component(binary_grid, params.do_morphological_processing, params.disk_radius)
    
    # Extract contour
    contour = extract_contour(processed, params.n_contour_points)
    
    if contour is None:
        return None
    
    # Transform to coordinates
    contour_coords = transform_contour_to_coordinates(
        contour,
        grid_size=params.grid_size,
        min_val=params.min_val,
        max_val=params.max_val
    )
    
    # Reverse projection to 3D
    contour_3d = reverse_projection(
        contour_coords,
        rotation_matrices[index],
        points[index]
    )
    
    return contour_3d


def process_all_points(
    centerline: np.ndarray,
    mesh: trimesh.Trimesh,
    params: Optional[ProcessingParams] = None
) -> Tuple[List[Optional[np.ndarray]], np.ndarray, np.ndarray]:
    """
    Process all points along a centerline to extract 3D contours.
    
    Parameters
    ----------
    centerline : np.ndarray
        Nx3 array of centerline points.
    mesh : trimesh.Trimesh
        The mesh object.
    params : ProcessingParams, optional
        Processing parameters. Uses defaults if not provided.
        
    Returns
    -------
    contours_3d : List[Optional[np.ndarray]]
        List of 3D contours for each point (None for failed points).
    points : np.ndarray
        Array of sample points.
    normals : np.ndarray
        Array of normal vectors.
    """
    if params is None:
        params = ProcessingParams()
    
    # Extract points and normals
    points, normals, _ = extract_points_and_normals(
        centerline,
        buffer=params.buffer,
        spacing=params.spacing,
        ahead_index=params.ahead_index
    )
    
    # Compute mesh intersections
    outlines = compute_mesh_intersections(mesh, points, normals)
    
    # Project to 2D
    projected_outlines, rotation_matrices = project_outlines_to_2d(
        outlines, points, normals
    )
    
    # Process each point
    contours_3d = []
    for i in range(len(points)):
        contour = process_single_point(
            i, projected_outlines, points, rotation_matrices, params
        )
        contours_3d.append(contour)
    
    return contours_3d, points, normals

# =============================================================================


def process_example_point(
    position: np.ndarray,
    centerline: np.ndarray,
    mesh: trimesh.Trimesh,
    params: Optional[ProcessingParams] = None
) -> Tuple[List[Optional[np.ndarray]], np.ndarray, np.ndarray]:
    """
    Process a single point on the centerline closest to a given position.
    
    Parameters
    ----------
    position : np.ndarray
        3D position to find the closest centerline point to.
    centerline : np.ndarray
        Nx3 array of centerline points.
    mesh : trimesh.Trimesh
        The mesh object.
    params : ProcessingParams, optional
        Processing parameters. Uses defaults if not provided.
        
    Returns
    -------
    contours_3d : List[Optional[np.ndarray]]
        List containing a single 3D contour (or None if extraction failed).
    points : np.ndarray
        Array with the single closest point.
    normals : np.ndarray
        Array with the single normal vector.
    """
    if params is None:
        params = ProcessingParams()
    
    # Find closest point on centerline
    distances = np.linalg.norm(centerline - position, axis=1)
    closest_idx = np.argmin(distances)
    
    # Extract points and normals for all points (needed for context)
    points, normals, selected_indices = extract_points_and_normals(
        centerline,
        buffer=params.buffer,
        spacing=params.spacing,
        ahead_index=params.ahead_index
    )
    
    # Find which extracted point index corresponds to closest centerline point
    if closest_idx not in selected_indices:
        closest_idx = selected_indices[np.argmin(
            np.abs(np.array(selected_indices) - closest_idx)
        )]
    
    point_idx = selected_indices.index(closest_idx)
    
    # Compute mesh intersections for all points
    outlines = compute_mesh_intersections(mesh, points, normals)
    
    # Project to 2D
    projected_outlines, rotation_matrices = project_outlines_to_2d(
        outlines, points, normals
    )
    
    # Process only the closest point
    contour = process_single_point(
        point_idx, projected_outlines, points, rotation_matrices, params
    )
    
    return [contour], points[point_idx:point_idx+1], normals[point_idx:point_idx+1]


def visualize_contours_with_mesh(
    mesh: trimesh.Trimesh,
    contours_3d: List[Optional[np.ndarray]],
    points: Optional[np.ndarray] = None,
    contour_color: tuple = (255, 0, 0, 255),
    point_color: tuple = (0, 255, 0, 255),
    point_size: float = 5.0
) -> trimesh.Scene:
    """
    Visualize 3D contours as a point cloud together with the original mesh.
    
    Parameters
    ----------
    mesh : trimesh.Trimesh
        The original mesh.
    contours_3d : List[Optional[np.ndarray]]
        List of 3D contours (some may be None).
    points : np.ndarray, optional
        Origin points to display.
    contour_color : tuple, optional
        RGBA color for contour points.
    point_color : tuple, optional
        RGBA color for origin points.
    point_size : float, optional
        Size of the points.
        
    Returns
    -------
    trimesh.Scene
        Scene containing mesh and point clouds.
    """
    # Create scene with mesh
    scene = trimesh.Scene([mesh])
    
    # Collect all contour points
    all_contour_points = []
    for contour in contours_3d:
        if contour is not None:
            all_contour_points.append(contour)
    
    if all_contour_points:
        # Stack all contour points into one array
        contour_points = np.vstack(all_contour_points)
        
        # Create point cloud for contours
        contour_cloud = trimesh.PointCloud(
            vertices=contour_points,
            colors=np.tile(contour_color, (len(contour_points), 1))
        )
        scene.add_geometry(contour_cloud, geom_name='contours')
    
    # Add origin points if provided
    if points is not None:
        origin_cloud = trimesh.PointCloud(
            vertices=points,
            colors=np.tile(point_color, (len(points), 1))
        )
        scene.add_geometry(origin_cloud, geom_name='origins')
    
    return scene


    # =============================================================================
    # MATLAB Struct Parsing
    # =============================================================================

def parse_matlab_parameters(matlab_struct: dict) -> ProcessingParams:
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
    expected_types = parameters_object.__annotations__

    for matlab_key, matlab_value in matlab_struct.items():
        if hasattr(parameters_object, matlab_key):
            # Make sure that the correct type is preserved when setting the attribute
            expected_type = expected_types.get(matlab_key, None)
            if expected_type is int: 
                value = int(matlab_value)
            elif expected_type is float:
                value = float(matlab_value)
            elif expected_type is bool:
                value = bool(matlab_value)
            else:
                continue  # Skip if type is not recognized
            # print('Setting attribute:', matlab_key, 'to value:', value, ', type:', type(value))
            setattr(parameters_object, matlab_key, value)

    return parameters_object


# =============================================================================
# Example Usage
# =============================================================================

if __name__ == "__main__":

    # Set paths
    # centerline_path = "centreline.mat"
    # mesh_path = "D:/OneDrive - IEM/Microscopy Team/Irbis project/Models_stl/planes2_new_unfinished.stl"

    centerline_path = "D:\\OneDrive - IEM\\Microscopy Team\\Irbis project\\Custom tools\\Mesh-plane intersection\\newCentreline.mat"
    mesh_path = "D:/OneDrive - IEM/Microscopy Team/Irbis project/Models_stl/newMesh.stl"
    
    # Create parameters
    params = parse_matlab_parameters(matlab_params)

    # Process all points
    
    # pr = cProfile.Profile()
    # pr.enable()
    # start_time = time.perf_counter()
    # Load data
    mesh = create_mesh_from_vertices_and_faces(vertices, faces)
    

    if 'test_point' in locals(): 
        print("Processing example point...")
        contours_3d, points, normals = process_example_point(
            test_point, centerline, mesh, params
        )
        # visualize_contours_with_mesh(mesh, contours_3d, points)

    else:
        # Process all points
        contours_3d, points, normals = process_all_points(
            centerline, mesh, params
        )
    # end_time = time.perf_counter()
    # pr.disable()
    # print(f"Processing time: {end_time - start_time:.2f} seconds")
    
    # # Profile output
    # s = StringIO()
    # ps = pstats.Stats(pr, stream=s).sort_stats('tottime')
    # ps.print_stats()
    # print(s.getvalue())
    
    # Count successful extractions
    # successful = sum(1 for c in contours_3d if c is not None)
    # print(f"Successfully extracted {successful}/{len(contours_3d)} contours")

