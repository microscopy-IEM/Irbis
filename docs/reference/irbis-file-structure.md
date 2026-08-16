# Irbis file structure

This page describes the main structure of an Irbis output file.

Detailed table column definitions are described on separate reference pages.

## Structure overview

- `Irbis file`
  - `info`
  - `timeline`
  - `tools`
  - `views`
  - `results`
  - `planes`
  - `tracks`
  - `points`
  - `model`

## Info

General metadata describing the Irbis file, version, dataset identity, units and save history.

- `info.irbisVersion` *(double)* - Irbis version used to create the file.
- `info.matlabVersion` *(char)* - MATLAB version used to create the file.
- `info.groupName` *(char)*
- `info.round` *(double)*
- `info.cell` *(double)*
- `info.dish` *(double)*
- `info.description` *(char)*
- `info.experimentDate` *(datetime)*
- `info.notes` *(char)*
- `info.spaceUnits` *(char)* - Units used for spatial measurements in the dataset.
- `info.timeUnits` *(char)* - Units used for temporal measurements in the dataset.
- `info.path` *(char)* - Path to the working directory where file was saved (rewritten during saving).
- `info.filename` *(char)* - Filename of the saved Irbis file (rewritten during saving).
- `info.createTimestamp` *(datetime)* - Timestamp when the structure was initially created.
- `info.saveTimestamp` *(datetime)* - Timestamp when the structure was last saved (rewritten during saving).

## Timeline

Structure for managing time points, current selections, and time-dependent indices.

- `timeline.nTimePoints` *(double)* - Number of time points present in the dataset.
- `timeline.currentTimePoint` *(double)* - Currently selected time point index.
- `timeline.currentIndex.planes` *(double / array)* - Index of the currently selected plane for each time point.
- `timeline.currentIndex.tracks` *(double / array)* - Index of the currently selected track for each time point.
- `timeline.currentIndex.points` *(double / array)* - Index of the currently selected point for each time point.
- `timeline.currentIndex.model` *(struct)* - Per-branch indices of currently selected model objects for each time point.
- `timeline.currentIndex.tools.areas` *(double / array)* - Index(es) of the currently selected area tool entries.

## Tools

Storage for user-defined tools and annotations, such as area selections.

- `tools.areas` *(struct)* - Storage for area-selection tool entries.
- `tools.areas.List` *(cell / table)* - List/table of area tool entries.
    - See: [areas table](parameters/areas-table.md)

## Views

Storage for viewer configurations, camera positions, and related settings.

- `views.storedViewsList` *(table)* - Stored viewer configurations and camera positions.
    - See: [views table](parameters/views-table.md)

## Results

Not used atm.

- `results` *(struct)* - Placeholder for results and computed outputs.

## Planes

Storage for structural image data, image stack parameters and spatial reference settings.

- `planes.refOrigFileName` *(char)* - Original filename of the reference image.
- `planes.zstack` *(array / numeric)* - Raw image data (z-stack), shape x*y*z*t*ch.
- `planes.pixel_size` *(double)* - Pixel size in spatial units.
- `planes.z_spacing` *(double)* - Z-step spacing for z-stack images.
- `planes.channelNames` *(cell)* - Channel names list (e.g., {'GFP','Homer','DIC'}).
- `planes.channelColors` *(cell)* - Per-channel color specifications.
- `planes.channelColormaps` *(cell)* - Per-channel colormap settings.
- `planes.channel_ranges` *(cell)* - Per-channel histogram ranges for plotting.
- `planes.imSize` *(double)* - Single-plane XY size in pixels.
- `planes.nPlanes` *(double)* - Number of Z planes in a stack.
- `planes.nChannels` *(double)* - Number of channels in the dataset.
- `planes.nTimePoints` *(double)* - Number of time points in the image data.
- `planes.bitDepth` *(double)* - Bit depth of the image data (e.g., 8,16,32).
- `planes.spacialRef` *(imref2d)* - Spatial referencing object for 2D images.
- `planes.refImParam.depth` *(double)* - Default reference image depth (z plane) used for registration.
- `planes.refImParam.channel` *(double)* - Channel index used as reference image.
- `planes.timeDrift` *(numeric)* - Measured time drift applied to plane images (per time point).

