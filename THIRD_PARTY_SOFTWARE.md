# Third-party software

This document lists third-party software that is incorporated into or distributed with **Irbis**, together with its purpose, integration method and licensing information.

## MATLAB source code included in the GitHub repository

The GitHub repository contains the Irbis MATLAB source code together with a number of third-party MATLAB components that are redistributed under their respective licenses.

| Software | Website | License | Integration | Purpose / notes | Reference |
|----------|---------|---------|-------------|-----------------|-------------|
| Toolbox Fast Marching | https://www.mathworks.com/matlabcentral/fileexchange/6110-toolbox-fast-marching | BSD-2-Clause | Individual MATLAB files | Fast-marching computations for centreline tracing | [Sethian, 1996](#ref-sethian1996) |
| msdanalyzer | https://github.com/tinevez/msdanalyzer | BSD-2-Clause | Bundled `@msdanalyzer` class | Mean-square displacement analysis | [Tarantino et al., 2014](#ref-tarantino2014) |
| TrackMate import script | https://github.com/trackmate-sc/TrackMate/blob/master/scripts/importTrackMateTracks.m | GPL-3.0 | Adapted source code | Import of TrackMate trajectories | [Tinevez et al., 2017](#ref-tinevez2017) |
| Bio-Formats MATLAB toolbox | https://github.com/Biofrontiers-ALMC/bioformats-matlab/wiki | BSD-2-Clause helpers + GPL-covered Java components | Bundled MATLAB toolbox (minor modifications) | Microscopy file import and export | [Linkert et al., 2010](#ref-linkert2010) |
| point2trimesh | https://www.mathworks.com/matlabcentral/fileexchange/52882-point2trimesh-distance-between-point-and-triangulated-surface | BSD-2-Clause | Individual MATLAB file | Distance computation (currently used in SpineSynapseMatcher) ||
| tubeplot | https://www.aleph.se/Nada/Ray/Tubeplot/tubeplot.html | Informal permission | Individual MATLAB file | Tube generation ||
| frenet | https://www.aleph.se/Nada/Ray/Tubeplot/tubeplot.html | Informal permission | Individual MATLAB file | Frenet frame computation for tube generation ||
| intriangulation | https://www.mathworks.com/matlabcentral/fileexchange/43381-intriangulation-vertices-faces-testp-heavytest | BSD-2-Clause | Individual MATLAB file | Point-in-mesh testing ||
| write3mf | https://github.com/cvergari/write3mf | MIT | Individual MATLAB file | Export of 3MF models ||

---

 


## Python packages distributed with the standalone application

The standalone Irbis application includes a packaged Python environment containing the following third-party packages. These packages are **not included in the GitHub repository**, but are distributed as part of the standalone installation.

| Package | Website | License | Purpose | Reference |
|---------|---------|---------|---------|-----------|
| NumPy | https://numpy.org | BSD-3-Clause | Numerical arrays and computations | [Harris et al., 2020](#ref-harris2020) |
| SciPy | https://scipy.org | BSD-3-Clause | Scientific computing | [Virtanen et al., 2020](#ref-virtanen2020) |
| scikit-image | https://scikit-image.org/ | BSD-3-Clause | Adaptive shaft generation | [Van Der Walt et al., 2014](#ref-vandervalt2014) |
| trimesh | https://github.com/mikedh/trimesh | MIT | Mesh processing | |
| manifold3d | https://github.com/elalish/manifold | Apache-2.0 | Mesh operations | |
| NetworkX | https://networkx.org | BSD-3-Clause | Graph algorithms | [Hagberg et al., 2008](#ref-hagberg2008) |
| Open3D | https://www.open3d.org | MIT | 3D geometry processing | [Zhou et al., 2018](#ref-zhou2018) |

---

## Acknowledged previously used code

The following packages were used during the development of earlier versions of Irbis or inspired parts of its implementation. They are **not required by the current version** and are **not distributed as part of the current release**. They are acknowledged here to give appropriate credit.

