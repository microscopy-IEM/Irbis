ResultsViewer is part of Irbis dedicated to exploring generated data in tables and plots. It supports filtering, custom categorizations and new column creation, as well as storing specific settings as views. It can run in connection with the main app, providing linked visualization of selected objects, or in batch mode, when multiple datasets can be loaded and explored together.

!!! info "Before you start"
    **Prerequisites:**

    - Processed model or tracks data.

    **UI location:**

    - **ResultsViewer** window.
    - Open it from the right side of the bottom panel by pressing the **Explore results** button.

**Layout**

- Top-left controls: load combined results, open or save a `.irbisRes` ResultsViewer file, and select the active modality and object type.
- Left side: table controls, parameter or column selection, and the current table.
- Right side: plot type, plot options, plot axes, and the **Filtering** panel.
- Bottom-left controls: show the summarized companion table when **Pivoted** view is active, export the current table, and export or evaluate the current plot.

**Table views**

- **Full** table view pools data from all time points; table columns are parameters.
- **Pivoted** table view shows one parameter across time (or another selected parameter); by default, columns are time points and rows are objects connected by group ID.
- **Summarized** table view contains values that summarize development of each row in the Pivoted table. In the GUI code it is usually created as a bottom companion table from **Show summarized** while **Pivoted** is selected.

**Data sources**

ResultsViewer can receive data directly from the main Irbis app, batch-load one or more `.irbis` files, append files to the current ResultsViewer session, or reopen a saved `.irbisRes` file.

When ResultsViewer is opened from the main app, filters and user-defined column definitions can sync with Irbis. Batch loading disconnects ResultsViewer from the main app. Based on the code, **Add files** appends data to the current ResultsViewer data store; **PLACEHOLDER:** verify whether this should also be described as disconnecting sync in every GUI workflow.

The loader code I could inspect handles model and tracks data. **PLACEHOLDER:** confirm whether points data can be supplied to ResultsViewer by another path before listing it as a documented modality.

**Pages**

- [Use table views and plots](../step-by-step/results-viewer/modes-plots.md)
- [Filter ResultsViewer data](../step-by-step/results-viewer/filter-data.md)
- [Create and manage user-defined columns](../step-by-step/results-viewer/categorize-data.md)
- [Open, save, and export ResultsViewer data](../step-by-step/results-viewer/open-save-export.md)
- [Store a view](../step-by-step/results-viewer/store-view.md)
- [Use batch mode](../step-by-step/results-viewer/batch-mode.md)

!!! warning
    Filters and categorizations are synced between the main Irbis app and ResultsViewer, but generated data itself is not. If you change or generate data in the main app, close and reopen ResultsViewer to sync changes.
