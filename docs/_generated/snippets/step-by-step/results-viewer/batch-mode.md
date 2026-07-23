Batch load mode lets you explore data from multiple datasets together. It combines selected result tables into one ResultsViewer session.

!!! info "Before you start"
    **Prerequisites:**

    - One or more `.irbis` files with processed data.

    **UI location:**

    - **ResultsViewer** window.

**Steps**

1. Press **Batch load**.
2. In the dialog, navigate to the folder containing the datasets and select the files you want to load.
3. When the dialog opens again, select files from another folder if needed.
4. Repeat until all datasets are loaded.
5. Press **Cancel** to close the file selection dialog.
6. Select whether to load **Model**, **Tracks**, or **Both**.
7. Wait for the datasets to load.

!!! warning
    Batch loading can be computationally demanding and may take time.

!!! warning
    Loading multiple datasets severs the connection with the main Irbis app. Uploaded data, filters, and categorizations are reset and are no longer synced.

**What batch loading adds**

For batch-loaded tables, ResultsViewer adds file metadata columns when available from the source `.irbis` file: `fileName`, `groupName`, `round`, `cell`, `description`, and `fileId`.

For model data, if both `fileId` and `groupId` are present, ResultsViewer automatically creates `fileId_groupId`. Use this column as the **Rows** value in Pivoted view when comparing several files, because plain `groupId` values can repeat between datasets.

Batch loading also combines stored filters and stored user-defined column definitions from the loaded files where possible.

**Add files to an existing session**

1. Press **Add files**.
2. Select more `.irbis` files with the same repeated file-selection workflow.
3. Select **Model**, **Tracks**, or **Both**.
4. Wait for loading to finish.

Based on the code, **Add files** appends the newly loaded data to the current ResultsViewer data store without forcing the current modality and branch selection to reset. **PLACEHOLDER:** verify expected behavior when adding files to a ResultsViewer instance that is still connected to the main Irbis app.

**Save batch-loaded data**

1. Press **Save .irbisRes**.
2. Choose a file name and folder.
3. Press **Save**.

Use `.irbisRes` when you want to reopen the combined ResultsViewer session later without repeating the batch load.

**Related**

- Use [Use ResultsViewer table views and plots](../step-by-step/results-viewer/modes-plots.md) after loading batch data.
- Create a unique object identifier with [Create and manage user-defined columns](../step-by-step/results-viewer/categorize-data.md).
- Save combined data with [Open, save, and export ResultsViewer data](../step-by-step/results-viewer/open-save-export.md).
