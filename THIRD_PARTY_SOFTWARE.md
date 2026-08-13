# Third-party software

This document lists third-party software that is incorporated into or distributed with **Irbis**, together with its purpose, integration method and licensing information.

## MATLAB source code included in the GitHub repository

The GitHub repository contains the Irbis MATLAB source code together with a number of third-party MATLAB components that are redistributed under their respective licenses.

| Software | Website | License | Integration | Purpose / notes |
|----------|---------|---------|-------------|-----------------|
| Toolbox Fast Marching | https://www.mathworks.com/matlabcentral/fileexchange/6110-toolbox-fast-marching | BSD-2-Clause | Individual MATLAB files | Fast-marching computations for centreline tracing |
| msdanalyzer | https://github.com/tinevez/msdanalyzer | BSD-2-Clause | Bundled `@msdanalyzer` class | Mean-square displacement analysis |
| TrackMate import script | https://github.com/trackmate-sc/TrackMate/blob/master/scripts/importTrackMateTracks.m | GPL-3.0 | Adapted source code | Import of TrackMate trajectories |
| Bio-Formats MATLAB toolbox | https://docs.openmicroscopy.org/bio-formats/stable/developers/matlab-dev.html | BSD-2-Clause helpers + GPL-covered Java components | Bundled MATLAB toolbox (minor modifications) | Microscopy file import and export |
| point2trimesh | https://www.mathworks.com/matlabcentral/fileexchange/52882-point2trimesh-distance-between-point-and-triangulated-surface | BSD-2-Clause | Individual MATLAB file | Distance computation (currently used in SpineSynapseMatcher) |
| tubeplot | https://www.aleph.se/Nada/Ray/Tubeplot/tubeplot.html | Informal permission | Individual MATLAB file | Tube generation |
| frenet | https://www.aleph.se/Nada/Ray/Tubeplot/tubeplot.html | Informal permission | Individual MATLAB file | Frenet frame computation for tube generation |
| intriangulation | https://www.mathworks.com/matlabcentral/fileexchange/43381-intriangulation-vertices-faces-testp-heavytest | BSD-2-Clause | Individual MATLAB file | Point-in-mesh testing |
| write3mf | https://github.com/cvergari/write3mf | MIT | Individual MATLAB file | Export of 3MF models |
| BM4D | https://webpages.tuni.fi/foi/GCF-BM3D/ | Non-commercial research license | Bundled MATLAB package | Volumetric image denoising |
| findPeaksSK | Adapted Matlab code | MathWorks copyright | Individual MATLAB file | Detecting peaks in a plot|

---

## Python packages distributed with the standalone application

The standalone Irbis application includes a packaged Python environment containing the following third-party packages. These packages are **not included in the GitHub repository**, but are distributed as part of the standalone installation.

| Package | Website | License | Purpose |
|---------|---------|---------|---------|
| NumPy | https://numpy.org | BSD-3-Clause | Numerical arrays and computations |
| SciPy | https://scipy.org | BSD-3-Clause | Scientific computing |
| trimesh | https://github.com/mikedh/trimesh | MIT | Mesh processing |
| manifold3d | https://github.com/elalish/manifold | Apache-2.0 | Mesh operations |
| NetworkX | https://networkx.org | BSD-3-Clause | Graph algorithms |
| Open3D | https://www.open3d.org | MIT | 3D geometry processing |

---

## Acknowledged previously used code

The following packages were used during the development of earlier versions of Irbis or inspired parts of its implementation. They are **not required by the current version** and are **not distributed as part of the current release**. They are acknowledged here to give appropriate credit.

| Software | Website | Former role |
|----------|---------|-------------|
| Mesh Processing Toolbox | https://github.com/NicolasDouillet/mesh_processing_toolbox | Mesh-processing utilities |
| dragzoom | https://www.mathworks.com/matlabcentral/fileexchange/29276-dragzoom-drag-and-zoom-tool | Basis for the original interactive figure navigation |

---
