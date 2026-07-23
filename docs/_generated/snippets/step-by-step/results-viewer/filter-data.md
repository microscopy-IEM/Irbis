Use filters to restrict the rows and objects shown in ResultsViewer tables and plots. The same filtering panel is used for ordinary table filters and, when a summarized table is shown, filters based on temporal development.

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.
    - Desired modality selected at the top of ResultsViewer.
    - For model data, desired branch selected at the top of ResultsViewer.

    **UI location:**

    - ResultsViewer: **Filtering** panel at the bottom right.

**Filter rows by column values**

1. Select the table to filter from **Table to filter** dropdown if it is shown.
2. Select the parameter to filter by from the filter parameter drop-down menu.
3. For categorical parameters, select included categories in the checkbox list.
4. For numerical parameters, set the lower and upper filter range (the edges are included in the interval).
5. Press **Filter**.
6. Existing filters appear as state buttons in the **Filtering** panel.
7. Toggle a filter button off to disable the filter (it will turn grey). Toggle it on to enable it again (it will turn blue).
8. To delete a filter, select the parameter name from the drop-down menu and press **Delete**.

The regular filtering component can filter numeric scalar columns and categorical columns. Right-click the categorical checkbox tree to use **Check all** or **Uncheck all**.

If you are viewing a single dataset loaded from the main Irbis app, filters should sync with the main app. Changing a filter in Irbis updates ResultsViewer, and changing it in ResultsViewer updates Irbis.

**Filter by temporal development**

Use the summarized table when you want to filter objects by a value that describes their full temporal development, rather than by values at individual time points.

!!! info "Before you start"
    **Additional prerequisites:**

    - Desired object type selected at the top of ResultsViewer.
    - Objects connected across time points by group ID.
    - **Pivoted** table view selected.

1. Switch to the modality and object type you want to inspect.
2. From the table view drop-down menu in the upper-left corner, select **Pivoted**.
3. Set **Rows** to the identifier that represents one object or group across time. For batch-loaded model data, prefer `fileId_groupId` when it is available.
4. Press **Show summarized** in the bottom-left corner.
5. In the **Filtering** panel, select **Summarized** from **Table to filter** dropdown.
6. Select the summarized parameter to filter by from the drop-down menu below it.
7. Set the accepted range or values.
8. Press **Filter**.

The filter is applied to both the pivoted and summarized tables.

When a summarized table is shown, the filtering panel separates **Full table filters** and **Summarized table filters**. Use **Table to filter** to choose which filter storage you are editing.

!!! warning
    Summarized values are calculated from the underlying Full table data. Pivoted transformations, such as ratios or subtraction from a reference column, are not reflected in the summarized table.

!!! tip
    If the plot does not update immediately, click another table column or briefly switch to another table view and back.

**Related**

- Use [Use ResultsViewer table views and plots](../step-by-step/results-viewer/modes-plots.md) to inspect filtered data.