## Tracks

Storage for trajectories (loaded from the TrackMate files) and their parameters.

- `tracks.tracksOrigFileName` *(cell)* - Original filenames for track input per time point.
- `tracks.nTracks` *(cell)* - Number of tracks found per time point.
- `tracks.nFrames` *(cell)* - Number of frames per time point.
- `tracks.frameInterval` *(cell)* - Frame interval in temporal units (per time point).
- `tracks.group` *(cell)* - Group identifier for tracks per time point.
- `tracks.description` *(cell)* - Descriptive text for track sets per time point.
- `tracks.driftCorrection` *(cell)* - Drift correction parameters applied to tracks per time point.
- `tracks.timeRange` *(cell)* - Time range information for tracks per time point.
- `tracks.tracksList` *(cell)* - Cell array of track tables, one per time point.
    - See: [tracks table](parameters/tracks-table.md)
- `tracks.filterTable` *(cell)* - (Deprecated) Filter tables per time point.
- `tracks.storedFilters` *(FilteringStorage)* - Storage object for filters applied to tracks.
- `tracks.storedCategorizations` *(CategorizationStorage)* - Storage object for categorizations related to tracks.
- `tracks.storedSummarizedTables` *(SummarizedTableStorageClass)* - Storage for precomputed summarized tables for tracks.
- `tracks.timePointPresent` *(logical)* - Flag indicating whether tracks include explicit time-point information.

## Points

Storage for detected points and corresponding metadata.

- `points.pointsList` *(table)* - Table/list of detected or stored points.
    - See: [points table](parameters/points-table.md)
- `points.fileName` *(char)* - Source filename for points data.
- `points.registration` *(struct)* - Registration parameters for points relative to images.
- `points.manualAlignment` *(struct)* - Manual alignment adjustments applied to points.
- `points.storedSummarizedTables` *(SummarizedTableStorageClass)* - Storage for summarized tables derived from points.

## Model

Storage for branch-based model objects, object parameters, reconstruction settings and drift correction data.

- `model.branches` *(cell)* - Names of model branches available in this dataset.
- `model.selectableBranches` *(cell)* - Subset of branches that are selectable in the UI.
- `model.(branch).Color` *(double (1x3))* - RGB color for objects in this branch.
- `model.(branch).Transparency` *(double)* - Transparency (alpha) for objects in this branch.
- `model.(branch).Show` *(logical / numeric)* - Visibility flag for this branch in the viewer.
- `model.(branch).List` *(cell array of tables)* - Cell array where each cell contains a table of objects for the time point defined by currentIndex in this branch. The table structure depends on the reconstruction method and branch type.
    - See: [model table](parameters/model-table.md)
- `model.(branch).methodApplied` *(char)* - Reconstruction method applied to derived objects in this branch.
- `model.(branch).storedFilters` *(FilteringStorage)* - Stored filters for objects in this branch.
- `model.(branch).storedCategorizations` *(CategorizationStorage)* - Stored categorizations for objects in this branch.
- `model.(branch).storedSummarizedTables` *(SummarizedTableStorageClass)* - Summarized tables storage for objects in this branch.
- `model.timeDrift` *(double)* - Time-dependent drift vectors for the model (nTimePoints x 3).
- `model.timeDriftCorrected` *(logical / numeric)* - Flag indicating if time drift correction has been applied.
- `model.driftCorrectedColumns` *(cell)* - List of model property names that are corrected by drift compensation.

---

*This page was generated automatically from: `getBaseStruct.m`.*

***Generated:** 2026-08-16 18:50:32*

*Do not edit this file manually. Edit the documentation comments in the source file and regenerate the documentation.*