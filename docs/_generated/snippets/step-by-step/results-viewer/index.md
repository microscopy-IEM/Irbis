ResultsViewer is part of Irbis dedicated to exploring generated data in tables and plots. It supports filtering, custom categorizations and new column creation, as well as storing specific settings as views. It can run in connection with the main app, providing linked visualization of selected objects, or in batch mode, when multiple datasets can be loaded and explored together.

!!! info "Before you start"
    **Prerequisites:**

    - Processed model or tracks data.

    **UI location:**

    - **ResultsViewer** window.
    - Open it from the right side of the bottom panel by pressing the **Explore results** button.

**Layout**

- Left side: parameter selection and table.
- Right side: plots.
- Bottom-right panel: filtering.

**Table views**

- **Full** table view pools data from all time points; table columns are parameters.
- **Pivoted** table view shows one parameter across time (or another selected parameter); by default, columns are time points and rows are objects connected by group ID.
- **Summarized** table view contains values that summarize development of each row in the Pivoted table.

**Pages**

- [Use table views and plots](../step-by-step/results-viewer/modes-plots.md)
- [Filter available data](../step-by-step/results-viewer/filter-data.md)
- [Filter by temporal development](../step-by-step/results-viewer/filter-temporal-development.md)
- [Define ResultsViewer categorization](../step-by-step/results-viewer/categorize-data.md)
- [Edit columns in Full table view](../step-by-step/results-viewer/edit-columns-full.md)
- [Store a view](../step-by-step/results-viewer/store-view.md)
- [Use batch mode](../step-by-step/results-viewer/batch-mode.md)

!!! warning
    Filters and categorizations are synced between the main Irbis app and ResultsViewer, but generated data itself is not. If you change or generate data in the main app, close and reopen ResultsViewer to sync changes.
