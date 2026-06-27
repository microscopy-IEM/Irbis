# Load data to ResultsViewer in batch

Batch load mode lets you explore data from multiple datasets together.

!!! info "Before you start"
    **Prerequisites:**

    - One or more `.irbis` files with processed data.

    **UI location:**

    - **ResultsViewer** window.

## Steps

1. Press **Batch load**.
2. In the dialog, navigate to the folder containing the datasets and select the files you want to load.
3. When the dialog opens again, select files from another folder if needed.
4. Repeat until all datasets are loaded.
5. Press **Cancel** to close the dialog.
6. Wait for the datasets to load.

!!! warning
    Batch loading can be computationally demanding and may take time.

!!! warning
    Loading multiple datasets severs the connection with the main Irbis app. Uploaded data, filters, and categorizations are reset and are no longer synced.

## Related

- Use [Use ResultsViewer table views and plots](modes-plots.md) after loading batch data.
- Create a unique object identifier with [Edit columns in Full table view](edit-columns-full.md).

!!! example "Screenshot placeholder"
    Add a screenshot of Batch load and the loaded combined table.