| Software | Website | Former role |
|----------|---------|-------------|
| Mesh Processing Toolbox | https://github.com/NicolasDouillet/mesh_processing_toolbox | Mesh-processing utilities |
| dragzoom | https://www.mathworks.com/matlabcentral/fileexchange/29276-dragzoom-drag-and-zoom-tool | Basis for the original interactive figure navigation |

---

## References

<a id="ref-sethian1996"></a>
**Sethian, J. A. (1996).** Level Set Methods and Fast Marching Methods. Cambridge University Press.

<a id="ref-tarantino2014"></a>
**Tarantino, N., Tinevez, J.-Y., Crowell, E. F., Boisson, B., Henriques, R., Mhlanga, M., Agou, F., Israël, A., & Laplantine, E. (2014).** TNF and IL-1 exhibit distinct ubiquitin requirements for inducing NEMO–IKK supramolecular structures. Journal of Cell Biology, 204(2), 231–245. https://doi.org/10.1083/jcb.201307172

<a id="ref-tinevez2017"></a>
**Tinevez, J.-Y., Perry, N., Schindelin, J., Hoopes, G. M., Reynolds, G. D., Laplantine, E., Bednarek, S. Y., Shorte, S. L., & Eliceiri, K. W. (2017).** TrackMate: An open and extensible platform for single-particle tracking. Methods, 115, 80–90. https://doi.org/10.1016/j.ymeth.2016.09.016

<a id="ref-linkert2010"></a>
**Linkert, M., Rueden, C. T., Allan, C., Burel, J.-M., Moore, W., Patterson, A., Loranger, B., Moore, J., Neves, C., MacDonald, D., Tarkowska, A., Sticco, C., Hill, E., Rossner, M., Eliceiri, K. W., & Swedlow, J. R. (2010).** Metadata matters: access to image data in the real world. Journal of Cell Biology, 189(5), 777–782. https://doi.org/10.1083/jcb.201004104

<a id="ref-harris2020"></a>
**Harris, C. R., Millman, K. J., Van Der Walt, S. J., Gommers, R., Virtanen, P., Cournapeau, D., Wieser, E., Taylor, J., Berg, S., Smith, N. J., Kern, R., Picus, M., Hoyer, S., Van Kerkwijk, M. H., Brett, M., Haldane, A., Del Río, J. F., Wiebe, M., Peterson, P., Gérard-Marchant, P., Sheppard, K., Reddy, T., Weckesser, W., Abbasi, H., Gohlke, C., & Oliphant, T. E. (2020).** Array programming with NumPy. Nature, 585, 357–362. https://doi.org/10.1038/s41586-020-2649-2

<a id="ref-virtanen2020"></a>
**Virtanen, P., Gommers, R., Oliphant, T. E., Haberland, M., Reddy, T., Cournapeau, D., Burovski, E., Peterson, P., Weckesser, W., Bright, J., Van Der Walt, S. J., Brett, M., Wilson, J., Millman, K. J., Mayorov, N., Nelson, A. R. J., Jones, E., Kern, R., Larson, E., et al. (2020).** SciPy 1.0: fundamental algorithms for scientific computing in Python. Nature Methods, 17(3), 261–272. https://doi.org/10.1038/s41592-019-0686-2

<a id="ref-vandervalt2014"></a>
**Van Der Walt, S., et al. (2014).** scikit-image: image processing in Python. PeerJ, 2, e453. https://doi.org/10.7717/peerj.453

<a id="ref-hagberg2008"></a>
**Hagberg, A. A., Schult, D. A., & Swart, P. J. (2008).** Exploring Network Structure, Dynamics, and Function using NetworkX. Proceedings of the 7th Python in Science Conference, 11–15. Pasadena, CA, USA.

<a id="ref-zhou2018"></a>
**Zhou, Q.-Y., Park, J., & Koltun, V. (2018).** Open3D: A Modern Library for 3D Data Processing. arXiv:1801.09847. https://arxiv.org/abs/1801.09847

