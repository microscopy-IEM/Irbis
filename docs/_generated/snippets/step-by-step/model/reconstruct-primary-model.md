!!! info "Before you start"
    **Prerequisites:**

    - Planes data loaded in Irbis.
    - Model structure initialized.

    **UI location:**

    - Main app: **Model** tab, **Full** subtab, **3D reconstruction** section.

**Steps**

1. Select the channel of interest from the channel drop-down menu.
2. Set the threshold that separates background from signal.
3. Press **Show** to preview the selected area highlighted in gray.
4. To reconstruct multiple time points, choose **More time points** and set **First** and **Last**.
5. Select a reconstruction detail level from `1` to `5`. Level `1` is fastest and least detailed. Level `5` preserves the most detail, but requires more memory and processing time. This parameter controls plane downscaling before surface reconstruction.
6. Press **Preview** to generate a temporary mesh before committing the reconstruction. Preview mode skips simplification, smoothing, object processing and table storage. Remove the preview object with the **X** button next to it.
7. If needed, adjust **Advanced reconstruction settings**.
8. Confirm that pixel size and z-spacing are correct in the **Planes** tab.
9. Press **Generate 3D** and wait for reconstruction to finish.

**Setting threshold for constant signal**

1. Press **Auto** for automatic threshold estimation.
2. Alternatively, set the threshold manually in the spinner.
3. Press **Show** to check the selected foreground area.

If signal strength is stable, define the threshold for one time point. Irbis uses the same value for the rest.

**Setting threshold for bleaching signal**

1. Open **Advanced reconstruction settings**.
2. Check **Bleaching compensation**.
3. Set the threshold for the first and last time point.
4. If the switch is set to **Selected range**, compensation applies only to the range from **First** to **Last**. Only those time points have editable thresholds.
5. Review the bleaching compensation value shown next to the checkbox.

**Advanced reconstruction settings options**

Use advanced settings when the default reconstruction is too coarse, too large, too noisy, or changes over time because of bleaching.

- **Scale factor** controls image resampling in x-y before surface extraction. A value of `1` keeps the original x-y sampling; `0.5` downsamples x-y by a factor of two.
- **Z scale factor** adjusts z-axis resampling relative to x-y before mesh generation. A value of `1` makes z sampling isotropic relative to the resampled x-y grid, based on the planes metadata.
- **Mesh simplification** reduces mesh size after the surface is generated. Use it for large reconstructions to improve performance while preserving the overall shape.
    - **Simplify** turns mesh simplification on or off.
    - **Target fraction** sets the fraction of mesh vertices preserved after simplification. For example, `0.2` keeps about 20% of the original vertices.
- **Mesh smoothing** can reduce jagged surfaces, but it may also soften small structures. Use it only when the raw surface is visibly noisy.
    - **Smooth** checkbox turns mesh smoothing on or off.
- **Auto drift correction** automatically runs [drift correction](../step-by-step/model/drift-correction.md) after generating meshes for all selected time points. This is a convenience option; it performs the same drift-correction step available separately.

For parameter names and default values, see [Surface generation parameters](../reference/spine-generation-parameters/surface-generation-parameters.md).

**Next steps**

- Continue to [Detect drift and correct it](../step-by-step/model/drift-correction.md).
- Then [Connect objects in time](../step-by-step/model/connect-objects-in-time.md).
