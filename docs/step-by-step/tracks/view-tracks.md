# View tracks

!!! info "Before you start"
    **Prerequisites:**

    - TrackMate `.xml` data loaded in Irbis.

    **UI location:**

    - Main app: **Tracks** tab.

## Change tracks visualization

1. Adjust **Line thickness** to change trajectory thickness in pixels.
2. Adjust **Tail** to change how many past frames are displayed in the trajectory.
3. Check **Limit to plane** to collapse trajectories to the z-position of the current plane.
4. Check **Limit to area** to show only trajectories within existing areas. This applies only if areas exist.

## Change color-coding

1. In the first **Colorcode** drop-down menu, select the parameter used for color-coding.
2. In the second **Colorcode** drop-down menu, select the colormap.
3. Select **random** to color trajectories randomly, independent of parameter values.
4. Check or uncheck **colorbar** to show or hide the colorbar in the bottom-right corner of the plotting area.

## Filter visible tracks

1. Press **Filter** to show filtering options.
2. Select the filtering parameter from the drop-down menu.
3. For numerical parameters, use the histogram to set the visible range.
4. For categorical parameters, select visible categories from the checkbox list.

## Next steps

- Continue to [Calculate track parameters](calculate-parameters.md).
- Then [Define and edit track categorizations](categorize-tracks.md).

!!! example "Screenshot placeholder"
    Add a screenshot of Tracks visualization controls, Colorcode controls, Filter, histogram, and category checkboxes.


