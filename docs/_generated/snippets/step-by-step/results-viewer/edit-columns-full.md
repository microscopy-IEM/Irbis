Use the Full table view controls to add derived columns or manage user-defined columns before switching to Pivoted table view or plotting.

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.
    - Desired modality selected at the top of ResultsViewer: model, tracks, or points.
    - For model data, desired branch selected at the top of ResultsViewer.
    - **Full** table view selected.

    **UI location:**

    - ResultsViewer: **Full** table view selected from the drop-down menu in the upper-left corner.
    - Column and table actions are available above the checkbox list on the left.

**Add a merged column**

Use a merged column when one identifier is not unique enough by itself. For example, after batch loading multiple datasets, combine `fileId` and `groupId` before using Pivoted table view.

1. In the upper-left corner above the checkbox list, click the downwards-pointing arrow.
2. Select **add merged**.
3. Select the first source column from the first drop-down menu.
4. Select the second source column from the second drop-down menu.
5. Press **Save**.

The new merged column appears in the parameter list and can be used as a row identifier in Pivoted table view.

**Remove a user-defined column**

1. Right-click the user-defined column in the checkbox list.
2. Select the delete action from the context menu.

!!! warning
    Removing a column only applies to user-defined columns such as categorizations or merged columns. Irbis-generated measurement columns should be kept as part of the source results table.

**Related**

- Create categories with [Define ResultsViewer categorization](../step-by-step/results-viewer/categorize-data.md).
- Use merged identifiers in [Use ResultsViewer table views and plots](../step-by-step/results-viewer/modes-plots.md).
