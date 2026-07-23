# Open, save, and export ResultsViewer data

Use these controls when you want to preserve a combined ResultsViewer dataset or export the visible table data for external analysis.

!!! info "Before you start"
    **Prerequisites:**

    - Data opened in ResultsViewer.

    **UI location:**

    - ResultsViewer: top-left buttons **Open .irbisRes**, **Save .irbisRes**, and bottom-left table **Export** controls.

## Save a ResultsViewer session

1. Press **Save .irbisRes**.
2. Choose the target folder and file name.
3. Press **Save**.

The saved file stores the ResultsViewer modality data store in a `.irbisRes` file. The code marks the current saved format as `version = 2`.

!!! warning
    Columns selected in **Settings > Select columns to exclude from saving** are removed from the data store before saving. Based on the code comment, this also removes them from the currently open ResultsViewer session.

## Open a ResultsViewer session

1. Press **Open .irbisRes**.
2. Select a file with the `.irbisRes` extension.
3. Wait for the loading dialog to close.

Version 2 `.irbisRes` files load the stored ResultsViewer modality data store. Older files are loaded through the legacy data-structure path if the expected fields are present.

## Exclude columns from saved sessions

1. Open **Settings > Select columns to exclude from saving**.
2. Select the modality and, for model data, the branch.
3. Tick the columns that should be excluded from saving.
4. Press **Apply**.
5. Save the `.irbisRes` file.

The dialog also shows previously excluded columns that are not present in the currently selected table under **Missing excluded columns**.

## Export the visible table

1. In the active table panel, select the export format.
2. Press **Export**.
3. Choose the output file name and folder.

The Full table export control offers `xlsx`, `csv`, and `mat`. Pivoted and Summarized table export controls offer `xlsx` and `csv`.

## Export all data

The main ResultsViewer shell contains an **Export all data** button, but it is hidden in the current App Designer layout. **PLACEHOLDER:** verify in the GUI whether this button is exposed in any mode before documenting it as a normal user workflow.

## Related

- Load multiple source datasets with [Use batch mode](batch-mode.md).
- Choose table content with [Use table views and plots](modes-plots.md).
